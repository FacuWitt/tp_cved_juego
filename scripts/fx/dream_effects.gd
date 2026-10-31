class_name DreamEffects
extends CanvasLayer
## Hace que una memoria se sienta soñada: la imagen ondula y se desenfoca en los bordes, la cámara
## se mece, el campo de visión respira, las piernas pesan al querer avanzar, a veces dejan de
## responder (se frena y, si sigue empujando, lo arrastra hacia atrás) y cada tanto hay un
## parpadeo (en el negro, las cosas pueden cambiar de lugar: lo escucha DreamShifter).
## Al girar, la imagen deja una estela. Todo se oye apagado y con eco, como bajo el agua (pone
## efectos en el bus Master solo mientras sueña y los saca al terminar o al salir de la escena).
## No sabe en qué memoria está: la memoria le dice cuánto soñar (`level`), cuánto le cuesta
## avanzar al jugador ahora (`drag`) y hacia dónde es "atrás" (`pull_direction`).
## Va debajo de la interfaz (subtítulos, mira).

const SHADER: Shader = preload("res://assets/shaders/dream_haze.gdshader")

## Hubo un parpadeo: la pantalla está en negro en este momento.
signal blinked
## Las piernas dejaron de responder.
signal stuck_started

@export var settings: DreamSettings
@export var player: Player

## Cuánto sueño hay (0 = real, 1 = lo máximo). Lo pone la memoria.
var level: float = 0.0
## Cuánto le cuesta avanzar al jugador ahora (0 = nada, 1 = lo máximo). Lo pone la memoria.
var drag: float = 0.0
## Hacia dónde lo arrastra el pasillo cuando las piernas no responden (global). Cero = no lo arrastra.
var pull_direction: Vector3 = Vector3.ZERO
var is_active: bool = false

var _material: ShaderMaterial
var _camera: Camera3D
var _time: float = 0.0
var _intensity: float = 0.0
var _drag: float = 0.0
var _blackout: float = 0.0
var _blink_wait: float = 0.0
var _stuck_time: float = 0.0
var _stuck_cooldown: float = 0.0
var _base_fov: float = 75.0
var _own_settings: PlayerSettings
var _slow_settings: PlayerSettings
## Estela: hacia dónde se corre la imagen al girar (fracción de pantalla por segundo, suavizado).
var _trail_velocity: Vector2 = Vector2.ZERO
var _last_forward: Vector3 = Vector3.ZERO
## Efectos de "bajo el agua" puestos en el bus Master mientras sueña (se sacan al terminar).
var _lowpass: AudioEffectLowPassFilter
var _echo: AudioEffectReverb


func _ready() -> void:
	assert(settings != null and player != null, "DreamEffects: faltan el DreamSettings y el Player")
	layer = 0
	_camera = player.get_node("Head/Camera3D") as Camera3D
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var rect: ColorRect = ColorRect.new()
	rect.name = "Screen"
	rect.material = _material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	_reset_blink_wait()


## Empieza a soñar (después del despertar, cuando el jugador ya tiene el control).
func start() -> void:
	if is_active:
		return
	is_active = true
	_base_fov = _camera.fov
	# Para que las piernas pesen sin tocar el Resource compartido del jugador, usa una copia.
	_own_settings = player.settings
	_slow_settings = _own_settings.duplicate() as PlayerSettings
	player.settings = _slow_settings
	_last_forward = Vector3.ZERO
	_add_underwater()


## Deja de soñar: devuelve la cámara, la velocidad del jugador y el sonido a lo normal.
func stop() -> void:
	if not is_active:
		return
	is_active = false
	if _own_settings != null:
		player.settings = _own_settings
	_camera.fov = _base_fov
	_camera.rotation.z = 0.0
	_intensity = 0.0
	_drag = 0.0
	_stuck_time = 0.0
	_trail_velocity = Vector2.ZERO
	_remove_underwater()
	_apply_shader()


