import '../ble.dart';
import '../hud_bike_peek.dart';
import 'bike_ble_kind.dart';

/// Pair sheet height — same factor as [WatchPairSheet] (one pairing language).
const kBlePairSheetHeightFactor = 0.52;

/// Bottom-sheet height: leaves the status bar, includes the home-indicator
/// zone. The widget pads [safeBottom] inside so the footer never overflows.
double blePairSheetBodyHeight({
  required double screenHeight,
  required double safeTop,
  required double safeBottom,
}) {
  final maxH = (screenHeight - safeTop).clamp(0.0, screenHeight);
  if (maxH <= 0) return 0;
  if (maxH <= 320) return maxH;
  final target = maxH * kBlePairSheetHeightFactor;
  if (target < safeBottom + 240) return maxH;
  return target.clamp(320.0, maxH);
}

/// Honesty line: e-bike with a saved link, but no live SoC from Intuvia/drive.
bool garageBleShowBatteryHonesty({
  required bool isEbike,
  required bool hasBinding,
  double? batterySocPercent,
}) =>
    isEbike && hasBinding && batterySocPercent == null;

/// Which one-liner the workshop should show — capability, not pairing how-to.
enum GarageBleRiderHint {
  emptyEbike,
  emptySensor,
  driveNeedsWheel,
  spinWheel,
  boschNoSoc,
  driveNoSoc,
  savedNotLive,
  none,
}

GarageBleRiderHint garageBleRiderHint({
  required bool isEbike,
  required bool bindingEmpty,
  required bool live,
  required bool hasWheel,
  BikeBleKind? driveKind,
  required bool spin,
  double? batterySocPercent,
}) {
  if (bindingEmpty) {
    return isEbike
        ? GarageBleRiderHint.emptyEbike
        : GarageBleRiderHint.emptySensor;
  }
  if (spin) return GarageBleRiderHint.spinWheel;
  if (bleDriveNeedsWheelSensor(driveKind) && !hasWheel) {
    return GarageBleRiderHint.driveNeedsWheel;
  }
  if (isEbike && batterySocPercent == null) {
    if (driveKind == BikeBleKind.shimano ||
        driveKind == BikeBleKind.yamaha ||
        driveKind == BikeBleKind.otherDrive) {
      return GarageBleRiderHint.driveNoSoc;
    }
    return GarageBleRiderHint.boschNoSoc;
  }
  if (!live) return GarageBleRiderHint.savedNotLive;
  return GarageBleRiderHint.none;
}

/// Workshop live chips from GATT/LDI. Never invented from a saved MAC.
List<String> garageBleLiveChips({
  required bool live,
  required bool hasCrank,
  double speedKmh = 0,
  double cadenceRpm = 0,
  double? batterySocPercent,
  double? riderPowerW,
  bool chargerConnected = false,
  bool lightOn = false,
  bool systemLock = false,
}) {
  if (!live) return const [];
  return [
    if (HudBikePeek.wheelDrivesSpeed(speedKmh))
      '${speedKmh.toStringAsFixed(1)} km/h',
    if (hasCrank) '${cadenceRpm.round()} rpm',
    if (riderPowerW != null && riderPowerW > 0 && riderPowerW < 2500)
      '${riderPowerW.round()} W',
    if (batterySocPercent != null) '${batterySocPercent.round()} %',
    if (chargerConnected) 'Lader',
    if (lightOn) 'Licht',
    if (systemLock) 'Schloss',
  ];
}

List<String> garageBleLiveChipsFromData({
  required bool live,
  required bool hasCrank,
  required BoschLiveData data,
}) {
  return garageBleLiveChips(
    live: live,
    hasCrank: hasCrank,
    speedKmh: data.speedKmh,
    cadenceRpm: data.cadenceRpm,
    batterySocPercent: data.batterySocPercent,
    riderPowerW: data.riderPowerW,
    chargerConnected: data.chargerConnected,
    lightOn: data.lightStatus,
    systemLock: data.systemLock,
  );
}

/// Connected but nothing moving yet — invite the rider to spin the wheel.
bool garageBleShowSpinHint({
  required bool live,
  required List<String> chips,
}) =>
    live && chips.isEmpty;
