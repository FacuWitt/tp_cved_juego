class_name WakeMessagesRoom
extends InterludeRoom
## Sala de los mensajes (M3): un cuarto vacío de la casa con una lamparita. Al entrar hay tres
## mensajes blancos, como proyectados ("despertá", "por favor", "otra vez la pesadilla").
## Mientras el jugador la cruza, aparecen más donde no está mirando: nunca se los ve aparecer,
## solo se oye el trazo a sus espaldas. Primero tranquilos, después a mano y en rojo. Pasada la
## mitad se va la luz un instante y, cuando vuelve, las paredes están cubiertas.

@export var settings: WakeMessagesSettings
## Letra de imprenta de los mensajes tranquilos.
@export var calm_font: Font
## Letra a mano de los mensajes rojos.
@export var urgent_font: Font
@export var scrawl_streams: Array[AudioStream] = []
@export var thud_stream: AudioStream

## Cada superficie donde se puede escribir: centro, ejes (derecha y arriba del texto), normal,
## medio ancho, medio alto y los huecos de puerta que hay que esquivar (Rect2 en sus ejes).
var _surfaces: Array[Dictionary] = []
var _count: int = 0
var _allowed: float = 0.0
var _check_wait: float = 0.0
var _scrawl_wait: float = 0.0
var _burst_done: bool = false
var _dark: bool = false
var _bulb: OmniLight3D
var _bulb_material: StandardMaterial3D
var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	assert(settings != null and entry != null and exit_portal != null, "WakeMessagesRoom: faltan referencias en el Inspector")
	_rng.seed = 11
	_build()
	_write_first()
	set_process(false)


func _room_depth() -> float:
	return settings.room_depth


func drag() -> float:
	return progress() * settings.leg_drag


func _on_entered() -> void:
	_allowed = float(_count)
	_check_wait = 1.5
	fade_drone(settings.drone_volume_db, 2.0)
	set_ambient(settings.ambient)
	set_process(true)


func _on_left() -> void:
	set_process(false)


func on_blink() -> void:
	if is_active:
		_write_many(settings.blink_count, true)


func _process(delta: float) -> void:
	_time += delta
	_scrawl_wait = maxf(_scrawl_wait - delta, 0.0)
	if not _dark:
		var noise: float = sin(_time * 31.0) * sin(_time * 7.3) * 0.5 + (0.5 if _rng.randf() < 0.03 else 0.0)
		_set_bulb(1.0 - settings.bulb_flicker * absf(noise))
	_allowed = minf(_allowed + settings.rate * (0.6 + level) * delta, float(settings.max_messages))
	_check_wait -= delta
	if _check_wait <= 0.0:
		_check_wait = settings.check_interval
		var pending: int = int(_allowed) - _count
		if pending > 0:
			_write_many(mini(pending, 6), false)
	if not _burst_done and progress() >= settings.burst_at:
		_burst()


## Se va la luz; en la oscuridad se llena todo.
func _burst() -> void:
	_burst_done = true
	_dark = true
	_set_bulb(0.0)
	play_at(thud_stream, player.global_position, settings.thud_volume_db, 1.0, 20.0)
	await get_tree().create_timer(settings.burst_dark_time).timeout
	_write_many(settings.burst_count, true)
	_allowed = float(_count)
	_dark = false


func _set_bulb(k: float) -> void:
	_bulb.light_energy = settings.bulb_energy * k
	_bulb_material.emission_energy_multiplier = 3.0 * k


# ---------- Escritura ----------

