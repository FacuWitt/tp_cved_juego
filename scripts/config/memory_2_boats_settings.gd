class_name Memory2BoatsSettings
extends Resource
## Valores de la Memoria 2 (los botes en el lago): cómo avanza la tormenta, las frases, el evento de la ola
## y el final bajo el agua. Los usa Memory2Boats.

@export_group("Textos (etapa 0, hasta tener voces grabadas)")
@export var gate_line: String = ""
@export var tutorial_line: String = "A y D mueven un remo cada uno. Alterná para ir derecho."
@export var behind_line: String = "PADRE: ¡No te quedes atrás! ¡Seguí mi luz!"
@export var off_course_line: String = "PADRE: ¡Por acá, hijo! ¡Seguí la luz!"
@export var bump_line: String = "PADRE: ¿Estás bien? ¡No pares de remar!"
@export var wave_line: String = "PADRE: ¡Una ola! ¡Agarrate fuerte!"
@export var rescue_line: String = "PADRE: ¡Agarrate! No te suelto."
@export var rock_hit_text: String = "(el casco choca contra la roca)"
@export var log_hit_text: String = "(un tronco golpea el bote)"
## Cuánto dura cada línea en pantalla.
@export_range(0.5, 10.0, 0.1, "suffix:s") var line_duration: float = 3.6
## Frases del padre por avance del recorrido, en orden.
@export var father_lines: Array[FatherLine] = []
## Voces de las frases que dispara el juego en el momento.
@export var voice_behind: AudioStream
@export var voice_off_course: AudioStream
@export var voice_bump: AudioStream
@export var voice_tutorial: AudioStream
@export var voice_wave: AudioStream
@export var voice_rescue: AudioStream
## Tiempo mínimo entre dos frases reactivas (atrás, fuera de camino, choque).
@export_range(1.0, 60.0, 0.5, "suffix:s") var reactive_cooldown: float = 11.0
## Si en este tiempo no remó con los dos remos, el padre le recuerda que alterne.
@export_range(2.0, 60.0, 0.5, "suffix:s") var tutorial_hint_after: float = 9.0

@export_group("Pesca del principio (antes de la tormenta)")
## Si está prendido, la memoria arranca con padre e hijo pescando en calma y recién después se viene la tormenta.
@export var fishing_intro: bool = true
## Frases de la pesca. En esta lista `at_progress` son SEGUNDOS desde que el hijo abre los ojos.
@export var fishing_lines: Array[FatherLine] = []
## Segundos de calma antes del primer trueno lejano.
@export_range(2.0, 90.0, 0.5, "suffix:s") var fishing_time: float = 10.0
## Qué tan cargado queda el cielo después del primer trueno (0 = calma, 1 = tormenta total).
@export_range(0.0, 1.0, 0.01) var onset_storm: float = 0.2
## Cuánto tarda en cerrarse el cielo tras el primer trueno.
@export_range(1.0, 30.0, 0.5, "suffix:s") var onset_time: float = 7.0
## Lo que dice el padre cuando se viene la tormenta, antes de empezar a remar.
@export var onset_line: String = "PADRE: Se está cerrando el cielo. Guardá la caña, hijo. Nos volvemos ya."
@export var voice_onset: AudioStream
## Cuánto después del trueno habla el padre.
@export_range(0.0, 10.0, 0.1, "suffix:s") var onset_line_delay: float = 1.6
## Pausa entre esa frase y el momento en que se puede remar.
@export_range(0.0, 10.0, 0.1, "suffix:s") var onset_control_delay: float = 2.4
## Cuántos metros a la derecha del hijo pesca el padre.
@export_range(3.0, 25.0, 0.5, "suffix:m") var fishing_father_side: float = 8.0
## Cuántos metros adelante del hijo (a lo largo del camino) está el bote del padre al pescar.
@export_range(0.0, 20.0, 0.5, "suffix:m") var fishing_father_ahead: float = 3.0
## Cuánto tarda el padre en volver al camino cuando empieza a remar.
@export_range(1.0, 20.0, 0.5, "suffix:s") var fishing_father_return_time: float = 6.0

@export_group("Tormenta")
## Avance del recorrido (0 a 1) en el que empieza a cerrarse la tormenta.
@export_range(0.0, 1.0, 0.01) var storm_start: float = 0.05
## Avance en el que la tormenta está al máximo.
@export_range(0.0, 1.0, 0.01) var storm_full: float = 0.78
## Cada cuánto caen rayos: factor sobre los intervalos del LightningSettings (1 = tal cual, 0.3 = muchos más).
@export_range(0.1, 3.0, 0.05) var lightning_interval_calm: float = 2.5
@export_range(0.1, 3.0, 0.05) var lightning_interval_storm: float = 0.55
## Cantidad de lluvia (0 a 1) en calma y con tormenta.
@export_range(0.0, 1.0, 0.01) var rain_calm: float = 0.0
@export_range(0.0, 1.0, 0.01) var rain_storm: float = 1.0
## Cuánto se moja la lente con la tormenta.
@export_range(0.0, 1.0, 0.01) var lens_wet_storm: float = 0.7

