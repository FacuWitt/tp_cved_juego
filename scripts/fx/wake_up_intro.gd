class_name WakeUpIntro
extends CanvasLayer
## El despertar con el que empieza cada memoria: ojos cerrados, un trueno que lo sobresalta,
## los ojos que se abren y el protagonista que se levanta. Mientras dura, el jugador no tiene control.
## No sabe en qué memoria está: recibe el jugador, los rayos (opcionales) y los valores.

## Terminó: el jugador ya está parado y con control.
signal finished
## El trueno lo despertó (para que la memoria haga sonar algo o muestre una línea).
signal thunder_struck

@export var settings: WakeUpSettings
@export var player: Player
## Opcional: si hay, el trueno trae su rayo.
@export var lightning: LightningController

var is_playing: bool = false

var _top: ColorRect
var _bottom: ColorRect


func _ready() -> void:
	assert(settings != null and player != null, "WakeUpIntro: faltan el WakeUpSettings y el Player")
	layer = 20
	_top = _make_lid(true)
	_bottom = _make_lid(false)
	_set_open(1.0)


## Juega el despertar completo. Se puede esperar con await.
func play() -> void:
	if not settings.enabled:
		finished.emit()
		return
	is_playing = true
	var head: Node3D = player.get_node("Head") as Node3D
	var camera: Camera3D = player.get_node("Head/Camera3D") as Camera3D
	var stand_y: float = head.position.y
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.velocity = Vector3.ZERO
	head.position.y = stand_y - settings.lying_drop
	head.rotation.x = deg_to_rad(settings.lying_pitch)
	camera.rotation.z = deg_to_rad(settings.lying_roll)
	_set_open(0.0)
	await get_tree().create_timer(settings.closed_time).timeout

	# El trueno: abre los ojos de golpe y los vuelve a cerrar.
	if lightning != null:
		lightning.flash_now(settings.thunder_strength)
	thunder_struck.emit()
	await _tween_open(settings.startle_open, settings.startle_time * 0.35)
	await get_tree().create_timer(settings.startle_time).timeout
	await _tween_open(0.0, settings.startle_time * 0.6)
	await get_tree().create_timer(settings.after_startle_time).timeout

	# Abre los ojos despacio, con un parpadeo a mitad de camino.
	await _tween_open(0.55, settings.open_time * 0.45)
	await _tween_open(0.1, 0.12)
	await _tween_open(1.0, settings.open_time * 0.55)

	# Se levanta.
	var t: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(head, "position:y", stand_y, settings.getup_time)
	t.tween_property(head, "rotation:x", 0.0, settings.getup_time)
	t.tween_property(camera, "rotation:z", 0.0, settings.getup_time)
	await t.finished

	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	is_playing = false
	finished.emit()


func _make_lid(top: bool) -> ColorRect:
	var lid: ColorRect = ColorRect.new()
	lid.color = Color.BLACK
	lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lid.anchor_left = 0.0
	lid.anchor_right = 1.0
	lid.anchor_top = 0.0 if top else 0.5
	lid.anchor_bottom = 0.5 if top else 1.0
	# Un poco más grande para que no quede una línea al cerrarse.
	lid.offset_top = -2.0
	lid.offset_bottom = 2.0
	add_child(lid)
	return lid


# 0 = ojos cerrados, 1 = abiertos.
func _set_open(amount: float) -> void:
	var half: float = 0.5 * (1.0 - clampf(amount, 0.0, 1.0))
	_top.anchor_bottom = half
	_bottom.anchor_top = 1.0 - half
	_top.visible = half > 0.001
	_bottom.visible = half > 0.001


func _get_open() -> float:
	return 1.0 - _top.anchor_bottom * 2.0


func _tween_open(amount: float, duration: float) -> void:
	var t: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_set_open, _get_open(), amount, maxf(duration, 0.01))
	await t.finished
