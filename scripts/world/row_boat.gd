class_name RowBoat
extends CharacterBody3D
## El bote a remos del protagonista. Se maneja remo por remo:
##   Q = remo izquierdo hacia adelante (el bote avanza y gira a la derecha)
##   E = remo derecho hacia adelante (avanza y gira a la izquierda)
##   A / D = remo izquierdo / derecho hacia atrás · S = los dos hacia atrás (frena y retrocede)
## Lo lleva la corriente del río, el viento lo empuja y lo inclina, y aguanta pocos golpes
## contra ramas, rocas y hielo (los obstáculos están en el grupo "boat_hazard").
## El jugador va sentado en `Hull/Seat`; la memoria lo cuelga ahí.

signal hit_taken(hits: int)
signal sunk
signal stroked(side: int)

@export var settings: RowBoatSettings
@export var river: RiverFlow
## Altura del agua.
@export var water_level: float = 0.0
## Si se puede remar (la memoria lo prende después de cortar la red).
@export var controls_enabled: bool = false

var hits: int = 0
var is_sunk: bool = false
## Viento actual (empuje horizontal en m/s², lo pone la memoria).
var wind: Vector3 = Vector3.ZERO
## Sacudón actual (0..1), lo baja solo.
var shake: float = 0.0

var _yaw_rate: float = 0.0
var _stroke_phase: Array[float] = [-1.0, -1.0]   # 0 = izquierdo, 1 = derecho; -1 = quieto
var _stroke_dir: Array[float] = [0.0, 0.0]
var _hit_timer: float = 0.0
var _time: float = 0.0
var _rapids: float = 1.0
var _hull: Node3D
var _oars: Array[Node3D] = []
var _water_inside: Node3D


func _ready() -> void:
	assert(settings != null, "RowBoat: falta asignar un RowBoatSettings")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_hull = get_node("Hull") as Node3D
	_oars = [get_node_or_null("Hull/OarL") as Node3D, get_node_or_null("Hull/OarR") as Node3D]
	_water_inside = get_node_or_null("Hull/WaterInside") as Node3D
	if _water_inside != null:
		_water_inside.visible = false


func _physics_process(delta: float) -> void:
	_time += delta
	_hit_timer = maxf(_hit_timer - delta, 0.0)
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
		if _stroke_phase[side] < 0.0:
			continue
		_stroke_phase[side] += delta / settings.stroke_time
		if _stroke_phase[side] >= 1.0:
			_stroke_phase[side] = -1.0
			continue
		var push: float = sin(PI * _stroke_phase[side])
		var dir: float = _stroke_dir[side]
		var force: float = settings.stroke_force * push * (1.0 if dir > 0.0 else settings.back_stroke_factor)
		accel += forward * force * dir
		# Remo izquierdo adelante → gira a la derecha (yaw negativo); el derecho, al revés.
		var side_sign: float = -1.0 if side == 0 else 1.0
		yaw_accel += side_sign * dir * settings.stroke_turn * push
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
	rel = forward * rel_f + right * rel_s + accel * delta
	if rel.length() > settings.max_speed:
		rel = rel.normalized() * settings.max_speed
	velocity = current + rel
	velocity.y = 0.0
	_yaw_rate = (_yaw_rate + yaw_accel * delta) * exp(-settings.turn_drag * delta)
	rotate_y(_yaw_rate * delta)

	var before: Vector3 = velocity
	move_and_slide()
	_handle_collisions(before)
	global_position.y = water_level
	_update_visuals(right)


func _read_input() -> void:
	_try_stroke(0, 1.0, "row_left")
	_try_stroke(1, 1.0, "row_right")
	_try_stroke(0, -1.0, "move_left")
	_try_stroke(1, -1.0, "move_right")
	if Input.is_action_pressed("move_back"):
		_start_stroke(0, -1.0)
		_start_stroke(1, -1.0)


func _try_stroke(side: int, dir: float, action: String) -> void:
	if InputMap.has_action(action) and Input.is_action_pressed(action):
		_start_stroke(side, dir)


## Empieza una remada si ese remo está libre. Mantener la tecla rema seguido.
func _start_stroke(side: int, dir: float) -> void:
	if _stroke_phase[side] >= 0.0:
		return
	_stroke_phase[side] = 0.0
	_stroke_dir[side] = dir
	stroked.emit(side)


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
	_hull.position = Vector3(0.0, settings.hull_lift + bob, 0.0) + jolt * 0.5
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
