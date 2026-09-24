// Material provisorio con grilla en espacio de mundo (triplanar simple).
// Sirve para leer distancias y alturas mientras no hay assets reales.
shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 line_color : source_color = vec4(0.25, 0.25, 0.25, 1.0);
uniform float cell_size : hint_range(0.1, 10.0) = 1.0;
uniform float line_width : hint_range(0.0, 0.5) = 0.03;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 uv;
	if (n.y >= n.x && n.y >= n.z) {
		uv = world_pos.xz;
	} else if (n.x >= n.z) {
		uv = world_pos.zy;
	} else {
		uv = world_pos.xy;
	}
	vec2 dist = abs(fract(uv / cell_size - 0.5) - 0.5) * cell_size;
	float line = step(min(dist.x, dist.y), line_width);
	ALBEDO = mix(base_color.rgb, line_color.rgb, line);
	ROUGHNESS = 0.9;
}
