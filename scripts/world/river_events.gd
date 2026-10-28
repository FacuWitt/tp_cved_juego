class_name RiverEvents
extends Node3D
## Los sucesos del río en la huida de la Memoria 2:
##   - Árboles de la orilla que se caen al agua cuando el bote se acerca. Caen del lado
##     contrario a la línea del padre, así siempre queda un paso libre.
##   - Troncos que bajan flotando con la corriente, adelante del bote.
##   - Tramos oscuros (los aplica la memoria con `darkness_at`).
## Árboles y troncos están en el grupo "boat_hazard": chocarlos fuerte es un golpe.
## Todo se arma al empezar; para moverlos se cambian los valores de RiverEventsSettings.

## Un árbol empezó a caer (para el relámpago y el subtítulo).
signal tree_falling(index: int)

@export var settings: RiverEventsSettings
@export var river: RiverFlow
## El bote que dispara los árboles y alrededor del cual aparecen los troncos.
@export var boat: Node3D
## La línea del padre: los árboles caen del otro lado.
@export var father_line: Path3D
@export var water_level: float = 0.0
## Se prende con la huida (antes no cae nada ni aparecen troncos).
var active: bool = false

var _trees: Array[Dictionary] = []
var _logs: Array[Dictionary] = []
var _log_timer: float = 0.0
var _wood: StandardMaterial3D
var _crown: StandardMaterial3D
var _snow: StandardMaterial3D
var _log_wood: StandardMaterial3D


func _ready() -> void:
	assert(settings != null and river != null, "RiverEvents: faltan settings y river")
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.17, 0.11, 0.07)
	_wood.roughness = 1.0
	_crown = StandardMaterial3D.new()
	_crown.albedo_color = Color(0.07, 0.12, 0.1)
	_crown.roughness = 1.0
	_log_wood = StandardMaterial3D.new()
	_log_wood.albedo_color = Color(0.36, 0.27, 0.19)
	_log_wood.roughness = 0.9
	_snow = StandardMaterial3D.new()
	_snow.albedo_color = Color(0.8, 0.83, 0.88)
	_snow.roughness = 1.0
	for i: int in settings.tree_offsets.size():
		_build_tree(i, settings.tree_offsets[i])
	for i: int in settings.log_count:
		_logs.append(_build_log(i))


## Qué tan oscuro está en esta distancia de curva (0 = normal, 1 = solo la linterna).
func darkness_at(offset: float) -> float:
	var k: float = 0.0
	for z: Vector2 in settings.dark_zones:
		var f: float = settings.dark_fade
		var v: float = smoothstep(z.x - f, z.x, offset) * (1.0 - smoothstep(z.y, z.y + f, offset))
		k = maxf(k, v)
	return k


## Hace caer ya todos los árboles que el bote dejó atrás o tiene cerca (para saltar etapas).
func settle_trees_before(offset: float) -> void:
	for t: Dictionary in _trees:
		if t.state == 0 and t.offset < offset + settings.tree_trigger_distance:
			t.state = 2
			t.angle = t.max_angle
			_pose_tree(t)


func _physics_process(delta: float) -> void:
	if not active or boat == null:
		return
	var boat_offset: float = river.offset_of(boat.global_position)
	for i: int in _trees.size():
		var t: Dictionary = _trees[i]
		if t.state == 0 and boat_offset > t.offset - settings.tree_trigger_distance:
			t.state = 1
			t.time = 0.0
			tree_falling.emit(i)
		if t.state == 1:
			t.time += delta
			var k: float = clampf(t.time / settings.tree_fall_time, 0.0, 1.0)
			# Empieza lento (se quiebra) y termina de golpe contra el agua.
			t.angle = t.max_angle * k * k * k
			if k >= 1.0:
				t.state = 2
			_pose_tree(t)
	_update_logs(delta, boat_offset)


# ---------- Árboles ----------

