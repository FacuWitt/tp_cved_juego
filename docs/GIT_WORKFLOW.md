# Cómo trabajamos con git

Guía para las 4 personas del equipo y para Claude Code. Pensada para quien nunca usó git con Godot.

Repo: https://github.com/FacuWitt/tp_cved_juego

## La idea en una línea
**Trabajamos de forma incremental: primero el juego completo con objetos genéricos, después se reemplaza por lo real. `main` siempre se juega de principio a fin.**

## Cómo avanza el proyecto: por etapas
No hay dueños de niveles. Hay **tareas chicas** que toma cualquiera, y el juego crece en capas sobre una base que siempre funciona.

| Etapa | Qué se hace | Cuándo está "lista" |
|---|---|---|
| **0 — Flujo genérico (greybox)** | Todo el juego armado con cubos, cápsulas y planos, sin modelos 3D: menú → M1 → M2 → M3 → M4 → despertar. Incluye las transiciones en negro, los cambios de estado y las **escenas no controlables** (cinemáticas: la caída al agua, el despertar en el hospital). Cada memoria tiene un objetivo mínimo de placeholder (por ejemplo, "tocar el cubo") | Se puede jugar de punta a punta sin trabarse |
| **1 — Mecánicas** | Se reemplaza cada objetivo placeholder por su mecánica real: el puzzle del móvil, las placas de hielo, buscar el barquito, las tareas en cubierta | Cada memoria se resuelve como está diseñada |
| **2 — Sensación** | Iluminación, post-procesado, audio con sus tres capas (recuerdo, amenaza, afuera), voces, distorsiones, shader PS1 | El juego se siente como se describe en los docs |
| **3 — Arte y pulido** | Modelos y texturas reales en lugar de las formas genéricas, detalles de ambientación, ajuste fino | Listo para entregar |

La regla de oro: **nunca se rompe el flujo**. Una tarea de la etapa 1 cambia una memoria por dentro, pero la memoria sigue empezando y terminando igual (misma señal de salida). Si algo no está terminado, se deja el placeholder anterior.

## Ramas
| Rama | Para qué |
|---|---|
| `main` | Siempre jugable de principio a fin. Solo entra por Pull Request. Facu mergea |
| `feature/<tarea>` | Una tarea chica de una persona. Ejemplos: `feature/m1-puzzle-movil`, `feature/transicion-negro`, `feature/cinematica-caida` |
| `claude/<tarea>` | Una tarea que hace Claude Code en una sesión |

Todas las ramas son **cortas**: se abren para una tarea, se mergean y se borran. Lo ideal es que una rama no dure más de unos días. Cuanto más dura, más se separa de `main` y más fácil es que haya conflictos.

## Cómo evitamos pisarnos: reclamar la escena
En Godot, los problemas casi nunca vienen de las ramas. Vienen de **dos personas editando el mismo archivo de escena (`.tscn`) al mismo tiempo**. Como no hay dueños fijos, la regla es:

1. **Antes de empezar una tarea, avisás qué escenas vas a tocar** (en el grupo o en el tablero de tareas). Por ejemplo: "tomo `m1_habitacion.tscn` para el puzzle".
2. **Mientras esté reclamada, nadie más la edita.** Si la necesitás, hablás con quien la tiene.
3. **Al mergear, la liberás.**

Para que esto no sea un cuello de botella, **las escenas se dividen en subescenas**. Por ejemplo, la memoria 1 no es un solo archivo gigante:
```
scenes/memories/m1_habitacion/
  m1_habitacion.tscn        ← la memoria: junta las partes y emite la señal de salida
  room_layout.tscn          ← paredes, piso, puerta
  mobile_puzzle.tscn        ← el puzzle
  props.tscn                ← ambientación
```
Así una persona arma el puzzle y otra la ambientación, al mismo tiempo, sin conflicto.

### Lo que se toca con aviso siempre
- `project.godot`: InputMap, autoloads, ajustes del proyecto.
- `scenes/player/` y los scripts de sistemas (`scripts/player/`, `scripts/interaction/`, `scripts/world/`, los autoloads).
- Los buses de audio.

Esto lo coordina Facu. Si necesitás una acción de input nueva o un cambio en el player, lo pedís.

## Las 6 reglas de Godot + git
1. **Misma versión exacta de Godot para todos: 4.7.x.** Versiones distintas reescriben archivos y generan conflictos falsos.
2. **Reclamá antes de editar una escena.** Ver arriba.
3. **Lo compartido se toca con aviso.** `project.godot`, player, autoloads, buses de audio.
4. **Usá el player sin editarlo.** En las memorias se instancia `scenes/player/player.tscn` (arrastrándolo a la escena). Instanciar no modifica el original.
5. **Mové o renombrá archivos solo desde el panel FileSystem de Godot**, nunca desde el explorador de Windows. Si no, se rompen las referencias (los `.uid`).
6. **Si hay conflicto en un `.tscn`, no se arregla a mano.** Se elige una versión entera (la tuya o la del otro) y se rehacen los cambios encima. Ante la duda, avisale a Facu.

