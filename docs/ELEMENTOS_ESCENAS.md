# ELEMENTOS POR ESCENA

Inventario de todo lo que hay que construir o conseguir para cada escena del juego.

> Estados: ✅ definido · 📝 propuesta · ❓ abierto
> **Etapa 0** = el placeholder genérico que se usa ahora (cubos, cápsulas, `Label3D` con el nombre). **Etapa 3** = el asset final (modelo, textura, sonido).
> Columna **Rol**: **OBL** = obligatorio para el flujo (sin esto no se puede terminar la escena) · **AMB** = ambientación (se puede sumar después).
>
> **Regla de todas las memorias ✅:** siempre hay tormenta y el protagonista **se despierta por la tormenta**. La excepción es el hospital, donde despierta por otra cosa.
> **Plan de la demo de la próxima clase:** `docs/PLAN_DEMO.md` (recorridos de M2 y M3, sistemas compartidos y teclas de debug).

---

## 0. Elementos compartidos (se hacen una vez y se reusan)

| Elemento | Dónde aparece | Etapa 0 | Qué necesita |
|---|---|---|---|
| **Barquito de madera** | M1 estante alto · M2 sube encendido en el final · M3 en las manos · M4 imagen luminosa en el fondo · Final mesita de luz | Prisma marrón | Un solo modelo con dos variantes: normal y **luminosa** (emisión cálida) |
| **Reloj parado** | M1 despertador · M2 cabaña · M3 varios · M4 camarote · Final reloj de pared | Cilindro con `Label3D` "RELOJ" | Script con modo `parado` (agujas fijas a las **3:00 am** ✅, hora del accidente)  o `en marcha` (Final). En ambos modos hace tic-tac al ritmo del bip |
| **Luna** | Ventanas de M1 y M3 · cielo de M2 y M4 | Esfera emisiva | Billboard o esfera lejana; las nubes la tapan y destapan |
| **Tormenta** | M1 (afuera) · M2 (se acerca) · M3 (afuera, por las ventanas) · M4 (encima) | — | Lluvia (partículas), relámpagos (flash de luz fría) y truenos con retardo. Intensidad configurable por escena |
| **Agua / goteo** | M1 techo · M3 charcos, paredes y canilla · M4 cubierta | Esfera chica que cae | Gota con sonido 3D seco (capa amenaza) |
| **Ritmo del bip** | Tic-tac (M1) · ladridos (M2) · canilla (M3) · bomba de achique (M4) · monitor (Final) | — | **Un único pulso global** (BPM en `config/`) que siguen todos estos sonidos |
| **Ventana con exterior falso** | M1, M3, Final | Plano con color | Plano detrás del vidrio (cielo, luna, lluvia o día) |
| **Player** | Todas | ✅ existe | Tiene que poder **quedar sin control** durante las cinemáticas |
| **NPC simple** | Padre, perro, hija, compañero | Cápsula de color + `Label3D` | Posición, mirar al jugador y un punto de donde sale su voz. Sin IA |
| **Pasajes entre memorias** ✅ (reemplaza las transiciones en negro) | Entre todas las memorias (CL-062): M1 → M2, M2 → M3, M3 → M4 (en silencio) y M4 → despertar (bajando por el agua hacia la luz, CL-063) | `scenes/passages/`: mar quieto (el océano de la M4 casi sin olas), cielo negro absoluto, una luz lejana que no se sabe qué es | Se camina hacia la luz; las voces del hospital suenan a medida que se avanza (📝 textos provisorios, subtítulos) y mientras hablan se encienden dos luces cálidas grandes y tenues arriba a los costados del jugador, que lo acompañan: las luces del presente. Su brillo sigue el volumen de la voz, como la luz de un parlante, y es lo que deja ver el agua. ❓ ABIERTO: si M3 → M4 también tiene pasaje (hoy es negro sin voces) |

---

## 1. Memoria 1 — La habitación de la abuela ✅

**Escena:** `scenes/memories/m1_habitacion/`. Noche, tormenta afuera, cálido. Degradación mínima.

### Espacio
| Elemento | Rol | Etapa 0 |
|---|---|---|
| Habitación de madera, chica (📝 4 × 4 m, techo de 2,6 m) | OBL | Caja de `CSGBox3D` |
| Puerta de salida | OBL | Caja; se abre o desaparece al resolver ❓ |
| Ventana (luna + tormenta afuera) | AMB | Hueco con plano azul oscuro y esfera de luna |
| Mancha de humedad en el techo + goteo | AMB | Decal o plano oscuro + gota |

### Muebles y props
| Elemento | Rol | Etapa 0 |
|---|---|---|
| Cama con frazada tejida | AMB | Caja |
| **Estante alto con el barquito** (fuera de alcance: **no** es agarrable) | OBL | Caja a 📝 2,1 m + prisma |
| Mesa de luz con **despertador parado** | AMB | Caja + reloj compartido |
| Lámpara de mesa (fuente de luz cálida principal) | OBL | Cilindro + `OmniLight3D` |
| Juguetes de chico | AMB | 3–4 cubos chicos |
| **Repisa de los juguetes** (casilleros del puzzle) | OBL | ✅ Repisa con 5 `PlacementSlot` numerados |
| **Papel de la abuela con la canción** | OBL | ✅ Papel clavado sobre la cama (`Label3D`) |

