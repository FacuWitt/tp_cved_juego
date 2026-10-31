class_name BendingHallway
extends Node3D
## Pasillo que dobla y se estira (M3). Sale del origen del nodo hacia adelante (-Z local) y sigue
## una forma escrita como texto: tramos rectos en metros y giros de 90° ("4 L 3 R 5" = 4 m,
## dobla a la izquierda, 3 m, dobla a la derecha, 5 m). Se arma "cavando" huecos en un bloque
## macizo (CSG), así las paredes y las esquinas salen solas para cualquier forma.
## Al final del último tramo pone el rellano (`far_end`: puertas, umbrales, luz) y cava detrás
## de cada puerta un tramo oscuro. El último tramo es el que se estira.
## No sabe por qué cambia: la memoria le pide la forma, el ancho, el alto y cuánto estirarse.

## Se volvió a armar (cambió la forma o el largo): lo que cuelga de las paredes se reubica.
signal layout_changed

## Lo que está al final del pasillo (el rellano con las puertas). Su origen queda en el final
## del último tramo, mirando hacia donde sigue el pasillo.
@export var far_end: Node3D
## Material de las paredes, el piso y el techo del pasillo y del rellano.
@export var hall_material: Material
## Material de los tramos oscuros detrás de las puertas.
@export var dark_material: Material
## Material de la cara de afuera del bloque (se puede ver de lejos por alguna ventana).
@export var outside_material: Material
@export var light_color: Color = Color(0.45, 0.7, 0.65)
## Intensidad de cada luz fría del pasillo (la memoria la multiplica con la degradación).
@export_range(0.0, 5.0, 0.05) var light_energy: float = 0.5
## Distancia entre luces del techo.
@export_range(1.0, 10.0, 0.1, "suffix:m") var light_spacing: float = 4.0
@export_range(1.0, 10.0, 0.1, "suffix:m") var light_range: float = 4.5
## Tamaño del bloque macizo donde se cava (tiene que entrar el pasillo más largo, con el rellano).
@export var block_size: Vector3 = Vector3(26.0, 3.6, 44.0)
## Posición (x local del rellano) de cada puerta. Tiene que coincidir con las puertas de `far_end`.
@export var door_offsets: PackedFloat32Array = PackedFloat32Array([-2.5, 0.0, 2.5])
@export var landing_size: Vector3 = Vector3(7.0, 2.6, 2.4)
@export var vestibule_size: Vector3 = Vector3(1.1, 2.3, 3.0)
@export var door_hole_size: Vector3 = Vector3(1.0, 2.1, 0.4)
@export_range(0.05, 1.0, 0.01, "suffix:m") var wall_thickness: float = 0.2

## Largo total del pasillo (sin el rellano).
var path_length: float = 0.0
var width: float = 1.6
var height: float = 2.6

var _lengths: Array[float] = [8.0]
var _turns: Array[int] = []
var _extra: float = 0.0
## Cada tramo: {"from": Vector3, "dir": Vector3, "length": float, "start": float} en coordenadas locales.
var _pieces: Array[Dictionary] = []
var _combiner: CSGCombiner3D
var _piece_boxes: Array[CSGBox3D] = []
var _landing_boxes: Array[CSGBox3D] = []
var _lights: Array[OmniLight3D] = []
var _light_scale: float = 1.0


func _ready() -> void:
	assert(far_end != null, "BendingHallway: falta far_end (el rellano)")
	_combiner = CSGCombiner3D.new()
	_combiner.name = "Carved"
	_combiner.use_collision = true
	add_child(_combiner)
	var solid: CSGBox3D = CSGBox3D.new()
	solid.size = block_size
	solid.position = Vector3(0.0, block_size.y * 0.5 - wall_thickness, -block_size.z * 0.5)
	solid.material = outside_material
	_combiner.add_child(solid)
	# Rellano, los tres huecos de las puertas y los tres tramos oscuros.
	_landing_boxes.append(_make_air(hall_material))
	for i: int in door_offsets.size():
		_landing_boxes.append(_make_air(hall_material))
	for i: int in door_offsets.size():
		_landing_boxes.append(_make_air(dark_material))
	rebuild()


