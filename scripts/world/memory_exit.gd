class_name MemoryExit
extends Area3D
## Zona que completa la memoria cuando el jugador entra.
## Hoy es la salida provisoria de cada memoria vacía; después sirve para salidas reales
## (por ejemplo la PUERTA SALIDA de la memoria 3, que se habilita con `enabled`).

## Si está en false, el jugador puede pasar por la zona sin completar la memoria.
@export var enabled: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not enabled or not body is Player:
		return
	var memory: Memory = Memory.find_for(self)
	if memory == null:
		push_warning("MemoryExit: %s no está dentro de una escena Memory." % name)
		return
	memory.complete()
