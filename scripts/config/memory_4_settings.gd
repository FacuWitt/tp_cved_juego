class_name Memory4Settings
extends Resource
## Valores de "feel" y textos provisorios de la Memoria 4 (el accidente en el barco).
## Se editan desde el Inspector en res://config/memory_4_settings.tres.

@export_group("Barco")
## Altura del nivel del mar respecto de la cubierta (negativo = más abajo que la cubierta).
@export_range(-6.0, -0.5, 0.1, "suffix:m") var sea_level: float = -2.6
## Escora fija del barco por el peso de la red (hacia un lado, siempre).
@export_range(0.0, 15.0, 0.1, "suffix:°") var deck_roll: float = 1.5
## Cuánto cabecea el barco de lado a lado con el oleaje. Es lo que hace resbalar al jugador.
@export_range(0.0, 12.0, 0.1, "suffix:°") var sway_roll: float = 3.5
## Duración de un vaivén completo.
@export_range(1.0, 12.0, 0.1, "suffix:s") var sway_period: float = 5.0
## Inclinación extra por cada golpe fallado (el barco se escora más mientras se tarda).
@export_range(0.0, 5.0, 0.1, "suffix:°") var roll_per_miss: float = 0.8

@export_group("Cubierta resbaladiza")
## Empuje lateral por cada grado de inclinación del barco. Más alto = resbala más.
@export_range(0.0, 2.0, 0.05, "suffix:m/s²/°") var slip_strength: float = 0.38
## Si el jugador baja de esta altura (cae por un costado abierto), cae al agua.
@export_range(-6.0, -0.5, 0.1, "suffix:m") var fall_height: float = -1.9
## Tiempo en negro, bajo el agua helada, antes de volver a bordo.
@export_range(0.5, 8.0, 0.1, "suffix:s") var fall_dark_time: float = 3.0
## Cuánto se suma a la inclinación del barco cada vez que se cae (como un fallo más).
@export_range(0.0, 5.0, 0.1, "suffix:°") var fall_roll_penalty: float = 0.8
## Frase al volver a bordo. %s = nombre del protagonista.
@export var fall_rescue_line: String = "TRIPULANTE: ¡Te tenemos, %s! ¡Volvé a las sogas!"

@export_group("Cortar las sogas (evento rápido)")
## Cuántos golpes bien dados hacen falta para cortar cada soga.
@export_range(1, 5, 1) var hits_per_rope: int = 2
## Velocidad del marcador, en recorridos de la barra por segundo.
@export_range(0.2, 3.0, 0.05, "suffix:/s") var marker_speed: float = 0.8
## Ancho de la zona buena, como fracción de la barra (0.2 = 20%).
@export_range(0.05, 0.6, 0.01) var zone_width: float = 0.24
## Cuánto se achica la zona buena en cada soga siguiente (la tensión sube).
@export_range(0.0, 0.1, 0.005) var zone_shrink_per_rope: float = 0.028
## Cuánto se acelera el marcador en cada soga siguiente.
@export_range(0.0, 1.0, 0.05, "suffix:/s") var speed_gain_per_rope: float = 0.25
## Cuántas veces puede recorrer la barra el marcador sin que el jugador apriete, antes de contar como fallo.
@export_range(1, 5, 1) var max_passes: int = 2
## Pausa después de fallar antes de poder volver a intentar. No hay game over.
@export_range(0.2, 3.0, 0.05, "suffix:s") var retry_delay: float = 0.8
## Texto del aviso al acercarse a una soga.
@export var rope_prompt: String = "(E) Cortar la soga"
## Frases de la tripulación al fallar un golpe (se elige una al azar). %s = nombre del protagonista.
@export var urge_lines: Array[String] = [
	"TRIPULANTE: ¡Más rápido, %s!",
	"TRIPULANTE: ¡No aguanta más!",
	"TRIPULANTE: ¡Pegale ahora, %s!",
]

@export_group("Tripulación")
## Nombre provisorio del protagonista (❓ ABIERTO: todavía no está decidido).
@export var protagonist_name: String = "NOMBRE"
## Frase de la tripulación al empezar, para que el jugador sepa qué hacer. %s = nombre del protagonista.
@export var intro_line: String = "TRIPULANTE: ¡Las sogas, %s! ¡Cortalas o nos damos vuelta!"
## Pausa antes de la frase inicial.
@export_range(0.0, 6.0, 0.1, "suffix:s") var intro_delay: float = 1.5
## Frase cuando se corta la última soga.
@export var success_line: String = "TRIPULACIÓN: ¡LO LOGRAMOS!"
## Frase de advertencia justo después. %s = nombre del protagonista.
@export var warning_line: String = "TRIPULANTE: ¡CUIDADO, %s!!!!"
## Pausa entre cortar la última soga y el "LO LOGRAMOS".
@export_range(0.0, 3.0, 0.05, "suffix:s") var success_delay: float = 0.9
## Pausa entre el "LO LOGRAMOS" y el grito de advertencia.
@export_range(0.0, 4.0, 0.05, "suffix:s") var warning_delay: float = 1.6
## Cuánto tiempo queda en pantalla cada frase.
@export_range(0.5, 6.0, 0.1, "suffix:s") var line_duration: float = 2.6

