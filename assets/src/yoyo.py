"""
Yo-yo (juguete; D-004). Yo-yo de madera torneada y pintada, con su cuerda y el lazo del dedo.
Franjas pintadas ORIGINALES con cian (color del efecto del yo-yo, D-004) sobre madera.

Una sola pieza ("Yoyo"), presupuesto de herramienta: 500–1,500 triángulos (D-010).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import bpy  # noqa: E402
import common  # noqa: E402

NAME = "Yoyo"
BODY = (0.0, 0.0, 0.5, 1.0)
STRING = (0.5, 0.0, 1.0, 1.0)


def painted(u, v):
    # v recorre el eje del yo-yo: caras exteriores cian, franja crema, canto de madera
    d = abs(v - 0.5) * 2  # 0 en el centro (ranura), 1 en las caras
    wood = (0.70, 0.50, 0.30)
    if d > 0.92:
        return (0.20, 0.72, 0.80)  # cara exterior cian
    if d > 0.80:
        return (0.96, 0.92, 0.80)  # franja crema
    if d > 0.55:
        return (0.18, 0.60, 0.70)  # canto cian oscuro
    if d > 0.25:
        return wood
    return (0.45, 0.30, 0.18)  # ranura y eje


def string(u, v):
    return (0.95, 0.93, 0.86) if int(v * 20) % 2 == 0 else (0.88, 0.86, 0.78)


def build():
    common.reset_scene()
    atlas = common.make_atlas(f"{NAME}_atlas", 128, common.paint_regions([(BODY, painted), (STRING, string)]))
    mat = common.atlas_material(f"{NAME}_mat", atlas)

    profile = [
        (0.00, -0.32),
        (0.30, -0.32),
        (0.42, -0.28),
        (0.46, -0.19),
        (0.42, -0.09),
        (0.10, -0.05),
        (0.06, 0.00),
        (0.10, 0.05),
        (0.42, 0.09),
        (0.46, 0.19),
        (0.42, 0.28),
        (0.30, 0.32),
        (0.00, 0.32),
    ]
    body = common.piece("Cuerpo", common.lathe(profile, 16), mat, BODY, axis=("x", "z"))
    # Eje horizontal: el yo-yo rueda sobre su cuerda
    body.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = body
    body.select_set(True)
    bpy.ops.object.transform_apply(rotation=True)

    pts = [(0.0, 0.0, 0.06), (0.0, 0.0, 0.5), (0.0, 0.02, 1.0), (0.0, 0.0, 1.5), (0.0, 0.0, 1.62)]
    loop = []
    for k in range(8):
        a = 2 * math.pi * k / 8
        loop.append((0.0, 0.08 * math.sin(a), 1.70 + 0.08 * math.cos(a)))
    cuerda = common.piece(
        "Cuerda",
        common.combine(common.tube(pts, 0.015, 5), common.tube(loop + [loop[0]], 0.015, 5)),
        mat,
        STRING,
        axis=("y", "z"),
    )

    yoyo = common.join([body, cuerda], NAME)
    common.report(NAME, [yoyo], (500, 1500))
    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", [yoyo])
    common.render_preview(f"{NAME}.png", target=(0, 0, 0.6), distance=3.4, elevation=15, azimuth=50)
    print(f"[{NAME}] exportado")


build()
