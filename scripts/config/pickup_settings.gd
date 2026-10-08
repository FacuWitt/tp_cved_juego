class_name PickupSettings
extends Resource
## Valores de "feel" de los objetos que se agarran y arrastran con físicas.
## Se editan desde el Inspector en res://config/pickup_settings.tres.

## Distancia a la que se sostiene el objeto frente a la cámara.
@export_range(0.3, 3.0, 0.05, "suffix:m") var hold_distance: float = 1.5
## Qué tan fuerte "tira" el objeto hacia el punto de sostén. Más alto = más rígido y menos física.
@export_range(1.0, 40.0, 0.5, "suffix:1/s") var hold_follow_speed: float = 12.0
## Velocidad máxima mientras se sostiene, para que no acelere sin control.
@export_range(0.5, 20.0, 0.5, "suffix:m/s") var max_hold_speed: float = 8.0
## Amortiguación lineal aplicada mientras se sostiene (evita que oscile).
@export_range(0.0, 20.0, 0.5) var hold_linear_damp: float = 6.0
## Amortiguación angular aplicada mientras se sostiene.
@export_range(0.0, 20.0, 0.5) var hold_angular_damp: float = 6.0
## Si el punto de sostén queda más lejos que esto (por ejemplo, tapado por una pared), se suelta solo.
## Tiene que ser mayor que el alcance del InteractionRay del jugador + hold_distance,
## si no, agarrar un objeto justo al límite del alcance lo soltaría solo en el mismo instante.
@export_range(0.5, 10.0, 0.1, "suffix:m") var auto_release_distance: float = 4.0
