class_name RowCourse
extends Node3D
## El recorrido del lago de la Memoria 2: el camino que sigue el padre, los obstáculos que lo cruzan,
## los bancos de niebla y la cabaña del final. Arma todo al cargarse a partir de un RowCourseSettings.
## Sabe contestar: "¿dónde está el camino a tantos metros?" y "¿qué tan avanzado está este punto?".

@export var settings: RowCourseSettings
@export var water: LakeWater

## Todos los obstáculos de choque.
var obstacles: Array[RowObstacle] = []
## Largo total del camino.
var length: float = 0.0

var _points: PackedVector2Array = PackedVector2Array()
var _dist: PackedFloat32Array = PackedFloat32Array()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _rock_material: StandardMaterial3D
var _wood_material: StandardMaterial3D
var _ring_texture: GradientTexture2D
var _ring_material: StandardMaterial3D


func _ready() -> void:
	assert(settings != null, "RowCourse: falta el RowCourseSettings")
	assert(settings.points.size() >= 2, "RowCourse: el camino necesita al menos dos puntos")
	_make_materials()
	_build_path()
	_rng.seed = settings.seed_value
	_build_obstacles()
	_build_fog_banks()


# ---------- Camino ----------

## Punto (x, z) del camino a `d` metros del comienzo.
func point_at(d: float) -> Vector2:
	d = clampf(d, 0.0, length)
	var i: int = _dist.bsearch(d)
	if i <= 0:
		return _points[0]
	if i >= _points.size():
		return _points[_points.size() - 1]
	var span: float = _dist[i] - _dist[i - 1]
	var t: float = 0.0 if span < 0.0001 else (d - _dist[i - 1]) / span
	return _points[i - 1].lerp(_points[i], t)


## Dirección del camino (unitaria) a `d` metros del comienzo.
func tangent_at(d: float) -> Vector2:
	var a: Vector2 = point_at(d - 1.5)
	var b: Vector2 = point_at(d + 1.5)
	var t: Vector2 = b - a
	return t.normalized() if t.length() > 0.001 else Vector2(0.0, -1.0)


## Qué distancia del camino recorrió un punto: la del punto del camino más cercano.
func progress_of(p: Vector2) -> float:
	return _nearest(p)[0]


## Distancia (siempre positiva) del punto al camino.
func distance_to_path(p: Vector2) -> float:
	return _nearest(p)[1]


## Punto del camino más cercano a `p`.
func nearest_point(p: Vector2) -> Vector2:
	return point_at(_nearest(p)[0])


## Dónde está la cabaña (x, z).
func cabin_position() -> Vector2:
	return point_at(length) + tangent_at(length) * settings.cabin_beyond_end


# Devuelve [distancia recorrida, distancia al camino] del punto más cercano.
func _nearest(p: Vector2) -> Array[float]:
	var best_i: int = 0
	var best_d2: float = INF
	for i: int in _points.size():
		var d2: float = p.distance_squared_to(_points[i])
		if d2 < best_d2:
			best_d2 = d2
			best_i = i
	# Se afina proyectando sobre los dos tramos vecinos.
	var best_progress: float = _dist[best_i]
	var best_dist: float = sqrt(best_d2)
	for j: int in [best_i - 1, best_i]:
		if j < 0 or j + 1 >= _points.size():
			continue
		var a: Vector2 = _points[j]
		var b: Vector2 = _points[j + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var q: Vector2 = a + ab * t
		var dd: float = p.distance_to(q)
		if dd < best_dist:
			best_dist = dd
			best_progress = lerpf(_dist[j], _dist[j + 1], t)
	return [best_progress, best_dist]


func _build_path() -> void:
	var pts: PackedVector2Array = settings.points
	var n: int = pts.size()
	_points = PackedVector2Array()
	for i: int in n - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, n - 1)]
		var steps: int = maxi(int(ceil(p1.distance_to(p2) / settings.sample_step)), 1)
		for k: int in steps:
			var t: float = float(k) / float(steps)
			_points.append(_catmull(p0, p1, p2, p3, t))
	_points.append(pts[n - 1])
	_dist = PackedFloat32Array()
	var acc: float = 0.0
	_dist.append(0.0)
	for i: int in range(1, _points.size()):
		acc += _points[i].distance_to(_points[i - 1])
		_dist.append(acc)
	length = acc


func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


# ---------- Obstáculos ----------

