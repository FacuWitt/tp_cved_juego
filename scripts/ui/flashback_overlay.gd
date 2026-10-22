class_name FlashbackOverlay
extends CanvasLayer
## Flashbacks: imágenes a pantalla completa, de menos de un segundo, con un golpe de luz.
## No sabe de qué memoria son: muestra las imágenes de su FlashbackSettings.

signal finished

@export var settings: FlashbackSettings

var is_playing: bool = false

var _image: TextureRect
var _black: ColorRect
var _flash: ColorRect
var _next: int = 0


func _ready() -> void:
	assert(settings != null, "FlashbackOverlay: falta el FlashbackSettings")
	layer = 15
	_black = _make_rect(Color.BLACK)
	_image = TextureRect.new()
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_image)
	_flash = _make_rect(Color(0.85, 0.92, 1.0))
	_hide_all()


## Muestra `count` imágenes seguidas (las toma en orden, dando la vuelta). Se puede esperar con await.
## Con `keep_black` la pantalla queda negra al terminar (para seguir en la oscuridad).
func play(count: int = 1, keep_black: bool = false) -> void:
	if settings.images.is_empty() or is_playing:
		return
	is_playing = true
	_black.visible = true
	for i: int in count:
		var texture: Texture2D = settings.images[_next % settings.images.size()]
		_next += 1
		await _show(texture)
		if settings.gap_time > 0.0:
			_image.visible = false
			await get_tree().create_timer(settings.gap_time).timeout
	_hide_all()
	_black.visible = keep_black
	is_playing = false
	finished.emit()


## Quita el negro que dejó `play(..., true)`.
func clear() -> void:
	_hide_all()


func _show(texture: Texture2D) -> void:
	_image.texture = texture
	_image.visible = true
	var reduced: bool = settings.reduce_flashes
	var brightness: float = settings.reduced_brightness if reduced else 1.0
	_image.modulate = Color(brightness, brightness, brightness, 0.0 if reduced else 1.0)
	if reduced:
		var t: Tween = create_tween()
		t.tween_property(_image, "modulate:a", 1.0, settings.image_time * 0.4)
		t.tween_interval(settings.image_time * 0.3)
		t.tween_property(_image, "modulate:a", 0.0, settings.image_time * 0.3)
		await t.finished
		return
	if settings.flash_strength > 0.0:
		_flash.visible = true
		_flash.modulate.a = settings.flash_strength
		var f: Tween = create_tween()
		f.tween_property(_flash, "modulate:a", 0.0, settings.image_time * 0.5)
	await get_tree().create_timer(settings.image_time).timeout
	_flash.visible = false


func _make_rect(color: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	return rect


func _hide_all() -> void:
	_image.visible = false
	_flash.visible = false
	_black.visible = false
