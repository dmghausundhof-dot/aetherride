# AetherRide – Vollständige Referenz-Implementation

**Intelligente All-in-One-App für Mountainbike, Enduro, Gravel, E-Bike & Wandern**

Version 1.0 · Spec-konform · Offline-First · Outdoor Design System

## Implementierte Bausteine

### 1. Native-ready Sensor Fusion + Bosch LDI
- `src/lib/sensor/SensorFusion.ts`  
  Hochfrequenz-Fusion (Complementary Filter, Impact-Detection, Flow-Score).  
  Web-Simulator + klare Contract für Flutter Platform Channels / CoreMotion / SensorManager.
- `src/lib/ble/BoschLDI.ts`  
  Offizielles Bosch Live Data Interface (Spec Mai 2026, read-only BLE).  
  Alle dokumentierten Datenpunkte + Web-Simulator. Native-Implementierung 1:1 austauschbar.

### 2. MapLibre + Offline-Routing-Architektur
- `src/components/MapView.tsx` – MapLibre GL mit OSM-Tiles + Live-Track.
- `src/lib/routing/profiles.ts` – Sportartspezifische Profile (MTB AM, Enduro, Gravel, Road, E-Bike, Hiking) mit OSM-Tag-Präferenzen.
- Produktion: PMTiles + self-hosted OSRM/Valhalla mit custom Profiles.

### 3. Backend-Grundlage
- Next.js API Routes (`/api/orders`, `/api/health`)
- Vorbereitet für PostgreSQL + TimescaleDB (Time-Series Sensor/Ride) + pgvector.
- Orders-Persistenz + Cart-System.

### 4. Shop als Tür zu Shopify
- Kein In-App-Warenkorb — Kasse nur bei Shopify
- Gateway-Seite „Der Laden“ mit ehrlicher Inhaber-Vorschau, falls der Store gesperrt ist
- Passende Teile aus der Werkstatt, Merch unabhängig vom Rad

### 5. Garage & Setup P0 (Spec F-GAR / F-SET)
- Katalog-/Basis-/Import-Anlage mit OEM-Vorbefüllung
- Pflicht-Slots, Historie (`installed_at`/`removed_at`), Verschieben inkl. Laufleistung
- Regelbasierte Kompatibilitäts-Engine (4 Urteile, Begründungskette, Drehmomente aus Docs)
- Wartungslog + Intervalle (RockShox/Fox/Industriepraxis)
- Immutable Setup-Versionen + Bracketing-Auswertung (1,5× gepoolte SD)
- Post-Ride-Feedback ≤3 Taps (F-SET-004)

### 6. Marktreife P1 (Spec Free/Pro + Shop + Prognosen)
- **F-GAR-004** SVG-Bike-Silhouetten mit Hotspots (gepflegt / Wartung / fehlt)
- **F-GAR-005 P1** Verschleißprognose als Spanne (Velopit, BIKE Magazin, Bavarian Bike, Linexo)
- **F-SET-002** Setup-Vorlagen: Fox/RockShox OEM-Gewichtstabellen + Editorial-Presets (als Ausgangspunkt gekennzeichnet)
- **F-SEN-005** Live-Hinweise ≤6 Wörter + SpeechSynthesis; Details nur im Stand
- **F-NAV-004** Routenvorschläge mit genau 3 Begründungsfaktoren
- **F-EBK-004 P1** Physik-Reichweite + Kalman-artige Selbstkalibrierung (Spanne, nie Punktwert)
- **F-AI-002** Rider-Profil erklärbar & korrigierbar (Terrainanteil, Fahrstil-Indikatoren)
- **F-SHP-001/003** Affiliate-Shop mit Kompat-Urteil; Checkout = Partner-Weiterleitung
- **Spec 1.4** Free/Pro-Paywall (1 Bike Free; Multi-Bike, Bracketing, Reichweite = Pro)

