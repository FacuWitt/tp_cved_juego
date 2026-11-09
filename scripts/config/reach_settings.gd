class_name ReachSettings
extends Resource
## Hasta dónde llega el jugador para agarrar un objeto puesto en alto (p. ej. la luna en el estante
## de la M1, que se alcanza subido al banquito). Lo usa PickupObject.can_be_picked_by().
## Sin este recurso un objeto se agarra desde cualquier altura, como siempre.

## Cuánto más abajo que el objeto pueden quedar los ojos del jugador y todavía alcanzarlo.
## En la M1: parado en el piso el nene queda 0,9 m abajo de la luna (no llega) y subido al
## banquito, 0,45 m (llega). Más alto = más fácil.
@export_range(0.0, 3.0, 0.05, "suffix:m") var max_eye_drop: float = 0.65
## Si está activo, hay que estar apoyado en algo: saltando no se alcanza.
@export var must_stand: bool = true
