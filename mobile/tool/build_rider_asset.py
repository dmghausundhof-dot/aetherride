#!/usr/bin/env python3
"""FlowLine-Fahrer — durchgehender Körper, Rig, Tretzyklus.

Aufruf:
  flatpak run --filesystem=home org.blender.Blender --background --python mobile/tool/build_rider_asset.py
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "community" / "rider"
OUT.mkdir(parents=True, exist_ok=True)

# AppColors / HOF_TOKENS — sRGB 0–1, nicht erfunden.
ORANGE = (1.0, 0.416, 0.0)  # #FF6A00 chrome / accent
ORANGE_PUNCH = (1.0, 0.28, 0.0)  # Emission, hält AgX vom Pfirsich fern
CHARCOAL = (0.122, 0.122, 0.122)  # #1F1F1F
HOF = (0.071, 0.071, 0.082)  # #121215
SURFACE = (0.118, 0.118, 0.149)  # #1E1E26
CREAM = (0.957, 0.945, 0.925)  # #F4F1EC pin-plate
INK = (0.122, 0.122, 0.129)
SAGE = (0.478, 0.545, 0.451)  # #7A8B73 — nur Set, nie Haut
STEEL = (0.55, 0.57, 0.60)
RUBBER = (0.045, 0.045, 0.048)
SKIN = (0.80, 0.60, 0.47)
SKIN_WARM = (0.74, 0.52, 0.40)
STALE = (0.55, 0.55, 0.58)
CHAIN_COL = (0.035, 0.034, 0.036)

# Bike (meters, +X forward, +Z up). Drive side = −Y = Kameraseite.
R_WHEEL = 0.35
REAR = Vector((-0.53, 0.0, R_WHEEL))
FRONT = Vector((0.54, 0.0, R_WHEEL))
BB = Vector((0.02, 0.0, 0.275))
SADDLE = Vector((-0.28, 0.0, 0.96))
HOOD_L = Vector((0.54, 0.20, 0.938))
HOOD_R = Vector((0.54, -0.20, 0.938))
CRANK_LEN = 0.168
PEDAL_Y = 0.12
DRIVE_Y = -0.090
CHAIN_Y = -0.152

# Rider
HIP = Vector((-0.26, 0.0, 0.99))
THIGH_LEN = 0.40
CALF_LEN = 0.39
FRAMES = 24


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.render.fps = 24
    scene.frame_start = 1
    scene.frame_end = FRAMES
    scene.frame_current = 1


def _bsdf(mat):
    return next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")


def principled(name, color, roughness=0.42, metallic=0.0, **kw):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = _bsdf(mat)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic
    # Blender 5.x: Default-SSS färbt Orange/Jersey zu Pfirsich.
    for key, val in (
        ("Subsurface Weight", 0.0),
        ("Subsurface", 0.0),
        ("Coat Weight", 0.0),
        ("Transmission Weight", 0.0),
    ):
        if key in bsdf.inputs:
            bsdf.inputs[key].default_value = val
    for key, val in kw.items():
        label = key.replace("_", " ").title()
        if label in bsdf.inputs:
            bsdf.inputs[label].default_value = val
        elif key in bsdf.inputs:
            bsdf.inputs[key].default_value = val
    mat.diffuse_color = (*color, 1.0)
    return mat


def skin_mat(name, color=SKIN):
    mat = principled(name, color, roughness=0.48)
    bsdf = _bsdf(mat)
    if "Subsurface Weight" in bsdf.inputs:
        bsdf.inputs["Subsurface Weight"].default_value = 0.18
        if "Subsurface Radius" in bsdf.inputs:
            bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.22, 0.11)
    elif "Subsurface" in bsdf.inputs:
        bsdf.inputs["Subsurface"].default_value = 0.18
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.35
    return mat


def fabric(name, color, roughness=0.58):
    mat = principled(name, color, roughness=roughness)
    bsdf = _bsdf(mat)
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.35
        if "Sheen Roughness" in bsdf.inputs:
            bsdf.inputs["Sheen Roughness"].default_value = 0.45
    if color in (ORANGE, ORANGE_PUNCH):
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (1.0, 0.18, 0.0, 1)
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = 0.85
    return mat


def signal_orange(name, strength=0.95, roughness=0.40):
    """FlowLine-Accent #FF6A00 — rötliche Emission, damit Key-Licht nicht gelb wäscht."""
    base = (1.0, 0.30, 0.0)
    emit = (1.0, 0.08, 0.0)
    mat = principled(name, base, roughness=roughness)
    bsdf = _bsdf(mat)
    if "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
    elif "Emission" in bsdf.inputs:
        bsdf.inputs["Emission"].default_value = (*emit, 1.0)
    if "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = strength
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.22
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.18
    mat.diffuse_color = (*ORANGE, 1.0)
    return mat