### 7. Phase 2 / P2 + Rest (Heatmap, Trail, Chat, Assist, Export)
- **F-NAV-005** Heatmap mit k≥5, OSM-Snap-Demo, Privacy-Trim, Kaltstart-Hinweis (Strava-Lehre)
- **F-NAV-006** Trail View Mapillary CC BY-SA Attribution + Nutzerfotos mit Heading
- **F-NAV-007** Höhenprofil mit Oberflächen-/Scale-Bändern; Lücken nicht interpoliert
- **F-EBK-005** Assist-Modus-Log (Schätzung gekennzeichnet, keine Steuerung)
- **F-SHP-002** Anlassbezogene Produktempfehlungen mit Datenpunkt-Zitat
- **F-AI-001/004** KI-Chat mit Tool-Zugriff + Numeric-Guard
- **F-ACC-003/005/006/007** GPX/JSON-Export, Privacy-Zonen, Einwilligungen, Familien-Garage
- **F-SHP-003 P3** Marketplace mit EU-Pflichtangaben + Stripe Checkout; Affiliate bleibt Default

### Weitere Kernfeatures
- Live-Ride mit Sensor + Bosch + Karte
- Post-Ride-Analyse + KI-Setup-Empfehlungen
- Dark Mode Outdoor Design System

## Starten

```bash
cd aetherride
npm install
npm run dev
```

→ http://localhost:3000 (mobil optimiert)

## Architektur-Übersicht

```
src/
├── app/                 # Next.js App Router (Screens + API)
├── components/          # UI (HofThresholdNav, MapView, …)
├── lib/
│   ├── sensor/          # SensorFusionEngine + WebSimulator
│   ├── ble/             # Bosch LDI Client Contract
│   ├── routing/         # Sportart-Profile
│   └── utils.ts
├── store/               # Zustand (App + Cart)
└── types/               # Spec-konforme Datenmodelle
```

## Mobile (Flutter-Gerüst)

Scaffold unter [`mobile/`](mobile/) — Spec §5 (Riverpod, Offline-First, native Hot-Path-Contracts).

```bash
cd mobile
./tool/bootstrap_platforms.sh   # einmalig: android/ + ios/
flutter pub get && flutter run
```

Tabs: Der Hof · Karte · Werkstatt · Laden. Ride-HUD nur in der App.

## Produktionsschicht (Supabase · Stripe · Grok)

Bereits verdrahtet auf Branch `feat/production-supabase-stripe`:

- **Supabase** Projekt `aetherride` (EU): Auth, profiles, sync_snapshots, orders, chat_usage + RLS
- **Stripe**: AetherRide Pro 6,99 €/Mo + 59,99 €/Jahr; Marketplace Checkout; Webhook → `/api/webhooks/stripe`
- **Grok** (`/api/chat`) hinter Numeric-Guard; Free 5/Tag · Pro 50/Tag (Monatskappe 40/500)
- Env-Vorlage: [`.env.example`](.env.example)

**Kein Vercel-Deploy in diesem Repo-Schritt** — Deploy später mit dem vorgesehenen Vercel-Account. Setup:

1. `.env.example` → `.env.local` (Service Role + Stripe + `XAI_API_KEY` setzen)
2. Repo auf dem richtigen Vercel-Account importieren und Env setzen
3. Stripe Webhook auf `/api/webhooks/stripe`
4. Supabase Auth Redirect: `https://<domain>/auth/callback`

## Mobile (Flutter)

Emulator: AVD **`aether_api34`** (API 34). API 36-AVDs sind in diesem Projekt unzuverlässig.

API gegen Host-Next: `API_BASE_URL=http://10.0.2.2:3001` (Next oft auf Port 3001).

Keys aus `.env.local` als `--dart-define` (sonst Free-Basemap OpenFreeMap, kein demotiles):

```bash
./scripts/mobile-with-env.sh run -d emulator-5556
# oder APK:
./scripts/mobile-with-env.sh apk
```

Definiert u. a. `STADIA_API_KEY`, `PMTILES_URL`, `SUPABASE_*`, `API_BASE_URL`.
Style-Priorität: Prefs-PMTiles-Style → compile-time PMTiles → Stadia → OpenFreeMap liberty.

## Web-Produktion (Demo-Gaps Schnitt 1)

- Legal: Env `NEXT_PUBLIC_LEGAL_*` + `/legal/impressum` · `/legal/widerruf` (ohne Impressum: Marketplace-Checkout gesperrt)
- Export: GPX + FIT Download unter Datenschutz
- Katalog: `npm run catalog:import` ← `data/catalog/extra-seed.json` → Yeti/Orbea
- Sync: LWW mit `updated_at` + Pull nach Login
- Discover: Heatmap aus eigenen Rides, Elevation `/api/elevation`, Mapillary `/api/trail`

