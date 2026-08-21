#!/usr/bin/env python3
"""Render FlowLine 3D POI pin sprites (and glTF) for the browse map.

Pipeline:
  blender --background --python blender_poi_pins.py
  (or Flatpak: flatpak run --filesystem=host org.blender.Blender ...)
  2. Else: same meshes → orthographic SDF raster (numpy) + GLB writer

MapLibre cannot display glTF markers. The map uses the PNGs via addImage.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import struct
import subprocess
import sys
from typing import TYPE_CHECKING, Iterable

import numpy as np

if TYPE_CHECKING:
    from PIL import Image

# Brand — keep in sync with blender_poi_pins.py / map_pin_image.dart
ORANGE = np.array([255, 106, 0], dtype=np.float64)
# Redder than brand so wrap + key light still reads #FF6A00, not gold.
ORANGE_ALBEDO = np.array([255, 62, 0], dtype=np.float64)
SAGE = np.array([122, 139, 115], dtype=np.float64)
CHARCOAL = np.array([26, 18, 12], dtype=np.float64)
CHARCOAL_SOFT = np.array([42, 36, 32], dtype=np.float64)
CREAM = np.array([244, 241, 236], dtype=np.float64)
INK = np.array([32, 28, 24], dtype=np.float64)
WHITE = np.array([255, 255, 255], dtype=np.float64)
GREEN = np.array([46, 125, 50], dtype=np.float64)  # #2E7D32 start ring

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
# Same 3D pin body as POIs — start/finish were 2D discs that read as black squares.
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
SS = 4  # supersample — box-filter down, no Lanczos ringing

# Shared pin proportions (mesh + SDF).
FOOT_R0, FOOT_R1, FOOT_Z0, FOOT_Z1 = 0.090, 0.052, 0.000, 0.062
STEM_R0, STEM_R1, STEM_Z0, STEM_Z1 = 0.046, 0.060, 0.040, 0.545
COLLAR_R0, COLLAR_R1, COLLAR_Z0, COLLAR_Z1 = 0.072, 0.168, 0.500, 0.600
HEAD_R0, HEAD_R1, HEAD_Z0, HEAD_Z1 = 0.398, 0.382, 0.585, 0.768
RING_R, RING_r, RING_Z = 0.360, 0.038, 0.812
PLATE_R0, PLATE_R1, PLATE_Z0, PLATE_Z1 = 0.292, 0.338, 0.748, 0.848
BEVEL_R0, BEVEL_R1, BEVEL_Z0, BEVEL_Z1 = 0.338, 0.300, 0.848, 0.898
DOME_R, DOME_Z0, DOME_H = 0.300, 0.888, 0.042

# Glyphs sit on the cream dome. +Y is icon-up (far edge / top of the 3/4 view).
GLYPH_Z0 = 0.900
GLYPH_Z1 = 1.070
PLATE_Z = 0.918
# Fill the cream plate — must still read at ~36px on the map.
GLYPH_S = 1.58

# Unscaled XY footprints — pin_glyphs() and _scene_glyphs() stay identical.
# After GLYPH_S they must sit inside the cream plate (~r 0.30).
# Side-view silhouettes (+Y icon-up) — top-down cups/trams collapse to blobs.
_FLAG = [(-0.100, 0.188), (-0.100, -0.055), (0.185, 0.078)]
_VIEW_RIDGE = [(-0.185, -0.125), (0.018, -0.125), (-0.095, 0.095)]
_VIEW_PEAK = [(-0.040, -0.125), (0.175, -0.125), (0.068, 0.118)]
_CUP = [(-0.155, -0.148), (0.088, -0.148), (0.112, 0.072), (-0.178, 0.072)]
_WATER_DROP = [
    (0.000, 0.195),
    (0.048, 0.095),
    (0.125, -0.005),
    (0.148, -0.088),
    (0.095, -0.162),
    (0.000, -0.192),
    (-0.095, -0.162),
    (-0.148, -0.088),
    (-0.125, -0.005),
    (-0.048, 0.095),
]
_TRAM = [
    (-0.175, -0.055),
    (-0.155, -0.095),
    (0.145, -0.095),
    (0.175, -0.040),
    (0.175, 0.095),
    (0.145, 0.125),
    (-0.155, 0.125),
    (-0.175, 0.095),
]


def _as_vf(verts, faces, nrms=None):
    v = np.asarray(verts, dtype=np.float64)
    f = np.asarray(faces, dtype=np.int32)
    n = None if nrms is None else np.asarray(nrms, dtype=np.float64)
    return v, f, n


def _box(cx, cy, cz, sx, sy, sz):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    v = np.array(
        [
            [cx - hx, cy - hy, cz - hz],
            [cx + hx, cy - hy, cz - hz],
            [cx + hx, cy + hy, cz - hz],
            [cx - hx, cy + hy, cz - hz],
            [cx - hx, cy - hy, cz + hz],
            [cx + hx, cy - hy, cz + hz],
            [cx + hx, cy + hy, cz + hz],
            [cx - hx, cy + hy, cz + hz],
        ],
        dtype=np.float64,
    )
    f = np.array(
        [
            [0, 1, 2],
            [0, 2, 3],
            [4, 7, 6],
            [4, 6, 5],
            [0, 4, 5],
            [0, 5, 1],
            [2, 6, 7],
            [2, 7, 3],
            [0, 3, 7],
            [0, 7, 4],
            [1, 5, 6],
            [1, 6, 2],
        ],
        dtype=np.int32,
    )
    return v, f


def _cylinder(r0, r1, z0, z1, segs=28, caps=True):
    """Tapered cylinder with split-cap verts and analytic side normals."""
    verts: list[tuple[float, float, float]] = []
    nrms: list[tuple[float, float, float]] = []
    dr, dz = r1 - r0, z1 - z0
    length = math.hypot(dz, dr) or 1.0
    nr, nz = dz / length, -dr / length
    for i in range(segs):
        a = 2 * math.pi * i / segs
        c, s = math.cos(a), math.sin(a)
        verts.append((r0 * c, r0 * s, z0))
        nrms.append((nr * c, nr * s, nz))
    for i in range(segs):
        a = 2 * math.pi * i / segs
        c, s = math.cos(a), math.sin(a)
        verts.append((r1 * c, r1 * s, z1))
        nrms.append((nr * c, nr * s, nz))
    faces: list[tuple[int, int, int]] = []
    for i in range(segs):
        j = (i + 1) % segs
        faces.append((i, j, segs + j))
        faces.append((i, segs + j, segs + i))
    do_bottom = caps in (True, "both", "bottom")
    do_top = caps in (True, "both", "top")
    if do_bottom:
        bi = len(verts)
        verts.append((0.0, 0.0, z0))
        nrms.append((0.0, 0.0, -1.0))
        for i in range(segs):
            a = 2 * math.pi * i / segs
            verts.append((r0 * math.cos(a), r0 * math.sin(a), z0))
            nrms.append((0.0, 0.0, -1.0))
        for i in range(segs):
            j = (i + 1) % segs
            faces.append((bi, bi + 1 + j, bi + 1 + i))
    if do_top:
        ti = len(verts)
        verts.append((0.0, 0.0, z1))
        nrms.append((0.0, 0.0, 1.0))
        for i in range(segs):
            a = 2 * math.pi * i / segs
            verts.append((r1 * math.cos(a), r1 * math.sin(a), z1))
            nrms.append((0.0, 0.0, 1.0))
        for i in range(segs):
            j = (i + 1) % segs
            faces.append((ti, ti + 1 + i, ti + 1 + j))
    return _as_vf(verts, faces, nrms)


def _sphere(cx, cy, cz, r, segs=12):
    verts: list[tuple[float, float, float]] = []
    nrms: list[tuple[float, float, float]] = []
    for iy in range(segs + 1):
        phi = math.pi * iy / segs
        sp, cp = math.sin(phi), math.cos(phi)
        for ix in range(segs):
            th = 2 * math.pi * ix / segs
            ct, st = math.cos(th), math.sin(th)
            n = (sp * ct, sp * st, cp)
            verts.append((cx + r * n[0], cy + r * n[1], cz + r * n[2]))
            nrms.append(n)
    faces: list[tuple[int, int, int]] = []
    for iy in range(segs):
        for ix in range(segs):
            i = iy * segs + ix
            j = iy * segs + (ix + 1) % segs
            faces.append((i, j, j + segs))
            faces.append((i, j + segs, i + segs))
    return _as_vf(verts, faces, nrms)


def _torus(R, r, zc, segs_u=26, segs_v=10):
    verts: list[tuple[float, float, float]] = []
    nrms: list[tuple[float, float, float]] = []
    for i in range(segs_u):
        u = 2 * math.pi * i / segs_u
        cu, su = math.cos(u), math.sin(u)
        for j in range(segs_v):
            v = 2 * math.pi * j / segs_v
            cv, sv = math.cos(v), math.sin(v)
            n = (cv * cu, cv * su, sv)
            verts.append((R * cu + r * n[0], R * su + r * n[1], zc + r * n[2]))
            nrms.append(n)
    faces: list[tuple[int, int, int]] = []
    for i in range(segs_u):
        inext = (i + 1) % segs_u
        for j in range(segs_v):
            jnext = (j + 1) % segs_v
            a = i * segs_v + j
            b = inext * segs_v + j
            c = inext * segs_v + jnext
            d = i * segs_v + jnext
            faces.append((a, b, c))
            faces.append((a, c, d))
    return _as_vf(verts, faces, nrms)


def _dome(radius, z0, height, rings=5, segs=28):
    """Shallow parabolic cap so the cream plate gets a real highlight."""
    verts: list[tuple[float, float, float]] = [(0.0, 0.0, z0 + height)]
    nrms: list[tuple[float, float, float]] = [(0.0, 0.0, 1.0)]
    inv_r2 = 1.0 / max(radius * radius, 1e-8)
    for ir in range(1, rings + 1):
        t = ir / rings
        rr = radius * t
        z = z0 + height * (1.0 - t * t)
        for ia in range(segs):
            a = 2 * math.pi * ia / segs
            x, y = rr * math.cos(a), rr * math.sin(a)
            verts.append((x, y, z))
            n = np.array([2.0 * height * x * inv_r2, 2.0 * height * y * inv_r2, 1.0])
            n = n / (np.linalg.norm(n) or 1.0)
            nrms.append((float(n[0]), float(n[1]), float(n[2])))
    faces: list[tuple[int, int, int]] = []
    for ia in range(segs):
        faces.append((0, 1 + ia, 1 + (ia + 1) % segs))
    for ir in range(rings - 1):
        r0 = 1 + ir * segs
        r1 = 1 + (ir + 1) * segs
        for ia in range(segs):
            a, b = r0 + ia, r0 + (ia + 1) % segs
            c, d = r1 + (ia + 1) % segs, r1 + ia
            faces.append((a, b, c))
            faces.append((a, c, d))
    return _as_vf(verts, faces, nrms)


def _prism(points_xy, z0, z1):
    n = len(points_xy)
    verts = [(x, y, z0) for x, y in points_xy] + [(x, y, z1) for x, y in points_xy]
    faces: list[tuple[int, int, int]] = []
    for i in range(1, n - 1):
        faces.append((0, i + 1, i))
        faces.append((n, n + i, n + i + 1))
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j))
        faces.append((i, n + j, n + i))
    return np.array(verts, dtype=np.float64), np.array(faces, dtype=np.int32)


def _extrude_y(points_xz, y0, y1):
    """Camera-facing slab: (x, z) polygon extruded along Y (towards the 3/4 view)."""
    n = len(points_xz)
    verts = [(x, y0, z) for x, z in points_xz] + [(x, y1, z) for x, z in points_xz]
    faces: list[tuple[int, int, int]] = []
    for i in range(1, n - 1):
        faces.append((0, i, i + 1))
        faces.append((n, n + i + 1, n + i))
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, n + i, n + j))
        faces.append((i, n + j, j))
    return np.array(verts, dtype=np.float64), np.array(faces, dtype=np.int32)


def _shift(verts, nrms, dx=0.0, dy=0.0, dz=0.0):
    out = verts.copy()
    out[:, 0] += dx
    out[:, 1] += dy
    out[:, 2] += dz
    return out, None if nrms is None else nrms.copy()


def _part(name, verts, faces, color, roughness=0.45, normals=None, metallic=0.04):
    verts = np.asarray(verts, dtype=np.float64)
    faces = np.asarray(faces, dtype=np.int32)
    if normals is None:
        normals = _vertex_normals(verts, faces)
    else:
        normals = np.asarray(normals, dtype=np.float64)
        lens = np.linalg.norm(normals, axis=1)
        lens[lens < 1e-9] = 1.0
        normals = normals / lens[:, None]
    return {
        "name": name,
        "verts": verts,
        "faces": faces,
        "color": np.asarray(color, dtype=np.float64),
        "roughness": roughness,
        "normals": normals,
        "metallic": metallic,
    }


def _p(name, packed, color, roughness=0.45, metallic=0.04, dx=0.0, dy=0.0, dz=0.0):
    if len(packed) == 3:
        v, f, n = packed
    else:
        v, f = packed
        n = None
    if dx or dy or dz:
        v, n = _shift(v, n, dx, dy, dz)
    return _part(name, v, f, color, roughness, n, metallic)


def _ring_color(kind: str):
    if kind == "start":
        return GREEN
    if kind in ("start-out", "finish-out"):
        return SAGE
    return ORANGE


def pin_body(ring_color=ORANGE) -> list[dict]:
    """Tapered charcoal stem, sage collar/head, cream bevel disc, tinted rim bead."""
    return [
        _p("foot", _cylinder(FOOT_R0, FOOT_R1, FOOT_Z0, FOOT_Z1, 22), CHARCOAL_SOFT, 0.52),
        _p("stem", _cylinder(STEM_R0, STEM_R1, STEM_Z0, STEM_Z1, 22), CHARCOAL, 0.58),
        _p("collar", _cylinder(COLLAR_R0, COLLAR_R1, COLLAR_Z0, COLLAR_Z1, 26), SAGE, 0.46),
        _p("head", _cylinder(HEAD_R0, HEAD_R1, HEAD_Z0, HEAD_Z1, 40, caps="bottom"), SAGE, 0.46),
        _p("ring", _torus(RING_R, RING_r, RING_Z, 40, 14), ring_color, 0.40, 0.03),
        _p("plate_wall", _cylinder(PLATE_R0, PLATE_R1, PLATE_Z0, PLATE_Z1, 36, caps=False), CREAM, 0.30),
        _p("plate_bevel", _cylinder(BEVEL_R0, BEVEL_R1, BEVEL_Z0, BEVEL_Z1, 36, caps=False), CREAM, 0.26),
        _p("plate_dome", _dome(DOME_R, DOME_Z0, DOME_H, 6, 32), CREAM, 0.24),
    ]


def _flowline_mark() -> list[dict]:
    """Standing FlowLine peaks + waves — readable from the 3/4 camera."""
    z0 = PLATE_Z
    return [
        _p("pk_l", _prism([(-0.22, -0.04), (-0.04, -0.04), (-0.14, 0.12)], z0, z0 + 0.10), INK, 0.46),
        _p("pk_m", _prism([(-0.09, -0.04), (0.09,  -0.04), (0.00,  0.20)], z0, z0 + 0.16), INK, 0.46),
        _p("pk_r", _prism([(0.04,  -0.04), (0.22,  -0.04), (0.14,  0.13)], z0, z0 + 0.11), INK, 0.46),
        _p("wave_o", _box(0.0, -0.12, z0 + 0.028, 0.44, 0.055, 0.045), ORANGE, 0.34, 0.10),
        _p("wave_s", _box(0.0, -0.16, z0 + 0.018, 0.34, 0.036, 0.030), SAGE, 0.48),
    ]


def _standing_flag(pole_dx: float = -0.10) -> list[dict]:
    """Ink pole + orange rectangle facing the camera — not a checkerboard square."""
    z0 = PLATE_Z
    pole_h, flag_h, flag_w = 0.24, 0.12, 0.22
    z_top = z0 + pole_h
    z_bot = z_top - flag_h
    x0 = pole_dx + 0.02
    return [
        _p("pole", _cylinder(0.030, 0.030, z0, z_top, 14), INK, 0.48, dx=pole_dx),
        _p(
            "flag",
            _extrude_y(
                [(x0, z_top), (x0 + flag_w, z_top), (x0 + flag_w, z_bot), (x0, z_bot)],
                -0.022,
                0.022,
            ),
            ORANGE,
            0.36,
            0.04,
        ),
    ]


def _standing_play() -> list[dict]:
    """Play triangle pointing +X, facing the camera. Orange on cream — not a dark block."""
    z0 = PLATE_Z
    z_mid = z0 + 0.11
    return [
        _p(
            "play",
            _extrude_y(
                [(0.14, z_mid), (-0.10, z0 + 0.02), (-0.10, z0 + 0.20)],
                -0.028,
                0.028,
            ),
            ORANGE,
            0.34,
            0.04,
        )
    ]


def pin_glyphs(kind: str) -> list[dict]:
    """Standing 3D marks on the cream plate — readable at ~36px from 3/4."""
    z0 = PLATE_Z
    base = kind.replace("-out", "")
    if base in ("trailhead", "finish"):
        return _standing_flag()
    if base == "start":
        return _standing_play()
    if kind == "viewpoint":
        return [
            _p("ridge", _prism([(-0.20, -0.10), (0.02, -0.10), (-0.10, 0.10)], z0, z0 + 0.11), INK, 0.46),
            _p("peak", _prism([(-0.04, -0.10), (0.20, -0.10), (0.08, 0.14)], z0, z0 + 0.15), INK, 0.46),
            _p("sun", _sphere(0.12, 0.12, z0 + 0.14, 0.055, 14), ORANGE, 0.36, 0.04),
        ]
    if kind == "cafe":
        # Upright mug: orange coffee disc reads from 3/4. Handle is a C on +X.
        return [
            _p("cup", _cylinder(0.11, 0.12, z0, z0 + 0.13, 20), INK, 0.44),
            _p("coffee", _cylinder(0.09, 0.09, z0 + 0.115, z0 + 0.138, 18), ORANGE, 0.34, 0.04),
            _p("h_top", _box(0.155, 0.00, z0 + 0.11, 0.09, 0.045, 0.035), INK, 0.44),
            _p("h_side", _box(0.195, 0.00, z0 + 0.07, 0.045, 0.045, 0.09), INK, 0.44),
            _p("h_bot", _box(0.155, 0.00, z0 + 0.035, 0.09, 0.045, 0.035), INK, 0.44),
        ]
    if kind == "culture":
        return [
            _p("base", _box(0.0, 0.0, z0 + 0.02, 0.38, 0.10, 0.04), INK, 0.48),
            _p("col0", _cylinder(0.028, 0.028, z0 + 0.02, z0 + 0.15, 12), INK, 0.46, dx=-0.12),
            _p("col1", _cylinder(0.028, 0.028, z0 + 0.02, z0 + 0.15, 12), INK, 0.46),
            _p("col2", _cylinder(0.028, 0.028, z0 + 0.02, z0 + 0.15, 12), INK, 0.46, dx=0.12),
            _p("lintel", _box(0.0, 0.0, z0 + 0.165, 0.40, 0.10, 0.04), ORANGE, 0.36, 0.04),
        ]
    if kind == "water":
        drop_xz = [
            (0.00, z0 + 0.20),
            (0.09, z0 + 0.10),
            (0.10, z0 + 0.04),
            (0.00, z0 + 0.01),
            (-0.10, z0 + 0.04),
            (-0.09, z0 + 0.10),
        ]
        return [
            _p("drop", _extrude_y(drop_xz, -0.03, 0.03), INK, 0.40),
            _p("hi", _sphere(-0.03, 0.00, z0 + 0.08, 0.032, 12), ORANGE, 0.36, 0.04),
        ]
    if kind == "transit":
        return [
            _p("body", _box(0.0, 0.0, z0 + 0.08, 0.32, 0.14, 0.12), INK, 0.44),
            _p("win", _box(0.0, -0.06, z0 + 0.10, 0.20, 0.03, 0.06), ORANGE, 0.36, 0.04),
            _p("w0", _cylinder(0.038, 0.038, z0, z0 + 0.05, 12), INK, 0.48, dx=-0.09),
            _p("w1", _cylinder(0.038, 0.038, z0, z0 + 0.05, 12), INK, 0.48, dx=0.09),
        ]
    if kind in ("meetup", "meet"):
        return [
            _p("a_head", _sphere(-0.10, 0.04, z0 + 0.14, 0.055, 12), INK, 0.44),
            _p("a_body", _cylinder(0.055, 0.032, z0, z0 + 0.10, 12), INK, 0.46, dx=-0.10, dy=0.04),
            _p("b_head", _sphere(0.10, 0.04, z0 + 0.14, 0.055, 12), INK, 0.44),
            _p("b_body", _cylinder(0.055, 0.032, z0, z0 + 0.10, 12), INK, 0.46, dx=0.10, dy=0.04),
            _p("c_head", _sphere(0.00, -0.08, z0 + 0.13, 0.050, 12), ORANGE, 0.36, 0.04),
            _p("c_body", _cylinder(0.048, 0.028, z0, z0 + 0.09, 12), ORANGE, 0.38, 0.04, dy=-0.08),
        ]
    if kind == "stimme":
        return [
            _p("bubble", _box(0.02, 0.02, z0 + 0.10, 0.28, 0.16, 0.14), WHITE, 0.28),
            _p("inner", _box(0.02, 0.02, z0 + 0.10, 0.20, 0.10, 0.08), ORANGE, 0.36, 0.04),
            _p(
                "tail",
                _extrude_y(
                    [(-0.08, z0 + 0.04), (-0.02, z0 + 0.08), (0.02, z0 + 0.05)],
                    -0.02,
                    0.02,
                ),
                WHITE,
                0.28,
            ),
        ]
    return _flowline_mark()


def pin_parts(kind: str) -> list[dict]:
    return pin_body(_ring_color(kind)) + pin_glyphs(kind)


def _vertex_normals(verts: np.ndarray, faces: np.ndarray) -> np.ndarray:
    nrm = np.zeros_like(verts)
    v0 = verts[faces[:, 0]]
    v1 = verts[faces[:, 1]]
    v2 = verts[faces[:, 2]]
    fn = np.cross(v1 - v0, v2 - v0)
    for i in range(3):
        np.add.at(nrm, faces[:, i], fn)
    lens = np.linalg.norm(nrm, axis=1)
    lens[lens < 1e-9] = 1.0
    return nrm / lens[:, None]


# --- SDF raster (smooth solids, no triangle speckles) -------------------------

MAT_ORANGE = 0
MAT_SAGE = 1
MAT_CHARCOAL = 2
MAT_CHARCOAL_SOFT = 3
MAT_CREAM = 4
MAT_INK = 5
MAT_GREEN = 6
MAT_WHITE = 7

_MAT_ALBEDO = np.stack(
    [ORANGE_ALBEDO, SAGE, CHARCOAL, CHARCOAL_SOFT, CREAM, INK, GREEN, WHITE]
)
_MAT_ROUGH = np.array([0.40, 0.50, 0.60, 0.55, 0.28, 0.44, 0.42, 0.28])
_MAT_METAL = np.array([0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03])


def _sd_cone(p: np.ndarray, r0: float, r1: float, z0: float, z1: float) -> np.ndarray:
    """Capped tapered cylinder. p (..., 3)."""
    pz = p[..., 2]
    he = z1 - z0
    t = np.clip((pz - z0) / he, 0.0, 1.0)
    r = r0 + (r1 - r0) * t
    r = np.where(pz < z0, r0, np.where(pz > z1, r1, r))
    d_rad = np.hypot(p[..., 0], p[..., 1]) - r
    d_z = np.maximum(z0 - pz, pz - z1)
    return np.hypot(np.maximum(d_rad, 0.0), np.maximum(d_z, 0.0)) + np.minimum(
        np.maximum(d_rad, d_z), 0.0
    )


def _sd_torus(p: np.ndarray, R: float, r: float, zc: float) -> np.ndarray:
    q0 = np.hypot(p[..., 0], p[..., 1]) - R
    return np.hypot(q0, p[..., 2] - zc) - r


def _sd_sphere(p: np.ndarray, cx: float, cy: float, cz: float, r: float) -> np.ndarray:
    return np.sqrt((p[..., 0] - cx) ** 2 + (p[..., 1] - cy) ** 2 + (p[..., 2] - cz) ** 2) - r


def _sd_box(p: np.ndarray, cx: float, cy: float, cz: float, sx: float, sy: float, sz: float) -> np.ndarray:
    q = np.abs(p - np.array([cx, cy, cz])) - np.array([sx, sy, sz]) * 0.5
    return np.linalg.norm(np.maximum(q, 0.0), axis=-1) + np.minimum(np.max(q, axis=-1), 0.0)


def _sd_polygon(px: np.ndarray, py: np.ndarray, verts) -> np.ndarray:
    verts = np.asarray(verts, dtype=np.float64)
    d = (px - verts[0, 0]) ** 2 + (py - verts[0, 1]) ** 2
    s = np.ones_like(px)
    n = len(verts)
    for i in range(n):
        j = (i - 1) % n
        vi, vj = verts[i], verts[j]
        e = vj - vi
        wx, wy = px - vi[0], py - vi[1]
        elen = float(e[0] * e[0] + e[1] * e[1]) or 1.0
        tt = np.clip((wx * e[0] + wy * e[1]) / elen, 0.0, 1.0)
        bx, by = wx - tt * e[0], wy - tt * e[1]
        d = np.minimum(d, bx * bx + by * by)
        c1 = py >= vi[1]
        c2 = py < vj[1]
        c3 = e[0] * wy > e[1] * wx
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(flip, -s, s)
    return s * np.sqrt(np.maximum(d, 0.0))


def _sd_prism(p: np.ndarray, verts_xy, z0: float, z1: float) -> np.ndarray:
    d2 = _sd_polygon(p[..., 0], p[..., 1], verts_xy)
    dz = np.maximum(z0 - p[..., 2], p[..., 2] - z1)
    return np.hypot(np.maximum(d2, 0.0), np.maximum(dz, 0.0)) + np.minimum(np.maximum(d2, dz), 0.0)


def _sd_ellipsoid(p: np.ndarray, cx: float, cy: float, cz: float, rx: float, ry: float, rz: float) -> np.ndarray:
    q = np.stack([(p[..., 0] - cx) / rx, (p[..., 1] - cy) / ry, (p[..., 2] - cz) / rz], axis=-1)
    k0 = np.linalg.norm(q, axis=-1)
    return (k0 - 1.0) * min(rx, ry, rz)


def _u(d0, m0, d1, m1):
    pick = d1 < d0
    return np.where(pick, d1, d0), np.where(pick, m1, m0)


def _scene_body(p: np.ndarray, ring_mat: int = MAT_ORANGE):
    d = _sd_cone(p, FOOT_R0, FOOT_R1, FOOT_Z0, FOOT_Z1)
    m = np.full(p.shape[:-1], MAT_CHARCOAL_SOFT, dtype=np.int32)
    d, m = _u(d, m, _sd_cone(p, STEM_R0, STEM_R1, STEM_Z0, STEM_Z1), MAT_CHARCOAL)
    d, m = _u(d, m, _sd_cone(p, COLLAR_R0, COLLAR_R1, COLLAR_Z0, COLLAR_Z1), MAT_SAGE)
    d, m = _u(d, m, _sd_cone(p, HEAD_R0, HEAD_R1, HEAD_Z0, HEAD_Z1), MAT_SAGE)
    d, m = _u(d, m, _sd_torus(p, RING_R, RING_r, RING_Z), ring_mat)
    d, m = _u(d, m, _sd_cone(p, 0.332, 0.312, 0.752, 0.905), MAT_CREAM)
    d, m = _u(d, m, _sd_ellipsoid(p, 0.0, 0.0, 0.900, DOME_R, DOME_R, DOME_H * 1.05), MAT_CREAM)
    return d, m


def _scene_glyphs(kind: str, p: np.ndarray):
    """Standing glyphs in world units (same as pin_glyphs meshes)."""
    z0 = PLATE_Z
    far = np.full(p.shape[:-1], 1e9, dtype=np.float64)
    empty = np.zeros(p.shape[:-1], dtype=np.int32)
    near = (np.hypot(p[..., 0], p[..., 1]) < 0.42) & (p[..., 2] > 0.82)
    if not np.any(near):
        return far, empty

    def mask(d):
        return np.where(near, d, 1e9)

    base = kind.replace("-out", "")
    if base in ("trailhead", "finish"):
        d, m = mask(_sd_cone(
            np.stack([p[..., 0] + 0.10, p[..., 1], p[..., 2]], axis=-1),
            0.030, 0.030, z0, z0 + 0.24,
        )), MAT_INK
        d, m = _u(d, m, mask(_sd_box(p, 0.03, 0.0, z0 + 0.18, 0.22, 0.044, 0.12)), MAT_ORANGE)
        return d, m
    if base == "start":
        d, m = mask(_sd_box(p, 0.00, 0.0, z0 + 0.11, 0.24, 0.056, 0.18)), MAT_ORANGE
        return d, m
    if kind == "viewpoint":
        d, m = mask(_sd_prism(p, [(-0.20, -0.10), (0.02, -0.10), (-0.10, 0.10)], z0, z0 + 0.11)), MAT_INK
        d, m = _u(d, m, mask(_sd_prism(p, [(-0.04, -0.10), (0.20, -0.10), (0.08, 0.14)], z0, z0 + 0.15)), MAT_INK)
        d, m = _u(d, m, mask(_sd_sphere(p, 0.12, 0.12, z0 + 0.14, 0.055)), MAT_ORANGE)
        return d, m
    if kind == "cafe":
        d, m = mask(_sd_cone(p, 0.11, 0.12, z0, z0 + 0.13)), MAT_INK
        d, m = _u(d, m, mask(_sd_cone(p, 0.09, 0.09, z0 + 0.115, z0 + 0.138)), MAT_ORANGE)
        d, m = _u(d, m, mask(_sd_box(p, 0.195, 0.0, z0 + 0.07, 0.045, 0.045, 0.09)), MAT_INK)
        return d, m
    if kind == "culture":
        d, m = mask(_sd_box(p, 0.0, 0.0, z0 + 0.02, 0.38, 0.10, 0.04)), MAT_INK
        for dx in (-0.12, 0.0, 0.12):
            col = np.stack([p[..., 0] - dx, p[..., 1], p[..., 2]], axis=-1)
            d, m = _u(d, m, mask(_sd_cone(col, 0.028, 0.028, z0 + 0.02, z0 + 0.15)), MAT_INK)
        d, m = _u(d, m, mask(_sd_box(p, 0.0, 0.0, z0 + 0.165, 0.40, 0.10, 0.04)), MAT_ORANGE)
        return d, m
    if kind == "water":
        d, m = mask(_sd_sphere(p, 0.0, 0.0, z0 + 0.10, 0.09)), MAT_INK
        d, m = _u(d, m, mask(_sd_cone(
            np.stack([p[..., 0], p[..., 1], p[..., 2]], axis=-1),
            0.02, 0.09, z0 + 0.10, z0 + 0.20,
        )), MAT_INK)
        d, m = _u(d, m, mask(_sd_sphere(p, -0.03, 0.0, z0 + 0.08, 0.032)), MAT_ORANGE)
        return d, m
    if kind == "transit":
        d, m = mask(_sd_box(p, 0.0, 0.0, z0 + 0.08, 0.32, 0.14, 0.12)), MAT_INK
        d, m = _u(d, m, mask(_sd_box(p, 0.0, -0.06, z0 + 0.10, 0.20, 0.03, 0.06)), MAT_ORANGE)
        w0 = np.stack([p[..., 0] + 0.09, p[..., 1], p[..., 2]], axis=-1)
        w1 = np.stack([p[..., 0] - 0.09, p[..., 1], p[..., 2]], axis=-1)
        d, m = _u(d, m, mask(_sd_cone(w0, 0.038, 0.038, z0, z0 + 0.05)), MAT_INK)
        d, m = _u(d, m, mask(_sd_cone(w1, 0.038, 0.038, z0, z0 + 0.05)), MAT_INK)
        return d, m
    if kind in ("meetup", "meet"):
        d, m = mask(_sd_sphere(p, -0.10, 0.04, z0 + 0.14, 0.055)), MAT_INK
        a_b = np.stack([p[..., 0] + 0.10, p[..., 1] - 0.04, p[..., 2]], axis=-1)
        d, m = _u(d, m, mask(_sd_cone(a_b, 0.055, 0.032, z0, z0 + 0.10)), MAT_INK)
        d, m = _u(d, m, mask(_sd_sphere(p, 0.10, 0.04, z0 + 0.14, 0.055)), MAT_INK)
        b_b = np.stack([p[..., 0] - 0.10, p[..., 1] - 0.04, p[..., 2]], axis=-1)
        d, m = _u(d, m, mask(_sd_cone(b_b, 0.055, 0.032, z0, z0 + 0.10)), MAT_INK)
        d, m = _u(d, m, mask(_sd_sphere(p, 0.00, -0.08, z0 + 0.13, 0.050)), MAT_ORANGE)
        c_b = np.stack([p[..., 0], p[..., 1] + 0.08, p[..., 2]], axis=-1)
        d, m = _u(d, m, mask(_sd_cone(c_b, 0.048, 0.028, z0, z0 + 0.09)), MAT_ORANGE)
        return d, m
    if kind == "stimme":
        d, m = mask(_sd_box(p, 0.02, 0.02, z0 + 0.10, 0.28, 0.16, 0.14)), MAT_WHITE
        d, m = _u(d, m, mask(_sd_box(p, 0.02, 0.02, z0 + 0.10, 0.20, 0.10, 0.08)), MAT_ORANGE)
        return d, m
    d, m = mask(_sd_prism(p, [(-0.22, -0.04), (-0.04, -0.04), (-0.14, 0.12)], z0, z0 + 0.10)), MAT_INK
    d, m = _u(d, m, mask(_sd_prism(p, [(-0.09, -0.04), (0.09, -0.04), (0.00, 0.20)], z0, z0 + 0.16)), MAT_INK)
    d, m = _u(d, m, mask(_sd_prism(p, [(0.04, -0.04), (0.22, -0.04), (0.14, 0.13)], z0, z0 + 0.11)), MAT_INK)
    d, m = _u(d, m, mask(_sd_box(p, 0.0, -0.12, z0 + 0.028, 0.44, 0.055, 0.045)), MAT_ORANGE)
    d, m = _u(d, m, mask(_sd_box(p, 0.0, -0.16, z0 + 0.018, 0.34, 0.036, 0.030)), MAT_SAGE)
    return d, m


def _scene(kind: str, p: np.ndarray):
    ring = MAT_GREEN if kind == "start" else (
        MAT_SAGE if kind.endswith("-out") else MAT_ORANGE
    )
    d, m = _scene_body(p, ring)
    dg, mg = _scene_glyphs(kind, p)
    return _u(d, m, dg, mg)


def _camera():
    # More top-down so glyphs read as icons; still 3/4 for stem/ring thickness.
    eye = np.array([0.40, -0.70, 2.02], dtype=np.float64)
    target = np.array([0.0, 0.02, 0.52], dtype=np.float64)
    up = np.array([0.0, 0.0, 1.0], dtype=np.float64)
    return eye, target, up


def _camera_basis():
    eye, target, up = _camera()
    zaxis = eye - target
    zaxis = zaxis / np.linalg.norm(zaxis)
    xaxis = np.cross(up, zaxis)
    xaxis = xaxis / np.linalg.norm(xaxis)
    yaxis = np.cross(zaxis, xaxis)
    return eye, target, xaxis, yaxis, zaxis


def _look_at_ortho(verts: np.ndarray, eye, target, up, scale, cx, cy):
    eye = np.asarray(eye, dtype=np.float64)
    target = np.asarray(target, dtype=np.float64)
    up = np.asarray(up, dtype=np.float64)
    zaxis = eye - target
    zaxis = zaxis / np.linalg.norm(zaxis)
    xaxis = np.cross(up, zaxis)
    xaxis = xaxis / np.linalg.norm(xaxis)
    yaxis = np.cross(zaxis, xaxis)
    rel = verts - target
    cam = np.stack((rel @ xaxis, rel @ yaxis, (verts - eye) @ zaxis), axis=1)
    screen = np.empty_like(cam)
    screen[:, 0] = cx + cam[:, 0] * scale
    screen[:, 1] = cy - cam[:, 1] * scale
    screen[:, 2] = -cam[:, 2]
    return screen, xaxis, yaxis, zaxis


def _raster_sdf(kind: str, w: int, h: int):
    eye, target, xaxis, yaxis, zaxis = _camera_basis()
    scale = min(w, h) * 1.12
    cx, cy = w * 0.50, h * 0.48
    view = -zaxis

    xs = np.arange(w, dtype=np.float64)
    ys = np.arange(h, dtype=np.float64)
    xx, yy = np.meshgrid(xs, ys, indexing="xy")
    u = (xx - cx) / scale
    v = (cy - yy) / scale
    ro = target + u[..., None] * xaxis + v[..., None] * yaxis + zaxis * 1.85
    rd = view

    t = np.zeros((h, w), dtype=np.float64)
    d = np.full((h, w), 1e9, dtype=np.float64)
    mat = np.zeros((h, w), dtype=np.int32)
    live = np.ones((h, w), dtype=bool)
    for _ in range(48):
        if not np.any(live):
            break
        p = ro + t[..., None] * rd
        d_now, m_now = _scene(kind, p)
        d = np.where(live, d_now, d)
        mat = np.where(live, m_now, mat)
        arrived = live & (d_now < 0.0020)
        escaped = live & ((t > 4.6) | (d_now > 8.0))
        live = live & ~arrived & ~escaped
        t = t + np.where(live, np.clip(d_now, 0.0007, 0.14), 0.0)

    hit = (d < 0.008) & (t < 4.6)
    p = ro + t[..., None] * rd

    # Tetrahedral normals on hits only (cheap full-image eps).
    eps = 0.0024
    e = np.array(
        [
            [1.0, -1.0, -1.0],
            [-1.0, -1.0, 1.0],
            [-1.0, 1.0, -1.0],
            [1.0, 1.0, 1.0],
        ]
    )
    n = np.zeros((h, w, 3), dtype=np.float64)
    for k in range(4):
        dk, _ = _scene(kind, p + e[k] * eps)
        n += dk[..., None] * e[k]
    nn = np.linalg.norm(n, axis=2)
    nn = np.where(nn < 1e-8, 1.0, nn)
    n = n / nn[..., None]
    # SDF gradient is already outward — do not flip toward the camera.

    key = np.array([0.64, -0.40, 0.66], dtype=np.float64)
    key = key / np.linalg.norm(key)
    fill = np.array([-0.55, -0.10, 0.83], dtype=np.float64)
    fill = fill / np.linalg.norm(fill)
    rim = np.array([-0.20, 0.90, 0.38], dtype=np.float64)
    rim = rim / np.linalg.norm(rim)
    half = key + view
    half = half / np.linalg.norm(half)

    ndotk = np.clip(n @ key, 0.0, 1.0)
    ndotf = np.clip(n @ fill, 0.0, 1.0)
    ndotr = np.clip(n @ rim, 0.0, 1.0)
    wrap = 0.56 + 0.30 * ndotk + 0.07 * ndotf + 0.05 * ndotr
    wrap = np.clip(wrap, 0.46, 0.98)

    # Soft shade under the disc onto the stem — keep charcoal dark, not grey.
    under = (p[..., 2] < 0.58) & (np.hypot(p[..., 0], p[..., 1]) < 0.36)
    wrap = wrap * np.where(under, 0.72, 1.0)
    dark = (mat == MAT_CHARCOAL) | (mat == MAT_CHARCOAL_SOFT) | (mat == MAT_SAGE)
    wrap = np.where(dark, wrap * 0.82, wrap)

    ao_d, _ = _scene(kind, p + n * 0.045)
    ao = np.clip(ao_d / 0.045, 0.72, 1.0)
    wrap = wrap * (0.84 + 0.16 * ao)

    albedo = _MAT_ALBEDO[mat]
    rough = _MAT_ROUGH[mat]
    metal = _MAT_METAL[mat]
    shin = 22.0 + (1.0 - rough) * 32.0
    spec_k = 0.04 + 0.10 * (1.0 - rough) + 0.08 * metal
    spec = spec_k * np.clip(n @ half, 0.0, 1.0) ** shin
    fres = 0.05 * (1.0 - np.clip(n @ view, 0.0, 1.0)) ** 2

    rgb = albedo * wrap[..., None]
    is_orange = mat == MAT_ORANGE
    # Emission toward brand orange so the rim does not go yellow-gold.
    rgb = rgb + np.where(is_orange[..., None], ORANGE * 0.28, 0.0)
    spec_rgb = np.where(is_orange[..., None], ORANGE * (spec[..., None] * 0.45), WHITE * spec[..., None])
    rgb = rgb + spec_rgb
    rgb = rgb + albedo * fres[..., None]
    rgb = np.clip(rgb, 0, 255)

    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[..., :3] = np.where(hit[..., None], rgb, 0).astype(np.uint8)
    rgba[..., 3] = np.where(hit, 255, 0).astype(np.uint8)
    from PIL import Image

    return Image.fromarray(rgba, "RGBA")


def _shadow(w: int, h: int):
    eye, target, up = _camera()
    scale = min(w, h) * 1.12
    cx_s, cy_s = w * 0.50, h * 0.48
    foot = np.array([[0.0, 0.0, 0.0]], dtype=np.float64)
    scr, *_ = _look_at_ortho(foot, eye, target, up, scale, cx_s, cy_s)
    cx, cy = float(scr[0, 0]) + w * 0.018, float(scr[0, 1]) + h * 0.018
    yy, xx = np.mgrid[0:h, 0:w]
    rx, ry = w * 0.20, h * 0.042
    dist = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    a = np.clip(1.20 - dist, 0.0, 1.0)
    a = (a**1.25) * 150.0
    img = np.zeros((h, w, 4), dtype=np.uint8)
    img[..., :3] = 12
    img[..., 3] = np.clip(a, 0, 165).astype(np.uint8)
    from PIL import Image, ImageFilter

    out = Image.fromarray(img, "RGBA")
    return out.filter(ImageFilter.GaussianBlur(radius=max(4, w // 36)))


def _box_downscale(im, ss: int):
    a = np.asarray(im, dtype=np.float32)
    h, w = a.shape[:2]
    rgb = a[..., :3] * (a[..., 3:4] / 255.0)
    prem = np.concatenate([rgb, a[..., 3:4]], axis=2)
    out = prem.reshape(h // ss, ss, w // ss, ss, 4).mean(axis=(1, 3))
    alpha = out[..., 3:4]
    rgb_out = np.zeros_like(out[..., :3])
    live = alpha[..., 0] > 0.4
    rgb_out[live] = np.clip(out[..., :3][live] * (255.0 / alpha[..., 0][live, None]), 0, 255)
    rgba = np.zeros_like(out)
    rgba[..., :3] = rgb_out
    rgba[..., 3] = out[..., 3]
    from PIL import Image

    return Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8), "RGBA")


def render_pin_png(kind: str):
    from PIL import Image

    w, h = RENDER_W * SS, RENDER_H * SS
    pin = _raster_sdf(kind, w, h)
    shadow = _shadow(w, h)
    out = Image.alpha_composite(shadow, pin)
    return _box_downscale(out, SS)


def _file_stem(kind: str) -> str:
    if kind == "place":
        return "poi"
    if kind in ROUTE_PIN_KINDS:
        return f"pin-{kind}"
    return f"poi-{kind}"


def write_glb(path: str, parts: list[dict]) -> None:
    """Minimal glTF 2.0 binary — PBR materials, no textures, no HDRI."""
    bin_chunks: list[bytes] = []
    buffer_views = []
    accessors = []
    meshes = []
    materials = []
    nodes = []

    def align4(b: bytes) -> bytes:
        pad = (4 - (len(b) % 4)) % 4
        return b + (b"\x00" * pad)

    for i, part in enumerate(parts):
        verts = part["verts"].astype(np.float32)
        faces = part["faces"].astype(np.uint16)
        nrm = part.get("normals")
        if nrm is None:
            nrm = _vertex_normals(part["verts"], part["faces"])
        nrm = nrm.astype(np.float32)
        pos_b = verts.tobytes()
        nrm_b = nrm.tobytes()
        idx_b = faces.flatten().tobytes()

        def push(data: bytes, target: int) -> int:
            data = align4(data)
            view_i = len(buffer_views)
            buffer_views.append(
                {
                    "buffer": 0,
                    "byteOffset": sum(len(c) for c in bin_chunks),
                    "byteLength": len(data),
                    "target": target,
                }
            )
            bin_chunks.append(data)
            return view_i

        pos_view = push(pos_b, 34962)
        nrm_view = push(nrm_b, 34962)
        idx_view = push(idx_b, 34963)
        mn = verts.min(axis=0).tolist()
        mx = verts.max(axis=0).tolist()
        pos_acc = len(accessors)
        accessors.append(
            {
                "bufferView": pos_view,
                "componentType": 5126,
                "count": len(verts),
                "type": "VEC3",
                "min": mn,
                "max": mx,
            }
        )
        nrm_acc = len(accessors)
        accessors.append(
            {
                "bufferView": nrm_view,
                "componentType": 5126,
                "count": len(nrm),
                "type": "VEC3",
            }
        )
        idx_acc = len(accessors)
        accessors.append(
            {
                "bufferView": idx_view,
                "componentType": 5123,
                "count": int(faces.size),
                "type": "SCALAR",
            }
        )
        col = (part["color"] / 255.0).tolist()
        materials.append(
            {
                "name": part["name"],
                "pbrMetallicRoughness": {
                    "baseColorFactor": col + [1.0],
                    "metallicFactor": float(part.get("metallic", 0.04)),
                    "roughnessFactor": float(part["roughness"]),
                },
            }
        )
        meshes.append(
            {
                "name": part["name"],
                "primitives": [
                    {
                        "attributes": {"POSITION": pos_acc, "NORMAL": nrm_acc},
                        "indices": idx_acc,
                        "material": i,
                    }
                ],
            }
        )
        nodes.append({"name": part["name"], "mesh": i})

    blob = b"".join(bin_chunks)
    gltf = {
        "asset": {"version": "2.0", "generator": "FlowLine POI pins"},
        "scene": 0,
        "scenes": [{"nodes": list(range(len(nodes)))}],
        "nodes": nodes,
        "meshes": meshes,
        "materials": materials,
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(blob)}],
    }
    json_b = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    json_pad = (4 - (len(json_b) % 4)) % 4
    json_b = json_b + (b" " * json_pad)
    bin_pad = (4 - (len(blob) % 4)) % 4
    blob = blob + (b"\x00" * bin_pad)

    total = 12 + 8 + len(json_b) + 8 + len(blob)
    header = struct.pack("<4sII", b"glTF", 2, total)
    jchunk = struct.pack("<II", len(json_b), 0x4E4F534A) + json_b
    bchunk = struct.pack("<II", len(blob), 0x004E4942) + blob
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as f:
        f.write(header + jchunk + bchunk)


def find_blender_cmd() -> list[str] | None:
    """Command prefix that launches Blender in the background.

    Native `blender` first; Flatpak `org.blender.Blender` is common on this
    machine (not on PATH).
    """
    env = os.environ.get("BLENDER")
    if env:
        import shlex

        return shlex.split(env)
    if shutil.which("blender"):
        return ["blender"]
    for cand in (
        "/usr/bin/blender",
        "/usr/local/bin/blender",
        "/snap/bin/blender",
        os.path.expanduser("~/blender/blender"),
    ):
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return [cand]
    if shutil.which("flatpak"):
        probe = subprocess.run(
            ["flatpak", "info", "org.blender.Blender"],
            capture_output=True,
        )
        if probe.returncode == 0:
            return [
                "flatpak",
                "run",
                "--filesystem=host",
                "org.blender.Blender",
            ]
    return None


def run_blender(root: str, blender_cmd: list[str]) -> bool:
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "blender_poi_pins.py")
    cmd = [
        *blender_cmd,
        "--background",
        "--python",
        script,
        "--",
        "--root",
        root,
    ]
    print("blender:", " ".join(cmd), flush=True)
    try:
        proc = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except OSError as exc:
        print(f"blender failed to start: {exc}", file=sys.stderr)
        return False
    if proc.stdout:
        print(proc.stdout, end="" if proc.stdout.endswith("\n") else "\n")
    if proc.stderr:
        print(proc.stderr, end="" if proc.stderr.endswith("\n") else "\n", file=sys.stderr)
    if proc.returncode != 0:
        return False
    if "Error" in (proc.stderr or "") and "blender ok" not in (proc.stdout or ""):
        return False
    return "blender ok" in (proc.stdout or "")


def render_via_disc(outside: bool = False):
    """Raster cream disc + ring — numbered vias stay discs, not teardrops."""
    from PIL import Image

    size = 256
    cx = cy = size / 2.0
    ring_rgb = SAGE if outside else ORANGE
    yy, xx = np.mgrid[0:size, 0:size]
    r = np.hypot(xx + 0.5 - cx, yy + 0.5 - cy)
    outer, inner = 108.0, 86.0
    rgba = np.zeros((size, size, 4), dtype=np.uint8)
    # Soft contact shadow
    shadow_r = np.hypot(xx + 0.5 - cx, yy + 0.5 - (cy + 6))
    sh = np.clip((118 - shadow_r) / 18.0, 0, 1) * 0.28
    rgba[..., 3] = (sh * 255).astype(np.uint8)
    fill = r <= inner
    ring = (r <= outer) & (r > inner)
    cream = np.array([244, 241, 236, 255], dtype=np.uint8)
    edge = np.array([*ring_rgb.astype(np.uint8), 255], dtype=np.uint8)
    rgba[fill] = cream
    rgba[ring] = edge
    # Anti-alias ring edges
    for limit, col in ((outer, edge), (inner, cream)):
        band = np.abs(r - limit) < 1.2
        a = (1.0 - np.abs(r - limit) / 1.2).clip(0, 1)
        for c in range(3):
            rgba[..., c] = np.where(
                band,
                (rgba[..., c] * (1 - a) + col[c] * a).astype(np.uint8),
                rgba[..., c],
            )
        rgba[..., 3] = np.where(
            band,
            np.maximum(rgba[..., 3], (a * 255).astype(np.uint8)),
            rgba[..., 3],
        )
    return Image.fromarray(rgba, "RGBA")


def write_via_discs(root: str) -> None:
    public_png = os.path.join(root, "public", "map", "pins")
    mobile_png = os.path.join(root, "mobile", "assets", "map", "pins")
    os.makedirs(public_png, exist_ok=True)
    os.makedirs(mobile_png, exist_ok=True)
    for outside, stem in ((False, "pin-via"), (True, "pin-via-out")):
        img = render_via_disc(outside)
        pub = os.path.join(public_png, f"{stem}.png")
        mob = os.path.join(mobile_png, f"{stem}.png")
        img.save(pub, "PNG", optimize=True)
        img.save(mob, "PNG", optimize=True)
        print(f"via disc ok {stem}", flush=True)


def write_outputs(root: str, kinds: Iterable[str]) -> None:
    public_png = os.path.join(root, "public", "map", "pins")
    public_3d = os.path.join(public_png, "poi")
    mobile_png = os.path.join(root, "mobile", "assets", "map", "pins")
    os.makedirs(public_3d, exist_ok=True)
    os.makedirs(mobile_png, exist_ok=True)
    for kind in kinds:
        stem = _file_stem(kind)
        parts = pin_parts(kind)
        png = render_pin_png(kind)
        pub = os.path.join(public_png, f"{stem}.png")
        mob = os.path.join(mobile_png, f"{stem}.png")
        png.save(pub, "PNG", optimize=True)
        png.save(mob, "PNG", optimize=True)
        write_glb(os.path.join(public_3d, f"{stem}.glb"), parts)
        print(f"fallback ok {stem}", flush=True)


def main() -> int:
    here = os.path.dirname(os.path.abspath(__file__))
    default_root = os.path.abspath(os.path.join(here, "..", ".."))
    p = argparse.ArgumentParser(description="Render FlowLine 3D POI pin sprites")
    p.add_argument("--root", default=default_root)
    p.add_argument("--force-fallback", action="store_true")
    p.add_argument("--kinds", nargs="*", default=list(KINDS))
    args = p.parse_args()
    root = os.path.abspath(args.root)
    kinds = args.kinds or list(KINDS)
    blender = None if args.force_fallback else find_blender_cmd()
    if blender:
        if run_blender(root, blender):
            print(f"used blender: {' '.join(blender)}")
            write_via_discs(root)
            return 0
        print("blender run failed — using numpy fallback", file=sys.stderr)
    else:
        print("blender not found — using numpy fallback (same meshes → PNG + GLB)")
    write_outputs(root, kinds)
    write_via_discs(root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
