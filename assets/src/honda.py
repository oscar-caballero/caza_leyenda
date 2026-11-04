"""
Honda (juguete; D-004). La honda tradicional: dos cordeles con una cuna tejida al centro,
un lazo para el dedo en un extremo y un nudo en el otro. No es la resortera (esa es el power-up).

Tejido de la cuna: franjas ORIGINALES naranja/crema (el naranja es el color del efecto de la
honda, D-004); no reproduce ningún textil de una comunidad concreta (biblia §10).

Una sola pieza ("Honda"), presupuesto de herramienta: 500–1,500 triángulos (D-010).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import common  # noqa: E402

NAME = "Honda"
CORD = (0.0, 0.0, 0.5, 1.0)
POUCH = (0.5, 0.0, 1.0, 1.0)


def fiber(u, v):
    # fibra natural torcida: rayas diagonales
    t = (u * 6 + v * 18) % 1.0
    k = 0.92 if t < 0.5 else 0.78
    return (0.86 * k, 0.76 * k, 0.56 * k)


def woven(u, v):
    band = int(v * 8) % 4
    base = [(0.95, 0.55, 0.16), (0.96, 0.92, 0.80), (0.80, 0.36, 0.12), (0.96, 0.92, 0.80)][band]
    # trama: cuadrícula fina para que se lea "tejido"
    if (int(u * 32) + int(v * 32)) % 2 == 0:
        base = tuple(c * 0.9 for c in base)
    return base


def pouch(w=0.42, d=0.22, cols=6, rows=3):
    verts, faces = [], []
    for j in range(rows + 1):
        for i in range(cols + 1):
            x = -w + 2 * w * i / cols
            y = -d + 2 * d * j / rows
            z = 0.5 * (x * x) - 0.6 * (y * y)  # cuna curva
            verts.append((x, y, z))
    for j in range(rows):
        for i in range(cols):
            a = j * (cols + 1) + i
            faces.append((a, a + 1, a + cols + 2, a + cols + 1))
    return verts, faces


def cord(side):
    pts = []
    for k in range(10):
        t = k / 9
        x = side * (0.40 * (1 - t) + 0.05 * t)
        z = 0.03 + 2.2 * t
        y = 0.04 * math.sin(t * math.pi)  # leve curva: cuelga
        pts.append((x, y, z))
    return pts


def torus(center, r_major, r_minor, seg=10, sides=5):
    cx, cy, cz = center
    verts, faces = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        for j in range(sides):
            b = 2 * math.pi * j / sides
            r = r_major + r_minor * math.cos(b)
            verts.append((cx + r * math.cos(a), cy + r_minor * math.sin(b), cz + r * math.sin(a)))
    for i in range(seg):
        for j in range(sides):
            a = i * sides + j
            b = i * sides + (j + 1) % sides
            c = ((i + 1) % seg) * sides + (j + 1) % sides
            d = ((i + 1) % seg) * sides + j
            faces.append((a, b, c, d))
    return verts, faces


def build():
    common.reset_scene()
    atlas = common.make_atlas(f"{NAME}_atlas", 128, common.paint_regions([(CORD, fiber), (POUCH, woven)]))
    mat = common.atlas_material(f"{NAME}_mat", atlas)

    cords = common.piece(
        "Cordeles",
        common.combine(
            common.tube(cord(-1), 0.04, 6),
            common.tube(cord(1), 0.04, 6),
            torus((-0.05, 0.0, 2.38), 0.12, 0.04),  # lazo para el dedo
            common.cylinder(0.05, 2.2, 2.3, 6, center=(0.05, 0.0)),  # nudo
        ),
        mat,
        CORD,
        axis=("x", "z"),
    )
    cuna = common.piece("Cuna", pouch(), mat, POUCH, axis=("x", "y"))
    solid = cuna.modifiers.new("Grosor", "SOLIDIFY")
    solid.thickness = 0.05
    common.apply_modifiers(cuna)

    honda = common.join([cords, cuna], NAME)
    common.report(NAME, [honda], (500, 1500))
    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", [honda])
    common.render_preview(f"{NAME}.png", target=(0, 0, 1.1), distance=4.0, elevation=12, azimuth=25)
    print(f"[{NAME}] exportado")


build()
