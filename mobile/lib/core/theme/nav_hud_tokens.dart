import 'package:flutter/material.dart';

/// Locked Android HUD tokens — `nav-hud-tokens-v1` (N-START-01 / N-HUD-01).
///
/// Clean Mode has exactly four HUD elements:
/// Next-turn · Speed · Rest-km · ETA.
/// Upcoming Rail is a compact line under next-turn when stop ETA <15 min
/// and does **not** count as a fifth stat.
abstract final class NavHudTokens {
  // --- Next-turn ---
  static const double nextTurnDistanceDp = 48;
  static const double nextTurnDistanceMinDp = 40;
  static const double nextTurnDistanceMaxDp = 56;
  static const FontWeight nextTurnDistanceWeight = FontWeight.w700; // Bold

  static const double nextTurnGlyphMinDp = 40;
  static const double nextTurnGlyphMaxDp = 48;
  static const double nextTurnGlyphDp = 44;

  static const double nextTurnStreetMinDp = 16;
  static const double nextTurnStreetMaxDp = 18;
  static const double nextTurnStreetDp = 17;
  static const FontWeight nextTurnStreetWeight = FontWeight.w600; // Semibold
  static const int nextTurnStreetMaxLines = 1;

  // --- Stats (Speed · Rest-km · ETA) ---
  static const double statValueDp = 22;
  static const FontWeight statValueWeight = FontWeight.w600; // Semibold
  static const double statLabelDp = 11;
  static const FontWeight statLabelWeight = FontWeight.w500; // Medium

  static const String labelSpeed = 'Speed';
  static const String labelRestKm = 'Rest-km';
  static const String labelEta = 'ETA';

  // --- Upcoming rail (not a 5th Clean stat); keep in sync with domain ---
  static const int upcomingRailMaxEtaMin = 15; // == kUpcomingRailMaxEtaMin

  // --- Start / Losfahren primary CTA (map-first) ---
  static const Color startCtaGreen = Color(0xFF00C853);
  static const double startCtaMinHeightDp = 64;

  /// Distance numeral size with accessibility scale, clamped 40–56.
  static double nextTurnDistanceSize(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (nextTurnDistanceDp * scale).clamp(
      nextTurnDistanceMinDp,
      nextTurnDistanceMaxDp,
    );
  }

  /// Turn glyph size, clamped 40–48.
  static double nextTurnGlyphSize(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (nextTurnGlyphDp * scale).clamp(
      nextTurnGlyphMinDp,
      nextTurnGlyphMaxDp,
    );
  }

  /// Street / instruction size, clamped 16–18.
  static double nextTurnStreetSize(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (nextTurnStreetDp * scale).clamp(
      nextTurnStreetMinDp,
      nextTurnStreetMaxDp,
    );
  }
}
