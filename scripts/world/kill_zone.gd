class_name KillZone
extends Area3D
## Devuelve al jugador a un punto de reaparición cuando entra (p. ej. al caer al vacío).

@export var respawn_point: Marker3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and respawn_point != null:
		(body as Player).teleport_to.call_deferred(respawn_point.global_transform)
