#!/usr/bin/env bash
# Upload built graph packs to Supabase Storage (public bucket offline-packs).
#
#   bash scripts/routing/publish-offline-packs.sh
#   ONLY=zuerich bash scripts/routing/publish-offline-packs.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIST="$ROOT/data/routing/dist"
MANIFESTS="$ROOT/data/routing/manifests"
BUCKET="offline-packs"
CDN_ROOT="${ROUTING_CDN_BASE:-https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/${BUCKET}}"
CDN_ROOT="${CDN_ROOT%/}"
ONLY="${ONLY:-}"
FORCE="${FORCE:-0}"

cd "$ROOT"
if [[ ! -f supabase/.temp/project-ref ]]; then
  supabase link --project-ref krmgatsugplouzrhhozn --yes
fi

python3 - <<'PY' "$DIST" "$MANIFESTS" "$CDN_ROOT" "$ONLY" "$ROOT" "$FORCE"
import http.client, json, sys, urllib.parse, urllib.request
from pathlib import Path

dist = Path(sys.argv[1])
man_dir = Path(sys.argv[2])
cdn_root = sys.argv[3].rstrip("/")
only = sys.argv[4]
root = Path(sys.argv[5])
force = sys.argv[6] == "1"
bucket = "offline-packs"

def load_env(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if not path.is_file():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env

env = load_env(root / ".env.local")
supabase_url = (env.get("NEXT_PUBLIC_SUPABASE_URL") or "").rstrip("/")
service_key = env.get("SUPABASE_SERVICE_ROLE_KEY") or ""
if not supabase_url or not service_key:
    raise SystemExit("missing SUPABASE url or service role")

def ready(rid: str) -> Path | None:
    tar = dist / rid / f"{rid}.tar.gz"
    graph = dist / rid / "offline_graph.json"
    man = dist / rid / "manifest.json"
    if tar.is_file() and graph.is_file() and graph.stat().st_size > 10_000 and man.is_file():
        return tar
    return None

def load_remote_catalog() -> dict[str, int]:
    url = f"{cdn_root}/catalog.json"
    try:
        with urllib.request.urlopen(url, timeout=20) as res:
            data = json.loads(res.read().decode("utf-8"))
        out = {}
        for p in data.get("packs") or []:
            rid = p.get("id")
            if rid:
                out[rid] = int(p.get("bytes") or 0)
        return out
    except Exception:
        return {}

def remote_object_size(object_path: str) -> int:
    url = f"{cdn_root}/{object_path}"
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=20) as res:
            return int(res.headers.get("Content-Length") or 0)
    except Exception:
        return 0

def storage_put_http11(method: str, object_path: str, body: bytes, content_type: str, cache_control: str) -> int:
    parsed = urllib.parse.urlparse(supabase_url)
    path = f"/storage/v1/object/{bucket}/{object_path}"
    conn = http.client.HTTPSConnection(parsed.hostname, parsed.port or 443, timeout=180)
    try:
        conn.putrequest(method, path)
        conn.putheader("Host", parsed.hostname)
        conn.putheader("Authorization", f"Bearer {service_key}")
        conn.putheader("apikey", service_key)
        conn.putheader("Content-Type", content_type)
        conn.putheader("Content-Length", str(len(body)))
        conn.putheader("x-upsert", "true")
        conn.putheader("cache-control", cache_control)
        conn.putheader("Connection", "close")
        conn.endheaders()
        conn.send(body)
        res = conn.getresponse()
        code = res.status
        res.read()
        return code
    finally:
        conn.close()

def storage_put(object_path: str, file_path: Path, content_type: str, cache_control: str) -> None:
    body = file_path.read_bytes()
    code = storage_put_http11("POST", object_path, body, content_type, cache_control)
    if code in (200, 201):
        return
    if code in (409, 400):
        code = storage_put_http11("PUT", object_path, body, content_type, cache_control)
        if code in (200, 201):
            return
    raise RuntimeError(f"storage_put {object_path} HTTP {code}")

ids = sorted(p.stem for p in (root / "data/routing/regions").glob("*.json"))
if only:
    ids = [x.strip() for x in only.split(",") if x.strip()]
remote = {} if force else load_remote_catalog()
uploaded = []
skipped = 0
for rid in ids:
    tar = ready(rid)
    if not tar:
        continue
    man_src = dist / rid / "manifest.json"
    data = json.loads(man_src.read_text(encoding="utf-8"))
    data["cdn"] = {
        **(data.get("cdn") or {}),
        "baseUrl": f"{cdn_root}/{rid}",
        "pack": data.get("cdn", {}).get("pack") or f"{rid}.tar.gz",
        "packGz": f"{rid}.tar.gz",
    }
    data.pop("shipped", None)
    man_out = dist / rid / "manifest.publish.json"
    man_out.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    man_dir.mkdir(parents=True, exist_ok=True)
    (man_dir / f"{rid}.json").write_text(man_out.read_text(encoding="utf-8"), encoding="utf-8")

    local_bytes = tar.stat().st_size
    if not force and remote.get(rid) == local_bytes:
        skipped += 1
        continue
    if not force and remote_object_size(f"{rid}/{rid}.tar.gz") == local_bytes:
        skipped += 1
        continue

    print(f"upload {rid} ({local_bytes / 1e6:.1f} MB)", flush=True)
    storage_put(f"{rid}/{rid}.tar.gz", tar, "application/gzip", "max-age=86400")
    storage_put(f"{rid}/manifest.json", man_out, "application/json", "max-age=300")
    uploaded.append(rid)

# Full catalog from every local ready pack (not only this run).
catalog = {"packs": [], "attribution": "FlowLine Offline Region Packs"}
for rid in sorted(p.stem for p in (root / "data/routing/regions").glob("*.json")):
    tar = ready(rid)
    man_path = man_dir / f"{rid}.json"
    if not tar or not man_path.is_file():
        continue
    m = json.loads(man_path.read_text(encoding="utf-8"))
    files = m.get("files") or {}
    gz = next((k for k in files if str(k).endswith(".tar.gz") or str(k).endswith(".tgz")), None)
    bytes_ = files.get(gz, {}).get("bytes") if gz else tar.stat().st_size
    catalog["packs"].append({
        "id": rid,
        "name": m.get("name") or rid,
        "bbox": m.get("bbox"),
        "builtAt": m.get("builtAt"),
        "engines": m.get("engines"),
        "hasManifest": True,
        "downloadable": True,
        "status": "ready",
        "bytes": bytes_,
        "cdn": m.get("cdn") or {
            "baseUrl": f"{cdn_root}/{rid}",
            "packGz": f"{rid}.tar.gz",
        },
    })
catalog["packs"].sort(key=lambda p: p["name"])
cat_path = dist / "_catalog.json"
cat_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
print(
    f"catalog {len(catalog['packs'])} packs (uploaded {len(uploaded)}, skipped {skipped})",
    flush=True,
)
remote_ids = set(remote)
local_ids = {p["id"] for p in catalog["packs"]}
if uploaded or force or local_ids != remote_ids:
    storage_put("catalog.json", cat_path, "application/json", "max-age=60")
print("PUBLISHED", ",".join(uploaded) if uploaded else "(none new)", flush=True)
PY
