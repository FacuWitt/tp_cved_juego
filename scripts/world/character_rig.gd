@tool
class_name CharacterRig
extends Node3D
## Personaje con esqueleto sin animaciones: lo posa por código según un `CharacterPose`
## (pose base, respiración, ciclo de remar, gesto al hablar y cabeza que mira a un objetivo).
## El modelo va como hijo (por ejemplo, el .glb del hombre). Funciona también en el editor,
## así la pose se ve y se ajusta desde el Inspector sin darle Play.
##
## Habla cuando la línea de los subtítulos empieza con `speaker_prefix` ("PADRE", "TRIPULANTE"):
## no hace falta que la memoria le avise.

@export var pose: CharacterPose:
	set(value):
		pose = value
		update_configuration_warnings()
## Subtítulos de la memoria (para saber cuándo habla). Opcional.
@export var subtitles: Label
## Con qué empiezan sus líneas en los subtítulos.
@export var speaker_prefix: String = ""
## A quién mira (opcional). Si no hay, mira al frente.
@export var look_target: Node3D

## Valor del ciclo de -1 a 1 (lo pone otro script si `pose.cycle_auto` es false).
var cycle_value: float = 0.0
## Cuánto del ciclo se aplica (0 = quieto en la pose base).
var cycle_amount: float = 0.0
## Si es false, deja de mirar a `look_target` aunque esté puesto.
var look_enabled: bool = true

var _time: float = 0.0
var _talk: float = 0.0
var _look: Vector2 = Vector2.ZERO
var _modifier: SkeletonModifier3D


func _ready() -> void:
	var skeletons: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("CharacterRig '%s': el modelo no tiene Skeleton3D" % name)
		return
	_modifier = preload("res://scripts/world/character_pose_modifier.gd").new()
	_modifier.name = "CharacterPoseModifier"
	_modifier.set("rig", self)
	# Sin dueño: lo crea el script cada vez y no se guarda en la escena.
	skeletons[0].add_child(_modifier)


func _get_configuration_warnings() -> PackedStringArray:
	if pose == null:
		return PackedStringArray(["Falta el CharacterPose (config/character_*.tres)"])
	return PackedStringArray()


## Avanza los tiempos y devuelve el giro total de cada hueso (grados, ejes del personaje).
## Lo llama el modificador del esqueleto una vez por cuadro.
func compute_bones(delta: float) -> Dictionary[StringName, Vector3]:
	var out: Dictionary[StringName, Vector3] = {}
	if pose == null:
		return out
	_time += delta
	for bone: StringName in pose.bones:
		_add(out, bone, pose.bones[bone])
	# Respiración.
	var breath: float = sin(_time * pose.breath_rate * TAU) * pose.breath_angle
	_add(out, pose.chest_bone, Vector3(-breath, 0.0, 0.0))
	# Ciclo (remar).
	var c_value: float = cycle_value
	var c_amount: float = cycle_amount
	if pose.cycle_auto:
		c_value = sin(_time * pose.cycle_rate * TAU)
		c_amount = 1.0
	if c_amount > 0.001:
		var t: float = (c_value + 1.0) * 0.5
		var keys: Dictionary = {}
		for bone: StringName in pose.cycle_forward:
			keys[bone] = true
		for bone: StringName in pose.cycle_back:
			keys[bone] = true
		for bone: StringName in keys:
			var fwd: Vector3 = pose.cycle_forward.get(bone, Vector3.ZERO)
			var back: Vector3 = pose.cycle_back.get(bone, Vector3.ZERO)
			_add(out, bone, back.lerp(fwd, t) * c_amount)
	# Hablar.
	var talking: bool = subtitles != null and speaker_prefix != "" and subtitles.text.begins_with(speaker_prefix)
	_talk = move_toward(_talk, 1.0 if talking else 0.0, delta / maxf(pose.talk_blend_time, 0.01))
	if _talk > 0.001:
		var shake: float = sin(_time * pose.talk_shake_rate * TAU)
		for bone: StringName in pose.talk_bones:
			_add(out, bone, pose.talk_bones[bone] * _talk)
		for bone: StringName in pose.talk_shake:
			_add(out, bone, pose.talk_shake[bone] * shake * _talk)
	# Mirar.
	var want: Vector2 = Vector2.ZERO
	if look_enabled and look_target != null and is_instance_valid(look_target) and look_target.is_inside_tree():
		var skeleton: Skeleton3D = _modifier.get_skeleton() if _modifier != null else null
		var from: Vector3 = global_position + global_basis.y * 1.5
		if skeleton != null:
			var head: int = skeleton.find_bone(pose.head_bone)
			if head >= 0:
				from = skeleton.global_transform * skeleton.get_bone_global_pose(head).origin
		var dir: Vector3 = global_basis.orthonormalized().inverse() * (look_target.global_position - from)
		var yaw: float = rad_to_deg(atan2(-dir.x, -dir.z))
		var pitch: float = rad_to_deg(atan2(dir.y, Vector2(dir.x, dir.z).length()))
		want = Vector2(clampf(pitch, -pose.look_max_pitch, pose.look_max_pitch), clampf(yaw, -pose.look_max_yaw, pose.look_max_yaw))
	_look = _look.lerp(want, minf(delta * pose.look_speed, 1.0))
	if _look.length() > 0.01:
		var look: Vector3 = Vector3(_look.x, _look.y, 0.0)
		_add(out, pose.neck_bone, look * pose.look_neck_share)
		_add(out, pose.head_bone, look * (1.0 - pose.look_neck_share))
	return out


func _add(out: Dictionary[StringName, Vector3], bone: StringName, euler: Vector3) -> void:
	out[bone] = out.get(bone, Vector3.ZERO) + euler
