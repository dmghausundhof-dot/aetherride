#!/usr/bin/env bash
# Extract bike-relevant OSM ways from a region PBF → GeoJSON + PMTiles overlay.
#
# Does not re-download Geofabrik if region-full.osm.pbf exists.
# Does not rebuild Valhalla tiles.
#
# Usage:
#   ./scripts/routing/build-bike-overlay.sh data/routing/regions/rhein-neckar.json
#   ./scripts/routing/build-bike-overlay.sh   # defaults to rhein-neckar
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGION_FILE="${1:-$ROOT/data/routing/regions/rhein-neckar.json}"
if [[ ! -f "$REGION_FILE" ]]; then
  echo "Region JSON missing: $REGION_FILE" >&2
  exit 1
fi

REGION_ID="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['id'])")"
BBOX="$(python3 -c "import json;b=json.load(open('$REGION_FILE'))['bbox'];print(f\"{b[0]},{b[1]},{b[2]},{b[3]}\")")"
PBF_URL="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['osm']['geofabrik'])")"
OUT="$ROOT/data/routing/dist/$REGION_ID"
CUSTOM="${VALHALLA_CUSTOM_FILES:-$OUT/custom_files}"
mkdir -p "$CUSTOM" "$OUT"

PBF_FULL="$CUSTOM/region-full.osm.pbf"
PBF_CLIP="$CUSTOM/region.osm.pbf"
PBF_BIKE="$CUSTOM/bike-ways.osm.pbf"
GEOJSONSEQ="$OUT/bike-ways.geojsonseq"
OVERLAY_GEOJSON="$OUT/bike-overlay.geojson"
OVERLAY_PMTILES="$OUT/bike-overlay.pmtiles"
SAMPLE_GEOJSON="$ROOT/mobile/assets/routing/bike-overlay-sample.geojson"
CFG="$ROOT/scripts/routing/osmium-export-bike.json"

HOST_OSMIUM="$(type -P osmium 2>/dev/null || true)"

run_osmium() {
  if [[ -n "$HOST_OSMIUM" ]]; then
    "$HOST_OSMIUM" "$@"
    return
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "osmium not on PATH and docker not found" >&2
    exit 127
  fi
  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$CUSTOM:/data" \
    -v "$OUT:/out" \
    -v "$CFG:/cfg.json:ro" \
    iboates/osmium:latest "$@"
}

echo "==> Bike overlay for $REGION_ID (bbox $BBOX)"

if [[ ! -f "$PBF_FULL" ]]; then
  echo "==> Download Geofabrik (missing $PBF_FULL)"
  curl -L --fail --retry 3 -o "$PBF_FULL.part" "$PBF_URL"
  mv "$PBF_FULL.part" "$PBF_FULL"
else
  echo "==> using existing PBF $PBF_FULL ($(wc -c < "$PBF_FULL") bytes)"
fi

if [[ -n "$HOST_OSMIUM" ]]; then
  EXTRACT_IN="$PBF_FULL"
  EXTRACT_OUT="$PBF_CLIP"
  HW_IN="$PBF_CLIP"
  HW_OUT="$PBF_BIKE"
  EXPORT_IN="$PBF_BIKE"
  EXPORT_CFG="$CFG"
  EXPORT_OUT="$GEOJSONSEQ"
else
  echo "==> docker iboates/osmium:latest"
  EXTRACT_IN="/data/region-full.osm.pbf"
  EXTRACT_OUT="/data/region.osm.pbf"
  HW_IN="/data/region.osm.pbf"
  HW_OUT="/data/bike-ways.osm.pbf"
  EXPORT_IN="/data/bike-ways.osm.pbf"
  EXPORT_CFG="/cfg.json"
  EXPORT_OUT="/out/bike-ways.geojsonseq"
fi

if [[ ! -f "$PBF_CLIP" ]]; then
  echo "==> osmium extract bbox $BBOX"
  run_osmium extract -b "$BBOX" "$EXTRACT_IN" -o "$EXTRACT_OUT" --overwrite
