class_name Memory3Settings
extends Resource
## Valores de la Memoria 3 (la casa, la madrugada antes de embarcar): textos de etapa 0,
## el laberinto de la casa que se repite, la degradación, las puertas y la entrega del barquito.
## Se editan desde el Inspector en res://config/memory_3_settings.tres.

@export_group("Textos (etapa 0, hasta tener voces)")
## Al despertarse en la mesa de la cocina por el trueno.
@export_multiline var wake_line: String = "(Un trueno. Se quedó dormido en la mesa de la cocina. Son casi las 3.)"
## La hija lo llama desde algún lugar de la casa, al empezar.
@export_multiline var first_call_line: String = "VOZ (hija, lejos): ¿Papá...? ¿Ya te vas?"
## Cada vez que elige la puerta buena: la voz se oye más cerca (una línea por tramo; si faltan, se repite la última).
@export var closer_lines: PackedStringArray = PackedStringArray([
	"VOZ (hija, más cerca): Papá... no te vayas.",
	"VOZ (hija, cerca): Tengo miedo, papá.",
])
## Cada vez que elige mal y vuelve a la cocina: la voz se oye más lejos (se van alternando).
@export var farther_lines: PackedStringArray = PackedStringArray([
	"(Otra vez la cocina.) VOZ (hija, muy lejos): ¿Papá...?",
	"(La cocina de nuevo. Hay más agua en el piso.) VOZ (hija, lejos): ¿Dónde estás?",
])
## Al llegar al pasillo del cuarto de la hija.
@export_multiline var room_arrival_line: String = "VOZ (hija, del otro lado de la puerta): ¿Papá? ¿Sos vos?"
## La hija, cuando el protagonista entra al cuarto.
@export_multiline var plea_line: String = "HIJA: No quiero que te vayas, papá..."
## Lo que dice el protagonista al dejarle el barquito.
@export_multiline var give_line: String = "PAPÁ: Cuidámelo hasta que vuelva."
## Cuando la casa se estabiliza y se abre el camino a la entrada.
@export_multiline var stable_line: String = "(La casa se queda quieta. El bolso espera en la entrada.)"
## Mira contextual al apuntar a una puerta cerrada.
@export var open_prompt: String = "(E) Abrir"
## Mira contextual al apuntar a la hija con el barquito en la mano.
@export var give_prompt: String = "(E) Darle el barquito"
## Cuánto dura cada línea en pantalla.
@export_range(0.5, 15.0, 0.1, "suffix:s") var line_duration: float = 4.0
## Pausa entre que termina el despertar y la primera llamada de la hija.
@export_range(0.0, 10.0, 0.1, "suffix:s") var first_call_delay: float = 2.5

@export_group("Laberinto")
## Puerta buena de cada tramo (0 = izquierda, 1 = centro, 2 = derecha). La cantidad de
## elementos es la cantidad de tramos: al pasar la puerta buena del último se llega al cuarto.
@export var good_doors: PackedInt32Array = PackedInt32Array([1, 0, 2])
## Distancia máxima a la que se conserva la posición del jugador al cruzar un umbral
## (por si entra en diagonal o muy rápido). Más grande = el salto se nota menos.
@export_range(0.5, 3.0, 0.05, "suffix:m") var carry_max_offset: float = 1.8

@export_group("Degradación")
## Degradación con la que empieza la casa (0 = intacta, 1 = lo peor). Es la memoria más degradada:
## ya hay agua desde el principio.
@export_range(0.0, 1.0, 0.01) var base_degradation: float = 0.25
## Cuánto sube la degradación cada vez que elige mal y vuelve a la cocina.
@export_range(0.0, 1.0, 0.01) var degradation_per_mistake: float = 0.25
## Cuánto más largo es el último tramo del pasillo con la degradación al máximo.
## (El largo base sale de la forma de cada tramo, en "Forma del pasillo".)
@export_range(0.0, 30.0, 0.1, "suffix:m") var hallway_extra_length: float = 8.0
## Mientras camina por el pasillo, el fondo se aleja a esta velocidad (multiplicada por la degradación).
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var hallway_creep_speed: float = 1.2
## Hasta cuánto se puede alejar el fondo mientras camina (multiplicado por la degradación).
@export_range(0.0, 20.0, 0.1, "suffix:m") var hallway_creep_max: float = 5.0
## Cada cuánto se rearma el pasillo mientras el fondo se aleja (más chico = más suave, más costoso).
@export_range(0.05, 2.0, 0.05, "suffix:m") var hallway_creep_step: float = 0.25
## Cuánto se apagan las fotos del pasillo con la degradación al máximo (0 = nada, 1 = desaparecen).
@export_range(0.0, 1.0, 0.01) var photo_fade_max: float = 0.85
## Cuánto más fuerte es la luz fría con la degradación al máximo (1 = el doble).
@export_range(0.0, 3.0, 0.05) var cold_light_boost: float = 1.0
## Cuánto tarda la casa en estabilizarse después de entregar el barquito.
@export_range(0.1, 10.0, 0.1, "suffix:s") var stabilize_time: float = 3.0