## Escribe hasta `amount` mensajes. Sin `anywhere`, solo donde el jugador no está mirando.
func _write_many(amount: int, anywhere: bool) -> void:
	var written: Vector3 = Vector3.ZERO
	var done: int = 0
	var tries: int = 0
	while done < amount and tries < amount * 12 and _count < settings.max_messages:
		tries += 1
		var surface: Dictionary = _surfaces[_rng.randi() % _surfaces.size()]
		var urgent: bool = _count >= settings.calm_count + settings.first_messages.size()
		var texts: PackedStringArray = settings.urgent_texts if urgent else settings.calm_texts
		if texts.is_empty():
			return
		var text: String = texts[_rng.randi() % texts.size()]
		var size: float = settings.calm_size
		if urgent:
			# Cuantos más hay, más grandes pueden ser.
			var grow: float = clampf(float(_count) / maxf(settings.max_messages * 0.6, 1.0), 0.0, 1.0)
			size = lerpf(settings.urgent_size_min, lerpf(settings.urgent_size_min, settings.urgent_size_max, 0.35 + 0.65 * grow), pow(_rng.randf(), 1.6))
		var half_w: float = _text_half_width(text, size)
		var half_u: float = float(surface["half_u"])
		var half_v: float = float(surface["half_v"])
		if half_w > half_u - 0.1:
			continue
		var u: float = _rng.randf_range(-half_u + half_w + 0.05, half_u - half_w - 0.05)
		var v: float = _rng.randf_range(-half_v + size * 0.7, half_v - size * 0.7)
		var blocked: bool = false
		for hole: Rect2 in surface["holes"]:
			if hole.grow_individual(half_w, size * 0.6, half_w, size * 0.6).has_point(Vector2(u, v)):
				blocked = true
		if blocked:
			continue
		var at: Vector3 = (surface["center"] as Vector3) + (surface["right"] as Vector3) * u + (surface["up"] as Vector3) * v
		if not anywhere and _is_seen(to_global(at)):
			continue
		var tilt: float = settings.urgent_tilt if urgent else settings.calm_tilt
		_write(surface, u, v, text, size, urgent, deg_to_rad(_rng.randf_range(-tilt, tilt)))
		written += at
		done += 1
	if done > 0 and _scrawl_wait <= 0.0 and not scrawl_streams.is_empty() and is_active:
		_scrawl_wait = settings.scrawl_gap
		play_at(scrawl_streams[_rng.randi() % scrawl_streams.size()], to_global(written / done), settings.scrawl_volume_db, _rng.randf_range(0.85, 1.15), 2.5)


func _write(surface: Dictionary, u: float, v: float, text: String, size: float, urgent: bool, tilt: float) -> void:
	var label: Label3D = Label3D.new()
	label.name = "_GMessage"
	label.text = text
	label.font = urgent_font if urgent else calm_font
	label.font_size = 96
	label.pixel_size = size / 96.0
	label.outline_size = 0
	label.modulate = settings.urgent_color if urgent else settings.calm_color
	# Los blancos son luz proyectada (se ven igual a oscuras); los rojos son pintura: los alumbra la lamparita.
	label.shaded = urgent
	label.double_sided = false
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var right: Vector3 = surface["right"]
	var up: Vector3 = surface["up"]
	var normal: Vector3 = surface["normal"]
	var basis: Basis = Basis(right, up, normal).rotated(normal, tilt)
	# Cada mensaje un pelo más afuera que el anterior, para que no se pisen al dibujarse.
	var lift: float = 0.006 + 0.00025 * _count
	label.transform = Transform3D(basis, (surface["center"] as Vector3) + right * u + up * v + normal * lift)
	label.render_priority = _count % 100
	add_child(label)
	_count += 1


func _write_first() -> void:
	var firsts: PackedStringArray = settings.first_messages
	# Pared del fondo, a la izquierda de la salida: el grande.
	if firsts.size() > 0:
		var far: Dictionary = _surfaces[0]
		var half_w: float = _text_half_width(firsts[0], settings.title_size)
		var u: float = clampf(settings.exit_x - STUB_WIDTH * 0.5 - half_w - 0.4, -float(far["half_u"]) + half_w, float(far["half_u"]) - half_w)
		_write(far, u, 0.15, firsts[0], settings.title_size, false, 0.0)
	if firsts.size() > 1:
		_write(_surfaces[1], settings.room_depth * 0.12, 0.1, firsts[1], settings.calm_size * 1.3, false, 0.0)
	if firsts.size() > 2:
		_write(_surfaces[4], -0.3, settings.room_depth * 0.02, firsts[2], settings.calm_size * 1.5, false, deg_to_rad(-9.0))


func _text_half_width(text: String, size: float) -> float:
	return text.length() * size * 0.27


func _is_seen(point: Vector3) -> bool:
	var to_point: Vector3 = (point - _camera.global_position).normalized()
	return to_point.dot(-_camera.global_transform.basis.z) > cos(deg_to_rad(settings.unseen_angle))


# ---------- Armado ----------

