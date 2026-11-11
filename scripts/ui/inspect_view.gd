class_name InspectView
extends CanvasLayer
## Inspección de objetos estilo Silent Hill. Al abrir un InspectableItem:
##   1. el jugador queda quieto, el fondo se desenfoca y se oscurece un poco;
##   2. una copia del objeto viaja desde donde está hasta frente a la cara, girando;
##   3. si tiene tapa ("CoverHinge"), se abre, y aparece la página para leer;
##   4. con `interact` se cierra todo al revés y el objeto vuelve a su lugar.
## La copia se dibuja en su propio mundo (SubViewport) por encima del fondo borroso, así
## queda nítida. Una sola InspectView por escena; los valores están en InspectSettings.

const GROUP_NAME: StringName = &"inspect_view"

signal opened(item: InspectableItem)
signal closed(item: InspectableItem)

@export var settings: InspectSettings

enum State { IDLE, OPENING, READING, CLOSING }

var _state: State = State.IDLE
var _item: InspectableItem
var _player: Node3D
var _clone: Node3D
var _hinge: Node3D
var _start: Transform3D
var _held: Transform3D
var _reading: Transform3D

var _blur: ColorRect
var _blur_material: ShaderMaterial
var _viewport: SubViewport
var _camera: Camera3D
var _light: DirectionalLight3D
var _env: WorldEnvironment
var _page: TextureRect
var _hint: Label
var _audio: AudioStreamPlayer


func _ready() -> void:
	assert(settings != null, "InspectView: falta asignar un InspectSettings en el Inspector")
	layer = 20
	add_to_group(GROUP_NAME)
	_build()
	_set_visible(false)


## true mientras hay algo abierto o animándose.
func is_busy() -> bool:
	return _state != State.IDLE


