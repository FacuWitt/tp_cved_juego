shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Lámina de agua de la casa que se repite (M3): oscura, casi quieta, con ondas lentas que se mueven
// aunque nadie la toque. La maneja RisingWater; los valores salen de DreamSettings.

uniform vec4 water_color : source_color = vec4(0.04, 0.1, 0.12, 0.8);
uniform float ripple_size = 0.8;
uniform float ripple_speed = 0.35;
uniform float time = 0.0;

float ripple(vec2 p) {
	float t = time * ripple_speed;
	return sin(p.x * 1.7 + t) * 0.5
		+ sin(p.y * 2.3 - t * 1.3) * 0.35
		+ sin((p.x + p.y) * 3.1 + t * 0.7) * 0.25;
}

void fragment() {
	vec2 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz / ripple_size;
	float e = 0.05;
	float h = ripple(p);
	vec3 n = normalize(vec3(ripple(p + vec2(e, 0.0)) - h, 6.0 * e, ripple(p + vec2(0.0, e)) - h));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	METALLIC = 0.3;
	ROUGHNESS = 0.04;
	SPECULAR = 0.8;
}