## Cambia la forma del pasillo ("4 L 3 R 5"), su ancho libre y su alto, y lo vuelve a armar.
func set_shape(shape: String, new_width: float, new_height: float) -> void:
	_lengths.clear()
	_turns.clear()
	for token: String in shape.strip_edges().split(" ", false):
		var t: String = token.to_upper()
		if t == "L" or t == "I":
			_turns.append(1)
		elif t == "R" or t == "D":
			_turns.append(-1)
		elif t.is_valid_float():
			# Si hay dos giros seguidos sin tramo en el medio, se agrega un tramo mínimo.
			while _turns.size() > _lengths.size():
				_lengths.append(new_width)
			_lengths.append(maxf(t.to_float(), new_width))
		else:
			push_warning("BendingHallway: no se entiende '%s' en la forma '%s'" % [token, shape])
	if _lengths.is_empty():
		_lengths.append(8.0)
	while _turns.size() >= _lengths.size():
		_turns.pop_back()
	width = new_width
	height = new_height
	rebuild()


## Cuánto más largo es el último tramo (la casa degradada, el fondo que se aleja al caminar).
func set_extra_length(value: float) -> void:
	_extra = maxf(value, 0.0)
	rebuild()


## Multiplica la intensidad de las luces del pasillo (la degradación las hace más fuertes).
func set_light_scale(value: float) -> void:
	_light_scale = value
	for light: OmniLight3D in _lights:
		light.light_energy = light_energy * _light_scale


func rebuild() -> void:
	if _combiner == null:
		return
	_pieces.clear()
	var pos: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3.FORWARD
	var start: float = 0.0
	for i: int in _lengths.size():
		var length: float = _lengths[i] + (_extra if i == _lengths.size() - 1 else 0.0)
		_pieces.append({"from": pos, "dir": dir, "length": length, "start": start})
		pos += dir * length
		start += length
		if i < _turns.size():
			dir = dir.rotated(Vector3.UP, PI * 0.5 * _turns[i]).round()
	path_length = start

	while _piece_boxes.size() < _pieces.size():
		_piece_boxes.append(_make_air(hall_material))
	# Si la forma nueva tiene menos tramos, sobran huecos: se sacan.
	while _piece_boxes.size() > _pieces.size():
		_piece_boxes.pop_back().queue_free()
	for i: int in _pieces.size():
		var box: CSGBox3D = _piece_boxes[i]
		var piece: Dictionary = _pieces[i]
		# Cada tramo se alarga medio ancho hacia los dos lados, así las esquinas quedan cavadas.
		# El primero no se alarga para atrás (ahí está la cocina) ni el último para adelante (el rellano).
		var back: float = 0.0 if i == 0 else width * 0.5
		var ahead: float = 0.0 if i == _pieces.size() - 1 else width * 0.5
		var from: Vector3 = piece["from"]
		var d: Vector3 = piece["dir"]
		var length: float = piece["length"]
		var center: float = (length + ahead - back) * 0.5
		box.size = Vector3(width, height, length + ahead + back)
		box.transform = Transform3D(Basis.looking_at(d), from + d * center + Vector3.UP * height * 0.5)

	far_end.transform = Transform3D(Basis.looking_at(dir), pos)
	_place_landing()
	_place_lights()
	layout_changed.emit()


## Si un punto (global) está adentro del pasillo (no en el rellano).
func contains(point: Vector3) -> bool:
	return not _piece_at(to_local(point)).is_empty()


## Qué tan adentro del pasillo está un punto: 0 = en la entrada (o afuera), 1 = llegando al rellano.
func progress(point: Vector3) -> float:
	var local: Vector3 = to_local(point)
	var piece: Dictionary = _piece_at(local)
	if piece.is_empty() or path_length <= 0.0:
		return 0.0
	var along: float = (local - (piece["from"] as Vector3)).dot(piece["dir"])
	return clampf((float(piece["start"]) + along) / path_length, 0.0, 1.0)


## Cuántos metros de pasillo hay desde la entrada hasta el punto (global), o -1 si no está en el pasillo.
func distance_along(point: Vector3) -> float:
	var local: Vector3 = to_local(point)
	var piece: Dictionary = _piece_at(local)
	if piece.is_empty():
		return -1.0
	var along: float = (local - (piece["from"] as Vector3)).dot(piece["dir"])
	return maxf(float(piece["start"]) + along, 0.0)


