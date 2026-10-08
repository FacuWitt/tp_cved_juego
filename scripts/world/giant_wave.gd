class_name GiantWave
extends Node3D
## Ola gigante que avanza hacia el jugador, se enrosca y lo cubre.
## La malla es una grilla plana y el shader (giant_wave.gdshader) calcula tres poses del perfil
## (marejada, pared, barril) y las recorre con el parámetro `curl`. Así el labio "gira"
## sobre su eje mientras la ola avanza, sin animación esqueletal ni modelos externos.
##
## Convención del perfil: u crece hacia el jugador, y hacia arriba. En la malla z = -u,
## o sea que la ola viaja hacia -Z (el jugador mira hacia +Z cuando la ve venir).

## El labio ya está por encima del jugador: lo está cubriendo.
signal covered
## La ola terminó su recorrido.
signal finished

const PROFILE_POINTS: int = 64
const LEAD: int = 6
const FACE: int = 34
const OUTER: int = 8
const SLOPE: int = 16
const SEGMENTS_X: int = 96
## Fracción del radio del barril a la que queda el jugador al terminar (bajo el labio).
const FINAL_U: float = 0.3

@export var settings: Memory4Settings
@export var material: ShaderMaterial

var _mesh_instance: MeshInstance3D
var _radius: float = 14.0
var _progress: float = 0.0
var _covered_emitted: bool = false


func _ready() -> void:
	assert(settings != null and material != null, "GiantWave: faltan settings o material en el Inspector")
	_radius = settings.wave_height * 0.5
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "WaveMesh"
	_mesh_instance.mesh = _build_mesh()
	_mesh_instance.material_override = material
	# El shader mueve los vértices mucho más allá de la malla: si no, el motor la descarta por error.
	# La ola se extiende hacia +Z (espalda, unas 5 alturas) y un poco hacia -Z (el mar llano de entrada).
	_mesh_instance.custom_aabb = AABB(Vector3(-settings.wave_width, -10.0, -settings.wave_height * 1.6), Vector3(settings.wave_width * 2.0, settings.wave_height * 2.5, settings.wave_height * 7.2))
	add_child(_mesh_instance)
	material.set_shader_parameter("glow", settings.wave_glow)
	material.set_shader_parameter("r", _radius)
	material.set_shader_parameter("half_w", settings.wave_width * 0.5)
	material.set_shader_parameter("curl", 0.0)
	visible = false


## Lanza la ola desde `start_z` hasta quedar con el barril sobre `target_z`.
func launch(start_z: float, target_z: float) -> void:
	var end_z: float = target_z + FINAL_U * _radius
	position.z = start_z
	_progress = 0.0
	_covered_emitted = false
	visible = true
	material.set_shader_parameter("curl", 0.0)
	var tween: Tween = create_tween()
	tween.tween_method(
		func(p: float) -> void: _on_progress(p, start_z, end_z),
		0.0, 1.0, settings.wave_time
	)
	tween.tween_callback(func() -> void: finished.emit())


## Esconde la ola (después de cubrir al jugador).
func hide_wave() -> void:
	visible = false


func _on_progress(p: float, start_z: float, end_z: float) -> void:
	_progress = p
	# Con acceleration > 1 la ola va tomando velocidad hacia el final.
	var eased: float = pow(p, settings.wave_acceleration)
	position.z = lerpf(start_z, end_z, eased)
	var curl_amount: float = smoothstep(settings.curl_start, 0.95, p)
	material.set_shader_parameter("curl", curl_amount)
	if p >= 0.97 and not _covered_emitted:
		_covered_emitted = true
		covered.emit()


## Devuelve cuánto avanzó la ola (0..1), para sincronizar efectos de cámara y sonido.
func get_progress() -> float:
	return _progress


# ---------- Malla ----------

## Grilla plana: el shader (giant_wave.gdshader) le da la forma de ola a partir de UV.
## UV.x = posición a lo largo del perfil (0..1), UV.y = posición a lo ancho (0..1).
func _build_mesh() -> ArrayMesh:
	var half_w: float = settings.wave_width * 0.5
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	for ix: int in SEGMENTS_X + 1:
		var fx: float = float(ix) / float(SEGMENTS_X)
		for ip: int in PROFILE_POINTS:
			vertices.append(Vector3(lerpf(-half_w, half_w, fx), 0.0, 0.0))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(ip) / float(PROFILE_POINTS - 1), fx))

	for ix: int in SEGMENTS_X:
		for ip: int in PROFILE_POINTS - 1:
			var i0: int = ix * PROFILE_POINTS + ip
			var i1: int = i0 + 1
			var i2: int = i0 + PROFILE_POINTS
			var i3: int = i2 + 1
			indices.append_array([i0, i2, i1, i1, i2, i3])

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
