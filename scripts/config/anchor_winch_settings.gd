class_name AnchorWinchSettings
extends Resource
## Cómo se siente subir el ancla con la manivela (M4): cuánto sube cada (E), cuánto se
## vuelve a bajar si el jugador afloja y cómo gira la manivela. Lo usa AnchorWinch.

@export_group("Subir")
## Cuánto sube el ancla con cada (E), en fracción del recorrido (0,04 = 25 apretadas sin pausa).
@export_range(0.005, 0.5, 0.005) var progress_per_press: float = 0.04
## Cuánto puede pasar entre dos (E) sin que el ancla empiece a bajar.
@export_range(0.0, 2.0, 0.05, "suffix:s") var slip_delay: float = 0.35
## Qué tan rápido se vuelve a bajar cuando el jugador afloja (fracción del recorrido por segundo).
@export_range(0.0, 1.0, 0.01, "suffix:1/s") var slip_speed: float = 0.12

@export_group("Manivela")
## Vueltas que da la manivela en todo el recorrido.
@export_range(1.0, 60.0, 0.5) var crank_turns: float = 12.0
## Qué tan rápido la manivela alcanza su giro (más alto = más seco).
@export_range(1.0, 40.0, 0.5, "suffix:1/s") var crank_follow: float = 12.0
## Sentido de giro (1 o -1).
@export_range(-1, 1, 2) var crank_direction: int = 1
## Golpe de cámara hacia abajo en cada (E).
@export_range(0.0, 6.0, 0.1, "suffix:°") var press_camera_kick: float = 1.4
## Cuánto tarda el jugador en acomodarse frente a la manivela.
@export_range(0.05, 2.0, 0.05, "suffix:s") var engage_time: float = 0.35

@export_group("Ancla")
## Balanceo del ancla colgando.
@export_range(0.0, 30.0, 0.5, "suffix:°") var anchor_sway: float = 6.0
@export_range(0.05, 3.0, 0.05, "suffix:Hz") var anchor_sway_rate: float = 0.35
## Grosor de la soga del ancla.
@export_range(0.005, 0.1, 0.005, "suffix:m") var rope_radius: float = 0.025
