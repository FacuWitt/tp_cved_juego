class_name PuzzlePiece
extends PickupObject
## Objeto agarrable que además tiene una identidad dentro de un puzzle (p. ej. "luna", "ancla").
## SequencePuzzle usa piece_id para saber qué pieza quedó en cada casillero.

## Identificador de la pieza. Tiene que coincidir con los de SequencePuzzleConfig.correct_order.
@export var piece_id: StringName
## Texto del cartel provisorio (etapa 0). Si queda vacío, se usa piece_id en mayúsculas.
@export var label_text: String = ""

@onready var _label: Label3D = get_node_or_null("Label3D") as Label3D


func _ready() -> void:
	super._ready()
	assert(piece_id != &"", "PuzzlePiece: falta asignar piece_id en el Inspector")
	if _label != null:
		_label.text = label_text if label_text != "" else String(piece_id).to_upper()
