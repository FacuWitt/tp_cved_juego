# CLAUDE.md — Cable a Tierra

Guía que Claude Code lee al inicio de cada sesión. Es corta a propósito: el detalle vive en `docs/`.

## El juego en 5 líneas
- Prototipo en primera persona hecho en Godot, para la materia Creatividad y Desarrollo de Entornos Virtuales (UTN FRC).
- Un pescador cae al mar desde el pesquero en el que trabaja, se ahoga y queda en coma.
- Para despertar, **rearma 4 recuerdos de su vida**: infancia, adolescencia, adultez y el accidente. Cada recuerdo anticipa el accidente de forma sutil.
- El hilo conductor es un **barquito de madera** que pasa de mano en mano. Al final, en el hospital, su hija se lo devuelve.
- Estética "PS1 con esteroides": low-poly y texturas crudas, con iluminación y post-procesado modernos.

## Roles
- **Claude Code:** implementa la lógica del juego en el motor (scripts, señales, estados, transiciones, audio, UI, shaders) y mantiene actualizados `docs/` y este archivo.
- **El equipo (4 personas):** ajusta las sensaciones (velocidades, FOV, tiempos, colores, volúmenes), define los controles, integra los assets y prueba jugando. Facu es el integrador: revisa y mergea a `main`.

## Entorno técnico
- **Godot 4.7.x estándar** (no .NET). Renderer **Forward+**. Físicas **Jolt**. En Windows usa D3D12.
- Todo el equipo usa **la misma versión exacta** de Godot.
- Escena principal actual: `res://scenes/memories/m1_habitacion/m1_habitacion.tscn` (memoria 1 en greybox). El sandbox de prueba sigue en `scenes/sandbox/` (F6).
- Autoloads: `GameFlow` (encadena las memorias) y `ScreenFade` (fundido a negro). Falta `EventBus`, `AudioManager`, etc.
- InputMap: `move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `interact`, `release_mouse`, `capture_mouse`, y los de debug `debug_next_memory` (F9) y `debug_restart_memory` (F10).

## Qué existe hoy
| Clase | Archivo | Qué hace |
|---|---|---|
| `Player` | `scripts/player/player.gd` | CharacterBody3D en primera persona: salto variable, coyote time, agarra y suelta `PickupObject` con `interact` |
| `PlayerSettings` | `scripts/config/player_settings.gd` → `config/player_settings.tres` | Valores de feel del jugador |
| `PickupObject` | `scripts/interaction/pickup_object.gd` | RigidBody3D que se agarra y se arrastra con física; se puede bloquear (`lock()`) |
| `PickupSettings` | `scripts/config/pickup_settings.gd` → `config/pickup_settings.tres` | Valores de feel del agarre |
| `PlacementSlot` | `scripts/world/placement_slot.gd` | Area3D donde un `PickupObject` encastra. Emite `object_placed` y `object_removed` |
| `KillZone` | `scripts/world/kill_zone.gd` | Devuelve al jugador a un punto de reaparición |
| `Memory` | `scripts/memories/memory.gd` | Clase base de la raíz de cada memoria: se registra en `GameFlow`; `complete()` y `fail()` |
| `MemoryExit` | `scripts/world/memory_exit.gd` | Salida de una memoria: emite `reached` y completa la `Memory` que la contiene (`enabled` la abre o cierra) |
| `Memory1Room` | `scripts/memories/memory_1_room.gd` | Memoria 1 (habitación de la abuela): une el puzzle con la puerta, el barquito y la salida |
| `SequencePuzzle` | `scripts/puzzles/sequence_puzzle.gd` | Puzzle genérico de ordenar piezas (`PuzzlePiece`) en casilleros |
| `InteractionPrompt` | `scripts/ui/interaction_prompt.gd` | Mira contextual: "(E) Agarrar" / "(E) Colocar" |

Capas de colisión: **1 = cuerpos físicos** (el InteractionRay mira esta), **2 = zonas de detección** (los `PlacementSlot`).

## Reglas de código
- Godot 4 con **tipado estático obligatorio** (`var x: float`, `func f() -> void`).
- `class_name` en las clases reutilizables.
- Archivos y carpetas en `snake_case`. Identificadores en inglés, comentarios y docstrings (`##`) en español.
- Señales en pasado: `puzzle_solved`, `memory_completed`.
- Un script por nodo. Composición antes que herencia profunda.
- `@onready` para referencias a nodos hijos. `assert()` con mensaje claro si falta un recurso obligatorio en el Inspector.

