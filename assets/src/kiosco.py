"""
Kiosco de la plaza (landmark de la región 1). Kiosco octagonal genérico de plaza mexicana:
plataforma de piedra con escalinata, ocho columnas de hierro, barandal y techo con cupulita.
No copia el kiosco de ningún pueblo real.

Medidas iguales al greybox (SliceBlockout): diámetro ~22 studs, piso a 2, techo a 11–15;
el farol del kiosco (farol_kiosco) va encima, como pieza aparte.

Piezas:
  Base     plataforma y escalones (piedra)
  Hierro   columnas, capiteles y barandal
  Techo    techo, alero y pedestal del farol
Presupuesto propuesto para landmark: ≤5,000 triángulos.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import common  # noqa: E402

NAME = "Kiosco"
STONE = (0.0, 0.5, 0.5, 1.0)
IRON = (0.5, 0.5, 1.0, 1.0)
ROOF = (0.0, 0.0, 0.5, 0.5)
TRIM = (0.5, 0.0, 1.0, 0.5)

R_BASE = 11.0
R_COL = 9.0
FLOOR = 2.0
COL_TOP = 11.0


def stone(u, v):
    row = int(v * 10)
    off = 0.5 if row % 2 else 0.0
    mortar = (v * 10) % 1 < 0.08 or ((u * 6 + off) % 1) < 0.04
    return (0.62, 0.59, 0.54) if mortar else (0.80, 0.76, 0.69)


def iron(u, v):
    # hierro pintado verde profundo (paleta de la región)
    return (0.16, 0.36, 0.33) if int(u * 16) % 4 else (0.22, 0.44, 0.40)


def roof(u, v):
    # lámina pintada en franjas ocre y crema, con remaches
    band = int(u * 8) % 2
    c = (0.80, 0.58, 0.24) if band else (0.86, 0.68, 0.34)
    if (v * 12) % 1 < 0.05:
        c = (0.62, 0.44, 0.18)
    return c


def trim(u, v):
    return (0.95, 0.92, 0.84)


def octagon_ring(r_in, r_out, z0, z1):
    """Anillo octagonal sólido (para alero y moldura)."""
    outer = common.lathe([(r_out, z0), (r_out, z1)], 8)
    inner = common.lathe([(r_in, z1), (r_in, z0)], 8)
    v, f = common.combine(outer, inner)
    # quitar tapas para que quede anillo abierto: lathe ya puso tapas; se aceptan (no se ven)
    return v, f


def build():
    common.reset_scene()
    atlas = common.make_atlas(
        f"{NAME}_atlas", 256, common.paint_regions([(STONE, stone), (IRON, iron), (ROOF, roof), (TRIM, trim)])
    )
    mat = common.atlas_material(f"{NAME}_mat", atlas)
    rot = math.radians(22.5)  # lados del octágono alineados con los ejes

    # --- Base de piedra: plataforma octagonal con moldura y escalinata al frente (-Y) ---
    platform = common.transform(common.lathe([(R_BASE, 0.0), (R_BASE, FLOOR - 0.3), (R_BASE + 0.3, FLOOR - 0.3), (R_BASE + 0.3, FLOOR)], 8), rot_z=rot)
    steps = []
    for i in range(3):
        h = (FLOOR / 3) * (i + 1)
        depth = 1.2 * (3 - i)
        steps.append(common.box((6.0, depth, h), center=(0, -(R_BASE + depth / 2 - 0.3), h / 2)))
    # Proyección desde arriba: el piso se lee como losas de piedra
    base = common.piece("Base", common.combine(platform, *steps), mat, STONE, axis=("x", "y"))

    # --- Hierro: columnas con base y capitel, barandal entre columnas (menos en la entrada) ---
    parts = []
    corners = []
    for i in range(8):
        a = rot + i * math.pi / 4 - math.pi / 2 + math.pi / 8
        corners.append((R_COL * math.cos(a), R_COL * math.sin(a)))
    for cx, cy in corners:
        col = common.lathe([(0.35, FLOOR), (0.35, FLOOR + 0.3), (0.18, FLOOR + 0.5), (0.16, COL_TOP - 0.6), (0.35, COL_TOP - 0.3), (0.40, COL_TOP)], 6)
        parts.append(common.transform(col, offset=(cx, cy, 0)))
    for i in range(8):
        (x0, y0), (x1, y1) = corners[i], corners[(i + 1) % 8]
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        if my < -R_COL * 0.8:
            continue  # entrada: sin barandal frente a la escalinata
        parts.append(common.tube([(x0, y0, FLOOR + 1.2), (x1, y1, FLOOR + 1.2)], 0.07, 4, cap=False))
        for k in range(1, 5):
            t = k / 5
            bx, by = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            parts.append(common.box((0.08, 0.08, 1.2), center=(bx, by, FLOOR + 0.6)))
    hierro = common.piece("Hierro", common.combine(*parts), mat, IRON, axis=("x", "y"))

    # --- Techo: alero, faldón octagonal, cupulita y pedestal del farol ---
    techo_part = common.transform(
        common.lathe(
            [
                (R_COL + 1.6, COL_TOP),
                (R_COL + 1.6, COL_TOP + 0.5),
                (R_COL - 1.0, COL_TOP + 2.6),
                (3.2, COL_TOP + 3.6),
                (2.4, COL_TOP + 4.4),
                (1.2, COL_TOP + 4.9),
                (0.8, COL_TOP + 4.9),
            ],
            8,
        ),
        rot_z=rot,
    )
    pedestal = common.lathe([(0.8, COL_TOP + 4.9), (0.5, COL_TOP + 5.2), (0.5, COL_TOP + 5.6), (0.7, COL_TOP + 5.7)], 8)
    techo = common.piece("Techo", common.combine(techo_part, pedestal), mat, ROOF, axis=("x", "y"))
    moldura = common.piece(
        "Moldura",
        common.transform(common.lathe([(R_COL + 1.7, COL_TOP - 0.25), (R_COL + 1.7, COL_TOP)], 8), rot_z=rot),
        mat,
        TRIM,
        axis=("x", "z"),
    )
    techo = common.join([techo, moldura], "Techo")

    objects = [base, hierro, techo]
    common.report(NAME, objects, (800, 5000))
    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", objects)
    common.render_preview(f"{NAME}.png", target=(0, 0, 6), distance=42, elevation=22, azimuth=25)
    print(f"[{NAME}] exportado")


build()
