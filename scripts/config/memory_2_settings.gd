class_name Memory2Settings
extends Resource
## Valores de la Memoria 2 (el lago y el río): textos de etapa 0, la pesca, la red,
## la tormenta, la huida siguiendo al padre y la cinemática del final.

@export_group("Textos (etapa 0, hasta tener voces)")
@export_multiline var wake_line: String = "PADRE: ¿Te dormiste? Dale, que están picando."
@export var net_prompt: String = "(E) Tirar la red"
@export var net_line: String = "PADRE: Bien, ahora tirá la red y esperamos un ratito."
@export var storm_line: String = "PADRE: Uy... mirá cómo se puso el cielo. ¡Juntá la red, nos vamos!"
@export var stuck_line: String = "(la red no sube: está trabada)"
@export var cut_line: String = "PADRE: ¡CORTÁ LA RED, HIJO! ¡VOLVAMOS, QUE VIENE LA TORMENTA!"
@export var cut_prompt: String = "(E) Cortar"
@export var urge_lines: PackedStringArray = PackedStringArray(["PADRE: ¡Dale, cortala!", "PADRE: ¡Rápido, hijo!"])
@export var follow_line: String = "PADRE: ¡Rápido, hijo, seguime! ¡No te separes de la luz!"
@export var row_hint: String = "Q / E: remar con el remo izquierdo / derecho · A / D: remo atrás · S: frenar"
@export var call_lines: PackedStringArray = PackedStringArray(["PADRE: ¡Hijo! ¡Por acá!", "PADRE: ¡Seguí mi luz!", "PADRE: ¡No te quedes atrás!"])
@export var hit_lines: PackedStringArray = PackedStringArray(["(el bote cruje: entra agua)", "(otro golpe: el agua sube)"])
@export var gust_line: String = "PADRE: ¡Cuidado con el viento! ¡Remá del otro lado!"
@export var rapids_line: String = "PADRE: ¡Rápidos! ¡Agarrate fuerte!"
@export var tree_line: String = "PADRE: ¡Cuidado, el árbol!"
@export var dark_line: String = "PADRE: ¡No se ve nada! ¡Seguí mi luz y alumbrá adelante!"
@export var capsize_line: String = "(el bote se da vuelta)"
@export var sink_line: String = "(el bote se hunde)"
@export var father_line: String = "PADRE: ¡Agarrate! No te suelto."
## Cuánto dura cada línea en pantalla.
@export_range(0.5, 10.0, 0.1, "suffix:s") var line_duration: float = 3.5

@export_group("Pesca y red")
## Peces que hay que sacar antes de la red.
@export_range(1, 6, 1) var fish_to_catch: int = 2
## Cuánto flota la red antes de que llegue la tormenta.
@export_range(0.0, 30.0, 0.5, "suffix:s") var net_wait_time: float = 5.0
## Golpes de cuchillo para cortar la soga de la red.
@export_range(1, 6, 1) var cut_hits: int = 3
## Evento rápido del cuchillo: ancho de la zona buena, velocidad y pasadas antes de fallar.
@export_range(0.05, 0.6, 0.01) var cut_zone_width: float = 0.2
@export_range(0.2, 4.0, 0.05) var cut_marker_speed: float = 1.3
@export_range(1, 6, 1) var cut_max_passes: int = 2

@export_group("Tormenta")
## Cuánto tarda el cielo en pasar de atardecer a tormenta.
@export_range(0.5, 30.0, 0.5, "suffix:s") var storm_build_time: float = 7.0
@export_range(0.0, 2.0, 0.01) var dusk_ambient: float = 0.34
@export_range(0.0, 2.0, 0.01) var storm_ambient: float = 0.11
@export_range(0.0, 2.0, 0.01) var dusk_sky: float = 1.0
## Sol del atardecer (se apaga con la tormenta).
@export_range(0.0, 4.0, 0.01) var sun_energy: float = 0.7
@export_range(0.0, 2.0, 0.01) var storm_sky: float = 0.28
@export var dusk_fog_color: Color = Color(0.32, 0.3, 0.36)
@export var storm_fog_color: Color = Color(0.08, 0.09, 0.12)
@export_range(0.0, 0.2, 0.001) var dusk_fog_density: float = 0.012
@export_range(0.0, 0.2, 0.001) var storm_fog_density: float = 0.03
## Olas del lago en calma y con tormenta (altura del shader del agua).
@export_range(0.0, 1.0, 0.01) var calm_waves: float = 0.03
@export_range(0.0, 1.0, 0.01) var storm_waves: float = 0.09
## Copos de la nieve liviana y de la nieve de tormenta.
@export_range(0, 4000, 10) var calm_snow: int = 250
@export_range(0, 4000, 10) var storm_snow: int = 900

