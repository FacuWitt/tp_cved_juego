class_name RowBoat
extends CharacterBody3D
## El bote a remos del protagonista. Se maneja remo por remo, tocando la tecla (mecánica de Mica):
##   A (row_left) = remo izquierdo hacia adelante (el bote avanza y gira a la derecha)
##   D (row_right) = remo derecho hacia adelante (avanza y gira a la izquierda)
##   S (move_back) = los dos remos hacia atrás (frena y retrocede)
## Cada toque es una remada: la pala entra al agua y ahí se da el empujón. Alternar los remos rinde
## más, repetir el mismo pierde fuerza. El tiempo de cada remada y el empuje están en RowBoatSettings.
## Lo lleva la corriente del río, el viento lo empuja y lo inclina, y aguanta pocos golpes
## contra ramas, rocas y hielo (los obstáculos están en el grupo "boat_hazard").
## El jugador va sentado en `Hull/Seat`; la memoria lo cuelga ahí.

signal hit_taken(hits: int)
signal sunk
signal stroked(side: int)

@export var settings: RowBoatSettings
@export var river: RiverFlow
## El mar/lago con olas: el casco sube, baja y se inclina con ellas (opcional).
@export var waves: OceanFollow
## Altura del agua.
@export var water_level: float = 0.0
## Si se puede remar (la memoria lo prende después de cortar la red).
@export var controls_enabled: bool = false
@export_group("Sonidos")
## Pala que entra al agua, pala que tira y crujido del remo (se elige uno al azar).
@export var dip_sounds: Array[AudioStream] = []
@export var pull_sounds: Array[AudioStream] = []
@export var creak_sounds: Array[AudioStream] = []
@export var bump_rock_sound: AudioStream
@export var bump_log_sound: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var sfx_volume_db: float = -2.0

var hits: int = 0
var is_sunk: bool = false
## Viento actual (empuje horizontal en m/s², lo pone la memoria).
var wind: Vector3 = Vector3.ZERO
## Sacudón actual (0..1), lo baja solo.
var shake: float = 0.0

var _yaw_rate: float = 0.0
var _stroke_phase: Array[float] = [-1.0, -1.0]   # 0 = izquierdo, 1 = derecho; -1 = quieto
var _stroke_dir: Array[float] = [0.0, 0.0]
var _stroke_entered: Array[bool] = [false, false]
var _stroke_cooldown: Array[float] = [0.0, 0.0]
var _stroke_buffer: Array[float] = [0.0, 0.0]
var _buffer_dir: Array[float] = [1.0, 1.0]
var _last_side: int = -1
var _impulse: Vector3 = Vector3.ZERO
## Cuántas remadas hizo en total y cuántas veces alternó un remo con el otro.
var stroke_count: int = 0
var alternations: int = 0
var _hit_timer: float = 0.0
var _time: float = 0.0
var _rapids: float = 1.0
var _hull: Node3D
var _oars: Array[Node3D] = []
var _water_inside: Node3D
var _sfx: AudioStreamPlayer3D
var _bump_sound_wait: float = 0.0


func _ready() -> void:
	assert(settings != null, "RowBoat: falta asignar un RowBoatSettings")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_sfx = AudioStreamPlayer3D.new()
	_sfx.name = "Sfx"
	add_child(_sfx)
	_hull = get_node("Hull") as Node3D
	_oars = [get_node_or_null("Hull/OarL") as Node3D, get_node_or_null("Hull/OarR") as Node3D]
	_water_inside = get_node_or_null("Hull/WaterInside") as Node3D
	if _water_inside != null:
		_water_inside.visible = false


