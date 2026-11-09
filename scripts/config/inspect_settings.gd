class_name InspectSettings
extends Resource
## Inspección de objetos estilo Silent Hill (InspectView): el objeto viene a la cara, el fondo se
## desenfoca y se oscurece, se abre y se lee la página.

@export_group("Fondo")
## Qué tan borroso queda lo que está detrás.
@export_range(0.0, 6.0, 0.1) var background_blur: float = 2.6
## Cuánto se oscurece lo que está detrás (0 = nada, 1 = negro).
@export_range(0.0, 1.0, 0.01) var background_darken: float = 0.35
## Cuánto tarda el fondo en desenfocarse y en volver.
@export_range(0.05, 2.0, 0.01, "suffix:s") var background_fade_time: float = 0.4

@export_group("El objeto en la mano")
## Cuánto tarda el objeto en venir desde donde está hasta frente a la cara.
@export_range(0.1, 3.0, 0.01, "suffix:s") var fly_time: float = 0.6
## A qué distancia de la cara queda.
@export_range(0.15, 1.5, 0.01, "suffix:m") var hold_distance: float = 0.42
## Cuánto lo gira en el camino (da la sensación de que se lo agarra y se lo da vuelta).
@export_range(0.0, 360.0, 1.0, "suffix:°") var fly_spin: float = 25.0
## Inclinación con la que se lo mira (hacia el jugador).
@export_range(-90.0, 90.0, 1.0, "suffix:°") var hold_tilt: float = 62.0
## Pausa mirando el objeto cerrado antes de abrirlo.
@export_range(0.0, 3.0, 0.01, "suffix:s") var look_pause: float = 0.25

@export_group("Abrir y leer")
## Cuánto tarda en abrirse la tapa (libros: nodo "CoverHinge").
@export_range(0.05, 3.0, 0.01, "suffix:s") var open_time: float = 0.5
## Ángulo al que se abre la tapa.
@export_range(30.0, 180.0, 1.0, "suffix:°") var open_angle: float = 165.0
## Cuánto tarda en aparecer la página.
@export_range(0.05, 2.0, 0.01, "suffix:s") var page_fade_time: float = 0.35
## La página aparece un poco más chica y crece hasta su tamaño (1 = sin efecto).
@export_range(0.5, 1.0, 0.01) var page_scale_from: float = 0.9
## Alto de la página respecto de la pantalla.
@export_range(0.3, 1.0, 0.01) var page_screen_height: float = 0.86
## Texto de ayuda abajo mientras se lee.
@export var close_hint: String = "(E) Cerrar"

@export_group("Luz del objeto")
## Color e intensidad de la luz con la que se ve el objeto en la mano.
@export var light_color: Color = Color(1.0, 0.85, 0.68)
@export_range(0.0, 4.0, 0.05) var light_energy: float = 1.2
@export_range(0.0, 2.0, 0.05) var ambient_energy: float = 0.55
