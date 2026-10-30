class_name Passage
extends Memory
## Pasaje entre dos memorias: el jugador camina sobre un mar quieto, bajo un cielo negro, hacia
## una luz lejana que no sabe qué es. Mientras avanza escucha voces del hospital y, cuando hablan,
## se encienden unas luces cálidas grandes arriba a los costados: las luces del presente. Su brillo
## sigue el volumen de la voz, como la luz de un parlante (sin audio, imita el ritmo del habla).
## Al llegar a la luz se completa y GameFlow carga la memoria siguiente.
## Se arma casi todo por código desde su PassageSettings, así cada pasaje es la misma escena
## con otro .tres (otras voces, otra distancia, otra luz).
## El camino va desde donde empieza el jugador hacia adonde mira (su -Z).

## Sonó una voz del hospital (índice dentro de `settings.voices`).
signal voice_heard(index: int)
## El jugador llegó a la luz del final.
signal goal_reached

const GLOW_SHADER: Shader = preload("res://assets/shaders/soft_glow.gdshader")

@export var settings: PassageSettings
@export var player: Player
@export var subtitles: SubtitleDisplay
@export var ocean: OceanFollow
@export var world_environment: WorldEnvironment
## Por donde suenan las voces (si tienen audio).
@export var voice_player: AudioStreamPlayer

## Cuánto del camino recorrió el jugador (0 a 1).
var progress: float = 0.0
## Cuántas voces sonaron.
var voices_heard: int = 0

var _start: Vector3
var _forward: Vector3
var _goal: Node3D
var _goal_light: OmniLight3D
var _goal_glow: MeshInstance3D
var _goal_material: ShaderMaterial
var _goal_quad: QuadMesh
var _voice_root: Node3D
var _voice_lights: Array[OmniLight3D] = []
var _voice_materials: Array[ShaderMaterial] = []
## 0 a 1: el brillo de las luces de las voces (sigue al volumen con subida y caída).
var voice_level: float = 0.0
## La voz que está sonando sin audio: hasta cuándo dura su imitación del habla.
var _fake_until: float = -1.0
var _fake_start: float = 0.0
var _speech_noise: FastNoiseLite
var _word_noise: FastNoiseLite
var _bus_index: int = -1
var _time: float = 0.0

const VOICE_BUS: StringName = &"PassageVoices"


func _ready() -> void:
	super()
	assert(settings != null and player != null and subtitles != null and ocean != null and world_environment != null,
		"Passage: faltan referencias en el Inspector (settings, player, subtitles, ocean, world_environment)")
	_start = player.global_position
	_start.y = settings.water_level
	_forward = -player.global_basis.z
	_forward.y = 0.0
	_forward = _forward.normalized() if _forward.length() > 0.01 else Vector3.FORWARD
	_apply_environment()
	_apply_ocean()
	_build_floor()
	_build_walls()
	_setup_voice_bus()
	_build_voice_lights()
	_build_goal()
	_update_lights(0.0)


func _process(delta: float) -> void:
	_time += delta
	var walked: float = (player.global_position - _start).dot(_forward)
	progress = clampf(walked / settings.path_length, 0.0, 1.0)
	while voices_heard < settings.voices.size() and progress >= settings.voices[voices_heard].at_progress:
		_play_voice(voices_heard)
	_update_lights(delta)
	if not is_completed:
		var to_goal: Vector3 = _goal.global_position - player.global_position
		to_goal.y = 0.0
		if to_goal.length() <= settings.end_radius:
			goal_reached.emit()
			complete()


## Suena una voz: subtítulo y audio (si tiene). Sin audio, las luces imitan el habla mientras dura.
func _play_voice(index: int) -> void:
	var voice: PassageVoice = settings.voices[index]
	voices_heard = index + 1
	if voice != null:
		subtitles.show_line(voice.text, voice.duration)
		if voice.stream != null and voice_player != null:
			voice_player.stream = voice.stream
			voice_player.play()
		else:
			_fake_start = _time
			_fake_until = _time + voice.duration * 0.85
	voice_heard.emit(index)


