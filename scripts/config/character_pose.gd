class_name CharacterPose
extends Resource
## Pose y movimiento de un personaje que tiene esqueleto pero no trae animaciones (como los
## modelos PS1 de Sketchfab). Lo usa `CharacterRig`.
##
## Todos los giros son en grados y alrededor de los ejes DEL PERSONAJE, no del hueso:
##   X = hacia su derecha (positivo: lo que cuelga, como brazos y piernas, va hacia adelante;
##       lo que apunta arriba, como la espalda, se inclina hacia atrás y la cabeza mira arriba),
##   Y = hacia arriba (positivo = gira hacia su izquierda),
##   Z = hacia atrás (positivo = se inclina hacia su izquierda).
## El personaje mira hacia -Z. Cada giro se suma al reposo del modelo y arrastra a los hijos
## (girar el muslo mueve la pierna entera).
##
## Huesos del hombre (male_character): pelvis_01, spine_02, chest_03, neck_04, head_05,
## shoulder_left_06, upper_arm_left_07, forearm_left_08, hand_left_09,
## shoulder_right_013, upper_arm_right_014, forearm_right_015, hand_right_016,
## thigh_left_020, shin.L_021, foot_left_022, thigh_right_023, shin.R_024, foot_right_025.

@export_group("Pose base")
## La postura quieta (sentado, parado al timón...). Hueso → giro en grados.
@export var bones: Dictionary[StringName, Vector3] = {}

@export_group("Respiración")
## Cuánto se mueve el pecho al respirar.
@export_range(0.0, 10.0, 0.1, "suffix:°") var breath_angle: float = 1.5
## Respiraciones por segundo.
@export_range(0.05, 2.0, 0.01, "suffix:Hz") var breath_rate: float = 0.25

@export_group("Ciclo (remar)")
## Giro extra en un extremo del ciclo (+1: brazos estirados hacia adelante).
@export var cycle_forward: Dictionary[StringName, Vector3] = {}
## Giro extra en el otro extremo (-1: tira de los remos hacia el cuerpo).
@export var cycle_back: Dictionary[StringName, Vector3] = {}
## Si el ciclo corre solo. Si es false lo maneja otro script (el bote del padre lo
## sincroniza con los remos).
@export var cycle_auto: bool = false
## Ciclos por segundo cuando corre solo.
@export_range(0.05, 3.0, 0.01, "suffix:Hz") var cycle_rate: float = 0.6

@export_group("Hablar / gritar")
## Giro extra mientras su línea está en los subtítulos (por ejemplo, levantar un brazo).
@export var talk_bones: Dictionary[StringName, Vector3] = {}
## Giro que oscila mientras habla (agitar el brazo, mover la cabeza).
@export var talk_shake: Dictionary[StringName, Vector3] = {}
## Oscilaciones por segundo al hablar.
@export_range(0.1, 6.0, 0.05, "suffix:Hz") var talk_shake_rate: float = 2.2
## Cuánto tarda en empezar y dejar el gesto.
@export_range(0.05, 2.0, 0.01, "suffix:s") var talk_blend_time: float = 0.35

@export_group("Mirar")
## Hasta cuánto gira la cabeza hacia los costados para mirar a su objetivo.
@export_range(0.0, 120.0, 1.0, "suffix:°") var look_max_yaw: float = 70.0
## Hasta cuánto sube o baja la mirada.
@export_range(0.0, 60.0, 1.0, "suffix:°") var look_max_pitch: float = 25.0
## Qué tan rápido gira la cabeza.
@export_range(0.5, 20.0, 0.5, "suffix:1/s") var look_speed: float = 3.0
## Parte del giro que hace el cuello (el resto lo hace la cabeza).
@export_range(0.0, 1.0, 0.05) var look_neck_share: float = 0.4
## Hueso del cuello y de la cabeza.
@export var neck_bone: StringName = &"neck_04"
@export var head_bone: StringName = &"head_05"
## Hueso del pecho (respira).
@export var chest_bone: StringName = &"chest_03"