func _build_tree(index: int, offset: float) -> void:
	var center: Vector3 = river.point_at(offset)
	var tangent: Vector3 = river.tangent_at(offset)
	var left: Vector3 = Vector3(-tangent.z, 0.0, tangent.x)
	var half: float = river.width_at(offset) * 0.5
	# Dónde pasa el padre a esa altura del río (distancia lateral, + = izquierda).
	var father_lat: float = 0.0
	if father_line != null and father_line.curve != null:
		var fp: Vector3 = father_line.to_global(father_line.curve.get_closest_point(father_line.to_local(center)))
		father_lat = (fp - center).dot(left)
	# Cae desde la orilla contraria al padre.
	var side: float = -signf(father_lat) if absf(father_lat) > 0.3 else (1.0 if index % 2 == 0 else -1.0)
	var u_father: float = father_lat * side          # <= 0: el padre está del otro lado
	var tip_u: float = u_father + settings.tree_gap   # hasta acá llega la copa
	var base_u: float = half + 1.6
	var height: float = maxf(base_u - tip_u, 4.0)
	var base: Vector3 = center + left * side * base_u
	base.y = water_level + 0.7
	var body: AnimatableBody3D = AnimatableBody3D.new()
	body.name = "Tree%02d" % (index + 1)
	body.sync_to_physics = false
	body.add_to_group("boat_hazard")
	add_child(body)
	body.global_position = base
	# El árbol crece en +Y local; cae girando sobre el eje del río, hacia el centro.
	var toward_center: Vector3 = -left * side
	var axis: Vector3 = toward_center.cross(Vector3.UP).normalized()
	# Tronco.
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = height
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.material_override = _wood
	trunk.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(trunk)
	# Copa: tres conos apilados en la mitad de arriba, con nieve en la punta.
	for k: int in 3:
		var cone: MeshInstance3D = MeshInstance3D.new()
		var cm: CylinderMesh = CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = lerpf(1.7, 0.9, float(k) / 2.0)
		cm.height = height * 0.32
		cm.radial_segments = 7
		cone.mesh = cm
		cone.material_override = _snow if k == 2 else _crown
		cone.position = Vector3(0.0, height * (0.45 + 0.17 * float(k)), 0.0)
		body.add_child(cone)
	# Colisión: el tronco y una caja más ancha para la copa.
	var trunk_shape: CollisionShape3D = CollisionShape3D.new()
	var tb: BoxShape3D = BoxShape3D.new()
	tb.size = Vector3(0.6, height, 0.6)
	trunk_shape.shape = tb
	trunk_shape.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(trunk_shape)
	var crown_shape: CollisionShape3D = CollisionShape3D.new()
	var cb: BoxShape3D = BoxShape3D.new()
	cb.size = Vector3(2.4, height * 0.5, 2.4)
	crown_shape.shape = cb
	crown_shape.position = Vector3(0.0, height * 0.72, 0.0)
	body.add_child(crown_shape)
	var rest: Basis = Basis(Vector3.UP, randf() * TAU)
	# Ángulo final: la punta queda apenas sobre el agua.
	var max_angle: float = acos(clampf((water_level + 0.25 - base.y) / height, -1.0, 1.0))
	var t: Dictionary = {"body": body, "offset": offset, "axis": axis, "rest": rest,
		"angle": 0.0, "max_angle": max_angle, "state": 0, "time": 0.0}
	_trees.append(t)
	_pose_tree(t)


func _pose_tree(t: Dictionary) -> void:
	var body: AnimatableBody3D = t.body
	body.global_basis = Basis(t.axis, -t.angle) * t.rest


# ---------- Troncos ----------

