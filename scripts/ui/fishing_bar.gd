class_name FishingBar
extends Control
## La pelea con el pez: una barra vertical con un área verde que se mueve sola (el pez) y
## se va achicando, y un punto que el jugador sube con W y baja con S. Mientras el punto
## está adentro del área se llena la barra de captura; afuera se vacía.
## Llena = pescado (`caught`); vacía = se soltó (`escaped`).

signal caught
signal escaped

const TRACK_SIZE: Vector2 = Vector2(38.0, 340.0)
const PROGRESS_WIDTH: float = 12.0

@export var settings: FishingSettings

## Captura actual, 0..1.
var progress: float = 0.0
## Dónde está el punto y el centro del área verde (0 = abajo, 1 = arriba).
var marker: float = 0.5
var zone_center: float = 0.5

var _active: bool = false
var _time: float = 0.0
var _marker_vel: float = 0.0
var _zone_dir: float = 1.0
var _zone_vel: float = 0.0
var _zone_turn: float = 0.0
var _zone_speed: float = 0.3
var _track: ColorRect
var _zone: ColorRect
var _marker_rect: ColorRect
var _progress_back: ColorRect
var _progress_fill: ColorRect
var _hint: Label


func _ready() -> void:
	assert(settings != null, "FishingBar: falta el FishingSettings")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -220.0
	offset_right = -120.0
	offset_top = -TRACK_SIZE.y * 0.5 - 10.0
	offset_bottom = TRACK_SIZE.y * 0.5 + 60.0
	_track = _rect(Color(0.02, 0.04, 0.06, 0.82), Vector2.ZERO, TRACK_SIZE, self)
	_zone = _rect(Color(0.35, 0.85, 0.45, 0.85), Vector2.ZERO, Vector2(TRACK_SIZE.x, 40.0), _track)
	_marker_rect = _rect(Color(1, 1, 1, 1), Vector2(-6.0, 0.0), Vector2(TRACK_SIZE.x + 12.0, 6.0), _track)
	_progress_back = _rect(Color(0.02, 0.04, 0.06, 0.82), Vector2(TRACK_SIZE.x + 10.0, 0.0), Vector2(PROGRESS_WIDTH, TRACK_SIZE.y), self)
	_progress_fill = _rect(Color(0.95, 0.75, 0.3, 0.95), Vector2.ZERO, Vector2(PROGRESS_WIDTH, 0.0), _progress_back)
	_hint = Label.new()
	_hint.text = settings.fight_hint
	_hint.position = Vector2(-150.0, TRACK_SIZE.y + 12.0)
	_hint.size = Vector2(260.0, 40.0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_font_size_override("font_size", 15)
	add_child(_hint)
	visible = false


func is_active() -> bool:
	return _active


## Empieza la pelea. `fish_index` hace cada pez un poco más rápido que el anterior.
func begin(fish_index: int) -> void:
	_active = true
	visible = true
	_time = 0.0
	progress = settings.progress_start
	marker = 0.5
	_marker_vel = 0.0
	zone_center = randf_range(0.35, 0.65)
	_zone_dir = 1.0 if randf() < 0.5 else -1.0
	_zone_vel = 0.0
	_zone_turn = randf_range(settings.zone_turn_min, settings.zone_turn_max)
	_zone_speed = settings.zone_speed + settings.zone_speed_gain * float(fish_index)
	_refresh()


func cancel() -> void:
	_active = false
	visible = false


## Tamaño actual del área verde (fracción de la barra).
func zone_size() -> float:
	return lerpf(settings.zone_start_size, settings.zone_end_size, clampf(_time / settings.zone_shrink_time, 0.0, 1.0))


func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	var size: float = zone_size()
	# El pez: va y viene y cambia de idea cada tanto. Acelera y frena de a poco
	# (`zone_accel`), así es poco predecible pero sin saltos.
	_zone_turn -= delta
	if _zone_turn <= 0.0:
		_zone_turn = randf_range(settings.zone_turn_min, settings.zone_turn_max)
		if randf() < settings.zone_turn_chance:
			_zone_dir = -_zone_dir
	var half: float = size * 0.5
	# Cerca de un borde da la vuelta con tiempo para frenar, en lugar de rebotar.
	var brake: float = _zone_vel * _zone_vel / (2.0 * settings.zone_accel) + 0.01
	if _zone_dir > 0.0 and zone_center + brake >= 1.0 - half:
		_zone_dir = -1.0
	elif _zone_dir < 0.0 and zone_center - brake <= half:
		_zone_dir = 1.0
	var speed: float = _zone_speed * (1.0 + settings.zone_speed_wobble * sin(_time * 2.3))
	_zone_vel = move_toward(_zone_vel, _zone_dir * speed, settings.zone_accel * delta)
	zone_center += _zone_vel * delta
	if zone_center > 1.0 - half or zone_center < half:
		zone_center = clampf(zone_center, half, 1.0 - half)
		_zone_vel = 0.0
	# El punto: W sube, S baja. Llega rápido a su velocidad y frena rápido al soltar.
	var input: float = 0.0
	if Input.is_action_pressed("move_forward"):
		input += 1.0
	if Input.is_action_pressed("move_back"):
		input -= 1.0
	var k: float = 1.0 - exp(-settings.marker_response * delta)
	_marker_vel = lerpf(_marker_vel, input * settings.marker_max_speed, k)
	marker += _marker_vel * delta
	if marker <= 0.0 or marker >= 1.0:
		marker = clampf(marker, 0.0, 1.0)
		_marker_vel = 0.0
	var inside: bool = absf(marker - zone_center) <= half
	progress += (settings.progress_gain if inside else -settings.progress_loss) * delta
	_zone.color = Color(0.35, 0.95, 0.5, 0.95) if inside else Color(0.3, 0.7, 0.4, 0.7)
	_refresh()
	if progress >= 1.0:
		_finish(true)
	elif progress <= 0.0:
		_finish(false)


func _finish(success: bool) -> void:
	_active = false
	progress = clampf(progress, 0.0, 1.0)
	_refresh()
	if success:
		caught.emit()
	else:
		escaped.emit()
	await get_tree().create_timer(0.35).timeout
	if not _active:
		visible = false


func _refresh() -> void:
	var size: float = zone_size()
	_zone.size.y = size * TRACK_SIZE.y
	_zone.position.y = (1.0 - zone_center - size * 0.5) * TRACK_SIZE.y
	_marker_rect.position.y = (1.0 - marker) * TRACK_SIZE.y - 3.0
	_progress_fill.size.y = progress * TRACK_SIZE.y
	_progress_fill.position.y = TRACK_SIZE.y - _progress_fill.size.y


func _rect(color: Color, pos: Vector2, size: Vector2, parent: Control) -> ColorRect:
	var r: ColorRect = ColorRect.new()
	r.color = color
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r
