class_name RiverEventsSettings
extends Resource
## Lo que pasa en el río durante la huida de la Memoria 2: árboles que se caen al agua
## cuando se acerca el bote, troncos que bajan flotando y tramos oscuros donde solo se ve
## lo que alumbra la linterna. Las distancias son metros de curva del cauce (RiverFlow).

@export_group("Árboles que caen")
## Dónde cae cada árbol (metros de curva).
@export var tree_offsets: PackedFloat32Array = PackedFloat32Array([128.0, 190.0, 272.0, 330.0])
## A cuántos metros del árbol tiene que estar el bote para que empiece a caer.
@export_range(5.0, 80.0, 0.5, "suffix:m") var tree_trigger_distance: float = 26.0
## Cuánto tarda en caer.
@export_range(0.3, 5.0, 0.05, "suffix:s") var tree_fall_time: float = 1.5
## Paso libre que deja al lado de la línea del padre (el árbol nunca tapa todo el río).
@export_range(1.0, 10.0, 0.1, "suffix:m") var tree_gap: float = 4.0
## Fuerza del relámpago que acompaña la caída (0 = sin relámpago).
@export_range(0.0, 1.0, 0.01) var tree_flash: float = 0.6

@export_group("Troncos flotando")
## Tramo del río donde aparecen troncos (metros de curva).
@export_range(0.0, 1000.0, 1.0, "suffix:m") var logs_from: float = 100.0
@export_range(0.0, 1000.0, 1.0, "suffix:m") var logs_to: float = 375.0
## Cuántos troncos puede haber a la vez.
@export_range(0, 20, 1) var log_count: int = 6
## Cada cuánto aparece uno nuevo.
@export_range(0.5, 20.0, 0.1, "suffix:s") var log_interval_min: float = 2.0
@export_range(0.5, 20.0, 0.1, "suffix:s") var log_interval_max: float = 4.5
## A qué distancia adelante del bote aparecen (lejos, para que la niebla los esconda).
@export_range(10.0, 120.0, 1.0, "suffix:m") var log_spawn_min: float = 38.0
@export_range(10.0, 120.0, 1.0, "suffix:m") var log_spawn_max: float = 60.0
## Largo y grosor de los troncos.
@export_range(1.0, 10.0, 0.1, "suffix:m") var log_length_min: float = 3.0
@export_range(1.0, 10.0, 0.1, "suffix:m") var log_length_max: float = 5.5
@export_range(0.1, 1.0, 0.01, "suffix:m") var log_radius: float = 0.28
## Fracción de la corriente que los lleva (el bote los alcanza remando).
@export_range(0.0, 1.5, 0.01) var log_drift_factor: float = 0.8
## Velocidad con la que el tronco se corre cuando lo toca el bote.
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var log_push: float = 2.5
## Cuánto giran sobre sí mismos mientras bajan.
@export_range(0.0, 1.0, 0.01, "suffix:rad/s") var log_spin: float = 0.15

@export_group("Tramos oscuros")
## Cada Vector2 es (desde, hasta) en metros de curva.
@export var dark_zones: PackedVector2Array = PackedVector2Array([Vector2(150.0, 200.0), Vector2(296.0, 352.0)])
## Metros en los que se oscurece o se aclara al entrar y salir.
@export_range(1.0, 40.0, 0.5, "suffix:m") var dark_fade: float = 12.0
## Niebla y luz ambiente en lo más oscuro.
@export var dark_fog_color: Color = Color(0.0, 0.0, 0.0)
@export_range(0.0, 0.5, 0.001) var dark_fog_density: float = 0.075
@export_range(0.0, 1.0, 0.01) var dark_ambient: float = 0.0
@export_range(0.0, 1.0, 0.01) var dark_sky: float = 0.0
## En lo oscuro no caen rayos (solo el del árbol que cae).
@export var dark_stops_lightning: bool = true
## Apertura del haz de la linterna en lo oscuro (un poco más ancha para poder jugar).
@export_range(5.0, 80.0, 0.5, "suffix:°") var dark_lamp_angle: float = 34.0
## Intensidad de la linterna en lo oscuro.
@export_range(0.0, 20.0, 0.1) var dark_lamp_energy: float = 6.0
## Alcance de la linterna en lo oscuro.
@export_range(5.0, 80.0, 0.5, "suffix:m") var dark_lamp_range: float = 26.0
