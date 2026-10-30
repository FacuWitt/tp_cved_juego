class_name Memory
extends Node3D
## Clase base de la raíz de cada escena de memoria.
## Al cargarse se registra en GameFlow. Cuando la mecánica de la memoria se resuelve,
## algo de la escena (una salida, un puzzle, la última tarea...) llama a complete()
## y GameFlow pasa a la memoria siguiente.
## Si un script hereda de Memory y redefine _ready(), tiene que llamar a super() primero.

## La memoria se resolvió. GameFlow la escucha para cargar la siguiente.
signal memory_completed
## El jugador falló. Justo después, GameFlow reinicia esta memoria.
signal memory_failed

## True después de llamar a complete(); evita completarla dos veces.
var is_completed: bool = false


func _ready() -> void:
	GameFlow.register_memory(self)


## Da la memoria por terminada. Solo tiene efecto la primera vez.
func complete() -> void:
	if is_completed:
		return
	is_completed = true
	memory_completed.emit()


## El jugador falló de una forma que obliga a empezar la memoria de nuevo.
func fail() -> void:
	if is_completed:
		return
	memory_failed.emit()
	GameFlow.restart_current()


## Devuelve la Memory que contiene a `node` (subiendo por sus padres), o null si no hay.
## Sirve para que un trigger o un objeto de la escena encuentre su memoria sin rutas fijas.
static func find_for(node: Node) -> Memory:
	var current: Node = node
	while current != null:
		if current is Memory:
			return current as Memory
		current = current.get_parent()
	return null
