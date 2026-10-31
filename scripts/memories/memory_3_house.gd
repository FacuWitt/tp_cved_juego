class_name Memory3House
extends Memory
## Memoria 3: la casa (la de la abuela, ahora suya), la madrugada antes de embarcar.
## El protagonista, adulto, se despierta en la mesa de la cocina por un trueno, con el barquito en
## la mano. Tiene que llegar al cuarto de su hija para despedirse, pero la casa se repite: al final
## del pasillo hay tres puertas y una sola es la buena (la que tiene la luz del velador abajo).
## La buena lleva al tramo siguiente; las otras devuelven a la cocina, con la casa más degradada
## (pasillo más largo, más agua, fotos más borrosas), pero se conserva el tramo ganado.
## En el cuarto (el de la M1, redecorado) le deja el barquito a la hija: "Cuidámelo hasta que vuelva".
## La casa se estabiliza, se abre el camino a la entrada y al salir por la puerta de casa
## la memoria se completa (GameFlow funde a negro y empieza la M4).
## Este script solo ordena la memoria: el pasillo, los umbrales y la salida viven en sus clases.

enum Stage { WAKE, MAZE, ROOM, GIVING, STABLE }

## Frames de física después de un traslado en los que se ignoran los umbrales (margen técnico, no de feel).
const CARRY_GRACE_FRAMES: int = 3

@export var settings: Memory3Settings
@export var player: Player
@export var subtitles: SubtitleDisplay
@export var prompt: InteractionPrompt
@export var lightning: LightningController
@export var wake_up: WakeUpIntro
@export var debug_tools: DebugTools
## El barquito en la mano del protagonista.
@export var boat_view: HeldItemView
## Opcional: efectos de sueño (imagen, cámara, piernas pesadas, parpadeos). Siguen a la degradación.
@export var dream: DreamEffects
## Opcional: cosas que cambian de lugar cuando no se las mira.
@export var shifter: DreamShifter
## Opcional: el pasillo se cierra a las espaldas del jugador.
@export var dead_end: HallwayDeadEnd
## Opcional: el agua que sube por el piso de la casa.
@export var rising_water: RisingWater

@export_group("Laberinto")
@export var hallway: BendingHallway
## Los umbrales detrás de las tres puertas del rellano (el índice de cada uno es su puerta).
@export var portals: Array[LoopPortal] = []
## Las bisagras de las tres puertas del rellano, en el mismo orden que los umbrales.
@export var landing_doors: Array[Node3D] = []
## La luz cálida bajo cada puerta del rellano (se prende solo la de la puerta buena).
@export var door_glows: Array[Node3D] = []
## Destino de la puerta buena: el comienzo del pasillo, saliendo de la cocina.
@export var hallway_start: Node3D
## Destino de las puertas malas: el pasillito oscuro del fondo de la cocina.
@export var kitchen_back: Node3D
## Destino de la puerta buena del último tramo: el pasillo del cuarto de la hija.
@export var room_arrival: Node3D
## La voz de la hija: suena detrás de la puerta buena para guiar con el oído.
@export var daughter_voice: AudioStreamPlayer3D

@export_group("Degradación")
## Contenedores de charcos: se muestran más hijos cuanto más degradada está la casa.
@export var water: Array[Node3D] = []
## Fotos sueltas que se borran (transparencia) con la degradación. Hoy el pasillo usa `repeating_photos`.
@export var photos: Array[Node3D] = []
## La misma foto repetida a lo largo del pasillo, cada vez más borrosa.
@export var repeating_photos: RepeatingPhotos
## Luces frías: se hacen más fuertes con la degradación.
@export var cold_lights: Array[Light3D] = []

@export_group("Cuarto y salida")
## Bisagra de la puerta del cuarto de la hija (la del layout de la M1).
@export var room_door: Node3D
## La hija: un cuerpo físico al que se apunta para darle el barquito.
@export var daughter: CollisionObject3D
## El barquito en manos de la hija (oculto hasta la entrega).
@export var given_boat: Node3D
## La pared del fondo del pasillo del cuarto: al estabilizarse la casa desaparece y deja pasar a la entrada.
@export var room_end_wall: CSGBox3D
## La salida del layout de la M1 (queda apagada: en esta memoria la salida es la puerta de casa).
@export var room_layout_exit: MemoryExit
## Bisagra de la puerta de entrada de la casa.
@export var front_door: Node3D
## Salida real de la memoria, del otro lado de la puerta de entrada.
@export var exit: MemoryExit
## Teclas de prueba (8 vuelo, 9 luz de rayo fija, 0 saltar etapa). Apagar antes de entregar.
@export var debug_keys: bool = true

var stage: Stage = Stage.WAKE
## Tramo actual del pasillo (0 = el primero).
var segment: int = 0
## Cuántas veces eligió mal.
var mistakes: int = 0

