class_name Sfx
extends RefCounted
## Sonidos sueltos: se reproducen una sola vez y el reproductor se borra solo al terminar.
## Sirven para golpes, puertas, voces y todo lo que suena "de a ratos" (no para los loops de ambiente).
## Con posición, el sonido sale de ese punto (se oye de dónde viene); sin posición suena parejo.
## Si el sonido es null no hace nada: así los campos del Inspector pueden quedar vacíos.


## Elige uno al azar de la lista (null si está vacía).
static func pick(streams: Array[AudioStream]) -> AudioStream:
	if streams.is_empty():
		return null
	return streams.pick_random() as AudioStream


## Suena sin posición. `host` es el nodo del que cuelga el reproductor (tiene que estar en el árbol).
## `pitch_variation` cambia el tono al azar (0.05 = ±5 %) para que no suene idéntico cada vez.
static func play_2d(host: Node, stream: AudioStream, volume_db: float = 0.0, pitch_variation: float = 0.0, bus: StringName = &"Master") -> void:
	if stream == null or host == null or not host.is_inside_tree():
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Suena desde un punto del mundo (se oye más fuerte cuanto más cerca).
static func play_3d(host: Node, stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_variation: float = 0.0, bus: StringName = &"Master") -> void:
	if stream == null or host == null or not host.is_inside_tree():
		return
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	# El tope por defecto (3 dB) recortaría los sonidos a los que se les sube el volumen.
	player.max_db = 24.0
	player.bus = bus
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	host.add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()
