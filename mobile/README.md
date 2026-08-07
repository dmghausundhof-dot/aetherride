# AetherRide Mobile (Flutter)

Offline-first Flutter-Client nach Spec §5.

## Billing (Pro)

Hybrid: Stripe Checkout (web) + Google Play subscription `aetherride_pro_monthly`.

### Play Console (ops — not automated)

1. App package: `com.aetherride.aetherride_mobile`
2. Create **Subscription** product / base plan ID exactly `aetherride_pro_monthly`
3. Internal / closed testing track + License Tester accounts
4. Sign a release/debug build that uses Play Billing Library
5. Later (2A): service account with Android Publisher API → set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` on the API; drop `PLAY_VERIFY_STUB`

Server verify (`POST /api/billing/play-verify`) always writes `profiles.subscription_tier` **and** `sync_snapshots.payload.subscriptionTier` so Mobile LWW stays Pro.

## Ride Chunks (ops)

1. Apply SQL once on Supabase: `supabase/ride_chunks.sql` (bucket + meta table + RLS)
2. Mobile queues uploads via Drift v6 → `POST /api/ride-chunks` (Bearer)
3. Confirm storage policies allow authenticated write to the ride-chunks bucket

## Schnitte (implementiert)

| ID | Inhalt |
|---|---|
| S1 | Drift SQLite + SyncEngine ↔ `/api/sync` (Bearer) + Supabase Auth |
| S2 | `dsp_core` Rust + Dart FFI/Fallback; `sensor_core` Android/iOS 1-s-Blöcke |
| S3 | `ble_core` Standard-BLE (CSC) + LDI-Shell/Simulator |
| S4 | MapLibre Discover + Online-Routing via `/api/route` |
| S5 | Catalog Postgres + `/api/catalog` + Upsert-Skript (G-4-Pfad) |
| S6 | Overpass-Report, Open-Meteo `/api/weather`, Outdooractive-Adapter, Trailforks attribution-only |
| S7 | `routing_core` Offline-Graph (OSM) + Valhalla NDK/iOS; APK via `install-android-jni.sh` |

## Start

```bash
export PATH="$HOME/flutter/bin:$PATH"
# AGP 9: JDK 17 empfohlen (nicht 21/25)
export JAVA_HOME="${JAVA_HOME:-$HOME/.sdkman/candidates/java/17.0.9-tem}"
cd mobile
flutter pub get

flutter run \
  --dart-define=SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY \
  --dart-define=API_BASE_URL=http://10.0.2.2:3001 \
  --dart-define=STADIA_API_KEY=$STADIA_API_KEY
```

## Android build

```bash
export JAVA_HOME="${JAVA_HOME:-$HOME/.sdkman/candidates/java/17.0.9-tem}"
# Optional Valhalla jniLibs (arm64): source …/aetherride-env.sh && cargo build --release --features valhalla --target aarch64-linux-android
# Emulator graph-only: cargo build --release --target x86_64-linux-android && ./scripts/routing/install-android-jni.sh --graph-only x86_64
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

`preBuild` kopiert `librouting_core` (+ protobuf) nach `jniLibs`, wenn das Cargo-Artifact existiert.

## Native libs

```bash
cd packages/dsp_core/native && cargo test && cargo build --release
cd packages/routing_core/native && cargo test
```

## Tests

```bash
flutter test
cd packages/dsp_core && flutter test
```