@export_group("Luz del atardecer a la noche")
@export var sky_top_calm: Color = Color(0.17, 0.2, 0.36)
@export var sky_top_storm: Color = Color(0.012, 0.016, 0.024)
@export var sky_horizon_calm: Color = Color(0.95, 0.52, 0.34)
@export var sky_horizon_storm: Color = Color(0.05, 0.065, 0.082)
@export var fog_color_calm: Color = Color(0.5, 0.36, 0.34)
@export var fog_color_storm: Color = Color(0.045, 0.06, 0.075)
@export_range(0.0, 0.1, 0.0005) var fog_density_calm: float = 0.004
@export_range(0.0, 0.1, 0.0005) var fog_density_storm: float = 0.012
@export_range(0.0, 2.0, 0.01) var ambient_calm: float = 0.55
@export_range(0.0, 2.0, 0.01) var ambient_storm: float = 0.07
@export_range(0.0, 3.0, 0.01) var sky_calm: float = 1.0
@export_range(0.0, 3.0, 0.01) var sky_storm: float = 0.25
## Energía de la luz del sol bajo del atardecer (se apaga con la tormenta).
@export_range(0.0, 3.0, 0.01) var sunset_energy: float = 0.9

@export_group("La ola")
## Avance del recorrido (0 a 1) en el que viene la ola gigante.
@export_range(0.5, 1.0, 0.005) var wave_event_progress: float = 0.84
## A qué distancia, por delante, aparece la ola.
@export_range(20.0, 200.0, 1.0, "suffix:m") var wave_start_distance: float = 85.0
## Cuánto tarda la ola en llegar al bote.
@export_range(2.0, 20.0, 0.1, "suffix:s") var wave_travel_time: float = 6.8
@export_range(1.0, 12.0, 0.1, "suffix:m") var wave_height: float = 5.2
@export_range(1.0, 20.0, 0.1, "suffix:m") var wave_width: float = 6.5
## Ancho de la ola hacia los costados.
@export_range(5.0, 120.0, 1.0, "suffix:m") var wave_lateral: float = 42.0
## Cuando el frente de la ola está a menos de esta distancia del bote, el bote se da vuelta.
@export_range(0.5, 10.0, 0.1, "suffix:m") var capsize_trigger_distance: float = 2.8
## Cuánto dura el relámpago largo que muestra la ola.
@export_range(0.5, 8.0, 0.1, "suffix:s") var wave_flash_time: float = 3.0
## Cuánto se vuelca el bote (grados de giro de la cámara) al llegar la ola.
@export_range(30.0, 180.0, 1.0, "suffix:°") var capsize_roll: float = 115.0
@export_range(0.2, 4.0, 0.05, "suffix:s") var capsize_time: float = 1.1

@export_group("Final: bajo el agua")
## Profundidad a la que queda el protagonista.
@export_range(0.5, 10.0, 0.1, "suffix:m") var underwater_depth: float = 2.6
## Cuánto tarda en hundirse.
@export_range(0.1, 5.0, 0.05, "suffix:s") var fall_time: float = 1.0
@export_range(0.5, 10.0, 0.1, "suffix:s") var lantern_sink_time: float = 3.2
@export_range(1.0, 30.0, 0.5, "suffix:m") var lantern_sink_depth: float = 7.0
## Oscuridad total antes de los flashbacks.
@export_range(0.0, 5.0, 0.05, "suffix:s") var dark_time: float = 1.2
@export_range(1, 12, 1) var ending_flashbacks: int = 4
@export_range(0.5, 10.0, 0.1, "suffix:s") var boat_rise_time: float = 2.8
@export_range(0.5, 10.0, 0.1, "suffix:s") var father_light_time: float = 2.4
@export_range(0.0, 30.0, 0.1) var father_light_energy: float = 7.0
@export_range(0.1, 5.0, 0.05, "suffix:s") var end_fade_time: float = 1.4
@export var underwater_fog_color: Color = Color(0.01, 0.03, 0.045)
@export_range(0.0, 1.0, 0.005) var underwater_fog_density: float = 0.22
## Pulso del corazón bajo el agua (el bip del juego).
@export_range(30.0, 120.0, 1.0, "suffix:bpm") var heartbeat_bpm: float = 58.0

@export_group("Sonidos de la escena")
@export var sfx_wave_roar: AudioStream
@export var sfx_capsize: AudioStream
@export var sfx_gasp: AudioStream
@export var sfx_hand: AudioStream
@export var sfx_heartbeat: AudioStream
@export var music_lullaby: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var voice_db: float = -3.0
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var sfx_db: float = -2.0
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var music_db: float = -9.0
