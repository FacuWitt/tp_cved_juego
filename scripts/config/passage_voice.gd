class_name PassageVoice
extends Resource
## Una voz del hospital que se escucha en un pasaje entre memorias (la realidad que se filtra).
## La usa PassageSettings: cada voz suena cuando el jugador recorrió cierta parte del camino.

## Lo que se lee en los subtítulos mientras no haya audio ("VOZ (doctor, tapada): ...").
@export_multiline var text: String = ""
## El audio de la voz (opcional: si está vacío, solo se muestra el texto).
@export var stream: AudioStream
## En qué parte del camino suena (0 = al empezar, 1 = al llegar a la luz).
@export_range(0.0, 1.0, 0.01) var at_progress: float = 0.25
## Cuánto queda el subtítulo en pantalla.
@export_range(0.5, 15.0, 0.1, "suffix:s") var duration: float = 3.5
