"""
Utilidades compartidas para modelar por código en Blender (sin interfaz).

Uso:
  flatpak run org.blender.Blender -b --factory-startup -P assets/src/<modelo>.py

Convenciones (D-010):
  - 1 unidad de Blender = 1 stud de Roblox. Eje Y de Blender = adelante del modelo.
  - Un objeto por pieza que se anime por separado (p. ej. alas): Roblox importa un MeshPart por objeto.
  - Una textura atlas pequeña por modelo (PNG), generada aquí mismo: sin assets de terceros.
  - Cada modelo verifica su presupuesto de triángulos antes de exportar.
"""

import math
import os
import sys

import bpy
import bmesh

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXPORT_DIR = os.path.join(ROOT, "assets", "export")
PREVIEW_DIR = os.path.join(ROOT, "assets", "preview")


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    return scene


def mesh_object(name, verts, faces, collection=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    (collection or bpy.context.scene.collection).objects.link(obj)
    return obj


def triangle_count(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    evaluated.to_mesh_clear()
    return tris


def apply_modifiers(obj):
    bpy.context.view_layer.objects.active = obj
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)


def flat_shade(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = False


def make_atlas(name, size, painter):
    """Crea una imagen size×size; painter(px, w, h) escribe en la lista RGBA plana."""
    image = bpy.data.images.new(name, width=size, height=size, alpha=True)
    pixels = [0.0] * (size * size * 4)
    painter(pixels, size, size)
    image.pixels = pixels
    return image


def atlas_material(name, image):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    return mat


def uv_from_rect(obj, rect, axis=("x", "y")):
    """Proyecta las coordenadas del objeto al rectángulo (u0, v0, u1, v1) del atlas."""
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv = mesh.uv_layers.active.data
    idx = {"x": 0, "y": 1, "z": 2}
    a, b = idx[axis[0]], idx[axis[1]]
    coords = [v.co for v in mesh.vertices]
    amin = min(c[a] for c in coords)
    amax = max(c[a] for c in coords)
    bmin = min(c[b] for c in coords)
    bmax = max(c[b] for c in coords)
    u0, v0, u1, v1 = rect
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            co = mesh.vertices[mesh.loops[li].vertex_index].co
            s = (co[a] - amin) / ((amax - amin) or 1)
            t = (co[b] - bmin) / ((bmax - bmin) or 1)
            uv[li].uv = (u0 + s * (u1 - u0), v0 + t * (v1 - v0))


def save_image(image, filename):
    path = os.path.join(EXPORT_DIR, filename)
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    return path


def export_fbx(filename, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    path = os.path.join(EXPORT_DIR, filename)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
    )
    return path


def render_preview(filename, target=(0, 0, 0), distance=6.0, elevation=25.0, azimuth=35.0, size=640):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.film_transparent = False

    world = bpy.data.worlds.new("Fondo")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.86, 0.86, 0.9, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    scene.world = world

    el, az = math.radians(elevation), math.radians(azimuth)
    tx, ty, tz = target
    cam_pos = (
        tx + distance * math.cos(el) * math.sin(az),
        ty - distance * math.cos(el) * math.cos(az),
        tz + distance * math.sin(el),
    )
    cam_data = bpy.data.cameras.new("Camara")
    cam = bpy.data.objects.new("Camara", cam_data)
    scene.collection.objects.link(cam)
    cam.location = cam_pos
    direction = (tx - cam_pos[0], ty - cam_pos[1], tz - cam_pos[2])
    cam.rotation_mode = "QUATERNION"
    from mathutils import Vector

    cam.rotation_quaternion = Vector(direction).to_track_quat("-Z", "Y")
    scene.camera = cam

    sun_data = bpy.data.lights.new("Sol", type="SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("Sol", sun_data)
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)

    path = os.path.join(PREVIEW_DIR, filename)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def report(name, objects, budget):
    total = 0
    for o in objects:
        t = triangle_count(o)
        total += t
        print(f"[{name}] {o.name}: {t} triángulos")
    lo, hi = budget
    if total > hi:
        status = "SE PASA DEL PRESUPUESTO"
    elif total < lo:
        status = "OK (por debajo del rango: más ligero para celular)"
    else:
        status = "OK"
    print(f"[{name}] TOTAL {total} triángulos (presupuesto {lo}–{hi}): {status}")
    if total > hi:
        sys.exit(1)
    return total


# ---------------------------------------------------------------------------
# Primitivas paramétricas (devuelven verts, faces para combinarlas libremente)
# ---------------------------------------------------------------------------


def _frame(tangent):
    from mathutils import Vector

    t = Vector(tangent).normalized()
    up = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
    n = t.cross(up).normalized()
    b = t.cross(n).normalized()
    return n, b


def tube(points, radius, sides=6, cap=True):
    """Tubo a lo largo de una polilínea (cordeles, cuerdas, ligas). radius puede ser número o lista."""
    from mathutils import Vector

    pts = [Vector(p) for p in points]
    radii = radius if isinstance(radius, (list, tuple)) else [radius] * len(pts)
    verts, faces = [], []
    for i, p in enumerate(pts):
        tangent = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)])
        n, b = _frame(tangent)
        for s in range(sides):
            a = 2 * math.pi * s / sides
            v = p + (n * math.cos(a) + b * math.sin(a)) * radii[i]
            verts.append(tuple(v))
    for i in range(len(pts) - 1):
        for s in range(sides):
            a = i * sides + s
            bb = i * sides + (s + 1) % sides
            faces.append((a, bb, bb + sides, a + sides))
    if cap:
        faces.append(tuple(reversed(range(sides))))
        last = (len(pts) - 1) * sides
        faces.append(tuple(range(last, last + sides)))
    return verts, faces


