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
	match stage:
		Stage.CUT:
			_update_rope_aim()
		Stage.CHASE:
			_update_gusts(delta)
			_check_rapids()
			_update_darkness(delta)
			_update_bow_lamp(delta)


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
	if hits < boat.settings.max_hits and not settings.hit_lines.is_empty():
		subtitles.show_line(settings.hit_lines[mini(hits - 1, settings.hit_lines.size() - 1)], settings.line_duration * 0.7)


func _on_father_calling() -> void:
	if stage == Stage.CHASE and not settings.call_lines.is_empty():
		subtitles.show_line(settings.call_lines[randi() % settings.call_lines.size()], settings.line_duration * 0.8)


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

	# 4. Oscuridad total y los flashbacks del accidente.
	if lightning != null:
		lightning.set_base_levels(0.0, 0.0)
	env.ambient_light_energy = 0.0
	await get_tree().create_timer(settings.dark_time).timeout
	await flashback.play(settings.ending_flashbacks, true)
	flashback.clear()

	# 5. El barquito sube encendido.
	var forward: Vector3 = -_camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	if toy_boat != null:
		toy_boat.visible = true
		toy_boat.global_position = _camera.global_position + forward * 1.4 + Vector3.DOWN * 1.2
		var rise: Tween = create_tween().set_parallel(true)
		rise.tween_property(toy_boat, "global_position", _camera.global_position + forward * 1.3 + Vector3.UP * 0.75, settings.boat_rise_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		rise.tween_property(toy_boat, "rotation:y", toy_boat.rotation.y + 1.2, settings.boat_rise_time)
		rise.tween_property(_head, "rotation:x", deg_to_rad(32.0), settings.boat_rise_time)
		await rise.finished

	# 6. La luz del padre desde arriba, su mano y su voz.
	if father_light != null:
		father_light.global_position = Vector3(_camera.global_position.x, settings.water_level - 0.15, _camera.global_position.z) + forward * 1.2
		father_light.look_at(_camera.global_position + Vector3.DOWN * 1.0, Vector3.FORWARD)
		father_light.visible = true
		var light_in: Tween = create_tween().set_parallel(true)
		light_in.tween_property(father_light, "light_energy", settings.father_light_energy, settings.father_light_time)
		var glow_light: OmniLight3D = father_light.get_node_or_null("GlowLight") as OmniLight3D
		if glow_light != null:
			light_in.tween_property(glow_light, "light_energy", settings.father_light_energy * 0.4, settings.father_light_time)
		var glow: Node3D = father_light.get_node_or_null("Glow") as Node3D
		if glow != null:
			glow.scale = Vector3.ONE * 0.05
			light_in.tween_property(glow, "scale", Vector3.ONE, settings.father_light_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if father_hand != null:
		father_hand.visible = true
		var hand_end: Vector3 = _camera.global_position + forward * 0.95 + Vector3.UP * 0.55
		father_hand.global_position = hand_end + Vector3.UP * 1.4 + forward * 0.5
		father_hand.look_at(father_hand.global_position + forward, Vector3.UP)
		father_hand.rotate_object_local(Vector3.RIGHT, deg_to_rad(-25.0))
		create_tween().tween_property(father_hand, "global_position", hand_end, settings.father_light_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	subtitles.show_line(settings.father_line, settings.father_light_time + settings.end_fade_time + 1.0)
	await get_tree().create_timer(settings.father_light_time).timeout
	await ScreenFade.fade_out(settings.end_fade_time)
	complete()


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
	for flakes: CPUParticles3D in [snow, snow_storm]:
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
