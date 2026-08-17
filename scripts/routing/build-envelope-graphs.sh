#!/usr/bin/env bash
# Build offline graphs for DACH envelope stubs from regional Geofabrik extracts.
# Never germany-latest / planet. Respects AR_PACK_LIMIT and disk gates.
#
#   AR_PACK_LIMIT=3 bash scripts/routing/build-envelope-graphs.sh
#   ONLY=de-bayern,de-nrw bash scripts/routing/build-envelope-graphs.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

ENVELOPES=(
  de-schleswig-holstein de-niedersachsen de-mecklenburg-vorpommern
  de-brandenburg de-sachsen-anhalt de-sachsen de-thueringen de-hessen
  de-nrw de-rlp de-saarland de-baden-wuerttemberg de-bayern
  at-vorarlberg at-tirol at-salzburg at-oberoesterreich at-niederoesterreich
  at-steiermark at-kaernten at-burgenland
  ch-genfersee ch-jura ch-mittelland ch-nordwest ch-zuerichsee
  ch-ostschweiz ch-zentralschweiz ch-tessin ch-graubuenden ch-wallis
  ch-berner-oberland li-liechtenstein
)

if [[ -n "${ONLY:-}" ]]; then
  IFS=',' read -ra ENVELOPES <<< "$ONLY"
fi

LIMIT="${AR_PACK_LIMIT:-0}"
n=0
for id in "${ENVELOPES[@]}"; do
  avail="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')"
  if [[ "$avail" -lt 8 ]]; then
    echo "STOP_DISK avail=${avail}G" >&2
    exit 2
  fi
  if [[ "$LIMIT" -gt 0 && "$n" -ge "$LIMIT" ]]; then
    echo "AR_PACK_LIMIT=$LIMIT reached"
    break
  fi
  if [[ ! -f "data/routing/regions/${id}.json" ]]; then
    echo "skip missing region $id"
    continue
  fi
  region_json="data/routing/regions/${id}.json"
  if [[ ! -f "$region_json" ]]; then
    echo "skip missing region file $region_json"
    continue
  fi
  echo "==> envelope graph $id"
  SKIP_TILES=1 SKIP_OVERLAY=1 USE_GEOFABRIK=1 GRAPH_SOURCE=geofabrik \
    bash scripts/routing/build-region-pack.sh "$region_json" || {
      echo "FAIL $id — continue"
      continue
    }
  n=$((n + 1))
done

if [[ "${PUBLISH:-0}" == "1" ]]; then
  bash scripts/routing/publish-offline-packs.sh
fi
echo "ENVELOPE_GRAPHS_DONE count=$n"
