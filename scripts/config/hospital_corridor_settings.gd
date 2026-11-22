class_name HospitalCorridorSettings
extends Resource
## Valores del pasillo del hospital de la M3 (segunda sala intermedia): un pasillo de la casa
## con el techo del hospital, paneles cuadrados cálidos que se pierden en la niebla.
## Se editan desde el Inspector en res://config/m3_hospital_corridor.tres.

@export_group("Pasillo")
## Ancho del pasillo.
@export_range(1.8, 10.0, 0.1, "suffix:m") var width: float = 3.0
## Largo del pasillo.
@export_range(10.0, 120.0, 1.0, "suffix:m") var length: float = 44.0
## Alto del techo.
@export_range(2.2, 6.0, 0.05, "suffix:m") var height: float = 2.6
## Cuánto pesan las piernas al llegar al fondo (0 = nada, 1 = lo mismo que en el pasillo de la casa).
@export_range(0.0, 1.0, 0.01) var leg_drag: float = 0.45

@export_group("Paneles del techo (las luces del hospital)")
## Lado de cada panel cuadrado.
@export_range(0.3, 2.0, 0.05, "suffix:m") var panel_size: float = 0.8
## Separación entre las dos columnas de paneles.
@export_range(0.5, 6.0, 0.05, "suffix:m") var column_spacing: float = 1.4
## Separación entre filas, a lo largo del pasillo.
@export_range(1.0, 8.0, 0.1, "suffix:m") var row_spacing: float = 2.4
## Color de los paneles (el cálido de las 6 luces de la M4 y del despertar).
@export var panel_color: Color = Color(1.0, 0.72, 0.34)
## Qué tan fuerte brilla el panel en sí.
@export_range(0.0, 8.0, 0.05) var panel_glow: float = 1.05
## Cuánta luz tira cada fila sobre el pasillo.
@export_range(0.0, 5.0, 0.05) var light_energy: float = 0.75
## Hasta dónde llega la luz de cada fila.
@export_range(1.0, 12.0, 0.1, "suffix:m") var light_range: float = 4.2
## Cuánto tarda un panel en prenderse o apagarse.
@export_range(0.01, 1.0, 0.01, "suffix:s") var switch_time: float = 0.07

@export_group("Niebla")
## Luz ambiente del pasillo, respecto de la de la casa (0 = solo alumbran los paneles: el apagón es negro).
@export_range(0.0, 2.0, 0.01) var ambient: float = 0.06
## Densidad de la niebla: más alto = los paneles del fondo se pierden antes.
@export_range(0.0, 0.3, 0.002) var fog_density: float = 0.06
## Color de la niebla.
@export var fog_color: Color = Color(0.2, 0.15, 0.08)
## Cuánto tarda la niebla en aparecer al entrar (y en irse al salir).
@export_range(0.0, 5.0, 0.1, "suffix:s") var fog_fade: float = 1.2

@export_group("Las luces se apagan atrás")
## Una fila se apaga cuando el jugador la dejó esta distancia atrás.
@export_range(0.5, 15.0, 0.1, "suffix:m") var behind_margin: float = 3.2
## Probabilidad por segundo de que una fila prendida parpadee sola.
@export_range(0.0, 1.0, 0.005) var random_flicker: float = 0.035

@export_group("Bip del monitor")
## Cada cuánto suena el bip al entrar...
@export_range(0.2, 3.0, 0.01, "suffix:s") var beep_interval_start: float = 1.15
## ...y al llegar al fondo (el pulso se acelera).
@export_range(0.2, 3.0, 0.01, "suffix:s") var beep_interval_end: float = 0.62
## Volumen del bip.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var beep_volume_db: float = -9.0
## Cuánto bajan los paneles con cada bip (0 = no laten, 1 = se apagan del todo).
@export_range(0.0, 1.0, 0.01) var beep_dip: float = 0.3
## Cuánto dura esa bajada.
@export_range(0.02, 0.6, 0.01, "suffix:s") var beep_dip_time: float = 0.14

@export_group("Apagón y las seis luces")
## En qué parte del pasillo se corta la luz (0 = al entrar, 1 = nunca).
@export_range(0.0, 1.0, 0.01) var blackout_at: float = 0.55
## Cuánto dura la oscuridad total (solo se oye el bip).
@export_range(0.1, 8.0, 0.1, "suffix:s") var blackout_time: float = 2.2
## Cuántas filas quedan prendidas después, siguiendo al jugador. Con 3 filas y 2 columnas son
## las 6 luces del techo del hospital.
@export_range(1, 6, 1) var rows_after: int = 3

@export_group("Sonido")
## Zumbido de los tubos (con todas las filas prendidas).
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var hum_volume_db: float = -17.0
## Chasquido de cada fila que se apaga o se prende.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var clack_volume_db: float = -8.0
## Chisporroteo de una fila que parpadea.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var flicker_volume_db: float = -14.0
## Golpe grave del apagón.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var thud_volume_db: float = -4.0
## Drone grave de fondo.
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var drone_volume_db: float = -16.0
