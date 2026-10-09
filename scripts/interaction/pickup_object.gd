class_name PickupObject
extends RigidBody3D
## Objeto que el jugador puede agarrar y arrastrar con físicas (drag and drop).
## Prototipo de las piezas que va a usar el puzzle de rotación de objetos.

signal picked_up(by: Node3D)
signal dropped
signal locked
signal unlocked
signal settled

@export var settings: PickupSettings
## Nodo visual (normalmente el MeshInstance3D) al que se le aplica el aplastamiento sutil
## al aterrizar en un PlacementSlot. Opcional: si queda sin asignar, se salta ese efecto.
@export var visual: Node3D

var is_held: bool = false
## Si está en true, pickup() no hace nada: quedó fijo para siempre (p. ej. una soga ya atada).
## Lo pone en true un PlacementSlot con locks_object_on_place, o se puede llamar lock() a mano.
var is_locked: bool = false
## Si es false, el jugador no lo puede soltar una vez que lo agarró (p. ej. el hacha).
var can_release: bool = true

var _holder: Node3D = null
var _holder_body: PhysicsBody3D = null
var _settle_tween: Tween = null


func _ready() -> void:
	assert(settings != null, "PickupObject: falta asignar un PickupSettings en el Inspector")


## Lo toma un holder (normalmente la cámara del jugador) y empieza a seguirlo.
## holder_body es el cuerpo físico de quien lo agarra (el jugador), para dejar de chocarlo
## mientras lo sostiene. No hace nada si el objeto está bloqueado (is_locked).
func pickup(holder: Node3D, holder_body: PhysicsBody3D = null) -> void:
	if is_locked:
		return
	if _settle_tween != null:
		_settle_tween.kill()
	_holder = holder
	_holder_body = holder_body
	is_held = true
	freeze = false
	gravity_scale = 0.0
	linear_damp = settings.hold_linear_damp
	angular_damp = settings.hold_angular_damp
	if _holder_body != null:
		add_collision_exception_with(_holder_body)
	picked_up.emit(holder)


## Lo suelta: vuelve a caer con física normal (o queda fijo si un PlacementSlot lo agarra).
func release() -> void:
	is_held = false
	_holder = null
	gravity_scale = 1.0
	linear_damp = 0.0
	angular_damp = 0.0
	if _holder_body != null:
		remove_collision_exception_with(_holder_body)
		_holder_body = null
	dropped.emit()


## Lo deja fijo para siempre: pickup() no va a tener efecto hasta que se llame unlock().
func lock() -> void:
	is_locked = true
	locked.emit()


func unlock() -> void:
	is_locked = false
	unlocked.emit()


## Lo anima aterrizando suavemente en destination (posición + rotación) y lo deja congelado
## ahí al terminar. La usa un PlacementSlot al encastrar el objeto.
func animate_settle(destination: Transform3D) -> void:
	is_held = false
	_holder = null
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	if _settle_tween != null:
		_settle_tween.kill()

	var start_transform: Transform3D = global_transform
	var start_rotation: Quaternion = start_transform.basis.get_rotation_quaternion()
	var end_rotation: Quaternion = destination.basis.get_rotation_quaternion()

	_settle_tween = create_tween()
	_settle_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_settle_tween.tween_method(
		func(t: float) -> void:
			global_transform = Transform3D(
				Basis(start_rotation.slerp(end_rotation, t)),
				start_transform.origin.lerp(destination.origin, t)
			),
		0.0, 1.0, settings.settle_duration
	)
	_settle_tween.finished.connect(func() -> void: settled.emit(), CONNECT_ONE_SHOT)

	if visual != null and settings.settle_squash > 0.0:
		var squash_tween: Tween = create_tween()
		var squashed: float = 1.0 - settings.settle_squash
		var down_time: float = settings.settle_duration * 0.4
		var up_time: float = settings.settle_duration * 0.6
		squash_tween.tween_property(visual, "scale:y", squashed, down_time).set_ease(Tween.EASE_OUT)
		squash_tween.tween_property(visual, "scale:y", 1.0, up_time).set_ease(Tween.EASE_OUT)


func _physics_process(_delta: float) -> void:
	if not is_held or _holder == null:
		return

	var forward: Vector3 = -_holder.global_transform.basis.z
	var hold_point: Vector3 = _holder.global_position + forward * settings.hold_distance
	var offset: Vector3 = hold_point - global_position

	if offset.length() > settings.auto_release_distance:
		release()
		return

	linear_velocity = (offset * settings.hold_follow_speed).limit_length(settings.max_hold_speed)