func _exit_tree() -> void:
	# El bus Master es de todo el juego: el efecto no puede quedar puesto en la escena siguiente.
	_remove_underwater()


## Si las piernas están trabadas ahora mismo.
func is_stuck() -> bool:
	return _stuck_time > 0.0


func _process(delta: float) -> void:
	_time += delta
	if not is_active:
		_apply_shader()
		return
	var target: float = clampf(level * settings.level_gain, 0.0, 1.0)
	_intensity = move_toward(_intensity, target, settings.level_follow * delta)
	_drag = move_toward(_drag, clampf(drag, 0.0, 1.0), settings.drag_follow * delta)
	_update_stuck(delta)
	_update_camera()
	_update_legs()
	_update_blinks(delta)
	_update_trail(delta)
	_update_underwater()
	_apply_shader()


## La estela sigue al giro de la cámara: dónde quedó, en la pantalla de ahora, lo que antes estaba
## en el centro. Al dejar de girar se apaga de a poco (la imagen tarda en alcanzarlo).
func _update_trail(delta: float) -> void:
	var forward: Vector3 = -_camera.global_basis.z
	var instant: Vector2 = Vector2.ZERO
	if _last_forward != Vector3.ZERO and delta > 0.0:
		var seen: Vector3 = _camera.global_basis.inverse() * _last_forward
		if seen.z < 0.0:
			var v_fov: float = deg_to_rad(_camera.fov)
			var aspect: float = get_viewport().get_visible_rect().size.aspect()
			var h_fov: float = 2.0 * atan(tan(v_fov * 0.5) * aspect)
			var shift: Vector2 = Vector2(atan2(seen.x, -seen.z) / h_fov, -atan2(seen.y, -seen.z) / v_fov)
			# Un salto enorme es un traslado (umbral, tecla de prueba), no un giro: no deja estela.
			if shift.length() < 0.25:
				instant = shift / delta
	_last_forward = forward
	if instant.length() > _trail_velocity.length():
		_trail_velocity = instant
	else:
		_trail_velocity = _trail_velocity.lerp(instant, 1.0 - exp(-settings.trail_decay * delta))


func _add_underwater() -> void:
	if not settings.underwater_enabled or _lowpass != null:
		return
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	_echo = AudioEffectReverb.new()
	_echo.wet = 0.0
	_echo.dry = 1.0
	_echo.room_size = settings.underwater_echo_size
	AudioServer.add_bus_effect(0, _lowpass)
	AudioServer.add_bus_effect(0, _echo)


func _remove_underwater() -> void:
	for effect: AudioEffect in [_echo, _lowpass]:
		if effect == null:
			continue
		for i: int in range(AudioServer.get_bus_effect_count(0) - 1, -1, -1):
			if AudioServer.get_bus_effect(0, i) == effect:
				AudioServer.remove_bus_effect(0, i)
	_lowpass = null
	_echo = null


## Cuanto más sueño, más apagado (sin agudos) y con más eco se oye todo, como con la cabeza bajo el agua.
func _update_underwater() -> void:
	if _lowpass == null:
		return
	var k: float = _intensity if settings.underwater_enabled else 0.0
	# El corte se mueve en escala logarítmica, que es como lo escucha el oído.
	_lowpass.cutoff_hz = exp(lerpf(log(20000.0), log(settings.underwater_cutoff), k))
	_echo.wet = settings.underwater_echo * k
	_echo.room_size = settings.underwater_echo_size


func _update_camera() -> void:
	if not settings.sway_enabled:
		_camera.fov = _base_fov
		_camera.rotation.z = 0.0
		return
	var roll: float = sin(_time * TAU / settings.sway_period) * settings.sway_roll * _intensity
	if is_stuck():
		# Forcejea: la cámara tiembla.
		roll += sin(_time * settings.stuck_shake_speed) * settings.stuck_shake
	_camera.rotation.z = deg_to_rad(roll)
	var breath: float = sin(_time * TAU / settings.fov_breath_period) * settings.fov_breath * _intensity
	_camera.fov = _base_fov + breath + settings.vertigo_fov * _drag * _intensity


