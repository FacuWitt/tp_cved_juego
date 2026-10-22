class_name HeldItemSettings
extends Resource
## Cómo se ve y se mueve un objeto que el protagonista lleva en la mano (linterna, barquito...).
## Lo usa HeldItemView. Cada objeto tiene su .tres en config/.

@export_group("Posición en la mano")
## Dónde queda el objeto respecto de la cámara (x = derecha, y = arriba, z = adelante negativo).
@export var rest_position: Vector3 = Vector3(0.3, -0.32, -0.5)
## Cómo queda inclinado en reposo (grados).
@export var rest_rotation_degrees: Vector3 = Vector3(0.0, 0.0, 0.0)
## Cuánto tarda en aparecer en la mano (sube desde abajo de la pantalla).
@export_range(0.05, 2.0, 0.01, "suffix:s") var equip_time: float = 0.45

@export_group("Reacción al movimiento")
## Cuánto se balancea al caminar.
@export_range(0.0, 0.05, 0.001, "suffix:m") var walk_bob: float = 0.012
## Velocidad del balanceo al caminar.
@export_range(1.0, 20.0, 0.1) var walk_bob_speed: float = 9.0
## Cuánto se queda atrás cuando el jugador gira la cámara (grados por grado girado).
@export_range(0.0, 2.0, 0.01) var look_lag: float = 0.45
## Qué tan rápido vuelve a su lugar después de girar.
@export_range(1.0, 30.0, 0.5, "suffix:1/s") var look_recover: float = 9.0
## Cuánto se desplaza cuando el jugador acelera o frena.
@export_range(0.0, 0.1, 0.001) var velocity_lag: float = 0.01

@export_group("Frío")
## Temblor de base (0 = firme, 1 = tiembla mucho).
@export_range(0.0, 1.0, 0.01) var shiver: float = 0.15
## Qué tan rápido tiembla.
@export_range(1.0, 40.0, 0.5, "suffix:Hz") var shiver_frequency: float = 14.0
## Cuánto se desplaza al temblar.
@export_range(0.0, 0.02, 0.0005, "suffix:m") var shiver_position: float = 0.004
## Cuánto gira al temblar.
@export_range(0.0, 8.0, 0.1, "suffix:°") var shiver_rotation: float = 1.6
