class_name HospitalCorridorRoom
extends InterludeRoom
## Pasillo del hospital (M3): las paredes y el piso son los de la casa, pero el techo es el del
## hospital: filas de paneles cuadrados cálidos (las 6 luces de la M4 y del despertar, repetidas)
## que se pierden en la niebla. Las filas se apagan a espaldas del jugador y laten con el bip
## del monitor. A mitad de camino se corta la luz y, cuando vuelve, solo quedan las seis luces
## de arriba de la cabeza, que lo siguen hasta la salida.

enum Phase { OPEN, BLACKOUT, SIX }

@export var settings: HospitalCorridorSettings
@export var hum_stream: AudioStream
@export var beep_stream: AudioStream
@export var clack_stream: AudioStream
@export var flicker_stream: AudioStream
@export var thud_stream: AudioStream

var phase: Phase = Phase.OPEN

## Por fila: si tiene que estar prendida, y su brillo actual (0..1).
var _wanted: Array[bool] = []
var _glow: PackedFloat32Array = PackedFloat32Array()
var _flicker: PackedFloat32Array = PackedFloat32Array()
var _materials: Array[StandardMaterial3D] = []
var _lights: Array[OmniLight3D] = []
var _hum: AudioStreamPlayer
var _beep: AudioStreamPlayer
var _beep_wait: float = 0.0
var _dip: float = 0.0
var _fog_tween: Tween
var _fog_before: Dictionary = {}


func _ready() -> void:
	assert(settings != null and entry != null and exit_portal != null, "HospitalCorridorRoom: faltan referencias en el Inspector")
	_build()
	_hum = make_player(hum_stream, -60.0, true)
	_beep = make_player(beep_stream, settings.beep_volume_db)
	set_process(false)


func _room_depth() -> float:
	return settings.length


## Cuánto pesan las piernas ahora (lo usa la memoria para los efectos de sueño).
func drag() -> float:
	return progress() * settings.leg_drag


func _on_entered() -> void:
	phase = Phase.OPEN
	for i: int in _wanted.size():
		_wanted[i] = true
		_glow[i] = 1.0
	_beep_wait = settings.beep_interval_start
	_hum.volume_db = settings.hum_volume_db
	_hum.play()
	fade_drone(settings.drone_volume_db, 2.0)
	_set_fog(true)
	set_ambient(settings.ambient)
	set_process(true)


func _on_left() -> void:
	set_process(false)
	_set_fog(false)
	var t: Tween = create_tween()
	t.tween_property(_hum, "volume_db", -60.0, 0.8)
	t.tween_callback(_hum.stop)


func _process(delta: float) -> void:
	var k: float = progress()
	var along: float = -STUB_FRONT - to_local(player.global_position).z
	if phase == Phase.OPEN:
		for i: int in _wanted.size():
			if _wanted[i] and along - _row_distance(i) > settings.behind_margin:
				_switch(i, false)
		if k >= settings.blackout_at:
			_blackout()
	elif phase == Phase.SIX:
		# Las filas prendidas son las más cercanas al jugador: lo siguen.
		var center: int = clampi(roundi((along - settings.row_spacing * 0.5) / settings.row_spacing), 0, _wanted.size() - 1)
		var first: int = clampi(center - (settings.rows_after - 1) / 2, 0, maxi(0, _wanted.size() - settings.rows_after))
		for i: int in _wanted.size():
			var on: bool = i >= first and i < first + settings.rows_after
			if on != _wanted[i]:
				_switch(i, on)
	# El bip: el pulso se acelera al avanzar y los paneles laten con él.
	_beep_wait -= delta
	if _beep_wait <= 0.0:
		_beep_wait = lerpf(settings.beep_interval_start, settings.beep_interval_end, k)
		_beep.play()
		_dip = 1.0
	_dip = maxf(_dip - delta / settings.beep_dip_time, 0.0)
	var lit: int = 0
	for i: int in _wanted.size():
		if _wanted[i]:
			lit += 1
			if phase != Phase.BLACKOUT and randf() < settings.random_flicker * delta:
				_flicker[i] = randf_range(0.15, 0.4)
				play_at(flicker_stream, _row_position(i), settings.flicker_volume_db, randf_range(0.9, 1.15))
		_flicker[i] = maxf(_flicker[i] - delta, 0.0)
		var target: float = 1.0 if _wanted[i] else 0.0
		_glow[i] = move_toward(_glow[i], target, delta / settings.switch_time)
		var shown: float = _glow[i] * (1.0 - settings.beep_dip * _dip)
		if _flicker[i] > 0.0:
			shown *= 0.25 + 0.75 * float(randi() % 2)
		_materials[i].albedo_color = settings.panel_color * (0.04 + shown * settings.panel_glow)
		_lights[i].light_energy = settings.light_energy * shown
		_lights[i].visible = shown > 0.01
	if phase != Phase.BLACKOUT:
		_hum.volume_db = settings.hum_volume_db + linear_to_db(clampf(float(lit) / maxf(_wanted.size(), 1.0), 0.02, 1.0)) * 0.5


