# ELEMENTOS POR ESCENA

Inventario de todo lo que hay que construir o conseguir para cada escena del juego.

> Estados: ✅ definido · 📝 propuesta · ❓ abierto
> **Etapa 0** = el placeholder genérico que se usa ahora (cubos, cápsulas, `Label3D` con el nombre). **Etapa 3** = el asset final (modelo, textura, sonido).
> Columna **Rol**: **OBL** = obligatorio para el flujo (sin esto no se puede terminar la escena) · **AMB** = ambientación (se puede sumar después).

---

## 0. Elementos compartidos (se hacen una vez y se reusan)

| Elemento | Dónde aparece | Etapa 0 | Qué necesita |
|---|---|---|---|
| **Barquito de madera** | M1 estante alto · M2 mochila · M3 en las manos · M4 imagen luminosa en el fondo · Final mesita de luz | Prisma marrón | Un solo modelo con dos variantes: normal y **luminosa** (emisión cálida) |
| **Reloj parado** | M1 despertador · M2 cabaña · M3 varios · M4 camarote · Final reloj de pared | Cilindro con `Label3D` "RELOJ" | Script con modo `parado` (agujas fijas a las **3:00 am** ✅, hora del accidente)  o `en marcha` (Final). En ambos modos hace tic-tac al ritmo del bip |
| **Luna** | Ventanas de M1 y M3 · cielo de M2 y M4 | Esfera emisiva | Billboard o esfera lejana; las nubes la tapan y destapan |
| **Tormenta** | M1 (afuera) · M2 (se acerca) · M4 (encima) | — | Lluvia (partículas), relámpagos (flash de luz fría) y truenos con retardo. Intensidad configurable por escena |
| **Agua / goteo** | M1 techo · M3 charcos, paredes y canilla · M4 cubierta | Esfera chica que cae | Gota con sonido 3D seco (capa amenaza) |
| **Ritmo del bip** | Tic-tac (M1) · ladridos (M2) · canilla (M3) · bomba de achique (M4) · monitor (Final) | — | **Un único pulso global** (BPM en `config/`) que siguen todos estos sonidos |
| **Ventana con exterior falso** | M1, M3, Final | Plano con color | Plano detrás del vidrio (cielo, luna, lluvia o día) |
| **Player** | Todas | ✅ existe | Tiene que poder **quedar sin control** durante las cinemáticas |
| **NPC simple** | Padre, perro, hija, compañero | Cápsula de color + `Label3D` | Posición, mirar al jugador y un punto de donde sale su voz. Sin IA |
| **Transiciones en negro** | Entre todas las escenas | Pantalla negra + texto con la línea | Voces del hospital, cada vez más cercanas; resplandor rojizo que late |

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

**Distractor:** barco. ✅ Es el único. El pescador no es un objeto (el poema lo nombra porque es el protagonista) y la marea se descartó por ser difícil de representar como objeto. Total: **6 objetos** agarrables (5 correctos + el barco).

#### El barco: el juguete favorito ✅
El barco **no** sirve para el orden, pero el nene no se va sin él:
1. El barco está suelto en el cuarto (Etapa 0: junto a la cama, sobre la mesa de luz).
2. Al resolver el puzzle la puerta se abre. El jugador, naturalmente, intenta salir.
3. Un `ItemGate` (barrera física + zona de aviso) en el umbral lo frena y el protagonista dice: *"No me puedo ir sin mi juguete favorito."* (`gate_line` en `memory_1_settings.tres`).
4. El jugador vuelve a buscar el barco. Al agarrarlo, el paso queda libre para siempre (aunque lo suelte).
5. Si agarró el barco antes de resolver, no hay aviso: ya lo lleva.
Intención narrativa: refuerza el vínculo con el barquito (el cable a tierra) desde la primera memoria.

Etapa 0: cubos grandes (36 cm, escala de nene) con `Label3D` arriba. Se colocan apuntando al casillero con la mira.

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
- `ItemGate` (`scripts/world/item_gate.gd`): barrera en el umbral que no deja salir hasta agarrar un objeto (el barco) y avisa con la señal `blocked`. ✅ Implementado.
- Reacción al error (sin castigo, sube la tensión). ✅ Incluye agua visible que se filtra por debajo de la puerta.

---

## 2. Memoria 2 — El lago helado ✅

