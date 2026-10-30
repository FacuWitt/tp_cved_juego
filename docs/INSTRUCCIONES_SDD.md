# Instrucciones para mantener el SDD

> **Para quién es este archivo.** Para cualquier persona o LLM (Claude Code u otro) que tenga que continuar el *Solution Design Document* (SDD) del juego. Explica qué es el SDD, dónde está, de dónde se saca la información, cómo tiene que estar escrito y cómo se le agrega contenido sin romper su estructura.
>
> **Regla corta:** el SDD es un **relato cronológico por etapas** de cómo evolucionó la idea. Cada cambio de diseño relevante se registra primero en `CHANGELOG.md` y después se **narra** en la etapa que corresponde del SDD, sin citar el changelog.

---

## 1. Qué es el SDD y para qué sirve

Es el entregable teórico de la materia *Creatividad y Desarrollo de Entornos Virtuales* (UTN FRC, 2026, Grupo 10). La consigna (enunciado "Solution Design Document", 2.º cuatrimestre) pide **sistematizar el proceso de diseño** del entorno virtual aplicando metodologías de creatividad, y articular cuatro dimensiones: **técnica, estética, narrativa y experiencial**.

Los criterios de evaluación son: profundidad del análisis, uso de herramientas de creatividad, conceptualización (narrativa y estética), y **coherencia entre narrativa, interacción y experiencia**. Se valora la reflexión crítica y el uso de conceptos teóricos (Janet Murray: inmersión, agencia, transformación).

Se entrega como **link a un documento compartido** con acceso para el equipo docente (Prof. Franco Mana, Prof. Inés Gimenez Zens, Prof. Bruno Aresu Barella).

### La pauta del grupo (pestaña "SDD Entregable")

En el documento del grupo "Solution Design Document Grupo 10" (Drive, carpeta *Entrega1 BrainStorming*) la pestaña **SDD Entregable** fija cómo hacerlo:

- **No armarlo con títulos fijos y de forma estática.** La idea es expresar **cómo evolucionamos la idea hasta llegar a la idea final**: "Etapa 0 - Lluvia de ideas, Etapa 1 - ...".
- El **mapa de empatía es obligatorio** (más el resto de las herramientas trabajadas en clase).
- Incluir **capturas del juego**, la **evolución de la idea** y el **tráiler**.

Por eso el SDD **no** sigue el índice del enunciado como capítulos. Los contenidos mínimos del enunciado se cubren **dentro de las etapas**, y una tabla en la Introducción indica en qué etapa está cada uno.

---

## 2. Dónde está

| Qué | Dónde |
|---|---|
| **El SDD (documento vivo)** | Google Doc "SDD - Cable a Tierra (Grupo 10)" · ID `1yRsWzoLw1s2hXue0UeK63wLjt5XROXfQMu5Io2RT4Rc` · https://docs.google.com/document/d/1yRsWzoLw1s2hXue0UeK63wLjt5XROXfQMu5Io2RT4Rc/edit |
| Carpeta del TP en Drive | "TP - CREATIVIDAD 2026" · ID `11ckdFJwviVkrk6u6Xh_DaAyx0zh5Gumt` |
| Documento del grupo con la pauta, integrantes y herramientas de clase | "Solution Design Document Grupo 10" · ID `13V5XUsrVkbq4vdO2dO4YnMgVN1n0Xu0dz7AuVTBECMg` (carpeta *Entrega1 BrainStorming*). Las imágenes del esquema del problema/reto, mapa de empatía y gráfico de actores están en la pestaña 6 |
| Guion, propuestas y simbología originales | "PROPUESTAS" · ID `1iYmAZRcSS1ldZs4jU_ZLpjeSxU1a7qbw3QvgY936gBg` (carpeta *Ideas*): guion del 30/09, propuestas modificadas del 2/10, simbología, voces de transición, documento de la M1, investigación de la M4 ("hombre al agua") |
| Enunciado de la cátedra | PDF "Enunciado_SolutionDesignDocument-2Q" (pedírselo al equipo si hace falta releerlo; lo esencial está resumido en la sección 1 y 4 de este archivo) |

