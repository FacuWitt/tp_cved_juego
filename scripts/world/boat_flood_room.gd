class_name BoatFloodRoom
extends InterludeRoom
## Sala de los barcos (M3): el cerebro bombardea al protagonista con el símbolo que lo trae de
## vuelta. Montañas de barquitos hasta donde llega la vista, un paso angosto en S por el medio y
## barquitos que caen del cielo negro, cada vez más seguido. Sin techo: los rayos la muestran entera.
## Las montañas son un MultiMesh (se ven) sobre una malla con colisión (no se trepan); los que
## caen son cuerpos físicos que el jugador aparta al caminar (lo chocan, pero no lo frenan).

## Capa de física de los barquitos sueltos: chocan con el mundo y entre ellos; el jugador no
## los "ve", así que camina y ellos se corren.
const LOOSE_LAYER: int = 4
const GRID_CELL: float = 0.25

@export var settings: BoatFloodSettings
## El modelo del barquito (versión liviana, para poner cientos).
@export var boat_scene: PackedScene
## Material de lo que hay debajo de los barquitos (lo que se ve por los huecos): una textura de
## barcos apilados, alumbrada por las mismas luces que los barquitos.
@export var mound_material: Material
@export var knock_streams: Array[AudioStream] = []
@export var cascade_stream: AudioStream
@export var hit_stream: AudioStream

var _mesh: Mesh
## Lleva el modelo a: centrado en el origen y con 1 m de largo.
var _unit: Transform3D
var _aspect: Vector3
var _noise: FastNoiseLite
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _loose: Array[RigidBody3D] = []
var _last_knock: Dictionary = {}
var _knockers: Array[AudioStreamPlayer3D] = []
var _next_knocker: int = 0
var _cascade: AudioStreamPlayer
var _hit: AudioStreamPlayer
var _fall_wait: float = 0.0
var _flash_light: SpotLight3D
var _kick_tween: Tween


func _ready() -> void:
	assert(settings != null and boat_scene != null and entry != null and exit_portal != null, "BoatFloodRoom: faltan referencias en el Inspector")
	_rng.seed = settings.random_seed
	_noise = FastNoiseLite.new()
	_noise.seed = settings.random_seed
	_noise.frequency = 0.45
	_read_model()
	_build_shell()
	_build_mounds()
	_build_boats()
	_build_lights()
	for i: int in 10:
		var knocker: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		knocker.unit_size = 4.0
		knocker.max_distance = 40.0
		add_child(knocker)
		_knockers.append(knocker)
	_cascade = make_player(cascade_stream, settings.cascade_volume_start_db, true)
	_hit = make_player(hit_stream, settings.hit_volume_db)
	set_process(false)


func _room_depth() -> float:
	return settings.room_depth


func drag() -> float:
	return progress() * settings.leg_drag


func _on_entered() -> void:
	set_process(true)
	_fall_wait = settings.fall_interval_start * 0.5
	_cascade.play()
	fade_drone(settings.drone_volume_db, 2.0)
	set_ambient(settings.ambient)
	if lightning != null:
		_reveal()


func _on_left() -> void:
	set_process(false)
	_flash_light.light_energy = 0.0
	var t: Tween = create_tween()
	t.tween_property(_cascade, "volume_db", -60.0, 1.5)
	t.tween_callback(_cascade.stop)
	t.tween_callback(_clear_loose)


## El primer rayo largo: deja ver la sala entera.
func _reveal() -> void:
	await get_tree().create_timer(settings.reveal_delay).timeout
	if is_active:
		lightning.long_flash(settings.reveal_duration)


func _process(delta: float) -> void:
	var k: float = progress()
	_cascade.volume_db = lerpf(settings.cascade_volume_start_db, settings.cascade_volume_end_db, k)
	if lightning != null:
		_flash_light.light_energy = lightning.get_level() * settings.flash_energy
	_fall_wait -= delta
	if _fall_wait <= 0.0:
		_fall_wait = lerpf(settings.fall_interval_start, settings.fall_interval_end, k) * _rng.randf_range(0.7, 1.3)
		_drop_boat()
		if k >= settings.cascade_at:
			_drop_boat()


# ---------- Forma de la sala ----------

