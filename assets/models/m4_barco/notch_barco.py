import numpy as np, json, struct, sys
from pygltflib import GLTF2

SRC, DST = sys.argv[1], sys.argv[2]
g = GLTF2().load(SRC)
blob = g.binary_blob()
def acc(i):
    a = g.accessors[i]; bv = g.bufferViews[a.bufferView]
    n = {'SCALAR':1,'VEC2':2,'VEC3':3}[a.type]
    dt = {5126:np.float32, 5125:np.uint32, 5123:np.uint16}[a.componentType]
    off = (bv.byteOffset or 0) + (a.byteOffset or 0)
    return np.frombuffer(blob, dtype=dt, count=a.count*n, offset=off).reshape(a.count, n).copy()
prim = g.meshes[0].primitives[0]
pos = acc(prim.attributes.POSITION); nor = acc(prim.attributes.NORMAL); uv = acc(prim.attributes.TEXCOORD_0)
idx = acc(prim.indices).reshape(-1)
tris = idx.reshape(-1, 3)
print('verts', len(pos), 'tris', len(tris))

# Muescas: (x_centro, mitad_ancho, y_piso) en cada borda. y0 = justo sobre la cubierta.
Y0 = -0.222; Z_IN, Z_OUT = 0.190, 0.213; RIM = -0.160
NOTCH_X = [0.01, 0.27, 0.48]
HW = 0.065
boxes = []
for xc in NOTCH_X:
    for side in (+1, -1):
        zlo, zhi = (0.17, 0.30) if side > 0 else (-0.30, -0.17)
        boxes.append((xc - HW, xc + HW, Y0, zlo, zhi, side))

def vert(i): return np.concatenate([pos[i], nor[i], uv[i]])  # 8 floats
def interp(a, b, t): return a + (b - a) * t

def clip(poly, axis, val, keep_less):
    # devuelve (parte_que_cumple, resto)  cumple: coord<val si keep_less
    keep, rest = [], []
    n = len(poly)
    for k in range(n):
        a, b = poly[k], poly[(k + 1) % n]
        da = a[axis] - val; db = b[axis] - val
        ina = (da < 0) if keep_less else (da > 0)
        inb = (db < 0) if keep_less else (db > 0)
        if ina: keep.append(a)
        else: rest.append(a)
        if (da < 0) != (db < 0) and da != db:
            t = da / (da - db)
            p = interp(a, b, t)
            keep.append(p); rest.append(p)
    return keep, rest

def fan(poly):
    out = []
    for k in range(1, len(poly) - 1): out.append((poly[0], poly[k], poly[k + 1]))
    return out

new_verts = []   # lista de arrays de 8
new_tris = []
kept_idx = []
bb_lo = np.array([b[0] for b in boxes]); 
removed = 0; split = 0
for ti, t in enumerate(tris):
    P = pos[t]
    tlo = P.min(0); thi = P.max(0)
    hit = None
    for b in boxes:
        x0, x1, y0, zlo, zhi, side = b
        if thi[0] > x0 and tlo[0] < x1 and thi[1] > y0 and thi[2] > zlo and tlo[2] < zhi:
            hit = b; break
    if hit is None:
        kept_idx.append(ti); continue
    x0, x1, y0, zlo, zhi, side = hit
    poly = [vert(i) for i in t]
    outside = []
    rest = poly
    for axis, val, less in ((0, x0, True), (0, x1, False), (1, y0, True), (2, zlo, True), (2, zhi, False)):
        keep, rest = clip(rest, axis, val, less)
        if len(keep) >= 3: outside.append(keep)
        if len(rest) < 3: rest = []; break
    removed += 1
    for poly2 in outside:
        for tr in fan(poly2):
            # descartar triangulos degenerados
            a, b2, c = tr[0][:3], tr[1][:3], tr[2][:3]
            if np.linalg.norm(np.cross(b2 - a, c - a)) < 1e-12: continue
            # conservar orientacion original del triangulo
            nrm = np.cross(b2 - a, c - a)
            orig = np.cross(P[1] - P[0], P[2] - P[0])
            if np.dot(nrm, orig) < 0: tr = (tr[0], tr[2], tr[1])
            new_tris.append(tr)