else
  echo "==> skip extract (exists $PBF_CLIP)"
fi

if [[ ! -f "$GEOJSONSEQ" ]]; then
  echo "==> osmium tags-filter bike ways"
  run_osmium tags-filter "$HW_IN" \
    w/highway=path,track,cycleway,bridleway,living_street \
    w/bicycle=designated \
    w/mtb:scale \
    w/mtb:scale:imba \
    w/cycleway \
    -o "$HW_OUT" --overwrite

  echo "==> osmium export geojsonseq (linestrings only)"
  run_osmium export "$EXPORT_IN" -c "$EXPORT_CFG" -f geojsonseq \
    --geometry-types=linestring -o "$EXPORT_OUT" --overwrite
else
  echo "==> skip tags-filter/export (exists $GEOJSONSEQ)"
fi

echo "==> classify overlay"
npx tsx "$ROOT/scripts/routing/classify-bike-overlay.ts" \
  --in "$GEOJSONSEQ" \
  --out "$OVERLAY_GEOJSON" \
  --sample-out "$SAMPLE_GEOJSON" \
  --sample-bbox "8.68,49.40,8.72,49.43"

run_tippecanoe() {
  local in_json="$1"
  local out_pmtiles="$2"
  if type -P tippecanoe >/dev/null 2>&1; then
    tippecanoe -o "$out_pmtiles" --force \
      --layer=bike \
      --minimum-zoom=9 --maximum-zoom=14 \
      --drop-densest-as-needed \
      --simplification=10 \
      "$in_json"
    return
  fi
  if command -v docker >/dev/null 2>&1; then
    if ! docker image inspect aetherride-tippecanoe >/dev/null 2>&1; then
      echo "==> building local tippecanoe image"
      docker build -t aetherride-tippecanoe \
        -f "$ROOT/scripts/routing/tippecanoe.Dockerfile" \
        "$ROOT/scripts/routing"
    fi
    echo "==> docker aetherride-tippecanoe"
    docker run --rm \
      -u "$(id -u):$(id -g)" \
      -v "$OUT:/data" \
      aetherride-tippecanoe \
      -o /data/bike-overlay.pmtiles --force \
        --layer=bike \
        --minimum-zoom=9 --maximum-zoom=14 \
        --drop-densest-as-needed \
        --simplification=10 \
        /data/bike-overlay.geojson
    return
  fi
  echo "tippecanoe not found — GeoJSON overlay only (PMTiles skipped)" >&2
}

echo "==> tippecanoe PMTiles"
run_tippecanoe "$OVERLAY_GEOJSON" "$OVERLAY_PMTILES"

python3 - <<PY
import hashlib, json, os, time
from pathlib import Path

root = Path("$ROOT")
out = Path("$OUT")
region_file = Path("$REGION_FILE")
region = json.loads(region_file.read_text())
manifest_path = root / "data" / "routing" / "manifests" / f"{region['id']}.json"
dist_manifest = out / "manifest.json"
base = {}
if manifest_path.is_file():
    base = json.loads(manifest_path.read_text())
elif dist_manifest.is_file():
    base = json.loads(dist_manifest.read_text())

files = dict(base.get("files") or {})
engines = dict(base.get("engines") or {})

def sha_entry(path: Path):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {"bytes": path.stat().st_size, "sha256": digest, "sha256_16": digest[:16]}

for name in ["bike-overlay.geojson", "bike-overlay.pmtiles"]:
    p = out / name
    if p.is_file():
        files[name] = sha_entry(p)

