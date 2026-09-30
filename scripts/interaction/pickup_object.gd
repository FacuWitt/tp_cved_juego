class_name PickupObject
extends RigidBody3D
## Objeto que el jugador puede agarrar y arrastrar con físicas (drag and drop).
## Prototipo de las piezas que va a usar el puzzle de rotación de objetos.

signal picked_up(by: Node3D)
signal dropped

@export var settings: PickupSettings

var is_held: bool = false
var _holder: Node3D = null


func _ready() -> void:
	assert(settings != null, "PickupObject: falta asignar un PickupSettings en el Inspector")


## Lo toma un holder (normalmente la cámara del jugador) y empieza a seguirlo.
func pickup(holder: Node3D) -> void:
	_holder = holder
	is_held = true
	freeze = false
	gravity_scale = 0.0
	linear_damp = settings.hold_linear_damp
	angular_damp = settings.hold_angular_damp
	picked_up.emit(holder)


## Lo suelta: vuelve a caer con física normal (o queda fijo si un PlacementSlot lo agarra).
func release() -> void:
	is_held = false
	_holder = null
	gravity_scale = 1.0
	linear_damp = 0.0
	angular_damp = 0.0
	dropped.emit()


func _physics_process(_delta: float) -> void:
	if not is_held or _holder == null:
		return

	var forward: Vector3 = -_holder.global_transform.basis.z
	var hold_point: Vector3 = _holder.global_position + forward * settings.hold_distance
	var offset: Vector3 = hold_point - global_position

	if offset.length() > settings.auto_release_distance:
		release()
		return

	linear_velocity = (offset * settings.hold_follow_speed).limit_length(settings.max_hold_speed)