@export_group("La ola")
## Altura de la cresta sobre el mar.
@export_range(10.0, 60.0, 1.0, "suffix:m") var wave_height: float = 28.0
## Ancho del frente de la ola.
@export_range(40.0, 300.0, 5.0, "suffix:m") var wave_width: float = 170.0
## A qué distancia detrás de la popa aparece la ola.
@export_range(40.0, 220.0, 5.0, "suffix:m") var wave_distance: float = 110.0
## Cuánto tarda la ola en llegar y cubrir al jugador.
@export_range(4.0, 30.0, 0.5, "suffix:s") var wave_time: float = 12.0
## Cuánto se acelera hacia el final (1 = velocidad constante).
@export_range(1.0, 2.5, 0.05) var wave_acceleration: float = 1.4
## En qué punto del recorrido empieza a enroscarse el labio (0 = al salir, 1 = al llegar).
@export_range(0.0, 0.9, 0.01) var curl_start: float = 0.2
## Cuánto levanta la vista el jugador al ver la ola encima.
@export_range(0.0, 60.0, 1.0, "suffix:°") var look_up_angle: float = 28.0
## Brillo propio muy tenue de la ola, para que se adivine su silueta entre rayo y rayo.
@export_range(0.0, 0.2, 0.002) var wave_glow: float = 0.02

@export_group("Rayos y lluvia")
## Tiempo mínimo entre rayos.
@export_range(0.5, 20.0, 0.1, "suffix:s") var lightning_min_interval: float = 2.4
## Tiempo máximo entre rayos.
@export_range(0.5, 30.0, 0.1, "suffix:s") var lightning_max_interval: float = 6.5
## Intensidad de la luz de un rayo. Es la única luz fuerte de la escena.
@export_range(0.0, 20.0, 0.1) var lightning_energy: float = 1.8
## Cuánto sube la luz ambiente durante el rayo.
@export_range(0.0, 3.0, 0.05) var lightning_ambient: float = 0.35
## Cuánto se enciende el cielo (las nubes) con cada rayo. Es lo que recorta la silueta de la ola.
@export_range(0.0, 40.0, 0.5) var lightning_sky: float = 14.0
## Duración de un rayo (incluye los parpadeos).
@export_range(0.1, 1.5, 0.01, "suffix:s") var lightning_time: float = 0.45
## Cantidad de gotas de lluvia en el aire (rayas finas).
@export_range(0, 6000, 50) var rain_amount: int = 1800
## Opacidad de la lluvia donde hay luces del barco (cubierta).
@export_range(0.0, 0.5, 0.005) var rain_alpha_lit: float = 0.22
## Opacidad extra de la lluvia durante un rayo.
@export_range(0.0, 0.5, 0.005) var rain_alpha_flash: float = 0.1
## Opacidad de la lluvia que se ve alrededor del barco cuando el jugador ya está lejos, en el agua.
@export_range(0.0, 0.3, 0.005) var rain_alpha_far: float = 0.09
## Largo de cada raya de lluvia.
@export_range(0.2, 3.0, 0.05, "suffix:m") var rain_length: float = 0.55
## Grosor de cada raya de lluvia.
@export_range(0.004, 0.1, 0.002, "suffix:m") var rain_width: float = 0.014

@export_group("Hacha")
## Cartel cuando está junto a una soga sin el hacha en la mano.
@export var axe_needed_prompt: String = "Necesitás el hacha"
## Línea de la tripulación si pasa un rato sin que agarre el hacha.
@export var axe_hint_line: String = "TRIPULANTE: ¡El hacha, %s! ¡Está junto a la puerta de la cabina!"
## Cuánto espera antes de avisarle dónde está el hacha.
@export_range(2.0, 60.0, 1.0, "suffix:s") var axe_hint_delay: float = 14.0

@export_group("Gotas y frío")
## Gotas rápidas que pasan al lado y delante de la cara del jugador.
@export_range(0, 800, 10) var near_drop_amount: int = 260
## Opacidad de esas gotas (sube un poco con los rayos).
@export_range(0.0, 1.0, 0.01) var near_drop_alpha: float = 0.34
## Largo de cada gota cercana.
@export_range(0.05, 1.5, 0.01, "suffix:m") var near_drop_length: float = 0.38
## Cantidad de bruma fría que flota alrededor.
@export_range(0, 120, 2) var mist_amount: int = 36
## Opacidad de la bruma fría.
@export_range(0.0, 0.3, 0.005) var mist_alpha: float = 0.05
## Cada cuánto sale el vaho del aliento (frío).
@export_range(1.0, 8.0, 0.1, "suffix:s") var breath_interval: float = 3.4
## Cuántas gotas hay pegadas en la lente en cubierta (0 = ninguna).
@export_range(0.0, 1.0, 0.05) var lens_wet_deck: float = 0.55

