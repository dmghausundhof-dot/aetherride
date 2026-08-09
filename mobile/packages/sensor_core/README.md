# sensor_core

Native Hot-Path (Spec §5.1): CoreMotion / SensorManager FIFO → Ringpuffer → **1-s-Blöcke** an Dart.

- Channel: `com.aetherride/sensor_core`
- Events: `com.aetherride/sensor_core/blocks`
- Verboten: Sample-für-Sample über Method Channels

Dart-Contract: `lib/native/sensor_core_channel.dart` · Domain: `lib/domain/sensor.dart`

MissingPlugin stub only when `kDebugMode` **and** `--dart-define=AETHER_SENSOR_SIM=true`. Release fail-closed (no random impact metrics).