**El Google Doc es la única versión válida del SDD.** Siempre se edita ese mismo archivo (mismo ID, mismo link): nunca se crea uno nuevo ni una copia.

`docs/SDD_EVOLUCION.md` fue el **primer borrador** en el repo del relato de la evolución. Quedó superado por el Google Doc y **ya no se mantiene**; sirve solo como referencia histórica.

---

## 3. De dónde sale la información

1. **`CHANGELOG.md` (fuente principal).** Cada entrada `CL-NNN` tiene *Pedido por*, *Qué se hizo*, *Por qué*, *Alternativas descartadas*, *Problemas encontrados* y *Pendiente*. De ahí salen las decisiones, los motivos y lo descartado. **Se usa como fuente, pero no se cita** en el SDD (nada de "CL-034", ni "según el changelog").
2. **Documentos de diseño del repo:** `docs/ELEMENTOS_ESCENAS.md` (qué hay en cada escena), `docs/PLAN_DEMO.md` (demo y decisiones de M2/M3/M4), `docs/arquitectura.md` (flujo entre memorias), `docs/GIT_WORKFLOW.md` (método por etapas y ramas), `CLAUDE.md` (reglas del proyecto).
3. **Documentos de Drive** listados arriba: para la etapa de ideación, la pauta y las herramientas de clase.
4. **El equipo.** Lo que no está escrito en ningún lado se pregunta. No se inventa.

### Correspondencia aproximada entre etapas del SDD y entradas del changelog

| Etapa del SDD | Entradas / fuentes |
|---|---|
| Etapa 0. Consigna y lluvia de ideas | Drive: PROPUESTAS (guion 30/09), documento del grupo; descripción del proyecto |
| Etapa 1. Usuario, universo y reglas | Drive: propuestas modificadas 2/10, simbología, voces; pestaña 6 del documento del grupo |
| Etapa 2. Método de producción y base técnica | CL-001 a CL-007, CL-010 |
| Etapa 3. Memoria 1 | CL-008, CL-009, CL-011, CL-012, CL-013 |
| Etapa 4. Memoria 4 (excepción al método) | CL-014 a CL-028, CL-032, CL-033 |
| Etapa 5. Cambio estético y demo | CL-016 (postprocesado), CL-022, CL-029, CL-030 |
| Etapa 6. Memoria 2, dos versiones | CL-031, CL-034 |
| Próximas etapas | CL-035 en adelante |

---

## 4. Estructura actual del documento

1. **Portada:** título, "Solution Design Document", universidad, materia, grupo, integrantes con legajo, y la línea en cursiva *"Documento en construcción… Última actualización: <fecha>"* (**actualizar la fecha en cada edición**).
2. **Introducción:** qué es el juego, que el documento es un relato cronológico, y la **tabla "Contenido del enunciado → Dónde se desarrolla"**.
3. **Organización del equipo de diseño:** tabla de roles (los integrantes figuran "A asignar") y subsección **"Uso de herramientas de inteligencia artificial"** (tabla Herramienta / Modelo / Uso: Claude Code con la familia Claude, en las últimas etapas Claude Opus 5.5 y Claude Sonnet 5.5; Claude en claude.ai; Meshy).
4. **Etapa 0. La consigna y la lluvia de ideas (septiembre)**
5. **Etapa 1. El usuario, el universo y sus reglas**
6. **Etapa 2. Método de producción y base técnica** (arquitectura técnica, dispositivos)
7. **Etapa 3. Memoria 1: el acertijo de la canción de cuna**
8. **Etapa 4. Memoria 4: el accidente.** Abre explicando que fue una **excepción deliberada al método por etapas**: se hizo un nivel completo (mecánicas, efectos, lluvia, océano, desafío técnico) porque el equipo no conocía el alcance de Claude Code en Godot y quería asegurar que el desarrollo completo de un nivel era viable antes de comprometer el resto.
9. **Etapa 5. Cambio estético y preparación de la demo**
10. **Etapa 6. Memoria 2: dos versiones**
11. **Estado actual y próximos pasos** (tabla Memoria / Estado / Lo que falta, párrafo de pendientes y lugar del tráiler)
12. **Síntesis del diseño** (inmersión, agencia y transformación según Murray; características generales; objetivos alineados con la estrategia)
13. **Conclusión** (borrador; la versión final se escribe al cerrar el prototipo)
14. **Referencias**, **Bibliografía**
15. **Anexos:** la canción de cuna y el orden del acertijo, Simbología, Controles, **Registro de decisiones de diseño** (tabla Fecha / Decisión / Motivo)

