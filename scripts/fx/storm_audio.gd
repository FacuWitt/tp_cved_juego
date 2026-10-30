class_name StormAudio
extends Node
## El sonido ambiente de una memoria con tormenta: lluvia, viento, agua, música que se oscurece y truenos.
## Todo sigue el valor de tormenta (`set_storm`, de 0 a 1). Los truenos llegan con demora después de cada rayo.
## No sabe qué memoria es: solo recibe un StormAudioSettings.

@export var settings: StormAudioSettings

var _rain: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _lap: AudioStreamPlayer
var _pad_calm: AudioStreamPlayer
var _pad_storm: AudioStreamPlayer
var _under: AudioStreamPlayer
var _storm: float = 0.0
var _underwater: float = 0.0
var _target_underwater: float = 0.0
var _muted: bool = false


func _ready() -> void:
	assert(settings != null, "StormAudio: falta el StormAudioSettings")
	_rain = _make_loop("Rain", settings.rain)
	_wind = _make_loop("Wind", settings.wind)
	_lap = _make_loop("Lap", settings.water_lap)
	_pad_calm = _make_loop("PadCalm", settings.pad_calm)
	_pad_storm = _make_loop("PadStorm", settings.pad_storm)
	_under = _make_loop("Underwater", settings.underwater)
	_apply_volumes(1.0)
	for player: AudioStreamPlayer in [_rain, _wind, _lap, _pad_calm, _pad_storm, _under]:
		if player.stream != null:
			player.play()


func _process(delta: float) -> void:
	_underwater = move_toward(_underwater, _target_underwater, delta / maxf(settings.fade_time, 0.05))
	_apply_volumes(1.0 - exp(-delta / maxf(settings.fade_time, 0.05) * 3.0))


## 0 = atardecer en calma, 1 = tormenta.
func set_storm(value: float) -> void:
	_storm = clampf(value, 0.0, 1.0)


## Bajo el agua: se apagan la lluvia, el viento y la música, y suena el sonido ahogado.
func set_underwater(value: bool) -> void:
	_target_underwater = 1.0 if value else 0.0


## Silencia todo (para el final).
func set_muted(value: bool) -> void:
	_muted = value


## Para conectar a LightningController.flashed: el trueno llega después, más tarde cuanto más lejos cayó.
func on_flash(strength: float) -> void:
	var delay: float = randf_range(settings.thunder_delay_min, settings.thunder_delay_max)
	get_tree().create_timer(delay).timeout.connect(func() -> void: play_thunder(delay, strength))


## Trueno según la demora: de cerca (con chasquido), de media distancia o lejano.
func play_thunder(delay: float, strength: float = 1.0) -> void:
	if _underwater > 0.5:
		return
	var stream: AudioStream = settings.thunder_mid
	if delay < settings.thunder_near_below:
		stream = settings.thunder_near
	elif delay > settings.thunder_far_above:
		stream = settings.thunder_far
	if stream == null:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = settings.thunder_db + linear_to_db(clampf(strength, 0.2, 1.0))
	p.pitch_scale = randf_range(0.9, 1.1)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _apply_volumes(follow: float) -> void:
	var above: float = 1.0 - _underwater
	_set_db(_rain, lerpf(settings.rain_calm_db, settings.rain_storm_db, _storm), above, follow)
	_set_db(_wind, lerpf(settings.wind_calm_db, settings.wind_storm_db, _storm), above, follow)
	_set_db(_lap, lerpf(settings.lap_calm_db, settings.lap_storm_db, _storm), above, follow)
	_set_db(_pad_calm, lerpf(settings.pad_calm_calm_db, settings.pad_calm_storm_db, _storm), above, follow)
	_set_db(_pad_storm, lerpf(settings.pad_storm_calm_db, settings.pad_storm_storm_db, _storm), above, follow)
	_set_db(_under, settings.underwater_db, _underwater, follow)


func _set_db(player: AudioStreamPlayer, db: float, weight: float, follow: float) -> void:
	var target: float = -80.0 if (_muted or weight < 0.01) else db + linear_to_db(clampf(weight, 0.0001, 1.0))
	player.volume_db = lerpf(player.volume_db, target, clampf(follow, 0.0, 1.0))


func _make_loop(node_name: String, stream: AudioStream) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = node_name
	if stream != null:
		var looped: AudioStream = stream.duplicate() as AudioStream
		if looped is AudioStreamOggVorbis:
			(looped as AudioStreamOggVorbis).loop = true
		player.stream = looped
	player.volume_db = -80.0
	add_child(player)
	return player
