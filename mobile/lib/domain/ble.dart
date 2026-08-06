// Contract-Spiegel von src/lib/ble/BoschLDI.ts (Bosch LDI read-only).

class BoschLiveData {
  const BoschLiveData({
    required this.speedKmh,
    required this.batterySocPercent,
    required this.riderPowerW,
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
  final double batterySocPercent;
  final double riderPowerW;
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
    bool b(Object? v) => v == true;
    return BoschLiveData(
      speedKmh: d(map['speedKmh']),
      batterySocPercent: d(map['batterySocPercent']),
      riderPowerW: d(map['riderPowerW']),
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

/// Beispiel-UUID Nähe Spec/Community — echte UUIDs aus Bosch-LDI-PDF.
const boschLdiServiceUuid = '00000010-eaa2-11e9-81b4-2a2ae2dbcce4';