@export_group("Huida: viento y padre")
## Ráfagas: cada cuánto, cuánto duran y cuánto empujan (m/s² de costado).
@export_range(1.0, 30.0, 0.5, "suffix:s") var gust_interval_min: float = 5.0
@export_range(1.0, 30.0, 0.5, "suffix:s") var gust_interval_max: float = 10.0
@export_range(0.2, 10.0, 0.1, "suffix:s") var gust_duration: float = 2.6
@export_range(0.0, 10.0, 0.05, "suffix:m/s²") var gust_force: float = 1.7
## Velocidad del padre remando y distancia a la que se mantiene adelante.
@export_range(0.5, 10.0, 0.1, "suffix:m/s") var father_speed: float = 4.5
@export_range(1.0, 40.0, 0.5, "suffix:m") var father_min_gap: float = 7.0
@export_range(2.0, 60.0, 0.5, "suffix:m") var father_max_gap: float = 22.0
## Cada cuánto llama si el hijo se queda atrás.
@export_range(1.0, 30.0, 0.5, "suffix:s") var father_call_interval: float = 6.0
## Energía de la linterna del bote del hijo.
@export_range(0.0, 20.0, 0.1) var bow_lamp_energy: float = 4.0
## La linterna de la proa gira hacia donde mira el jugador (hasta este ángulo a cada lado).
@export var bow_lamp_follows_look: bool = true
@export_range(0.0, 90.0, 1.0, "suffix:°") var bow_lamp_max_yaw: float = 60.0
## Inclinación del haz hacia el agua (negativo = más cerca del bote).
@export_range(-30.0, 10.0, 0.5, "suffix:°") var bow_lamp_pitch: float = -2.5
## Qué tan rápido sigue la mirada.
@export_range(0.5, 20.0, 0.5, "suffix:1/s") var bow_lamp_follow_speed: float = 6.0
## Luz que la linterna derrama adentro del bote (para ver las manos, la soga y los remos).
@export_range(0.0, 5.0, 0.05) var bow_glow_energy: float = 0.7

@export_group("Final")
## Cuánto tarda el bote en darse vuelta o hundirse.
@export_range(0.2, 5.0, 0.05, "suffix:s") var capsize_time: float = 0.9
## Altura del agua.
@export_range(-3.0, 1.0, 0.01, "suffix:m") var water_level: float = 0.0
## Cuánto tarda en hundirse bajo el agua.
@export_range(0.1, 5.0, 0.05, "suffix:s") var fall_time: float = 1.0
## Profundidad a la que queda el jugador bajo el agua.
@export_range(0.5, 10.0, 0.1, "suffix:m") var underwater_depth: float = 2.4
## Cuánto tarda la linterna en hundirse y apagarse.
@export_range(0.5, 10.0, 0.1, "suffix:s") var flashlight_sink_time: float = 3.4
## Hasta dónde se hunde la linterna.
@export_range(1.0, 30.0, 0.5, "suffix:m") var flashlight_sink_depth: float = 7.0
## Oscuridad total antes de los flashbacks.
@export_range(0.0, 5.0, 0.05, "suffix:s") var dark_time: float = 1.2
## Cuántas imágenes se ven en la oscuridad del final.
@export_range(1, 12, 1) var ending_flashbacks: int = 4
## Cuánto tarda el barquito en subir encendido.
@export_range(0.5, 10.0, 0.1, "suffix:s") var boat_rise_time: float = 2.6
## Cuánto tarda en llegar la luz del padre.
@export_range(0.5, 10.0, 0.1, "suffix:s") var father_light_time: float = 2.2
## Intensidad de la linterna del padre en el rescate.
@export_range(0.0, 30.0, 0.1) var father_light_energy: float = 7.0
## Fundido a negro final.
@export_range(0.1, 5.0, 0.05, "suffix:s") var end_fade_time: float = 1.4
## Color y densidad de la niebla bajo el agua.
@export var underwater_fog_color: Color = Color(0.01, 0.03, 0.045)
@export_range(0.0, 1.0, 0.005) var underwater_fog_density: float = 0.22
