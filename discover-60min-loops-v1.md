# Discover · 60-Minuten-Rundkurse v1
**Input:** Luka via CEO · Discover + Nav-Wow · 2026-08-11  
**Rahmen:** Near-me / Nähe-Peek · „Losfahren“ ohne Reibung · Claim ohne Abo-Falle · POIs/Highlights entlang der Route

---

## Job to be done
„Ich habe eine Stunde — zeig mir eine runde Tour hier, mit netten Stopps, und lass mich sofort losfahren.“

Nicht: lange Wochenend-Etappen als Default. Lange Touren bleiben filterbar, aber **Primary Lens = ~60 Min Loops**.

---

## 1) Wie die 60-Min-Karte / Liste aussieht

### Entdecken — Default Lens
```
┌─────────────────────────────────────┐
│ [🔍]  [⏱ ~60 Min ▾]  [Filter]       │  Duration chip DEFAULT an
│                                     │
│         ╔══ MAP ══╗                 │
│         ║ ○ loops ║                 │  Pins = Rundkurs-Centroid
│         ║ ★ POIs  ║                 │  kleine POI-dots entlang hover/select
│         ╚═════════╝                 │
│           [Karte|Liste]             │
│ ┌─────────────────────────────┐     │
│ │ Peek: 8 Rundkurse ~60 Min   │     │
│ │ ┌ Card ┐ ┌ Card ┐           │     │
│ └─────────────────────────────┘     │
└─────────────────────────────────────┘
```

**Duration Chip Presets:** `~45` · **`~60` (default)** · `~90` · `2–3 h` · `egal`  
Default nach Onboarding Sport=Stadt/Gravel: **~60**. Touring-Default darf `2–3 h` sein (Sport-aware).

### Loop Card (Liste / Sheet)
```
┌ Foto / Mini-Map Loop ─────────────┐
│ Grunewald Feierabendrunde         │
│ ⟲ Rundkurs · ~58 Min · 18 km      │  ⟲ = Loop-Glyph (Pflicht)
│ ↑120 m · Asphalt 70% Gravel 30%   │  Surface nur wenn Daten
│ ★ Café + Aussicht · 3 Stops       │  POI-count
│ [ Losfahren ]      [♡]            │  Primary = Start, nicht nur Detail
└───────────────────────────────────┘
```

**Regeln**
- Nur echte oder klar markierte **Rundkurse** (Start≈Ziel, Toleranz ~200 m) tragen ⟲
- A→B unter ~60 Min = separate Chip „Kurzstrecken“, nicht als Rundkurs lügen
- Sort Peek: Distanz zum User **dann** Duration-Fit (45–75 Min Band für „~60“)

---

## 2) POIs / Highlights entlang der Route

### Auf der Karte (select Loop)
- Route-Ribbon + **POI-Perlen** (Café, Aussicht, Wasser, Radshop, Bahn-Hub)
- Tap POI → Mini-Sheet (Name · Typ · 1 Tip-Zeile) — nicht Full-Screen

### Auf Detail
```
Stops auf der Runde
· 12 Min  Café am See
· 28 Min  Aussicht Teufelsberg
· 45 Min  Trinkbrunnen
```
Zeitangaben relativ zum Loop-Start (ETA along route) — fühlt sich planbarer an als nur km.

### API / Content (Eng-Hinweis)
- P0: kuratierte POIs an Seeds (wie Nähe-Peek Berlin seeds + tip type)
- P1: Highlights-API / OSM tags (cafe, viewpoint, drinking_water, bicycle) snapped to route corridor (~80 m)
- Nie Paywall vor POI-Sichtbarkeit

---

## 3) „Losfahren“ ohne Reibung

**Happy Path:** Card → **Losfahren** → (optional 1-Tap Offline-Hinweis wenn nötig) → Mid-Ride HUD (Nav-Wow)

| Reibung | Vermeiden | Stattdessen |
|---|---|---|
| Muss erst Detail öffnen | Primary CTA schon auf Card | Detail = Secondary „Mehr“ |
| Sport/Bike-Picker modal | Nur wenn kein Default | Sport-Toggle global greift |
| Paywall / Sync-Ask | verboten mid-start | Guardrails |
| Lange Onboarding mid-flow | — | Garage optional später |
| Permission spam | Location schon für Near-me | Wenn fehlt: „In deiner Region“ Loops |

**Deep-Link:** `/discover?lens=60&loop=<id>&start=1` → direkt Nav (Shop-Test / Landing)

---

## 4) Gap vs Komoot „kurze Runden“

| | Komoot (typisch) | FlowLine Ziel |
|---|---|---|
| Discovery Default | Oft Inspiration / Distanz / Highlight-Touren; Dauer-Filter existiert, ~60-Min-Loop nicht emotional Default | **~60 Min Rundkurs = Default-Lens** |
| Loop-Erkennung | Rundtour-Filter / Profile | ⟲ Glyph + Start≈Ziel hart in Card |
| Start Friction | Detail → Navigation (mehrere Steps) | **Losfahren auf Card** |
| POIs | Highlights stark, aber Tour-first | POI-Perlen + „Stops auf der Runde“ Timeline |
| Near-me short loops | Möglich via Filter | Nähe-Peek **vorfiltert** Duration-Band 45–75 |
| Honesty | Auto-Touren können „rund“ wirken ohne klar zu sein | Nur echte Loops als Rundkurs |

**Komoot-Parität reicht nicht:** Wir gewinnen, wenn Feierabend-Loop in **2 Taps** startet und POIs die Stunde erzählen.

---

## 5) Eng-Tickets (Vorschlag)

| ID | Titel | Prio |
|---|---|---|
| **D-60-01** | Duration Lens Chip Default ~60 + Band 45–75 | P0 Discover |
| **D-60-02** | Loop-Flag (Start≈Ziel) + ⟲ Card UI + Losfahren CTA | P0 |
| **D-60-03** | Nähe-Peek Seeds: mind. 3× ~60-Min Loops Berlin (+ POI tips) | P0.5 (erweitert T-EN-04) |
| **D-60-04** | Detail „Stops auf der Runde“ Timeline | P0/P1 |
| **D-60-05** | Deep-Link start=1 → Nav-Wow | P0 Nav+Discover |
| **D-60-06** | POI snap corridor API | P1 |

---

## 6) Seed-Erweiterung (Berlin, Richtung)
Bestehende Nähe-Seeds ergänzen um explizite ~60-Min Loops z.B.:
- Spree Feierabend ⟲ ~55 Min
- Tempelhofer Feld Runde ⟲ ~50 Min  
- Grunewald Kurz ⟲ ~65 Min  
+ Tipps als Stops (Café, Aussicht)

