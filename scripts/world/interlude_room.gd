class_name InterludeRoom
extends Node3D
## Sala intermedia de la M3: lo que hay detrás de una puerta buena, antes del tramo siguiente.
## El jugador llega caminando desde un tramo oscuro (`entry`), la cruza y sale por el umbral del
## fondo (`exit_portal`). La memoria decide a dónde lleva ese umbral; la sala solo se ocupa de
## lo que pasa adentro. Esta clase arma las paredes (cajas con colisión, nombres "_G", no se
## guardan en la escena) y da las utilidades comunes; cada sala hereda y pone lo suyo.
## El origen de la sala es `entry`; se avanza hacia -Z.

## Largo del tramo oscuro por el que se llega, detrás del punto de llegada (margen técnico).
const STUB_BACK: float = 1.4
## Largo del tramo oscuro entre el punto de llegada y la sala.
const STUB_FRONT: float = 3.0
## Largo del tramo oscuro de salida (el umbral está adentro).
const EXIT_STUB: float = 4.0
const STUB_WIDTH: float = 1.6
const STUB_HEIGHT: float = 2.3
const WALL: float = 0.2

## Donde aparece el jugador (misma orientación que los umbrales del rellano).
@export var entry: Marker3D
## El umbral de salida, en el tramo oscuro del fondo.
@export var exit_portal: LoopPortal
@export var wall_material: Material
@export var floor_material: Material
@export var ceiling_material: Material
## Negro sin luz: los tramos oscuros de entrada y salida.
@export var dark_material: Material
## Drone grave que suena mientras se está en la sala (opcional).
@export var drone_stream: AudioStream
## Si está en true, no caen rayos mientras se cruza la sala (vuelven al salir).
@export var stops_lightning: bool = false

var player: Player
var environment: Environment
var lightning: LightningController
## Degradación de la casa, 0..1 (la pone la memoria).
var level: float = 0.0
var is_active: bool = false
## Luz ambiente y cielo de la escena sin rayo (los pasa la memoria): la sala los baja y los devuelve.
var base_ambient: float = 0.0
var base_sky: float = 1.0

var _shell: Node3D
var _camera: Camera3D
var _drone: AudioStreamPlayer
var _drone_tween: Tween


## El jugador acaba de llegar a la sala.
func enter(p_player: Player, p_environment: Environment, p_lightning: LightningController) -> void:
	player = p_player
	environment = p_environment
	lightning = p_lightning
	_camera = player.get_node("Head/Camera3D") as Camera3D
	is_active = true
	if stops_lightning and lightning != null:
		lightning.stop()
	_on_entered()


## El jugador salió por el umbral del fondo.
func leave() -> void:
	if not is_active:
		return
	is_active = false
	_on_left()
	set_ambient(1.0)
	if stops_lightning and lightning != null:
		lightning.start()
	fade_drone(-60.0, 1.5)


## Si la escena se va con el jugador adentro (reinicio de la memoria), se devuelve lo que la sala
## le cambió al ambiente: el recurso se comparte con la próxima carga de la escena.
func _exit_tree() -> void:
	if is_active and environment != null:
		environment.ambient_light_energy = base_ambient
		_restore_environment()


## Para las salas que cambian algo más del ambiente (la niebla): devolverlo ya, sin transición.
func _restore_environment() -> void:
	pass


## Deja la luz ambiente de la escena en `scale` veces la normal (1 = como estaba).
func set_ambient(scale: float) -> void:
	if lightning != null:
		lightning.set_base_levels(base_ambient * scale, base_sky)
	elif environment != null:
		environment.ambient_light_energy = base_ambient * scale


## Hubo un parpadeo a negro: en ese instante las cosas pueden cambiar aunque se las mire.
func on_blink() -> void:
	pass


## Cuánto avanzó el jugador dentro de la sala: 0 al entrar, 1 en la pared del fondo.
func progress() -> float:
	if player == null:
		return 0.0
	return clampf((-STUB_FRONT - to_local(player.global_position).z) / maxf(_room_depth(), 0.01), 0.0, 1.0)


## Cuánto pesan las piernas en este punto de la sala, 0..1 (la memoria se lo pasa a los efectos de sueño).
func drag() -> float:
	return 0.0


func _on_entered() -> void:
	pass


func _on_left() -> void:
	pass


## Largo de la sala (entre el tramo de entrada y la pared del fondo). Lo define cada sala.
func _room_depth() -> float:
	return 1.0


# ---------- Armado ----------

func _shell_root() -> Node3D:
	if _shell == null:
		_shell = Node3D.new()
		_shell.name = "_GShell"
		add_child(_shell)
	return _shell


## Una caja con malla y (si `collide`) colisión. `center` y `size` en el espacio de la sala.
func add_box(center: Vector3, size: Vector3, material: Material, collide: bool = true) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	_shell_root().add_child(instance)
	if collide:
		var body: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		instance.add_child(body)
	return instance


