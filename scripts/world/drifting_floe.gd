class_name DriftingFloe
extends AnimatableBody3D
## Un pedazo de hielo que flota: se deja llevar despacio por la corriente y gira un poco.
## Es un obstáculo (grupo "boat_hazard"): si el bote lo choca fuerte, es un golpe.
## Si la corriente lo lleva demasiado lejos, vuelve a donde empezó (así el río nunca queda vacío).

@export var river: RiverFlow
## Fracción de la corriente que lo lleva (el hielo es pesado y va más lento que el agua).
@export_range(0.0, 1.5, 0.01) var drift_factor: float = 0.45
## Cuánto puede alejarse río abajo antes de volver al principio.
@export_range(5.0, 200.0, 1.0, "suffix:m") var max_travel: float = 45.0
@export_range(-1.0, 1.0, 0.01, "suffix:rad/s") var spin: float = 0.08

var _start: Vector3
var _time: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	add_to_group("boat_hazard")
	sync_to_physics = true
	_start = global_position
	_phase = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	var flow: Vector3 = river.flow_at(global_position) if river != null else Vector3.ZERO
	# En el lago, sin corriente, derivan apenas en círculos.
	var wander: Vector3 = Vector3(sin(_time * 0.21 + _phase), 0.0, cos(_time * 0.17 + _phase)) * 0.08
	var next: Vector3 = global_position + (flow * drift_factor + wander) * delta
	next.y = _start.y + sin(_time * 1.3 + _phase) * 0.03
	if next.distance_to(_start) > max_travel:
		next = _start
	global_position = next
	rotate_y(spin * delta)
