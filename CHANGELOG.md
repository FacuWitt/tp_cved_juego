# CHANGELOG — Cable a Tierra

Registro de **qué se hizo, por qué y qué se descartó**, ordenado de lo más nuevo a lo más viejo.

## Para qué sirve

El profesor pidió que **todo lo que hagamos vaya quedando en el documento de la solución**. Este archivo es la materia prima de ese documento: de acá se copian las decisiones de diseño, los problemas que aparecieron y cómo se resolvieron, sin tener que reconstruirlos de memoria o de `git log` al final de la cursada.

- Un commit dice **qué cambió en el código**. El changelog dice **qué problema se resolvía y por qué se eligió esa solución**.
- Tiene que poder leerse sin abrir el código: alguien que no estuvo en la sesión debe entender la decisión.
- Se escribe en español, en lenguaje claro y sin jerga innecesaria.

## Cómo se escribe una entrada

**Cuándo:** al terminar cada tarea (no al final del día ni de la semana). Toda sesión de Claude Code cierra su trabajo con una entrada nueva. Los humanos también pueden agregar las suyas con el mismo formato.

**Dónde:** arriba de todo, justo debajo de la línea `<!-- ENTRADAS -->`. Se numeran con `CL-NNN` (siguiente número libre, nunca se reutilizan ni se renumeran).

**Qué entra:** cambios de mecánicas, de arquitectura, de flujo de trabajo, de diseño narrativo o de documentación; bugs importantes y cómo se resolvieron; decisiones tomadas (aunque sean "no hacer X").
**Qué no entra:** ajustes de valores de feel sueltos, cambios de formato, renombres menores. Eso queda en el commit.

**Formato:**

```
### CL-NNN · Título corto en presente · AAAA-MM-DD
- **Rama / commits:** `rama` · `abc1234` (si todavía no hay commit: "sin commitear")
- **Pedido por:** quién y con qué palabras, si importa
- **Qué se hizo:** 2 a 5 líneas.
- **Por qué (decisión de diseño):** el problema que había y por qué esta solución.
- **Alternativas descartadas:** qué se consideró y por qué no. ("Ninguna registrada" si no consta.)
- **Problemas encontrados:** bugs o imprevistos y cómo se resolvieron. (Omitir si no hubo.)
- **Archivos y docs:** los principales; qué documento se actualizó.
- **Pendiente / ❓ ABIERTO:** lo que queda sin decidir.
```

**Reglas de honestidad:** no se inventan motivos. Si el motivo de una decisión no quedó registrado, se escribe `motivo no registrado` y se le pregunta al equipo. Lo reconstruido a partir del historial de git va marcado como *(reconstruido del historial)*.

**Para pasarlo al documento de la solución:** cada entrada es un bloque autónomo. Se pueden copiar "Por qué", "Alternativas descartadas" y "Problemas encontrados" casi tal cual.

---

<!-- ENTRADAS -->

### CL-013 · El nene no se va de la habitación sin su barco · 2026-10-08
- **Rama / commits:** `claude/m1-habitacion` · ver `git log`
- **Pedido por:** Facu: "Saca el objeto marea (es difícil hacer un objeto marea), que quede como distractor únicamente el barco... cuando intente sobrepasar la puerta, un mensaje de dialogo del propio protagonista dice, no me puedo ir sin mi juguete favorito, y vuelve a buscar el barco (aquí se fortalece la conexión con el barco)".
- **Qué se hizo:** se quitaron la marea y el pescador del puzzle (quedan 6 objetos: 5 piezas y el barco). Nueva clase `ItemGate`: una barrera física en el umbral de la puerta y una zona de aviso delante. Con la puerta ya abierta, si el jugador intenta salir sin haber agarrado el barco, el protagonista dice la línea y no puede cruzar. Al agarrar el barco la barrera se libera. El barco pasó a la mesa de luz (antes estaba junto a la puerta).
- **Por qué (decisión de diseño):** el barco era un distractor sin consecuencia. Convertirlo en el juguete favorito que el nene no abandona refuerza desde la primera memoria el vínculo con el barquito (el cable a tierra) y le da al jugador una última pequeña tarea después del puzzle. La barrera es física y no solo un cartel para que no se pueda saltear el momento. El texto vive en `memory_1_settings.tres` (`gate_line`), no en el código. El barco se movió lejos de la puerta para que el "volver a buscarlo" sea un recorrido real. Es una decisión mía de ubicación y se puede cambiar.
- **Alternativas descartadas:** pedir que lo lleve en la mano hasta la salida (más rígido; si lo suelta el paso quedaría cerrado de nuevo). Dejar que el aviso se repita sin barrera (el jugador podría ignorarlo y salir).
- **Problemas encontrados:** la prueba automática no corría como script suelto porque `GameFlow` es un autoload y no existe todavía en ese modo; se corrió como escena. Además, al cruzar la salida `GameFlow` cambia de escena y libera la propia prueba, así que el resultado se imprime antes de que eso ocurra.
- **Archivos y docs:** `scripts/world/item_gate.gd` (nuevo), `scripts/memories/memory_1_room.gd`, `scripts/config/memory_1_settings.gd`, `m1_habitacion.tscn`, `puzzle.tscn`, `docs/ELEMENTOS_ESCENAS.md`.
- **Pendiente / ❓ ABIERTO:** el barco todavía no brilla ni se resalta al ser el juguete favorito (idea para la etapa 2). En la etapa 2 la línea pasa a ser audio.

