import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Locked Android HUD tokens — `nav-hud-tokens-v2` (N-MAP-02).
///
/// Clean Mode has exactly four HUD **nav** elements:
/// Next-turn · Tempo · noch km · Ziel.
/// Upcoming Rail is a compact line under next-turn when stop ETA <15 min
/// and does **not** count as a fifth stat.
/// Media transport, compass rose, and Pro bike-peek chips are overlays —
/// not nav stats (same class as Pause).
abstract final class NavHudTokens {
  // --- Next-turn (single-row pill; map stays primary) ---
  static const double nextTurnDistanceDp = 32;
  static const double nextTurnDistanceMinDp = 28;
  static const double nextTurnDistanceMaxDp = 40;
  static const FontWeight nextTurnDistanceWeight = FontWeight.w700; // Bold

  static const double nextTurnGlyphMinDp = 24;
  static const double nextTurnGlyphMaxDp = 32;
  static const double nextTurnGlyphDp = 28;

  static const double nextTurnStreetMinDp = 13;
  static const double nextTurnStreetMaxDp = 16;
  static const double nextTurnStreetDp = 14;
  static const FontWeight nextTurnStreetWeight = FontWeight.w600; // Semibold
  static const int nextTurnStreetMaxLines = 1;

  // --- Stats (Tempo · noch km · Ziel) ---
  static const double statValueDp = 22;
  static const FontWeight statValueWeight = FontWeight.w600; // Semibold
  static const double statLabelDp = 11;
  static const FontWeight statLabelWeight = FontWeight.w500; // Medium

  /// Domain keys = DE product copy. [hudSpeedCaptionFor] / ride* l10n map locales.
  static const String labelSpeed = 'Tempo';
  static const String labelRestKm = 'noch km';
  static const String labelEta = 'Ziel';

  /// Empty rest / Ziel when there is no ActiveRoute (Einfach fahren).
  static const String emptyStat = '—';

  // --- Upcoming rail (not a 5th Clean stat); keep in sync with domain ---
  static const int upcomingRailMaxEtaMin = 15; // == kUpcomingRailMaxEtaMin

  // --- Start / Losfahren primary CTA (map-first) ---
  static const Color startCtaOrange = Color(0xFFFF6A00);
  static const Color startCtaGreen = startCtaOrange;
  static const double startCtaMinHeightDp = 64;

  /// Round Pause control beside the data strip (not a second full-width bar).
  static const double pauseFabDp = 56;

  // --- Live layer bar (Karte / Daten / Fahrwerk) — charcoal island, not orange fill ---
  static const double layerLabelDp = 13;
  static const FontWeight layerLabelWeight = FontWeight.w600;
  static const double layerIconDp = 18;
  static const double layerBarMinHeightDp = 48;

  /// Shared HUD island (Layer / Zusammen / Ja / Live) — charcoal, not a second Tempo bar.
  static const double islandPadH = 12;
  static const double islandPadV = 8;
  static const double islandCompactPadV = 6;
  static const double islandGapDp = 8;
  static const double islandCodeDp = 14;
  static const double islandCodeTracking = 2.2;
  static const double islandHitDp = 48;
  static const double islandFillAlpha = 0.94;
  static const double islandStrokeAlpha = 0.7;

  static Color islandFill(BuildContext context) =>
      (AppColors.isSunlight(context) ? AppColors.sunSurface : AppColors.overlay)
          .withValues(alpha: islandFillAlpha);

  static Color islandStroke(BuildContext context) =>
      (AppColors.isSunlight(context) ? AppColors.borderLight : AppColors.border)
          .withValues(alpha: islandStrokeAlpha);

  /// Distance numeral size with accessibility scale, clamped 28–40.
  static double nextTurnDistanceSize(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (nextTurnDistanceDp * scale).clamp(
      nextTurnDistanceMinDp,
      nextTurnDistanceMaxDp,
    );
  }

  /// Turn glyph size, clamped 24–32.
  static double nextTurnGlyphSize(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (nextTurnGlyphDp * scale).clamp(
      nextTurnGlyphMinDp,
      nextTurnGlyphMaxDp,
    );
  }

  /// Street / instruction size, clamped 13–16.
  static double nextTurnStreetSize(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (nextTurnStreetDp * scale).clamp(
      nextTurnStreetMinDp,
      nextTurnStreetMaxDp,
    );
  }
}
