shader_type canvas_item;
// Fondo de la inspección de objetos: lo que está detrás se desenfoca y se oscurece un poco.
// `amount` va de 0 (sin efecto) a 1 (efecto completo) y lo anima InspectView.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
// Qué tan borroso queda (nivel de detalle de la imagen: más alto = más borroso).
uniform float blur : hint_range(0.0, 6.0) = 2.6;
// Cuánto se oscurece (0 = nada, 1 = negro).
uniform float darken : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	float lod = blur * amount;
	vec2 px = SCREEN_PIXEL_SIZE * pow(2.0, lod);
	vec3 c = vec3(0.0);
	// Nueve muestras alrededor, sobre la imagen ya reducida: desenfoque suave sin bloques.
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			c += textureLod(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px, lod).rgb;
		}
	}
	c /= 9.0;
	COLOR = vec4(c * (1.0 - darken * amount), 1.0);
}
