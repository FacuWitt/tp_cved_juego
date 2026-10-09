class_name Memory4Accident
extends Memory
## Memoria 4: el accidente en el barco.
## 1) CUBIERTA: el jugador corta las 6 sogas (3 por banda) con un evento rápido. El suelo resbala
##    y los costados están abiertos: si cae al agua, vuelve a bordo después de unos segundos en negro.
## 2) AVISO: la tripulación grita "¡LO LOGRAMOS!" y enseguida "¡CUIDADO!".
## 3) OLA: una ola gigante se enrosca y lo cubre.
## 4) SUPERFICIE: flota de noche, el barco lo perdió de vista y se aleja.
## 5) HUNDIMIENTO: oscuridad total (talasofobia).
## 6) LUZ: aparece la luz del helicóptero y la memoria se completa.
## Este script solo ordena las etapas; cada pieza (ola, rayos, soga, evento rápido) vive en su propia clase.

enum Stage { DECK, WARNING, WAVE, COVERED, SURFACE, DESCENT, RESCUE }

@export var settings: Memory4Settings
@export var player: Player
@export var ropes: Array[CuttableRope] = []
@export var qte: TimingQte
@export var subtitles: SubtitleDisplay
@export var prompt_label: Label
@export var lightning: LightningController
@export var wave: GiantWave
@export var ship: Node3D
@export var searchlight: SpotLight3D
@export var world_environment: WorldEnvironment
@export var rain: CPUParticles3D
@export var ocean: OceanFollow
@export var slam_overlay: ColorRect
@export var water_overlay: ColorRect
@export var black_overlay: ColorRect
@export var rescue_glow: MeshInstance3D
## Tecla de prueba: con 0 se cortan todas las sogas de una (para probar rápido). Apagar antes de entregar.
@export var debug_keys: bool = true
@export var abyss_overlay: ColorRect
@export var deck_slip: DeckSlip
@export var splash_player: AudioStreamPlayer

var stage: Stage = Stage.DECK

var _head: Node3D
var _camera: Camera3D
var _axe: AxeView
var _active_rope: CuttableRope = null
var _chop_rope: CuttableRope = null
var _busy: bool = false
var _ropes_cut: int = 0
var _misses: int = 0
var _roll_extra: float = 0.0
var _shake_amount: float = 0.0
var _time: float = 0.0
var _float_base_y: float = 0.0
var _search_time: float = 0.0
var _base_fov: float = 75.0
var _overboard: bool = false
var _under_view: bool = false
var _roll_deg: float = 0.0
var _last_safe: Vector3 = Vector3.ZERO


func _ready() -> void:
	super()
	assert(settings != null and player != null and qte != null and subtitles != null, "Memory4Accident: faltan referencias en el Inspector")
	assert(lightning != null and wave != null and ship != null and world_environment != null, "Memory4Accident: faltan referencias en el Inspector")
	assert(slam_overlay != null and water_overlay != null and black_overlay != null and rescue_glow != null, "Memory4Accident: faltan overlays en el Inspector")
	_head = player.get_node("Head") as Node3D
	_camera = player.get_node("Head/Camera3D") as Camera3D
	_base_fov = _camera.fov
	_axe = AxeView.new()
	_camera.add_child(_axe)

	prompt_label.text = settings.rope_prompt
	prompt_label.visible = false
	rain.amount = settings.rain_amount
	rain.top_level = true
	(rain.mesh as BoxMesh).size = Vector3(settings.rain_width, settings.rain_length, settings.rain_width)
	deck_slip.strength = settings.slip_strength
	deck_slip.enabled = true
	_last_safe = player.global_position
	ocean.target = player
	for overlay: ColorRect in [slam_overlay, water_overlay, black_overlay]:
		overlay.modulate.a = 0.0
	rescue_glow.visible = false

	for rope: CuttableRope in ropes:
		rope.player_range_changed.connect(_on_rope_range_changed.bind(rope))
		rope.hit_taken.connect(_on_rope_hit.bind(rope))
		rope.severed.connect(_on_rope_severed)
	qte.hit.connect(_on_qte_hit)
	qte.missed.connect(_on_qte_missed)
	wave.covered.connect(_on_wave_covered)
	ocean.position.y = settings.sea_level
	wave.position.y = settings.sea_level
	# Reflector del mástil: luz cálida y sutil sobre la cubierta.
	searchlight.light_energy = settings.deck_floodlight_energy
	searchlight.spot_angle = settings.deck_floodlight_angle
	searchlight.rotation_degrees = Vector3(settings.deck_floodlight_pitch, 180.0, 0.0)
	lightning.start()
	_say_intro()


