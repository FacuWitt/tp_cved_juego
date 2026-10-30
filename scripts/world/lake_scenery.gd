class_name LakeScenery
extends Node3D
## El paisaje alrededor del lago: lomas oscuras en el horizonte (acompañan al bote, como un fondo lejano)
## y la cabaña con su muelle al final del recorrido, con las ventanas encendidas: la meta que se ve de lejos.
## Todo se arma por código (provisorio hasta tener los modelos).

@export var course: RowCourse
## A quién acompañan las lomas.
@export var target: Node3D
@export_range(100.0, 600.0, 5.0, "suffix:m") var hills_radius: float = 290.0
@export_range(5.0, 150.0, 1.0, "suffix:m") var hills_height: float = 55.0
@export var hills_color: Color = Color(0.025, 0.032, 0.04)
@export var window_color: Color = Color(1.0, 0.68, 0.32)

var _hills: MeshInstance3D
var _cabin_light: OmniLight3D
var _time: float = 0.0


func _ready() -> void:
	assert(course != null and target != null, "LakeScenery: faltan el recorrido y el objetivo")
	_build_hills()
	_build_cabin()


func _process(delta: float) -> void:
	_time += delta
	if _hills != null:
		_hills.global_position = Vector3(target.global_position.x, -3.0, target.global_position.z)
	if _cabin_light != null:
		_cabin_light.light_energy = 2.2 * (1.0 + 0.06 * sin(_time * 6.0) + 0.04 * sin(_time * 17.0))


func _build_hills() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var segments: int = 72
	var inner: float = hills_radius
	var outer: float = hills_radius + 90.0
	var tops: Array[float] = []
	var base_h: float = 0.0
	for i: int in segments:
		base_h = clampf(base_h + rng.randf_range(-0.28, 0.28), 0.2, 1.0)
		tops.append(base_h * hills_height * rng.randf_range(0.6, 1.1))
	for i: int in segments:
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float((i + 1) % segments) / float(segments)
		var h0: float = tops[i]
		var h1: float = tops[(i + 1) % segments]
		var p_in0: Vector3 = Vector3(cos(a0) * inner, 0.0, sin(a0) * inner)
		var p_in1: Vector3 = Vector3(cos(a1) * inner, 0.0, sin(a1) * inner)
		var p_top0: Vector3 = Vector3(cos(a0) * (inner + 25.0), h0, sin(a0) * (inner + 25.0))
		var p_top1: Vector3 = Vector3(cos(a1) * (inner + 25.0), h1, sin(a1) * (inner + 25.0))
		var p_out0: Vector3 = Vector3(cos(a0) * outer, 4.0, sin(a0) * outer)
		var p_out1: Vector3 = Vector3(cos(a1) * outer, 4.0, sin(a1) * outer)
		_tri(st, p_in0, p_top0, p_top1)
		_tri(st, p_in0, p_top1, p_in1)
		_tri(st, p_top0, p_out0, p_out1)
		_tri(st, p_top0, p_out1, p_top1)
	st.generate_normals()
	_hills = MeshInstance3D.new()
	_hills.name = "Hills"
	_hills.mesh = st.commit()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = hills_color
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hills.material_override = mat
	_hills.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hills.top_level = true
	add_child(_hills)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _build_cabin() -> void:
	var pos2: Vector2 = course.cabin_position()
	var back: Vector2 = course.tangent_at(course.length)
	var root: Node3D = Node3D.new()
	root.name = "Cabin"
	add_child(root)
	root.global_position = Vector3(pos2.x, 0.0, pos2.y)
	# Su +Z apunta tierra adentro (hacia donde va el bote); el muelle sale hacia -Z, hacia el lago.
	root.rotation.y = atan2(back.x, back.y)
	var wood: StandardMaterial3D = _mat(Color(0.16, 0.1, 0.06), 0.95)
	var roof: StandardMaterial3D = _mat(Color(0.08, 0.07, 0.07), 0.9)
	var ground: StandardMaterial3D = _mat(Color(0.03, 0.04, 0.035), 1.0)
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.albedo_color = window_color
	glow.emission_enabled = true
	glow.emission = window_color
	glow.emission_energy_multiplier = 3.2
	_box(root, "Shore", Vector3(70.0, 3.0, 36.0), Vector3(0.0, -0.4, 22.0), ground)
	_box(root, "Walls", Vector3(7.0, 3.2, 5.5), Vector3(0.0, 1.6, 12.0), wood)
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(8.2, 1.9, 6.6)
	var roof_node: MeshInstance3D = MeshInstance3D.new()
	roof_node.name = "Roof"
	roof_node.mesh = roof_mesh
	roof_node.position = Vector3(0.0, 4.15, 12.0)
	roof_node.material_override = roof
	root.add_child(roof_node)
	# Ventanas y puerta hacia el lago (el frente apunta a -Z).
	_box(root, "WindowL", Vector3(1.3, 1.0, 0.1), Vector3(-2.0, 1.9, 9.2), glow)
	_box(root, "WindowR", Vector3(1.3, 1.0, 0.1), Vector3(2.0, 1.9, 9.2), glow)
	_box(root, "Door", Vector3(1.0, 2.0, 0.1), Vector3(0.0, 1.0, 9.2), _mat(Color(0.05, 0.03, 0.02), 1.0))
	# Muelle.
	for i: int in 8:
		_box(root, "Plank%d" % i, Vector3(2.0, 0.12, 0.6), Vector3(0.0, 0.05, 8.2 - float(i) * 0.75), wood)
	for i: int in 4:
		_box(root, "PostL%d" % i, Vector3(0.14, 1.2, 0.14), Vector3(-1.0, -0.2, 8.0 - float(i) * 1.7), wood)
		_box(root, "PostR%d" % i, Vector3(0.14, 1.2, 0.14), Vector3(1.0, -0.2, 8.0 - float(i) * 1.7), wood)
	_cabin_light = OmniLight3D.new()
	_cabin_light.name = "CabinLight"
	_cabin_light.light_color = Color(1.0, 0.7, 0.38)
	_cabin_light.light_energy = 2.2
	_cabin_light.omni_range = 38.0
	_cabin_light.omni_attenuation = 1.1
	_cabin_light.position = Vector3(0.0, 2.5, 7.4)
	root.add_child(_cabin_light)
	# Resplandor de lejos, visible aunque haya niebla.
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.name = "Halo"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * 0.16
	halo.mesh = quad
	var hm: StandardMaterial3D = StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.fixed_size = true
	hm.disable_fog = true
	hm.albedo_texture = _soft()
	hm.albedo_color = Color(1.0, 0.7, 0.36, 0.85)
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(0.0, 2.0, 8.8)
	root.add_child(halo)


func _soft() -> Texture2D:
	var g: Gradient = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
	var t: GradientTexture2D = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func _box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m
