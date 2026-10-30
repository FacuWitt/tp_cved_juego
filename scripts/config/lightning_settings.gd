class_name LightningSettings
extends Resource
## Cómo son los rayos de una escena: cada cuánto caen, cuánto duran y cuánto iluminan.
## Lo usa LightningController. Cada memoria con tormenta tiene su .tres en config/.

## Tiempo mínimo entre rayos.
@export_range(0.5, 30.0, 0.1, "suffix:s") var lightning_min_interval: float = 2.4
## Tiempo máximo entre rayos.
@export_range(0.5, 60.0, 0.1, "suffix:s") var lightning_max_interval: float = 6.5
## Intensidad de la luz de un rayo.
@export_range(0.0, 20.0, 0.1) var lightning_energy: float = 1.8
## Cuánto sube la luz ambiente durante el rayo.
@export_range(0.0, 3.0, 0.05) var lightning_ambient: float = 0.35
## Cuánto se enciende el cielo (las nubes) con cada rayo.
@export_range(0.0, 40.0, 0.5) var lightning_sky: float = 14.0
## Duración de un rayo (incluye los parpadeos).
@export_range(0.1, 1.5, 0.01, "suffix:s") var lightning_time: float = 0.45
