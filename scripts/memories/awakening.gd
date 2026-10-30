class_name Awakening
extends Memory
## El despertar en el hospital (última escena). Arranca en blanco: abre los ojos acostado y ve el
## techo con las 6 luces que en la M4 aparecían en el cielo con los rayos. Suena el monitor cardíaco.
## Gira la cabeza hacia la hija, que le dice que le trajo el barquito; la mirada baja al barquito de
## la mesita de luz (último plano) y todo se funde a blanco con el título.
## Entre los momentos guiados se puede mirar alrededor con el mouse, sin moverse.

@export var settings: AwakeningSettings
## La cabeza (pivote de la mirada) con la cámara adentro.
@export var head: Node3D
@export var camera: Camera3D
@export var subtitles: SubtitleDisplay
## Dónde mirar a la hija (su cara) y al barquito.
@export var daughter_look: Node3D
## La hija: se la gira para que mire hacia la cama (el modelo mira hacia su +Z).
@export var daughter_model: Node3D
@export var toy_boat: Node3D
## Blanco que tapa la pantalla al principio y al final, y el título.
@export var white_overlay: ColorRect
@export var title_label: Label
## De dónde sale el bip del monitor.
@export var monitor_speaker: AudioStreamPlayer3D
## Dónde va el techo (el centro de la grilla de luces queda justo arriba de la cabeza).
@export var ceiling_height: float = 2.85

var _look_enabled: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _beep_timer: float = 0.0
var _voice: AudioStreamPlayer


func _ready() -> void:
	super()
	assert(settings != null and head != null and camera != null and subtitles != null, "Awakening: faltan referencias en el Inspector")
	assert(white_overlay != null and title_label != null, "Awakening: faltan el blanco y el título")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	white_overlay.visible = true
	white_overlay.color.a = 1.0
	title_label.text = settings.end_title
	title_label.modulate.a = 0.0
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	_build_ceiling()
	if daughter_model != null:
		var face: Vector3 = Vector3(camera.global_position.x, daughter_model.global_position.y, camera.global_position.z)
		daughter_model.look_at(face, Vector3.UP, true)
	_pitch = deg_to_rad(settings.max_pitch)
	_apply_look()
	_play.call_deferred()


func _process(delta: float) -> void:
	if settings.monitor_beep != null and monitor_speaker != null:
		_beep_timer -= delta
		if _beep_timer <= 0.0:
			_beep_timer = settings.beep_interval
			monitor_speaker.stream = settings.monitor_beep
			monitor_speaker.volume_db = settings.beep_db
			monitor_speaker.play()


func _unhandled_input(event: InputEvent) -> void:
	if not _look_enabled or not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	_yaw -= deg_to_rad(motion.relative.x * settings.mouse_sensitivity)
	_pitch -= deg_to_rad(motion.relative.y * settings.mouse_sensitivity)
	_apply_look()


# ---------- Secuencia ----------

func _play() -> void:
	# 1. Abre los ojos: el blanco se aclara con un par de parpadeos.
	var open: Tween = create_tween()
	open.tween_property(white_overlay, "color:a", 0.35, settings.open_eyes_time * 0.5).set_trans(Tween.TRANS_SINE)
	for i: int in settings.blinks:
		open.tween_property(white_overlay, "color:a", 0.8, settings.blink_time * 0.5)
		open.tween_property(white_overlay, "color:a", 0.25 - 0.1 * float(i), settings.blink_time)
	open.tween_property(white_overlay, "color:a", 0.0, settings.open_eyes_time * 0.5).set_trans(Tween.TRANS_SINE)
	await open.finished
	_look_enabled = true
	await get_tree().create_timer(settings.ceiling_hold).timeout

	# 2. Gira hacia la hija, que le habla.
	if daughter_look != null:
		await _look_at(daughter_look.global_position, settings.turn_to_daughter_time)
	subtitles.show_line(settings.daughter_line, settings.daughter_line_time)
	if settings.daughter_voice != null:
		_voice.stream = settings.daughter_voice
		_voice.play()
	await get_tree().create_timer(settings.daughter_line_time).timeout

	# 3. Último plano: el barquito en la mesita de luz.
	if toy_boat != null:
		await _look_at(toy_boat.global_position, settings.turn_to_boat_time)
	await get_tree().create_timer(settings.boat_hold).timeout

	# 4. Fundido a blanco y el título.
	_look_enabled = false
	var end: Tween = create_tween()
	end.tween_property(white_overlay, "color:a", 1.0, settings.end_fade_time).set_trans(Tween.TRANS_SINE)
	end.tween_property(title_label, "modulate:a", 1.0, settings.title_fade_time)
	await end.finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Gira la cabeza hasta mirar `point` (sin pasarse de los topes). Mientras gira no se controla la mirada.
