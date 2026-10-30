class_name RemosFishingRod
extends Node3D
## Caña de pescar de un bote: echada (apunta al agua, con hilo y flotador) o guardada (acostada a lo largo del bote).
## La usan el bote del jugador y el del padre en la escena de pesca del principio de la Memoria 2.

## Lado hacia el que se echa la caña: 1 = derecha del bote, -1 = izquierda.
@export_range(-1.0, 1.0, 2.0) var side: float = 1.0
@export_range(0.5, 4.0, 0.05, "suffix:m") var length: float = 2.4
## Cuánto se aleja el flotador del bote (hacia adelante y hacia el costado).
@export var float_offset: Vector2 = Vector2(3.0, 3.2)
## Ángulo hacia arriba y hacia el costado de la caña echada.
@export_range(0.0, 80.0, 1.0, "suffix:°") var cast_pitch: float = 38.0
@export_range(0.0, 80.0, 1.0, "suffix:°") var cast_yaw: float = 28.0

var is_cast: bool = false

var _pivot: Node3D
var _line: MeshInstance3D
var _bobber: MeshInstance3D
var _bobber_base: Vector3
var _time: float = 0.0
var _blend: float = 0.0
var _tween: Tween


func _ready() -> void:
	_build()
	_apply_pose(0.0)


## Echa la caña al agua (si duration es 0 queda de golpe).
func cast(duration: float = 1.2) -> void:
	is_cast = true
	_animate(1.0, duration)


## La guarda: baja la caña y saca el hilo.
func stow(duration: float = 1.5) -> void:
	is_cast = false
	_animate(0.0, duration)


func _animate(target: float, duration: float) -> void:
	if _tween != null:
		_tween.kill()
	if duration <= 0.0:
		_apply_pose(target)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_pose, _blend, target, duration)


func _process(delta: float) -> void:
	_time += delta
	if _blend > 0.01:
		# El flotador sube y baja con el agua y la punta de la caña vibra apenas.
		_bobber.position = _bobber_base + Vector3(0.0, sin(_time * 1.7 + side) * 0.025, 0.0)
		_pivot.rotation.x += sin(_time * 2.3) * 0.0006 * _blend
		_update_line()


func _apply_pose(blend: float) -> void:
	_blend = blend
	# Guardada: acostada hacia atrás y pegada al bote. Echada: hacia adelante, arriba y al costado.
	_pivot.rotation = Vector3(
		lerpf(deg_to_rad(4.0), deg_to_rad(cast_pitch), blend),
		lerpf(deg_to_rad(side * 4.0), deg_to_rad(-side * cast_yaw), blend),
		0.0)
	_line.visible = blend > 0.6
	_bobber.visible = blend > 0.6
	if _line.visible:
		_update_line()


func _update_line() -> void:
	var tip: Vector3 = _pivot.position + _pivot.basis * Vector3(0.0, 0.0, -length)
	var bob: Vector3 = _bobber.position
	var dir: Vector3 = bob - tip
	var dist: float = maxf(dir.length(), 0.01)
	_line.position = (tip + bob) * 0.5
	_line.basis = Basis.looking_at(dir / dist, Vector3.UP)
	(_line.mesh as BoxMesh).size = Vector3(0.006, 0.006, dist)


func _build() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	var rod: MeshInstance3D = MeshInstance3D.new()
	rod.name = "Rod"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.02
	cyl.height = length
	cyl.radial_segments = 5
	rod.mesh = cyl
	# El cilindro crece en Y: se acuesta para que apunte hacia -Z (adelante) y se corre para que el mango quede en el pivote.
	rod.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	rod.position = Vector3(0.0, 0.0, -length * 0.5)
	var wood: StandardMaterial3D = StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.25, 0.14)
	wood.roughness = 0.8
	rod.material_override = wood
	_pivot.add_child(rod)
	_line = MeshInstance3D.new()
	_line.name = "Line"
	_line.mesh = BoxMesh.new()
	var thread: StandardMaterial3D = StandardMaterial3D.new()
	thread.albedo_color = Color(0.85, 0.88, 0.9, 0.7)
	thread.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	thread.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line.material_override = thread
	add_child(_line)
	_bobber = MeshInstance3D.new()
	_bobber.name = "Bobber"
	var ball: SphereMesh = SphereMesh.new()
	ball.radius = 0.05
	ball.height = 0.1
	ball.radial_segments = 8
	ball.rings = 4
	_bobber.mesh = ball
	var red: StandardMaterial3D = StandardMaterial3D.new()
	red.albedo_color = Color(0.9, 0.18, 0.1)
	red.emission_enabled = true
	red.emission = Color(0.9, 0.2, 0.1)
	red.emission_energy_multiplier = 0.6
	_bobber.material_override = red
	# El flotador cae sobre el agua: el mango está a la altura de la mano, el agua queda más abajo.
	_bobber_base = Vector3(side * float_offset.x, -position.y, -float_offset.y)
	_bobber.position = _bobber_base
	add_child(_bobber)
