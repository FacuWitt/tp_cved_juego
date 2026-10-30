class_name WakeUpSettings
extends Resource
## Cómo se despierta el protagonista al empezar una memoria (regla del juego: lo despierta la tormenta).
## Lo usa WakeUpIntro.

## Si está apagado, la memoria empieza directo con el jugador parado y con control (útil para probar).
@export var enabled: bool = true
## Tiempo con los ojos cerrados antes del trueno.
@export_range(0.0, 5.0, 0.05, "suffix:s") var closed_time: float = 1.4
## Cuánto se abren los ojos de golpe con el trueno (0 = nada, 1 = del todo).
@export_range(0.0, 1.0, 0.01) var startle_open: float = 0.35
## Cuánto dura ese primer vistazo antes de volver a cerrarlos.
@export_range(0.05, 1.0, 0.01, "suffix:s") var startle_time: float = 0.18
## Pausa con los ojos cerrados después del susto.
@export_range(0.0, 3.0, 0.05, "suffix:s") var after_startle_time: float = 0.7
## Cuánto tardan en abrirse del todo.
@export_range(0.1, 5.0, 0.05, "suffix:s") var open_time: float = 1.6
## Cuánto tarda en levantarse (de acostado a parado).
@export_range(0.1, 5.0, 0.05, "suffix:s") var getup_time: float = 1.5
## Hacia dónde mira acostado (grados; positivo = arriba, al techo).
@export_range(-90.0, 90.0, 1.0, "suffix:°") var lying_pitch: float = 62.0
## Cuánto más abajo está la cabeza acostado que parado.
@export_range(0.0, 1.6, 0.01, "suffix:m") var lying_drop: float = 0.95
## Giro de la cabeza acostado (grados, hacia un costado).
@export_range(-60.0, 60.0, 1.0, "suffix:°") var lying_roll: float = 18.0
## Fuerza del rayo/trueno que lo despierta.
@export_range(0.0, 1.0, 0.01) var thunder_strength: float = 1.0
