class_name PlacementSlot
extends Area3D
## Zona donde un PickupObject se apoya y queda fijo, emulando un casillero del puzzle.

signal object_placed(object: PickupObject)
signal object_removed(object: PickupObject)

## Punto exacto donde queda el objeto al encastrar (normalmente arriba del socket).
@export var snap_point: Marker3D
## Si está en true, el objeto queda bloqueado para siempre apenas encastra acá
## (p. ej. una soga que se ata a un lugar del barco: no se puede volver a sacar).
## Si está en false (default), se puede volver a agarrar, como en un puzzle sin resolver.
@export var locks_object_on_place: bool = false

var _placed_object: PickupObject = null


## Grupo al que pertenecen todos los PlacementSlot (para que la UI los consulte).
const GROUP_NAME := &"placement_slots"


## true si el objeto está dentro de la zona y el casillero está libre, o sea que
## soltarlo ahora lo encastraría.
func would_accept(object: PickupObject) -> bool:
	return _placed_object == null and get_overlapping_bodies().has(object)


func _ready() -> void:
	add_to_group(GROUP_NAME)
	# Capa 2 = "zona de detección": el InteractionRay del jugador solo mira la capa 1
	# (cuerpos físicos), así que nunca choca contra esta Area3D en vez de contra el
	# objeto encastrado adentro. Sigue detectando cuerpos en la capa 1 con normalidad.
	collision_layer = 2
	collision_mask = 1


func _physics_process(_delta: float) -> void:
	if _placed_object != null:
		return
	for body in get_overlapping_bodies():
		if body is PickupObject and not (body as PickupObject).is_held:
			_place(body as PickupObject)
			return


func _place(object: PickupObject) -> void:
	object.animate_settle(snap_point.global_transform)
	_placed_object = object
	if locks_object_on_place:
		object.lock()
	else:
		object.picked_up.connect(_on_placed_object_taken, CONNECT_ONE_SHOT)
	object_placed.emit(object)


func _on_placed_object_taken(_by: Node3D) -> void:
	var object: PickupObject = _placed_object
	_placed_object = null
	object_removed.emit(object)
