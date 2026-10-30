shader_type spatial;
// Océano de tormenta de noche. Casi negro: solo se ve por los rayos (parámetro `flash`).
// Se ve desde arriba (superficie) y desde abajo (cuando el jugador se hunde).
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.006, 0.016, 0.022);
uniform vec3 foam_color : source_color = vec3(0.55, 0.62, 0.66);
uniform vec3 sky_reflect_color : source_color = vec3(0.35, 0.46, 0.6);
uniform float wave_height = 1.0;
// Reloj del mar: lo avanza OceanFollow, así el barco (en GDScript) y el agua (acá) siempre coinciden.
uniform float sea_time = 0.0;
uniform float chop = 0.55;
uniform float foam_amount = 0.6;
uniform float base_roughness = 0.4;
// 0..1: lo pone LightningController mientras dura el rayo.
uniform float flash = 0.0;
// Cuánto se ve la superficie desde abajo con cada rayo.
uniform float under_flash_strength = 0.12;
// Cuánto se apaga la superficie cuando se la mira desde arriba hacia abajo (el abismo no refleja nada).
// Color y fuerza con que el agua devuelve la luz de un reflector (el haz del barco sobre el mar).
uniform vec3 spot_lit_color : source_color = vec3(0.2, 0.52, 0.5);
uniform float spot_lit_strength = 5.0;
uniform float spot_glint = 0.5;
uniform float look_down_black = 0.92;
// --- Mar embravecido (referencias: pintura de tormenta, boya en mar de fondo) ---
// Cerca del barco el mar es más manso (para que flote bien); lejos las olas crecen hasta `far_scale` veces.
uniform vec2 calm_center = vec2(0.0, 0.0);
uniform float calm_radius = 28.0;
uniform float far_radius = 110.0;
uniform float far_scale = 3.2;
// Mar de fondo: ola larguísima y lenta. Fuerza lejos / cerca del barco.
uniform float big_swell_far = 2.3;
uniform float big_swell_near = 0.45;
// Color pizarra azulado que aparece en las olas cuando cae un rayo.
uniform vec3 slate_color : source_color = vec3(0.07, 0.11, 0.15);
uniform float slate_strength = 1.0;
// Cielo reflejado (nubes iluminadas por el rayo): horizonte pálido y cenit oscuro.
uniform vec3 sky_horizon_color : source_color = vec3(0.62, 0.7, 0.78);
uniform vec3 sky_zenith_color : source_color = vec3(0.1, 0.14, 0.2);
uniform float reflect_strength = 1.0;
// Reflejo ambiente mínimo sin rayo (que el mar no sea un agujero negro plano).
uniform float night_reflect = 0.012;
uniform float foam_streaks = 1.0;

varying vec3 w_pos;
varying float v_foam;
varying float v_crest;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Factor de escala del oleaje según la distancia al barco (0 = cerca, 1 = lejos).
float far_factor(vec2 p) {
	return smoothstep(calm_radius, far_radius, length(p - calm_center));
}

// Suma de ondas con crestas picudas (Gerstner simplificado).
// Devuelve xyz = desplazamiento; `slope` = pendiente (dh/dx, dh/dz); `squash` = compresión horizontal (para la espuma).
// IMPORTANTE: ocean_follow.gd replica la altura (height_at). Si se cambia algo acá, cambiarlo allá.
vec3 swell(vec2 p, float t, out vec2 slope, out float squash) {
	vec3 d = vec3(0.0);
	slope = vec2(0.0);
	squash = 0.0;
	vec2 dirs[6] = vec2[6](vec2(1.0, 0.3), vec2(-0.6, 1.0), vec2(0.2, -1.0), vec2(-1.0, -0.5), vec2(0.8, 0.9), vec2(0.7, 0.55));
	float freqs[6] = float[6](0.11, 0.19, 0.31, 0.53, 0.87, 0.045);
	float amps[6] = float[6](1.0, 0.62, 0.34, 0.16, 0.07, 1.0);
	float spds[6] = float[6](0.9, 1.2, 1.6, 2.1, 2.9, 0.62);
	float f = far_factor(p);
	float scl = mix(1.0, far_scale, f);
	for (int i = 0; i < 6; i++) {
		vec2 dir = normalize(dirs[i]);
		float ph = dot(p, dir) * freqs[i] + t * spds[i];
		float a = amps[i] * wave_height * scl;
		if (i == 5) {
			a = wave_height * mix(big_swell_near, big_swell_far, f);
		}
		float s_ph = sin(ph);
		float c_ph = cos(ph);
		d.y += s_ph * a;
		d.xz += dir * c_ph * a * chop;
		slope += dir * c_ph * a * freqs[i];
		squash += s_ph * a * chop * freqs[i];
	}
	return d;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 sl;
	float sq;
	vec3 d = swell(wp.xz, sea_time, sl, sq);
	VERTEX += vec3(d.x, d.y, d.z);
	w_pos = wp + d;
	v_crest = d.y / max(wave_height * mix(1.0, far_scale, far_factor(wp.xz)), 0.001);
}

