class_name BoatFloodSettings
extends Resource
## Valores de la sala de los barcos de la M3 (la última sala intermedia): montañas de barquitos,
## un paso angosto por el medio y barquitos que caen cada vez más seguido.
## Se editan desde el Inspector en res://config/m3_boat_flood.tres.

@export_group("Sala")
## Ancho de la sala.
@export_range(4.0, 30.0, 0.5, "suffix:m") var room_width: float = 10.0
## Largo de la sala (lo que hay que cruzar).
@export_range(6.0, 60.0, 0.5, "suffix:m") var room_depth: float = 26.0
## Alto de las paredes. No hay techo: arriba está el cielo negro de la tormenta.
@export_range(3.0, 20.0, 0.5, "suffix:m") var wall_height: float = 7.0
## Semilla del azar: otra semilla, otras montañas.
@export var random_seed: int = 3
## Cuánto pesan las piernas al llegar al fondo (0 = nada, 1 = lo mismo que en el pasillo de la casa).
@export_range(0.0, 1.0, 0.01) var leg_drag: float = 0.6

@export_group("Paso entre los barcos")
## Medio ancho del paso libre. Más chico = más apretado (el jugador mide 0,35 m de radio).
@export_range(0.45, 3.0, 0.05, "suffix:m") var path_half_width: float = 0.85
## Cuánto se va el paso hacia los costados (forma de S). 0 = recto.
@export_range(0.0, 6.0, 0.1, "suffix:m") var path_sway: float = 2.0
## Cuántas eses hace el paso de punta a punta.
@export_range(0.0, 3.0, 0.5) var path_curves: float = 1.5

@export_group("Montañas")
## Qué tan empinadas son (metros de alto por metro que se aleja del paso). Más de 1 no se puede trepar.
@export_range(0.5, 5.0, 0.05) var mound_slope: float = 1.7
## Altura máxima de las montañas.
@export_range(0.5, 12.0, 0.1, "suffix:m") var mound_height: float = 5.0
## Irregularidad de las montañas.
@export_range(0.0, 1.5, 0.05, "suffix:m") var mound_bumps: float = 0.45
## Cantidad de barquitos apilados. Es lo que más pesa en el rendimiento: bajarlo si va lento.
@export_range(50, 4000, 10) var boat_count: int = 1300
## Largo del barquito más chico.
@export_range(0.1, 2.0, 0.05, "suffix:m") var boat_min_length: float = 0.45
## Largo del barquito más grande.
@export_range(0.2, 6.0, 0.05, "suffix:m") var boat_max_length: float = 1.7
## Cuántos son chicos: 1 = tamaños parejos; más alto = casi todos chicos y pocos grandes.
@export_range(1.0, 5.0, 0.1) var small_bias: float = 2.2
## Cuánto pueden estar volcados respecto de la pendiente donde están apoyados.
@export_range(0.0, 180.0, 1.0, "suffix:°") var tilt_max: float = 80.0
## Cuánto sobresalen de la superficie de la montaña, en largos de barco: 0 = medio enterrados,
## 0,3 = apoyados encima, más = flotando.
@export_range(0.0, 1.0, 0.01) var lift_min: float = 0.24
## Hasta cuánto sobresalen (cada uno toma un valor al azar entre los dos).
@export_range(0.0, 1.0, 0.01) var lift_max: float = 0.42
## Hasta esta altura la montaña tiene todos sus barquitos (es lo que el jugador mira: adelante y abajo).
@export_range(0.0, 12.0, 0.1, "suffix:m") var dense_height: float = 2.6
## Cuántos barquitos hay en la cima respecto de abajo (1 = igual de tupido, 0 = ninguno).
@export_range(0.0, 1.0, 0.01) var top_density: float = 0.25
## Cada cuántos metros se repite la textura de barcos apilados que hay debajo (a lo largo de la sala;
## a lo alto se repite cada el doble).
@export_range(1.0, 20.0, 0.1, "suffix:m") var fill_tile: float = 4.0

