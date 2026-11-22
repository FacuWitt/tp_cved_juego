class_name RowCourseSettings
extends Resource
## El recorrido del lago: el camino que sigue el padre y los obstáculos que hay que esquivar.
## Lo usa RowCourse. Todo es ajustable desde acá.

@export_group("Camino")
## Puntos (x, z) por los que pasa el camino, en orden. El bote arranca en el primero mirando hacia -Z.
## La curva que une los puntos es suave (Catmull-Rom).
@export var points: PackedVector2Array = PackedVector2Array([
	Vector2(0, 0), Vector2(0, -16), Vector2(3, -34), Vector2(10, -52), Vector2(12, -72),
	Vector2(7, -92), Vector2(-3, -110), Vector2(-12, -130), Vector2(-14, -149),
	Vector2(-10, -169), Vector2(-1, -187), Vector2(4, -203)])
## Separación entre los puntos de la curva ya suavizada.
@export_range(0.5, 10.0, 0.5, "suffix:m") var sample_step: float = 2.0

@export_group("Obstáculos")
## Semilla: con la misma semilla, siempre salen los mismos obstáculos.
@export var seed_value: int = 20260
## A qué distancia del comienzo aparece el primer obstáculo (antes es el tramo para aprender).
@export_range(0.0, 300.0, 1.0, "suffix:m") var first_obstacle_at: float = 28.0
## Distancia libre de obstáculos antes de la cabaña.
@export_range(0.0, 200.0, 1.0, "suffix:m") var clear_end: float = 28.0
## Separación entre obstáculos en el tramo tranquilo.
@export_range(5.0, 80.0, 0.5, "suffix:m") var spacing_calm: float = 15.0
## Separación entre obstáculos con tormenta (más chico = más obstáculos).
@export_range(5.0, 80.0, 0.5, "suffix:m") var spacing_storm: float = 9.0
## Distancia mínima del centro del camino a un obstáculo suelto.
@export_range(0.5, 12.0, 0.1, "suffix:m") var lateral_min: float = 2.5
## Distancia máxima del centro del camino a un obstáculo suelto.
@export_range(1.0, 20.0, 0.1, "suffix:m") var lateral_max: float = 8.0
## Qué parte del recorrido (0 a 1) tiene portones: dos rocas con un hueco para pasar.
@export var gate_at: PackedFloat32Array = PackedFloat32Array([0.36, 0.64])
## Mitad de la separación entre las dos rocas de un portón.
@export_range(1.5, 8.0, 0.1, "suffix:m") var gate_half_gap: float = 3.3
## Qué parte del recorrido tiene un campo de troncos cruzados (slalom).
@export var log_field_at: PackedFloat32Array = PackedFloat32Array([0.5])
## Qué parte del recorrido tiene un banco de niebla que tapa la vista.
@export var fog_bank_at: PackedFloat32Array = PackedFloat32Array([0.28, 0.57, 0.74])
## Largo de cada banco de niebla.
@export_range(10.0, 120.0, 1.0, "suffix:m") var fog_bank_length: float = 46.0

@export_group("Orilla")
## Distancia entre el final del camino y la cabaña.
@export_range(0.0, 150.0, 1.0, "suffix:m") var cabin_beyond_end: float = 55.0
