class_name LakeWater
extends MeshInstance3D
## El agua del lago. Acompaña al objetivo en X y Z para que parezca infinita, lleva el reloj de las olas
## y sabe la altura del agua en cualquier punto (para que el bote y los obstáculos floten sobre ella).
## Las olas crecen con la tormenta (`set_storm`). Una ola gigante (`launch_surge`) cruza el lago por delante.
## El shader (lake_water.gdshader) calcula las mismas olas: si se toca una, hay que tocar la otra.

@export var settings: LakeSettings
## A quién acompaña el agua (normalmente el bote del jugador).
@export var target: Node3D
## Se mueve de a saltos de este tamaño, para que la grilla de vértices no vibre.
@export_range(0.5, 10.0, 0.1, "suffix:m") var snap: float = 2.0

# Mismas ondas que lake_water.gdshader (dirección, frecuencia, amplitud, velocidad).
const _DIRS: Array[Vector2] = [Vector2(1.0, 0.35), Vector2(-0.55, 1.0), Vector2(0.25, -1.0), Vector2(-1.0, -0.6), Vector2(0.8, 0.9)]
const _FREQS: Array[float] = [0.16, 0.27, 0.43, 0.71, 1.1]
const _AMPS: Array[float] = [1.0, 0.6, 0.35, 0.18, 0.08]
const _SPEEDS: Array[float] = [0.8, 1.0, 1.3, 1.7, 2.3]

## 0 = calma, 1 = tormenta.
var storm: float = 0.0
var sea_time: float = 0.0

var _material: ShaderMaterial
var _wave_scale: float = 0.1
var _surge_origin: Vector2 = Vector2.ZERO
var _surge_dir: Vector2 = Vector2(0.0, -1.0)
var _surge_pos: float = 0.0
var _surge_height: float = 0.0
var _surge_width: float = 6.0
var _surge_lat: float = 40.0
var _surge_tween: Tween = null


func _ready() -> void:
	assert(settings != null, "LakeWater: falta el LakeSettings")
	_material = material_override as ShaderMaterial
	assert(_material != null, "LakeWater: el material_override tiene que ser un ShaderMaterial con lake_water.gdshader")
	set_storm(storm)
	if target != null:
		_follow()


func _process(delta: float) -> void:
	sea_time += delta * settings.wave_speed
	_material.set_shader_parameter("sea_time", sea_time)
	if target != null:
		_follow()


## Material del agua (para que LightningController le pase el parámetro `flash`).
func get_water_material() -> ShaderMaterial:
	return _material


## Cambia la tormenta: 0 = atardecer en calma, 1 = tormenta. Mueve las olas y los colores del agua.
func set_storm(value: float) -> void:
	storm = clampf(value, 0.0, 1.0)
	_wave_scale = settings.storm_wave_height * lerpf(settings.calm_wave_scale, 1.0, storm)
	_material.set_shader_parameter("storm", storm)
	_material.set_shader_parameter("wave_scale", _wave_scale)
	_material.set_shader_parameter("deep_color", settings.calm_deep_color.lerp(settings.storm_deep_color, storm))
	_material.set_shader_parameter("sky_horizon_color", settings.calm_horizon_color.lerp(settings.storm_horizon_color, storm))
	_material.set_shader_parameter("sky_zenith_color", settings.calm_zenith_color.lerp(settings.storm_zenith_color, storm))
	_material.set_shader_parameter("reflect_strength", lerpf(settings.calm_reflect, settings.storm_reflect, storm))
	_material.set_shader_parameter("foam_color", settings.foam_color)
	_material.set_shader_parameter("slate_color", settings.slate_color)
	_material.set_shader_parameter("foam_amount", settings.foam_amount)
	_material.set_shader_parameter("lit_color", settings.lit_color)
	_material.set_shader_parameter("lit_strength", settings.lit_strength)


## Altura del agua (sobre el nivel medio) en un punto del mundo.
func height_at(world_x: float, world_z: float) -> float:
	var point: Vector2 = Vector2(world_x, world_z)
	var h: float = 0.0
	for i: int in _DIRS.size():
		h += sin(point.dot(_DIRS[i].normalized()) * _FREQS[i] + sea_time * _SPEEDS[i]) * _AMPS[i] * _wave_scale
	if _surge_height > 0.0:
		var rel: Vector2 = point - _surge_origin
		var s: float = rel.dot(_surge_dir) - _surge_pos
		var lat: float = rel.dot(Vector2(-_surge_dir.y, _surge_dir.x))
		var w: float = _surge_width * (2.4 if s < 0.0 else 0.5)
		h += _surge_height * exp(-(s * s) / (w * w)) * exp(-(lat * lat) / (_surge_lat * _surge_lat))
	return h


## Lanza una ola gigante que sale de `from` (x, z), viaja en la dirección `dir` y recorre `distance` metros en `time` segundos.
## Se puede esperar con await: termina cuando el frente llegó a `distance`.
func launch_surge(from: Vector2, dir: Vector2, distance: float, time: float, height: float, width: float, lateral: float) -> void:
	_surge_origin = from
	_surge_dir = dir.normalized()
	_surge_pos = 0.0
	_surge_width = width
	_surge_lat = lateral
	_surge_height = 0.0
	_push_surge()
	if _surge_tween != null and _surge_tween.is_valid():
		_surge_tween.kill()
	_surge_tween = create_tween().set_parallel(true)
	# La altura sube mientras viaja: se la ve crecer en la oscuridad.
	_surge_tween.tween_method(func(k: float) -> void:
		_surge_height = height * smoothstep(0.0, 0.35, k)
		_surge_pos = distance * k
		_push_surge(), 0.0, 1.0, time)
	await _surge_tween.finished


## Saca la ola gigante.
func clear_surge() -> void:
	if _surge_tween != null and _surge_tween.is_valid():
		_surge_tween.kill()
	_surge_height = 0.0
	_push_surge()


## Distancia (en metros) que le falta al frente de la ola para llegar al punto `world`, o un número grande si no hay ola.
func surge_distance_to(world: Vector2) -> float:
	if _surge_height <= 0.0:
		return 9999.0
	return (world - _surge_origin).dot(_surge_dir) - _surge_pos


func _push_surge() -> void:
	_material.set_shader_parameter("surge_origin", _surge_origin)
	_material.set_shader_parameter("surge_dir", _surge_dir)
	_material.set_shader_parameter("surge_pos", _surge_pos)
	_material.set_shader_parameter("surge_height", _surge_height)
	_material.set_shader_parameter("surge_width", _surge_width)
	_material.set_shader_parameter("surge_lat", _surge_lat)


func _follow() -> void:
	var p: Vector3 = target.global_position
	global_position = Vector3(snappedf(p.x, snap), global_position.y, snappedf(p.z, snap))
