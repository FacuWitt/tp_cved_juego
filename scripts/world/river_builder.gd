@tool
class_name RiverBuilder
extends Node3D
## Arma el terreno del lago y del río a partir del cauce (RiverFlow): las dos orillas con su
## colisión, los árboles y la espuma de los rápidos. Todo se genera al abrir la escena,
## así que para cambiar la forma se mueven los puntos de la curva del cauce o sus anchos.
## Es @tool: se ve en el editor.

@export var river: RiverFlow:
	set(value):
		river = value
		_queue_build()
## Distancia entre cortes de la orilla (más chico = más prolijo y más pesado).
@export_range(0.5, 10.0, 0.5, "suffix:m") var step: float = 2.0
## Hasta dónde llega el terreno hacia afuera de cada orilla.
@export_range(5.0, 120.0, 1.0, "suffix:m") var land_reach: float = 55.0
## Altura de las lomas al final del terreno (tapan el horizonte).
@export_range(1.0, 30.0, 0.5, "suffix:m") var hill_height: float = 6.0
@export var snow_color: Color = Color(0.78, 0.81, 0.86)
@export var rock_color: Color = Color(0.16, 0.16, 0.17)
## Árboles por cada 10 m de orilla (de cada lado).
@export_range(0.0, 10.0, 0.1) var tree_density: float = 2.6
@export var tree_seed: int = 11
@export var rebuild: bool = false:
	set(value):
		rebuild = false
		_queue_build()

var _pending: bool = false

const ORDER_RIGHT: Array[int] = [0, 1, 2, 0, 2, 3]
const ORDER_LEFT: Array[int] = [0, 2, 1, 0, 3, 2]


func _ready() -> void:
	_build()


func _queue_build() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	_build.call_deferred()


func _build() -> void:
	_pending = false
	for child: Node in get_children():
		if String(child.name).begins_with("_G"):
			child.queue_free()
	if river == null or river.curve == null or river.get_length() < 1.0:
		return
	_build_banks()
	_build_trees()
	_build_foam()


## Corte de la orilla de un lado: puntos (distancia al centro, altura) de adentro hacia afuera.
func _profile(half_width: float) -> Array[Vector2]:
	return [
		Vector2(half_width - 0.8, -1.4),
		Vector2(half_width + 0.3, 0.3),
		Vector2(half_width + 2.2, 0.85),
		Vector2(half_width + 7.0, 1.15),
		Vector2(half_width + land_reach * 0.4, 1.9),
		Vector2(half_width + land_reach, hill_height),
	]


## Altura del terreno a esa distancia del centro del cauce (la misma forma que las orillas).
func _ground_height(distance: float, half_width: float) -> float:
	var prof: Array[Vector2] = _profile(half_width)
	for i: int in prof.size() - 1:
		if distance <= prof[i + 1].x:
			var k: float = inverse_lerp(prof[i].x, prof[i + 1].x, distance)
			return lerpf(prof[i].y, prof[i + 1].y, clampf(k, 0.0, 1.0))
	return prof[prof.size() - 1].y


func _build_banks() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length: float = river.get_length()
	var count: int = int(ceil(length / step))
	var rows: Array = []   # por cada corte: [izquierda: Array[Vector3], derecha: Array[Vector3]]
	for i: int in count + 1:
		var s: float = minf(float(i) * step, length)
		var center: Vector3 = river.to_local(river.point_at(s))
		center.y = 0.0
		var t: Vector3 = river.tangent_at(s)
		# Izquierda mirando río abajo.
		var left: Vector3 = Vector3(t.z, 0.0, -t.x)
		var prof: Array[Vector2] = _profile(river.width_at(s) * 0.5)
		var l_pts: Array[Vector3] = []
		var r_pts: Array[Vector3] = []
		for p: Vector2 in prof:
			l_pts.append(center + left * p.x + Vector3.UP * p.y)
			r_pts.append(center - left * p.x + Vector3.UP * p.y)
		rows.append([l_pts, r_pts])
	for i: int in rows.size() - 1:
		for side: int in 2:
			var a: Array[Vector3] = rows[i][side]
			var b: Array[Vector3] = rows[i + 1][side]
			for k: int in a.size() - 1:
				var c_in: Color = rock_color if k == 0 else snow_color.darkened(0.12 * float(k >= 4))
				var c_out: Color = rock_color if k == 0 else snow_color
				if k == 1:
					c_in = rock_color.lerp(snow_color, 0.5)
				var quad: Array[Vector3] = [a[k], a[k + 1], b[k + 1], b[k]]
				var cols: Array[Color] = [c_in, c_out, c_out, c_in]
				# El orden de los vértices depende del lado para que la cara mire hacia arriba.
				var order: Array[int] = ORDER_RIGHT if side == 1 else ORDER_LEFT
				for idx: int in order:
					st.set_color(cols[idx])
					st.set_uv(Vector2(quad[idx].x, quad[idx].z) * 0.2)
					st.add_vertex(quad[idx])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.name = "_GBanks"
	inst.mesh = mesh
	inst.material_override = mat
	add_child(inst)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "_GBanksBody"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	# Pared vertical invisible en el borde del agua: el bote rebota de costado en vez de
	# trepar por la pendiente de la orilla.
	var wall: CollisionShape3D = CollisionShape3D.new()
	wall.shape = _build_wall_shape(rows)
	body.add_child(wall)
	add_child(body)