print('triangulos tocados', removed, 'nuevos', len(new_tris))

# Tapas: piso (y=Y0) y dos jambas por muesca
def nearest_uv(p):
    d = np.linalg.norm(pos - p, axis=1); return uv[int(np.argmin(d))]
def quad(corners, normal, uvc):
    c = [np.concatenate([np.array(p, np.float32), np.array(normal, np.float32), uvc]) for p in corners]
    a, b, cc = c[0][:3], c[1][:3], c[2][:3]
    if np.dot(np.cross(b - a, cc - a), normal) < 0: c = [c[0], c[3], c[2], c[1]]
    return [(c[0], c[1], c[2]), (c[0], c[2], c[3])]
for (x0, x1, y0, zlo, zhi, side) in boxes:
    zi, zo = Z_IN * side, Z_OUT * side
    uvc = nearest_uv(np.array([(x0 + x1) / 2, Y0 - 0.02, zo]))
    new_tris += quad([(x0, y0, zi), (x1, y0, zi), (x1, y0, zo), (x0, y0, zo)], (0, 1, 0), uvc)
    new_tris += quad([(x0, y0, zi), (x0, RIM, zi), (x0, RIM, zo), (x0, y0, zo)], (1, 0, 0), uvc)
    new_tris += quad([(x1, y0, zi), (x1, RIM, zi), (x1, RIM, zo), (x1, y0, zo)], (-1, 0, 0), uvc)

# Reensamblar buffers
keep_tris = tris[kept_idx]
nv = len(pos)
add = []
for tr in new_tris: add.extend(tr)
add = np.array(add, dtype=np.float32).reshape(-1, 8)
pos2 = np.vstack([pos, add[:, 0:3]]).astype(np.float32)
nor2 = np.vstack([nor, add[:, 3:6]]).astype(np.float32)
uv2 = np.vstack([uv, add[:, 6:8]]).astype(np.float32)
idx2 = np.concatenate([keep_tris.reshape(-1), np.arange(nv, nv + len(add), dtype=np.uint32)]).astype(np.uint32)
print('final verts', len(pos2), 'tris', len(idx2) // 3)

def pad4(b): return b + b'\x00' * ((4 - len(b) % 4) % 4)
chunks = []; views = []
def addview(data, target=None):
    off = sum(len(c) for c in chunks)
    chunks.append(pad4(data))
    views.append(dict(byteOffset=off, byteLength=len(data), target=target))
    return len(views) - 1
v_idx = addview(idx2.tobytes(), 34963)
v_pos = addview(pos2.tobytes(), 34962)
v_uv = addview(uv2.tobytes(), 34962)
v_nor = addview(nor2.tobytes(), 34962)
# imagenes originales intactas
img_views = []
for im in g.images:
    bv = g.bufferViews[im.bufferView]
    data = blob[(bv.byteOffset or 0):(bv.byteOffset or 0) + bv.byteLength]
    img_views.append(addview(data, None))
from pygltflib import BufferView, Accessor, Buffer
g.bufferViews = [BufferView(buffer=0, byteOffset=v['byteOffset'], byteLength=v['byteLength'], target=v['target']) for v in views]
a_pos, a_uv, a_nor, a_idx = g.accessors[prim.attributes.POSITION], g.accessors[prim.attributes.TEXCOORD_0], g.accessors[prim.attributes.NORMAL], g.accessors[prim.indices]
a_pos.bufferView = v_pos; a_pos.count = len(pos2); a_pos.byteOffset = 0; a_pos.min = pos2.min(0).tolist(); a_pos.max = pos2.max(0).tolist()
a_uv.bufferView = v_uv; a_uv.count = len(uv2); a_uv.byteOffset = 0; a_uv.min = uv2.min(0).tolist(); a_uv.max = uv2.max(0).tolist()
a_nor.bufferView = v_nor; a_nor.count = len(nor2); a_nor.byteOffset = 0
a_idx.bufferView = v_idx; a_idx.count = len(idx2); a_idx.byteOffset = 0
for im, v in zip(g.images, img_views): im.bufferView = v
newblob = b''.join(chunks)
g.buffers = [Buffer(byteLength=len(newblob))]
g.set_binary_blob(newblob)
g.save_binary(DST)
print('ok', DST)
