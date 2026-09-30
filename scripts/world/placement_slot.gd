class_name PlacementSlot
extends Area3D
## Zona donde un PickupObject se apoya y queda fijo, emulando un casillero del puzzle.

signal object_placed(object: PickupObject)
signal object_removed(object: PickupObject)

## Punto exacto donde queda el objeto al encastrar (normalmente arriba del socket).
@export var snap_point: Marker3D

var _placed_object: PickupObject = null


func _physics_process(_delta: float) -> void:
	if _placed_object != null:
		return
	for body in get_overlapping_bodies():
		if body is PickupObject and not (body as PickupObject).is_held:
			_place(body as PickupObject)
			return


func _place(object: PickupObject) -> void:
	object.global_position = snap_point.global_position
	object.freeze = true
	object.linear_velocity = Vector3.ZERO
	object.angular_velocity = Vector3.ZERO
	_placed_object = object
	object.picked_up.connect(_on_placed_object_taken, CONNECT_ONE_SHOT)
	object_placed.emit(object)


func _on_placed_object_taken(_by: Node3D) -> void:
	var object: PickupObject = _placed_object
	_placed_object = null
	object_removed.emit(object)
