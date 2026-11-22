class_name RapidsSettings
extends Resource
## Cómo se ven los rápidos del río: la espuma que corre sobre el agua, las nubes blancas de agua
## pulverizada que flotan encima y las salpicaduras. Lo usa RiverBuilder (los rápidos los marca
## RiverFlow.rapids: desde dónde, hasta dónde y qué tan fuerte corre el agua).

@export_group("Espuma sobre el agua")
## Cuánta espuma blanca hay en los rápidos (0 = nada).
@export_range(0.0, 1.0, 0.01) var foam_strength: float = 0.9
## Qué parte del agua de los rápidos queda cubierta de espuma (más alto = más blanco).
@export_range(0.0, 1.0, 0.01) var foam_coverage: float = 0.55
## Tamaño de las manchas de espuma (más alto = manchas más chicas).
@export_range(0.05, 3.0, 0.01) var foam_scale: float = 0.45
## Cuánto se estiran las vetas de espuma a lo largo de la corriente.
@export_range(1.0, 8.0, 0.1) var foam_stretch: float = 3.2
## Velocidad con la que corre la espuma, en proporción a la corriente del rápido.
@export_range(0.0, 3.0, 0.05) var foam_flow: float = 1.0
## Agua revuelta: cuánto se pican las olitas en los rápidos (cambia los reflejos).
@export_range(0.0, 2.0, 0.01) var turbulence: float = 0.6
## Brillo propio de la espuma, para que se vea un poco en la oscuridad (0 = solo con luz).
@export_range(0.0, 1.0, 0.005) var foam_glow: float = 0.18
## Ancho del borde suave de la zona de espuma, hacia las orillas y en el principio y el final del rápido.
@export_range(0.5, 20.0, 0.5, "suffix:m") var edge_fade: float = 4.0
## Tamaño de cada punto del mapa de rápidos (más chico = bordes más prolijos, más memoria).
@export_range(0.1, 2.0, 0.05, "suffix:m") var mask_texel: float = 0.4

@export_group("Nubes de agua pulverizada")
## Nubes por cada 10 m de rápido.
@export_range(0.0, 40.0, 0.5) var mist_per_10m: float = 9.0
## Tamaño de cada nube al nacer y al desaparecer.
@export_range(0.5, 15.0, 0.1, "suffix:m") var mist_size_start: float = 2.2
@export_range(0.5, 20.0, 0.1, "suffix:m") var mist_size_end: float = 4.8
## Opacidad máxima de cada nube (se suman entre ellas).
@export_range(0.0, 1.0, 0.01) var mist_opacity: float = 0.2
## Cuánto dura cada nube.
@export_range(0.5, 15.0, 0.1, "suffix:s") var mist_lifetime: float = 4.5
## Velocidad con la que sube y altura a la que nace sobre el agua.
@export_range(0.0, 3.0, 0.05, "suffix:m/s") var mist_rise: float = 0.3
@export_range(-1.0, 3.0, 0.05, "suffix:m") var mist_height: float = 0.35
@export var mist_color: Color = Color(0.86, 0.9, 0.94)
## Brillo propio de las nubes y las gotas, para que se vean de noche (0 = solo con luz).
@export_range(0.0, 2.0, 0.01) var mist_glow: float = 0.35

@export_group("Salpicaduras")
## Gotas por cada 10 m de rápido.
@export_range(0.0, 200.0, 1.0) var spray_per_10m: float = 45.0
## Tamaño de cada gota.
@export_range(0.01, 0.5, 0.005, "suffix:m") var spray_size: float = 0.07
## Velocidad con la que saltan.
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var spray_speed: float = 2.8
@export_range(0.1, 3.0, 0.05, "suffix:s") var spray_lifetime: float = 0.8
@export_range(0.0, 1.0, 0.01) var spray_opacity: float = 0.65
