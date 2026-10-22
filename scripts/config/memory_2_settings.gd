class_name Memory2Settings
extends Resource
## Valores de la Memoria 2 (el lago helado): textos de etapa 0, caídas al agua,
## cómo oscurece, flashbacks y la cinemática del final.

@export_group("Textos (etapa 0, hasta tener voces)")
@export_multiline var radio_line: String = "RADIO: ...alerta por tormenta de nieve sobre el lago. No salgan al hielo..."
@export var dog_line: String = "(el perro sale corriendo hacia el lago, ladrando)"
@export var gate_line: String = "No me voy sin la mochila."
@export var crack_line: String = "(el hielo cruje)"
@export var fall_line: String = "(el agua helada lo corta como un cuchillo)"
@export var father_line: String = "PADRE: ¡Agarrate! No te suelto."
## Cuánto dura cada línea en pantalla.
@export_range(0.5, 10.0, 0.1, "suffix:s") var line_duration: float = 3.5

@export_group("Lago")
## Altura del agua.
@export_range(-3.0, 1.0, 0.01, "suffix:m") var water_level: float = -0.32
## Cuánto debajo del agua tiene que quedar el jugador para contar como caída.
@export_range(0.1, 3.0, 0.05, "suffix:m") var fall_depth: float = 0.7
## Fundido a negro al caer al agua (ida y vuelta).
@export_range(0.05, 2.0, 0.05, "suffix:s") var fall_fade_time: float = 0.35
## Tiempo en negro antes de reaparecer.
@export_range(0.0, 3.0, 0.05, "suffix:s") var fall_black_time: float = 0.7

@export_group("Atardecer → noche")
## Luz ambiente en la orilla (atardecer).
@export_range(0.0, 2.0, 0.01) var dusk_ambient: float = 0.32
## Luz ambiente cerca del perro (noche).
@export_range(0.0, 2.0, 0.01) var night_ambient: float = 0.06
## Brillo del cielo en la orilla.
@export_range(0.0, 2.0, 0.01) var dusk_sky: float = 1.0
## Brillo del cielo cerca del perro.
@export_range(0.0, 2.0, 0.01) var night_sky: float = 0.2
## Color de la niebla en la orilla (atardecer).
@export var dusk_fog_color: Color = Color(0.24, 0.26, 0.32)
## Color de la niebla cerca del perro (noche).
@export var night_fog_color: Color = Color(0.05, 0.06, 0.085)
## Dónde empieza a oscurecer (z del mundo; la orilla está en z = 10).
@export_range(-100.0, 100.0, 0.5, "suffix:m") var darken_start_z: float = 9.0
## Dónde ya es de noche (z del mundo; el perro está cerca de z = -40).
@export_range(-100.0, 100.0, 0.5, "suffix:m") var darken_end_z: float = -32.0

@export_group("Flashbacks")
## Probabilidad de un flashback cuando una placa empieza a agrietarse.
@export_range(0.0, 1.0, 0.05) var crack_flashback_chance: float = 0.6
## Tiempo mínimo entre flashbacks durante el cruce.
@export_range(0.0, 60.0, 0.5, "suffix:s") var flashback_cooldown: float = 8.0
## Cuántas imágenes se ven en la oscuridad del final.
@export_range(1, 12, 1) var ending_flashbacks: int = 4

@export_group("Final: el hielo se rompe")
## Distancia al perro a la que empieza el final.
@export_range(0.5, 6.0, 0.1, "suffix:m") var ending_radius: float = 2.2
## Cuánto tiembla el hielo antes de romperse.
@export_range(0.0, 5.0, 0.05, "suffix:s") var shake_time: float = 1.4
## Cuánto tarda en hundirse bajo el agua.
@export_range(0.1, 5.0, 0.05, "suffix:s") var fall_time: float = 1.0
## Profundidad a la que queda el jugador bajo el hielo.
@export_range(0.5, 10.0, 0.1, "suffix:m") var underwater_depth: float = 2.4
## Cuánto tarda la linterna en hundirse y apagarse.
@export_range(0.5, 10.0, 0.1, "suffix:s") var flashlight_sink_time: float = 3.4
## Hasta dónde se hunde la linterna.
@export_range(1.0, 30.0, 0.5, "suffix:m") var flashlight_sink_depth: float = 7.0
## Oscuridad total antes de los flashbacks.
@export_range(0.0, 5.0, 0.05, "suffix:s") var dark_time: float = 1.2
## Cuánto tarda el barquito en subir encendido.
@export_range(0.5, 10.0, 0.1, "suffix:s") var boat_rise_time: float = 2.6
## Cuánto tarda en llegar la luz del padre.
@export_range(0.5, 10.0, 0.1, "suffix:s") var father_light_time: float = 2.2
## Intensidad de la linterna del padre.
@export_range(0.0, 30.0, 0.1) var father_light_energy: float = 7.0
## Fundido a negro final.
@export_range(0.1, 5.0, 0.05, "suffix:s") var end_fade_time: float = 1.4
## Color de la niebla bajo el agua.
@export var underwater_fog_color: Color = Color(0.01, 0.03, 0.045)
## Densidad de la niebla bajo el agua.
@export_range(0.0, 1.0, 0.005) var underwater_fog_density: float = 0.22
