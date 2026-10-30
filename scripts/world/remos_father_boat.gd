class_name RemosFatherBoat
extends Node3D
## El bote del padre. Va por delante siguiendo el camino del RowCourse, con el farol prendido en la proa.
## Si el hijo se queda atrás, frena y lo espera; si lo alcanza, acelera un poco. Nunca se pierde de vista del todo.
## El casco, el padre, los remos y el farol se arman por código (provisorio hasta tener el modelo).

## Empezó o dejó de esperar al hijo.
signal waiting_changed(is_waiting: bool)
## Hizo una remada (para sonidos o efectos).
signal stroke_started

@export var settings: FatherBoatSettings
@export var course: RowCourse
@export var water: LakeWater
## El bote del hijo: el padre lo mira para saber cuánto lo está esperando.
@export var follow_target: RemosBoat
@export_group("Sonidos")
@export var dip_sounds: Array[AudioStream] = []
@export var pull_sounds: Array[AudioStream] = []
@export var creak_sounds: Array[AudioStream] = []
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var sfx_volume_db: float = -1.0

## Distancia recorrida por el camino.
var progress: float = 0.0
## Cuánto se corre hacia la derecha del camino (para pescar al lado del hijo). 0 = sobre el camino.
var lateral_offset: float = 0.0
## Caña de pescar del padre.
var rod: RemosFishingRod
var speed: float = 0.0
## Mientras está en verdadero, el padre no avanza (espera a que el hijo despierte, o el evento de la ola).
var holding: bool = true
## Cuántos metros le lleva al hijo (positivo = el padre va adelante).
var gap: float = 0.0
var is_waiting: bool = false

var _lantern_light: OmniLight3D
var _glow: MeshInstance3D
var _oars: Array[Node3D] = []
var _oar_u: Array[float] = [-1.0, -1.0]
var _next_side: int = 0
var _stroke_timer: float = 0.0
var _time: float = 0.0
var _pitch: float = 0.0
var _roll: float = 0.0
var _sfx: AudioStreamPlayer3D
var _torso: Node3D


func _ready() -> void:
	assert(settings != null and course != null, "RemosFatherBoat: faltan el FatherBoatSettings y el RowCourse")
	_build_visuals()
	progress = settings.start_ahead
	_place(0.0)


## Empieza a remar hacia la cabaña.
func start_leading() -> void:
	holding = false


## Se queda quieto, esperando.
func hold() -> void:
	holding = true


func get_lantern_position() -> Vector3:
	return _lantern_light.global_position if _lantern_light != null else global_position


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_time += delta
	var player_progress: float = 0.0
	if follow_target != null:
		player_progress = course.progress_of(follow_target.plane_position())
	gap = progress - player_progress
	var storm: float = water.storm if water != null else 0.0
	var base: float = lerpf(settings.calm_speed, settings.storm_speed, storm)
	var target: float = base
	if holding:
		target = 0.0
	elif gap > settings.far_gap:
		target = lerpf(base, settings.wait_speed, clampf((gap - settings.far_gap) / (settings.far_gap * 0.5), 0.0, 1.0))
	elif gap < settings.near_gap:
		target = base * settings.catch_up_factor
	speed = move_toward(speed, target, settings.acceleration * delta)
	progress = clampf(progress + speed * delta, 0.0, course.length)
	var waiting_now: bool = not holding and gap > settings.far_gap
	if waiting_now != is_waiting:
		is_waiting = waiting_now
		waiting_changed.emit(is_waiting)
	_place(delta)
	_row(delta)
	_flicker()


func _place(delta: float) -> void:
	var p: Vector2 = course.point_at(progress)
	var tangent: Vector2 = course.tangent_at(progress)
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	p += normal * (sin(_time * 0.45 + 1.3) * settings.sway + lateral_offset)
	var yaw: float = atan2(-tangent.x, -tangent.y)
	rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-3.0 * maxf(delta, 0.016)))
	var h: float = 0.0
	if water != null:
		var fwd: Vector2 = Vector2(-sin(rotation.y), -cos(rotation.y))
		var right: Vector2 = Vector2(cos(rotation.y), -sin(rotation.y))
		h = water.height_at(p.x, p.y)
		var hb: float = water.height_at(p.x + fwd.x * 1.9, p.y + fwd.y * 1.9)
		var hs: float = water.height_at(p.x - fwd.x * 1.6, p.y - fwd.y * 1.6)
		var hr: float = water.height_at(p.x + right.x * 0.7, p.y + right.y * 0.7)
		var hl: float = water.height_at(p.x - right.x * 0.7, p.y - right.y * 0.7)
		var follow: float = 1.0 - exp(-5.0 * maxf(delta, 0.016))
		_pitch = lerpf(_pitch, clampf(atan2(hb - hs, 3.5), -0.25, 0.25) * settings.wave_follow, follow)
		_roll = lerpf(_roll, clampf(atan2(hr - hl, 1.4), -0.25, 0.25) * settings.wave_follow, follow)
	rotation.x = _pitch
	rotation.z = _roll
	global_position = Vector3(p.x, h * settings.wave_follow - 0.05, p.y)


