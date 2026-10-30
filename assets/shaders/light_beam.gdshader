shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, fog_disabled;

// Haz de luz de un reflector: un cono aditivo, más claro en el eje y suave en los bordes,
// con rayas de lluvia que lo cruzan. El mesh es un cono de altura 1 (el vértice en y = -0.5).

uniform vec3 beam_color : source_color = vec3(1.0, 0.93, 0.8);
uniform float strength = 0.25;
uniform float rain_streaks = 0.9;
uniform vec3 rain_dir = vec3(0.55, -1.0, 0.08);
uniform float fade_power = 1.4;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;

varying float v_t;
varying vec3 v_world;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	v_t = VERTEX.y + 0.5;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Bordes suaves: pleno donde miro el cono de frente, nada donde lo rozo.
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.6);
	float along = pow(clamp(1.0 - v_t, 0.0, 1.0), fade_power) * smoothstep(0.0, 0.06, v_t);

	// Rayas de lluvia que caen dentro del haz.
	vec3 r = normalize(rain_dir);
	vec3 a = normalize(cross(r, vec3(0.0, 0.0, 1.0)));
	vec3 b = cross(r, a);
	vec2 cell_p = vec2(dot(v_world, a), dot(v_world, b)) * 5.0;
	vec2 cell = floor(cell_p);
	float h = hash21(cell);
	float s = dot(v_world, r) * 0.55 + TIME * (5.0 + h * 3.0) + h * 10.0;
	float f = fract(s);
	float streak = smoothstep(0.0, 0.04, f) * (1.0 - smoothstep(0.04, 0.4, f));
	streak *= step(0.55, h);
	float haze = 0.55 + rain_streaks * streak;

	// No cortar de golpe contra el agua ni contra el casco.
	float depth = textureLod(depth_tex, SCREEN_UV, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	depth = depth * 2.0 - 1.0;
#endif
	vec4 up = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = up.z / up.w;
	float soft = clamp((VERTEX.z - scene_z) * 0.35, 0.0, 1.0);

	ALBEDO = beam_color * strength * edge * along * haze * soft;
}
