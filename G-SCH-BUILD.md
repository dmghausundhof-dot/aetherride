# Build: Garage Bike Schema G-SCH-01…05 (Web + Flutter)

Worktree: `/home/luka/Projects/aetherride-wt-garage-schema` · Branch: `feat/garage-bike-schema` · Open PR when done.

## Spec
Full UX: `garage-bike-schema-spec-v1.md` (copied into worktree). Refs: `aetherride-ux/bike-schema-refs/` (schema-ref-*.svg/png + schema-gravel/trail hotspots + manifest).

## Goal
Replace stick-polygon `BikeSilhouette.tsx` with real diamond-frame SVGs. Same assets Web + Flutter. Keep maintenance status dots API (ok/missing/maintenance). QA: untrained viewer recognizes road/gravel/mtb/city in <2s.

## Implement
### G-SCH-01 Assets
- Prod assets under shared path e.g. `public/garage/silhouettes/` (web) + `mobile/assets/garage/silhouettes/` (flutter) — same SVG filenames: `road.svg`, `gravel.svg`, `mtb.svg`, `city.svg`
- Start from UX ref SVGs; clean to viewBox consistent (prefer Spec: `0 0 1000 500` or `0 0 400 240` — pick one and stick to it for all 4)
- Diamond tubes: HT/TT/ST/DT/CS/SS, fork to front hub, stays to rear hub, BB+crank, sport cues (tire stroke, bars, shock, fenders/rack for city)

### G-SCH-02 Hotspots
- Anchor map JSON per template (or data-* in SVG): slot → {x,y}; invisible hit r≥22 (≥44pt); visible status dot smaller
- Reuse status colors from current BikeSilhouette

### G-SCH-03 Mapper
- BikeCategory → template + layers (hardtail hides shock; eBike shows motor/battery)

### G-SCH-04 Web
- Replace/rewrite `src/components/garage/BikeSilhouette.tsx` (or new `BikeSchema.tsx` + swap imports) to render SVG + hotspot overlays; remove debug `Schema · {drawKind}` label

### G-SCH-05 Flutter
- Garage screen parity with flutter_svg + same assets; empty-state painter can stay separate or reuse simplified asset

## Out of scope
G-SCH-07 overlays P1; Nav-Wow; Shop; full 8-kind explosion — 4 templates enough

## Done
- PR with screenshots note / how to QA
- Tests if any catalog/schema helpers added
- German UI if any new copy