func _row(delta: float) -> void:
	var moving: bool = speed > 0.3
	var interval: float = settings.stroke_interval * (1.0 if moving else 2.4)
	_stroke_timer += delta
	if _stroke_timer >= interval and (moving or is_waiting or holding):
		_stroke_timer = 0.0
		if moving:
			_oar_u[_next_side] = 0.0
			_play(creak_sounds, -12.0)
			get_tree().create_timer(0.1).timeout.connect(func() -> void: _play(dip_sounds, -2.0))
			get_tree().create_timer(0.18).timeout.connect(func() -> void: _play(pull_sounds, -9.0))
			stroke_started.emit()
		_next_side = 1 - _next_side
	for i: int in 2:
		var side: float = -1.0 if i == 0 else 1.0
		var a: float = 0.2
		var lift: float = 0.1
		var u: float = _oar_u[i]
		if u >= 0.0:
			u += delta / 0.55
			if u >= 1.0:
				u = -1.0
			_oar_u[i] = u
			if u >= 0.0:
				if u < 0.12:
					a = lerpf(0.2, 1.0, u / 0.12)
					lift = lerpf(0.1, -0.33, u / 0.12)
				elif u < 0.62:
					a = lerpf(1.0, -1.0, smoothstep(0.0, 1.0, (u - 0.12) / 0.5))
					lift = -0.33
				else:
					var k: float = smoothstep(0.0, 1.0, (u - 0.62) / 0.38)
					a = lerpf(-1.0, 0.2, k)
					lift = lerpf(-0.33, 0.1, k)
		_oars[i].rotation = Vector3(0.0, side * a * 0.66, side * lift)
	if _torso != null:
		_torso.rotation.x = sin(_time * 2.2) * 0.03


func _flicker() -> void:
	if _lantern_light != null:
		_lantern_light.light_energy = settings.lantern_energy * (1.0 + 0.1 * sin(_time * 8.0) + 0.07 * sin(_time * 21.0))


func _play(pool: Array[AudioStream], offset_db: float) -> void:
	if pool.is_empty():
		return
	var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	p.stream = pool[randi() % pool.size()]
	p.volume_db = sfx_volume_db + offset_db
	p.pitch_scale = randf_range(0.92, 1.05)
	p.unit_size = 10.0
	p.max_distance = 90.0
	_sfx.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ---------- Armado (provisorio) ----------

