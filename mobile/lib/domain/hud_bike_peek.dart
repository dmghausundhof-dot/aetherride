import '../core/theme/nav_hud_tokens.dart';

/// One live bike readout for the Ride HUD peek row.
///
/// Only populated from a live stream (CSC / power / HR / Battery / LDI).
/// Never invented from pairing state or garage geometry.
class HudBikePeekChip {
  const HudBikePeekChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is HudBikePeekChip &&
      other.value == value &&
      other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// Live bike / chassis peek for the Ride HUD.
///
/// Clean Mode: no chips (the four nav stats stay glanceable). CSC still
/// replaces GPS speed silently; the Tempo caption may say **Rad**.
/// Pro: up to [maxPro] chips, only when a value is actually streaming.
abstract final class HudBikePeek {
  static const int maxClean = 0;
  static const int maxPro = 4;

  /// Wheel / LDI speed is driving the Speed slot (same threshold as HUD fusion).
  static bool wheelDrivesSpeed(double? wheelSpeedKmh) =>
      wheelSpeedKmh != null && wheelSpeedKmh > 0.5;

  /// Cadence chip: sticky while the bike sensor stays connected (0 rpm at a
  /// light is real). Hidden as soon as CSC/LDI is gone — never a leftover 0.
  static bool crankLive({
    required bool bikeConnected,
    required bool previouslySeen,
    required double cadenceRpm,
  }) {
    if (!bikeConnected) return false;
    return previouslySeen || cadenceRpm > 0.5;
  }

  /// GPS slot is always Tempo — same chrome as a routed HUD (Einfach fahren).
  static String speedCaption({required bool wheelDrives}) {
    if (wheelDrives) return 'Rad';
    return NavHudTokens.labelSpeed;
  }

  static List<HudBikePeekChip> chips({
    required bool cleanMode,
    required bool hasCrank,
    double cadenceRpm = 0,
    double? heartRateBpm,
    double? riderPowerW,
    double? batterySocPercent,
    String? assistMode,
    double? leanAngleDeg,
    bool showChassis = false,
  }) {
    if (cleanMode) return const [];

    final out = <HudBikePeekChip>[];
    if (heartRateBpm != null && heartRateBpm >= 1 && heartRateBpm <= 239) {
      out.add(
        HudBikePeekChip(
          value: heartRateBpm.round().toString(),
          label: 'Puls',
        ),
      );
    }
    if (hasCrank) {
      out.add(
        HudBikePeekChip(
          value: cadenceRpm.round().toString(),
          label: 'rpm',
        ),
      );
    }
    if (riderPowerW != null) {
      out.add(
        HudBikePeekChip(
          value: riderPowerW.round().toString(),
          label: 'W',
        ),
      );
    }
    if (batterySocPercent != null) {
      out.add(
        HudBikePeekChip(
          value: '${batterySocPercent.round()}%',
          label: 'Akku',
        ),
      );
    }
    final assist = assistMode?.trim();
    if (assist != null && assist.isNotEmpty) {
      out.add(HudBikePeekChip(value: assist, label: 'Assist'));
    }
    if (showChassis && leanAngleDeg != null) {
      out.add(
        HudBikePeekChip(
          value: '${leanAngleDeg.abs().round()}°',
          label: 'Lean',
        ),
      );
    }
    if (out.length <= maxPro) return out;
    return out.sublist(0, maxPro);
  }
}
