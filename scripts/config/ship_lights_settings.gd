class_name ShipLightsSettings
extends Resource
## Luces visibles del barco: el brillo de las ventanas de la cabina y el proyector del mástil
## (con su encandilamiento). Todo lo que se ajusta a ojo está acá.

@export_group("Ventanas de la cabina")
## Color del brillo que se ve por las ventanas (luz de adentro, sin dejar ver el interior).
@export var window_color: Color = Color(1.0, 0.68, 0.32)
@export_range(0.0, 8.0, 0.05) var window_energy: float = 1.5
## Tamaño de cada ventana en metros (ancho, alto).
@export var window_size: Vector2 = Vector2(0.7, 0.62)
## Qué tanto titila la luz (0 = fija).
@export_range(0.0, 1.0, 0.01) var window_flicker: float = 0.12
@export_range(0.0, 30.0, 0.5, "suffix:/s") var window_flicker_speed: float = 9.0
## Halo suave alrededor de cada ventana, como luz que se escapa por la lluvia.
@export_range(0.0, 3.0, 0.05) var window_halo_scale: float = 2.6
@export_range(0.0, 2.0, 0.01) var window_halo_energy: float = 0.55

@export_group("Proyector — aspecto")
@export_range(0.05, 1.0, 0.01, "suffix:m") var lens_radius: float = 0.32
@export_range(0.1, 2.0, 0.05, "suffix:m") var housing_length: float = 0.7
@export_range(0.5, 20.0, 0.1) var lens_energy: float = 6.0
## Tamaño del halo (siempre de frente a la cámara) y su intensidad.
@export_range(0.5, 20.0, 0.1, "suffix:m") var halo_size: float = 7.0
@export_range(0.0, 8.0, 0.05) var halo_energy: float = 1.6

@export_group("Proyector — encandilamiento")
## Con la lente a menos de este ángulo del centro de la mirada, el efecto es pleno.
@export_range(0.5, 30.0, 0.5, "suffix:°") var glare_core_angle: float = 6.0
## Más allá de este ángulo del centro de la mirada ya no encandila.
@export_range(10.0, 90.0, 1.0, "suffix:°") var glare_edge_angle: float = 42.0
## La lente tiene que apuntar hacia vos: 1 = de frente, 0 = de costado.
@export_range(-0.5, 0.95, 0.01) var facing_min: float = 0.25
## A esta distancia empieza a perder fuerza y a la lejana ya no encandila.
@export_range(1.0, 100.0, 1.0, "suffix:m") var dazzle_near: float = 18.0
@export_range(20.0, 400.0, 1.0, "suffix:m") var dazzle_far: float = 140.0
## Tope del blanco sobre la pantalla (0 = sin encandilar, 1 = pantalla blanca).
@export_range(0.0, 1.0, 0.01) var max_dazzle: float = 0.88
## Cuánto tarda en encandilar al mirarlo y cuánto en desaparecer al mirar para otro lado
## (corto: no queda la vista "quemada" después).
@export_range(0.01, 2.0, 0.01, "suffix:s") var dazzle_rise_time: float = 0.18
@export_range(0.01, 2.0, 0.01, "suffix:s") var dazzle_fall_time: float = 0.1
## Color del encandilamiento.
@export var dazzle_color: Color = Color(1.0, 0.96, 0.86)
