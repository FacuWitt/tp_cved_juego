shader_type canvas_item;
// Abismo: al mirar hacia abajo estando en el agua, la parte baja de la pantalla se va a negro.
// `look_down` va de 0 (mirando al frente) a 1 (mirando directo hacia abajo: todo negro).
uniform float look_down : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float edge = 1.0 - look_down * 1.35;
	float a = smoothstep(edge, edge + 0.4, UV.y);
	a = max(a, smoothstep(0.85, 1.0, look_down));
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