@export_group("Barquitos que caen")
## Cuántos barquitos sueltos puede haber a la vez (los más viejos se reciclan cuando no se los mira).
@export_range(0, 120, 1) var max_falling: int = 40
## Cada cuánto cae uno al entrar a la sala.
@export_range(0.05, 10.0, 0.05, "suffix:s") var fall_interval_start: float = 1.8
## Cada cuánto cae uno al llegar al fondo (te bombardea).
@export_range(0.05, 10.0, 0.05, "suffix:s") var fall_interval_end: float = 0.22
## Desde qué altura caen.
@export_range(2.0, 20.0, 0.1, "suffix:m") var fall_height: float = 6.5
## Caen entre esta distancia...
@export_range(0.0, 10.0, 0.1, "suffix:m") var fall_ahead_min: float = 1.2
## ...y esta, adelante del jugador, sobre el paso.
@export_range(0.5, 20.0, 0.1, "suffix:m") var fall_ahead_max: float = 6.0
## Cuánto se desvían hacia los costados del paso.
@export_range(0.0, 4.0, 0.05, "suffix:m") var fall_spread: float = 0.9
## Probabilidad de que uno caiga justo encima del jugador.
@export_range(0.0, 1.0, 0.01) var overhead_chance: float = 0.18
## Largo del barquito que cae más chico.
@export_range(0.1, 2.0, 0.05, "suffix:m") var fall_min_length: float = 0.35
## Largo del barquito que cae más grande.
@export_range(0.1, 3.0, 0.05, "suffix:m") var fall_max_length: float = 0.8
## Cuánto pesan. Más livianos = el jugador los aparta más fácil al caminar.
@export_range(0.05, 10.0, 0.05, "suffix:kg") var fall_mass: float = 0.5
## Cuánto giran al caer.
@export_range(0.0, 20.0, 0.1, "suffix:rad/s") var fall_spin: float = 5.0
## A partir de qué parte del recorrido caen de a dos (0 = desde el comienzo, 1 = nunca).
@export_range(0.0, 1.0, 0.01) var cascade_at: float = 0.7

@export_group("Luz")
## Luz ambiente de la sala, respecto de la de la casa (1 = igual, 0 = negro entre rayo y rayo).
@export_range(0.0, 2.0, 0.01) var ambient: float = 0.45
## Luz fría tenue que deja adivinar las montañas entre rayo y rayo.
@export_range(0.0, 3.0, 0.01) var cold_light_energy: float = 0.22
## Luz cálida de la salida (el velador de la hija está del otro lado).
@export_range(0.0, 8.0, 0.05) var exit_glow_energy: float = 2.2
## Hasta dónde llega la luz de la salida.
@export_range(1.0, 20.0, 0.1, "suffix:m") var exit_glow_range: float = 7.0
## Fuerza de la luz que cae desde arriba con cada rayo.
@export_range(0.0, 20.0, 0.1) var flash_energy: float = 2.6
## Cuánto tarda el primer rayo largo, el que deja ver toda la sala, después de entrar.
@export_range(0.0, 10.0, 0.1, "suffix:s") var reveal_delay: float = 1.0
## Cuánto dura ese rayo largo.
@export_range(0.5, 6.0, 0.1, "suffix:s") var reveal_duration: float = 1.8

@export_group("Sonido")
## Golpes de madera de los barquitos que caen.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var knock_volume_db: float = -5.0
## Rumor de barquitos cayendo, al entrar...
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var cascade_volume_start_db: float = -34.0
## ...y al llegar al fondo.
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var cascade_volume_end_db: float = -7.0
## Drone grave de fondo.
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var drone_volume_db: float = -13.0
## Golpe cuando un barquito le pega al jugador.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var hit_volume_db: float = -3.0
## Cuánto baja la cámara con ese golpe.
@export_range(0.0, 0.4, 0.005, "suffix:m") var hit_kick: float = 0.07
## Cuánto tarda la cámara en recuperarse.
@export_range(0.05, 1.5, 0.01, "suffix:s") var hit_kick_time: float = 0.3
