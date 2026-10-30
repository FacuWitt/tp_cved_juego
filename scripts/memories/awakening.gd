extends Memory
## Escena final (el Despertar). Por ahora solo muestra "FIN": el jugador no se mueve
## y se libera el mouse. Acá va a ir la escena real del hospital.


func _ready() -> void:
	super()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
