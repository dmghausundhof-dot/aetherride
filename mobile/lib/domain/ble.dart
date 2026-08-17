// Contract-Spiegel von src/lib/ble/BoschLDI.ts (Bosch LDI read-only).
// SoC/Power sind nullable: CSC liefert nur Speed/Cadence — keine erfundenen LDI-Werte.

class BoschLiveData {
  const BoschLiveData({
    required this.speedKmh,
    this.batterySocPercent,
    this.riderPowerW,
    this.assistMode,
    this.heartRateBpm,
    required this.cadenceRpm,
    required this.odometerKm,
    required this.lightStatus,
    required this.ambientBrightness,
    required this.systemLock,
    required this.bikeNotDriving,
    required this.chargerConnected,
    required this.timestampMs,
  });

  final double speedKmh;
  /// null = kein LDI/Battery (z. B. nur CSC).
  final double? batterySocPercent;
  /// null = kein Power-Meter / kein LDI-Power.
  final double? riderPowerW;
  /// null = kein LDI-Assist (nie aus CSC/Kadenz ableiten).
  final String? assistMode;
  /// null = kein BLE Heart Rate (0x180D).
  final double? heartRateBpm;
  final double cadenceRpm;
  final double odometerKm;
  final bool lightStatus;
  final double ambientBrightness;
  final bool systemLock;
  final bool bikeNotDriving;
  final bool chargerConnected;
  final int timestampMs;

  factory BoschLiveData.fromMap(Map<Object?, Object?> map) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    double? dOpt(Object? v) => (v as num?)?.toDouble();
    bool b(Object? v) => v == true;
    return BoschLiveData(
      speedKmh: d(map['speedKmh']),
      batterySocPercent: map.containsKey('batterySocPercent')
          ? dOpt(map['batterySocPercent'])
          : null,
      riderPowerW:
          map.containsKey('riderPowerW') ? dOpt(map['riderPowerW']) : null,
      assistMode: () {
        final v = map['assistMode'] ?? map['assist_mode'];
        if (v is String && v.trim().isNotEmpty) return v.trim();
        return null;
      }(),
      heartRateBpm: map.containsKey('heartRateBpm')
          ? dOpt(map['heartRateBpm'])
          : null,
      cadenceRpm: d(map['cadenceRpm']),
      odometerKm: d(map['odometerKm']),
      lightStatus: b(map['lightStatus']),
      ambientBrightness: d(map['ambientBrightness']),
      systemLock: b(map['systemLock']),
      bikeNotDriving: b(map['bikeNotDriving']),
      chargerConnected: b(map['chargerConnected']),
      timestampMs: (map['timestampMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Bosch LDI GATT service (Spec V1.0): 0000eb20-eaa2-11e9-81b4-2a2ae2dbcce4.
const boschLdiServiceUuid = '0000eb20-eaa2-11e9-81b4-2a2ae2dbcce4';
const boschLdiLiveCharUuid = '0000eb21-eaa2-11e9-81b4-2a2ae2dbcce4';
/// Saved when the bike bonded via Flow → Komponenten, not a display MAC.
const boschLdiAccessoryId = 'ldi:bosch';
