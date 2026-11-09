shader_type spatial;
// Mar de sueño de la M1: el que se ve por la ventana de la abuela. Quieto, oscuro y espejado,
// con un oleaje largo y lento (respira) y ondas finas que hacen brillar el camino de la luna.
// El reflejo de la luna y las estrellas sale del cielo (radiance), por eso la rugosidad es baja.

uniform vec3 deep_color : source_color = vec3(0.004, 0.012, 0.03);
// Tinte que aparece en la cresta de las olas largas (un poco de "brillo de sueño").
uniform vec3 crest_color : source_color = vec3(0.03, 0.07, 0.13);
// Oleaje largo: altura (m), largo de onda (m) y velocidad.
uniform float swell_height : hint_range(0.0, 1.5) = 0.12;
uniform float swell_length : hint_range(2.0, 80.0) = 18.0;
uniform float swell_speed : hint_range(0.0, 3.0) = 0.25;
// Ondas finas (solo en la normal): cuánto rompen el espejo y su tamaño (m).
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.22;
uniform float ripple_size : hint_range(0.2, 10.0) = 2.2;
uniform float ripple_speed : hint_range(0.0, 3.0) = 0.35;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.04;
// Lejos el oleaje se aplana (se ve como un espejo hasta el horizonte).
uniform float flatten_start = 25.0;
uniform float flatten_end = 140.0;

varying float v_crest;

vec3 swell(vec2 p, float t, float k_len) {
	// Tres ondas largas en direcciones distintas: altura y derivadas (dx, dz).
	vec2 dirs[3] = vec2[](normalize(vec2(1.0, 0.25)), normalize(vec2(0.6, -0.8)), normalize(vec2(-0.3, 1.0)));
	float lens[3] = float[](1.0, 0.63, 0.41);
	float amps[3] = float[](1.0, 0.45, 0.25);
	float h = 0.0;
	vec2 d = vec2(0.0);
	for (int i = 0; i < 3; i++) {
		float k = 6.2831 / (k_len * lens[i]);
		float ph = dot(dirs[i], p) * k + t * swell_speed * (1.0 + float(i) * 0.37) * 1.7;
		h += sin(ph) * amps[i];
		d += cos(ph) * amps[i] * k * dirs[i];
	}
	return vec3(h, d);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	float fade = 1.0 - smoothstep(flatten_start, flatten_end, length(w.xz - cam.xz));
	vec3 s = swell(w.xz, TIME, swell_length);
	float a = swell_height * fade / 1.7;
	VERTEX.y += s.x * a;
	v_crest = s.x * fade;
	vec3 n = normalize(vec3(-s.y * a, 1.0, -s.z * a));
	NORMAL = (inverse(MODEL_MATRIX) * vec4(n, 0.0)).xyz;
}

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = length(w - INV_VIEW_MATRIX[3].xyz);
	float far = smoothstep(flatten_start, flatten_end * 1.5, dist);
	// Ondas finas: dos capas de ruido que se cruzan, se apagan a lo lejos (queda espejo).
	vec2 p = w.xz / ripple_size;
	float t = TIME * ripple_speed;
	float e = 0.08;
	float n0 = noise(p + vec2(t, t * 0.6)) + noise(p * 2.3 - vec2(t * 0.7, -t));
	float nx = noise(p + vec2(e, 0.0) + vec2(t, t * 0.6)) + noise((p + vec2(e, 0.0)) * 2.3 - vec2(t * 0.7, -t));
	float nz = noise(p + vec2(0.0, e) + vec2(t, t * 0.6)) + noise((p + vec2(0.0, e)) * 2.3 - vec2(t * 0.7, -t));
	vec3 ripple = vec3(n0 - nx, 0.0, n0 - nz) / e * ripple_strength * 0.05 * (1.0 - far);
	vec3 view_n = normalize(NORMAL + (VIEW_MATRIX * vec4(ripple, 0.0)).xyz);
	NORMAL = view_n;
	ALBEDO = mix(deep_color, crest_color, clamp(v_crest * 0.5 + 0.2, 0.0, 1.0) * (1.0 - far));
	ROUGHNESS = surface_roughness;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
