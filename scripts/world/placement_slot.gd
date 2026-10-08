class_name PlacementSlot
extends Area3D
## Zona donde un PickupObject se apoya y queda fijo, emulando un casillero del puzzle.
##
## Hay dos formas de encastrar un objeto:
## - Apuntando: el jugador mira el casillero con algo agarrado y aprieta interact (place()).
##   Es la forma principal: decide la mira, no dónde cae el objeto.
## - Soltándolo encima: si el objeto queda dentro de la zona, encastra solo. Si toca varios
##   casilleros a la vez, se lo queda el más cercano.

signal object_placed(object: PickupObject)
signal object_removed(object: PickupObject)

## Grupo al que pertenecen todos los PlacementSlot (para que la UI y otros casilleros los consulten).
const GROUP_NAME := &"placement_slots"

## Punto exacto donde queda el objeto al encastrar (normalmente arriba del socket).
@export var snap_point: Marker3D
## Si está en true, el objeto queda bloqueado para siempre apenas encastra acá
## (p. ej. una soga que se ata a un lugar del barco: no se puede volver a sacar).
## Si está en false (default), se puede volver a agarrar, como en un puzzle sin resolver.
@export var locks_object_on_place: bool = false
## Nodo opcional que se muestra mientras el jugador apunta a este casillero con algo en la mano
## (p. ej. un recuadro iluminado). Arranca oculto.
@export var aim_indicator: Node3D

var _placed_object: PickupObject = null


func _ready() -> void:
	add_to_group(GROUP_NAME)
	# Capa 2 = "zona de detección": el InteractionRay del jugador solo mira la capa 1
	# (cuerpos físicos), así que nunca choca contra esta Area3D en vez de contra el
	# objeto encastrado adentro. Sigue detectando cuerpos en la capa 1 con normalidad.
	collision_layer = 2
	collision_mask = 1
	if aim_indicator != null:
		aim_indicator.visible = false


## true si no tiene ningún objeto encastrado.
func is_free() -> bool:
	return _placed_object == null


## El objeto encastrado ahora mismo, o null.
func get_placed_object() -> PickupObject:
	return _placed_object


## Encastra el objeto acá, esté donde esté (lo anima hasta snap_point).
## Devuelve false si el casillero ya está ocupado.
func place(object: PickupObject) -> bool:
	if _placed_object != null or object == null:
		return false
	_place(object)
	return true


## true si soltar el objeto ahora lo encastraría acá por estar encima del casillero.
func would_accept(object: PickupObject) -> bool:
	return _closest_free_slot_overlapping(object) == self


## Muestra u oculta el indicador de "estás apuntando acá".
func set_aimed(aimed: bool) -> void:
	if aim_indicator != null:
		aim_indicator.visible = aimed and _placed_object == null


func _physics_process(_delta: float) -> void:
	if _placed_object != null:
		return
	for body in get_overlapping_bodies():
		var object: PickupObject = body as PickupObject
		if object == null or object.is_held or _is_in_any_slot(object):
			continue
		# Si el objeto toca varios casilleros libres, se lo queda el más cercano.
		if _closest_free_slot_overlapping(object) != self:
			continue
		_place(object)
		return


func _place(object: PickupObject) -> void:
	object.animate_settle(snap_point.global_transform)
	_placed_object = object
	set_aimed(false)
	if locks_object_on_place:
		object.lock()
	else:
		object.picked_up.connect(_on_placed_object_taken, CONNECT_ONE_SHOT)
	object_placed.emit(object)


func _on_placed_object_taken(_by: Node3D) -> void:
	var object: PickupObject = _placed_object
	_placed_object = null
	object_removed.emit(object)


## true si el objeto ya está encastrado en algún casillero (este u otro), para que un
## casillero vecino no se lo "robe" porque lo roza.
func _is_in_any_slot(object: PickupObject) -> bool:
	for node in get_tree().get_nodes_in_group(GROUP_NAME):
		if (node as PlacementSlot).get_placed_object() == object:
			return true
	return false


## De todos los casilleros libres que el objeto está tocando, el más cercano a él (o null).
func _closest_free_slot_overlapping(object: PickupObject) -> PlacementSlot:
	var best: PlacementSlot = null
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group(GROUP_NAME):
		var slot: PlacementSlot = node as PlacementSlot
		if not slot.is_free() or not slot.get_overlapping_bodies().has(object):
			continue
		var distance: float = slot.snap_point.global_position.distance_to(object.global_position)
		if distance < best_distance:
			best_distance = distance
			best = slot
	return best
