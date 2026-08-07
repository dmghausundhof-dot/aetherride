#!/usr/bin/env bash
# Build regional Valhalla tile extract + package with offline_graph from same OSM coverage.
# Requires: docker (gis-ops/valhalla or ghcr.io/gis-ops/docker-valhalla/valhalla)
#
# Usage:
#   ./scripts/routing/build-region-pack.sh data/routing/regions/schwarzwald-nord.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGION_FILE="${1:-$ROOT/data/routing/regions/schwarzwald-nord.json}"
REGION_ID="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['id'])")"
OUT="$ROOT/data/routing/dist/$REGION_ID"
CUSTOM_FILES="${VALHALLA_CUSTOM_FILES:-$OUT/custom_files}"
mkdir -p "$OUT" "$CUSTOM_FILES"

echo "==> Region $REGION_ID → $OUT"

# 1) offline_graph from Overpass (same bbox as region)
echo "==> offline_graph (Overpass / OSM)"
node "$ROOT/scripts/routing/osm-to-offline-graph.mjs" "$REGION_FILE" --out "$OUT/offline_graph.json"

# 2) Optional: clip Geofabrik PBF to bbox with osmium (if available)
PBF_URL="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['osm']['geofabrik'])")"
BBOX="$(python3 -c "import json;b=json.load(open('$REGION_FILE'))['bbox'];print(f\"{b[0]},{b[1]},{b[2]},{b[3]}\")")"
PBF_FULL="$CUSTOM_FILES/region-full.osm.pbf"
PBF_CLIP="$CUSTOM_FILES/region.osm.pbf"

if [[ "${SKIP_TILES:-}" == "1" ]]; then
  echo "==> SKIP_TILES=1 — writing manifest without Valhalla tiles"
else
  if [[ ! -f "$PBF_CLIP" ]]; then
    if [[ ! -f "$PBF_FULL" ]]; then
      echo "==> Download Geofabrik extract"
      curl -L --fail -o "$PBF_FULL" "$PBF_URL"
    fi
    if command -v osmium >/dev/null 2>&1; then
      echo "==> Clip PBF to bbox $BBOX"
      osmium extract -b "$BBOX" "$PBF_FULL" -o "$PBF_CLIP" --overwrite
    else
      echo "WARN: osmium not found — using full extract (slow/large). Install osmium-tool or set SKIP_TILES=1"
      ln -sfn "$(basename "$PBF_FULL")" "$PBF_CLIP" 2>/dev/null || cp "$PBF_FULL" "$PBF_CLIP"
    fi
  fi

  IMAGE="${VALHALLA_DOCKER_IMAGE:-ghcr.io/gis-ops/docker-valhalla/valhalla:latest}"
  echo "==> Valhalla tiles via Docker ($IMAGE)"
  docker pull "$IMAGE" || true
  # gis-ops image builds tiles from /custom_files/*.pbf into /custom_files/valhalla_tiles
  docker run --rm \
    -e tile_urls="" \
    -e use_tiles_ignore_pbf=False \
    -e build_elevation=False \
    -e build_admins=False \
    -e build_time_zones=False \
    -e serve_tiles=False \
    -v "$CUSTOM_FILES:/custom_files" \
    "$IMAGE" \
    /bin/bash -c 'ls /custom_files/*.pbf >/dev/null && valhalla_build_config --mjolnir-tile-dir /custom_files/valhalla_tiles --mjolnir-tile-extract /custom_files/valhalla_tiles.tar --mjolnir-timezone /custom_files/tz.sqlite --mjolnir-admin /custom_files/admins.sqlite > /custom_files/valhalla.json && valhalla_build_tiles -c /custom_files/valhalla.json /custom_files/*.pbf && valhalla_build_extract -c /custom_files/valhalla.json -v || true'

  if [[ -d "$CUSTOM_FILES/valhalla_tiles" ]]; then
    rm -rf "$OUT/tiles"
    cp -a "$CUSTOM_FILES/valhalla_tiles" "$OUT/tiles"
  fi
  if [[ -f "$CUSTOM_FILES/valhalla.json" ]]; then
    cp "$CUSTOM_FILES/valhalla.json" "$OUT/valhalla.json"
  fi
  if [[ -f "$CUSTOM_FILES/valhalla_tiles.tar" ]]; then
    cp "$CUSTOM_FILES/valhalla_tiles.tar" "$OUT/valhalla_tiles.tar"
  fi
fi

# 3) Manifest for app / CDN
python3 - <<PY
import json, hashlib, os, time
from pathlib import Path
out = Path("$OUT")
region = json.load(open("$REGION_FILE"))
files = {}
for name in ["offline_graph.json", "valhalla.json", "valhalla_tiles.tar"]:
    p = out / name
    if p.is_file():
        h = hashlib.sha256(p.read_bytes()).hexdigest()[:16]
        files[name] = {"bytes": p.stat().st_size, "sha256_16": h}
tiles = out / "tiles"
if tiles.is_dir():
    n = sum(1 for _ in tiles.rglob("*") if _.is_file())
    files["tiles/"] = {"file_count": n}
manifest = {
    "id": region["id"],
    "name": region["name"],
    "bbox": region["bbox"],
    "builtAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "engines": {
        "offline_graph": "offline_graph.json" in files,
        "valhalla_tiles": "tiles/" in files or "valhalla_tiles.tar" in files,
    },
    "files": files,
    "cdn": region.get("cdn") or {},
}
(out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))
PY

echo "==> Done: $OUT"
