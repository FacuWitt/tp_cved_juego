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
// Gotas pegadas en la lente (0 = lente seca). Las maneja la memoria que lo necesite.
uniform float lens_wet = 0.0;
uniform float lens_time = 0.0;

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

// Gotas en la lente: devuelve (desplazamiento del UV, brillo). Grilla de celdas con una gota por celda.
vec3 lens_drops(vec2 uv, float aspect, float t) {
	vec2 acc = vec2(0.0);
	float shine = 0.0;
	float scale = 7.0;
	for (int layer = 0; layer < 2; layer++) {
		scale = layer == 0 ? 7.0 : 12.0;
		vec2 p = vec2(uv.x * aspect, uv.y) * scale;
		// Las gotas resbalan lento hacia abajo.
		p.y += t * (layer == 0 ? 0.05 : 0.09);
		vec2 id = floor(p);
		vec2 f = fract(p) - 0.5;
		float h = hash(id + float(layer) * 17.0);
		// Solo algunas celdas tienen gota, y se van y vuelven con el tiempo.
		float life = fract(h * 5.0 + t * 0.03);
		float on = step(1.0 - lens_wet * 0.55, hash(id * 1.7 + 3.0)) * smoothstep(0.0, 0.15, life) * (1.0 - smoothstep(0.7, 1.0, life));
		vec2 c = (vec2(hash(id + 5.0), hash(id + 9.0)) - 0.5) * 0.5;
		vec2 d = f - c;
		float r = 0.11 + 0.1 * hash(id + 2.0);
		d.y *= 0.8;
		float m = smoothstep(r, r * 0.55, length(d)) * on;
		acc += -d * m * 0.9;
		shine += m * smoothstep(0.0, 0.5, -d.y + 0.2) * 0.25;
	}
	return vec3(acc * 0.18, shine);
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 block = vec2(max(pixel_size, 1.0));
	// Coordenada del "píxel grande" al que pertenece este punto.
	vec2 cell = floor(FRAGCOORD.xy / block);
	vec2 uv = (cell + 0.5) * block / res;
	float drop_shine = 0.0;
	if (lens_wet > 0.001) {
		vec3 dr = lens_drops(uv, res.x / res.y, lens_time);
		uv += dr.xy;
		drop_shine = dr.z;
	}

	// Aberración cromática: más fuerte hacia los bordes.
	vec2 from_center = uv - 0.5;
	float edge = dot(from_center, from_center) * 2.0;
	vec2 shift = normalize(from_center + 1e-5) * edge * chromatic_aberration / res;
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;

	col += vec3(0.55, 0.65, 0.8) * drop_shine * lens_wet;

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
