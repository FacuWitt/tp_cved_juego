@tool
class_name RiverFlow
extends Path3D
## El cauce: una curva por el medio del lago y del río. Sabe el ancho en cada punto,
## hacia dónde corre el agua y con qué fuerza (más en los rápidos). RiverBuilder arma
## las orillas a partir de esto, y el bote y los hielos le preguntan la corriente.
## La curva arranca en la orilla sur del lago y termina al final del río.

## Largo del lago (desde el comienzo de la curva): forma de elipse.
@export_range(10.0, 300.0, 1.0, "suffix:m") var lake_length: float = 90.0
## Ancho máximo del lago.
@export_range(10.0, 300.0, 1.0, "suffix:m") var lake_width: float = 70.0
## Ancho del río al salir del lago y al final.
@export_range(4.0, 60.0, 0.5, "suffix:m") var river_width_start: float = 17.0
@export_range(4.0, 60.0, 0.5, "suffix:m") var river_width_end: float = 12.0
## Tramo final donde el río se cierra (para que no haya un borde abierto).
@export_range(2.0, 60.0, 1.0, "suffix:m") var end_taper: float = 14.0
## Velocidad de la corriente en el río (en el lago no hay).
@export_range(0.0, 6.0, 0.05, "suffix:m/s") var current_speed: float = 1.0
## Rápidos: cada Vector3 es (desde, hasta, multiplicador de corriente), en metros de curva.
@export var rapids: PackedVector3Array = PackedVector3Array()

var _length_cache: float = -1.0


## Largo total de la curva.
func get_length() -> float:
	if curve == null:
		return 0.0
	return curve.get_baked_length()


## Ancho del agua a esta distancia de curva.
func width_at(offset: float) -> float:
	var length: float = get_length()
	var river_t: float = clampf((offset - lake_length) / maxf(length - lake_length, 1.0), 0.0, 1.0)
	var width: float = lerpf(river_width_start, river_width_end, river_t)
	if offset < lake_length:
		# Elipse del lago, sin quedar nunca más angosto que el río.
		var u: float = (offset / lake_length) * 2.0 - 1.0
		width = maxf(lake_width * sqrt(maxf(1.0 - u * u, 0.0)), width * smoothstep(0.0, 0.35, offset / lake_length))
	var to_end: float = length - offset
	if to_end < end_taper:
		width *= clampf(to_end / end_taper, 0.0, 1.0)
	return width


## Multiplicador de corriente de los rápidos en esta distancia (1 = normal).
func rapids_at(offset: float) -> float:
	var mult: float = 1.0
	for r: Vector3 in rapids:
		var fade: float = 6.0
		if offset > r.x - fade and offset < r.y + fade:
			var k: float = smoothstep(r.x - fade, r.x, offset) * (1.0 - smoothstep(r.y, r.y + fade, offset))
			mult = maxf(mult, lerpf(1.0, r.z, k))
	return mult


## Distancia de curva más cercana a un punto del mundo.
func offset_of(world_pos: Vector3) -> float:
	return curve.get_closest_offset(to_local(world_pos))


## Punto del medio del cauce a esa distancia (en el mundo).
func point_at(offset: float) -> Vector3:
	return to_global(curve.sample_baked(clampf(offset, 0.0, get_length())))


## Dirección del cauce (hacia río abajo) a esa distancia, horizontal.
func tangent_at(offset: float) -> Vector3:
	var a: Vector3 = point_at(offset - 1.0)
	var b: Vector3 = point_at(offset + 1.0)
	var t: Vector3 = Vector3(b.x - a.x, 0.0, b.z - a.z)
	return t.normalized() if t.length() > 0.001 else Vector3.FORWARD


## Velocidad del agua en un punto del mundo (horizontal).
func flow_at(world_pos: Vector3) -> Vector3:
	var offset: float = offset_of(world_pos)
	# En el lago el agua está quieta; arranca al acercarse a la boca del río.
	var start: float = smoothstep(lake_length - 25.0, lake_length + 5.0, offset)
	return tangent_at(offset) * current_speed * rapids_at(offset) * start
