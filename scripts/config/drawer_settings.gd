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
## Volumen del sonido de abrir. Subilo si el archivo de audio quedó bajito.
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var open_volume_db: float = 0.0
## Volumen del sonido de cerrar.
@export_range(-40.0, 24.0, 0.5, "suffix:dB") var close_volume_db: float = 0.0
## Bus de audio por el que salen.
@export var sound_bus: StringName = &"Master"
