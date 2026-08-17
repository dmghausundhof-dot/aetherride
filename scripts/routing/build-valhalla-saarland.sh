#!/usr/bin/env bash
# Build Valhalla tiles for de-saarland (small DE Land) from cached Geofabrik PBF.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
LOG=data/routing/dist/_logs/valhalla-saarland.log
REGION=data/routing/regions/de-saarland.json
OUT=data/routing/dist/de-saarland
CUSTOM=$OUT/custom_files
mkdir -p "$CUSTOM" data/routing/dist/_logs
echo "START $(date -Iseconds)" | tee "$LOG"

if [[ ! -f "$CUSTOM/region.osm.pbf" ]]; then
  if [[ -f data/routing/dist/_geofabrik/saarland-latest.osm.pbf ]]; then
    BBOX="$(python3 -c "import json;b=json.load(open('$REGION'))['bbox'];print(f'{b[0]},{b[1]},{b[2]},{b[3]}')")"
    docker run --rm -u "$(id -u):$(id -g)" \
      -v "$ROOT/data/routing/dist/_geofabrik:/cache:ro" \
      -v "$ROOT/data/routing/dist/de-saarland/custom_files:/data" \
      iboates/osmium:latest extract -b "$BBOX" /cache/saarland-latest.osm.pbf \
      -o /data/region.osm.pbf --overwrite >>"$LOG" 2>&1
  else
    echo "missing saarland PBF" | tee -a "$LOG"
    exit 1
  fi
fi
ls -lh "$CUSTOM" | tee -a "$LOG"
IMAGE=ghcr.io/gis-ops/docker-valhalla/valhalla:latest
chmod a+rwx "$CUSTOM" 2>/dev/null || true
docker run --rm --entrypoint /bin/bash \
  -v "$ROOT/data/routing/dist/de-saarland/custom_files:/custom_files" \
  "$IMAGE" \
  -lc 'set -e
    ls /custom_files/*.pbf
    valhalla_build_config \
      --mjolnir-tile-dir /custom_files/valhalla_tiles \
      --mjolnir-tile-extract /custom_files/valhalla_tiles.tar \
      --mjolnir-timezone /custom_files/tz.sqlite \
      --mjolnir-admin /custom_files/admins.sqlite \
      > /custom_files/valhalla.json
    valhalla_build_tiles -c /custom_files/valhalla.json /custom_files/*.pbf
    valhalla_build_extract -c /custom_files/valhalla.json -v
  ' >>"$LOG" 2>&1
[[ -f $CUSTOM/valhalla_tiles.tar ]] && cp -f "$CUSTOM/valhalla_tiles.tar" "$OUT/valhalla_tiles.tar"
[[ -f $CUSTOM/valhalla.json ]] && cp -f "$CUSTOM/valhalla.json" "$OUT/valhalla.json"
ONLY=de-saarland FORCE=1 bash scripts/routing/publish-offline-packs.sh >>"$LOG" 2>&1 || true
echo "END $(date -Iseconds) tar=$(stat -c%s $OUT/valhalla_tiles.tar 2>/dev/null || echo 0)" | tee -a "$LOG"