func _look_at(point: Vector3, duration: float) -> void:
	_look_enabled = false
	var to: Vector3 = point - camera.global_position
	var target_yaw: float = atan2(-to.x, -to.z) - head.get_parent_node_3d().global_rotation.y
	var target_pitch: float = atan2(to.y, Vector2(to.x, to.z).length())
	target_yaw = _yaw + wrapf(target_yaw - _yaw, -PI, PI)
	var turn: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	turn.tween_method(func(v: float) -> void:
		_yaw = v
		_apply_look(), _yaw, target_yaw, duration)
	turn.tween_method(func(v: float) -> void:
		_pitch = v
		_apply_look(), _pitch, target_pitch, duration)
	await turn.finished
	_look_enabled = true


func _apply_look() -> void:
	var max_yaw: float = deg_to_rad(settings.max_yaw)
	_yaw = clampf(_yaw, -max_yaw, max_yaw)
	_pitch = clampf(_pitch, deg_to_rad(settings.min_pitch), deg_to_rad(settings.max_pitch))
	head.rotation = Vector3(0.0, _yaw, 0.0)
	camera.rotation = Vector3(_pitch, 0.0, 0.0)


# ---------- Techo ----------

## Arma los 6 paneles del techo con la misma forma, separación y color que los del cielo de la M4,
## achicados a la altura del techo: desde la cama ocupan el mismo lugar en la vista que en el cielo.
func _build_ceiling() -> void:
	var cfg: HospitalLightsSettings = settings.ceiling_lights
	if cfg == null:
		return
	var eye: Vector3 = camera.global_position
	var rise: float = ceiling_height - 0.02 - eye.y
	var k: float = rise / cfg.distance
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/hospital_light.gdshader")
	material.set_shader_parameter("light_color", cfg.color)
	material.set_shader_parameter("energy", settings.panel_energy)
	material.set_shader_parameter("opacity", 1.0)
	material.set_shader_parameter("softness", cfg.edge_softness)
	var quad: QuadMesh = QuadMesh.new()
	quad.size = cfg.panel_size * k
	for r: int in cfg.rows:
		for c: int in cfg.columns:
			# Igual que HospitalLights (OVERHEAD): columnas en X, filas en Z.
			var offset: Vector3 = Vector3(
				(float(c) - float(cfg.columns - 1) * 0.5) * cfg.spacing.x * k,
				0.0,
				(float(r) - float(cfg.rows - 1) * 0.5) * cfg.spacing.y * k)
			var panel: MeshInstance3D = MeshInstance3D.new()
			panel.name = "Panel%d" % (r * cfg.columns + c)
			panel.mesh = quad
			panel.material_override = material
			panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(panel)
			panel.global_transform = Transform3D(Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), Vector3(eye.x, ceiling_height - 0.02, eye.z) + offset)
			var light: OmniLight3D = OmniLight3D.new()
			light.name = "Light%d" % (r * cfg.columns + c)
			light.light_color = cfg.color.lerp(Color.WHITE, 0.5)
			light.light_energy = settings.room_light_energy
			light.omni_range = settings.room_light_range
			light.shadow_enabled = false
			add_child(light)
			light.global_position = Vector3(eye.x, ceiling_height - 0.25, eye.z) + offset