### Objetos del acertijo (agarrables, `PuzzlePiece`) ✅
La abuela le pide que ordene los juguetes y le deja la canción de cuna en un papel para recordar el orden.

| Orden | Verso | Objeto |
|---|---|---|
| 1 | Cuando el espejo del sol se asomó a mirar el mar | Luna |
| 2 | los hilos volvieron llenos | Red |
| 3 | Un muro de espuma blanca se levantó a saludar | Ola |
| 4 | y el hierro que nunca flota le enseñó a descansar | Ancla |
| 5 | Mientras la torre que no duerme lo llamaba sin cesar | Faro |

**Distractor:** barco. Total: **6 objetos** agarrables (5 correctos + 1 distractor). El pescador aparece nombrado en el poema pero no es un juguete: es el propio protagonista (decisión CL-012; marea y pescador fueron sacados del puzzle).

#### El barquito: el juguete favorito ✅
El barco **no** sirve para el orden: es un distractor más. El barquito que le talló el abuelo está en el estante alto (2,1 m), **fuera de alcance, y no se puede agarrar**.
1. Al resolver el puzzle la puerta se abre y el jugador sale **sin condiciones**: no hay barrera en el umbral.
2. El barquito del estante se enciende con luz cálida al resolver, pero sigue fuera de alcance.
Intención narrativa: el barquito queda como un recuerdo que no se puede tocar (el vínculo se recupera en las memorias siguientes).

Figuras (36 cm, escala de nene): están en `scenes/interaction/figures/` (ver `docs/FIGURAS_M1.md`). La `ola` y la `luna` usan modelos 3D externos (`assets/models/m1_figuras/`); el resto se arma con primitivas. Se colocan apuntando al casillero con la mira.

### Luz
- **Cálida:** la lámpara de mesa (dominante).
- **Fría:** relámpagos y el reflejo de la ventana.
- **Al resolver:** el barquito se enciende (luz cálida propia).

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Canción de cuna tarareada por la abuela | Recuerdo (eco, sin posición) | — |
| Lluvia y truenos | Amenaza | Ventana (3D) |
| Goteo del techo | Amenaza | Punto de la mancha (3D) |
| Tic-tac del despertador | Amenaza, al ritmo del bip | Mesa de luz (3D) |
| Voz de la mamá al resolver (*"¡Muy bien, mi amor!"*) | Recuerdo | — |
| Error: golpe grave, crujido, goteo más cerca | Amenaza | Puerta (3D) |
| Error: agua que se filtra bajo la puerta ✅ (visual, ver tareas) | Amenaza | Puerta |


### 🔧 TAREAS TEMPORALES M1 (decididas 2026-10-08) — borrar este bloque cuando estén todas hechas
> Para Claude Code. Al terminar cada una: tachala (`~~...~~`), sumá la entrada al `CHANGELOG.md` y probá recorriendo el camino del jugador (no teletransportes). Cuando estén todas, borrá el bloque entero.

- [x] ~~**T1. Sacar el pescador.**~~ Hecho: se sacaron también la marea (difícil de representar). Quedan 6 objetos. El poema no cambia.
- [ ] **T2. Hora del accidente = 3:00 am.** El reloj compartido (`Reloj parado`) toma la hora de un `@export` en un Resource de `config/` (hora y minuto), con 3:00 por defecto. El despertador de M1 la usa. Que M2, M3, M4 reutilicen el mismo valor cuando se arme su reloj. El reloj del Final (en marcha) no la usa.
- [ ] **T3. Agua bajo la puerta al equivocarse.** En el evento `failed` de `memory_1_room.gd`, un charco finito (placeholder: plano/`CSGBox3D` azul oscuro, semitransparente) crece desde el hueco de la puerta hacia adentro con un tween. 📝 Propuesta (confirmar con Facu si no gusta): cada error lo agranda un poco y al resolver el puzzle se seca o deja de crecer. Valores (tamaño por error, tiempo, color, opacidad) en `memory_1_settings.tres`. Sin colisión y sin castigo. Etapa 2: reemplazar por shader de agua.
- [ ] **T4. Docs.** Actualizar `docs/ELEMENTOS_ESCENAS.md` si algo de lo anterior cambia al implementarlo, y anotar la decisión en el changelog (ya existe CL-012 con el porqué).
- [x] **Confirmado, sin cambios:** valores de nene (figuras de 36 cm, cámara a 1,1 m, caminar 3,2, correr 5,0, salto 4,0). "Por el momento está bien así".

### Sistemas que pide
- `piece_id` en `PickupObject` + script de puzzle de secuencia que valide qué pieza hay en cada `PlacementSlot`.
- Evento de puzzle resuelto: ilumina el barquito, suena la voz, se habilita la salida.
- `ItemGate` (`scripts/world/item_gate.gd`): barrera en el umbral que no deja salir hasta agarrar un objeto y avisa con la señal `blocked`. ✅ Implementado (M1 ya no lo usa: se mantiene para M2).
- Reacción al error (sin castigo, sube la tensión). ✅ Incluye agua visible que se filtra por debajo de la puerta.

