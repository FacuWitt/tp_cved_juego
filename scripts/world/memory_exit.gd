class_name MemoryExit
extends Area3D
## Zona de salida de una memoria. Cuando el jugador la atraviesa (y está habilitada)
## emite `reached` y, si está dentro de una escena Memory, la da por completada.
## No sabe cuál es la escena siguiente: eso lo decide quien escuche (la memoria o GameFlow).
## Hoy es la salida provisoria de las memorias vacías; sirve también para salidas reales
## (por ejemplo la puerta de la memoria 1, que se habilita al resolver el puzzle).

## El jugador atravesó la salida estando habilitada.
signal reached

## Si está en false, el jugador puede pasar por la zona sin que pase nada
## (p. ej. antes de resolver el puzzle).
@export var enabled: bool = true

var _already_reached: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not enabled or _already_reached or not (body is Player):
		return
	_already_reached = true
	reached.emit()

	var memory: Memory = Memory.find_for(self)
	if memory != null:
		memory.complete()
	elif reached.get_connections().is_empty():
		push_warning("MemoryExit: %s no está dentro de una escena Memory y nadie escucha 'reached'." % name)
