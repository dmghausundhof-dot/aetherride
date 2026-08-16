#!/usr/bin/env python3
"""Bake OSRM cycling loop polylines into Nähe seed JSON assets.

Replaces perfect-circle offline fallbacks with street-routed [[lng,lat],…]
geometry for Discover map / mini-map. Re-run when adding cities/regions.

Usage (from repo root):
  python3 scripts/bake-seed-loop-geometry.py
  python3 scripts/bake-seed-loop-geometry.py --only-outliers
"""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
SEED_FILES = [
    ROOT / "mobile/assets/seeds/naehe-peek-seeds-berlin-v1.json",
    ROOT / "mobile/assets/seeds/p0-dach-60min-naehe-v1.json",
    ROOT / "mobile/assets/seeds/p0-gaps-60min-naehe-v1.json",
    ROOT / "mobile/assets/seeds/p0-france-60min-naehe-v1.json",
    ROOT / "mobile/assets/seeds/p0-rhein-neckar-60min-naehe-v1.json",
    ROOT / "mobile/assets/seeds/p0-rhein-neckar-60min-premium-v1.json",
]


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


def simplify(coords: list[list[float]], max_pts: int = 100) -> list[list[float]]:
    if len(coords) <= max_pts:
        return coords
    step = max(1, len(coords) // max_pts)
    out = coords[::step]
    if out[-1] != coords[-1]:
        out.append(coords[-1])
    if out[0] != out[-1]:
        out.append(out[0][:])
    return out


def make_wps(
    lat: float,
    lng: float,
    distance_km: float,
    seed_id: str,
    *,
    scale: float = 1.0,
    n: int = 5,
) -> list[tuple[float, float]]:
    h = sum(ord(c) for c in seed_id)
    phase = (h % 12) * math.pi / 12
    radius_km = max(0.7, distance_km / (2 * math.pi)) * scale
    rx = radius_km * (1.04 + (h % 5) * 0.015)
    ry = radius_km * (0.90 + (h % 7) * 0.015)
    coslat = max(0.2, abs(math.cos(lat * math.pi / 180)))
    dlat = ry / 111.0
    dlng = rx / (111.0 * coslat)
    wps: list[tuple[float, float]] = []
    for i in range(n):
        a = phase + 2 * math.pi * i / n
        wobble = 0.84 + 0.22 * ((i * 3 + h) % 5) / 4
        wps.append(
            (lng + dlng * math.cos(a) * wobble, lat + dlat * math.sin(a) * wobble)
        )
    wps.append(wps[0])
    return wps


def osrm(wps: list[tuple[float, float]]) -> tuple[list[list[float]], float]:
    coords_str = ";".join(f"{lng:.6f},{lat:.6f}" for lng, lat in wps)
    url = (
        "https://router.project-osrm.org/route/v1/cycling/"
        f"{coords_str}?overview=full&geometries=geojson"
    )
    req = urllib.request.Request(url, headers={"User-Agent": "aetherride-seed-geom/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.load(resp)
    if data.get("code") != "Ok" or not data.get("routes"):
        raise RuntimeError(str(data.get("code")))
    route = data["routes"][0]
    geom = [
        [round(c[0], 5), round(c[1], 5)] for c in route["geometry"]["coordinates"]
    ]
    geom = simplify(geom, 100)
    if haversine_km(geom[0][1], geom[0][0], geom[-1][1], geom[-1][0]) > 0.05:
        geom.append(geom[0][:])
    return geom, route["distance"] / 1000


def bake_one(
    lat: float, lng: float, dist: float, cid: str
) -> tuple[list[list[float]], float, float, int]:
    best: tuple[int, float, float, list[list[float]], float, int] | None = None
    # Extra-small scales help alpine outliers (Uetliberg / Bremgarten) land in-band.
    for scale in (0.40, 0.48, 0.55, 0.7, 0.85, 1.0, 1.15):
        for n in (4, 5, 6, 7):
            try:
                geom, km = osrm(make_wps(lat, lng, dist, cid, scale=scale, n=n))
                score = abs(km - dist)
                in_band = dist * 0.55 <= km <= dist * 1.75
                cand = (0 if in_band else 1, score, km, geom, scale, n)
                if best is None or cand[:2] < best[:2]:
                    best = cand
                if in_band and score < dist * 0.25:
                    return geom, km, scale, n
                time.sleep(0.25)
            except Exception:
                time.sleep(0.3)
    if best is None:
        raise RuntimeError("no route")
    return best[3], best[2], best[4], best[5]


def iter_seeds(data: object):
    if isinstance(data, list):
        yield from data
    elif isinstance(data, dict):
        for s in data.get("seeds") or []:
            yield s


def is_loop(s: dict) -> bool:
    return bool(s.get("is_loop") or s.get("loop") or s.get("closed"))


def center_of(s: dict) -> tuple[float, float]:
    c = s.get("center") or s.get("start_area") or {}
    return float(c["lat"]), float(c.get("lng") or c.get("lon"))


def is_degenerate_geom(geom: object) -> bool:
    """Match mobile isDegenerateTrack — rulers / coarse polygons."""
    if not isinstance(geom, list) or len(geom) < 4:
        return True
    segs: list[float] = []
    for i in range(1, len(geom)):
        a, b = geom[i - 1], geom[i]
        if not (isinstance(a, list) and isinstance(b, list) and len(a) >= 2 and len(b) >= 2):
            return True
        segs.append(haversine_km(a[1], a[0], b[1], b[0]))
    path = sum(segs)
    if path < 0.05:
        return True
    chord = haversine_km(geom[0][1], geom[0][0], geom[-1][1], geom[-1][0])
    closed = chord < max(0.30, path * 0.05)
    if not closed:
        straightness = chord / path
        if straightness > 0.92:
            return True
        if len(geom) <= 6 and straightness > 0.85:
            return True
        return False
    if len(geom) <= 6:
        return True
    if max(segs) / path > 0.45:
        return True
    return False


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--only-outliers",
        action="store_true",
        help="Only re-route seeds whose geometry_distance is outside 0.55–1.75× target "
        "or whose polyline is degenerate (ruler / too coarse)",
    )
    ap.add_argument(
        "--missing-only",
        action="store_true",
        help="Only bake loops that lack usable geometry (≥4 points)",
    )
    ap.add_argument(
        "--file",
        action="append",
        dest="files",
        help="Limit to one or more seed JSON paths (repeatable)",
    )
    args = ap.parse_args()

    paths = [pathlib.Path(p) for p in args.files] if args.files else SEED_FILES

    for path in paths:
        if not path.is_absolute():
            path = ROOT / path
        if not path.exists():
            print("skip missing", path)
            continue
        data = json.loads(path.read_text())
        changed = False
        for s in iter_seeds(data):
            if not isinstance(s, dict) or not is_loop(s):
                continue
            if s.get("type") not in (None, "route"):
                continue
            dist = float(s.get("distance_km") or 15)
            gkm = float(s.get("geometry_distance_km") or 0)
            ratio = (gkm / dist) if dist and gkm else None
            geom = s.get("geometry")
            has_geom = isinstance(geom, list) and len(geom) >= 4
            degenerate = is_degenerate_geom(geom) if has_geom else True
            if args.missing_only and has_geom and not degenerate:
                continue
            if args.only_outliers:
                in_band = ratio is not None and 0.55 <= ratio <= 1.75
                if in_band and has_geom and not degenerate:
                    continue
            cid = s.get("id") or "?"
            lat, lng = center_of(s)
            why = []
            if not has_geom:
                why.append("missing")
            elif degenerate:
                why.append("degenerate")
            if ratio is not None and not (0.55 <= ratio <= 1.75):
                why.append(f"ratio={ratio:.2f}")
            print(f"Routing {cid} ({','.join(why) or 'refresh'}) …", flush=True)
            try:
                geom, km, scale, n = bake_one(lat, lng, dist, cid)
                s["geometry"] = geom
                s["geometry_engine"] = "osrm-cycling-prebake-v1"
                s["geometry_distance_km"] = round(km, 2)
                print(f"  OK {km:.1f} km pts={len(geom)} scale={scale} n={n}")
                changed = True
            except Exception as e:
                print(f"  FAIL {e}")
        if changed:
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
            print("Wrote", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