### CL-012 · Decisiones de la memoria 1: hora del accidente, sin pescador y agua bajo la puerta · 2026-10-08
- **Rama / commits:** `claude/m1-decisiones` · ver `git log`
- **Pedido por:** Facu: "digamos que fue a las 3 am", "Saquemos al pescador como objeto", "Si!" (agua visible al equivocarse) y "Por el momento está bien así" (valores de nene).
- **Qué se hizo:** solo documentación. Se cerraron cuatro pendientes de `docs/ELEMENTOS_ESCENAS.md` y se dejó en ese archivo un bloque de tareas temporales (T1 a T4) para implementarlo cuando se vuelva a la M1.
- **Por qué (decisión de diseño):** (1) todos los relojes marcan las 3:00 am, la hora del accidente, para tener una única referencia que repetir. (2) El pescador sale como objeto porque el protagonista ya es el pescador del poema y, como juguete, confundía de más; quedan 7 objetos. (3) El agua bajo la puerta refuerza la capa de amenaza sin castigar: el error se siente, no se pierde nada. (4) Los valores de escala de nene se mantienen. Motivos (2) y (3) en palabras de Facu: motivo detallado no registrado.
- **Alternativas descartadas:** ninguna registrada.
- **Archivos y docs:** `docs/ELEMENTOS_ESCENAS.md`, `CLAUDE.md` (puntero a las tareas), `CHANGELOG.md`.
- **Pendiente / ❓ ABIERTO:** implementar T1 a T3. Si el agua es acumulativa por error y si se seca al resolver es una propuesta sin confirmar.

### CL-011 · La puerta de la memoria 1 dejaba de bloquear solo a la vista, no a la física · 2026-10-08
- **Rama / commits:** `develop` · sin commitear
- **Pedido por:** Facu: "no puedo pasar la puerta una vez que abre" (al probar el paso de la M1 a la M2).
- **Qué se hizo:** se desactivó `sync_to_physics` en el nodo `Door` (un `AnimatableBody3D`) de `room_layout.tscn`.
- **Por qué (decisión de diseño):** la puerta se abre girando su nodo padre (`DoorHinge`), no el cuerpo en sí. Con `sync_to_physics` activado, la colisión se quedaba en la posición cerrada aunque la puerta *se viera* abierta, y una pared invisible bloqueaba el hueco. Sin esa sincronización la colisión acompaña al movimiento del padre. Se prefirió esto a rehacer la animación para mover el cuerpo directamente porque cambia una sola propiedad y conserva el diseño de bisagra.
- **Problemas encontrados:** la prueba automática de CL-009 teletransportaba al jugador a la salida y por eso **no detectó el error**: nadie había recorrido el camino caminando. Ahora la prueba camina con el input real, comprueba que la puerta cerrada bloquea (queda en z=1,70), que la abierta deja pasar y que el flujo llega a la memoria 2. **Lección para próximas pruebas:** recorrer el camino del jugador, no saltarse la física.
- **Alternativas descartadas:** mover el `AnimatableBody3D` directamente en el tween (más cambios y sin ventaja visible).
- **Archivos y docs:** `scenes/memories/m1_habitacion/room_layout.tscn`.
- **Pendiente / ❓ ABIERTO:** ninguno.

