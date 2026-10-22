# PLAN DE LA DEMO — avances de las 4 memorias

Plan para la próxima clase. **No es el diseño final de cada memoria:** es qué armamos ahora para poder mostrar avances, y en qué orden. Se trabaja de forma iterativa: si algo de acá cambia lo que dice `ELEMENTOS_ESCENAS.md`, se actualiza ese doc.

> Estados: ✅ decidido por el equipo · 📝 propuesta (confirmar) · ❓ abierto
> Prioridad: **A** = sin esto no hay demo de esa memoria · **B** = suma mucho si llegamos · **C** = después de la clase

---

## 1. Qué es la demo ✅

- **Rama `demo`** (nace de `develop`). Ahí se juntan las 4 memorias para la clase. Después de la clase, `demo` vuelve a `develop`.
- **La presentación habla de avances por aspecto:** técnicos, visuales, narrativos, estructurales, de modelado, de mecánicas, de desarrollo de personajes y de sonido. Si un aspecto no avanzó en una memoria, no pasa nada: se dice.
- **Las teclas de debug se quedan** hasta que el juego llegue a `main`. Sirven para mostrar la escena desde otros puntos de vista: luz de rayo fija, cámara libre, saltar un evento. **Todas las memorias tienen las mismas** (ver sección 5).
- Estado de partida: **M1 y M4 están bien.** Faltan **M2 y M3** (hoy son salas provisorias con un cartel y una caja "SALIDA").

### Aspectos que vamos a poder mostrar (meta)

| Aspecto | M1 Habitación | M2 Lago | M3 Casa | M4 Barco |
|---|---|---|---|---|
| Técnico | Puzzle de secuencia, agarrar/colocar | Placas de hielo físicas, nieve, flashbacks | Laberinto que se repite (teletransportes invisibles) | Océano, sogas simuladas, ola, rayos, flotación |
| Visual | Luz cálida | Hielo frío + farol cálido, niebla | Casa que se degrada, luz fría + velador cálido | Tormenta nocturna, rayos, reflector |
| Narrativo | Canción de la abuela, barquito favorito | Perro, padre, rescate, mochila con el barquito | Entrega del barquito a la hija | Despertar en el camarote, la ola, el hundimiento |
| Estructural | Flujo entre memorias (`GameFlow`) | Sistemas compartidos reutilizados (sección 4) | Reutiliza el layout de M1 | Transición M3 → M4 |
| Modelado | Greybox | Greybox + assets libres si llegan | Greybox (reusa M1) | Barco, cabrestantes, hacha |
| Mecánicas | Ordenar juguetes | Cruzar el hielo hasta el perro | Encontrar el cuarto y entregar | Cortar sogas con el evento rápido |
| Personajes | Abuela (voz), mamá (voz) | Perro, padre (linterna, voz) | Hija | Tripulante (voz desde la cabina) |
| Sonido | ❓ | Ladridos, crujidos, viento (placeholder) | Goteo, voz de la hija (placeholder) | Chapuzón (placeholder) |

---

## 2. Memoria 2 — El lago helado (demo)

### Recorrido de la demo 📝
1. **Despertar por la tormenta** (regla de todas las memorias ✅). El protagonista, adolescente, se despierta en la **cabaña de pesca** con un trueno. Afuera atardece y la tormenta se acerca por el horizonte. La radio a pilas avisa de la tormenta.
   - **Tiene una linterna en la mano** ✅ desde el comienzo. Es su luz para cruzar el lago cuando oscurece.
2. **La mochila con el barquito** (ver abajo). Está sobre la mesa de la cabaña. No se sale sin ella (se reutiliza `ItemGate` de M1).
3. **El perro escapa.** Sale corriendo y ladrando hacia el lago, y queda esperando sobre una placa de hielo lejana. Los ladridos guían.
4. **Cruzar el hielo.** Placas que se inclinan según dónde se pisa, resbalan y se agrietan si uno se queda quieto. Caerse al agua = negro breve y se vuelve a la última placa firme (como caerse del barco en M4: un fallo más, nunca game over).
5. **Flashbacks** de la noche del accidente (capturas de M4), de menos de un segundo, cuando el hielo cruje fuerte o una placa se parte, y sobre todo en la oscuridad del final.
6. **Llegar al perro → cinemática** ✅: el hielo se rompe y caen los dos al agua → **la linterna se le cae y se hunde**, girando y apagándose → **oscuridad total** → **flashbacks** de la noche del accidente → la luz del padre desde arriba, su mano y su voz (*"agarrate, no te suelto"*) → negro → M3.