engines["bike_overlay"] = (out / "bike-overlay.pmtiles").is_file() or (out / "bike-overlay.geojson").is_file()
cdn = dict(base.get("cdn") or region.get("cdn") or {})
manifest = {
    "id": region["id"],
    "name": region.get("name") or base.get("name"),
    "bbox": region.get("bbox") or base.get("bbox"),
    "builtAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "engines": engines,
    "files": files,
    "cdn": cdn,
    "overlay": {
        "layer": "bike",
        "pmtiles": "bike-overlay.pmtiles" if (out / "bike-overlay.pmtiles").is_file() else None,
        "geojson": "bike-overlay.geojson" if (out / "bike-overlay.geojson").is_file() else None,
        "sourceLayer": "bike",
        "property": "bike_class",
    },
}
text = json.dumps(manifest, indent=2) + "\n"
manifest_path.parent.mkdir(parents=True, exist_ok=True)
manifest_path.write_text(text)
dist_manifest.write_text(text)
print(json.dumps({"overlay": manifest["overlay"], "files": {k: files[k] for k in files if k.startswith("bike-overlay")}}, indent=2))
PY

# Include overlay in existing tar.gz if present (no graph rebuild).
if [[ -f "$OUT/offline_graph.json" ]]; then
  echo "==> refresh tar.gz with overlay"
  PACK_GZ="$OUT/${REGION_ID}.tar.gz"
  TAR_MEMBERS=(manifest.json offline_graph.json)
  [[ -f "$OUT/bike-overlay.geojson" ]] && TAR_MEMBERS+=(bike-overlay.geojson)
  [[ -f "$OUT/bike-overlay.pmtiles" ]] && TAR_MEMBERS+=(bike-overlay.pmtiles)
  [[ -f "$OUT/valhalla.json" ]] && TAR_MEMBERS+=(valhalla.json)
  [[ -f "$OUT/valhalla_tiles.tar" ]] && TAR_MEMBERS+=(valhalla_tiles.tar)
  tar -czf "$PACK_GZ" -C "$OUT" "${TAR_MEMBERS[@]}"
  if [[ -d "$OUT/tiles" ]]; then
    tar -rzf "$PACK_GZ" -C "$OUT" tiles 2>/dev/null || \
      tar -czf "$PACK_GZ" -C "$OUT" "${TAR_MEMBERS[@]}" tiles
  fi
  python3 - <<PY
import hashlib, json
from pathlib import Path
out = Path("$OUT")
gz = out / "${REGION_ID}.tar.gz"
manifest_paths = [out / "manifest.json", Path("$ROOT") / "data/routing/manifests/${REGION_ID}.json"]
if gz.is_file():
    digest = hashlib.sha256(gz.read_bytes()).hexdigest()
    entry = {"bytes": gz.stat().st_size, "sha256": digest, "sha256_16": digest[:16]}
    for mp in manifest_paths:
        m = json.loads(mp.read_text())
        m.setdefault("files", {})["${REGION_ID}.tar.gz"] = entry
        mp.write_text(json.dumps(m, indent=2) + "\n")
print("pack", gz, gz.stat().st_size if gz.is_file() else 0)
PY
  if command -v zstd >/dev/null 2>&1; then
    echo "==> refresh tar.zst"
    RAW_TAR="$OUT/${REGION_ID}.tar"
    tar -cf "$RAW_TAR" -C "$OUT" "${TAR_MEMBERS[@]}"
    zstd -f -q -o "$OUT/${REGION_ID}.tar.zst" "$RAW_TAR"
    rm -f "$RAW_TAR"
    python3 - <<PY
import hashlib, json
from pathlib import Path
out = Path("$OUT")
zst = out / "${REGION_ID}.tar.zst"
manifest_paths = [out / "manifest.json", Path("$ROOT") / "data/routing/manifests/${REGION_ID}.json"]
if zst.is_file():
    digest = hashlib.sha256(zst.read_bytes()).hexdigest()
    entry = {"bytes": zst.stat().st_size, "sha256": digest, "sha256_16": digest[:16]}
    for mp in manifest_paths:
        m = json.loads(mp.read_text())
        m.setdefault("files", {})["${REGION_ID}.tar.zst"] = entry
        mp.write_text(json.dumps(m, indent=2) + "\n")
print("zst", zst.stat().st_size if zst.is_file() else 0)
PY
  fi
fi

echo "==> Done overlay $OUT"
ls -lh "$OVERLAY_GEOJSON" "$OVERLAY_PMTILES" 2>/dev/null || true
