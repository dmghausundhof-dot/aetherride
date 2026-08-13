#!/usr/bin/env bash
# Build regional Valhalla tile extract + offline_graph from same OSM coverage.
# Requires: docker (gis-ops valhalla + iboates/osmium)
#
# Prefer Geofabrik PBF + osmium (GRAPH_SOURCE=geofabrik, default).
# Overpass is flaky on large DACH bboxes: GRAPH_SOURCE=overpass
#
# Usage:
#   ./scripts/routing/build-region-pack.sh data/routing/regions/schwarzwald-nord.json
#   SKIP_TILES=1 ./scripts/routing/build-region-pack.sh ...
#   GRAPH_SOURCE=overpass ./scripts/routing/build-region-pack.sh ...
#   # Graph-only wrapper (same as SKIP_TILES=1):
#   ./scripts/routing/build-graph-only-pack.sh data/routing/regions/rhein-neckar.json
#
# Full packs need Docker + time; do not commit large dist/ binaries without OK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGION_FILE="${1:-$ROOT/data/routing/regions/schwarzwald-nord.json}"
REGION_ID="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['id'])")"
OUT="$ROOT/data/routing/dist/$REGION_ID"
CUSTOM_FILES="${VALHALLA_CUSTOM_FILES:-$OUT/custom_files}"
mkdir -p "$OUT" "$CUSTOM_FILES"

echo "==> Region $REGION_ID → $OUT"

GRAPH_SOURCE="${GRAPH_SOURCE:-geofabrik}"
if [[ "$GRAPH_SOURCE" == "geofabrik" ]]; then
  echo "==> offline_graph via Geofabrik PBF (no Overpass)"
  "$ROOT/scripts/routing/prepare-pbf-geojson.sh" "$REGION_FILE"
  NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}" \
    node "$ROOT/scripts/routing/osm-to-offline-graph.mjs" "$REGION_FILE" \
    --geojson "$OUT/highways.geojson" --out "$OUT/offline_graph.json"
else
  echo "==> offline_graph (Overpass / OSM)"
  node "$ROOT/scripts/routing/osm-to-offline-graph.mjs" "$REGION_FILE" --out "$OUT/offline_graph.json"
fi

PBF_URL="$(python3 -c "import json;print(json.load(open('$REGION_FILE'))['osm']['geofabrik'])")"
BBOX="$(python3 -c "import json;b=json.load(open('$REGION_FILE'))['bbox'];print(f\"{b[0]},{b[1]},{b[2]},{b[3]}\")")"
# south,west,north,east for overpass
OVERPASS_BOX="$(python3 -c "import json;b=json.load(open('$REGION_FILE'))['bbox'];print(f\"{b[1]},{b[0]},{b[3]},{b[2]}\")")"
PBF_FULL="$CUSTOM_FILES/region-full.osm.pbf"
PBF_CLIP="$CUSTOM_FILES/region.osm.pbf"

if [[ "${SKIP_TILES:-}" == "1" ]]; then
  echo "==> SKIP_TILES=1 — writing manifest without Valhalla tiles"