func open(item: InspectableItem, by: Node3D) -> void:
	if _state != State.IDLE:
		return
	var main_camera: Camera3D = get_viewport().get_camera_3d()
	if main_camera == null:
		return
	_state = State.OPENING
	_item = item
	_player = by
	if _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", false)

	# La copia arranca exactamente donde se ve el objeto real, visto desde la cámara.
	_camera.fov = main_camera.fov
	_camera.near = 0.02
	_clone = item.visual.duplicate() as Node3D
	_viewport.add_child(_clone)
	_start = main_camera.global_transform.affine_inverse() * item.visual.global_transform
	_clone.transform = _start
	_hinge = _clone.find_child("CoverHinge", true, false) as Node3D
	item.visual.visible = false

	var tilt: Basis = Basis(Vector3.RIGHT, deg_to_rad(settings.hold_tilt))
	_held = Transform3D(tilt.scaled(_start.basis.get_scale()), Vector3(0.0, -0.03, -settings.hold_distance))
	var face: Basis = Basis(Vector3.RIGHT, deg_to_rad(90.0))
	var spine_shift: float = _spine_offset()
	_reading = Transform3D(face.scaled(_start.basis.get_scale()), Vector3(spine_shift, 0.0, -settings.hold_distance * 0.92))

	_set_visible(true)
	_page.modulate.a = 0.0
	_hint.modulate.a = 0.0
	_layout_page()
	opened.emit(item)

	# 1 y 2: el fondo se desenfoca mientras el objeto viene a la cara, girando un poco.
	var t: Tween = create_tween().set_parallel(true)
	t.tween_method(_set_blur, 0.0, 1.0, settings.background_fade_time)
	t.tween_method(_fly.bind(_start, _held, settings.fly_spin), 0.0, 1.0, settings.fly_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished
	await get_tree().create_timer(settings.look_pause).timeout

	# 3: se abre la tapa (si tiene) y aparece la página.
	if _hinge != null:
		_play_cover_sound(settings.open_sound, settings.open_volume_db)
		var o: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		o.tween_property(_hinge, "rotation:z", deg_to_rad(settings.open_angle), settings.open_time)
		o.tween_method(_fly.bind(_held, _reading, 0.0), 0.0, 1.0, settings.open_time)
		await o.finished
	if item.page != null:
		var p: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		p.tween_property(_page, "modulate:a", 1.0, settings.page_fade_time)
		p.tween_property(_page, "scale", Vector2.ONE, settings.page_fade_time).from(Vector2.ONE * settings.page_scale_from)
		await p.finished
		_clone.visible = false
	var h: Tween = create_tween()
	h.tween_property(_hint, "modulate:a", 1.0, 0.3)
	_state = State.READING


func close() -> void:
	if _state != State.READING:
		return
	_state = State.CLOSING
	_clone.visible = true
	var c: Tween = create_tween().set_parallel(true)
	c.tween_property(_hint, "modulate:a", 0.0, 0.15)
	if _item.page != null:
		c.tween_property(_page, "modulate:a", 0.0, settings.page_fade_time * 0.7)
		c.tween_property(_page, "scale", Vector2.ONE * settings.page_scale_from, settings.page_fade_time * 0.7)
	await c.finished
	var from: Transform3D = _held
	if _hinge != null:
		from = _reading
		_play_cover_sound(settings.close_sound, settings.close_volume_db)
		var o: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		o.tween_property(_hinge, "rotation:z", 0.0, settings.open_time * 0.8)
		o.tween_method(_fly.bind(_reading, _held, 0.0), 0.0, 1.0, settings.open_time * 0.8)
		await o.finished
		from = _held
	# 4: vuelve a su lugar y el fondo se aclara.
	var b: Tween = create_tween().set_parallel(true)
	b.tween_method(_fly.bind(from, _start, -settings.fly_spin), 0.0, 1.0, settings.fly_time * 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	b.tween_method(_set_blur, 1.0, 0.0, settings.background_fade_time).set_delay(settings.fly_time * 0.85 - settings.background_fade_time * 0.5)
	await b.finished
	_item.visual.visible = true
	_clone.queue_free()
	_clone = null
	_set_visible(false)
	if _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", true)
	var item: InspectableItem = _item
	_item = null
	_state = State.IDLE
	item.inspected.emit()
	closed.emit(item)


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.IDLE:
		return
	# Mientras se inspecciona, la tecla de interactuar es de esta vista (no llega al jugador).
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _state == State.READING:
			close()


# ---------- Animación ----------

## Mueve la copia de `from` a `to` (t de 0 a 1), con un giro extra que se desarma al llegar.
func _fly(t: float, from: Transform3D, to: Transform3D, spin_degrees: float) -> void:
	var tr: Transform3D = from.interpolate_with(to, t)
	var spin: float = deg_to_rad(spin_degrees) * (1.0 - t) * sin(t * PI)
	tr.basis = Basis(Vector3.UP, spin) * tr.basis
	_clone.transform = tr


## Suena el sonido de la tapa (abrir o cerrar), si hay uno asignado.
func _play_cover_sound(sound: AudioStream, volume_db: float) -> void:
	if sound == null:
		return
	_audio.stream = sound
	_audio.volume_db = volume_db
	_audio.play()


func _set_blur(amount: float) -> void:
	_blur_material.set_shader_parameter("amount", amount)


## Cuánto correr el libro para que, abierto, quede centrado en el lomo.
func _spine_offset() -> float:
	if _hinge == null:
		return 0.0
	return -_hinge.position.x * _start.basis.get_scale().x


# ---------- Armado ----------

func _build() -> void:
	_blur = ColorRect.new()
	_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur_material = ShaderMaterial.new()
	_blur_material.shader = preload("res://assets/shaders/inspect_blur.gdshader")
	_blur_material.set_shader_parameter("blur", settings.background_blur)
	_blur_material.set_shader_parameter("darken", settings.background_darken)
	_blur.material = _blur_material
	add_child(_blur)

	var container: SubViewportContainer = SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(_viewport)
	_camera = Camera3D.new()
	_camera.current = true
	_viewport.add_child(_camera)
	_light = DirectionalLight3D.new()
	_light.light_color = settings.light_color
	_light.light_energy = settings.light_energy
	_light.rotation_degrees = Vector3(-35.0, -30.0, 0.0)
	_viewport.add_child(_light)
	_env = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = settings.light_color
	env.ambient_light_energy = settings.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.environment = env
	_viewport.add_child(_env)

	_page = TextureRect.new()
	_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_page.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_page)

	_hint = Label.new()
	_hint.text = settings.close_hint
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.anchor_left = 0.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top = -64.0
	_hint.offset_bottom = -24.0
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 6)
	add_child(_hint)

	_audio = AudioStreamPlayer.new()
	_audio.bus = settings.sound_bus
	add_child(_audio)


func _layout_page() -> void:
	var screen: Vector2 = get_viewport().get_visible_rect().size
	_page.texture = _item.page
	var aspect: float = 1.5
	if _item.page != null:
		aspect = float(_item.page.get_width()) / float(_item.page.get_height())
	var h: float = screen.y * settings.page_screen_height
	var w: float = minf(h * aspect, screen.x * 0.96)
	h = w / aspect
	_page.size = Vector2(w, h)
	_page.position = (screen - _page.size) * 0.5
	_page.pivot_offset = _page.size * 0.5


func _set_visible(on: bool) -> void:
	for child: Node in get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = on