func _physics_process(delta: float) -> void:
	_time += delta
	_hit_timer = maxf(_hit_timer - delta, 0.0)
	_bump_sound_wait = maxf(_bump_sound_wait - delta, 0.0)
	shake = move_toward(shake, 0.0, delta * 2.5)
	if is_sunk:
		return
	if controls_enabled:
		_read_input()
	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x)
	var accel: Vector3 = Vector3.ZERO
	var yaw_accel: float = 0.0
	for side: int in 2:
		_stroke_cooldown[side] = maxf(_stroke_cooldown[side] - delta, 0.0)
		_stroke_buffer[side] = maxf(_stroke_buffer[side] - delta, 0.0)
		if _stroke_buffer[side] > 0.0 and controls_enabled:
			_start_stroke(side, _buffer_dir[side])
		if _stroke_phase[side] < 0.0:
			continue
		_stroke_phase[side] += delta / settings.stroke_time
		if not _stroke_entered[side] and _stroke_phase[side] >= settings.blade_enter:
			_stroke_entered[side] = true
			_blade_enters(side, _stroke_dir[side])
		if _stroke_phase[side] >= 1.0:
			_stroke_phase[side] = -1.0
	# Viento: empuja y hace girar un poco.
	accel += Vector3(wind.x, 0.0, wind.z)
	yaw_accel += -wind.dot(right) * settings.wind_turn * 0.1

	# El agua: el bote se mueve con la corriente; la quilla frena lo que va de costado.
	var current: Vector3 = river.flow_at(global_position) if river != null else Vector3.ZERO
	_rapids = river.rapids_at(river.offset_of(global_position)) if river != null else 1.0
	var rel: Vector3 = velocity - current
	rel.y = 0.0
	var rel_f: float = rel.dot(forward) * exp(-settings.forward_drag * delta)
	var rel_s: float = rel.dot(right) * exp(-settings.side_drag * delta)
	rel = forward * rel_f + right * rel_s + accel * delta + _impulse
	_impulse = Vector3.ZERO
	if rel.length() > settings.max_speed:
		rel = rel.normalized() * settings.max_speed
	velocity = current + rel
	velocity.y = 0.0
	_yaw_rate = (_yaw_rate + yaw_accel * delta) * exp(-settings.turn_drag * delta)
	var max_rate: float = deg_to_rad(settings.max_turn_rate)
	_yaw_rate = clampf(_yaw_rate, -max_rate, max_rate)
	rotate_y(_yaw_rate * delta)

	var before: Vector3 = velocity
	move_and_slide()
	_handle_collisions(before)
	global_position.y = water_level
	_update_visuals(right)


func _read_input() -> void:
	var tap: Callable = Input.is_action_pressed if settings.hold_to_repeat else Input.is_action_just_pressed
	if tap.call("row_left"):
		request_stroke(0, 1.0)
	if tap.call("row_right"):
		request_stroke(1, 1.0)
	if tap.call("move_back"):
		request_stroke(0, -1.0)
		request_stroke(1, -1.0)


## Pide una remada con el remo `side` (0 izquierdo, 1 derecho) hacia adelante (`dir` 1) o atrás (-1).
## Si el remo está ocupado, la guarda un instante y sale apenas se puede.
func request_stroke(side: int, dir: float) -> void:
	if _stroke_phase[side] < 0.0 and _stroke_cooldown[side] <= 0.0:
		_start_stroke(side, dir)
	else:
		_stroke_buffer[side] = settings.stroke_buffer_time
		_buffer_dir[side] = dir


func _start_stroke(side: int, dir: float) -> void:
	if _stroke_phase[side] >= 0.0 or _stroke_cooldown[side] > 0.0:
		return
	_stroke_phase[side] = 0.0
	_stroke_dir[side] = dir
	_stroke_entered[side] = false
	_stroke_cooldown[side] = settings.stroke_cooldown
	_stroke_buffer[side] = 0.0
	_play(creak_sounds, -9.0)
	stroked.emit(side)


## La pala toca el agua: acá se da el empujón y el giro de la remada.
func _blade_enters(side: int, dir: float) -> void:
	var thrust: float = settings.stroke_thrust
	var side_id: int = -1 if side == 0 else 1
	if dir > 0.0:
		if _last_side == 1 - side:
			thrust *= 1.0 + settings.alternate_bonus
			alternations += 1
		elif _last_side == side:
			thrust *= 1.0 - settings.repeat_penalty
		_last_side = side
	else:
		thrust *= settings.back_stroke_factor
	stroke_count += 1
	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	_impulse += forward.normalized() * thrust * dir
	var fwd_speed: float = velocity.dot(forward.normalized())
	var speed_factor: float = lerpf(1.0 - settings.turn_needs_speed, 1.0, clampf(fwd_speed / 3.0, 0.0, 1.0))
	var sign_turn: float = -1.0 if settings.invert_steering else 1.0
	# Remo izquierdo adelante → gira a la derecha (yaw negativo); el derecho, al revés.
	_yaw_rate += sign_turn * float(side_id) * dir * deg_to_rad(settings.stroke_turn) * speed_factor
	_play(dip_sounds, 0.0)
	get_tree().create_timer(settings.stroke_time * 0.1).timeout.connect(func() -> void: _play(pull_sounds, -7.0))


func _handle_collisions(before: Vector3) -> void:
	for i: int in get_slide_collision_count():
		var col: KinematicCollision3D = get_slide_collision(i)
		var normal: Vector3 = col.get_normal()
		normal.y = 0.0
		if normal.length() < 0.01:
			continue
		normal = normal.normalized()
		var impact: float = -before.dot(normal)
		if impact <= 0.0:
			continue
		velocity += normal * impact * settings.bounce
		if impact >= settings.hit_speed * 0.5 and _bump_sound_wait <= 0.0:
			_bump_sound_wait = 0.5
			_play_bump(col.get_collider(), impact)
		_yaw_rate += randf_range(-0.6, 0.6) * impact * 0.3
		var collider: Object = col.get_collider()
		if collider is Node and (collider as Node).is_in_group("boat_hazard") \
				and impact >= settings.hit_speed and _hit_timer <= 0.0:
			take_hit()


