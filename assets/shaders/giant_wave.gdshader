shader_type spatial;
// Ola gigante. El perfil (visto de costado) se calcula acá, en tres poses:
//   0 = marejada baja, 1 = pared empinada, 2 = barril con el labio enroscado hacia el jugador.
// `curl` (0..1) las recorre en orden, así la ola "gira" mientras avanza.
// La malla es solo una grilla: UV.x = posición a lo largo del perfil (0..1), UV.y = posición a lo ancho.
// Se calcula en el shader (y no con atributos extra de la malla) para que funcione igual en todos los renderers.
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float curl : hint_range(0.0, 1.0) = 0.0;
// Radio del barril (la mitad de la altura de la cresta) y semiancho del frente. Los pone GiantWave.
uniform float r = 14.0;
uniform float half_w = 85.0;
uniform vec3 water_color : source_color = vec3(0.004, 0.014, 0.02);
uniform vec3 foam_color : source_color = vec3(0.6, 0.68, 0.72);
uniform vec3 sky_reflect_color : source_color = vec3(0.35, 0.46, 0.6);
uniform float flash = 0.0;
// Brillo propio muy tenue para que se adivine la silueta entre rayos.
uniform float glow = 0.02;

varying float v_s;
varying float v_x;
varying vec3 w_pos;

const float POINTS = 64.0;
const float LEAD = 6.0;
const float FACE = 34.0;
const float OUTER = 8.0;
const float SLOPE = 16.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// u crece hacia el jugador; y hacia arriba.
vec2 face_pt(int pose, float t) {
	if (pose == 0) {
		return vec2(-3.0 * r * t, 0.55 * r * smoothstep(0.0, 1.0, t));
	}
	if (pose == 1) {
		return vec2(-0.9 * r * sin(t * PI * 0.5), 2.0 * r * (1.0 - cos(t * PI * 0.5)));
	}
	float th = radians(-90.0 - t * 230.0);
	// El barril se estira hacia el jugador para que el labio sobresalga más.
	return vec2(1.35 * r * cos(th), r + r * sin(th));
}

vec2 outer_pt(int pose, float t, vec2 last) {
	if (pose == 2) {
		float th = radians(-320.0 + t * 50.0);
		float rr = r * 1.22;
		return vec2(1.35 * rr * cos(th), r + rr * sin(th));
	}
	return vec2(last.x - 0.15 * r * t, last.y);
}

vec2 profile(int pose, float idx) {
	if (idx < LEAD) {
		return vec2(mix(2.4 * r, 0.0, idx / LEAD), 0.0);
	}
	if (idx < LEAD + FACE) {
		return face_pt(pose, (idx - LEAD) / (FACE - 1.0));
	}
	vec2 last = face_pt(pose, 1.0);
	if (idx < LEAD + FACE + OUTER) {
		return outer_pt(pose, (idx - LEAD - FACE) / (OUTER - 1.0), last);
	}
	vec2 crest = outer_pt(pose, 1.0, last);
	float t = (idx - LEAD - FACE - OUTER + 1.0) / SLOPE;
	return vec2(crest.x - 9.0 * r * t, crest.y * (1.0 - smoothstep(0.0, 1.0, t)));
}

void vertex() {
	float idx = floor(UV.x * (POINTS - 1.0) + 0.5);
	vec2 a = profile(0, idx);
	vec2 b = profile(1, idx);
	vec2 c = profile(2, idx);
	float k = curl * 2.0;
	vec2 p = k < 1.0 ? mix(a, b, smoothstep(0.0, 1.0, k)) : mix(b, c, smoothstep(0.0, 1.0, k - 1.0));

	// Hacia los bordes la ola se achata y se desenrosca; en el medio es más alta e irregular.
	float x = VERTEX.x;
	float edge = 1.0 - smoothstep(0.55, 1.0, abs(x) / half_w);
	float variation = 0.88 + 0.12 * sin(x * 0.09) + 0.07 * sin(x * 0.23 + 1.3);
	// La base queda un poco hundida en el mar para que no se vea el borde.
	vec3 pos = vec3(x, p.y * edge * variation - 0.5, -p.x * mix(0.2, 1.0, edge));

	// Ondulación del frente: la pared respira y el labio se desordena.
	float lip = smoothstep(0.45, 0.75, UV.x) * (1.0 - smoothstep(0.78, 0.9, UV.x));
	pos.y += sin(x * 0.31 + TIME * 1.1) * 0.5 * smoothstep(0.1, 0.5, UV.x) * curl;
	pos.z += sin(x * 0.17 - TIME * 0.8 + pos.y * 0.2) * 0.9 * lip * curl;
	VERTEX = pos;
	v_s = UV.x;
	v_x = pos.x;
	w_pos = (MODEL_MATRIX * vec4(pos, 1.0)).xyz;
}

void fragment() {
	// El tramo de mar llano de entrada no se dibuja: ya lo cubre el océano.
	if (v_s < LEAD / (POINTS - 1.0) + 0.002) {
		discard;
	}
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VIEW) < 0.0) {
		n = -n;
	}
	float ripple = vnoise(vec2(v_x * 0.35, w_pos.y * 0.9) + TIME * 0.4) - 0.5;
	n = normalize(n + vec3(ripple * 0.25, ripple * 0.15, 0.0));
	NORMAL = n;

	float noise = vnoise(vec2(v_x * 0.5, w_pos.y * 0.6) - TIME * 0.2) * 0.6 + vnoise(vec2(v_x * 1.9, w_pos.y * 1.7)) * 0.4;
	// Espuma en el labio, en la cresta y en el pie de la ola.
	float lip_foam = smoothstep(0.58, 0.72, v_s) * (0.45 + noise * 0.8);
	float toe_foam = (1.0 - smoothstep(0.0, 0.14, v_s)) * (0.3 + noise);
	float foam = clamp(max(lip_foam, toe_foam) * smoothstep(0.1, 0.9, curl + 0.25), 0.0, 1.0);

	float fres = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(water_color, foam_color, foam);
	ROUGHNESS = mix(0.16, 0.85, foam);
	SPECULAR = 0.85;
	EMISSION = sky_reflect_color * (glow * (0.4 + fres) + flash * (0.03 + fres * 0.3)) + foam_color * foam * (glow * 1.5 + flash * 0.12);
}
