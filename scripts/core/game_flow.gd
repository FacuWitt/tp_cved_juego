extends Node
## Encadena las memorias del juego.
## Cada Memory se registra acá al cargarse; cuando emite `memory_completed`, GameFlow
## hace el fundido a negro y carga la escena siguiente según res://config/memory_sequence.tres.
## Es un autoload: se usa como GameFlow desde cualquier script.
## No lleva class_name porque el nombre global ya lo da el autoload.

## Empezó una memoria (ya está cargada y visible detrás del fundido).
signal memory_started(index: int)
## Se terminó una memoria y está por empezar la transición a la siguiente.
signal memory_finished(index: int)
## Se llegó a la última escena de la secuencia (el Despertar).
signal game_finished
## Arrancó o terminó una transición (cambio de memoria o reinicio).
signal transition_started
signal transition_finished

const SEQUENCE_PATH: String = "res://config/memory_sequence.tres"
const SETTINGS_PATH: String = "res://config/flow_settings.tres"

## Posición de la memoria actual en la secuencia (-1 si la escena actual no es una memoria de la lista).
var current_index: int = -1
## True mientras dura un fundido o un cambio de escena.
var is_transitioning: bool = false

var _sequence: MemorySequence
var _settings: FlowSettings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sequence = load(SEQUENCE_PATH) as MemorySequence
	_settings = load(SETTINGS_PATH) as FlowSettings
	assert(_sequence != null, "GameFlow: no se encontró %s" % SEQUENCE_PATH)
	assert(_settings != null, "GameFlow: no se encontró %s" % SETTINGS_PATH)


func _unhandled_input(event: InputEvent) -> void:
	# Atajos de debug: solo existen en builds de debug (al correr desde el editor).
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_next_memory"):
		get_viewport().set_input_as_handled()
		go_to_next()
	elif event.is_action_pressed("debug_restart_memory"):
		get_viewport().set_input_as_handled()
		restart_current()


## Lo llama cada Memory en su _ready. Así GameFlow sabe en qué memoria está,
## aunque la escena se haya abierto directo desde el editor (F6).
func register_memory(memory: Memory) -> void:
	current_index = _sequence.index_of(memory.scene_file_path)
	if current_index == -1:
		push_warning("GameFlow: la escena %s no está en %s; no se va a poder pasar a la siguiente." % [memory.scene_file_path, SEQUENCE_PATH])
	if not memory.memory_completed.is_connected(_on_memory_completed):
		memory.memory_completed.connect(_on_memory_completed)
	memory_started.emit(current_index)
	if current_index != -1 and _sequence.is_last(current_index):
		game_finished.emit()


## Pasa a la memoria siguiente de la secuencia.
func go_to_next() -> void:
	if current_index == -1:
		push_warning("GameFlow: la escena actual no está en la secuencia; no hay memoria siguiente.")
		return
	if _sequence.is_last(current_index):
		return
	go_to(current_index + 1)


## Carga la memoria que está en esa posición de la secuencia, con fundido.
func go_to(index: int) -> void:
	if is_transitioning:
		return
	if index < 0 or index >= _sequence.size():
		push_error("GameFlow: no existe la memoria %d en la secuencia." % index)
		return
	_begin_transition()
	if current_index != -1:
		memory_finished.emit(current_index)
	await ScreenFade.fade_out(_settings.fade_out_duration)
	if _settings.black_hold_duration > 0.0:
		await get_tree().create_timer(_settings.black_hold_duration).timeout
	var error: Error = get_tree().change_scene_to_file(_sequence.get_path_at(index))
	if error != OK:
		push_error("GameFlow: no se pudo cargar %s (error %d)." % [_sequence.get_path_at(index), error])
	await _wait_for_scene_change()
	await ScreenFade.fade_in(_settings.fade_in_duration)
	_end_transition()


## Reinicia la memoria actual desde cero (por ejemplo, cuando el jugador falla).
func restart_current() -> void:
	if is_transitioning:
		return
	_begin_transition()
	await ScreenFade.fade_out(_settings.restart_fade_duration)
	get_tree().reload_current_scene()
	await _wait_for_scene_change()
	await ScreenFade.fade_in(_settings.restart_fade_duration)
	_end_transition()


func _on_memory_completed() -> void:
	go_to_next()


func _begin_transition() -> void:
	is_transitioning = true
	transition_started.emit()


func _end_transition() -> void:
	is_transitioning = false
	transition_finished.emit()


## El cambio de escena se aplica al final del frame: esperamos al siguiente,
## cuando la escena nueva ya está en el árbol y corrió su _ready.
func _wait_for_scene_change() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
