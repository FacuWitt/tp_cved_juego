shader_type sky;

// Cielo de la Memoria 2: atardecer de invierno que se cierra en tormenta.
// Degradé de horizonte a cenit, brillo del sol (la primera luz direccional que afecta al cielo,
// el Sun de la escena), nubes que se mueven y, con `storm` en 1, todo oscuro y cubierto.
// Colores en bandas (`color_steps`) para el look PS1. La memoria mueve `storm` con la tormenta y
// los rayos lo iluminan con la energía del fondo del Environment, como antes.

group_uniforms calma;
uniform vec3 zenith_color : source_color = vec3(0.05, 0.06, 0.14);
uniform vec3 mid_color : source_color = vec3(0.22, 0.15, 0.28);
uniform vec3 horizon_color : source_color = vec3(0.62, 0.30, 0.22);
uniform vec3 ground_color : source_color = vec3(0.04, 0.04, 0.06);
uniform vec3 sun_color : source_color = vec3(1.0, 0.55, 0.28);
// Qué tan concentrado está el brillo del sol (más alto = más chico).
uniform float sun_glow_focus : hint_range(1.0, 64.0) = 10.0;
uniform float sun_glow_strength : hint_range(0.0, 4.0) = 0.9;
uniform vec3 cloud_color : source_color = vec3(0.12, 0.10, 0.16);
uniform vec3 cloud_lit_color : source_color = vec3(0.75, 0.38, 0.26);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.5;

group_uniforms tormenta;
uniform vec3 storm_zenith_color : source_color = vec3(0.02, 0.025, 0.035);
uniform vec3 storm_mid_color : source_color = vec3(0.05, 0.055, 0.07);
uniform vec3 storm_horizon_color : source_color = vec3(0.09, 0.09, 0.11);
uniform vec3 storm_cloud_color : source_color = vec3(0.07, 0.075, 0.09);
uniform float storm_coverage : hint_range(0.0, 1.0) = 0.92;
// 0 = calma, 1 = tormenta cerrada (lo pone la memoria).
uniform float storm : hint_range(0.0, 1.0) = 0.0;

group_uniforms nubes;
uniform float cloud_scale : hint_range(0.1, 10.0) = 1.6;
uniform float cloud_speed : hint_range(0.0, 0.2) = 0.008;
uniform float storm_cloud_speed : hint_range(0.0, 0.5) = 0.04;

group_uniforms ps1;
// Cantidad de bandas de color por canal (más bajo = más PS1).
uniform float color_steps : hint_range(4.0, 128.0) = 32.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 zen = mix(zenith_color, storm_zenith_color, storm);
	vec3 mid = mix(mid_color, storm_mid_color, storm);
	vec3 hor = mix(horizon_color, storm_horizon_color, storm);
	vec3 col;
	if (h >= 0.0) {
		col = mix(hor, mid, smoothstep(0.0, 0.22, h));
		col = mix(col, zen, smoothstep(0.18, 0.75, h));
	} else {
		col = mix(hor * 0.5, ground_color, smoothstep(0.0, 0.15, -h));
	}

	// Brillo del sol, sobre todo cerca del horizonte.
	float sun_dot = 0.0;
	if (LIGHT0_ENABLED) {
		sun_dot = max(dot(d, LIGHT0_DIRECTION), 0.0);
	}
	float calm = 1.0 - storm;
	float glow = pow(sun_dot, sun_glow_focus) + 0.35 * pow(sun_dot, 3.0) * exp(-abs(h) * 7.0);
	col += sun_color * glow * sun_glow_strength * calm;

	// Nubes: ruido proyectado sobre un techo, que se apaga hacia el horizonte.
	if (h > 0.0) {
		vec2 uv = d.xz / (h + 0.12) * cloud_scale;
		float speed = mix(cloud_speed, storm_cloud_speed, storm);
		float n = fbm(uv + vec2(TIME * speed, TIME * speed * 0.4));
		float cover = mix(cloud_coverage, storm_coverage, storm);
		float c = smoothstep(1.0 - cover, 1.0 - cover + 0.22, n) * smoothstep(0.0, 0.1, h);
		vec3 ccol = mix(cloud_color, storm_cloud_color, storm);
		vec3 lit = cloud_lit_color * pow(sun_dot, 4.0) * calm;
		col = mix(col, ccol + lit * 0.7, c * 0.92);
	}

	col = floor(col * color_steps + 0.5) / color_steps;
	COLOR = col;
}