---

## 2c. Memoria 2 de Mica — El lago de noche: remar tras el padre ✅ (CL-054)

**Escena:** `scenes/memories/m2_remos/m2_remos.tscn` ✅. Atardecer que pasa a tormenta. Convive con la M2 del río (sección 2): no está en la secuencia, se usa de referencia y de fuente de sonido y clima para la M2 híbrida. Sus scripts se llaman `remos_*` / `Remos…`.

- **Jugador:** bote propio, un remo por tecla (A/D), HUD con las teclas, cámara a la altura de los ojos, balanceo con las olas.
- **Padre:** bote adelante con farol y resplandor visible de lejos; espera si te alejás, acelera si lo alcanzás; habla con subtítulos (voz provisoria).
- **Camino:** 12 puntos, rocas, troncos, palos, boyas con luz, bancos de niebla, cabaña con muelle al final.
- **Tormenta:** olas, cielo, niebla, lluvia, rayos y audio suben con el avance. Ola gigante al ~84 %, vuelco, buceo con audio apagado y latido, rescate con luz y mano del padre, barquito de juguete.
- **Audio:** 37 OGG en `assets/audio/m2_remos/` (remos, agua, viento, lluvia, truenos, ola, vuelco, latido, voces provisorias).
- **Sistemas:** `Memory2Boats`, `RemosBoat`, `RemosFatherBoat`, `RowCourse`, `RowObstacle`, `LakeWater`, `LakeScenery`, `StormAudio`, `RowHud`, `WakeUpIntro`, `FlashbackOverlay`, `LightningController`, `DebugTools`.
- ❓ Voz real del padre, sentido de giro, texto final de diálogos.

---

## 2. Memoria 2 — El lago y el río ✅

**Escena:** `scenes/memories/m2_lago/m2_lago.tscn` ✅ greybox jugable (CL-034, reemplaza a la versión de las placas de hielo de CL-031). La genera `gen_m2_rio.py` (en la nube de Claude); se puede editar a mano: las orillas salen solas de la curva del cauce. Atardecer en calma → tormenta de nieve de noche.

**Recorrido ✅:** despierta en el bote por un trueno lejano → pesca 2 peces → tira la red → llega la tormenta → la red se traba → el padre grita "¡CORTÁ LA RED, HIJO!" → evento rápido con cuchillo → huida remando detrás de la luz del padre por el río (ramas, rocas, hielo y troncos flotando, árboles que caen, tramos oscuros, rápidos, viento) → el bote se hunde (3 golpes) o el último rápido lo da vuelta → cae al agua → la linterna se hunde → oscuridad y flashbacks → sube el barquito encendido → la luz, la mano y la voz del padre → negro.

### Espacio
| Elemento | Rol | Etapa 0 |
|---|---|---|
| Lago (elipse al principio del cauce) | OBL | Shader del océano en calma (`ocean.gdshader`, olas casi nulas) |
| Río que sale del lago, con curvas | OBL | `RiverFlow` (curva + ancho + corriente + rápidos) y `RiverBuilder` (orillas con colisión, lomas, árboles, espuma) |
| **Rápidos** (2): corriente más fuerte, el bote se sacude | OBL | Rangos en `RiverFlow.rapids` + espuma |
| Zona del vuelco (último rápido) | OBL | `Area3D` `CapsizeZone` |
| **Tramos oscuros** (2): se cierra la niebla y solo se ve lo que alumbra la linterna y la luz del padre | OBL | `RiverEvents` + `config/river_events.tres` (`dark_zones`); la memoria baja niebla, cielo y luz ambiente y frena los rayos |
| Orillas nevadas, lomas, árboles y arbustos | AMB | Generado por `RiverBuilder`; árboles y arbustos PS1 de `assets/models/m2_arboles` (CL-048) |

### Props e interactivos
| Elemento | Rol | Etapa 0 |
|---|---|---|
| **Bote del protagonista** con dos remos ✅ | OBL | `RowBoat`: cada toque de tecla es una remada (mecánica de Mica, CL-055): A remo izquierdo, D remo derecho (alternar rinde más, un solo remo gira), S los dos hacia atrás. Responde rápido (la pala empuja al entrar al agua) y tiene buena velocidad máxima (inercia). Sube y baja con las olas. Lo lleva la corriente, lo empuja el viento, aguanta 3 golpes. **Modelo:** canoa PS1 (`scenes/props/canoe.tscn`, CL-047), la misma que usa el padre |
| **Caña de pescar** ✅ | OBL | Objeto en mano (`HeldItemView`) + `FishingRod` (boya, línea, pez) |
| **Red** con su soga ✅ | OBL | Plano con shader de red + `CuttableRope` (la misma soga de M4, más chica) |
| **Cuchillo** ✅ | OBL | Objeto en mano; corta con el evento rápido de M4 (`TimingQte`) |
| **Linterna del protagonista** ✅ | OBL | Atada a la proa del bote (deja las manos libres para remar) y gira hacia donde mira el jugador (hasta 60° por lado). Se prende con la tormenta; en la caída se hunde y se apaga |
| **Ramas** que salen de las orillas | OBL | Troncos con colisión (grupo `boat_hazard`) |
| **Rocas** en los rápidos | OBL | Esferas con colisión (`boat_hazard`) |
| **Hielo flotante** | OBL | `DriftingFloe` (deriva con la corriente, `boat_hazard`) |
| **Árboles que caen** (4) al acercarse el bote, del lado contrario a la línea del padre | OBL | `RiverEvents` (los arma por código; `tree_offsets`), con relámpago y "¡Cuidado, el árbol!" |
| **Troncos flotando** que aparecen adelante del bote y bajan con la corriente | OBL | `RiverEvents` (pool de troncos; se corren de costado si el bote los toca) |
| **Barquito** (aparece encendido en el final) ✅ | OBL | Prisma + mástil + vela + luz |
| ~~Mochila con el barquito~~ | — | **Se sacó** (no quedaba bien). El barquito solo aparece en el final |

