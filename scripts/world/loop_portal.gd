class_name LoopPortal
extends Area3D
## Umbral invisible de la casa que se repite (M3): está apenas pasando una puerta, en la oscuridad.
## Cuando el jugador lo cruza emite `crossed` con su índice; quien escucha decide a dónde lo lleva
## y lo mueve con carry(). No sabe nada del laberinto ni de qué puerta es la buena.
## El origen del nodo es la referencia: el jugador aparece en el destino en el mismo lugar
## (y mirando hacia el mismo lado) respecto del destino que respecto del umbral.

## El jugador cruzó el umbral.
signal crossed(index: int)

## Qué puerta es (0 = izquierda, 1 = centro, 2 = derecha).
@export var index: int = 0
## Si está en false, cruzarlo no hace nada.
@export var enabled: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Lleva al jugador desde este umbral hasta `destination` sin cortarle el paso: conserva su
## posición, su orientación y su velocidad respecto del umbral. `max_offset` limita qué tan
## lejos del origen del umbral se lo puede dejar (por si entró en diagonal o muy rápido).
func carry(body: CharacterBody3D, destination: Node3D, max_offset: float) -> void:
	var local: Transform3D = global_transform.affine_inverse() * body.global_transform
	local.origin = local.origin.limit_length(max_offset)
	var turn: Basis = destination.global_transform.basis * global_transform.basis.inverse()
	body.global_transform = destination.global_transform * local
	body.velocity = turn * body.velocity


func _on_body_entered(body: Node3D) -> void:
	if enabled and body is Player:
		crossed.emit(index)
