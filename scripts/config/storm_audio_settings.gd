class_name StormAudioSettings
extends Resource
## Los sonidos de ambiente de una memoria con tormenta: lluvia, viento, agua, música y truenos.
## Lo usa StormAudio. Los volúmenes están en dB (0 = tal cual el archivo, negativo = más bajo).

@export_group("Sonidos")
@export var rain: AudioStream
@export var wind: AudioStream
@export var water_lap: AudioStream
@export var pad_calm: AudioStream
@export var pad_storm: AudioStream
@export var underwater: AudioStream
## Truenos de cerca (con chasquido), de media distancia y lejanos.
@export var thunder_near: AudioStream
@export var thunder_mid: AudioStream
@export var thunder_far: AudioStream

@export_group("Volumen según la tormenta")
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var rain_calm_db: float = -42.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var rain_storm_db: float = -7.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var wind_calm_db: float = -32.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var wind_storm_db: float = -9.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var lap_calm_db: float = -10.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var lap_storm_db: float = -24.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var pad_calm_calm_db: float = -15.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var pad_calm_storm_db: float = -40.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var pad_storm_calm_db: float = -60.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var pad_storm_storm_db: float = -12.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var underwater_db: float = -6.0
@export_range(-80.0, 6.0, 0.5, "suffix:dB") var thunder_db: float = -4.0

@export_group("Truenos")
## Cuánto tarda el trueno en llegar después del rayo (mínimo y máximo).
@export_range(0.0, 8.0, 0.05, "suffix:s") var thunder_delay_min: float = 0.4
@export_range(0.0, 12.0, 0.05, "suffix:s") var thunder_delay_max: float = 3.8
## Con menos demora que esto el trueno es el de cerca (con chasquido).
@export_range(0.0, 8.0, 0.05, "suffix:s") var thunder_near_below: float = 1.0
## Con más demora que esto es el lejano.
@export_range(0.0, 12.0, 0.05, "suffix:s") var thunder_far_above: float = 2.4
## Cuánto tardan los volúmenes en seguir los cambios (más alto = más lento).
@export_range(0.05, 5.0, 0.05, "suffix:s") var fade_time: float = 1.2
