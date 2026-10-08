class_name OceanFollow
extends MeshInstance3D
## Hace que el plano del océano acompañe al objetivo en X y Z, para que parezca infinito.
## El oleaje se calcula con la posición del mundo en el shader, así que no se "arrastra".

@export var target: Node3D
## Se mueve de a saltos de este tamaño, para que la grilla de vértices no vibre.
@export_range(0.5, 10.0, 0.1, "suffix:m") var snap: float = 3.0


func _process(_delta: float) -> void:
	if target == null:
		return
	var p: Vector3 = target.global_position
	global_position = Vector3(snappedf(p.x, snap), global_position.y, snappedf(p.z, snap))
