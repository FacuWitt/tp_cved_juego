class_name FlowSettings
extends Resource
## Tiempos de las transiciones entre memorias.
## Se editan desde el Inspector en res://config/flow_settings.tres, sin tocar código.

@export_group("Cambio de memoria")
## Duración del fundido a negro al salir de una memoria.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_out_duration: float = 0.8
## Tiempo que la pantalla queda en negro antes de mostrar la memoria siguiente.
@export_range(0.0, 5.0, 0.05, "suffix:s") var black_hold_duration: float = 0.3
## Duración del fundido desde negro al entrar a la memoria nueva.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_in_duration: float = 0.8

@export_group("Reinicio")
## Duración de cada fundido (ida y vuelta) al reiniciar la memoria actual.
@export_range(0.0, 5.0, 0.05, "suffix:s") var restart_fade_duration: float = 0.4
