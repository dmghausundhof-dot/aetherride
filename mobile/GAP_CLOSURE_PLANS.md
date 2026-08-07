# Android Gap-Closure Plans — Status

Ziel: Jede dokumentierte Web↔Android-Lücke schließen (sinnvoll im Produktkontext).
Bosch LDI echtes Protokoll bleibt hinter G-1; UX/Shell geschlossen.

## Plan A — Shell / Profil / Legal / Sync-Identität — DONE
- ProfileScreen: Rider-Profil, Familie, Sync, Stripe-Portal, Legal-Links
- SyncPayload: riderProfile + familyRiders lesen/schreiben
- Dark Outdoor Theme Default

## Plan B — Home echt — DONE
- Wetter `/api/weather`, Suggestions aus Saved Routes + Fingerprint + Evidence-Zeile
- SetupFingerprint, Wartung→Shop, Onboarding-Karten, Profil-Avatar

## Plan C — Garage-Parität — DONE
- Foto (image_picker), Sag-Guide, Fingerprint, Odometer-Import
- Wear→Shop, Setups/Bracketing Sheet bleibt

## Plan D — Ride — DONE
- MapLibre Live-Layer + Track/Route-Polylines
- Auto-Sunlight (Sensor/Fallback), CSC vs LDI G-1 Klartext

## Plan E — Discover — DONE
- Outdooractive-Fetch + Seeds-Fallback, FilterChips, Elevation-Mini-Chart
- Heatmap-Consent-Pfad, Trail-View Mapillary-Hinweis

## Plan F — Shop — DONE
- Detail-Sheet, Compat-Verdict, Wishlist

## Plan G — Polish — DONE
- Post-Ride MetricBars/Confidence, Chat-History, Privacy GPS-Default
- Design Dark Outdoor

## Bewusst nicht „echt“ schließbar ohne Ops/Hardware
- Bosch LDI Protokoll (G-1)
- Play Console Produkt + Google Verify 2A
- Valhalla-Tiles ohne Docker-Build
- Mapillary-Full-Trail ohne Token

## Follow-up (nach Plans A–G) — DONE
- Discover: geroutete Tour-Geometrie um OA/TF-Center (APIs liefern keine Polylines)
- Heatmap aus lokalen Rides + Privacy-Zonen (`domain/routing/heatmap.dart`)
- Bracketing-Auswertung aus Ride-Feedback (`runsFromRides`)
- Trailforks-Pins auf Discover-Karte (tippbar → Deep-Link)
- `commerceMode` Sync + Profil-Umschalter; aktiver Familien-Fahrer

## Follow-up 2
- Trail View in-app via `/api/trail` (Demo ohne Token)
- TTS Spec 400/150/30 + Engine-Steps (`nav_announce.dart`)
- Live-Hints F-SEN-005 während Ride
- Chat mitsendet bike/rides/profile
- SyncEngine flush pending Ride-Chunks
- Export Share-Sheet (GPX/FIT/JSON)
- `activeFamilyRiderId` Sync + `effectiveWeightKg`
