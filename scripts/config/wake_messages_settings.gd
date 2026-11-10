class_name WakeMessagesSettings
extends Resource
## Valores de la sala de los mensajes de la M3 (primera sala intermedia): un cuarto vacío de la
## casa donde el sueño le escribe al protagonista que despierte. Los mensajes aparecen donde no
## está mirando, cada vez más, cada vez más desesperados.
## Se editan desde el Inspector en res://config/m3_wake_messages.tres.

@export_group("Sala")
## Ancho de la sala.
@export_range(3.0, 20.0, 0.5, "suffix:m") var room_width: float = 7.0
## Largo de la sala.
@export_range(4.0, 30.0, 0.5, "suffix:m") var room_depth: float = 12.0
## Alto del techo.
@export_range(2.2, 6.0, 0.05, "suffix:m") var room_height: float = 2.8
## Dónde está la salida en la pared del fondo (0 = al centro; positivo = a la derecha).
@export_range(-8.0, 8.0, 0.1, "suffix:m") var exit_x: float = 2.3
## Cuánto pesan las piernas al llegar al fondo (0 = nada).
@export_range(0.0, 1.0, 0.01) var leg_drag: float = 0.25

@export_group("Textos")
## Los tres mensajes que ya están al entrar: pared del fondo, pared izquierda y piso.
@export var first_messages: PackedStringArray = PackedStringArray(["despertá", "por favor", "otra vez la pesadilla"])
## Mensajes tranquilos (letra de imprenta, blancos, como proyectados): los primeros que aparecen.
@export var calm_texts: PackedStringArray = PackedStringArray([
	"despertá", "por favor", "es un sueño", "estás soñando", "otra vez la pesadilla", "despierta",
])
## Mensajes desesperados (a mano, en rojo): los que siguen.
@export var urgent_texts: PackedStringArray = PackedStringArray([
	"DESPERTÁ", "despertá", "despertate", "despierta", "es una pesadilla", "es un sueño",
	"no es real", "estás soñando", "abrí los ojos", "por favor", "POR FAVOR", "volvé", "DESPERTÁ",
])

@export_group("Cómo aparecen")
## Cuántos mensajes tranquilos aparecen antes de que empiecen los rojos.
@export_range(0, 60, 1) var calm_count: int = 7
## Tope de mensajes en la sala (por rendimiento y para que se sigan leyendo).
@export_range(10, 600, 1) var max_messages: int = 260
## Cuántos mensajes nuevos por segundo, como mucho (crece con la degradación de la casa).
@export_range(0.1, 30.0, 0.1, "suffix:/s") var rate: float = 3.5
## Cada cuánto se fija si puede escribir (siempre donde el jugador no mira).
@export_range(0.05, 3.0, 0.05, "suffix:s") var check_interval: float = 0.4
## Qué tan lejos del centro de la vista tiene que estar un lugar para escribir ahí sin que se vea.
@export_range(30.0, 120.0, 1.0, "suffix:°") var unseen_angle: float = 72.0
## En cada parpadeo del sueño aparecen estos mensajes de golpe, aunque se esté mirando.
@export_range(0, 60, 1) var blink_count: int = 6

@export_group("Apagón")
## En qué parte de la sala se va la luz un instante (0 = al entrar, 1 = nunca).
@export_range(0.0, 1.0, 0.01) var burst_at: float = 0.6
## Cuánto dura la oscuridad.
@export_range(0.05, 4.0, 0.05, "suffix:s") var burst_dark_time: float = 0.7
## Cuántos mensajes aparecen en esa oscuridad: cuando vuelve la luz, la sala está cubierta.
@export_range(0, 300, 1) var burst_count: int = 110

@export_group("Aspecto")
## Alto de letra de los mensajes tranquilos.
@export_range(0.05, 1.0, 0.01, "suffix:m") var calm_size: float = 0.26
## Alto de letra del primer mensaje grande de la pared del fondo.
@export_range(0.1, 2.0, 0.01, "suffix:m") var title_size: float = 0.62
## Alto de letra de los mensajes rojos: el más chico...
@export_range(0.05, 1.0, 0.01, "suffix:m") var urgent_size_min: float = 0.17
## ...y el más grande.
@export_range(0.05, 2.0, 0.01, "suffix:m") var urgent_size_max: float = 0.7
## Color de los mensajes tranquilos (blanco que deja ver la pared, como una proyección).
@export var calm_color: Color = Color(0.92, 0.94, 0.9, 0.5)
## Color de los mensajes rojos.
@export var urgent_color: Color = Color(0.72, 0.05, 0.04, 0.96)
## Cuánto se tuercen los mensajes tranquilos.
@export_range(0.0, 45.0, 0.5, "suffix:°") var calm_tilt: float = 2.5
## Cuánto se tuercen los mensajes rojos.
@export_range(0.0, 90.0, 0.5, "suffix:°") var urgent_tilt: float = 17.0

@export_group("Luz")
## Luz ambiente de la sala, respecto de la de la casa (0 = solo alumbra la lamparita: el apagón es negro).
@export_range(0.0, 2.0, 0.01) var ambient: float = 0.12
## Fuerza de la lamparita del techo.
@export_range(0.0, 5.0, 0.01) var bulb_energy: float = 0.55
## Color de la lamparita.
@export var bulb_color: Color = Color(1.0, 0.86, 0.62)
## Hasta dónde llega.
@export_range(1.0, 25.0, 0.1, "suffix:m") var bulb_range: float = 9.0
## Cuánto tiembla la luz (0 = fija).
@export_range(0.0, 1.0, 0.01) var bulb_flicker: float = 0.12

@export_group("Sonido")
## Trazo de escritura que suena en la pared donde acaba de aparecer un mensaje.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var scrawl_volume_db: float = -7.0
## Pausa mínima entre dos trazos.
@export_range(0.1, 5.0, 0.05, "suffix:s") var scrawl_gap: float = 0.8
## Golpe grave del apagón.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var thud_volume_db: float = -5.0
## Drone grave de fondo.
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var drone_volume_db: float = -15.0
