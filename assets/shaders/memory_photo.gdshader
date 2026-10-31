shader_type spatial;
// Una foto familiar que se va borrando (M3). `blur` va de 0 (nítida) a 1 (no se distingue nada):
// se desenfoca, se corre como una doble exposición, pierde contraste y se funde con el papel.
// Si no hay textura, dibuja una foto genérica: la silueta de una persona en sepia.
// Lo maneja RepeatingPhotos.

uniform sampler2D photo_tex : source_color, filter_linear_mipmap, hint_default_black;
uniform bool use_texture = false;
uniform float blur : hint_range(0.0, 1.0) = 0.0;
uniform float max_lod = 6.0;
uniform vec3 paper : source_color = vec3(0.78, 0.68, 0.52);
uniform vec3 ink : source_color = vec3(0.24, 0.17, 0.11);

float silhouette(vec2 uv, float soft) {
	float head = 1.0 - smoothstep(0.15 - soft, 0.15 + soft, length((uv - vec2(0.5, 0.36)) * vec2(1.0, 0.85)));
	float body = 1.0 - smoothstep(0.3 - soft, 0.3 + soft, length((uv - vec2(0.5, 0.98)) * vec2(0.85, 1.0)));
	return max(head, body);
}

vec3 photo(vec2 uv) {
	if (use_texture) {
		return textureLod(photo_tex, uv, blur * max_lod).rgb;
	}
	float soft = 0.01 + blur * 0.28;
	return mix(paper, ink, silhouette(uv, soft));
}

void fragment() {
	vec2 uv = UV;
	// Doble exposición: una segunda copia corrida que aparece con el borroso.
	vec3 col = mix(photo(uv), photo(uv + vec2(0.06, -0.02) * blur), 0.45 * blur);
	// Pierde contraste y se funde con el papel.
	col = mix(col, paper * 0.85, blur * 0.55);
	// Bordes gastados.
	col *= mix(1.0, smoothstep(0.78, 0.35, length(uv - 0.5)), 0.45);
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
