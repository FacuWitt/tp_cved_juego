shader_type spatial;
// Agua del lago: del atardecer en calma a la tormenta de noche.
// Se ve desde arriba y desde abajo (cuando el protagonista se hunde).
// IMPORTANTE: lake_water.gd replica la altura (height_at) para que el bote flote sobre las mismas olas.
// Si se cambia algo en height() hay que cambiarlo allá.
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.035, 0.07, 0.085);
uniform vec3 sky_horizon_color : source_color = vec3(0.95, 0.55, 0.38);
uniform vec3 sky_zenith_color : source_color = vec3(0.22, 0.26, 0.42);
uniform vec3 foam_color : source_color = vec3(0.62, 0.68, 0.72);
uniform vec3 slate_color : source_color = vec3(0.07, 0.11, 0.15);
uniform vec3 lit_color : source_color = vec3(0.72, 0.5, 0.26);
uniform float lit_strength = 4.0;
uniform float reflect_strength = 0.55;
uniform float foam_amount = 0.7;
// 0 = calma, 1 = tormenta (lo pone LakeWater).
uniform float storm = 0.0;
// Altura de las olas ya combinada con la tormenta (lo pone LakeWater).
uniform float wave_scale = 0.1;
// Reloj del agua: lo avanza LakeWater, así el bote (en GDScript) y el agua (acá) siempre coinciden.
uniform float sea_time = 0.0;
// 0..1: lo pone LightningController mientras dura el rayo.
uniform float flash = 0.0;
uniform float under_flash_strength = 0.35;
// Ola gigante (ver LakeWater.launch_surge).
uniform vec2 surge_origin = vec2(0.0);
uniform vec2 surge_dir = vec2(0.0, -1.0);
uniform float surge_pos = 0.0;
uniform float surge_height = 0.0;
uniform float surge_width = 6.0;
uniform float surge_lat = 40.0;

varying vec3 w_pos;
varying float v_h;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float height(vec2 p) {
	vec2 dirs[5] = vec2[5](vec2(1.0, 0.35), vec2(-0.55, 1.0), vec2(0.25, -1.0), vec2(-1.0, -0.6), vec2(0.8, 0.9));
	float freqs[5] = float[5](0.16, 0.27, 0.43, 0.71, 1.1);
	float amps[5] = float[5](1.0, 0.6, 0.35, 0.18, 0.08);
	float spds[5] = float[5](0.8, 1.0, 1.3, 1.7, 2.3);
	float h = 0.0;
	for (int i = 0; i < 5; i++) {
		h += sin(dot(p, normalize(dirs[i])) * freqs[i] + sea_time * spds[i]) * amps[i] * wave_scale;
	}
	if (surge_height > 0.0) {
		vec2 rel = p - surge_origin;
		float s = dot(rel, surge_dir) - surge_pos;
		float lat = dot(rel, vec2(-surge_dir.y, surge_dir.x));
		float w = s < 0.0 ? surge_width * 2.4 : surge_width * 0.5;
		h += surge_height * exp(-(s * s) / (w * w)) * exp(-(lat * lat) / (surge_lat * surge_lat));
	}
	return h;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = height(wp.xz);
	VERTEX.y += h;
	w_pos = wp + vec3(0.0, h, 0.0);
	v_h = h;
}

void fragment() {
	float e = 0.7;
	float hx = height(w_pos.xz + vec2(e, 0.0)) - height(w_pos.xz - vec2(e, 0.0));
	float hz = height(w_pos.xz + vec2(0.0, e)) - height(w_pos.xz - vec2(0.0, e));
	// Ondas chicas de viento: más con tormenta.
	vec2 mr = vec2(vnoise(w_pos.xz * 1.9 + vec2(TIME * 0.6, 0.0)), vnoise(w_pos.xz * 2.2 - vec2(0.0, TIME * 0.5))) - 0.5;
	float ripple = mix(0.05, 0.2, storm);
	vec3 nw = normalize(vec3(-hx / (2.0 * e) - mr.x * ripple, 1.0, -hz / (2.0 * e) - mr.y * ripple));
	vec3 n = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	if (dot(n, VIEW) < 0.0) {
		n = -n;
		nw = -nw;
	}
	NORMAL = n;

	vec3 view_w = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float cosv = clamp(dot(nw, view_w), 0.0, 1.0);
	float fres = 0.02 + 0.98 * pow(1.0 - cosv, 5.0);

	float crest = clamp(v_h / max(wave_scale * 1.6, 0.02) * 0.5 + 0.5, 0.0, 1.0);
	float foam_noise = vnoise(w_pos.xz * 0.9 - TIME * 0.3) * 0.65 + vnoise(w_pos.xz * 3.1) * 0.35;
	float foam = smoothstep(0.66, 0.95, crest * 0.75 + foam_noise * 0.4) * storm * foam_amount;
	// La ola gigante viene con la cresta blanca.
	if (surge_height > 0.0) {
		foam = max(foam, smoothstep(0.35, 0.8, v_h / max(surge_height, 0.1)) * 0.9);
	}

	if (FRONT_FACING) {
		vec3 r = reflect(-view_w, nw);
		float hzn = clamp(1.0 - max(r.y, 0.0) * 1.6, 0.0, 1.0);
		float cloud = vnoise(r.xz / max(r.y + 0.35, 0.12) * 1.3 + vec2(TIME * 0.015, 0.0)) * 0.6 + vnoise(r.xz / max(r.y + 0.35, 0.12) * 3.7) * 0.4;
		vec3 sky = mix(sky_zenith_color, sky_horizon_color, hzn * hzn) * (0.45 + cloud * 0.9);
		float slate = (0.35 + crest * 0.65) * (0.55 + 0.45 * (1.0 - cosv));
		vec3 body = deep_color + slate_color * slate * flash;
		ALBEDO = mix(body, foam_color, foam);
		ROUGHNESS = mix(mix(0.12, 0.4, storm), 0.9, foam);
		SPECULAR = 0.5;
		EMISSION = sky * fres * reflect_strength * (1.0 + flash * 0.9)
				+ foam_color * foam * flash * 0.07
				+ vec3(0.02, 0.06, 0.07) * slate * flash * 0.5;
	} else {
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		EMISSION = vec3(0.04, 0.1, 0.13) * (0.12 + flash * under_flash_strength) * (0.4 + fres);
	}
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += ALBEDO * ndl * LIGHT_COLOR * ATTENUATION / PI;
	} else {
		// Faroles del bote y del padre: el agua devuelve un brillo cálido, la espuma casi blanca.
		DIFFUSE_LIGHT += lit_color * lit_strength * ndl * LIGHT_COLOR * ATTENUATION / PI;
		vec3 h = normalize(LIGHT + VIEW);
		float glint = pow(max(dot(NORMAL, h), 0.0), 60.0);
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * glint * 0.6;
	}
}