## Posición X del centro del paso según cuánto se avanzó (0..1).
func path_x(t: float) -> float:
	return settings.path_sway * sin(TAU * settings.path_curves * t)


## Altura de las montañas en un punto de la sala (0 sobre el paso).
func mound_height(x: float, z: float) -> float:
	var t: float = clampf((-STUB_FRONT - z) / settings.room_depth, 0.0, 1.0)
	var away: float = absf(x - path_x(t)) - settings.path_half_width
	if away <= 0.0:
		return 0.0
	var bump: float = (_noise.get_noise_2d(x * 3.0, z * 3.0) * 0.5 + 0.5) * settings.mound_bumps * smoothstep(0.0, 1.0, away)
	return minf(away * settings.mound_slope + bump, settings.mound_height)


func _build_shell() -> void:
	var half: float = settings.room_width * 0.5
	var z0: float = -STUB_FRONT
	var z1: float = z0 - settings.room_depth
	var h: float = settings.wall_height
	add_entry_stub()
	add_box(Vector3(0.0, -WALL * 0.5, (z0 + z1) * 0.5), Vector3(settings.room_width, WALL, settings.room_depth), floor_material)
	add_wall_z(z0 + WALL * 0.5, -half, half, h, wall_material, 0.0)
	add_wall_z(z1 - WALL * 0.5, -half, half, h, wall_material, path_x(1.0))
	for side: float in [-1.0, 1.0]:
		add_box(Vector3(side * (half + WALL * 0.5), h * 0.5, (z0 + z1) * 0.5), Vector3(WALL, h, settings.room_depth + WALL * 2.0), wall_material)
	add_exit(path_x(1.0), z1, settings.exit_glow_energy, settings.exit_glow_range)


## La malla de las montañas: se ve oscura por los huecos entre barquitos y es la colisión.
func _build_mounds() -> void:
	var half: float = settings.room_width * 0.5
	var z0: float = -STUB_FRONT
	var nx: int = ceili(settings.room_width / GRID_CELL)
	var nz: int = ceili(settings.room_depth / GRID_CELL)
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize((nx + 1) * (nz + 1))
	for j: int in nz + 1:
		for i: int in nx + 1:
			# Apenas por debajo del piso sobre el paso, para que no se pisen las dos superficies.
			heights[j * (nx + 1) + i] = mound_height(-half + i * GRID_CELL, z0 - j * GRID_CELL) - 0.03
	# La textura se despliega sobre la superficie (a lo largo de la sala y a lo largo de la pendiente),
	# una sola vez: así se ve tal cual es, sin estirarse en lo empinado ni mezclarse consigo misma.
	var across: PackedFloat32Array = PackedFloat32Array()
	across.resize((nx + 1) * (nz + 1))
	for j: int in nz + 1:
		var run: float = 0.0
		for i: int in nx + 1:
			if i > 0:
				run += Vector2(GRID_CELL, heights[j * (nx + 1) + i] - heights[j * (nx + 1) + i - 1]).length()
			across[j * (nx + 1) + i] = run
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j: int in nz:
		for i: int in nx:
			var corners: Array[int] = [j * (nx + 1) + i, j * (nx + 1) + i + 1, (j + 1) * (nx + 1) + i, (j + 1) * (nx + 1) + i + 1]
			var top: float = -1.0
			for k: int in corners:
				top = maxf(top, heights[k])
			if top <= 0.0:
				continue
			# En Godot la cara de adelante es la que se ve girar en sentido horario: en este orden
			# las caras miran hacia arriba (hacia el paso), que es desde donde se las ve y se las pisa.
			for c: int in [0, 2, 1, 1, 2, 3]:
				var k: int = corners[c]
				var col: int = k % (nx + 1)
				var row: int = k / (nx + 1)
				st.set_uv(Vector2(row * GRID_CELL / settings.fill_tile, across[k] / (settings.fill_tile * 2.0)))
				st.add_vertex(Vector3(-half + col * GRID_CELL, heights[k], z0 - row * GRID_CELL))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "_GMounds"
	instance.mesh = mesh
	instance.material_override = mound_material
	add_child(instance)
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var trimesh: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	# Por si algo llega desde abajo o desde atrás: que choque igual.
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	instance.add_child(body)


