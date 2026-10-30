class_name DogNpc
extends Node3D
## El perro de la Memoria 2. Etapa 0: una cápsula marrón.
## Sale corriendo por una lista de puntos (saltando un poco) y, al llegar, se queda ladrando
## para que el jugador lo siga. No tiene IA: lo maneja la memoria.

## Llegó al último punto.
signal arrived
## Ladró (para el sonido o la línea en pantalla).
signal barked

## Velocidad al correr.
@export_range(0.5, 15.0, 0.1, "suffix:m/s") var run_speed: float = 5.5
## Alto de cada saltito al correr.
@export_range(0.0, 0.6, 0.01, "suffix:m") var hop_height: float = 0.12
## Cada cuánto ladra mientras espera (sigue el ritmo del bip).
@export_range(0.2, 5.0, 0.05, "suffix:s") var bark_interval: float = 0.9
## Cartel que aparece al ladrar (etapa 0, hasta tener sonido).
@export var bark_label: Label3D

var is_running: bool = false
var is_waiting: bool = false

var _path: Array[Vector3] = []
var _bark_time: float = 0.0
var _run_time: float = 0.0
var _ground_y: float = 0.0


func _ready() -> void:
	_ground_y = global_position.y
	if bark_label != null:
		bark_label.visible = false


## Corre por estos puntos (en coordenadas del mundo) y después espera ladrando.
func run_along(points: Array[Vector3]) -> void:
	_path = points.duplicate()
	is_running = true
	is_waiting = false


## Deja de ladrar y de moverse (la cinemática del final se encarga).
func stop() -> void:
	is_running = false
	is_waiting = false
	if bark_label != null:
		bark_label.visible = false


func _process(delta: float) -> void:
	if is_running:
		_run(delta)
	elif is_waiting:
		_bark_time += delta
		if bark_label != null:
			bark_label.visible = fmod(_bark_time, bark_interval) < bark_interval * 0.45
		if _bark_time >= bark_interval:
			_bark_time = 0.0
			barked.emit()


func _run(delta: float) -> void:
	if _path.is_empty():
		is_running = false
		is_waiting = true
		arrived.emit()
		return
	_run_time += delta
	var target: Vector3 = _path[0]
	var flat: Vector3 = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	var step: float = run_speed * delta
	if flat.length() <= step:
		global_position = Vector3(target.x, _ground_y, target.z)
		_path.remove_at(0)
	else:
		global_position += flat.normalized() * step
		look_at(global_position + flat, Vector3.UP)
	# Saltitos al correr, sobre la altura del punto al que va.
	_ground_y = lerpf(_ground_y, target.y, minf(1.0, 6.0 * delta))
	global_position.y = _ground_y + absf(sin(_run_time * 12.0)) * hop_height
