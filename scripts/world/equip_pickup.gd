class_name EquipPickup
extends PickupObject
## Objeto que se agarra con (E) y pasa a "llevarse puesto" (una mochila, una linterna):
## desaparece del mundo y avisa con `equipped`; quien escucha muestra el objeto en la mano (HeldItemView).
## No se puede soltar. Es la versión general del hacha de M4 (AxePickup).

## Lo tomó el jugador. Lleva la transformación global desde donde lo tomó.
signal equipped(from_global: Transform3D)


func _ready() -> void:
	super()
	freeze = true


func pickup(holder: Node3D, holder_body: PhysicsBody3D = null) -> void:
	if is_locked or is_held:
		return
	_holder = holder
	_holder_body = holder_body
	is_held = true
	can_release = false
	var from: Transform3D = global_transform
	collision_layer = 0
	collision_mask = 0
	visible = false
	picked_up.emit(holder)
	equipped.emit(from)


func _physics_process(_delta: float) -> void:
	pass
