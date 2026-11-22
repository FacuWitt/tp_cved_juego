
class_name Memory3House
extends Memory
## Memoria 3: la casa (la de la abuela, ahora suya), la madrugada antes de embarcar.
## El protagonista, adulto, se despierta en la mesa de la cocina por un trueno, con el barquito en
## la mano. Tiene que llegar al cuarto de su hija para despedirse, pero la casa se repite: al final
## del pasillo hay tres puertas y una sola es la buena (la que tiene la luz del velador abajo).
## La buena da a una sala intermedia (`interludes`: los mensajes, el pasillo del hospital, los
## barcos) que hay que cruzar para llegar al tramo siguiente; las otras devuelven a la cocina, con la casa más degradada
## (pasillo más largo, más agua, fotos más borrosas), pero se conserva el tramo ganado.
## En el cuarto (el de la M1, redecorado) le deja el barquito a la hija: "Cuidámelo hasta que vuelva".
## La casa se estabiliza, se abre el camino a la entrada y al salir por la puerta de casa
## la memoria se completa (GameFlow funde a negro y empieza la M4).
## Este script solo ordena la memoria: el pasillo, los umbrales y la salida viven en sus clases.

enum Stage { WAKE, MAZE, INTERLUDE, ROOM, GIVING, STABLE }

## Frames de física después de un traslado en los que se ignoran los umbrales.
const CARRY_GRACE_FRAMES: int = 3
## Volumen al que un loop queda inaudible.
const SILENT_DB: float = -80.0
## Cuánto baja el ambiente mientras se reproduce una voz.
const VOICE_DUCK_DB: float = 4.0
## Tiempo de transición al bajar o recuperar el ambiente.
const VOICE_DUCK_TIME: float = 0.25
## Intervalo del monitor cardíaco durante el despertar.
const HEARTBEAT_INTERVAL: float = 0.95

@export var settings: Memory3Settings
@export var player: Player
@export var subtitles: SubtitleDisplay
@export var prompt: InteractionPrompt
@export var lightning: LightningController
@export var wake_up: WakeUpIntro
@export var debug_tools: DebugTools
## El barquito en la mano del protagonista.
@export var boat_view: HeldItemView
## Opcional: efectos de sueño.
@export var dream: DreamEffects
## Opcional: cosas que cambian de lugar cuando no se las mira.
@export var shifter: DreamShifter
## Opcional: el pasillo se cierra a las espaldas del jugador.
@export var dead_end: HallwayDeadEnd
## Opcional: el agua que sube por el piso de la casa.
@export var rising_water: RisingWater

@export_group("Laberinto")
@export var hallway: BendingHallway
## Los umbrales detrás de las tres puertas del rellano.
@export var portals: Array[LoopPortal] = []
## Las bisagras de las tres puertas del rellano.
@export var landing_doors: Array[Node3D] = []
## La luz cálida bajo cada puerta del rellano.
@export var door_glows: Array[Node3D] = []
## Destino de la puerta buena.
@export var hallway_start: Node3D
## Destino de las puertas malas.
@export var kitchen_back: Node3D
## Destino de la puerta buena del último tramo.
@export var room_arrival: Node3D
## La voz de la hija.
@export var daughter_voice: AudioStreamPlayer3D
## Salas intermedias.
@export var interludes: Array[InterludeRoom] = []
## El ambiente de la escena.
@export var world_environment: WorldEnvironment

@export_group("Degradación")
@export var water: Array[Node3D] = []
@export var photos: Array[Node3D] = []
@export var repeating_photos: RepeatingPhotos
@export var cold_lights: Array[Light3D] = []

@export_group("Cuarto y salida")
@export var room_door: Node3D
@export var daughter: CollisionObject3D
@export var given_boat: Node3D
@export var room_end_wall: CSGBox3D
@export var room_layout_exit: MemoryExit
@export var front_door: Node3D
@export var exit: MemoryExit
@export var debug_keys: bool = true

