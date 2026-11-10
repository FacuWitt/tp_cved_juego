extends Node
## Prueba de la Memoria 3 de punta a punta, caminando con la física del jugador (sin teletransportar):
## cocina -> pasillo -> una puerta mala (vuelve a la cocina) -> las tres puertas buenas con sus salas
## intermedias -> cuarto de la hija -> entrega del barquito -> entrada -> puerta de casa -> salida.
## Uso (desde la carpeta del proyecto):
##   godot --headless --fixed-fps 60 res://tools/tests/m3_recorrido.tscn
## Con `-- capturas=<carpeta>` y sin --headless guarda capturas en los puntos clave.
## Con `-- sala=<n>` salta directo a la sala intermedia n (0, 1, 2), la cruza caminando y termina.

const SCENE: String = "res://scenes/memories/m3_casa/m3_casa.tscn"

var mem: Memory3House
var player: Player
var head: Node3D
var failed: bool = false
var finished: bool = false
var shots_dir: String = ""
var _try_wrong: bool = true
var only_room: int = -1


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("capturas="):
			shots_dir = arg.trim_prefix("capturas=")
		if arg.begins_with("sala="):
			only_room = arg.trim_prefix("sala=").to_int()
	seed(12345)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	mem = scene as Memory3House
	_run.call_deferred(scene)


func _run(scene: Node) -> void:
	get_tree().root.add_child(scene)
	player = mem.player
	head = player.get_node("Head") as Node3D
	mem.exit.reached.connect(func() -> void: finished = true)
	await _until(func() -> bool: return mem.stage == Memory3House.Stage.MAZE, 40.0, "despertar")
	_log("despierto en la cocina")
	await _shot("01_cocina")
	if only_room >= 0:
		mem.segment = only_room
		mem._advance(null)
		await _wait(0.3)
		await _cross_interlude()
		_log("RESULTADO: %s" % ("FALLO" if failed else "OK"))
		get_tree().quit(1 if failed else 0)
		return
	# De la mesa al pasillo, rodeando la mesa.
	for p: Vector3 in [Vector3(1.6, 0, 0.9), Vector3(1.6, 0, -1.6), Vector3(0, 0, -2.2)]:
		await _walk(p, 0.35, 12.0)
	while mem.stage == Memory3House.Stage.MAZE and not failed:
		var good: int = mem.settings.good_doors[mem.segment]
		var door: int = good
		if _try_wrong:
			door = (good + 1) % 3
		await _hallway_to_door(door)
		if failed:
			break
		if _try_wrong:
			_try_wrong = false
			_check(mem.mistakes == 1 and mem.stage == Memory3House.Stage.MAZE, "puerta mala: vuelve a la cocina (errores=%d)" % mem.mistakes)
			_check(player.global_position.distance_to(mem.kitchen_back.global_position) < 3.0, "aparece en el fondo de la cocina")
			for p: Vector3 in [Vector3(0, 0, 2.0), Vector3(1.6, 0, 1.2), Vector3(1.6, 0, -1.6), Vector3(0, 0, -2.2)]:
				await _walk(p, 0.35, 12.0)
			continue
		if mem.stage == Memory3House.Stage.INTERLUDE:
			await _cross_interlude()
	_check(mem.stage == Memory3House.Stage.ROOM, "llega al pasillo del cuarto de la hija (etapa %d)" % mem.stage)
	if not failed:
		await _daughter_room()
	_log("RESULTADO: %s" % ("FALLO" if failed else "OK"))
	get_tree().quit(1 if failed else 0)


func _hallway_to_door(door: int) -> void:
	var hall: BendingHallway = mem.hallway
	var seg: int = mem.segment
	var t0: float = _now()
	Input.action_press("move_forward")
	while _now() - t0 < 120.0:
		var along: float = hall.distance_along(player.global_position)
		if along >= hall.path_length - 0.4:
			break
		_aim(hall.to_global(hall._point_at(along + 1.0)))
		await get_tree().physics_frame
		if player.global_position.y < -3.0:
			_fail("se cayó del mapa en el pasillo (tramo %d) en %s" % [seg, player.global_position])
			return
	Input.action_release("move_forward")
	_check(_now() - t0 < 120.0, "tramo %d: recorre el pasillo (%.1f m) en %.1f s" % [seg, hall.path_length, _now() - t0])
	if seg == 1:
		await _shot("02_pasillo_rellano")
	var far: Node3D = hall.far_end
	var x: float = hall.door_offsets[door]
	await _walk(far.to_global(Vector3(x, 0, -1.2)), 0.25, 10.0)
	_face(far.to_global(Vector3(x, 0, -6.0)))
	await _interact()
	await _wait(mem.settings.door_open_time + 0.3)
	var before: Vector3 = player.global_position
	Input.action_press("move_forward")
	t0 = _now()
	while _now() - t0 < 8.0 and player.global_position.distance_to(before) < 6.0:
		_aim(far.to_global(Vector3(x, 0, -7.0)))
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_check(player.global_position.distance_to(before) >= 6.0, "tramo %d, puerta %d: cruza el umbral" % [seg, door])
	await _wait(0.2)