### Personajes
| Personaje | Qué hace | Etapa 0 |
|---|---|---|
| **Padre** ✅ | Pesca en su propio bote al lado. En la huida rema adelante por la línea segura (esquiva los obstáculos), espera si el hijo se queda atrás y lo alumbra; llama ("¡Hijo! ¡Por acá!"). En el final lo rescata | `FatherBoat`: bote + farol + linterna, sigue la curva `FatherLine`. **Modelo del hombre** (`male_character`, CL-038) sentado, rema con los remos y mira al hijo (`CharacterRig` + `config/character_father_m2.tres`) |
| ~~Perro~~ | **Se sacó** con la versión de las placas | — |

### Luz
- **Atardecer en calma:** sol bajo naranja, cielo violeta, farol del padre.
- **Tormenta:** casi de noche; solo la linterna de la proa, la linterna y el farol del padre, y los relámpagos.

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Voz del padre | Recuerdo | Bote del padre (3D) |
| Agua contra el bote, remos, carrete de la caña | Recuerdo | Bote (3D) |
| Viento, trueno, nieve | Amenaza | Ambiente |
| Crujido del bote al chocar, agua que entra | Amenaza | Bote (3D) |
| Rápidos | Amenaza | Tramos del río (3D) |

### Efectos
- **Flashbacks:** cuatro fotos sacadas del juego desde el agua, de menos de un segundo, que alternan **A** (el bote del padre a lo lejos con su linterna, M2) y **B** (el pesquero a lo lejos con su reflector, M4, después de caer), con la luz en el mismo lugar de la pantalla: la misma escena en los dos recuerdos. El bote del padre, mientras el protagonista nada, está armado igual que en las fotos. 📝 Los cambios entre A y B los van a marcar los truenos. Se cambian en `config/flashbacks_m2.tres` sin tocar código.
- Nieve liviana (calma) y nieve de tormenta que el viento inclina.
- El bote se inclina con el viento y se sacude en los rápidos.

### Cinemática (sin control) ✅
El bote se da vuelta en el último rápido (los golpes lo llenan de agua pero no lo hunden: el protagonista cae al agua solo al final) → el protagonista cae al agua → **la linterna se hunde apagándose** → sale a la superficie en la tormenta y **nada medio ahogándose** (se puede mirar y moverse despacio; la cabeza se hunde cada tanto) mientras el padre lo busca a lo lejos con la linterna → **flashbacks** → en el negro, **el bote del padre llega al lado**, su linterna se enciende de a poco desde arriba y él, inclinado sobre la borda, le estira la mano (*"¡Agarrate! No te suelto."*) → negro → M3. ❓ ABIERTO: el barquito ya no aparece en este final.

### Sistemas que pide
- `RowBoat` + `RowBoatSettings` (`config/row_boat.tres`).
- `FishingRod` + `FishingBar` + `FishingSettings` (`config/fishing.tres`).
- `RiverFlow`, `RiverBuilder`, `DriftingFloe`, `FatherBoat`, `CharacterRig` (padre).
- Reutiliza: `CuttableRope`, `TimingQte`, `HeldItemView`, `WakeUpIntro`, `FlashbackOverlay`, `LightningController`, `DebugTools`.
- Acciones nuevas del InputMap: `row_left` (Q) y `row_right` (E). A, D y S usan las de caminar.

---

## 3. Memoria 3 — La casa, la madrugada antes de embarcar ✅

**Escena:** `scenes/memories/m3_casa/m3_casa.tscn` ✅ greybox jugable (CL-065). Madrugada, casi las 3:00, tormenta afuera (✅ regla de todas las memorias; antes decía "sin tormenta"). El protagonista se despierta en la mesa de la cocina por un trueno. **La más degradada:** pasillos que se estiran, cocina que se repite.

Subescenas: `house_layout.tscn` (cocina, pasillito oscuro del fondo, pasillo que se estira, rellano con tres puertas y sus umbrales) y `daughter_room.tscn` (el `room_layout.tscn` de M1 + cuarto de la hija + entrada de la casa). Raíz: `Memory3House` (`scripts/memories/memory_3_house.gd`). Valores y textos: `config/memory_3_settings.tres`.

