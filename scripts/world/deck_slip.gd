class_name DeckSlip
extends Node
## Cubierta resbaladiza: el barco se inclina de un lado a otro y empuja al jugador hacia el lado bajo.
## No toca el script del jugador: se suma a su velocidad horizontal justo antes de que él se mueva.
## El "resbalar" también depende de PlayerSettings (poca aceleración y poco freno = suelo mojado).

@export var player: Player
## Empuje por cada grado de inclinación (m/s² por °).
@export_range(0.0, 2.0, 0.05, "suffix:m/s²/°") var strength: float = 0.9

## Lo prende y apaga quien maneja la escena.
var enabled: bool = false
## Inclinación actual del barco en grados. Positivo = el lado bajo es el -X.
var roll_degrees: float = 0.0


func _ready() -> void:
	assert(player != null, "DeckSlip: falta asignar el jugador en el Inspector")
	# Antes que el jugador, para que su propio movimiento ya parta de la velocidad empujada.
	process_physics_priority = -10


func _physics_process(delta: float) -> void:
	if not enabled or not player.is_on_floor():
		return
	player.velocity.x += -roll_degrees * strength * delta