## Regla de tuning (no negociable)
- **Cero valores de "feel" hardcodeados.** Todo lo ajustable va con `@export_range` (con sufijo de unidad y un comentario `##` que explique el efecto) dentro de un `Resource` propio en `scripts/config/`, con su `.tres` en `config/`.
- **Nunca teclas fijas en el código:** siempre acciones del InputMap. Si hace falta una acción nueva, se agrega y se avisa, porque toca `project.godot`.

## Arquitectura objetivo (resumen)
El detalle va a vivir en `docs/ARQUITECTURA.md`.
- **Autoloads previstos:**
  - `EventBus`: solo señales globales.
  - `GameManager`: máquina de estados `MENU → M1 → M2 → M3 → M4 → WAKE_UP`.
  - `AudioManager`: buses `Recuerdo`, `Amenaza` y `Afuera`.
  - `TransitionLayer`: negros con las voces del hospital.
- **Las memorias no se conocen entre sí.** Cada una emite `memory_completed` al EventBus y el GameManager decide qué sigue.
- Cada memoria es una escena propia en `scenes/memories/mN_nombre/`, dividida en subescenas (layout, puzzle, props), que instancia `player.tscn` sin modificarlo.
- Hay **escenas no controlables** (cinemáticas: la caída al agua, el despertar). El player tiene que poder quedar sin control (bloquear input y cámara) mientras una cinemática mueve la cámara.

## Desarrollo incremental (detalle en `docs/GIT_WORKFLOW.md`)
1. **Etapa 0 — Flujo genérico:** todo el juego de punta a punta con formas genéricas, sin modelos 3D. Objetivos placeholder, transiciones, estados y cinemáticas.
2. **Etapa 1 — Mecánicas reales** de cada memoria.
3. **Etapa 2 — Sensación:** luz, audio, post-procesado, shader PS1.
4. **Etapa 3 — Arte y pulido.**

`main` siempre se juega de principio a fin. Una tarea cambia una memoria por dentro sin romper cómo empieza ni cómo termina. No te adelantes de etapa: en la 0, nada de arte ni efectos.

## Git (detalle en `docs/GIT_WORKFLOW.md`)
- Trabajás **siempre** en una rama `claude/<tarea>`, una por tarea, que nace de `develop`. Nunca se commitea directo en `main` ni en `develop`.
- Flujo de integración: `claude/*` y `feature/*` → PR a **`develop`** → cuando `develop` está estable, PR de `develop` a **`main`**. Facu mergea todo.
- **Claude no ejecuta `git commit`, `git push` ni `git merge`**: el equipo commitea a mano. Dejás los cambios en el working tree y avisás qué quedó modificado. Sí podés usar comandos de solo lectura (`git status`, `git diff`, `git log`, `git branch`) para orientarte.
- Formato de commit (lo usa el equipo; sugerilo cuando termines): `tipo(ámbito): descripción` en español. Por ejemplo `feat(player): agrega agacharse`.
- Nunca `push --force`, nunca `reset --hard` sobre trabajo sin commitear, nunca borrar ramas ajenas.
- **No tocar una escena `.tscn` reclamada por otra persona.** Antes de editar una escena, preguntá si alguien la tiene.
- `project.godot`, `player.tscn`, los autoloads y los buses de audio son **compartidos**: se tocan con aviso.
- Antes de cambiar de rama, verificá que no haya cambios sin commitear (`git status`).

## Changelog (obligatorio)
El profesor pidió que todo lo que hagamos quede en el **documento de la solución**. `CHANGELOG.md` es la materia prima de ese documento: registra qué se hizo, **por qué se eligió así** y qué se descartó. Los commits dicen qué cambió; el changelog dice la decisión.

