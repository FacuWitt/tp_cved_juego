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
@export_subgroup("Nadar")
## Después de caer, sale a la superficie y nada un poco, medio ahogándose, antes de los flashbacks.
## Cuánto dura.
@export_range(2.0, 60.0, 0.5, "suffix:s") var swim_time: float = 12.0
## Cuánto tarda en salir a la superficie.
@export_range(0.2, 5.0, 0.05, "suffix:s") var emerge_time: float = 1.6
## Velocidad nadando (W/A/S/D).
@export_range(0.0, 4.0, 0.05, "suffix:m/s") var swim_speed: float = 0.7
## A qué altura quedan los ojos sobre el agua mientras flota (si queda en 0, la cámara corta la superficie).
@export_range(0.0, 0.5, 0.01, "suffix:m") var eye_above_water: float = 0.16
## Cuánto sube y baja la cabeza con el agua.
@export_range(0.0, 1.0, 0.01, "suffix:m") var swim_bob: float = 0.1
## Cada cuánto se le hunde la cabeza (al azar entre estos valores).
@export_range(0.5, 20.0, 0.1, "suffix:s") var dip_interval_min: float = 2.2
@export_range(0.5, 20.0, 0.1, "suffix:s") var dip_interval_max: float = 4.2
## Cuánto se hunde y cuánto dura cada hundida.
@export_range(0.0, 3.0, 0.05, "suffix:m") var dip_depth: float = 0.55
@export_range(0.1, 3.0, 0.05, "suffix:s") var dip_time: float = 0.9
## Lo que se oye al salir de cada hundida.
@export var gasp_lines: PackedStringArray = PackedStringArray(["(tose y escupe agua)", "(traga agua)", "(jadea)"])
## El bote del padre buscándolo queda armado como el pesquero de la M4 visto desde el agua (el
## flashback "B"): adelante, casi al centro, con la luz cruzando hacia la derecha.
## A qué distancia está.
@export_range(5.0, 120.0, 1.0, "suffix:m") var father_far_distance: float = 18.0
## Hacia qué lado queda respecto de hacia donde mira el jugador al salir (positivo = a la izquierda).
@export_range(-90.0, 90.0, 1.0, "suffix:°") var father_far_angle: float = 2.0
## Hacia dónde apunta la proa (y la linterna), medido desde la línea que va del jugador al bote:
## 90 = cruza de izquierda a derecha, más de 90 = además se aleja.
@export_range(0.0, 180.0, 1.0, "suffix:°") var father_far_heading: float = 100.0
## Tamaño del foco de la linterna mientras busca lejos (1 = el real; más grande = se ve como el
## reflector del pesquero de la M4).
@export_range(1.0, 10.0, 0.1) var father_far_lens_scale: float = 8.0
## Cuánto barre con la luz mientras busca (para cada lado), y qué tan rápido.
@export_range(0.0, 120.0, 1.0, "suffix:°") var father_search_sweep: float = 15.0
@export_range(0.01, 2.0, 0.01, "suffix:Hz") var father_search_rate: float = 0.12
## Lo que grita el padre mientras lo busca, y cada cuánto.
@export var search_lines: PackedStringArray = PackedStringArray(["PADRE: ¡HIJO! ¡¿DÓNDE ESTÁS?!", "PADRE: ¡Contestame, hijo!", "PADRE: ¡HIJOOO!"])
@export_range(1.0, 20.0, 0.5, "suffix:s") var search_line_interval: float = 3.6

@export_subgroup("Rescate")
## Después de los flashbacks: el padre llega con su bote y lo alumbra desde arriba.
## Pose del padre inclinado sobre el borde con el brazo estirado.
@export var father_rescue_pose: CharacterPose
## Cuánto tarda el bote del padre en llegar al lado del jugador.
@export_range(0.5, 10.0, 0.1, "suffix:s") var rescue_boat_time: float = 3.2
## A qué distancia queda el bote (del centro del bote a los ojos del jugador).
@export_range(0.5, 4.0, 0.05, "suffix:m") var rescue_distance: float = 1.15
## Hueso de la mano que sostiene la linterna (alcanza con el comienzo del nombre). Si el modelo no lo
## tiene, la linterna queda en `rescue_light_offset`.
@export var rescue_light_bone: String = "hand_left"
## Corrimiento de la linterna desde ese hueso (en metros, en ejes del mundo; y = arriba).
@export var rescue_light_bone_offset: Vector3 = Vector3(0.0, 0.08, 0.0)
## Dónde está la linterna si no se encuentra el hueso, respecto del bote (x hacia el jugador, y arriba, z adelante).
@export var rescue_light_offset: Vector3 = Vector3(0.45, 1.25, -0.2)
## Tamaño del brillo de la linterna.
@export_range(0.02, 2.0, 0.01) var rescue_glow_scale: float = 0.2
## A qué altura del bote mira el jugador cuando llega el padre (su cara, más o menos).
@export_range(0.0, 2.5, 0.05, "suffix:m") var rescue_look_height: float = 1.1
## Cuánto flota la cabeza durante el rescate, en fracción de `swim_bob` (más bajo = cámara más quieta).
@export_range(0.0, 1.0, 0.05) var rescue_bob: float = 0.3
## Cuánto se queda alumbrado antes del fundido final.
@export_range(0.0, 10.0, 0.1, "suffix:s") var rescue_hold_time: float = 2.4

## Color y densidad de la niebla bajo el agua.
@export var underwater_fog_color: Color = Color(0.01, 0.03, 0.045)
@export_range(0.0, 1.0, 0.005) var underwater_fog_density: float = 0.22
