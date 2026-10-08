class_name Memory4Settings
extends Resource
## Valores de "feel" y textos provisorios de la Memoria 4 (el accidente en el barco).
## Se editan desde el Inspector en res://config/memory_4_settings.tres.

@export_group("Barco")
## Altura del nivel del mar respecto de la cubierta (negativo = más abajo que la cubierta).
@export_range(-6.0, -0.5, 0.1, "suffix:m") var sea_level: float = -2.6
## Inclinación base de la cámara hacia babor: el barco está escorado por el peso de la red.
@export_range(0.0, 15.0, 0.1, "suffix:°") var deck_roll: float = 4.0
## Cuánto oscila la cámara de lado a lado con el vaivén del barco.
@export_range(0.0, 6.0, 0.1, "suffix:°") var sway_roll: float = 1.6
## Duración de un vaivén completo.
@export_range(1.0, 12.0, 0.1, "suffix:s") var sway_period: float = 5.0
## Inclinación extra por cada golpe fallado (el barco se escora más mientras se tarda).
@export_range(0.0, 5.0, 0.1, "suffix:°") var roll_per_miss: float = 1.2

@export_group("Cortar las sogas (evento rápido)")
## Cuántos golpes bien dados hacen falta para cortar cada soga.
@export_range(1, 5, 1) var hits_per_rope: int = 2
## Velocidad del marcador, en recorridos de la barra por segundo.
@export_range(0.2, 3.0, 0.05, "suffix:/s") var marker_speed: float = 0.9
## Ancho de la zona buena, como fracción de la barra (0.2 = 20%).
@export_range(0.05, 0.6, 0.01) var zone_width: float = 0.2
## Cuánto se achica la zona buena en cada soga siguiente (la tensión sube).
@export_range(0.0, 0.1, 0.005) var zone_shrink_per_rope: float = 0.03
## Cuánto se acelera el marcador en cada soga siguiente.
@export_range(0.0, 1.0, 0.05, "suffix:/s") var speed_gain_per_rope: float = 0.2
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
## Cantidad de gotas de lluvia en el aire.
@export_range(0, 6000, 50) var rain_amount: int = 1800

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
@export_range(0.0, 30.0, 0.5) var searchlight_energy: float = 9.0
## Velocidad de barrido del reflector del barco.
@export_range(0.0, 2.0, 0.05, "suffix:/s") var searchlight_speed: float = 0.35

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