var stage: Stage = Stage.WAKE
var segment: int = 0
var mistakes: int = 0

var _degradation: float = 0.0
var _creep: float = 0.0
var _applied_creep: float = 0.0
var _carry_frame: int = -100
var _busy: bool = false
var _plea_said: bool = false
var _ray: RayCast3D
var _door_by_body: Dictionary = {}
var _door_rest: Dictionary = {}
var _open_doors: Dictionary = {}
var _door_tweens: Dictionary = {}
var _cold_base: Array[float] = []
var _glow_lights: Array[OmniLight3D] = []
var _interlude: InterludeRoom
var _ambient_base: float = 0.0
var _sky_base: float = 1.0

# Sonido.
var _ambience: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _line_voice: AudioStreamPlayer
var _ambience_tween: Tween
var _house_sound_enabled: bool = false

## Segundos que faltan para la próxima gota aleatoria.
var _drip_wait: float = 0.0
## Temporizador del goteo sincronizado con el monitor durante el despertar.
var _wake_drip_wait: float = 0.0
var _step_distance: float = 0.0


func _ready() -> void:
	super()
	assert(settings != null and player != null and subtitles != null and prompt != null and wake_up != null and boat_view != null, "Memory3House: faltan referencias en el Inspector")
	assert(hallway != null and hallway_start != null and kitchen_back != null and room_arrival != null, "Memory3House: faltan referencias del laberinto en el Inspector")
	assert(portals.size() == landing_doors.size() and portals.size() == door_glows.size() and portals.size() > 0, "Memory3House: tiene que haber la misma cantidad de umbrales, puertas y luces de puerta")
	assert(room_door != null and daughter != null and given_boat != null and room_end_wall != null and front_door != null and exit != null, "Memory3House: faltan referencias del cuarto y la salida en el Inspector")
	assert(settings.good_doors.size() > 0, "Memory3House: good_doors no puede estar vacío")
	_ray = player.get_node("Head/Camera3D/InteractionRay") as RayCast3D

	for portal: LoopPortal in portals:
		portal.crossed.connect(_on_portal_crossed)
	var hinges: Array[Node3D] = landing_doors.duplicate()
	hinges.append(room_door)
	hinges.append(front_door)
	for hinge: Node3D in hinges:
		_register_door(hinge)
	for glow: Node3D in door_glows:
		var light: OmniLight3D = null
		for child: Node in glow.find_children("*", "OmniLight3D", true, false):
			light = child as OmniLight3D
		_glow_lights.append(light)
	for light: Light3D in cold_lights:
		_cold_base.append(light.light_energy)

	given_boat.visible = false
	exit.enabled = false
	exit.reached.connect(_on_exit_reached)
	if room_layout_exit != null:
		room_layout_exit.enabled = false
		for label: Node in room_layout_exit.find_children("*", "Label3D", true, false):
			(label as Label3D).visible = false

	if debug_tools != null:
		debug_tools.enabled = debug_keys
		debug_tools.skip_requested.connect(_debug_skip)
	if dream != null and shifter != null:
		dream.blinked.connect(shifter.shift_all)
	if dream != null:
		dream.stuck_started.connect(_on_stuck)
	if world_environment != null:
		_ambient_base = world_environment.environment.ambient_light_energy
		_sky_base = world_environment.environment.background_energy_multiplier
	for room: InterludeRoom in interludes:
		if room == null:
			continue
		room.base_ambient = _ambient_base
		room.base_sky = _sky_base
		room.exit_portal.crossed.connect(_on_interlude_exit.bind(room))
		if dream != null:
			dream.blinked.connect(room.on_blink)

	if daughter_voice != null:
		daughter_voice.stream = settings.voice_stream
		daughter_voice.unit_size = settings.voice_unit_size
		daughter_voice.max_distance = settings.voice_max_distance
		daughter_voice.finished.connect(_on_voice_finished)

	_setup_sound()
	_apply_degradation(settings.base_degradation, false)
	_refresh_segment()
	_begin.call_deferred()


