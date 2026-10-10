class_name RopeSettings
extends Resource
## Cómo se ven, cuelgan y se cortan las sogas del barco.

@export_group("Aspecto")
## Cuántos lados tiene el cilindro de la soga (más = más redonda y más costosa).
@export_range(5, 12, 1) var sides: int = 7
## Largo del cordón trenzado antes de repetirse la textura.
@export_range(0.1, 2.0, 0.05, "suffix:m") var texture_pitch: float = 0.45
## Cuántos puntos tiene el tramo hacia el mar (más = curva más suave).
@export_range(8, 40, 1) var sea_points: int = 20
## Cuántos puntos tiene el tramo hacia el cabrestante.
@export_range(3, 16, 1) var winch_points: int = 7

@export_group("Cómo cuelgan")
## Cuánto cae el centro del tramo hacia el mar por su propio peso.
@export_range(0.0, 3.0, 0.05, "suffix:m") var sag: float = 0.85
## Cuánto se curva el tramo hacia la proa, empujado por el viento y la corriente.
@export_range(0.0, 3.0, 0.05, "suffix:m") var belly: float = 0.55
## Cuánto vibra cuando recibe un golpe de hacha.
@export_range(0.0, 0.3, 0.005, "suffix:m") var hit_tremor: float = 0.06

@export_group("Al cortarse")
## Velocidad con que el tramo del mar sale disparado hacia el agua.
@export_range(0.0, 50.0, 0.5, "suffix:m/s") var sea_whip_speed: float = 24.0
## Velocidad con que el tramo del cabrestante vuelve de un latigazo.
@export_range(0.0, 50.0, 0.5, "suffix:m/s") var winch_whip_speed: float = 22.0
## Impulso hacia arriba del latigazo (la soga salta antes de caer).
@export_range(0.0, 15.0, 0.5, "suffix:m/s") var whip_lift: float = 5.0
## Desvío lateral al azar del latigazo.
@export_range(0.0, 10.0, 0.5, "suffix:m/s") var whip_side: float = 3.5
## Cuánto se frena la soga al meterse en el agua (0 = nada, 1 = se frena de golpe).
@export_range(0.0, 1.0, 0.01) var water_drag: float = 0.18
## Con qué velocidad se hunde la soga una vez en el agua.
@export_range(0.0, 8.0, 0.1, "suffix:m/s") var sink_speed: float = 3.0
## Rigidez de la soga (0 = hilo flojo que se quiebra, 0.5 = más tiesa).
@export_range(0.0, 0.6, 0.01) var stiffness: float = 0.22
## Rozamiento al arrastrarse por la cubierta.
@export_range(0.0, 1.0, 0.01) var deck_friction: float = 0.25
## Cuánto dura la simulación antes de quedarse quieta.
@export_range(1.0, 8.0, 0.1, "suffix:s") var sim_time: float = 3.5

@export_group("Apuntar")
## Qué tan generosa es la zona que hay que mirar para poder cortarla.
@export_range(0.05, 0.6, 0.01, "suffix:m") var aim_radius: float = 0.24
## Hasta dónde (largo de soga desde el corte hacia el mar) se puede apuntar.
@export_range(0.5, 12.0, 0.5, "suffix:m") var aim_length: float = 5.0
