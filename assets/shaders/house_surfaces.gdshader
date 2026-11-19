// Piso, paredes y techo con un solo material (texturas PS1 en espacio de mundo).
// Lo usa el pasillo que dobla de la M3 (BendingHallway): se arma cavando un bloque
// CSG con un único material, así que la textura se elige según hacia dónde mira
// cada cara: hacia arriba es piso, hacia abajo es techo y el resto es pared.
// Mapea igual que los StandardMaterial triplanares de pared.tres, piso.tres y
// techo.tres, para que no se note el empalme con las habitaciones.
shader_type spatial;

uniform sampler2D floor_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D wall_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D ceiling_texture : source_color, filter_nearest_mipmap, repeat_enable;
/// Cuántas veces se repite la textura por metro.
uniform float floor_scale : hint_range(0.1, 8.0) = 1.0;
uniform float wall_scale : hint_range(0.1, 8.0) = 1.4;
uniform float ceiling_scale : hint_range(0.1, 8.0) = 0.8;
/// Tinte que multiplica a cada textura (blanco = la textura tal cual).
uniform vec4 floor_tint : source_color = vec4(1.0);
uniform vec4 wall_tint : source_color = vec4(1.0);
uniform vec4 ceiling_tint : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec3 color;
	if (n.y >= n.x && n.y >= n.z) {
		if (world_normal.y > 0.0) {
			color = texture(floor_texture, world_pos.xz * floor_scale).rgb * floor_tint.rgb;
		} else {
			color = texture(ceiling_texture, world_pos.xz * ceiling_scale).rgb * ceiling_tint.rgb;
		}
	} else {
		// Pared: la v va hacia abajo para que la imagen quede derecha.
		vec2 uv = n.x >= n.z ? vec2(world_pos.z, -world_pos.y) : vec2(world_pos.x, -world_pos.y);
		color = texture(wall_texture, uv * wall_scale).rgb * wall_tint.rgb;
	}
	ALBEDO = color;
	ROUGHNESS = roughness;
}
