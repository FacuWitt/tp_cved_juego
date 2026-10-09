class_name AxePickup
extends PickupObject
## El hacha apoyada en la pared de la cabina. Se agarra con (E) como cualquier objeto del puzzle,
## pero al tomarla pasa a la mano del jugador (AxeView) y ya no se puede soltar:
## solo se va cuando la ola se la arranca.

## Se emite cuando el jugador la toma. Lleva la transformación global desde donde la tomó.
signal equipped(from_global: Transform3D)


func _ready() -> void:
	super()
	freeze = true
	can_release = true


## La toma el jugador: desaparece de la pared y la mano pasa a mostrar el hacha.
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


## Ya no se mueve por física mientras está "agarrada": el que la muestra es AxeView.
func _physics_process(_delta: float) -> void:
	pass
