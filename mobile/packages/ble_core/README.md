# ble_core

Bosch Live Data Interface (read-only) über CoreBluetooth / BluetoothGatt (+ Hersteller-SDK-Wrapper).

- Channel: `com.aetherride/ble_core`
- Events: `com.aetherride/ble_core/ldi`
- Service-UUID-Platzhalter: siehe `lib/domain/ble.dart`

Dart-Contract: `lib/native/ble_core_channel.dart`

## Status

- **Offener BLE-Scan** (kein `withServices`-Filter): Bosch Smart System, Shimano STEPS/E-TUBE, CSC, Powermeter. Klassifikation in `lib/domain/ble/bike_ble_kind.dart`.
- **Pairing-UI**: Werkstatt → Sheet mit Live-Liste (Antrieb vs. Sensor). User wählt; Ride-Start verbindet das gespeicherte Gerät.
- **CSC / Standard BLE** (0x1816): live via `flutter_blue_plus` — speed/cadence.
- **Heart Rate (0x180D) / Cycling Power (0x1818) / Battery (0x180F)**: nur echte GATT-Werte. Nie synthetisiert.
- **Smartwatch / HR-Gurt**: Der Hof öffnet einen Picker (`watch_pair_sheet.dart`). Offener Scan (kein `withServices: 0x180D`-Filter — viele Uhren lassen 180D in Ads weg). Kopplung nur mit echtem Heart-Rate-Notify 0x180D. Apple Watch ohne 180D ist blockiert. Uhr-Akku (0x180F) nie als Rad-SoC. Ride-Ende trennt nur Rad (`disconnectBikeKeepWatch`), nicht die Uhr. Speicher: `watch_ble_device.json` + `ble_last_watch_id.txt`. CSC bleibt am Rad in der Werkstatt.
- **Bosch LDI (Spec V1.0, Android 12+)**: Phone is BLE accessory. Advertise service solicitation `0000eb20-eaa2-…`, bike (firmware ≥19) connects as central, we subscribe to Live Data `eb21` and decode the public protobuf. Pairing: Flow → Komponenten → FlowLine. iOS not wired yet. Never invent SoC.
- **Fähigkeitsmatrix**: `lib/domain/ble/manufacturer_ble.dart` + Proofs in `test/manufacturer_ble_proof_test.dart`. Offen dekodierbar: LDI (Android), SIG CSC/Power/HR/Battery. Identität nur: Shimano STEPS, Yamaha, Fazua, TQ, Brose, Specialized, Giant, Mahle, Bafang. ESM ohne eigenes öffentliches Antriebsprotokoll → SIG-GATT.
- **Löschen**: Werkstatt-Unlink, Hof-Uhr, Privatsphäre → Hersteller-Kopplungen, Account-Wipe. Dateien: `bike_ble_devices.json`, `watch_ble_device.json`, `ble_last_csc_id.txt`, `ble_last_watch_id.txt`.
- **Shimano STEPS**: Erkennung über Display-Namen (SC-E…, EP8, E-TUBE). Kein inoffizielles E-TUBE-Protokoll.
- LDI Dart stub telemetry only when `kDebugMode` **and** `--dart-define=AETHER_LDI_SIM=true`. Release never starts the stub.

## Hardware / QA

Native LDI braucht zum Pairing-Test ein Bosch Smart System **Steuerung ≥19**. Spec ist öffentlich (Apache-2.0), kein NDA mehr für die 13 Live-Felder.

| Gate | Stand |
|------|-----------|
| Spec / NDA | Öffentliche LDI V1.0 (Mai 2026) |
| Android | Accessory-Plugin verdrahtet |
| iOS | Noch nicht |
| QA | CSC-Pfad unverändert; Release ohne Sim-Stub |

Web-Simulator in `src/lib/ble/BoschLDI.ts` bleibt Browser-Demo und darf nicht als Hardware gelten.
