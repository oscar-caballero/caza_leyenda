"""
El Rumor (criatura del Olvido, nivel 3; invención del juego). Biblia §6 y D-019:
"una mancha grande hecha con la versión torcida que todos repiten". Se arma con pedazos de
cosas olvidadas: JUGUETES ROTOS y deslavados, y PAPEL DE PERIÓDICO (no papel picado: es una
artesanía viva de San Salvador Huixcolotla, D-019). Cucuruchos de periódico como "bocas" por
las que susurra: misterio cálido, nunca terror (sin dientes, sin ojos amenazantes).

El periódico es inventado: renglones y titulares sin texto real (no copia ningún diario).

Una sola pieza ("Rumor"), ~8 studs de alto como el greybox. Presupuesto: 3,000–5,000 (D-010).
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
import bmesh  # noqa: E402
from mathutils import Vector, noise  # noqa: E402

import common  # noqa: E402

NAME = "Rumor"
NEWS = (0.0, 0.5, 1.0, 1.0)
TOYS = (0.0, 0.0, 0.5, 0.5)
DARK = (0.5, 0.0, 1.0, 0.5)
# Colores de juguete deslavados (el Olvido les quita color)
TOY_COLORS = [(0.78, 0.47, 0.42), (0.47, 0.62, 0.74), (0.80, 0.72, 0.42), (0.52, 0.68, 0.52), (0.70, 0.56, 0.72), (0.86, 0.84, 0.80)]

random.seed(7)


def news(u, v):
    paper = (0.86, 0.84, 0.78)
    ink = (0.36, 0.35, 0.38)
    col = int(u * 4)  # cuatro columnas de "texto"
    cu = (u * 4) % 1
    if cu < 0.06 or cu > 0.94:
        return paper  # medianil
    line = (v * 40) % 1
    if int(v * 40) % 8 == 0:
        # titular: barra gruesa
        return ink if 0.15 < line < 0.85 and cu < 0.75 + 0.2 * ((col * 7) % 3) / 2 else paper
    # renglones de texto falso: rayitas de largo variable
    word = int(cu * 9 + int(v * 40) * 3) % 5
    if 0.35 < line < 0.65 and word != 0:
        return ink
    return paper


def toys(u, v):
    return TOY_COLORS[min(int(u * 6), 5)]


def dark(u, v):
    return (0.20, 0.19, 0.24)


def toy_rect(i):
    w = 0.5 / 6
    return (i * w, 0.0, (i + 1) * w, 0.5)


def crumpled_blob(radius, subdiv=3, puddle=True):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    for v in bm.verts:
        n = v.co.normalized()
        # bultos grandes (silueta irregular) + arrugas chicas (papel)
        bump = noise.noise(v.co * (0.9 / radius) + Vector((3.1, 0.7, 1.9))) * radius * 0.45
        bump += noise.noise(v.co * (3.0 / radius)) * radius * 0.12
        co = v.co + n * bump
        if puddle and co.z < -radius * 0.35:
            # se derrama: la base se aplasta y se ensancha
            spread = 1.0 + (-radius * 0.35 - co.z) / radius * 0.9
            co = Vector((co.x * spread, co.y * spread, -radius * 0.35 - (co.z + radius * 0.35) * 0.15))
        v.co = co
    verts = [tuple(v.co) for v in bm.verts]
    faces = [tuple(v.index for v in f.verts) for f in bm.faces]
    bm.free()
    return verts, faces


def patch_uv(obj, rect, patch=0.22):
    """Cada cara recibe su propio pedazo de periódico, girado al azar: se lee como collage."""
    mesh = obj.data
    uv = mesh.uv_layers.active.data
    u0, v0, u1, v1 = rect
    rng = random.Random(11)
    for poly in mesh.polygons:
        n = poly.normal
        t = n.orthogonal().normalized()
        b = n.cross(t).normalized()
        ang = rng.uniform(0, math.pi)
        t, b = t * math.cos(ang) + b * math.sin(ang), b * math.cos(ang) - t * math.sin(ang)
        pts = [mesh.vertices[mesh.loops[li].vertex_index].co for li in poly.loop_indices]
        c = sum(pts, Vector()) / len(pts)
        ou, ov = rng.uniform(0.2, 0.8), rng.uniform(0.2, 0.8)
        for li, p in zip(poly.loop_indices, pts):
            du, dv = (p - c).dot(t) * patch * 0.25, (p - c).dot(b) * patch * 0.25
            uu = min(0.97, max(0.03, ou + du))
            vv = min(0.97, max(0.03, ov + dv))
            uv[li].uv = (u0 + uu * (u1 - u0), v0 + vv * (v1 - v0))


def ribbon(start, direction, length, width, segments, twist):
    """Tira de periódico que ondea."""
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 0.1:
        side = Vector((1, 0, 0))
    side.normalize()
    up = side.cross(d).normalized()
    verts, faces = [], []
    p = Vector(start)
    for i in range(segments + 1):
        t = i / segments
        a = twist * t
        w = side * math.cos(a) + up * math.sin(a)
        center = p + d * (length * t) + up * math.sin(t * math.pi * 2) * 0.35
        half = width * (1 - 0.5 * t) / 2
        verts += [tuple(center - w * half), tuple(center + w * half)]
    for i in range(segments):
        a = 2 * i
        faces.append((a, a + 1, a + 3, a + 2))
    return verts, faces


def cone(base_center, direction, length, radius):
    """Cucurucho de periódico: el 'altavoz' por el que susurra."""
    profile = [(radius * 0.25, 0.0), (radius, length), (radius * 0.85, length * 0.97)]
    v, f = common.lathe(profile, 8)
    d = Vector(direction).normalized()
    rot = Vector((0, 0, 1)).rotation_difference(d)
    out = []
    for p in v:
        q = Vector(p)
        q.rotate(rot)
        out.append(tuple(q + Vector(base_center)))
    return out, f


def build():
    common.reset_scene()
    atlas = common.make_atlas(
        f"{NAME}_atlas", 256, common.paint_regions([(NEWS, news), (TOYS, toys), (DARK, dark)])
    )
    mat = common.atlas_material(f"{NAME}_mat", atlas)
    pieces = []

    # Cuerpo: periódico arrugado (centro a 4 studs: mide ~8 de alto)
    body = common.transform(crumpled_blob(3.3, 3), offset=(0, 0, 3.4))
    cuerpo = common.piece("Cuerpo", body, mat, NEWS, axis=("x", "z"))
    patch_uv(cuerpo, NEWS)
    pieces.append(cuerpo)

    # Tiras de periódico sueltas
    strips = []
    for k in range(7):
        a = 2 * math.pi * k / 7 + random.uniform(-0.2, 0.2)
        start = (math.cos(a) * 2.6, math.sin(a) * 2.4, 2.0 + random.uniform(0, 3))
        direction = (math.cos(a), math.sin(a), random.uniform(-0.3, 0.6))
        strips.append(ribbon(start, direction, random.uniform(3.0, 4.4), 1.1, 10, random.uniform(1.5, 3.0)))
    tiras = common.piece("Tiras", common.combine(*strips), mat, NEWS, axis=("x", "y"))
    solid = tiras.modifiers.new("Grosor", "SOLIDIFY")
    solid.thickness = 0.05
    common.apply_modifiers(tiras)
    pieces.append(tiras)

    # Cucuruchos (bocas): el exterior es periódico; el interior oscuro se lee como hueco
    for k, (pos, d) in enumerate(
        [((1.2, -2.6, 4.6), (0.3, -1, 0.2)), ((-1.6, -2.4, 3.6), (-0.4, -1, -0.1)), ((0.2, -2.0, 6.0), (0.1, -0.6, 0.8))]
    ):
        outer = common.piece(f"Cucurucho{k}", cone(pos, d, 1.4, 0.6), mat, NEWS, axis=("x", "z"))
        inner_pos = tuple(Vector(pos) + Vector(d).normalized() * 0.2)
        inner = common.piece(f"Hueco{k}", cone(inner_pos, d, 1.2, 0.5), mat, DARK, axis=("x", "z"))
        pieces += [outer, inner]

    # Juguetes rotos incrustados (deslavados): parte adentro de la mancha, parte afuera
    trompo = common.lathe([(0.0, 0.0), (0.5, 0.7), (0.9, 1.3), (0.8, 1.6), (0.15, 1.75), (0.15, 2.2)], 10)
    for k, (pos, rx, ry, c) in enumerate(
        [((3.2, -0.9, 4.2), 20, 70, 0), ((-2.6, 1.6, 5.4), -40, -50, 3), ((0.4, -3.1, 1.3), 80, 10, 4)]
    ):
        pieces.append(common.piece(f"Trompo{k}", common.transform(trompo, offset=pos, rot_x=math.radians(rx), rot_y=math.radians(ry)), mat, toy_rect(c), axis=("x", "z")))
    rueda = common.cylinder(0.8, -0.2, 0.2, 12)
    for k, (pos, rx, rz, c) in enumerate(
        [((-3.4, -1.4, 2.4), 90, 30, 1), ((2.4, 2.9, 2.0), 80, 0, 3), ((-0.8, -3.2, 4.8), 60, 80, 5), ((3.6, 1.0, 1.0), 90, 60, 1)]
    ):
        pieces.append(common.piece(f"Rueda{k}", common.transform(rueda, offset=pos, rot_x=math.radians(rx), rot_z=math.radians(rz)), mat, toy_rect(c), axis=("x", "y")))
    medio_yoyo = common.lathe([(0.0, 0.0), (0.75, 0.0), (0.82, 0.22), (0.68, 0.45), (0.15, 0.48)], 12)
    for k, (pos, rx, c) in enumerate([((-2.3, 2.6, 5.8), -60, 4), ((2.6, -2.4, 5.6), 50, 1)]):
        pieces.append(common.piece(f"MedioYoyo{k}", common.transform(medio_yoyo, offset=pos, rot_x=math.radians(rx)), mat, toy_rect(c), axis=("x", "z")))
    for k in range(6):
        bm_v, bm_f = crumpled_blob(0.42, 1, puddle=False)
        a = k * 1.1
        pieces.append(common.piece(f"Canica{k}", common.transform((bm_v, bm_f), offset=(math.cos(a) * 4.2, math.sin(a) * 3.8, 0.5 + (k % 3) * 0.3)), mat, toy_rect([2, 5, 1, 3, 2, 4][k]), axis=("x", "z")))
    for k, (pos, rz, c) in enumerate([((0.8, 3.2, 5.0), 0.5, 5), ((-3.4, -0.2, 4.6), 1.1, 2)]):
        pieces.append(common.piece(f"Cubo{k}", common.transform(common.box((1.2, 1.2, 1.2)), offset=pos, rot_z=rz, rot_x=0.4), mat, toy_rect(c), axis=("x", "z")))

    rumor = common.join(pieces, NAME)
    common.report(NAME, [rumor], (3000, 5000))
    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", [rumor])
    common.render_preview(f"{NAME}.png", target=(0, 0, 3.8), distance=19, elevation=14, azimuth=20)
    print(f"[{NAME}] exportado")


build()
