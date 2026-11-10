class_name PickupObject
extends RigidBody3D
## Objeto que el jugador puede agarrar y arrastrar con físicas (drag and drop).
## Prototipo de las piezas que va a usar el puzzle de rotación de objetos.

signal picked_up(by: Node3D)
signal dropped
signal locked
signal unlocked
signal settled
## Se intentó agarrarlo pero el jugador no llega (está muy abajo o saltando; ver reach).
signal reach_failed

@export var settings: PickupSettings
## Nodo visual (normalmente el MeshInstance3D) al que se le aplica el aplastamiento sutil
## al aterrizar en un PlacementSlot. Opcional: si queda sin asignar, se salta ese efecto.
@export var visual: Node3D
## Opcional: para objetos puestos en alto. Si está asignado, solo se agarra con los ojos cerca de
## su altura (p. ej. subido a un banquito). Vacío = se agarra desde cualquier altura.
@export var reach: ReachSettings

var is_held: bool = false
## Si está en true, pickup() no hace nada: quedó fijo para siempre (p. ej. una soga ya atada).
## Lo pone en true un PlacementSlot con locks_object_on_place, o se puede llamar lock() a mano.
var is_locked: bool = false
## Si es false, el jugador no lo puede soltar una vez que lo agarró (p. ej. el hacha).
var can_release: bool = true

var _holder: Node3D = null
var _holder_body: PhysicsBody3D = null
var _settle_tween: Tween = null
var _audio: AudioStreamPlayer3D = null
## true desde que se suelta hasta el primer golpe (o hasta que se encastra o se vuelve a agarrar).
var _drop_pending: bool = false
## Velocidad que traía justo antes del último paso de física (al llegar el golpe ya se frenó).
var _impact_speed: float = 0.0


func _ready() -> void:
	assert(settings != null, "PickupObject: falta asignar un PickupSettings en el Inspector")
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = settings.sound_bus
	# El tope por defecto (3 dB) recortaría los sonidos a los que se les sube el volumen.
	_audio.max_db = 24.0
	add_child(_audio)
	picked_up.connect(_on_picked_up)
	if not settings.drop_sounds.is_empty():
		# Hace falta para que el RigidBody3D avise con body_entered cuando choca.
		contact_monitor = true
		max_contacts_reported = maxi(max_contacts_reported, 4)
		body_entered.connect(_on_body_entered)


## true si quien lo quiere agarrar lo alcanza: sin reach siempre; con reach, si los ojos (holder)
## están lo bastante alto y el cuerpo (holder_body) está apoyado. No mira is_locked.
func can_be_picked_by(holder: Node3D, holder_body: PhysicsBody3D = null) -> bool:
	if reach == null or holder == null:
		return true
	if reach.must_stand and holder_body is CharacterBody3D and not (holder_body as CharacterBody3D).is_on_floor():
		return false
	return global_position.y - holder.global_position.y <= reach.max_eye_drop


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
	_drop_pending = true
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
	_drop_pending = false
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
	if _drop_pending:
		_impact_speed = linear_velocity.length()
	if not is_held or _holder == null:
		return

	var forward: Vector3 = -_holder.global_transform.basis.z
	var hold_point: Vector3 = _holder.global_position + forward * settings.hold_distance + Vector3.DOWN * settings.hold_drop
	var offset: Vector3 = hold_point - global_position

	if offset.length() > settings.auto_release_distance:
		release()
		return

	linear_velocity = (offset * settings.hold_follow_speed).limit_length(settings.max_hold_speed)


func _on_picked_up(_by: Node3D) -> void:
	_drop_pending = false
	_play_random(settings.pickup_sounds, settings.pickup_volume_db)


## Primer choque después de soltarlo: suena la caída (si pegó con suficiente velocidad).
func _on_body_entered(_body: Node) -> void:
	if not _drop_pending or is_held or freeze:
		return
	if _impact_speed < settings.drop_min_speed:
		return
	_drop_pending = false
	_play_random(settings.drop_sounds, settings.drop_volume_db)


## Reproduce uno de los sonidos al azar, con el volumen dado y un pequeño cambio de tono.
func _play_random(sounds: Array[AudioStream], volume_db: float) -> void:
	if sounds.is_empty():
		return
	var variation: float = settings.sound_pitch_variation
	_audio.stream = sounds.pick_random() as AudioStream
	_audio.volume_db = volume_db
	_audio.pitch_scale = 1.0 + randf_range(-variation, variation)
	_audio.play()