## Qué tan fuerte suena la voz ahora (0 a 1).
func _voice_loudness() -> float:
	var loud: float = 0.0
	if voice_player != null and voice_player.playing and _bus_index >= 0:
		var analyzer: AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(_bus_index, 0) as AudioEffectSpectrumAnalyzerInstance
		if analyzer != null:
			var mag: Vector2 = analyzer.get_magnitude_for_frequency_range(80.0, 5000.0)
			var db: float = linear_to_db(maxf(mag.x, mag.y))
			loud = clampf(inverse_lerp(settings.voice_min_db, settings.voice_max_db, db), 0.0, 1.0)
	if _time < _fake_until:
		# Sílabas que suben y bajan, con pausas entre palabras, y que entran y salen suaves.
		var syll: float = smoothstep(-0.15, 0.45, _speech_noise.get_noise_1d(_time * settings.fake_syllable_rate * 10.0))
		var word: float = smoothstep(-0.35, 0.05, _word_noise.get_noise_1d(_time * settings.fake_word_rate * 10.0))
		var span: float = _fake_until - _fake_start
		var shape: float = smoothstep(0.0, 0.25, _time - _fake_start) * smoothstep(0.0, 0.35, _fake_until - _time)
		loud = maxf(loud, (0.35 + 0.65 * syll) * word * shape if span > 0.0 else 0.0)
	return loud


func _update_lights(delta: float) -> void:
	var target: float = _voice_loudness()
	var time_const: float = settings.voice_attack if target > voice_level else settings.voice_release
	voice_level = target if delta <= 0.0 else lerpf(voice_level, target, 1.0 - exp(-delta / time_const))
	var level: float = settings.voice_idle_level + (1.0 - settings.voice_idle_level) * voice_level
	_place_voice_lights()
	for i: int in _voice_lights.size():
		_voice_lights[i].light_energy = settings.voice_light_energy * level
		_voice_lights[i].visible = level > 0.001
		_voice_materials[i].set_shader_parameter("energy", settings.voice_glow_energy * level)
	if _goal != null:
		var pulse: float = 1.0 + settings.goal_pulse * sin(_time * settings.goal_pulse_rate * TAU)
		var grow: float = lerpf(1.0, settings.goal_glow_growth, progress)
		_goal_quad.size = Vector2.ONE * settings.goal_glow_size * grow * (1.0 + (pulse - 1.0) * 0.5)
		_goal_material.set_shader_parameter("energy", settings.goal_glow_energy * pulse)
		_goal_light.light_energy = settings.goal_light_energy * pulse


## Las luces de las voces acompañan al jugador (en la dirección del camino, no de la mirada).
func _place_voice_lights() -> void:
	if _voice_root == null:
		return
	var base: Vector3 = player.global_position
	base.y = settings.water_level
	_voice_root.global_transform = Transform3D(Basis.looking_at(_forward, Vector3.UP), base)


# ---------- Armado ----------

## Cielo negro, sin luz ambiente, y niebla negra que se come el mar a lo lejos.
func _apply_environment() -> void:
	var env: Environment = world_environment.environment
	if env == null:
		env = Environment.new()
		world_environment.environment = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.ambient_light_energy = 0.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.fog_enabled = settings.fog_density > 0.0
	env.fog_light_color = Color.BLACK
	env.fog_light_energy = 0.0
	env.fog_density = settings.fog_density
	env.fog_sky_affect = 1.0


## El océano de la M4, casi sin olas y sin reflejar ningún cielo.
func _apply_ocean() -> void:
	ocean.target = player
	ocean.global_position = Vector3(_start.x, settings.water_level, _start.z)
	var mat: ShaderMaterial = ocean.material_override as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("wave_height", settings.wave_height)
	mat.set_shader_parameter("chop", settings.wave_chop)
	mat.set_shader_parameter("far_scale", 1.0)
	mat.set_shader_parameter("big_swell_near", settings.wave_swell)
	mat.set_shader_parameter("big_swell_far", settings.wave_swell)
	mat.set_shader_parameter("foam_amount", 0.0)
	mat.set_shader_parameter("foam_streaks", 0.0)
	mat.set_shader_parameter("slate_strength", 0.0)
	mat.set_shader_parameter("reflect_strength", 0.0)
	mat.set_shader_parameter("night_reflect", 0.0)
	mat.set_shader_parameter("spot_lit_color", settings.water_lit_color)
	mat.set_shader_parameter("spot_lit_strength", settings.water_lit_strength)
	mat.set_shader_parameter("spot_glint", settings.water_glint)
	mat.set_shader_parameter("look_down_black", settings.water_look_down_black)


