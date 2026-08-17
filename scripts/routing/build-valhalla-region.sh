#!/usr/bin/env bash
# Build Valhalla tiles for one registered region (Geofabrik regional extract).
# Never planet / france-latest / germany-latest.
#
#   bash scripts/routing/build-valhalla-region.sh nl-netherlands
#   bash scripts/routing/build-valhalla-region.sh schwarzwald-nord
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ID="${1:-}"
if [[ -z "$ID" ]]; then
  echo "usage: $0 <region-id>" >&2
  exit 1
fi
case "$ID" in
  *planet*|france-latest|germany-latest)
    echo "refusing banned extract id $ID" >&2
    exit 1
    ;;
esac

avail="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')"
if [[ "$avail" -lt 8 ]]; then
  echo "STOP_DISK avail=${avail}G" >&2
  exit 2
fi

REGION_FILE="$ROOT/data/routing/regions/${ID}.json"
if [[ ! -f "$REGION_FILE" ]]; then
  ID="$ID" npx tsx <<'TS'
import { writeFileSync, mkdirSync } from "fs";
import { VALHALLA_REGIONS } from "./src/lib/routing/valhallaRegions.ts";
const id = process.env.ID!;
const r = VALHALLA_REGIONS.find((x) => x.id === id);
if (!r) throw new Error("unknown region " + id);
mkdirSync("data/routing/regions", { recursive: true });
const osm = r.geofabrik
  ? { geofabrik: "https://download.geofabrik.de/europe/" + r.geofabrik }
  : {};
writeFileSync(
  `data/routing/regions/${id}.json`,
  JSON.stringify(
    {
      id: r.id,
      name: r.name,
      bbox: r.bbox,
      osm,
      cdn: { pack: `${r.id}.tar.gz` },
    },
    null,
    2
  ) + "\n"
);
console.log("wrote data/routing/regions/" + id + ".json");
TS
fi

export USE_GEOFABRIK=1
# build-region-pack builds graph + optional valhalla when SKIP_TILES unset
unset SKIP_TILES || true
bash "$ROOT/scripts/routing/build-region-pack.sh" "$ID"
echo "VALHALLA_REGION_OK $ID"
