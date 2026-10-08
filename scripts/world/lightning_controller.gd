class_name LightningController
extends Node
## Rayos: la luz que ilumina la escena. Entre rayo y rayo casi no se ve nada.
## Cada rayo hace parpadear una DirectionalLight3D, sube la luz ambiente y el cielo,
## y le avisa a los shaders del agua con el parámetro `flash`.
## No sabe qué hay en la escena: solo recibe qué luz, qué entorno y qué materiales mover.

## Empezó un rayo. `strength` va de 0 a 1.
signal flashed(strength: float)

@export var settings: Memory4Settings
@export var light: DirectionalLight3D
@export var world_environment: WorldEnvironment
## Materiales con un parámetro `flash` (agua, ola).
@export var flash_materials: Array[ShaderMaterial] = []

var is_running: bool = false

var _base_ambient: float = 0.0
var _base_sky: float = 1.0
var _level: float = 0.0
var _loop_id: int = 0
var _tween: Tween = null


func _ready() -> void:
	assert(settings != null and light != null and world_environment != null, "LightningController: faltan referencias en el Inspector")
	_base_ambient = world_environment.environment.ambient_light_energy
	_base_sky = world_environment.environment.background_energy_multiplier
	_apply(0.0)


## Empieza a tirar rayos cada tanto.
func start() -> void:
	if is_running:
		return
	is_running = true
	_loop_id += 1
	_loop(_loop_id)


## Deja de tirar rayos (el que está en curso termina solo).
func stop() -> void:
	is_running = false
	_loop_id += 1


## Rayo inmediato (para momentos de la historia: la ola, el aviso de la tripulación).
func flash_now(strength: float = 1.0) -> void:
	_do_flash(strength)


func _loop(id: int) -> void:
	while is_running and id == _loop_id:
		var wait: float = randf_range(settings.lightning_min_interval, settings.lightning_max_interval)
		await get_tree().create_timer(wait).timeout
		if not is_running or id != _loop_id:
			return
		await _do_flash(randf_range(0.7, 1.0))


func _do_flash(strength: float) -> void:
	# Cada rayo cae desde una dirección distinta, para que las sombras cambien de lugar.
	light.rotation_degrees = Vector3(randf_range(-70.0, -30.0), randf_range(0.0, 360.0), 0.0)
	flashed.emit(strength)
	var time: float = settings.lightning_time
	# Un solo rayo a la vez: si había otro en curso, se corta.
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var tween: Tween = create_tween()
	_tween = tween
	# Dos o tres parpadeos que se apagan: pico, caída, segundo pico, final.
	tween.tween_method(func(v: float) -> void: _apply(v * strength), 0.0, 1.0, time * 0.06)
	tween.tween_method(func(v: float) -> void: _apply(v * strength), 1.0, 0.2, time * 0.14)
	tween.tween_method(func(v: float) -> void: _apply(v * strength), 0.2, 0.75, time * 0.06)
	tween.tween_method(func(v: float) -> void: _apply(v * strength), 0.75, 0.0, time * 0.74) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished


func _apply(level: float) -> void:
	_level = level
	light.light_energy = level * settings.lightning_energy
	var env: Environment = world_environment.environment
	env.ambient_light_energy = _base_ambient + level * settings.lightning_ambient
	env.background_energy_multiplier = _base_sky + level * settings.lightning_sky
	for material: ShaderMaterial in flash_materials:
		material.set_shader_parameter("flash", level)


## Apaga todo y deja la escena a oscuras (bajo el agua).
func blackout() -> void:
	stop()
	_apply(0.0)
