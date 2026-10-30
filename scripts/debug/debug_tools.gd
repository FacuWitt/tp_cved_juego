class_name DebugTools
extends Node
## Teclas de prueba comunes a todas las memorias (sirven para mostrar las escenas en clase).
##   8 = cámara libre: WASD vuela hacia donde se mira, Espacio sube, Shift baja, Ctrl acelera.
##   9 = luz de rayo fija (si la escena tiene LightningController).
##   0 = saltar el evento principal de la memoria (la memoria decide qué hace: escucha `skip_requested`).
##   7 = disparar un flashback (la memoria decide qué muestra: escucha `flashback_requested`).
## Se apaga entero con `enabled` (o con el `debug_keys` de cada memoria) antes de llegar a main.
## Son teclas fijas a propósito: son herramientas de desarrollo, no controles del juego.

signal skip_requested
signal flashback_requested
signal fly_toggled(is_on: bool)

@export var enabled: bool = true
@export var player: Player
## Opcional: sin rayos, la tecla 9 no hace nada.
@export var lightning: LightningController
@export_range(0.5, 30.0, 0.5, "suffix:m/s") var fly_speed: float = 5.0
@export_range(1.0, 60.0, 0.5, "suffix:m/s") var fly_fast_speed: float = 14.0

var is_flying: bool = false

var _camera: Camera3D


func _ready() -> void:
	assert(player != null, "DebugTools: falta asignar el jugador")
	_camera = player.get_node("Head/Camera3D") as Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: Key = (event as InputEventKey).keycode
	if key == KEY_8 or key == KEY_KP_8:
		set_flying(not is_flying)
	elif key == KEY_9 or key == KEY_KP_9:
		if lightning != null:
			lightning.set_held(not lightning.is_held)
			print("[debug] luz de rayo fija: ", lightning.is_held)
	elif key == KEY_0 or key == KEY_KP_0:
		print("[debug] saltar evento")
		skip_requested.emit()
	elif key == KEY_7 or key == KEY_KP_7:
		flashback_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


## Prende o apaga la cámara libre. Mientras vuela, el jugador no tiene física (ni gravedad ni choques).
func set_flying(value: bool) -> void:
	is_flying = value
	player.set_physics_process(not is_flying)
	player.velocity = Vector3.ZERO
	print("[debug] modo vuelo: ", is_flying)
	fly_toggled.emit(is_flying)


func _process(delta: float) -> void:
	if not is_flying:
		return
	var basis: Basis = _camera.global_transform.basis
	var direction: Vector3 = Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		direction -= basis.z
	if Input.is_physical_key_pressed(KEY_S):
		direction += basis.z
	if Input.is_physical_key_pressed(KEY_D):
		direction += basis.x
	if Input.is_physical_key_pressed(KEY_A):
		direction -= basis.x
	if Input.is_physical_key_pressed(KEY_SPACE):
		direction += Vector3.UP
	if Input.is_physical_key_pressed(KEY_SHIFT):
		direction += Vector3.DOWN
	var speed: float = fly_fast_speed if Input.is_physical_key_pressed(KEY_CTRL) else fly_speed
	if direction.length() > 0.01:
		player.global_position += direction.normalized() * speed * delta
	player.velocity = Vector3.ZERO
