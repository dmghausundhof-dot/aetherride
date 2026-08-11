# Build: Discover 60-Min Rundkurse — D-60-01/02/03/05 (Android Flutter, thin P0)

Repo worktree: `/home/luka/Projects/aetherride-wt-discover-60` · Branch: `feat/discover-60min-loops` · Open a PR when done.

Spec: UX `discover-60min-loops-v1.md` (job: one-hour loop near me → Losfahren). Seeds JSON will be copied into the repo if missing — see Acceptance.

## Goal
Default Discover lens = **~60 min loops** with honest ⟲ + primary **Losfahren** into existing Ride/nav. Reuse Discover filters (`_minutes`, `_loopOnly`, `_startRide`) — change defaults + UI, do not rebuild routing.

## In scope
### D-60-01 Duration Lens
- Default `_minutes` → **60** (was 90)
- Chip presets: ~45 · **~60 (default)** · ~90 · 2–3h · egal (or keep dropdown but default 60)
- Filter band for "~60": prefer 45–75 when sorting/filtering for default lens
- Sport-aware: if rider sport is touring-like and easy to detect from existing profile, default may be 120–180; else 60. If unclear, default 60.

### D-60-02 Loop Card + Losfahren
- Show ⟲ when `routeShapeOf` == loop OR seed `is_loop`
- Primary CTA **Losfahren** on card/sheet (not only after detail)
- Do not label A→B as Rundkurs

### D-60-03 Seeds fallback
- Bundle Berlin seeds (copy from prompts/`naehe-peek-seeds-berlin-v1.json` into e.g. `mobile/assets/seeds/` or existing asset path) including `is_loop`, `duration_band`, `poi_stops`
- If OA/OSM empty or no location: show seeds under label „In deiner Region“
- Wire into Discover suggestion list

### D-60-05 Deep-Link
- Support start intent: e.g. query/extra `start=1` + loop id → set ActiveRoute + navigate to Ride (Nav entry). Document the Android/deeplink path used.

## Out of scope
D-60-04 full Stops timeline UI (may show poi_stops count on card if cheap) · D-60-06 POI corridor API · Nav-Wow HUD (other branch) · Web Discover parity unless trivial

## Done when
- PR on `feat/discover-60min-loops`
- Default lens feels ~60 Min; 3 Berlin loops visible offline/fallback; Losfahren starts ride
- No mid-ride/discover paywall

German UI. Investigate `discover_screen.dart` idiomatically.
