#!/usr/bin/env python3
"""FlowLine 3D POI pins — Blender source of truth.

Run (when Blender is installed):
  blender --background --python scripts/map/blender_poi_pins.py -- \\
    --root /path/to/aetherride

  # Flatpak (this machine):
  python3 scripts/map/render_poi_pins.py

Writes:
  public/map/pins/poi/*.glb
  public/map/pins/poi/*.blend
  public/map/pins/poi-*.png
  mobile/assets/map/pins/poi-*.png

MapLibre still uses the PNGs (addImage). The .glb/.blend stay the 3D source.
"""

from __future__ import annotations

import math
import os
import sys

# Keep in sync with render_poi_pins.py
ORANGE = (1.0, 0.416, 0.0, 1.0)
ORANGE_PUNCH = (1.0, 0.24, 0.0, 1.0)
SAGE = (0.478, 0.545, 0.451, 1.0)
CHARCOAL = (0.102, 0.071, 0.047, 1.0)
CHARCOAL_SOFT = (0.165, 0.141, 0.125, 1.0)
CREAM = (0.957, 0.945, 0.925, 1.0)
INK = (0.125, 0.110, 0.094, 1.0)
WHITE = (1.0, 1.0, 1.0, 1.0)
GREEN = (0.180, 0.490, 0.196, 1.0)  # #2E7D32

POI_KINDS = (
    "place",
    "trailhead",
    "viewpoint",
    "cafe",
    "culture",
    "water",
    "transit",
    "meetup",
)
ROUTE_PIN_KINDS = (
    "start",
    "start-out",
    "finish",
    "finish-out",
    "meet",
    "stimme",
)
KINDS = POI_KINDS + ROUTE_PIN_KINDS

RENDER_W = 256
RENDER_H = 320


def _argv_after_dash() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return [a for a in sys.argv[1:] if not a.startswith("--python")]


def _parse_root(argv: list[str]) -> str:
    if "--root" in argv:
        return os.path.abspath(argv[argv.index("--root") + 1])
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(here, "..", ".."))


def _require_bpy():
    try:
        import bpy  # type: ignore
    except ImportError as exc:
        raise SystemExit(
            "blender_poi_pins.py needs Blender's Python (bpy).\n"
            "  blender --background --python scripts/map/blender_poi_pins.py"
        ) from exc
    return bpy


