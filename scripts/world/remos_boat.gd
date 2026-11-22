class_name RemosBoat
extends Node3D
## El bote del protagonista. Se maneja con dos teclas: una por remo (acciones `row_left` y `row_right`).
## Cada remada empuja el bote hacia adelante y lo gira un poco: remar de un solo lado lo hace girar
## hacia el lado contrario (como en un bote de verdad), alternar lo mantiene derecho.
## No usa el motor de física: guarda su propia velocidad en el plano del agua, flota sobre las olas
## de LakeWater y choca con los RowObstacle del RowCourse.
## El casco, los remos, el farol y el barquito se arman por código (provisorio hasta tener el modelo).

## Hizo una remada. `side` es -1 (remo izquierdo) o 1 (remo derecho).
signal stroke_made(side: int)
## La pala de un remo entró al agua en `world_position`.
signal blade_entered(side: int, world_position: Vector3)
## Chocó con algo. `strength` va de 0 a 1; `kind` es un RowObstacle.Kind.
signal bumped(strength: float, kind: int)

const LEFT: int = -1
const RIGHT: int = 1
# Momentos de la remada (fracción de stroke_time): la pala entra, empieza a salir, sale.
const _ENTER: float = 0.12
const _DRIVE_END: float = 0.62
const _LIFT_END: float = 0.8

@export var settings: RemosBoatSettings
@export var water: LakeWater
@export var course: RowCourse
## Donde va sentado el jugador: el Player se cuelga de este nodo.
@export var seat: Node3D
@export_group("Sonidos")
@export var dip_sounds: Array[AudioStream] = []
@export var pull_sounds: Array[AudioStream] = []
@export var creak_sounds: Array[AudioStream] = []
@export var bump_rock_sound: AudioStream
@export var bump_log_sound: AudioStream
@export var lantern_creak_sound: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var sfx_volume_db: float = -2.0

## Si es falso el bote no responde a las teclas (cinemáticas, antes de despertar).
var control_enabled: bool = false
## Caña de pescar (se echa en la escena de pesca del principio y se guarda para remar).
var rod: RemosFishingRod
## Si es verdadero el bote queda quieto (pero sigue flotando en las olas).
var frozen: bool = false
## Cuántas remadas hizo en total.
var stroke_count: int = 0
## Cuántas veces alternó un remo con el otro (para saber si ya aprendió).
var alternations: int = 0
## Vuelco extra (radianes) y hundimiento extra (metros): los usa la escena cuando el bote se da vuelta.
var extra_roll: float = 0.0
var extra_sink: float = 0.0

var _pos2: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _yaw_rate: float = 0.0
var _pitch: float = 0.0
var _roll: float = 0.0
var _last_side: int = 0
var _bump_wait: float = 0.0
var _shake: float = 0.0
var _seat_base: Vector3 = Vector3.ZERO
var _oars: Dictionary = {}
var _lantern: Node3D
var _lantern_light: OmniLight3D
var _toy_boat: Node3D
var _bow_spray: CPUParticles3D
var _sfx: AudioStreamPlayer3D
var _wind_dir: Vector2 = Vector2(0.9, 0.35).normalized()
var _creak_wait: float = 3.0
var _time: float = 0.0


class Oar extends RefCounted:
	var side: int = 0
	var pivot: Node3D
	var blade: Marker3D
	var splash: CPUParticles3D
	var sfx: AudioStreamPlayer3D
	var u: float = -1.0
	var cooldown: float = 0.0
	var buffered: float = 0.0
	var entered: bool = false


func _ready() -> void:
	assert(settings != null, "RemosBoat: falta el RemosBoatSettings")
	assert(seat != null, "RemosBoat: falta asignar el asiento (seat)")
	_pos2 = Vector2(global_position.x, global_position.z)
	_seat_base = seat.position
	_build_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled or frozen:
		return
	if event.is_action_pressed("row_left"):
		request_stroke(LEFT)
	elif event.is_action_pressed("row_right"):
		request_stroke(RIGHT)


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_time += delta
	for side: int in _oars:
		_update_oar(_oars[side] as Oar, delta)
	if not frozen:
		_update_motion(delta)
	_update_tilt(delta)
	_update_extras(delta)


