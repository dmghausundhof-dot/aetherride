#!/usr/bin/env bash
# Deep-Link / App-Link smoke (Web + optional adb).
# Usage:
#   bash scripts/smoke-deeplink-android.sh
#   bash scripts/smoke-deeplink-android.sh https://aetherride.vercel.app
#   ADB=1 bash scripts/smoke-deeplink-android.sh   # also fire adb VIEW intents
set -euo pipefail

BASE="${1:-https://aetherride.vercel.app}"
BASE="${BASE%/}"
PKG="${ANDROID_PACKAGE:-com.aetherride.aetherride_mobile}"
ROUTE="${SMOKE_ROUTE_ID:-r-heidelberg-city}"

ok() { echo "  [OK] $*"; }
fail() { echo "  [FAIL] $*"; FAILED=1; }
FAILED=0

echo "== Deep Link / App Link Smoke =="
echo "Base: $BASE"
echo

# --- Web well-known + open landing ---
code=$(curl -sS -o /tmp/ar-assetlinks.json -w '%{http_code}' \
  "$BASE/.well-known/assetlinks.json" || true)
if [[ "$code" == "200" ]]; then
  pkg=$(node -e "const j=require('/tmp/ar-assetlinks.json');console.log(j[0]?.target?.package_name||'')" 2>/dev/null || true)
  fps=$(node -e "const j=require('/tmp/ar-assetlinks.json');const f=j[0]?.target?.sha256_cert_fingerprints||[];console.log(f[0]||'')" 2>/dev/null || true)
  if [[ "$pkg" == "$PKG" ]]; then
    ok "assetlinks package=$pkg"
  else
    fail "assetlinks package='$pkg' expected $PKG"
  fi
  if [[ "$fps" == 00:00:* ]] || [[ -z "$fps" ]]; then
    # App Links verification needs real fingerprints; custom scheme still works.
    if [[ "${STRICT_SHA:-0}" == "1" ]]; then
      fail "assetlinks SHA still placeholder — set NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS"
    else
      echo "  [WARN] assetlinks SHA placeholder — set NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS (STRICT_SHA=1 to fail)"
    fi
  else
    ok "assetlinks SHA present (${fps:0:17}…)"
  fi
else
  fail "assetlinks HTTP $code"
fi

code=$(curl -sS -o /tmp/ar-aasa.json -w '%{http_code}' \
  "$BASE/.well-known/apple-app-site-association" || true)
if [[ "$code" == "200" ]]; then
  ok "apple-app-site-association HTTP 200"
else
  fail "AASA HTTP $code"
fi

for path in \
  "/open/ride?route=${ROUTE}" \
  "/ride?route=${ROUTE}" \
  "/tours/${ROUTE}" \
  "/discover"; do
  c=$(curl -sS -o /dev/null -w '%{http_code}' "$BASE$path" || true)
  if [[ "$c" == "200" || "$c" == "307" || "$c" == "308" || "$c" == "301" || "$c" == "302" ]]; then
    ok "GET $path → $c"
  else
    fail "GET $path → $c"
  fi
done

# Geometry API used by Flutter DeepLinkHandler
code=$(curl -sS -o /tmp/ar-geom.json -w '%{http_code}' \
  "$BASE/api/tours/geometry?id=${ROUTE}" || true)
if [[ "$code" == "200" ]]; then
  pts=$(node -e "const j=require('/tmp/ar-geom.json');console.log((j.geometry&&j.geometry.coordinates||[]).length)" 2>/dev/null || echo 0)
  if [[ "${pts:-0}" -ge 2 ]]; then
    ok "geometry $ROUTE pts=$pts"
  else
    fail "geometry $ROUTE pts=$pts"
  fi
else
  fail "geometry HTTP $code"
fi

echo
LOOP="${SMOKE_LOOP_ID:-seed-loop-tempelhofer-60}"

echo "Custom scheme (install + adb):"
echo "  adb shell am start -a android.intent.action.VIEW \\"
echo "    -d 'aetherride://ride?route=${ROUTE}' $PKG"
echo "  adb shell am start -a android.intent.action.VIEW \\"
echo "    -d 'aetherride://tours/${ROUTE}' $PKG"
echo "  adb shell am start -a android.intent.action.VIEW \\"
echo "    -d 'aetherride://discover' $PKG"
echo "  # D-60-05: 60-Min loop → ActiveRoute + Ride"
echo "  adb shell am start -a android.intent.action.VIEW \\"
echo "    -d 'aetherride://discover?lens=60&loop=${LOOP}&start=1' $PKG"
echo "HTTPS App Link (needs verified assetlinks + installed app):"
echo "  adb shell am start -a android.intent.action.VIEW \\"
echo "    -d '${BASE}/open/ride?route=${ROUTE}'"
echo "  adb shell am start -a android.intent.action.VIEW \\"
echo "    -d '${BASE}/discover?lens=60&loop=${LOOP}&start=1'"
echo

if [[ "${ADB:-0}" == "1" ]]; then
  if ! command -v adb >/dev/null 2>&1; then
    fail "adb not in PATH"
  else
    n=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{c++} END{print c+0}')
    if [[ "$n" -lt 1 ]]; then
      fail "no adb device — skip VIEW intents"
    else
      for uri in \
        "aetherride://ride?route=${ROUTE}" \
        "aetherride://tours/${ROUTE}" \
        "aetherride://discover" \
        "aetherride://discover?lens=60&loop=${LOOP}&start=1"; do
        if adb shell am start -a android.intent.action.VIEW -d "$uri" "$PKG" >/tmp/ar-adb.out 2>&1; then
          ok "adb VIEW $uri"
        else
          fail "adb VIEW $uri ($(head -c 120 /tmp/ar-adb.out))"
        fi
      done
    fi
  fi
else
  echo "  · Set ADB=1 to fire intents when a device is connected"
fi

echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "SMOKE DEEPLINK FAIL"
  exit 1
fi
echo "SMOKE DEEPLINK OK (web paths + well-known)"
exit 0
