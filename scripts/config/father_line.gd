class_name FatherLine
extends Resource
## Una frase del padre que se dice cuando el hijo llega a cierto punto del recorrido.
## Mientras no haya voces grabadas, el audio es una voz sintética de reemplazo.

## Qué parte del recorrido (0 a 1) tiene que haber avanzado el hijo para que la diga.
@export_range(0.0, 1.0, 0.005) var at_progress: float = 0.0
@export var text: String = ""
@export var voice: AudioStream
