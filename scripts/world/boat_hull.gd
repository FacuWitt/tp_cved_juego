class_name BoatHull
extends RefCounted
## Arma el casco de un bote de remos low-poly (proa en punta, popa recta) sin necesitar un modelo.
## Proa hacia -Z, popa hacia +Z, el agua está en y = 0. Es provisorio: se cambia por un modelo cuando llegue.

const STATIONS: int = 9


## `length` es de proa a popa, `beam` el ancho, `depth` lo que sube el borde sobre la quilla.
static func build(length: float, beam: float, depth: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var bow_z: float = -length * 0.55
	var stern_z: float = length * 0.45
	var rings: Array = []
	for i: int in STATIONS:
		var t: float = float(i) / float(STATIONS - 1)
		var z: float = lerpf(bow_z, stern_z, t)
		var half: float = beam * 0.5 * _width_profile(t)
		var end_factor: float = pow(absf(t - 0.5) * 2.0, 2.0)
		var keel: float = -depth * 0.28 + depth * 0.22 * end_factor
		var gunwale: float = depth * 0.72 + depth * 0.14 * end_factor
		rings.append({
			"gl": Vector3(-half, gunwale, z),
			"cl": Vector3(-half * 0.74, keel + depth * 0.2, z),
			"k": Vector3(0.0, keel, z),
			"cr": Vector3(half * 0.74, keel + depth * 0.2, z),
			"gr": Vector3(half, gunwale, z),
		})
	var order: Array[String] = ["gl", "cl", "k", "cr", "gr"]
	for i: int in STATIONS - 1:
		var a: Dictionary = rings[i]
		var b: Dictionary = rings[i + 1]
		for j: int in order.size() - 1:
			var k0: String = order[j]
			var k1: String = order[j + 1]
			_quad(st, a[k0], a[k1], b[k1], b[k0])
	# Espejo de popa.
	var last: Dictionary = rings[STATIONS - 1]
	_quad(st, last["gl"], last["cl"], last["cr"], last["gr"])
	st.generate_normals()
	return st.commit()


static func _width_profile(t: float) -> float:
	if t < 0.4:
		return lerpf(0.07, 1.0, sin(t / 0.4 * PI * 0.5))
	if t < 0.82:
		return 1.0
	return lerpf(1.0, 0.78, (t - 0.82) / 0.18)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)
