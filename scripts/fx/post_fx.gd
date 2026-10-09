class_name PostFx
extends CanvasLayer
## Postprocesado de pantalla completa (estilo "PS1 con esteroides"). Se arma solo:
## un rectángulo que cubre la pantalla con un shader que lee lo que ya se dibujó.
## Va debajo de la interfaz (subtítulos, barra del evento rápido), que no se ve afectada.
## Los valores salen de un PostFxSettings; cada escena elige el suyo.

const SHADER: Shader = preload("res://assets/shaders/post_fx.gdshader")

@export var settings: PostFxSettings:
	set(value):
		settings = value
		if is_node_ready():
			apply_settings()

var _material: ShaderMaterial
var _time: float = 0.0


func _ready() -> void:
	assert(settings != null, "PostFx: falta asignar un PostFxSettings en el Inspector")
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var rect: ColorRect = ColorRect.new()
	rect.name = "Screen"
	rect.material = _material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	apply_settings()


func _process(delta: float) -> void:
	_time += delta
	# El grano cambia unas 24 veces por segundo, como el cine.
	_material.set_shader_parameter("time_seed", floorf(_time * 24.0) * 7.13)
	_material.set_shader_parameter("lens_time", _time)


## Vuelve a pasar los valores del Resource al shader (por si se cambió en pleno juego).
func apply_settings() -> void:
	_material.set_shader_parameter("pixel_size", settings.pixel_size)
	_material.set_shader_parameter("color_levels", float(settings.color_levels))
	_material.set_shader_parameter("dither_strength", settings.dither_strength)
	_material.set_shader_parameter("vignette_strength", settings.vignette_strength)
	_material.set_shader_parameter("vignette_radius", settings.vignette_radius)
	_material.set_shader_parameter("chromatic_aberration", settings.chromatic_aberration)
	_material.set_shader_parameter("grain_strength", settings.grain_strength)
	_material.set_shader_parameter("contrast", settings.contrast)
	_material.set_shader_parameter("saturation", settings.saturation)
	_material.set_shader_parameter("shadow_tint", settings.shadow_tint)
	_material.set_shader_parameter("highlight_tint", settings.highlight_tint)
	_material.set_shader_parameter("black_lift", settings.black_lift)


## Cuántas gotas hay pegadas en la lente: 0 = seca, 1 = muy mojada.
func set_lens_wet(amount: float) -> void:
	_material.set_shader_parameter("lens_wet", clampf(amount, 0.0, 1.0))
