class_name Memory2Lake
extends Memory
## Memoria 2: el lago helado.
## El protagonista (adolescente) se despierta en la cabaña de pesca por un trueno, con la linterna en la mano.
## Agarra la mochila (el barquito asoma por encima del hombro), sigue al perro que escapó al lago
## y cruza las placas de hielo. Al llegar al perro el hielo se rompe: la linterna se hunde,
## llega la oscuridad, los flashbacks del accidente, el barquito sube encendido y aparece el padre.
## Este script solo ordena la memoria; cada pieza (placas, perro, despertar, flashbacks) vive en su clase.

@export var settings: Memory2Settings
@export var player: Player
@export var subtitles: SubtitleDisplay
@export var world_environment: WorldEnvironment
@export var lightning: LightningController
@export var wake_up: WakeUpIntro
@export var flashback: FlashbackOverlay
@export var debug_tools: DebugTools
@export var dog: DogNpc
## Sus hijos (Marker3D) son los puntos por los que corre el perro, en orden.
@export var dog_path: Node3D
## Sus hijos son las placas de hielo.
@export var plates_root: Node3D
## La placa donde espera el perro: no se agrieta, la rompe el final.
@export var dog_plate: IcePlate
@export var backpack: EquipPickup
@export var item_gate: ItemGate
@export var flashlight_view: HeldItemView
@export var boat_view: HeldItemView
## Donde reaparece si cae al agua sin haber pisado ninguna placa firme.
@export var shore_respawn: Marker3D
@export var snow: CPUParticles3D
@export var father_light: SpotLight3D
@export var father_hand: Node3D
## Centro de la cabaña (x, z) y medio tamaño: adentro no se ve la nieve.
@export var cabin_center: Vector3 = Vector3(0.0, 0.0, 24.0)
@export var cabin_half_size: Vector2 = Vector2(2.2, 2.2)
## Teclas de prueba (8 vuelo, 9 luz de rayo fija, 0 ir al final, 7 flashback). Apagar antes de entregar.
@export var debug_keys: bool = true

var _plates: Array[IcePlate] = []
var _head: Node3D
var _camera: Camera3D
var _last_safe: Vector3
var _falling: bool = false
var _ending: bool = false
var _started: bool = false
var _flashback_wait: float = 0.0


func _ready() -> void:
	super()
	assert(settings != null and player != null and subtitles != null and world_environment != null, "Memory2Lake: faltan referencias en el Inspector")
	assert(wake_up != null and flashback != null and dog != null and plates_root != null and dog_plate != null, "Memory2Lake: faltan referencias en el Inspector")
	assert(flashlight_view != null and boat_view != null and backpack != null and item_gate != null, "Memory2Lake: faltan referencias en el Inspector")
	_head = player.get_node("Head") as Node3D
	_camera = player.get_node("Head/Camera3D") as Camera3D
	_last_safe = shore_respawn.global_position if shore_respawn != null else player.global_position
	for child: Node in plates_root.get_children():
		if child is IcePlate:
			var plate: IcePlate = child as IcePlate
			plate.player = player
			plate.cracking.connect(_on_plate_cracking)
			_plates.append(plate)
	backpack.equipped.connect(_on_backpack_equipped)
	item_gate.blocked.connect(func() -> void: subtitles.show_line(settings.gate_line, settings.line_duration))
	item_gate.arm()
	if debug_tools != null:
		debug_tools.enabled = debug_keys
		debug_tools.skip_requested.connect(_debug_skip_to_dog)
		debug_tools.flashback_requested.connect(func() -> void: flashback.play(1))
	if snow != null:
		snow.top_level = true
	if father_light != null:
		father_light.visible = false
		father_light.light_energy = 0.0
	if father_hand != null:
		father_hand.visible = false
	_apply_night(0.0)
	_begin.call_deferred()


func _begin() -> void:
	if lightning != null:
		lightning.start()
	wake_up.thunder_struck.connect(func() -> void: subtitles.show_line(settings.radio_line, settings.line_duration * 1.4), CONNECT_ONE_SHOT)
	await wake_up.play()
	_started = true
	flashlight_view.equip()
	subtitles.show_line(settings.dog_line, settings.line_duration)
	var points: Array[Vector3] = []
	for marker: Node in dog_path.get_children():
		points.append((marker as Node3D).global_position)
	dog.run_along(points)