# ---------- Interfaz ----------

## Pide una remada con el remo `side` (-1 izquierdo, 1 derecho). Si el remo está ocupado, la guarda un instante.
func request_stroke(side: int) -> void:
	var oar: Oar = _oars[side] as Oar
	if oar.cooldown <= 0.0 and oar.u < 0.0:
		_start_stroke(oar)
	else:
		oar.buffered = settings.stroke_buffer_time


## Velocidad hacia adelante (negativa si va de reversa).
func forward_speed() -> float:
	return _vel.dot(_forward())


## Posición en el plano del agua (x, z).
func plane_position() -> Vector2:
	return _pos2


## Hacia dónde apunta la proa, en el plano del agua (vector unitario).
func forward_2d() -> Vector2:
	return _forward()


## Lleva el bote a un punto del agua mirando en una dirección, y lo frena.
func teleport(pos: Vector2, heading: Vector2) -> void:
	_pos2 = pos
	_vel = Vector2.ZERO
	_yaw_rate = 0.0
	rotation.y = atan2(-heading.x, -heading.y)
	global_position = Vector3(pos.x, global_position.y, pos.y)


## Frena el bote de golpe (el padre lo pide en el evento de la ola).
func stop_dead() -> void:
	_vel = Vector2.ZERO
	_yaw_rate = 0.0


## Sacude la cámara (0 a 1).
func shake_camera(amount: float) -> void:
	_shake = maxf(_shake, clampf(amount, 0.0, 1.0))


func get_lantern() -> Node3D:
	return _lantern


func get_toy_boat() -> Node3D:
	return _toy_boat


# ---------- Remadas ----------

func _start_stroke(oar: Oar) -> void:
	oar.u = 0.0
	oar.entered = false
	oar.cooldown = settings.stroke_cooldown
	oar.buffered = 0.0
	_play(creak_sounds, oar.sfx, -9.0)


func _update_oar(oar: Oar, delta: float) -> void:
	oar.cooldown = maxf(oar.cooldown - delta, 0.0)
	oar.buffered = maxf(oar.buffered - delta, 0.0)
	if oar.buffered > 0.0 and oar.cooldown <= 0.0 and oar.u < 0.0 and control_enabled and not frozen:
		_start_stroke(oar)
	if oar.u >= 0.0:
		oar.u += delta / settings.stroke_time
		if not oar.entered and oar.u >= _ENTER:
			oar.entered = true
			_blade_enters(oar)
		if oar.u >= 1.0:
			oar.u = -1.0
			oar.entered = false
	_pose_oar(oar)


func _blade_enters(oar: Oar) -> void:
	# El empuje se aplica cuando la pala toca el agua.
	var side: int = oar.side
	var thrust: float = settings.stroke_thrust
	if _last_side == -side:
		thrust *= 1.0 + settings.alternate_bonus
		alternations += 1
	elif _last_side == side:
		thrust *= 1.0 - settings.repeat_penalty
	_last_side = side
	stroke_count += 1
	if not frozen:
		_vel += _forward() * thrust
		var speed_factor: float = lerpf(1.0 - settings.turn_needs_speed, 1.0, clampf(forward_speed() / 3.0, 0.0, 1.0))
		var sign_turn: float = -1.0 if settings.invert_steering else 1.0
		_yaw_rate += sign_turn * float(side) * deg_to_rad(settings.stroke_turn) * speed_factor
	if oar.splash != null:
		oar.splash.restart()
		oar.splash.emitting = true
	_play(dip_sounds, oar.sfx, 0.0)
	get_tree().create_timer(settings.stroke_time * 0.1).timeout.connect(func() -> void: _play(pull_sounds, oar.sfx, -7.0))
	stroke_made.emit(side)
	blade_entered.emit(side, oar.blade.global_position)