func _build_wall_shape(rows: Array) -> ConcavePolygonShape3D:
	var faces: PackedVector3Array = PackedVector3Array()
	for i: int in rows.size() - 1:
		for side: int in 2:
			var a: Array[Vector3] = rows[i][side]
			var b: Array[Vector3] = rows[i + 1][side]
			# Entre el punto sumergido y el del borde: una pared que sube recta.
			var a_base: Vector3 = (a[0] + a[1]) * 0.5
			var b_base: Vector3 = (b[0] + b[1]) * 0.5
			var low: Vector3 = Vector3.DOWN * 1.5
			var high: Vector3 = Vector3.UP * 1.8
			var q: Array[Vector3] = [Vector3(a_base.x, 0.0, a_base.z) + low, Vector3(b_base.x, 0.0, b_base.z) + low,
				Vector3(b_base.x, 0.0, b_base.z) + high, Vector3(a_base.x, 0.0, a_base.z) + high]
			faces.append_array(PackedVector3Array([q[0], q[1], q[2], q[0], q[2], q[3]]))
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	return shape


func _build_trees() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = tree_seed
	var length: float = river.get_length()
	var spots: Array[Transform3D] = []
	var s: float = 0.0
	while s < length:
		for side: float in [-1.0, 1.0]:
			if rng.randf() > 0.8:
				continue
			var center: Vector3 = river.to_local(river.point_at(s))
			var t: Vector3 = river.tangent_at(s)
			var left: Vector3 = Vector3(-t.z, 0.0, t.x)
			var half: float = river.width_at(s) * 0.5
			var lateral: float = half + rng.randf_range(3.5, land_reach * 0.7)
			var pos: Vector3 = center + left * lateral * side
			pos.y = _ground_height(lateral, half) - 0.1
			var scale: float = rng.randf_range(0.8, 1.6)
			var basis: Basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale, scale * rng.randf_range(0.9, 1.3), scale))
			spots.append(Transform3D(basis, pos))
		s += 10.0 / maxf(tree_density, 0.1)
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.2
	trunk.height = 2.4
	trunk.radial_segments = 6
	var crown: CylinderMesh = CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 1.4
	crown.height = 4.2
	crown.radial_segments = 7
	var trunk_mat: StandardMaterial3D = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.15, 0.1, 0.07)
	var crown_mat: StandardMaterial3D = StandardMaterial3D.new()
	crown_mat.albedo_color = Color(0.07, 0.12, 0.1)
	crown_mat.roughness = 1.0
	_multimesh("_GTrunks", trunk, trunk_mat, spots, Vector3(0.0, 1.2, 0.0))
	_multimesh("_GCrowns", crown, crown_mat, spots, Vector3(0.0, 4.0, 0.0))


func _multimesh(node_name: String, mesh: Mesh, mat: Material, spots: Array[Transform3D], offset: Vector3) -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = spots.size()
	for i: int in spots.size():
		var tr: Transform3D = spots[i]
		mm.set_instance_transform(i, Transform3D(tr.basis, tr.origin + tr.basis * offset))
	var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inst.name = node_name
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)


## Manchas de espuma blanca sobre el agua de los rápidos.
func _build_foam() -> void:
	if river.rapids.is_empty():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = tree_seed + 5
	var spots: Array[Transform3D] = []
	for r: Vector3 in river.rapids:
		var s: float = r.x
		while s < r.y:
			var center: Vector3 = river.to_local(river.point_at(s))
			var t: Vector3 = river.tangent_at(s)
			var left: Vector3 = Vector3(-t.z, 0.0, t.x)
			var half: float = river.width_at(s) * 0.5
			for k: int in 3:
				var pos: Vector3 = center + left * rng.randf_range(-half * 0.9, half * 0.9)
				pos.y = 0.06
				var sc: float = rng.randf_range(0.6, 1.8)
				var basis: Basis = Basis(Vector3.UP, atan2(-t.x, -t.z) + rng.randf_range(-0.4, 0.4)).scaled(Vector3(sc, 1.0, sc * 2.0))
				spots.append(Transform3D(basis, pos))
			s += 1.5
	var quad: PlaneMesh = PlaneMesh.new()
	quad.size = Vector2(0.9, 0.9)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.9, 0.95, 0.55)
	_multimesh("_GFoam", quad, mat, spots, Vector3.ZERO)