### Recorrido implementado
1. Despierta dormido sobre la mesa de la cocina (`WakeUpIntro`, `config/wake_up_m3.tres`), con un rayo por la ventana. Aparece el barquito en la mano (`HeldItemView`, `config/held_boat.tres`); no se puede soltar.
2. La hija lo llama de lejos. Sale de la cocina al pasillo; al fondo hay un **rellano con tres puertas cerradas** ((E) Abrir). Detrás de cada una hay un tramo oscuro con un umbral invisible (`LoopPortal`).
3. **Regla del laberinto** (📝 era propuesta de PLAN_DEMO, ahora implementada así): hay 3 tramos (`good_doors`, por defecto centro → izquierda → derecha). La puerta buena tiene abajo la **luz cálida del velador**, cada tramo un poco más fuerte.
   - **Puerta buena:** aparece de nuevo al comienzo del pasillo (tramo siguiente) y la voz de la hija se oye más cerca. En el último tramo aparece en el pasillo del cuarto de la hija.
   - **Puerta mala:** aparece en el pasillito oscuro del fondo de la cocina, la voz se oye más lejos y la casa se degrada un escalón. **Se conserva el tramo ganado.**
   - El paso por el umbral conserva posición, orientación y velocidad (no hay corte ni fundido): sale de la oscuridad caminando.
4. **Degradación** (0 a 1, arranca en 0,25 y sube 0,25 por error): pasillo más largo (8 m + hasta 8 m), más charcos visibles, fotos del pasillo más borradas, luz fría más fuerte. Con la casa degradada, **el fondo del pasillo se aleja mientras se camina hacia él**.
5. El cuarto de la hija: la puerta (la de M1) tiene la luz del velador abajo; al abrirla la hija dice que no quiere que se vaya. Apuntándola: (E) Darle el barquito → *"Cuidámelo hasta que vuelva."* El barquito pasa a sus manos.
6. **La casa se estabiliza:** se seca el agua, baja la luz fría y desaparece la pared del fondo del pasillo del cuarto: se abre el camino a la entrada (bolso, campera, botas).
7. (E) Abrir la puerta de casa → sale → `MemoryExit` completa la memoria → pasaje M3 → M4 en silencio (CL-062) → M4.

Tecla **0**: en el laberinto pasa al tramo siguiente; en el cuarto abre la puerta y entrega el barquito; con la casa estable completa la memoria.

### Pasillos distintos y piernas que no responden 🧪 (CL-068)
- **Cada tramo tiene otra forma** (`segment_shapes` en `memory_3_settings.tres`): por defecto el 1.º es recto (8 m), el 2.º dobla a la izquierda y después a la derecha (`4 L 3 R 4`) y el 3.º hace zigzag (`3 R 2 L 3 L 2 R 3`). Además **cada tramo es más angosto y más bajo** (1,6 → 1,35 → 1,1 m de ancho; 2,6 → 2,4 → 2,15 m de alto): la casa se va cerrando. El último tramo recto es el que se estira.
- **Piernas que no responden** (`DreamSettings`, grupo "Piernas que no responden"): pasada una parte del pasillo, mientras empuja hacia adelante, a veces las piernas se traban: el personaje se frena en seco, la cámara tiembla y, si sigue empujando, el pasillo lo arrastra despacio hacia atrás. Aparece una línea ("Quiere avanzar y no puede.").

### Guía por el oído y fotos que se repiten 🧪 (CL-067)
- Las tres puertas del rellano están **más separadas** (2,5 m entre sí) y **la voz de la hija suena detrás de la puerta buena** (`AudioStreamPlayer3D`), así se puede elegir también por el oído. Con la casa más degradada se oye más bajo. Hoy suena un placeholder (la cajita musical de la M2): falta grabar la voz (`voice_stream` en `memory_3_settings.tres`).
- ❓ ABIERTO: la regla de audio dice que la capa recuerdo "no viene de ningún lugar"; esta voz sí viene de un lugar (la puerta). Confirmar con el equipo si es la excepción de la M3.
- **Fotos del pasillo:** la misma foto se repite a lo largo de las dos paredes; cuanto más adentro, más borrosa (desenfoque, doble exposición, sin contraste) y más torcida. Como el pasillo se estira, aparecen más fotos, cada vez más borradas.

