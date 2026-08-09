#!/usr/bin/env bash
# Print Android / Supabase Auth ops facts (SHA, package, redirect URLs).
# Usage: bash scripts/ops-android-auth.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== AetherRide Android Auth Ops =="
echo
echo "Package / applicationId:"
echo "  com.aetherride.aetherride_mobile"
echo
echo "Deep links (Manifest + AppConfig):"
echo "  io.aetherride.app://login-callback/"
echo "  io.aetherride.app://strava-callback/"
echo
echo "Debug keystore fingerprints (License Tester / Supabase Google Android client):"
if [[ -f "$HOME/.android/debug.keystore" ]]; then
  keytool -list -v \
    -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null \
    | grep -E 'SHA1:|SHA256:' || true
else
  echo "  ~/.android/debug.keystore fehlt — einmal flutter run erzeugen"
fi
echo
echo "Supabase Dashboard (falls CLI-PATCH nicht genutzt):"
echo "  Authentication → URL Configuration"
echo "  Redirect URLs: die beiden Deep-Links + http://localhost:3000/**"
echo
echo "Play Console:"
echo "  Produkt-ID exakt: aetherride_pro_monthly"
echo "  License Testing → Google-Konto des Testers"
echo
echo "Strava Developer App:"
echo "  Authorization Callback Domain / Redirect:"
echo "  {NEXT_PUBLIC_APP_URL}/api/strava/callback"
echo "  Env: STRAVA_CLIENT_ID + STRAVA_CLIENT_SECRET"
echo
echo "Offline-Pack (lokal):"
echo "  GET /api/offline/packs"
echo "  GET /api/offline/packs/schwarzwald-nord/schwarzwald-nord.tar.gz"
echo "  Dist: data/routing/dist/schwarzwald-nord/"
echo "  Smoke: bash scripts/smoke-offline-pack.sh [--push]"
echo "  Flugmodus: bash scripts/smoke-offline-flight.sh"
echo
echo "Google Sign-In (optional):"
echo "  1) Google Cloud OAuth Client (Web) → Supabase Auth → Google enable"
echo "  2) Android Client: package com.aetherride.aetherride_mobile"
echo "  3) SHA-1 Debug (oben) in Google Cloud / Supabase hinterlegen"
echo "  Ohne das: E-Mail-Login + Deep-Link login-callback nutzen"
echo
echo "Siehe: mobile/ANDROID_OPS_CHECKLIST.md"
