class_name AxeView
extends Node3D
## El hacha que se ve en primera persona, colgada de la cámara.
## Reacciona a lo que hace el jugador (caminar, girar, frenar, el balanceo del barco),
## tiembla de frío (más cuanto más sogas se cortaron) y tiene un golpe acertado y uno fallido.
## Todo el feel sale de un AxeSettings.

const MODEL: PackedScene = preload("res://assets/models/m4_hacha/fire_axe.glb")

var settings: AxeSettings
var player: Player
## Cuánto está torcida la cámara por el barco (grados). Lo actualiza quien la use.
var boat_roll_degrees: float = 0.0
## Temblor de frío (0..1). Se suma a la base del Resource.
var shiver: float = 0.0

var _model: Node3D
var _time: float = 0.0
var _kick: float = 0.0
var _last_yaw: float = 0.0
var _last_pitch: float = 0.0
var _look_offset: Vector2 = Vector2.ZERO
var _vel_offset: Vector3 = Vector3.ZERO
var _bob_amount: float = 0.0
var _busy: bool = false
var _tween: Tween
# Desplazamientos animados por los golpes (los mueve un Tween).
var _anim_rot: Vector3 = Vector3.ZERO
var _anim_pos: Vector3 = Vector3.ZERO
var _noise: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
	assert(settings != null and player != null, "AxeView: faltan el AxeSettings y el Player")
	_noise.frequency = 1.0
	_model = MODEL.instantiate() as Node3D
	_model.scale = Vector3.ONE * settings.model_scale
	# El modelo trae el filo hacia +Z y el pivote al medio: se gira para que el filo mire adelante
	# y se sube para que la mano agarre el mango, un poco más abajo de la mitad.
	_model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_model.position = Vector3(0.0, 0.2, 0.0)
	add_child(_model)
	visible = false
	_last_yaw = player.rotation.y
	_last_pitch = _head_pitch()
	position = settings.rest_position
	rotation_degrees = settings.rest_rotation_degrees


