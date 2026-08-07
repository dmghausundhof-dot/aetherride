# AetherRide Mobile (Flutter)

Offline-first Flutter-Client nach Spec §5.

## Schnitte (implementiert)

| ID | Inhalt |
|---|---|
| S1 | Drift SQLite + SyncEngine ↔ `/api/sync` (Bearer) + Supabase Auth |
| S2 | `dsp_core` Rust + Dart FFI/Fallback; `sensor_core` Android/iOS 1-s-Blöcke |
| S3 | `ble_core` Standard-BLE (CSC) + LDI-Shell/Simulator |
| S4 | MapLibre Discover + Online-Routing via `/api/route` |
| S5 | Catalog Postgres + `/api/catalog` + Upsert-Skript (G-4-Pfad) |
| S6 | Overpass-Report, Open-Meteo `/api/weather`, Outdooractive-Adapter, Trailforks attribution-only |
| S7 | `routing_core` Offline-Graph (OSM) + Valhalla NDK/iOS Build-Skripte |

## Start

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd mobile
flutter pub get

flutter run \
  --dart-define=SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

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
