# ble_core

Bosch Live Data Interface (read-only) über CoreBluetooth / BluetoothGatt (+ Hersteller-SDK-Wrapper).

- Channel: `com.aetherride/ble_core`
- Events: `com.aetherride/ble_core/ldi`
- Service-UUID-Platzhalter: siehe `lib/domain/ble.dart`

Dart-Contract: `lib/native/ble_core_channel.dart`

## Status

- **CSC / Standard BLE** (0x1816): live via `flutter_blue_plus` in `BleCoreChannel`.
- **Bosch LDI (G-1)**: Android shell `BoschLdiPlugin` — `connect` returns `false`, other methods `UnimplementedError` / `"G-1 pending"`.
- LDI Dart stub telemetry only when `kDebugMode` **and** `--dart-define=AETHER_LDI_SIM=true`. Release never starts the stub.
