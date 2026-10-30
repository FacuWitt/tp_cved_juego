# Arquitectura: flujo entre memorias

Este documento explica cómo el juego pasa de una memoria a la siguiente. Las mecánicas de cada memoria todavía no están implementadas: cada una es una sala provisoria con una salida.

## Piezas

| Pieza | Archivo | Qué hace |
|---|---|---|
| `GameFlow` (autoload) | `scripts/core/game_flow.gd` | Sabe en qué memoria estamos. Cuando la memoria actual avisa que terminó, hace el fundido y carga la siguiente. También reinicia la memoria actual. |
| `ScreenFade` (autoload) | `scenes/ui/screen_fade.tscn` + `scripts/core/screen_fade.gd` | Fundido a negro de pantalla completa (`fade_out` / `fade_in`). |
| `Memory` | `scripts/memories/memory.gd` | Clase base de la raíz de cada escena de memoria. Se registra en `GameFlow` al cargarse. Tiene `complete()` y `fail()`. |
| `MemoryExit` | `scripts/world/memory_exit.gd` | Area3D que, cuando entra el jugador (y `enabled` es true), emite `reached` y llama a `complete()` de la `Memory` que la contiene. En la memoria 1 arranca deshabilitada y la habilita el puzzle. |
| `MemorySequence` | `scripts/config/memory_sequence.gd` → `config/memory_sequence.tres` | Lista ordenada de escenas del juego. |
| `FlowSettings` | `scripts/config/flow_settings.gd` → `config/flow_settings.tres` | Duración de los fundidos. |

## Cómo se pasa de una memoria a otra

1. Se carga la escena de una memoria. Su raíz (un `Memory`) llama a `GameFlow.register_memory(self)`.
2. `GameFlow` busca esa escena en `memory_sequence.tres` para saber su posición y escucha su señal `memory_completed`.
3. Cuando la mecánica se resuelve, algo de la escena llama a `complete()` en la memoria. Hoy lo hace `MemoryExit`; después puede ser un puzzle resuelto o la última tarea de M4.
4. La memoria emite `memory_completed`, y `GameFlow` funde a negro, espera un momento, carga la escena siguiente de la lista y funde desde negro.
5. Si el jugador falla, se llama a `fail()` en la memoria y `GameFlow` la recarga desde cero, con un fundido corto.

Para encontrar su memoria desde cualquier nodo de la escena, sin rutas fijas: `Memory.find_for(self)`.

Señales útiles de `GameFlow`: `memory_started(index)`, `memory_finished(index)`, `game_finished`, `transition_started`, `transition_finished`.

## Escenas actuales

`scenes/memories/m1_habitacion/m1_habitacion.tscn` es la memoria 1 real en greybox (la habitación de la abuela con el puzzle de la canción de cuna; su raíz es `Memory1Room`, que hereda de `Memory`). `m2_lago/m2_lago.tscn` es la memoria 2 en greybox (el lago helado; raíz `Memory2Lake`). `memory_4.tscn` es la memoria 4 (el barco; raíz `Memory4Accident`). `memory_3.tscn` sigue siendo una sala provisoria; `memory_2.tscn` quedó sin uso. Las salas provisorias son: piso, jugador, un cartel con el nombre de la memoria y una caja "SALIDA". `awakening.tscn` es el final: cámara fija, el texto "FIN" y el mouse liberado.

**Pasajes entre memorias** (`scenes/passages/`): entre una memoria y la siguiente el jugador camina sobre un mar quieto y negro hacia una luz lejana, mientras escucha voces del hospital. Para `GameFlow` un pasaje es una escena más de la secuencia (su raíz, `Passage`, hereda de `Memory` y se completa al llegar a la luz), así las memorias siguen sin conocerse entre sí. `passage.tscn` es la escena base; cada pasaje es una escena heredada que solo cambia su `PassageSettings` (voces, distancia, luces). Hoy existe `pasaje_m1_m2.tscn`, entre la memoria 1 y la 2.

F5 arranca desde la memoria 1. El sandbox sigue en `scenes/sandbox/` y se puede abrir y correr con F6.

## Atajos de debug

Solo funcionan en builds de debug, por ejemplo al correr desde el editor:

| Tecla | Acción (Mapa de Entrada) |
|---|---|
| F9 | `debug_next_memory`: pasa a la memoria siguiente |
| F10 | `debug_restart_memory`: reinicia la memoria actual |

Además, cada memoria tiene un nodo `DebugTools` (teclas fijas, solo para desarrollo y para mostrar el juego en clase; se apagan con `debug_keys` en la raíz de cada memoria antes de llegar a `main`):

| Tecla | Acción |
|---|---|
| 8 | Cámara libre: WASD hacia donde se mira, Espacio sube, Shift baja, Ctrl acelera |
| 9 | Luz de rayo fija (si la escena tiene rayos) |
| 0 | Saltar el evento principal (M2: ir al perro y disparar el final; M4: cortar todas las sogas) |
| 7 | Disparar un flashback (M2) |

## Cómo agregar o reordenar una memoria

1. Crear la escena en `scenes/memories/`. Su nodo raíz tiene que usar el script `memory.gd`, o uno que herede de `Memory`. Si ese script redefine `_ready()`, tiene que llamar a `super()` primero.
2. Abrir `config/memory_sequence.tres` en el Inspector y agregar la escena a la lista **Scene Paths**, en el lugar que corresponda. Para reordenar las memorias, se reordena esa lista.
3. Hacer que algo de la escena llame a `complete()` cuando la memoria se resuelva. La forma más simple es poner un `MemoryExit`.

## Qué se toca desde el Inspector

- `config/flow_settings.tres`: duración del fundido de salida, del tiempo en negro, del fundido de entrada y del fundido de reinicio.
- `config/memory_sequence.tres`: qué escenas forman el juego y en qué orden (memorias y pasajes).
- `config/passage_m1_m2.tres`: el pasaje entre M1 y M2 (voces, largo del camino, luz del final, luces cálidas, mar).
- `MemoryExit.enabled` en cada escena: si la salida está activa o no.
