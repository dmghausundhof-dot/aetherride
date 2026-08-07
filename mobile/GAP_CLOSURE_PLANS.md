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
