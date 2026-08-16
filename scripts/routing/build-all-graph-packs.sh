#!/usr/bin/env bash
# Build graph-only offline packs for every DACH region stub.
#
# Does NOT build Valhalla tile extracts (hours + GB per region). Those stay
# SKIP_TILES=1 — mobile uses offline_graph Dijkstra until tiles exist.
#
# Usage:
#   ./scripts/routing/build-all-graph-packs.sh
#   ONLY=frankfurt-rhein-main ./scripts/routing/build-all-graph-packs.sh
#   AR_PACK_LIMIT=3 ./scripts/routing/build-all-graph-packs.sh
#   FORCE=1 ./scripts/routing/build-all-graph-packs.sh
#   KEEP_PBF=1 KEEP_INTERMEDIATE=1 ./scripts/routing/build-all-graph-packs.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export ROOT
export SKIP_TILES="${SKIP_TILES:-1}"
export SKIP_OVERLAY="${SKIP_OVERLAY:-1}"
export GRAPH_SOURCE="${GRAPH_SOURCE:-geofabrik}"
export FORCE="${FORCE:-0}"
export KEEP_PBF="${KEEP_PBF:-0}"
export KEEP_INTERMEDIATE="${KEEP_INTERMEDIATE:-0}"
export ONLY="${ONLY:-}"
export AR_PACK_LIMIT="${AR_PACK_LIMIT:-0}"
export GEOFABRIK_CACHE="${GEOFABRIK_CACHE:-$ROOT/data/routing/dist/_geofabrik}"
export BUILD_ALL_LOG="${BUILD_ALL_LOG:-$ROOT/data/routing/dist/_build-all-graphs.log}"
mkdir -p "$ROOT/data/routing/dist" "$GEOFABRIK_CACHE"

python3 - <<'PY'
import json, os, subprocess, sys, time
from collections import defaultdict
from pathlib import Path

root = Path(os.environ["ROOT"])
reg_dir = root / "data/routing/regions"
dist = root / "data/routing/dist"
cache = Path(os.environ["GEOFABRIK_CACHE"])
log_path = Path(os.environ["BUILD_ALL_LOG"])
only = os.environ.get("ONLY") or ""
only_set = {x.strip() for x in only.split(",") if x.strip()} if only else set()
force = os.environ.get("FORCE") == "1"
keep_pbf = os.environ.get("KEEP_PBF") == "1"
keep_intermediate = os.environ.get("KEEP_INTERMEDIATE") == "1"
limit = int(os.environ.get("AR_PACK_LIMIT") or "0")
builder = root / "scripts/routing/build-graph-only-pack.sh"

def log(msg: str) -> None:
    line = msg.rstrip() + "\n"
    sys.stdout.write(line)
    sys.stdout.flush()
    with log_path.open("a", encoding="utf-8") as f:
        f.write(line)

def pack_ready(rid: str) -> bool:
    out = dist / rid
    graph = out / "offline_graph.json"
    tar = out / f"{rid}.tar.gz"
    if not graph.is_file() or not tar.is_file():
        return False
    return graph.stat().st_size > 10_000

def cleanup(rid: str) -> None:
    if keep_intermediate:
        return
    out = dist / rid
    for name in ("custom_files", "highways.geojson", "bike-ways.geojsonseq"):
        p = out / name
        if p.is_dir():
            subprocess.run(["rm", "-rf", str(p)], check=False)
        elif p.is_file():
            p.unlink(missing_ok=True)

groups: dict[str, list[Path]] = defaultdict(list)
for p in sorted(reg_dir.glob("*.json")):
    data = json.loads(p.read_text(encoding="utf-8"))
    rid = data.get("id") or p.stem
    if only_set and rid not in only_set:
        continue
    url = ((data.get("osm") or {}).get("geofabrik") or "").strip()
    groups[url].append(p)

log(
    f"==== build-all-graph-packs SKIP_TILES={os.environ.get('SKIP_TILES')} "
    f"SKIP_OVERLAY={os.environ.get('SKIP_OVERLAY')} ===="
)

built = skipped = failed = attempted = 0
for url, files in sorted(groups.items(), key=lambda kv: (-len(kv[1]), kv[0])):
    label = Path(url).name if url else "(no-geofabrik)"
    log(f"==> group {len(files)} region(s)  {label}")
    for rf in files:
        data = json.loads(rf.read_text(encoding="utf-8"))
        rid = data["id"]
        if limit and attempted >= limit:
            log(f"==> AR_PACK_LIMIT={limit} reached")
            break
        if not force and pack_ready(rid):
            log(f"    skip {rid} (already ready)")
            skipped += 1
            continue
        attempted += 1
        log(f"    BUILD {rid}")
        with log_path.open("a", encoding="utf-8") as lf:
            proc = subprocess.run(
                ["bash", str(builder), str(rf)],
                cwd=str(root),
                stdout=lf,
                stderr=subprocess.STDOUT,
            )
        if proc.returncode == 0 and pack_ready(rid):
            cleanup(rid)
            tar = dist / rid / f"{rid}.tar.gz"
            size = f"{tar.stat().st_size / 1_000_000:.1f} MB" if tar.is_file() else "?"
            log(f"    OK {rid} ({size})")
            built += 1
        else:
            log(f"    FAIL {rid} (see {log_path})")
            failed += 1
        # Overpass endpoints rate-limit; pause between regions.
        if os.environ.get("GRAPH_SOURCE") == "overpass":
            time.sleep(2)
    else:
        if not keep_pbf and url:
            pbf = cache / Path(url).name
            if pbf.is_file():
                log(f"    drop PBF {pbf.name} ({pbf.stat().st_size / 1_000_000:.1f} MB)")
                pbf.unlink()
        continue
    break

log(f"==== done built={built} skipped={skipped} failed={failed} ====")
sys.exit(1 if failed else 0)
PY
