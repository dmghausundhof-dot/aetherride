#!/usr/bin/env python3
"""python3 scripts/routing/write-dach-style.test.py"""
from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "write_dach_style", ROOT / "write-dach-style.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)


def layer_ids(style: dict) -> list[str]:
    return [layer["id"] for layer in style["layers"]]


def test_hierarchy_and_pois() -> None:
    dach = mod.style_for(
        11,
        "https://cdn.example/dach-z11.pmtiles",
        german_names=True,
    )
    ids = layer_ids(dach)
    assert "roads-highway" in ids
    assert "roads-major" in ids
    assert "roads" in ids
    assert "pois" in ids
    assert "paths" not in ids
    assert "cycleways" not in ids
    places = next(layer for layer in dach["layers"] if layer["id"] == "places")
    assert "name:de" in json.dumps(places["layout"]["text-field"])
    pois = next(layer for layer in dach["layers"] if layer["id"] == "pois")
    kinds = json.dumps(pois["filter"])
    assert "peak" in kinds and "station" in kinds and "alpine_hut" in kinds
    assert "cafe" not in kinds
    hw = next(layer for layer in dach["layers"] if layer["id"] == "roads-highway")
    assert hw["paint"]["line-color"] == "#3a4a42"
    assert dach["metadata"]["aetherride:paths"] == "absent-at-z11"


def test_local_names_outside_dach() -> None:
    italy = mod.style_for(
        11,
        "https://cdn.example/italy-north-z11.pmtiles",
        name="AetherRide italy-north z0–11",
        german_names=False,
    )
    places = next(layer for layer in italy["layers"] if layer["id"] == "places")
    field = places["layout"]["text-field"]
    assert field == ["get", "name"]
    assert italy["metadata"]["aetherride:name-de"] is False


def test_paths_only_when_zoom_allows() -> None:
    hi = mod.style_for(14, "https://cdn.example/x.pmtiles", german_names=True)
    assert "paths" in layer_ids(hi)


def test_write_all_archives() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        written = mod.write_all(Path(tmp), maxzoom=11)
        assert len(written) == 9
        names = {p.name for p in written}
        for stem, _, german in mod.ARCHIVES:
            path = Path(tmp) / f"{stem}-z11-style.json"
            assert path.name in names
            data = json.loads(path.read_text(encoding="utf-8"))
            places = next(layer for layer in data["layers"] if layer["id"] == "places")
            field = json.dumps(places["layout"]["text-field"])
            if german:
                assert "name:de" in field
            else:
                assert "name:de" not in field


if __name__ == "__main__":
    test_hierarchy_and_pois()
    test_local_names_outside_dach()
    test_paths_only_when_zoom_allows()
    test_write_all_archives()
    print("write-dach-style.test.py ok")
