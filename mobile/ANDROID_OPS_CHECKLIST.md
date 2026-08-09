# Android Ops-Checkliste (AetherRide)

Kurze Gate-/Console-Punkte — App-Code für Strava/Heatmap/Fotos ist vorbereitet.
Schnellcheck Auth/SHA: `bash scripts/ops-android-auth.sh`

## Auth / Supabase

- [x] SQL anwenden: `supabase/strava_connections.sql` (Projekt aetherride)
- [x] SQL anwenden: `supabase/heatmap_cells.sql`
- [x] SQL anwenden: `supabase/bike_photos_storage.sql` (Bucket `bike-photos`)
- [x] Deep-Link Redirects in Auth `uri_allow_list`:
  `io.aetherride.app://login-callback/`, `io.aetherride.app://strava-callback/`,
  plus `http://localhost:3000/**` / `3001/**`
- [ ] Mobile OAuth Client (Android package + SHA) in Supabase Dashboard hinterlegt  
  Package: `com.aetherride.aetherride_mobile` — SHA via `scripts/ops-android-auth.sh`
- [x] `SUPABASE_SERVICE_ROLE_KEY` lokal gesetzt (Account-Delete, Strava-Store, Heatmap)

## Strava

- [x] Upload-Route: GPX → Strava Uploads API; sonst Metadaten (Code)
- [x] Kein Fake-Track bei leerem GPS — GPX/FIT (Code)
- [ ] `STRAVA_CLIENT_ID` + `STRAVA_CLIENT_SECRET` in Env (`.env.local` noch leer)
- [ ] Strava App Redirect: `{APP_URL}/api/strava/callback`
- [ ] Optional: `STRAVA_STATE_SECRET` (sonst CLIENT_SECRET für State-HMAC)
- [ ] Nach Connect: Mobile/Web „Letzten Ride zu Strava“ testen

## Play Billing

- [ ] SKU `aetherride_pro_monthly` in Play Console angelegt
- [ ] License Tester Account für Restore/Kauf-Smoke
- [ ] Optional: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` für Server-Verify
- [ ] App Signing + Internal Testing Track

## Routing / Offline (Valhalla)

- [x] Android JNI Valhalla-linked (`jniLibs/arm64-v8a`, `GRAPH_ONLY=0`)
- [x] Region-Pack `schwarzwald-nord` mit `valhalla.json` + `tiles/` + `schwarzwald-nord.tar.gz`
- [x] Bundled `mobile/assets/routing/offline_graph.json` an Pack synchronisiert
- [x] Lokal servierbar: `GET /api/offline/packs` / `…/schwarzwald-nord/schwarzwald-nord.tar.gz`
- [x] Smoke: `bash scripts/smoke-offline-pack.sh [--push]` (API 200 + Pack ~24 MB; Push nach `/sdcard/Download/`)
- [ ] Emulator UI: Offline-Sheet → Region laden (`http://10.0.2.2:3001`) und Valhalla-Status
- [x] Basemap: Roh-`.pmtiles` abgelehnt; Style-JSON-URL (Web+Mobile gleiche Heuristik)

## Android OAuth Client (nur bei Google Sign-In)

- Google Provider derzeit **aus** — Deep-Link Redirect reicht für E-Mail/OAuth-Browser.
- Wenn Google aktiviert wird: Package `com.aetherride.aetherride_mobile` + SHA aus `scripts/ops-android-auth.sh`
- Auth-Screen: Hinweis, dass Google ohne Provider/SHA fehlschlägt

## Outdooractive / Mapillary

- [x] OA Keys lokal → Live-Pfad (List + Detail-Hydration); Discover sendet `lat`/`lon`
- [x] Mapillary über `/api/trail` live (`usingDemo: false`) — Token server-seitig, nicht `NEXT_PUBLIC`

## LDI / Bosch (Hardware)

- [ ] NDA / Partner-Zugang (siehe `packages/ble_core/README.md` Gates G-1)
- [ ] Kein Fake-SDK — Ride-UI bleibt „LDI folgt G-1“ bis Hardware da ist

## Community-Heatmap

- [x] `heatmap_cells` SQL live (Projekt aetherride)
- [ ] Mehrere Test-Accounts mit Consent → Zellen erst ab k≥5 sichtbar
