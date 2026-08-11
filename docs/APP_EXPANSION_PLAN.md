# AetherRide — Ausbau-Plan (App + Touren-Content)

Stand: 2026-08-11 · Multi-Sport (MTB · Gravel · Rennrad · City · E-Bike)

---

## 0. Ist-Zustand (kurz)

| Bereich | Heute |
|---------|--------|
| Öffentliche Touren (`publicTours.ts`) | ~46 redaktionelle Ideen / Pins (Multi-Sport DACH + EU) |
| Live-Routen | GraphHopper/OSRM/OA/OSM je nach Env & Standort |
| Mobile | Offline-first Garage/Ride, Touren mit Sport-Chips, Near-me |
| Web | Touren/Planen, Near-me Hero, SEO `/tours/*` |
| Content-Lücke | Dünne Dichte pro Region; wenig City/Rennrad vs. MTB-Ideen; Geometrie oft erst live |

---

## 1. Touren-Content — mehr, ehrlicher, multi-sport

### 1.1 Content-Ziele (90 Tage)

| Meilenstein | Ziel | Messbar |
|-------------|------|---------|
| **T1** Woche 1–2 | **80** Public Tours | ≥ 8 Regionen × 10 Touren |
| **T2** Woche 3–4 | **150** Tours | 5 Disziplinen × ≥ 25 |
| **T3** Woche 5–8 | **300** + Live-Geometry-Overrides für Top-50 | SEO + App-Katalog fühlt sich „voll“ an |
| **T4** Woche 9–12 | UGC-Pipeline (User speichert → optional „öffentlich vorschlagen“) | 1. Community-Schleife |

**Disziplin-Mix (Soll-Anteil im Katalog):**

| Sport | Anteil | Beispiele |
|-------|--------|----------|
| Rennrad | 25 % | Alpenpässe-Ideen, Bodensee, Radwege, City-Loops sportlich |
| Gravel | 25 % | Forst, Weinberge, Fernradwege-Mix |
| MTB | 20 % | Trails, Parks, Enduro-Ideen (ehrlich als „Idee“) |
| City / Urban | 15 % | Pendeln, Flussradwege, 15–40 km Runden |
| E-Bike / E-Trekking | 15 % | Touring mit Höhenmeter-Cap, Reichweiten-Hinweis |

### 1.2 Content-Quellen (Priorität)

1. **Redaktionell** (`publicTours.ts` + `tourGeometryOverrides`) — Qualität, SEO, Brand  
2. **OSM Relations** (`/api/osm-routes`) — Skalierung, Attribution, live  
3. **Outdooractive** (wenn Keys live) — Hydration, nicht sole source  
4. **GPX-Imports** (intern kuratiert) — echte Tracks → Override-JSON  
5. **User-GPX** (später, mit Review) — Volumen  

**Honesty-Regeln (nicht brechen):**

- Keine Fake-Community-Heatmaps  
- „Idee“ vs. „vermessener Track“ klar labeln  
- Keine Demo-Seeds in Release-Mobile  

### 1.3 Operatives Content-Playbook

```
Woche: 1 Region wählen (z.B. Rhein-Neckar, Schwarzwald, München, Alpen-Nord)
  → 2× Rennrad, 2× Gravel, 2× City, 2× MTB, 2× E-Bike
  → Center-Pin + Summary/SEO-Text
  → Optional: GPX → tour-geometry-overrides.json für Top-Touren
  → Smoke: GET /api/tours/geometry?id=… + Web /tours/[id]
  → Mobile Deep Link aetherride://tours/<id>
```

**Pipeline-Skripte (bauen, falls noch dünn):**

| Script | Zweck |
|--------|--------|
| `scripts/tours/import-gpx-batch.mjs` | GPX-Ordner → Override-JSON + Metadaten-Stub |
| `scripts/tours/osm-relation-seed.mjs` | OSM relation IDs → PublicTour draft |
| `npm run smoke:tours` | alle Public-IDs geometry ≥ 2 Punkte |

### 1.4 Region-Roadmap (Content)

| Phase | Regionen |
|-------|----------|
| A | Rhein-Neckar, Freiburg/Schwarzwald, Stuttgart, Karlsruhe |
| B | München, Bodensee, Pfalz, Eifel |
| C | Tirol / Wilder Kaiser, Elsass, Vosges |
| D | EU-Highlights (Bretagne, Provence, Annecy) — SEO, nicht DACH-only |

---

## 2. App-Ausbau — Produkt-Roadmap

### Phase P0 — Trust & Launch (2–4 Wochen)

