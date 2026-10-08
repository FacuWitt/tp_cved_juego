shader_type spatial;
// Luz difusa del helicóptero vista desde abajo del agua: un disco suave que siempre mira a la cámara.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, skip_vertex_transform;

uniform float strength : hint_range(0.0, 3.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.85, 0.93, 1.0);

void vertex() {
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	// Se conserva la escala del nodo.
	billboard[0] *= length(MODEL_MATRIX[0].xyz);
	billboard[1] *= length(MODEL_MATRIX[1].xyz);
	billboard[2] *= length(MODEL_MATRIX[2].xyz);
	VERTEX = (VIEW_MATRIX * billboard * vec4(VERTEX, 1.0)).xyz;
	NORMAL = (VIEW_MATRIX * billboard * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float core = pow(clamp(1.0 - d, 0.0, 1.0), 2.2);
	float halo = pow(clamp(1.0 - d, 0.0, 1.0), 0.8) * 0.25;
	float flicker = 0.92 + 0.08 * sin(TIME * 23.0) * sin(TIME * 7.3);
	ALBEDO = tint;
	ALPHA = clamp((core + halo) * strength * flicker, 0.0, 1.0);
}
