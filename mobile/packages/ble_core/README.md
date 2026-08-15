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
- **Bosch LDI (G-1)**: Android shell `BoschLdiPlugin` — `connect` returns `false` until official spec/NDA + hardware. Scan erkennt „SMART SYSTEM EBIKE“ / Kiox / Nyon und die UUID `eaa2-11e9-…`; proprietäre Notifications werden nicht geparst.
- **Shimano STEPS**: Erkennung über Display-Namen (SC-E…, EP8, E-TUBE). Kein inoffizielles E-TUBE-Protokoll.
- LDI Dart stub telemetry only when `kDebugMode` **and** `--dart-define=AETHER_LDI_SIM=true`. Release never starts the stub.

## G-1 Gates (nicht vorziehen)

Native LDI-Implementierung erst starten, wenn **alle** Gates grün sind:

| Gate | Bedingung |
|------|-----------|
| Hardware | Echtes Bosch-System (Display/Drive) zum Pairing-Test |
| Spec / NDA | Offizielle LDI Spec + ggf. Partner-/SDK-Zugang |
| Plattform | Android GATT-Plugin + iOS CoreBluetooth Mapping |
| QA | CSC-Pfad unverändert; Release ohne Sim-Stub |

Bis dahin: Shell belassen, Web-Simulator in `src/lib/ble/BoschLDI.ts`, Mobile nur mit `AETHER_LDI_SIM`. Kopplung und Erkennung sind unabhängig davon live.
