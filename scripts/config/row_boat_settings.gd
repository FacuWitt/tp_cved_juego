class_name RowBoatSettings
extends Resource
## Cómo se maneja el bote a remos de la Memoria 2: fuerza de cada remada, cuánto gira,
## cuánto lo frena el agua, cómo lo empujan el viento y los rápidos, y cuántos golpes aguanta.

@export_group("Remadas")
## Duración de una remada completa (el remo entra, empuja y sale).
@export_range(0.2, 2.0, 0.01, "suffix:s") var stroke_time: float = 0.62
## Empuje hacia adelante de cada remada (en el pico de la remada). Bajo = el bote tarda
## en tomar velocidad (con los dos remos llega a la máxima en unos 4 s).
@export_range(0.0, 20.0, 0.1, "suffix:m/s²") var stroke_force: float = 1.8
## Cuánto gira el bote por remada de un solo lado (en el pico de la remada).
@export_range(0.0, 10.0, 0.05, "suffix:rad/s²") var stroke_turn: float = 1.7
## Las remadas hacia atrás empujan esta fracción de una remada hacia adelante.
@export_range(0.1, 1.5, 0.05) var back_stroke_factor: float = 1.0
## Velocidad máxima respecto del agua.
@export_range(0.5, 12.0, 0.1, "suffix:m/s") var max_speed: float = 6.2

@export_group("Agua")
## Cuánto sobresale el casco del agua (más alto = el agua no se mete por el piso con olas).
@export_range(0.0, 0.6, 0.01, "suffix:m") var hull_lift: float = 0.14
## Cuánto lo frena el agua hacia adelante (por segundo). Bajo = se desliza más.
@export_range(0.0, 5.0, 0.01, "suffix:1/s") var forward_drag: float = 0.2
## Cuánto lo frena el agua de costado (la quilla no lo deja derrapar).
@export_range(0.0, 10.0, 0.05, "suffix:1/s") var side_drag: float = 2.8
## Cuánto se frena el giro.
@export_range(0.0, 10.0, 0.05, "suffix:1/s") var turn_drag: float = 2.2
## Cuánto se mece con el agua (metros) y qué tan rápido.
@export_range(0.0, 0.3, 0.005, "suffix:m") var bob_height: float = 0.05
@export_range(0.1, 5.0, 0.05, "suffix:Hz") var bob_speed: float = 0.6
## Cuánto se mece en los rápidos (se suma).
@export_range(0.0, 0.5, 0.005, "suffix:m") var rapids_bob: float = 0.14

@export_group("Viento")
## Cuánto se inclina el bote por cada m/s² de viento de costado.
@export_range(0.0, 10.0, 0.1, "suffix:°") var wind_roll: float = 2.4
## Cuánto lo hace girar el viento (fracción del empuje de costado).
@export_range(0.0, 2.0, 0.01) var wind_turn: float = 0.22

@export_group("Golpes")
## Si es true, con `max_hits` golpes el bote se hunde y empieza el final. Si es false (lo que
## pidió el equipo), los golpes solo lo sacuden y lo llenan de agua, y el final llega siempre en el
## último rápido.
@export var sinks_on_hits: bool = false
## Golpes que llenan el bote de agua (y, con `sinks_on_hits`, con este golpe se hunde).
@export_range(1, 10, 1) var max_hits: int = 3
## Velocidad de choque mínima para que cuente como golpe.
@export_range(0.1, 5.0, 0.05, "suffix:m/s") var hit_speed: float = 1.5
## Tiempo sin poder recibir otro golpe.
@export_range(0.0, 5.0, 0.05, "suffix:s") var hit_cooldown: float = 1.6
## Cuánto rebota al chocar (0 = se queda pegado, 1 = rebota entero).
@export_range(0.0, 1.0, 0.01) var bounce: float = 0.45
## Sacudón de cámara de un golpe.
@export_range(0.0, 0.3, 0.005) var hit_shake: float = 0.09
## Altura del agua adentro del bote con cada golpe.
@export_range(0.0, 0.3, 0.005, "suffix:m") var water_per_hit: float = 0.07
