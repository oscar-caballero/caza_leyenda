"""
Polilla de Papel (criatura del Olvido, nivel 3; invención del juego).

Diseño: polilla de origami doblada con una hoja de cuaderno rayado (biblia §3: el Olvido
"como un cuaderno con páginas arrancadas"). Cuerpo de tinta oscura y alas de papel claro:
silueta legible a 20 m por contraste de valor, no solo de color (D-011).

Piezas (un MeshPart cada una en Roblox):
  Cuerpo   cuerpo + antenas
  AlaIzq   ala delantera + trasera, con el origen en la raíz (para aletear girando en Y)
  AlaDer   espejo de AlaIzq

Presupuesto (sesión del Estudio, D-019): 250–400 triángulos; aquí se queda por debajo.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import common  # noqa: E402

NAME = "PolillaPapel"
PAPER = (0.0, 0.0, 0.5, 1.0)  # región del atlas: mitad izquierda
INK = (0.5, 0.0, 1.0, 1.0)  # mitad derecha


def paint_atlas(px, w, h):
    paper = (0.953, 0.941, 0.902)
    ruled = (0.55, 0.68, 0.86)
    margin = (0.85, 0.42, 0.42)
    ink = (0.18, 0.165, 0.267)
    ink_line = (0.26, 0.24, 0.36)
    for y in range(h):
        for x in range(w):
            i = (y * w + x) * 4
            if x < w // 2:
                r, g, b = paper
                if y % 12 == 0:
                    r, g, b = ruled  # renglones del cuaderno
                if x == 10 or x == 11:
                    r, g, b = margin  # margen rojo
                # bordes un poco deslavados: el Olvido se come el color
                fade = min(x, w // 2 - x, y, h - y) / 10.0
                k = 0.85 + 0.15 * min(1.0, fade)
                px[i : i + 4] = [r * k + (1 - k), g * k + (1 - k), b * k + (1 - k), 1.0]
            else:
                r, g, b = ink_line if (y // 6) % 2 == 0 else ink
                px[i : i + 4] = [r, g, b, 1.0]


def spindle(rings, segments):
    """Cuerpo en huso a lo largo de Y. rings = [(y, radio, z)], puntas en el primero y el último."""
    verts, faces = [], []
    tail = rings[0]
    head = rings[-1]
    verts.append((0.0, tail[0], tail[2]))
    for y, r, z in rings[1:-1]:
        for s in range(segments):
            a = 2 * math.pi * s / segments
            verts.append((r * math.cos(a), y, z + r * 0.8 * math.sin(a)))
    verts.append((0.0, head[0], head[2]))
    last = len(verts) - 1
    n_rings = len(rings) - 2
    for s in range(segments):
        faces.append((0, 1 + (s + 1) % segments, 1 + s))
    for ring in range(n_rings - 1):
        base = 1 + ring * segments
        for s in range(segments):
            a, b = base + s, base + (s + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    base = 1 + (n_rings - 1) * segments
    for s in range(segments):
        faces.append((base + s, base + (s + 1) % segments, last))
    return verts, faces


def antenna(start, end, width):
    sx, sy, sz = start
    ex, ey, ez = end
    verts = [
        (sx - width, sy, sz),
        (sx + width, sy, sz),
        (sx, sy, sz + width),
        (ex, ey, ez),
    ]
    faces = [(0, 1, 3), (1, 2, 3), (2, 0, 3), (0, 2, 1)]
    return verts, faces


def wing(side):
    """Ala de origami: delantera y trasera, cada una con un pliegue central levantado."""
    s = side
    verts = [
        # delantera
        (0.0, 0.32, 0.0),  # 0 raíz frente
        (s * 1.20, 0.30, 0.22),  # 1 punta
        (s * 1.05, -0.18, 0.08),  # 2 borde exterior
        (0.0, -0.02, 0.0),  # 3 raíz medio
        (s * 0.62, 0.10, 0.16),  # 4 pliegue
        (s * 0.95, 0.42, 0.18),  # 5 borde de ataque (curva)
        # trasera
        (s * 0.82, -0.36, 0.05),  # 6 borde exterior
        (s * 0.50, -0.78, 0.0),  # 7 punta trasera
        (0.0, -0.34, -0.01),  # 8 raíz atrás
        (s * 0.42, -0.36, 0.09),  # 9 pliegue
    ]
    faces = [
        (0, 5, 4),
        (5, 1, 4),
        (1, 2, 4),
        (2, 3, 4),
        (3, 0, 4),
        (3, 2, 9),
        (2, 6, 9),
        (6, 7, 9),
        (7, 8, 9),
        (8, 3, 9),
    ]
    if s < 0:
        faces = [tuple(reversed(f)) for f in faces]
    return verts, faces


def build():
    common.reset_scene()
    atlas = common.make_atlas(f"{NAME}_atlas", 128, paint_atlas)
    mat = common.atlas_material(f"{NAME}_mat", atlas)

    # Cuerpo + antenas en un solo objeto
    bv, bf = spindle(
        [(-0.85, 0, 0.0), (-0.55, 0.10, 0.0), (-0.20, 0.17, 0.02), (0.15, 0.19, 0.04), (0.45, 0.15, 0.06), (0.62, 0.16, 0.08), (0.80, 0, 0.08)],
        8,
    )
    for side in (-1, 1):
        av, af = antenna((side * 0.06, 0.70, 0.18), (side * 0.32, 1.15, 0.55), 0.025)
        off = len(bv)
        bv += av
        bf += [tuple(i + off for i in f) for f in af]
    body = common.mesh_object("Cuerpo", bv, bf)
    body.data.materials.append(mat)
    common.uv_from_rect(body, INK, axis=("y", "z"))
    common.flat_shade(body)

    wings = []
    for side, name in ((-1, "AlaIzq"), (1, "AlaDer")):
        wv, wf = wing(side)
        obj = common.mesh_object(name, wv, wf)
        obj.data.materials.append(mat)
        common.uv_from_rect(obj, PAPER, axis=("x", "y"))
        solid = obj.modifiers.new("Grosor", "SOLIDIFY")
        solid.thickness = 0.02
        solid.offset = 0
        common.flat_shade(obj)
        # El origen queda en la raíz del ala: girar en Y la hace aletear
        obj.location = (side * 0.13, 0.05, 0.10)
        wings.append(obj)

    objects = [body] + wings
    common.report(NAME, objects, (100, 400))
    for o in wings:
        common.apply_modifiers(o)

    common.save_image(atlas, f"{NAME}_atlas.png")
    common.export_fbx(f"{NAME}.fbx", objects)

    # Vista previa con las alas un poco levantadas, como en vuelo
    wings[0].rotation_euler = (0, math.radians(18), 0)
    wings[1].rotation_euler = (0, math.radians(-18), 0)
    common.render_preview(f"{NAME}.png", target=(0, 0, 0.1), distance=4.2, elevation=32, azimuth=30)
    print(f"[{NAME}] exportado")


build()
