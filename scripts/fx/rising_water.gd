class_name RisingWater
extends Node3D
## Agua que sube (M3): una lámina de agua oscura sobre el piso de los lugares que se le indiquen
## (`areas`). Sube despacio con el sueño, sin que se note, y se mece sola, como si algo la moviera.
## Cuando la casa vuelve a ser real (nivel 0), baja hasta desaparecer.
## No sabe en qué memoria está: la memoria le dice cuánto soñar (`level`).

const SHADER: Shader = preload("res://assets/shaders/dream_water.gdshader")

@export var settings: DreamSettings
## Rectángulos de piso que se inundan, en coordenadas locales de este nodo (la altura no se usa).
## Conviene que entren un poco en las paredes, así no queda un borde seco.
@export var areas: Array[AABB] = []

## Cuánto sueño hay (0 = seco, 1 = lo máximo). Lo pone la memoria.
var level: float = 0.0

var _material: ShaderMaterial
var _sheets: Array[MeshInstance3D] = []
var _height: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	assert(settings != null, "RisingWater: falta el DreamSettings")
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	for area: AABB in areas:
		var plane: PlaneMesh = PlaneMesh.new()
		plane.size = Vector2(area.size.x, area.size.z)
		var sheet: MeshInstance3D = MeshInstance3D.new()
		sheet.mesh = plane
		sheet.material_override = _material
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sheet.position = Vector3(area.position.x + area.size.x * 0.5, 0.0, area.position.z + area.size.z * 0.5)
		add_child(sheet)
		_sheets.append(sheet)
	_apply()


func _process(delta: float) -> void:
	_time += delta
	var target: float = 0.0
	if settings.water_enabled:
		target = settings.water_max_height * clampf(level * settings.level_gain, 0.0, 1.0)
	_height = move_toward(_height, target, settings.water_rise_speed * delta)
	_apply()


func _apply() -> void:
	# Se mece sola, pero nunca por debajo del piso.
	var slosh: float = sin(_time * TAU / settings.water_slosh_period) * settings.water_slosh * minf(_height / maxf(settings.water_max_height, 0.001), 1.0)
	var y: float = maxf(_height + slosh, 0.0)
	var wet: bool = y > 0.004
	for sheet: MeshInstance3D in _sheets:
		sheet.visible = wet
		sheet.position.y = y
	_material.set_shader_parameter("water_color", settings.water_color)
	_material.set_shader_parameter("ripple_size", settings.water_ripple_size)
	_material.set_shader_parameter("ripple_speed", settings.water_ripple_speed)
	_material.set_shader_parameter("time", _time)
