# Evolución del diseño — insumo para el SDD

> **Para qué es este archivo.** Es el relato de cómo evolucionó la idea del prototipo desde la propuesta inicial hasta la entrega, escrito para pasarlo al *Solution Design Document* (SDD). Se redacta en registro académico y se nombra a las personas por su **rol**, no por su nombre. Los roles se asignan al armar el SDD final.
>
> **Cómo se mantiene.** Cada cambio de diseño relevante (una mecánica que se reemplaza, una decisión narrativa, un cambio de alcance) agrega o corrige un apartado acá, además de su entrada en `CHANGELOG.md`. El CHANGELOG registra el detalle técnico de cada tarea. Este archivo cuenta el hilo de las decisiones.
>
> **Regla de honestidad** (igual que en el CHANGELOG): no se inventan motivos. Cuando el motivo de una decisión no quedó registrado se indica *motivo no registrado*. Las lecturas de diseño que no fueron enunciadas por el equipo se marcan como *interpretación propuesta, a validar*.
>
> **Roles usados en el texto** (provisorios):
> - **Responsable de Programación y Diseño de Juego (RPDJ)**: define mecánicas y arquitectura, integra el motor y coordina el repositorio.
> - **Equipo de diseño**: el grupo completo de cuatro integrantes, en las decisiones tomadas en conjunto.
> - **Cátedra**: el equipo docente de la materia.

---

## 1. Punto de partida: la consigna y la idea genérica

La consigna de la materia *Creatividad y Desarrollo de Entornos Virtuales* pide un entorno virtual con narrativa, interactivo y en primera persona, que trabaje la inmersión, la agencia del jugador y la dimensión multisensorial. Sobre esa base el equipo de diseño eligió desarrollar un prototipo jugable en Godot Engine 4 con GDScript.

La primera formulación del concepto plantea una **progresión psicológica**: el jugador recorre recuerdos que se degradan hasta convertirse en una pesadilla y busca un objeto que funciona como "cable a tierra", un barquito de madera. El giro final revela que el protagonista estaba en coma después de un accidente en el mar, y alcanzar el objeto equivale a despertar.

En esa primera versión la experiencia se organizaba en **tres fases** con una duración estimada de tres a cinco minutos:

1. **El recuerdo ancla:** un entorno seguro y cálido (la casa de la abuela) con un puzzle sencillo de rotación de objetos.
2. **La distorsión:** el entorno seguro se corrompe, con pasillos deformados, plataformas flotantes y una paleta que vira a tonos fríos.
3. **El trauma:** el descenso a la oscuridad del océano hacia una luz en el fondo, donde el sonido submarino se transforma en el de un monitor cardíaco de hospital.

Para la estética se propuso un estilo "PS1 con esteroides": modelos *low-poly* y texturas crudas combinados con iluminación y post-procesado modernos, con la intención de reforzar la irrealidad del sueño y abaratar la integración de modelos de repositorios.

## 2. De tres fases a cuatro memorias

La estructura de tres fases se reemplazó por una de **cuatro memorias**. El protagonista quedó en coma tras caer del barco pesquero en el que trabajaba, y para despertar tiene que rearmar cuatro recuerdos de su vida. Cada memoria es una escena autónoma y al final hay un despertar en el hospital. Con este cambio también se abandonó el límite de tres a cinco minutos. *Motivo no registrado.*

El orden de las memorias quedó así:

- **M1:** la habitación de la abuela.
- **M2:** el lago, con el padre.
- **M3:** la casa, la madrugada antes de embarcar.
- **M4:** el accidente en el barco.
- **Cierre:** el despertar.

**Regla transversal.** Más adelante el equipo de diseño fijó una regla común a todas las memorias: **siempre hay tormenta, y el protagonista se despierta por la tormenta**. La única excepción es el hospital, donde despierta por otra causa. La regla da continuidad sensorial entre recuerdos que, de otro modo, no comparten espacio ni época.

## 3. Método de producción

