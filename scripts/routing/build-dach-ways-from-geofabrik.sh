#!/usr/bin/env bash
# Thin wrapper — DACH ways via the shared sheet pipeline.
#   bash scripts/routing/build-dach-ways-from-geofabrik.sh [--tile-only] [--upload]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec bash "$ROOT/scripts/routing/build-ways-from-geofabrik.sh" --sheet dach "$@"