else
  if [[ ! -f "$PBF_CLIP" ]]; then
    if [[ "${USE_GEOFABRIK:-}" == "1" ]]; then
      if [[ ! -f "$PBF_FULL" ]]; then
        echo "==> Download Geofabrik extract"
        curl -L --fail -o "$PBF_FULL" "$PBF_URL"
      fi
      # `command -v osmium` matches a bash function — use type -P for the real binary.
      HOST_OSMIUM="$(type -P osmium 2>/dev/null || true)"
      if [[ -n "$HOST_OSMIUM" ]]; then
        echo "==> Clip PBF to bbox $BBOX ($HOST_OSMIUM)"
        "$HOST_OSMIUM" extract -b "$BBOX" "$PBF_FULL" -o "$PBF_CLIP" --overwrite
      else
        echo "==> Clip PBF via docker iboates/osmium"
        docker pull iboates/osmium:latest
        # entrypoint is already `osmium`
        docker run --rm -u "$(id -u):$(id -g)" -v "$CUSTOM_FILES:/data" iboates/osmium:latest \
          extract -b "$BBOX" /data/$(basename "$PBF_FULL") -o /data/$(basename "$PBF_CLIP") --overwrite
      fi
    else
      echo "==> Overpass OSM XML for bbox → PBF (USE_GEOFABRIK=1 for Land extract)"
      curl -sS -m 180 -o "$CUSTOM_FILES/region.osm" -X POST 'https://overpass-api.de/api/interpreter' \
        --data-binary "[out:xml][timeout:120];(way[\"highway\"](${OVERPASS_BOX});>;);out body;"
      docker pull iboates/osmium:latest
      docker run --rm -v "$CUSTOM_FILES:/data" iboates/osmium:latest \
        cat /data/region.osm -o /data/region.osm.pbf --overwrite
    fi
  fi

  IMAGE="${VALHALLA_DOCKER_IMAGE:-ghcr.io/gis-ops/docker-valhalla/valhalla:latest}"
  echo "==> Valhalla tiles via Docker ($IMAGE)"
  docker pull "$IMAGE" || true
  # Image runs as uid 59999 (valhalla) — host mount must be world-writable.
  chmod a+rwx "$CUSTOM_FILES" 2>/dev/null || true
  docker run --rm --entrypoint /bin/bash \
    -v "$CUSTOM_FILES:/custom_files" \
    "$IMAGE" \
    -lc 'set -e
      ls /custom_files/*.pbf
      valhalla_build_config \
        --mjolnir-tile-dir /custom_files/valhalla_tiles \
        --mjolnir-tile-extract /custom_files/valhalla_tiles.tar \
        --mjolnir-timezone /custom_files/tz.sqlite \
        --mjolnir-admin /custom_files/admins.sqlite \
        > /custom_files/valhalla.json
      valhalla_build_tiles -c /custom_files/valhalla.json /custom_files/*.pbf
      valhalla_build_extract -c /custom_files/valhalla.json -v
    '

  if [[ -d "$CUSTOM_FILES/valhalla_tiles" ]]; then
    rm -rf "$OUT/tiles"
    cp -a "$CUSTOM_FILES/valhalla_tiles" "$OUT/tiles"
  fi
  if [[ -f "$CUSTOM_FILES/valhalla.json" ]]; then
    cp "$CUSTOM_FILES/valhalla.json" "$OUT/valhalla.json"
  fi
  if [[ -f "$CUSTOM_FILES/valhalla_tiles.tar" ]]; then
    cp "$CUSTOM_FILES/valhalla_tiles.tar" "$OUT/valhalla_tiles.tar"
  fi
fi

python3 - <<PY
import json, hashlib, time, os, subprocess, shutil
from pathlib import Path
out = Path("$OUT")
region = json.load(open("$REGION_FILE"))
cdn_base = os.environ.get("ROUTING_CDN_BASE", "").rstrip("/")
files = {}
for name in ["offline_graph.json", "valhalla.json", "valhalla_tiles.tar"]:
    p = out / name
    if p.is_file():
        digest = hashlib.sha256(p.read_bytes()).hexdigest()
        files[name] = {
            "bytes": p.stat().st_size,
            "sha256": digest,
            "sha256_16": digest[:16],
        }
tiles = out / "tiles"
if tiles.is_dir():
    files["tiles/"] = {"file_count": sum(1 for _ in tiles.rglob("*") if _.is_file())}

# Pack archive: prefer tar.zst when zstd available, always also tar.gz for mobile
pack_members = []
for name in ["manifest.json", "offline_graph.json", "valhalla.json", "valhalla_tiles.tar"]:
    if (out / name).is_file() or name == "manifest.json":
        pack_members.append(name)
# write preliminary manifest without pack hashes first
cdn = dict(region.get("cdn") or {})
if cdn_base:
    cdn["baseUrl"] = cdn_base
pack_name = cdn.get("pack") or f"{region['id']}.tar.zst"
cdn["pack"] = pack_name
cdn.setdefault("packGz", f"{region['id']}.tar.gz")

manifest = {
    "id": region["id"],
    "name": region["name"],
    "bbox": region["bbox"],
    "builtAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "engines": {
        "offline_graph": "offline_graph.json" in files,
        "valhalla_tiles": "tiles/" in files or "valhalla_tiles.tar" in files,
    },
    "files": files,
    "cdn": cdn,
}
(out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

def sha_entry(path: Path):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {"bytes": path.stat().st_size, "sha256": digest, "sha256_16": digest[:16]}

# Build tar.gz of pack contents (graph + config + optional tiles tree)
gz_path = out / cdn["packGz"]
tar_args = ["tar", "-czf", str(gz_path), "-C", str(out)]
for name in ["manifest.json", "offline_graph.json", "valhalla.json"]:
    if (out / name).is_file():
        tar_args.append(name)
if tiles.is_dir():
    tar_args.append("tiles")
if (out / "valhalla_tiles.tar").is_file():
    tar_args.append("valhalla_tiles.tar")
subprocess.check_call(tar_args)
files[cdn["packGz"]] = sha_entry(gz_path)

zst_path = out / pack_name
if shutil.which("zstd"):
    # recompress from tar stream
    raw_tar = out / f"{region['id']}.tar"
    tar_raw = ["tar", "-cf", str(raw_tar), "-C", str(out)]
    for name in ["manifest.json", "offline_graph.json", "valhalla.json"]:
        if (out / name).is_file():
            tar_raw.append(name)
    if tiles.is_dir():
        tar_raw.append("tiles")
    if (out / "valhalla_tiles.tar").is_file():
        tar_raw.append("valhalla_tiles.tar")
    subprocess.check_call(tar_raw)
    subprocess.check_call(["zstd", "-f", "-q", "-o", str(zst_path), str(raw_tar)])
    raw_tar.unlink(missing_ok=True)
    files[pack_name] = sha_entry(zst_path)
else:
    # No zstd: point pack at gzip archive so CDN clients still resolve
    cdn["pack"] = cdn["packGz"]
    pack_name = cdn["pack"]
    print("zstd not found — using tar.gz as cdn.pack", flush=True)

manifest["files"] = files
manifest["cdn"] = cdn
(out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
# refresh gzip so it includes final manifest with pack hashes
subprocess.check_call(tar_args)
files[cdn["packGz"]] = sha_entry(gz_path)
if (out / pack_name).is_file() and pack_name.endswith(".zst"):
    # rebuild zst with updated manifest
    raw_tar = out / f"{region['id']}.tar"
    tar_raw = ["tar", "-cf", str(raw_tar), "-C", str(out)]
    for name in ["manifest.json", "offline_graph.json", "valhalla.json"]:
        if (out / name).is_file():
            tar_raw.append(name)
    if tiles.is_dir():
        tar_raw.append("tiles")
    if (out / "valhalla_tiles.tar").is_file():
        tar_raw.append("valhalla_tiles.tar")
    subprocess.check_call(tar_raw)
    subprocess.check_call(["zstd", "-f", "-q", "-o", str(zst_path), str(raw_tar)])
    raw_tar.unlink(missing_ok=True)
    files[pack_name] = sha_entry(zst_path)

manifest["files"] = files
(out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
manifests = Path("$ROOT/data/routing/manifests")
manifests.mkdir(parents=True, exist_ok=True)
(manifests / f"{region['id']}.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))
PY

# Dev serve: copy small artifacts into public/offline/<id>/.
# public/offline is gitignored, but skip huge graphs so a local Vercel upload
# cannot ship tens of MB. Full binaries stay in gitignored dist/.
PUBLIC_OFFLINE="$ROOT/public/offline/$REGION_ID"
mkdir -p "$PUBLIC_OFFLINE"
MAX_PUBLIC_BYTES=$((1 * 1024 * 1024))
copy_public() {
  local src="$1"
  local dest="$2"
  local sz
  sz=$(wc -c < "$src")
  if [[ "$sz" -gt "$MAX_PUBLIC_BYTES" ]]; then
    echo "==> skip public copy $(basename "$src") ($sz bytes) — dist/ only"
    rm -f "$dest"
    return
  fi
  cp -f "$src" "$dest"
}
for f in offline_graph.json valhalla.json manifest.json; do
  if [[ -f "$OUT/$f" ]]; then
    copy_public "$OUT/$f" "$PUBLIC_OFFLINE/$f"
  fi
done
for f in "$OUT"/*.tar.gz "$OUT"/*.tar.zst; do
  [[ -f "$f" ]] && copy_public "$f" "$PUBLIC_OFFLINE/$(basename "$f")"
done

if [[ "${SKIP_OVERLAY:-}" != "1" ]]; then
  echo "==> bike overlay (PMTiles) — SKIP_OVERLAY=1 to skip"
  "$ROOT/scripts/routing/build-bike-overlay.sh" "$REGION_FILE" || echo "==> overlay build failed (non-fatal)" >&2
fi

echo "==> Done: $OUT (public mirror: $PUBLIC_OFFLINE)"