Para que el prototipo pudiera jugarse de principio a fin en todo momento, el RPDJ organizó el trabajo **por etapas** y no por dueños de niveles:

| Etapa | Contenido |
|---|---|
| 0 | Flujo completo con formas genéricas (*greybox*) |
| 1 | Mecánicas reales |
| 2 | Sensación: luz, audio y post-procesado |
| 3 | Arte final |

El modelo de un dueño fijo por nivel se descartó (*motivo no registrado*).

Las decisiones técnicas que sostienen el método son tres:

- **Las memorias no se conocen entre sí.** Cada una avisa que terminó y un controlador global decide qué sigue, de modo que reordenarlas es editar una lista.
- **Ningún valor de sensación está escrito en el código.** Velocidades, tiempos, colores e intensidades viven en archivos de configuración que el equipo ajusta desde el editor.
- **Hay un registro escrito de las decisiones.** A pedido de la cátedra, que todo lo trabajado quede en el documento de la solución, se incorporó un registro de cambios con el problema, la solución elegida y las alternativas descartadas de cada tarea. Este documento se apoya en ese registro.

Para la presentación de avances se agregaron **herramientas de depuración** comunes a todas las memorias: cámara libre, iluminación fija de relámpago, salto del evento principal y disparo de un flashback. Sirven para mostrar cada escena desde ángulos que el recorrido normal no ofrece, y se retiran antes de la versión final.

## 4. Estética: del "PS1" a una estética contemporánea

El estilo "PS1 con esteroides" de la propuesta inicial se fue abandonando a medida que se integraban modelos e iluminación. El equipo de diseño expresó que el look PS1 no lo convencía y que la estética actual, más moderna, funcionaba mejor. Esa estética se mantiene. La irrealidad del sueño se busca ahora con la iluminación dinámica, la niebla, la tormenta y el post-procesado, no con la degradación de las texturas.

## 5. Memoria 1 — La habitación de la abuela

El "puzzle de rotación de objetos" de la propuesta inicial se transformó en un **acertijo de orden**. Un papel de la abuela con una canción de cuna indica en qué orden colocar cinco juguetes (luna, red, ola, ancla y faro) en una repisa, y hay juguetes que funcionan como distractores. La memoria se vive desde la altura de un niño de siete años (*motivo narrativo de la perspectiva no registrado*).

Las iteraciones posteriores refinaron la propuesta:

- **Menos objetos.** Se retiraron el pescador y la marea como objetos del puzzle. El pescador confundía, porque el protagonista ya es el pescador de la canción, y la marea era difícil de representar.
- **Error sin castigo.** El error no se castiga: hace aparecer agua bajo la puerta y sube la tensión, sin hacer perder nada.
- **El vínculo con el barquito.** El barquito pasó de distractor a **juguete favorito**: el niño no puede salir de la habitación sin él. Así se establece desde la primera memoria el vínculo con el objeto que funciona como cable a tierra.
- **La hora del accidente.** Todos los relojes del juego marcan las 3:00 a. m., la hora del accidente.

Durante la prueba de esta memoria se detectó que una verificación automática que teletransportaba al jugador no había encontrado un error de colisión en la puerta. De ahí surgió una pauta para el resto del proyecto: **las pruebas recorren el camino del jugador con su física, sin atajos.**

## 6. Memoria 4 — El accidente

La cuarta memoria concentra la mayor parte del trabajo técnico y visual del primer tramo. El protagonista está en la cubierta de un pesquero en plena tormenta y tiene que cortar con un hacha las sogas de las redes, que arrastran el barco, antes de que una ola gigante lo arroje al agua. Desde ahí empieza el descenso hacia la luz del fondo.

Las decisiones de diseño que la definieron fueron estas:

