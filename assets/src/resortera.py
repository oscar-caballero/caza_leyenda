"""
Resortera (power-up momentáneo de la honda; D-013). Horqueta de madera barnizada en dorado
(el color del power-up en el juego), dos ligas y una pequeña bolsa de cuero.

Una sola pieza ("Resortera"), presupuesto de herramienta: 500–1,500 triángulos (D-010).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import common  # noqa: E402

NAME = "Resortera"
WOOD = (0.0, 0.0, 0.5, 1.0)
RUBBER = (0.5, 0.5, 1.0, 1.0)
LEATHER = (0.5, 0.0, 1.0, 0.5)


def wood(u, v):
    grain = 0.5 + 0.5 * math.sin(v * 40 + math.sin(u * 9) * 2)
    k = 0.85 + 0.15 * grain
    return (0.95 * k, 0.74 * k, 0.26 * k)  # madera dorada


def rubber(u, v):
    return (0.62, 0.16, 0.12) if int(v * 10) % 2 == 0 else (0.52, 0.12, 0.10)


def leather(u, v):
    edge = min(u, 1 - u, v, 1 - v)
    return (0.40, 0.24, 0.14) if edge > 0.08 else (0.28, 0.16, 0.09)


def build():
    common.reset_scene()
    atlas = common.make_atlas(
        f"{NAME}_atlas", 128, common.paint_regions([(WOOD, wood), (RUBBER, rubber), (LEATHER, leather)])
    )
    mat = common.atlas_material(f"{NAME}_mat", atlas)

    handle = common.tube([(0, 0, 0.0), (0, 0, 0.45), (0, 0, 0.9)], [0.085, 0.095, 0.10], 8)
    arm_l = common.tube([(0, 0, 0.85), (-0.18, 0, 1.15), (-0.32, 0, 1.55)], [0.10, 0.08, 0.07], 8)
    arm_r = common.tube([(0, 0, 0.85), (0.18, 0, 1.15), (0.32, 0, 1.55)], [0.10, 0.08, 0.07], 8)
    madera = common.piece("Horqueta", common.combine(handle, arm_l, arm_r), mat, WOOD, axis=("x", "z"))

    # Bolsa al frente, entre los brazos; cada liga va de la punta del brazo al borde de la bolsa
    bag_center = (0.0, -0.28, 1.38)
    ligas = common.piece(
        "Ligas",
        common.combine(
            common.tube([(-0.32, 0, 1.52), (-0.24, -0.14, 1.46), (-0.15, -0.27, 1.39)], 0.04, 6),
            common.tube([(0.32, 0, 1.52), (0.24, -0.14, 1.46), (0.15, -0.27, 1.39)], 0.04, 6),
        ),
        mat,
        RUBBER,
        axis=("x", "z"),
    )
    bolsa = common.piece(
        "Bolsa",
        common.transform(common.cylinder(0.16, -0.035, 0.035, 10), offset=bag_center, rot_x=math.radians(90)),
        mat,
        LEATHER,
        axis=("x", "z"),
    )

    resortera = common.join([madera, ligas, bolsa], NAME)
    common.report(NAME, [resortera], (500, 1500))
    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", [resortera])
    common.render_preview(f"{NAME}.png", target=(0, 0, 0.8), distance=3.6, elevation=18, azimuth=30)
    print(f"[{NAME}] exportado")


build()
