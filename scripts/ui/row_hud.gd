class_name RowHud
extends Control
## Cartelito de los remos: muestra qué tecla mueve cada remo y se enciende cuando se rema.
## Se va apagando cuando el jugador ya aprendió y vuelve si deja de remar un rato.
## Las teclas se leen del Mapa de Entrada (acciones `row_left` y `row_right`).

@export var boat: RemosBoat
## Cuántas veces tiene que alternar los remos para que el cartel se esconda.
@export_range(1, 30, 1) var alternations_to_learn: int = 5
## Si deja de remar este tiempo, el cartel vuelve.
@export_range(2.0, 60.0, 0.5, "suffix:s") var idle_return_time: float = 9.0
@export var text_color: Color = Color(1.0, 0.95, 0.85)
@export var lit_color: Color = Color(1.0, 0.8, 0.45)

var _left_key: Label
var _right_key: Label
var _left_panel: PanelContainer
var _right_panel: PanelContainer
var _hint: Label
var _alpha: float = 1.0
var _idle: float = 0.0
var _left_glow: float = 0.0
var _right_glow: float = 0.0
var _shown_forced: bool = true


func _ready() -> void:
	assert(boat != null, "RowHud: falta el bote")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_left_panel = _make_key("A", -1)
	_right_panel = _make_key("D", 1)
	_hint = Label.new()
	_hint.text = "Un remo por tecla. Alterná para ir derecho; con uno solo girás hacia el otro lado."
	_hint.add_theme_color_override("font_color", text_color)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.add_theme_font_size_override("font_size", 17)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -112.0
	_hint.offset_bottom = -84.0
	_hint.offset_left = -420.0
	_hint.offset_right = 420.0
	add_child(_hint)
	_left_key = _left_panel.get_meta("key") as Label
	_right_key = _right_panel.get_meta("key") as Label
	_refresh_key_names()
	boat.stroke_made.connect(_on_stroke)


func _process(delta: float) -> void:
	_idle += delta
	_left_glow = maxf(_left_glow - delta * 3.0, 0.0)
	_right_glow = maxf(_right_glow - delta * 3.0, 0.0)
	var show: bool = boat.control_enabled and (boat.alternations < alternations_to_learn or _idle > idle_return_time)
	_alpha = move_toward(_alpha, 1.0 if show else 0.0, delta * 1.5)
	modulate.a = _alpha
	visible = _alpha > 0.01
	_left_panel.modulate = text_color.lerp(lit_color, _left_glow)
	_right_panel.modulate = text_color.lerp(lit_color, _right_glow)
	_left_panel.scale = Vector2.ONE * (1.0 + 0.15 * _left_glow)
	_right_panel.scale = Vector2.ONE * (1.0 + 0.15 * _right_glow)


func _on_stroke(side: int) -> void:
	_idle = 0.0
	if side < 0:
		_left_glow = 1.0
	else:
		_right_glow = 1.0


func _refresh_key_names() -> void:
	_left_key.text = _key_name("row_left", "A")
	_right_key.text = _key_name("row_right", "D")


func _key_name(action: String, fallback: String) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event as InputEventKey
			var text: String = key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE else key.as_text_keycode()
			if text.length() > 0:
				return text
	return fallback


func _make_key(label: String, side: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.04, 0.55)
	style.border_color = text_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	var box: VBoxContainer = VBoxContainer.new()
	panel.add_child(box)
	var key: Label = Label.new()
	key.text = label
	key.add_theme_font_size_override("font_size", 30)
	key.add_theme_color_override("font_color", Color.WHITE)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(key)
	var caption: Label = Label.new()
	caption.text = "remo izquierdo" if side < 0 else "remo derecho"
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", text_color)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	panel.set_meta("key", key)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_top = -76.0
	panel.offset_bottom = -8.0
	panel.offset_left = -230.0 if side < 0 else 70.0
	panel.offset_right = -70.0 if side < 0 else 230.0
	panel.pivot_offset = Vector2(80.0, 34.0)
	return panel
