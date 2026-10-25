# Figuras de la Memoria 1 (juguetes de madera)

Las 6 figuras son juguetes de madera del cuarto del nene. La mayoría está armada
con primitivas de Godot; la `ola` y la `luna` usan modelos externos (.glb).

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Escena de cada figura | `scenes/interaction/figures/<piece_id>.tscn` |
| Piezas dentro del cuarto | `scenes/memories/m1_habitacion/puzzle.tscn` |
| Orden correcto | `config/memory_1_puzzle.tres` |

| Pieza | Archivo | Qué representa |
|---|---|---|
| `luna` | `figures/luna.tscn` | Globo lunar tallado (modelo `moon_globe.glb`) |
| `red` | `figures/red.tscn` | Red de pesca: aro, mango e hilos cruzados |
| `ola` | `figures/ola.tscn` | Ola tallada (modelo `wave_sculpture.glb`) |
| `ancla` | `figures/ancla.tscn` | Ancla con anillo, travesaño y uñas |
| `faro` | `figures/faro.tscn` | Faro con franjas rojas y linterna |
| `barco` | `figures/barco.tscn` | Barquito de juguete sobre base (distractor) |

> Antes había 8 figuras con dos distractores más (`marea` y `pescador`); se sacaron
> del puzzle (ver CL-011, CL-012 y CL-034).

## Cómo está armada cada figura

```
RigidBody3D  (script PuzzlePiece, piece_id, label_text)
├── Visual (Node3D)
│   ├── Base / Cuerpo / ...  (MeshInstance3D con primitivas)
│   └── ...
├── CollisionShape3D  (cubo de 36 cm, invisible)
└── Label3D  (nombre provisorio, encima de la figura)
```

- `piece_id` tiene que coincidir con `config/memory_1_puzzle.tres`.
- El `CollisionShape3D` es un cubo de 36 cm: se mantiene igual para que todas se agarren
  con la misma comodidad, aunque la figura visible sea más chica.
- `Visual` es el nodo que el script aplasta al encastrar (`settle_squash`).
- La `ola` y la `luna` no tienen primitivas: dentro de `Visual` tienen un hijo `Modelo`
  que instancia su `.glb`, ya escalado y apoyado (ver sección de reemplazo más abajo).
- Las figuras miden hasta 36 cm y se apoyan en `y = -0.18` (el piso del cubo).

## Materiales

Se usan 7 materiales compartidos por nombre, definidos dentro de cada escena:

| Material | Color | Uso |
|---|---|---|
| `madera` | marrón medio | cuerpos principales |
| `madera_oscura` | marrón oscuro | bases, mástiles, hilos |
| `madera_clara` | madera clara | torres, cabezas, cubiertas |
| `azul` | azul pintado | agua, olas, ropa |
| `blanco` | blanco tiza | espuma, velas, línea de pesca |
| `rojo` | rojo pintado | franjas del faro, techo |
| `amarillo` | amarillo | linterna del faro |

## Cómo reemplazar una figura por un modelo `.glb`

1. Copiar el modelo a `assets/models/m1_figuras/` y abrir el proyecto para que Godot lo importe.
2. Abrir la escena de esa figura (por ejemplo `figures/ola.tscn`).
3. Borrar los `MeshInstance3D` que están dentro de `Visual` y arrastrar el `.glb` como hijo de `Visual`.
4. Escalar el modelo para que su dimensión mayor mida **0,36 m**:
   `escala = 0.36 / mayor_dimension_del_modelo`.
5. Apoyarlo: `Model.position.y = -0.18 - min_y * escala` (con `min_y` del AABB del modelo).
6. No tocar `piece_id`, `CollisionShape3D` ni `Label3D`.
7. Anotar el crédito en `assets/models/m1_figuras/CREDITS.md` si la licencia lo pide.

## Cómo ajustar una figura

- Para mover una pieza dentro del cuarto: editá su `position` en `puzzle.tscn`.
- Para cambiar tamaño o forma: editá los nodos dentro de `Visual` en la escena de la figura.
- Para que una figura distinta sea la correcta: cambiá `config/memory_1_puzzle.tres`
  (los `piece_id`, en orden).
