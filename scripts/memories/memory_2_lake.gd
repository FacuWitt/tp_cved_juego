class_name Memory2Lake
extends Memory
## Memoria 2: el lago y el río.
## El protagonista (adolescente) pesca con su padre en un lago, cada uno en su bote. Lo despierta
## un trueno lejano; saca un par de peces, tira la red y llega la tormenta. La red se traba y el
## padre le grita que la corte: evento rápido con el cuchillo. Después hay que huir remando
## detrás de la luz del padre por un río con ramas, rápidos, hielo y viento. El bote aguanta
## pocos golpes: si se hunde, o si llega al último rápido (que lo da vuelta), cae al agua.
## Bajo el agua la linterna se hunde, llegan los flashbacks, sube el barquito y el padre lo rescata.
## Este script solo ordena la memoria; cada pieza (bote, pesca, padre, río) vive en su clase.

enum Stage { WAKE, FISHING, NET, STORM, CUT, CHASE, ENDING }

@export var settings: Memory2Settings
@export var player: Player
@export var subtitles: SubtitleDisplay
@export var world_environment: WorldEnvironment
@export var lightning: LightningController
@export var wake_up: WakeUpIntro
@export var flashback: FlashbackOverlay
@export var debug_tools: DebugTools
@export var prompt: InteractionPrompt
@export var qte: TimingQte
@export var river: RiverFlow
@export var boat: RowBoat
@export var father: FatherBoat
@export var fishing: FishingRod
@export var knife_view: HeldItemView
## La red que flota (se tira desde el bote).
@export var net: Node3D
@export var net_rope: CuttableRope
## La linterna atada a la proa del bote (con un SpotLight3D adentro).
@export var bow_lamp: Node3D
## Al entrar el bote acá, el último rápido lo da vuelta.
@export var capsize_zone: Area3D
## Árboles que caen, troncos flotando y tramos oscuros del río.
@export var events: RiverEvents
@export var ocean: MeshInstance3D
## Nieve liviana (siempre) y nieve de tormenta (se prende con la tormenta).
@export var snow: CPUParticles3D
@export var snow_storm: CPUParticles3D
@export var toy_boat: Node3D
## Sonido de la tormenta (lluvia, viento, agua, música, truenos, bajo el agua), de la M2 de Mica.
@export var storm_audio: StormAudio
## Lluvia que acompaña a la cámara; cae con la tormenta (se suma a la nieve).
@export var rain: CPUParticles3D
@export var post_fx: PostFx
@export var father_light: SpotLight3D
@export var father_hand: Node3D
## El sol del atardecer: se apaga con la tormenta.
@export var sun: DirectionalLight3D
## Teclas de prueba (8 vuelo, 9 luz de rayo fija, 0 saltar etapa, 7 flashback). Apagar antes de entregar.
@export var debug_keys: bool = true

var stage: Stage = Stage.WAKE

var _head: Node3D
var _camera: Camera3D
var _seat: Node3D
var _storm: float = 0.0
var _busy: bool = false
var _aimed_rope: CuttableRope = null
var _gust_timer: float = 0.0
var _gust_time: float = -1.0
var _gust_sign: float = 1.0
var _gust_warned: bool = false
var _rapids_warned: Array[int] = []
var _bow_light: SpotLight3D
var _bow_glow: OmniLight3D
var _waiting_net: bool = false
var _dark: float = 0.0
var _dark_warned: Array[int] = []
var _dark_stopped_lightning: bool = false
var _lamp_angle: float = 26.0
var _lamp_range: float = 32.0
# Final: nadar en la superficie y el rescate.
var _floating: bool = false        # la cabeza sube y baja con el agua
var _swimming: bool = false        # además se puede nadar y se hunde cada tanto
var _float_time: float = 0.0
var _dip: float = 0.0
var _dip_timer: float = 0.0
var _search_timer: float = 0.0
var _search_yaw: float = 0.0
var _eye_height: float = 1.6
var _under_surface: bool = false
var _rescue_light_on: bool = false
var _bob_scale: float = 1.0
var _hand: BoneAttachment3D        # sigue la mano del padre ya posada
var _voice: AudioStreamPlayer
var _rain_material: StandardMaterial3D
var _heartbeat: AudioStreamPlayer
var _lullaby: AudioStreamPlayer


