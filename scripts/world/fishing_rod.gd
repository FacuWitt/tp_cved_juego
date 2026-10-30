class_name FishingRod
extends Node3D
## La pesca: la caña en la mano, la boya y la línea. Ciclo:
##   (E) lanzar → la boya cae al agua adelante de la mirada → espera → pica (la boya se hunde)
##   → (E) a tiempo para enganchar → pelea con la FishingBar (W / S) → pescado o se soltó.
## Cada pez sacado emite `fish_caught`. La memoria decide cuántos hacen falta.

signal fish_caught(count: int)

enum State { OFF, READY, CASTING, WAITING, BITE, FIGHT, LANDING }

@export var settings: FishingSettings
@export var player: Player
## La caña en la mano. Tiene que tener un hijo "Bend" (gira al pelear) con un "Tip" (la punta).
@export var rod_view: HeldItemView
@export var bar: FishingBar
@export var subtitles: SubtitleDisplay
@export var prompt: InteractionPrompt
@export var water_level: float = 0.0

var state: State = State.OFF
var caught_count: int = 0

var _camera: Camera3D
var _bend: Node3D
var _tip: Node3D
var _bobber: MeshInstance3D
var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _fish: MeshInstance3D
var _target: Vector3
var _timer: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	assert(settings != null and player != null and rod_view != null and bar != null, "FishingRod: faltan referencias")
	_camera = player.get_node("Head/Camera3D") as Camera3D
	_bend = rod_view.get_node("Bend") as Node3D
	_tip = rod_view.get_node("Bend/Tip") as Node3D
	_build_bobber()
	_build_line()
	_build_fish()
	bar.caught.connect(_on_caught)
	bar.escaped.connect(_on_escaped)


## Saca la caña y queda lista para lanzar.
func start() -> void:
	await rod_view.equip()
	_set_state(State.READY)


## Guarda la caña (para pasar a la red).
func stop() -> void:
	_set_state(State.OFF)
	bar.cancel()
	_bobber.visible = false
	_line.visible = false
	rod_view.unequip()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if state == State.READY:
		get_viewport().set_input_as_handled()
		_cast()
	elif state == State.BITE:
		get_viewport().set_input_as_handled()
		_hook()


func _set_state(value: State) -> void:
	state = value
	if prompt == null:
		return
	match state:
		State.READY:
			prompt.override_text = settings.cast_prompt
		State.BITE:
			prompt.override_text = settings.hook_prompt
		_:
			prompt.override_text = ""


func _cast() -> void:
	_set_state(State.CASTING)
	var forward: Vector3 = -_camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else -player.global_basis.z
	_target = _camera.global_position + forward * settings.cast_distance
	_target.y = water_level
	_bobber.visible = true
	_line.visible = true
	var from: Vector3 = _tip.global_position
	var tween: Tween = create_tween()
	tween.tween_method(func(k: float) -> void:
		var p: Vector3 = from.lerp(_target, k)
		p.y += sin(PI * k) * 2.2
		_bobber.global_position = p, 0.0, 1.0, settings.cast_time)
	# La caña acompaña el lanzamiento.
	var swing: Tween = create_tween()
	# Atrás y arriba, y después hacia adelante.
	swing.tween_property(_bend, "rotation:x", 0.8, settings.cast_time * 0.3)
	swing.tween_property(_bend, "rotation:x", -0.2, settings.cast_time * 0.7)
	await tween.finished
	_timer = randf_range(settings.bite_min_wait, settings.bite_max_wait)
	_set_state(State.WAITING)


func _hook() -> void:
	_set_state(State.FIGHT)
	bar.begin(caught_count)


