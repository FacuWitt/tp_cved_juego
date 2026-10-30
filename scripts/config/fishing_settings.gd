class_name FishingSettings
extends Resource
## Valores de la pesca de la Memoria 2: lanzar, esperar la picada, enganchar y pelear el pez.

@export_group("Lanzar")
## Distancia a la que cae la boya, adelante de la mirada.
@export_range(2.0, 25.0, 0.5, "suffix:m") var cast_distance: float = 9.0
## Cuánto tarda la boya en volar hasta el agua.
@export_range(0.2, 3.0, 0.05, "suffix:s") var cast_time: float = 0.8

@export_group("Picada")
## Espera mínima y máxima hasta que pica.
@export_range(0.5, 20.0, 0.1, "suffix:s") var bite_min_wait: float = 2.5
@export_range(0.5, 30.0, 0.1, "suffix:s") var bite_max_wait: float = 6.0
## Ventana para enganchar con E después de la picada.
@export_range(0.2, 3.0, 0.05, "suffix:s") var hook_window: float = 1.1

@export_group("Pelea (W / S)")
## Tamaño del área verde al empezar y al final (fracción de la barra).
@export_range(0.05, 0.9, 0.01) var zone_start_size: float = 0.36
@export_range(0.03, 0.6, 0.01) var zone_end_size: float = 0.16
## Cuánto tarda en achicarse del todo.
@export_range(1.0, 60.0, 0.5, "suffix:s") var zone_shrink_time: float = 14.0
## Velocidad máxima del área verde (fracción de la barra por segundo) para el primer pez;
## cada pez siguiente suma `zone_speed_gain`.
@export_range(0.05, 2.0, 0.01) var zone_speed: float = 0.32
@export_range(0.0, 1.0, 0.01) var zone_speed_gain: float = 0.1
## Qué tan rápido el pez cambia de velocidad (fracción de la barra por segundo²).
## Más bajo = movimientos más suaves y anticipables; más alto = tirones bruscos.
## 30 = cambia de dirección prácticamente al instante (comportamiento original).
@export_range(0.1, 30.0, 0.05) var zone_accel: float = 30.0
## Cuánto varía la velocidad del pez con el tiempo (0 = constante, 1 = muy irregular).
@export_range(0.0, 1.0, 0.01) var zone_speed_wobble: float = 0.6
## Cada cuánto el pez decide si cambia de dirección, y la probabilidad de que la cambie.
@export_range(0.2, 6.0, 0.05, "suffix:s") var zone_turn_min: float = 0.6
@export_range(0.2, 6.0, 0.05, "suffix:s") var zone_turn_max: float = 1.6
@export_range(0.0, 1.0, 0.01) var zone_turn_chance: float = 0.7
## Velocidad máxima del punto con W / S (fracción de la barra por segundo).
@export_range(0.1, 5.0, 0.05) var marker_max_speed: float = 1.1
## Qué tan rápido el punto llega a esa velocidad y se frena al soltar (1/s).
## Más alto = respuesta inmediata, sin peso; más bajo = más inercia.
@export_range(0.5, 40.0, 0.5, "suffix:1/s") var marker_response: float = 14.0
## Cuánto sube la barra de captura por segundo adentro del área y cuánto baja afuera.
@export_range(0.01, 2.0, 0.01, "suffix:/s") var progress_gain: float = 0.2
@export_range(0.01, 2.0, 0.01, "suffix:/s") var progress_loss: float = 0.13
## Captura inicial al enganchar.
@export_range(0.0, 1.0, 0.01) var progress_start: float = 0.3

@export_group("Textos")
@export var cast_prompt: String = "(E) Lanzar"
@export var hook_prompt: String = "¡Picó!  (E) Tirar"
@export var fight_hint: String = "W / S: mantené el punto en la zona verde"
@export var escaped_line: String = "(se soltó)"
@export var caught_lines: PackedStringArray = PackedStringArray(["¡Una trucha!", "¡Otra más!", "¡Qué pescado!"])