## Una pared en el plano XY (en `z`), de `x_min` a `x_max`, con un hueco de puerta centrado en `door_x`
## (NAN = sin hueco).
func add_wall_z(z: float, x_min: float, x_max: float, height: float, material: Material, door_x: float = NAN) -> void:
	if is_nan(door_x):
		add_box(Vector3((x_min + x_max) * 0.5, height * 0.5, z), Vector3(x_max - x_min, height, WALL), material)
		return
	var left: float = door_x - STUB_WIDTH * 0.5
	var right: float = door_x + STUB_WIDTH * 0.5
	if left > x_min:
		add_box(Vector3((x_min + left) * 0.5, height * 0.5, z), Vector3(left - x_min, height, WALL), material)
	if x_max > right:
		add_box(Vector3((right + x_max) * 0.5, height * 0.5, z), Vector3(x_max - right, height, WALL), material)
	if height > STUB_HEIGHT:
		add_box(Vector3(door_x, (STUB_HEIGHT + height) * 0.5, z), Vector3(STUB_WIDTH, height - STUB_HEIGHT, WALL), material)


## Un tramo oscuro (piso, techo y dos paredes negras) entre `z_near` y `z_far` (z_far < z_near),
## centrado en `x`. Con `end_wall` lo cierra en `z_far`; con `back_wall`, en `z_near`.
func add_stub(x: float, z_near: float, z_far: float, end_wall: bool, back_wall: bool) -> void:
	var length: float = z_near - z_far
	var mid: float = (z_near + z_far) * 0.5
	add_box(Vector3(x, -WALL * 0.5, mid), Vector3(STUB_WIDTH + WALL * 2.0, WALL, length), dark_material)
	add_box(Vector3(x, STUB_HEIGHT + WALL * 0.5, mid), Vector3(STUB_WIDTH + WALL * 2.0, WALL, length), dark_material)
	for side: float in [-1.0, 1.0]:
		add_box(Vector3(x + side * (STUB_WIDTH + WALL) * 0.5, STUB_HEIGHT * 0.5, mid), Vector3(WALL, STUB_HEIGHT, length), dark_material)
	if end_wall:
		add_box(Vector3(x, STUB_HEIGHT * 0.5, z_far - WALL * 0.5), Vector3(STUB_WIDTH + WALL * 2.0, STUB_HEIGHT, WALL), dark_material)
	if back_wall:
		add_box(Vector3(x, STUB_HEIGHT * 0.5, z_near + WALL * 0.5), Vector3(STUB_WIDTH + WALL * 2.0, STUB_HEIGHT, WALL), dark_material)


## El tramo oscuro por el que se llega (alrededor de `entry`).
func add_entry_stub() -> void:
	add_stub(0.0, STUB_BACK, -STUB_FRONT, false, true)


## El tramo oscuro de salida en la pared del fondo (`z_end`), centrado en `x`: ubica el umbral
## y pone en el piso la franja de luz cálida del velador (la guía de toda la memoria).
## Devuelve la luz de esa franja.
func add_exit(x: float, z_end: float, glow_energy: float, glow_range: float) -> OmniLight3D:
	add_stub(x, z_end, z_end - EXIT_STUB, true, false)
	exit_portal.position = Vector3(x, 0.0, z_end - 0.6)
	var strip: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(STUB_WIDTH - 0.2, 0.015, 0.12)
	strip.mesh = mesh
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.75, 0.45)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.7, 0.4)
	glow.emission_energy_multiplier = 2.0
	strip.material_override = glow
	strip.position = Vector3(x, 0.01, z_end - 0.1)
	_shell_root().add_child(strip)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.4)
	light.light_energy = glow_energy
	light.omni_range = glow_range
	light.position = Vector3(x, 0.35, z_end + 0.3)
	_shell_root().add_child(light)
	return light


# ---------- Sonido ----------

## Un reproductor sin posición (suena "en la cabeza"). Con `loop` repite el sonido.
func make_player(stream: AudioStream, volume_db: float, loop: bool = false) -> AudioStreamPlayer:
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = _looped(stream) if loop else stream
	audio.volume_db = volume_db
	add_child(audio)
	return audio


## Suena una vez en un punto de la sala (posición global) y se libera sola.
func play_at(stream: AudioStream, at: Vector3, volume_db: float, pitch: float = 1.0, unit_size: float = 3.0) -> void:
	if stream == null:
		return
	var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	audio.stream = stream
	audio.volume_db = volume_db
	audio.pitch_scale = pitch
	audio.unit_size = unit_size
	audio.max_distance = 40.0
	add_child(audio)
	audio.global_position = at
	audio.finished.connect(audio.queue_free)
	audio.play()


## Arranca el drone (si hay) en silencio y lo lleva a `volume_db` en `time` segundos.
func fade_drone(volume_db: float, time: float) -> void:
	if drone_stream == null:
		return
	if _drone == null:
		_drone = make_player(drone_stream, -60.0, true)
	if not _drone.playing and volume_db > -59.0:
		_drone.play()
	if _drone_tween != null and _drone_tween.is_valid():
		_drone_tween.kill()
	_drone_tween = create_tween()
	_drone_tween.tween_property(_drone, "volume_db", volume_db, time)
	if volume_db <= -59.0:
		_drone_tween.tween_callback(_drone.stop)


func _looped(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamOggVorbis:
		var copy: AudioStreamOggVorbis = stream.duplicate() as AudioStreamOggVorbis
		copy.loop = true
		return copy
	return stream
