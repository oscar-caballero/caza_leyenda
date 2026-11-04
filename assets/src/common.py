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
    status = "OK" if lo <= total <= hi else "FUERA DE PRESUPUESTO"
    print(f"[{name}] TOTAL {total} triángulos (presupuesto {lo}–{hi}): {status}")
    if total > hi:
        sys.exit(1)
    return total