func _say_intro() -> void:
	await get_tree().create_timer(settings.intro_delay).timeout
	if stage == Stage.DECK and subtitles.text == "":
		subtitles.show_line(settings.intro_line % settings.protagonist_name, settings.line_duration * 1.6)


func _process(delta: float) -> void:
	_time += delta
	_roll_deg = settings.deck_roll + _roll_extra + sin(_time * TAU / settings.sway_period) * settings.sway_roll
	deck_slip.roll_degrees = _roll_deg
	deck_slip.enabled = stage <= Stage.WARNING and not _overboard
	# Mientras corta una soga tiene los pies firmes: si no, no habría forma de apuntar el golpe.
	deck_slip.planted = stage == Stage.DECK and _busy and not _overboard
	_update_camera_motion(delta)
	_update_rain()
	_update_abyss()
	if stage <= Stage.WARNING and not _overboard:
		_watch_edges()
	match stage:
		Stage.DECK:
			prompt_label.visible = _active_rope != null and not _busy and not qte.is_active()
		Stage.SURFACE, Stage.DESCENT:
			_update_float()
			if stage == Stage.SURFACE and _under_view and _camera.global_position.y > settings.sea_level + 0.1:
				_set_underwater_view(false)
				rain.emitting = true
	if stage >= Stage.SURFACE:
		_float_ship()
	if stage >= Stage.SURFACE and searchlight != null:
		_search_time += delta
		# El reflector del barco barre otras zonas del mar: nunca apunta al jugador.
		var blend: float = clampf(_search_time / settings.search_turn_time, 0.0, 1.0)
		blend = blend * blend * (3.0 - 2.0 * blend)
		var sweep: float = sin(_search_time * settings.searchlight_speed) * 45.0 + 28.0
		var cone: float = lerpf(settings.deck_floodlight_angle, settings.search_angle, blend)
		var local_yaw: float = deg_to_rad(180.0 + sweep * blend)
		# El haz pasa cerca pero nunca ilumina al jugador: se mantiene a una separación mínima.
		var to_player: Vector3 = _camera.global_position - searchlight.global_position
		var player_yaw: float = atan2(-to_player.x, -to_player.z)
		var ship_yaw: float = ship.global_rotation.y
		var diff: float = wrapf(ship_yaw + local_yaw - player_yaw, -PI, PI)
		var min_sep: float = deg_to_rad(cone + settings.search_safe_margin)
		if absf(diff) < min_sep:
			diff = min_sep if diff >= 0.0 else -min_sep
			local_yaw = player_yaw + diff - ship_yaw
		searchlight.rotation = Vector3(
			deg_to_rad(lerpf(settings.deck_floodlight_pitch, settings.search_pitch, blend)),
			local_yaw, 0.0)
		searchlight.spot_angle = cone
		searchlight.light_energy = lerpf(settings.deck_floodlight_energy, settings.searchlight_energy, blend)


## Última posición firme en cubierta y detección de caída por un costado abierto.
func _watch_edges() -> void:
	if player.is_on_floor() and absf(player.global_position.x) < 3.9:
		_last_safe = player.global_position
	elif player.global_position.y < settings.fall_height:
		_fall_overboard()


## SOLO PARA PRUEBAS: corta todas las sogas y sigue el flujo normal (aviso, ola, etc.).
func _debug_cut_all_ropes() -> void:
	if stage != Stage.DECK or _overboard:
		return
	qte.cancel()
	prompt_label.visible = false
	for rope: CuttableRope in ropes:
		if not rope.is_severed:
			rope.sever()