func _begin() -> void:
	wake_up.thunder_struck.connect(func() -> void: subtitles.show_line(settings.wake_line, settings.line_duration), CONNECT_ONE_SHOT)
	wake_up.thunder_struck.connect(_on_wake_thunder, CONNECT_ONE_SHOT)
	_fade_house_sound(true)

	# El goteo empieza con el mismo intervalo que el monitor cardíaco.
	_wake_drip_wait = HEARTBEAT_INTERVAL

	await wake_up.play()
	if lightning != null:
		lightning.flashed.connect(_on_lightning_flashed)
		lightning.start()
	_play_sfx(settings.boat_equip_sound, settings.sfx_db)
	await boat_view.equip()
	stage = Stage.MAZE
	if dream != null:
		dream.start()
	if daughter_voice != null and daughter_voice.stream != null:
		_play_daughter_voice()
	await get_tree().create_timer(settings.first_call_delay).timeout
	if stage == Stage.MAZE and segment == 0:
		subtitles.show_line(settings.first_call_line, settings.line_duration)
		_say(settings.first_call_voice)


func _process(delta: float) -> void:
	_update_prompt()
	_update_drips(delta)
	_update_footsteps(delta)
	if stage == Stage.MAZE:
		_update_creep(delta)
	if dream != null:
		var in_maze: bool = stage == Stage.MAZE
		if in_maze:
			dream.drag = hallway.progress(player.global_position)
		else:
			dream.drag = _interlude.drag() if _interlude != null else 0.0
		dream.pull_direction = -hallway.forward_at(player.global_position) if in_maze else Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _busy or stage == Stage.WAKE:
		return
	var target: Object = _aimed()
	if target == null:
		return
	if target == daughter and stage == Stage.ROOM:
		get_viewport().set_input_as_handled()
		_give_boat()
	elif _door_by_body.has(target):
		var hinge: Node3D = _door_by_body[target]
		if not _open_doors.get(hinge, false):
			get_viewport().set_input_as_handled()
			_open_door(hinge)


# ---------- Puertas ----------

func _register_door(hinge: Node3D) -> void:
	_door_rest[hinge] = hinge.rotation_degrees.y
	_open_doors[hinge] = false
	for child: Node in hinge.find_children("*", "CollisionObject3D", true, false):
		_door_by_body[child] = hinge


