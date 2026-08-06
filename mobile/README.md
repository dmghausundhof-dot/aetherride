# AetherRide Mobile (Flutter)

Offline-first Flutter-Gerüst nach Spec §5: UI + Riverpod + Domäne in Dart; zeitkritische Pfade als native Module (FFI / Platform Channels, **nur 1-s-Blöcke**).

## Status

Scaffold mit `android/` + `ios/` (Flutter 3.44.x). Native Plugins noch Stubs; Drift-Schema folgt.

## Voraussetzungen

- Flutter **stable** (≥ 3.24, getestet gegen 3.44.x)
- Xcode (iOS) / Android SDK (Android)

```bash
# SDK (falls noch nicht installiert)
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

cd mobile
./tool/bootstrap_platforms.sh   # erzeugt android/ + ios/
flutter pub get
flutter run
```

## Schichtung (Spec §5.2)

```
presentation/   Widgets, Design-Tokens, Bottom-Nav
providers/      Riverpod (unidirektional)
domain/         reines Dart (Bike, Sensor-Contracts, BLE)
data/           Drift/SQLite + Sync-Stubs (lesen IMMER lokal)
native/         Channel-Contracts → sensor_core, ble_core, …
packages/       READMEs für native Hot-Path-Module
```

## Native Module (MUSS)

| Modul | Kanal / FFI | Übergabe |
|---|---|---|
| `sensor_core` | `com.aetherride/sensor_core` | 1-s-Blöcke, kein Sample-für-Sample |
| `ble_core` | `com.aetherride/ble_core` | Bosch LDI read-only |
| `location_core` | `com.aetherride/location_core` | Batch während Ride |
| `map_core` | MapLibre GL Native | Embed |
| `routing_core` | Valhalla C++/FFI | identisch Online/Offline |
| `dsp_core` | Rust FFI | Filter, Fusion, Features |

Web-Contracts zum Spiegeln: `src/lib/sensor/SensorFusion.ts`, `src/lib/ble/BoschLDI.ts`.

## Tabs (Parität Web)

Home · Garage · Ride · Discover · Shop

## Offline-First

UI liest ausschließlich aus Drift. Sync-Engine aktualisiert im Hintergrund — Netzausfall ist kein UI-Sonderfall.
