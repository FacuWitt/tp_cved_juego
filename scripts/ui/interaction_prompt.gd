class_name InteractionPrompt
extends VBoxContainer
## Mira contextual: avisa con (E) qué se puede hacer según a qué apunta el jugador
## o si ya tiene algo agarrado. Se fija en el Player que se le asigne en el Inspector.

@export var player: Player
@export var settings: InteractionPromptSettings
@export var pickup_label_text: String = "(E) Agarrar"
@export var place_label_text: String = "(E) Colocar"

@onready var _dot: ReticleDot = $Dot
@onready var _label: Label = $Label

var _highlighted: bool = false


func _ready() -> void:
	assert(player != null, "InteractionPrompt: falta asignar el Player en el Inspector")
	assert(settings != null, "InteractionPrompt: falta asignar un InteractionPromptSettings")
	_label.text = ""
	_dot.radius = settings.normal_radius
	_dot.dot_color = settings.normal_color


func _process(_delta: float) -> void:
	var held: PickupObject = player.get_held_object()
	var target: PickupObject = player.get_interactable_under_crosshair()

	# Con algo en mano, solo se avisa si soltarlo ahora lo encastraría en algún casillero.
	var can_place: bool = held != null and _is_over_free_slot(held)

	_set_highlighted(can_place or (held == null and target != null))

	if can_place:
		_label.text = place_label_text
	elif held == null and target != null:
		_label.text = pickup_label_text
	else:
		_label.text = ""


func _is_over_free_slot(object: PickupObject) -> bool:
	for node in get_tree().get_nodes_in_group(PlacementSlot.GROUP_NAME):
		if (node as PlacementSlot).would_accept(object):
			return true
	return false


func _set_highlighted(highlighted: bool) -> void:
	if highlighted == _highlighted:
		return
	_highlighted = highlighted

	var target_radius: float = settings.hover_radius if highlighted else settings.normal_radius
	var target_color: Color = settings.hover_color if highlighted else settings.normal_color

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dot, "radius", target_radius, settings.transition_time)
	tween.tween_property(_dot, "dot_color", target_color, settings.transition_time)
