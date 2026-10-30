class_name Memory2Boats
extends Memory
## Memoria 2: los botes en el lago.
## El protagonista (adolescente) pesca con su padre, cada uno en su bote. Lo despierta un trueno:
## la tormenta se viene y hay que seguir la luz del farol del padre hasta la cabaña, remando
## (una tecla por remo) y esquivando rocas, troncos y boyas. Cerca de la cabaña llega una ola gigante,
## el bote se da vuelta, el protagonista cae al agua, se le apaga el farol, ve los flashbacks del accidente
## y el padre lo rescata ("Agarrate. No te suelto.").
## Este script solo ordena la memoria; cada pieza (bote, padre, agua, recorrido, sonido) vive en su clase.

@export var settings: Memory2BoatsSettings
@export var player: Player
@export var boat: RowBoat
@export var father: FatherBoat
@export var course: RowCourse
@export var water: LakeWater
@export var subtitles: SubtitleDisplay
@export var world_environment: WorldEnvironment
@export var lightning: LightningController
## Luz baja del atardecer: se apaga a medida que cierra la tormenta.
@export var sunset_light: DirectionalLight3D
@export var wake_up: WakeUpIntro
@export var flashback: FlashbackOverlay
@export var debug_tools: DebugTools
@export var storm_audio: StormAudio
@export var rain: CPUParticles3D
@export var post_fx: PostFx
## Destello blanco del golpe del agua.
@export var slam_overlay: ColorRect
## Velo azul oscuro de estar bajo el agua.
@export var water_overlay: ColorRect
## Teclas de prueba (8 vuelo, 9 luz de rayo fija, 0 ir a la ola, 7 flashback). Apagar antes de entregar.
@export var debug_keys: bool = true

var _head: Node3D
var _camera: Camera3D
var _voice: AudioStreamPlayer
var _started: bool = false
var _wave_started: bool = false
var _capsizing: bool = false
var _underwater_active: bool = false
var _storm: float = 0.0
## Piso de la tormenta durante el principio (el trueno lejano cierra un poco el cielo antes de remar).
var _intro_storm: float = 0.0
var _progress_max: float = 0.0
var _next_line: int = 0
var _reactive_wait: float = 0.0
var _control_time: float = 0.0
var _tutorial_said: bool = false
var _sky_material: ProceduralSkyMaterial
var _rain_material: StandardMaterial3D
var _rescue_light: SpotLight3D


func _ready() -> void:
	super()
	assert(settings != null and player != null and boat != null and father != null and course != null and water != null, "Memory2Boats: faltan referencias en el Inspector")
	assert(subtitles != null and world_environment != null and lightning != null and wake_up != null and flashback != null, "Memory2Boats: faltan referencias en el Inspector")
	assert(storm_audio != null and slam_overlay != null and water_overlay != null, "Memory2Boats: faltan referencias en el Inspector")
	_head = player.get_node("Head") as Node3D
	_camera = player.get_node("Head/Camera3D") as Camera3D
	# El jugador va sentado en el bote: no camina ni cae. Solo mira con el mouse.
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_physics_process(false)
	_voice = AudioStreamPlayer.new()
	_voice.name = "Voice"
	add_child(_voice)
	_sky_material = world_environment.environment.sky.sky_material as ProceduralSkyMaterial
	if rain != null:
		_rain_material = rain.material_override as StandardMaterial3D
	slam_overlay.modulate.a = 0.0
	slam_overlay.visible = false
	water_overlay.modulate.a = 0.0
	water_overlay.visible = false
	lightning.flashed.connect(storm_audio.on_flash)
	boat.bumped.connect(_on_bumped)
	if debug_tools != null:
		debug_tools.enabled = debug_keys
		debug_tools.skip_requested.connect(_debug_skip_to_wave)
		debug_tools.flashback_requested.connect(func() -> void: flashback.play(1))
		debug_tools.fly_toggled.connect(_on_fly_toggled)
	father.hold()
	if settings.fishing_intro:
		# Padre e hijo pescan, uno al lado del otro. El camino todavía no importa.
		father.progress = settings.fishing_father_ahead
		father.lateral_offset = settings.fishing_father_side
		boat.rod.cast(0.0)
		father.rod.cast(0.0)
	_apply_storm(0.0)
	_begin.call_deferred()