func _build_obstacles() -> void:
	var d: float = settings.first_obstacle_at
	var last_side: float = 1.0
	while d < length - settings.clear_end:
		var f: float = d / length
		var storm_k: float = smoothstep(0.1, 0.7, f)
		var spacing: float = lerpf(settings.spacing_calm, settings.spacing_storm, storm_k) * _rng.randf_range(0.8, 1.25)
		var side: float = -last_side if _rng.randf() < 0.65 else last_side
		last_side = side
		var kind: RowObstacle.Kind = _pick_kind(f)
		var lateral: float = side * _rng.randf_range(settings.lateral_min, settings.lateral_max)
		_spawn(kind, d, lateral)
		d += spacing
	for f_gate: float in settings.gate_at:
		var dg: float = length * f_gate
		_spawn(RowObstacle.Kind.ROCK, dg, -settings.gate_half_gap - 1.2, 1.7)
		_spawn(RowObstacle.Kind.ROCK, dg, settings.gate_half_gap + 1.2, 1.9)
	for f_field: float in settings.log_field_at:
		var df: float = length * f_field
		_spawn(RowObstacle.Kind.LOG, df - 9.0, -2.6)
		_spawn(RowObstacle.Kind.LOG, df, 2.2)
		_spawn(RowObstacle.Kind.LOG, df + 9.0, -2.0)
		_spawn(RowObstacle.Kind.LOG, df + 18.0, 2.8)


func _pick_kind(f: float) -> RowObstacle.Kind:
	var r: float = _rng.randf()
	# Las boyas se ven sobre todo al principio, cuando todavía hay luz.
	var buoy_chance: float = lerpf(0.34, 0.1, smoothstep(0.0, 0.6, f))
	if r < buoy_chance:
		return RowObstacle.Kind.BUOY
	r = (r - buoy_chance) / (1.0 - buoy_chance)
	if r < 0.55:
		return RowObstacle.Kind.ROCK
	if r < 0.8:
		return RowObstacle.Kind.LOG
	return RowObstacle.Kind.SNAG


func _spawn(kind: RowObstacle.Kind, d: float, lateral: float, forced_radius: float = 0.0) -> RowObstacle:
	var t: Vector2 = tangent_at(d)
	var normal: Vector2 = Vector2(-t.y, t.x)
	var pos: Vector2 = point_at(d) + normal * lateral
	var obstacle: RowObstacle = RowObstacle.new()
	obstacle.kind = kind
	obstacle.water = water
	obstacle.name = "%s_%d" % [RowObstacle.Kind.keys()[kind].capitalize(), obstacles.size()]
	match kind:
		RowObstacle.Kind.ROCK:
			obstacle.radius = forced_radius if forced_radius > 0.0 else _rng.randf_range(1.0, 1.9)
			obstacle.base_y = -obstacle.radius * 0.35
			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = _jagged_rock(obstacle.radius, _rng.randi())
			mesh.material_override = _rock_material
			mesh.rotation.y = _rng.randf() * TAU
			obstacle.add_child(mesh)
		RowObstacle.Kind.LOG:
			obstacle.radius = 1.7
			obstacle.bob = 0.7
			obstacle.base_y = 0.0
			obstacle.drift = Vector2(_rng.randf_range(-0.25, 0.25), _rng.randf_range(0.1, 0.4))
			var mesh: MeshInstance3D = MeshInstance3D.new()
			var cyl: CylinderMesh = CylinderMesh.new()
			cyl.top_radius = 0.28
			cyl.bottom_radius = 0.34
			cyl.height = 4.6
			cyl.radial_segments = 7
			mesh.mesh = cyl
			mesh.rotation = Vector3(0.0, 0.0, PI * 0.5)
			mesh.material_override = _wood_material
			obstacle.add_child(mesh)
			obstacle.rotation.y = _rng.randf() * TAU
		RowObstacle.Kind.SNAG:
			obstacle.radius = 1.0
			obstacle.base_y = -0.5
			_build_snag(obstacle)
		RowObstacle.Kind.BUOY:
			obstacle.radius = 0.6
			obstacle.bob = 1.0
			obstacle.base_y = 0.05
			_build_buoy(obstacle)
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "FoamRing"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * obstacle.radius * 2.8
	quad.orientation = PlaneMesh.FACE_Y
	ring.mesh = quad
	ring.material_override = _ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	obstacle.add_child(ring)
	add_child(obstacle)
	obstacle.global_position = Vector3(pos.x, 0.0, pos.y)
	obstacles.append(obstacle)
	return obstacle


