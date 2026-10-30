class_name ItemGate
extends Area3D
## Paso condicionado a haber agarrado un objeto.
## Una barrera física (StaticBody3D) cierra el paso hasta que el jugador agarre el objeto
## requerido. Si el jugador se acerca al paso con la barrera activa y el aviso armado,
## emite `blocked`; quien escuche decide qué mostrar (p. ej. un pensamiento del protagonista).
## Una vez agarrado el objeto, el paso queda libre para siempre aunque después lo suelte.
## No conoce la memoria ni el texto: solo el objeto, la barrera y la zona de aviso.

## El jugador intentó pasar sin haber agarrado el objeto.
signal blocked
## El jugador agarró el objeto requerido: la barrera ya no bloquea.
signal item_taken

## Objeto que hay que agarrar antes de poder pasar.
@export var required_item: PickupObject
## Cuerpo estático que bloquea el paso hasta que se agarra el objeto.
@export var barrier: StaticBody3D
## Si está en false, acercarse al paso no avisa (p. ej. con la puerta todavía cerrada).
## La barrera bloquea igual; solo se silencia el aviso.
@export var armed: bool = false

var _taken: bool = false


func _ready() -> void:
	assert(required_item != null and barrier != null, "ItemGate: faltan required_item o barrier en el Inspector")
	required_item.picked_up.connect(_on_item_picked_up)
	body_entered.connect(_on_body_entered)


## Habilita el aviso. Se llama cuando el paso pasa a ser transitable (la puerta ya abrió).
func arm() -> void:
	armed = true


func is_item_taken() -> bool:
	return _taken


func _on_item_picked_up(_by: Node3D) -> void:
	if _taken:
		return
	_taken = true
	barrier.set_deferred("collision_layer", 0)
	item_taken.emit()


func _on_body_entered(body: Node3D) -> void:
	if not armed or _taken or not (body is Player):
		return
	blocked.emit()
