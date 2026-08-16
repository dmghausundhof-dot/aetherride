#!/usr/bin/env bash
# Cut a vector basemap from the Protomaps daily planet (range requests, no planet download).
#
#   bash scripts/routing/extract-dach-basemap.sh
#   MAXZOOM=12 bash scripts/routing/extract-dach-basemap.sh
#   NAME=france-west BBOX=-5.3,42.3,5.85,51.1 bash scripts/routing/extract-dach-basemap.sh
#   NAME=alps-south BBOX=5.55,43.40,11.60,45.90 bash scripts/routing/extract-dach-basemap.sh
#   NAME=benelux BBOX=2.40,49.40,7.25,53.75 bash scripts/routing/extract-dach-basemap.sh
#   NAME=italy-north BBOX=11.50,43.50,14.10,46.15 bash scripts/routing/extract-dach-basemap.sh
#   NAME=catalonia-pyrenees BBOX=-2.20,41.15,3.35,43.55 bash scripts/routing/extract-dach-basemap.sh
#   NAME=uk-south BBOX=-1.50,50.50,1.80,52.50 bash scripts/routing/extract-dach-basemap.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="${PMTILES_BIN:-$ROOT/data/routing/dist/_tools/pmtiles}"
OUT_DIR="$ROOT/data/routing/dist/_basemap"
# z11 DACH ≈ 515 MB, france-west ≈ 294 MB, alps-south ≈ 66 MB.
# Pro-Plan: TUS-Upload (Standard-PUT bleibt ~50 MB).
MAXZOOM="${MAXZOOM:-11}"
NAME="${NAME:-dach}"
# west,south,east,north — DACH + etwas Rand
BBOX="${BBOX:-5.8,45.75,17.25,55.15}"
PLANET="${PLANET_URL:-https://build.protomaps.com/20260816.pmtiles}"
OUT="$OUT_DIR/${NAME}-z${MAXZOOM}.pmtiles"

if [[ ! -x "$TOOLS" ]]; then
  echo "pmtiles CLI fehlt: $TOOLS" >&2
  exit 127
fi
mkdir -p "$OUT_DIR"
echo "==> extract $NAME z0-$MAXZOOM from $PLANET"
echo "    bbox=$BBOX"
echo "    out=$OUT"
"$TOOLS" extract "$PLANET" "$OUT" \
  --bbox="$BBOX" \
  --maxzoom="$MAXZOOM" \
  --download-threads="${THREADS:-8}"
ls -lh "$OUT"
STYLE_NAME="AetherRide ${NAME} z0–${MAXZOOM}"
GERMAN_NAMES=()
if [[ "$NAME" == "dach" ]]; then
  GERMAN_NAMES=(--german-names)
fi
python3 "$ROOT/scripts/routing/write-dach-style.py" \
  --maxzoom="$MAXZOOM" \
  --name="$STYLE_NAME" \
  "${GERMAN_NAMES[@]}" \
  --pmtiles-url="${ROUTING_CDN_BASE:-https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs}/basemap/${NAME}-z${MAXZOOM}.pmtiles" \
  --out="$OUT_DIR/${NAME}-z${MAXZOOM}-style.json"
echo "EXTRACT_OK $OUT"
