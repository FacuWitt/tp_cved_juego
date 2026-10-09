class_name OceanFollow
extends MeshInstance3D
## Hace que el plano del océano acompañe al objetivo en X y Z, para que parezca infinito.
## El oleaje se calcula con la posición del mundo en el shader, así que no se "arrastra".
## También lleva el reloj del mar y sabe la altura del oleaje en cualquier punto, para que el barco flote sobre él.

@export var target: Node3D
## Se mueve de a saltos de este tamaño, para que la grilla de vértices no vibre.
@export_range(0.5, 10.0, 0.1, "suffix:m") var snap: float = 3.0

# Mismas ondas que ocean.gdshader (dirección, frecuencia, amplitud, velocidad).
const _DIRS: Array[Vector2] = [Vector2(1.0, 0.3), Vector2(-0.6, 1.0), Vector2(0.2, -1.0), Vector2(-1.0, -0.5), Vector2(0.8, 0.9)]
const _FREQS: Array[float] = [0.11, 0.19, 0.31, 0.53, 0.87]
const _AMPS: Array[float] = [1.0, 0.62, 0.34, 0.16, 0.07]
const _SPEEDS: Array[float] = [0.9, 1.2, 1.6, 2.1, 2.9]

## Mismo valor que `wave_height` en ocean.gdshader (si se cambia allá, cambiarlo acá).
const WAVE_HEIGHT: float = 1.0

var sea_time: float = 0.0


func _process(delta: float) -> void:
	sea_time += delta
	(material_override as ShaderMaterial).set_shader_parameter("sea_time", sea_time)
	if target == null:
		return
	var p: Vector3 = target.global_position
	global_position = Vector3(snappedf(p.x, snap), global_position.y, snappedf(p.z, snap))


## Altura del oleaje (sobre el nivel medio del mar) en un punto del mundo.
func height_at(world_x: float, world_z: float) -> float:
	var point: Vector2 = Vector2(world_x, world_z)
	var height: float = 0.0
	for i: int in _DIRS.size():
		var phase: float = point.dot(_DIRS[i].normalized()) * _FREQS[i] + sea_time * _SPEEDS[i]
		height += sin(phase) * _AMPS[i] * WAVE_HEIGHT
	return height