func _begin() -> void:
	if not settings.fishing_intro:
		lightning.start()
	await wake_up.play()
	# WakeUpIntro le devuelve la física al jugador: sentado en el bote no la necesita.
	player.set_physics_process(false)
	player.position = Vector3.ZERO
	if settings.fishing_intro:
		await _fishing_intro()
	if _started:
		return
	_started = true
	boat.control_enabled = true
	father.start_leading()


## Principio en calma: pescan en el atardecer. Después un trueno lejano, el cielo se cierra y hay que volver.
func _fishing_intro() -> void:
	var elapsed: float = 0.0
	for line: FatherLine in settings.fishing_lines:
		if _started:
			return
		await _wait(maxf(line.at_progress - elapsed, 0.0))
		elapsed = maxf(elapsed, line.at_progress)
		if _started:
			return
		_say(line.text, line.voice)
	await _wait(maxf(settings.fishing_time - elapsed, 0.0))
	if _started:
		return
	# Primer trueno, todavía lejos.
	lightning.start()
	lightning.flash_now(0.6)
	create_tween().tween_property(self, "_intro_storm", settings.onset_storm, settings.onset_time)
	await _wait(settings.onset_line_delay)
	if _started:
		return
	_say(settings.onset_line, settings.voice_onset)
	await _wait(settings.onset_control_delay)
	if _started:
		return
	# Guardan las cañas y el padre vuelve al camino.
	boat.rod.stow(1.5)
	father.rod.stow(1.5)
	create_tween().tween_property(father, "lateral_offset", 0.0, settings.fishing_father_return_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout


func _process(delta: float) -> void:
	if rain != null:
		# La lluvia acompaña a la cámara pero siempre cae derecha, aunque el bote se incline.
		rain.global_position = _camera.global_position + Vector3(0.0, 9.0, 0.0)
	if _capsizing:
		return
	var target: float = 1.0 if _wave_started else maxf(_intro_storm, smoothstep(settings.storm_start, settings.storm_full, _fraction()))
	_storm = move_toward(_storm, target, delta * 0.3)
	_apply_storm(_storm)
	if not _started:
		return
	_control_time += delta
	_progress_max = maxf(_progress_max, course.progress_of(boat.plane_position()))
	_say_progress_lines()
	_check_reactive(delta)
	if not _wave_started:
		if _fraction() >= settings.wave_event_progress:
			_start_wave_event()
	elif water.surge_distance_to(boat.plane_position()) < settings.capsize_trigger_distance:
		_capsize()


func _fraction() -> float:
	return clampf(_progress_max / maxf(course.length, 1.0), 0.0, 1.0)


# ---------- Tormenta: del atardecer a la noche ----------

func _apply_storm(s: float) -> void:
	water.set_storm(s)
	storm_audio.set_storm(s)
	var env: Environment = world_environment.environment
	if _sky_material != null:
		var top: Color = settings.sky_top_calm.lerp(settings.sky_top_storm, s)
		var horizon: Color = settings.sky_horizon_calm.lerp(settings.sky_horizon_storm, s)
		_sky_material.sky_top_color = top
		_sky_material.sky_horizon_color = horizon
		_sky_material.ground_horizon_color = horizon.darkened(0.2)
		_sky_material.ground_bottom_color = top.darkened(0.6)
	if not _underwater_active:
		env.fog_light_color = settings.fog_color_calm.lerp(settings.fog_color_storm, s)
		env.fog_density = lerpf(settings.fog_density_calm, settings.fog_density_storm, s)
		lightning.set_base_levels(lerpf(settings.ambient_calm, settings.ambient_storm, s), lerpf(settings.sky_calm, settings.sky_storm, s))
	lightning.interval_scale = lerpf(settings.lightning_interval_calm, settings.lightning_interval_storm, s)
	if sunset_light != null:
		sunset_light.light_energy = settings.sunset_energy * (1.0 - smoothstep(0.0, 0.55, s))
	if _rain_material != null:
		var c: Color = _rain_material.albedo_color
		c.a = lerpf(0.0, 0.4, lerpf(settings.rain_calm, settings.rain_storm, s))
		_rain_material.albedo_color = c
	if post_fx != null:
		post_fx.set_lens_wet(settings.lens_wet_storm * s)


# ---------- El padre habla ----------

func _say(text: String, voice: AudioStream) -> void:
	subtitles.show_line(text, settings.line_duration)
	if voice != null:
		_voice.stream = voice
		_voice.volume_db = settings.voice_db
		_voice.play()


func _say_progress_lines() -> void:
	while _next_line < settings.father_lines.size() and _fraction() >= settings.father_lines[_next_line].at_progress:
		var line: FatherLine = settings.father_lines[_next_line]
		_next_line += 1
		# Las frases por avance no pisan a la ola.
		if not _wave_started:
			_say(line.text, line.voice)
			_reactive_wait = maxf(_reactive_wait, 4.0)


func _check_reactive(delta: float) -> void:
	_reactive_wait = maxf(_reactive_wait - delta, 0.0)
	if _reactive_wait > 0.0 or _wave_started:
		return
	var off: float = course.distance_to_path(boat.plane_position())
	if off > boat.settings.soft_corridor * 0.75:
		_say(settings.off_course_line, settings.voice_off_course)
		_reactive_wait = settings.reactive_cooldown
	elif father.is_waiting:
		_say(settings.behind_line, settings.voice_behind)
		_reactive_wait = settings.reactive_cooldown
	elif not _tutorial_said and _control_time > settings.tutorial_hint_after and boat.alternations < 2:
		_tutorial_said = true
		_say(settings.tutorial_line, settings.voice_tutorial)
		_reactive_wait = settings.reactive_cooldown


func _on_bumped(_strength: float, kind: int) -> void:
	if _wave_started:
		return
	var text: String = settings.log_hit_text if kind == RowObstacle.Kind.LOG else settings.rock_hit_text
	subtitles.show_line(text, 1.6)
	if _reactive_wait <= 0.0 and randf() < 0.45:
		_reactive_wait = settings.reactive_cooldown
		get_tree().create_timer(1.1).timeout.connect(func() -> void:
			if not _wave_started:
				_say(settings.bump_line, settings.voice_bump))


# ---------- La ola ----------

func _start_wave_event() -> void:
	if _wave_started:
		return
	_wave_started = true
	father.hold()
	_say(settings.wave_line, settings.voice_wave)
	lightning.long_flash(settings.wave_flash_time, 1.0)
	_play_sfx(settings.sfx_wave_roar, 0.0)
	var forward: Vector2 = boat.forward_2d()
	var start: Vector2 = boat.plane_position() + forward * settings.wave_start_distance
	water.launch_surge(start, -forward, settings.wave_start_distance + 8.0, settings.wave_travel_time,
			settings.wave_height, settings.wave_width, settings.wave_lateral)


func _capsize() -> void:
	if _capsizing:
		return
	_capsizing = true
	boat.control_enabled = false
	boat.stop_dead()
	boat.frozen = true
	lightning.flash_now(1.0)
	_play_sfx(settings.sfx_capsize, 2.0)
	_slam(0.9)
	# El bote se da vuelta con el protagonista adentro.
	var flip: Tween = create_tween().set_parallel(true)
	flip.tween_property(boat, "extra_roll", deg_to_rad(settings.capsize_roll), settings.capsize_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flip.tween_property(boat, "extra_sink", 0.7, settings.capsize_time)
	flip.tween_property(_head, "rotation:x", deg_to_rad(-12.0), settings.capsize_time)
	await flip.finished
	_play_sfx(settings.sfx_gasp, -4.0)
	player.reparent(self, true)
	await _sink_and_rescue()


# ---------- Final: bajo el agua ----------

func _sink_and_rescue() -> void:
	var env: Environment = world_environment.environment
	_set_underwater(env)
	_slam(0.8)
	# 1. Se hunde, desorientado.
	var surface_y: float = water.height_at(player.global_position.x, player.global_position.z)
	var fall: Tween = create_tween().set_parallel(true)
	fall.tween_property(player, "global_position:y", surface_y - settings.underwater_depth, settings.fall_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fall.tween_property(player, "rotation:z", 0.0, settings.fall_time)
	fall.tween_property(player, "rotation:x", 0.0, settings.fall_time)
	fall.tween_property(_head, "rotation:x", deg_to_rad(-30.0), settings.fall_time)
	await fall.finished
	water.clear_surge()
	_heartbeat_loop.call_deferred()

	# 2. El farol se le cae y se hunde, apagándose.
	var lantern: Node3D = boat.get_lantern()
	var forward: Vector3 = -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	if lantern != null:
		lantern.reparent(self, true)
		lantern.rotation = Vector3.ZERO
		lantern.global_position = _camera.global_position + forward * 1.8 + Vector3(0.0, 0.5, 0.0)
		var lamp: OmniLight3D = lantern.get_node_or_null("LanternLight") as OmniLight3D
		var start_energy: float = lamp.light_energy if lamp != null else 0.0
		var sink: Tween = create_tween().set_parallel(true)
		sink.tween_property(lantern, "global_position", lantern.global_position + Vector3(0.3, -settings.lantern_sink_depth, -0.6), settings.lantern_sink_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		sink.tween_property(lantern, "rotation", Vector3(-1.4, 2.6, 0.8), settings.lantern_sink_time)
		sink.tween_property(_head, "rotation:x", deg_to_rad(-55.0), settings.lantern_sink_time * 0.6)
		if lamp != null:
			sink.tween_method(func(k: float) -> void:
				var flicker: float = 1.0 if k < 0.55 else (0.25 + 0.75 * float(randf() > k * 0.7))
				lamp.light_energy = start_energy * 3.0 * (1.0 - k) * flicker, 0.0, 1.0, settings.lantern_sink_time)
		await sink.finished
		lantern.visible = false

	# 3. Oscuridad total y los flashbacks del accidente.
	lightning.stop()
	lightning.set_base_levels(0.0, 0.0)
	env.ambient_light_energy = 0.0
	await get_tree().create_timer(settings.dark_time).timeout
	await flashback.play(settings.ending_flashbacks, true)
	flashback.clear()

	# 4. El barquito sube encendido, con la caja de música.
	_play_music()
	var toy: Node3D = boat.get_toy_boat()
	if toy != null:
		toy.reparent(self, true)
		toy.visible = true
		toy.rotation = Vector3.ZERO
		toy.scale = Vector3.ONE * 2.5
		for child: Node in toy.find_children("*", "OmniLight3D", true, false):
			(child as OmniLight3D).light_energy = 3.0
		toy.global_position = _camera.global_position + forward * 1.4 + Vector3.DOWN * 1.2
		var rise: Tween = create_tween().set_parallel(true)
		rise.tween_property(toy, "global_position", _camera.global_position + forward * 1.3 + Vector3.UP * 0.75, settings.boat_rise_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		rise.tween_property(toy, "rotation:y", 1.2, settings.boat_rise_time)
		rise.tween_property(_head, "rotation:x", deg_to_rad(32.0), settings.boat_rise_time)
		await rise.finished

	# 5. La luz del padre desde arriba, su mano y su voz.
	_rescue(env, forward, surface_y)
	_say(settings.rescue_line, settings.voice_rescue)
	await get_tree().create_timer(settings.father_light_time).timeout
	_play_sfx(settings.sfx_hand, 0.0)
	await get_tree().create_timer(0.5).timeout
	await ScreenFade.fade_out(settings.end_fade_time)
	_underwater_active = false
	complete()


func _rescue(env: Environment, forward: Vector3, surface_y: float) -> void:
	_rescue_light = SpotLight3D.new()
	_rescue_light.name = "FatherLight"
	_rescue_light.light_color = Color(1.0, 0.85, 0.6)
	_rescue_light.light_energy = 0.0
	_rescue_light.spot_range = 18.0
	_rescue_light.spot_angle = 38.0
	_rescue_light.spot_attenuation = 0.8
	add_child(_rescue_light)
	_rescue_light.global_position = Vector3(_camera.global_position.x, surface_y - 0.15, _camera.global_position.z) + forward * 1.2
	_rescue_light.look_at(_camera.global_position + Vector3.DOWN * 1.0, Vector3.FORWARD)
	var glow: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(2.4, 2.4)
	glow.mesh = quad
	var gm: StandardMaterial3D = StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	gm.disable_fog = true
	gm.albedo_texture = _soft_texture()
	gm.albedo_color = Color(1.0, 0.82, 0.55, 0.9)
	glow.material_override = gm
	glow.scale = Vector3.ONE * 0.05
	_rescue_light.add_child(glow)
	var light_in: Tween = create_tween().set_parallel(true)
	light_in.tween_property(_rescue_light, "light_energy", settings.father_light_energy, settings.father_light_time)
	light_in.tween_property(glow, "scale", Vector3.ONE, settings.father_light_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# La mano baja desde el agujero de luz.
	var hand: Node3D = _make_hand()
	add_child(hand)
	var hand_end: Vector3 = _camera.global_position + forward * 0.95 + Vector3.UP * 0.55
	hand.global_position = hand_end + Vector3.UP * 1.4 + forward * 0.5
	hand.look_at(hand.global_position + forward, Vector3.UP)
	hand.rotate_object_local(Vector3.RIGHT, deg_to_rad(-25.0))
	create_tween().tween_property(hand, "global_position", hand_end, settings.father_light_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _make_hand() -> Node3D:
	var hand: Node3D = Node3D.new()
	hand.name = "FatherHand"
	var skin: StandardMaterial3D = StandardMaterial3D.new()
	skin.albedo_color = Color(0.5, 0.36, 0.28)
	skin.roughness = 0.8
	var sleeve: StandardMaterial3D = StandardMaterial3D.new()
	sleeve.albedo_color = Color(0.5, 0.42, 0.12)
	sleeve.roughness = 0.7
	var arm: MeshInstance3D = MeshInstance3D.new()
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.055
	cap.height = 0.8
	cap.radial_segments = 8
	cap.rings = 3
	arm.mesh = cap
	arm.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	arm.position = Vector3(0.0, 0.0, 0.45)
	arm.material_override = sleeve
	hand.add_child(arm)
	var palm: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.1, 0.035, 0.1)
	palm.mesh = box
	palm.position = Vector3(0.0, 0.0, -0.04)
	palm.material_override = skin
	hand.add_child(palm)
	for i: int in 4:
		var finger: MeshInstance3D = MeshInstance3D.new()
		var fm: BoxMesh = BoxMesh.new()
		fm.size = Vector3(0.022, 0.022, 0.085)
		finger.mesh = fm
		finger.position = Vector3(-0.036 + float(i) * 0.024, 0.0, -0.13)
		finger.rotation.x = deg_to_rad(-12.0)
		finger.material_override = skin
		hand.add_child(finger)
	return hand


func _soft_texture() -> Texture2D:
	var g: Gradient = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
	var t: GradientTexture2D = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


## Bajo el agua: niebla oscura que se come todo, sin cielo, sin lluvia, sin los sonidos de arriba.
func _set_underwater(env: Environment) -> void:
	_underwater_active = true
	env.fog_enabled = true
	env.fog_light_color = settings.underwater_fog_color
	env.fog_density = settings.underwater_fog_density
	lightning.set_held(false)
	lightning.set_sky_visible(false)
	lightning.set_base_levels(0.02, 0.0)
	env.background_energy_multiplier = 0.0
	env.ambient_light_energy = 0.02
	if rain != null:
		rain.visible = false
	storm_audio.set_underwater(true)
	water_overlay.visible = true
	create_tween().tween_property(water_overlay, "modulate:a", 0.45, 0.8)
	if sunset_light != null:
		sunset_light.light_energy = 0.0
	if father != null:
		father.visible = false


func _heartbeat_loop() -> void:
	var interval: float = 60.0 / settings.heartbeat_bpm
	while _underwater_active and is_inside_tree():
		_play_sfx(settings.sfx_heartbeat, 0.0)
		await get_tree().create_timer(interval).timeout


func _play_music() -> void:
	if settings.music_lullaby == null:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = settings.music_lullaby
	p.volume_db = settings.music_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _play_sfx(stream: AudioStream, offset_db: float) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = settings.sfx_db + offset_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Golpe de luz blanca (el agua que pega en la cara).
func _slam(strength: float) -> void:
	slam_overlay.visible = true
	slam_overlay.modulate.a = strength
	var t: Tween = create_tween()
	t.tween_property(slam_overlay, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: slam_overlay.visible = false)


# ---------- Teclas de prueba ----------

func _on_fly_toggled(is_on: bool) -> void:
	boat.frozen = is_on
	boat.control_enabled = _started and not is_on and not _capsizing
	if not is_on:
		# Al soltar el vuelo, el jugador vuelve a su asiento (DebugTools le prendió la física).
		player.set_physics_process(false)
		if not _capsizing:
			player.position = Vector3.ZERO


## SOLO PARA PRUEBAS (tecla 0): salta al tramo de la ola y la dispara.
func _debug_skip_to_wave() -> void:
	if _wave_started:
		return
	if debug_tools != null and debug_tools.is_flying:
		debug_tools.set_flying(false)
	var d: float = course.length * settings.wave_event_progress - 10.0
	boat.teleport(course.point_at(d), course.tangent_at(d))
	father.progress = d + 15.0
	father.lateral_offset = 0.0
	boat.rod.stow(0.0)
	father.rod.stow(0.0)
	lightning.start()
	_progress_max = d
	_started = true
	boat.control_enabled = true
	_start_wave_event()
