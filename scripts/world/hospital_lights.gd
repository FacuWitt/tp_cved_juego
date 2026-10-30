class_name HospitalLights
extends Node3D
## Las luces del hospital que se cuelan en el recuerdo: 6 paneles en el cielo que solo se ven
## mientras el rayo ilumina. Por defecto están arriba de la cabeza, como un techo (columnas a
## los costados, filas a lo largo del eje Z del mundo); también pueden ponerse en la dirección
## de donde viene el rayo. Siguen a la cámara: están "en el cielo", nunca se llega a ellas.
## Los paneles se arman por código (nombres "_G") y no se guardan en la escena.

const PANEL_SHADER: Shader = preload("res://assets/shaders/hospital_light.gdshader")

@export var settings: HospitalLightsSettings
@export var lightning: LightningController

var _material: ShaderMaterial
var _panels: Array[MeshInstance3D] = []
var _active: bool = false


func _ready() -> void:
	assert(settings != null and lightning != null, "HospitalLights: faltan el HospitalLightsSettings y el LightningController")
	_material = ShaderMaterial.new()
	_material.shader = PANEL_SHADER
	_material.render_priority = 1
	_build()
	lightning.flashed.connect(_on_flashed)
	if settings.hide_sun_disc:
		lightning.light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	visible = false


## Arma los paneles en una grilla centrada, en el plano XY del nodo (mirando a su +Z).
func _build() -> void:
	for panel: MeshInstance3D in _panels:
		panel.queue_free()
	_panels.clear()
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = settings.panel_size
	var cols: int = settings.columns
	var rows: int = settings.rows
	for r: int in rows:
		for c: int in cols:
			var panel: MeshInstance3D = MeshInstance3D.new()
			panel.name = "_GPanel%d" % _panels.size()
			panel.mesh = mesh
			panel.material_override = _material
			panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			panel.extra_cull_margin = 1000.0
			panel.position = Vector3(
				(float(c) - float(cols - 1) * 0.5) * settings.spacing.x,
				(float(rows - 1) * 0.5 - float(r)) * settings.spacing.y,
				0.0)
			add_child(panel)
			_panels.append(panel)


func _on_flashed(_strength: float) -> void:
	if lightning.in_long_flash and not settings.show_on_long_flash:
		_active = false
		return
	_active = randf() < settings.chance_per_flash


func _process(_delta: float) -> void:
	var level: float = lightning.get_level()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not _active or camera == null or not lightning.is_sky_visible() or level <= settings.threshold:
		visible = false
		return
	var k: float = pow(inverse_lerp(settings.threshold, 1.0, level), settings.flash_curve)
	_material.set_shader_parameter("light_color", settings.color)
	_material.set_shader_parameter("energy", settings.energy)
	_material.set_shader_parameter("opacity", settings.max_opacity * k)
	_material.set_shader_parameter("softness", settings.edge_softness)
	var cam_pos: Vector3 = camera.global_position
	if settings.placement == HospitalLightsSettings.Placement.OVERHEAD:
		# Plano horizontal arriba: el +Z del nodo apunta hacia abajo (a la cámara), las columnas
		# quedan en X y las filas en Z.
		global_transform = Transform3D(Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), cam_pos + Vector3.UP * settings.distance)
	else:
		# La luz direccional alumbra hacia su -Z: el rayo "viene" de su +Z.
		var source_dir: Vector3 = lightning.light.global_basis.z.normalized()
		global_position = cam_pos + source_dir * settings.distance
		var up: Vector3 = Vector3.UP if absf(source_dir.y) < 0.98 else Vector3.FORWARD
		look_at(cam_pos + (global_position - cam_pos) * 2.0, up)
	visible = true
