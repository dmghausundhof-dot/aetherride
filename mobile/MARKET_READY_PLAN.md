# FlowLine Android — Gap-Closure zur Marktreife

Ziel: **öffentliche Play-App ohne Demo/Simulation**, verkaufbar, crash-beobachtbar.
Stand: Aug 2026 · Version-Ziel Launch: `0.9.0+…` (Internal) → `1.0.0` (Production)

---

## P0 — Launch-Blocker (jetzt / Code + Ops)

| ID | Ticket | Owner | Status |
|----|--------|-------|--------|
| P0-1 | Release-API-Default ≠ Emulator; Prod = `https://aetherride.vercel.app` | Code | **done** |
| P0-2 | Demo-Content fail-closed in Release (`allowDemoContent`) | Code | **done** |
| P0-3 | Signing via `key.properties` (kein Debug-Key in Release) | Code+Ops | Keystore generiert (lokal, `android/keystore/aetherride-upload.jks`, siehe [PLAY_CONSOLE_RUNBOOK.md](PLAY_CONSOLE_RUNBOOK.md)) · Play-Console-Upload Ops offen |
| P0-4 | R8 minify + shrink Resources Release | Code | **done** — Fix 09.08.2026: Play-Core-Split-Install-Klassen (`FlutterPlayStoreSplitApplication`) brachen R8 (`proguard-rules.pro`); Release-Build war zuvor rot |
| P0-5 | Datenschutzerklärung Seite + In-App-Link | Code | **done** (Text finalisieren Ops) |
| P0-6 | CSC BLE-Measurement korrekt parsen (kein Kadenz→Speed-Hack) | Code | **done** |
| P0-7 | Crash-Reporting-Scaffold (Sentry optional via `SENTRY_DSN`) | Code | **done** (DSN Ops) |
| P0-8 | CI: `flutter analyze` + `flutter test` + Release-Build (`bundleRelease`) | Code | **done** — `release-build` Job in `flutter-mobile.yml` baut `appbundle --release` gegen Debug-Signing, damit ein roter Release-Build (s. P0-4) nicht mehr erst manuell auffällt |
| P0-9 | Play: App Signing, Internal Track, Feature Graphic | Ops | offen — Runbook: [PLAY_CONSOLE_RUNBOOK.md](PLAY_CONSOLE_RUNBOOK.md) |
| P0-10 | Play SKU `aetherride_pro_monthly` + License Tester | Ops | offen — Runbook: [PLAY_CONSOLE_RUNBOOK.md](PLAY_CONSOLE_RUNBOOK.md) |
| P0-11 | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` auf API (kein Trusted-Token-Prod) | Ops | offen — Runbook: [PLAY_CONSOLE_RUNBOOK.md](PLAY_CONSOLE_RUNBOOK.md) |
| P0-12 | `NEXT_PUBLIC_LEGAL_*` + Privacy-Text final | Ops/Legal | offen |
| P0-13 | POST_NOTIFICATIONS Runtime-Request vor Ride-Start (Android 13+) | Code | **done** 09.08.2026 — ohne Request blieb die Ride-Tracking-Notification unsichtbar (Service lief, aber „unsichtbar“ wirkt wie kaputt); `permission_handler`, siehe `native/location_core_channel.dart` |

## P1 — Wachstum & Vertrauen

| ID | Ticket | Status |
|----|--------|--------|
| P1-1 | Google OAuth: SHA + Supabase Provider + `ENABLE_GOOGLE_OAUTH` | Ops |
| P1-2 | Strava Client-ID/Secret + Redirect live testen | Ops |
| P1-3 | Analytics hinter Consent (kein SDK ohne Opt-in) | offen |
| P1-4 | Onboarding → erster echter Ride &lt; 60s | **done** (Sport→Gewicht→GPS-Freeride) |
| P1-5 | Store Listing DE (Kurz/Lang, Screenshots Outdoor) | Ops |
| P1-6 | Background-Location Policy klären (FGS vs. ACCESS_BACKGROUND) | **verifiziert** 09.08.2026 auf Android 14 (API 34) Emulator, App kompiliert mit `targetSdk 36`: `RideLocationService`-Start aus Foreground-Kontext ist erlaubt (`ActivityManager: Background started FGS: Allowed … uidState: TOP`), Service bleibt nach Home-Button `isForeground=true` samt Notification. Android-15/16-Emulator (API 36, `google_apis_playstore`) zweimal an eigenem SurfaceFlinger/SwiftShader-Crash gescheitert (Emulator-Infra, kein App-Bug) — **offen bleibt ein Soak-Test auf echtem Android-15-Gerät** vor Launch |

## P2 — Differenzierung (nicht Launch-kritisch)

| ID | Ticket | Status |
|----|--------|--------|
| P2-1 | Bosch LDI echtes Protokoll (G-1 / NDA) | blockiert |
| P2-2 | iOS Native-Parität (FGS, Ambient, LDI) | später |
| P2-3 | Health Connect | später |
| P2-4 | Auto-Reroute default on nach Smoke | später |

---

## Produktregel (Release)

1. **Kein Demo-Content** in Release: keine Seed-Touren, keine Seed-Trails, kein Freiburg-Fallback ohne GPS, keine OA/Trail-Demo-Fotos.
2. **Kein Fake-Sensor**: LDI/Sensor-Sim nur Debug + explizites `--dart-define`.
3. **Bosch nicht bewerben**, bis G-1 grün — UI bleibt „LDI folgt G-1“.
4. **Billing**: Play-Verify nur mit Publisher-API in Production.

## Release-Build (Vorlage)

```bash
cd mobile
flutter build appbundle --release \
  --dart-define=SUPABASE_ANON_KEY="$NEXT_PUBLIC_SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL=https://aetherride.vercel.app \
  --dart-define=STADIA_API_KEY="$NEXT_PUBLIC_STADIA_API_KEY"
```

Signing: `android/key.properties` (nicht committen) — siehe `android/key.properties.example`.
