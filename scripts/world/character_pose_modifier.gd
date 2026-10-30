@tool
extends SkeletonModifier3D
## Lo crea `CharacterRig` como hijo del Skeleton3D del modelo. Aplica los giros que calcula
## el rig: cada giro está en los ejes del personaje y se convierte al espacio de cada hueso.
## Como es un modificador, el resultado no se guarda en la escena (el esqueleto vuelve a su
## reposo cada cuadro).

var rig: Node3D


func _process_modification_with_delta(delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if rig == null or skeleton == null or not is_instance_valid(rig):
		return
	var bones: Dictionary[StringName, Vector3] = rig.call("compute_bones", delta)
	if bones.is_empty():
		return
	# Del espacio del esqueleto al del personaje.
	var to_char: Basis = (rig.global_basis.orthonormalized().inverse() * skeleton.global_basis.orthonormalized()).orthonormalized()
	var from_char: Basis = to_char.inverse()
	for bone_name: StringName in bones:
		var idx: int = skeleton.find_bone(bone_name)
		if idx < 0:
			continue
		var e: Vector3 = bones[bone_name]
		var r_char: Basis = Basis.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))
		var r_skel: Basis = from_char * r_char * to_char
		var rest_global: Basis = skeleton.get_bone_global_rest(idx).basis.orthonormalized()
		var local_delta: Basis = (rest_global.inverse() * r_skel * rest_global).orthonormalized()
		var rest_local: Quaternion = skeleton.get_bone_rest(idx).basis.orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(idx, (rest_local * local_delta.get_rotation_quaternion()).normalized())