### CL-010 · Changelog como registro para el documento de la solución · 2026-10-08
- **Rama / commits:** `develop` · sin commitear
- **Pedido por:** Facu: "el profe dijo que todo lo que hagamos tenemos que ir poniendo en el documento de la solución"; el changelog es "para ese documento más que nada" y debe servir de guía a otras sesiones de Claude.
- **Qué se hizo:** se creó este archivo con el formato de entrada, las reglas de uso y el historial reconstruido (CL-001 a CL-009). `CLAUDE.md` obliga a cada sesión de Claude a leerlo al empezar y a escribir una entrada al cerrar cada tarea.
- **Por qué (decisión de diseño):** los commits registran qué cambió pero no por qué se eligió una solución ni qué se descartó, que es justo lo que pide el documento de la solución. Registrarlo al terminar cada tarea evita reconstruirlo de memoria al final.
- **Alternativas descartadas:** escribir la documentación al final de la cursada (se pierden los motivos); usar solo `docs/DECISIONES.md` (hoy pendiente y pensado para decisiones puntuales, no para el hilo completo del trabajo).
- **Archivos y docs:** `CHANGELOG.md`, `CLAUDE.md`, `docs/GIT_WORKFLOW.md`.

### CL-009 · Memoria 1 conectada al flujo del juego · 2026-10-08
- **Rama / commits:** `develop` · sin commitear
- **Pedido por:** Facu: "armalo en la rama develop", tras el merge de la rama de transiciones con la del puzzle de la memoria 1.
- **Qué se hizo:**
  - `Memory1Room` pasó a heredar de `Memory` (antes era un `Node3D` con su propia señal `memory_completed`) y llama a `super()` en `_ready()`.
  - `MemoryExit` unifica los dos diseños que habían nacido en ramas distintas: emite `reached` y, si está dentro de una `Memory`, la completa. `enabled` arranca en `true`.
  - `config/memory_sequence.tres` y `project.godot` (`run/main_scene`) apuntan a `m1_habitacion/m1_habitacion.tscn`. Se eliminó la sala provisoria `memory_1.tscn`.
  - Flujo de ramas actualizado: `claude/*` y `feature/*` → `develop` → `main`.
- **Por qué (decisión de diseño):** el juego tiene que poder jugarse de punta a punta en todo momento. Si la memoria 1 real no era una `Memory`, `GameFlow` no la registraba y el puzzle resuelto no llevaba a la memoria 2. Hacer que `MemoryExit` emita la señal **y** complete la memoria cubre las dos formas de uso sin romper ninguna: las salidas provisorias de M2–M4 siguen funcionando sin código extra y la puerta de M1 puede reaccionar con el subtítulo.
- **Alternativas descartadas:**
  - Dejar `Memory1Room` como `Node3D` y conectar su señal a mano a `GameFlow`: obligaba a que cada memoria con lógica propia repitiera ese cableado y rompía la regla de que todas las raíces son `Memory`.
  - Que `MemoryExit` solo emitiera la señal (diseño de la rama del puzzle) o solo llamara a `complete()` (diseño de la rama de transiciones): cada una dejaba sin funcionar el caso de la otra.
- **Problemas encontrados:** al hacer el merge, ambas ramas habían creado `scripts/world/memory_exit.gd` con contenidos incompatibles (único conflicto de texto). Se resolvió fusionando los dos comportamientos. Comprobado con una prueba automática: puerta cerrada no hace nada; abierta, completa la memoria y `GameFlow` carga la memoria 2.
- **Archivos y docs:** `scripts/world/memory_exit.gd`, `scripts/memories/memory_1_room.gd`, `config/memory_sequence.tres`, `project.godot`, `docs/arquitectura.md`, `docs/GIT_WORKFLOW.md`, `CLAUDE.md`.
- **Pendiente / ❓ ABIERTO:** `project.godot` es un archivo compartido que se tocó (solo la escena principal). El texto de salida de la M1 y la voz de la mamá siguen siendo provisorios.