func _unhandled_input(event: InputEvent) -> void:
	if debug_keys and event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_0 or event.keycode == KEY_KP_0):
		_debug_cut_all_ropes()
		return
	if stage == Stage.DECK and event.is_action_pressed("interact") and _active_rope != null and not _busy and not _overboard:
		_start_chop(_active_rope)


# ---------- Cubierta ----------

func _start_chop(rope: CuttableRope) -> void:
	_busy = true
	_chop_rope = rope
	prompt_label.visible = false
	_begin_qte()


func _begin_qte() -> void:
	var rope_index: int = _ropes_cut
	var zone: float = maxf(0.05, settings.zone_width - settings.zone_shrink_per_rope * float(rope_index))
	var speed: float = settings.marker_speed + settings.speed_gain_per_rope * float(rope_index)
	qte.begin(zone, speed, settings.max_passes)


func _on_qte_hit() -> void:
	_axe.swing()
	_shake_amount = 0.05
	if _chop_rope != null:
		_chop_rope.add_hit()


func _on_rope_hit(hits: int, rope: CuttableRope) -> void:
	if hits >= settings.hits_per_rope:
		rope.sever()
	else:
		# Todavía no cede: sigue el siguiente golpe sin que haya que volver a apretar E.
		await get_tree().create_timer(0.45).timeout
		if stage == Stage.DECK and _chop_rope == rope and not rope.is_severed:
			_begin_qte()


func _on_qte_missed() -> void:
	_misses += 1
	_roll_extra = minf(_roll_extra + settings.roll_per_miss, 8.0)
	_shake_amount = 0.12
	_axe.swing()
	if not settings.urge_lines.is_empty():
		var line: String = settings.urge_lines[randi() % settings.urge_lines.size()]
		subtitles.show_line(line % settings.protagonist_name if line.contains("%s") else line, settings.line_duration)
	await get_tree().create_timer(settings.retry_delay).timeout
	if stage == Stage.DECK:
		_busy = false


func _on_rope_range_changed(in_range: bool, rope: CuttableRope) -> void:
	if in_range:
		_active_rope = rope
	elif _active_rope == rope:
		_active_rope = null


func _on_rope_severed() -> void:
	_ropes_cut += 1
	_shake_amount = 0.2
	_active_rope = null
	if _ropes_cut >= ropes.size():
		_on_all_ropes_cut()
	else:
		_busy = false


# ---------- Caída al agua ----------

