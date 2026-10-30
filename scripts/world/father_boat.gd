class_name FatherBoat
extends Node3D
## El bote del padre en la huida: rema por la línea segura del río (la curva `line`, que
## esquiva ramas y rocas) y va siempre unos metros adelante del hijo. Si el hijo se queda
## atrás, frena, lo espera y lo alumbra con la linterna. No choca con nada: es una guía.

## Pide que lo llamen (la memoria muestra la línea del padre).
signal calling

@export var settings: Memory2Settings
## La línea segura que sigue.
@export var line: Path3D
## A quién espera.
@export var follow_target: Node3D
@export var water_level: float = 0.0

var is_running: bool = false
## Distancia recorrida por la línea.
var offset: float = 0.0

var _time: float = 0.0
var _speed: float = 0.0
var _call_timer: float = 0.0
var _target_offset: float = -1.0
var _target_speed: float = 0.0
var _hull: Node3D
var _flashlight: SpotLight3D
var _oars: Array[Node3D] = []
var _character: CharacterRig


func _ready() -> void:
	assert(settings != null and line != null, "FatherBoat: faltan el Memory2Settings y la línea")
	_hull = get_node_or_null("Hull") as Node3D
	_flashlight = get_node_or_null("Hull/Flashlight") as SpotLight3D
	_oars = [get_node_or_null("Hull/OarL") as Node3D, get_node_or_null("Hull/OarR") as Node3D]
	_character = get_node_or_null("Hull/Character") as CharacterRig


## Empieza a remar desde el punto de la línea más cercano a donde está.
func start() -> void:
	offset = line.curve.get_closest_offset(line.to_local(global_position))
	is_running = true


func _process(delta: float) -> void:
	_time += delta
	_call_timer = maxf(_call_timer - delta, 0.0)
	var waiting: bool = false
	if is_running:
		var length: float = line.curve.get_baked_length()
		var gap: float = settings.father_max_gap
		if follow_target != null:
			var target_offset: float = line.curve.get_closest_offset(line.to_local(follow_target.global_position))
			gap = offset - target_offset
			# Qué tan rápido viene el hijo por la línea (suavizado).
			if _target_offset >= 0.0 and delta > 0.0:
				_target_speed = lerpf(_target_speed, maxf((target_offset - _target_offset) / delta, 0.0), minf(delta * 2.0, 1.0))
			_target_offset = target_offset
		# Cerca: rema rápido (nunca más lento que el hijo, así siempre va adelante).
		# Lejos: frena hasta quedarse quieto esperando.
		var k: float = clampf(inverse_lerp(settings.father_max_gap, settings.father_min_gap, gap), 0.0, 1.0)
		var target_speed: float = settings.father_speed * lerpf(0.0, 1.3, k)
		if gap < settings.father_min_gap * 1.6:
			target_speed = maxf(target_speed, _target_speed * 1.15 + 0.4)
		waiting = gap >= settings.father_max_gap
		_speed = move_toward(_speed, target_speed, delta * 3.0)
		offset = minf(offset + _speed * delta, length - 1.0)
		var p: Vector3 = line.to_global(line.curve.sample_baked(offset))
		var ahead: Vector3 = line.to_global(line.curve.sample_baked(minf(offset + 2.0, length)))
		global_position = Vector3(p.x, water_level, p.z)
		var dir: Vector3 = Vector3(ahead.x - p.x, 0.0, ahead.z - p.z)
		if dir.length() > 0.05:
			var target_yaw: float = atan2(-dir.x, -dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 3.0, 1.0))
		if waiting and _call_timer <= 0.0:
			_call_timer = settings.father_call_interval
			calling.emit()
	_update_visuals(waiting)


func _update_visuals(waiting: bool) -> void:
	if _hull != null:
		_hull.position.y = 0.14 + sin(_time * 3.4) * 0.05
		_hull.rotation = Vector3(sin(_time * 1.9) * 0.03, 0.0, sin(_time * 1.4 + 0.5) * 0.05)
	var rowing: float = clampf(_speed / maxf(settings.father_speed, 0.1), 0.0, 1.0)
	for i: int in _oars.size():
		var oar: Node3D = _oars[i]
		if oar == null:
			continue
		var side_sign: float = -1.0 if i == 0 else 1.0
		var phase: float = _time * 1.6 * TAU
		oar.rotation = Vector3(0.0, -side_sign * sin(phase) * 0.5 * rowing, -side_sign * (0.25 + maxf(sin(phase), 0.0) * 0.2 * rowing))
	# El cuerpo rema con los remos (+1 = brazos adelante, cuando el mango del remo va hacia la proa)
	# y mira al hijo mientras pescan o cuando lo espera.
	if _character != null:
		_character.cycle_value = sin(_time * 1.6 * TAU)
		_character.cycle_amount = rowing
		_character.look_enabled = waiting or not is_running
	# Si espera, alumbra al hijo; si no, el camino.
	if _flashlight != null and follow_target != null:
		var forward_point: Vector3 = _flashlight.global_position - global_basis.z * 10.0 + Vector3.DOWN * 1.2
		var back_point: Vector3 = follow_target.global_position + Vector3.UP * 0.6
		var aim: Vector3 = back_point if waiting else forward_point
		var current: Vector3 = _flashlight.global_position - _flashlight.global_basis.z * 8.0
		var blended: Vector3 = current.lerp(aim, 0.08)
		if blended.distance_to(_flashlight.global_position) > 0.5:
			_flashlight.look_at(blended, Vector3.UP)
