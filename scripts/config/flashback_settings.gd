class_name FlashbackSettings
extends Resource
## Cómo se ven los flashbacks: imágenes de la noche del accidente que aparecen menos de un segundo.
## Lo usa FlashbackOverlay.

## Imágenes posibles (capturas de la Memoria 4).
@export var images: Array[Texture2D] = []
## Cuánto dura cada imagen en pantalla.
@export_range(0.05, 1.0, 0.01, "suffix:s") var image_time: float = 0.3
## Negro entre una imagen y la siguiente.
@export_range(0.0, 1.0, 0.01, "suffix:s") var gap_time: float = 0.12
## Destello blanco al aparecer cada imagen (0 = sin destello).
@export_range(0.0, 1.0, 0.01) var flash_strength: float = 0.55
## Fotosensibilidad: sin destellos, cambios suaves e imágenes más oscuras.
@export var reduce_flashes: bool = false
## Brillo de la imagen con `reduce_flashes` prendido.
@export_range(0.1, 1.0, 0.01) var reduced_brightness: float = 0.55
