class_name IceSettings
extends Resource
## Cómo se comportan las placas de hielo del lago (Memoria 2). Lo usa IcePlate.

@export_group("Inclinación")
## Cuánto se inclina la placa por cada metro que el jugador se aleja del centro.
@export_range(0.0, 20.0, 0.1, "suffix:°/m") var tilt_per_meter: float = 5.5
## Inclinación máxima.
@export_range(0.0, 40.0, 0.5, "suffix:°") var max_tilt: float = 13.0
## Qué tan rápido sigue al jugador (más = más nerviosa).
@export_range(0.1, 20.0, 0.1, "suffix:1/s") var tilt_speed: float = 2.4
## Cuánto se hunde con el jugador encima.
@export_range(0.0, 0.5, 0.01, "suffix:m") var sink_depth: float = 0.1
## Vaivén del agua (alto del balanceo de cada placa).
@export_range(0.0, 0.2, 0.005, "suffix:m") var bob_height: float = 0.035
## Velocidad del vaivén.
@export_range(0.1, 5.0, 0.05, "suffix:1/s") var bob_speed: float = 0.9

@export_group("Resbalar")
## Empuje cuesta abajo por cada grado de inclinación (como el resbalón de la cubierta de M4).
@export_range(0.0, 2.0, 0.01, "suffix:m/s²/°") var slip_strength: float = 0.32

@export_group("Grietas")
## Segundos parado sobre una placa hasta que se agrieta (aviso).
@export_range(0.2, 10.0, 0.1, "suffix:s") var crack_warn_time: float = 1.8
## Segundos parado hasta que se rompe (desde que se sube).
@export_range(0.5, 15.0, 0.1, "suffix:s") var break_time: float = 3.6
## Cuánto se "cura" por segundo cuando el jugador se baja (segundos de grieta que se recuperan).
@export_range(0.0, 5.0, 0.05) var recover_speed: float = 0.5
## Color del hielo sano.
@export var ice_color: Color = Color(0.62, 0.74, 0.82, 0.92)
## Color al agrietarse.
@export var cracked_color: Color = Color(0.86, 0.92, 0.96, 0.92)
