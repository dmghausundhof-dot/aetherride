import '../ble.dart';
import '../hud_bike_peek.dart';

/// Pair sheet covers the shell, including the tab bar. Content scrolls inside.
const kBlePairSheetHeightFactor = 0.92;

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

/// Workshop live chips from GATT/LDI. Never invented from a saved MAC.
List<String> garageBleLiveChips({
  required bool live,
  required bool hasCrank,
  double speedKmh = 0,
  double cadenceRpm = 0,
  double? batterySocPercent,
  double? riderPowerW,
  bool chargerConnected = false,
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
  );
}

/// Connected but nothing moving yet — invite the rider to spin the wheel.
bool garageBleShowSpinHint({
  required bool live,
  required List<String> chips,
}) =>
    live && chips.isEmpty;
