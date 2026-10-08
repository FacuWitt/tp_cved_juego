class_name MemoryExit
extends Area3D
## Salida de una memoria. Cuando el jugador la atraviesa (y está habilitada) emite reached.
## No sabe cuál es la escena siguiente: eso lo decide quien escuche la señal (la memoria o el GameManager).

signal reached

## Si está en false, el jugador puede atravesarla sin que pase nada (p. ej. antes de resolver el puzzle).
@export var enabled: bool = false

var _already_reached: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not enabled or _already_reached or not (body is Player):
		return
	_already_reached = true
	reached.emit()