@export_group("Puertas")
## Ángulo de una puerta abierta.
@export_range(30.0, 120.0, 1.0, "suffix:°") var door_open_angle: float = 88.0
## Cuánto tarda una puerta en abrirse.
@export_range(0.05, 3.0, 0.05, "suffix:s") var door_open_time: float = 0.7
## Intensidad de la luz cálida bajo la puerta buena en el primer tramo.
@export_range(0.0, 5.0, 0.05) var door_glow_energy: float = 0.6
## Cuánto más fuerte es esa luz en cada tramo siguiente (el velador está cada vez más cerca).
@export_range(0.0, 5.0, 0.05) var door_glow_step: float = 0.35

@export_group("Entrega del barquito")
## Pausa entre que la hija habla y el protagonista puede darle el barquito (la mira lo avisa igual).
@export_range(0.0, 5.0, 0.1, "suffix:s") var give_line_delay: float = 1.2
## Pausa entre la línea "Cuidámelo..." y que la casa empiece a estabilizarse.
@export_range(0.0, 10.0, 0.1, "suffix:s") var stabilize_delay: float = 2.5

@export_group("Voz de la hija (sale de la puerta buena)")
## Lo que suena detrás de la puerta buena. Hoy es un placeholder (la cajita musical de la M2):
## reemplazarlo por la grabación de la voz de la hija ("¿Papá...?").
@export var voice_stream: AudioStream
## Volumen de la voz.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var voice_volume_db: float = -4.0
## Cuánto más baja se oye con la casa degradada al máximo (cuanto más perdido, más lejos).
@export_range(0.0, 30.0, 0.5, "suffix:dB") var voice_degradation_db: float = 8.0
## Distancia hasta la que se oye fuerte; más allá se va apagando (más chico = se nota más de dónde viene).
@export_range(0.5, 20.0, 0.1, "suffix:m") var voice_unit_size: float = 2.5
## Distancia a partir de la cual ya no se oye.
@export_range(5.0, 80.0, 0.5, "suffix:m") var voice_max_distance: float = 30.0
## Qué tan atrás de la puerta suena (dentro del tramo oscuro).
@export_range(0.0, 3.0, 0.05, "suffix:m") var voice_depth: float = 1.0
## Pausa entre que termina de sonar y vuelve a llamar.
@export_range(0.0, 20.0, 0.1, "suffix:s") var voice_interval: float = 3.0

@export_group("Fotos del pasillo (la misma foto, cada vez más borrosa)")
## La foto que se repite. Vacío = una foto genérica dibujada por el shader (una silueta en sepia).
@export var photo_texture: Texture2D
## Distancia entre una foto y la siguiente (se alternan las paredes).
@export_range(0.5, 5.0, 0.05, "suffix:m") var photo_spacing: float = 1.4
## Dónde está la primera foto, desde la entrada del pasillo.
@export_range(0.0, 5.0, 0.05, "suffix:m") var photo_first_distance: float = 1.2
## Altura de las fotos.
@export_range(0.5, 2.5, 0.05, "suffix:m") var photo_height: float = 1.5
## Qué tan borrosa es la primera foto (0 = nítida, 1 = no se distingue nada).
@export_range(0.0, 1.0, 0.01) var photo_blur_start: float = 0.0
## Cuánto más borrosa es cada metro más adentro del pasillo.
@export_range(0.0, 0.3, 0.005, "suffix:/m") var photo_blur_per_meter: float = 0.06
## Cuánto más borrosas están todas con la casa degradada al máximo.
@export_range(0.0, 1.0, 0.01) var photo_blur_degradation: float = 0.4
## Cuánto se tuercen las fotos más borrosas (las nítidas quedan derechas).
@export_range(0.0, 30.0, 0.5, "suffix:°") var photo_max_tilt: float = 10.0

@export_group("Forma del pasillo (cada tramo distinto)")
## La forma del pasillo en cada tramo: metros en línea recta y giros de 90° (L = izquierda,
## R = derecha). "4 L 3 R 5" = 4 m, dobla a la izquierda, 3 m, dobla a la derecha, 5 m.
## El primer tramo recto tiene que medir al menos 3 m (ahí aparece el jugador al pasar una puerta buena).
## Conviene que termine mirando hacia adelante (misma cantidad de L que de R), así al pasar
## una puerta no se gira la vista. Si faltan formas, se repite la última.
@export var segment_shapes: PackedStringArray = PackedStringArray(["8", "4 L 3 R 4", "3 R 2 L 3 L 2 R 3"])
## Ancho libre del pasillo en cada tramo (la casa se va cerrando). Si faltan, se repite el último.
@export var segment_widths: PackedFloat32Array = PackedFloat32Array([1.6, 1.35, 1.1])
## Alto del pasillo en cada tramo (el techo baja). Si faltan, se repite el último.
@export var segment_heights: PackedFloat32Array = PackedFloat32Array([2.6, 2.4, 2.15])

@export_group("Piernas que no responden")
## Lo que aparece cuando las piernas dejan de responder (se van alternando). Vacío = nada.
@export var stuck_lines: PackedStringArray = PackedStringArray([
	"(Las piernas no le responden.)",
	"(Quiere avanzar y no puede.)",
])


## El largo (sin estirar) de la forma más larga de todos los tramos.
func longest_shape_length() -> float:
	var longest: float = 0.0
	for shape: String in segment_shapes:
		var total: float = 0.0
		for token: String in shape.split(" ", false):
			if token.is_valid_float():
				total += token.to_float()
		longest = maxf(longest, total)
	return longest