func _pose_oar(oar: Oar) -> void:
	var sweep: float = deg_to_rad(settings.oar_sweep)
	var dip: float = deg_to_rad(settings.oar_dip)
	var up: float = deg_to_rad(settings.oar_lift)
	var rest_a: float = 0.2
	var rest_lift: float = up * 0.4
	var a: float = rest_a
	var lift: float = rest_lift
	var u: float = oar.u
	if u >= 0.0:
		if u < _ENTER:
			var k: float = u / _ENTER
			a = lerpf(rest_a, 1.0, smoothstep(0.0, 1.0, k))
			lift = lerpf(rest_lift, dip, k)
		elif u < _DRIVE_END:
			var k2: float = (u - _ENTER) / (_DRIVE_END - _ENTER)
			a = lerpf(1.0, -1.0, smoothstep(0.0, 1.0, k2))
			lift = dip
		elif u < _LIFT_END:
			var k3: float = smoothstep(0.0, 1.0, (u - _DRIVE_END) / (_LIFT_END - _DRIVE_END))
			a = lerpf(-1.0, -0.8, k3)
			lift = lerpf(dip, up, k3)
		else:
			var k4: float = smoothstep(0.0, 1.0, (u - _LIFT_END) / (1.0 - _LIFT_END))
			a = lerpf(-0.8, rest_a, k4)
			lift = lerpf(up, rest_lift, k4)
	oar.pivot.rotation = Vector3(0.0, float(oar.side) * a * sweep, float(oar.side) * lift)


# ---------- Movimiento ----------

func _forward() -> Vector2:
	var yaw: float = rotation.y
	return Vector2(-sin(yaw), -cos(yaw))


func _right() -> Vector2:
	var yaw: float = rotation.y
	return Vector2(cos(yaw), -sin(yaw))


func _update_motion(delta: float) -> void:
	var fwd: Vector2 = _forward()
	var right: Vector2 = _right()
	var vf: float = _vel.dot(fwd) * exp(-settings.water_drag * delta)
	var vl: float = _vel.dot(right) * exp(-settings.side_drag * delta)
	_vel = fwd * vf + right * vl
	var storm: float = water.storm if water != null else 0.0
	_vel += _wind_dir * settings.wind_push * storm * delta
	_bump_wait = maxf(_bump_wait - delta, 0.0)
	_apply_corridor(delta)
	if _vel.length() > settings.max_speed:
		_vel = _vel.normalized() * settings.max_speed
	_yaw_rate *= exp(-settings.turn_drag * delta)
	var max_rate: float = deg_to_rad(settings.max_turn_rate)
	_yaw_rate = clampf(_yaw_rate, -max_rate, max_rate)
	rotation.y += _yaw_rate * delta
	_pos2 += _vel * delta
	_collide()
	global_position.x = _pos2.x
	global_position.z = _pos2.y


# La corriente empuja de vuelta al camino si se aleja demasiado: nadie se pierde.
func _apply_corridor(delta: float) -> void:
	if course == null:
		return
	var nearest: Vector2 = course.nearest_point(_pos2)
	var off: float = _pos2.distance_to(nearest)
	if off <= settings.soft_corridor:
		return
	var back: Vector2 = (nearest - _pos2).normalized()
	var k: float = clampf((off - settings.soft_corridor) / maxf(settings.hard_corridor - settings.soft_corridor, 1.0), 0.0, 1.5)
	_vel += back * settings.bounds_push * (0.4 + k) * delta * 4.0
	if off > settings.hard_corridor:
		_pos2 = nearest - back * settings.hard_corridor
		var outward: float = _vel.dot(-back)
		if outward > 0.0:
			_vel += back * outward


