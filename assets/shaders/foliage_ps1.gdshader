shader_type spatial;
render_mode cull_disabled;

// Vegetación PS1 (árboles y arbustos de la M2): textura sin suavizado, alfa recortado y el color
// apagado. Con poca luz los colores pierden saturación: `saturation` y `brightness` lo controlan.
// Lo arma RiverBuilder con los valores de su grupo "Vegetación".

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform float saturation : hint_range(0.0, 1.5) = 0.45;
uniform float brightness : hint_range(0.0, 2.0) = 0.8;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(luma), c.rgb, saturation) * brightness;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
}
