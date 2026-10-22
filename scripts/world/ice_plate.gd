@tool
class_name IcePlate
extends AnimatableBody3D
## Placa de hielo que flota en el lago (Memoria 2).
## Se inclina hacia donde está parado el jugador, lo hace resbalar cuesta abajo y,
## si se queda quieto encima mucho tiempo, se agrieta y se rompe.
## Arma su propia forma (mesh y colisión) a partir de `size`, así en la escena solo se ubica y se le da tamaño.

## Empezó a agrietarse (aviso: el jugador tiene que moverse).
signal cracking(plate: IcePlate)
## Se rompió: el jugador cae al agua.
signal broke(plate: IcePlate)

@export var size: Vector3 = Vector3(3.0, 0.3, 3.0):
	set(value):
		size = value
		if is_node_ready():
			_build()
@export var settings: IceSettings
## Si es false no se agrieta nunca (p. ej. la placa del perro, que la rompe la cinemática).
@export var crackable: bool = true

## Lo asigna la memoria al empezar.
var player: Player
var is_broken: bool = false
var is_cracked: bool = false

var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _material: StandardMaterial3D
var _cracks: Array[MeshInstance3D] = []
var _base: Transform3D
var _stand_time: float = 0.0
var _tilt: Vector2 = Vector2.ZERO
var _sink: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	assert(settings != null, "IcePlate: falta el IceSettings")
	sync_to_physics = true
	_base = global_transform
	_phase = randf() * TAU
	# Antes que el jugador, para que su movimiento ya parta del empujón.
	process_physics_priority = -10


## ¿El jugador está parado sobre esta placa?
func has_player() -> bool:
	if player == null or is_broken or not player.is_on_floor():
		return false
	for i: int in player.get_slide_collision_count():
		if player.get_slide_collision(i).get_collider() == self:
			return true
	return false


## Vuelve la placa a como estaba (después de que el jugador reaparece).
func reset() -> void:
	is_broken = false
	is_cracked = false
	_stand_time = 0.0
	_tilt = Vector2.ZERO
	_sink = 0.0
	global_transform = _base
	_mesh.visible = true
	_mesh.transparency = 0.0
	_shape.set_deferred("disabled", false)
	_material.albedo_color = settings.ice_color
	for crack: MeshInstance3D in _cracks:
		crack.visible = false


## Rompe la placa ya (la usa la cinemática del final).
func shatter() -> void:
	if is_broken:
		return
	is_broken = true
	_shape.set_deferred("disabled", true)
	broke.emit(self)
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(self, "global_position:y", global_position.y - 0.5, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_mesh, "transparency", 1.0, 0.6)
	t.chain().tween_callback(func() -> void: _mesh.visible = false)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or is_broken:
		return
	_time += delta
	var on_it: bool = has_player()
	var target: Vector2 = Vector2.ZERO
	if on_it:
		# Dónde está el jugador respecto del centro, en el plano de la placa sin inclinar.
		var local: Vector3 = _base.affine_inverse() * player.global_position
		target = Vector2(local.z, -local.x) * settings.tilt_per_meter
		target = target.limit_length(settings.max_tilt)
		if crackable:
			_stand_time += delta
	else:
		_stand_time = maxf(_stand_time - settings.recover_speed * delta, 0.0)
	_tilt = _tilt.lerp(target, minf(1.0, settings.tilt_speed * delta))
	_sink = lerpf(_sink, settings.sink_depth if on_it else 0.0, minf(1.0, 3.0 * delta))
	var bob: float = sin(_time * settings.bob_speed * TAU * 0.3 + _phase) * settings.bob_height
	var rot: Basis = Basis.from_euler(Vector3(deg_to_rad(_tilt.x), 0.0, deg_to_rad(_tilt.y)))
	global_transform = Transform3D(_base.basis * rot, _base.origin + Vector3(0.0, bob - _sink, 0.0))

	if on_it:
		# Resbala cuesta abajo: la normal de la placa inclinada apunta hacia el lado bajo.
		var up: Vector3 = global_transform.basis.y
		var downhill: Vector3 = Vector3(up.x, 0.0, up.z)
		if downhill.length() > 0.0001:
			player.velocity += downhill.normalized() * _tilt.length() * settings.slip_strength * delta

	if crackable:
		_update_cracks()


func _update_cracks() -> void:
	var k: float = clampf(_stand_time / settings.break_time, 0.0, 1.0)
	_material.albedo_color = settings.ice_color.lerp(settings.cracked_color, k)
	var shown: int = 0
	if _stand_time >= settings.crack_warn_time:
		shown = int(ceil(lerpf(1.0, float(_cracks.size()), inverse_lerp(settings.crack_warn_time, settings.break_time, _stand_time))))
		if not is_cracked:
			is_cracked = true
			cracking.emit(self)
	elif _stand_time <= 0.0:
		is_cracked = false
	for i: int in _cracks.size():
		_cracks[i].visible = i < shown
	if _stand_time >= settings.break_time:
		shatter()


func _build() -> void:
	for child: Node in get_children():
		if child.has_meta("ice_generated"):
			child.free()
	_cracks.clear()
	_material = StandardMaterial3D.new()
	_material.albedo_color = settings.ice_color if settings != null else Color(0.62, 0.74, 0.82, 0.92)
	_material.roughness = 0.18
	_material.metallic_specular = 0.7
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	_mesh = MeshInstance3D.new()
	_mesh.mesh = box
	_mesh.material_override = _material
	_mesh.set_meta("ice_generated", true)
	add_child(_mesh)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	_shape = CollisionShape3D.new()
	_shape.shape = shape
	_shape.set_meta("ice_generated", true)
	add_child(_shape)
	# Grietas: líneas finas oscuras sobre la cara de arriba, se van mostrando de a una.
	var crack_material: StandardMaterial3D = StandardMaterial3D.new()
	crack_material.albedo_color = Color(0.08, 0.14, 0.2)
	crack_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(name)
	var start: Vector2 = Vector2.ZERO
	for i: int in 7:
		var angle: float = rng.randf() * TAU
		var length: float = rng.randf_range(0.4, 0.5 * minf(size.x, size.z))
		var line: BoxMesh = BoxMesh.new()
		line.size = Vector3(0.025, 0.004, length)
		var crack: MeshInstance3D = MeshInstance3D.new()
		crack.mesh = line
		crack.material_override = crack_material
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var mid: Vector2 = start + dir * length * 0.5
		crack.position = Vector3(clampf(mid.x, -size.x * 0.45, size.x * 0.45), size.y * 0.5 + 0.003, clampf(mid.y, -size.z * 0.45, size.z * 0.45))
		crack.rotation.y = -angle + PI * 0.5
		crack.visible = Engine.is_editor_hint()
		crack.set_meta("ice_generated", true)
		add_child(crack)
		_cracks.append(crack)
		start = start + dir * length * 0.8
		if start.length() > 0.4 * minf(size.x, size.z):
			start = Vector2.ZERO
