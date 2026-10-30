shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

// Panel de luz de techo (las luces del hospital que se ven en el cielo con los rayos).
// Es un rectángulo sólido con el borde apenas difuso. Se mezcla (no se suma) para que se vea
// aunque el cielo esté muy iluminado por el rayo. Lo maneja HospitalLights.

uniform vec3 light_color : source_color = vec3(1.0, 0.86, 0.45);
uniform float energy = 3.0;
uniform float opacity = 0.0;
uniform float softness = 0.12;   // ancho del borde difuso (0 = borde duro)

void fragment() {
	vec2 q = abs(UV * 2.0 - 1.0);
	float d = max(q.x, q.y);
	float mask = 1.0 - smoothstep(1.0 - max(softness, 0.001), 1.0, d);
	ALBEDO = light_color * energy;
	ALPHA = mask * opacity;
}