func _collide() -> void:
	if course == null:
		return
	var fwd: Vector2 = _forward()
	for obstacle: RowObstacle in course.obstacles:
		var op: Vector2 = obstacle.plane_position()
		# Dos círculos: uno en el centro del bote y otro en la proa.
		for i: int in 2:
			var c: Vector2 = _pos2 + fwd * (1.3 if i == 1 else 0.0)
			var min_d: float = obstacle.radius + settings.boat_radius * (0.6 if i == 1 else 0.9)
			var d: float = c.distance_to(op)
			if d >= min_d:
				continue
			var away: Vector2 = (c - op).normalized() if d > 0.001 else -fwd
			_pos2 += away * (min_d - d)
			var into: float = _vel.dot(-away)
			if into > 0.0:
				_vel += away * into
				_vel *= 1.0 - settings.bump_speed_loss * clampf(into / (settings.max_speed * 0.5), 0.15, 1.0)
				_vel += away * settings.bump_push
				_yaw_rate += fwd.cross(away) * deg_to_rad(18.0)
				if _bump_wait <= 0.0 and into > 0.35:
					_bump_wait = settings.bump_cooldown
					var strength: float = clampf(into / (settings.max_speed * 0.6), 0.15, 1.0)
					_shake = maxf(_shake, strength * settings.bump_shake)
					_play_bump(obstacle.kind)
					bumped.emit(strength, obstacle.kind)


func _height(p: Vector2) -> float:
	return water.height_at(p.x, p.y) if water != null else 0.0


func _update_tilt(delta: float) -> void:
	var fwd: Vector2 = _forward()
	var right: Vector2 = _right()
	var hc: float = _height(_pos2)
	var hb: float = _height(_pos2 + fwd * 1.9)
	var hs: float = _height(_pos2 - fwd * 1.6)
	var hr: float = _height(_pos2 + right * 0.7)
	var hl: float = _height(_pos2 - right * 0.7)
	var limit: float = deg_to_rad(settings.max_tilt)
	var target_pitch: float = clampf(atan2(hb - hs, 3.5) * settings.pitch_amount, -limit, limit)
	var target_roll: float = clampf(atan2(hr - hl, 1.4) * settings.roll_amount, -limit, limit)
	var follow: float = 1.0 - exp(-settings.tilt_follow * delta)
	_pitch = lerpf(_pitch, target_pitch, follow)
	_roll = lerpf(_roll, target_roll, follow)
	rotation.x = _pitch
	rotation.z = _roll + extra_roll
	global_position.y = hc * settings.bob_amount + settings.draft - extra_sink


# Sacudida de cámara, farol que se balancea, rocío en la proa, crujidos.
func _update_extras(delta: float) -> void:
	_shake = maxf(_shake - delta / maxf(settings.shake_decay, 0.01), 0.0)
	var jitter: Vector3 = Vector3(randf() - 0.5, randf() - 0.5, 0.0) * _shake * 0.12
	seat.position = _seat_base + jitter
	seat.rotation.z = (randf() - 0.5) * _shake * 0.06
	if _lantern != null:
		var sway: float = sin(_time * 1.7) * 0.07 + _roll * 0.9
		_lantern.rotation.z = sway
		_lantern.rotation.x = sin(_time * 1.3 + 1.0) * 0.05 + _pitch * 0.6
	if _lantern_light != null:
		_lantern_light.light_energy = 1.05 + 0.12 * sin(_time * 9.0) + 0.08 * sin(_time * 23.0)
	if _bow_spray != null:
		_bow_spray.emitting = forward_speed() > 1.4
	var storm: float = water.storm if water != null else 0.0
	_creak_wait -= delta
	if _creak_wait <= 0.0:
		_creak_wait = randf_range(3.0, 7.0) - 2.0 * storm
		if absf(_roll) > deg_to_rad(2.0) or storm > 0.3:
			var one: Array[AudioStream] = [lantern_creak_sound]
			_play(one, _sfx, -10.0)


# ---------- Sonido ----------

func _play(pool: Array[AudioStream], player: AudioStreamPlayer3D, offset_db: float) -> void:
	if pool.is_empty() or player == null:
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
	player.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _play_bump(kind: int) -> void:
	var sound: AudioStream = bump_log_sound if kind == RowObstacle.Kind.LOG else bump_rock_sound
	var one: Array[AudioStream] = [sound]
	_play(one, _sfx, 3.0)


# ---------- Armado del bote (provisorio) ----------

