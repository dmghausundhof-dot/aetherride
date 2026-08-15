// Standard BLE GATT parsers (Heart Rate 0x180D, Cycling Power 0x1818,
// optional RSC 0x1814). Never invent values — return null if the packet
// is too short or flags require fields that are missing.

int? parseHeartRateBpm(List<int> bytes) {
  if (bytes.isEmpty) return null;
  final flags = bytes[0];
  final uint16 = (flags & 0x01) != 0;
  if (uint16) {
    if (bytes.length < 3) return null;
    return bytes[1] | (bytes[2] << 8);
  }
  if (bytes.length < 2) return null;
  return bytes[1];
}

/// Instantaneous power (watts) from Cycling Power Measurement (0x2A63).
int? parseCyclingPowerWatts(List<int> bytes) {
  if (bytes.length < 4) return null;
  return bytes[2] | (bytes[3] << 8);
}

/// Battery Level (0x2A19) — uint8 0–100. Null if missing or out of range.
int? parseBatteryLevelPercent(List<int> bytes) {
  if (bytes.isEmpty) return null;
  final pct = bytes[0];
  if (pct < 0 || pct > 100) return null;
  return pct;
}

/// Running Speed and Cadence Measurement (0x2A53). Cadence is steps/min,
/// not cycling crank RPM — do not feed this into [BoschLiveData.cadenceRpm].
class RscMeasurement {
  const RscMeasurement({
    required this.speedMps,
    required this.cadenceSpm,
    required this.isRunning,
    this.strideLengthM,
    this.totalDistanceM,
  });

  final double speedMps;
  final int cadenceSpm;
  final bool isRunning;
  final double? strideLengthM;
  final double? totalDistanceM;
}

RscMeasurement? parseRscMeasurement(List<int> bytes) {
  if (bytes.length < 4) return null;
  final flags = bytes[0];
  final speedRaw = bytes[1] | (bytes[2] << 8);
  final cadenceSpm = bytes[3];
  var offset = 4;
  double? strideLengthM;
  if ((flags & 0x01) != 0) {
    if (bytes.length < offset + 2) return null;
    final raw = bytes[offset] | (bytes[offset + 1] << 8);
    strideLengthM = raw / 100.0;
    offset += 2;
  }
  double? totalDistanceM;
  if ((flags & 0x02) != 0) {
    if (bytes.length < offset + 4) return null;
    final raw = bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
    totalDistanceM = raw / 10.0;
    offset += 4;
  }
  return RscMeasurement(
    speedMps: speedRaw / 256.0,
    cadenceSpm: cadenceSpm,
    isRunning: (flags & 0x04) != 0,
    strideLengthM: strideLengthM,
    totalDistanceM: totalDistanceM,
  );
}
