shader_type canvas_item;
// Postprocesado de pantalla completa: pixelado, reducción de color con tramado, viñeta,
// aberración cromática, grano y corrección de color. Se aplica sobre todo lo que se dibujó antes.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float pixel_size = 2.0;
uniform float color_levels = 32.0;
uniform float dither_strength = 0.7;
uniform float vignette_strength = 0.55;
uniform float vignette_radius = 0.75;
uniform float chromatic_aberration = 1.0;
uniform float grain_strength = 0.05;
uniform float contrast = 1.12;
uniform float saturation = 0.85;
uniform vec3 shadow_tint : source_color = vec3(0.0, 0.03, 0.06);
uniform vec3 highlight_tint : source_color = vec3(0.03, 0.02, 0.0);
uniform float black_lift = 0.0;
// Lo actualiza PostFx cada cuadro (para que el grano se mueva).
uniform float time_seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Matriz de Bayer 4x4 (tramado ordenado).
float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int idx = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[idx] / 16.0 - 0.5;
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 block = vec2(max(pixel_size, 1.0));
	// Coordenada del "píxel grande" al que pertenece este punto.
	vec2 cell = floor(FRAGCOORD.xy / block);
	vec2 uv = (cell + 0.5) * block / res;

	// Aberración cromática: más fuerte hacia los bordes.
	vec2 from_center = uv - 0.5;
	float edge = dot(from_center, from_center) * 2.0;
	vec2 shift = normalize(from_center + 1e-5) * edge * chromatic_aberration / res;
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;

	// Color: contraste, saturación y tinte de sombras/luces.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col += mix(shadow_tint, highlight_tint, smoothstep(0.0, 0.6, luma));
	col = max(col, vec3(black_lift));

	// Reducción de color con tramado.
	float levels = max(color_levels, 2.0);
	col += bayer4(cell) * dither_strength / levels;
	col = floor(col * levels + 0.5) / levels;

	// Viñeta.
	float d = length(from_center * vec2(res.x / res.y, 1.0));
	float vig = smoothstep(vignette_radius, vignette_radius + 0.55, d);
	col *= 1.0 - vig * vignette_strength;

	// Grano.
	col += (hash(cell + time_seed) - 0.5) * grain_strength;

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