Dentro de cada etapa el patrón es: qué se propuso → qué se probó → qué se descartó y por qué → (opcional) **"Lo que dejó esta etapa:"** en negrita, con las decisiones que quedan para el resto del juego.

---

## 5. Cómo tiene que estar escrito

- **Narrado, en orden cronológico.** El documento cuenta cómo se llegó a cada decisión, no solo cuál es. Siempre que exista: la propuesta original, lo que se probó, lo que se descartó y **por qué**.
- **Registro académico, no literario.** Prosa clara y formal, en español rioplatense neutro (voseo no hace falta; usar impersonal o tercera persona: "el equipo decidió", "se descartó"). Nada de lenguaje poético ni dramatizado.
- **Personas por rol, no por nombre.** "El responsable de programación y diseño de juego", "el equipo", "la cátedra". Los nombres aparecen solo en la portada.
- **No mencionar el changelog, los números CL, ni que el contenido sale de una conversación o de un chat.** Las herramientas de IA sí se mencionan, en la subsección correspondiente y donde sean parte de una decisión (por ejemplo, la Etapa 4).
- **Honestidad.** No se inventan motivos. Si no se registró por qué se decidió algo, se escribe *motivo no registrado* (en cursiva). Las lecturas de diseño que el equipo no enunció se marcan como *Interpretación propuesta, a validar por el equipo:*.
- **Fechas** en cada título de etapa (rango aproximado) y en las decisiones importantes.
- **Conceptos teóricos** donde aporten: inmersión, agencia y transformación (Murray), narrativa digital, perspectiva y flujo, dispositivos de interacción, diseño sonoro, diseño narrativo del entorno.
- **Sin rayas (—) como puntuación.** Usar comas, dos puntos o punto.
- Detalle técnico solo el necesario para entender la decisión. Nombres de clases, scripts y archivos **no** van al SDD (eso queda en el repo).

### Formato en el Google Doc

- Títulos con estilos de párrafo: *Título* (portada), *Encabezado 1* (cada etapa y sección), *Encabezado 2* (subtemas), con "mantener con el siguiente".
- Viñetas con la lista nativa del documento (no escribir "- " a mano). Cada viñeta empieza con una frase en **negrita** cuando enumera pasos o cambios.
- Tablas nativas con la fila de encabezado en negrita.
- Cursiva para *motivo no registrado*, la canción de cuna y las interpretaciones propuestas.

---

## 6. Capturas, imágenes y otros pendientes visuales

- Donde haga falta una imagen se deja un **marcador** en su propio párrafo, **entre corchetes, en cursiva y gris** (RGB 0.45, 0.45, 0.5):
  - `[Captura pendiente: <qué tiene que mostrar>]`
  - `[Imagen pendiente: mapa de empatía]`, `[Diagrama pendiente: ...]`, `[Storyboard pendiente: ...]`, `[Moodboard pendiente: ...]`, `[Tráiler pendiente: ...]`
  - `[Texto pendiente: ...]` o `[Completar: ...]` para texto que tiene que escribir el equipo.
- La descripción tiene que ser lo bastante concreta para que alguien entre al juego y saque exactamente esa captura (lugar, momento, qué se ve).
- **Las capturas las saca el equipo** jugando. Un LLM no las inventa ni las genera. Cuando el equipo pasa una imagen, se reemplaza el marcador por la imagen y debajo se agrega un epígrafe corto en cursiva ("Figura N. ...").
- Cada etapa nueva con contenido visible en el juego lleva al menos un marcador de captura.
- Las imágenes del documento del grupo (mapa de empatía, gráfico de actores, esquema del reto) se copian desde ahí cuando el equipo lo indique.

---

## 7. Cómo agregar información