### Efectos de sueño 🧪 (experimento, CL-066)
Para que la M3 se sienta soñada y no tan real. Siguen a la degradación de la casa (más errores = más sueño) y **se apagan cuando la casa se estabiliza** (la despedida es lo real). Cada uno se prende y apaga por separado en `config/dream_m3.tres` para compararlos:
- **Imagen:** ondula, los bordes se desenfocan y separan sus colores, doble imagen tenue, esquinas oscuras, colores apagados y fríos (`dream_haze.gdshader`).
- **Cámara:** se mece de un lado al otro y el campo de visión "respira". Al acercarse al fondo del pasillo el campo de visión se abre (efecto vértigo): el fondo se ve más lejos.
- **Piernas pesadas:** cuanto más cerca del fondo del pasillo, más lento camina; correr no sirve. Sumado al fondo que se aleja, es "querer avanzar y no poder".
- **Parpadeos:** cada tanto la pantalla se va a negro un instante; en ese negro las cosas cambian de lugar aunque se las esté mirando.
- **Cosas que cambian cuando no se las mira:** la taza y los juguetes se corren o giran (las fotos del pasillo se tuercen solas con el borroso, ver CL-067). Al volver a la cocina por una puerta mala, algo ya no está donde estaba.
- **El pasillo cambia a tus espaldas** (CL-070): si pasa un rato sin mirar hacia atrás, el camino recorrido aparece cerrado por una pared a unos metros de su espalda; cuando deja de mirarla, desaparece (y puede volver a aparecer en otro lugar). Nunca se cierra delante ni cerca de una esquina (`HallwayDeadEnd`).
- **Bajo el agua (sonido)** (CL-070): todo se oye cada vez más apagado (sin agudos) y con eco, como con la cabeza sumergida. Se pone en el bus Master solo mientras sueña y se saca al terminar. ❓ Pasos con eco: no hay sonido de pasos todavía.
- **Estela al girar** (CL-070): al girar la cámara la imagen deja un rastro que tarda en alcanzarlo (`dream_haze.gdshader`).
- **Agua que sube** (CL-070): una lámina de agua oscura sobre el piso de la cocina, el pasillito del fondo y el pasillo; sube despacio con la degradación, se mece sola y baja cuando la casa se estabiliza (`RisingWater`, `dream_water.gdshader`). Los charcos siguen como antes.

### Espacio
| Elemento | Rol | Etapa 0 |
|---|---|---|
| **Habitación de M1 redecorada** (ahora cuarto de la hija) | OBL | ✅ Se reutiliza `room_layout.tscn` de M1 (su salida queda apagada) |
| Pasillo con fotos familiares desdibujadas (la abuela, el padre) | OBL | ✅ `BendingHallway` (CL-068) + `RepeatingPhotos`: la misma foto repetida en las dos paredes, cada vez más borrosa y torcida hacia el fondo (CL-067). Foto genérica por shader hasta tener la real (`photo_texture`) |
| Cocina (se repite) | OBL | ✅ Caja con mesa, mesada, heladera; las puertas malas vuelven acá |
| Puertas que llevan siempre al mismo lugar | OBL | ✅ 3 puertas + `LoopPortal` en tramos oscuros |
| Entrada con la puerta de salida | OBL | ✅ Detrás del pasillo del cuarto; se abre al estabilizarse |
| Charcos en el piso, paredes húmedas | AMB | ✅ Charcos (planos oscuros) según la degradación · paredes húmedas ❓ etapa 2 |

### Props
| Elemento | Rol | Etapa 0 |
|---|---|---|
| **Barquito en las manos del protagonista** | OBL | ✅ Prisma + mástil + vela en `HeldItemView` |
| Cama chica con dibujos, juguetes de nena | AMB | ✅ Cajas |
| El mismo estante alto, ahora **vacío** | AMB | ✅ Mismas medidas que en M1 |
| Bolso de viaje listo en la entrada | AMB | ✅ Caja |
| Campera de pesca y botas | AMB | ✅ Cajas |
| Taza de café en la cocina | AMB | ✅ Cilindro |
| Ventana con la luna | AMB | ✅ Cocina y cuarto (el del layout de M1) |
| Relojes parados | AMB | ✅ Cocina y mesa de luz, con `Label3D` "3:00" (falta el reloj compartido, T2 de M1) |
| Canilla que gotea al ritmo del bip | AMB | Cilindro con cartel; gota y audio ❓ etapa 2 |
| Velador del cuarto de la hija (**única luz cálida**) | OBL | ✅ `OmniLight3D` cálida (y su luz bajo las puertas buenas) |

### Personajes
| Personaje | Qué hace | Etapa 0 |
|---|---|---|
| **Hija** (~7 años, cara borrosa) | Espera en su cuarto. Recibe el barquito | ✅ Cápsula chica + esfera semitransparente sobre la cara (`StaticBody3D` para apuntarla) |

### Luz
- Cálida solo en el velador (y en la franja bajo la puerta buena, que es "su" luz). El resto, luz fría azul verdosa (más fuerte que en M1 y M2, y sube con la degradación).
- Rayos por las ventanas (`LightningController`, `config/lightning_m3.tres`).

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Voz de la hija (más lejana cuando el jugador se pierde) | Recuerdo | Subtítulos de etapa 0 (`closer_lines` / `farther_lines`) |
| *"Cuidámelo hasta que vuelva."* | Recuerdo | Subtítulo de etapa 0 (lo dice el protagonista) |
| Goteo, agua en las paredes, canilla | Amenaza | Puntos concretos (3D) · ❓ etapa 2 |

### Cinemática (sin control) 📝
✅ Sale por la puerta de su casa → **pasaje en silencio** (CL-062: el mar negro y la luz, sin voces del hospital, como se había decidido para este corte) → empieza M4 en el camarote.

### Sistemas que pide
- ✅ Laberinto que se repite: `LoopPortal` (umbral que lleva al jugador conservando posición y orientación) + `BendingHallway` (pasillo que dobla y se estira, con una forma distinta por tramo).
- ✅ Objeto sostenido (el barquito en la mano) y "entregar" al interactuar con la hija.
- ✅ Al entregar: la casa se estabiliza y se habilita la salida.

