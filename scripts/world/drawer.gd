class_name Drawer
extends Interactable
## Cajón que se abre y se cierra con `interact`. Todo lo que cuelga de este nodo sale con él
## (por ejemplo un libro adentro). La colisión del cajón tiene que ser solo el frente, así
## la mira llega a lo que hay adentro cuando está abierto.

@export var settings: DrawerSettings
@export var open_prompt: String = "(E) Abrir cajón"
@export var close_prompt: String = "(E) Cerrar cajón"
## Hacia dónde sale, en coordenadas del cajón (por defecto, hacia su +Z).
@export var slide_axis: Vector3 = Vector3(0, 0, 1)

var is_open: bool = false

var _closed_position: Vector3
var _tween: Tween
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	assert(settings != null, "Drawer: falta asignar un DrawerSettings en el Inspector")
	_closed_position = position
	prompt_text = open_prompt
	_audio = AudioStreamPlayer3D.new()
	add_child(_audio)


func interact(by: Node3D) -> void:
	super(by)
	set_open(not is_open)


func set_open(open: bool) -> void:
	is_open = open
	prompt_text = close_prompt if open else open_prompt
	var axis: Vector3 = (transform.basis * slide_axis).normalized()
	var target: Vector3 = _closed_position + (axis * settings.open_distance if open else Vector3.ZERO)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if open and settings.overshoot > 0.0:
		_tween.tween_property(self, "position", target + axis * settings.overshoot, settings.slide_time * 0.8) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "position", target, settings.slide_time * 0.2).set_trans(Tween.TRANS_SINE)
	else:
		_tween.tween_property(self, "position", target, settings.slide_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var sound: AudioStream = settings.open_sound if open else settings.close_sound
	if sound != null:
		_audio.stream = sound
		_audio.play()
