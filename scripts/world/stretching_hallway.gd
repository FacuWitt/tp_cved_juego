class_name StretchingHallway
extends Node3D
## Pasillo que se estira (M3). El pasillo sale desde el origen del nodo hacia adelante (-Z local).
## Cambia el largo del piso, el techo y las paredes, y corre el fondo (`far_end`) hasta el final.
## No sabe por qué se estira: la memoria le pide un largo con set_length().

@export var floor_box: CSGBox3D
@export var ceiling_box: CSGBox3D
@export var wall_left: CSGBox3D
@export var wall_right: CSGBox3D
## Lo que está al final del pasillo (el rellano con las puertas). Su origen queda en el final.
@export var far_end: Node3D
## Mitad del ancho libre del pasillo (de pared a pared), para saber si alguien está adentro.
@export_range(0.2, 5.0, 0.05, "suffix:m") var half_width: float = 0.8

## Largo actual del pasillo.
var length: float = 0.0


func _ready() -> void:
	assert(floor_box != null and ceiling_box != null and wall_left != null and wall_right != null and far_end != null, "StretchingHallway: faltan referencias en el Inspector")
	length = -far_end.position.z


## Cambia el largo del pasillo (el fondo se corre en el momento).
func set_length(value: float) -> void:
	length = maxf(value, 0.5)
	for box: CSGBox3D in [floor_box, ceiling_box, wall_left, wall_right]:
		box.size.z = length
		box.position.z = -length * 0.5
	far_end.position.z = -length


## Si un punto (global) está dentro del pasillo, entre la entrada y el fondo.
func contains(point: Vector3) -> bool:
	var local: Vector3 = to_local(point)
	return local.z <= 0.0 and local.z >= -length and absf(local.x) <= half_width
