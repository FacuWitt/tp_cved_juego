class_name Memory1Room
extends Memory
## Memoria 1: la habitación de la abuela (etapa 0, greybox).
## La abuela le pide que ordene los juguetes; la canción de cuna dice el orden.
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


func _ready() -> void:
	super()
	assert(settings != null, "Memory1Room: falta asignar un Memory1Settings")
	assert(puzzle != null and door_hinge != null and boat_light != null, "Memory1Room: faltan referencias en el Inspector")
	assert(exit != null and subtitles != null, "Memory1Room: faltan referencias en el Inspector")
	_door_closed_rotation = door_hinge.rotation_degrees.y
	boat_light.light_energy = 0.0
	exit.enabled = false
	puzzle.solved.connect(_on_puzzle_solved)
	puzzle.failed.connect(_on_puzzle_failed)
	exit.reached.connect(_on_exit_reached)
	_play_intro()


func _play_intro() -> void:
	await get_tree().create_timer(settings.intro_line_delay).timeout
	# Si el jugador ya resolvió algo en la pausa, no pisar ese texto.
	if not puzzle.is_solved and subtitles.text == "":
		subtitles.show_line(settings.intro_line, settings.intro_line_duration)


func _on_puzzle_solved() -> void:
	subtitles.show_line(settings.solved_line, settings.solved_line_duration)

	var glow: Tween = create_tween()
	glow.tween_property(boat_light, "light_energy", settings.boat_glow_energy, settings.boat_glow_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var door: Tween = create_tween()
	door.tween_interval(settings.door_open_delay)
	door.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation + settings.door_open_angle, settings.door_open_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	door.tween_callback(func() -> void: exit.enabled = true)


func _on_puzzle_failed() -> void:
	subtitles.show_line(settings.failed_line, settings.failed_line_duration)

	var step: float = settings.door_shake_time / 4.0
	var shake: Tween = create_tween()
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation + settings.door_shake_angle, step)
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation - settings.door_shake_angle, step)
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation + settings.door_shake_angle * 0.5, step)
	shake.tween_property(door_hinge, "rotation_degrees:y", _door_closed_rotation, step)


func _on_exit_reached() -> void:
	# La memoria la da por completada el propio MemoryExit (ver MemoryExit._on_body_entered).
	subtitles.show_line(settings.exit_line, 0.0)
