class_name TimingQte
extends Control
## Evento rápido de timing: un marcador recorre una barra de ida y vuelta y el jugador
## tiene que apretar `interact` cuando está dentro de la zona buena.
## No tiene game over: si falla avisa con `missed` y quien lo usa decide qué pasa.
## Los valores (velocidad, ancho de la zona) los recibe en begin().

## Apretó dentro de la zona.
signal hit
## Apretó fuera de la zona o dejó pasar el marcador demasiadas veces.
signal missed

const TRACK_SIZE: Vector2 = Vector2(480.0, 22.0)

var _active: bool = false
var _position: float = 0.0
var _direction: float = 1.0
var _speed: float = 1.0
var _zone_start: float = 0.4
var _zone_width: float = 0.2
var _passes: int = 0
var _max_passes: int = 2

var _track: ColorRect
var _zone: ColorRect
var _marker: ColorRect
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -TRACK_SIZE.x * 0.5
	offset_right = TRACK_SIZE.x * 0.5
	offset_top = -170.0
	offset_bottom = -170.0 + TRACK_SIZE.y + 36.0

	_label = Label.new()
	_label.text = "¡AHORA!  (E)"
	_label.size = Vector2(TRACK_SIZE.x, 28.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)

	_track = ColorRect.new()
	_track.color = Color(0.02, 0.04, 0.06, 0.8)
	_track.position = Vector2(0.0, 34.0)
	_track.size = TRACK_SIZE
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_track)

	_zone = ColorRect.new()
	_zone.color = Color(0.85, 0.65, 0.25, 0.9)
	_zone.size = Vector2(10.0, TRACK_SIZE.y)
	_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_zone)

	_marker = ColorRect.new()
	_marker.color = Color(1, 1, 1, 1)
	_marker.size = Vector2(6.0, TRACK_SIZE.y + 10.0)
	_marker.position.y = -5.0
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_marker)

	visible = false


func is_active() -> bool:
	return _active


## Corta el evento sin resultado (p. ej. si el jugador cae al agua).
func cancel() -> void:
	_active = false
	visible = false


## Muestra la barra y arranca el marcador. zone_width y speed salen de Memory4Settings.
func begin(zone_width: float, speed: float, max_passes: int) -> void:
	_zone_width = zone_width
	_speed = speed
	_max_passes = max_passes
	_zone_start = randf_range(0.25, 0.92 - zone_width)
	_zone.position.x = _zone_start * TRACK_SIZE.x
	_zone.size.x = _zone_width * TRACK_SIZE.x
	_zone.color = Color(0.85, 0.65, 0.25, 0.9)
	_position = 0.0
	_direction = 1.0
	_passes = 0
	_active = true
	visible = true


func _process(delta: float) -> void:
	if not _active:
		return
	_position += _direction * _speed * delta
	if _position >= 1.0:
		_position = 1.0
		_direction = -1.0
		_register_pass()
	elif _position <= 0.0:
		_position = 0.0
		_direction = 1.0
		_register_pass()
	_marker.position.x = _position * (TRACK_SIZE.x - _marker.size.x)


func _input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("interact"):
		# Que el jugador no use esta misma pulsación para agarrar objetos.
		get_viewport().set_input_as_handled()
		_resolve(_position >= _zone_start and _position <= _zone_start + _zone_width)


func _register_pass() -> void:
	_passes += 1
	if _passes >= _max_passes * 2:
		_resolve(false)


func _resolve(success: bool) -> void:
	_active = false
	_zone.color = Color(0.4, 0.9, 0.5, 1.0) if success else Color(0.9, 0.25, 0.2, 1.0)
	if success:
		hit.emit()
	else:
		missed.emit()
	await get_tree().create_timer(0.3).timeout
	if not _active:
		visible = false
