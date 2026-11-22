class_name FatherBoatSettings
extends Resource
## Cómo rema el padre: a qué velocidad avanza, cuándo espera y cuándo acelera para no perderlo.
## Lo usa RemosFatherBoat.

## Cuánto adelante del hijo arranca el padre, para que no se superpongan los botes.
@export_range(0.0, 40.0, 0.5, "suffix:m") var start_ahead: float = 14.0
## Velocidad del padre con el lago en calma.
@export_range(0.5, 8.0, 0.05, "suffix:m/s") var calm_speed: float = 3.1
## Velocidad con la tormenta al máximo.
@export_range(0.5, 8.0, 0.05, "suffix:m/s") var storm_speed: float = 3.6
## Distancia por delante del hijo a la que se queda cómodo.
@export_range(2.0, 60.0, 0.5, "suffix:m") var comfort_gap: float = 17.0
## Si el hijo queda más atrás que esto, el padre empieza a frenar para esperarlo.
@export_range(5.0, 100.0, 0.5, "suffix:m") var far_gap: float = 30.0
## Si el hijo queda más cerca que esto, el padre acelera un poco (para no chocarlo).
@export_range(2.0, 30.0, 0.5, "suffix:m") var near_gap: float = 9.0
## Cuánto acelera cuando el hijo está muy cerca (1 = nada).
@export_range(1.0, 2.0, 0.01) var catch_up_factor: float = 1.18
## Velocidad mínima cuando espera.
@export_range(0.0, 3.0, 0.05, "suffix:m/s") var wait_speed: float = 0.4
## Qué tan rápido cambia de velocidad.
@export_range(0.2, 6.0, 0.05, "suffix:m/s²") var acceleration: float = 1.2
## Cuánto zigzaguea el bote del padre alrededor del camino.
@export_range(0.0, 5.0, 0.05, "suffix:m") var sway: float = 1.3
## Tiempo entre una remada y la siguiente del padre. Es el pulso que se parece al bip del juego.
@export_range(0.3, 3.0, 0.01, "suffix:s") var stroke_interval: float = 1.0
## Cuánto sigue el bote del padre a las olas.
@export_range(0.0, 1.5, 0.01) var wave_follow: float = 0.9
## Energía de la luz de su farol.
@export_range(0.0, 10.0, 0.05) var lantern_energy: float = 2.6
## Alcance de la luz de su farol.
@export_range(2.0, 80.0, 0.5, "suffix:m") var lantern_range: float = 22.0
## Tamaño en pantalla del resplandor del farol (se ve de lejos aunque haya niebla).
@export_range(0.005, 0.2, 0.001) var glow_size: float = 0.05
