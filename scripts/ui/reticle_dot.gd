class_name ReticleDot
extends Control
## Punto circular de la mira. radius y color son animables con Tween (ver InteractionPrompt).

@export var radius: float = 2.0:
	set(value):
		radius = value
		queue_redraw()

@export var dot_color: Color = Color(1.0, 1.0, 1.0, 0.75):
	set(value):
		dot_color = value
		queue_redraw()


func _draw() -> void:
	draw_circle(size * 0.5, radius, dot_color)
