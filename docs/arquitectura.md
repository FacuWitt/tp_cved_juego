# Arquitectura: flujo entre memorias

Este documento explica cómo el juego pasa de una memoria a la siguiente. Las mecánicas de cada memoria todavía no están implementadas: cada una es una sala provisoria con una salida.

## Piezas

| Pieza | Archivo | Qué hace |
|---|---|---|
| `GameFlow` (autoload) | `scripts/core/game_flow.gd` | Sabe en qué memoria estamos. Cuando la memoria actual avisa que terminó, hace el fundido y carga la siguiente. También reinicia la memoria actual. |
| `ScreenFade` (autoload) | `scenes/ui/screen_fade.tscn` + `scripts/core/screen_fade.gd` | Fundido a negro de pantalla completa (`fade_out` / `fade_in`). |
| `Memory` | `scripts/memories/memory.gd` | Clase base de la raíz de cada escena de memoria. Se registra en `GameFlow` al cargarse. Tiene `complete()` y `fail()`. |
| `MemoryExit` | `scripts/world/memory_exit.gd` | Area3D que llama a `complete()` cuando entra el jugador. Se puede desactivar con `enabled`. |
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

`scenes/memories/memory_1.tscn` … `memory_4.tscn` son salas provisorias: piso, jugador, un cartel con el nombre de la memoria y una caja "SALIDA". `awakening.tscn` es el final: cámara fija, el texto "FIN" y el mouse liberado.

F5 arranca desde la memoria 1. El sandbox sigue en `scenes/sandbox/` y se puede abrir y correr con F6.

## Atajos de debug

Solo funcionan en builds de debug, por ejemplo al correr desde el editor:

| Tecla | Acción (Mapa de Entrada) |
|---|---|
| F9 | `debug_next_memory`: pasa a la memoria siguiente |
| F10 | `debug_restart_memory`: reinicia la memoria actual |

## Cómo agregar o reordenar una memoria

1. Crear la escena en `scenes/memories/`. Su nodo raíz tiene que usar el script `memory.gd`, o uno que herede de `Memory`. Si ese script redefine `_ready()`, tiene que llamar a `super()` primero.
2. Abrir `config/memory_sequence.tres` en el Inspector y agregar la escena a la lista **Scene Paths**, en el lugar que corresponda. Para reordenar las memorias, se reordena esa lista.
3. Hacer que algo de la escena llame a `complete()` cuando la memoria se resuelva. La forma más simple es poner un `MemoryExit`.

## Qué se toca desde el Inspector

- `config/flow_settings.tres`: duración del fundido de salida, del tiempo en negro, del fundido de entrada y del fundido de reinicio.
- `config/memory_sequence.tres`: qué escenas forman el juego y en qué orden.
- `MemoryExit.enabled` en cada escena: si la salida está activa o no.
