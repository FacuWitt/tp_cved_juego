class_name Memory3AudioSettings
extends Resource
## Todos los sonidos de la Memoria 3 (la casa) en un solo lugar: tormenta de afuera, fondo de cada
## habitación, voces de las líneas y sonidos sueltos. Todo es opcional: un slot vacío no suena.
## Se edita desde el Inspector en res://config/memory_3_audio.tres. Los volúmenes están en dB
## (0 = tal cual el archivo, negativo = más bajo).
##
## Lo que NO está acá (ya tiene su slot en otro lado):
## - La voz de la hija que guía desde la puerta buena: `voice_stream` en `memory_3_settings.tres`.
## - Los sonidos sueltos de cada sala intermedia (garabatos, golpe, zumbido, bip, relé, tubo,
##   golpes de madera, cascada, golpe de barquito): en el Inspector de `sala_mensajes.tscn`,
##   `pasillo_hospital.tscn` y `sala_barcos.tscn`. Sus volúmenes, en `config/m3_wake_messages.tres`,
##   `config/m3_hospital_corridor.tres` y `config/m3_boat_flood.tres`.

@export_group("Tormenta (lluvia, viento y truenos de afuera)")
## Lluvia, viento, música y los tres truenos (cerca, media distancia, lejos). Se edita en
## `config/storm_audio_m3.tres`. El trueno suena con cada rayo, también el del despertar.
@export var storm: StormAudioSettings
## Qué tan fuerte es la tormenta (0 = calma, 1 = tormenta). Mueve el volumen de la lluvia, el
## viento y la música entre sus valores de calma y de tormenta.
@export_range(0.0, 1.0, 0.01) var storm_level: float = 1.0
## Si está activo, la lluvia y los truenos se apagan mientras se cruza una sala intermedia y
## vuelven al salir. Sirve si en esas salas solo tiene que sonar su propio fondo.
@export var mute_storm_in_interludes: bool = true

@export_group("Fondo de cada habitación (loops)")
## Cuánto tarda un fondo en apagarse y el siguiente en subir al cambiar de habitación.
@export_range(0.1, 10.0, 0.1, "suffix:s") var background_fade_time: float = 1.5
## La cocina: donde se despierta y donde vuelve cada vez que elige mal. Cuenta también el
## pasillito oscuro del fondo.
@export var kitchen_background: AudioStream
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var kitchen_background_volume_db: float = -10.0
## El pasillo largo que se repite, hasta el rellano de las tres puertas.
@export var hallway_background: AudioStream
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var hallway_background_volume_db: float = -10.0
## El cuarto de la hija (pasillo del cuarto y cuarto), hasta que se entrega el barquito.
@export var daughter_room_background: AudioStream
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var daughter_room_background_volume_db: float = -10.0
## La casa ya estabilizada, después de darle el barquito a la hija. Vacío = sigue el fondo del cuarto.
@export var stable_background: AudioStream
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var stable_background_volume_db: float = -10.0
## Fondo de la sala de los mensajes (reemplaza el drone de la escena; el volumen es
## `drone_volume_db` de `config/m3_wake_messages.tres`). Vacío = queda el de la escena.
@export var messages_room_background: AudioStream
## Fondo del pasillo del hospital (reemplaza el drone de la escena; el volumen es `drone_volume_db`
## de `config/m3_hospital_corridor.tres`). Vacío = queda el de la escena.
@export var hospital_corridor_background: AudioStream
## Fondo de la sala de los barcos (reemplaza el drone de la escena; el volumen es `drone_volume_db`
## de `config/m3_boat_flood.tres`). Vacío = queda el de la escena.
@export var boat_room_background: AudioStream

@export_group("Voces (una por línea de subtítulo)")
## Volumen de todas las voces de esta sección.
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var voices_volume_db: float = 5.0
## La hija llama desde lejos al empezar (`first_call_line`).
@export var first_call_voice: AudioStream
## Cada vez que elige la puerta buena y la hija se oye más cerca (misma posición que `closer_lines`;
## si faltan, se repite la última).
@export var closer_voices: Array[AudioStream] = []
## Cada vez que elige mal y vuelve a la cocina (misma posición que `farther_lines`; si faltan,
## vuelve a empezar).
@export var farther_voices: Array[AudioStream] = []
## La hija, al llegar al pasillo del cuarto (`room_arrival_line`).
@export var room_arrival_voice: AudioStream
## La hija, cuando se abre la puerta de su cuarto (`plea_line`).
@export var plea_voice: AudioStream
## El protagonista, al dejarle el barquito (`give_line`).
@export var give_voice: AudioStream

@export_group("Sonidos de la casa")
## Cuánto más lejos se oye una puerta (más chico = se nota más de dónde viene).
@export_range(0.5, 20.0, 0.1, "suffix:m") var positional_unit_size: float = 3.0
## Distancia a partir de la cual una puerta ya no se oye.
@export_range(5.0, 80.0, 0.5, "suffix:m") var positional_max_distance: float = 30.0
## Al empezar, mientras el protagonista abre los ojos (antes del trueno).
@export var wake_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var wake_volume_db: float = -2.0
## Se abre una puerta del rellano o la del cuarto de la hija (suena en la puerta).
@export var door_open_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var door_open_volume_db: float = 0.0
## Se abre la puerta de entrada de la casa. Vacío = suena `door_open_sound`.
@export var front_door_open_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var front_door_open_volume_db: float = 0.0
## Las puertas del rellano se vuelven a cerrar solas (al cruzar una o al volver a la cocina).
@export var door_close_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var door_close_volume_db: float = 0.0
## Cruza la puerta buena y entra a la sala de ese tramo.
@export var good_door_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var good_door_volume_db: float = 0.0
## Cruza una puerta mala y vuelve a la cocina.
@export var wrong_door_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var wrong_door_volume_db: float = 0.0
## Las piernas dejan de responder (suena uno al azar cada vez).
@export var stuck_sounds: Array[AudioStream] = []
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var stuck_volume_db: float = 0.0
## Deja el barquito en manos de la hija.
@export var give_boat_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var give_boat_volume_db: float = 0.0
## La casa se queda quieta (empieza a estabilizarse después de darle el barquito).
@export var stabilize_sound: AudioStream
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var stabilize_volume_db: float = 0.0
