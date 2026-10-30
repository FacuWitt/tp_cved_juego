class_name HospitalLightsSettings
extends Resource
## Las 6 luces del techo del hospital que se ven en el cielo cuando cae un rayo: quien mira
## arriba durante el rayo ve, sin saberlo, el techo del hospital donde está en coma.
## Lo usa HospitalLights.

enum Placement {
	## Arriba de la cabeza, como un techo (columnas a los lados, filas hacia adelante).
	OVERHEAD,
	## En la dirección de donde viene cada rayo, de frente a la cámara.
	LIGHTNING_SOURCE,
}

@export_group("Forma")
## Dónde aparecen.
@export var placement: Placement = Placement.OVERHEAD
## Columnas y filas de paneles (2 x 3 = 6 luces, las mismas que habrá en el hospital).
@export_range(1, 6, 1) var columns: int = 2
@export_range(1, 6, 1) var rows: int = 3
## Tamaño de cada panel (ancho x largo), a la distancia de abajo. Con 100 m y FOV 75°, el
## tamaño por defecto ocupa algo más de un cuarto del ancho de la pantalla mirando arriba.
@export var panel_size: Vector2 = Vector2(46.0, 31.0)
## Separación entre centros de paneles (entre columnas, entre filas).
@export var spacing: Vector2 = Vector2(122.0, 37.0)
## A qué distancia de la cámara se dibujan. Si se cambia, conviene escalar tamaño y separación igual.
@export_range(20.0, 600.0, 1.0, "suffix:m") var distance: float = 100.0
## Borde difuso de cada panel (0 = borde duro).
@export_range(0.0, 1.0, 0.01) var edge_softness: float = 0.08

@export_group("Brillo")
## Color de las luces.
@export var color: Color = Color(1.0, 0.86, 0.45)
## Brillo con el rayo al máximo (sube si el cielo del rayo las tapa).
@export_range(0.0, 20.0, 0.1) var energy: float = 2.0
## Opacidad con el rayo al máximo (1 = paneles sólidos).
@export_range(0.0, 1.0, 0.01) var max_opacity: float = 0.85
## Cómo sigue al rayo: 1 = igual que el rayo, más alto = solo aparecen en los picos.
@export_range(0.5, 6.0, 0.1) var flash_curve: float = 1.0
## Por debajo de este brillo del rayo no se ven.
@export_range(0.0, 1.0, 0.01) var threshold: float = 0.1
## Probabilidad de que aparezcan en cada rayo (1 = en todos).
@export_range(0.0, 1.0, 0.01) var chance_per_flash: float = 1.0
## Saca el "sol" que el cielo dibuja en la dirección del rayo.
@export var hide_sun_disc: bool = true
## Aparecen también en el relámpago largo del comienzo.
@export var show_on_long_flash: bool = false
