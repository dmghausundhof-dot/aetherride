#!/usr/bin/env python3
"""Resumable TUS upload to Supabase Storage (6 MiB chunks). Never prints secrets."""
from __future__ import annotations

import argparse
import base64
import os
import sys
import time
from pathlib import Path

import requests

CHUNK = 6 * 1024 * 1024


def _b64(s: str) -> str:
    return base64.b64encode(s.encode("utf-8")).decode("ascii")


def _load_env(root: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    p = root / ".env.local"
    if not p.is_file():
        raise SystemExit("missing .env.local")
    for line in p.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("object_name")
    ap.add_argument("--content-type", default="application/octet-stream")
    ap.add_argument("--cache-control", default="86400")
    ap.add_argument("--bucket", default="offline-packs")
    args = ap.parse_args()

    root = Path(__file__).resolve().parents[2]
    env = _load_env(root)
    base = (env.get("NEXT_PUBLIC_SUPABASE_URL") or "").rstrip("/")
    key = env.get("SUPABASE_SERVICE_ROLE_KEY") or ""
    if not base or not key:
        print("missing SUPABASE url or service role", file=sys.stderr)
        return 2

    path = Path(args.file)
    size = path.stat().st_size
    host = base.replace("https://", "").split(".")[0]
    endpoints = [
        f"https://{host}.storage.supabase.co/storage/v1/upload/resumable",
        f"{base}/storage/v1/upload/resumable",
    ]
    meta = ",".join(
        [
            f"bucketName {_b64(args.bucket)}",
            f"objectName {_b64(args.object_name)}",
            f"contentType {_b64(args.content_type)}",
            f"cacheControl {_b64(args.cache_control)}",
        ]
    )
    headers = {
        "Authorization": f"Bearer {key}",
        "apikey": key,
        "Tus-Resumable": "1.0.0",
        "Upload-Length": str(size),
        "Upload-Metadata": meta,
        "x-upsert": "true",
    }
    loc_file = path.with_suffix(path.suffix + ".tus-location")
    sess = requests.Session()
    loc = None
    last_err = None

    def auth_headers() -> dict[str, str]:
        return {
            "Authorization": f"Bearer {key}",
            "apikey": key,
            "Tus-Resumable": "1.0.0",
        }

    if loc_file.is_file():
        saved = loc_file.read_text(encoding="utf-8").strip()
        if saved:
            try:
                hr = sess.head(saved, headers=auth_headers(), timeout=30)
                if hr.status_code in (200, 204) and hr.headers.get("Upload-Offset"):
                    loc = saved
                    print(f"TUS resume saved location offset={hr.headers.get('Upload-Offset')}", flush=True)
            except requests.RequestException as e:
                print(f"TUS saved location dead ({type(e).__name__})", flush=True)

    if not loc:
        for ep in endpoints:
            print(f"TUS create {ep} size={size}", flush=True)
            try:
                r = sess.post(ep, headers=headers, timeout=60)
            except requests.RequestException as e:
                last_err = f"{type(e).__name__}"
                print(f"  create fail {last_err}", flush=True)
                continue
            print(f"  status {r.status_code}", flush=True)
            if r.status_code in (200, 201):
                loc = r.headers.get("Location")
                if loc:
                    loc_file.write_text(loc + "\n", encoding="utf-8")
                    break
            last_err = f"{r.status_code} {r.text[:240]}"
            print(f"  body {last_err}", flush=True)
    if not loc:
        print(f"TUS_CREATE_FAIL {last_err}", flush=True)
        return 1

    print(f"TUS location ok offset_target={size}", flush=True)
    offset = 0
    try:
        hr = sess.head(loc, headers=auth_headers(), timeout=30)
        if hr.status_code in (200, 204):
            offset = int(hr.headers.get("Upload-Offset") or 0)
            print(f"TUS start offset={offset}", flush=True)
    except requests.RequestException:
        pass
    t0 = time.time()
    with path.open("rb") as fh:
        fh.seek(offset)
        while offset < size:
            chunk = fh.read(CHUNK)
            if not chunk:
                break
            patch_headers = {
                **auth_headers(),
                "Upload-Offset": str(offset),
                "Content-Type": "application/offset+octet-stream",
                "x-upsert": "true",
            }
            for attempt in range(12):
                try:
                    pr = sess.patch(loc, headers=patch_headers, data=chunk, timeout=180)
                except requests.RequestException as e:
                    print(f"  patch err {type(e).__name__} retry={attempt}", flush=True)
                    sess.close()
                    sess = requests.Session()
                    time.sleep(min(30, 2 * (attempt + 1)))
                    continue
                if pr.status_code in (200, 204):
                    new_off = int(pr.headers.get("Upload-Offset") or (offset + len(chunk)))
                    offset = new_off
                    pct = 100.0 * offset / size
                    rate = offset / max(time.time() - t0, 1) / 1e6
                    print(f"  {offset}/{size} {pct:.1f}% {rate:.2f} MB/s", flush=True)
                    break
                print(f"  patch {pr.status_code} {pr.text[:200]} retry={attempt}", flush=True)
                if pr.status_code == 409:
                    hr = sess.head(loc, headers=auth_headers(), timeout=30)
                    offset = int(hr.headers.get("Upload-Offset") or 0)
                    fh.seek(offset)
                    print(f"  resume offset={offset}", flush=True)
                    break
                time.sleep(min(30, 2 * (attempt + 1)))
            else:
                print("TUS_PATCH_FAIL", flush=True)
                return 1
    loc_file.unlink(missing_ok=True)
    print("TUS_OK", flush=True)
    return 0


if __name__ == "__main__":
    os.environ.setdefault("PYTHONUNBUFFERED", "1")
    raise SystemExit(main())
