class_name RepeatingPhotos
extends Node3D
## La misma foto familiar repetida a lo largo del pasillo de la M3, alternando paredes. Cuanto más
## adentro del pasillo, más borrosa y más torcida; con la casa degradada, todas se borran más.
## Arma las fotos por código (cuadro + foto) para cubrir el pasillo aunque se estire, y cada vez
## que el pasillo cambia de forma o de largo las vuelve a ubicar a lo largo de las paredes (no pone
## fotos en las esquinas). Va como hijo del BendingHallway, en su origen.

const SHADER: Shader = preload("res://assets/shaders/memory_photo.gdshader")

@export var settings: Memory3Settings
@export var hallway: BendingHallway
## Cartel de etapa 0 sobre la primera foto (vacío = sin cartel).
@export var label_text: String = "FOTO (se repite, cada vez más borrosa)"
@export var frame_material: Material

var _photos: Array[Node3D] = []
var _materials: Array[ShaderMaterial] = []
var _distances: Array[float] = []
var _tilt_signs: Array[float] = []
var _degradation: float = 0.0


func _ready() -> void:
	assert(settings != null and hallway != null, "RepeatingPhotos: faltan el Memory3Settings y el BendingHallway")
	var longest: float = settings.longest_shape_length() + settings.hallway_extra_length + settings.hallway_creep_max
	var count: int = ceili(maxf(longest - settings.photo_first_distance, 0.0) / settings.photo_spacing) + 1
	for i: int in count:
		_add_photo(i)
	hallway.layout_changed.connect(_relayout)
	# Este nodo es hijo del pasillo, así que está listo antes que él: espera a que el pasillo se arme.
	_relayout.call_deferred()
	_update_blur()


## La casa se degrada (0..1): todas las fotos se borran un poco más.
func set_degradation(value: float) -> void:
	_degradation = clampf(value, 0.0, 1.0)
	_update_blur()


func _add_photo(i: int) -> void:
	var distance: float = settings.photo_first_distance + i * settings.photo_spacing
	var photo: Node3D = Node3D.new()
	photo.name = "Photo%d" % i
	add_child(photo)

	var frame: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(0.34, 0.42, 0.03)
	frame.mesh = frame_mesh
	frame.material_override = frame_material
	frame.position.z = -0.005
	photo.add_child(frame)

	var picture: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.26, 0.34)
	picture.mesh = quad
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("use_texture", settings.photo_texture != null)
	if settings.photo_texture != null:
		material.set_shader_parameter("photo_tex", settings.photo_texture)
	picture.material_override = material
	picture.position.z = 0.012
	photo.add_child(picture)

	if i == 0 and label_text != "":
		var label: Label3D = Label3D.new()
		label.text = label_text
		label.pixel_size = 0.0025
		label.font_size = 18
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.0, 0.32, 0.05)
		photo.add_child(label)

	_photos.append(photo)
	_materials.append(material)
	_distances.append(distance)
	_tilt_signs.append(randf_range(-1.0, 1.0))


## Ubica cada foto en la pared a su distancia (se alternan las paredes: izquierda, derecha...).
## Las que caen en una esquina o más allá del final del pasillo no se muestran.
func _relayout() -> void:
	for i: int in _photos.size():
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var spot: Variant = null
		if _distances[i] < hallway.path_length - 0.4:
			spot = hallway.wall_spot(_distances[i], side, settings.photo_height)
		_photos[i].visible = spot != null
		if spot != null:
			_photos[i].transform = spot
	# La posición pisa la inclinación: se vuelve a torcer.
	_update_blur()


func _update_blur() -> void:
	for i: int in _photos.size():
		var blur: float = clampf(settings.photo_blur_start + _distances[i] * settings.photo_blur_per_meter \
			+ _degradation * settings.photo_blur_degradation, 0.0, 1.0)
		_materials[i].set_shader_parameter("blur", blur)
		_photos[i].rotation_degrees.z = _tilt_signs[i] * settings.photo_max_tilt * blur
