class_name CuttableRope
extends Node3D
## Soga de la red, tensa entre el cabrestante y el mar. El jugador la corta con el evento rápido.
## Se dibuja como un tubo trenzado que sigue una curva; al cortarse se parte en dos tramos
## que se simulan como cadenas de puntos: el del mar sale disparado al agua y el del cabrestante
## vuelve de un latigazo. No decide cuándo se corta: recibe `add_hit()` y `sever()`.

## Recibió un golpe. `hits` es el total hasta ahora.
signal hit_taken(hits: int)
## La soga se cortó.
signal severed

const DEFAULT_SETTINGS: RopeSettings = preload("res://config/rope_settings.tres")
const TEXTURE: Texture2D = preload("res://assets/textures/rope_strands.png")

## Punto de la soga en el cabrestante, en coordenadas locales.
@export var winch_point: Vector3 = Vector3(0.0, 0.9, -3.0)
## Punto donde se corta (el borde de la rampa).
@export var cut_point: Vector3 = Vector3(0.0, -0.4, 4.0)
## Punto donde la soga entra al mar.
@export var water_point: Vector3 = Vector3(0.0, -2.6, 22.0)
@export_range(0.02, 0.3, 0.005, "suffix:m") var radius: float = 0.07
## Altura del mar en coordenadas locales (lo pone la escena).
@export var water_level: float = -2.6
## Si queda sin asignar usa config/rope_settings.tres.
@export var settings: RopeSettings
## Color al irse deshilachando.
@export var frayed_color: Color = Color(0.9, 0.82, 0.6)

var hits: int = 0
var is_severed: bool = false

var _cfg: RopeSettings
var _material: StandardMaterial3D
var _sea_mesh: MeshInstance3D
var _winch_mesh: MeshInstance3D
var _aim: Area3D
var _sea_path: Array[Vector3] = []
var _winch_path: Array[Vector3] = []
var _tremor: float = 0.0
# Simulación después del corte.
var _chains: Array[Dictionary] = []
var _sim_time: float = 0.0


func _ready() -> void:
	_cfg = settings if settings != null else DEFAULT_SETTINGS
	_material = StandardMaterial3D.new()
	_material.albedo_texture = TEXTURE
	_material.roughness = 0.92
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sea_mesh = _make_mesh_instance("SeaSide")
	_winch_mesh = _make_mesh_instance("WinchSide")
	_sea_path = _build_sea_path()
	_winch_path = _build_winch_path()
	_rebuild_intact(0.0)
	_build_aim_zone()
	set_process(false)
	set_physics_process(false)


## Registra un golpe: la soga se estremece y se ve más deshilachada.
func add_hit() -> void:
	if is_severed:
		return
	hits += 1
	_material.albedo_color = Color.WHITE.lerp(frayed_color * 1.15, minf(float(hits) * 0.35, 0.8))
	_material.emission_enabled = true
	_material.emission = frayed_color * 0.1 * float(hits)
	_tremor = 0.32
	set_process(true)
	hit_taken.emit(hits)


## Corta la soga: el tramo del mar sale disparado y el del cabrestante vuelve de un latigazo.
func sever() -> void:
	if is_severed:
		return
	is_severed = true
	if _aim != null:
		_aim.queue_free()
		_aim = null
	set_process(false)
	var sea: Array[Vector3] = []
	var winch: Array[Vector3] = []
	# Los dos tramos arrancan en el corte (índice 0 = punta libre; el último índice está anclado).
	sea.assign(_sea_path)
	winch.assign(_winch_path)
	_chains = [
		_make_chain(sea, _cfg.sea_whip_speed, _sea_mesh, true),
		_make_chain(winch, _cfg.winch_whip_speed, _winch_mesh, false),
	]
	_sim_time = 0.0
	set_physics_process(true)
	severed.emit()


## Punto del mundo donde se corta (para apuntar la cámara, chispas, etc.).
func get_cut_position() -> Vector3:
	return to_global(cut_point)


# ---------- Forma ----------

func _build_sea_path() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var n: int = _cfg.sea_points
	for i: int in n:
		var t: float = float(i) / float(n - 1)
		var bend: float = 4.0 * t * (1.0 - t)
		var p: Vector3 = cut_point.lerp(water_point, t)
		p.y -= _cfg.sag * bend
		p.z -= _cfg.belly * bend
		points.append(p)
	return points