## El día a día
### La primera vez
```bash
git clone https://github.com/FacuWitt/tp_cved_juego.git
cd tp_cved_juego
```

### Empezar una tarea
```bash
git checkout main
git pull                                  # traer lo último
git checkout -b feature/m1-puzzle-movil   # rama nueva para esta tarea
# avisar en el grupo qué escenas vas a tocar
# abrir Godot y trabajar
```

### Mientras trabajás (cada vez que algo funciona, aunque sea chico)
Guardá la escena en Godot (Ctrl+S) y después:
```bash
git status                                # ¿cambió algo que no tocaste a propósito?
git add .
git commit -m "feat(m1): figuras del móvil encastran en su lugar"
git push -u origin feature/m1-puzzle-movil   # el -u solo la primera vez
```
Si `git status` muestra archivos que no tocaste a propósito (típico: `project.godot`), **no los commitees**. Descartalos con `git restore <archivo>` o preguntá.

Si la tarea dura más de un día, traé lo nuevo de `main` cada mañana:
```bash
git pull origin main
```

### Terminar la tarea
1. Antes de abrir el PR, **jugá el juego completo** (F5 desde el menú) y verificá que el flujo no se rompió.
2. En GitHub: **Pull requests → New pull request**, de tu rama hacia `main`.
3. Título claro y una línea diciendo qué se puede probar.
4. Facu lo revisa, lo prueba y lo mergea.
5. Borrás la rama y liberás las escenas que habías reclamado.

## Formato de commits
`tipo(ámbito): descripción`, en español y en presente.

| Tipo | Cuándo |
|---|---|
| `feat` | Algo nuevo que se ve o se juega |
| `fix` | Arreglo de un error |
| `art` | Assets: modelos, texturas, sonidos |
| `tune` | Ajuste de valores de feel en `config/` |
| `refactor` | Reorganizar código sin cambiar el comportamiento |
| `docs` | Documentación |
| `chore` | Mantenimiento: limpieza, configuración |

Ámbitos: `m1`, `m2`, `m3`, `m4`, `flujo`, `cinematica`, `player`, `audio`, `ui`, etc.
Ejemplos: `feat(flujo): transición en negro entre M1 y M2`, `feat(cinematica): caída al agua sin control del jugador`, `tune(player): baja la velocidad al caminar`.

## Integración semanal
**Una vez por semana (día a definir ❓)**, se juega el juego completo de punta a punta todos juntos y se decide qué placeholders se reemplazan en la semana siguiente.

## Assets pesados
- GitHub **rechaza archivos de más de 100 MB** y avisa desde los 50 MB.
- Estilo PS1: texturas chicas (256 px o menos) y modelos low-poly. No debería haber archivos grandes.
- Audio en `.ogg`, no en `.wav` (pesa mucho menos).
- Git LFS no está activado. Si algún archivo supera los 50 MB, avisen antes de commitearlo.

## Qué NO hacer
- `git push --force` → nunca.
- Commitear directo en `main` → nunca.
- Borrar la rama de otro → nunca.
- Editar una escena reclamada por otro → no.
- Mergear algo que rompe el flujo de principio a fin → no.
- Editar algo dentro de `.godot/` → no hace falta, está ignorada.
- Resolver un conflicto de `.tscn` editando el texto a mano → no.
- Abrir el proyecto con otra versión de Godot "para probar" → no.

## Si algo sale mal
| Situación | Qué hacer |
|---|---|
| `git pull` dice que hay conflicto | No toques nada más. Si es en una escena que reclamaste vos, elegí tu versión; si es en algo compartido, avisale a Facu |
| Quiero deshacer cambios que no commiteé | `git restore <archivo>` (o `git restore .` para todo). **Se pierden.** |
| Commiteé algo que no debía y todavía no pushée | `git reset --soft HEAD~1` (deshace el commit pero te deja los cambios) |
| Godot muestra "dependencias rotas" al abrir | Casi siempre es un archivo movido fuera de Godot. Avisá qué archivo y quién lo movió |
| No sé en qué rama estoy | `git branch` (la que tiene `*`) |

## Para Claude Code
- Trabaja en `claude/<tarea>`, una rama por tarea, y respeta las escenas reclamadas por otros.
- Antes de cambiar de rama, verifica `git status`. Si hay cambios sin commitear que no son suyos, frena y pregunta.
- Nunca mergea a `main`. Deja la rama pusheada o abre el Pull Request, y Facu mergea.
- Respeta la etapa actual: en la etapa 0 no agrega modelos, arte ni efectos, solo flujo con formas genéricas.