**Escena:** `scenes/memories/m2_lago/`. Atardecer → noche, frío, viento, nieve. Degradación media (niebla, la orilla parece lejos).

### Espacio
| Elemento | Rol | Etapa 0 |
|---|---|---|
| Orilla con nieve | OBL | Plano blanco |
| Lago (agua helada) | OBL | Plano gris azulado + `KillZone` (reaparecer) |
| **Placas de hielo** de distintos tamaños: se mueven, se inclinan, resbalan, se agrietan | OBL | Cajas planas con script |
| Cabaña de pesca con **farol en la puerta** (única luz cálida) | OBL | Caja + `OmniLight3D` |
| Muelle de madera | AMB | Cajas en fila |
| Niebla en los bordes | AMB | `FogVolume` / fog del entorno |

### Props
| Elemento | Rol | Etapa 0 |
|---|---|---|
| Bote del padre amarrado, con cadena y ancla | AMB | Caja + cilindros |
| Redes colgadas, cañas | AMB | Planos / cilindros finos |
| **Radio a pilas** (alerta de tormenta) | AMB | Cubo chico + fuente de audio |
| Reloj de la cabaña parado | AMB | Reloj compartido |
| **Mochila con el barquito adentro** | AMB ❓ (¿se ve? ¿la lleva el jugador?) | Cubo |
| Luna detrás de las nubes | AMB | Compartido |

### Personajes
| Personaje | Qué hace | Etapa 0 |
|---|---|---|
| **Perro** | Huye hacia el lago y espera sobre una placa lejana, ladrando | Cápsula chica marrón |
| **Padre** | Con linterna. Aparece en el rescate | Cápsula alta + `SpotLight3D` |

### Luz
- **Cálida:** farol de la cabaña y linterna del padre.
- **Fría:** el azul del hielo y del agua (domina).

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Voz del padre, radio | Recuerdo | — |
| Crujidos del hielo, agua debajo de los pies | Amenaza | **Debajo del jugador** (3D) |
| Viento | Amenaza | Ambiente |
| Ladridos del perro, al ritmo del bip | Amenaza | Perro (3D) |

### Efectos
- **Flashbacks:** imágenes de la noche del accidente, de menos de un segundo, a pantalla completa. **Dependen de M4**: se sacan capturas de esa escena. Hace falta una opción para reducirlos (fotosensibilidad).
- Nieve (partículas).

### Cinemática (sin control) 📝
El hielo se rompe → el jugador y el perro caen al agua → la mano y la voz del padre los sacan (*"agarrate, no te suelto"*) → negro.

### Sistemas que pide
- Placas de hielo físicas: inclinación según dónde pisa, deslizamiento y grieta que avanza con un tiempo (todo configurable en `config/`).
- Control resbaloso sobre hielo (modificador de fricción del player).
- Overlay de flashbacks.
- Director de cinemáticas.

---

## 3. Memoria 3 — La casa, la madrugada antes de embarcar ✅

**Escena:** `scenes/memories/m3_casa/`. Madrugada, silencio, sin tormenta. **La más degradada:** pasillos que se estiran, cocina que se repite.

### Espacio
| Elemento | Rol | Etapa 0 |
|---|---|---|
| **Habitación de M1 redecorada** (ahora cuarto de la hija) | OBL | **Se reutiliza el layout de M1** |
| Pasillo con fotos familiares desdibujadas (la abuela, el padre) | OBL | Pasillo de cajas + planos |
| Cocina (se repite) | OBL | Caja con mesa |
| Puertas que llevan siempre al mismo lugar | OBL | Triggers que teletransportan |
| Entrada con la puerta de salida | OBL | Caja + trigger final |
| Charcos en el piso, paredes húmedas | AMB | Planos oscuros |

### Props
| Elemento | Rol | Etapa 0 |
|---|---|---|
| **Barquito en las manos del protagonista** | OBL | Prisma pegado a la cámara |
| Cama chica con dibujos, juguetes de nena | AMB | Cajas |
| El mismo estante alto, ahora **vacío** | AMB | Reutilizado de M1 |
| Bolso de viaje listo en la entrada | AMB | Caja |
| Campera de pesca y botas | AMB | Cajas |
| Taza de café en la cocina | AMB | Cilindro |
| Ventana con la luna | AMB | Compartido |
| Relojes parados | AMB | Compartido |
| Canilla que gotea al ritmo del bip | AMB | Gota + audio |
| Velador del cuarto de la hija (**única luz cálida**) | OBL | `OmniLight3D` cálida |