func _build_visuals() -> void:
	var wood: StandardMaterial3D = _mat(Color(0.3, 0.19, 0.1), 0.9)
	var pale: StandardMaterial3D = _mat(Color(0.55, 0.42, 0.26), 0.85)
	var dark: StandardMaterial3D = _mat(Color(0.12, 0.1, 0.09), 0.7)
	var hull: MeshInstance3D = MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = BoatHull.build(4.4, 1.5, 0.62)
	var hull_mat: StandardMaterial3D = _mat(Color(0.2, 0.125, 0.07), 0.9)
	hull_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	hull.material_override = hull_mat
	add_child(hull)
	_add_box("SeatPlank", Vector3(1.28, 0.06, 0.36), Vector3(0.0, 0.2, 0.3), wood)
	_add_box("BowPlank", Vector3(1.0, 0.06, 0.3), Vector3(0.0, 0.22, -1.0), wood)
	_add_box("SternPlank", Vector3(1.1, 0.06, 0.3), Vector3(0.0, 0.2, 1.4), wood)
	for side: int in [LEFT, RIGHT]:
		var lock: MeshInstance3D = MeshInstance3D.new()
		lock.name = "Oarlock%s" % ("L" if side == LEFT else "R")
		var post: CylinderMesh = CylinderMesh.new()
		post.top_radius = 0.025
		post.bottom_radius = 0.03
		post.height = 0.16
		post.radial_segments = 6
		lock.mesh = post
		lock.material_override = dark
		lock.position = Vector3(float(side) * 0.78, 0.5, 0.12)
		add_child(lock)
		_oars[side] = _make_oar(side, pale, dark)
	_sfx = AudioStreamPlayer3D.new()
	_sfx.name = "Sfx"
	_sfx.position = Vector3(0.0, 0.5, -0.5)
	add_child(_sfx)
	_build_lantern(dark)
	_build_toy_boat()
	_build_rod(pale)
	_bow_spray = _make_spray(Vector3(0.0, 0.1, -2.3))
	add_child(_bow_spray)


func _make_oar(side: int, pale: StandardMaterial3D, dark: StandardMaterial3D) -> Oar:
	var oar: Oar = Oar.new()
	oar.side = side
	var pivot: Node3D = Node3D.new()
	pivot.name = "Oar%s" % ("L" if side == LEFT else "R")
	pivot.position = Vector3(float(side) * 0.78, 0.5, 0.12)
	add_child(pivot)
	oar.pivot = pivot
	var shaft: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.022
	cyl.bottom_radius = 0.03
	cyl.height = 2.4
	cyl.radial_segments = 6
	shaft.mesh = cyl
	shaft.rotation = Vector3(0.0, 0.0, PI * 0.5)
	shaft.position = Vector3(float(side) * 0.5, 0.0, 0.0)
	shaft.material_override = pale
	pivot.add_child(shaft)
	var blade: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.56, 0.014, 0.2)
	blade.mesh = box
	blade.position = Vector3(float(side) * 1.46, 0.0, 0.0)
	blade.material_override = pale
	pivot.add_child(blade)
	var grip: MeshInstance3D = MeshInstance3D.new()
	var gc: CylinderMesh = CylinderMesh.new()
	gc.top_radius = 0.035
	gc.bottom_radius = 0.035
	gc.height = 0.22
	gc.radial_segments = 6
	grip.mesh = gc
	grip.rotation = Vector3(0.0, 0.0, PI * 0.5)
	grip.position = Vector3(float(side) * -0.62, 0.0, 0.0)
	grip.material_override = dark
	pivot.add_child(grip)
	oar.blade = Marker3D.new()
	oar.blade.position = Vector3(float(side) * 1.5, 0.0, 0.0)
	pivot.add_child(oar.blade)
	oar.sfx = AudioStreamPlayer3D.new()
	oar.blade.add_child(oar.sfx)
	oar.splash = _make_splash()
	oar.blade.add_child(oar.splash)
	return oar


func _make_splash() -> CPUParticles3D:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 16
	p.lifetime = 0.55
	p.explosiveness = 0.95
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var drop: SphereMesh = SphereMesh.new()
	drop.radius = 0.025
	drop.height = 0.05
	drop.radial_segments = 4
	drop.rings = 2
	p.mesh = drop
	p.material_override = _mat(Color(0.8, 0.88, 0.95), 0.4)
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 55.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0.0, -9.0, 0.0)
	return p