func _build_log(index: int) -> Dictionary:
	var body: AnimatableBody3D = AnimatableBody3D.new()
	body.name = "Log%02d" % (index + 1)
	body.sync_to_physics = false
	body.add_to_group("boat_hazard")
	add_child(body)
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = settings.log_radius
	cm.bottom_radius = settings.log_radius * 1.1
	cm.height = 1.0
	cm.radial_segments = 8
	mesh_inst.mesh = cm
	mesh_inst.material_override = _log_wood
	mesh_inst.rotation.z = PI * 0.5   # acostado sobre X
	body.add_child(mesh_inst)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	shape.shape = box
	body.add_child(shape)
	body.visible = false
	shape.disabled = true
	return {"body": body, "mesh": mesh_inst, "shape": shape, "box": box, "alive": false, "phase": 0.0, "spin": 0.0, "length": 1.0, "push": Vector3.ZERO}


func _update_logs(delta: float, boat_offset: float) -> void:
	var time: float = Time.get_ticks_msec() / 1000.0
	for l: Dictionary in _logs:
		if not l.alive:
			continue
		var body: AnimatableBody3D = l.body
		var flow: Vector3 = river.flow_at(body.global_position)
		var p: Vector3 = body.global_position + (flow * settings.log_drift_factor + l.push) * delta
		# Si el bote lo toca, el tronco se corre de costado y gira (no queda pegado a la proa).
		var away: Vector3 = p - boat.global_position
		away.y = 0.0
		if away.length() < l.length * 0.5 + 1.3 and away.length() > 0.01:
			l.push = away.normalized() * settings.log_push
			l.spin = signf(l.spin + 0.01) * maxf(absf(l.spin), 0.6)
		l.push = (l.push as Vector3).move_toward(Vector3.ZERO, delta * 2.0)
		p.y = water_level + 0.05 + sin(time * 1.4 + l.phase) * 0.05
		body.global_position = p
		body.rotate_y(l.spin * delta)
		# Atrás del bote o al final del tramo: se recicla.
		var off: float = river.offset_of(p)
		if off < boat_offset - 20.0 or off > settings.logs_to + 30.0:
			_kill_log(l)
	if boat_offset < settings.logs_from - settings.log_spawn_max or boat_offset > settings.logs_to:
		return
	_log_timer -= delta
	if _log_timer > 0.0:
		return
	_log_timer = randf_range(settings.log_interval_min, settings.log_interval_max)
	for l: Dictionary in _logs:
		if not l.alive:
			_spawn_log(l, boat_offset + randf_range(settings.log_spawn_min, settings.log_spawn_max))
			break


func _spawn_log(l: Dictionary, offset: float) -> void:
	if offset < settings.logs_from or offset > settings.logs_to:
		return
	var center: Vector3 = river.point_at(offset)
	var tangent: Vector3 = river.tangent_at(offset)
	var left: Vector3 = Vector3(-tangent.z, 0.0, tangent.x)
	var half: float = river.width_at(offset) * 0.5
	var length: float = randf_range(settings.log_length_min, settings.log_length_max)
	var lat: float = randf_range(-half + length * 0.4 + 0.8, half - length * 0.4 - 0.8)
	var body: AnimatableBody3D = l.body
	body.global_position = center + left * lat + Vector3.UP * water_level
	# Cruzado a la corriente, más o menos en diagonal.
	var flow_yaw: float = atan2(-tangent.x, -tangent.z)
	body.global_rotation = Vector3(0.0, flow_yaw + PI * 0.5 + randf_range(-0.7, 0.7), 0.0)
	(l.mesh as MeshInstance3D).scale = Vector3(1.0, length, 1.0)
	(l.box as BoxShape3D).size = Vector3(length, settings.log_radius * 2.0, settings.log_radius * 2.0)
	l.phase = randf() * TAU
	l.length = length
	l.push = Vector3.ZERO
	l.spin = randf_range(-settings.log_spin, settings.log_spin)
	l.alive = true
	body.visible = true
	(l.shape as CollisionShape3D).disabled = false


func _kill_log(l: Dictionary) -> void:
	l.alive = false
	(l.body as Node3D).visible = false
	(l.shape as CollisionShape3D).disabled = true
