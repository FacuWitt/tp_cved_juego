class_name RowObstacle
extends Node3D
## Algo que hay que esquivar en el lago: una roca, un tronco flotando, un árbol hundido o una boya.
## Es una "bola" de choque en el plano del agua (x, z): el bote choca si se acerca a menos de su radio.
## Flota sobre las olas. Lo crea RowCourse; el bote (RemosBoat) lo consulta.

enum Kind { ROCK, LOG, SNAG, BUOY }

@export var kind: Kind = Kind.ROCK
## Radio de choque.
@export_range(0.2, 6.0, 0.05, "suffix:m") var radius: float = 1.4
## Cuánto sube y baja con las olas (0 = fijo, como una roca).
@export_range(0.0, 1.5, 0.05) var bob: float = 0.0
## Deriva lenta (m/s) en x, z.
@export var drift: Vector2 = Vector2.ZERO
## Altura de su base respecto al agua.
@export_range(-3.0, 2.0, 0.05, "suffix:m") var base_y: float = 0.0

var water: LakeWater
var _ring: Node3D
var _spin: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_phase = randf() * TAU
	_ring = get_node_or_null("FoamRing") as Node3D
	_spin = randf_range(-0.15, 0.15) if kind == Kind.LOG else 0.0


func _process(delta: float) -> void:
	if drift != Vector2.ZERO:
		global_position += Vector3(drift.x, 0.0, drift.y) * delta
		rotation.y += _spin * delta
	if water == null:
		return
	var h: float = water.height_at(global_position.x, global_position.z)
	global_position.y = base_y + h * bob
	if _ring != null:
		# El anillo de espuma se queda pegado al agua.
		_ring.global_position.y = h + 0.03
		_ring.global_rotation = Vector3.ZERO


## Posición en el plano del agua.
func plane_position() -> Vector2:
	return Vector2(global_position.x, global_position.z)
