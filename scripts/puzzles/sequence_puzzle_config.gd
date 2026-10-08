class_name SequencePuzzleConfig
extends Resource
## Orden correcto de un puzzle de secuencia. Se edita desde el Inspector (en res://config/),
## así el acertijo se puede cambiar sin tocar código.

## Un piece_id por casillero, en orden: el primero va en el casillero 1, el segundo en el 2, etc.
## La cantidad tiene que coincidir con la cantidad de casilleros del SequencePuzzle.
@export var correct_order: Array[StringName] = []