func _cross_interlude() -> void:
	var room: InterludeRoom = mem._interlude
	var label: String = room.name
	_log("entra a la sala intermedia %s" % label)
	var z_end: float = room.exit_portal.position.z + 0.6
	var exit_x: float = room.exit_portal.position.x
	var points: Array[Vector3] = []
	if room is BoatFloodRoom:
		var boats: BoatFloodRoom = room as BoatFloodRoom
		var depth: float = boats.settings.room_depth
		var n: int = ceili(depth / 0.5)
		for i: int in n + 1:
			var t: float = float(i) / n
			points.append(Vector3(boats.path_x(t), 0, -InterludeRoom.STUB_FRONT - t * depth))
	else:
		var start: Vector3 = Vector3(0, 0, -InterludeRoom.STUB_FRONT - 0.5)
		var end: Vector3 = Vector3(exit_x, 0, z_end + 0.8)
		var n: int = ceili(start.distance_to(end) / 1.0)
		for i: int in n + 1:
			points.append(start.lerp(end, float(i) / n))
	var t0: float = _now()
	var marks: Array[float] = [0.1, 0.3, 0.5, 0.62, 0.75, 0.92]
	var next_mark: int = 0
	for i: int in points.size():
		await _walk(room.to_global(points[i]), 0.3, 25.0)
		if failed:
			return
		var k: float = float(i) / points.size()
		if next_mark < marks.size() and k >= marks[next_mark]:
			await _shot("sala_%s_%d" % [label, next_mark + 1])
			if shots_dir != "" and next_mark >= 3:
				# Mirar atrás: lo que cambió a espaldas del jugador.
				var yaw: float = player.rotation.y
				player.rotation.y = yaw + PI * 0.8
				await _wait(0.5)
				await _shot("sala_%s_%d_atras" % [label, next_mark + 1])
				player.rotation.y = yaw
			next_mark += 1
	Input.action_press("move_forward")
	var t1: float = _now()
	while _now() - t1 < 8.0 and mem.stage == Memory3House.Stage.INTERLUDE:
		_aim(room.to_global(Vector3(exit_x, 0, z_end - 6.0)))
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_check(mem.stage != Memory3House.Stage.INTERLUDE, "sala %s: se cruza y se sale (%.1f s)" % [label, _now() - t0])
	await _wait(0.2)


func _daughter_room() -> void:
	var room: Node3D = mem.room_arrival.get_parent().get_parent() as Node3D
	await _walk(room.to_global(Vector3(1.3, 0, 3.0)), 0.25, 10.0)
	_face(room.to_global(Vector3(1.3, 0, 0.0)))
	await _interact()
	await _wait(mem.settings.door_open_time + 0.4)
	await _walk(room.to_global(Vector3(1.3, 0, 1.1)), 0.25, 10.0)
	await _shot("08_cuarto_hija")
	_face(mem.daughter.global_position + Vector3(0, 0.6, 0), true)
	await _interact()
	_check(mem.stage == Memory3House.Stage.GIVING or mem.stage == Memory3House.Stage.STABLE, "le da el barquito a la hija")
	await _until(func() -> bool: return mem.stage == Memory3House.Stage.STABLE, 20.0, "la casa se estabiliza")
	head.rotation.x = 0.0
	for p: Vector3 in [Vector3(1.3, 0, 1.2), Vector3(1.3, 0, 4.0), Vector3(1.3, 0, 7.6), Vector3(1.3, 0, 9.4)]:
		await _walk(room.to_global(p), 0.3, 12.0)
	_face(room.to_global(Vector3(1.3, 0, 12.0)))
	await _shot("09_entrada")
	await _interact()
	await _wait(mem.settings.door_open_time + 0.4)
	Input.action_press("move_forward")
	var t0: float = _now()
	while _now() - t0 < 8.0 and not finished:
		_aim(room.to_global(Vector3(1.3, 0, 13.0)))
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_check(finished, "sale por la puerta de casa: la memoria se completa")


# ---------- Utilidades ----------

func _walk(target: Vector3, tolerance: float, timeout: float) -> void:
	if failed:
		return
	var t0: float = _now()
	Input.action_press("move_forward")
	while _now() - t0 < timeout:
		var flat: Vector3 = target - player.global_position
		flat.y = 0.0
		if flat.length() <= tolerance:
			break
		_aim(target)
		await get_tree().physics_frame
		if player.global_position.y < -3.0:
			break
	Input.action_release("move_forward")
	var d: Vector3 = target - player.global_position
	d.y = 0.0
	if d.length() > tolerance + 0.05:
		_fail("no llega a %s (queda en %s)" % [target, player.global_position])
	await get_tree().physics_frame


func _aim(target: Vector3) -> void:
	var d: Vector3 = target - player.global_position
	if Vector2(d.x, d.z).length() > 0.01:
		player.rotation.y = atan2(-d.x, -d.z)


func _face(target: Vector3, pitch: bool = false) -> void:
	_aim(target)
	head.rotation.x = 0.0
	if pitch:
		var eye: Vector3 = head.global_position
		var d: Vector3 = target - eye
		head.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())


func _interact() -> void:
	for i: int in 4:
		await get_tree().physics_frame
	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	for i: int in 3:
		await get_tree().physics_frame
	var release: InputEventAction = InputEventAction.new()
	release.action = "interact"
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().physics_frame


func _until(condition: Callable, timeout: float, what: String) -> void:
	var t0: float = _now()
	while not condition.call() and _now() - t0 < timeout:
		await get_tree().physics_frame
	_check(condition.call(), what)


func _wait(seconds: float) -> void:
	var t0: float = _now()
	while _now() - t0 < seconds:
		await get_tree().physics_frame


func _now() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


func _shot(name: String) -> void:
	if shots_dir == "":
		return
	Input.action_release("move_forward")
	for i: int in 3:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(shots_dir.path_join(name + ".png"))


func _check(ok: bool, what: String) -> void:
	_log(("  ok    " if ok else "  FALLA ") + what)
	if not ok:
		failed = true


func _fail(what: String) -> void:
	_check(false, what)


func _log(text: String) -> void:
	print("[M3 %.1fs] %s" % [_now(), text])