### Personajes
| Personaje | Qué hace | Etapa 0 |
|---|---|---|
| **Hija** (~7 años, cara borrosa) | Espera en su cuarto. Recibe el barquito | Cápsula chica |

### Luz
- Cálida solo en el velador. El resto, luz fría azul verdosa (más fuerte que en M1 y M2).

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Voz de la hija (más lejana cuando el jugador se pierde) | Recuerdo | — |
| *"Cuidámelo hasta que vuelva."* | Recuerdo | — |
| Goteo, agua en las paredes, canilla | Amenaza | Puntos concretos (3D) |

### Cinemática (sin control) 📝
Sale por la puerta → todo se oscurece → **sin transición en negro con voces**: corte directo al camarote de M4 ❓.

### Sistemas que pide
- Laberinto que se repite: zonas que teletransportan sin que se note y que cambian según el progreso.
- Objeto sostenido (el barquito en la mano) y "entregar" al interactuar con la hija.
- Al entregar: la casa se estabiliza (se apagan los loops) y se habilita la salida.

---

## 4. Memoria 4 — El accidente ✅

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
| **Luz del faro en el fondo + imagen del barquito luminosa** | 6. El faro | OBL | Luz + barquito luminoso |
| Cajones y equipo sueltos, salvavidas | — | AMB | Cajas |

### Personajes
| Personaje | Qué hace | Etapa 0 |
|---|---|---|
| **Compañero** | En el camarote o en la cubierta le pide que tome su turno; grita durante la tormenta | Cápsula |

### Luz
- Cálida solo en la cabina y el faro lejano. El resto: oscuridad + relámpagos fríos.
- Bajo el agua: todo azul verdoso, salvo la luz del faro.

### Audio
| Sonido | Capa | Fuente |
|---|---|---|
| Viento, olas, crujidos del casco, golpes de agua | Amenaza (muy presente) | Puntos alrededor del jugador (3D) |
| Gritos del compañero | Amenaza | Compañero (3D) |
| Bomba de achique, al ritmo del bip | Amenaza | Punto en cubierta (3D) |
| Canción de cuna, muy tenue, al hundirse | Recuerdo | — |

### Cinemáticas (sin control) 📝
- Despertar en el camarote (viene de M3).
- La ola y la caída al agua.
- El descenso: ❓ ¿controlado (hundirse lento hacia la luz) o cinemática?

### Sistemas que pide
- Balanceo del barco (afecta cubierta, objetos sueltos y cámara).
- Interacción de **mantener** (sostener E un tiempo) para red, palancas, timón.
- Secuencia de tareas en orden (cada una = un verso).
- Modo submarino del player (gravedad baja, movimiento lento, visibilidad reducida).

---

## 5. Despertar ✅

**Escena:** `scenes/memories/final_hospital/`. Día, **blanco**, calma total, sin agua. Todo suena seco.

| Elemento | Rol | Etapa 0 |
|---|---|---|
| Habitación de hospital | OBL | Caja blanca |
| Cama (el jugador está acostado: solo mira alrededor ❓) | OBL | Caja |
| **Monitor cardíaco** (el bip real) | OBL | Caja + audio 3D |
| Ventana con luz de día | OBL | Plano blanco + `DirectionalLight3D` |
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
1. ~~Puzzle de M1~~ ✅ 5 piezas (luna, red, ola, ancla, faro) y 1 distractor: el barco (sin marea ni pescador). El barco es además el juguete favorito que hay que llevarse para salir.
2. ~~M1: dónde se ordena y dónde está el acertijo~~ ✅ repisa de los juguetes + papel de la abuela.
3. **M1:** ¿cómo sale el jugador? ¿Se abre la puerta al resolver?
4. ~~M1: quién felicita~~ ✅ la mamá.
5. ~~La hora del accidente~~ ✅ **3:00 am** (todos los relojes).
6. **M2:** ¿la mochila con el barquito se ve en escena?
7. **M3 → M4:** ¿corte directo o transición en negro con voces?
8. **M4:** ¿el descenso es controlado o cinemática? ¿Hay timón?
9. **Final:** ¿el jugador puede mover la cámara? ¿Qué pasa después del último plano?
