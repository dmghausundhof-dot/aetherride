import '../ble.dart';
import 'bike_ble_kind.dart';
import 'bosch_ldi_proto.dart';

/// Sparse LDI + CSC/GATT merge. LDI fields win when present; CSC fills gaps.
/// Never invents SoC / watts / HR.
class ManufacturerLiveMerge {
  const ManufacturerLiveMerge({
    this.ldiSpeedKmh,
    this.ldiCadenceRpm,
    this.ldiSoc,
    this.ldiPowerW,
    this.ldiOdometerKm,
    this.lightStatus = false,
    this.ambientBrightness = 0,
    this.systemLock = false,
    this.chargerConnected = false,
    this.bikeNotDriving = true,
    this.ldiConnected = false,
  });

  final double? ldiSpeedKmh;
  final double? ldiCadenceRpm;
  final double? ldiSoc;
  final double? ldiPowerW;
  final double? ldiOdometerKm;
  final bool lightStatus;
  final double ambientBrightness;
  final bool systemLock;
  final bool chargerConnected;
  final bool bikeNotDriving;
  final bool ldiConnected;

  ManufacturerLiveMerge applyLdi(BoschLiveData d) {
    return ManufacturerLiveMerge(
      ldiSpeedKmh: d.speedKmh > 0
          ? d.speedKmh
          : (ldiConnected && d.bikeNotDriving ? 0.0 : ldiSpeedKmh),
      ldiCadenceRpm: d.cadenceRpm > 0 ? d.cadenceRpm : ldiCadenceRpm,
      ldiSoc: d.batterySocPercent ?? ldiSoc,
      ldiPowerW: d.riderPowerW ?? ldiPowerW,
      ldiOdometerKm: d.odometerKm > 0 ? d.odometerKm : ldiOdometerKm,
      lightStatus: d.lightStatus,
      ambientBrightness: d.ambientBrightness,
      systemLock: d.systemLock,
      chargerConnected: d.chargerConnected,
      bikeNotDriving: d.bikeNotDriving,
      ldiConnected: true,
    );
  }

  ManufacturerLiveMerge applyLdiFrame(BoschLdiFrame f) {
    return applyLdi(
      BoschLiveData(
        speedKmh: f.speedKmh ?? 0,
        cadenceRpm: f.cadenceRpm ?? 0,
        batterySocPercent: f.batterySocPercent,
        riderPowerW: f.riderPowerW,
        odometerKm: f.odometerKm ?? 0,
        lightStatus: f.lightOn ?? lightStatus,
        ambientBrightness: f.ambientBrightnessLux ?? ambientBrightness,
        systemLock: f.systemLock ?? systemLock,
        bikeNotDriving: f.bikeNotDriving ?? bikeNotDriving,
        chargerConnected: f.chargerConnected ?? chargerConnected,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  BoschLiveData emit({
    required double cscSpeedKmh,
    required double cscCadenceRpm,
    double? gattSoc,
    double? gattPowerW,
    double? heartRateBpm,
    String? assistMode,
  }) {
    final speed = ldiSpeedKmh ?? cscSpeedKmh;
    return BoschLiveData(
      speedKmh: speed,
      batterySocPercent: ldiSoc ?? gattSoc,
      riderPowerW: ldiPowerW ?? gattPowerW,
      assistMode: assistMode,
      heartRateBpm: heartRateBpm,
      cadenceRpm: ldiCadenceRpm ?? cscCadenceRpm,
      odometerKm: ldiOdometerKm ?? 0,
      lightStatus: lightStatus,
      ambientBrightness: ambientBrightness,
      systemLock: systemLock,
      bikeNotDriving: ldiConnected ? bikeNotDriving : speed < 1,
      chargerConnected: chargerConnected,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Official bike odometer (LDI) may seed or advance the garage km.
bool shouldImportManufacturerOdometer({
  required double bikeOdometerKm,
  required double? liveOdometerKm,
  required bool fromLdi,
}) {
  if (!fromLdi) return false;
  final live = liveOdometerKm;
  if (live == null || live < 1) return false;
  if (bikeOdometerKm <= 0) return true;
  return live > bikeOdometerKm + 0.5;
}

enum BlePairNextStep {
  done,
  tryBoschLdi,
  keepScanningWheel,
  failed,
}

/// After a pair-sheet GATT attempt: close, start LDI, or keep looking for CSC.
BlePairNextStep blePairNextStep({
  required bool connected,
  required BikeBleKind kind,
  required bool hasLiveMetrics,
}) {
  if (connected && hasLiveMetrics) return BlePairNextStep.done;
  if (kind == BikeBleKind.bosch && !hasLiveMetrics) {
    return BlePairNextStep.tryBoschLdi;
  }
  if (bikeBleKindIsDrive(kind) && !hasLiveMetrics) {
    return BlePairNextStep.keepScanningWheel;
  }
  if (connected) return BlePairNextStep.done;
  return BlePairNextStep.failed;
}
