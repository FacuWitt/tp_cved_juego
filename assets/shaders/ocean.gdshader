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
uniform float foam_amount = 0.38;
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

// Suma de ondas con crestas picudas (Gerstner simplificado). Devuelve xyz = desplazamiento.
vec3 swell(vec2 p, float t) {
	vec3 d = vec3(0.0);
	vec2 dirs[5] = vec2[5](vec2(1.0, 0.3), vec2(-0.6, 1.0), vec2(0.2, -1.0), vec2(-1.0, -0.5), vec2(0.8, 0.9));
	float freqs[5] = float[5](0.11, 0.19, 0.31, 0.53, 0.87);
	float amps[5] = float[5](1.0, 0.62, 0.34, 0.16, 0.07);
	float spds[5] = float[5](0.9, 1.2, 1.6, 2.1, 2.9);
	for (int i = 0; i < 5; i++) {
		vec2 dir = normalize(dirs[i]);
		float ph = dot(p, dir) * freqs[i] + t * spds[i];
		float a = amps[i] * wave_height;
		d.y += sin(ph) * a;
		d.xz += dir * cos(ph) * a * chop;
	}
	return d;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 d = swell(wp.xz, sea_time);
	VERTEX += vec3(d.x, d.y, d.z);
	w_pos = wp + d;
	v_crest = d.y / max(wave_height, 0.001);
}

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VIEW) < 0.0) {
		n = -n;
	}
	float ripple = vnoise(w_pos.xz * 1.7 + TIME * 0.6) - 0.5;
	n = normalize(n + vec3(ripple * 0.18, 0.0, ripple * 0.12));
	NORMAL = n;

	float foam_noise = vnoise(w_pos.xz * 0.9 - TIME * 0.35) * 0.65 + vnoise(w_pos.xz * 3.1) * 0.35;
	float foam = smoothstep(0.78, 1.05, v_crest * 0.5 + foam_noise * 0.62) * foam_amount;

	v_foam = foam / max(foam_amount, 0.001);

	float fres = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 4.0);
	// Elevación de la cámara respecto de este punto del agua: 1 = lo miro desde justo arriba.
	vec3 view_w = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float dim = 1.0 - smoothstep(0.3, 0.8, view_w.y) * look_down_black;

	if (FRONT_FACING) {
		ALBEDO = mix(deep_color, foam_color, foam) * dim;
		ROUGHNESS = mix(base_roughness, 0.9, foam);
		SPECULAR = 0.25 * dim;
		// Reflejo falso del cielo encendido por el rayo, más fuerte de costado.
		EMISSION = (sky_reflect_color * flash * (0.012 + fres * 0.28) + foam_color * foam * flash * 0.05) * dim;
	} else {
		// Desde abajo: oscuridad total, salvo el destello del rayo atravesando el agua.
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		// Sin brillo: las luces del barco no tienen que asomarse desde abajo del agua.
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
		float glint = pow(max(dot(NORMAL, h), 0.0), 40.0);
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * glint * spot_glint;
	}
}
