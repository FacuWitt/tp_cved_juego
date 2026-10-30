shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// Red de pesca: una grilla de hilos sobre un plano, con el borde más grueso. Lo demás es transparente.

uniform vec3 thread_color : source_color = vec3(0.75, 0.72, 0.62);
uniform float cells = 14.0;
uniform float thickness = 0.1;

void fragment() {
	vec2 g = abs(fract(UV * cells) - 0.5);
	float line = step(0.5 - thickness, max(g.x, g.y));
	vec2 e = abs(UV - 0.5);
	float edge = step(0.48, max(e.x, e.y));
	float a = max(line, edge);
	if (a < 0.5) {
		discard;
	}
	ALBEDO = thread_color;
	ROUGHNESS = 0.9;
}
