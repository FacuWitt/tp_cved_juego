// La cara borrosa de la hija (M3): en lugar de taparla con algo, desenfoca lo que hay detrás.
// Va en una esfera chica delante de la cara. Lee la imagen ya dibujada (la cara), la toma con
// menos detalle (un mipmap más chico = más borrosa) y se funde con los bordes de la esfera, así no
// se ve el contorno ni parece una burbuja o un casco.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
/// Cuánto se desenfoca (0 = nítido; cada punto más es la mitad de detalle).
uniform float blur_amount : hint_range(0.0, 6.0) = 3.5;
/// Qué tan suave es el borde (más alto = el desenfoque se apaga antes hacia los bordes).
uniform float edge_softness : hint_range(0.05, 1.0) = 0.7;
/// Tinte que se mezcla con lo desenfocado (alfa = cuánto). Sirve para "lavar" un poco los rasgos.
uniform vec4 wash : source_color = vec4(0.9, 0.78, 0.7, 0.15);

void fragment() {
	vec3 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount).rgb;
	// NORMAL y VIEW están en espacio de cámara: 1 de frente, 0 en el borde de la esfera.
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = mix(blurred, wash.rgb, wash.a);
	ALPHA = smoothstep(0.0, edge_softness, facing);
}