### El barquito en la mochila 📝 (era el pendiente ❓ 6)
Estamos en un sueño: no tiene que ser realista.
- **En la cabaña:** la mochila está abierta sobre la mesa y el barquito asoma, con un brillo cálido apenas visible (la misma variante "luminosa" del barquito compartido, muy baja).
- **Al agarrarla:** queda colgada del hombro y el barquito **asoma por encima del hombro, en la esquina inferior de la pantalla**, como el hacha en M4 (mismo sistema de objeto en mano). Se mueve con el paso y tiembla de frío.
- **En la caída al agua:** después de los flashbacks, el barquito **flota hacia arriba, encendido**, y es lo último que se ve antes de la luz del padre. Anticipa la luz del final de M4.
- **La linterna** va en la otra mano: el barquito asoma a la izquierda y la linterna a la derecha.
- Alternativa más barata si no llegamos: el barquito brillando en la mochila sobre la mesa y nada más (la mochila no se ve después).

### Prioridades
| Qué | Prioridad | Reutiliza |
|---|---|---|
| Terreno: orilla, cabaña con farol, lago, placas | A | — |
| Placas de hielo (`IcePlate`: inclinación, deslizamiento, grieta con tiempo) | A | `DeckSlip` (empuje), ajustes en un Resource |
| Caer al agua y volver a la última placa firme | A | Lógica de caída de M4 (`_fall_overboard`) |
| Perro (cápsula que corre a un punto y ladra) | A | `NPC simple` |
| Linterna en la mano (luz para cruzar el lago) | A | `HeldItemView` |
| Cinemática final (caída, la linterna se hunde, oscuridad, flashbacks, el padre) | A | Vista bajo el agua de M4 |
| Despertar por la tormenta en la cabaña | A | `WakeUpIntro` (sección 4) |
| Flashbacks | A | `FlashbackOverlay` (sección 4) |
| Mochila + barquito sobre el hombro | B | `HeldItemView` (sección 4) + `ItemGate` |
| Nieve, viento, niebla, rayos lejanos | B | Lluvia de M4 con otros valores, `LightningController` |
| Lago con el shader del océano en calma | B | `ocean.gdshader` (olas casi nulas, color helado) |
| Radio con la alerta de tormenta (voz/texto) | C | — |

---

## 3. Memoria 3 — La casa, la madrugada antes de embarcar (demo)

### Recorrido de la demo 📝
1. **Despertar por la tormenta** ✅. Son casi las 3:00. El protagonista, adulto, se despierta **en la mesa de la cocina** (se quedó dormido con el café) por un trueno. Llueve contra las ventanas. *(Cambia el doc: decía "sin tormenta"; la regla de todas las memorias es que siempre hay tormenta.)*
2. **El barquito en la mano** desde el comienzo (objeto en mano, como el hacha de M4). No se puede soltar.
3. **La casa que se repite.** Hay que llegar al **cuarto de la hija** para despedirse. El pasillo y las puertas llevan de vuelta a la cocina si se elige mal.
   - Guía: la **voz de la hija** y la **luz cálida del velador** bajo una puerta. Si se va bien, la voz se oye más cerca; si se va mal, más lejos.
   - Cada vez que el jugador vuelve a la cocina, la casa está **más degradada:** el pasillo es más largo, hay más agua en el piso, las fotos más borrosas.
   - 📝 Regla concreta: 3 tramos de pasillo; en cada uno, una sola puerta es la buena (la del velador). Elegir mal te devuelve a la cocina, pero se conserva el tramo ganado.
4. **El cuarto de la hija** = la habitación de M1 redecorada (mismo layout), con el **estante alto vacío** donde estaba el barquito. Se le entrega el barquito: *"Cuidámelo hasta que vuelva."*
5. **La casa se estabiliza:** se apagan los loops, el pasillo vuelve a su largo, se abre el camino a la entrada (bolso de viaje, campera y botas).
6. **Sale por la puerta de casa → todo negro → empieza M4** ✅ (ver 3.1).

### 3.1 Transición M3 → M4 ✅ (era el pendiente ❓ 7)
- El protagonista **sale por la puerta de su casa** y **todo se pone negro**. Sin voces del hospital en esta transición.
- **M4 empieza con el protagonista levantándose de la cama en el camarote** del barco. Lo despierta la tormenta y lo llaman porque lo necesitan en cubierta (el tripulante grita desde afuera).
- El jugador **sale corriendo** por el pasillo del barco hasta salir a cubierta.
- 📝 Cómo se une con lo que ya está hecho (CL-025): la puerta del pasillo sale a la **pasarela de arriba de la escalera**, y recién ahí ocurre el **relámpago largo** que muestra el mar. Es decir, el camarote y el pasillo se agregan **antes** del inicio actual de M4, sin cambiar el resto.
- 📝 Técnica: el camarote y el pasillo son un set chico aparte (el modelo del barco no tiene interior). Al abrir la puerta, un destello del rayo en blanco tapa el cambio y el jugador aparece en la pasarela.

### Prioridades
| Qué | Prioridad | Reutiliza |
|---|---|---|
| Cocina, pasillo, puertas, entrada (greybox) | A | — |
| Laberinto: puertas que teletransportan sin que se note, por tramos | A | `MemoryExit`/`Area3D` |
| Cuarto de la hija (layout de M1) + hija (cápsula) + entrega | A | `room_layout.tscn` de M1 |
| Barquito en la mano | A | `HeldItemView` |
| Estabilizar la casa y salir → negro → M4 | A | `GameFlow` |
| Despertar en la cocina por un trueno | A | `WakeUpIntro` |
| Degradación progresiva (agua, pasillo más largo, fotos borrosas) | B | — |
| Lluvia y rayos por las ventanas | B | `LightningController` |
| Voz de la hija que se acerca o se aleja | B | `AudioStreamPlayer3D` |

