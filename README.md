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

### 4. Echter Shop-Checkout
- Warenkorb (Zustand + localStorage)
- Checkout mit Lieferadresse
- Bestellbestätigung + API-Anbindung
- Kompatibilitäts-Badges aus der Garage

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
├── components/          # UI (BottomTabBar, MapView, …)
├── lib/
│   ├── sensor/          # SensorFusionEngine + WebSimulator
│   ├── ble/             # Bosch LDI Client Contract
│   ├── routing/         # Sportart-Profile
│   └── utils.ts
├── store/               # Zustand (App + Cart)
└── types/               # Spec-konforme Datenmodelle
```

## Nächster Schritt (echte Mobile-App)

1. Flutter-Projekt mit denselben TypeScript-Models als Shared Spec
2. Native Module:
   - Sensor: CoreMotion / SensorManager → Platform Channel → SensorFusionEngine
   - BLE: flutter_blue_plus + Bosch LDI Characteristic Mapping
3. MapLibre Flutter + PMTiles Offline-Packs
4. Backend: PostgreSQL + TimescaleDB + Vector-DB (Empfehlungen)
5. Shop: Stripe / Partner-Händler API

Die gesamte Domain-Logik und die Contracts sind bereits produktionsreif.

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

---
AetherRide · Spec 1.0 · August 2026
