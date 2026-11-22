class_name BlinkLight
extends OmniLight3D
## Luz que parpadea despacio (la boya de una red de pesca). Apagada de día no se nota.

@export_range(0.2, 6.0, 0.05, "suffix:s") var period: float = 1.8
@export_range(0.0, 1.0, 0.01) var on_fraction: float = 0.18

var _base_energy: float = 1.0
var _t: float = 0.0


func _ready() -> void:
	_base_energy = light_energy
	_t = randf() * period


func _process(delta: float) -> void:
	_t = fmod(_t + delta, period)
	light_energy = _base_energy if _t < period * on_fraction else _base_energy * 0.04
