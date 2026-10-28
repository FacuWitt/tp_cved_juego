class_name AnchorWinch
extends Node3D
## El malacate del ancla (M4): se sube apretando (E) repetidamente frente a la manivela.
## Si el jugador afloja, el peso del ancla la vuelve a bajar de a poco.
## Hijos que espera (están en scenes/props/anchor_winch.tscn y se mueven en el editor):
##   CrankPivot (gira en su eje X), DrumPoint (de donde sale la soga), Pulley (el bloque del
##   pórtico de donde cuelga la soga), AnchorBottom y AnchorTop (dónde está el ancla abajo, en el
##   agua, y arriba: va en línea recta de uno al otro), Anchor (el ancla), StandPoint (dónde se
##   para el jugador, mirando a la manivela), AimArea (a qué hay que apuntar con la mira).

## El ancla llegó arriba.
signal raised

@export var settings: AnchorWinchSettings

## 0 = abajo, 1 = arriba.
var progress: float = 0.0
## Si es true el ancla responde y se resbala (la memoria lo prende cuando toca subirla).
var is_active: bool = false
var is_raised: bool = false

var _angle: float = 0.0
var _since_press: float = 99.0
var _time: float = 0.0
var _rope_up: MeshInstance3D
var _rope_down: MeshInstance3D

@onready var _pivot: Node3D = $CrankPivot
@onready var _drum: Node3D = $DrumPoint
@onready var _pulley: Node3D = $Pulley
@onready var _anchor_top: Node3D = $AnchorTop
@onready var _anchor_bottom: Node3D = $AnchorBottom
@onready var _anchor: Node3D = $Anchor
@onready var stand_point: Node3D = $StandPoint
@onready var aim_area: Area3D = $AimArea


func _ready() -> void:
	assert(settings != null, "AnchorWinch: falta el AnchorWinchSettings")
	aim_area.set_meta("winch", self)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.3, 0.22)
	mat.roughness = 0.9
	_rope_up = _make_rope(mat)
	_rope_down = _make_rope(mat)
	_update_visuals()


## Una apretada de (E).
func press() -> void:
	if not is_active or is_raised:
		return
	_since_press = 0.0
	progress = minf(progress + settings.progress_per_press, 1.0)
	if progress >= 1.0:
		is_raised = true
		raised.emit()


## SOLO PARA PRUEBAS: la sube de una.
func complete_now() -> void:
	if is_raised:
		return
	progress = 1.0
	is_raised = true
	raised.emit()


## Está bajando porque el jugador aflojó.
func is_slipping() -> bool:
	return is_active and not is_raised and progress > 0.0 and _since_press > settings.slip_delay


func _process(delta: float) -> void:
	_time += delta
	_since_press += delta
	if is_slipping():
		progress = maxf(progress - settings.slip_speed * delta, 0.0)
	_update_visuals(delta)


func _update_visuals(delta: float = 0.0) -> void:
	var target: float = progress * settings.crank_turns * TAU * float(settings.crank_direction)
	_angle = target if delta <= 0.0 else lerpf(_angle, target, 1.0 - exp(-settings.crank_follow * delta))
	_pivot.rotation.x = _angle
	_anchor.position = _anchor_bottom.position.lerp(_anchor_top.position, progress)
	var sway: float = deg_to_rad(settings.anchor_sway) * sin(_time * settings.anchor_sway_rate * TAU)
	_anchor.rotation = Vector3(sway * 0.4, _time * 0.2, sway)
	_place_rope(_rope_up, _drum.global_position, _pulley.global_position)
	_place_rope(_rope_down, _pulley.global_position, _anchor.global_position)


func _make_rope(mat: Material) -> MeshInstance3D:
	var rope: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = settings.rope_radius
	mesh.bottom_radius = settings.rope_radius
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 1
	rope.mesh = mesh
	rope.material_override = mat
	rope.top_level = true
	add_child(rope)
	return rope


## Estira un cilindro de alto 1 entre dos puntos.
func _place_rope(rope: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.01:
		rope.visible = false
		return
	rope.visible = true
	var y: Vector3 = dir / length
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	rope.global_transform = Transform3D(Basis(x, y * length, z), (a + b) * 0.5)