func _switch(row: int, on: bool) -> void:
	_wanted[row] = on
	play_at(clack_stream, _row_position(row), settings.clack_volume_db, randf_range(0.9, 1.1))


## Se corta la luz: oscuridad, solo el bip. Después quedan las seis luces.
func _blackout() -> void:
	phase = Phase.BLACKOUT
	for i: int in _wanted.size():
		_wanted[i] = false
	_hum.volume_db = -60.0
	play_at(thud_stream, player.global_position, settings.thud_volume_db, 1.0, 20.0)
	await get_tree().create_timer(settings.blackout_time).timeout
	if is_active:
		phase = Phase.SIX


func _row_distance(row: int) -> float:
	return (row + 0.5) * settings.row_spacing


func _row_position(row: int) -> Vector3:
	return to_global(Vector3(0.0, settings.height - 0.2, -STUB_FRONT - _row_distance(row)))


func _build() -> void:
	var half: float = settings.width * 0.5
	var z0: float = -STUB_FRONT
	var z1: float = z0 - settings.length
	var h: float = settings.height
	add_entry_stub()
	# Piso, techo y paredes van en tramos cortos: así a cada pieza le llegan pocas luces
	# (algunos renderizadores limitan cuántas luces alumbran una misma malla).
	var chunks: int = maxi(1, ceili(settings.length / (settings.row_spacing * 2.0)))
	var chunk: float = settings.length / chunks
	for c: int in chunks:
		var cz: float = z0 - (c + 0.5) * chunk
		add_box(Vector3(0.0, -WALL * 0.5, cz), Vector3(settings.width, WALL, chunk), floor_material)
		add_box(Vector3(0.0, h + WALL * 0.5, cz), Vector3(settings.width, WALL, chunk), ceiling_material)
		for side: float in [-1.0, 1.0]:
			add_box(Vector3(side * (half + WALL * 0.5), h * 0.5, cz), Vector3(WALL, h, chunk), wall_material)
	add_wall_z(z0 + WALL * 0.5, -half, half, h, wall_material, 0.0)
	add_wall_z(z1 - WALL * 0.5, -half, half, h, wall_material, 0.0)
	add_exit(0.0, z1, 0.9, 3.0)
	var rows: int = floori(settings.length / settings.row_spacing)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(settings.panel_size, 0.03, settings.panel_size)
	for i: int in rows:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.disable_fog = true
		_materials.append(material)
		var z: float = z0 - _row_distance(i)
		for side: float in [-0.5, 0.5]:
			var panel: MeshInstance3D = MeshInstance3D.new()
			panel.name = "_GPanel"
			panel.mesh = mesh
			panel.material_override = material
			panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			panel.position = Vector3(side * settings.column_spacing, h - 0.015, z)
			add_child(panel)
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = settings.panel_color
		light.omni_range = settings.light_range
		light.position = Vector3(0.0, h - 0.35, z)
		add_child(light)
		_lights.append(light)
		_wanted.append(true)
	_glow.resize(rows)
	_glow.fill(1.0)
	_flicker.resize(rows)
	_flicker.fill(0.0)


func _restore_environment() -> void:
	if _fog_before.is_empty():
		return
	environment.fog_enabled = _fog_before["enabled"]
	environment.fog_density = _fog_before["density"]
	environment.fog_light_color = _fog_before["color"]


func _set_fog(on: bool) -> void:
	if environment == null:
		return
	if _fog_tween != null and _fog_tween.is_valid():
		_fog_tween.kill()
	if on:
		_fog_before = {"enabled": environment.fog_enabled, "density": environment.fog_density, "color": environment.fog_light_color}
		environment.fog_enabled = true
		environment.fog_light_color = settings.fog_color
		environment.fog_density = 0.0
		_fog_tween = create_tween()
		_fog_tween.tween_property(environment, "fog_density", settings.fog_density, settings.fog_fade)
	elif not _fog_before.is_empty():
		_fog_tween = create_tween()
		_fog_tween.tween_property(environment, "fog_density", 0.0, settings.fog_fade)
		var before: Dictionary = _fog_before
		var env: Environment = environment
		_fog_tween.tween_callback(func() -> void:
			env.fog_enabled = before["enabled"]
			env.fog_density = before["density"]
			env.fog_light_color = before["color"])