## Routing-Infra (Schnitt 2)

- `/api/route` → Valhalla (`VALHALLA_URL`) oder OSRM (`OSRM_URL`); ohne Env Demo-Geometrie
- MapLibre: `NEXT_PUBLIC_PMTILES_URL` (pmtiles://) oder OSM-Raster-Fallback
- Discover → „Route berechnen“ zeichnet Engine-Polyline
- Demo-Offline-Graph: nur `mobile/assets/routing/offline_graph.json` (Sync: `./scripts/routing/sync-demo-graph.sh`)
- Region-Builds unter `data/routing/dist/` sind gitignored (~GB); Manifeste/Region-Configs bleiben im Repo

## Was gehört (nicht) ins GitHub-Repo

**Committen:** `src/`, `mobile/` (Quellcode), `scripts/`, `data/catalog/oem-seed.json` + `extra-seed.json`, `data/routing/{regions,manifests}/`, `.env.example`, Locks.

**Lokal behalten / ignoriert:** `.env.local`, `.vercel/`, `node_modules/`, `.next/`, `data/routing/dist/`, Build-Artefakte, `Claude INhalte/` (Spec-Entwürfe), synthetische `bulk-seed*.json`.

### Launch-Checkliste (Prozess)

Lokal abhaken: `./scripts/ops-checklist.sh`

```bash
npm run smoke:web:prod          # Routing, Geometry, Sync-401, env-check, well-known
npm run smoke:sync-auth         # optional mit SMOKE_EMAIL + SMOKE_PASSWORD
npm run smoke:deeplink          # App Links paths + geometry
npm run smoke:deeplink:adb      # + adb VIEW (Gerät nötig)
bash scripts/ops-android-auth.sh
```

- [ ] **Git push** → Vercel Prod (damit `/api/ops/env-check` live ist)  
- [ ] Vercel: `NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS` (+ Play App-Signing-SHA)  
- [ ] Vercel: `NEXT_PUBLIC_IOS_TEAM_ID`  
- [ ] Device Deep-Link: `aetherride://ride?route=r-heidelberg-city`  
- [ ] DSFA abgeschlossen  
- [ ] A11y-Audit ohne kritische Befunde  
- [ ] Offline-Regression Flugmodus  
- [ ] Store-Richtlinien-Vorprüfung  
- [ ] Play Produkt `aetherride_pro_monthly` + License Tester + `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`  
- [ ] Routing-Env live (`VALHALLA_URL` / `OSRM_URL` / `GRAPHHOPPER_API_KEY`) — sonst Demo-Geometrie  
- [ ] Nach erfolgreichem Smoke: `NEXT_PUBLIC_ROUTING_LIVE=true` (Discover-Banner erst dann weg)  
- [ ] Partner-Tokens: Mapillary, Outdooractive, Strava OAuth (`/api/strava` + `/api/strava/callback`)  
- [ ] `NEXT_PUBLIC_LEGAL_*` für Marketplace (Affiliate braucht das nicht)  
- [ ] Vercel-Deploy + Stripe Webhook Prod  
- [ ] Mobile: `./scripts/mobile-with-env.sh` + Emulator **aether_api34**  
- [ ] Bosch LDI Hardware (G-1) — bewusst Ops/HW  

### UX-Fixes (Code, Aug 2026)

- First-Run Onboarding (Sport → Gewicht → Bike/Freeride)
- AddBikeWizard Mode-Param (Katalog/Basis/Import)
- Freeride ohne Garage-Bike
- Discover: Seeds ohne Bike, City-Profil, neutraler Default
- Shop Empty ohne Negativ-Spam
- Rider-UI ohne Spec-/Engine-Jargon; Profil Einfach/Advanced
- BikeChip auf Home/Discover
- Ehrlicher Routing-Status (`/api/routing/status`), Demo-Fallback bei Live-Fehler
- Strava-UI erst bei OAuth-Config; Shop „Beispielkatalog“; Heatmap ohne Fake-Community
- Mehr Discover-Seeds (City/Gravel/Road DACH)
- Kein Auto-Demo-Bike/Ride nach Onboarding; Spec-IDs aus Rider-UI
- Tour-Ideen klar gelabelt; Partner-Copy ehrlich (OA/TF/Mapillary)
- Shop: Urteile ohne Rule-Codes; Visuals ohne Indigo-Bias
