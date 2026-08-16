#!/usr/bin/env python3
"""Write a MapLibre style JSON for a DACH PMTiles extract (native needs JSON, not raw .pmtiles)."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

CDN = (
    "https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/"
    "offline-packs/basemap"
)
GLYPHS = f"{CDN}/assets/fonts/{{fontstack}}/{{range}}.pbf"
SPRITE = f"{CDN}/assets/sprites/v4/light"


def style_for(
    maxzoom: int,
    pmtiles_url: str,
    *,
    name: str | None = None,
    glyphs: str | None = None,
    sprite: str | None = None,
) -> dict:
    z = max(0, int(maxzoom))
    label = name or f"AetherRide DACH z0–{z}"
    return {
        "version": 8,
        "name": label,
        "glyphs": glyphs or GLYPHS,
        "sprite": sprite or SPRITE,
        "sources": {
            "protomaps": {
                "type": "vector",
                "url": f"pmtiles://{pmtiles_url}",
                "attribution": "© OpenStreetMap · Protomaps",
                "minzoom": 0,
                "maxzoom": z,
            }
        },
        "layers": [
            {
                "id": "background",
                "type": "background",
                "paint": {"background-color": "#e8eee9"},
            },
            {
                "id": "earth",
                "type": "fill",
                "source": "protomaps",
                "source-layer": "earth",
                "paint": {"fill-color": "#dfe8e2"},
            },
            {
                "id": "landcover",
                "type": "fill",
                "source": "protomaps",
                "source-layer": "landcover",
                "paint": {"fill-color": "#c5d9c8", "fill-opacity": 0.45},
            },
            {
                "id": "landuse",
                "type": "fill",
                "source": "protomaps",
                "source-layer": "landuse",
                "paint": {"fill-color": "#c5d9c8", "fill-opacity": 0.7},
            },
            {
                "id": "water",
                "type": "fill",
                "source": "protomaps",
                "source-layer": "water",
                "paint": {"fill-color": "#a8c8d8"},
            },
            {
                "id": "waterway",
                "type": "line",
                "source": "protomaps",
                "source-layer": "water",
                "filter": ["==", ["geometry-type"], "LineString"],
                "paint": {"line-color": "#a8c8d8", "line-width": 1},
            },
            {
                "id": "buildings",
                "type": "fill",
                "source": "protomaps",
                "source-layer": "buildings",
                "minzoom": min(10, z),
                "paint": {"fill-color": "#cfd6d0", "fill-opacity": 0.6},
            },
            {
                "id": "roads",
                "type": "line",
                "source": "protomaps",
                "source-layer": "roads",
                "paint": {
                    "line-color": "#6a7a72",
                    "line-width": [
                        "interpolate",
                        ["linear"],
                        ["zoom"],
                        6,
                        0.3,
                        10,
                        0.8,
                        z,
                        1.8,
                    ],
                },
            },
            {
                "id": "paths",
                "type": "line",
                "source": "protomaps",
                "source-layer": "roads",
                "minzoom": min(11, z),
                "filter": ["==", ["get", "kind"], "path"],
                "paint": {
                    "line-color": "#4a7a52",
                    "line-width": 1.2,
                    "line-dasharray": [2, 1],
                },
            },
            {
                "id": "cycleways",
                "type": "line",
                "source": "protomaps",
                "source-layer": "roads",
                "minzoom": min(11, z),
                "filter": ["==", ["get", "kind_detail"], "cycleway"],
                "paint": {
                    "line-color": "#1E88E5",
                    "line-width": 1.35,
                    "line-opacity": 0.85,
                },
            },
            {
                "id": "boundaries",
                "type": "line",
                "source": "protomaps",
                "source-layer": "boundaries",
                "paint": {
                    "line-color": "#9aa89c",
                    "line-width": 0.6,
                    "line-dasharray": [3, 2],
                },
            },
            {
                "id": "places",
                "type": "symbol",
                "source": "protomaps",
                "source-layer": "places",
                "minzoom": 5,
                "layout": {
                    "text-field": ["coalesce", ["get", "name:de"], ["get", "name"]],
                    "text-font": ["Noto Sans Regular"],
                    "text-size": [
                        "interpolate",
                        ["linear"],
                        ["zoom"],
                        5,
                        10,
                        z,
                        14,
                    ],
                },
                "paint": {
                    "text-color": "#2c3a32",
                    "text-halo-color": "#f4f7f4",
                    "text-halo-width": 1.2,
                },
            },
        ],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--maxzoom", type=int, required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument(
        "--pmtiles-url",
        default="",
        help="Public HTTPS URL of the .pmtiles file (no pmtiles:// prefix)",
    )
    ap.add_argument("--name", default="", help="Style name")
    ap.add_argument("--glyphs", default="", help="Glyphs URL template")
    ap.add_argument("--sprite", default="", help="Sprite URL prefix (no @2x)")
    args = ap.parse_args()
    url = args.pmtiles_url.strip() or f"{CDN}/dach-z{args.maxzoom}.pmtiles"
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    data = style_for(
        args.maxzoom,
        url,
        name=args.name.strip() or None,
        glyphs=args.glyphs.strip() or None,
        sprite=args.sprite.strip() or None,
    )
    if data["version"] != 8 or "protomaps" not in data["sources"] or not data.get("glyphs"):
        raise SystemExit("invalid style")
    out.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"STYLE_OK {out}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
