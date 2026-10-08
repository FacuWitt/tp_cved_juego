class_name InteractionPromptSettings
extends Resource
## Valores de "feel" de la mira contextual (el puntito que avisa qué se puede hacer con E).
## Se editan desde el Inspector en res://config/interaction_prompt_settings.tres.

## Radio del punto de mira en estado normal.
@export_range(1.0, 10.0, 0.5, "suffix:px") var normal_radius: float = 2.0
## Radio del punto de mira cuando hay algo para agarrar o soltar (un poco más "gordito").
@export_range(1.0, 15.0, 0.5, "suffix:px") var hover_radius: float = 3.5
## Color del punto de mira en estado normal.
@export var normal_color: Color = Color(1.0, 1.0, 1.0, 0.75)
## Color del punto de mira cuando hay algo para agarrar o soltar.
@export var hover_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## Cuánto tarda en pasar de un estado al otro.
@export_range(0.0, 0.5, 0.01, "suffix:s") var transition_time: float = 0.08