### Memoria 4: lo nuevo para la transición
| Qué | Prioridad |
|---|---|
| Camarote + pasillo (greybox), despertar en la litera por la tormenta, el tripulante grita desde afuera | A |
| Salir por la puerta → destello → pasarela → relámpago largo (lo de CL-025) | A |
| Reloj parado a las 3:00 en el camarote | B |

---

## 4. Sistemas compartidos (se hacen una vez, antes que las memorias)

Es el avance **estructural** de la demo: lo que se hizo para M4 pasa a servir para todas.

| Sistema | Qué hace | Sale de | Lo usan |
|---|---|---|---|
| `DebugTools` | Teclas de debug comunes (sección 5). Se pone en cada memoria como un nodo | Teclas 8 y 9 de `Memory4Accident` | M1–M4 |
| `LightningController` sin depender de M4 | Hoy lee los valores de `Memory4Settings`; pasa a tener su propio `LightningSettings` | `lightning_controller.gd` | M2, M3, M4 (y M1 por la ventana, C) |
| `WakeUpIntro` | Despertar por la tormenta: negro, trueno, parpadeo de ojos, se devuelve el control | Intro de M4 | M2, M3, M4 |
| `HeldItemView` | Objeto en mano en la esquina de la pantalla, que se mueve con el paso y tiembla | `AxeView` | Barquito (M3), mochila (M2), hacha (M4) |
| `FlashbackOverlay` | Imágenes a pantalla completa de menos de un segundo, con opción de reducirlas (fotosensibilidad) | Nuevo | M2 (y donde se quiera) |
| Capturas de M4 | Imágenes para los flashbacks: la cubierta con el rayo, la soga cortándose, la ola, el agua negra, la luz del fondo | Se sacan de `memory_4.tscn` | M2 |
| Caída al agua / volver a lo firme | Negro, chapuzón y vuelta al último punto firme | `_fall_overboard` de M4 | M2 |

---

## 5. Teclas de debug (iguales en todas las memorias) ✅ / 📝

| Tecla | Qué hace | Dónde |
|---|---|---|
| 8 | Cámara libre: WASD hacia donde se mira, Espacio sube, Shift baja, Ctrl acelera ✅ | Todas |
| 9 | Luz de rayo fija ✅ | Donde hay rayos (M2, M3, M4) |
| 0 | **Saltar el evento principal** de la memoria 📝: M1 resuelve el puzzle, M2 lleva al perro, M3 entrega el barquito, M4 corta las sogas ✅ | Todas |
| 7 | 📝 Disparar un flashback | M2 |
| F9 / F10 | Siguiente memoria / reiniciar (ya existen) | Todas |

Se apagan todas juntas con `debug_keys` en cada memoria cuando el juego llegue a `main`.

---

## 6. Orden de trabajo y ramas

| Paso | Rama | Qué |
|---|---|---|
| 0 | `demo` | ✅ Creada desde `develop` (M4 ya está mergeada) |
| 1 | `demo` | ✅ `DebugTools`, `LightningSettings`, `HeldItemView`, `WakeUpIntro`, `FlashbackOverlay` + capturas de M4 (CL-030) |
| 2 | `demo` | ✅ M2 demo: prioridad A completa y casi toda la B (CL-031) |
| 3 | `memories/m3-casa` | M3 demo (prioridad A, después B) |
| 4 | `memories/m4-barco` | Camarote + pasillo + unión con el inicio actual |
| 5 | `demo` | Se mergea todo y se prueba de punta a punta (F5 desde M1) |

Cada paso termina con su entrada en el `CHANGELOG.md` y capturas. *(Los pasos 1 y 2 se hicieron directo sobre `demo`, sin commitear, para no cambiar de rama con el editor abierto.)* Los pasos 2, 3 y 4 dependen del 1, pero entre ellos son independientes.

**Modelos de Claude:** Opus para planificar y para lo difícil (física de las placas, laberinto, shaders); Sonnet para implementar e iterar sobre un plan cerrado.

---

## 7. Abierto ❓ (no frena la demo, se usa la propuesta 📝 si no hay respuesta)
1. Edad del protagonista en M2 (📝 adolescente, ~14) y en M3 (📝 adulto, ~35).
2. ¿El padre se ve en el rescate o solo la linterna y la mano? (📝 linterna + mano)
3. ¿La cara de la hija se ve borrosa (como dice el doc) o directamente no se ve? (📝 cápsula sin cara en la demo)
4. M3: ¿la regla de "3 tramos con una puerta buena" se entiende o hace falta otra pista además de la voz y la luz?
5. ¿Quién llama al protagonista en el camarote: el mismo tripulante de la cabina? (📝 sí, el único tripulante)
