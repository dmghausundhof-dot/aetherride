#!/usr/bin/env python3
"""Bake OSRM cycling polylines for every public catalog tour.

Writes data/catalog/tour-geometry-overrides.json and a mobile asset copy
so Discover can paint Wiesloch / DACH / all catalog loops without live routing.

Usage (from repo root):
  npx tsx scripts/export-public-tours.ts
  python3 scripts/bake-catalog-tour-geometry.py
"""

from __future__ import annotations

import json
import math
import pathlib
import shutil
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPORT = ROOT / "data/catalog/public-tours-export.json"
OUT = ROOT / "data/catalog/tour-geometry-overrides.json"
MOBILE = ROOT / "mobile/assets/catalog/tour-geometry-overrides.json"


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p = math.pi / 180
    a = (
        math.sin((lat2 - lat1) * p / 2) ** 2
        + math.cos(lat1 * p)
        * math.cos(lat2 * p)
        * math.sin((lng2 - lng1) * p / 2) ** 2
    )
    return 2 * r * math.asin(math.sqrt(min(1.0, a)))


def simplify(coords: list[list[float]], max_pts: int = 120) -> list[list[float]]:
    if len(coords) <= max_pts:
        return coords
    step = max(1, len(coords) // max_pts)
    out = coords[::step]
    if out[-1] != coords[-1]:
        out.append(coords[-1])
    return out


def make_wps(
    lat: float,
    lng: float,
    distance_km: float,
    tour_id: str,
    *,
    loop: bool,
    scale: float = 1.0,
    n: int = 5,
) -> list[tuple[float, float]]:
    h = sum(ord(c) for c in tour_id)
    phase = (h % 12) * math.pi / 12
    radius_km = max(0.7, distance_km / (2 * math.pi)) * scale
    rx = radius_km * (1.04 + (h % 5) * 0.015)
    ry = radius_km * (0.90 + (h % 7) * 0.015)
    coslat = max(0.2, abs(math.cos(lat * math.pi / 180)))
    dlat = ry / 111.0
    dlng = rx / (111.0 * coslat)
    if loop:
        wps: list[tuple[float, float]] = []
        for i in range(n):
            a = phase + 2 * math.pi * i / n
            wobble = 0.84 + 0.22 * ((i * 3 + h) % 5) / 4
            wps.append(
                (lng + dlng * math.cos(a) * wobble, lat + dlat * math.sin(a) * wobble)
            )
        wps.append(wps[0])
        return wps
    span = max(2.0, min(distance_km * 0.45, 35.0)) * scale
    dlat_s = span / 111.0
    dlng_s = span / (111.0 * coslat)
    return [
        (lng - dlng_s * 0.5, lat - dlat_s * 0.08),
        (lng, lat + dlat_s * 0.12),
        (lng + dlng_s * 0.5, lat + dlat_s * 0.05),
    ]


def osrm(wps: list[tuple[float, float]]) -> tuple[list[list[float]], float]:
    coords_str = ";".join(f"{lng:.6f},{lat:.6f}" for lng, lat in wps)
    url = (
        "https://router.project-osrm.org/route/v1/cycling/"
        f"{coords_str}?overview=full&geometries=geojson"
    )
    req = urllib.request.Request(url, headers={"User-Agent": "aetherride-catalog-geom/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.load(resp)
    if data.get("code") != "Ok" or not data.get("routes"):
        raise RuntimeError(str(data.get("code")))
    route = data["routes"][0]
    geom = [
        [round(c[0], 5), round(c[1], 5)] for c in route["geometry"]["coordinates"]
    ]
    geom = simplify(geom, 120)
    if (
        len(wps) > 3
        and haversine_km(geom[0][1], geom[0][0], geom[-1][1], geom[-1][0]) > 0.05
    ):
        geom.append(geom[0][:])
    return geom, route["distance"] / 1000


def bake_one(
    lat: float, lng: float, dist: float, cid: str, loop: bool
) -> tuple[list[list[float]], float]:
    best: tuple[int, float, list[list[float]], float] | None = None
    for scale in (0.40, 0.55, 0.7, 0.85, 1.0, 1.15):
        for n in (4, 5, 6) if loop else (3,):
            try:
                geom, km = osrm(
                    make_wps(lat, lng, dist, cid, loop=loop, scale=scale, n=n)
                )
                score = abs(km - dist)
                in_band = dist * 0.55 <= km <= dist * 1.75
                cand = (0 if in_band else 1, score, geom, km)
                if best is None or cand[:2] < best[:2]:
                    best = cand
                if in_band and score < dist * 0.25:
                    return geom, km
                time.sleep(0.2)
            except Exception:
                time.sleep(0.35)
    if best is None:
        raise RuntimeError("no route")
    return best[2], best[3]


def main() -> None:
    if not EXPORT.exists():
        raise SystemExit(f"missing {EXPORT} — run npx tsx scripts/export-public-tours.ts")
    tours = json.loads(EXPORT.read_text())
    existing: dict = {}
    if OUT.exists():
        try:
            existing = json.loads(OUT.read_text())
        except json.JSONDecodeError:
            existing = {}
    out: dict = dict(existing)
    for t in tours:
        tid = t["id"]
        prev = out.get(tid)
        if (
            isinstance(prev, dict)
            and isinstance(prev.get("coordinates"), list)
            and len(prev["coordinates"]) >= 8
            and str(prev.get("source") or "").startswith("osrm")
        ):
            print("keep", tid, len(prev["coordinates"]))
            continue
        lat = float(t["lat"])
        lng = float(t["lng"])
        dist = float(t["distanceKm"] or 15)
        loop = bool(t.get("loop", True))
        print("bake", tid, f"{dist:.0f}km", "loop" if loop else "ab")
        geom, km = bake_one(lat, lng, dist, tid, loop)
        out[tid] = {
            "coordinates": geom,
            "distanceM": int(round(km * 1000)),
            "durationS": int(round(float(t.get("durationMin") or km * 4) * 60)),
            "shape": "loop" if loop else "point_to_point",
            "source": "osrm-cycling-prebake-v1",
        }
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(json.dumps(out, ensure_ascii=False))
        print("  ->", len(geom), "pts", f"{km:.1f}km")
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
    MOBILE.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(OUT, MOBILE)
    print("wrote", OUT, "tours", len(out))
    print("copied", MOBILE)


if __name__ == "__main__":
    main()