func _on_caught() -> void:
	caught_count += 1
	_set_state(State.LANDING)
	var lines: PackedStringArray = settings.caught_lines
	if subtitles != null and not lines.is_empty():
		subtitles.show_line(lines[mini(caught_count - 1, lines.size() - 1)], 2.2)
	# El pez sale del agua colgando de la línea y se guarda.
	_bobber.visible = false
	_fish.visible = true
	var tween: Tween = create_tween()
	tween.tween_method(func(k: float) -> void:
		_fish.global_position = _target.lerp(_tip.global_position + Vector3.DOWN * 0.45, k) + Vector3.UP * sin(PI * k) * 1.2, 0.0, 1.0, 0.9)
	await tween.finished
	await get_tree().create_timer(1.1).timeout
	_fish.visible = false
	_line.visible = false
	fish_caught.emit(caught_count)
	if state == State.LANDING:
		_set_state(State.READY)


func _on_escaped() -> void:
	if subtitles != null:
		subtitles.show_line(settings.escaped_line, 1.8)
	_bobber.visible = false
	_line.visible = false
	_set_state(State.READY)


func _process(delta: float) -> void:
	_time += delta
	match state:
		State.WAITING:
			_bobber.global_position = _target + Vector3.UP * sin(_time * 2.4) * 0.03
			_timer -= delta
			if _timer <= 0.0:
				_timer = settings.hook_window
				_set_state(State.BITE)
		State.BITE:
			# Pica: la boya se hunde a tirones.
			_bobber.global_position = _target + Vector3.DOWN * (0.12 + 0.06 * sin(_time * 30.0))
			_timer -= delta
			if _timer <= 0.0:
				_on_escaped()
		State.FIGHT:
			# El pez tira: la boya va y viene y la caña se dobla.
			var pull: Vector3 = Vector3(sin(_time * 2.7), 0.0, cos(_time * 2.1)) * 0.6
			_bobber.global_position = _target + pull + Vector3.DOWN * 0.15
			# La caña se levanta y vibra con los tirones.
			_bend.rotation.x = 0.4 + sin(_time * 13.0) * 0.05 * (1.0 - bar.progress)
			_bend.rotation.z = sin(_time * 2.7) * 0.12
		_:
			if state != State.CASTING:
				_bend.rotation.x = lerpf(_bend.rotation.x, 0.0, minf(delta * 4.0, 1.0))
				_bend.rotation.z = lerpf(_bend.rotation.z, 0.0, minf(delta * 4.0, 1.0))
	_draw_line()


func _draw_line() -> void:
	_line_mesh.clear_surfaces()
	if not _line.visible:
		return
	var end: Vector3 = _fish.global_position if _fish.visible else _bobber.global_position
	var start: Vector3 = _tip.global_position
	var tight: bool = state == State.FIGHT or state == State.LANDING
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i: int in 13:
		var t: float = float(i) / 12.0
		var p: Vector3 = start.lerp(end, t)
		# Floja, la línea cuelga; tensa, va casi recta.
		p.y -= sin(PI * t) * (0.05 if tight else 0.5)
		_line_mesh.surface_add_vertex(p)
	_line_mesh.surface_end()


func _build_bobber() -> void:
	_bobber = MeshInstance3D.new()
	_bobber.name = "Bobber"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	_bobber.mesh = sphere
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.2, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.2, 0.1)
	mat.emission_energy_multiplier = 0.6
	_bobber.material_override = mat
	_bobber.top_level = true
	_bobber.visible = false
	add_child(_bobber)


func _build_line() -> void:
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.name = "Line"
	_line.mesh = _line_mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.88, 0.9, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line.material_override = mat
	_line.top_level = true
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line.visible = false
	add_child(_line)


func _build_fish() -> void:
	_fish = MeshInstance3D.new()
	_fish.name = "Fish"
	var body: CapsuleMesh = CapsuleMesh.new()
	body.radius = 0.06
	body.height = 0.38
	_fish.mesh = body
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.6, 0.55)
	mat.metallic = 0.5
	mat.roughness = 0.3
	_fish.material_override = mat
	_fish.top_level = true
	_fish.visible = false
	add_child(_fish)