def lamp_orange(name, strength=3.4):
    """Flasche: Emission gemischt, überlebt AgX nicht — plus Standard-View."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    mix = nt.nodes.new("ShaderNodeMixShader")
    em = nt.nodes.new("ShaderNodeEmission")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    col = (*ORANGE, 1.0)
    if "Base Color" in bsdf.inputs:
        bsdf.inputs["Base Color"].default_value = col
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = 0.22
    em.inputs[0].default_value = (1.0, 0.08, 0.0, 1)
    em.inputs[1].default_value = strength
    mix.inputs[0].default_value = 0.55
    nt.links.new(bsdf.outputs[0], mix.inputs[1])
    nt.links.new(em.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    mat.diffuse_color = col
    return mat


def mesh(name, primitive, **kw):
    op = getattr(bpy.ops.mesh, f"primitive_{primitive}_add")
    op(**kw)
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_mode = "XYZ"
    return obj


def apply(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def shade_smooth(obj):
    data = obj.data
    for p in data.polygons:
        p.use_smooth = True
    if hasattr(data, "use_auto_smooth"):
        data.use_auto_smooth = True
        if hasattr(data, "auto_smooth_angle"):
            data.auto_smooth_angle = math.radians(35)
    try:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        if hasattr(bpy.ops.object, "shade_auto_smooth"):
            bpy.ops.object.shade_auto_smooth(angle=math.radians(35))
        else:
            bpy.ops.object.shade_smooth()
        obj.select_set(False)
    except Exception:
        pass


def _track(a: Vector, b: Vector) -> Euler:
    d = b - a
    if d.length < 1e-8:
        return Euler((0, 0, 0))
    return d.to_track_quat("Z", "Y").to_euler()


def place_z(obj, a: Vector, b: Vector, rest_len: float | None = None):
    sx, sy = obj.scale.x, obj.scale.y
    obj.location = (a + b) * 0.5
    obj.rotation_euler = _track(a, b)
    length = (b - a).length
    base = rest_len if rest_len else length
    if base and base > 1e-6:
        obj.scale = (sx if sx else 1.0, sy if sy else 1.0, length / base)


def ball(name, loc, radius, mat, segs=20):
    obj = mesh(name, "uv_sphere", radius=radius, segments=segs, ring_count=max(10, segs // 2))
    obj.location = loc
    apply(obj, mat)
    shade_smooth(obj)
    return obj


def ellipsoid(name, loc, radii, mat, segs=22, rot=None):
    obj = mesh(name, "uv_sphere", radius=1.0, segments=segs, ring_count=14)
    obj.location = loc
    obj.scale = radii
    if rot:
        obj.rotation_euler = rot
    apply(obj, mat)
    shade_smooth(obj)
    return obj


def _join(name, objs):
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    objs[0].select_set(False)
    return objs[0]


def _unify_mesh(name, objs, voxel=0.008, smooth=8, remesh=True):
    """Schale zusammenziehen — Voxel nur als Modifier, optional."""
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        o.select_set(False)
    joined = _join(name, objs)
    bpy.context.view_layer.objects.active = joined
    joined.select_set(True)
    if remesh:
        rem = joined.modifiers.new("rm", "REMESH")
        rem.mode = "VOXEL"
        rem.voxel_size = voxel
        if hasattr(rem, "use_smooth_shade"):
            rem.use_smooth_shade = True
        bpy.ops.object.modifier_apply(modifier=rem.name)
        sm = joined.modifiers.new("sm", "SMOOTH")
        sm.factor = 0.55
        sm.iterations = smooth
        bpy.ops.object.modifier_apply(modifier=sm.name)
    shade_smooth(joined)
    joined.select_set(False)
    return joined


def capsule(name, a: Vector, b: Vector, r0: float, r1: float, mat, segs=16):
    length = max((b - a).length, 0.01)
    obj = mesh(name, "cone", radius1=r0, radius2=r1, depth=length, vertices=segs)
    obj.location = (a + b) * 0.5
    obj.rotation_euler = _track(a, b)
    apply(obj, mat)
    shade_smooth(obj)
    cap_a = ball(f"{name}_cap_a", a, r0, mat, segs=14)
    cap_b = ball(f"{name}_cap_b", b, r1, mat, segs=14)
    joined = _join(name, [obj, cap_a, cap_b])
    return joined, None, None


def look_at(obj, target: Vector):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def pedal_pos(theta: float, side: float) -> Vector:
    return Vector(
        (
            BB.x + CRANK_LEN * math.sin(theta),
            PEDAL_Y * side,
            BB.z - CRANK_LEN * math.cos(theta),
        )
    )


def ik_knee(hip: Vector, foot: Vector, thigh: float, calf: float) -> Vector:
    """Knie in der Sagittalebene, nach vorn/oben (Fahrpose)."""
    dx = foot.x - hip.x
    dz = foot.z - hip.z
    y = (hip.y + foot.y) * 0.5
    d = math.hypot(dx, dz)
    d = min(max(d, 0.08), thigh + calf - 0.012)
    base = math.atan2(dz, dx)
    cos_a = (thigh * thigh + d * d - calf * calf) / (2.0 * thigh * d)
    cos_a = max(-1.0, min(1.0, cos_a))
    a = math.acos(cos_a)
    ang = base + a
    return Vector((hip.x + thigh * math.cos(ang), y + (foot.y - hip.y) * 0.15, hip.z + thigh * math.sin(ang)))


def key_obj(obj, frame, loc=True, rot=True, scale=False):
    if loc:
        obj.keyframe_insert("location", frame=frame)
    if rot:
        obj.keyframe_insert("rotation_euler", frame=frame)
    if scale:
        obj.keyframe_insert("scale", frame=frame)


def cyclic_fcurves(obj):
    ad = obj.animation_data
    if not ad:
        return
    action = getattr(ad, "action", None)
    if not action:
        return
    curves = getattr(action, "fcurves", None)
    if not curves:
        return
    for fc in curves:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
        try:
            fc.modifiers.new(type="CYCLES")
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Bike
# ---------------------------------------------------------------------------


def _spokes(name, center, radius, mat, count=16):
    objs = []
    for i in range(count):
        ang = i * (2 * math.pi / count)
        a = center + Vector((0.034 * math.cos(ang), 0, 0.034 * math.sin(ang)))
        b = center + Vector((radius * math.cos(ang), 0, radius * math.sin(ang)))
        spoke = mesh(f"{name}_{i}", "cylinder", radius=0.0034, depth=(b - a).length, vertices=6)
        spoke.location = (a + b) * 0.5
        spoke.rotation_euler = _track(a, b)
        apply(spoke, mat)
        objs.append(spoke)
    return objs


def _tube(name, a, b, r, mat):
    obj = mesh(name, "cylinder", radius=r, depth=max((b - a).length, 0.02), vertices=14)
    obj.location = (a + b) * 0.5
    obj.rotation_euler = _track(a, b)
    apply(obj, mat)
    shade_smooth(obj)
    return obj


def _slab(name, loc, size, mat, rot=None):
    obj = mesh(name, "cube", size=1.0)
    obj.location = loc
    obj.scale = size
    if rot:
        obj.rotation_euler = rot
    apply(obj, mat)
    shade_smooth(obj)
    return obj


def _lug(name, loc, r, mat):
    return ball(name, loc, r, mat, segs=12)


def _polyline(name, pts, r, mat):
    out = []
    for i in range(len(pts) - 1):
        out.append(_tube(f"{name}_{i}", pts[i], pts[i + 1], r, mat))
    return out


def _chain_arc(name, center, radius, y, mat, r, a0, a1, n=6):
    pts = []
    for i in range(n + 1):
        t = a0 + (a1 - a0) * i / n
        pts.append(Vector((center.x + radius * math.sin(t), y, center.z + radius * math.cos(t))))
    return _polyline(name, pts, r, mat)


def build_bike(mats):
    rubber, steel, ink, orange, cream, frame = mats
    parts = {}

    def _empty(name, loc):
        e = bpy.data.objects.new(name, None)
        e.location = loc
        e.empty_display_size = 0.08
        bpy.context.scene.collection.objects.link(e)
        return e

    def _parent(obj, parent):
        mw = obj.matrix_world.copy()
        obj.parent = parent
        bpy.context.view_layer.update()
        obj.matrix_world = mw

    for tag, hub in (("rear", REAR), ("front", FRONT)):
        spin = _empty(f"wheel_{tag}_spin", hub)
        tire = mesh(
            f"tire_{tag}",
            "torus",
            major_radius=0.316,
            minor_radius=0.028,
            major_segments=44,
            minor_segments=14,
        )
        tire.location = hub
        tire.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(tire, rubber)
        shade_smooth(tire)
        rim = mesh(
            f"rim_{tag}",
            "torus",
            major_radius=0.298,
            minor_radius=0.013,
            major_segments=40,
            minor_segments=10,
        )
        rim.location = hub
        rim.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(rim, steel)
        shade_smooth(rim)
        rim_accent = mesh(
            f"rim_accent_{tag}",
            "torus",
            major_radius=0.292,
            minor_radius=0.0075,
            major_segments=36,
            minor_segments=8,
        )
        rim_accent.location = hub
        rim_accent.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(rim_accent, orange)
        shade_smooth(rim_accent)
        brake_track = mesh(
            f"track_{tag}",
            "torus",
            major_radius=0.284,
            minor_radius=0.005,
            major_segments=36,
            minor_segments=8,
        )
        brake_track.location = hub
        brake_track.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(brake_track, ink)
        hub_o = mesh(f"hub_{tag}", "cylinder", radius=0.026, depth=0.118, vertices=16)
        hub_o.location = hub
        hub_o.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(hub_o, ink)
        flange = mesh(f"flange_{tag}", "cylinder", radius=0.058, depth=0.044, vertices=16)
        flange.location = hub
        flange.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(flange, orange)
        rotor = mesh(f"rotor_{tag}", "cylinder", radius=0.078, depth=0.004, vertices=24)
        rotor.location = hub + Vector((0, DRIVE_Y * 0.85, 0))
        rotor.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(rotor, ink)
        rotor_in = mesh(f"rotor_in_{tag}", "cylinder", radius=0.032, depth=0.006, vertices=12)
        rotor_in.location = rotor.location
        rotor_in.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(rotor_in, steel)
        cap = mesh(f"axle_{tag}", "cylinder", radius=0.012, depth=0.132, vertices=10)
        cap.location = hub
        cap.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(cap, steel)
        spokes = _spokes(f"spoke_{tag}", hub, 0.286, ink)
        spinning = (
            tire,
            rim,
            rim_accent,
            brake_track,
            hub_o,
            flange,
            rotor,
            rotor_in,
            cap,
            *spokes,
        )
        for obj in spinning:
            _parent(obj, spin)
        parts[f"wheel_{tag}"] = list(spinning)
        parts[f"spin_{tag}"] = spin

    ht = Vector((0.36, 0, 0.84))
    st = Vector((-0.20, 0, 0.80))
    crown = ht + Vector((0.038, 0, -0.055))
    dt_a = BB + Vector((0.03, 0, 0.03))
    dt_b = ht + Vector((-0.03, 0, -0.08))
    tt_a = st + Vector((0.05, 0, 0.07))
    tt_b = ht + Vector((-0.02, 0, 0.045))
    st_a = BB + Vector((-0.02, 0, 0.04))
    _tube("tube_down", dt_a, dt_b, 0.024, frame)
    _tube("tube_top", tt_a, tt_b, 0.019, frame)
    _tube("tube_seat", st_a, st, 0.018, frame)
    _tube("seatpost", st, SADDLE + Vector((0.01, 0, -0.03)), 0.013, ink)
    _tube("stay_l", REAR + Vector((0.03, 0.042, 0.01)), st + Vector((0.01, 0.018, -0.03)), 0.012, frame)
    _tube("stay_r", REAR + Vector((0.03, -0.042, 0.01)), st + Vector((0.01, -0.018, -0.03)), 0.012, frame)
    _tube("cs_l", REAR + Vector((0.04, 0.042, 0)), BB + Vector((0, 0.032, 0)), 0.013, frame)
    _tube("cs_r", REAR + Vector((0.04, -0.042, 0)), BB + Vector((0, -0.032, 0)), 0.013, frame)
    _tube("accent_tt", st + Vector((0.08, 0, 0.042)), ht + Vector((-0.10, 0, 0.048)), 0.014, orange)
    _tube("accent_dt", dt_a + Vector((0.012, 0, 0.018)), dt_b + Vector((0.0, 0, 0.014)), 0.011, orange)
    # Kameraseite (−Y): Streifen nicht hinter dem Torso verstecken.
    _tube(
        "accent_dt_cam",
        dt_a + Vector((0.008, -0.024, 0.010)),
        dt_b + Vector((0.0, -0.022, 0.006)),
        0.016,
        orange,
    )
    _tube(
        "accent_st_cam",
        st_a + Vector((0.0, -0.018, 0.0)),
        st + Vector((0.0, -0.016, 0.0)),
        0.011,
        orange,
    )
    _lug("lug_bb", BB, 0.038, ink)
    _lug("lug_ht_lo", ht + Vector((-0.01, 0, -0.06)), 0.028, ink)
    _lug("lug_ht_hi", ht + Vector((0.01, 0, 0.05)), 0.024, ink)
    _lug("lug_st", st, 0.026, ink)
    _lug("lug_st_tt", tt_a, 0.022, ink)

    # Gabel: Krone als Querbalken, Holme leicht nach vorn gereckt, klare Ausfallenden.
    _slab("fork_crown", crown, (0.028, 0.078, 0.022), ink)
    for sign in (1, -1):
        blade_top = crown + Vector((0.004, sign * 0.028, -0.012))
        dropout = FRONT + Vector((-0.018, sign * 0.058, 0.0))
        mid = blade_top.lerp(dropout, 0.46) + Vector((0.016, sign * 0.006, 0))
        _tube(f"fork_{sign}", blade_top, mid, 0.013, ink)
        _tube(f"forkb_{sign}", mid, dropout, 0.0115, ink)
        _slab(f"dropout_{sign}", dropout, (0.018, 0.012, 0.022), ink)
        cal = ellipsoid(
            f"caliper_{sign}",
            dropout + Vector((0.018, sign * 0.010, 0.068)),
            (0.026, 0.014, 0.028),
            ink,
            segs=10,
        )
        cal.rotation_euler = Euler((0, math.radians(10), 0))

    _tube("head", ht + Vector((-0.01, 0, -0.10)), ht + Vector((0.025, 0, 0.10)), 0.020, ink)
    spacer = mesh("spacer", "cylinder", radius=0.018, depth=0.024, vertices=12)
    spacer.location = ht + Vector((0.02, 0, 0.088))
    spacer.rotation_euler = _track(ht, ht + Vector((0.03, 0, 0.12)))
    apply(spacer, ink)
    _tube("stem", ht + Vector((0.025, 0, 0.09)), Vector((0.448, 0, 0.954)), 0.013, ink)
    _slab("stem_face", Vector((0.450, 0, 0.954)), (0.022, 0.030, 0.018), ink)
    ellipsoid("stem_cap", ht + Vector((0.028, 0, 0.112)), (0.016, 0.016, 0.010), steel, segs=10)

    # Dropbar: Oberlenker + J-Drop in kurzen Segmenten (kein Torus-Ring).
    bar = mesh("bar_top", "cylinder", radius=0.012, depth=0.40, vertices=14)
    bar.location = (0.452, 0, 0.960)
    bar.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(bar, ink)
    shade_smooth(bar)
    tape = mesh("bar_tape", "cylinder", radius=0.0155, depth=0.22, vertices=12)
    tape.location = (0.452, 0, 0.960)
    tape.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(tape, cream)
    for i, y in enumerate((0.20, -0.20)):
        drop_pts = (
            Vector((0.452, y, 0.960)),
            Vector((0.492, y, 0.928)),
            Vector((0.518, y, 0.882)),
            Vector((0.508, y, 0.838)),
            Vector((0.458, y, 0.822)),
            Vector((0.408, y, 0.834)),
        )
        _polyline(f"drop_{i}", drop_pts, 0.013, ink)
        for j, p in enumerate(drop_pts[1:-1]):
            ball(f"drop_joint_{i}_{j}", p, 0.0135, ink, segs=10)
        _polyline(
            f"tape_{i}",
            (
                Vector((0.488, y, 0.932)),
                Vector((0.516, y, 0.884)),
                Vector((0.506, y, 0.840)),
            ),
            0.0145,
            cream,
        )
        hood = ellipsoid(
            f"hood_{i}",
            Vector((0.558, y, 0.944)),
            (0.082, 0.026, 0.034),
            rubber,
            segs=16,
        )
        hood.rotation_euler = Euler((0, math.radians(18), 0))
        ellipsoid(
            f"hood_body_{i}",
            Vector((0.528, y, 0.928)),
            (0.042, 0.020, 0.026),
            rubber,
            segs=12,
        )
        _slab(
            f"lever_{i}",
            Vector((0.582, y, 0.858)),
            (0.011, 0.009, 0.062),
            ink,
            rot=Euler((0, math.radians(26), 0)),
        )
        _slab(
            f"shift_{i}",
            Vector((0.562, y + (0.012 if y > 0 else -0.012), 0.872)),
            (0.008, 0.007, 0.040),
            ink,
            rot=Euler((0, math.radians(22), 0)),
        )
        ellipsoid(
            f"hood_cap_{i}",
            Vector((0.598, y, 0.952)),
            (0.018, 0.015, 0.016),
            cream,
            segs=10,
        )

    saddle = ellipsoid("saddle", SADDLE + Vector((-0.02, 0, 0.006)), (0.108, 0.072, 0.028), ink, segs=18)
    saddle.rotation_euler = Euler((0, math.radians(-8), 0))
    saddle_n = ellipsoid("saddle_nose", SADDLE + Vector((0.078, 0, -0.002)), (0.062, 0.026, 0.016), ink, segs=12)
    saddle_n.rotation_euler = Euler((0, math.radians(-12), 0))
    _slab("saddle_pad", SADDLE + Vector((-0.03, 0, 0.016)), (0.070, 0.058, 0.010), ink)
    _tube("saddle_rail", SADDLE + Vector((-0.05, 0.012, -0.018)), SADDLE + Vector((0.04, 0.008, -0.016)), 0.005, steel)
    _tube("saddle_rail_b", SADDLE + Vector((-0.05, -0.012, -0.018)), SADDLE + Vector((0.04, -0.008, -0.016)), 0.005, steel)

    # Flasche am Unterrohr, zur Kamera versetzt — eigenes Orange, nicht Jersey.
    dt_dir = (dt_b - dt_a).normalized()
    bottle_c = dt_a.lerp(dt_b, 0.40) + Vector((0.0, -0.046, 0.010))
    bottle_rot = _track(dt_a, dt_b)
    bottle = mesh("bottle", "cylinder", radius=0.036, depth=0.168, vertices=16)
    bottle.location = bottle_c
    bottle.rotation_euler = bottle_rot
    apply(bottle, orange)
    shade_smooth(bottle)
    ellipsoid("bottle_shoulder", bottle_c + dt_dir * 0.078, (0.030, 0.030, 0.022), orange, segs=12)
    neck = mesh("bottle_neck", "cylinder", radius=0.014, depth=0.028, vertices=10)
    neck.location = bottle_c + dt_dir * 0.098
    neck.rotation_euler = bottle_rot
    apply(neck, ink)
    ellipsoid("bottle_cap", bottle_c + dt_dir * 0.116, (0.016, 0.016, 0.014), cream, segs=10)
    band = mesh("bottle_label", "cylinder", radius=0.0385, depth=0.034, vertices=16)
    band.location = bottle_c + dt_dir * 0.006
    band.rotation_euler = bottle_rot
    apply(band, ink)
    side = Vector((0.0, 1.0, 0.0))
    _tube("cage_up", bottle_c + side * 0.032 - dt_dir * 0.055, bottle_c + side * 0.032 + dt_dir * 0.062, 0.0045, steel)
    _tube("cage_dn", bottle_c - side * 0.016 - dt_dir * 0.055, bottle_c - side * 0.016 + dt_dir * 0.062, 0.0045, steel)
    _tube("cage_base", bottle_c + side * 0.032 - dt_dir * 0.058, bottle_c - side * 0.016 - dt_dir * 0.058, 0.0045, steel)
    _tube("cage_lip", bottle_c + side * 0.032 + dt_dir * 0.064, bottle_c - side * 0.016 + dt_dir * 0.064, 0.0045, steel)
    _tube("cage_boss", bottle_c + Vector((0.012, 0.012, 0.0)), dt_a.lerp(dt_b, 0.40), 0.0055, steel)

    chain_mat = principled("chain", CHAIN_COL, 0.38, metallic=0.42)

    # Antrieb auf der Kameraseite, Kette außerhalb des Beins.
    ring = mesh("chainring", "cylinder", radius=0.096, depth=0.009, vertices=36)
    ring.location = BB + Vector((0, DRIVE_Y, 0))
    ring.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(ring, steel)
    ring2 = mesh("chainring_in", "cylinder", radius=0.052, depth=0.016, vertices=22)
    ring2.location = BB + Vector((0, DRIVE_Y - 0.004, 0))
    ring2.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(ring2, ink)
    teeth = mesh("chainring_teeth", "cylinder", radius=0.106, depth=0.007, vertices=40)
    teeth.location = BB + Vector((0, DRIVE_Y, 0))
    teeth.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(teeth, steel)
    for i in range(5):
        ang = i * (2 * math.pi / 5)
        _tube(
            f"spider_{i}",
            BB + Vector((0.018 * math.cos(ang), DRIVE_Y, 0.018 * math.sin(ang))),
            BB + Vector((0.078 * math.cos(ang), DRIVE_Y, 0.078 * math.sin(ang))),
            0.0075,
            ink,
        )
    for i in range(12):
        ang = i * (2 * math.pi / 12)
        _slab(
            f"tooth_{i}",
            BB + Vector((0.104 * math.cos(ang), DRIVE_Y, 0.104 * math.sin(ang))),
            (0.016, 0.007, 0.011),
            steel,
            rot=Euler((0, -ang, 0)),
        )

    bb_shell = mesh("bb_shell", "cylinder", radius=0.034, depth=0.082, vertices=16)
    bb_shell.location = BB
    bb_shell.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(bb_shell, ink)

    for i, rad in enumerate((0.054, 0.046, 0.038, 0.030)):
        cog = mesh(f"cassette_{i}", "cylinder", radius=rad, depth=0.008, vertices=18)
        cog.location = REAR + Vector((0, DRIVE_Y - 0.007 * i, 0))
        cog.rotation_euler = Euler((math.pi / 2, 0, 0))
        apply(cog, steel if i % 2 == 0 else ink)

    ring_r = 0.100
    cas_r = 0.046
    _tube(
        "chain_top",
        BB + Vector((0.012, CHAIN_Y, ring_r)),
        REAR + Vector((0.012, CHAIN_Y, cas_r)),
        0.013,
        chain_mat,
    )
    hanger = REAR + Vector((0.048, DRIVE_Y, -0.058))
    _tube(
        "chain_bot",
        BB + Vector((0.012, CHAIN_Y, -ring_r)),
        hanger + Vector((0.04, CHAIN_Y - DRIVE_Y, -0.04)),
        0.013,
        chain_mat,
    )
    _chain_arc("chain_wrap_f", BB, ring_r, CHAIN_Y, chain_mat, 0.012, 0.0, math.pi, n=7)
    _chain_arc("chain_wrap_r", REAR, cas_r, CHAIN_Y, chain_mat, 0.012, math.pi * 0.15, -math.pi * 0.55, n=5)

    _tube("rd_arm", hanger, hanger + Vector((0.042, 0, -0.058)), 0.008, ink)
    ellipsoid("rd_cage", hanger + Vector((0.052, 0, -0.074)), (0.030, 0.014, 0.040), ink, segs=10)
    pulley = mesh("rd_pulley", "cylinder", radius=0.016, depth=0.010, vertices=10)
    pulley.location = hanger + Vector((0.058, 0, -0.092))
    pulley.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(pulley, steel)
    pulley_b = mesh("rd_pulley_b", "cylinder", radius=0.013, depth=0.009, vertices=10)
    pulley_b.location = hanger + Vector((0.038, 0, -0.058))
    pulley_b.rotation_euler = Euler((math.pi / 2, 0, 0))
    apply(pulley_b, steel)

    ellipsoid(
        "caliper_r",
        REAR + Vector((0.05, DRIVE_Y * 0.7, 0.08)),
        (0.026, 0.014, 0.030),
        ink,
        segs=10,
    )

    crank_l = mesh("crank_l", "cylinder", radius=0.015, depth=CRANK_LEN, vertices=12)
    crank_r = mesh("crank_r", "cylinder", radius=0.015, depth=CRANK_LEN, vertices=12)
    crank_l.scale = (1.45, 0.38, 1.0)
    crank_r.scale = (1.45, 0.38, 1.0)
    apply(crank_l, steel)
    apply(crank_r, steel)
    shade_smooth(crank_l)
    shade_smooth(crank_r)
    pedal_l = _slab("pedal_l", pedal_pos(math.pi, 1), (0.082, 0.034, 0.018), ink)
    pedal_r = _slab("pedal_r", pedal_pos(0, -1), (0.082, 0.034, 0.018), ink)
    plate_l = _slab("pedal_l_plate", pedal_pos(math.pi, 1) + Vector((0, 0, 0.008)), (0.070, 0.026, 0.008), steel)
    plate_r = _slab("pedal_r_plate", pedal_pos(0, -1) + Vector((0, 0, 0.008)), (0.070, 0.026, 0.008), steel)
    _parent(plate_l, pedal_l)
    _parent(plate_r, pedal_r)

    parts["crank"] = [crank_l, crank_r, ring, ring2, teeth, pedal_l, pedal_r]
    parts["pedal_l"] = pedal_l
    parts["pedal_r"] = pedal_r
    parts["crank_l"] = crank_l
    parts["crank_r"] = crank_r
    return parts


def build_helmet(head_c: Vector, neck_a: Vector, helmet_mat, visor_mat, jersey, ink, skin):
    """Aero-Helm extra (nicht am Body): Charcoal-Schale, oranger Streifen + Vents."""
    extras = []
    tilt = Euler((0, math.radians(16), 0))

    shell = ellipsoid(
        "helmet",
        head_c + Vector((0.014, 0, 0.078)),
        (0.128, 0.112, 0.108),
        helmet_mat,
        segs=28,
    )
    shell.rotation_euler = tilt
    tail = ellipsoid(
        "helmet_tail",
        head_c + Vector((-0.122, 0, 0.046)),
        (0.142, 0.078, 0.056),
        helmet_mat,
        segs=20,
    )
    tail.rotation_euler = Euler((0, math.radians(36), 0))
    tip = ellipsoid(
        "helmet_tip",
        head_c + Vector((-0.208, 0, 0.010)),
        (0.068, 0.046, 0.030),
        helmet_mat,
        segs=12,
    )
    tip.rotation_euler = Euler((0, math.radians(40), 0))
    brow = ellipsoid(
        "helmet_brow",
        head_c + Vector((0.092, 0, 0.052)),
        (0.056, 0.104, 0.050),
        helmet_mat,
        segs=18,
    )
    brow.rotation_euler = Euler((0, math.radians(6), 0))
    peak = ellipsoid(
        "helmet_peak",
        head_c + Vector((0.148, 0, 0.012)),
        (0.038, 0.100, 0.012),
        helmet_mat,
        segs=14,
    )
    peak.rotation_euler = Euler((0, math.radians(-16), 0))
    rim = ellipsoid(
        "helmet_rim",
        head_c + Vector((0.016, 0, 0.010)),
        (0.116, 0.110, 0.022),
        helmet_mat,
        segs=16,
    )
    rim.rotation_euler = tilt
    extras.append(_unify_mesh("helmet", [shell, tail, tip, brow, peak, rim], voxel=0.0065, smooth=3, remesh=True))

    for i, (dx, dy, dz, sx, sy, sz) in enumerate(
        (
            (0.02, -0.102, 0.088, 0.086, 0.016, 0.022),
            (-0.06, -0.088, 0.072, 0.070, 0.014, 0.018),
            (0.08, -0.090, 0.070, 0.048, 0.014, 0.016),
            (0.00, 0.000, 0.198, 0.100, 0.016, 0.014),
        )
    ):
        vent = ellipsoid(
            f"helmet_vent_{i}",
            head_c + Vector((dx, dy, dz)),
            (sx, sy, sz),
            jersey,
            segs=10,
        )
        vent.rotation_euler = Euler((0, math.radians(16), 0))
        extras.append(vent)

    for i, (off, rad) in enumerate(
        (
            (Vector((0.02, -0.118, 0.074)), (0.110, 0.018, 0.032)),
            (Vector((-0.08, -0.096, 0.052)), (0.080, 0.016, 0.022)),
            (Vector((0.00, 0.000, 0.202)), (0.096, 0.020, 0.016)),
        )
    ):
        stripe = ellipsoid(f"helmet_stripe_{i}", head_c + off, rad, jersey, segs=10)
        stripe.rotation_euler = tilt
        extras.append(stripe)

    glasses = ellipsoid(
        "visor",
        head_c + Vector((0.120, 0, 0.006)),
        (0.026, 0.124, 0.044),
        visor_mat,
        segs=18,
    )
    glasses.rotation_euler = Euler((0, math.radians(8), 0))
    extras.append(glasses)
    extras.append(
        ellipsoid(
            "visor_frame",
            head_c + Vector((0.108, 0, 0.032)),
            (0.012, 0.120, 0.009),
            ink,
            segs=12,
        )
    )
    extras.append(
        ellipsoid(
            "visor_bridge",
            head_c + Vector((0.118, 0, 0.016)),
            (0.014, 0.026, 0.012),
            ink,
            segs=10,
        )
    )

    extras.append(
        ellipsoid(
            "nose",
            head_c + Vector((0.100, 0, -0.024)),
            (0.026, 0.016, 0.018),
            skin,
            segs=12,
        )
    )

    for i, y in enumerate((0.080, -0.080)):
        extras.append(
            _tube(
                f"strap_rear_{i}",
                head_c + Vector((-0.03, y, 0.006)),
                neck_a + Vector((0.018, y * 0.55, -0.018)),
                0.008,
                ink,
            )
        )
        extras.append(
            _tube(
                f"strap_front_{i}",
                head_c + Vector((0.055, y * 0.88, -0.008)),
                neck_a + Vector((0.042, y * 0.22, -0.058)),
                0.008,
                ink,
            )
        )
    extras.append(
        _tube(
            "strap_chin",
            neck_a + Vector((0.048, 0.032, -0.056)),
            neck_a + Vector((0.048, -0.032, -0.056)),
            0.008,
            ink,
        )
    )
    extras.append(
        ellipsoid(
            "buckle",
            neck_a + Vector((0.052, 0, -0.058)),
            (0.018, 0.024, 0.012),
            jersey,
            segs=10,
        )
    )
    extras.append(
        ellipsoid(
            "cradle",
            head_c + Vector((-0.055, 0, -0.006)),
            (0.024, 0.068, 0.018),
            ink,
            segs=12,
        )
    )
    return extras


# ---------------------------------------------------------------------------
# Rider
# ---------------------------------------------------------------------------


def _chain(a: Vector, b: Vector, r0: float, r1: float, n: int = 7):
    pts = []
    for i in range(n):
        t = i / (n - 1)
        pts.append((a.lerp(b, t), r0 * (1.0 - t) + r1 * t))
    return pts


def build_rider(jersey, shorts, skin, helmet_mat, visor_mat, ink, cream):
    hip_l = HIP + Vector((0.02, 0.085, -0.015))
    hip_r = HIP + Vector((0.02, -0.085, -0.015))
    foot_l = pedal_pos(math.pi, 1) + Vector((0.025, 0, 0.028))
    foot_r = pedal_pos(0, -1) + Vector((0.025, 0, 0.028))
    knee_l = ik_knee(hip_l, foot_l, THIGH_LEN, CALF_LEN)
    knee_r = ik_knee(hip_r, foot_r, THIGH_LEN, CALF_LEN)

    abdomen = HIP + Vector((0.07, 0, 0.09))
    rib = HIP + Vector((0.16, 0, 0.20))
    chest = HIP + Vector((0.22, 0, 0.30))
    neck_a = chest + Vector((0.06, 0, 0.08))
    neck_b = neck_a + Vector((0.02, 0, 0.04))
    head_c = neck_b + Vector((0.03, 0, 0.07))
    sh_l = chest + Vector((0.00, 0.17, 0.04))
    sh_r = chest + Vector((0.00, -0.17, 0.04))
    el_l = Vector((0.30, 0.21, 1.03))
    el_r = Vector((0.30, -0.21, 1.03))
    wr_l = HOOD_L + Vector((-0.02, 0.01, 0.012))
    wr_r = HOOD_R + Vector((-0.02, -0.01, 0.012))

    blobs = []

    def blob(co, r):
        obj = mesh("blob", "uv_sphere", radius=r, segments=14, ring_count=10)
        obj.location = co
        apply(obj, skin)
        blobs.append(obj)
        return obj

    for p, r in (
        (HIP + Vector((-0.04, 0, -0.02)), 0.12),
        (HIP, 0.13),
        (HIP + Vector((0.04, 0, 0.04)), 0.125),
        (abdomen, 0.12),
        (HIP + Vector((0.12, 0, 0.15)), 0.125),
        (rib, 0.13),
        (chest + Vector((-0.02, 0, -0.02)), 0.135),
        (chest, 0.14),
        (chest + Vector((0.04, 0, 0.03)), 0.12),
        (chest + Vector((0.0, 0.12, 0.02)), 0.09),
        (chest + Vector((0.0, -0.12, 0.02)), 0.09),
    ):
        blob(p, r)

    for p, r in _chain(neck_a, neck_b, 0.058, 0.052, 4):
        blob(p, r)
    blob(head_c, 0.102)
    blob(head_c + Vector((0.02, 0, -0.05)), 0.078)
    blob(head_c + Vector((0.08, 0, -0.01)), 0.034)
    blob(head_c + Vector((0.03, 0.055, -0.01)), 0.048)
    blob(head_c + Vector((0.03, -0.055, -0.01)), 0.048)
    blob(head_c + Vector((0.0, 0.08, 0.0)), 0.032)
    blob(head_c + Vector((0.0, -0.08, 0.0)), 0.032)

    for hip, knee, foot, sh, el, wr, hood, sign in (
        (hip_l, knee_l, foot_l, sh_l, el_l, wr_l, HOOD_L, 1),
        (hip_r, knee_r, foot_r, sh_r, el_r, wr_r, HOOD_R, -1),
    ):
        blob(hip, 0.078)
        for p, r in _chain(hip, knee, 0.078, 0.056, 10):
            blob(p, r)
        blob(knee, 0.054)
        for p, r in _chain(knee, foot, 0.052, 0.036, 9):
            blob(p, r)
        blob(foot, 0.034)
        blob(sh, 0.076)
        for p, r in _chain(sh, el, 0.060, 0.046, 9):
            blob(p, r)
        blob(el, 0.044)
        for p, r in _chain(el, wr, 0.042, 0.034, 8):
            blob(p, r)
        blob(wr, 0.034)
        blob(wr + Vector((0.028, sign * 0.012, 0.004)), 0.028)
        blob(hood + Vector((0.008, sign * 0.004, 0.006)), 0.026)
        blob(hood + Vector((0.028, 0, 0.002)), 0.020)
        blob(wr + Vector((0.0, sign * 0.022, 0.010)), 0.016)

    extras = build_helmet(
        head_c,
        neck_a,
        helmet_mat,
        visor_mat,
        jersey,
        ink,
        skin_mat("nose", SKIN_WARM),
    )
    shoe_mat = principled("shoe", HOF, 0.58)
    for side, foot in (("l", foot_l), ("r", foot_r)):
        shoe = ellipsoid(f"shoe_{side}", foot + Vector((0.042, 0, -0.004)), (0.092, 0.032, 0.028), shoe_mat, segs=14)
        shoe.rotation_euler = Euler((0, math.radians(8), 0))
        extras.append(shoe)
        extras.append(ellipsoid(f"sole_{side}", foot + Vector((0.038, 0, -0.024)), (0.088, 0.028, 0.011), shoe_mat, segs=10))
        extras.append(ellipsoid(f"heel_{side}", foot + Vector((-0.018, 0, 0.002)), (0.028, 0.026, 0.022), shoe_mat, segs=10))
        extras.append(
            _slab(f"cleat_{side}", foot + Vector((0.028, 0, -0.032)), (0.038, 0.016, 0.007), cream)
        )
        stripe = ellipsoid(
            f"shoe_stripe_{side}",
            foot + Vector((0.052, 0, 0.012)),
            (0.036, 0.012, 0.008),
            jersey,
            segs=8,
        )
        stripe.rotation_euler = Euler((0, math.radians(8), 0))
        extras.append(stripe)
    for side, hip, knee, foot in (
        ("l", hip_l, knee_l, foot_l),
        ("r", hip_r, knee_r, foot_r),
    ):
        mid = hip.lerp(knee, 0.40)
        hem = mesh(f"hem_{side}", "cylinder", radius=0.072, depth=0.050, vertices=14)
        hem.location = mid
        hem.rotation_euler = _track(hip, knee)
        apply(hem, shorts)
        shade_smooth(hem)
        extras.append(hem)
        bib = ellipsoid(f"bib_{side}", hip.lerp(knee, 0.30), (0.072, 0.066, 0.132), shorts, segs=12)
        bib.rotation_euler = _track(hip, knee)
        extras.append(bib)
        sock_c = knee.lerp(foot, 0.62)
        sock = mesh(f"sock_{side}", "cylinder", radius=0.042, depth=0.088, vertices=12)
        sock.location = sock_c
        sock.rotation_euler = _track(knee, foot)
        apply(sock, cream)
        shade_smooth(sock)
        extras.append(sock)
        extras.append(ellipsoid(f"sock_cuff_{side}", knee.lerp(foot, 0.42), (0.044, 0.044, 0.016), cream, segs=10))
    for side, hood, sign in (("l", HOOD_L, 1), ("r", HOOD_R, -1)):
        extras.append(
            ellipsoid(
                f"glove_{side}",
                hood + Vector((-0.012, sign * 0.010, 0.008)),
                (0.036, 0.028, 0.024),
                cream,
                segs=12,
            )
        )
        extras.append(
            ellipsoid(
                f"knuckle_{side}",
                hood + Vector((0.018, sign * 0.004, 0.010)),
                (0.024, 0.020, 0.016),
                cream,
                segs=10,
            )
        )

    for o in blobs:
        _apply_tr(o)
    body = _join("Rider", blobs)
    body.name = "Rider"
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = body
    body.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    rem = body.modifiers.new("rm", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.009
    if hasattr(rem, "use_smooth_shade"):
        rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)
    lap = body.modifiers.new("lap", "LAPLACIANSMOOTH")
    lap.iterations = 22
    if hasattr(lap, "lambda_factor"):
        lap.lambda_factor = 0.55
    bpy.ops.object.modifier_apply(modifier=lap.name)
    sm = body.modifiers.new("sm", "SMOOTH")
    sm.factor = 1.0
    sm.iterations = 18
    bpy.ops.object.modifier_apply(modifier=sm.name)
    print(f"rider mesh verts={len(body.data.vertices)} faces={len(body.data.polygons)}")
    shade_smooth(body)
    _paint_rider_regions(body, (jersey, shorts, skin, helmet_mat, cream), head_c, chest, HIP)

    kept = []
    for ex in extras:
        _apply_tr(ex)
        if ex.name in bpy.data.objects:
            kept.append(ex)

    return {
        "body": body,
        "extras": kept,
        "knee_pt_l": knee_l,
        "knee_pt_r": knee_r,
        "foot_pt_l": foot_l,
        "foot_pt_r": foot_r,
        "anchors": {
            "hip_l": hip_l,
            "hip_r": hip_r,
            "sh_l": sh_l,
            "sh_r": sh_r,
            "el_l": el_l,
            "el_r": el_r,
            "wr_l": wr_l,
            "wr_r": wr_r,
            "head": head_c,
        },
    }


def _apply_tr(obj):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for mod in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=mod.name)
        except RuntimeError:
            obj.modifiers.remove(mod)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)


def _paint_rider_regions(obj, mats, head_c, chest, hip):
    jersey, shorts, skin, helmet, cream = mats
    mesh = obj.data
    mesh.materials.clear()
    for mat in (skin, jersey, shorts, helmet, cream):
        mesh.materials.append(mat)
    mw = obj.matrix_world
    used = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
    for poly in mesh.polygons:
        c = mw @ poly.center
        to_head = (c - head_c).length
        to_hip = (c - hip).length
        # Innenoberschenkel hat kleines |y| — sonst bleibt Jersey-Orange im Schritt.
        thigh = c.z < hip.z + 0.08 and c.z > 0.52 and c.x < 0.26
        leg = abs(c.y) > 0.04 and c.z < hip.z - 0.02 and c.x < 0.32
        if to_head < 0.12 and c.z < head_c.z + 0.03:
            idx = 0
        elif c.x > 0.44 and c.z < 1.05 and abs(c.y) > 0.10:
            idx = 4
        elif to_hip < 0.26 and c.z < hip.z + 0.10:
            idx = 2
        elif thigh:
            idx = 2
        elif leg and c.z > 0.36:
            idx = 4
        elif leg:
            idx = 0
        else:
            idx = 1
        poly.material_index = idx
        used[idx] = used.get(idx, 0) + 1
    print(f"rider materials faces={used}")


def assemble_rider(rider, mats):
    return rider.get("body")


# ---------------------------------------------------------------------------
# Armature (for .blend posing + GLB skins)
# ---------------------------------------------------------------------------


def _ebone(arm, name, head, tail, parent=None):
    b = arm.edit_bones.new(name)
    b.head = head
    b.tail = tail
    if parent is not None:
        b.parent = parent
        b.use_connect = False
    return b


def build_armature(rider):
    arm_data = bpy.data.armatures.new("RiderRig")
    arm_data.display_type = "OCTAHEDRAL"
    arm = bpy.data.objects.new("RiderRig", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")

    a = rider["anchors"]
    hip = HIP
    root = _ebone(arm_data, "root", Vector((0, 0, 0)), Vector((0, 0, 0.12)))
    hips = _ebone(arm_data, "hips", hip, hip + Vector((0.04, 0, 0.08)), root)
    spine = _ebone(arm_data, "spine", hip + Vector((0.06, 0, 0.10)), hip + Vector((0.18, 0, 0.24)), hips)
    chest = _ebone(arm_data, "chest", hip + Vector((0.18, 0, 0.24)), a["head"] + Vector((-0.12, 0, -0.08)), spine)
    neck = _ebone(arm_data, "neck", a["head"] + Vector((-0.08, 0, -0.10)), a["head"] + Vector((-0.02, 0, -0.02)), chest)
    head = _ebone(arm_data, "head", a["head"] + Vector((-0.02, 0, -0.02)), a["head"] + Vector((0.04, 0, 0.12)), neck)

    for side, sign in (("l", 1), ("r", -1)):
        sh = a[f"sh_{side}"]
        el = a[f"el_{side}"]
        wr = a[f"wr_{side}"]
        hip_p = a[f"hip_{side}"]
        knee = rider[f"knee_pt_{side}"]
        foot = rider[f"foot_pt_{side}"]
        _ebone(arm_data, f"shoulder.{side}", sh + Vector((-0.04, 0, 0.02)), sh, chest)
        _ebone(arm_data, f"upper_arm.{side}", sh, el, chest)
        _ebone(arm_data, f"forearm.{side}", el, wr, None)
        _ebone(arm_data, f"hand.{side}", wr, wr + Vector((0.06, 0, 0)), None)
        _ebone(arm_data, f"thigh.{side}", hip_p, knee, hips)
        _ebone(arm_data, f"calf.{side}", knee, foot, None)
        _ebone(arm_data, f"foot.{side}", foot, foot + Vector((0.08, 0, -0.01)), None)
        _ebone(arm_data, f"ik_foot.{side}", foot, foot + Vector((0, 0, 0.08)), root)
        _ebone(arm_data, f"pole_knee.{side}", knee + Vector((0.18, sign * 0.02, 0.04)), knee + Vector((0.18, sign * 0.02, 0.12)), root)

    # reconnect forearm/calf parents (created after so we can look up)
    eb = arm_data.edit_bones
    for side in ("l", "r"):
        eb[f"forearm.{side}"].parent = eb[f"upper_arm.{side}"]
        eb[f"hand.{side}"].parent = eb[f"forearm.{side}"]
        eb[f"calf.{side}"].parent = eb[f"thigh.{side}"]
        eb[f"foot.{side}"].parent = eb[f"calf.{side}"]

    _ebone(arm_data, "crank", BB, BB + Vector((0, 0.12, 0)), root)
    _ebone(arm_data, "wheel_f", FRONT, FRONT + Vector((0, 0.12, 0)), root)
    _ebone(arm_data, "wheel_r", REAR, REAR + Vector((0, 0.12, 0)), root)

    bpy.ops.object.mode_set(mode="POSE")
    for side in ("l", "r"):
        calf = arm.pose.bones[f"calf.{side}"]
        ik = calf.constraints.new("IK")
        ik.target = arm
        ik.subtarget = f"ik_foot.{side}"
        ik.chain_count = 2
        ik.pole_target = arm
        ik.pole_subtarget = f"pole_knee.{side}"
        ik.pole_angle = math.radians(90)
        foot = arm.pose.bones[f"foot.{side}"]
        cp = foot.constraints.new("COPY_ROTATION")
        cp.target = arm
        cp.subtarget = f"ik_foot.{side}"

    bpy.ops.object.mode_set(mode="OBJECT")
    for b in arm.data.bones:
        if b.name.startswith(("ik_", "pole_", "root", "crank", "wheel")):
            b.use_deform = False
    return arm


def bind_rider(arm, body):
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    return body


def parent_to_bone(obj, arm, bone):
    mw = obj.matrix_world.copy()
    obj.parent = arm
    obj.parent_type = "BONE"
    obj.parent_bone = bone
    bpy.context.view_layer.update()
    obj.matrix_world = mw


def animate(arm, bike, rider):
    scene = bpy.context.scene
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")

    for f in range(1, FRAMES + 1):
        t = (f - 1) / FRAMES
        theta = t * math.tau
        scene.frame_set(f)

        bob = 0.012 * math.sin(theta * 2)
        sway = 0.014 * math.sin(theta)
        hips = arm.pose.bones["hips"]
        hips.location = Vector((0, sway * 0.4, bob))
        hips.rotation_mode = "XYZ"
        hips.rotation_euler = Euler((0, 0, math.radians(2.2) * math.sin(theta)))
        hips.keyframe_insert("location", frame=f)
        hips.keyframe_insert("rotation_euler", frame=f)

        spine = arm.pose.bones["spine"]
        spine.rotation_mode = "XYZ"
        spine.rotation_euler = Euler((0, math.radians(1.4) * math.sin(theta * 2), 0))
        spine.keyframe_insert("rotation_euler", frame=f)

        for side, sign, phase in (("l", 1, math.pi), ("r", -1, 0.0)):
            foot = pedal_pos(theta + phase, sign) + Vector((0.02, 0, 0.03))
            ik = arm.pose.bones[f"ik_foot.{side}"]
            # pose-space vs armature: armature at origin
            rest = rider[f"foot_pt_{side}"]
            ik.location = foot - rest
            ik.rotation_mode = "XYZ"
            ik.rotation_euler = Euler((0, math.radians(10) * math.cos(theta + phase), 0))
            ik.keyframe_insert("location", frame=f)
            ik.keyframe_insert("rotation_euler", frame=f)

        crank = arm.pose.bones["crank"]
        crank.rotation_mode = "XYZ"
        crank.rotation_euler = Euler((theta, 0, 0))
        crank.keyframe_insert("rotation_euler", frame=f)

        # ~2.6 m development per rev → wheel angle
        wheel_ang = -theta * 2.55
        for name in ("wheel_f", "wheel_r"):
            wb = arm.pose.bones[name]
            wb.rotation_mode = "XYZ"
            wb.rotation_euler = Euler((wheel_ang, 0, 0))
            wb.keyframe_insert("rotation_euler", frame=f)

    bpy.ops.object.mode_set(mode="OBJECT")

    # object-level crank / pedal / wheel so the drivetrain reads even without skin
    for f in range(1, FRAMES + 1):
        t = (f - 1) / FRAMES
        theta = t * math.tau
        fl = pedal_pos(theta + math.pi, 1)
        fr = pedal_pos(theta, -1)
        bike["pedal_l"].location = fl
        bike["pedal_r"].location = fr
        place_z(bike["crank_l"], BB + Vector((0, PEDAL_Y, 0)), fl, CRANK_LEN)
        place_z(bike["crank_r"], BB + Vector((0, -PEDAL_Y, 0)), fr, CRANK_LEN)
        key_obj(bike["pedal_l"], f)
        key_obj(bike["pedal_r"], f)
        key_obj(bike["crank_l"], f, scale=True)
        key_obj(bike["crank_r"], f, scale=True)
        for tag in ("rear", "front"):
            spin = bike[f"spin_{tag}"]
            spin.rotation_euler = Euler((0, -theta * 2.55, 0))
            key_obj(spin, f, loc=False)

    for obj in (*bike["crank"], bike["spin_rear"], bike["spin_front"]):
        cyclic_fcurves(obj)
    cyclic_fcurves(arm)


# ---------------------------------------------------------------------------
# World / render
# ---------------------------------------------------------------------------


def setup_world(live: bool):
    scene = bpy.context.scene
    world = bpy.data.worlds.new("rider_world")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.93, 0.90, 0.86, 1) if live else (0.16, 0.16, 0.18, 1)
    bg.inputs[1].default_value = 0.35 if live else 0.12

    def add_area(name, energy, size, loc, target, color=(1.0, 1.0, 1.0)):
        light = bpy.data.objects.new(name, bpy.data.lights.new(name, "AREA"))
        light.data.energy = energy
        light.data.size = size
        light.data.color = color
        if hasattr(light.data, "shape"):
            light.data.shape = "RECTANGLE"
            light.data.size_y = size * 0.7
        light.location = loc
        look_at(light, target)
        scene.collection.objects.link(light)
        return light

    add_area(
        "key",
        170 if live else 120,
        1.7,
        Vector((2.0, -2.0, 2.15)),
        Vector((0.1, 0, 0.9)),
        color=(0.90, 0.95, 1.0),
    )
    add_area("fill", 55 if live else 36, 2.6, Vector((-1.8, 1.6, 1.7)), Vector((0, 0, 0.8)))
    rim = bpy.data.objects.new("rim", bpy.data.lights.new("rim", "POINT"))
    rim.data.energy = 80 if live else 28
    rim.data.color = (0.92, 0.96, 1.0)
    rim.location = (-0.55, -2.15, 1.85)
    scene.collection.objects.link(rim)

    cam_data = bpy.data.cameras.new("rider_cam")
    cam_data.lens = 58
    cam_data.clip_start = 0.05
    cam_obj = bpy.data.objects.new("rider_cam", cam_data)
    cam_obj.location = (1.48, -2.62, 1.14)
    look_at(cam_obj, Vector((0.02, -0.04, 0.72)))
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj


def set_engine():
    scene = bpy.context.scene
    for name in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        try:
            scene.render.engine = name
            break
        except TypeError:
            continue
    eevee = getattr(scene, "eevee", None)
    if eevee:
        for attr, val in (
            ("taa_render_samples", 64),
            ("use_gtao", True),
            ("use_bloom", False),
            ("use_raytracing", True),
            ("gi_cubemap_resolution", "128"),
        ):
            if hasattr(eevee, attr):
                try:
                    setattr(eevee, attr, val)
                except Exception:
                    pass
    vs = scene.view_settings
    try:
        vs.view_transform = "Standard"
    except TypeError:
        try:
            vs.view_transform = "Khronos PBR Neutral"
        except TypeError:
            pass
    try:
        vs.look = "None"
    except Exception:
        pass
    try:
        vs.exposure = -0.15
    except Exception:
        pass
    print(f"view_transform={getattr(vs, 'view_transform', '?')}")
    return scene.render.engine


def render_png(path: Path, transparent: bool):
    scene = bpy.context.scene
    scene.frame_set(1)
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def paint_stale():
    grey = principled("stale", STALE, 0.55)
    ink = principled("stale_ink", (0.32, 0.32, 0.35), 0.48)
    skin_s = principled("stale_skin", (0.62, 0.60, 0.58), 0.5)
    for obj in bpy.data.objects:
        if obj.type != "MESH" or not obj.data.materials:
            continue
        for i, mat in enumerate(list(obj.data.materials)):
            if mat is None:
                continue
            n = mat.name.lower()
            if any(k in n for k in ("skin", "nose", "cream")):
                obj.data.materials[i] = skin_s
            elif any(k in n for k in ("helmet", "ink", "rubber", "visor", "chain", "shoe", "frame")):
                obj.data.materials[i] = ink
            else:
                obj.data.materials[i] = grey


def export_glb(path: Path):
    kwargs = {
        "filepath": str(path),
        "export_format": "GLB",
    }
    extras = {
        "export_apply": True,
        "export_animations": True,
        "export_cameras": False,
        "export_lights": False,
        "export_extras": False,
    }
    try:
        bpy.ops.export_scene.gltf(**kwargs, **extras)
    except TypeError:
        try:
            bpy.ops.export_scene.gltf(**kwargs, export_apply=True)
        except TypeError:
            bpy.ops.export_scene.gltf(**kwargs)


def main():
    reset()
    jersey = signal_orange("jersey", strength=0.95, roughness=0.40)
    shorts = fabric("shorts", CHARCOAL, 0.56)
    rubber = principled("rubber", RUBBER, 0.82)
    steel = principled("steel", STEEL, 0.22, metallic=0.72)
    cream = fabric("cream", CREAM, 0.58)
    skin = skin_mat("skin")
    helmet = principled("helmet", CHARCOAL, 0.22, metallic=0.08)
    visor = principled("visor", HOF, 0.06, metallic=0.55)
    accent = signal_orange("accent", strength=1.05, roughness=0.30)
    bottle_mat = lamp_orange("bottle", strength=3.8)
    frame = principled("frame", CHARCOAL, 0.34)
    ink = principled("ink", INK, 0.38)
    sage = principled("sage", SAGE, 0.55)

    bike = build_bike((rubber, steel, ink, accent, cream, frame))
    for obj in bpy.data.objects:
        if obj.type == "MESH" and obj.name.startswith(("bottle", "bottle_shoulder")):
            apply(obj, bottle_mat)
    rider = build_rider(jersey, shorts, skin, helmet, visor, ink, cream)
    body = assemble_rider(rider, (jersey, shorts, skin, helmet, ink, cream))
    arm = build_armature(rider)
    if body:
        bind_rider(arm, body)
    for ex in rider.get("extras", []):
        n = ex.name
        bone = "head"
        if n.startswith(("shoe_l", "sole_l", "heel_l", "cleat_l", "shoe_stripe_l")):
            bone = "foot.l"
        elif n.startswith(("shoe_r", "sole_r", "heel_r", "cleat_r", "shoe_stripe_r")):
            bone = "foot.r"
        elif n.startswith(("glove_l", "knuckle_l")):
            bone = "hand.l"
        elif n.startswith(("glove_r", "knuckle_r")):
            bone = "hand.r"
        elif n.startswith(("hem_l", "bib_l")):
            bone = "thigh.l"
        elif n.startswith(("hem_r", "bib_r")):
            bone = "thigh.r"
        elif n.startswith(("sock_l", "sock_cuff_l")):
            bone = "calf.l"
        elif n.startswith(("sock_r", "sock_cuff_r")):
            bone = "calf.r"
        parent_to_bone(ex, arm, bone)
    animate(arm, bike, rider)

    ground = mesh("ground", "circle", radius=1.4, fill_type="NGON")
    ground.location = (0, 0, 0.0)
    apply(ground, sage)
    ground.hide_render = True
    ground.hide_set(True)

    setup_world(live=True)
    engine = set_engine()

    blend = OUT / "rider.blend"
    glb = OUT / "rider.glb"
    live = OUT / "rider-live.png"
    stale = OUT / "rider-stale.png"

    for trash in ("ground",):
        obj = bpy.data.objects.get(trash)
        if obj:
            bpy.data.objects.remove(obj, do_unlink=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    export_glb(glb)
    render_png(live, transparent=True)
    paint_stale()
    scene = bpy.context.scene
    if scene.world and scene.world.node_tree:
        bg = scene.world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs[0].default_value = (0.16, 0.16, 0.18, 1)
            bg.inputs[1].default_value = 0.12
    for obj in scene.objects:
        if obj.type == "LIGHT":
            obj.data.energy = getattr(obj.data, "energy", 100) * 0.38
            if hasattr(obj.data, "color") and tuple(obj.data.color) != (1.0, 1.0, 1.0):
                obj.data.color = (0.7, 0.7, 0.75)
    render_png(stale, transparent=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    print(f"rider assets ok engine={engine} -> {OUT}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"rider asset failed: {exc}", file=sys.stderr)
        raise