## El corte del pasillo a `distance` metros de la entrada: origen en el piso, en el medio, mirando
## hacia donde avanza el pasillo (su -Z). En coordenadas locales del pasillo. Devuelve null si cae
## cerca de una esquina o fuera del pasillo.
func section_at(distance: float) -> Variant:
	for i: int in _pieces.size():
		var piece: Dictionary = _pieces[i]
		var along: float = distance - float(piece["start"])
		var length: float = piece["length"]
		if along < 0.0 or along > length:
			continue
		var margin: float = width * 0.75
		if (i > 0 and along < margin) or (i < _pieces.size() - 1 and along > length - margin):
			return null
		var d: Vector3 = piece["dir"]
		return Transform3D(Basis.looking_at(d), (piece["from"] as Vector3) + d * along)
	return null


## Hacia dónde avanza el pasillo en el punto (global), o cero si el punto no está en el pasillo.
func forward_at(point: Vector3) -> Vector3:
	var piece: Dictionary = _piece_at(to_local(point))
	if piece.is_empty():
		return Vector3.ZERO
	return global_transform.basis * (piece["dir"] as Vector3)


## Un lugar en la pared, a `distance` metros desde la entrada, del lado `side` (-1 izquierda, 1 derecha),
## a `y` metros de altura, mirando hacia el centro del pasillo (su +Z). Devuelve null si cae cerca
## de una esquina o fuera del pasillo.
func wall_spot(distance: float, side: float, y: float) -> Variant:
	for i: int in _pieces.size():
		var piece: Dictionary = _pieces[i]
		var along: float = distance - float(piece["start"])
		var length: float = piece["length"]
		if along < 0.0 or along > length:
			continue
		var margin: float = width * 0.75
		if (i > 0 and along < margin) or (i < _pieces.size() - 1 and along > length - margin):
			return null
		var d: Vector3 = piece["dir"]
		var right: Vector3 = d.cross(Vector3.UP)
		var origin: Vector3 = (piece["from"] as Vector3) + d * along + right * side * (width * 0.5 - 0.01) + Vector3.UP * y
		return Transform3D(Basis.looking_at(right * side), origin)
	return null


func _piece_at(local: Vector3) -> Dictionary:
	for i: int in _pieces.size():
		var piece: Dictionary = _pieces[i]
		var rel: Vector3 = local - (piece["from"] as Vector3)
		var d: Vector3 = piece["dir"]
		var along: float = rel.dot(d)
		var back: float = 0.0 if i == 0 else width * 0.5
		if along >= -back and along <= float(piece["length"]) and absf(rel.dot(d.cross(Vector3.UP))) <= width * 0.5:
			return piece
	return {}


func _place_landing() -> void:
	var frame: Transform3D = far_end.transform
	var n: int = door_offsets.size()
	var room: CSGBox3D = _landing_boxes[0]
	room.size = landing_size
	room.transform = frame * Transform3D(Basis.IDENTITY, Vector3(0.0, landing_size.y * 0.5, -landing_size.z * 0.5))
	var wall_z: float = -landing_size.z - wall_thickness * 0.5
	for i: int in n:
		var hole: CSGBox3D = _landing_boxes[1 + i]
		hole.size = door_hole_size
		hole.transform = frame * Transform3D(Basis.IDENTITY, Vector3(door_offsets[i], door_hole_size.y * 0.5, wall_z))
		var dark: CSGBox3D = _landing_boxes[1 + n + i]
		dark.size = vestibule_size
		dark.transform = frame * Transform3D(Basis.IDENTITY, Vector3(door_offsets[i], vestibule_size.y * 0.5, wall_z - wall_thickness * 0.5 - vestibule_size.z * 0.5))


func _place_lights() -> void:
	var count: int = maxi(1, floori(path_length / light_spacing))
	while _lights.size() < count:
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = light_color
		light.omni_range = light_range
		add_child(light)
		_lights.append(light)
	for i: int in _lights.size():
		var light: OmniLight3D = _lights[i]
		light.visible = i < count
		if not light.visible:
			continue
		light.light_energy = light_energy * _light_scale
		light.position = _point_at((i + 0.5) * light_spacing) + Vector3.UP * (height - 0.3)


func _point_at(distance: float) -> Vector3:
	for piece: Dictionary in _pieces:
		var along: float = distance - float(piece["start"])
		if along <= float(piece["length"]):
			return (piece["from"] as Vector3) + (piece["dir"] as Vector3) * maxf(along, 0.0)
	return far_end.position


func _make_air(material: Material) -> CSGBox3D:
	var box: CSGBox3D = CSGBox3D.new()
	box.operation = CSGShape3D.OPERATION_SUBTRACTION
	box.material = material
	_combiner.add_child(box)
	return box
