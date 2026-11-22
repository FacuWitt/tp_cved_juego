class_name WallClockHands
extends Node3D
## Reloj de pared en marcha (el del hospital): mueve las agujas con la hora real del sistema.
## Las agujas giran sobre su eje Z (el reloj mira hacia su +Z).

@export var hour_hand: Node3D
@export var minute_hand: Node3D
@export var second_hand: Node3D
## Si está prendido, el segundero salta de a un segundo (tic tac); si no, gira continuo.
@export var ticking_seconds: bool = true


func _process(_delta: float) -> void:
	var t: Dictionary = Time.get_time_dict_from_system()
	var sec: float = float(t["second"])
	if not ticking_seconds:
		sec += fmod(Time.get_ticks_msec() / 1000.0, 1.0)
	var minute: float = float(t["minute"]) + sec / 60.0
	var hour: float = fmod(float(t["hour"]), 12.0) + minute / 60.0
	if second_hand != null:
		second_hand.rotation.z = -TAU * sec / 60.0
	if minute_hand != null:
		minute_hand.rotation.z = -TAU * minute / 60.0
	if hour_hand != null:
		hour_hand.rotation.z = -TAU * hour / 12.0
