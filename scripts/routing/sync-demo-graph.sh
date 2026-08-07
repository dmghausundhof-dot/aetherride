#!/usr/bin/env bash
# Copy a built offline_graph into the Flutter demo asset (single canonical copy in git).
# Usage:
#   ./scripts/routing/sync-demo-graph.sh
#   ./scripts/routing/sync-demo-graph.sh data/routing/dist/schwarzwald-nord/offline_graph.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="${1:-$ROOT/data/routing/dist/schwarzwald-nord/offline_graph.json}"
DST="$ROOT/mobile/assets/routing/offline_graph.json"

if [[ ! -f "$SRC" ]]; then
  echo "Source missing: $SRC" >&2
  echo "Build first: npm run routing:region:graph-only -- data/routing/regions/schwarzwald-nord.json" >&2
  exit 1
fi

mkdir -p "$(dirname "$DST")"
cp -f "$SRC" "$DST"
echo "Synced $(wc -c <"$DST") bytes → $DST"
