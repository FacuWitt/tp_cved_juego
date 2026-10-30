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
| Técnico | Puzzle de secuencia, agarrar/colocar | Bote a remos con corriente y viento, pesca, río generado de una curva, flashbacks | Laberinto que se repite (teletransportes invisibles) | Océano, sogas simuladas, ola, rayos, flotación |
| Visual | Luz cálida | Atardecer en calma → tormenta de nieve; linternas en la oscuridad | Casa que se degrada, luz fría + velador cálido | Tormenta nocturna, rayos, reflector |
| Narrativo | Canción de la abuela, barquito favorito | Pesca con el padre, la red, la huida por el río, el rescate | Entrega del barquito a la hija | Despertar en el camarote, la ola, el hundimiento |
| Estructural | Flujo entre memorias (`GameFlow`) | Sistemas compartidos reutilizados (sección 4) | Reutiliza el layout de M1 | Transición M3 → M4 |
| Modelado | Greybox | Greybox + assets libres si llegan | Greybox (reusa M1) | Barco, cabrestantes, hacha |
| Mecánicas | Ordenar juguetes | Pescar, cortar la red, remar esquivando obstáculos | Encontrar el cuarto y entregar | Cortar sogas con el evento rápido |
| Personajes | Abuela (voz), mamá (voz) | Padre (pesca al lado, guía con su luz, rescata) | Hija | Tripulante (voz desde la cabina) |
| Sonido | ❓ | Voz del padre, viento, crujidos del bote (placeholder) | Goteo, voz de la hija (placeholder) | Chapuzón (placeholder) |

---

## 2. Memoria 2 — El lago y el río (demo)

> **Segunda versión ✅ (CL-034).** La primera (cruzar placas de hielo detrás del perro, con la mochila del barquito) se probó y se descartó: la mochila no quedaba bien y saltar entre placas no era entretenido. El detalle de cómo se llegó a esto está en `docs/SDD_EVOLUCION.md` (sección 7).

### Recorrido de la demo ✅
1. **Despertar por la tormenta** (regla de todas las memorias): dormitando en el bote, un trueno lejano lo despierta. El padre, en su bote al lado: "¿Te dormiste? Dale, que están picando".
2. **Pesca.** (E) lanzar → espera → pica (la boya se hunde) → (E) a tiempo para enganchar → pelea: con **W / S** se mueve un punto en una barra y hay que mantenerlo dentro del área verde, que se mueve y se achica. Hacen falta 2 peces.
3. **La red.** (E) tirar la red. Mientras flota llega la tormenta: el cielo se cierra, nieva fuerte, se prende la linterna de la proa.
4. **Cortar la red.** La red se traba. Padre: "¡CORTÁ LA RED, HIJO! ¡VOLVAMOS, QUE VIENE LA TORMENTA!". Aparece el cuchillo: se apunta a la soga y se corta con el mismo evento rápido del hacha de M4 (3 golpes).
5. **La huida.** "¡Rápido, hijo, seguime!". Se rema detrás de la luz del padre por el río:
   - **Remos:** A / D tocar para remar con el remo izquierdo / derecho (solo uno = gira, alternar rinde más), S los dos hacia atrás. Sonido de tormenta, lluvia y voces del padre de la M2 de Mica (CL-055).
   - **Obstáculos:** ramas que salen de las orillas, rocas en los rápidos, hielo flotante.
   - **Viento:** ráfagas de costado que empujan e inclinan el bote; se compensa remando del otro lado.
   - **Golpes:** el bote aguanta 3; con cada uno cruje y entra agua. Al tercero se hunde.
   - **El padre** va adelante por la línea que esquiva los obstáculos; si el hijo se queda atrás, lo espera, lo alumbra y lo llama.
6. **Final ✅:** si el bote se hunde o el último rápido lo da vuelta, cae al agua → la linterna se hunde → oscuridad → flashbacks → el barquito sube encendido → la luz, la mano y la voz del padre → negro → M3. Nunca hay pantalla de "perdiste": jugar mejor o peor cambia cómo se llega a la caída.

### Tecla 0 en M2 (saltar etapa)
Pesca → red → tormenta → cortar → lleva el bote antes del último rápido.

### Pendiente
| Qué | Prioridad |
|---|---|
| Capturas definitivas de los flashbacks (las hace el equipo) | A |
| Voces del padre y sonidos (agua, remos, viento, crujidos, rápidos) | B |
| Modelos de los botes, la caña y el cuchillo | C |
| Ajustar a mano la dificultad (fuerza de remada, viento, ancho del río) jugando | A |

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
| `HeldItemView` | Objeto en mano en la esquina de la pantalla, que se mueve con el paso y tiembla | `AxeView` | Barquito (M3), caña y cuchillo (M2), hacha (M4) |
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
