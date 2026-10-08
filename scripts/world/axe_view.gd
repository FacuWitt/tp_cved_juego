class_name AxeView
extends Node3D
## El hacha que se ve en primera persona, colgada de la cámara.
## Etapa 0: dos cajas. Se reemplaza por el modelo final sin tocar la lógica.

## Posición de reposo, relativa a la cámara.
@export var rest_position: Vector3 = Vector3(0.38, -0.34, -0.6)
@export var rest_rotation_degrees: Vector3 = Vector3(-8.0, -12.0, -18.0)
## Cuánto sube el hacha antes de bajar el golpe.
@export_range(10.0, 120.0, 1.0, "suffix:°") var raise_angle: float = 55.0
@export_range(0.05, 1.0, 0.01, "suffix:s") var swing_time: float = 0.22


func _ready() -> void:
	position = rest_position
	rotation_degrees = rest_rotation_degrees
	var wood: StandardMaterial3D = StandardMaterial3D.new()
	wood.albedo_color = Color(0.25, 0.16, 0.09)
	wood.roughness = 0.9
	var steel: StandardMaterial3D = StandardMaterial3D.new()
	steel.albedo_color = Color(0.45, 0.48, 0.5)
	steel.metallic = 0.7
	steel.roughness = 0.4
	var handle: MeshInstance3D = MeshInstance3D.new()
	var handle_mesh: BoxMesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.045, 0.55, 0.045)
	handle.mesh = handle_mesh
	handle.material_override = wood
	handle.position = Vector3(0.0, 0.18, 0.0)
	add_child(handle)
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = Vector3(0.05, 0.14, 0.2)
	head.mesh = head_mesh
	head.material_override = steel
	head.position = Vector3(0.0, 0.4, -0.08)
	add_child(head)


## Anima un hachazo: sube y baja de golpe.
func swing() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees:x", rest_rotation_degrees.x + raise_angle, swing_time * 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees:x", rest_rotation_degrees.x - 35.0, swing_time * 0.4) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees:x", rest_rotation_degrees.x, swing_time * 1.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