func _read_model() -> void:
	var model: Node3D = boat_scene.instantiate() as Node3D
	var found: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	assert(not found.is_empty(), "BoatFloodRoom: el modelo del barquito no tiene malla")
	var instance: MeshInstance3D = found[0] as MeshInstance3D
	_mesh = instance.mesh
	var xf: Transform3D = Transform3D.IDENTITY
	var node: Node3D = instance
	while node != null and node != model:
		xf = node.transform * xf
		node = node.get_parent() as Node3D
	var box: AABB = xf * _mesh.get_aabb()
	var length: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	_unit = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE / length), -box.get_center() / length) * xf
	_aspect = box.size / length
	model.free()


func _build_boats() -> void:
	var half: float = settings.room_width * 0.5
	var z0: float = -STUB_FRONT
	var transforms: Array[Transform3D] = []
	var tries: int = 0
	while transforms.size() < settings.boat_count and tries < settings.boat_count * 8:
		tries += 1
		var x: float = _rng.randf_range(-half, half)
		var z: float = z0 - _rng.randf_range(0.0, settings.room_depth)
		var h: float = mound_height(x, z)
		if h < 0.12:
			continue
		var length: float = lerpf(settings.boat_min_length, settings.boat_max_length, pow(_rng.randf(), settings.small_bias))
		# Cerca del paso solo entran los chicos: si no, se meten en el camino y se los atraviesa.
		var away: float = absf(x - path_x((z0 - z) / settings.room_depth)) - settings.path_half_width
		length = minf(length, away * 1.9)
		if length < settings.boat_min_length * 0.5:
			continue
		# Arriba hay menos: lo que más se mira es adelante y abajo.
		var thin: float = smoothstep(settings.dense_height, maxf(settings.mound_height, settings.dense_height + 0.1), h)
		if _rng.randf() > lerpf(1.0, settings.top_density, thin):
			continue
		# Apoyado sobre la pendiente (no hundido en ella), con el casco hacia la montaña.
		var normal: Vector3 = Vector3(
			mound_height(x - 0.15, z) - mound_height(x + 0.15, z),
			0.3,
			mound_height(x, z - 0.15) - mound_height(x, z + 0.15)).normalized()
		var side: Vector3 = normal.cross(Vector3.FORWARD).normalized()
		var lying: Basis = Basis(side, normal, side.cross(normal)).orthonormalized()
		var tilt_axis: Vector3 = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)).normalized()
		if tilt_axis == Vector3.ZERO:
			tilt_axis = Vector3.RIGHT
		var basis: Basis = lying * Basis(tilt_axis, deg_to_rad(_rng.randf_range(-settings.tilt_max, settings.tilt_max))) \
			* Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
		var origin: Vector3 = Vector3(x, h, z) + normal * length * _rng.randf_range(settings.lift_min, settings.lift_max)
		transforms.append(Transform3D(basis.scaled(Vector3.ONE * length), origin) * _unit)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _mesh
	multimesh.instance_count = transforms.size()
	for i: int in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = "_GBoats"
	instance.multimesh = multimesh
	add_child(instance)


func _build_lights() -> void:
	var z0: float = -STUB_FRONT
	for k: float in [0.3, 0.75]:
		var cold: OmniLight3D = OmniLight3D.new()
		cold.light_color = Color(0.45, 0.6, 0.7)
		cold.light_energy = settings.cold_light_energy
		cold.omni_range = settings.room_depth * 0.6
		cold.position = Vector3(path_x(k), settings.mound_height + 1.5, z0 - settings.room_depth * k)
		add_child(cold)
	# La luz del rayo, desde arriba: la del nivel viene muy de costado y las paredes la tapan.
	_flash_light = SpotLight3D.new()
	_flash_light.name = "_GFlash"
	_flash_light.light_color = Color(0.75, 0.85, 1.0)
	_flash_light.light_energy = 0.0
	_flash_light.shadow_enabled = true
	_flash_light.spot_range = 40.0
	_flash_light.spot_angle = 50.0
	_flash_light.spot_attenuation = 0.2
	_flash_light.position = Vector3(1.5, 18.0, z0 - settings.room_depth * 0.5 + 2.0)
	_flash_light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(_flash_light)