| ID | Thema | Ergebnis |
|----|--------|----------|
| P0-1 | Play Internal Track + echte Billing-Verify | Pro kaufbar ohne Trusted-Token-Text |
| P0-2 | App Links SHA + Strava Keys | Web→App, Export-Loop |
| P0-3 | Push + Deploy aller Multi-Sport-Commits | Prod = Code-Stand |
| P0-4 | Sentry DSN | Crash-Sicht |
| P0-5 | Version `0.9.0` + Store Listing DE | Screenshots multi-sport |
| P0-6 | **+50 Public Tours** (T1) | Katalog fühlt sich nicht leer an |

### Phase P1 — Parität Discover/Nav (4–8 Wochen)

| ID | Thema | Ergebnis |
|----|--------|----------|
| P1-1 | Near-me Default überall (GPS → 3 Vorschläge) | Komoot-ähnlicher Einstieg |
| P1-2 | Multi-Region Offline-Packs (≥3 DACH) | 1-Tap Download UX |
| P1-3 | Auto-Reroute default on nach Smoke | Nav-Qualität |
| P1-4 | Stadia/PMTiles in Release-Builds | Kartenästhetik |
| P1-5 | Tour-Detail: Hero-Stats, Technik einklappen | Weniger Engineer-UI |
| P1-6 | **+150 Tours + Top-50 Geometry Overrides** | Content-T2/T3 |

### Phase P2 — Vorbeiziehen (Garage × Post-Ride)

| ID | Thema | Ergebnis |
|----|--------|----------|
| P2-1 | Post-Ride Setup-Coach v2 (1 klare Empfehlung) | Unique vs. Strava |
| P2-2 | Garage Tabs: Übersicht \| Setup \| Teile \| Wartung | Weniger God-Screen |
| P2-3 | „Bike health“ Score auf Home | Habit Loop |
| P2-4 | Share-Card Setup+Ride (ohne Social-Netz) | Viraler Hook |
| P2-5 | Progressive Fahrwerk-UI (nur Federgabel-Sports) | City/Road schlank |

### Phase P3 — Wachstum (später)

| ID | Thema | Ergebnis |
|----|--------|----------|
| P3-1 | UGC Tour-Vorschläge + Moderation | Content-Skalierung |
| P3-2 | Collections teilen (Deep Link) | Social light |
| P3-3 | Health Connect / HR / Power (opt-in) | Sensor-Ökosystem |
| P3-4 | iOS Parität | Store-Volumen |
| P3-5 | Bosch LDI nur nach G-1 | E-Bike-Differenzierung |

**Bewusst nicht kopieren:** Strava-Feed, Kudos, Segmente-Rennen.

---

## 3. Architektur-Hebel für Content bei Skala

```
[Redaktion / GPX] → publicTours + overrides (Git)
[OSM Overpass]    → /api/osm-routes (live, cached)
[OA API]          → enrich, not sole catalog
[User save]       → Drift → Sync → optional public queue (P3)
[App Touren]      → Sport-Chip filter → Near-me + Katalog
[Web /tours/id]   → SEO + Deep Link → App
```

**Caching:** CDN für geometry; Edge-Cache OSM 15–60 min; Overrides immer first.

---

## 4. KPIs (Ausbau steuern)

| KPI | Ziel 90 Tage |
|-----|----------------|
| Public Tours live | ≥ 150 |
| Geometry-Hits (pts≥2) Smoke | ≥ 95 % der Top-50 |
| Time-to-first-ride (Onboarding) | &lt; 60 s |
| Crash-free sessions | ≥ 99 % |
| Play Internal Testers | ≥ 20 aktive |
| Disziplin-Nutzung (Onboarding) | keine Disziplin &lt; 10 % |

---

## 5. Nächste konkrete Arbeitspakete (Reihenfolge)

1. **`git push`** offener Multi-Sport-Commits  
2. **APK Release-Track** (optional `--release` + Upload-Key) nach Debug-Feedback vom S25  
3. **Content-Sprint Region A:** 10 neue Tours in `publicTours.ts` (Mix Disziplinen)  
4. **Smoke-Script** `npm run smoke:tours` über alle IDs  
5. **Play Internal + SHA**  
6. **Post-Ride Coach v1 polish**  

---

## 6. Device-Install Notiz

- Package: `com.aetherride.aetherride_mobile`  
- Debug-APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`  
- API: `https://aetherride.vercel.app`  
- Rebuild:

```bash
cd mobile
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://aetherride.vercel.app \
  --dart-define=SUPABASE_URL=… \
  --dart-define=SUPABASE_ANON_KEY=…
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