def cylinder(radius, z0, z1, sides=16, center=(0, 0), r_top=None):
    """Cilindro (o tronco de cono) vertical entre z0 y z1."""
    cx, cy = center
    rt = radius if r_top is None else r_top
    verts = []
    for z, r in ((z0, radius), (z1, rt)):
        for s in range(sides):
            a = 2 * math.pi * s / sides
            verts.append((cx + r * math.cos(a), cy + r * math.sin(a), z))
    faces = [(s, (s + 1) % sides, sides + (s + 1) % sides, sides + s) for s in range(sides)]
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple(range(sides, 2 * sides)))
    return verts, faces


def lathe(profile, sides=16):
    """Sólido de revolución alrededor de Z. profile = [(radio, z)] de abajo hacia arriba."""
    verts, faces = [], []
    for r, z in profile:
        for s in range(sides):
            a = 2 * math.pi * s / sides
            verts.append((r * math.cos(a), r * math.sin(a), z))
    for i in range(len(profile) - 1):
        for s in range(sides):
            a = i * sides + s
            b = i * sides + (s + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    if profile[0][0] > 0:
        faces.append(tuple(reversed(range(sides))))
    if profile[-1][0] > 0:
        last = (len(profile) - 1) * sides
        faces.append(tuple(range(last, last + sides)))
    return verts, faces


def combine(*parts):
    """Une varias (verts, faces) en una sola malla."""
    verts, faces = [], []
    for v, f in parts:
        off = len(verts)
        verts += list(v)
        faces += [tuple(i + off for i in face) for face in f]
    return verts, faces


def transform(part, offset=(0, 0, 0), rot_x=0.0, rot_y=0.0, rot_z=0.0):
    from mathutils import Euler, Vector

    v, f = part
    e = Euler((rot_x, rot_y, rot_z), "XYZ")
    o = Vector(offset)
    out = []
    for p in v:
        q = Vector(p)
        q.rotate(e)
        out.append(tuple(q + o))
    return out, f


def piece(name, part, mat, rect, axis=("x", "z")):
    """Crea un objeto con su región del atlas (UV por proyección)."""
    obj = mesh_object(name, *part)
    obj.data.materials.append(mat)
    uv_from_rect(obj, rect, axis=axis)
    flat_shade(obj)
    return obj


def join(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


def paint_regions(regions):
    """Painter de atlas por regiones: [(rect_uv, fn(u, v) -> (r, g, b))] con u, v en 0..1 locales."""

    def painter(px, w, h):
        for y in range(h):
            for x in range(w):
                u, v = (x + 0.5) / w, (y + 0.5) / h
                color = (1.0, 0.0, 1.0)
                for (u0, v0, u1, v1), fn in regions:
                    if u0 <= u < u1 and v0 <= v < v1:
                        color = fn((u - u0) / (u1 - u0), (v - v0) / (v1 - v0))
                        break
                i = (y * w + x) * 4
                px[i : i + 4] = [color[0], color[1], color[2], 1.0]

    return painter