# ---------- Barquitos que caen ----------

func _drop_boat() -> void:
	if settings.max_falling <= 0:
		return
	var z0: float = -STUB_FRONT
	var local: Vector3 = to_local(player.global_position)
	var x: float
	var z: float
	if _rng.randf() < settings.overhead_chance:
		x = local.x + _rng.randf_range(-0.25, 0.25)
		z = local.z + _rng.randf_range(-0.25, 0.25)
	else:
		z = local.z - _rng.randf_range(settings.fall_ahead_min, settings.fall_ahead_max)
		z = clampf(z, z0 - settings.room_depth + 0.5, z0 - 0.5)
		x = path_x((z0 - z) / settings.room_depth) + _rng.randf_range(-settings.fall_spread, settings.fall_spread)
	var body: RigidBody3D = _take_loose()
	if body == null:
		return
	body.position = Vector3(x, settings.fall_height + _rng.randf_range(0.0, 1.5), z)
	body.rotation = Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU))
	body.linear_velocity = Vector3(0.0, -2.0, 0.0)
	body.angular_velocity = Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * settings.fall_spin
	body.sleeping = false


## Un barquito suelto para tirar: uno nuevo, o el más viejo que no se esté mirando.
func _take_loose() -> RigidBody3D:
	if _loose.size() < settings.max_falling:
		var created: RigidBody3D = _make_loose()
		_loose.append(created)
		return created
	for i: int in _loose.size():
		var old: RigidBody3D = _loose[i]
		if _camera.is_position_behind(old.global_position):
			_loose.remove_at(i)
			_loose.append(old)
			return old
	return null


func _make_loose() -> RigidBody3D:
	var length: float = _rng.randf_range(settings.fall_min_length, settings.fall_max_length)
	var body: RigidBody3D = RigidBody3D.new()
	body.collision_layer = LOOSE_LAYER
	body.collision_mask = 1 | LOOSE_LAYER
	body.mass = settings.fall_mass
	body.contact_monitor = true
	body.max_contacts_reported = 3
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = _mesh
	instance.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * length), Vector3.ZERO) * _unit
	body.add_child(instance)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	# El casco, sin el mástil: si no, quedan parados sobre la punta.
	box.size = _aspect * length * Vector3(0.9, 0.6, 0.9)
	shape.shape = box
	body.add_child(shape)
	body.set_meta("length", length)
	body.body_entered.connect(_on_loose_hit.bind(body))
	add_child(body)
	return body


func _on_loose_hit(other: Node, body: RigidBody3D) -> void:
	if not is_active:
		return
	if other is Player:
		_hit.pitch_scale = _rng.randf_range(0.9, 1.1)
		_hit.play()
		_kick_camera()
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last_knock.get(body, 0)) < 140:
		return
	_last_knock[body] = now
	var speed: float = body.linear_velocity.length()
	if speed < 0.4:
		return
	if knock_streams.is_empty():
		return
	var knocker: AudioStreamPlayer3D = _knockers[_next_knocker]
	_next_knocker = (_next_knocker + 1) % _knockers.size()
	knocker.stream = knock_streams[_rng.randi() % knock_streams.size()]
	# Los más grandes suenan más graves.
	var size_k: float = inverse_lerp(settings.fall_min_length, settings.fall_max_length, float(body.get_meta("length")))
	knocker.pitch_scale = lerpf(1.25, 0.75, clampf(size_k, 0.0, 1.0)) * _rng.randf_range(0.92, 1.08)
	knocker.volume_db = settings.knock_volume_db + linear_to_db(clampf(speed / 6.0, 0.15, 1.0))
	knocker.global_position = body.global_position
	knocker.play()


func _kick_camera() -> void:
	if settings.hit_kick <= 0.0:
		return
	if _kick_tween != null and _kick_tween.is_valid():
		_kick_tween.kill()
	_camera.v_offset = -settings.hit_kick
	_kick_tween = create_tween()
	_kick_tween.tween_property(_camera, "v_offset", 0.0, settings.hit_kick_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _clear_loose() -> void:
	for body: RigidBody3D in _loose:
		body.queue_free()
	_loose.clear()
	_last_knock.clear()