func _build_snag(obstacle: RowObstacle) -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.32
	cyl.height = 4.4
	cyl.radial_segments = 6
	trunk.mesh = cyl
	trunk.position = Vector3(0.0, 1.5, 0.0)
	trunk.rotation = Vector3(_rng.randf_range(-0.25, 0.25), 0.0, _rng.randf_range(-0.25, 0.25))
	trunk.material_override = _wood_material
	obstacle.add_child(trunk)
	for i: int in 3:
		var branch: MeshInstance3D = MeshInstance3D.new()
		var bc: CylinderMesh = CylinderMesh.new()
		bc.top_radius = 0.02
		bc.bottom_radius = 0.07
		bc.height = _rng.randf_range(0.9, 1.7)
		bc.radial_segments = 5
		branch.mesh = bc
		branch.position = Vector3(0.0, 1.2 + i * 0.75, 0.0)
		branch.rotation = Vector3(0.0, _rng.randf() * TAU, _rng.randf_range(0.7, 1.2))
		branch.material_override = _wood_material
		obstacle.add_child(branch)


func _build_buoy(obstacle: RowObstacle) -> void:
	var ball: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	sphere.radial_segments = 8
	sphere.rings = 5
	ball.mesh = sphere
	ball.position = Vector3(0.0, 0.15, 0.0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.28, 0.12)
	mat.roughness = 0.6
	ball.material_override = mat
	obstacle.add_child(ball)
	var lamp: OmniLight3D = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.25, 0.15)
	lamp.light_energy = 0.8
	lamp.omni_range = 7.0
	lamp.position = Vector3(0.0, 0.7, 0.0)
	lamp.set_script(preload("res://scripts/world/blink_light.gd"))
	obstacle.add_child(lamp)


# ---------- Niebla ----------

func _build_fog_banks() -> void:
	for f: float in settings.fog_bank_at:
		var d: float = length * f
		var center: Vector2 = point_at(d)
		var t: Vector2 = tangent_at(d)
		var bank: CPUParticles3D = CPUParticles3D.new()
		bank.name = "FogBank_%d" % int(f * 100.0)
		bank.amount = 46
		bank.lifetime = 9.0
		bank.preprocess = 9.0
		bank.local_coords = true
		bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(16.0, 9.0)
		bank.mesh = quad
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_texture = _soft_texture()
		mat.albedo_color = Color(0.5, 0.58, 0.66, 0.2)
		mat.vertex_color_use_as_albedo = true
		bank.material_override = mat
		bank.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		bank.emission_box_extents = Vector3(20.0, 1.6, settings.fog_bank_length * 0.5)
		bank.direction = Vector3(1.0, 0.0, 0.0)
		bank.spread = 20.0
		bank.initial_velocity_min = 0.3
		bank.initial_velocity_max = 0.9
		bank.gravity = Vector3.ZERO
		bank.scale_amount_min = 0.8
		bank.scale_amount_max = 1.5
		add_child(bank)
		bank.global_position = Vector3(center.x, 1.8, center.y)
		bank.rotation.y = atan2(-t.x, -t.y)


# ---------- Materiales y formas ----------

func _make_materials() -> void:
	_rock_material = StandardMaterial3D.new()
	_rock_material.albedo_color = Color(0.2, 0.22, 0.24)
	_rock_material.roughness = 0.85
	_wood_material = StandardMaterial3D.new()
	_wood_material.albedo_color = Color(0.2, 0.14, 0.09)
	_wood_material.roughness = 0.95
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.52, 0.72, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	_ring_texture = GradientTexture2D.new()
	_ring_texture.gradient = gradient
	_ring_texture.fill = GradientTexture2D.FILL_RADIAL
	_ring_texture.fill_from = Vector2(0.5, 0.5)
	_ring_texture.fill_to = Vector2(1.0, 0.5)
	_ring_texture.width = 64
	_ring_texture.height = 64
	_ring_material = StandardMaterial3D.new()
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.albedo_texture = _ring_texture
	_ring_material.albedo_color = Color(0.8, 0.88, 0.95)
	_ring_material.roughness = 1.0
	_ring_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _soft_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


## Roca de caras planas: una esfera de pocos polígonos con los vértices corridos.
func _jagged_rock(radius: float, seed_value: int) -> ArrayMesh:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 7
	sphere.rings = 4
	var arrays: Array = sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var jitter: RandomNumberGenerator = RandomNumberGenerator.new()
	jitter.seed = seed_value
	var scale: Vector3 = Vector3(jitter.randf_range(0.9, 1.25), jitter.randf_range(0.65, 0.95), jitter.randf_range(0.9, 1.25)) * radius
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i: int in index:
		var v: Vector3 = verts[i]
		# El corrimiento depende de la dirección del vértice, así los bordes repetidos de la esfera coinciden.
		var key: int = hash(Vector3i((v * 40.0).round())) ^ seed_value
		var local_jitter: RandomNumberGenerator = RandomNumberGenerator.new()
		local_jitter.seed = key
		st.add_vertex(v * scale * local_jitter.randf_range(0.78, 1.18))
	st.generate_normals()
	return st.commit()
