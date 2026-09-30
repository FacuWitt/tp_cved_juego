# Cable a Tierra

Prototipo de videojuego en primera persona hecho en **Godot 4** para la materia *Creatividad y Desarrollo de Entornos Virtuales* (UTN FRC).

El protagonista está en coma después de un accidente en el mar. El juego es el viaje interno hacia el despertar: recorre recuerdos de su vida, cada vez más deformados, hasta llegar al momento del trauma (el ahogo) y alcanzar un "cable a tierra" que lo hace despertar.

Estética objetivo: *"PS1 con esteroides"* — low-poly y texturas crudas combinadas con iluminación y post-procesado modernos.

> El diseño narrativo y la arquitectura todavía se están definiendo. Este README cubre cómo levantar el proyecto y cómo trabajamos como equipo, no el diseño del juego.

## Requisitos

- **Godot Engine 4.7.x**, versión estándar (no la build .NET/C#). Se descarga desde [godotengine.org/download](https://godotengine.org/download).
- Windows, Mac o Linux (el proyecto no usa nada específico de plataforma).
- Git. Opcionalmente [GitHub Desktop](https://desktop.github.com/) si no manejan la terminal.

No hace falta instalar nada más: no usamos .NET, ni assets con licencias que requieran activación.

## Cómo levantar el proyecto

1. Cloná el repo:
   ```
   git clone https://github.com/FacuWitt/tp_cved_juego.git
   ```
2. Abrí **Godot 4.7**, entrá al *Project Manager* y click en **Importar** → seleccioná la carpeta clonada → abrí el proyecto.
3. La primera vez que abre, Godot importa todos los assets (puede tardar un rato y quedan archivos `.import` — es normal, se versionan).
4. Con el proyecto abierto, **F5** lo corre. La escena principal actual es un sandbox de prueba (terreno con plataformas), no el juego final.

Si Godot pregunta por una escena principal o tira un error de escena faltante, revisá que estés parado en la rama `main` y que hiciste `git pull`.

### Controles actuales (sandbox de prueba)

| Acción | Tecla |
|---|---|
| Moverse | `W A S D` o flechas |
| Correr | `Shift` |
| Saltar | `Espacio` (mantenido = salto más alto) |
| Interactuar | `E` (todavía sin efecto) |
| Soltar el mouse | `Esc` |
| Capturar el mouse de nuevo | Clic izquierdo |

Los controles se definen en **Proyecto → Configuración del Proyecto → Mapa de Entrada**, nunca como tecla fija dentro de un script.

## Estructura del proyecto

```
assets/
  shaders/        shaders (por ahora, material de grilla provisorio)
config/           Resources .tres con los valores de "feel" (velocidad, FOV, sensibilidad...)
scenes/
  player/         escena del jugador en primera persona
  sandbox/        escena de prueba para probar movimiento y plataformas
scripts/
  config/         definición de los Resources de config (PlayerSettings, etc.)
  player/         lógica del jugador
  world/          lógica de elementos del nivel (KillZone, etc.)
```

Esta estructura va a crecer (`ui/`, más carpetas en `assets/`, escenas de niveles) a medida que se defina la arquitectura final. Se va a documentar en `docs/` cuando esté cerrada.

## Cómo trabajamos (git)

- **`main`** siempre tiene que quedar jugable. Evitá pushear directo ahí si el cambio es grande o experimental: usá una rama y avisá en el grupo antes de mergear.
- **Ramas de trabajo:**
  - `feature/<algo>` para cambios de una persona del equipo (ej. `feature/puzzle-recuerdo-1`).
  - `claude/<algo>` para lo que arma Claude Code en una sesión.
- **Commits chicos**, con el formato `tipo(ámbito): descripción` en español. Ejemplos:
  - `feat(player): agrega salto variable`
  - `fix(sandbox): corrige colisión de la rampa`
  - `chore(assets): limpia texturas sin usar`
- **Nunca hacer `push --force`** sobre una rama que ya bajó otra persona, y nunca borrar una rama que no es tuya.
- **Antes de commitear una escena `.tscn`**, avisá si otra persona la está tocando en simultáneo. Los archivos de escena son binarios en la práctica (aunque se vean como texto): dos personas editando el mismo `.tscn` al mismo tiempo casi siempre termina en conflicto irresoluble. Cuando definamos las escenas grandes del juego, vamos a asignar un dueño por escena.
- **No edites `.godot/`** (carpeta de caché del editor, ya está en `.gitignore`) ni el contenido de `addons/` de terceros a mano.

## Reglas de código (resumen)

- Godot 4 con **tipado estático obligatorio** (`var x: float`, `func foo() -> void`).
- `class_name` en las clases reutilizables (`Player`, `PlayerSettings`, etc.).
- Archivos y carpetas en `snake_case`. Identificadores en inglés, comentarios en español.
- **Cero valores de "feel" hardcodeados** en scripts: todo lo que sea sensación de juego (velocidad, sensibilidad, FOV, tiempos, volúmenes) va en un `Resource` propio dentro de `config/`, editable desde el Inspector.
- Señales en pasado (`memory_completed`, no `complete_memory`).

Estas reglas se van a expandir en un `CLAUDE.md` y en `docs/` cuando cerremos la arquitectura definitiva; por ahora este README es la referencia.

## Estado actual

Hay un sandbox de prueba (terreno, plataformas y jugador en primera persona) para validar que el movimiento y el salto se sienten bien. Todavía **no hay** menú, niveles reales, ni sistema de guardado de progreso — eso es lo próximo que se va a diseñar y documentar antes de programarlo.
