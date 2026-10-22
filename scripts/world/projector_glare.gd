class_name ProjectorGlare
extends Node3D
## Proyector del mástil hecho visible: carcasa con lente brillante, halo que siempre mira a la
## cámara y encandilamiento en pantalla cuando se lo mira de frente. Va como hijo del
## SpotLight3D del reflector (apunta hacia su -Z, así que gira junto con la luz).
## Si algo se interpone entre la cámara y la lente (la cabina, por ejemplo), no encandila.

const GLOW_SHADER: Shader = preload("res://assets/shaders/soft_glow.gdshader")
const DAZZLE_SHADER: Shader = preload("res://assets/shaders/dazzle.gdshader")

@export var settings: ShipLightsSettings
## Capa de pantalla del encandilamiento (arriba del postprocesado y la interfaz).
@export var overlay_layer: int = 8

var dazzle: float = 0.0   ## Fuerza actual del encandilamiento, 0..1 (la lee quien quiera).

var _halo_material: ShaderMaterial
var _lens_material: StandardMaterial3D
var _dazzle_material: ShaderMaterial
var _overlay: CanvasLayer
var _rect: ColorRect


func _ready() -> void:
	assert(settings != null, "ProjectorGlare: falta asignar un ShipLightsSettings")
	_build_housing()
	_build_halo()
	_build_overlay()


func _process(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var target: float = 0.0
	var screen_pos: Vector2 = Vector2(0.5, 0.5)
	var in_front: bool = false
	if camera != null and is_visible_in_tree():
		var to_cam: Vector3 = camera.global_position - global_position
		var dist: float = maxf(to_cam.length(), 0.001)
		var dir_to_light: Vector3 = -to_cam / dist
		var look: float = (-camera.global_transform.basis.z).dot(dir_to_light)
		in_front = look > 0.0
		if in_front:
			var size: Vector2 = get_viewport().get_visible_rect().size
			screen_pos = camera.unproject_position(global_position) / size
			var angle: float = rad_to_deg(acos(clampf(look, -1.0, 1.0)))
			var view_f: float = 1.0 - smoothstep(settings.glare_core_angle, settings.glare_edge_angle, angle)
			var facing: float = (-global_transform.basis.z).dot(to_cam / dist)
			var face_f: float = smoothstep(settings.facing_min, 0.95, facing)
			var dist_f: float = 1.0 - smoothstep(settings.dazzle_near, settings.dazzle_far, dist)
			target = settings.max_dazzle * view_f * face_f * dist_f
			if target > 0.001 and _is_occluded(camera):
				target = 0.0
	# Sube rápido y se recupera despacio: queda el ojo "quemado" un rato.
	var time: float = settings.dazzle_rise_time if target > dazzle else settings.dazzle_fall_time
	dazzle = move_toward(dazzle, target, delta / maxf(time, 0.01))
	_dazzle_material.set_shader_parameter("strength", dazzle)
	_dazzle_material.set_shader_parameter("tint", settings.dazzle_color)
	_dazzle_material.set_shader_parameter("center", screen_pos if in_front else Vector2(0.5, 0.5))
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_dazzle_material.set_shader_parameter("aspect", vp.x / maxf(vp.y, 1.0))
	_rect.visible = dazzle > 0.002
	_halo_material.set_shader_parameter("energy", settings.halo_energy)
	_lens_material.emission_energy_multiplier = settings.lens_energy


func _is_occluded(camera: Camera3D) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		camera.global_position, global_position)
	var excluded: Array[RID] = []
	var node: Node = camera
	while node != null:
		if node is CollisionObject3D:
			excluded.append((node as CollisionObject3D).get_rid())
		node = node.get_parent()
	query.exclude = excluded
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()


func _build_housing() -> void:
	var metal: StandardMaterial3D = StandardMaterial3D.new()
	metal.albedo_color = Color(0.13, 0.14, 0.15)
	metal.metallic = 0.7
	metal.roughness = 0.5
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Housing"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = settings.lens_radius * 1.25
	cyl.bottom_radius = settings.lens_radius * 1.1
	cyl.height = settings.housing_length
	cyl.radial_segments = 20
	body.mesh = cyl
	body.material_override = metal
	# El cilindro nace vertical: se acuesta para mirar hacia -Z, con la boca al frente.
	body.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5),
		Vector3(0.0, 0.0, settings.housing_length * 0.5 - 0.05))
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)

	_lens_material = StandardMaterial3D.new()
	_lens_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lens_material.albedo_color = Color(1.0, 0.97, 0.88)
	_lens_material.emission_enabled = true
	_lens_material.emission = Color(1.0, 0.96, 0.85)
	_lens_material.emission_energy_multiplier = settings.lens_energy
	var lens: MeshInstance3D = MeshInstance3D.new()
	lens.name = "Lens"
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = settings.lens_radius
	disc.bottom_radius = settings.lens_radius
	disc.height = 0.04
	disc.radial_segments = 24
	lens.mesh = disc
	lens.material_override = _lens_material
	lens.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, 0.0, -0.06))
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lens)


func _build_halo() -> void:
	_halo_material = ShaderMaterial.new()
	_halo_material.shader = GLOW_SHADER
	_halo_material.set_shader_parameter("glow_color", Color(1.0, 0.95, 0.82))
	_halo_material.set_shader_parameter("energy", settings.halo_energy)
	_halo_material.set_shader_parameter("rect_mix", 0.0)
	_halo_material.set_shader_parameter("falloff", 2.6)
	_halo_material.set_shader_parameter("billboard", 1.0)
	_halo_material.render_priority = 3
	var quad: MeshInstance3D = MeshInstance3D.new()
	quad.name = "Halo"
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(settings.halo_size, settings.halo_size)
	quad.mesh = mesh
	quad.material_override = _halo_material
	quad.position = Vector3(0.0, 0.0, -0.12)
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(quad)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "DazzleLayer"
	_overlay.layer = overlay_layer
	_dazzle_material = ShaderMaterial.new()
	_dazzle_material.shader = DAZZLE_SHADER
	_rect = ColorRect.new()
	_rect.name = "Dazzle"
	_rect.material = _dazzle_material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	_overlay.add_child(_rect)
	add_child(_overlay)