### Pendiente ❓
- Textos de la hija y del protagonista: son **provisorios** (📝), salvo *"Cuidámelo hasta que vuelva."*. Confirmarlos con el equipo.
- Voz real de la hija con `AudioStreamPlayer3D` (más fuerte/cerca según el tramo), goteo de la canilla al ritmo del bip.
- Probar a mano el largo del pasillo, la velocidad a la que se aleja y la cantidad de tramos.

---

## 4. Memoria 4 — El accidente ✅

> ### 🔄 Cambio de diseño (CL-014): cubierta, sogas y ola gigante
> El prototipo de M4 se armó con **una sola escena de cubierta** (`scenes/memories/memory_4.tscn`) en lugar de camarote + escalera + fondo. Lo que quedó implementado:
> - **Cortar sogas con hacha:** 3 sogas (izquierda, centro, derecha). Hay que acertar un **quick event** (barra con marcador que va y viene, tecla `interact`) 2 veces por soga. Errar nunca es game over: el barco se inclina un poco más y se vuelve a intentar. Cada soga hace la zona más chica y el marcador más rápido.
> - **Tripulación (placeholders):** al cortar la última soga gritan *"¡LO LOGRAMOS!"* y justo después *"¡CUIDADO, NOMBRE!"* (`protagonist_name` en `config/memory_4_settings.tres`, ❓ falta el nombre).
> - **La ola gigante** (`GiantWave` + `giant_wave.gdshader`): una malla que se deforma en el shader desde una ola baja, a una pared, a una ola que **rompe hacia el jugador** (`curl`). Avanza acelerando y lo cubre. Todo configurable en `Memory4Settings`.
> - **Luz:** lo único que ilumina son los **rayos** (`LightningController`) y una luz muy lejana del barco. Entre rayo y rayo, casi negro.
> - **Después de la ola:** el protagonista emerge, flota; el barco se aleja mirando para otro lado y su reflector barre otras partes del mar sin verlo. Luego se hunde a oscuridad total (talasofobia).
> - **Final de la memoria:** una luz que crece desde el fondo = **helicóptero** ✅ (reemplaza al barquito luminoso del fondo). ❓ Falta confirmar con el equipo si además aparece el barquito.
> - **CL-015 — Barco pesquero grande:** unos 39 m, **6 sogas (3 por banda)** sobre huecos de la baranda, **suelo resbaladizo** (el barco cabecea y empuja al jugador, `DeckSlip` + `config/player_settings_deck.tres`) y **costados abiertos**: si cae al agua → negro con sonido de chapuzón (`assets/audio/m4_fall_splash.wav`, placeholder) y vuelve a bordo como un fallo más. El evento rápido (`E`) se achica y acelera con cada soga. Lluvia en manchas borrosas, que cerca del barco se ve apenas y lejos casi no se ve. Mirando hacia abajo en el agua la pantalla se va a negro (`abyss.gdshader`).
> - **Pendientes ❓:** sonido (capas Amenaza/Afuera), modelos finales, nombre del protagonista, control del QTE (hoy `E`), mecánica de frío/input lag **descartada** por ahora, camarote/reloj de las 3:00 am no incluidos en este prototipo.

**Escena:** `scenes/memories/m4_pesquero/`. Noche, tormenta fuerte. **Sin degradación:** la más nítida y real.

### Espacio
| Elemento | Rol | Etapa 0 |
|---|---|---|
| **Camarote** (litera, reloj parado) | OBL | Caja chica |
| Pasillo/escalera a cubierta | OBL | Rampa |
| **Cubierta** mojada que se inclina con cada ola | OBL | Plano sobre un nodo que se balancea |
| Cabina iluminada (luz cálida) | AMB | Caja + luz |
| Mar picado alrededor | OBL | Plano oscuro animado |
| Faro lejano en la costa (luz cálida) | OBL | Esfera emisiva lejana |
| **Fondo del mar** para el descenso | OBL | Volumen oscuro + luz al fondo |

### Props e interactivos
| Elemento | Verso que representa | Rol | Etapa 0 |
|---|---|---|---|
| Luna entre las nubes (se ve al salir a cubierta) | 1. La luna asomada | OBL | Compartido |
| **Red llena** de pesca: sostenerla | 2. La red llena | OBL | Caja + interacción de **mantener** |
| Tomar el turno del compañero | 3. El pescador sale a tirar | OBL | Diálogo / trigger |
| Sogas para atar cajones sueltos | (tareas) | OBL | `PickupObject` + `PlacementSlot` con bloqueo |
| Palancas y guinche: girar y sostener | (tareas) | OBL | Cilindros con interacción de mantener |
| Timón | (tareas) | AMB ❓ | Cilindro |
| **La ola** | 4. La ola | OBL | Evento + cinemática |
| Ancla y cadena | 5. El hundimiento | OBL | Cilindros; acompaña la caída |
| **Malacate del ancla en popa** ✅ (CL-045): después de las sogas hay que subir el ancla apretando (E) en la manivela; si se afloja, baja | (tareas) | OBL | `AnchorWinch` (`scenes/props/anchor_winch.tscn`): soporte y manivela con modelo, ancla provisoria con formas simples |
| **Luz del faro en el fondo + imagen del barquito luminosa** | 6. El faro | OBL | Luz + barquito luminoso |
| Cajones y equipo sueltos, salvavidas | — | AMB | Cajas |