### CL-008 · Memoria 1: la habitación de la abuela con el puzzle de la canción de cuna · 2026-10-08
*(reconstruido del historial: commits `dbc910a`, `a52c1af`, `e0d7999`, `25bde6f`, `f463d54`, `e11c083` de la rama `claude/m1-habitacion`)*
- **Qué se hizo:**
  - Habitación en *greybox* dividida en subescenas (`room_layout`, `props`, `puzzle`).
  - Puzzle genérico `SequencePuzzle` con piezas `PuzzlePiece` (un `PickupObject` con identificador). Un papel de la abuela clavado sobre la cama trae el acertijo: ordenar cinco juguetes (luna, red, ola, ancla, faro) en una repisa de cinco casilleros; hay distractores (barco, marea, pescador).
  - Al resolver: voz provisoria (la mamá felicita), el barquito se enciende y se abre la puerta. Al equivocarse: texto provisorio y sacudida de la puerta, **sin castigo**.
  - Perfil de jugador "nene" solo para la M1 (`player_settings_child.tres`): ojos a 1,1 m, camina más lento y salta menos. El player original no cambia.
  - Textos provisorios de voces y sonidos con `SubtitleDisplay`.
- **Por qué (decisión de diseño):** `docs/ELEMENTOS_ESCENAS.md` (memoria 1) describe el puzzle y fija que el error es "sin castigo, sube la tensión". El commit `a52c1af` plantea el cambio como "perspectiva de nene de 7 años": figuras de 22 a 36 cm y ojos a 1,1 m. El motivo narrativo de esa perspectiva (por qué la memoria se vive desde la altura de un niño) no quedó registrado: *motivo no registrado, a confirmar con el equipo*.
- **Problemas encontrados (según el commit `e0d7999`):** antes, el casillero lo decidía dónde caía físicamente la figura. Con figuras grandes tocaba dos casilleros, se lo quedaba el primero de la lista y un casillero podía "robarle" la figura al vecino: **en una simulación, 13 de 27 intentos fallaban**. Se cambió a que la figura vaya al casillero al que **apunta la mira** (`Player.get_aimed_slot` + `PlacementSlot.place`), el casillero apuntado se ilumina y la mira dice "(E) Colocar". También se quitó una rotación accidental de ~4,5° en el nodo `Head` del player que desviaba la dirección de caminar respecto de hacia dónde se miraba.
- **Alternativas descartadas:** ninguna registrada.
- **Archivos y docs:** `scenes/memories/m1_habitacion/`, `scripts/puzzles/`, `scripts/memories/memory_1_room.gd`, `scripts/ui/subtitle_display.gd`, `config/memory_1_*.tres`, `docs/ELEMENTOS_ESCENAS.md`.
- **Pendiente / ❓ ABIERTO:** faltan modelos y sonidos reales (etapa 3); la letra de la canción de cuna es provisoria.

### CL-007 · Documentación de trabajo del equipo · 2026-10-08
*(reconstruido del historial: `CLAUDE.md`, `docs/GIT_WORKFLOW.md`, `docs/ELEMENTOS_ESCENAS.md`)*
- **Qué se hizo:** se escribió la guía para sesiones de Claude (`CLAUDE.md`), el flujo de git para las 4 personas, y el inventario de elementos por escena.
- **Por qué (decisión de diseño):** el trabajo se organiza por **etapas** en vez de por dueños de niveles: etapa 0 (todo el juego de punta a punta con formas genéricas), etapa 1 (mecánicas reales), etapa 2 (sensación: luz, audio, shader PS1) y etapa 3 (arte). Así `main` siempre se puede jugar de principio a fin y nadie queda bloqueado esperando el nivel de otro. Para no pisarse, las escenas grandes se dividen en subescenas y se **reclaman** antes de editarlas.
- **Alternativas descartadas:** un dueño fijo por nivel (el diseño inicial de este flujo): no consta por qué se cambió, motivo no registrado.
- **Archivos y docs:** `CLAUDE.md`, `docs/GIT_WORKFLOW.md`, `docs/ELEMENTOS_ESCENAS.md`.
- **Pendiente / ❓ ABIERTO:** `GUION_MAESTRO`, `SIMBOLOGIA`, `SENALES_Y_ESTADOS`, `TUNING` y `DECISIONES` siguen sin escribirse (ver tabla en `CLAUDE.md`).

