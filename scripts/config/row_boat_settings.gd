class_name RowBoatSettings
extends Resource
## Cómo se maneja el bote a remos de la Memoria 2: fuerza de cada remada, cuánto gira,
## cuánto lo frena el agua, cómo lo empujan el viento y los rápidos, y cuántos golpes aguanta.

@export_group("Remadas")
## Cada toque de tecla es una remada (mecánica de Mica): A = remo izquierdo, D = remo derecho,
## S = los dos hacia atrás. La pala entra al agua y ahí se da el empujón.
## Duración de una remada completa (el remo entra, empuja y sale). Más corto = remos más ágiles.
@export_range(0.2, 1.5, 0.01, "suffix:s") var stroke_time: float = 0.4
## En qué parte de la remada la pala toca el agua y empuja (0 = al instante, 0.5 = a la mitad).
## Más bajo = el bote responde antes a la tecla.
@export_range(0.0, 0.5, 0.01) var blade_enter: float = 0.1
## Empujón hacia adelante que da cada remada, al entrar la pala.
@export_range(0.2, 6.0, 0.05, "suffix:m/s") var stroke_thrust: float = 1.5
## Giro que da cada remada de un solo lado. El remo izquierdo gira el bote a la derecha y al revés.
@export_range(0.0, 120.0, 1.0, "suffix:°/s") var stroke_turn: float = 30.0
## Tiempo mínimo entre dos remadas del mismo remo.
@export_range(0.1, 1.5, 0.01, "suffix:s") var stroke_cooldown: float = 0.28
## Si se toca la tecla durante la espera, la remada se guarda este tiempo y sale apenas se puede.
@export_range(0.0, 0.5, 0.01, "suffix:s") var stroke_buffer_time: float = 0.2
## Empuje extra al alternar un remo con el otro (remar parejo rinde más).
@export_range(0.0, 1.0, 0.01) var alternate_bonus: float = 0.3
## Empuje que se pierde al remar dos veces seguidas del mismo lado.
@export_range(0.0, 1.0, 0.01) var repeat_penalty: float = 0.25
## Las remadas hacia atrás (S, los dos remos) empujan esta fracción de una remada hacia adelante.
@export_range(0.1, 1.5, 0.05) var back_stroke_factor: float = 0.7
## Si está prendido, mantener apretada la tecla sigue remando solo (si no, hay que tocarla cada vez).
@export var hold_to_repeat: bool = false
## Con esto prendido, el remo derecho gira el bote a la derecha (más intuitivo, menos realista).
@export var invert_steering: bool = false
## El giro rinde menos si el bote está casi parado (0 = igual de parado, 1 = no gira sin velocidad).
@export_range(0.0, 1.0, 0.01) var turn_needs_speed: float = 0.35
## Giro máximo del bote.
@export_range(10.0, 180.0, 1.0, "suffix:°/s") var max_turn_rate: float = 60.0
## Velocidad máxima respecto del agua.
@export_range(0.5, 12.0, 0.1, "suffix:m/s") var max_speed: float = 6.2

@export_group("Agua")
## Cuánto sobresale el casco del agua (más alto = el agua no se mete por el piso con olas).
@export_range(0.0, 0.6, 0.01, "suffix:m") var hull_lift: float = 0.14
## Cuánto lo frena el agua hacia adelante (por segundo). Bajo = se desliza más.
@export_range(0.0, 5.0, 0.01, "suffix:1/s") var forward_drag: float = 0.35
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

@export_group("Oleaje")
## Cuánto sube y baja el casco con las olas (0 = no las sigue, 1 = las sigue del todo).
@export_range(0.0, 1.5, 0.01) var wave_bob: float = 1.0
## Cuánto se inclina de costado con las olas.
@export_range(0.0, 2.0, 0.01) var wave_roll: float = 0.9
## Cuánto cabecea (proa arriba y abajo) con las olas.
@export_range(0.0, 2.0, 0.01) var wave_pitch: float = 0.8
## Inclinación máxima por las olas (para que no maree).
@export_range(0.0, 40.0, 0.5, "suffix:°") var max_wave_tilt: float = 12.0
