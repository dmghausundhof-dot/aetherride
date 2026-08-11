# Android Ops-Checkliste (AetherRide)

Kurze Gate-/Console-Punkte — App-Code für Strava/Heatmap/Fotos ist vorbereitet.
Schnellcheck Auth/SHA: `bash scripts/ops-android-auth.sh`

## Deep Links / App Links (Web → App)

- [x] Custom scheme `aetherride://ride|tours|discover` (Manifest + Flutter `DeepLinkHandler`)
- [x] HTTPS App Links: hosts via Gradle placeholders  
  Default: `aetherride.vercel.app` + `aetherride.app` (`autoVerify=true`)  
  Paths: `/open`, `/ride`, `/tours`, `/discover`
- [x] Web: `/open/ride`, `/.well-known/assetlinks.json`, AASA
- [x] Cleartext nur Emulator-Loopback (`network_security_config.xml` → 10.0.2.2)
- [x] Unit-Tests: `mobile/test/deep_link_parse_test.dart`
- [x] Smoke: `npm run smoke:deeplink` · mit Gerät `npm run smoke:deeplink:adb`
- [ ] Vercel: `NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS` (Debug: `ops-android-auth.sh`; Play: App Signing)
- [ ] Vercel: `NEXT_PUBLIC_IOS_TEAM_ID` für Universal Links
- [ ] Device-Test:  
  `adb shell am start -a android.intent.action.VIEW -d "aetherride://ride?route=r-heidelberg-city"`  
  und Browser `https://aetherride.vercel.app/open/ride?route=r-heidelberg-city`
- [ ] Override Host: `./gradlew … -PappLinkHost=your.domain.com`

## Auth / Supabase

- [x] SQL anwenden: `supabase/strava_connections.sql` (Projekt aetherride)
- [x] SQL anwenden: `supabase/heatmap_cells.sql`
- [x] SQL anwenden: `supabase/bike_photos_storage.sql` (Bucket `bike-photos`)
- [x] Deep-Link Redirects in Auth `uri_allow_list`:
  `io.aetherride.app://login-callback/`, `io.aetherride.app://strava-callback/`,
  plus `http://localhost:3000/**` / `3001/**`
- [ ] Mobile OAuth Client (Package + SHA) in Supabase Dashboard  
  Package: `com.aetherride.aetherride_mobile` — SHA via `scripts/ops-android-auth.sh`
- [x] Google/Apple Buttons default **aus** (`ENABLE_GOOGLE_OAUTH` / `ENABLE_APPLE_OAUTH`)
- [x] `SUPABASE_SERVICE_ROLE_KEY` lokal gesetzt (Account-Delete, Strava-Store, Heatmap)

## Strava

- [x] Upload-Route: GPX → Strava Uploads API; sonst Metadaten (Code)
- [x] Kein Fake-Track bei leerem GPS — GPX/FIT (Code)
- [ ] `STRAVA_CLIENT_ID` + `STRAVA_CLIENT_SECRET` in Env
- [ ] Strava App Redirect: `{APP_URL}/api/strava/callback`
- [ ] Optional: `STRAVA_STATE_SECRET`
- [ ] Nach Connect: Mobile/Web „Letzten Ride zu Strava“ testen

## Play Billing

Schritt-für-Schritt-Runbook (Keystore ist bereits generiert):
[PLAY_CONSOLE_RUNBOOK.md](PLAY_CONSOLE_RUNBOOK.md)

- [x] Upload-Keystore generiert (lokal, git-ignoriert) — SHA im Runbook
- [ ] SKU `aetherride_pro_monthly` in Play Console angelegt
- [ ] License Tester Account für Restore/Kauf-Smoke
- [ ] Optional: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` für Server-Verify
- [ ] App Signing + Internal Testing Track
- [x] UI: Trusted-Token-MVP ehrlich gelabelt (ohne Publisher-API)

## Routing / Offline (Valhalla)

- [x] Android JNI Valhalla-linked (`jniLibs/arm64-v8a`, `GRAPH_ONLY=0`)
- [x] Region-Pack `schwarzwald-nord` + Smoke-Script
- [x] Offline-Sheet: API-Base, Pack zurücksetzen, Style-Reload
- [x] Basemap Style-JSON Heuristik; Roh-`.pmtiles` abgelehnt
- [x] Discover Routing-Status-Banner
- [x] Flugmodus-Smoke: `bash scripts/smoke-offline-flight.sh` (API + manuelle Checkliste)
- [ ] Emulator UI manuell: Pack laden + Valhalla-Status + Flugmodus-Checkliste
- [ ] `NEXT_PUBLIC_ROUTING_LIVE=1` in Deploy-Env nach Smoke (lokal ok; nicht committen)

## Honesty Fixes (Code, Aug 2026)

- [x] CSC: kein Fake-SoC/Power — nur Kadenz/Tempo; SoC zeigt „LDI folgt G-1“
- [x] CSC Measurement: Wheel/Crank nach BLE-Spec (kein Kadenz→Speed-Hack)
- [x] Sensor-Stub nur Debug + `AETHER_SENSOR_SIM`
- [x] FIT: Null-Island-Punkte übersprungen
- [x] Web Ride: Sensor/Bosch klar als Simulation
- [x] Web Post-Ride: Heatmap Contribute
- [x] Web Profil: Konto löschen
- [x] Consents default alle aus (Opt-in)
- [x] Shop/Offline/Elevation ehrlich gelabelt
- [x] Release: Demo-Touren/Seeds/Freiburg-Fallback fail-closed (`AppConfig.allowDemoContent`)
- [x] Release-API-Default → `https://aetherride.vercel.app` (Override via `API_BASE_URL`)
- [x] Datenschutz-Seite `/legal/datenschutz` + Profil-Link
- [x] Crash-Reporting-Scaffold (Sentry via `SENTRY_DSN`)
- [x] Release Signing via `android/key.properties` + R8 minify
- [x] CI: `.github/workflows/flutter-mobile.yml`
- [x] R8-Fix 09.08.2026: Play-Core-Split-Install-Klassen (`proguard-rules.pro`) — Release-Build war rot, jetzt grün + CI-Job `release-build` baut `bundleRelease` mit
- [x] FGS-Verhalten Android 14 (API 34) verifiziert: Start aus Foreground erlaubt, Service+Notification überleben Backgrounding (Details: `MARKET_READY_PLAN.md` P1-6). Android-15/16-Emulator zweimal an Emulator-eigenem SurfaceFlinger-Crash gescheitert — **echtes Android-15-Gerät vor Launch nachziehen**
- [x] POST_NOTIFICATIONS Runtime-Request vor Ride-Start ergänzt (`permission_handler`) — ohne war die Ride-Notification auf Android 13+ unsichtbar

## Outdooractive / Mapillary

- [x] OA Keys lokal → Live-Pfad (List + Detail-Hydration)
- [x] Mapillary über `/api/trail` live — Token server-seitig

## LDI / Bosch (Hardware)

- [ ] NDA / Partner-Zugang (Gates G-1 in `packages/ble_core/README.md`)
- [x] Kein Fake-SDK in Release — Ride-UI „LDI folgt G-1“; Sim nur Debug

## Community-Heatmap

- [x] `heatmap_cells` SQL live
- [x] Contribute Mobile + Web (Post-Ride)
- [ ] Mehrere Test-Accounts mit Consent → Zellen erst ab k≥5 sichtbar
