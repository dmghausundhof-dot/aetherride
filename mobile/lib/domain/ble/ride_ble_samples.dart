import '../ble.dart';

/// Running averages from live GATT — never seeded, never invented.
class RideBleSamples {
  int hrCount = 0;
  double hrSum = 0;
  int? hrMax;
  int cadenceCount = 0;
  double cadenceSum = 0;
  int powerCount = 0;
  double powerSum = 0;

  void reset() {
    hrCount = 0;
    hrSum = 0;
    hrMax = null;
    cadenceCount = 0;
    cadenceSum = 0;
    powerCount = 0;
    powerSum = 0;
  }

  void add(BoschLiveData d) {
    final hr = d.heartRateBpm;
    if (hr != null && hr >= 1 && hr <= 239) {
      hrCount++;
      hrSum += hr;
      final v = hr.round();
      if (hrMax == null || v > hrMax!) hrMax = v;
    }
    if (d.cadenceRpm > 0.5) {
      cadenceCount++;
      cadenceSum += d.cadenceRpm;
    }
    final w = d.riderPowerW;
    if (w != null && w > 0 && w < 2500) {
      powerCount++;
      powerSum += w;
    }
  }

  /// Keys only when at least one real sample exists.
  Map<String, dynamic> toSummary() {
    return {
      if (hrCount > 0) 'avgHr': (hrSum / hrCount).round(),
      if (hrMax != null) 'maxHr': hrMax,
      if (cadenceCount > 0) 'avgCadence': (cadenceSum / cadenceCount).round(),
      if (powerCount > 0) 'avgPowerW': (powerSum / powerCount).round(),
    };
  }
}
