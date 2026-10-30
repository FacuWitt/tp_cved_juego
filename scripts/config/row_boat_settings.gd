class_name RowBoatSettings
extends Resource
## Cómo se siente el bote a remo: cuánto empuja cada remada, cuánto gira, cuánto frena el agua,
## qué pasa al chocar y cuánto se mueve con las olas. Lo usa RowBoat.

@export_group("Remadas")
## Empuje hacia adelante que da cada remada.
@export_range(0.2, 6.0, 0.05, "suffix:m/s") var stroke_thrust: float = 1.0
## Cuánto gira el bote con cada remada de un solo lado. El remo izquierdo lo gira a la derecha y al revés.
@export_range(0.0, 120.0, 1.0, "suffix:°/s") var stroke_turn: float = 30.0
## Tiempo mínimo entre dos remadas del mismo remo.
@export_range(0.15, 1.5, 0.01, "suffix:s") var stroke_cooldown: float = 0.42
## Si se aprieta un remo durante la espera, la remada se guarda este tiempo y sale apenas se puede.
@export_range(0.0, 0.5, 0.01, "suffix:s") var stroke_buffer_time: float = 0.18
## Empuje extra al alternar un remo con el otro (remar parejo rinde más).
@export_range(0.0, 1.0, 0.01) var alternate_bonus: float = 0.3
## Empuje que se pierde al remar dos veces seguidas del mismo lado.
@export_range(0.0, 1.0, 0.01) var repeat_penalty: float = 0.25
## Con esto prendido, el remo derecho gira el bote a la derecha (más intuitivo, menos realista).
@export var invert_steering: bool = false

@export_group("Agua")
## Cuánto frena el agua hacia adelante (por segundo). Más alto = el bote se detiene antes.
@export_range(0.05, 3.0, 0.01, "suffix:1/s") var water_drag: float = 0.6
## Cuánto frena el agua el deslizamiento hacia los costados (la quilla).
@export_range(0.1, 8.0, 0.05, "suffix:1/s") var side_drag: float = 2.6
## Cuánto frena el giro.
@export_range(0.1, 8.0, 0.05, "suffix:1/s") var turn_drag: float = 2.0
## Velocidad máxima del bote.
@export_range(1.0, 12.0, 0.1, "suffix:m/s") var max_speed: float = 5.5
## Giro máximo.
@export_range(10.0, 180.0, 1.0, "suffix:°/s") var max_turn_rate: float = 60.0
## El giro rinde menos si el bote está casi parado (0 = igual de parado, 1 = no gira sin velocidad).
@export_range(0.0, 1.0, 0.01) var turn_needs_speed: float = 0.35
## Empujón del viento sobre el bote cuando la tormenta está al máximo.
@export_range(0.0, 3.0, 0.01, "suffix:m/s²") var wind_push: float = 0.4

@export_group("Choques")
## Radio del bote para chocar con rocas y troncos.
@export_range(0.3, 3.0, 0.05, "suffix:m") var boat_radius: float = 1.0
## Cuánto de la velocidad se pierde en un choque (0 = nada, 1 = frena del todo).
@export_range(0.0, 1.0, 0.01) var bump_speed_loss: float = 0.65
## Rebote: velocidad con la que el choque aleja al bote del obstáculo.
@export_range(0.0, 6.0, 0.05, "suffix:m/s") var bump_push: float = 1.8
## Tiempo mínimo entre dos avisos de choque (el golpe físico sí se aplica siempre).
@export_range(0.0, 3.0, 0.05, "suffix:s") var bump_cooldown: float = 0.7
## Cuánto sacude la cámara un choque fuerte.
@export_range(0.0, 1.0, 0.01) var bump_shake: float = 0.5
## Cuánto tarda en calmarse esa sacudida.
@export_range(0.1, 3.0, 0.05, "suffix:s") var shake_decay: float = 0.8

@export_group("Oleaje")
## Cuánto sigue el bote la altura de las olas (0 = flota quieto, 1 = las sigue del todo).
@export_range(0.0, 1.5, 0.01) var bob_amount: float = 1.0
## Cuánto se inclina de costado con las olas.
@export_range(0.0, 2.0, 0.01) var roll_amount: float = 0.9
## Cuánto cabecea (proa arriba/abajo) con las olas.
@export_range(0.0, 2.0, 0.01) var pitch_amount: float = 0.8
## Inclinación máxima por las olas (para que no maree).
@export_range(0.0, 40.0, 0.5, "suffix:°") var max_tilt: float = 13.0
## Cuánto de rápido sigue la inclinación a las olas (más alto = más seco).
@export_range(0.5, 20.0, 0.1, "suffix:1/s") var tilt_follow: float = 5.0
## Cuánto se hunde el casco bajo el agua.
@export_range(-0.5, 0.5, 0.01, "suffix:m") var draft: float = -0.05

@export_group("Orilla blanda (para no perderse)")
## Hasta qué distancia del camino el lago es libre.
@export_range(5.0, 80.0, 0.5, "suffix:m") var soft_corridor: float = 24.0
## Desde acá la corriente lo empuja de vuelta al camino.
@export_range(0.0, 8.0, 0.05, "suffix:m/s²") var bounds_push: float = 1.6
## Distancia máxima al camino: más allá no se puede ir.
@export_range(10.0, 150.0, 1.0, "suffix:m") var hard_corridor: float = 48.0

@export_group("Remos (animación)")
## Duración de una remada completa.
@export_range(0.2, 1.5, 0.01, "suffix:s") var stroke_time: float = 0.52
## Cuánto abre el remo hacia adelante y hacia atrás.
@export_range(10.0, 80.0, 1.0, "suffix:°") var oar_sweep: float = 38.0
## Inclinación del remo con la pala dentro del agua (negativo = pala abajo).
@export_range(-45.0, 0.0, 0.5, "suffix:°") var oar_dip: float = -19.0
## Inclinación del remo con la pala en el aire.
@export_range(0.0, 45.0, 0.5, "suffix:°") var oar_lift: float = 11.0