## Piso invisible a la altura del agua: se camina sobre el mar.
func _build_floor() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "WaterFloor"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(shape)
	add_child(floor_body)
	floor_body.global_position = Vector3(0.0, settings.water_level, 0.0)


## Paredes invisibles a los costados y atrás, para no perderse en la oscuridad.
func _build_walls() -> void:
	var length: float = settings.path_length + 20.0
	var side: Vector3 = _forward.cross(Vector3.UP).normalized()
	var center: Vector3 = _start + _forward * (settings.path_length * 0.5)
	_add_wall("WallLeft", center - side * settings.corridor_half_width, Vector3(0.5, 6.0, length))
	_add_wall("WallRight", center + side * settings.corridor_half_width, Vector3(0.5, 6.0, length))
	_add_wall("WallBack", _start - _forward * 2.0, Vector3(settings.corridor_half_width * 2.0, 6.0, 0.5))


func _add_wall(wall_name: String, at: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = wall_name
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_transform = Transform3D(Basis.looking_at(_forward, Vector3.UP), at + Vector3.UP * size.y * 0.5)


## Un bus de audio propio (creado al vuelo, no toca el layout del proyecto) para medir el volumen
## de las voces con un analizador.
func _setup_voice_bus() -> void:
	_speech_noise = FastNoiseLite.new()
	_speech_noise.seed = 7
	_speech_noise.frequency = 0.1
	_word_noise = FastNoiseLite.new()
	_word_noise.seed = 21
	_word_noise.frequency = 0.1
	if voice_player == null:
		return
	_bus_index = AudioServer.get_bus_index(VOICE_BUS)
	if _bus_index == -1:
		_bus_index = AudioServer.bus_count
		AudioServer.add_bus(_bus_index)
		AudioServer.set_bus_name(_bus_index, VOICE_BUS)
		AudioServer.set_bus_send(_bus_index, &"Master")
		AudioServer.add_bus_effect(_bus_index, AudioEffectSpectrumAnalyzer.new())
	voice_player.bus = VOICE_BUS


## Las luces de las voces: grandes, tenues, arriba a los costados del jugador. Apagadas al empezar.
func _build_voice_lights() -> void:
	_voice_root = Node3D.new()
	_voice_root.name = "VoiceLights"
	add_child(_voice_root)
	for offset: Vector3 in settings.voice_light_offsets:
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = settings.voice_light_color
		light.omni_range = settings.voice_light_range
		light.omni_attenuation = 0.5
		light.light_energy = 0.0
		light.shadow_enabled = false
		# En el nodo raíz, -Z es la dirección del camino: z del offset positivo = adelante.
		light.position = Vector3(offset.x, offset.y, -offset.z)
		_voice_root.add_child(light)
		var glow: MeshInstance3D = _make_glow(settings.voice_light_color, settings.voice_glow_size)
		light.add_child(glow)
		_voice_lights.append(light)
		_voice_materials.append(glow.material_override as ShaderMaterial)


## La luz del final: un brillo que no se sabe qué es.
func _build_goal() -> void:
	_goal = Node3D.new()
	_goal.name = "Goal"
	add_child(_goal)
	_goal.global_position = _start + _forward * settings.path_length + Vector3.UP * settings.goal_height
	_goal_light = OmniLight3D.new()
	_goal_light.light_color = settings.goal_color
	_goal_light.omni_range = settings.goal_light_range
	_goal_light.omni_attenuation = 1.2
	_goal.add_child(_goal_light)
	_goal_glow = _make_glow(settings.goal_color, 1.0)
	_goal.add_child(_goal_glow)
	_goal_material = _goal_glow.material_override as ShaderMaterial
	_goal_quad = _goal_glow.mesh as QuadMesh


## Un halo aditivo que mira siempre a la cámara (no lo afecta la niebla). El tamaño va en el
## QuadMesh porque el billboard del shader ignora la escala del nodo.
func _make_glow(color: Color, size: float) -> MeshInstance3D:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * size
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GLOW_SHADER
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("energy", 0.0)
	mat.set_shader_parameter("falloff", 2.4)
	mat.set_shader_parameter("billboard", 1.0)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh
