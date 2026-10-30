class_name PassageSettings
extends Resource
## Cómo es un pasaje entre dos memorias: el jugador camina sobre un mar quieto y negro hacia una
## luz lejana mientras escucha voces del hospital. Cuando hablan, se encienden unas luces cálidas
## grandes arriba a los costados (las luces del presente). Lo usa Passage; cada pasaje tiene su .tres.

@export_group("Camino")
## A qué distancia está la luz del final, adelante del jugador.
@export_range(10.0, 300.0, 1.0, "suffix:m") var path_length: float = 70.0
## Qué tan cerca de la luz hay que llegar para terminar el pasaje.
@export_range(0.5, 10.0, 0.1, "suffix:m") var end_radius: float = 2.5
## Hasta dónde se puede alejar de la línea del camino para cada lado (paredes invisibles).
@export_range(2.0, 60.0, 0.5, "suffix:m") var corridor_half_width: float = 9.0

@export_group("Luz del final")
## Lo que está al final: no se sabe qué es, solo se ve su luz.
@export var goal_color: Color = Color(0.82, 0.9, 1.0)
## Altura de la luz sobre el agua.
@export_range(0.0, 10.0, 0.05, "suffix:m") var goal_height: float = 1.8
## Tamaño del brillo visto de lejos.
@export_range(0.1, 20.0, 0.1, "suffix:m") var goal_glow_size: float = 2.2
## Cuánto crece el brillo al acercarse (1 = no crece).
@export_range(1.0, 6.0, 0.05) var goal_glow_growth: float = 1.4
@export_range(0.0, 8.0, 0.05) var goal_glow_energy: float = 1.6
## Luz que echa sobre el agua.
@export_range(0.0, 30.0, 0.1) var goal_light_energy: float = 3.0
@export_range(1.0, 80.0, 0.5, "suffix:m") var goal_light_range: float = 22.0
## Latido lento del brillo: cuánto y qué tan rápido.
@export_range(0.0, 1.0, 0.01) var goal_pulse: float = 0.15
@export_range(0.05, 3.0, 0.05, "suffix:Hz") var goal_pulse_rate: float = 0.35

@export_group("Voces")
## Las voces del hospital, en el orden en que suenan.
@export var voices: Array[PassageVoice] = []

@export_group("Luz de las voces")
## Las luces del presente: grandes y tenues, arriba del jugador a los costados. Se encienden solo
## cuando hablan las voces del hospital y su brillo sigue el volumen de la voz, como la luz de un
## parlante. Acompañan al jugador mientras camina.
@export var voice_light_color: Color = Color(1.0, 0.7, 0.38)
## Dónde está cada una respecto del jugador, en metros: x = a la derecha, y = arriba, z = adelante
## (en la dirección del camino, no hacia donde mira). Una por punto.
@export var voice_light_offsets: PackedVector3Array = PackedVector3Array([Vector3(-11.0, 7.5, 10.0), Vector3(11.0, 7.5, 10.0)])
## Tamaño del halo que se ve.
@export_range(0.5, 40.0, 0.5, "suffix:m") var voice_glow_size: float = 12.0
## Fuerza del halo con la voz más fuerte.
@export_range(0.0, 4.0, 0.05) var voice_glow_energy: float = 0.35
## Luz que echa sobre el agua con la voz más fuerte (es la que deja ver el mar).
@export_range(0.0, 30.0, 0.1) var voice_light_energy: float = 6.0
@export_range(1.0, 80.0, 0.5, "suffix:m") var voice_light_range: float = 30.0
## Cuánto brillan en silencio (0 = apagadas: solo brillan cuando hablan).
@export_range(0.0, 1.0, 0.01) var voice_idle_level: float = 0.0
## Qué tan rápido sube y baja el brillo con la voz (como el medidor de un parlante).
@export_range(0.005, 1.0, 0.005, "suffix:s") var voice_attack: float = 0.05
@export_range(0.01, 3.0, 0.01, "suffix:s") var voice_release: float = 0.35
## Con audio: volumen (en dB) que la deja apagada y el que la deja al máximo.
@export_range(-80.0, 0.0, 1.0, "suffix:dB") var voice_min_db: float = -48.0
@export_range(-80.0, 0.0, 1.0, "suffix:dB") var voice_max_db: float = -12.0
## Sin audio (mientras las voces son solo subtítulos), el brillo imita el habla: sílabas por
## segundo y cada cuánto hace pausas entre palabras.
@export_range(1.0, 12.0, 0.1, "suffix:Hz") var fake_syllable_rate: float = 5.0
@export_range(0.1, 4.0, 0.05, "suffix:Hz") var fake_word_rate: float = 1.1

@export_group("Mar")
## Altura del agua (el jugador camina sobre ella).
@export var water_level: float = 0.0
## Tamaño de las olas (el océano de la M4 usa 1).
@export_range(0.0, 1.0, 0.01, "suffix:m") var wave_height: float = 0.06
## Qué tan picudas son las olas.
@export_range(0.0, 1.0, 0.01) var wave_chop: float = 0.2
## Mar de fondo (ola larga y lenta), en fracción de `wave_height`.
@export_range(0.0, 2.0, 0.01) var wave_swell: float = 0.3
## Color que toma el agua donde la alcanza una luz (se multiplica por el color de la luz).
@export var water_lit_color: Color = Color(0.22, 0.27, 0.3)
@export_range(0.0, 10.0, 0.1) var water_lit_strength: float = 2.5
## Brillo de los reflejos de las luces en el agua.
@export_range(0.0, 3.0, 0.05) var water_glint: float = 0.35
## Cuánto se oscurece el agua al mirar hacia abajo (1 = negro total).
@export_range(0.0, 1.0, 0.01) var water_look_down_black: float = 0.6

@export_group("Oscuridad")
## Niebla negra que se come el mar a lo lejos (0 = sin niebla).
@export_range(0.0, 0.2, 0.001) var fog_density: float = 0.02
