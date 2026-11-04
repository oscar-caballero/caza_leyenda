"""
Farol del Pueblo de los Faroles (prop que más se repite; región 1).

Farol de hierro de mediados del siglo XX ("el pueblo de los abuelos", biblia §7): base
ensanchada, poste octagonal, collarín, linterna de cuatro vidrios con techito y remate.

Piezas:
  Poste   hierro (poste + marco de la linterna + techito)
  Vidrio  los cuatro vidrios: el código lo cambia a Neon/cálido cuando el farol se enciende

Se modela con la misma altura que el greybox (cabeza a ~7.9 studs del suelo).
Presupuesto propuesto para props repetidos: ≤1,500 triángulos.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import common  # noqa: E402

NAME = "Farol"
IRON = (0.0, 0.0, 0.5, 1.0)
GLASS = (0.5, 0.0, 1.0, 1.0)


def iron(u, v):
    # hierro pintado casi negro con un toque azul; líneas sutiles de forja
    k = 0.92 if int(v * 24) % 6 else 1.08
    return (0.17 * k, 0.17 * k, 0.21 * k)


def glass(u, v):
    # vidrio cálido apagado; el brillo lo pone el material Neon en Roblox
    edge = min(u, 1 - u, v, 1 - v)
    return (0.93, 0.86, 0.66) if edge > 0.06 else (0.70, 0.64, 0.50)


def build():
    common.reset_scene()
    atlas = common.make_atlas(f"{NAME}_atlas", 128, common.paint_regions([(IRON, iron), (GLASS, glass)]))
    mat = common.atlas_material(f"{NAME}_mat", atlas)

    post = common.lathe(
        [
            (0.55, 0.00),
            (0.55, 0.25),
            (0.36, 0.45),
            (0.22, 0.70),
            (0.15, 1.00),
            (0.13, 5.60),
            (0.22, 5.75),
            (0.22, 5.95),
            (0.12, 6.10),
            (0.12, 6.80),
            (0.30, 6.95),
        ],
        8,
    )
    # Marco de la linterna: cuatro postes delgados en las esquinas + base y techito piramidal
    frame = []
    h0, h1 = 6.95, 8.45
    for sx in (-1, 1):
        for sy in (-1, 1):
            frame.append(common.box((0.08, 0.08, h1 - h0), center=(sx * 0.42, sy * 0.42, (h0 + h1) / 2)))
    roof = common.lathe([(0.0, 9.35), (0.12, 9.05), (0.70, 8.55), (0.62, 8.45)][::-1], 4)
    roof = common.transform(roof, rot_z=math.radians(45))
    finial = common.lathe([(0.07, 9.30), (0.14, 9.45), (0.0, 9.65)], 6)
    base_plate = common.box((1.0, 1.0, 0.1), center=(0, 0, h0))
    poste = common.piece("Poste", common.combine(post, *frame, roof, finial, base_plate), mat, IRON, axis=("x", "z"))

    vidrio = common.piece(
        "Vidrio",
        common.box((0.78, 0.78, h1 - h0 - 0.1), center=(0, 0, (h0 + h1) / 2)),
        mat,
        GLASS,
        axis=("x", "z"),
    )

    objects = [poste, vidrio]
    common.report(NAME, objects, (200, 1500))
    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", objects)
    common.render_preview(f"{NAME}.png", target=(0, 0, 4.8), distance=14, elevation=10, azimuth=30)
    print(f"[{NAME}] exportado")


build()