## Aparece en la mano, viniendo de donde estaba (una transformación global, normalmente la de la pared).
func equip(from_global: Transform3D) -> void:
	visible = true
	_busy = true
	var target: Transform3D = Transform3D(Basis.from_euler(settings.rest_rotation_degrees * (PI / 180.0)), settings.rest_position)
	var origin: Transform3D = get_parent().global_transform.affine_inverse() * from_global
	transform = origin
	var t: Tween = create_tween()
	t.tween_method(func(k: float) -> void:
		transform = Transform3D(
			Basis(origin.basis.get_rotation_quaternion().slerp(target.basis.get_rotation_quaternion(), k)),
			origin.origin.lerp(target.origin, k)),
		0.0, 1.0, settings.equip_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	_busy = false


## Golpe acertado: sube, baja de golpe hacia adelante y vuelve.
func swing_hit() -> void:
	_play([
		[Vector3(settings.raise_angle, 0.0, 6.0), Vector3(0.0, 0.03, 0.04), settings.hit_time * 0.35, Tween.TRANS_QUAD, Tween.EASE_OUT],
		[Vector3(-42.0, -3.0, -8.0), Vector3(-0.05, -0.1, -settings.hit_lunge), settings.hit_time * 0.18, Tween.TRANS_EXPO, Tween.EASE_IN],
		[Vector3(-30.0, -2.0, -6.0), Vector3(-0.05, -0.08, -settings.hit_lunge * 0.9), settings.hit_time * 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT],
		[Vector3.ZERO, Vector3.ZERO, settings.hit_time * 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT],
	])


## Golpe fallido: sube torpe, baja flojo, rebota contra la soga y queda temblando.
func swing_miss() -> void:
	_kick = settings.miss_shiver_kick
	_play([
		[Vector3(settings.raise_angle * 0.8, 0.0, -8.0), Vector3(0.0, 0.02, 0.03), settings.miss_time * 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT],
		[Vector3(-22.0, 6.0, 4.0), Vector3(0.03, -0.06, -settings.hit_lunge * 0.55), settings.miss_time * 0.16, Tween.TRANS_QUAD, Tween.EASE_IN],
		[Vector3(settings.miss_recoil, 10.0, 12.0), Vector3(0.05, 0.05, 0.1), settings.miss_time * 0.14, Tween.TRANS_BACK, Tween.EASE_OUT],
		[Vector3(-6.0, -5.0, -6.0), Vector3(0.0, -0.03, 0.02), settings.miss_time * 0.18, Tween.TRANS_SINE, Tween.EASE_IN_OUT],
		[Vector3.ZERO, Vector3.ZERO, settings.miss_time * 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT],
	])


## Se la arranca la ola: sale volando de la mano.
func torn_away() -> void:
	_busy = true
	if _tween != null:
		_tween.kill()
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(self, "position", position + Vector3(0.5, 0.6, -0.9), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "rotation_degrees", rotation_degrees + Vector3(-220.0, 90.0, 140.0), 0.4)
	await t.finished
	visible = false


func _play(steps: Array) -> void:
	if _busy:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	for step: Array in steps:
		var target_rot: Vector3 = step[0]
		var target_pos: Vector3 = step[1]
		var duration: float = step[2]
		_tween.tween_property(self, "_anim_rot", target_rot, duration).set_trans(step[3]).set_ease(step[4])
		_tween.parallel().tween_property(self, "_anim_pos", target_pos, duration).set_trans(step[3]).set_ease(step[4])


func _head_pitch() -> float:
	return (player.get_node("Head") as Node3D).rotation.x


func _process(delta: float) -> void:
	if not visible or settings == null or _busy:
		return
	_time += delta
	_kick = move_toward(_kick, 0.0, delta * 0.7)

	# Giro de cámara: el hacha se queda un poco atrás y vuelve.
	var yaw: float = player.rotation.y
	var pitch: float = _head_pitch()
	var d_yaw: float = wrapf(yaw - _last_yaw, -PI, PI)
	var d_pitch: float = pitch - _last_pitch
	_last_yaw = yaw
	_last_pitch = pitch
	_look_offset += Vector2(d_yaw, d_pitch) * (180.0 / PI) * settings.look_lag
	_look_offset = _look_offset.limit_length(14.0)
	_look_offset = _look_offset.lerp(Vector2.ZERO, minf(1.0, settings.look_recover * delta))

	# Aceleración: se desplaza en sentido contrario al movimiento (en el espacio del jugador).
	var local_vel: Vector3 = player.global_transform.basis.inverse() * player.velocity
	_vel_offset = _vel_offset.lerp(-local_vel * settings.velocity_lag, minf(1.0, 8.0 * delta))
	_vel_offset.y = clampf(-player.velocity.y * settings.velocity_lag, -0.05, 0.05)

	# Balanceo de la marcha: solo si camina sobre el piso.
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var walking: float = clampf(speed / 3.0, 0.0, 1.0) if player.is_on_floor() else 0.0
	_bob_amount = lerpf(_bob_amount, walking, minf(1.0, 8.0 * delta))
	var bob: Vector3 = Vector3(
		cos(_time * settings.walk_bob_speed * 0.5) * settings.walk_bob * 0.6,
		absf(sin(_time * settings.walk_bob_speed * 0.5)) * -settings.walk_bob,
		0.0) * _bob_amount

	# Temblor de frío: ruido rápido e irregular, más fuerte con cada soga.
	var s: float = clampf(settings.shiver_start + shiver + _kick, 0.0, 1.0)
	var tt: float = _time * settings.shiver_frequency
	var burst: float = 0.6 + 0.4 * sin(_time * 1.7)
	var shake_pos: Vector3 = Vector3(_noise.get_noise_2d(tt, 0.0), _noise.get_noise_2d(tt, 10.0), _noise.get_noise_2d(tt, 20.0)) \
		* settings.shiver_position * s * burst
	var shake_rot: Vector3 = Vector3(_noise.get_noise_2d(tt, 30.0), _noise.get_noise_2d(tt, 40.0), _noise.get_noise_2d(tt, 50.0)) \
		* settings.shiver_rotation * s * burst

	position = settings.rest_position + _anim_pos + _vel_offset + bob + shake_pos
	rotation_degrees = settings.rest_rotation_degrees + _anim_rot + shake_rot \
		+ Vector3(-_look_offset.y * 0.8 + bob.y * 40.0, -_look_offset.x * 0.8, boat_roll_degrees * settings.roll_follow + bob.x * 30.0)
