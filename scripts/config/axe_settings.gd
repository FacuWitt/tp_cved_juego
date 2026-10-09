class_name AxeSettings
extends Resource
## Todo el "feel" del hacha en primera persona: dónde se sostiene, cómo reacciona al movimiento,
## cuánto tiembla de frío y cómo se ven el golpe bueno y el fallido.

@export_group("Posición en la mano")
## Dónde queda el hacha respecto de la cámara (derecha, abajo, adelante).
@export var rest_position: Vector3 = Vector3(0.34, -0.40, -0.55)
## Cómo queda inclinada en reposo (grados).
@export var rest_rotation_degrees: Vector3 = Vector3(-14.0, 8.0, -16.0)
## Tamaño del modelo (el original viene en centímetros).
@export_range(0.005, 0.1, 0.001) var model_scale: float = 0.025
## Cuánto tarda en pasar de la pared a la mano.
@export_range(0.05, 1.5, 0.01, "suffix:s") var equip_time: float = 0.35

@export_group("Reacción al movimiento")
## Cuánto se balancea al caminar.
@export_range(0.0, 0.05, 0.001, "suffix:m") var walk_bob: float = 0.012
## Velocidad del balanceo al caminar.
@export_range(1.0, 20.0, 0.1) var walk_bob_speed: float = 9.0
## Cuánto se queda atrás cuando el jugador gira la cámara (grados por grado girado).
@export_range(0.0, 2.0, 0.01) var look_lag: float = 0.55
## Qué tan rápido vuelve a su lugar después de girar.
@export_range(1.0, 30.0, 0.5, "suffix:1/s") var look_recover: float = 9.0
## Cuánto se desplaza cuando el jugador acelera o frena.
@export_range(0.0, 0.1, 0.001) var velocity_lag: float = 0.012
## Cuánto sigue al balanceo del barco (grados de cámara torcida → grados del hacha).
@export_range(0.0, 2.0, 0.05) var roll_follow: float = 0.6

@export_group("Frío")
## Temblor al principio, con ninguna soga cortada (0 = nada, 1 = máximo).
@export_range(0.0, 1.0, 0.01) var shiver_start: float = 0.08
## Cuánto sube el temblor con cada soga cortada.
@export_range(0.0, 0.5, 0.01) var shiver_per_rope: float = 0.14
## Cuánto se mueve la posición con temblor máximo.
@export_range(0.0, 0.05, 0.001, "suffix:m") var shiver_position: float = 0.014
## Cuánto gira con temblor máximo.
@export_range(0.0, 10.0, 0.1, "suffix:°") var shiver_rotation: float = 3.2
## Frecuencia del temblor.
@export_range(4.0, 40.0, 0.5, "suffix:Hz") var shiver_frequency: float = 21.0

@export_group("Golpes")
## Cuánto sube el hacha antes de bajar el golpe.
@export_range(10.0, 120.0, 1.0, "suffix:°") var raise_angle: float = 58.0
## Duración total del golpe acertado.
@export_range(0.1, 1.0, 0.01, "suffix:s") var hit_time: float = 0.34
## Cuánto avanza el hacha hacia la soga al acertar.
@export_range(0.0, 0.6, 0.01, "suffix:m") var hit_lunge: float = 0.22
## Duración del golpe fallido (rebota).
@export_range(0.1, 1.2, 0.01, "suffix:s") var miss_time: float = 0.5
## Cuánto rebota hacia arriba al fallar.
@export_range(0.0, 60.0, 1.0, "suffix:°") var miss_recoil: float = 28.0
## Temblor extra que queda en la mano después de fallar (se va solo).
@export_range(0.0, 1.0, 0.01) var miss_shiver_kick: float = 0.5
