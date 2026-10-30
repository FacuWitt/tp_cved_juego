class_name AwakeningSettings
extends Resource
## El despertar en el hospital (última escena): tiempos de cada momento, el texto de la hija, el
## monitor cardíaco y la mirada del jugador acostado. Lo usa Awakening.

@export_group("Despertar")
## Cuánto tarda en aclararse el blanco del principio (abre los ojos).
@export_range(0.5, 15.0, 0.1, "suffix:s") var open_eyes_time: float = 4.5
## Parpadeos al abrir los ojos (cada uno cierra un poco y vuelve a abrir).
@export_range(0, 5, 1) var blinks: int = 2
@export_range(0.05, 1.0, 0.01, "suffix:s") var blink_time: float = 0.35
## Cuánto se queda mirando el techo (las mismas 6 luces que veía en el cielo con los rayos).
@export_range(0.0, 20.0, 0.1, "suffix:s") var ceiling_hold: float = 4.0

@export_group("La hija")
## Cuánto tarda en girar la cabeza hacia la hija.
@export_range(0.5, 10.0, 0.1, "suffix:s") var turn_to_daughter_time: float = 3.0
@export_multiline var daughter_line: String = "HIJA: Papá... te traje esto. Lo cuidé como me dijiste antes de irte."
@export_range(1.0, 15.0, 0.1, "suffix:s") var daughter_line_time: float = 6.0
## Voz de la hija (opcional: sin audio solo se ve el subtítulo).
@export var daughter_voice: AudioStream

@export_group("El barquito")
## Cuánto tarda en bajar la mirada al barquito de la mesita de luz y cuánto se queda ahí.
@export_range(0.5, 10.0, 0.1, "suffix:s") var turn_to_boat_time: float = 2.5
@export_range(0.5, 20.0, 0.1, "suffix:s") var boat_hold: float = 4.0

@export_group("Final")
## Fundido a blanco y el título que queda (❓ ABIERTO: créditos, menú o solo el título).
@export_range(0.5, 10.0, 0.1, "suffix:s") var end_fade_time: float = 3.5
@export var end_title: String = "Cable a Tierra"
@export_range(0.5, 10.0, 0.1, "suffix:s") var title_fade_time: float = 2.5

@export_group("Mirada")
## Entre los momentos guiados se puede mirar alrededor con el mouse, sin moverse (está acostado).
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12
## Hasta dónde puede girar la cabeza a cada lado y hacia arriba o abajo.
@export_range(10.0, 170.0, 1.0, "suffix:°") var max_yaw: float = 110.0
@export_range(-80.0, 0.0, 1.0, "suffix:°") var min_pitch: float = -45.0
@export_range(0.0, 89.0, 1.0, "suffix:°") var max_pitch: float = 85.0

@export_group("Monitor cardíaco")
@export var monitor_beep: AudioStream
## Tiempo entre bips (1 = 60 pulsaciones por minuto).
@export_range(0.3, 3.0, 0.01, "suffix:s") var beep_interval: float = 0.95
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var beep_db: float = -8.0

@export_group("Luces del techo")
## Las mismas del cielo de la M4 (forma y color): el techo se arma achicando esa grilla a la altura
## real del techo, así desde la cama se ven igual que se veían en el cielo.
@export var ceiling_lights: HospitalLightsSettings
## Brillo de cada panel y de la luz que echa a la habitación.
@export_range(0.0, 10.0, 0.05) var panel_energy: float = 1.6
@export_range(0.0, 10.0, 0.05) var room_light_energy: float = 0.6
@export_range(0.5, 15.0, 0.1, "suffix:m") var room_light_range: float = 5.5