func _ready() -> void:
	super()
	assert(settings != null and player != null and subtitles != null and world_environment != null, "Memory2Lake: faltan referencias en el Inspector")
	assert(boat != null and father != null and fishing != null and river != null and qte != null, "Memory2Lake: faltan referencias en el Inspector")
	_head = player.get_node("Head") as Node3D
	_camera = player.get_node("Head/Camera3D") as Camera3D
	_seat = boat.get_node("Hull/Seat") as Node3D
	_sit_player()
	# La mira no tiene que chocar con el propio bote (el jugador va sentado adentro).
	(_camera.get_node("InteractionRay") as RayCast3D).add_exception(boat)
	fishing.fish_caught.connect(_on_fish_caught)
	# La barra del evento rápido va más arriba que los subtítulos.
	qte.offset_top -= 90.0
	qte.offset_bottom -= 90.0
	qte.hit.connect(_on_qte_hit)
	qte.missed.connect(_on_qte_missed)
	boat.hit_taken.connect(_on_boat_hit)
	boat.sunk.connect(func() -> void: _play_ending(true))
	father.calling.connect(_on_father_calling)
	if capsize_zone != null:
		capsize_zone.body_entered.connect(func(body: Node3D) -> void:
			if body == boat and stage == Stage.CHASE:
				_play_ending(false))
	if net_rope != null:
		net_rope.visible = false
		net_rope.hit_taken.connect(_on_rope_hit)
		net_rope.severed.connect(_on_net_cut)
	if net != null:
		net.visible = false
	_bow_light = _find_spot(bow_lamp)
	if _bow_light != null:
		_bow_light.light_energy = 0.0
		_lamp_angle = _bow_light.spot_angle
		_bow_light.rotation.x = deg_to_rad(settings.bow_lamp_pitch)
		_lamp_range = _bow_light.spot_range
	if events != null:
		events.tree_falling.connect(_on_tree_falling)
	if bow_lamp != null:
		for child: Node in bow_lamp.find_children("*", "OmniLight3D", true, false):
			_bow_glow = child as OmniLight3D
	if _bow_glow != null:
		_bow_glow.light_energy = 0.0
	if toy_boat != null:
		toy_boat.visible = false
	if father_light != null:
		father_light.visible = false
		father_light.light_energy = 0.0
	if father_hand != null:
		father_hand.visible = false
	for flakes: CPUParticles3D in [snow, snow_storm]:
		if flakes != null:
			flakes.top_level = true
	if snow != null:
		snow.amount = settings.calm_snow
	if snow_storm != null:
		snow_storm.amount = settings.storm_snow
		snow_storm.emitting = false
	if debug_tools != null:
		debug_tools.enabled = debug_keys
		debug_tools.skip_requested.connect(_debug_skip)
		debug_tools.flashback_requested.connect(func() -> void: flashback.play(1))
		debug_tools.fly_toggled.connect(func(on: bool) -> void:
			if not on and stage != Stage.ENDING:
				_sit_player())
	_voice = AudioStreamPlayer.new()
	_voice.name = "Voice"
	add_child(_voice)
	if rain != null:
		rain.top_level = true
		_rain_material = rain.material_override as StandardMaterial3D
	if storm_audio != null and lightning != null:
		lightning.flashed.connect(storm_audio.on_flash)
	_apply_storm(0.0)
	_begin.call_deferred()


## Sienta al jugador en el bote: va donde vaya el bote, solo mueve la mirada.
func _sit_player() -> void:
	if player.get_parent() != _seat:
		player.reparent(_seat, false)
	player.transform = Transform3D.IDENTITY
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.collision_layer = 0
	player.collision_mask = 0
	_head.position.y = 0.62


func _begin() -> void:
	wake_up.thunder_struck.connect(func() -> void: subtitles.show_line(settings.wake_line, settings.line_duration), CONNECT_ONE_SHOT)
	await wake_up.play()
	# El despertar le devuelve la física al jugador: sentado en el bote no la usa.
	player.set_physics_process(false)
	stage = Stage.FISHING
	fishing.start()