func _process(delta: float) -> void:
	if snow != null:
		snow.global_position = player.global_position + Vector3(0.0, 7.0, 0.0)
		# Dentro de la cabaña no nieva.
		var p: Vector3 = player.global_position
		snow.visible = not _ending and not (absf(p.x - cabin_center.x) < cabin_half_size.x and absf(p.z - cabin_center.z) < cabin_half_size.y)
	_flashback_wait = maxf(_flashback_wait - delta, 0.0)
	if _ending:
		return
	var night: float = clampf(inverse_lerp(settings.darken_start_z, settings.darken_end_z, player.global_position.z), 0.0, 1.0)
	_apply_night(night)
	if debug_tools != null and debug_tools.is_flying:
		return
	_track_safe_ground()
	if not _falling and player.global_position.y < settings.water_level - settings.fall_depth:
		_fall_in_water()
	if _started and not _falling and dog.is_waiting \
			and player.global_position.distance_to(dog.global_position) < settings.ending_radius:
		_play_ending()


# ---------- Cruce del lago ----------

## Recuerda dónde reaparecer: la última placa firme pisada (o la orilla).
func _track_safe_ground() -> void:
	if not player.is_on_floor():
		return
	for plate: IcePlate in _plates:
		if plate.has_player():
			if not plate.is_cracked:
				_last_safe = plate.global_position + Vector3(0.0, plate.size.y * 0.5 + 0.3, 0.0)
			return
	if player.global_position.y > -0.05:
		_last_safe = player.global_position


func _on_plate_cracking(_plate: IcePlate) -> void:
	if _ending:
		return
	subtitles.show_line(settings.crack_line, settings.line_duration * 0.6)
	if _flashback_wait <= 0.0 and randf() < settings.crack_flashback_chance:
		_flashback_wait = settings.flashback_cooldown
		flashback.play(1)


## Cayó al agua: negro, frío, y vuelve a la última placa firme. Nunca es game over.
func _fall_in_water() -> void:
	_falling = true
	player.set_physics_process(false)
	subtitles.show_line(settings.fall_line, settings.line_duration)
	await ScreenFade.fade_out(settings.fall_fade_time)
	for plate: IcePlate in _plates:
		if plate.is_broken or plate.is_cracked:
			plate.reset()
	player.global_position = _last_safe
	player.velocity = Vector3.ZERO
	await get_tree().create_timer(settings.fall_black_time).timeout
	player.set_physics_process(true)
	await ScreenFade.fade_in(settings.fall_fade_time)
	_falling = false


func _on_backpack_equipped(_from: Transform3D) -> void:
	boat_view.equip()


## Atardecer → noche según qué tan lejos de la orilla está el jugador (0 = orilla, 1 = noche).
func _apply_night(amount: float) -> void:
	var ambient: float = lerpf(settings.dusk_ambient, settings.night_ambient, amount)
	var sky: float = lerpf(settings.dusk_sky, settings.night_sky, amount)
	world_environment.environment.fog_light_color = settings.dusk_fog_color.lerp(settings.night_fog_color, amount)
	if lightning != null:
		lightning.set_base_levels(ambient, sky)
	else:
		world_environment.environment.ambient_light_energy = ambient
		world_environment.environment.background_energy_multiplier = sky


# ---------- Final: el hielo se rompe ----------

