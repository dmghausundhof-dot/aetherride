#!/usr/bin/env bash
# Ops-Checkliste (Gap-Plan E) — lokal Abhakbares + externe Reste.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok() { echo "  [OK] $*"; }
miss() { echo "  [ ] $*"; }
note() { echo "  · $*"; }

echo "== AetherRide Ops-Check =="
echo

echo "Env / Routing"
if [[ -f .env.local ]]; then
  ok ".env.local vorhanden"
  for key in GRAPHHOPPER_API_KEY NEXT_PUBLIC_ROUTING_LIVE STADIA_API_KEY \
    NEXT_PUBLIC_PMTILES_URL STRAVA_CLIENT_ID STRAVA_CLIENT_SECRET \
    NEXT_PUBLIC_SUPABASE_URL STRIPE_WEBHOOK_SECRET; do
    if grep -qE "^${key}=" .env.local 2>/dev/null && \
       ! grep -qE "^${key}=\s*$" .env.local 2>/dev/null; then
      ok "$key gesetzt"
    else
      miss "$key fehlt oder leer"
    fi
  done
else
  miss ".env.local fehlt"
fi
echo

echo "Mobile"
if [[ -x scripts/mobile-with-env.sh ]]; then
  ok "scripts/mobile-with-env.sh ausführbar (dart-defines)"
else
  miss "scripts/mobile-with-env.sh"
fi
note "AVD: aether_api34 (nicht API 36)"
note "API_BASE_URL=http://10.0.2.2:3001 gegen Host-Next"
echo

echo "Partner / Honesty"
note "Trailforks: Attribution-only (kein Condition-Layer ohne Partnerschaft)"
note "Mapillary: Token → Live; sonst ehrlicher Platzhalter"
note "Outdooractive: Geometry wenn API liefert; sonst usingDemoFallback"
note "Bosch LDI Hardware (G-1): bewusst nicht in diesem Batch"
for key in OUTDOORACTIVE_API_KEY OUTDOORACTIVE_PROJECT_KEY MAPILLARY_ACCESS_TOKEN \
  NEXT_PUBLIC_MAPILLARY_TOKEN; do
  if [[ -f .env.local ]] && grep -qE "^${key}=" .env.local 2>/dev/null && \
     ! grep -qE "^${key}=\s*$" .env.local 2>/dev/null; then
    ok "$key gesetzt"
  else
    miss "$key fehlt — Live-Enrichment eingeschränkt (Demo/Platzhalter ok)"
  fi
done
echo

echo "Deep Links / App Links"
ok "Web: /open/ride + well-known assetlinks/AASA (Code)"
ok "Android: aetherride://ride|tours|discover + autoVerify hosts"
ok "Cleartext: network_security_config (10.0.2.2 only)"
ok "Smoke script: npm run smoke:deeplink"
miss "Vercel NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS"
miss "Vercel NEXT_PUBLIC_IOS_TEAM_ID"
miss "Device adb deep-link smoke (npm run smoke:deeplink:adb)"
echo

echo "Externe Ops (nicht lokal fakebar)"
note "Prod smoke: npm run smoke:web:prod"
note "Auth sync: SMOKE_EMAIL=… SMOKE_PASSWORD=… npm run smoke:sync-auth -- https://aetherride.vercel.app"
miss "Vercel Env (Prod) synchron — GET /api/ops/env-check auf Prod"
miss "Stripe Webhook Endpoint Prod"
miss "Play Service Account JSON + License Tester + SKU aetherride_pro_monthly"
miss "STRAVA_CLIENT_ID/SECRET in .env.local + Strava Redirect → /api/strava/callback"
ok "SQL: strava_connections + heatmap_cells + bike-photos (Supabase aetherride)"
ok "Auth uri_allow_list: login-callback + strava-callback Deep-Links"
ok "Valhalla JNI arm64 linked + schwarzwald-nord pack mit Tiles"
miss "Bosch LDI G-1 (Hardware/NDA)"
echo

echo "Done: lokal prüfbar abgehakt; Rest = echte Credentials/Freigaben."
echo "Siehe auch: mobile/ANDROID_OPS_CHECKLIST.md · bash scripts/ops-android-auth.sh"
