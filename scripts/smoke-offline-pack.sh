#!/usr/bin/env bash
# Smoke: Offline-Pack API + optional Emulator push.
# Usage:
#   bash scripts/smoke-offline-pack.sh
#   API_BASE=http://127.0.0.1:3001 bash scripts/smoke-offline-pack.sh --push
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="${API_BASE:-http://127.0.0.1:3001}"
ID=schwarzwald-nord
PACK="$ROOT/data/routing/dist/$ID/$ID.tar.gz"
PUSH=0
for a in "$@"; do [[ "$a" == "--push" ]] && PUSH=1; done

echo "== Offline-Pack Smoke =="
echo "API=$API"
code=$(curl -sS -o /tmp/ar-packs.json -w "%{http_code}" "$API/api/offline/packs" || true)
echo "GET /api/offline/packs → HTTP $code"
python3 - <<'PY'
import json
d=json.load(open("/tmp/ar-packs.json"))
packs=d.get("packs") or []
print(" packs:", [p.get("id") for p in packs])
assert any(p.get("id")=="schwarzwald-nord" for p in packs), "schwarzwald-nord missing"
PY

code=$(curl -sS -o /tmp/ar-manifest.json -w "%{http_code}" "$API/api/offline/packs/$ID")
echo "GET /api/offline/packs/$ID → HTTP $code"
python3 - <<'PY'
import json
m=json.load(open("/tmp/ar-manifest.json"))
assert m.get("engines",{}).get("valhalla_tiles") is True
print(" engines:", m.get("engines"))
print(" packGz:", (m.get("cdn") or {}).get("packGz"))
PY

code=$(curl -sS -o /tmp/ar-pack.tar.gz -w "%{http_code}" \
  "$API/api/offline/packs/$ID/$ID.tar.gz")
bytes=$(wc -c </tmp/ar-pack.tar.gz)
echo "GET …/$ID.tar.gz → HTTP $code bytes=$bytes"
[[ "$code" == "200" && "$bytes" -gt 1000000 ]] || { echo "FAIL pack download"; exit 1; }

if [[ "$PUSH" == "1" ]]; then
  if ! command -v adb >/dev/null; then
    echo "adb fehlt — skip push"
    exit 0
  fi
  dev=$(adb devices | awk '/device$/{print $1; exit}')
  if [[ -z "$dev" ]]; then
    echo "Kein Emulator/Gerät — skip push"
    exit 0
  fi
  echo "adb reverse 3001 + push pack → /sdcard/Download/"
  adb -s "$dev" reverse tcp:3001 tcp:3001 || true
  SRC="$PACK"
  [[ -f "$SRC" ]] || SRC=/tmp/ar-pack.tar.gz
  adb -s "$dev" push "$SRC" /sdcard/Download/schwarzwald-nord.tar.gz
  echo "OK — in der App Offline-Sheet: Region laden (API 10.0.2.2:3001) oder tar.gz entpacken."
fi

echo "Smoke OK"
rm -f /tmp/ar-packs.json /tmp/ar-manifest.json /tmp/ar-pack.tar.gz
