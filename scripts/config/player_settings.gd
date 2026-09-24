class_name PlayerSettings
extends Resource
## Valores de "feel" del jugador en primera persona.
## Se editan desde el Inspector en res://config/player_settings.tres, sin tocar código.

@export_group("Movimiento")
## Velocidad al caminar.
@export_range(0.5, 15.0, 0.1, "suffix:m/s") var walk_speed: float = 4.0
## Velocidad mientras se mantiene la acción "sprint".
@export_range(0.5, 20.0, 0.1, "suffix:m/s") var sprint_speed: float = 6.5
## Qué tan rápido alcanza la velocidad objetivo en el piso. Más alto = más "seco".
@export_range(1.0, 100.0, 0.5, "suffix:m/s²") var acceleration: float = 40.0
## Qué tan rápido frena al soltar las teclas. Más bajo = más "patinoso".
@export_range(1.0, 100.0, 0.5, "suffix:m/s²") var deceleration: float = 50.0
## Fracción de la aceleración disponible en el aire (0 = sin control, 1 = igual que en el piso).
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.4

@export_group("Salto")
## Velocidad vertical inicial del salto. Con 5 m/s se alcanza ~1,3 m de altura.
@export_range(0.0, 15.0, 0.1, "suffix:m/s") var jump_velocity: float = 5.0
## Multiplicador de la gravedad del proyecto mientras sube.
@export_range(0.1, 5.0, 0.05) var gravity_multiplier: float = 1.0
## Multiplicador de la gravedad al caer. Mayor que 1 da saltos más "pesados" y precisos.
@export_range(0.1, 5.0, 0.05) var fall_gravity_multiplier: float = 1.6
## Al soltar el salto mientras sube, la velocidad vertical se multiplica por esto (1 = altura siempre igual).
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.5
## Margen para saltar justo después de salir de un borde.
@export_range(0.0, 0.5, 0.01, "suffix:s") var coyote_time: float = 0.12
## Margen para aceptar un salto apretado justo antes de tocar el piso.
@export_range(0.0, 0.5, 0.01, "suffix:s") var jump_buffer_time: float = 0.12
## Velocidad máxima de caída.
@export_range(1.0, 100.0, 1.0, "suffix:m/s") var max_fall_speed: float = 30.0

@export_group("Cámara")
## Grados que gira la cámara por cada píxel de movimiento del mouse.
@export_range(0.01, 1.0, 0.01, "suffix:°/px") var mouse_sensitivity: float = 0.12
## Invierte el eje vertical del mouse.
@export var invert_y: bool = false
## Campo de visión vertical.
@export_range(40.0, 120.0, 1.0, "suffix:°") var fov: float = 75.0
## Cuánto puede mirar hacia arriba/abajo.
@export_range(30.0, 89.0, 1.0, "suffix:°") var pitch_limit: float = 85.0
## Altura de los ojos medida desde los pies.
@export_range(0.5, 2.5, 0.05, "suffix:m") var camera_height: float = 1.6