var _degradation: float = 0.0
var _creep: float = 0.0
## La parte de `_creep` que ya se aplicó al pasillo (se rearma de a pasos, no en cada frame).
var _applied_creep: float = 0.0
## Frame de física del último traslado (ver `_on_portal_crossed`).
var _carry_frame: int = -100
var _busy: bool = false
var _plea_said: bool = false
var _ray: RayCast3D
## Cuerpo de cada puerta (lo que toca la mira) -> su bisagra.
var _door_by_body: Dictionary = {}
var _door_rest: Dictionary = {}
var _open_doors: Dictionary = {}
## Bisagra -> la animación de apertura en curso (para cortarla si hay que cerrar la puerta antes de que termine).
var _door_tweens: Dictionary = {}
var _cold_base: Array[float] = []
var _glow_lights: Array[OmniLight3D] = []


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
	# En la M1 el layout trae su propia salida; acá la salida es la puerta de casa.
	if room_layout_exit != null:
		room_layout_exit.enabled = false
		for label: Node in room_layout_exit.find_children("*", "Label3D", true, false):
			(label as Label3D).visible = false

	if debug_tools != null:
		debug_tools.enabled = debug_keys
		debug_tools.skip_requested.connect(_debug_skip)
	if dream != null and shifter != null:
		# En el negro del parpadeo las cosas cambian aunque se las esté mirando.
		dream.blinked.connect(shifter.shift_all)
	if dream != null:
		dream.stuck_started.connect(_on_stuck)

	if daughter_voice != null:
		daughter_voice.stream = settings.voice_stream
		daughter_voice.unit_size = settings.voice_unit_size
		daughter_voice.max_distance = settings.voice_max_distance
		daughter_voice.finished.connect(_on_voice_finished)

	_apply_degradation(settings.base_degradation)
	_refresh_segment()
	_begin.call_deferred()


func _begin() -> void:
	wake_up.thunder_struck.connect(func() -> void: subtitles.show_line(settings.wake_line, settings.line_duration), CONNECT_ONE_SHOT)
	await wake_up.play()
	if lightning != null:
		lightning.start()
	await boat_view.equip()
	stage = Stage.MAZE
	if dream != null:
		dream.start()
	if daughter_voice != null and daughter_voice.stream != null:
		daughter_voice.play()
	await get_tree().create_timer(settings.first_call_delay).timeout
	if stage == Stage.MAZE and segment == 0:
		subtitles.show_line(settings.first_call_line, settings.line_duration)


