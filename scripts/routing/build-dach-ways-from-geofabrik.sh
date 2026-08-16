#!/usr/bin/env bash
# DACH ways overlay from Geofabrik *regional* extracts (not germany-latest, not planet).
#
#   bash scripts/routing/build-dach-ways-from-geofabrik.sh
#   bash scripts/routing/build-dach-ways-from-geofabrik.sh --tile-only
#   bash scripts/routing/build-dach-ways-from-geofabrik.sh --upload
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CACHE="${GEOFABRIK_CACHE:-$ROOT/data/routing/dist/_geofabrik}"
OUT="$ROOT/data/routing/dist/_basemap"
WORK="$OUT/_ways-work"
CFG="$ROOT/scripts/routing/osmium-export-bike.json"
SEQ="$OUT/dach-ways.geojsonseq"
PROGRESS="$OUT/dach-ways.geofabrik-progress.txt"
UA="AetherRide/dach-ways (https://aetherride.app)"
TILE_ONLY=0
DO_UPLOAD=0
for a in "$@"; do
  case "$a" in
    --tile-only) TILE_ONLY=1 ;;
    --upload) DO_UPLOAD=1 ;;
  esac
done

EXTRACTS=(
  europe/liechtenstein-latest.osm.pbf
  europe/germany/berlin-latest.osm.pbf
  europe/germany/hamburg-latest.osm.pbf
  europe/germany/bremen-latest.osm.pbf
  europe/germany/saarland-latest.osm.pbf
  europe/germany/schleswig-holstein-latest.osm.pbf
  europe/germany/mecklenburg-vorpommern-latest.osm.pbf
  europe/germany/sachsen-anhalt-latest.osm.pbf
  europe/germany/thueringen-latest.osm.pbf
  europe/germany/sachsen-latest.osm.pbf
  europe/germany/brandenburg-latest.osm.pbf
  europe/germany/rheinland-pfalz-latest.osm.pbf
  europe/germany/hessen-latest.osm.pbf
  europe/germany/niedersachsen-latest.osm.pbf
  europe/germany/nordrhein-westfalen-latest.osm.pbf
  europe/germany/baden-wuerttemberg-latest.osm.pbf
  europe/germany/bayern-latest.osm.pbf
  europe/switzerland-latest.osm.pbf
  europe/austria-latest.osm.pbf
)

disk_ok() {
  local avail
  avail="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')"
  if [[ "$avail" -lt 8 ]]; then
    echo "STOP_DISK avail=${avail}G" >&2
    exit 2
  fi
}

run_osmium() {
  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$CACHE:/cache" \
    -v "$WORK:/data" \
    -v "$CFG:/cfg.json:ro" \
    iboates/osmium:latest "$@"
}

remote_bytes() {
  local rel="$1"
  curl -sIL -A "$UA" "https://download.geofabrik.de/$rel" \
    | tr -d '\r' \
    | awk 'BEGIN{IGNORECASE=1} /^content-length:/{l=$2} END{print l+0}'
}

ARIA2="${ARIA2:-$ROOT/data/routing/dist/_tools/aria2c}"

download_extract() {
  local rel="$1"
  local dest="$CACHE/$(basename "$rel")"
  local want
  want="$(remote_bytes "$rel")"
  if [[ -f "$dest" ]]; then
    local bytes
    bytes="$(wc -c < "$dest")"
    if [[ "$want" -gt 0 && "$bytes" -eq "$want" ]]; then
      echo "==> cache hit $(basename "$rel") (${bytes} bytes)"
      return
    fi
    echo "==> incomplete $(basename "$rel") have=${bytes} want=${want} — resume"
  else
    echo "==> download $rel want=${want}"
  fi
  if [[ -x "$ARIA2" ]]; then
    "$ARIA2" -x 6 -s 6 -c --file-allocation=none --console-log-level=notice \
      --user-agent="$UA" \
      -d "$CACHE" -o "$(basename "$rel")" \
      "https://download.geofabrik.de/$rel"
  else
    curl -L --fail --retry 4 --retry-delay 4 -A "$UA" -C - \
      -o "$dest" "https://download.geofabrik.de/$rel"
  fi
}

mkdir -p "$CACHE" "$OUT" "$WORK"
touch "$PROGRESS"
disk_ok

if [[ "$TILE_ONLY" -eq 0 ]]; then
  echo "==> DACH ways from ${#EXTRACTS[@]} Geofabrik extracts (no germany-latest)"
  for rel in "${EXTRACTS[@]}"; do
    disk_ok
    name="$(basename "$rel" .osm.pbf)"
    if grep -qx "$name" "$PROGRESS"; then
      echo "==> skip done $name"
      continue
    fi
    download_extract "$rel"
    echo "==> osmium tags-filter $name"
    run_osmium tags-filter "/cache/${name}.osm.pbf" \
      w/highway=cycleway \
      w/mtb:scale \
      w/bicycle=designated \
      w/bicycle=yes \
      w/bicycle=permissive \
      -o "/data/${name}-bike.osm.pbf" --overwrite
    echo "==> osmium export $name"
    run_osmium export "/data/${name}-bike.osm.pbf" \
      -c /cfg.json -f geojsonseq --geometry-types=linestring \
      -o "/data/${name}-bike.geojsonseq" --overwrite
    echo "==> classify append $name"
    npx tsx "$ROOT/scripts/routing/build-dach-ways-overlay.ts" \
      --ingest-seq "$WORK/${name}-bike.geojsonseq"
    rm -f "$CACHE/${name}.osm.pbf" \
      "$WORK/${name}-bike.osm.pbf" \
      "$WORK/${name}-bike.geojsonseq"
    echo "$name" >> "$PROGRESS"
    echo "==> done $name seq=$(wc -c < "$SEQ") bytes"
  done
fi

echo "==> tippecanoe"
npx tsx "$ROOT/scripts/routing/build-dach-ways-overlay.ts" --tile
if [[ "$DO_UPLOAD" -eq 1 ]]; then
  npx tsx "$ROOT/scripts/routing/build-dach-ways-overlay.ts" --skip-fetch --upload
fi
echo "GEOFABRIK_WAYS_OK $SEQ"
