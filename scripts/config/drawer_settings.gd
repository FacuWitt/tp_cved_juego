class_name DrawerSettings
extends Resource
## Cómo se abre un cajón (Drawer).

## Cuánto sale el cajón al abrirse.
@export_range(0.05, 1.0, 0.01, "suffix:m") var open_distance: float = 0.36
## Cuánto tarda en abrirse o cerrarse.
@export_range(0.05, 2.0, 0.01, "suffix:s") var slide_time: float = 0.45
## Un pequeño rebote al final de la apertura (0 = sin rebote).
@export_range(0.0, 0.1, 0.005, "suffix:m") var overshoot: float = 0.015
## Sonido al abrir y al cerrar (opcionales).
@export var open_sound: AudioStream
@export var close_sound: AudioStream