func _build_visuals() -> void:
	var hull: MeshInstance3D = MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = BoatHull.build(4.6, 1.6, 0.64)
	var hm: StandardMaterial3D = _mat(Color(0.2, 0.14, 0.09), 0.9)
	hm.cull_mode = BaseMaterial3D.CULL_DISABLED
	hull.material_override = hm
	add_child(hull)
	var pale: StandardMaterial3D = _mat(Color(0.5, 0.4, 0.26), 0.85)
	var dark: StandardMaterial3D = _mat(Color(0.1, 0.09, 0.08), 0.7)
	var coat: StandardMaterial3D = _mat(Color(0.5, 0.42, 0.12), 0.7)
	var skin: StandardMaterial3D = _mat(Color(0.45, 0.32, 0.25), 0.8)
	rod = RemosFishingRod.new()
	rod.name = "RemosFishingRod"
	rod.side = 1.0
	rod.position = Vector3(0.5, 0.78, 0.2)
	add_child(rod)
	_sfx = AudioStreamPlayer3D.new()
	_sfx.name = "Sfx"
	_sfx.position = Vector3(0.0, 0.5, 0.0)
	add_child(_sfx)
	# Asiento y padre sentado, de espaldas al hijo no: mira hacia la proa, como rema el hijo.
	_add_box(self, "SeatPlank", Vector3(1.3, 0.06, 0.36), Vector3(0.0, 0.2, 0.3), pale)
	_torso = Node3D.new()
	_torso.name = "Father"
	_torso.position = Vector3(0.0, 0.45, 0.3)
	add_child(_torso)
	var body: MeshInstance3D = MeshInstance3D.new()
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = 0.95
	cap.radial_segments = 8
	cap.rings = 3
	body.mesh = cap
	body.position = Vector3(0.0, 0.35, 0.0)
	body.material_override = coat
	_torso.add_child(body)
	var head: MeshInstance3D = MeshInstance3D.new()
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.13
	sph.height = 0.26
	sph.radial_segments = 8
	sph.rings = 5
	head.mesh = sph
	head.position = Vector3(0.0, 0.98, 0.0)
	head.material_override = skin
	_torso.add_child(head)
	var hat: MeshInstance3D = MeshInstance3D.new()
	var brim: CylinderMesh = CylinderMesh.new()
	brim.top_radius = 0.2
	brim.bottom_radius = 0.2
	brim.height = 0.025
	brim.radial_segments = 10
	hat.mesh = brim
	hat.position = Vector3(0.0, 1.07, 0.0)
	hat.material_override = dark
	_torso.add_child(hat)
	var crown: MeshInstance3D = MeshInstance3D.new()
	var cr: CylinderMesh = CylinderMesh.new()
	cr.top_radius = 0.11
	cr.bottom_radius = 0.13
	cr.height = 0.14
	cr.radial_segments = 8
	crown.mesh = cr
	crown.position = Vector3(0.0, 1.14, 0.0)
	crown.material_override = dark
	_torso.add_child(crown)
	for i: int in 2:
		var side: float = -1.0 if i == 0 else 1.0
		var pivot: Node3D = Node3D.new()
		pivot.name = "Oar%s" % ("L" if i == 0 else "R")
		pivot.position = Vector3(side * 0.8, 0.5, 0.12)
		add_child(pivot)
		_oars.append(pivot)
		var shaft: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.top_radius = 0.022
		cyl.bottom_radius = 0.03
		cyl.height = 2.4
		cyl.radial_segments = 6
		shaft.mesh = cyl
		shaft.rotation = Vector3(0.0, 0.0, PI * 0.5)
		shaft.position = Vector3(side * 0.5, 0.0, 0.0)
		shaft.material_override = pale
		pivot.add_child(shaft)
		_add_box(pivot, "Blade", Vector3(0.56, 0.014, 0.2), Vector3(side * 1.46, 0.0, 0.0), pale)
	# Farol de proa en un palo corto, para que se vea de lejos.
	var mast: MeshInstance3D = MeshInstance3D.new()
	var mc: CylinderMesh = CylinderMesh.new()
	mc.top_radius = 0.02
	mc.bottom_radius = 0.03
	mc.height = 1.5
	mc.radial_segments = 5
	mast.mesh = mc
	mast.position = Vector3(0.0, 0.95, -1.85)
	mast.material_override = dark
	add_child(mast)
	var lantern: Node3D = Node3D.new()
	lantern.name = "Lantern"
	lantern.position = Vector3(0.0, 1.7, -1.85)
	add_child(lantern)
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.albedo_color = Color(1.0, 0.75, 0.4)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.65, 0.28)
	glass.emission_energy_multiplier = 3.0
	_add_box(lantern, "Glass", Vector3(0.14, 0.18, 0.14), Vector3.ZERO, glass)
	_add_box(lantern, "Cap", Vector3(0.18, 0.03, 0.18), Vector3(0.0, 0.11, 0.0), dark)
	_lantern_light = OmniLight3D.new()
	_lantern_light.name = "LanternLight"
	_lantern_light.light_color = Color(1.0, 0.7, 0.4)
	_lantern_light.light_energy = settings.lantern_energy
	_lantern_light.omni_range = settings.lantern_range
	_lantern_light.omni_attenuation = 1.2
	lantern.add_child(_lantern_light)
	_glow = MeshInstance3D.new()
	_glow.name = "Glow"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * settings.glow_size
	_glow.mesh = quad
	var gm: StandardMaterial3D = StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	gm.fixed_size = true
	gm.disable_fog = true
	gm.albedo_texture = _glow_texture()
	gm.albedo_color = Color(1.0, 0.72, 0.4, 0.9)
	gm.render_priority = 5
	_glow.material_override = gm
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lantern.add_child(_glow)


func _glow_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


func _add_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> void:
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