func _process(delta: float) -> void:
	_update_prompt()
	if stage == Stage.MAZE:
		_update_creep(delta)
	if dream != null:
		var in_maze: bool = stage == Stage.MAZE
		dream.drag = hallway.progress(player.global_position) if in_maze else 0.0
		# "Atrás" es hacia la entrada del tramo donde está parado.
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
	# Todas abren hacia el lado contrario al jugador: la de entrada abre hacia afuera (ángulo negativo).
	var angle: float = -settings.door_open_angle if hinge == front_door else settings.door_open_angle
	var t: Tween = create_tween()
	_door_tweens[hinge] = t
	t.tween_property(hinge, "rotation_degrees:y", float(_door_rest[hinge]) + angle, settings.door_open_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if hinge == room_door and not _plea_said:
		_plea_said = true
		t.tween_callback(func() -> void: subtitles.show_line(settings.plea_line, settings.line_duration))


func _close_landing_doors() -> void:
	for hinge: Node3D in landing_doors:
		# Si todavía se estaba abriendo, se corta la animación: si no, la vuelve a abrir.
		var opening: Tween = _door_tweens.get(hinge) as Tween
		if opening != null and opening.is_valid():
			opening.kill()
		hinge.rotation_degrees.y = _door_rest[hinge]
		_open_doors[hinge] = false


# ---------- Laberinto ----------

func _on_portal_crossed(index: int) -> void:
	if stage != Stage.MAZE:
		return
	# Al trasladarlo, el pasillo se rearma y el rellano se corre: un umbral puede caer justo donde
	# estaba parado antes del salto, y la física avisa ese cruce viejo al frame siguiente. Se ignora.
	if Engine.get_physics_frames() - _carry_frame <= CARRY_GRACE_FRAMES:
		return
	# Mover el cuerpo dentro de la señal de un Area3D puede chocar con la física en curso: se difiere.
	_resolve_door.call_deferred(index, portals[index])


func _resolve_door(index: int, from: LoopPortal) -> void:
	if stage != Stage.MAZE or Engine.get_physics_frames() - _carry_frame <= CARRY_GRACE_FRAMES:
		return
	if index == _good_door():
		_advance(from)
	else:
		_lose_way(from)


## Eligió la puerta buena: pasa al tramo siguiente, o al cuarto si era el último.
## `from` es el umbral por el que pasó (null si lo pidió la tecla de prueba).
func _advance(from: LoopPortal) -> void:
	segment += 1
	if segment >= settings.good_doors.size():
		stage = Stage.ROOM
		if daughter_voice != null:
			daughter_voice.stop()
		_carry(from, room_arrival)
		subtitles.show_line(settings.room_arrival_line, settings.line_duration)
	else:
		_carry(from, hallway_start)
		_refresh_segment()
		subtitles.show_line(_pick(settings.closer_lines, segment - 1, true), settings.line_duration)
	_close_landing_doors()


## Eligió mal: vuelve al fondo de la cocina y la casa se degrada un poco más. El tramo se conserva.
func _lose_way(from: LoopPortal) -> void:
	mistakes += 1
	_carry(from, kitchen_back)
	_apply_degradation(minf(1.0, _degradation + settings.degradation_per_mistake))
	_close_landing_doors()
	if shifter != null:
		# Al volver a la cocina, algo ya no está donde estaba.
		shifter.shift_unseen()
	subtitles.show_line(_pick(settings.farther_lines, mistakes - 1, false), settings.line_duration)


func _carry(from: LoopPortal, destination: Node3D) -> void:
	if from != null:
		from.carry(player, destination, settings.carry_max_offset)
	else:
		# Tecla de prueba: no viene de ningún umbral, aparece un paso adelante del destino.
		player.teleport_to(destination.global_transform.translated_local(Vector3(0.0, 0.0, -1.0)))
	_carry_frame = Engine.get_physics_frames()
	if dead_end != null:
		dead_end.clear()
	_creep = 0.0
	_applied_creep = 0.0
	hallway.set_extra_length(_target_extra())


func _good_door() -> int:
	return settings.good_doors[clampi(segment, 0, settings.good_doors.size() - 1)]


## Prende la luz bajo la puerta buena del tramo actual; cada tramo un poco más fuerte.
func _refresh_segment() -> void:
	# Cada tramo tiene su propia forma, más angosto y más bajo que el anterior.
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
	# La voz se muda detrás de la puerta buena del tramo nuevo.
	if daughter_voice != null:
		daughter_voice.global_position = door_glows[good].global_transform * Vector3(0.0, 1.1, -settings.voice_depth)


## Terminó de sonar la voz: después de una pausa vuelve a llamar (solo mientras busca el cuarto).
func _on_voice_finished() -> void:
	await get_tree().create_timer(settings.voice_interval).timeout
	if stage == Stage.MAZE and not daughter_voice.playing:
		daughter_voice.play()


## El fondo del pasillo se aleja mientras el jugador camina hacia él (solo con la casa degradada).
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
	# El pasillo se rearma de a pasos (rearmarlo en cada frame es costoso).
	if _creep - _applied_creep >= settings.hallway_creep_step or _creep >= limit:
		_applied_creep = _creep
		hallway.set_extra_length(_target_extra() + _applied_creep)


## Cuánto más largo es el último tramo por la degradación.
func _target_extra() -> float:
	return settings.hallway_extra_length * _degradation


## Las piernas dejaron de responder.
func _on_stuck() -> void:
	if not settings.stuck_lines.is_empty():
		subtitles.show_line(settings.stuck_lines[randi() % settings.stuck_lines.size()], settings.line_duration)


# ---------- Degradación ----------

## 0 = la casa intacta, 1 = lo más degradada (más agua, fotos borradas, luz fría más fuerte, pasillo más largo).
func _apply_degradation(level: float) -> void:
	_degradation = clampf(level, 0.0, 1.0)
	if dream != null:
		dream.level = _degradation
	if shifter != null:
		shifter.level = _degradation
	if dead_end != null:
		dead_end.level = _degradation
	if rising_water != null:
		rising_water.level = _degradation
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
	# Cuanto más perdido, más lejos se oye la hija.
	if daughter_voice != null:
		daughter_voice.volume_db = settings.voice_volume_db - settings.voice_degradation_db * _degradation
	# Si el jugador está adentro del pasillo no se le cambia el largo en la cara.
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
	subtitles.show_line(settings.give_line, settings.line_duration)
	await get_tree().create_timer(settings.stabilize_delay).timeout
	await _stabilize()
	_busy = false


## La casa se queda quieta: se seca el agua, la luz fría baja y se abre el camino a la entrada.
func _stabilize() -> void:
	var t: Tween = create_tween()
	t.tween_method(_apply_degradation, _degradation, 0.0, settings.stabilize_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	# La casa ya es real: se apagan los efectos de sueño y todo vuelve a su lugar.
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
	# La memoria la da por completada el propio MemoryExit; GameFlow funde a negro y carga la M4.
	prompt.override_text = ""


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
		Stage.ROOM:
			if not _open_doors.get(room_door, false):
				_open_door(room_door)
			_give_boat()
		Stage.STABLE:
			complete()


## Elige una línea de la lista: con `clamp_last` se queda en la última, si no, vuelve a empezar.
func _pick(lines: PackedStringArray, i: int, clamp_last: bool) -> String:
	if lines.is_empty():
		return ""
	return lines[mini(i, lines.size() - 1)] if clamp_last else lines[i % lines.size()]
