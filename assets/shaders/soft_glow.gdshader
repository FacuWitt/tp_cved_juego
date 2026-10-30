shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, fog_disabled;

// Brillo suave aditivo para un quad: radial (halo) o rectángulo redondeado (ventana).
// Con billboard = 1 el quad mira siempre a la cámara. No lo afecta la niebla: es luz, no objeto.

uniform vec3 glow_color : source_color = vec3(1.0, 0.75, 0.4);
uniform float energy = 1.0;
uniform float rect_mix = 0.0;   // 0 = radial, 1 = rectángulo redondeado
uniform float falloff = 2.0;
uniform float billboard = 0.0;

void vertex() {
	if (billboard > 0.5) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radial = clamp(1.0 - length(p), 0.0, 1.0);
	vec2 q = abs(p);
	float rect = clamp(1.0 - max(q.x, q.y), 0.0, 1.0);
	rect = smoothstep(0.0, 0.6, rect);
	float g = mix(pow(radial, falloff), rect, rect_mix);
	ALBEDO = glow_color * energy * g;
}
