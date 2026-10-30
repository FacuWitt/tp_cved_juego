class_name OceanFollow
extends MeshInstance3D
## Hace que el plano del océano acompañe al objetivo en X y Z, para que parezca infinito.
## El oleaje se calcula con la posición del mundo en el shader, así que no se "arrastra".
## También lleva el reloj del mar y sabe la altura del oleaje en cualquier punto, para que el barco flote sobre él.

@export var target: Node3D
## Se mueve de a saltos de este tamaño, para que la grilla de vértices no vibre.
@export_range(0.5, 10.0, 0.1, "suffix:m") var snap: float = 3.0

# Mismas ondas que ocean.gdshader (dirección, frecuencia, amplitud, velocidad).
const _DIRS: Array[Vector2] = [Vector2(1.0, 0.3), Vector2(-0.6, 1.0), Vector2(0.2, -1.0), Vector2(-1.0, -0.5), Vector2(0.8, 0.9), Vector2(0.7, 0.55)]
const _FREQS: Array[float] = [0.11, 0.19, 0.31, 0.53, 0.87, 0.045]
const _AMPS: Array[float] = [1.0, 0.62, 0.34, 0.16, 0.07, 1.0]
const _SPEEDS: Array[float] = [0.9, 1.2, 1.6, 2.1, 2.9, 0.62]

## Valores de respaldo: los mismos que tienen por defecto los parámetros del shader. Si el material de la
## escena los cambia (la M2 baja las olas y apaga el mar de fondo), `height_at` usa los del material.
const WAVE_HEIGHT: float = 1.0
const CALM_CENTER: Vector2 = Vector2.ZERO
const CALM_RADIUS: float = 28.0
const FAR_RADIUS: float = 110.0
const FAR_SCALE: float = 3.2
const BIG_SWELL_NEAR: float = 0.45
const BIG_SWELL_FAR: float = 2.3

var sea_time: float = 0.0

var _wave_height: float = WAVE_HEIGHT
var _calm_center: Vector2 = CALM_CENTER
var _calm_radius: float = CALM_RADIUS
var _far_radius: float = FAR_RADIUS
var _far_scale: float = FAR_SCALE
var _swell_near: float = BIG_SWELL_NEAR
var _swell_far: float = BIG_SWELL_FAR
var _params_frame: int = -1


func _process(delta: float) -> void:
	sea_time += delta
	_refresh_params()
	(material_override as ShaderMaterial).set_shader_parameter("sea_time", sea_time)
	if target == null:
		return
	var p: Vector3 = target.global_position
	global_position = Vector3(snappedf(p.x, snap), global_position.y, snappedf(p.z, snap))


## Altura del oleaje (sobre el nivel medio del mar) en un punto del mundo.
func height_at(world_x: float, world_z: float) -> float:
	_refresh_params()
	var point: Vector2 = Vector2(world_x, world_z)
	var height: float = 0.0
	# Igual que far_factor() del shader: cerca del centro el mar es más manso.
	var far_f: float = smoothstep(_calm_radius, _far_radius, point.distance_to(_calm_center))
	var scl: float = lerpf(1.0, _far_scale, far_f)
	for i: int in _DIRS.size():
		var phase: float = point.dot(_DIRS[i].normalized()) * _FREQS[i] + sea_time * _SPEEDS[i]
		var amp: float = _AMPS[i] * _wave_height * scl
		if i == 5:
			amp = _wave_height * lerpf(_swell_near, _swell_far, far_f)
		height += sin(phase) * amp
	return height


## Lee del material los parámetros que mueven las olas, una vez por cuadro, para que la altura que
## calcula el código sea la que se ve en pantalla.
func _refresh_params() -> void:
	var frame: int = Engine.get_process_frames()
	if frame == _params_frame:
		return
	_params_frame = frame
	var mat: ShaderMaterial = material_override as ShaderMaterial
	if mat == null:
		return
	_wave_height = _param(mat, "wave_height", WAVE_HEIGHT)
	_calm_radius = _param(mat, "calm_radius", CALM_RADIUS)
	_far_radius = _param(mat, "far_radius", FAR_RADIUS)
	_far_scale = _param(mat, "far_scale", FAR_SCALE)
	_swell_near = _param(mat, "big_swell_near", BIG_SWELL_NEAR)
	_swell_far = _param(mat, "big_swell_far", BIG_SWELL_FAR)
	var center: Variant = mat.get_shader_parameter("calm_center")
	_calm_center = center as Vector2 if center is Vector2 else CALM_CENTER


func _param(mat: ShaderMaterial, key: String, fallback: float) -> float:
	var value: Variant = mat.get_shader_parameter(key)
	return float(value) if value != null else fallback
