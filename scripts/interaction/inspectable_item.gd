class_name InspectableItem
extends Interactable
## Objeto que se inspecciona y se lee (estilo Silent Hill): con `interact` lo abre la InspectView.
## Lo que se ve en la mano es una copia del nodo `visual`; si ese nodo tiene un hijo
## "CoverHinge", la tapa se abre antes de mostrar la página.

## Se terminó de leer y se cerró la inspección.
signal inspected

## La vista que hace la inspección. Vacío = la busca en la escena (grupo "inspect_view").
@export var view: InspectView
## Lo que se ve del objeto (se copia para mostrarlo en la mano).
@export var visual: Node3D
## La imagen que se lee (por ejemplo, el libro abierto con el texto). Vacío = solo se mira.
@export var page: Texture2D


func _ready() -> void:
	assert(visual != null, "InspectableItem: falta el nodo visual en el Inspector")


func interact(by: Node3D) -> void:
	if view == null:
		view = get_tree().get_first_node_in_group(InspectView.GROUP_NAME) as InspectView
	assert(view != null, "InspectableItem: no hay una InspectView en la escena")
	if view.is_busy():
		return
	super(by)
	view.open(self, by)