func _make_spray(pos: Vector3) -> CPUParticles3D:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.name = "BowSpray"
	p.position = pos
	p.amount = 28
	p.lifetime = 0.6
	p.local_coords = false
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var drop: SphereMesh = SphereMesh.new()
	drop.radius = 0.03
	drop.height = 0.06
	drop.radial_segments = 4
	drop.rings = 2
	p.mesh = drop
	p.material_override = _mat(Color(0.75, 0.85, 0.92), 0.4)
	p.direction = Vector3(0.0, 1.0, -0.3)
	p.spread = 40.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.8
	p.gravity = Vector3(0.0, -7.0, 0.0)
	return p


func _build_lantern(dark: StandardMaterial3D) -> void:
	_lantern = Node3D.new()
	_lantern.name = "Lantern"
	_lantern.position = Vector3(-0.28, 0.82, -1.55)
	add_child(_lantern)
	var hook: MeshInstance3D = MeshInstance3D.new()
	var rod: CylinderMesh = CylinderMesh.new()
	rod.top_radius = 0.012
	rod.bottom_radius = 0.012
	rod.height = 0.5
	rod.radial_segments = 4
	hook.mesh = rod
	hook.position = Vector3(0.0, 0.2, 0.0)
	hook.material_override = dark
	_lantern.add_child(hook)
	_add_box_to(_lantern, "Base", Vector3(0.16, 0.025, 0.16), Vector3(0.0, -0.06, 0.0), dark)
	_add_box_to(_lantern, "Cap", Vector3(0.17, 0.03, 0.17), Vector3(0.0, 0.1, 0.0), dark)
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.albedo_color = Color(1.0, 0.72, 0.38)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.62, 0.25)
	glass.emission_energy_multiplier = 2.2
	_add_box_to(_lantern, "Glass", Vector3(0.12, 0.14, 0.12), Vector3(0.0, 0.02, 0.0), glass)
	_lantern_light = OmniLight3D.new()
	_lantern_light.name = "LanternLight"
	_lantern_light.light_color = Color(1.0, 0.68, 0.36)
	_lantern_light.light_energy = 1.05
	_lantern_light.omni_range = 11.0
	_lantern_light.omni_attenuation = 1.3
	_lantern_light.position = Vector3(0.0, 0.02, 0.0)
	_lantern.add_child(_lantern_light)


func _build_toy_boat() -> void:
	_toy_boat = Node3D.new()
	_toy_boat.name = "ToyBoat"
	_toy_boat.position = Vector3(0.32, 0.27, -1.0)
	_toy_boat.rotation.y = 0.4
	add_child(_toy_boat)
	var hull: MeshInstance3D = MeshInstance3D.new()
	hull.mesh = BoatHull.build(0.34, 0.14, 0.09)
	hull.position = Vector3(0.0, 0.0, 0.0)
	var m: StandardMaterial3D = _mat(Color(0.6, 0.38, 0.18), 0.8)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.35)
	m.emission_energy_multiplier = 0.25
	hull.material_override = m
	_toy_boat.add_child(hull)
	_add_box_to(_toy_boat, "Mast", Vector3(0.012, 0.22, 0.012), Vector3(0.0, 0.15, -0.02), m)
	_add_box_to(_toy_boat, "Sail", Vector3(0.012, 0.15, 0.13), Vector3(0.0, 0.17, 0.05), m)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(1.0, 0.72, 0.4)
	glow.light_energy = 0.28
	glow.omni_range = 1.8
	glow.position = Vector3(0.0, 0.12, 0.0)
	_toy_boat.add_child(glow)


func _build_rod(_pale: StandardMaterial3D) -> void:
	# Caña del hijo: a la izquierda, para que el padre (a la derecha) se vea en la escena de pesca.
	rod = RemosFishingRod.new()
	rod.name = "RemosFishingRod"
	rod.side = -1.0
	rod.position = Vector3(-0.5, 0.55, 0.2)
	add_child(rod)


func _add_box(node_name: String, size: Vector3, pos: Vector3, material: Material) -> void:
	_add_box_to(self, node_name, size, pos, material)


func _add_box_to(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m
