#!/usr/bin/env bash
# Country / sheet ways overlay from Geofabrik *regional* extracts.
# Never germany-latest, france-latest, or planet.
#
#   bash scripts/routing/build-ways-from-geofabrik.sh --sheet nl
#   bash scripts/routing/build-ways-from-geofabrik.sh --sheet be --upload
#   bash scripts/routing/build-ways-from-geofabrik.sh --sheet fr --tile-only
#   bash scripts/routing/build-dach-ways-from-geofabrik.sh  # thin wrapper → --sheet dach
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CACHE="${GEOFABRIK_CACHE:-$ROOT/data/routing/dist/_geofabrik}"
OUT="$ROOT/data/routing/dist/_basemap"
WORK="$OUT/_ways-work"
CFG="$ROOT/scripts/routing/osmium-export-bike.json"
SHEETS_JSON="$ROOT/scripts/routing/ways-sheets.json"
UA="AetherRide/ways (https://aetherride.app)"
SHEET=""
TILE_ONLY=0
DO_UPLOAD=0
for a in "$@"; do
  case "$a" in
    --sheet) SHEET="" ;; # filled below
    --tile-only) TILE_ONLY=1 ;;
    --upload) DO_UPLOAD=1 ;;
  esac
done
# parse --sheet VALUE
prev=""
for a in "$@"; do
  if [[ "$prev" == "--sheet" ]]; then SHEET="$a"; fi
  prev="$a"
done
if [[ -z "$SHEET" ]]; then
  echo "usage: $0 --sheet nl|be|dach|fr|it|uk-south [--tile-only] [--upload]" >&2
  exit 1
fi

# Refuse banned extracts
case "$SHEET" in
  *planet*|france-latest|germany-latest)
    echo "refusing planet / france-latest / germany-latest" >&2
    exit 1
    ;;
esac

SHEET_META="$(
  SHEET="$SHEET" SHEETS_JSON="$SHEETS_JSON" python3 - <<'PY'
import json, os, sys
sheets = json.load(open(os.environ["SHEETS_JSON"]))["sheets"]
sheet = os.environ["SHEET"]
hit = next((s for s in sheets if s["id"] == sheet), None)
if not hit:
    sys.stderr.write(f"unknown sheet {sheet}\n")
    sys.exit(1)
print(hit["file"])
print(hit["name"])
print(",".join(map(str, hit["bbox"])))
print("\n".join(hit["extracts"]))
PY
)"
FILE="$(echo "$SHEET_META" | sed -n '1p')"
NAME="$(echo "$SHEET_META" | sed -n '2p')"
BBOX="$(echo "$SHEET_META" | sed -n '3p')"
mapfile -t EXTRACTS < <(echo "$SHEET_META" | tail -n +4)

SEQ="$OUT/${FILE}.geojsonseq"
PROGRESS="$OUT/${FILE}.geofabrik-progress.txt"

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
  # Last Content-Length after redirects (Geofabrik 302 → dated file).
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
  echo "==> $SHEET ways ($NAME) from ${#EXTRACTS[@]} Geofabrik extracts (no planet/france-latest)"
  for rel in "${EXTRACTS[@]}"; do
    if [[ "$rel" == *france-latest* || "$rel" == *germany-latest* || "$rel" == *planet* ]]; then
      echo "refusing banned extract $rel" >&2
      exit 1
    fi
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
    npx tsx "$ROOT/scripts/routing/build-ways-overlay.ts" \
      --sheet "$SHEET" \
      --ingest-seq "$WORK/${name}-bike.geojsonseq"
    rm -f "$WORK/${name}-bike.osm.pbf" "$WORK/${name}-bike.geojsonseq"
    avail="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')"
    if [[ "${KEEP_EXTRACTS:-1}" != "1" || "$avail" -lt 20 ]]; then
      rm -f "$CACHE/${name}.osm.pbf"
    fi
    echo "$name" >> "$PROGRESS"
    echo "==> done $name seq=$(wc -c < "$SEQ") bytes"
  done
fi

echo "==> tippecanoe $FILE"
npx tsx "$ROOT/scripts/routing/build-ways-overlay.ts" --sheet "$SHEET" --tile
if [[ "$DO_UPLOAD" -eq 1 ]]; then
  npx tsx "$ROOT/scripts/routing/build-ways-overlay.ts" --sheet "$SHEET" --skip-fetch --upload
fi
echo "GEOFABRIK_WAYS_OK $SEQ"
