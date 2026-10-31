class_name HallwayDeadEnd
extends Node
## El pasillo cambia a tus espaldas (M3): si el jugador pasa un rato sin mirar hacia atrás, el camino
## que ya recorrió aparece cerrado por una pared, unos metros detrás de él. Cuando la pared queda
## fuera de la vista un rato, desaparece (y más adelante puede aparecer en otro lugar).
## Nunca se cierra delante ni encima del jugador: solo detrás, y solo lejos de las esquinas.
## No sabe en qué memoria está: la memoria le dice cuánto soñar (`level`) y lo limpia con clear()
## cuando lleva al jugador a otro lado.

@export var settings: DreamSettings
@export var player: Player
@export var hallway: BendingHallway

## Cuánto sueño hay (0 = nada cambia, 1 = lo máximo). Lo pone la memoria.
var level: float = 0.0

var _camera: Camera3D
var _wall: CSGBox3D
## Tiempo sin mirar hacia atrás (o, con la pared puesta, sin mirar la pared).
var _unseen: float = 0.0
var _check: float = 0.0


func _ready() -> void:
	assert(settings != null and player != null and hallway != null, "HallwayDeadEnd: faltan el DreamSettings, el Player o el pasillo")
	_camera = player.get_node("Head/Camera3D") as Camera3D
	_wall = CSGBox3D.new()
	_wall.name = "DeadEnd"
	# Arranca sin colisión: hasta que no se pone, no puede tapar nada (sin esto, la caja por
	# defecto quedaba invisible en la entrada del pasillo y no dejaba pasar).
	_wall.use_collision = false
	_wall.visible = false
	hallway.add_child.call_deferred(_wall)


## Saca la pared (el jugador fue llevado a otro lado, o la casa se estabilizó).
func clear() -> void:
	_hide_wall()
	_unseen = 0.0


func _process(delta: float) -> void:
	if _wall == null or not _wall.is_inside_tree():
		return
	var intensity: float = clampf(level * settings.level_gain, 0.0, 1.0)
	if _wall.visible:
		# La pared desaparece cuando hace rato que no se la mira.
		_unseen = 0.0 if _is_seen(_wall.global_transform) else _unseen + delta
		if _unseen >= settings.dead_end_vanish_time:
			clear()
		return
	if not settings.dead_end_enabled or intensity <= 0.0:
		_unseen = 0.0
		return
	var here: float = hallway.distance_along(player.global_position)
	if here < 0.0:
		_unseen = 0.0
		return
	# ¿Está mirando hacia atrás? (al punto del pasillo más cercano donde podría aparecer la pared)
	var behind: Variant = hallway.section_at(here - settings.dead_end_min_distance)
	if behind != null and _is_seen(hallway.global_transform * (behind as Transform3D)):
		_unseen = 0.0
		return
	_unseen += delta
	_check += delta
	if _unseen < settings.dead_end_unseen_time or _check < settings.dead_end_check_interval:
		return
	_check = 0.0
	if randf() < settings.dead_end_chance * intensity:
		_try_place(here)


func _try_place(here: float) -> void:
	var back: float = randf_range(settings.dead_end_min_distance, maxf(settings.dead_end_min_distance, settings.dead_end_max_distance))
	var spot: Variant = hallway.section_at(here - back)
	if spot == null:
		return
	var frame: Transform3D = hallway.global_transform * (spot as Transform3D)
	if _is_seen(frame):
		return
	# Un poco más grande que el hueco del pasillo, así se mete en las paredes y no se ve el borde.
	_wall.size = Vector3(hallway.width + 0.3, hallway.height + 0.3, 0.2)
	_wall.material = hallway.hall_material
	_wall.global_transform = frame.translated_local(Vector3(0.0, hallway.height * 0.5, 0.0))
	_wall.visible = true
	_wall.use_collision = true
	_unseen = 0.0


func _hide_wall() -> void:
	if _wall == null:
		return
	_wall.visible = false
	_wall.use_collision = false


## Si algo de ese corte del pasillo (piso, techo, costados) entra en la cámara.
func _is_seen(frame: Transform3D) -> bool:
	var w: float = hallway.width * 0.5
	var h: float = hallway.height
	for p: Vector3 in [Vector3(0.0, h * 0.5, 0.0), Vector3(-w, 0.1, 0.0), Vector3(w, 0.1, 0.0), Vector3(-w, h - 0.1, 0.0), Vector3(w, h - 0.1, 0.0)]:
		if _camera.is_position_in_frustum(frame * p):
			return true
	return false
