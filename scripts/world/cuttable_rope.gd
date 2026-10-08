class_name CuttableRope
extends Node3D
## Soga de la red, tensa entre el cabrestante y el mar. El jugador la corta con el evento rápido.
## Se arma sola con dos tramos (lado cabrestante y lado mar) que se separan al cortarse.
## No decide cuándo se corta: recibe `add_hit()` y `sever()` de quien maneja la escena.

## El jugador entró o salió de la zona donde puede cortarla.
signal player_range_changed(in_range: bool)
## Recibió un golpe. `hits` es el total hasta ahora.
signal hit_taken(hits: int)
## La soga se cortó.
signal severed

## Punto de la soga en el cabrestante, en coordenadas locales.
@export var winch_point: Vector3 = Vector3(0.0, 0.9, -3.0)
## Punto donde se corta (el borde de la rampa).
@export var cut_point: Vector3 = Vector3(0.0, -0.4, 4.0)
## Punto donde la soga entra al mar.
@export var water_point: Vector3 = Vector3(0.0, -2.6, 22.0)
@export_range(0.02, 0.3, 0.005, "suffix:m") var radius: float = 0.07
## Desde qué distancia al punto de corte el jugador puede cortarla.
@export_range(0.5, 5.0, 0.1, "suffix:m") var interaction_radius: float = 1.7
@export var rope_color: Color = Color(0.55, 0.47, 0.32)
## Color al irse deshilachando.
@export var frayed_color: Color = Color(0.9, 0.82, 0.6)

var hits: int = 0
var is_severed: bool = false
var player_in_range: bool = false

var _material: StandardMaterial3D
var _winch_pivot: Node3D
var _sea_pivot: Node3D
var _area: Area3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = rope_color
	_material.roughness = 0.95
	_winch_pivot = _make_segment("WinchSide", cut_point, winch_point)
	_sea_pivot = _make_segment("SeaSide", cut_point, water_point)
	_area = Area3D.new()
	_area.name = "CutZone"
	_area.position = cut_point
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = interaction_radius
	shape.shape = sphere
	_area.add_child(shape)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


## Registra un golpe: la soga se estremece y se ve más deshilachada.
func add_hit() -> void:
	if is_severed:
		return
	hits += 1
	_material.albedo_color = rope_color.lerp(frayed_color, minf(float(hits) * 0.4, 1.0))
	_material.emission_enabled = true
	_material.emission = frayed_color * 0.12 * float(hits)
	var shake: Tween = create_tween()
	for i: int in 6:
		var offset: Vector3 = Vector3(randf_range(-0.05, 0.05), randf_range(-0.04, 0.04), 0.0)
		shake.tween_property(_sea_pivot, "position", cut_point + offset, 0.03)
	shake.tween_property(_sea_pivot, "position", cut_point, 0.04)
	hit_taken.emit(hits)


## Corta la soga: el tramo del mar sale disparado y el del cabrestante cae flojo.
func sever() -> void:
	if is_severed:
		return
	is_severed = true
	if player_in_range:
		player_in_range = false
		player_range_changed.emit(false)
	_area.set_deferred("monitoring", false)
	var sea: Tween = create_tween()
	sea.tween_property(_sea_pivot, "rotation:x", -0.8, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sea.tween_property(_sea_pivot, "rotation:x", 1.5, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var winch: Tween = create_tween()
	winch.tween_property(_winch_pivot, "rotation:x", 0.35, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	winch.tween_property(_winch_pivot, "rotation:x", -0.3, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	severed.emit()


## Punto del mundo donde se corta (para apuntar la cámara, chispas, etc.).
func get_cut_position() -> Vector3:
	return to_global(cut_point)


func _make_segment(segment_name: String, from_point: Vector3, to_point: Vector3) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = segment_name
	pivot.position = from_point
	add_child(pivot)
	var direction: Vector3 = to_point - from_point
	var length: float = direction.length()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = 6
	cylinder.rings = 1
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = _material
	mesh_instance.position = direction * 0.5
	mesh_instance.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	pivot.add_child(mesh_instance)
	return pivot


func _on_body_entered(body: Node3D) -> void:
	if is_severed or not (body is Player):
		return
	player_in_range = true
	player_range_changed.emit(true)


func _on_body_exited(body: Node3D) -> void:
	if not (body is Player) or not player_in_range:
		return
	player_in_range = false
	player_range_changed.emit(false)
