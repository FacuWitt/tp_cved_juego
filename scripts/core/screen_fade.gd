extends CanvasLayer
## Fundido a negro de pantalla completa, usado en las transiciones entre memorias.
## Es un autoload (res://scenes/ui/screen_fade.tscn): se usa como ScreenFade desde cualquier script.
## No lleva class_name porque el nombre global ya lo da el autoload.

signal faded_out
signal faded_in

var _tween: Tween

@onready var _overlay: ColorRect = $Overlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_alpha(0.0)


## Lleva la pantalla a negro en `duration` segundos. Se puede esperar con await.
func fade_out(duration: float) -> void:
	await _fade_to(1.0, duration)
	faded_out.emit()


## Vuelve a mostrar la escena en `duration` segundos. Se puede esperar con await.
func fade_in(duration: float) -> void:
	await _fade_to(0.0, duration)
	faded_in.emit()


## Indica si la pantalla está (al menos parcialmente) tapada.
func is_covering() -> bool:
	return _overlay.modulate.a > 0.0


func _fade_to(alpha: float, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_set_alpha(alpha)
		return
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", alpha, duration)
	await _tween.finished


func _set_alpha(alpha: float) -> void:
	_overlay.modulate.a = alpha