func _open_door(hinge: Node3D) -> void:
	_open_doors[hinge] = true
	var angle: float = -settings.door_open_angle if hinge == front_door else settings.door_open_angle
	var open_sound: AudioStream = settings.door_open_sound
	if hinge == front_door and settings.front_door_open_sound != null:
		open_sound = settings.front_door_open_sound
	_play_sfx_at(open_sound, hinge.global_position, settings.door_db)
	var t: Tween = create_tween()
	_door_tweens[hinge] = t
	t.tween_property(hinge, "rotation_degrees:y", float(_door_rest[hinge]) + angle, settings.door_open_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if hinge == room_door and not _plea_said:
		_plea_said = true
		t.tween_callback(
			func() -> void:
				subtitles.show_line(settings.plea_line, settings.line_duration)
				_say(settings.plea_voice)
		)


func _close_landing_doors() -> void:
	for hinge: Node3D in landing_doors:
		if _open_doors.get(hinge, false):
			_play_sfx_at(settings.door_close_sound, hinge.global_position, settings.door_db)
		var opening: Tween = _door_tweens.get(hinge) as Tween
		if opening != null and opening.is_valid():
			opening.kill()
		hinge.rotation_degrees.y = _door_rest[hinge]
		_open_doors[hinge] = false


# ---------- Laberinto ----------

func _on_portal_crossed(index: int) -> void:
	if stage != Stage.MAZE:
		return
	if Engine.get_physics_frames() - _carry_frame <= CARRY_GRACE_FRAMES:
		return
	_resolve_door.call_deferred(index, portals[index])


func _resolve_door(index: int, from: LoopPortal) -> void:
	if stage != Stage.MAZE or Engine.get_physics_frames() - _carry_frame <= CARRY_GRACE_FRAMES:
		return
	if index == _good_door():
		_advance(from)
	else:
		_lose_way(from)


func _advance(from: LoopPortal) -> void:
	var room: InterludeRoom = interludes[segment] if segment < interludes.size() else null
	_close_landing_doors()
	_play_sfx(settings.good_door_sound, settings.sfx_db)
	if room == null:
		_next_segment(from)
		return
	stage = Stage.INTERLUDE
	_fade_house_sound(false)
	_interlude = room
	if daughter_voice != null:
		_stop_daughter_voice()
	_carry(from, room.entry)
	room.level = _degradation
	room.enter(player, world_environment.environment if world_environment != null else null, lightning)


func _on_interlude_exit(_index: int, room: InterludeRoom) -> void:
	if stage != Stage.INTERLUDE or room != _interlude:
		return
	_leave_interlude.call_deferred(room.exit_portal)


func _leave_interlude(from: LoopPortal) -> void:
	if stage != Stage.INTERLUDE:
		return
	_interlude.leave()
	_interlude = null
	stage = Stage.MAZE
	_fade_house_sound(true)
	_next_segment(from)


func _next_segment(from: LoopPortal) -> void:
	segment += 1
	if segment >= settings.good_doors.size():
		stage = Stage.ROOM
		if daughter_voice != null:
			_stop_daughter_voice()
		_carry(from, room_arrival)
		subtitles.show_line(settings.room_arrival_line, settings.line_duration)
		_say(settings.room_arrival_voice)
	else:
		_carry(from, hallway_start)
		_refresh_segment()
		if daughter_voice != null and daughter_voice.stream != null and not daughter_voice.playing:
			_play_daughter_voice()
		subtitles.show_line(_pick(settings.closer_lines, segment - 1, true), settings.line_duration)
		_say(_pick_voice(settings.closer_voices, settings.closer_lines.size(), segment - 1, true))


func _lose_way(from: LoopPortal) -> void:
	mistakes += 1
	_carry(from, kitchen_back)
	_apply_degradation(minf(1.0, _degradation + settings.degradation_per_mistake))
	_close_landing_doors()
	_play_sfx(settings.wrong_door_sound, settings.sfx_db)
	if shifter != null:
		shifter.shift_unseen()
	subtitles.show_line(_pick(settings.farther_lines, mistakes - 1, false), settings.line_duration)
	_say(_pick_voice(settings.farther_voices, settings.farther_lines.size(), mistakes - 1, false))


func _carry(from: LoopPortal, destination: Node3D) -> void:
	if from != null:
		from.carry(player, destination, settings.carry_max_offset)
	else:
		player.teleport_to(destination.global_transform.translated_local(Vector3(0.0, 0.0, -1.0)))
	_carry_frame = Engine.get_physics_frames()
	if dead_end != null:
		dead_end.clear()
	_creep = 0.0
	_applied_creep = 0.0
	hallway.set_extra_length(_target_extra())


func _good_door() -> int:
	return settings.good_doors[clampi(segment, 0, settings.good_doors.size() - 1)]


func _refresh_segment() -> void:
	var shape_index: int = segment
	hallway.set_shape(
		settings.segment_shapes[mini(shape_index, settings.segment_shapes.size() - 1)] if not settings.segment_shapes.is_empty() else "8",
		settings.segment_widths[mini(shape_index, settings.segment_widths.size() - 1)] if not settings.segment_widths.is_empty() else 1.6,
		settings.segment_heights[mini(shape_index, settings.segment_heights.size() - 1)] if not settings.segment_heights.is_empty() else 2.6)
	var good: int = _good_door()
	for i: int in door_glows.size():
		door_glows[i].visible = i == good
		if _glow_lights[i] != null:
			_glow_lights[i].light_energy = settings.door_glow_energy + settings.door_glow_step * segment
	if daughter_voice != null:
		daughter_voice.global_position = door_glows[good].global_transform * Vector3(0.0, 1.1, -settings.voice_depth)


func _on_voice_finished() -> void:
	_update_voice_ducking()
	await get_tree().create_timer(settings.voice_interval).timeout
	if stage == Stage.MAZE and not daughter_voice.playing:
		_play_daughter_voice()


func _play_daughter_voice() -> void:
	if daughter_voice == null:
		return
	daughter_voice.play()
	_update_voice_ducking()


func _stop_daughter_voice() -> void:
	if daughter_voice == null:
		return
	daughter_voice.stop()
	_update_voice_ducking()


func _update_creep(delta: float) -> void:
	if _degradation <= 0.0:
		return
	var forward: Vector3 = hallway.forward_at(player.global_position)
	if forward == Vector3.ZERO or forward.dot(player.velocity) <= 0.5:
		return
	var limit: float = settings.hallway_creep_max * _degradation
	if _creep >= limit:
		return
	_creep = minf(_creep + settings.hallway_creep_speed * _degradation * delta, limit)
	if _creep - _applied_creep >= settings.hallway_creep_step or _creep >= limit:
		_applied_creep = _creep
		hallway.set_extra_length(_target_extra() + _applied_creep)
		_play_glitch()


func _target_extra() -> float:
	return settings.hallway_extra_length * _degradation


func _on_stuck() -> void:
	_play_sfx(settings.stuck_sound, settings.sfx_db)
	if not settings.stuck_lines.is_empty():
		subtitles.show_line(settings.stuck_lines[randi() % settings.stuck_lines.size()], settings.line_duration)


# ---------- Degradación ----------

func _apply_degradation(level: float, play_glitch: bool = true) -> void:
	var previous_degradation: float = _degradation
	_degradation = clampf(level, 0.0, 1.0)

	if play_glitch and _degradation > previous_degradation + 0.001:
		_play_glitch()

	if dream != null:
		dream.level = _degradation
	if shifter != null:
		shifter.level = _degradation
	if dead_end != null:
		dead_end.level = _degradation
	if rising_water != null:
		rising_water.level = _degradation

	for room: InterludeRoom in interludes:
		if room != null:
			room.level = _degradation

	for container: Node3D in water:
		var count: int = container.get_child_count()
		var shown: int = roundi(_degradation * count)
		for i: int in count:
			(container.get_child(i) as Node3D).visible = i < shown

	for photo: Node3D in photos:
		for child: Node in photo.find_children("*", "GeometryInstance3D", true, false):
			(child as GeometryInstance3D).transparency = _degradation * settings.photo_fade_max

	for i: int in cold_lights.size():
		cold_lights[i].light_energy = _cold_base[i] * (1.0 + _degradation * settings.cold_light_boost)

	hallway.set_light_scale(1.0 + _degradation * settings.cold_light_boost)

	if repeating_photos != null:
		repeating_photos.set_degradation(_degradation)

	if daughter_voice != null:
		daughter_voice.volume_db = settings.voice_volume_db - settings.voice_degradation_db * _degradation

	if not hallway.contains(player.global_position):
		hallway.set_extra_length(_target_extra() + _applied_creep)


# ---------- Cuarto de la hija ----------

func _give_boat() -> void:
	if not _open_doors.get(room_door, false):
		return
	_busy = true
	stage = Stage.GIVING
	prompt.override_text = ""
	boat_view.unequip()
	given_boat.visible = true
	_play_sfx(settings.give_boat_sound, settings.sfx_db)
	subtitles.show_line(settings.give_line, settings.line_duration)
	_say(settings.give_voice)
	await get_tree().create_timer(settings.stabilize_delay).timeout
	await _stabilize()
	_busy = false


func _stabilize() -> void:
	_play_sfx(settings.stabilize_sound, settings.sfx_db)
	var t: Tween = create_tween()
	t.tween_method(_apply_degradation, _degradation, 0.0, settings.stabilize_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	if dream != null:
		dream.stop()
	if shifter != null:
		shifter.restore_all()
	if dead_end != null:
		dead_end.clear()
	room_end_wall.use_collision = false
	room_end_wall.visible = false
	exit.enabled = true
	stage = Stage.STABLE
	subtitles.show_line(settings.stable_line, settings.line_duration)


func _on_exit_reached() -> void:
	prompt.override_text = ""
	_fade_house_sound(false)


# ---------- Sonido ----------

func _setup_sound() -> void:
	_ambience = _make_loop("HouseAmbience", settings.ambience_loop)
	_rain = _make_loop("HouseRain", settings.rain_loop)
	if dream != null:
		dream.blinked.connect(_on_blinked)


func _fade_house_sound(on: bool) -> void:
	_house_sound_enabled = on
	_update_house_sound_levels(settings.ambience_fade_time)


func _is_voice_playing() -> bool:
	var line_playing: bool = _line_voice != null and _line_voice.playing
	var daughter_playing: bool = daughter_voice != null and daughter_voice.playing
	return line_playing or daughter_playing


func _update_house_sound_levels(fade_time: float) -> void:
	if _ambience == null and _rain == null:
		return

	if _ambience_tween != null and _ambience_tween.is_valid():
		_ambience_tween.kill()

	var duck: float = VOICE_DUCK_DB if _is_voice_playing() else 0.0
	var ambience_target: float = SILENT_DB
	var rain_target: float = SILENT_DB

	if _house_sound_enabled:
		ambience_target = settings.ambience_db - duck
		rain_target = settings.rain_db - duck

	_ambience_tween = create_tween().set_parallel(true)

	if _ambience != null:
		_ambience_tween.tween_property(_ambience, "volume_db", ambience_target, fade_time)

	if _rain != null:
		_ambience_tween.tween_property(_rain, "volume_db", rain_target, fade_time)


func _update_voice_ducking() -> void:
	await get_tree().process_frame
	_update_house_sound_levels(VOICE_DUCK_TIME)


func _on_wake_thunder() -> void:
	var stream: AudioStream = settings.wake_thunder_sound
	if stream == null:
		stream = _random_stream(settings.thunder_sounds)
	_play_sfx(stream, settings.thunder_db)


func _on_lightning_flashed(strength: float) -> void:
	if settings.thunder_sounds.is_empty():
		return
	var delay: float = randf_range(settings.thunder_delay_min, maxf(settings.thunder_delay_min, settings.thunder_delay_max))
	await get_tree().create_timer(delay).timeout
	_play_sfx(_random_stream(settings.thunder_sounds), settings.thunder_db + linear_to_db(clampf(strength, 0.05, 1.0)))


func _on_blinked() -> void:
	_play_sfx(settings.blink_sound, settings.sfx_db)
	_play_glitch()


## Goteo sincronizado durante el despertar; después conserva el goteo aleatorio original.
func _update_drips(delta: float) -> void:
	if settings.drip_sounds.is_empty() or stage == Stage.INTERLUDE:
		return

	# Durante el despertar, la canilla sigue el intervalo del monitor cardíaco.
	if stage == Stage.WAKE:
		_wake_drip_wait -= delta
		if _wake_drip_wait > 0.0:
			return

		_wake_drip_wait = HEARTBEAT_INTERVAL

		var wake_distance: float = randf_range(
			settings.drip_distance_min,
			maxf(settings.drip_distance_min, settings.drip_distance_max)
		)
		var wake_angle: float = randf() * TAU
		var wake_at: Vector3 = player.global_position + Vector3(
			cos(wake_angle), 0.0, sin(wake_angle)
		) * wake_distance

		_play_sfx_at(_random_stream(settings.drip_sounds), wake_at, settings.drip_db)
		return

	# En las demás etapas se conserva el comportamiento original.
	if _degradation <= 0.0:
		return

	_drip_wait -= delta
	if _drip_wait > 0.0:
		return

	_drip_wait = randf_range(
		settings.drip_interval_min,
		maxf(settings.drip_interval_min, settings.drip_interval_max)
	) / _degradation

	var distance: float = randf_range(
		settings.drip_distance_min,
		maxf(settings.drip_distance_min, settings.drip_distance_max)
	)
	var angle: float = randf() * TAU
	var at: Vector3 = player.global_position + Vector3(
		cos(angle), 0.0, sin(angle)
	) * distance

	_play_sfx_at(_random_stream(settings.drip_sounds), at, settings.drip_db)


func _update_footsteps(delta: float) -> void:
	if settings.footstep_sounds.is_empty() or stage == Stage.WAKE:
		return
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	if not player.is_on_floor() or speed < settings.footstep_min_speed:
		return
	_step_distance += speed * delta
	if _step_distance >= settings.footstep_stride:
		_step_distance = 0.0
		_play_sfx(_random_stream(settings.footstep_sounds), settings.footstep_db)


func _make_loop(node_name: String, stream: AudioStream) -> AudioStreamPlayer:
	if stream == null:
		return null
	var looped: AudioStream = stream.duplicate() as AudioStream
	if looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	elif looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = node_name
	p.stream = looped
	p.volume_db = SILENT_DB
	add_child(p)
	p.play()
	return p


func _play_sfx(stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = _random_pitch()
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Reproduce un sonido aleatorio cuando ocurre un glitch.
func _play_glitch() -> void:
	if settings.glitch_sounds.is_empty():
		return
	_play_sfx(
		_random_stream(settings.glitch_sounds),
		settings.glitch_db
	)


func _play_sfx_at(stream: AudioStream, at: Vector3, volume_db: float) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = _random_pitch()
	add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
	p.play()


func _say(stream: AudioStream) -> void:
	if stream == null:
		return
	if _line_voice == null:
		_line_voice = AudioStreamPlayer.new()
		_line_voice.name = "LineVoice"
		_line_voice.finished.connect(_on_line_voice_finished)
		add_child(_line_voice)
	_line_voice.stream = stream
	_line_voice.volume_db = settings.voice_line_db
	_line_voice.play()
	_update_voice_ducking()


func _on_line_voice_finished() -> void:
	_update_voice_ducking()


func _random_stream(pool: Array[AudioStream]) -> AudioStream:
	return null if pool.is_empty() else pool[randi() % pool.size()]


func _random_pitch() -> float:
	return 1.0 + randf_range(-settings.sfx_pitch_variation, settings.sfx_pitch_variation)


# ---------- Mira y teclas de prueba ----------

func _aimed() -> Object:
	return _ray.get_collider() if _ray.is_colliding() else null


func _update_prompt() -> void:
	var text: String = ""
	if not _busy and stage != Stage.WAKE:
		var target: Object = _aimed()
		if target != null and target == daughter and stage == Stage.ROOM and _open_doors.get(room_door, false):
			text = settings.give_prompt
		elif target != null and _door_by_body.has(target) and not _open_doors.get(_door_by_body[target], false):
			text = settings.open_prompt
	prompt.override_text = text


func _debug_skip() -> void:
	match stage:
		Stage.MAZE:
			_advance(null)
		Stage.INTERLUDE:
			_leave_interlude(null)
		Stage.ROOM:
			if not _open_doors.get(room_door, false):
				_open_door(room_door)
			_give_boat()
		Stage.STABLE:
			complete()


func _pick(lines: PackedStringArray, i: int, clamp_last: bool) -> String:
	if lines.is_empty():
		return ""
	return lines[_pick_index(lines.size(), i, clamp_last)]


func _pick_index(count: int, i: int, clamp_last: bool) -> int:
	return mini(i, count - 1) if clamp_last else i % count


func _pick_voice(voices: Array[AudioStream], line_count: int, i: int, clamp_last: bool) -> AudioStream:
	if line_count <= 0:
		return null
	var index: int = _pick_index(line_count, i, clamp_last)
	return voices[index] if index < voices.size() else null