func _play_ending() -> void:
	if _ending:
		return
	_ending = true
	dog.stop()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.velocity = Vector3.ZERO
	# Durante la cinemática nada lo empuja (ni la placa que se hunde).
	player.collision_layer = 0
	player.collision_mask = 0
	subtitles.show_line(settings.crack_line, settings.shake_time)
	var env: Environment = world_environment.environment

	# 1. El hielo tiembla.
	var shake: Tween = create_tween()
	shake.tween_method(func(k: float) -> void:
		_camera.rotation.z = sin(k * 60.0) * 0.025 * k
		_camera.position.y = sin(k * 47.0) * 0.02 * k, 0.0, 1.0, settings.shake_time)
	await shake.finished
	_camera.rotation.z = 0.0
	_camera.position.y = 0.0

	# 2. Se rompe y caen los dos al agua.
	dog_plate.shatter()
	if lightning != null:
		lightning.stop()
		lightning.flash_now(0.6)
	var fall: Tween = create_tween().set_parallel(true)
	fall.tween_property(player, "global_position:y", settings.water_level - settings.underwater_depth, settings.fall_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(dog, "global_position:y", settings.water_level - 3.0, settings.fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(_head, "rotation:x", deg_to_rad(-25.0), settings.fall_time)
	await get_tree().create_timer(settings.fall_time * 0.45).timeout
	_set_underwater(env)
	await fall.finished
	dog.visible = false

	# 3. La linterna se le cae y se hunde, girando y apagándose.
	var flashlight: Node3D = flashlight_view
	flashlight_view.is_equipped = false
	flashlight.reparent(self, true)
	var spot: SpotLight3D = null
	for child: Node in flashlight.find_children("*", "SpotLight3D", true, false):
		spot = child as SpotLight3D
	var start_energy: float = spot.light_energy if spot != null else 0.0
	var sink: Tween = create_tween().set_parallel(true)
	sink.tween_property(flashlight, "global_position", flashlight.global_position + Vector3(0.3, -settings.flashlight_sink_depth, -1.5), settings.flashlight_sink_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(flashlight, "rotation", flashlight.rotation + Vector3(-1.4, 2.6, 0.8), settings.flashlight_sink_time)
	sink.tween_property(_head, "rotation:x", deg_to_rad(-55.0), settings.flashlight_sink_time * 0.6)
	if spot != null:
		sink.tween_method(func(k: float) -> void:
			var flicker: float = 1.0 if k < 0.55 else (0.25 + 0.75 * float(randf() > k * 0.7))
			spot.light_energy = start_energy * (1.0 - k) * flicker, 0.0, 1.0, settings.flashlight_sink_time)
	await sink.finished
	flashlight.visible = false

	# 4. Oscuridad total y los flashbacks del accidente.
	if lightning != null:
		lightning.set_base_levels(0.0, 0.0)
	env.ambient_light_energy = 0.0
	await get_tree().create_timer(settings.dark_time).timeout
	await flashback.play(settings.ending_flashbacks, true)
	flashback.clear()

	# 5. El barquito sube encendido.
	boat_view.is_equipped = false
	var boat: Node3D = boat_view
	boat.reparent(self, true)
	boat.visible = true
	# En el sueño el barquito se ve más grande que en la mochila.
	boat.scale = Vector3.ONE * 2.5
	for child: Node in boat.find_children("*", "OmniLight3D", true, false):
		(child as OmniLight3D).light_energy = 3.0
	var forward: Vector3 = -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	boat.global_position = _camera.global_position + forward * 1.4 + Vector3.DOWN * 1.2
	var rise: Tween = create_tween().set_parallel(true)
	rise.tween_property(boat, "global_position", _camera.global_position + forward * 1.3 + Vector3.UP * 0.75, settings.boat_rise_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rise.tween_property(boat, "rotation:y", boat.rotation.y + 1.2, settings.boat_rise_time)
	rise.tween_property(_head, "rotation:x", deg_to_rad(32.0), settings.boat_rise_time)
	await rise.finished

	# 6. La luz del padre desde arriba, su mano y su voz.
	if father_light != null:
		# Justo debajo del agujero del hielo, arriba del protagonista.
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
		# La mano baja desde el agujero del hielo, con los dedos hacia el protagonista.
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
		lightning.set_held(false)
		lightning.set_sky_visible(false)
		lightning.set_base_levels(0.02, 0.0)
	env.background_energy_multiplier = 0.0
	env.ambient_light_energy = 0.02
	if snow != null:
		snow.visible = false


## SOLO PARA PRUEBAS (tecla 0): lleva al jugador junto al perro y arranca el final.
func _debug_skip_to_dog() -> void:
	if _ending:
		return
	if not dog.is_waiting:
		var points: Array[Vector3] = []
		for marker: Node in dog_path.get_children():
			points.append((marker as Node3D).global_position)
		dog.global_position = points[points.size() - 1]
		dog.stop()
		dog.is_waiting = true
	if debug_tools != null and debug_tools.is_flying:
		debug_tools.set_flying(false)
	player.global_position = dog.global_position + Vector3(0.0, 0.3, 1.2)
	player.velocity = Vector3.ZERO
	_started = true
	_play_ending()
