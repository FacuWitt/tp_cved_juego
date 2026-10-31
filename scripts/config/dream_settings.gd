class_name DreamSettings
extends Resource
## Cuánto "sueño" tiene una memoria: la imagen que ondula y se desenfoca en los bordes, la cámara
## que se mece, las piernas que pesan al querer avanzar, los parpadeos y las cosas que cambian de
## lugar cuando no se las mira. Lo usan DreamEffects y DreamShifter.
## Cada efecto se puede apagar por separado para comparar.
## La intensidad la da la memoria (en la M3, la degradación de la casa): 0 = real, 1 = lo más soñado.

## Multiplica el nivel que manda la memoria (con 2, una casa degradada al 50 % ya sueña al máximo).
@export_range(0.0, 4.0, 0.05) var level_gain: float = 2.0
## Qué tan rápido sigue la intensidad al nivel (más alto = cambia más de golpe).
@export_range(0.1, 10.0, 0.1, "suffix:1/s") var level_follow: float = 1.5

@export_group("Imagen (ondas, bordes borrosos, doble imagen)")
@export var haze_enabled: bool = true
## Cuánto ondula la imagen (fracción de la pantalla).
@export_range(0.0, 0.03, 0.0005) var wave_amount: float = 0.006
## Cuántas ondas hay a lo ancho de la pantalla.
@export_range(0.5, 20.0, 0.1) var wave_frequency: float = 5.0
## Qué tan rápido se mueven las ondas.
@export_range(0.0, 5.0, 0.05) var wave_speed: float = 0.5
## Cuánto se desenfocan los bordes (el centro queda nítido).
@export_range(0.0, 6.0, 0.1) var edge_blur: float = 3.0
## Separación de colores en los bordes.
@export_range(0.0, 0.03, 0.0005) var aberration: float = 0.006
## Separación de la doble imagen (como ver con los ojos cansados).
@export_range(0.0, 0.05, 0.0005) var ghost_offset: float = 0.008
## Cuánto se ve la doble imagen (0 = nada).
@export_range(0.0, 0.6, 0.01) var ghost_mix: float = 0.25
## Oscurecimiento de las esquinas.
@export_range(0.0, 1.0, 0.01) var vignette: float = 0.7
## Cuánto se apagan los colores.
@export_range(0.0, 1.0, 0.01) var desaturation: float = 0.35
## Color que tiñe la imagen (frío: el coma).
@export var tint: Color = Color(0.78, 0.9, 0.92)

@export_group("Cámara (se mece y el pasillo se estira a la vista)")
@export var sway_enabled: bool = true
## Cuánto se inclina la cámara de un lado al otro.
@export_range(0.0, 10.0, 0.1, "suffix:°") var sway_roll: float = 2.5
## Cuánto tarda en ir y volver.
@export_range(1.0, 20.0, 0.1, "suffix:s") var sway_period: float = 7.0
## Cuánto "respira" el campo de visión.
@export_range(0.0, 10.0, 0.1, "suffix:°") var fov_breath: float = 3.0
## Cuánto tarda en respirar.
@export_range(1.0, 20.0, 0.1, "suffix:s") var fov_breath_period: float = 5.0
## Cuánto se abre el campo de visión al llegar al fondo del pasillo (el fondo se ve más lejos: efecto vértigo).
@export_range(0.0, 40.0, 0.5, "suffix:°") var vertigo_fov: float = 18.0

@export_group("Piernas pesadas (querer avanzar y no poder)")
@export var heavy_legs_enabled: bool = true
## Velocidad que queda al llegar al fondo del pasillo, con el sueño al máximo (1 = normal).
@export_range(0.05, 1.0, 0.01) var min_speed_factor: float = 0.35
## Si correr sirve de algo. Apagado: correr va igual de lento que caminar.
@export var sprint_helps: bool = false
## Qué tan rápido se ponen pesadas (o livianas) las piernas.
@export_range(0.1, 10.0, 0.1, "suffix:1/s") var drag_follow: float = 2.0

@export_group("Piernas que no responden (se frena y no puede avanzar)")
@export var stuck_enabled: bool = true
## Probabilidad por segundo de que las piernas se traben mientras empuja hacia adelante
## (multiplicada por la intensidad del sueño).
@export_range(0.0, 2.0, 0.01, "suffix:/s") var stuck_chance: float = 0.12
## Solo puede pasar a partir de este punto del pasillo (0 = desde la entrada, 1 = solo al llegar).
@export_range(0.0, 1.0, 0.01) var stuck_min_drag: float = 0.25
## Cuánto dura cada vez que se traba.
@export_range(0.2, 8.0, 0.1, "suffix:s") var stuck_duration: float = 1.8
## Si sigue empujando hacia adelante mientras está trabado, el pasillo lo arrastra hacia atrás a esta velocidad.
@export_range(0.0, 3.0, 0.05, "suffix:m/s") var stuck_pull_speed: float = 0.6
## Temblor de la cámara mientras forcejea.
@export_range(0.0, 5.0, 0.05, "suffix:°") var stuck_shake: float = 0.8
## Qué tan rápido tiembla mientras forcejea.
@export_range(1.0, 60.0, 0.5, "suffix:rad/s") var stuck_shake_speed: float = 31.0
## Pausa mínima entre una trabada y la siguiente.
@export_range(0.0, 30.0, 0.5, "suffix:s") var stuck_cooldown: float = 6.0