func _build() -> void:
	var half: float = settings.room_width * 0.5
	var z0: float = -STUB_FRONT
	var z1: float = z0 - settings.room_depth
	var mid: float = (z0 + z1) * 0.5
	var h: float = settings.room_height
	add_entry_stub()
	add_box(Vector3(0.0, -WALL * 0.5, mid), Vector3(settings.room_width, WALL, settings.room_depth), floor_material)
	add_box(Vector3(0.0, h + WALL * 0.5, mid), Vector3(settings.room_width, WALL, settings.room_depth), ceiling_material)
	for side: float in [-1.0, 1.0]:
		add_box(Vector3(side * (half + WALL * 0.5), h * 0.5, mid), Vector3(WALL, h, settings.room_depth + WALL * 2.0), wall_material)
	add_wall_z(z0 + WALL * 0.5, -half, half, h, wall_material, 0.0)
	add_wall_z(z1 - WALL * 0.5, -half, half, h, wall_material, settings.exit_x)
	add_exit(settings.exit_x, z1, 0.8, 3.0)

	var door: Vector2 = Vector2(STUB_WIDTH, STUB_HEIGHT)
	# 0: pared del fondo (mira hacia +Z).
	_surfaces.append({"center": Vector3(0.0, h * 0.5, z1), "right": Vector3.RIGHT, "up": Vector3.UP, "normal": Vector3.BACK,
		"half_u": half, "half_v": h * 0.5, "holes": [Rect2(settings.exit_x - door.x * 0.5, -h * 0.5, door.x, door.y)]})
	# 1: pared izquierda (mira hacia +X).
	_surfaces.append({"center": Vector3(-half, h * 0.5, mid), "right": Vector3.FORWARD, "up": Vector3.UP, "normal": Vector3.RIGHT,
		"half_u": settings.room_depth * 0.5, "half_v": h * 0.5, "holes": []})
	# 2: pared derecha (mira hacia -X).
	_surfaces.append({"center": Vector3(half, h * 0.5, mid), "right": Vector3.BACK, "up": Vector3.UP, "normal": Vector3.LEFT,
		"half_u": settings.room_depth * 0.5, "half_v": h * 0.5, "holes": []})
	# 3: pared de la entrada (mira hacia -Z).
	_surfaces.append({"center": Vector3(0.0, h * 0.5, z0), "right": Vector3.LEFT, "up": Vector3.UP, "normal": Vector3.FORWARD,
		"half_u": half, "half_v": h * 0.5, "holes": [Rect2(-door.x * 0.5, -h * 0.5, door.x, door.y)]})
	# 4: piso (se lee caminando hacia el fondo).
	_surfaces.append({"center": Vector3(0.0, 0.0, mid), "right": Vector3.RIGHT, "up": Vector3.FORWARD, "normal": Vector3.UP,
		"half_u": half, "half_v": settings.room_depth * 0.5, "holes": []})
	# 5: techo.
	_surfaces.append({"center": Vector3(0.0, h, mid), "right": Vector3.RIGHT, "up": Vector3.BACK, "normal": Vector3.DOWN,
		"half_u": half, "half_v": settings.room_depth * 0.5, "holes": []})

	# La lamparita: un cable, el foco y su luz.
	var bulb_at: Vector3 = Vector3(0.0, h - 0.55, mid)
	var cable: MeshInstance3D = MeshInstance3D.new()
	var cable_mesh: CylinderMesh = CylinderMesh.new()
	cable_mesh.top_radius = 0.008
	cable_mesh.bottom_radius = 0.008
	cable_mesh.height = 0.5
	cable.mesh = cable_mesh
	cable.material_override = dark_material
	cable.position = bulb_at + Vector3(0.0, 0.3, 0.0)
	add_child(cable)
	var bulb_mesh: SphereMesh = SphereMesh.new()
	bulb_mesh.radius = 0.045
	bulb_mesh.height = 0.11
	var bulb: MeshInstance3D = MeshInstance3D.new()
	bulb.mesh = bulb_mesh
	_bulb_material = StandardMaterial3D.new()
	_bulb_material.albedo_color = settings.bulb_color
	_bulb_material.emission_enabled = true
	_bulb_material.emission = settings.bulb_color
	_bulb_material.emission_energy_multiplier = 3.0
	bulb.material_override = _bulb_material
	bulb.position = bulb_at
	add_child(bulb)
	_bulb = OmniLight3D.new()
	_bulb.light_color = settings.bulb_color
	_bulb.light_energy = settings.bulb_energy
	_bulb.omni_range = settings.bulb_range
	_bulb.position = bulb_at - Vector3(0.0, 0.1, 0.0)
	add_child(_bulb)
