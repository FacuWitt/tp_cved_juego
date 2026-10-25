# Créditos de modelos 3D

Las figuras de la Memoria 1 están armadas con primitivas de Godot en
`scenes/interaction/figures/`, salvo las que usan modelos externos (listados acá).

## Modelos externos reemplazando primitivas

| Archivo | Modelo | Autor | Licencia | Fuente |
|---|---|---|---|---|
| `wave_sculpture.glb` (figura `ola`) | Wave Sculpture | ? | ? | ? |
| `moon_globe.glb` (figura `luna`) | Moon Globe | ? | ? | ? |

> TODO: completar autor, licencia y fuente de cada modelo (descargados de Downloads).
> Si no son CC0, hay que acreditar en los créditos del juego.

Nota: `wave_sculpture.glb` fue procesado para Godot (venía con Draco + WebP,
formatos que el motor no importa): se decodificó, se soldaron vértices por posición,
se decimó de 1,5 M a ~100 mil triángulos y las texturas WebP se pasaron a JPEG a 2048 px.

## Recordatorio de licencias
- **CC0**: uso libre, sin atribución.
- **CC-BY**: se puede usar, pero **hay que acreditar al autor** (en la documentación del TP o
  en los créditos del juego).
- **CC-BY-NC**: no se puede usar si el TP se considera uso comercial.
