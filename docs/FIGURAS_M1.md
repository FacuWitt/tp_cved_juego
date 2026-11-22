# Figuras de la Memoria 1 (juguetes de madera)

Las 6 figuras son juguetes del cuarto del nene. **Desde CL-073 todas usan modelos 3D**
(`assets/models/m1_juguetes/`), generados por el equipo a partir de imágenes de referencia y
reducidos a estilo PS1 con `tools/ps1ify` (unos 2.000 triángulos y una textura de color de 256 px).
Las figuras de primitivas y los modelos anteriores (`assets/models/m1_figuras/`) quedan sin usar.

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Escena de cada figura | `scenes/interaction/figures/<piece_id>.tscn` |
| Piezas dentro del cuarto | `scenes/memories/m1_habitacion/puzzle.tscn` |
| Orden correcto | `config/memory_1_puzzle.tres` |

| Pieza | Archivo | Qué representa |
|---|---|---|
| `luna` | `figures/luna.tscn` | Globo lunar con soporte (`m1_juguetes/luna.glb`) |
| `red` | `figures/red.tscn` | Red de pesca con mango (`m1_juguetes/red.glb`) |
| `ola` | `figures/ola.tscn` | Ola con espuma (`m1_juguetes/ola.glb`), girada para que se vea la curva de perfil |
| `ancla` | `figures/ancla.tscn` | Ancla de hierro (`m1_juguetes/ancla.glb`) |
| `faro` | `figures/faro.tscn` | Faro de primitivas (ya no se usa en el acertijo desde CL-071) |
| `sirena` | `figures/sirena.tscn` | Sirena de pelo rojo (`m1_juguetes/sirena.glb`) |
| `barco` | `figures/barco.tscn` | Pesquero rojo de juguete (`m1_juguetes/barco_de_juguete.glb`, distractor). El mismo modelo es el barquito del estante alto |

> Antes había 8 figuras con dos distractores más (`marea` y `pescador`); se sacaron
> del puzzle (ver CL-011, CL-012 y CL-034).

## Cómo está armada cada figura

```
RigidBody3D  (script PuzzlePiece, piece_id, label_text)
├── Visual (Node3D)
│   └── Modelo  (instancia del .glb, escalada y centrada)
└── CollisionShape3D  (caja invisible del tamaño del modelo, mínimo 12 cm de profundidad)
```

- `piece_id` tiene que coincidir con `config/memory_1_puzzle.tres`.
- El `CollisionShape3D` es una caja del tamaño del modelo (la dimensión mayor mide 36 cm); en las
  figuras planas (red, ancla) tiene al menos 12 cm de profundidad para que se agarren y se paren bien.
- Ya no tienen cartel (`Label3D`): con el modelo real se reconocen solas.
- `Visual` es el nodo que el script aplasta al encastrar (`settle_squash`).
- Los modelos vienen centrados en el origen: el centro de la caja es el centro del modelo.
- El frente de cada modelo mira a +Z; en la alfombra, +Z apunta a la pieza.

## Cómo reemplazar o agregar un modelo `.glb`

1. Reducirlo: `cd tools/ps1ify && npm install && node ps1ify.mjs original.glb salida.glb 2000 256`.
2. Copiar `salida.glb` a `assets/models/m1_juguetes/` y abrir el proyecto para que Godot lo importe.
3. En la escena de la figura, cambiar el `.glb` del nodo `Modelo` y ajustar la escala para que la
   dimensión mayor mida **0,36 m**: `escala = 0.36 / mayor_dimension_del_modelo`.
4. Ajustar la caja de colisión al tamaño escalado.
5. No tocar `piece_id`.

## Cómo ajustar una figura

- Para mover una pieza dentro del cuarto: editá su `position` en `puzzle.tscn`.
- Para cambiar tamaño o forma: editá los nodos dentro de `Visual` en la escena de la figura.
- Para que una figura distinta sea la correcta: cambiá `config/memory_1_puzzle.tres`
  (los `piece_id`, en orden).
