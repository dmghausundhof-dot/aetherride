#!/usr/bin/env bash
# Offline / Flugmodus-Regression (API + manuelle Emulator-Checkliste).
#
# Usage:
#   bash scripts/smoke-offline-flight.sh
#   API_BASE=http://127.0.0.1:3001 bash scripts/smoke-offline-flight.sh
#
# Automatisch: Pack-API, Manifest, Download-Größe, Routing-Status.
# Manuell: Emulator Flugmodus — Schritte unten (nicht per ADB erzwingbar
# ohne Geräte-UI; Script druckt die Checkliste).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="${API_BASE:-http://127.0.0.1:3001}"
ID=schwarzwald-nord

echo "== Offline / Flugmodus Smoke =="
echo "API=$API"

# 1) Katalog
code=$(curl -sS -o /tmp/ar-flight-packs.json -w "%{http_code}" \
  "$API/api/offline/packs" || true)
echo "GET /api/offline/packs → HTTP $code"
[[ "$code" == "200" ]] || { echo "FAIL packs catalog"; exit 1; }

python3 - <<'PY'
import json
d = json.load(open("/tmp/ar-flight-packs.json"))
packs = d.get("packs") or []
ids = [p.get("id") for p in packs]
print(" packs:", ids)
assert "schwarzwald-nord" in ids, "schwarzwald-nord missing from catalog"
PY

# 2) Manifest
code=$(curl -sS -o /tmp/ar-flight-manifest.json -w "%{http_code}" \
  "$API/api/offline/packs/$ID")
echo "GET /api/offline/packs/$ID → HTTP $code"
[[ "$code" == "200" ]] || { echo "FAIL manifest"; exit 1; }

# 3) Artifact (mind. 1 MB — Valhalla-Pack)
code=$(curl -sS -o /tmp/ar-flight-pack.tar.gz -w "%{http_code}" \
  "$API/api/offline/packs/$ID/$ID.tar.gz")
bytes=$(wc -c </tmp/ar-flight-pack.tar.gz)
echo "GET …/$ID.tar.gz → HTTP $code bytes=$bytes"
[[ "$code" == "200" && "$bytes" -gt 1000000 ]] || {
  echo "FAIL pack download too small or error"
  exit 1
}

# 4) Routing status (Live-Flag ehrlich)
code=$(curl -sS -o /tmp/ar-flight-routing.json -w "%{http_code}" \
  "$API/api/routing/status" || true)
echo "GET /api/routing/status → HTTP $code"
if [[ "$code" == "200" ]]; then
  python3 - <<'PY'
import json
s = json.load(open("/tmp/ar-flight-routing.json"))
print(" engine:", s.get("engine"), "liveVerified:", s.get("liveVerified"),
      "configured:", s.get("configured"))
if s.get("notice"):
    print(" notice:", s.get("notice"))
PY
fi

# 5) Optional: Online-Route kurz (Flugmodus später — muss dann fehlschlagen)
code=$(curl -sS -o /tmp/ar-flight-route.json -w "%{http_code}" \
  -X POST "$API/api/route" \
  -H 'Content-Type: application/json' \
  -d '{"profile":"mtb_allmountain","from":[7.85,47.99],"to":[7.9,48.0]}' \
  || true)
echo "POST /api/route (online baseline) → HTTP $code"
if [[ "$code" == "200" ]]; then
  python3 - <<'PY'
import json
r = json.load(open("/tmp/ar-flight-route.json"))
dist = r.get("distance") or r.get("distanceM") or (r.get("paths") or [{}])[0].get("distance")
print(" distance hint:", dist)
assert "error" not in r or dist, r
PY
fi

rm -f /tmp/ar-flight-packs.json /tmp/ar-flight-manifest.json \
  /tmp/ar-flight-pack.tar.gz /tmp/ar-flight-routing.json /tmp/ar-flight-route.json

echo
echo "API-Smoke OK."
echo
cat <<'EOF'
== Manuelle Emulator-Checkliste (Flugmodus) ==
Voraussetzung: Pack einmal online geladen (Offline-Sheet / smoke-offline-pack.sh --push).

1. App starten, Offline-Region „Schwarzwald Nord“ aktiv (Valhalla/offline_graph).
2. Gerät: Flugmodus EIN (oder mobiles Daten+WLAN aus).
3. Discover → Planen: Start/Ziel in Pack-BBox → Route berechnen.
   Erwartung: Offline-Engine antwortet; kein „Netzwerkfehler“ für die Route.
4. Karte: Style/Tiles aus Pack oder graue Basemap — kein Crash.
5. Ride kurz starten → GPS (Sim) → Stop → Post-Ride: Distanz > 0 wenn Sim-Fixes.
6. Online-only APIs (Strava Upload, Heatmap contribute, Live-Geocode) zeigen
   ehrlichen Offline-/Fehlerhinweis — kein Fake-Erfolg.
7. Flugmodus AUS → Sync/Heatmap wieder ok.

Optional ADB:
  adb shell cmd connectivity airplane-mode enable
  adb shell cmd connectivity airplane-mode disable
  (API-Level abhängig; bei Fehler Settings → Netzwerk manuell.)
EOF