### CL-006 · Flujo entre memorias: `GameFlow`, fundido y clase `Memory` · 2026-10-07
*(reconstruido del historial: `0fa2ffd`, `37d362c`, `72e66f7`, `e01eae4`, `08cae0d` de la rama `claude/estructura-memorias`)*
- **Qué se hizo:**
  - Autoloads `GameFlow` (sabe en qué memoria estamos y carga la siguiente) y `ScreenFade` (fundido a negro).
  - Clase base `Memory` con `complete()` y `fail()`; `MemorySequence` (lista ordenada de escenas) y `FlowSettings` (duración de los fundidos).
  - Cuatro memorias provisorias con una salida, y la escena del Despertar. Atajos de debug F9 (siguiente memoria) y F10 (reiniciar), solo en builds de debug.
- **Por qué (decisión de diseño):** **las memorias no se conocen entre sí**. Cada una avisa que terminó (`memory_completed`) y `GameFlow` decide qué sigue; reordenar o insertar memorias es editar una lista, no tocar escenas. Si el jugador falla, `fail()` reinicia solo esa memoria.
- **Alternativas descartadas:** ninguna registrada.
- **Archivos y docs:** `scripts/core/`, `scripts/memories/memory.gd`, `scripts/config/memory_sequence.gd`, `scenes/memories/`, `docs/arquitectura.md`.
- **Pendiente / ❓ ABIERTO:** escenas no controlables (la caída al agua, el despertar): el player todavía no puede quedar sin control durante una cinemática.

### CL-005 · Mira contextual y aterrizaje suave de los objetos · 2026-10-08
*(commits `de62acd` y `9c5c0ae`)*
- **Pedido por:** Facu: debajo de la mira un "(E) Agarrar", y que el círculo de la mira se vuelva "un poquito más gordito y blanco"; una animación sutil para que el objeto aterrice suavemente en su lugar. Después: "Colocar" debe aparecer **solo cuando se puede dejar en alguna zona colocable** (sea la correcta o no).
- **Qué se hizo:**
  - Mira circular (`ReticleDot`) que crece y se pone blanca llena cuando hay algo para hacer. Mensaje "(E) Agarrar" al apuntar a un objeto libre; "(E) Colocar" solo con algo en la mano y sobre un casillero libre. Con algo en la mano y lejos de un casillero, no muestra nada (E igual lo suelta).
  - `PickupObject.animate_settle()`: el objeto aterriza interpolando posición y rotación (~0,18 s) con un aplastamiento sutil del mesh. Es genérico: sirve para cualquier objeto y casillero.
  - Valores ajustables en `config/interaction_prompt_settings.tres` y `config/pickup_settings.tres`.
- **Por qué (decisión de diseño):** encastrar era un teletransporte instantáneo, que se lee como un glitch. Un aterrizaje corto y amortiguado confirma "se colocó" sin parecerse a un efecto de dibujito animado. El mensaje "Colocar" solo aparece cuando hay algo que decir para no llenar la pantalla de carteles. La UI consulta al `Player` con dos funciones públicas de solo lectura en vez de leer sus variables internas.
- **Alternativas descartadas:** mostrar siempre "Colocar" con algo en la mano (probado; Facu pidió el cambio); un rebote tipo *bounce* (descartado por "sutil").
- **Problemas encontrados:** ninguno relevante.
- **Archivos y docs:** `scripts/ui/`, `scripts/interaction/pickup_object.gd`, `scripts/world/placement_slot.gd`, `scripts/player/player.gd`.
- **Pendiente / ❓ ABIERTO:** estética de la mira y tamaño del texto, a ajustar jugando.

### CL-004 · Pulido del agarre: sin choque con el jugador, re-agarrar y bloqueo · 2026-10-08
*(commits `de62acd` y `9c5c0ae`)*
- **Pedido por:** Facu: "el objeto esté un poco más lejos (cuando sprinteas con el objeto en mano, te lo chocas y te frenás)"; poder agarrarlo otra vez después de dejarlo; y una bandera para que en algunos niveles (atar sogas en la cubierta) el objeto **no** se pueda sacar una vez colocado.
- **Qué se hizo:**
  - Mientras se carga, el objeto no colisiona con el jugador; distancia de sostén de 1,1 a 1,5 m.
  - `PickupObject.is_locked` (con `lock()` / `unlock()`) y `PlacementSlot.locks_object_on_place` (apagado por defecto): cada casillero decide si deja el objeto fijo para siempre.