## Cayó por un costado: un susto en negro bajo el agua helada y vuelve a bordo. Cuenta como un fallo más.
func _fall_overboard() -> void:
	_overboard = true
	_busy = true
	deck_slip.enabled = false
	qte.cancel()
	prompt_label.visible = false
	_active_rope = null
	_chop_rope = null
	subtitles.show_line("", 0.0)
	_shake_amount = 0.6
	if splash_player != null:
		splash_player.play()
	# Golpe de frío: el campo de visión se abre de golpe y todo se va a negro.
	var dive: Tween = create_tween().set_parallel(true)
	dive.tween_property(_camera, "fov", _base_fov + 22.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	dive.tween_property(water_overlay, "modulate:a", 0.9, 0.2)
	dive.tween_property(black_overlay, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.4).timeout
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	await get_tree().create_timer(settings.fall_dark_time).timeout

	# Vuelve a bordo, más cerca del centro de la cubierta que de donde cayó.
	var back: Vector3 = _last_safe
	back.x *= 0.35
	player.global_position = back
	player.rotation.y = PI
	player.velocity = Vector3.ZERO
	_head.rotation.x = 0.0
	_misses += 1
	_roll_extra = minf(_roll_extra + settings.fall_roll_penalty, 8.0)
	if stage <= Stage.WARNING:
		player.set_physics_process(true)
	var back_tween: Tween = create_tween().set_parallel(true)
	back_tween.tween_property(_camera, "fov", _base_fov, 1.0)
	back_tween.tween_property(black_overlay, "modulate:a", 0.0, 1.0)
	back_tween.tween_property(water_overlay, "modulate:a", 0.0, 1.6)
	subtitles.show_line(settings.fall_rescue_line % settings.protagonist_name, settings.line_duration)
	await back_tween.finished
	_overboard = false
	if stage == Stage.DECK:
		_busy = false
		deck_slip.enabled = true


# ---------- Aviso y ola ----------

func _on_all_ropes_cut() -> void:
	stage = Stage.WARNING
	_busy = true
	prompt_label.visible = false
	await get_tree().create_timer(settings.success_delay).timeout
	while _overboard:
		await get_tree().process_frame
	subtitles.show_line(settings.success_line, settings.line_duration)
	await get_tree().create_timer(settings.warning_delay).timeout
	# El grito de advertencia y un rayo que deja ver lo que viene.
	lightning.flash_now(1.0)
	subtitles.show_line(settings.warning_line % settings.protagonist_name, settings.line_duration)
	_start_wave()


func _start_wave() -> void:
	stage = Stage.WAVE
	deck_slip.enabled = false
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	var start_z: float = player.global_position.z + settings.wave_distance
	wave.launch(start_z, player.global_position.z)

	# La cámara se levanta a medida que la ola crece, y el campo de visión se abre.
	var look: Tween = create_tween().set_parallel(true)
	# Se da vuelta hacia la popa: la ola viene por detrás del barco.
	look.tween_property(player, "rotation:y", player.rotation.y + wrapf(PI - player.rotation.y, -PI, PI), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	look.tween_property(_head, "rotation:x", deg_to_rad(settings.look_up_angle), settings.wave_time * 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	look.tween_property(_camera, "fov", _base_fov + 14.0, settings.wave_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_wave_flashes()


## Rayos seguidos mientras viene la ola: es lo único que deja verla.
func _wave_flashes() -> void:
	while stage == Stage.WAVE:
		await get_tree().create_timer(randf_range(0.9, 1.7)).timeout
		if stage == Stage.WAVE:
			lightning.flash_now(randf_range(0.8, 1.0))


func _on_wave_covered() -> void:
	if stage != Stage.WAVE:
		return
	stage = Stage.COVERED
	_shake_amount = 0.5
	lightning.stop()
	var slam: Tween = create_tween()
	slam.tween_property(slam_overlay, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await slam.finished
	# La espuma blanca se hunde enseguida en el agua oscura.
	var sink_color: Tween = create_tween()
	sink_color.tween_property(slam_overlay, "color", Color(0.01, 0.05, 0.07), 0.55).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.8).timeout
	_enter_surface()


# ---------- Superficie ----------

func _enter_surface() -> void:
	stage = Stage.SURFACE
	wave.hide_wave()
	subtitles.show_line("", 0.0)
	var sea_y: float = settings.sea_level
	# El jugador reaparece bajo el agua, lejos del barco, mirando hacia donde quedó.
	player.global_position = Vector3(0.0, sea_y - 3.0, settings.float_distance)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	_head.rotation.x = 0.0
	_camera.fov = _base_fov
	_roll_extra = 0.0
	_axe.visible = false
	# La lluvia que queda es la de alrededor del barco, donde hay luz.
	rain.emission_box_extents = Vector3(10.0, 0.1, 24.0)
	# Mientras emerge no ve nada: recién al asomar la cabeza aparecen el cielo y el barco.
	_set_underwater_view(true)
	_float_base_y = sea_y + 0.15
	black_overlay.modulate.a = 1.0
	water_overlay.modulate.a = 0.85
	slam_overlay.modulate.a = 0.0
	lightning.start()

	# El barco gira y se aleja: lo perdió de vista y busca en otra dirección.
	var heading: Vector3 = Basis(Vector3.UP, deg_to_rad(settings.ship_turn)) * Vector3(0.0, 0.0, -1.0)
	var float_time: float = settings.float_time
	var turn: Tween = create_tween().set_parallel(true)
	turn.tween_property(ship, "rotation_degrees:y", settings.ship_turn, float_time * 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Solo X y Z: la altura la pone el oleaje (el barco flota).
	turn.tween_property(ship, "position:x", ship.position.x + heading.x * settings.ship_drift, float_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	turn.tween_property(ship, "position:z", ship.position.z + heading.z * settings.ship_drift, float_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Sale a la superficie: del negro y el agua turbia a la tormenta.
	var emerge: Tween = create_tween().set_parallel(true)
	emerge.tween_property(player, "global_position:y", _float_base_y - 1.4, settings.emerge_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	emerge.tween_property(black_overlay, "modulate:a", 0.0, settings.emerge_time * 0.8)
	emerge.tween_property(water_overlay, "modulate:a", 0.0, settings.emerge_time)
	await get_tree().create_timer(float_time).timeout
	_begin_descent()


## El barco flota sobre el oleaje: sube y baja y se inclina un poco, así nunca se le ve el casco sumergido.
func _float_ship() -> void:
	var pos: Vector3 = ship.global_position
	var heading: Basis = ship.global_transform.basis
	var bow: Vector3 = pos + heading * Vector3(0.0, 0.0, -12.0)
	var stern: Vector3 = pos + heading * Vector3(0.0, 0.0, 10.0)
	var port: Vector3 = pos + heading * Vector3(-4.5, 0.0, 0.0)
	var starboard: Vector3 = pos + heading * Vector3(4.5, 0.0, 0.0)
	var h_center: float = ocean.height_at(pos.x, pos.z)
	var h_bow: float = ocean.height_at(bow.x, bow.z)
	var h_stern: float = ocean.height_at(stern.x, stern.z)
	var h_port: float = ocean.height_at(port.x, port.z)
	var h_star: float = ocean.height_at(starboard.x, starboard.z)
	ship.position.y = h_center
	ship.rotation.x = atan2(h_bow - h_stern, 22.0) * 0.8
	ship.rotation.z = atan2(h_star - h_port, 9.0) * 0.8


func _update_float() -> void:
	if stage != Stage.SURFACE or black_overlay.modulate.a > 0.5:
		return
	var bob: float = sin(_time * 1.25) * settings.bob_height + sin(_time * 0.63 + 1.0) * settings.bob_height * 0.6
	# La cabeza (ojos) a ras del agua: el origen del jugador está 1,6 m más abajo.
	player.global_position.y = _float_base_y - 1.55 + bob


# ---------- Hundimiento ----------

func _begin_descent() -> void:
	stage = Stage.DESCENT
	var env: Environment = world_environment.environment
	_go_underwater_after_dip()
	var sink: Tween = create_tween().set_parallel(true)
	sink.tween_property(player, "global_position:y", settings.sea_level - settings.sink_depth, settings.sink_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sink.tween_property(water_overlay, "modulate:a", 0.75, settings.sink_time * 0.2)
	sink.tween_property(_head, "rotation:x", deg_to_rad(40.0), settings.sink_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sink.tween_property(env, "fog_density", 0.35, settings.sink_time * 0.8)
	sink.tween_property(env, "ambient_light_energy", 0.0, settings.sink_time * 0.5)
	sink.tween_property(black_overlay, "modulate:a", 1.0, settings.sink_time * 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(settings.sink_time * 0.5).timeout
	rain.emitting = false
	lightning.stop()
	await sink.finished
	lightning.blackout()
	await get_tree().create_timer(settings.darkness_time).timeout
	_show_rescue_light()


## Cuando la cabeza ya está bajo el agua, el cielo deja de existir: negro total en vez del horizonte.
## Así no se asoma el borde del mar, ni el barco, ni la luz del cielo por encima.
func _go_underwater_after_dip() -> void:
	while stage == Stage.DESCENT and player.global_position.y + 1.6 > settings.sea_level - 0.6:
		await get_tree().process_frame
	if stage != Stage.DESCENT:
		return
	world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_set_underwater_view(true)


## Bajo el agua no existe nada más que la oscuridad: ni el barco, ni sus luces, ni la lluvia, ni el mar, ni el cielo.
func _set_underwater_view(underwater: bool) -> void:
	_under_view = underwater
	var env: Environment = world_environment.environment
	env.background_mode = Environment.BG_COLOR if underwater else Environment.BG_SKY
	env.background_color = Color.BLACK
	lightning.set_sky_visible(not underwater)
	ship.visible = not underwater
	ocean.visible = not underwater
	rain.visible = not underwater
	if underwater:
		rain.emitting = false


# ---------- Luz final ----------

func _show_rescue_light() -> void:
	stage = Stage.RESCUE
	# El negro total se levanta: lo único que existe es la luz que viene de arriba.
	black_overlay.modulate.a = 0.0
	water_overlay.modulate.a = 0.0
	# La luz aparece justo donde el jugador está mirando (hacia arriba) y se acerca.
	var look_dir: Vector3 = -_camera.global_transform.basis.z
	var origin: Vector3 = _camera.global_position
	rescue_glow.global_position = origin + look_dir * 70.0
	rescue_glow.scale = Vector3.ONE * 4.0
	var material: ShaderMaterial = rescue_glow.material_override as ShaderMaterial
	material.set_shader_parameter("strength", 0.0)
	rescue_glow.visible = true
	var rise: Tween = create_tween().set_parallel(true)
	rise.tween_method(func(v: float) -> void: material.set_shader_parameter("strength", v), 0.0, settings.rescue_light_strength, settings.rescue_light_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rise.tween_property(rescue_glow, "global_position", origin + look_dir * 18.0, settings.rescue_light_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rise.tween_property(rescue_glow, "scale", Vector3.ONE * 26.0, settings.rescue_light_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await rise.finished
	complete()


# ---------- Lluvia y abismo ----------

func _update_rain() -> void:
	var material: StandardMaterial3D = rain.material_override as StandardMaterial3D
	var level: float = lightning.get_level()
	var alpha: float
	if stage >= Stage.SURFACE:
		# Lejos del barco solo se ve la lluvia que cae donde están sus luces, y apenas.
		rain.global_position = ship.global_position + ship.global_transform.basis * Vector3(0.0, 9.0, -6.0)
		alpha = settings.rain_alpha_far * (1.0 + level * 1.2)
	else:
		rain.global_position = player.global_position + Vector3(0.0, 9.0, 0.0)
		alpha = settings.rain_alpha_lit + level * settings.rain_alpha_flash
	var color: Color = material.albedo_color
	color.a = alpha
	material.albedo_color = color


## En el agua, mirar hacia abajo es mirar el vacío: la pantalla se va a negro de abajo hacia arriba.
func _update_abyss() -> void:
	var look_down: float = 0.0
	if stage == Stage.SURFACE or stage == Stage.DESCENT:
		var pitch_down: float = -rad_to_deg(_head.rotation.x)
		look_down = smoothstep(settings.abyss_start_angle, settings.abyss_full_angle, pitch_down)
	(abyss_overlay.material as ShaderMaterial).set_shader_parameter("look_down", look_down)


# ---------- Cámara ----------

func _update_camera_motion(delta: float) -> void:
	if _camera == null:
		return
	_shake_amount = move_toward(_shake_amount, 0.0, delta * 0.35)
	_camera.position = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake_amount
	match stage:
		Stage.DECK, Stage.WARNING, Stage.WAVE, Stage.COVERED:
			# El barco escorado: la cámara queda torcida y se mece con el oleaje.
			# El barco se inclina a lo largo: de frente a la proa o a la popa se ve toda la inclinación, de costado casi nada.
			var facing: float = -player.global_transform.basis.z.z
			var target: float = deg_to_rad(_roll_deg * facing)
			_camera.rotation.z = lerpf(_camera.rotation.z, target, minf(1.0, delta * 3.0))
		_:
			_camera.rotation.z = lerpf(_camera.rotation.z, sin(_time * 0.9) * 0.05, minf(1.0, delta * 2.0))
