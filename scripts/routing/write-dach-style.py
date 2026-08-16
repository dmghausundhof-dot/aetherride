#!/usr/bin/env python3
"""Write a MapLibre style JSON for a regional PMTiles extract (native needs JSON, not raw .pmtiles)."""
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

# Mint / Hof greys — not a rainbow. Darker = higher in the road hierarchy.
COLOR_HIGHWAY = "#3a4a42"
COLOR_MAJOR = "#5c6e66"
COLOR_ROAD = "#8a9a92"
COLOR_PLACE = "#2c3a32"
COLOR_HALO = "#f4f7f4"

POI_KINDS = [
    "peak",
    "volcano",
    "station",
    "alpine_hut",
    "wilderness_hut",
    "shelter",
]

ARCHIVES: tuple[tuple[str, str, bool], ...] = (
    ("dach", "AetherRide DACH z0–{z}", True),
    ("france-west", "AetherRide france-west z0–{z}", False),
    ("alps-south", "AetherRide alps-south z0–{z}", False),
    ("benelux", "AetherRide benelux z0–{z}", False),
    ("italy-north", "AetherRide italy-north z0–{z}", False),
    ("italy-center", "AetherRide italy-center z0–{z}", False),
    ("italy-south", "AetherRide italy-south z0–{z}", False),
    ("catalonia-pyrenees", "AetherRide catalonia-pyrenees z0–{z}", False),
    ("uk-south", "AetherRide uk-south z0–{z}", False),
)


def _name_field(*, german_names: bool) -> list:
    if german_names:
        return ["coalesce", ["get", "name:de"], ["get", "name"]]
    return ["get", "name"]


def _zoom_width(z: int, lo: float, hi: float) -> list:
    return ["interpolate", ["linear"], ["zoom"], 6, lo, 10, (lo + hi) / 2, z, hi]


def style_for(
    maxzoom: int,
    pmtiles_url: str,
    *,
    name: str | None = None,
    glyphs: str | None = None,
    sprite: str | None = None,
    german_names: bool = True,
) -> dict:
    z = max(0, int(maxzoom))
    label = name or f"AetherRide DACH z0–{z}"
    names = _name_field(german_names=german_names)
    include_paths = z >= 12
    layers: list[dict] = [
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
            "filter": [
                "all",
                ["!=", ["get", "kind"], "highway"],
                ["!=", ["get", "kind"], "major_road"],
                ["!=", ["get", "kind"], "path"],
            ],
            "paint": {
                "line-color": COLOR_ROAD,
                "line-width": _zoom_width(z, 0.25, 1.15),
            },
        },
        {
            "id": "roads-major",
            "type": "line",
            "source": "protomaps",
            "source-layer": "roads",
            "filter": ["==", ["get", "kind"], "major_road"],
            "paint": {
                "line-color": COLOR_MAJOR,
                "line-width": _zoom_width(z, 0.45, 1.85),
            },
        },
        {
            "id": "roads-highway",
            "type": "line",
            "source": "protomaps",
            "source-layer": "roads",
            "filter": ["==", ["get", "kind"], "highway"],
            "paint": {
                "line-color": COLOR_HIGHWAY,
                "line-width": _zoom_width(z, 0.7, 2.45),
            },
        },
    ]
    if include_paths:
        layers.append(
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
            }
        )
    layers.extend(
        [
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
                "id": "pois",
                "type": "symbol",
                "source": "protomaps",
                "source-layer": "pois",
                "minzoom": min(8, z) if z else 0,
                "filter": ["in", ["get", "kind"], ["literal", POI_KINDS]],
                "layout": {
                    "text-field": names,
                    "text-font": ["Noto Sans Regular"],
                    "text-size": 11,
                    "text-max-width": 8,
                    "text-optional": True,
                    "text-padding": 2,
                },
                "paint": {
                    "text-color": COLOR_PLACE,
                    "text-halo-color": COLOR_HALO,
                    "text-halo-width": 1.1,
                },
            },
            {
                "id": "places",
                "type": "symbol",
                "source": "protomaps",
                "source-layer": "places",
                "minzoom": 5,
                "layout": {
                    "text-field": names,
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
                    "text-color": COLOR_PLACE,
                    "text-halo-color": COLOR_HALO,
                    "text-halo-width": 1.2,
                },
            },
        ]
    )
    return {
        "version": 8,
        "name": label,
        "metadata": {
            "aetherride:overview": True,
            "aetherride:paths": "styled" if include_paths else "absent-at-z11",
            "aetherride:name-de": german_names,
        },
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
        "layers": layers,
    }


def write_style(path: Path, data: dict) -> None:
    if data["version"] != 8 or "protomaps" not in data["sources"] or not data.get("glyphs"):
        raise SystemExit("invalid style")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def write_all(out_dir: Path, *, maxzoom: int = 11) -> list[Path]:
    written: list[Path] = []
    for stem, title, german in ARCHIVES:
        z = maxzoom
        data = style_for(
            z,
            f"{CDN}/{stem}-z{z}.pmtiles",
            name=title.format(z=z),
            german_names=german,
        )
        out = out_dir / f"{stem}-z{z}-style.json"
        write_style(out, data)
        written.append(out)
        print(f"STYLE_OK {out}", flush=True)
    return written


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--maxzoom", type=int, default=11)
    ap.add_argument("--out", default="", help="Single style JSON path")
    ap.add_argument(
        "--pmtiles-url",
        default="",
        help="Public HTTPS URL of the .pmtiles file (no pmtiles:// prefix)",
    )
    ap.add_argument("--name", default="", help="Style name")
    ap.add_argument("--glyphs", default="", help="Glyphs URL template")
    ap.add_argument("--sprite", default="", help="Sprite URL prefix (no @2x)")
    ap.add_argument(
        "--german-names",
        action="store_true",
        help="Prefer name:de then name (DACH only)",
    )
    ap.add_argument(
        "--all",
        action="store_true",
        help="Write all online archive styles into --out-dir",
    )
    ap.add_argument(
        "--out-dir",
        default="",
        help="Directory for --all (default: data/routing/basemap-styles)",
    )
    args = ap.parse_args()
    root = Path(__file__).resolve().parents[2]
    if args.all:
        out_dir = Path(args.out_dir) if args.out_dir.strip() else root / "data/routing/basemap-styles"
        write_all(out_dir, maxzoom=args.maxzoom)
        return 0
    if not args.out.strip():
        raise SystemExit("--out or --all required")
    url = args.pmtiles_url.strip() or f"{CDN}/dach-z{args.maxzoom}.pmtiles"
    data = style_for(
        args.maxzoom,
        url,
        name=args.name.strip() or None,
        glyphs=args.glyphs.strip() or None,
        sprite=args.sprite.strip() or None,
        german_names=args.german_names,
    )
    write_style(Path(args.out), data)
    print(f"STYLE_OK {args.out}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