func _process(delta: float) -> void:
	for flakes: CPUParticles3D in [snow, snow_storm]:
		if flakes != null:
			flakes.global_position = _camera.global_position + Vector3(0.0, 6.0, 0.0)
	if rain != null:
		# La lluvia acompaña a la cámara pero siempre cae derecha, aunque el bote se incline.
		rain.global_position = _camera.global_position + Vector3(0.0, 9.0, 0.0)
	match stage:
		Stage.CUT:
			_update_rope_aim()
		Stage.CHASE:
			_update_gusts(delta)
			_check_rapids()
			_update_darkness(delta)
			_update_bow_lamp(delta)
		Stage.ENDING:
			_update_float(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if stage == Stage.NET and _waiting_net:
		get_viewport().set_input_as_handled()
		_throw_net()
	elif stage == Stage.CUT and _aimed_rope != null and not _busy and not qte.is_active():
		get_viewport().set_input_as_handled()
		_busy = true
		prompt.override_text = ""
		_begin_cut_qte()


# ---------- Pesca y red ----------

func _on_fish_caught(count: int) -> void:
	if count < settings.fish_to_catch or stage != Stage.FISHING:
		return
	fishing.stop()
	_go_to_net()


func _go_to_net() -> void:
	stage = Stage.NET
	subtitles.show_line(settings.net_line, settings.line_duration)
	_waiting_net = true
	prompt.override_text = settings.net_prompt


func _throw_net() -> void:
	_waiting_net = false
	prompt.override_text = ""
	if net != null:
		var rest: Vector3 = net.position
		net.visible = true
		net.position = Vector3(0.9, 1.2, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(net, "position", rest + Vector3.UP * 0.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(net, "position", rest, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if net_rope != null:
		net_rope.visible = true
	await get_tree().create_timer(settings.net_wait_time).timeout
	if stage == Stage.NET:
		_storm_arrives()


## Llega la tormenta: el cielo se cierra, sopla, nieva fuerte y la red se traba.
func _storm_arrives() -> void:
	stage = Stage.STORM
	if lightning != null:
		lightning.start()
		lightning.flash_now(0.9)
	subtitles.show_line(settings.storm_line, settings.line_duration)
	# Con la tormenta se prende la linterna de la proa.
	if _bow_light != null:
		create_tween().tween_property(_bow_light, "light_energy", settings.bow_lamp_energy, 1.2)
	if _bow_glow != null:
		create_tween().tween_property(_bow_glow, "light_energy", settings.bow_glow_energy, 1.2)
	var build: Tween = create_tween()
	build.tween_method(_apply_storm, _storm, 1.0, settings.storm_build_time)
	await get_tree().create_timer(settings.storm_build_time * 0.5).timeout
	# Intenta juntar la red: tira, pero no sube.
	subtitles.show_line(settings.stuck_line, settings.line_duration * 0.7)
	var tug: Tween = create_tween()
	for i: int in 3:
		tug.tween_property(_head, "rotation:x", deg_to_rad(-22.0), 0.18)
		tug.tween_property(_head, "rotation:x", deg_to_rad(-12.0), 0.3)
	await tug.finished
	await get_tree().create_timer(0.6).timeout
	if stage != Stage.STORM:
		return
	subtitles.show_line(settings.cut_line, settings.line_duration)
	stage = Stage.CUT
	knife_view.equip()


## 0 = atardecer en calma, 1 = tormenta cerrada.
func _apply_storm(amount: float) -> void:
	_storm = amount
	var env: Environment = world_environment.environment
	var ambient: float = lerpf(settings.dusk_ambient, settings.storm_ambient, amount)
	var sky: float = lerpf(settings.dusk_sky, settings.storm_sky, amount)
	env.fog_light_color = settings.dusk_fog_color.lerp(settings.storm_fog_color, amount)
	env.fog_density = lerpf(settings.dusk_fog_density, settings.storm_fog_density, amount)
	# El cielo (m2_sky.gdshader) se cierra y se oscurece con la tormenta.
	if env.sky != null and env.sky.sky_material is ShaderMaterial:
		(env.sky.sky_material as ShaderMaterial).set_shader_parameter("storm", amount)
	if lightning != null:
		lightning.set_base_levels(ambient, sky)
	else:
		env.ambient_light_energy = ambient
		env.background_energy_multiplier = sky
	if sun != null:
		sun.light_energy = lerpf(settings.sun_energy, 0.0, amount)
	if ocean != null and ocean.material_override is ShaderMaterial:
		(ocean.material_override as ShaderMaterial).set_shader_parameter("wave_height", lerpf(settings.calm_waves, settings.storm_waves, amount))
	if snow_storm != null:
		snow_storm.emitting = amount > 0.35
	if storm_audio != null:
		storm_audio.set_storm(amount)
	if _rain_material != null:
		var c: Color = _rain_material.albedo_color
		c.a = lerpf(0.0, 0.4, lerpf(settings.rain_calm, settings.rain_storm, amount))
		_rain_material.albedo_color = c
	if post_fx != null:
		post_fx.set_lens_wet(settings.lens_wet_storm * amount)


# ---------- Cortar la red ----------

func _update_rope_aim() -> void:
	var aimed: CuttableRope = null
	if not _busy and not qte.is_active():
		var ray: RayCast3D = _camera.get_node("InteractionRay") as RayCast3D
		var hit: Object = ray.get_collider() if ray.is_colliding() else null
		if hit is Area3D and (hit as Area3D).has_meta("rope"):
			var rope: CuttableRope = (hit as Area3D).get_meta("rope") as CuttableRope
			if rope != null and not rope.is_severed:
				aimed = rope
	_aimed_rope = aimed
	if not _busy:
		prompt.override_text = settings.cut_prompt if aimed != null else ""


func _begin_cut_qte() -> void:
	qte.begin(settings.cut_zone_width, settings.cut_marker_speed, settings.cut_max_passes)


func _on_qte_hit() -> void:
	_swing_knife()
	if net_rope != null:
		net_rope.add_hit()


func _on_rope_hit(hits: int) -> void:
	if hits >= settings.cut_hits:
		net_rope.sever()
	else:
		await get_tree().create_timer(0.4).timeout
		if stage == Stage.CUT and not net_rope.is_severed:
			_begin_cut_qte()


func _on_qte_missed() -> void:
	if not settings.urge_lines.is_empty():
		subtitles.show_line(settings.urge_lines[randi() % settings.urge_lines.size()], settings.line_duration * 0.7)
	await get_tree().create_timer(0.5).timeout
	if stage == Stage.CUT:
		_busy = false


func _swing_knife() -> void:
	var pivot: Node3D = knife_view.get_node_or_null("Pivot") as Node3D
	if pivot == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(pivot, "rotation:x", -1.1, 0.08)
	tween.tween_property(pivot, "rotation:x", 0.0, 0.22)


func _on_net_cut() -> void:
	_busy = false
	prompt.override_text = ""
	stage = Stage.CHASE
	# La red queda atrás y se hunde; la soga suelta se deja de ver al rato.
	if net != null:
		net.reparent(self, true)
		var sink: Tween = create_tween()
		sink.tween_property(net, "global_position:y", settings.water_level - 1.5, 4.0)
		sink.tween_callback(net.hide)
	get_tree().create_timer(2.6).timeout.connect(func() -> void:
		if net_rope != null:
			net_rope.visible = false)
	await get_tree().create_timer(0.5).timeout
	knife_view.unequip()
	subtitles.show_line(settings.follow_line, settings.line_duration)
	if _bow_light != null:
		_bow_light.light_energy = settings.bow_lamp_energy
	if _bow_glow != null:
		_bow_glow.light_energy = settings.bow_glow_energy
	boat.controls_enabled = true
	father.start()
	if events != null:
		events.active = true
	_gust_timer = randf_range(settings.gust_interval_min, settings.gust_interval_max)
	await get_tree().create_timer(settings.line_duration + 0.3).timeout
	if stage == Stage.CHASE:
		subtitles.show_line(settings.row_hint, settings.line_duration * 1.6)


# ---------- Huida ----------

## Ráfagas de viento de costado: empujan e inclinan el bote; se compensa remando del otro lado.
func _update_gusts(delta: float) -> void:
	if _gust_time < 0.0:
		_gust_timer -= delta
		boat.wind = boat.wind.move_toward(Vector3.ZERO, delta)
		if _gust_timer <= 0.0:
			_gust_time = 0.0
			_gust_sign = 1.0 if randf() < 0.5 else -1.0
			if not _gust_warned:
				_gust_warned = true
				subtitles.show_line(settings.gust_line, settings.line_duration)
	else:
		_gust_time += delta
		var k: float = _gust_time / settings.gust_duration
		var tangent: Vector3 = river.tangent_at(river.offset_of(boat.global_position))
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x)
		boat.wind = side * _gust_sign * settings.gust_force * sin(PI * clampf(k, 0.0, 1.0))
		if k >= 1.0:
			_gust_time = -1.0
			_gust_timer = randf_range(settings.gust_interval_min, settings.gust_interval_max)
	for flakes: CPUParticles3D in [snow, snow_storm]:
		if flakes != null:
			flakes.gravity = Vector3(boat.wind.x * 2.5, -3.0, boat.wind.z * 2.5)


func _check_rapids() -> void:
	var offset: float = river.offset_of(boat.global_position)
	for i: int in river.rapids.size():
		var r: Vector3 = river.rapids[i]
		if offset > r.x - 12.0 and offset < r.y and not _rapids_warned.has(i):
			_rapids_warned.append(i)
			subtitles.show_line(settings.rapids_line, settings.line_duration)


## Tramos oscuros: la niebla se cierra y se apaga el cielo; solo se ve lo que alumbra la
## linterna (un poco más abierta) y la luz del padre.
func _update_darkness(delta: float) -> void:
	if events == null:
		return
	var es: RiverEventsSettings = events.settings
	var offset: float = river.offset_of(boat.global_position)
	_dark = move_toward(_dark, events.darkness_at(offset), delta * 1.2)
	var env: Environment = world_environment.environment
	env.fog_density = lerpf(settings.storm_fog_density, es.dark_fog_density, _dark)
	env.fog_light_color = settings.storm_fog_color.lerp(es.dark_fog_color, _dark)
	var ambient: float = lerpf(settings.storm_ambient, es.dark_ambient, _dark)
	var sky: float = lerpf(settings.storm_sky, es.dark_sky, _dark)
	if lightning != null:
		lightning.set_base_levels(ambient, sky)
		if es.dark_stops_lightning:
			if _dark > 0.5 and lightning.is_running:
				lightning.stop()
				_dark_stopped_lightning = true
			elif _dark < 0.5 and _dark_stopped_lightning:
				_dark_stopped_lightning = false
				lightning.start()
	else:
		env.ambient_light_energy = ambient
		env.background_energy_multiplier = sky
	if _bow_light != null:
		_bow_light.spot_angle = lerpf(_lamp_angle, es.dark_lamp_angle, _dark)
		_bow_light.spot_range = lerpf(_lamp_range, es.dark_lamp_range, _dark)
		_bow_light.light_energy = lerpf(settings.bow_lamp_energy, es.dark_lamp_energy, _dark)
	for i: int in es.dark_zones.size():
		var z: Vector2 = es.dark_zones[i]
		if offset > z.x - es.dark_fade * 0.5 and offset < z.y and not _dark_warned.has(i):
			_dark_warned.append(i)
			subtitles.show_line(settings.dark_line, settings.line_duration)


## La linterna de la proa apunta hacia donde mira el jugador (con un tope a cada lado).
func _update_bow_lamp(delta: float) -> void:
	if bow_lamp == null or not settings.bow_lamp_follows_look:
		return
	var max_yaw: float = deg_to_rad(settings.bow_lamp_max_yaw)
	var target: float = clampf(wrapf(player.rotation.y, -PI, PI), -max_yaw, max_yaw)
	bow_lamp.rotation.y = lerp_angle(bow_lamp.rotation.y, target, minf(delta * settings.bow_lamp_follow_speed, 1.0))


func _on_tree_falling(_index: int) -> void:
	if stage != Stage.CHASE:
		return
	if lightning != null and events.settings.tree_flash > 0.0:
		lightning.flash_now(events.settings.tree_flash)
	subtitles.show_line(settings.tree_line, settings.line_duration * 0.8)


func _on_boat_hit(hits: int) -> void:
	if stage != Stage.CHASE:
		return
	if lightning != null:
		lightning.flash_now(0.35)
	var sinking: bool = boat.settings.sinks_on_hits and hits >= boat.settings.max_hits
	if not sinking and not settings.hit_lines.is_empty():
		subtitles.show_line(settings.hit_lines[mini(hits - 1, settings.hit_lines.size() - 1)], settings.line_duration * 0.7)


func _on_father_calling() -> void:
	if stage == Stage.CHASE and not settings.call_lines.is_empty():
		var index: int = randi() % settings.call_lines.size()
		subtitles.show_line(settings.call_lines[index], settings.line_duration * 0.8)
		if index < settings.call_voices.size():
			_say_voice(settings.call_voices[index])


## Suena una voz del padre (si hay audio).
func _say_voice(stream: AudioStream) -> void:
	if stream == null or _voice == null:
		return
	_voice.stream = stream
	_voice.volume_db = settings.voice_db
	_voice.play()


## Un efecto suelto (sin posición) con el volumen general de efectos.
func _play_sfx(stream: AudioStream, offset_db: float = 0.0) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = settings.sfx_db + offset_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Un sonido en bucle que se puede apagar (latido, caja de música).
func _start_loop(stream: AudioStream, db: float) -> AudioStreamPlayer:
	if stream == null:
		return null
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	var looped: AudioStream = stream.duplicate() as AudioStream
	if looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	p.stream = looped
	p.volume_db = db
	add_child(p)
	p.play()
	return p


func _stop_loop(p: AudioStreamPlayer, fade: float) -> void:
	if p == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(p, "volume_db", -60.0, fade)
	tween.tween_callback(p.queue_free)


# ---------- Final: cae al agua ----------

func _play_ending(drowned: bool) -> void:
	if stage == Stage.ENDING:
		return
	stage = Stage.ENDING
	boat.controls_enabled = false
	boat.stop()
	boat.wind = Vector3.ZERO
	boat.set_physics_process(false)
	father.is_running = false
	if events != null:
		events.active = false
	qte.cancel()
	prompt.override_text = ""
	if debug_tools != null and debug_tools.is_flying:
		debug_tools.set_flying(false)
	player.set_process_unhandled_input(false)
	var env: Environment = world_environment.environment
	var hull: Node3D = boat.get_node("Hull") as Node3D

	# 1. El bote se da vuelta (último rápido) o se hunde (demasiados golpes).
	if lightning != null:
		lightning.flash_now(0.8)
	if drowned:
		subtitles.show_line(settings.sink_line, settings.capsize_time + 1.5)
		var sink: Tween = create_tween().set_parallel(true)
		sink.tween_property(hull, "position:y", -0.7, settings.capsize_time * 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		sink.tween_property(hull, "rotation:z", 0.35, settings.capsize_time * 1.6)
		await sink.finished
	else:
		subtitles.show_line(settings.capsize_line, settings.capsize_time + 1.5)
		_play_sfx(settings.capsize_roar_sound)
		var flip: Tween = create_tween()
		flip.tween_property(hull, "rotation:z", PI * 0.85, settings.capsize_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await flip.finished

	# 2. Cae al agua y se hunde.
	player.reparent(self, true)
	player.global_rotation = Vector3(0.0, player.global_rotation.y, 0.0)
	var fall: Tween = create_tween().set_parallel(true)
	fall.tween_property(player, "global_position:y", settings.water_level - settings.underwater_depth, settings.fall_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(_head, "rotation:x", deg_to_rad(-25.0), settings.fall_time)
	await get_tree().create_timer(settings.fall_time * 0.4).timeout
	_play_sfx(settings.capsize_splash_sound)
	if storm_audio != null:
		storm_audio.set_underwater(true)
	_set_underwater(env)
	# Bajo el agua los botes quedan arriba, fuera de la vista: el rescate es la luz y la mano.
	boat.visible = false
	father.visible = false
	await fall.finished

	# 3. La linterna del bote se hunde, girando y apagándose.
	if bow_lamp != null:
		bow_lamp.reparent(self, true)
		var forward_flat: Vector3 = -_camera.global_basis.z
		forward_flat.y = 0.0
		forward_flat = forward_flat.normalized() if forward_flat.length() > 0.01 else Vector3.FORWARD
		bow_lamp.global_position = _camera.global_position + forward_flat * 1.6 + Vector3.UP * 0.4
		var start_energy: float = _bow_light.light_energy if _bow_light != null else 0.0
		var sink_lamp: Tween = create_tween().set_parallel(true)
		sink_lamp.tween_property(bow_lamp, "global_position", bow_lamp.global_position + Vector3(0.3, -settings.flashlight_sink_depth, -1.5), settings.flashlight_sink_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		sink_lamp.tween_property(bow_lamp, "rotation", bow_lamp.rotation + Vector3(-1.4, 2.6, 0.8), settings.flashlight_sink_time)
		sink_lamp.tween_property(_head, "rotation:x", deg_to_rad(-50.0), settings.flashlight_sink_time * 0.6)
		if _bow_light != null:
			var spot: SpotLight3D = _bow_light
			sink_lamp.tween_method(func(k: float) -> void:
				var flicker: float = 1.0 if k < 0.55 else (0.25 + 0.75 * float(randf() > k * 0.7))
				spot.light_energy = start_energy * (1.0 - k) * flicker, 0.0, 1.0, settings.flashlight_sink_time)
		await sink_lamp.finished
		bow_lamp.visible = false

	# 4. Sale a la superficie y nada un poco, medio ahogándose. El padre lo busca a lo lejos.
	await _swim(env)

	# 5. Flashbacks: el bote del padre a lo lejos y el pesquero a lo lejos (la misma escena).
	await flashback.play(settings.ending_flashbacks, true)

	# 6. El padre llega con su linterna desde arriba y lo rescata.
	await _rescue()
	await ScreenFade.fade_out(settings.end_fade_time)
	complete()


## Sale a la superficie en la tormenta y nada. Se puede mirar y moverse despacio; la cabeza se le
## hunde cada tanto. El bote del padre está lejos, barriendo con su luz sin verlo.
func _swim(env: Environment) -> void:
	_restore_surface(env)
	_eye_height = _camera.global_position.y - player.global_position.y
	var forward: Vector3 = -_camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	# El bote dado vuelta queda flotando a un costado.
	var side: Vector3 = Vector3(-forward.z, 0.0, forward.x)
	boat.global_position = Vector3(player.global_position.x, settings.water_level, player.global_position.z) + side * 2.6 + forward * 0.8
	boat.visible = true
	# El padre, lejos, buscando con su luz: armado como el pesquero de la M4 visto desde el agua.
	father.stop_rowing()
	father.look_at_son = false
	father.visible = true
	var to_father: Vector3 = Basis(Vector3.UP, deg_to_rad(settings.father_far_angle)) * forward
	father.global_position = Vector3(player.global_position.x, settings.water_level, player.global_position.z) + to_father * settings.father_far_distance
	# La proa (y la linterna) gira hacia la derecha de la línea de mirada.
	var bow: Vector3 = Basis(Vector3.UP, -deg_to_rad(settings.father_far_heading)) * to_father
	_search_yaw = atan2(-bow.x, -bow.z)
	var lens: Node3D = father.get_node_or_null("Hull/Flashlight/Lens") as Node3D
	if lens != null:
		lens.scale = Vector3.ONE * settings.father_far_lens_scale
	father.rotation.y = _search_yaw
	_search_timer = settings.search_line_interval * 0.5
	# Sube a la superficie.
	_head.rotation.x = deg_to_rad(5.0)
	var emerge: Tween = create_tween()
	emerge.tween_property(player, "global_position:y", settings.water_level + settings.eye_above_water - _eye_height, settings.emerge_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await emerge.finished
	subtitles.show_line(settings.gasp_lines[0] if not settings.gasp_lines.is_empty() else "", settings.line_duration * 0.7)
	_play_sfx(settings.gasp_sound)
	if storm_audio != null:
		storm_audio.set_underwater(false)
	_heartbeat = _start_loop(settings.heartbeat_sound, settings.heartbeat_db)
	_float_time = 0.0
	_bob_scale = 1.0
	_dip = 0.0
	_dip_timer = randf_range(settings.dip_interval_min, settings.dip_interval_max)
	_floating = true
	_swimming = true
	player.set_process_unhandled_input(true)
	await get_tree().create_timer(settings.swim_time).timeout
	_swimming = false
	player.set_process_unhandled_input(false)


## Cada cuadro del final: la cabeza flota, y mientras nada, se mueve y se hunde cada tanto.
func _update_float(delta: float) -> void:
	if not _floating:
		return
	_float_time += delta
	if _swimming:
		var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dir: Vector3 = player.global_basis * Vector3(input.x, 0.0, input.y)
		dir.y = 0.0
		player.global_position += dir * settings.swim_speed * delta
		_dip_timer -= delta
		if _dip_timer <= 0.0:
			_dip_timer = randf_range(settings.dip_interval_min, settings.dip_interval_max) + settings.dip_time
			var dip: Tween = create_tween()
			dip.tween_property(self, "_dip", 1.0, settings.dip_time * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			dip.tween_property(self, "_dip", 0.0, settings.dip_time * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			dip.tween_callback(func() -> void:
				if _swimming:
					_play_sfx(settings.gasp_sound, -3.0)
				if _swimming and not settings.gasp_lines.is_empty():
					subtitles.show_line(settings.gasp_lines[randi() % settings.gasp_lines.size()], settings.line_duration * 0.6))
		# El padre barre con la luz, lejos, y lo llama.
		father.rotation.y = _search_yaw + deg_to_rad(settings.father_search_sweep) * sin(_float_time * settings.father_search_rate * TAU)
		_search_timer -= delta
		if _search_timer <= 0.0 and not settings.search_lines.is_empty():
			_search_timer = settings.search_line_interval
			subtitles.show_line(settings.search_lines[randi() % settings.search_lines.size()], settings.line_duration * 0.8)
	var bob: float = (sin(_float_time * 1.3) + sin(_float_time * 0.7 + 1.0) * 0.5) * settings.swim_bob * _bob_scale
	player.global_position.y = settings.water_level + settings.eye_above_water - _eye_height + bob - _dip * settings.dip_depth
	# Con la cabeza abajo del agua se ve como bajo el agua.
	var under: bool = _camera.global_position.y < settings.water_level - 0.03
	if under != _under_surface:
		_under_surface = under
		if storm_audio != null:
			storm_audio.set_underwater(under)
		var env: Environment = world_environment.environment
		if under:
			env.fog_light_color = settings.underwater_fog_color
			env.fog_density = settings.underwater_fog_density
		else:
			env.fog_light_color = settings.storm_fog_color
			env.fog_density = settings.storm_fog_density
	if _rescue_light_on:
		_aim_rescue_light()


## Vuelve la tormenta de la superficie (al salir del agua).
func _restore_surface(env: Environment) -> void:
	env.fog_light_color = settings.storm_fog_color
	env.fog_density = settings.storm_fog_density
	_under_surface = false
	if lightning != null:
		lightning.set_sky_visible(true)
		lightning.set_base_levels(settings.storm_ambient, settings.storm_sky)
		lightning.start()
	else:
		env.background_energy_multiplier = settings.storm_sky
		env.ambient_light_energy = settings.storm_ambient
	for flakes: CPUParticles3D in [snow, snow_storm, rain]:
		if flakes != null:
			flakes.visible = true


## Después de los flashbacks: en el negro, el bote del padre queda al lado; la luz de su linterna
## aparece de a poco desde arriba, él inclinado sobre el borde estirándole la mano.
func _rescue() -> void:
	_floating = true
	_swimming = false
	_dip = 0.0
	var forward: Vector3 = -_camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	var eye: Vector3 = Vector3(_camera.global_position.x, settings.water_level, _camera.global_position.z)
	# El bote queda de costado, con su lado derecho (+X) hacia el jugador.
	var yaw: float = atan2(forward.z, -forward.x)
	var bow_dir: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
	var final_pos: Vector3 = eye + forward * settings.rescue_distance
	father.stop_rowing()
	father.look_at_son = true
	father.rotation = Vector3(0.0, yaw, 0.0)
	father.global_position = final_pos - bow_dir * 6.0
	var rig: CharacterRig = father.get_node_or_null("Hull/Character") as CharacterRig
	if rig != null:
		rig.look_target = _camera
		if settings.father_rescue_pose != null:
			rig.pose = settings.father_rescue_pose
	var father_flashlight: Node3D = father.get_node_or_null("Hull/Flashlight") as Node3D
	if father_flashlight != null:
		father_flashlight.visible = false
	# El brillo del farol de proa, de cerca, se ve como una luna: la luz es la de su mano.
	var lantern_glow: Node3D = father.get_node_or_null("Hull/LanternGlow") as Node3D
	if lantern_glow != null:
		lantern_glow.visible = false
	if father_light != null:
		father_light.visible = true
		father_light.light_energy = 0.0
	_rescue_light_on = true
	_aim_rescue_light()
	flashback.clear()
	_find_hand(rig)
	# Llega el bote, la luz crece y él mira hacia arriba, a la cara del padre.
	var face: Vector3 = final_pos + Vector3.UP * settings.rescue_look_height
	var to_face: Vector3 = face - _camera.global_position
	var look_pitch: float = atan2(to_face.y, Vector2(to_face.x, to_face.z).length())
	var arrive: Tween = create_tween().set_parallel(true)
	arrive.tween_property(self, "_bob_scale", settings.rescue_bob, settings.rescue_boat_time)
	arrive.tween_property(father, "global_position", final_pos, settings.rescue_boat_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	arrive.tween_property(_head, "rotation:x", look_pitch, settings.rescue_boat_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrive.tween_property(player, "rotation:y", atan2(-forward.x, -forward.z), settings.rescue_boat_time)
	if father_light != null:
		arrive.tween_property(father_light, "light_energy", settings.father_light_energy, settings.father_light_time).set_delay(settings.rescue_boat_time * 0.3)
		var glow_light: OmniLight3D = father_light.get_node_or_null("GlowLight") as OmniLight3D
		if glow_light != null:
			glow_light.light_energy = 0.0
			arrive.tween_property(glow_light, "light_energy", settings.father_light_energy * 0.35, settings.father_light_time).set_delay(settings.rescue_boat_time * 0.3)
		var glow: Node3D = father_light.get_node_or_null("Glow") as Node3D
		if glow != null:
			glow.scale = Vector3.ONE * 0.01
			arrive.tween_property(glow, "scale", Vector3.ONE * settings.rescue_glow_scale, settings.father_light_time).set_delay(settings.rescue_boat_time * 0.3) \
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(settings.rescue_boat_time * 0.6).timeout
	subtitles.show_line(settings.father_line, settings.rescue_boat_time + settings.rescue_hold_time + settings.end_fade_time)
	_say_voice(settings.rescue_voice)
	_play_sfx(settings.hand_grab_sound)
	_stop_loop(_heartbeat, 2.0)
	_lullaby = _start_loop(settings.lullaby_sound, settings.lullaby_db)
	if storm_audio != null:
		storm_audio.set_muted(true)
	await arrive.finished
	await get_tree().create_timer(settings.rescue_hold_time).timeout


## La linterna del padre: en su mano, arriba, apuntando a la cara del jugador.
func _aim_rescue_light() -> void:
	if father_light == null:
		return
	if _hand != null:
		father_light.global_position = _hand.global_position + settings.rescue_light_bone_offset
	else:
		father_light.global_position = father.global_transform * settings.rescue_light_offset
	if father_light.global_position.distance_to(_camera.global_position) > 0.2:
		father_light.look_at(_camera.global_position, Vector3.UP)


## Engancha un BoneAttachment3D a la mano que lleva la linterna (por el comienzo del nombre del hueso).
## Se usa un BoneAttachment3D porque sigue la pose ya aplicada por el CharacterRig.
func _find_hand(rig: CharacterRig) -> void:
	if _hand != null or rig == null or settings.rescue_light_bone.is_empty():
		return
	var skeletons: Array[Node] = rig.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
	for i: int in skeleton.get_bone_count():
		if skeleton.get_bone_name(i).begins_with(settings.rescue_light_bone):
			_hand = BoneAttachment3D.new()
			_hand.name = "RescueLightHand"
			skeleton.add_child(_hand)
			_hand.bone_idx = i
			return


## Bajo el agua: niebla oscura que se come todo, sin cielo.
func _set_underwater(env: Environment) -> void:
	env.fog_enabled = true
	env.fog_light_color = settings.underwater_fog_color
	env.fog_density = settings.underwater_fog_density
	if lightning != null:
		lightning.stop()
		lightning.set_held(false)
		lightning.set_sky_visible(false)
		lightning.set_base_levels(0.02, 0.0)
	env.background_energy_multiplier = 0.0
	env.ambient_light_energy = 0.02
	for flakes: CPUParticles3D in [snow, snow_storm, rain]:
		if flakes != null:
			flakes.visible = false


func _find_spot(root: Node) -> SpotLight3D:
	if root == null:
		return null
	if root is SpotLight3D:
		return root as SpotLight3D
	for child: Node in root.find_children("*", "SpotLight3D", true, false):
		return child as SpotLight3D
	return null


## SOLO PARA PRUEBAS (tecla 0): salta la etapa actual.
func _debug_skip() -> void:
	match stage:
		Stage.WAKE, Stage.FISHING:
			fishing.stop()
			stage = Stage.FISHING
			_go_to_net()
		Stage.NET:
			if _waiting_net:
				_waiting_net = false
				prompt.override_text = ""
				if net != null:
					net.visible = true
				if net_rope != null:
					net_rope.visible = true
			_storm_arrives()
		Stage.CUT:
			qte.cancel()
			if net_rope != null and not net_rope.is_severed:
				net_rope.sever()
		Stage.CHASE:
			# Lleva el bote cerca del último rápido.
			var end_offset: float = river.offset_of(capsize_zone.global_position) if capsize_zone != null else river.get_length() - 30.0
			var target: Vector3 = river.point_at(end_offset - 28.0)
			boat.global_position = Vector3(target.x, boat.water_level, target.z)
			var t: Vector3 = river.tangent_at(end_offset - 28.0)
			boat.rotation.y = atan2(-t.x, -t.z)
			boat.stop()
			var f_target: Vector3 = river.point_at(end_offset - 14.0)
			father.global_position = Vector3(f_target.x, father.water_level, f_target.z)
			father.start()
			if events != null:
				events.settle_trees_before(end_offset)
		_:
			pass
