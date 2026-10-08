class_name Memory1Settings
extends Resource
## Valores de "feel" y textos provisorios de la Memoria 1 (la habitación de la abuela).
## Se editan desde el Inspector en res://config/memory_1_settings.tres.

@export_group("Al empezar")
## Texto provisorio de la abuela pidiendo que ordene (en la etapa 2: su voz con eco, desde otra habitación).
@export_multiline var intro_line: String = "VOZ (abuela, desde otra habitación): Antes de dormir ordená los juguetes, mi amor. Si no te acordás dónde va cada uno, cantá la canción del papel."
## Pausa entre que empieza la memoria y habla la abuela.
@export_range(0.0, 10.0, 0.1, "suffix:s") var intro_line_delay: float = 1.5
## Cuánto tiempo queda en pantalla el texto de la abuela.
@export_range(0.5, 15.0, 0.1, "suffix:s") var intro_line_duration: float = 7.0

@export_group("Al resolver el puzzle")
## Texto provisorio de la voz que felicita (en la etapa 2 se reemplaza por audio con eco).
@export_multiline var solved_line: String = "VOZ (mamá, con eco): ¡Muy bien, mi amor! ¡Qué inteligente sos!"
## Cuánto tiempo queda en pantalla el texto de la voz.
@export_range(0.5, 10.0, 0.1, "suffix:s") var solved_line_duration: float = 4.0
## Intensidad final de la luz cálida del barquito al encenderse.
@export_range(0.0, 10.0, 0.1) var boat_glow_energy: float = 2.5
## Cuánto tarda el barquito en encenderse.
@export_range(0.0, 5.0, 0.05, "suffix:s") var boat_glow_time: float = 1.5
## Pausa entre que se resuelve el puzzle y se abre la puerta.
@export_range(0.0, 5.0, 0.05, "suffix:s") var door_open_delay: float = 1.5
## Cuánto tarda la puerta en abrirse.
@export_range(0.1, 5.0, 0.05, "suffix:s") var door_open_time: float = 1.6
## Ángulo final de la puerta abierta.
@export_range(30.0, 170.0, 1.0, "suffix:°") var door_open_angle: float = 100.0

@export_group("Antes de salir")
## Pensamiento del protagonista cuando intenta irse sin su juguete favorito (el barco).
## En la etapa 2: su voz de nene, sin eco, como pensamiento en voz alta.
@export_multiline var gate_line: String = "NENE (pensando): No me puedo ir sin mi juguete favorito."
## Cuánto tiempo queda en pantalla el pensamiento.
@export_range(0.5, 10.0, 0.1, "suffix:s") var gate_line_duration: float = 3.5

@export_group("Al equivocarse")
## Texto provisorio de la reacción al error (en la etapa 2: golpe grave, crujido, goteo más cerca).
@export_multiline var failed_line: String = "(Un golpe grave sacude la puerta. El goteo se escucha más cerca.)"
## Cuánto tiempo queda en pantalla el texto del error.
@export_range(0.5, 10.0, 0.1, "suffix:s") var failed_line_duration: float = 3.0
## Cuánto se sacude la puerta con el golpe.
@export_range(0.0, 10.0, 0.1, "suffix:°") var door_shake_angle: float = 3.0
## Duración total de la sacudida.
@export_range(0.05, 2.0, 0.05, "suffix:s") var door_shake_time: float = 0.35

@export_group("Salida")
## Texto provisorio al salir (hasta que el flujo entre memorias esté integrado).
@export_multiline var exit_line: String = "[ Fin de la Memoria 1: acá va la transición en negro ]"
