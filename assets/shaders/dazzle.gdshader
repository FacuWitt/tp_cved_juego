shader_type canvas_item;
render_mode blend_add;

// Encandilamiento: un destello radial grande donde está la luz en pantalla
// más un velo blanco general que crece con la fuerza.

uniform vec2 center = vec2(0.5, 0.5);
uniform float strength = 0.0;
uniform float aspect = 1.7778;
uniform vec3 tint : source_color = vec3(1.0, 0.96, 0.86);

void fragment() {
	vec2 d = (UV - center) * vec2(aspect, 1.0);
	float r = length(d);
	float core = exp(-r * 5.5);
	float bloom = exp(-r * 1.6);
	float wash = 0.55;
	float v = strength * (wash * 0.5 + bloom * 0.9 + core * 1.4);
	COLOR = vec4(tint * v, 1.0);
}
