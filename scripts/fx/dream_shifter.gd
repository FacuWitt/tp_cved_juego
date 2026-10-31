class_name DreamShifter
extends Node
## Cosas que cambian de lugar cuando no se las mira (como en los sueños: das vuelta la cabeza y
## la taza ya no está donde estaba). Un objeto que pasó un rato fuera de la cámara puede correrse
## o girar un poco; un cuadro colgado se tuerce. Nunca se alejan mucho de su lugar original.
## Con shift_all() cambian aunque se los esté mirando (lo usa la memoria en los parpadeos).
## No sabe en qué memoria está: la memoria le dice cuánto soñar (`level`).

@export var settings: DreamSettings
@export var player: Player
## Objetos sueltos: se corren por el piso y giran.
@export var loose_props: Array[Node3D] = []
## Cuadros colgados: se tuercen sobre la pared.
@export var hanging_props: Array[Node3D] = []
## Eje (local de cada cuadro) alrededor del cual se tuercen. Para un cuadro en una pared que mira hacia X, es X.
@export var hanging_axis: Vector3 = Vector3.RIGHT

## Cuánto sueño hay (0 = nada cambia, 1 = lo máximo). Lo pone la memoria.
var level: float = 0.0

var _camera: Camera3D
var _rest: Dictionary = {}
var _unseen: Dictionary = {}
var _check: float = 0.0


func _ready() -> void:
	assert(settings != null and player != null, "DreamShifter: faltan el DreamSettings y el Player")
	_camera = player.get_node("Head/Camera3D") as Camera3D
	for prop: Node3D in loose_props + hanging_props:
		_rest[prop] = prop.transform
		_unseen[prop] = 0.0


func _process(delta: float) -> void:
	if not settings.shifts_enabled or level <= 0.0:
		return
	for prop: Node3D in _rest:
		if _camera.is_position_in_frustum(prop.global_position):
			_unseen[prop] = 0.0
		else:
			_unseen[prop] = float(_unseen[prop]) + delta
	_check += delta
	if _check < settings.shift_check_interval:
		return
	_check = 0.0
	shift_unseen()


## Cambia los objetos que hace rato que no se miran (con la probabilidad de los settings).
func shift_unseen() -> void:
	if not settings.shifts_enabled or level <= 0.0:
		return
	var chance: float = settings.shift_chance * clampf(level * settings.level_gain, 0.0, 1.0)
	for prop: Node3D in _rest:
		if float(_unseen[prop]) >= settings.shift_unseen_time and randf() < chance:
			_shift(prop)
			_unseen[prop] = 0.0


## Cambia todos, aunque se los esté mirando (en un parpadeo, cuando la pantalla está en negro).
func shift_all() -> void:
	if not settings.shifts_enabled or level <= 0.0:
		return
	for prop: Node3D in _rest:
		_shift(prop)


## Devuelve todo a su lugar original (la memoria se estabiliza).
func restore_all() -> void:
	for prop: Node3D in _rest:
		prop.transform = _rest[prop]


func _shift(prop: Node3D) -> void:
	var rest: Transform3D = _rest[prop]
	var t: Transform3D = rest
	if hanging_props.has(prop):
		var tilt: float = deg_to_rad(randf_range(-settings.shift_max_tilt, settings.shift_max_tilt))
		t.basis = rest.basis * Basis(hanging_axis.normalized(), tilt)
	else:
		var offset: float = settings.shift_max_offset
		t.origin = rest.origin + Vector3(randf_range(-offset, offset), 0.0, randf_range(-offset, offset))
		var yaw: float = deg_to_rad(randf_range(-settings.shift_max_yaw, settings.shift_max_yaw))
		t.basis = Basis(Vector3.UP, yaw) * rest.basis
	prop.transform = t
