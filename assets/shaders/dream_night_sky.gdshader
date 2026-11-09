shader_type sky;
// Cielo de sueño de la M1 (lo que se ve por la ventana sobre el mar): noche despejada, estrellas
// y una luna creciente grande, como la de la alfombra. La luna está donde apunta la luz
// direccional de la escena (la luz de luna): se mueve rotando esa luz.

uniform vec3 zenith_color : source_color = vec3(0.006, 0.01, 0.035);
uniform vec3 horizon_color : source_color = vec3(0.07, 0.1, 0.2);
// Brillo pálido sobre el horizonte, más fuerte del lado de la luna.
uniform vec3 horizon_glow_color : source_color = vec3(0.16, 0.2, 0.32);
uniform float horizon_glow : hint_range(0.0, 3.0) = 0.8;
uniform vec3 moon_color : source_color = vec3(1.0, 0.94, 0.78);
// Tamaño de la luna (radianes: 0.09 ≈ 5°, unas 10 lunas reales: es un sueño).
uniform float moon_size : hint_range(0.01, 0.4) = 0.09;
uniform float moon_energy : hint_range(0.0, 20.0) = 4.0;
// Creciente: cuánto tapa la "sombra" (0 = luna llena) y hacia dónde.
uniform float crescent : hint_range(0.0, 1.0) = 0.62;
uniform float crescent_angle : hint_range(-3.15, 3.15) = 0.6;
uniform float halo_strength : hint_range(0.0, 2.0) = 0.35;
uniform float halo_size : hint_range(0.05, 1.5) = 0.45;
uniform float star_density : hint_range(0.0, 0.05) = 0.006;
uniform float star_brightness : hint_range(0.0, 10.0) = 2.5;
// Si no hay luz direccional, la luna va acá.
uniform vec3 fallback_moon_dir = vec3(-0.85, 0.35, 0.4);

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 md = normalize(LIGHT0_ENABLED ? LIGHT0_DIRECTION : fallback_moon_dir);
	float up = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, zenith_color, pow(up, 0.45));
	float toward_moon = dot(normalize(vec3(d.x, 0.0, d.z) + 1e-4), normalize(vec3(md.x, 0.0, md.z) + 1e-4)) * 0.5 + 0.5;
	col += horizon_glow_color * horizon_glow * exp(-abs(d.y) * 9.0) * (0.35 + 0.65 * toward_moon * toward_moon);

	// Estrellas: celdas en la dirección; cada celda tiene, o no, una estrella.
	vec3 cell = floor(d * 220.0);
	if (hash3(cell) < star_density && d.y > 0.02) {
		vec3 center = (cell + 0.5 + (vec3(hash3(cell + 1.3), hash3(cell + 2.7), hash3(cell + 4.1)) - 0.5) * 0.6) / 220.0;
		float s = smoothstep(0.0045, 0.0, length(d - normalize(center)));
		col += vec3(0.8, 0.86, 1.0) * s * star_brightness * (0.4 + hash3(cell + 9.0)) * smoothstep(0.02, 0.15, d.y);
	}

	// Luna creciente con halo.
	float ang = acos(clamp(dot(d, md), -1.0, 1.0));
	vec3 side = normalize(cross(md, vec3(0.0, 1.0, 0.0)) + 1e-4);
	vec3 upv = cross(side, md);
	vec3 shift_dir = side * cos(crescent_angle) + upv * sin(crescent_angle);
	vec3 shadow_center = normalize(md + shift_dir * moon_size * (1.0 - crescent) * 1.6);
	float disc = smoothstep(moon_size, moon_size * 0.92, ang);
	float shadow = smoothstep(moon_size * 0.98, moon_size * 0.9, acos(clamp(dot(d, shadow_center), -1.0, 1.0)));
	float lit = disc * (1.0 - shadow * step(0.001, crescent));
	col += moon_color * moon_energy * lit;
	col += moon_color * halo_strength * exp(-ang / halo_size) * 0.5;
	COLOR = col;
}
