@tool
class_name ShipWindowGlow
extends Node3D
## Brillo cálido en las ventanas de la cabina.
## Cada ventana es un nodo hijo (Node3D) de este nodo: lo movés con el gizmo en el editor y el
## brillo se mueve con él. Por cada hijo se arma un rectángulo luminoso y un halo, que son
## generados por código (nombres que empiezan con "_G") y no se guardan en la escena.
## Es @tool: se ve en el editor sin correr el juego.

const GLOW_SHADER: Shader = preload("res://assets/shaders/soft_glow.gdshader")
const GEN_PREFIX: String = "_G"

@export var settings: ShipLightsSettings:
	set(value):
		if settings != null and settings.changed.is_connected(_rebuild):
			settings.changed.disconnect(_rebuild)
		settings = value
		if settings != null and not settings.changed.is_connected(_rebuild):
			settings.changed.connect(_rebuild)
		_rebuild()

var _materials: Array[ShaderMaterial] = []
var _halo_materials: Array[ShaderMaterial] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


func _ready() -> void:
	if not child_entered_tree.is_connected(_on_child_changed):
		child_entered_tree.connect(_on_child_changed)
		child_exiting_tree.connect(_on_child_changed)
	if not Engine.is_editor_hint():
		assert(settings != null, "ShipWindowGlow: falta asignar un ShipLightsSettings")
	_rebuild()


func _process(delta: float) -> void:
	if settings == null:
		return
	_time += delta
	for i in _materials.size():
		# Titileo de lámpara vieja: dos senos desfasados por ventana.
		var t: float = _time * settings.window_flicker_speed + _phases[i]
		var f: float = 1.0 - settings.window_flicker * (0.5 + 0.5 * sin(t) * sin(t * 0.37 + 1.3))
		_apply_one(i, f)


func _on_child_changed(node: Node) -> void:
	if node.name.begins_with(GEN_PREFIX):
		return
	call_deferred("_rebuild")


## Arma el brillo de cada ventana (cada hijo que no sea generado).
func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if String(child.name).begins_with(GEN_PREFIX):
			child.queue_free()
	_materials.clear()
	_halo_materials.clear()
	_phases.clear()
	if settings == null:
		return
	var index: int = 0
	for child in get_children():
		if not child is Node3D or String(child.name).begins_with(GEN_PREFIX):
			continue
		var main: ShaderMaterial = _make_material(settings.window_color, 1.0, 2.0)
		_add_quad(child, Vector3.ZERO, settings.window_size, main, GEN_PREFIX + "Win%d" % index)
		var halo: ShaderMaterial = _make_material(settings.window_color, 0.0, 2.2)
		_add_quad(child, Vector3(0.0, 0.0, 0.04), settings.window_size * settings.window_halo_scale,
			halo, GEN_PREFIX + "Halo%d" % index)
		_materials.append(main)
		_halo_materials.append(halo)
		_phases.append(randf() * 100.0)
		_apply_one(index, 1.0)
		index += 1


func _apply_one(i: int, factor: float) -> void:
	_materials[i].set_shader_parameter("energy", settings.window_energy * factor)
	_materials[i].set_shader_parameter("glow_color", settings.window_color)
	_halo_materials[i].set_shader_parameter("energy", settings.window_halo_energy * factor)
	_halo_materials[i].set_shader_parameter("glow_color", settings.window_color)


func _make_material(color: Color, rect_mix: float, falloff: float) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GLOW_SHADER
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("rect_mix", rect_mix)
	mat.set_shader_parameter("falloff", falloff)
	mat.render_priority = 2
	return mat


func _add_quad(parent: Node3D, pos: Vector3, size: Vector2, mat: ShaderMaterial, node_name: String) -> void:
	var quad: MeshInstance3D = MeshInstance3D.new()
	quad.name = node_name
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = size
	quad.mesh = mesh
	quad.material_override = mat
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = pos
	parent.add_child(quad)
