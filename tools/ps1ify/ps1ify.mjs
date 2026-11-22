// Reduce un .glb generado (decenas de miles de triángulos y texturas de 2048) a un juguete PS1:
// pocos triángulos, solo la textura de color, chica, y sin mapas de normales ni de rugosidad.
// Uso: node ps1ify.mjs entrada.glb salida.glb [triangulos_objetivo] [lado_textura]
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { weld, simplify, dedup, prune, textureCompress } from '@gltf-transform/functions';
import { MeshoptSimplifier } from 'meshoptimizer';
import sharp from 'sharp';

const [, , input, output, targetArg, texArg] = process.argv;
const target = Number(targetArg || 2000);
const texSize = Number(texArg || 256);

const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
const doc = await io.read(input);
const root = doc.getRoot();

for (const mat of root.listMaterials()) {
	mat.setNormalTexture(null);
	mat.setMetallicRoughnessTexture(null);
	mat.setOcclusionTexture(null);
	mat.setEmissiveTexture(null);
	mat.setMetallicFactor(0.0);
	mat.setRoughnessFactor(0.9);
}

const countTris = () => root.listMeshes().reduce((n, m) => n + m.listPrimitives().reduce((k, p) => k + (p.getIndices() ? p.getIndices().getCount() : p.getAttribute('POSITION').getCount()) / 3, 0), 0);
const before = countTris();
await doc.transform(weld({ tolerance: 0.0001 }));
await MeshoptSimplifier.ready;
const ratio = Math.min(1, target / before);
await doc.transform(simplify({ simplifier: MeshoptSimplifier, ratio, error: 0.02, lockBorder: false }));
await doc.transform(
	prune(),
	dedup(),
	textureCompress({ encoder: sharp, targetFormat: 'png', resize: [texSize, texSize] }),
);
await io.write(output, doc);
console.log(`${input.split('/').pop()}: ${before} → ${countTris()} triángulos, textura ${texSize}px`);
