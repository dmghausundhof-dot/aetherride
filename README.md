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

### Weitere Kernfeatures
- Multi-Bike-Garage (Komponenten, Setups, Historie)
- Live-Ride mit Sensor + Bosch + Karte
- Post-Ride-Analyse + KI-Setup-Empfehlungen
- Discover mit Match-Score
- Rider-Profil
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

---
AetherRide · Spec 1.0 · August 2026