### Cuándo
Cada vez que un cambio de diseño relevante entra al `CHANGELOG.md` (mecánica nueva o reemplazada, decisión narrativa, cambio estético, cambio de alcance o de método, una memoria nueva), en la misma sesión o cuando el equipo lo pida. Ajustes de valores, bugs menores y refactors **no** van al SDD.

### Qué tocar
1. **Si el cambio continúa una etapa existente** (por ejemplo, una tercera versión de la M2): agregar el texto en esa etapa, respetando el orden "propuesta → prueba → descarte → motivo". No borrar lo anterior: lo descartado es parte del relato.
2. **Si es una etapa nueva** (por ejemplo, la construcción de la Memoria 3, el sonido, el despertar, el tráiler): crear **"Etapa N. Título (fechas)"** como *Encabezado 1* **antes** de "Estado actual y próximos pasos". La próxima es la **Etapa 7**.
3. **Siempre, además:**
   - Sumar una fila al **Registro de decisiones de diseño** (anexo), en orden cronológico: Fecha / Decisión / Motivo.
   - Actualizar la tabla de **Estado actual** y el párrafo de pendientes.
   - Si cambia la cobertura del enunciado, actualizar la **tabla de la Introducción**.
   - Si el cambio aporta a inmersión, agencia o transformación, ajustar la **Síntesis del diseño**.
   - Si aparece un control nuevo, la tabla de **Controles**; si aparece un símbolo nuevo, la de **Simbología** (los símbolos no se agregan sin acuerdo del equipo).
   - Si se usó otra herramienta de IA, la tabla de herramientas.
   - Actualizar la fecha de "Última actualización" de la portada.
4. **Al cerrar el prototipo:** escribir la Conclusión con reflexión crítica sobre el proceso y reemplazar los marcadores que queden.

### Qué no hacer
- No reordenar el documento por los apartados del enunciado ni convertirlo en un documento de títulos fijos.
- No recrear el documento ni subir uno nuevo: siempre el mismo archivo.
- No borrar versiones descartadas de mecánicas o ideas.
- No citar el changelog ni números CL, no mencionar sesiones ni chats.
- No inventar motivos, resultados de pruebas con usuarios, ni contenido de herramientas de clase que no esté en los documentos.

---

## 8. Cómo editar el Google Doc (para un LLM con el conector de Google Docs)

- Leer primero el documento (`read_doc`) para tener el `revisionId` y los índices actuales. El resultado es grande: guardarlo y consultarlo con un script.
- Toda escritura (`update_doc`) va con `writeControl.requiredRevisionId` del último read o write, para no pisar ediciones del equipo. Si falla por revisión, releer y rehacer.
- **Cambios chicos de texto:** `replaceAllText` con un fragmento exacto y único del texto actual. No depende de índices y conserva el estilo del párrafo.
- **Párrafos o secciones nuevas:** `insertText` en el índice del final del párrafo anterior, después `updateParagraphStyle` (estilo con nombre) y `updateTextStyle` (negritas, cursivas, gris de los marcadores), y `createParagraphBullets` para las listas. Si se hacen varias inserciones en un mismo pedido, ir del índice más alto al más bajo.
- **Filas de tabla:** `insertTableRow` con `tableStartLocation` (inicio de la tabla) y `rowIndex`, y luego `insertText` en cada celda nueva (del índice más alto al más bajo).
- Después de escribir, releer y verificar que el texto quedó donde se esperaba.

---

## 9. Lista de control antes de terminar

- [ ] La información nueva está en la etapa correcta (o en una etapa nueva antes de "Estado actual").
- [ ] Está narrada: propuesta, prueba, descarte y motivo, en registro académico y por roles.
- [ ] Sin referencias al changelog, a números CL ni a chats.
- [ ] Motivos no registrados marcados como tales; interpretaciones marcadas "a validar".
- [ ] Marcadores de captura con descripción concreta.
- [ ] Fila nueva en el Registro de decisiones; Estado actual, Síntesis y tabla de la Introducción revisados.
- [ ] Fecha de "Última actualización" al día.
- [ ] Entrada en `CHANGELOG.md` de la tarea, que mencione que se actualizó el SDD.