@export_group("Parpadeos")
@export var blinks_enabled: bool = true
## Espera mínima entre parpadeos (con el sueño al máximo; con menos sueño, más espera).
@export_range(1.0, 60.0, 0.5, "suffix:s") var blink_min_interval: float = 7.0
## Espera máxima entre parpadeos.
@export_range(1.0, 60.0, 0.5, "suffix:s") var blink_max_interval: float = 15.0
## Cuánto dura un parpadeo (en el negro, las cosas cambian de lugar aunque se las esté mirando).
@export_range(0.03, 1.0, 0.01, "suffix:s") var blink_duration: float = 0.14

@export_group("Cosas que cambian cuando no se las mira")
@export var shifts_enabled: bool = true
## Cuánto tiempo tiene que estar fuera de la vista un objeto para poder cambiar.
@export_range(0.1, 10.0, 0.1, "suffix:s") var shift_unseen_time: float = 1.5
## Cada cuánto se revisa.
@export_range(0.1, 5.0, 0.1, "suffix:s") var shift_check_interval: float = 1.0
## Probabilidad de cambiar en cada revisión (multiplicada por la intensidad).
@export_range(0.0, 1.0, 0.01) var shift_chance: float = 0.5
## Hasta cuánto se corre un objeto suelto desde su lugar original.
@export_range(0.0, 1.0, 0.01, "suffix:m") var shift_max_offset: float = 0.25
## Hasta cuánto gira un objeto suelto.
@export_range(0.0, 180.0, 1.0, "suffix:°") var shift_max_yaw: float = 35.0
## Hasta cuánto se tuerce un cuadro colgado.
@export_range(0.0, 45.0, 0.5, "suffix:°") var shift_max_tilt: float = 12.0

@export_group("El pasillo cambia a tus espaldas")
@export var dead_end_enabled: bool = true
## Cuánto tiempo tiene que pasar sin mirar hacia atrás para que el camino recorrido se cierre.
@export_range(0.5, 20.0, 0.1, "suffix:s") var dead_end_unseen_time: float = 3.0
## Cada cuánto se tira la suerte (mientras no mira atrás).
@export_range(0.1, 5.0, 0.1, "suffix:s") var dead_end_check_interval: float = 1.0
## Probabilidad de cerrarse en cada intento (multiplicada por la intensidad del sueño).
@export_range(0.0, 1.0, 0.01) var dead_end_chance: float = 0.5
## La pared aparece entre estas dos distancias detrás del jugador.
@export_range(0.5, 10.0, 0.1, "suffix:m") var dead_end_min_distance: float = 1.5
@export_range(0.5, 15.0, 0.1, "suffix:m") var dead_end_max_distance: float = 4.0
## Cuánto tiempo tiene que estar fuera de la vista la pared para desaparecer (y quizás aparecer en otro lado).
@export_range(0.2, 20.0, 0.1, "suffix:s") var dead_end_vanish_time: float = 2.0

@export_group("Bajo el agua (sonido)")
@export var underwater_enabled: bool = true
## Con el sueño al máximo, se cortan los sonidos por encima de esta frecuencia (más bajo = más sumergido).
@export_range(200.0, 8000.0, 10.0, "suffix:Hz") var underwater_cutoff: float = 900.0
## Cuánto eco hay con el sueño al máximo (0 = nada, 1 = solo eco).
@export_range(0.0, 1.0, 0.01) var underwater_echo: float = 0.35
## Tamaño del eco (más grande = suena como un lugar más grande del que es).
@export_range(0.0, 1.0, 0.01) var underwater_echo_size: float = 0.85

@export_group("Estela al girar la cámara")
@export var trail_enabled: bool = true
## Largo de la estela: cuántos segundos de giro deja marcados la imagen.
@export_range(0.0, 0.5, 0.005, "suffix:s") var trail_length: float = 0.12
## Cuánto se ve la estela (0 = nada).
@export_range(0.0, 1.0, 0.01) var trail_mix: float = 0.6
## Qué tan rápido se apaga la estela cuando deja de girar (más bajo = la imagen tarda más en alcanzarlo).
@export_range(0.5, 30.0, 0.5, "suffix:1/s") var trail_decay: float = 6.0
## Largo máximo de la estela (fracción de la pantalla), para que un giro brusco no la vuelva un borrón.
@export_range(0.0, 0.5, 0.01) var trail_max: float = 0.12

@export_group("Agua que sube")
@export var water_enabled: bool = true
## Altura del agua sobre el piso con el sueño al máximo.
@export_range(0.0, 0.6, 0.01, "suffix:m") var water_max_height: float = 0.14
## Qué tan rápido sube o baja el agua hacia su altura (sube despacio, sin que se note).
@export_range(0.001, 0.5, 0.001, "suffix:m/s") var water_rise_speed: float = 0.01
## Cuánto sube y baja sola, como si algo la moviera.
@export_range(0.0, 0.1, 0.002, "suffix:m") var water_slosh: float = 0.012
## Cuánto tarda en subir y bajar sola.
@export_range(0.5, 20.0, 0.1, "suffix:s") var water_slosh_period: float = 6.0
## Tamaño de las ondas de la superficie.
@export_range(0.1, 5.0, 0.05, "suffix:m") var water_ripple_size: float = 0.8
## Qué tan rápido se mueven las ondas.
@export_range(0.0, 3.0, 0.05) var water_ripple_speed: float = 0.35
@export var water_color: Color = Color(0.04, 0.1, 0.12, 0.8)
