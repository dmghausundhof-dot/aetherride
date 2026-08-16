import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../map/nav_puck_image.dart';

/// Compact next-turn pill — one row, glanceable at speed (N-MAP-02).
/// Glyph · distance · street. Street is secondary; glyph already encodes turn.
class RideNextTurnBanner extends StatelessWidget {
  const RideNextTurnBanner({
    super.key,
    required this.distance,
    required this.instruction,
    required this.icon,
    this.street,
    this.maneuver,
    this.navPuckStyle = NavPuckStyle.chevron,
  });

  final String distance;

  /// Fallback 1-line text when [street] is null (legacy call sites).
  final String instruction;
  final IconData icon;

  /// Prefer street name (Komoot-style glance).
  final String? street;

  /// Optional maneuver short label (unused when [street] is set).
  final String? maneuver;

  final NavPuckStyle navPuckStyle;

  @override
  Widget build(BuildContext context) {
    final distanceDp = NavHudTokens.nextTurnDistanceSize(context);
    final glyphDp = NavHudTokens.nextTurnGlyphSize(context);
    final streetDp = NavHudTokens.nextTurnStreetSize(context);
    final line = (street != null && street!.trim().isNotEmpty)
        ? street!.trim()
        : instruction;

    final fill = AppColors.chromeFill(context);
    final ink = AppColors.inkOnChrome(context);
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      color: fill,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: NavHudTokens.nextTurnDistanceMinDp,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.s,
          ),
          child: Row(
            children: [
              icon == Icons.navigation
                  ? AetherNavMark(
                      size: glyphDp,
                      color: ink,
                      stroke: fill,
                      style: navPuckStyle,
                    )
                  : Icon(icon, color: ink, size: glyphDp),
              const SizedBox(width: AppSpacing.s),
              Text(
                distance,
                style: TextStyle(
                  fontWeight: NavHudTokens.nextTurnDistanceWeight,
                  fontSize: distanceDp,
                  color: ink,
                  height: 1.0,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  line,
                  maxLines: NavHudTokens.nextTurnStreetMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: NavHudTokens.nextTurnStreetWeight,
                    fontSize: streetDp,
                    color: ink.withValues(alpha: 0.92),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
