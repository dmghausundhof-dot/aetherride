#!/usr/bin/env python3
"""Upload generated basemap style JSONs to Supabase Storage (HTTP/1.1, x-upsert)."""
from __future__ import annotations

import http.client
import json
import sys
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STYLES = ROOT / "data/routing/basemap-styles"
BUCKET = "offline-packs"


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


def storage_put_http11(
    supabase_url: str,
    service_key: str,
    method: str,
    object_path: str,
    body: bytes,
    content_type: str,
) -> int:
    parsed = urllib.parse.urlparse(supabase_url)
    path = f"/storage/v1/object/{BUCKET}/{object_path}"
    conn = http.client.HTTPSConnection(parsed.hostname, parsed.port or 443, timeout=180)
    try:
        conn.putrequest(method, path)
        conn.putheader("Host", parsed.hostname)
        conn.putheader("Authorization", f"Bearer {service_key}")
        conn.putheader("apikey", service_key)
        conn.putheader("Content-Type", content_type)
        conn.putheader("Content-Length", str(len(body)))
        conn.putheader("x-upsert", "true")
        conn.putheader("cache-control", "max-age=300")
        conn.putheader("Connection", "close")
        conn.endheaders()
        conn.send(body)
        res = conn.getresponse()
        code = res.status
        res.read()
        return code
    finally:
        conn.close()


def storage_put(supabase_url: str, service_key: str, object_path: str, file_path: Path) -> None:
    body = file_path.read_bytes()
    code = storage_put_http11(
        supabase_url, service_key, "POST", object_path, body, "application/json"
    )
    if code in (200, 201):
        return
    if code in (409, 400):
        code = storage_put_http11(
            supabase_url, service_key, "PUT", object_path, body, "application/json"
        )
        if code in (200, 201):
            return
    raise RuntimeError(f"storage_put {object_path} HTTP {code}")


def main() -> int:
    env = load_env(ROOT / ".env.local")
    if not env.get("SUPABASE_SERVICE_ROLE_KEY"):
        env = {**load_env(Path("/home/luka/Projects/aetherride/.env.local")), **env}
    supabase_url = (env.get("NEXT_PUBLIC_SUPABASE_URL") or "").rstrip("/")
    service_key = env.get("SUPABASE_SERVICE_ROLE_KEY") or ""
    if not supabase_url or not service_key:
        raise SystemExit("missing SUPABASE url or service role")
    files = sorted(STYLES.glob("*-z11-style.json"))
    if len(files) < 1:
        raise SystemExit(f"no style JSONs in {STYLES}")
    for path in files:
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("version") != 8:
            raise SystemExit(f"invalid style {path.name}")
        object_path = f"basemap/{path.name}"
        print(f"upload {object_path} ({path.stat().st_size} B)", flush=True)
        storage_put(supabase_url, service_key, object_path, path)
        print(f"OK {object_path}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
