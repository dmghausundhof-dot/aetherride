#!/usr/bin/env bash
# Graph-only offline pack (no Valhalla Docker tiles).
#
# Builds `offline_graph.json` + pack manifest via build-region-pack.sh with
# SKIP_TILES=1. Suitable for CI / quick local packs without hour-long tile builds.
#
# Full packs (tiles + graph):
#   ./scripts/routing/build-region-pack.sh data/routing/regions/<id>.json
#   # or: USE_GEOFABRIK=1 ./scripts/routing/build-region-pack.sh …
#
# Graph-only (this wrapper):
#   ./scripts/routing/build-graph-only-pack.sh data/routing/regions/rhein-neckar.json
#   ./scripts/routing/build-graph-only-pack.sh   # defaults to rhein-neckar
#
# Do not commit large binaries under data/routing/dist/ without agreement.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGION_FILE="${1:-$ROOT/data/routing/regions/rhein-neckar.json}"

if [[ ! -f "$REGION_FILE" ]]; then
  echo "Region JSON missing: $REGION_FILE" >&2
  echo "Create one under data/routing/regions/ (see manifests/ + schwarzwald-nord.json)." >&2
  exit 1
fi

echo "==> Graph-only pack (SKIP_TILES=1) for $REGION_FILE"
export SKIP_TILES=1
exec "$ROOT/scripts/routing/build-region-pack.sh" "$REGION_FILE"
