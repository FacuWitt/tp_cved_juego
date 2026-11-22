shader_type canvas_item;
// Neblina de sueño: la imagen ondula, los bordes se desenfocan y separan sus colores,
// hay una doble imagen tenue, las esquinas se oscurecen y los colores se apagan hacia el frío.
// Con intensity = 0 la imagen pasa tal cual. blackout lleva la pantalla a negro (parpadeos).
// Lo maneja DreamEffects; los valores salen de DreamSettings.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float intensity = 0.0;
uniform float time = 0.0;
uniform float wave_amount = 0.006;
uniform float wave_frequency = 5.0;
uniform float wave_speed = 0.5;
uniform float edge_blur = 3.0;
uniform float aberration = 0.006;
uniform float ghost_offset = 0.008;
uniform float ghost_mix = 0.25;
uniform float vignette = 0.7;
uniform float desaturation = 0.35;
uniform vec4 tint : source_color = vec4(0.78, 0.9, 0.92, 1.0);
uniform float blackout = 0.0;
// Estela al girar: hacia dónde quedó corrida la imagen (fracción de pantalla) y cuánto se ve.
uniform vec2 trail = vec2(0.0);
uniform float trail_mix = 0.0;
const int TRAIL_TAPS = 8;

vec3 sample_split(vec2 uv, vec2 split, float lod) {
	return vec3(
		textureLod(screen_tex, uv + split, lod).r,
		textureLod(screen_tex, uv, lod).g,
		textureLod(screen_tex, uv - split, lod).b);
}

void fragment() {
	float k = clamp(intensity, 0.0, 1.0);
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - 0.5;
	// 0 en el centro, ~1 en las esquinas.
	float r = length(from_center) * 1.414;

	// Ondas lentas, más fuertes hacia los bordes.
	vec2 wave = vec2(
		sin(uv.y * wave_frequency * 6.2832 + time * wave_speed),
		cos(uv.x * wave_frequency * 5.0 + time * wave_speed * 1.3));
	uv += wave * wave_amount * k * (0.35 + r);

	float lod = edge_blur * k * smoothstep(0.3, 1.0, r);
	vec2 split = from_center * aberration * k * r;
	vec3 col = sample_split(uv, split, lod);

	// Doble imagen que se mece despacio.
	vec2 ghost = vec2(ghost_offset, ghost_offset * 0.35) * k * (0.6 + 0.4 * sin(time * 0.7));
	col = mix(col, sample_split(uv + ghost, split, lod + 0.5), ghost_mix * k);

	// Estela: copias de la imagen hacia donde estaba antes del giro, cada vez más tenues.
	if (trail_mix > 0.001 && length(trail) > 0.0005) {
		vec3 acc = vec3(0.0);
		float total = 0.0;
		for (int i = 1; i <= TRAIL_TAPS; i++) {
			float t = float(i) / float(TRAIL_TAPS);
			float w = 1.0 - t * 0.85;
			acc += textureLod(screen_tex, uv + trail * t, lod + 1.0).rgb * w;
			total += w;
		}
		col = mix(col, acc / total, clamp(trail_mix, 0.0, 1.0) * smoothstep(0.0, 0.02, length(trail)));
	}

	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(gray), desaturation * k);
	col = mix(col, col * tint.rgb, k);
	col *= 1.0 - vignette * k * smoothstep(0.45, 1.25, r);
	col *= 1.0 - clamp(blackout, 0.0, 1.0);
	COLOR = vec4(col, 1.0);
}
