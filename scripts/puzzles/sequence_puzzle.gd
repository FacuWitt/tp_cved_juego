class_name SequencePuzzle
extends Node
## Puzzle de "colocar piezas en el orden correcto".
## Escucha una lista ordenada de PlacementSlot y, cuando están todos ocupados, compara los
## piece_id de las piezas contra SequencePuzzleConfig.correct_order.

## Todos los casilleros quedaron ocupados en el orden correcto. Las piezas quedan bloqueadas.
signal solved
## Todos los casilleros quedaron ocupados, pero en un orden incorrecto.
signal failed
## Cambió la cantidad de casilleros ocupados (sirve para dar feedback de progreso).
signal progress_changed(filled: int, total: int)

@export var config: SequencePuzzleConfig
## Casilleros en orden: el primero de la lista es el casillero 1.
@export var slots: Array[PlacementSlot] = []

var is_solved: bool = false

## Qué pieza hay en cada casillero (null si está vacío). Mismo orden que slots.
var _placed: Array[PickupObject] = []


func _ready() -> void:
	assert(config != null, "SequencePuzzle: falta asignar un SequencePuzzleConfig")
	assert(slots.size() > 0, "SequencePuzzle: no hay casilleros asignados")
	assert(
		slots.size() == config.correct_order.size(),
		"SequencePuzzle: hay %d casilleros pero el orden correcto tiene %d piezas" % [slots.size(), config.correct_order.size()]
	)
	_placed.resize(slots.size())
	for i in slots.size():
		slots[i].object_placed.connect(_on_object_placed.bind(i))
		slots[i].object_removed.connect(_on_object_removed.bind(i))


## Cantidad de casilleros ocupados.
func get_filled_count() -> int:
	var count: int = 0
	for object in _placed:
		if object != null:
			count += 1
	return count


func _on_object_placed(object: PickupObject, index: int) -> void:
	_placed[index] = object
	progress_changed.emit(get_filled_count(), slots.size())
	_evaluate()


func _on_object_removed(_object: PickupObject, index: int) -> void:
	_placed[index] = null
	progress_changed.emit(get_filled_count(), slots.size())


func _evaluate() -> void:
	if is_solved or get_filled_count() < slots.size():
		return

	for i in slots.size():
		var piece: PuzzlePiece = _placed[i] as PuzzlePiece
		if piece == null or piece.piece_id != config.correct_order[i]:
			failed.emit()
			return

	is_solved = true
	for object in _placed:
		object.lock()
	solved.emit()
