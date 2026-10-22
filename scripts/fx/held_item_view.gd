class_name HeldItemView
extends Node3D
## Un objeto en la mano del protagonista, en primera persona (se cuelga de la cámara).
## Lo que se ve son sus nodos hijos (un modelo, una luz...). Reacciona a lo que hace el jugador:
## se balancea al caminar, se queda atrás al girar y tiembla de frío.
## Es la versión general del hacha de M4 (AxeView), sin los golpes.

@export var settings: HeldItemSettings
@export var player: Player

## Temblor extra (0..1) que se suma al de base: lo puede subir la memoria (más frío, más miedo).
var extra_shiver: float = 0.0
var is_equipped: bool = false

var _time: float = 0.0
var _last_yaw: float = 0.0
var _last_pitch: float = 0.0
var _look_offset: Vector2 = Vector2.ZERO
var _vel_offset: Vector3 = Vector3.ZERO
var _bob_amount: float = 0.0
var _anim_offset: Vector3 = Vector3.ZERO
var _noise: FastNoiseLite = FastNoiseLite.new()
var _head: Node3D


func _ready() -> void:
	assert(settings != null and player != null, "HeldItemView: faltan el HeldItemSettings y el Player")
	_noise.frequency = 1.0
	_noise.seed = randi()
	_head = player.get_node("Head") as Node3D
	_last_yaw = player.rotation.y
	_last_pitch = _head.rotation.x
	position = settings.rest_position
	rotation_degrees = settings.rest_rotation_degrees
	visible = is_equipped


## Aparece en la mano subiendo desde abajo de la pantalla. Se puede esperar con await.
func equip() -> void:
	is_equipped = true
	visible = true
	_anim_offset = Vector3(0.0, -0.45, 0.1)
	var t: Tween = create_tween()
	t.tween_property(self, "_anim_offset", Vector3.ZERO, settings.equip_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished


## Deja de estar en la mano (sin animación: quien llama decide qué pasa con el objeto).
func unequip() -> void:
	is_equipped = false
	visible = false


func _process(delta: float) -> void:
	if not is_equipped:
		return
	_time += delta
	var yaw: float = player.rotation.y
	var pitch: float = _head.rotation.x
	var d_yaw: float = wrapf(yaw - _last_yaw, -PI, PI)
	var d_pitch: float = pitch - _last_pitch
	_last_yaw = yaw
	_last_pitch = pitch
	_look_offset += Vector2(d_yaw, d_pitch) * (180.0 / PI) * settings.look_lag
	_look_offset = _look_offset.limit_length(14.0)
	_look_offset = _look_offset.lerp(Vector2.ZERO, minf(1.0, settings.look_recover * delta))

	var local_vel: Vector3 = player.global_transform.basis.inverse() * player.velocity
	_vel_offset = _vel_offset.lerp(-local_vel * settings.velocity_lag, minf(1.0, 8.0 * delta))
	_vel_offset.y = clampf(-player.velocity.y * settings.velocity_lag, -0.05, 0.05)

	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var walking: float = clampf(speed / 3.0, 0.0, 1.0) if player.is_on_floor() else 0.0
	_bob_amount = lerpf(_bob_amount, walking, minf(1.0, 8.0 * delta))
	var bob: Vector3 = Vector3(
		cos(_time * settings.walk_bob_speed * 0.5) * settings.walk_bob * 0.6,
		absf(sin(_time * settings.walk_bob_speed * 0.5)) * -settings.walk_bob,
		0.0) * _bob_amount

	var s: float = clampf(settings.shiver + extra_shiver, 0.0, 1.0)
	var tt: float = _time * settings.shiver_frequency
	var burst: float = 0.6 + 0.4 * sin(_time * 1.7)
	var shake_pos: Vector3 = Vector3(_noise.get_noise_2d(tt, 0.0), _noise.get_noise_2d(tt, 10.0), _noise.get_noise_2d(tt, 20.0)) \
		* settings.shiver_position * s * burst
	var shake_rot: Vector3 = Vector3(_noise.get_noise_2d(tt, 30.0), _noise.get_noise_2d(tt, 40.0), _noise.get_noise_2d(tt, 50.0)) \
		* settings.shiver_rotation * s * burst

	position = settings.rest_position + _anim_offset + _vel_offset + bob + shake_pos
	rotation_degrees = settings.rest_rotation_degrees + shake_rot \
		+ Vector3(-_look_offset.y * 0.8 + bob.y * 40.0, -_look_offset.x * 0.8, bob.x * 30.0)
