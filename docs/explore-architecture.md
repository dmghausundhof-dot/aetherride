# Explore Workspace — Vereinheitlichung Discover + Planner

## Konkurrenz-Analyse (Web)

| Anbieter | Discover | Planen | Einheit |
|----------|----------|--------|---------|
| **Komoot** | Collections, Region, Sport-Tabs | Route Planner (Web stark) | Ein Map-First Shell; Sport-Profil steuert beides |
| **RideWithGPS** | Explore library | Flagship Desktop Planner | Planner = Produktkern; Discover speist denselben Editor |
| **AllTrails** | Trail catalog + filters | Custom route (tier) | Trail detail → navigate; less multi-via on web |
| **Strava** | Segments / heat | Route builder (web) | Social feed ≠ planner; heat informs routes |

**Muster der Sieger:** Eine **Desktop-Map + Side-Panel**, ein **Routing-Profil**, ein **Route-Objekt**, das man speichern, teilen und in die App schieben kann. Kein zweites „Mini-App“-UI.

## FlowLine-Zielbild (besser)

```
┌─────────────────────────────────────────────────────────────┐
│ Top-Nav: Explore | Library | Garage | Shop | App            │
├──────────────┬──────────────────────────────────────────────┤
│ Panel tabs:  │                                              │
│ Touren       │              VOLLKARTE                       │
│ Hier & Jetzt │     Heatmap / Surface / Route layers         │
│ Planen       │                                              │
│ Bibliothek   │                                              │
│              │                                              │
│ Filters      │                                              │
│ Near-me card │                                              │
│ Draft stats  │                                              │
│ Save / App   │                                              │
└──────────────┴──────────────────────────────────────────────┘
         │
         ▼  PlanDraft (shared)
    /api/route · /api/tours/geometry · OSM/OA enrich
         │
         ▼  Sync payload savedRoutes
    App Deep Link aetherride://ride?route=
```

### Prinzipien

1. **Ein Draft** (`PlanDraft` in `planDraft.ts`) — Discover und Planner mutieren dasselbe Modell.
2. **URL ist State** — `?panel=plan&lat=&lng=&profile=road&route=id` (siehe `lib/explore/workspace.ts`).
3. **Quellen-Schichten** (ehrlich): editorial override → live engine → OSM relation geometry → OA enrichment (keine Fake-Community).
4. **Hier & Jetzt** — GPS/Suche → `/api/tours/geometry?lat&lng` (neu), speichern, App.
5. **Bike-Intelligence** — aktives Garage-Bike setzt Default-Profil (USP vs. Komoot).
6. **Web ≠ Nav** — „In App“ immer Bridge; nie Browser-GPS-Hot-Path.

### Migrationspfad

| Phase | Aktion |
|-------|--------|
| Done | Shared `workspace.ts`, NearMe card, geometry near API |
| Next | Discover-Page: panel=plan|nearby|library; Planner redirect → `/discover?panel=plan` |
| Later | Extract MapShell component; delete duplicate planner page UI |

### Warum besser als Komoot/RWGPS

- Multi-Bike + Setup-Kontext im selben Workspace-Flow.
- Honesty labels (editorial / osrm / graphhopper).
- Sync v2 mit Konflikt-UI.
- Open OSM routes + curated catalog + live near-me in one shell.
