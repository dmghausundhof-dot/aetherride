#!/usr/bin/env bash
# After italy-ways CDN upload: build all 33 DACH envelope graphs (serialized downloads).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
LOG=data/routing/dist/_logs/envelope-after-it.log
mkdir -p data/routing/dist/_logs
echo "WAIT_IT $(date -Iseconds)" | tee "$LOG"
for i in $(seq 1 300); do
  if grep -q 'UPLOADED basemap/italy-ways\|GEOFABRIK_WAYS_OK' data/routing/dist/_basemap/_build-it-ways.log 2>/dev/null; then
    echo "IT_WAYS_OK $(date -Iseconds)" | tee -a "$LOG"
    break
  fi
  if grep -q '^IT_WAYS_END' data/routing/dist/_logs/chain-it-fr.log 2>/dev/null; then
    echo "IT_WAYS_END_LOG $(date -Iseconds)" | tee -a "$LOG"
    break
  fi
  sleep 60
done
export GEOFABRIK_CACHE="$ROOT/data/routing/dist/_geofabrik"
ARIA2="$ROOT/data/routing/dist/_tools/aria2c.bin"
for rel in europe/austria-latest.osm.pbf europe/switzerland-latest.osm.pbf; do
  name="$(basename "$rel")"
  if [[ -f "$GEOFABRIK_CACHE/$name" && ! -f "$GEOFABRIK_CACHE/$name.aria2" ]]; then
    echo "cache hit $name" | tee -a "$LOG"
    continue
  fi
  echo "DL $name" | tee -a "$LOG"
  "$ARIA2" -x 6 -s 6 -c --file-allocation=none \
    -d "$GEOFABRIK_CACHE" -o "$name" "https://download.geofabrik.de/$rel" >>"$LOG" 2>&1 || true
done
AR_PACK_LIMIT=33 bash scripts/routing/build-envelope-graphs.sh >>"$LOG" 2>&1
echo "ENV_DONE $(date -Iseconds)" | tee -a "$LOG"
FORCE=1 bash scripts/routing/publish-offline-packs.sh >>"$LOG" 2>&1 || true
echo "END $(date -Iseconds)" | tee -a "$LOG"