- **Al empezar la sesión:** leé `CHANGELOG.md` (al menos las últimas entradas) para saber qué se decidió y no contradecirlo ni re-discutirlo.
- **Al terminar cada tarea** (antes de dar el trabajo por cerrado): agregá una entrada nueva **arriba de todo**, debajo de `<!-- ENTRADAS -->`, con el siguiente número `CL-NNN` libre. El formato y las reglas están en el propio `CHANGELOG.md`; seguilos.
- **Qué registrar:** mecánicas, arquitectura, flujo de trabajo, diseño narrativo, documentación, bugs importantes y cómo se resolvieron, y decisiones de "no hacer X". Ajustes sueltos de valores de feel o de formato no.
- **El "por qué" es lo más importante:** el problema que había, la solución elegida y las alternativas descartadas. Si el motivo lo dio el equipo, citá lo que pidieron.
- **No inventes motivos.** Si no consta por qué se decidió algo, escribí `motivo no registrado` y preguntá. Lo que reconstruyas del historial de git marcalo *(reconstruido del historial)*.
- **Nunca reescribas ni renumeres entradas viejas.** Si una decisión cambia, agregá una entrada nueva que diga qué cambió y por qué, y referenciá la anterior (`reemplaza CL-NNN`).
- Si la tarea cambió una decisión que figura en otro doc de `docs/`, actualizá también ese doc.
- Cerrá tu resumen al usuario mencionando el número de entrada que escribiste.

## Reglas de trabajo
- **No editar `.godot/`.** Es caché y está ignorada.
- Editar `.tscn` y `.tres` a mano solo para cambios chicos (conectar una señal, cambiar una propiedad). Si la escena es grande o visual, describir los pasos para que el equipo la arme en el editor.
- **Mover o renombrar archivos** mantiene los `.uid`: siempre mover el `.gd` junto con su `.gd.uid`.
- **Validar antes de commitear**: revisar errores de parseo; si hay un ejecutable de Godot disponible, usar `--headless --check-only`.
- **Preguntar antes** de cambiar la arquitectura, el contrato de señales o algo del diseño narrativo.
- **No inventar decisiones de diseño.** Lo no definido se marca `❓ ABIERTO` en el doc correspondiente.
- Cuando cambie una decisión, actualizar el doc y anotarla en `docs/DECISIONES.md`.
- `prueba_script.gd` y `node_3d.tscn` en la raíz son restos de prueba: no usarlos como referencia.

## Tareas temporales
- Hay un bloque **🔧 TAREAS TEMPORALES M1** en `docs/ELEMENTOS_ESCENAS.md` (sección de la Memoria 1) con trabajo decidido y todavía sin implementar. Hacelo cuando toques la M1 y borrá el bloque al terminar.

## Documentos
| Doc | Estado |
|---|---|
| `README.md` | ✅ Cómo levantar el proyecto |
| `CHANGELOG.md` | ✅ **Registro de decisiones y cambios. Insumo del documento de la solución. Obligatorio, ver sección "Changelog"** |
| `docs/GIT_WORKFLOW.md` | ✅ Etapas, ramas, reclamo de escenas, día a día |
| `docs/ELEMENTOS_ESCENAS.md` | ✅ Inventario de elementos por escena (placeholder de etapa 0, rol, sistemas que pide) |
| `docs/GUION_MAESTRO.md` | ⏳ Pendiente: la historia completa y los beats por memoria |
| `docs/SIMBOLOGIA.md` | ⏳ Pendiente: diccionario de símbolos, regla 80/20, capas de audio |
| `docs/arquitectura.md` | ✅ Flujo entre memorias (`GameFlow`, `Memory`, `MemoryExit`, secuencia) |
| `docs/SENALES_Y_ESTADOS.md` | ⏳ Pendiente: contrato del EventBus y del GameManager |
| `docs/TUNING.md` | ⏳ Pendiente: guía de los Resources de `config/` |
| `docs/DECISIONES.md` | ⏳ Pendiente |

Si un doc marcado ⏳ no existe, no lo inventes: preguntá.
