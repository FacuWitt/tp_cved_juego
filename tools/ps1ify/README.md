# ps1ify

Reduce un modelo `.glb` generado (por ejemplo con una herramienta de imagen a 3D) a un juguete
con estilo PS1: unos 2.000 triángulos y solo la textura de color, chica (256 px), sin mapas de
normales ni de rugosidad. Así se hicieron los juguetes de la Memoria 1 (`assets/models/m1_juguetes/`).

```
cd tools/ps1ify
npm install
node ps1ify.mjs entrada.glb salida.glb 2000 256
```

Los dos últimos números son opcionales: triángulos objetivo y lado de la textura en píxeles.
El modelo queda centrado y en la escala original; la escala a 36 cm se pone en la escena de la
figura (ver `docs/FIGURAS_M1.md`).