### Personajes
| Personaje | Qué hace | Etapa 0 |
|---|---|---|
| **Compañero** (tripulante) ✅ | Al timón, detrás de las ventanas de popa de la cabina: mira al jugador y grita durante la tormenta (levanta el brazo) | **Modelo del hombre** (`male_character`, CL-038) con `CharacterRig` + `config/character_crew_m4.tres` |

### Luz
- Cálida solo en la cabina y el faro lejano. El resto: oscuridad + relámpagos fríos.
- **Luces del hospital en el cielo** (CL-040, CL-041): con cada rayo, mirando hacia arriba, se ven 6 paneles amarillos grandes (2 columnas x 3 filas) como los del techo del hospital. `HospitalLights` + `config/hospital_lights_m4.tres`.
- Bajo el agua: todo azul verdoso, salvo la luz del faro.

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Viento, olas, crujidos del casco, golpes de agua | Amenaza (muy presente) | Puntos alrededor del jugador (3D) |
| Gritos del compañero | Amenaza | Compañero (3D) |
| Bomba de achique, al ritmo del bip | Amenaza | Punto en cubierta (3D) |
| Canción de cuna, muy tenue, al hundirse | Recuerdo | — |

### Cinemáticas (sin control) 📝
- ✅ **Despertar en el camarote** (viene de M3): se levanta de la litera, lo despierta la tormenta y lo llaman porque lo necesitan en cubierta (el tripulante grita desde afuera). El jugador sale corriendo por el pasillo; la puerta da a la pasarela de arriba de la escalera, donde ocurre el relámpago largo de CL-025 📝.
- La ola y la caída al agua.
- El descenso: ❓ ¿controlado (hundirse lento hacia la luz) o cinemática?

### Sistemas que pide
- Balanceo del barco (afecta cubierta, objetos sueltos y cámara).
- Interacción de **mantener** (sostener E un tiempo) para red, palancas, timón.
- Secuencia de tareas en orden (cada una = un verso).
- Modo submarino del player (gravedad baja, movimiento lento, visibilidad reducida).

---

## 5. Despertar ✅

**Escena:** `scenes/memories/awakening.tscn` ✅ greybox (CL-060). Día, **blanco**, calma total, sin agua. Todo suena seco.

| Elemento | Rol | Etapa 0 |
|---|---|---|
| Habitación de hospital | OBL | Caja blanca |
| Cama (el jugador está acostado: solo mira alrededor ❓) | OBL | Caja |
| **Monitor cardíaco** (el bip real) | OBL | Caja + audio 3D |
| Ventana con luz de día | OBL | Plano blanco + `DirectionalLight3D` |
| **6 luces de techo** (2 x 3), las mismas que se ven en el cielo con los rayos de la M4 (CL-040) | OBL | Paneles con el mismo brillo que `HospitalLights` |
| **Reloj de pared en marcha** | OBL | Reloj compartido en modo "en marcha" |
| **Hija** al lado de la cama | OBL | Cápsula chica |
| **Barquito en la mesita de luz** (último plano) | OBL | Prisma |
| Ruidos cotidianos de hospital | AMB | Ambiente |

**Voz:** la hija, clara y seca: *"Papá... te traje esto, lo cuidé como me dijiste antes de irte."*
**Final:** último plano en el barquito → ❓ ¿créditos, fundido a blanco, vuelta al menú?

---

## 6. Dependencias de producción
- **Los flashbacks de M2 dependen de M4.** Se arman cuando M4 tenga greybox y se reemplazan cuando tenga arte.
- **M3 reutiliza el layout de M1.** M1 se arma primero y como subescena separable (`room_layout.tscn`).
- **El barquito, el reloj, la luna, la tormenta y el pulso del bip** son compartidos: se hacen una vez, antes de que dos escenas los necesiten.

## 7. Pendientes ❓
1. ~~Puzzle de M1~~ ✅ 5 piezas (luna, red, ola, ancla, faro), 1 distractor (barco) y el papel de la abuela con la canción. Total: 6 objetos agarrables. La `ola` y la `luna` usan modelos 3D externos.
2. ~~M1: dónde se ordena y dónde está el acertijo~~ ✅ repisa de los juguetes + papel de la abuela.
3. ~~**M1:** ¿cómo sale el jugador?~~ ✅ Al resolver se abre la puerta y se sale sin condiciones (sin `ItemGate`). El barquito del estante se enciende pero queda fuera de alcance.
4. ~~M1: quién felicita~~ ✅ la mamá.
5. ~~La hora del accidente~~ ✅ **3:00 am** (todos los relojes).
6. ~~**M2:** ¿la mochila con el barquito se ve en escena?~~ ✅ Se sacó la mochila (CL-034): el barquito solo aparece encendido en el final.
7. ~~**M3 → M4:** ¿corte directo o transición en negro con voces?~~ ✅ Sale por la puerta de casa → negro → M4 empieza en el camarote.
8. **M4:** ¿el descenso es controlado o cinemática? ¿Hay timón?
9. **Final:** ¿el jugador puede mover la cámara? ¿Qué pasa después del último plano?
