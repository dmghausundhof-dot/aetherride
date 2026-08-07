#!/usr/bin/env bash
# AetherRide ops dry-run checklist (no secrets required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok() { printf '  OK  %s\n' "$*"; }
warn() { printf '  !!  %s\n' "$*"; }
info() { printf '  ·   %s\n' "$*"; }

echo "== AetherRide Ops Checklist =="

echo
echo "[1] Ride chunks SQL"
if [[ -f supabase/ride_chunks.sql ]]; then
  ok "supabase/ride_chunks.sql vorhanden — in Supabase SQL Editor ausführen"
  info "Bucket ride-chunks + Tabelle ride_chunk_uploads + RLS"
else
  warn "supabase/ride_chunks.sql fehlt"
fi

echo
echo "[2] Play Billing"
info "Package: com.aetherride.aetherride_mobile"
info "Product ID: aetherride_pro_monthly (siehe mobile/README.md)"
if [[ -n "${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON:-}" ]]; then
  ok "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON ist gesetzt (2A Verify aktiv)"
else
  warn "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON unset → trusted-token MVP / PLAY_VERIFY_STUB=1"
fi

echo
echo "[3] Offline region packs"
for d in public/offline data/routing/dist data/routing/manifests; do
  if [[ -d "$d" ]]; then
    n=$(find "$d" -maxdepth 2 \( -name 'manifest.json' -o -name '*.json' \) 2>/dev/null | wc -l | tr -d ' ')
    ok "$d ($n json-Dateien)"
  else
    info "$d fehlt (optional bis Region-Build)"
  fi
done
info "Build: npm run routing:region  |  Valhalla Android: npm run routing:valhalla:android"

echo
echo "[4] Mapillary / Strava / Valhalla env"
[[ -n "${MAPILLARY_ACCESS_TOKEN:-}${NEXT_PUBLIC_MAPILLARY_ACCESS_TOKEN:-}" ]] && ok "Mapillary-Token gesetzt" || warn "Mapillary-Token unset → Trail View Demo"
[[ -n "${STRAVA_CLIENT_ID:-}" && -n "${STRAVA_CLIENT_SECRET:-}" ]] && ok "Strava OAuth env gesetzt" || warn "Strava OAuth unset → Stub-Export only"
[[ -n "${VALHALLA_URL:-}" ]] && ok "VALHALLA_URL gesetzt" || info "VALHALLA_URL optional (Server-Routing)"

echo
echo "[5] Bewusst Hardware/Ops"
info "Bosch LDI echtes Protokoll = G-1 (Shell vorhanden)"
info "Play Console Produkt + License Tester anlegen"
info "GET /api/offline/packs · GET /api/strava · POST /api/billing/play-verify"

echo
echo "Done."
