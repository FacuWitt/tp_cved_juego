class_name LakeSettings
extends Resource
## Cómo se ve y se mueve el agua del lago: altura de las olas, colores del atardecer a la tormenta
## y espuma. Lo usa LakeWater (y el shader lake_water.gdshader).

@export_group("Oleaje")
## Altura base de las olas con tormenta al máximo.
@export_range(0.05, 3.0, 0.01, "suffix:m") var storm_wave_height: float = 0.55
## Qué parte de esa altura tiene el agua en calma (0 = espejo, 1 = ya con tormenta).
@export_range(0.0, 1.0, 0.01) var calm_wave_scale: float = 0.1
## Velocidad con la que corre el oleaje.
@export_range(0.1, 3.0, 0.05) var wave_speed: float = 1.0

@export_group("Colores en calma (atardecer)")
@export var calm_deep_color: Color = Color(0.035, 0.07, 0.085)
@export var calm_horizon_color: Color = Color(0.95, 0.55, 0.38)
@export var calm_zenith_color: Color = Color(0.22, 0.26, 0.42)
## Cuánto refleja el cielo en calma.
@export_range(0.0, 2.0, 0.01) var calm_reflect: float = 0.55

@export_group("Colores con tormenta")
@export var storm_deep_color: Color = Color(0.008, 0.02, 0.028)
@export var storm_horizon_color: Color = Color(0.5, 0.58, 0.68)
@export var storm_zenith_color: Color = Color(0.08, 0.11, 0.17)
## Cuánto refleja el cielo de noche (sin rayo).
@export_range(0.0, 2.0, 0.001) var storm_reflect: float = 0.014
## Color pizarra de las olas cuando cae un rayo.
@export var slate_color: Color = Color(0.07, 0.11, 0.15)

@export_group("Espuma")
@export var foam_color: Color = Color(0.62, 0.68, 0.72)
## Cuánta espuma hay en las crestas con tormenta.
@export_range(0.0, 1.0, 0.01) var foam_amount: float = 0.7

@export_group("Luz de la linterna sobre el agua")
## Color con el que el agua devuelve la luz cálida de las linternas.
@export var lit_color: Color = Color(0.72, 0.5, 0.26)
@export_range(0.0, 12.0, 0.1) var lit_strength: float = 4.0
