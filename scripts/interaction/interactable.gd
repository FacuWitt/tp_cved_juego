class_name Interactable
extends StaticBody3D
## Algo fijo con lo que se interactúa apuntándole y apretando `interact` (no se agarra):
## un cajón que se abre, un libro que se lee. La mira muestra `prompt_text`.
## Las clases hijas reemplazan interact().

## Se apretó `interact` apuntándole. `by` es el jugador.
signal interacted(by: Node3D)

## Lo que dice la mira al apuntarle, por ejemplo "(E) Leer".
@export var prompt_text: String = "(E) Usar"
## Apagado = la mira lo ignora y no responde.
@export var enabled: bool = true


## Lo llama el Player. Por defecto solo avisa con la señal.
func interact(by: Node3D) -> void:
	interacted.emit(by)
