#!/usr/bin/env bash
# Clip Geofabrik PBF to region bbox and export highway GeoJSON for the graph builder.
# Avoids Overpass (429/504 on large DACH bboxes).
#
# Usage:
#   ./scripts/routing/prepare-pbf-geojson.sh data/routing/regions/rhein-neckar.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGION_FILE="${1:?region json}"
REGION_ID="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['id'])")"
PBF_URL="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['osm']['geofabrik'])")"
BBOX="$(python3 -c "import json;b=json.load(open('$REGION_FILE'))['bbox'];print(f\"{b[0]},{b[1]},{b[2]},{b[3]}\")")"
OUT="$ROOT/data/routing/dist/$REGION_ID"
CUSTOM="${VALHALLA_CUSTOM_FILES:-$OUT/custom_files}"
mkdir -p "$CUSTOM" "$OUT"

PBF_FULL="$CUSTOM/region-full.osm.pbf"
PBF_CLIP="$CUSTOM/region.osm.pbf"
PBF_HW="$CUSTOM/highways.osm.pbf"
GEOJSON="$OUT/highways.geojson"
CFG="$ROOT/scripts/routing/osmium-export-highways.json"

# Detect the real binary BEFORE any wrapper exists.
# `command -v osmium` is true for a bash function of the same name — never use it
# after defining osmium(). `type -P` / `hash` only match PATH executables.
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
  # iboates/osmium:latest entrypoint is already `osmium`.
  # Mount custom_files + out dir; callers pass container paths.
  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$CUSTOM:/data" \
    -v "$OUT:/out" \
    -v "$CFG:/cfg.json:ro" \
    iboates/osmium:latest "$@"
}

echo "==> Geofabrik $PBF_URL"
if [[ ! -f "$PBF_FULL" ]]; then
  curl -L --fail --retry 3 -o "$PBF_FULL.part" "$PBF_URL"
  mv "$PBF_FULL.part" "$PBF_FULL"
else
  echo "==> using existing PBF $PBF_FULL ($(wc -c < "$PBF_FULL") bytes)"
fi

if [[ -n "$HOST_OSMIUM" ]]; then
  echo "==> host osmium: $HOST_OSMIUM"
  EXTRACT_IN="$PBF_FULL"
  EXTRACT_OUT="$PBF_CLIP"
  HW_IN="$PBF_CLIP"
  HW_OUT="$PBF_HW"
  EXPORT_IN="$PBF_HW"
  EXPORT_CFG="$CFG"
  EXPORT_OUT="$GEOJSON"
else
  echo "==> docker iboates/osmium:latest"
  EXTRACT_IN="/data/region-full.osm.pbf"
  EXTRACT_OUT="/data/region.osm.pbf"
  HW_IN="/data/region.osm.pbf"
  HW_OUT="/data/highways.osm.pbf"
  EXPORT_IN="/data/highways.osm.pbf"
  EXPORT_CFG="/cfg.json"
  EXPORT_OUT="/out/highways.geojson"
fi

if [[ ! -f "$PBF_CLIP" ]]; then
  echo "==> osmium extract bbox $BBOX"
  run_osmium extract -b "$BBOX" "$EXTRACT_IN" -o "$EXTRACT_OUT" --overwrite
else
  echo "==> skip extract (exists $PBF_CLIP)"
fi

if [[ ! -f "$GEOJSON" ]]; then
  echo "==> osmium tags-filter highways"
  run_osmium tags-filter "$HW_IN" \
    w/highway=path,track,cycleway,bridleway,footway,residential,tertiary,unclassified,service,living_street,secondary,primary \
    -o "$HW_OUT" --overwrite
  echo "==> osmium export geojson"
  run_osmium export "$EXPORT_IN" -c "$EXPORT_CFG" -f geojson -o "$EXPORT_OUT" --overwrite
else
  echo "==> skip tags-filter/export (exists $GEOJSON)"
fi

echo "==> GeoJSON $GEOJSON ($(wc -c < "$GEOJSON") bytes)"
