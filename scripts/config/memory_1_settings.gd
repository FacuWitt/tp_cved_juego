class_name Memory1Settings
extends Resource
## Valores de "feel" y textos provisorios de la Memoria 1 (la habitación de la abuela).
## Se editan desde el Inspector en res://config/memory_1_settings.tres.

@export_group("Al empezar")
## Texto provisorio de la abuela pidiendo que ordene (en la etapa 2: su voz con eco, desde otra habitación).
@export_multiline var intro_line: String = "VOZ (abuela, desde otra habitación): Antes de dormir poné los juguetes en la alfombra del mar, mi amor, cada uno en su número. Si no te acordás el orden, la canción está en el libro de cuentos."
## Pausa entre que empieza la memoria y habla la abuela.
@export_range(0.0, 10.0, 0.1, "suffix:s") var intro_line_delay: float = 1.5
## Cuánto tiempo queda en pantalla el texto de la abuela.
@export_range(0.5, 15.0, 0.1, "suffix:s") var intro_line_duration: float = 7.0

@export_group("Objetos en alto")
## Lo que piensa el nene cuando quiere agarrar algo que está muy alto (la luna del estante).
@export_multiline var reach_hint_line: String = "No llego... ¿y si me subo a algo?"
@export_range(0.5, 10.0, 0.1, "suffix:s") var reach_hint_duration: float = 3.0
## Tiempo mínimo entre un aviso y el siguiente si sigue intentando.
@export_range(0.0, 30.0, 0.5, "suffix:s") var reach_hint_cooldown: float = 6.0
## Voz del nene diciendo esa frase (suena a la vez que el texto). Vacío = solo el texto.
@export var reach_hint_voice: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var reach_hint_voice_volume_db: float = 0.0
## Bus de audio de la voz del nene (la abuela usa otro, con eco).
@export var own_voice_bus: StringName = &"Master"

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

@export_group("Al equivocarse")
## Texto provisorio de la reacción al error (en la etapa 2: golpe grave, crujido, goteo más cerca).
@export_multiline var failed_line: String = "(Un golpe grave sacude la puerta. El goteo se escucha más cerca.)"
## Cuánto tiempo queda en pantalla el texto del error.
@export_range(0.5, 10.0, 0.1, "suffix:s") var failed_line_duration: float = 3.0
## Cuánto se sacude la puerta con el golpe.
@export_range(0.0, 10.0, 0.1, "suffix:°") var door_shake_angle: float = 3.0
## Duración total de la sacudida.
@export_range(0.05, 2.0, 0.05, "suffix:s") var door_shake_time: float = 0.35

@export_group("Sonidos")
## Si está activo, cada pieza que se coloca suena distinto según vaya o no en ese casillero.
## Si se apaga, el jugador recién se entera de si acertó cuando llena todos los casilleros.
@export var piece_feedback_enabled: bool = true
## Sonido al colocar una pieza en el casillero que le corresponde.
@export var piece_correct_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var piece_correct_volume_db: float = 0.0
## Sonido al colocar una pieza en un casillero que no es el suyo.
@export var piece_incorrect_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var piece_incorrect_volume_db: float = 0.0
## Bus de audio de los dos sonidos anteriores.
@export var piece_sound_bus: StringName = &"sound_correctly"
## Sonido de la puerta al abrirse cuando se resuelve el puzzle (sale de la puerta misma).
@export var door_open_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var door_open_volume_db: float = 0.0
## Sonido del golpe en la puerta cuando el orden está mal.
@export var door_knock_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var door_knock_volume_db: float = 0.0
## Bus de audio de los sonidos de la puerta.
@export var door_sound_bus: StringName = &"Master"
## Voz que felicita al resolver el puzzle ("¡Muy bien, mi amor!"). Vacío = solo se muestra el texto.
@export var solved_voice: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var solved_voice_volume_db: float = 0.0
## Pausa entre que se resuelve el puzzle y empieza la voz (así no se pisa con el sonido de la última pieza).
@export_range(0.0, 5.0, 0.05, "suffix:s") var solved_voice_delay: float = 0.6
## Bus de audio de la voz. El de la abuela ("discurso_abuela") tiene un efecto de eco que se prende en el panel Audio.
@export var voice_bus: StringName = &"discurso_abuela"

@export_group("Salida")
## Texto provisorio al salir (hasta que el flujo entre memorias esté integrado).
@export_multiline var exit_line: String = "[ Fin de la Memoria 1: acá va la transición en negro ]"
