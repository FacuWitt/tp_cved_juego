class_name SubtitleDisplay
extends Label
## Muestra una línea de texto abajo de la pantalla durante un tiempo.
## En la etapa 0 reemplaza a las voces y sonidos que todavía no existen ("VOZ: ...", "(golpe grave)").

var _hide_timer: SceneTreeTimer = null


func _ready() -> void:
	text = ""


## Muestra la línea durante duration segundos (si es 0 o menos, queda fija hasta la próxima).
func show_line(line: String, duration: float) -> void:
	text = line
	if duration <= 0.0:
		_hide_timer = null
		return
	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	_hide_timer = timer
	timer.timeout.connect(
		func() -> void:
			if _hide_timer == timer:
				text = ""
	)