@export_group("En el agua")
## Cuánto tarda en salir a la superficie después de la ola.
@export_range(0.5, 8.0, 0.1, "suffix:s") var emerge_time: float = 3.0
## A qué distancia de la popa del barco queda el jugador flotando.
@export_range(30.0, 200.0, 5.0, "suffix:m") var float_distance: float = 85.0
## Cuánto tiempo flota mirando alrededor antes de hundirse.
@export_range(3.0, 60.0, 0.5, "suffix:s") var float_time: float = 16.0
## Cuánto sube y baja el jugador con el oleaje.
@export_range(0.0, 1.0, 0.01, "suffix:m") var bob_height: float = 0.3
## Cuánto se aleja el barco mientras flota.
@export_range(0.0, 200.0, 5.0, "suffix:m") var ship_drift: float = 70.0
## Cuánto gira el barco (de espaldas al jugador, buscando en otra dirección).
@export_range(0.0, 180.0, 1.0, "suffix:°") var ship_turn: float = 35.0
## Intensidad del reflector del barco (se enciende cuando el jugador está en el agua).
@export_range(0.0, 30.0, 0.5) var searchlight_energy: float = 7.0
## Velocidad de barrido del reflector del barco.
@export_range(0.0, 2.0, 0.05, "suffix:/s") var searchlight_speed: float = 0.35

@export_group("Reflector del mástil")
## Intensidad del reflector sobre la cubierta (luz cálida, muy sutil).
@export_range(0.0, 8.0, 0.1) var deck_floodlight_energy: float = 2.0
## Apertura del cono del reflector mientras ilumina la cubierta.
@export_range(10.0, 80.0, 1.0, "suffix:°") var deck_floodlight_angle: float = 40.0
## Inclinación del reflector sobre la cubierta (negativo = hacia abajo).
@export_range(-90.0, 0.0, 1.0, "suffix:°") var deck_floodlight_pitch: float = -46.0
## Apertura del cono cuando busca al náufrago (más cerrado = haz más definido).
@export_range(4.0, 40.0, 1.0, "suffix:°") var search_angle: float = 10.0
## Separación mínima (además de la apertura del cono) entre el haz y el jugador: así nunca lo encuentra.
@export_range(0.0, 40.0, 1.0, "suffix:°") var search_safe_margin: float = 12.0
## Inclinación del haz de búsqueda sobre el mar.
@export_range(-30.0, 0.0, 0.5, "suffix:°") var search_pitch: float = -10.0
## Segundos que tarda el reflector en pasar de la cubierta a barrer el mar.
@export_range(0.5, 8.0, 0.1, "suffix:s") var search_turn_time: float = 2.5

## Largo visible del haz de luz (el cono luminoso en el aire).
@export_range(10.0, 150.0, 1.0, "suffix:m") var beam_length: float = 70.0
## Visibilidad del haz sobre la cubierta (muy sutil).
@export_range(0.0, 1.0, 0.01) var beam_strength_deck: float = 0.05
## Visibilidad del haz mientras busca en el mar.
@export_range(0.0, 1.0, 0.01) var beam_strength_search: float = 0.3

@export_group("Oscuridad bajo el agua")
## Ángulo hacia abajo desde el cual empieza a oscurecerse la parte baja de la pantalla.
@export_range(0.0, 60.0, 1.0, "suffix:°") var abyss_start_angle: float = 6.0
## Ángulo hacia abajo con el cual todo es negro (mirar el abismo).
@export_range(10.0, 89.0, 1.0, "suffix:°") var abyss_full_angle: float = 50.0

@export_group("Hundimiento")
## Cuánto tarda en hundirse hasta la oscuridad total.
@export_range(2.0, 40.0, 0.5, "suffix:s") var sink_time: float = 14.0
## Profundidad final (positiva).
@export_range(5.0, 150.0, 1.0, "suffix:m") var sink_depth: float = 45.0
## Tiempo en oscuridad total antes de que aparezca la luz.
@export_range(0.0, 20.0, 0.5, "suffix:s") var darkness_time: float = 5.0
## Cuánto tarda en aparecer y crecer la luz del helicóptero.
@export_range(1.0, 30.0, 0.5, "suffix:s") var rescue_light_time: float = 9.0
## Intensidad máxima de la luz del helicóptero.
@export_range(0.0, 3.0, 0.05) var rescue_light_strength: float = 1.8