func _build_winch_path() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var n: int = _cfg.winch_points
	for i: int in n:
		points.append(cut_point.lerp(winch_point, float(i) / float(n - 1)))
	return points


func _make_mesh_instance(node_name: String) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.material_override = _material
	instance.mesh = ArrayMesh.new()
	add_child(instance)
	return instance


## Dibuja los dos tramos con la curva original; `tremor` los sacude un poco (golpe de hacha).
func _rebuild_intact(tremor: float) -> void:
	var sea: Array[Vector3] = []
	var time: float = Time.get_ticks_msec() * 0.001
	for i: int in _sea_path.size():
		var p: Vector3 = _sea_path[i]
		if tremor > 0.0 and i > 0 and i < _sea_path.size() - 1:
			var wobble: float = sin(time * 70.0 + float(i) * 1.9) * tremor * sin(PI * float(i) / float(_sea_path.size() - 1))
			p += Vector3(0.0, wobble, wobble * 0.6)
		sea.append(p)
	_set_tube(_sea_mesh, sea, false)
	_set_tube(_winch_mesh, _winch_path, false)


func _set_tube(instance: MeshInstance3D, points: Array[Vector3], cap_start: bool) -> void:
	var mesh: ArrayMesh = instance.mesh as ArrayMesh
	mesh.clear_surfaces()
	var sides: int = _cfg.sides
	var count: int = points.size()
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var reference: Vector3 = Vector3.UP
	var travelled: float = 0.0
	var first_ring: Array = []
	for i: int in count:
		var tangent: Vector3 = (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side: Vector3 = reference - tangent * reference.dot(tangent)
		if side.length() < 0.01:
			side = Vector3.RIGHT - tangent * Vector3.RIGHT.dot(tangent)
		side = side.normalized()
		reference = side
		var binormal: Vector3 = tangent.cross(side)
		if i > 0:
			travelled += points[i].distance_to(points[i - 1]) / _cfg.texture_pitch
		for s: int in sides + 1:
			var angle: float = TAU * float(s) / float(sides)
			var direction: Vector3 = side * cos(angle) + binormal * sin(angle)
			vertices.append(points[i] + direction * radius)
			normals.append(direction)
			uvs.append(Vector2(float(s) / float(sides), travelled))
		if i == 0:
			first_ring = [tangent, side, binormal]
	for i: int in count - 1:
		for s: int in sides:
			var a: int = i * (sides + 1) + s
			var b: int = a + sides + 1
			indices.append_array([a, b, a + 1, a + 1, b, b + 1])
	if cap_start:
		# Tapa plana en la punta cortada.
		var tangent0: Vector3 = first_ring[0]
		var center: int = vertices.size()
		vertices.append(points[0])
		normals.append(-tangent0)
		uvs.append(Vector2(0.5, 0.0))
		var ring_start: int = vertices.size()
		for s: int in sides + 1:
			var angle: float = TAU * float(s) / float(sides)
			var direction: Vector3 = (first_ring[1] as Vector3) * cos(angle) + (first_ring[2] as Vector3) * sin(angle)
			vertices.append(points[0] + direction * radius)
			normals.append(-tangent0)
			uvs.append(Vector2(0.5 + cos(angle) * 0.4, 0.5 + sin(angle) * 0.4))
		for s: int in sides:
			indices.append_array([center, ring_start + s, ring_start + s + 1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


# ---------- Apuntar ----------

## Zona que el jugador tiene que mirar para cortar: cápsulas a lo largo de la soga.
func _build_aim_zone() -> void:
	_aim = Area3D.new()
	_aim.name = "AimZone"
	_aim.collision_layer = 1
	_aim.collision_mask = 0
	_aim.monitoring = false
	_aim.set_meta("rope", self)
	add_child(_aim)
	var run: Array[Vector3] = [winch_point]
	var travelled: float = 0.0
	run.append(_sea_path[0])
	for i: int in range(1, _sea_path.size()):
		travelled += _sea_path[i].distance_to(_sea_path[i - 1])
		run.append(_sea_path[i])
		if travelled >= _cfg.aim_length:
			break
	for i: int in run.size() - 1:
		var from_p: Vector3 = run[i]
		var to_p: Vector3 = run[i + 1]
		var length: float = from_p.distance_to(to_p)
		if length < 0.01:
			continue
		var capsule: CapsuleShape3D = CapsuleShape3D.new()
		capsule.radius = _cfg.aim_radius
		capsule.height = length + _cfg.aim_radius * 2.0
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.shape = capsule
		shape.position = (from_p + to_p) * 0.5
		shape.basis = Basis(Quaternion(Vector3.UP, (to_p - from_p).normalized()))
		_aim.add_child(shape)


# ---------- Simulación del corte ----------

func _make_chain(points: Array[Vector3], whip_speed: float, instance: MeshInstance3D, toward_water: bool) -> Dictionary:
	var count: int = points.size()
	var previous: Array[Vector3] = []
	var dt: float = 1.0 / 60.0
	var rest: float = 0.0
	for i: int in count - 1:
		rest += points[i].distance_to(points[i + 1])
	rest /= float(count - 1)
	var anchor_dir: Vector3 = (points[count - 1] - points[0]).normalized()
	for i: int in count:
		var falloff: float = pow(1.0 - float(i) / float(count - 1), 0.6)
		var velocity: Vector3 = anchor_dir * whip_speed * falloff
		velocity.y += _cfg.whip_lift * falloff
		velocity += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * _cfg.whip_side * falloff
		previous.append(points[i] - velocity * dt)
	return {"points": points, "previous": previous, "rest": rest, "mesh": instance, "sea": toward_water}


func _physics_process(delta: float) -> void:
	_sim_time += delta
	var steps: int = 2
	var dt: float = delta / float(steps)
	for step: int in steps:
		for chain: Dictionary in _chains:
			_step_chain(chain, dt)
	for chain: Dictionary in _chains:
		_set_tube(chain["mesh"] as MeshInstance3D, chain["points"] as Array[Vector3], true)
	if _sim_time >= _cfg.sim_time:
		set_physics_process(false)


func _step_chain(chain: Dictionary, dt: float) -> void:
	var points: Array[Vector3] = chain["points"]
	var previous: Array[Vector3] = chain["previous"]
	var rest: float = chain["rest"]
	var count: int = points.size()
	var gravity: Vector3 = Vector3.DOWN * 9.8
	for i: int in count - 1:
		var velocity: Vector3 = (points[i] - previous[i]) * 0.995
		previous[i] = points[i]
		points[i] += velocity + gravity * dt * dt
		if points[i].y < water_level:
			# En el agua se frena y se hunde.
			points[i] = previous[i] + (points[i] - previous[i]) * (1.0 - _cfg.water_drag)
			points[i].y -= _cfg.sink_speed * dt
		elif absf(points[i].x) < 3.85 and points[i].y < 0.06:
			# Sobre la cubierta: no la atraviesa y roza.
			points[i].y = 0.06
			points[i].x = lerpf(points[i].x, previous[i].x, _cfg.deck_friction)
			points[i].z = lerpf(points[i].z, previous[i].z, _cfg.deck_friction)
	# La punta anclada en el mar se va hundiendo y arrastra la soga con ella.
	if bool(chain["sea"]) and _sim_time > 0.3:
		var anchor: Vector3 = points[count - 1]
		anchor.y = maxf(anchor.y - _cfg.sink_speed * dt, water_level - 14.0)
		points[count - 1] = anchor
	for iteration: int in 8:
		for i: int in count - 1:
			var delta: Vector3 = points[i + 1] - points[i]
			var distance: float = delta.length()
			if distance < 0.0001:
				continue
			var correction: Vector3 = delta * ((distance - rest) / distance)
			if i + 1 == count - 1:
				points[i] += correction
			else:
				points[i] += correction * 0.5
				points[i + 1] -= correction * 0.5
	# Rigidez a la flexión: evita que la soga se quiebre en zigzag.
	for i: int in range(1, count - 1):
		points[i] = points[i].lerp((points[i - 1] + points[i + 1]) * 0.5, _cfg.stiffness)


func _process(delta: float) -> void:
	_tremor = maxf(_tremor - delta, 0.0)
	_rebuild_intact(_cfg.hit_tremor * clampf(_tremor / 0.32, 0.0, 1.0))
	if _tremor <= 0.0:
		set_process(false)