## Un golpe fuerte: se sacude y entra agua. Si `sinks_on_hits` está prendido, al último se hunde.
func take_hit() -> void:
	if is_sunk:
		return
	hits += 1
	_hit_timer = settings.hit_cooldown
	shake = 1.0
	if _water_inside != null:
		_water_inside.visible = true
		var tween: Tween = create_tween()
		var filled: int = mini(hits, settings.max_hits)
		tween.tween_property(_water_inside, "position:y", -0.25 + settings.water_per_hit * float(filled), 0.6)
	hit_taken.emit(hits)
	if settings.sinks_on_hits and hits >= settings.max_hits:
		is_sunk = true
		controls_enabled = false
		sunk.emit()


## Deja el bote quieto (para cinemáticas).
func stop() -> void:
	velocity = Vector3.ZERO
	_yaw_rate = 0.0
	_stroke_phase = [-1.0, -1.0]
	_impulse = Vector3.ZERO


## Qué tan avanzada va la remada de cada lado (para que la UI o el sonido la sigan).
func stroke_phase(side: int) -> float:
	return _stroke_phase[side]


func _update_visuals(right: Vector3) -> void:
	if _hull == null:
		return
	var rapids_k: float = clampf(_rapids - 1.0, 0.0, 1.0)
	var bob: float = sin(_time * TAU * settings.bob_speed) * settings.bob_height \
		+ sin(_time * TAU * 2.3) * settings.rapids_bob * rapids_k
	var lean: float = deg_to_rad(settings.wind_roll) * wind.dot(right)
	var roll: float = lean + sin(_time * 1.7) * 0.02 + sin(_time * 9.0) * 0.05 * rapids_k
	var pitch: float = sin(_time * 1.3 + 0.7) * 0.015 + sin(_time * 7.0) * 0.04 * rapids_k
	var jolt: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * settings.hit_shake * shake
	var wave_lift: float = 0.0
	if waves != null:
		var limit: float = deg_to_rad(settings.max_wave_tilt)
		var fwd: Vector3 = -global_basis.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var h_c: float = waves.height_at(global_position.x, global_position.z)
		var h_bow: float = waves.height_at(global_position.x + fwd.x * 1.9, global_position.z + fwd.z * 1.9)
		var h_stern: float = waves.height_at(global_position.x - fwd.x * 1.6, global_position.z - fwd.z * 1.6)
		var h_r: float = waves.height_at(global_position.x + right.x * 0.7, global_position.z + right.z * 0.7)
		var h_l: float = waves.height_at(global_position.x - right.x * 0.7, global_position.z - right.z * 0.7)
		wave_lift = h_c * settings.wave_bob
		pitch += clampf(atan2(h_bow - h_stern, 3.5) * settings.wave_pitch, -limit, limit)
		roll -= clampf(atan2(h_r - h_l, 1.4) * settings.wave_roll, -limit, limit)
	_hull.position = Vector3(0.0, settings.hull_lift + bob + wave_lift, 0.0) + jolt * 0.5
	_hull.rotation = Vector3(pitch + jolt.x, 0.0, -roll + jolt.z)
	# Remos: barren hacia atrás mientras empujan y vuelven por arriba del agua.
	for side: int in 2:
		var oar: Node3D = _oars[side]
		if oar == null:
			continue
		var side_sign: float = -1.0 if side == 0 else 1.0
		var phase: float = _stroke_phase[side]
		var sweep: float = 0.0
		var dip: float = 0.0
		if phase >= 0.0:
			var d: float = _stroke_dir[side]
			sweep = lerpf(-0.55, 0.6, phase) * d
			dip = sin(PI * phase) * 0.28
		# El remo izquierdo apunta a -X y el derecho a +X: los signos se espejan.
		oar.rotation = Vector3(0.0, -sweep * side_sign, -side_sign * (0.22 + dip))


# ---------- Sonido ----------

## Toca un sonido al azar del grupo, en el bote (con un poco de variación de tono).
func _play(pool: Array[AudioStream], offset_db: float) -> void:
	if pool.is_empty() or _sfx == null:
		return
	var stream: AudioStream = pool[randi() % pool.size()]
	if stream == null:
		return
	var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = sfx_volume_db + offset_db
	p.pitch_scale = randf_range(0.93, 1.07)
	p.unit_size = 6.0
	p.max_distance = 45.0
	_sfx.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Golpe contra un obstáculo: roca (y hielo) suena a piedra; rama o tronco, a madera.
func _play_bump(collider: Object, impact: float) -> void:
	var is_rock: bool = collider is Node and not (collider as Node).name.begins_with("Branch")
	var sound: AudioStream = bump_rock_sound if is_rock else bump_log_sound
	var one: Array[AudioStream] = [sound]
	_play(one, 3.0 + linear_to_db(clampf(impact / (settings.max_speed * 0.6), 0.2, 1.0)))