func _update_legs() -> void:
	var factor: float = 1.0
	if settings.heavy_legs_enabled:
		factor = lerpf(1.0, settings.min_speed_factor, _drag * _intensity)
	if is_stuck():
		factor = 0.0
	_slow_settings.walk_speed = _own_settings.walk_speed * factor
	var sprint: float = _own_settings.sprint_speed if settings.sprint_helps else _own_settings.walk_speed
	_slow_settings.sprint_speed = sprint * factor


func _update_stuck(delta: float) -> void:
	_stuck_cooldown = maxf(_stuck_cooldown - delta, 0.0)
	if is_stuck():
		_stuck_time -= delta
		return
	if not settings.stuck_enabled or _stuck_cooldown > 0.0 or _drag < settings.stuck_min_drag or not _wants_forward():
		return
	if randf() < settings.stuck_chance * _intensity * delta:
		_stuck_time = settings.stuck_duration
		_stuck_cooldown = settings.stuck_duration + settings.stuck_cooldown
		stuck_started.emit()


func _physics_process(delta: float) -> void:
	# Trabado y empujando hacia adelante: camina en el lugar y el pasillo lo lleva para atrás.
	if is_active and is_stuck() and _wants_forward() and pull_direction != Vector3.ZERO:
		var pull: Vector3 = Vector3(pull_direction.x, 0.0, pull_direction.z).normalized()
		player.move_and_collide(pull * settings.stuck_pull_speed * delta)


func _wants_forward() -> bool:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back").y < -0.3


func _update_blinks(delta: float) -> void:
	if not settings.blinks_enabled or _intensity <= 0.01:
		return
	# Con menos sueño, los parpadeos llegan más espaciados.
	_blink_wait -= delta * _intensity
	if _blink_wait <= 0.0:
		_reset_blink_wait()
		blink()


## Un parpadeo: negro un instante. En el medio avisa con `blinked`.
func blink() -> void:
	var half: float = settings.blink_duration * 0.5
	var t: Tween = create_tween()
	t.tween_property(self, "_blackout", 1.0, half * 0.6)
	t.tween_callback(func() -> void: blinked.emit())
	t.tween_interval(half * 0.4)
	t.tween_property(self, "_blackout", 0.0, half)


func _reset_blink_wait() -> void:
	_blink_wait = randf_range(settings.blink_min_interval, settings.blink_max_interval)


func _apply_shader() -> void:
	var haze: float = _intensity if settings.haze_enabled else 0.0
	_material.set_shader_parameter("intensity", haze)
	_material.set_shader_parameter("time", _time)
	_material.set_shader_parameter("blackout", _blackout)
	_material.set_shader_parameter("wave_amount", settings.wave_amount)
	_material.set_shader_parameter("wave_frequency", settings.wave_frequency)
	_material.set_shader_parameter("wave_speed", settings.wave_speed)
	_material.set_shader_parameter("edge_blur", settings.edge_blur)
	_material.set_shader_parameter("aberration", settings.aberration)
	_material.set_shader_parameter("ghost_offset", settings.ghost_offset)
	_material.set_shader_parameter("ghost_mix", settings.ghost_mix)
	_material.set_shader_parameter("vignette", settings.vignette)
	_material.set_shader_parameter("desaturation", settings.desaturation)
	_material.set_shader_parameter("tint", settings.tint)
	var trail: Vector2 = Vector2.ZERO
	if settings.trail_enabled and is_active:
		trail = (_trail_velocity * settings.trail_length).limit_length(settings.trail_max)
	_material.set_shader_parameter("trail", trail)
	_material.set_shader_parameter("trail_mix", settings.trail_mix * _intensity)
