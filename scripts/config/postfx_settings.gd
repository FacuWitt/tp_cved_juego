class_name PostFxSettings
extends Resource
## Valores del postprocesado "PS1 con esteroides". Cada escena puede tener su propio perfil
## (res://config/postfx_*.tres) para que la memoria 1 sea cálida y la 4 fría y áspera.

@export_group("Pixelado y color (la parte PS1)")
## Tamaño del "píxel" en píxeles reales de pantalla. 1 = sin pixelado, 2-3 = look PS1 marcado.
@export_range(1.0, 6.0, 0.25) var pixel_size: float = 2.0
## Niveles de color por canal. 32 = como la PlayStation original; 256 = sin reducir.
@export_range(4, 256, 1) var color_levels: int = 32
## Fuerza del tramado (dither) que disimula la reducción de colores.
@export_range(0.0, 1.0, 0.01) var dither_strength: float = 0.7

@export_group("Lente")
## Oscurecimiento de las esquinas.
@export_range(0.0, 1.5, 0.01) var vignette_strength: float = 0.55
## Radio de la zona clara: más bajo = la viñeta entra más hacia el centro.
@export_range(0.2, 1.2, 0.01) var vignette_radius: float = 0.75
## Separación de colores en los bordes de la pantalla (aberración cromática).
@export_range(0.0, 8.0, 0.1, "suffix:px") var chromatic_aberration: float = 1.0
## Grano de película.
@export_range(0.0, 0.3, 0.005) var grain_strength: float = 0.05

@export_group("Color")
## Contraste general (1 = sin cambios).
@export_range(0.5, 1.8, 0.01) var contrast: float = 1.12
## Saturación general (1 = sin cambios, 0 = blanco y negro).
@export_range(0.0, 1.5, 0.01) var saturation: float = 0.85
## Color que se suma en las sombras (frío = azul verdoso).
@export var shadow_tint: Color = Color(0.0, 0.03, 0.06)
## Color que se suma en las luces.
@export var highlight_tint: Color = Color(0.03, 0.02, 0.0)
## Cuánto se levantan los negros (0 = negro puro; más = velo grisáceo, estilo película vieja).
@export_range(0.0, 0.1, 0.002) var black_lift: float = 0.0