def _hex_mat(bpy, name: str, color, roughness: float = 0.42, metallic: float = 0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    # Blender 5.x default SSS shifts orange toward peach/gold.
    for key in ("Subsurface Weight", "Subsurface", "Coat Weight", "Transmission Weight"):
        if key in bsdf.inputs:
            bsdf.inputs[key].default_value = 0.0
    is_orange = name == "orange" or (color[0] > 0.9 and color[1] < 0.5)
    bsdf.inputs["Base Color"].default_value = ORANGE_PUNCH if is_orange else color
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = 0.44 if is_orange else roughness
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = 0.02 if is_orange else metallic
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.18 if is_orange else 0.28
    elif "Specular" in bsdf.inputs:
        bsdf.inputs["Specular"].default_value = 0.18 if is_orange else 0.28
    if is_orange:
        emit = (1.0, 0.08, 0.0, 1.0)
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emit
        elif "Emission" in bsdf.inputs:
            bsdf.inputs["Emission"].default_value = emit
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = 0.78
    return mat


def _assign(obj, mat) -> None:
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def _mesh(bpy, name: str, verts, faces, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(list(verts), [], list(faces))
    mesh.validate()
    mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    _assign(obj, mat)
    return obj


def _clear(bpy) -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras):
        for item in list(block):
            block.remove(item)


def _mat_for_part(part, mats: dict):
    """Match numpy part colors to Blender brand materials."""
    c = part["color"]
    swatches = (
        ((255.0, 106.0, 0.0), "orange"),
        ((122.0, 139.0, 115.0), "sage"),
        ((26.0, 18.0, 12.0), "charcoal"),
        ((42.0, 36.0, 32.0), "charcoal_soft"),
        ((244.0, 241.0, 236.0), "cream"),
        ((32.0, 28.0, 24.0), "ink"),
        ((46.0, 125.0, 50.0), "green"),
        ((255.0, 255.0, 255.0), "white"),
    )
    best, best_d = "ink", 1e18
    for rgb, key in swatches:
        d = sum((float(c[i]) - rgb[i]) ** 2 for i in range(3))
        if d < best_d:
            best, best_d = key, d
    return mats[best]


def _build_pin(bpy, kind: str, mats: dict) -> None:
    # Same meshes as the numpy fallback (render_poi_pins.pin_parts).
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from render_poi_pins import pin_parts  # type: ignore

    for part in pin_parts(kind):
        verts = part["verts"].tolist()
        faces = [tuple(int(i) for i in face) for face in part["faces"]]
        _mesh(bpy, f"{kind}_{part['name']}", verts, faces, _mat_for_part(part, mats))


def _setup_world(bpy) -> None:
    scene = bpy.context.scene
    engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items else "BLENDER_EEVEE"
    try:
        scene.render.engine = engine
    except Exception:
        scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = RENDER_W
    scene.render.resolution_y = RENDER_H
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.dither_intensity = 0.0
    if hasattr(scene, "display_settings"):
        try:
            scene.display_settings.display_device = "sRGB"
        except Exception:
            pass
    if hasattr(scene, "view_settings"):
        try:
            scene.view_settings.view_transform = "Standard"
        except Exception:
            try:
                scene.view_settings.view_transform = "Standard"
            except Exception:
                pass
        try:
            scene.view_settings.look = "None"
        except Exception:
            pass
    if hasattr(scene, "eevee"):
        if hasattr(scene.eevee, "taa_render_samples"):
            scene.eevee.taa_render_samples = 64
        if hasattr(scene.eevee, "use_gtao"):
            scene.eevee.use_gtao = True
    world = bpy.data.worlds.new("poi_world") if not scene.world else scene.world
    scene.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.03, 0.03, 0.03, 1.0)
    bg.inputs[1].default_value = 0.08

    cam_data = bpy.data.cameras.new("poi_cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 1.28
    cam = bpy.data.objects.new("poi_cam", cam_data)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.40, -0.70, 2.02)
    direction = __import__("mathutils").Vector((0.0, 0.02, 0.52)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam

    key = bpy.data.lights.new("key", "SUN")
    key.energy = 1.85
    if hasattr(key, "angle"):
        key.angle = math.radians(18)
    key_obj = bpy.data.objects.new("key", key)
    key_obj.rotation_euler = (math.radians(52), math.radians(8), math.radians(32))
    bpy.context.collection.objects.link(key_obj)

    fill = bpy.data.lights.new("fill", "AREA")
    fill.energy = 1.8
    fill.size = 2.8
    fill.color = (0.78, 0.84, 0.90)
    fill_obj = bpy.data.objects.new("fill", fill)
    fill_obj.location = (-1.5, -0.5, 2.0)
    fill_obj.rotation_euler = (math.radians(58), 0.0, math.radians(-22))
    bpy.context.collection.objects.link(fill_obj)

    rim = bpy.data.lights.new("rim", "SUN")
    rim.energy = 0.45
    rim_obj = bpy.data.objects.new("rim", rim)
    rim_obj.rotation_euler = (math.radians(112), math.radians(-18), math.radians(-78))
    bpy.context.collection.objects.link(rim_obj)


def _copy(src: str, dst: str) -> None:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(src, "rb") as f:
        data = f.read()
    with open(dst, "wb") as f:
        f.write(data)


def main() -> int:
    bpy = _require_bpy()
    root = _parse_root(_argv_after_dash())
    public_png = os.path.join(root, "public", "map", "pins")
    public_3d = os.path.join(public_png, "poi")
    mobile_png = os.path.join(root, "mobile", "assets", "map", "pins")
    os.makedirs(public_3d, exist_ok=True)
    os.makedirs(mobile_png, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats = {
        "orange": _hex_mat(bpy, "orange", ORANGE, 0.44, 0.02),
        "sage": _hex_mat(bpy, "sage", SAGE, 0.52),
        "charcoal": _hex_mat(bpy, "charcoal", CHARCOAL, 0.58),
        "charcoal_soft": _hex_mat(bpy, "charcoal_soft", CHARCOAL_SOFT, 0.52),
        "cream": _hex_mat(bpy, "cream", CREAM, 0.32),
        "ink": _hex_mat(bpy, "ink", INK, 0.48),
        "white": _hex_mat(bpy, "white", WHITE, 0.28),
        "green": _hex_mat(bpy, "green", GREEN, 0.44),
    }
    _setup_world(bpy)

    for kind in KINDS:
        for obj in list(bpy.data.objects):
            if obj.type == "MESH":
                bpy.data.objects.remove(obj, do_unlink=True)
        _build_pin(bpy, kind, mats)

        stem = "poi" if kind == "place" else (
            f"pin-{kind}" if kind in ROUTE_PIN_KINDS else f"poi-{kind}"
        )
        png = os.path.join(public_png, f"{stem}.png")
        glb = os.path.join(public_3d, f"{stem}.glb")
        blend = os.path.join(public_3d, f"{stem}.blend")
        bpy.context.scene.view_settings.view_transform = "Standard"
        bpy.context.scene.render.filepath = png
        bpy.ops.render.render(write_still=True)
        try:
            bpy.ops.export_scene.gltf(
                filepath=glb,
                export_format="GLB",
                use_selection=False,
                export_animations=False,
                export_extras=False,
            )
        except TypeError:
            bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB")
        bpy.ops.wm.save_as_mainfile(filepath=blend)
        _copy(png, os.path.join(mobile_png, f"{stem}.png"))
        print(f"blender ok {stem}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