- **Por qué (decisión de diseño):** el bloqueo es **por casillero**, no global: en el puzzle de la M1 las piezas se pueden reacomodar hasta resolverlo; en la cubierta, cada amarre fija la soga. Quedó **sin construir** el controlador que bloquea todas las piezas cuando el puzzle completo se resuelve: depende de decidir cómo se sabe que una pieza está en el casillero correcto.
- **Alternativas descartadas:** un único bloqueo global por puzzle (no cubre el caso de la soga).
- **Problemas encontrados:** al volver a agarrar un objeto ya colocado, el rayo de interacción chocaba contra la zona de detección invisible del casillero, que rodeaba al objeto, y nunca lo reconocía. **Solución:** los casilleros viven en la capa de colisión 2 y el rayo solo mira la capa 1. Detectado por pruebas automáticas.
- **Archivos y docs:** `scripts/interaction/pickup_object.gd`, `scripts/world/placement_slot.gd`, `config/pickup_settings.tres`.
- **Pendiente / ❓ ABIERTO:** ❓ cómo se valida "pieza correcta en el casillero correcto" en los puzzles con varias piezas.

### CL-003 · Primer prototipo de agarrar y colocar · 2026-09-30
*(commit `4a34266`)*
- **Pedido por:** Facu: "una esfera roja con físicas drag and drop, emulando los objetos que hay que colocar en el primer puzzle", y un lugar para colocarla "encima de un cubo rojo".
- **Qué se hizo:** `PickupObject` (RigidBody3D que se sostiene con un resorte frente a la cámara y se suelta solo si queda muy lejos), `PlacementSlot` (Area3D que lo detecta y lo encastra), `PickupSettings` y la tecla `interact` (E).
- **Por qué (decisión de diseño):** el objeto sigue siendo un cuerpo físico mientras se lo carga (en vez de "pegarlo" a la cámara) para que se sienta con peso y choque con el entorno. La distancia de auto-liberación evita que quede atravesando una pared si el jugador se aleja.
- **Alternativas descartadas:** rotación manual del objeto en la mano (no pedida; depende de cómo sea el puzzle real).
- **Problemas encontrados:** una versión inicial del valor de auto-liberación (2,5 m) coincidía con el alcance del rayo y soltaba el objeto en el mismo instante de agarrarlo; se subió a 4 m.
- **Archivos y docs:** `scripts/interaction/`, `scripts/world/placement_slot.gd`, `config/pickup_settings.tres`.

### CL-002 · README y estructura inicial del repositorio · 2026-09-30
*(commits `289edee`, `7b40874`)*
- **Qué se hizo:** `README.md` con requisitos (Godot 4.7.x estándar), cómo levantar el proyecto, controles y estructura de carpetas.
- **Por qué (decisión de diseño):** una guía única para que cualquiera de las 4 personas pueda abrir el proyecto sin ayuda.
- **Alternativas descartadas:** Git LFS para audio y modelos: se recomendó no usarlo (estilo PS1, assets chicos); sigue sin activarse.

### CL-001 · Proyecto base y jugador en primera persona · 2026-09-24
*(commits `d672607`, `38842be`, `874df2d`)*
- **Qué se hizo:** proyecto Godot 4.7 (Forward+, física Jolt); sandbox con terreno, plataformas y rampa; jugador en primera persona (caminar, correr, salto variable, *coyote time*, *jump buffer*); acciones del InputMap; shader provisorio de grilla; se eliminó el plugin Phantom Camera, que se había descargado solo para probar el editor y no se usaba.
- **Por qué (decisión de diseño):** **ningún valor de "feel" va escrito en el código**: todo se expone en un `Resource` (`config/player_settings.tres`) que el equipo edita desde el Inspector. Los controles son acciones del InputMap, nunca teclas fijas. Así el equipo ajusta las sensaciones sin tocar scripts.
- **Alternativas descartadas:** conservar Phantom Camera (no se usaba).
- **Archivos y docs:** `scripts/player/player.gd`, `scripts/config/player_settings.gd`, `scenes/sandbox/`.
