class_name Player
extends CharacterBody3D
## Controlador en primera persona. Todos los valores de "feel" vienen de PlayerSettings.
## El origen del nodo está en los pies del personaje.

@export var settings: PlayerSettings

var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _held_object: PickupObject = null

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay


func _ready() -> void:
	assert(settings != null, "Player: falta asignar un PlayerSettings en el Inspector")
	_apply_camera_settings()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view((event as InputEventMouseMotion).relative)
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		_toggle_pickup()


func _physics_process(delta: float) -> void:
	_update_jump_timers(delta)
	_apply_gravity(delta)
	_try_jump()
	_apply_horizontal_movement(delta)
	move_and_slide()


## Lleva al jugador a un punto (p. ej. al reaparecer) y corta toda la inercia.
func teleport_to(target: Transform3D) -> void:
	global_position = target.origin
	rotation.y = target.basis.get_euler().y
	_head.rotation.x = 0.0
	velocity = Vector3.ZERO


## Agarra el objeto al que apunta el InteractionRay, o suelta el que ya tiene agarrado.
## Si al soltar está apuntando a un casillero libre, el objeto va a ese casillero.
func _toggle_pickup() -> void:
	if _held_object != null:
		if not _held_object.can_release:
			return
		var slot: PlacementSlot = get_aimed_slot()
		var object: PickupObject = _held_object
		_held_object = null
		object.release()
		if slot != null:
			slot.place(object)
		return

	if not _interaction_ray.is_colliding():
		return

	var collider: Object = _interaction_ray.get_collider()
	if collider is PickupObject:
		_held_object = collider as PickupObject
		_held_object.pickup(_camera, self)


## Se queda sin nada en la mano (algo se lo sacó, como la ola con el hacha).
func clear_held_object() -> void:
	_held_object = null


## El objeto que tiene agarrado ahora mismo, o null si no tiene nada. Para que la UI
## sepa qué mostrar sin depender de los nombres internos del Player.
func get_held_object() -> PickupObject:
	return _held_object


## Con algo agarrado: el casillero libre al que apunta la mira (dentro del alcance del
## InteractionRay), o null. Lo primero que toca el rayo manda: una pared o un objeto
## ya encastrado tapan lo que hay detrás.
func get_aimed_slot() -> PlacementSlot:
	if _held_object == null:
		return null
	var from: Vector3 = _interaction_ray.global_position
	var to: Vector3 = _interaction_ray.to_global(_interaction_ray.target_position)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, 1 | 2, [get_rid(), _held_object.get_rid()]
	)
	query.collide_with_areas = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var slot: PlacementSlot = hit.collider as PlacementSlot
	if slot == null or not slot.is_free():
		return null
	return slot


## El PickupObject al que apunta el InteractionRay ahora mismo (si se puede agarrar), o null.
func get_interactable_under_crosshair() -> PickupObject:
	if not _interaction_ray.is_colliding():
		return null
	var collider: Object = _interaction_ray.get_collider()
	if collider is PickupObject and not (collider as PickupObject).is_locked:
		return collider as PickupObject
	return null


func _apply_camera_settings() -> void:
	_camera.fov = settings.fov
	_head.position.y = settings.camera_height


func _rotate_view(mouse_delta: Vector2) -> void:
	var sensitivity: float = deg_to_rad(settings.mouse_sensitivity)
	var pitch_direction: float = 1.0 if settings.invert_y else -1.0
	var pitch_limit: float = deg_to_rad(settings.pitch_limit)
	rotate_y(-mouse_delta.x * sensitivity)
	_head.rotation.x = clampf(
		_head.rotation.x + pitch_direction * mouse_delta.y * sensitivity,
		-pitch_limit,
		pitch_limit
	)


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = settings.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = settings.jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var multiplier: float = settings.gravity_multiplier if velocity.y > 0.0 else settings.fall_gravity_multiplier
	velocity.y = maxf(velocity.y - _gravity * multiplier * delta, -settings.max_fall_speed)


func _try_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = settings.jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		# Salto variable: soltar antes corta la subida.
		velocity.y *= settings.jump_cut_multiplier


func _apply_horizontal_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	var target_speed: float = settings.sprint_speed if Input.is_action_pressed("sprint") else settings.walk_speed
	var target_velocity: Vector2 = Vector2(direction.x, direction.z) * target_speed

	var rate: float = settings.acceleration if input_dir != Vector2.ZERO else settings.deceleration
	if not is_on_floor():
		rate *= settings.air_control

	var horizontal: Vector2 = Vector2(velocity.x, velocity.z).move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