void fragment() {
	// Normal analítica de las olas (más limpia que derivadas de pantalla) + ondas chicas.
	vec2 sl;
	float sq;
	vec3 dd = swell(w_pos.xz - vec2(0.0), sea_time, sl, sq);
	vec2 mr = vec2(vnoise(w_pos.xz * 2.1 + vec2(TIME * 0.7, 0.0)), vnoise(w_pos.xz * 2.3 - vec2(0.0, TIME * 0.6))) - 0.5;
	float mr_fade = 1.0 - smoothstep(30.0, 120.0, length(VERTEX));
	vec3 nw = normalize(vec3(-sl.x - mr.x * 0.22 * mr_fade, 1.0, -sl.y - mr.y * 0.22 * mr_fade));
	// A espacio de vista.
	vec3 n = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	if (dot(n, VIEW) < 0.0) {
		n = -n;
		nw = -nw;
	}
	NORMAL = n;

	float far_f = far_factor(w_pos.xz);
	float ampl = mix(1.0, far_scale, far_f);
	// Espuma: en la cresta, donde la superficie se comprime, y estirada en vetas siguiendo el viento.
	float foam_noise = vnoise(w_pos.xz * 0.9 - TIME * 0.35) * 0.65 + vnoise(w_pos.xz * 3.1) * 0.35;
	float streak = vnoise(vec2(dot(w_pos.xz, vec2(0.82, 0.57)) * 0.35, dot(w_pos.xz, vec2(-0.57, 0.82)) * 2.6 + TIME * 0.2));
	float crest = clamp(v_crest * 0.5 + 0.5, 0.0, 1.0);
	float comp = clamp(sq * 1.6 / max(ampl, 0.001), 0.0, 1.0);
	float foam_base = smoothstep(0.78, 1.05, v_crest * 0.5 + foam_noise * 0.62);
	float foam_str = smoothstep(0.55, 0.85, crest * 0.7 + comp * 0.5 + streak * 0.35) * smoothstep(0.35, 0.8, streak) * foam_streaks;
	float foam = clamp(foam_base + foam_str * 0.7, 0.0, 1.0) * foam_amount;
	v_foam = foam / max(foam_amount, 0.001);

	vec3 view_w = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float cosv = clamp(dot(nw, view_w), 0.0, 1.0);
	float fres = 0.02 + 0.98 * pow(1.0 - cosv, 5.0);
	float dim = 1.0 - smoothstep(0.3, 0.8, view_w.y) * look_down_black;

	if (FRONT_FACING) {
		// Cielo reflejado: nubes que se encienden con el rayo.
		vec3 r = reflect(-view_w, nw);
		float hz = clamp(1.0 - max(r.y, 0.0) * 1.6, 0.0, 1.0);
		float cloud = vnoise(r.xz / max(r.y + 0.35, 0.12) * 1.3 + vec2(TIME * 0.015, 0.0)) * 0.6 + vnoise(r.xz / max(r.y + 0.35, 0.12) * 3.7) * 0.4;
		vec3 sky = mix(sky_zenith_color, sky_horizon_color, hz * hz) * (0.45 + cloud * 0.9);
		float reflect_vis = max(r.y, -0.02) > -0.02 ? 1.0 : 0.0;

		// Agua: casi negra; con el rayo se asoma el color pizarra de las olas (más en las caras que miran a la luz y en las crestas finas).
		float slate = (0.35 + crest * 0.65) * (0.55 + 0.45 * (1.0 - cosv));
		vec3 body = deep_color + slate_color * slate * slate_strength * flash;
		ALBEDO = mix(body, foam_color, foam) * dim;
		ROUGHNESS = mix(base_roughness, 0.9, foam);
		SPECULAR = 0.5 * dim;
		EMISSION = (sky * fres * reflect_strength * (night_reflect + flash * 0.55) * reflect_vis
				+ foam_color * foam * flash * 0.07
				+ vec3(0.02, 0.06, 0.07) * slate * flash * 0.5) * dim;
	} else {
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		METALLIC = 0.0;
		EMISSION = vec3(0.05, 0.12, 0.16) * flash * under_flash_strength * (0.4 + fres);
	}
}


void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	if (LIGHT_IS_DIRECTIONAL) {
		// Luz direccional (relámpagos): comportamiento habitual.
		DIFFUSE_LIGHT += ALBEDO * ndl * LIGHT_COLOR * ATTENUATION / PI;
	} else {
		// Luces del barco y reflectores: el mar iluminado se vuelve verde azulado, la espuma
		// casi blanca, y las crestas brillan como en una foto de noche con un foco.
		vec3 lit = mix(spot_lit_color, foam_color * 1.5, clamp(v_foam, 0.0, 1.0));
		DIFFUSE_LIGHT += lit * spot_lit_strength * ndl * LIGHT_COLOR * ATTENUATION / PI;
		vec3 h = normalize(LIGHT + VIEW);
		float glint = pow(max(dot(NORMAL, h), 0.0), 70.0);
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * glint * spot_glint;
	}
}