- **Un solo tripulante además del jugador**, dentro de la cabina, que se oye y no se ve.
- **El hacha es un objeto que no se suelta.** Tiembla de frío cada vez más con cada soga cortada.
- **El corte es un evento rápido de *timing*.** Las sogas se ven tensas hasta el corte y salen despedidas al cortarse.
- **Una apertura que establece la escala.** Un relámpago largo sobre el océano hace sentir la inmensidad y la oscuridad del mar antes de que el jugador tome el control.
- **Mejoras de fidelidad sin cambiar la mecánica.** Más adelante se reemplazó el modelo del barco por uno de mayor calidad y se ajustaron el océano y la iluminación (el brillo de la cabina y el reflector del mástil).

## 7. Memoria 2 — El lago: dos versiones

La segunda memoria es el caso más claro de iteración por evaluación del juego.

**Primera versión.** Un adolescente se despierta en una cabaña de pesca con un trueno, toma una mochila con el barquito (que asomaba por encima del hombro), sigue a su perro, que escapó hacia el lago congelado, y cruza saltando entre placas de hielo que se inclinan y se agrietan. Al llegar al perro el hielo se rompe y cae al agua. La linterna se le escapa y se hunde, llega la oscuridad, aparecen flashbacks del accidente y por último la luz y la mano del padre que lo rescatan.

**Evaluación.** Al jugarla, el RPDJ concluyó que la mochila con el barquito no funcionaba visualmente y que la mecánica de saltar entre placas de hielo no resultaba entretenida. Se decidió quitar la mochila y revisar la mecánica central, explorando el uso de un bote.

**Segunda versión.** Se rediseñó la memoria alrededor de una actividad compartida con el padre:

1. **Pesca.** El protagonista pesca desde su bote junto al de su padre. Lanza la línea, espera la picada y la engancha a tiempo. Para pelear el pez mantiene un indicador dentro de una zona que se mueve y se achica.
2. **Red y tormenta.** Después tira una red, y mientras espera llega la tormenta.
3. **Cortar la red.** Al intentar recogerla, la red se traba y el padre le grita que la corte. El corte es un evento rápido con cuchillo que **reutiliza la mecánica de corte de la Memoria 4**.
4. **La huida.** El protagonista rema detrás de la luz del padre por un río, esquivando ramas, rocas, hielo flotante y rápidos, mientras el viento inclina el bote y hay que compensarlo remando del lado contrario. Cada remo se controla por separado.
5. **El final.** El bote aguanta tres golpes. Si se hunde, o si llega al último rápido, que lo da vuelta, el protagonista cae al agua. Desde ahí se conserva el final de la primera versión: la linterna se hunde, llegan la oscuridad y los flashbacks, y el padre lo rescata.

Que el final sea inevitable es deliberado. Al ser un recuerdo, jugar mejor o peor cambia *cómo* se llega a la caída, no *si* se llega. Tampoco hay pantalla de derrota.

*Interpretación propuesta, a validar:* reutilizar el gesto de cortar una línea tensa en M2 y en M4 anticipa en un recuerdo de la adolescencia la acción que en el accidente ya no alcanza para salvarlo. El final bajo el agua de M2 anticipa la luz del fondo de M4.

## 8. Memoria 3 y transición al accidente

La tercera memoria transcurre en la casa familiar, la madrugada antes de embarcar. La transición hacia la cuarta quedó definida así:

1. El protagonista sale por la puerta de su casa y todo se vuelve negro.
2. La Memoria 4 comienza con él levantándose de la cama del camarote. Lo despierta la tormenta y lo llaman porque lo necesitan en cubierta.
3. El jugador corre por el barco hasta salir a la cubierta.

De esta forma el despertar dentro del recuerdo también respeta la regla transversal de la tormenta.

## 9. Pendientes de diseño abiertos

- El nombre del protagonista.
- El cierre en el hospital, si es con un helicóptero o con el barco.
- El diseño sonoro completo, con sus tres capas: recuerdo, amenaza y afuera.
- Los flashbacks definitivos de la Memoria 2, que se van a componer con capturas parecidas a lo que el jugador ve fuera de ellos.
