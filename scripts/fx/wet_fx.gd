class_name WetFx
extends Node3D
## Sensación de lluvia fría pegada al cuerpo: gotas rápidas que pasan frente a la cara,
## bruma helada que flota y el vaho del aliento. Todo sigue a la cámara del jugador.
## No toca la lluvia grande del barco: la complementa.

var camera: Camera3D
var amount_drops: int = 260
var drop_alpha: float = 0.34
var drop_length: float = 0.38
var mist_amount: int = 36
var mist_alpha: float = 0.05
var breath_interval: float = 3.4

var _drops: CPUParticles3D
var _mist: CPUParticles3D
var _breath: CPUParticles3D
var _breath_timer: float = 0.0
var _enabled: bool = true
var _boost: float = 0.0


func _ready() -> void:
	assert(camera != null, "WetFx: falta la cámara")
	top_level = true
	_drops = _make_drops()
	_mist = _make_mist()
	_breath = _make_breath()
	add_child(_drops)
	add_child(_mist)
	add_child(_breath)
	_breath_timer = breath_interval * 0.5


## Prende o apaga todo (por ejemplo bajo el agua o lejos del barco).
func set_enabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	_drops.emitting = value
	_mist.emitting = value
	if not value:
		_breath.emitting = false


## Con los rayos las gotas se ven más (0..1).
func set_flash(level: float) -> void:
	_boost = level


func _process(delta: float) -> void:
	if camera == null:
		return
	global_position = camera.global_position
	var mat: StandardMaterial3D = _drops.material_override as StandardMaterial3D
	var c: Color = mat.albedo_color
	c.a = clampf(drop_alpha + _boost * 0.4, 0.0, 1.0)
	mat.albedo_color = c
	if not _enabled:
		return
	_breath_timer -= delta
	if _breath_timer <= 0.0:
		_breath_timer = breath_interval
		# El vaho sale de adelante y un poco abajo de la cámara.
		_breath.global_position = camera.global_position + camera.global_transform.basis * Vector3(0.0, -0.18, -0.35)
		_breath.restart()
		_breath.emitting = true


func _make_drops() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "NearDrops"
	p.amount = amount_drops
	p.lifetime = 0.55
	p.preprocess = 0.6
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.007, drop_length, 0.007)
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.72, 0.8, 0.9, drop_alpha)
	mat.no_depth_test = false
	p.material_override = mat
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	# Una caja alrededor y por encima de la cabeza: caen cruzando el campo visual.
	p.emission_box_extents = Vector3(2.6, 0.2, 2.6)
	p.position = Vector3(0.0, 2.6, 0.0)
	p.particle_flag_align_y = true
	p.direction = Vector3(0.6, -1.0, 0.06)
	p.spread = 4.0
	p.gravity = Vector3(0.0, -10.0, 0.0)
	p.initial_velocity_min = 9.0
	p.initial_velocity_max = 14.0
	return p


func _make_mist() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "ColdMist"
	p.amount = mist_amount
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(3.5, 3.5)
	p.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = _soft_dot()
	mat.albedo_color = Color(0.6, 0.72, 0.85, mist_alpha)
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(7.0, 1.2, 7.0)
	p.direction = Vector3(1.0, 0.0, 0.2)
	p.spread = 30.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.4
	# Aparece y se disuelve suave.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 1))
	ramp.add_point(0.7, Color(1, 1, 1, 1))
	p.color_ramp = ramp
	return p


func _make_breath() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Breath"
	p.amount = 10
	p.lifetime = 1.4
	p.one_shot = true
	p.explosiveness = 0.5
	p.emitting = false
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(0.28, 0.28)
	p.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = _soft_dot()
	mat.albedo_color = Color(0.85, 0.9, 1.0, 0.16)
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	p.direction = Vector3(0.0, 0.25, -1.0)
	p.spread = 25.0
	p.gravity = Vector3(0.0, 0.25, 0.0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.7
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.8
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.25, Color(1, 1, 1, 1))
	p.color_ramp = ramp
	return p


## Punto suave (radial) para la bruma y el vaho, sin depender de un archivo.
func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t
