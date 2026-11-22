class_name Memory1Room
extends Memory
## Memoria 1: la habitación de la abuela.
## La abuela le pide que ponga los juguetes en la alfombra del mar; la canción de cuna dice el orden.
## Los juguetes están repartidos por la pieza y la luna está en alto: hay que subirse al banquito.
## Conecta el puzzle con sus consecuencias: barquito que se enciende, voz, puerta y salida.
## Hereda de Memory: la salida (MemoryExit) la completa y GameFlow carga la siguiente.
## No sabe cuál es la memoria siguiente.

@export var settings: Memory1Settings
@export var puzzle: SequencePuzzle
@export var door_hinge: Node3D
@export var boat_light: OmniLight3D
@export var exit: MemoryExit
@export var subtitles: SubtitleDisplay

var _door_closed_rotation: float = 0.0
var _last_reach_hint: float = -INF
var _piece_audio: AudioStreamPlayer = null
var _door_audio: AudioStreamPlayer3D = null
var _voice_audio: AudioStreamPlayer = null
var _own_voice_audio: AudioStreamPlayer = null


func _ready() -> void:
	super()
	assert(settings != null, "Memory1Room: falta asignar un Memory1Settings")
	assert(puzzle != null and door_hinge != null and boat_light != null, "Memory1Room: faltan referencias en el Inspector")
	assert(exit != null and subtitles != null, "Memory1Room: faltan referencias en el Inspector")
	_door_closed_rotation = door_hinge.rotation_degrees.y
	boat_light.light_energy = 0.0
	exit.enabled = false
	_setup_audio()
	puzzle.piece_checked.connect(_on_piece_checked)
	puzzle.solved.connect(_on_puzzle_solved)
	puzzle.failed.connect(_on_puzzle_failed)
	exit.reached.connect(_on_exit_reached)
	for node: Node in find_children("*", "PickupObject", true, false):
		(node as PickupObject).reach_failed.connect(_on_reach_failed)
	_play_intro()


## Crea los reproductores de los sonidos del puzzle y de la puerta.
func _setup_audio() -> void:
	_piece_audio = AudioStreamPlayer.new()
	_piece_audio.bus = settings.piece_sound_bus
	add_child(_piece_audio)
	_voice_audio = AudioStreamPlayer.new()
	_voice_audio.bus = settings.voice_bus
	add_child(_voice_audio)
	_own_voice_audio = AudioStreamPlayer.new()
	_own_voice_audio.bus = settings.own_voice_bus
	add_child(_own_voice_audio)
	# Los de la puerta salen de la puerta misma, así se escucha de dónde vienen.
	_door_audio = AudioStreamPlayer3D.new()
	_door_audio.bus = settings.door_sound_bus
	_door_audio.max_db = 24.0  # el tope por defecto (3 dB) recortaría sonidos con el volumen subido
	door_hinge.add_child(_door_audio)


func _play_intro() -> void:
	await get_tree().create_timer(settings.intro_line_delay).timeout
	# Si el jugador ya resolvió algo en la pausa, no pisar ese texto.
	if not puzzle.is_solved and subtitles.text == "":
		subtitles.show_line(settings.intro_line, settings.intro_line_duration)


## Quiso agarrar algo que está en alto (la luna del estante): la pista es subirse al banquito.
func _on_reach_failed() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_reach_hint < settings.reach_hint_cooldown:
		return
	_last_reach_hint = now
	subtitles.show_line(settings.reach_hint_line, settings.reach_hint_duration)
	if settings.reach_hint_voice != null:
		_own_voice_audio.stream = settings.reach_hint_voice
		_own_voice_audio.volume_db = settings.reach_hint_voice_volume_db
		_own_voice_audio.play()


## Se colocó una pieza: suena distinto si va en ese casillero o no.
func _on_piece_checked(_index: int, correct: bool) -> void:
	if not settings.piece_feedback_enabled:
		return
	if correct:
		_play_piece_sound(settings.piece_correct_sound, settings.piece_correct_volume_db)
	else:
		_play_piece_sound(settings.piece_incorrect_sound, settings.piece_incorrect_volume_db)


## Suena un sonido del puzzle (si hay uno asignado).
func _play_piece_sound(sound: AudioStream, volume_db: float) -> void:
	if sound == null:
		return
	_piece_audio.stream = sound
	_piece_audio.volume_db = volume_db
	_piece_audio.play()


## Suena un sonido de la puerta (si hay uno asignado).
func _play_door_sound(sound: AudioStream, volume_db: float) -> void:
	if sound == null:
		return
	_door_audio.stream = sound
	_door_audio.volume_db = volume_db
	_door_audio.play()


## La voz que felicita al resolver el puzzle (si hay una asignada).
func _play_solved_voice() -> void:
	if settings.solved_voice == null:
		return
	await get_tree().create_timer(settings.solved_voice_delay).timeout
	_voice_audio.stream = settings.solved_voice
	_voice_audio.volume_db = settings.solved_voice_volume_db
	_voice_audio.play()


func _on_puzzle_solved() -> void:
	subtitles.show_line(settings.solved_line, settings.solved_line_duration)
	_play_solved_voice()

	var glow: Tween = create_tween()
	glow.tween_property(boat_light, "light_energy", settings.boat_glow_energy, settings.boat_glow_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var door: Tween = create_tween()
	door.tween_interval(settings.door_open_delay)
	door.tween_callback(_play_door_sound.bind(settings.door_open_sound, settings.door_open_volume_db))
	door.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation + settings.door_open_angle, settings.door_open_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	door.tween_callback(func() -> void:
		exit.enabled = true
	)


func _on_puzzle_failed() -> void:
	subtitles.show_line(settings.failed_line, settings.failed_line_duration)
	_play_door_sound(settings.door_knock_sound, settings.door_knock_volume_db)

	var step: float = settings.door_shake_time / 4.0
	var shake: Tween = create_tween()
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation + settings.door_shake_angle, step)
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation - settings.door_shake_angle, step)
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation + settings.door_shake_angle * 0.5, step)
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation, step)


func _on_exit_reached() -> void:
	# La memoria la da por completada el propio MemoryExit (ver MemoryExit._on_body_entered).
	subtitles.show_line(settings.exit_line, 0.0)
