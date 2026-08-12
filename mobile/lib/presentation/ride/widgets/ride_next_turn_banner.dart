import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';

/// Dominant next-turn HUD pill — glanceable at speed (N-HUD-01 / nav-hud-tokens-v1).
/// Hierarchy: large distance → turn glyph → street (1-line) secondary.
/// Optional [street] / [maneuver]: when [street] is set, it is the 1-line label
/// and [maneuver] (if any) is ignored in the street slot (glyph already encodes turn).
class RideNextTurnBanner extends StatelessWidget {
  const RideNextTurnBanner({
    super.key,
    required this.distance,
    required this.instruction,
    required this.icon,
    this.street,
    this.maneuver,
  });

  final String distance;
  /// Fallback 1-line text when [street] is null (legacy call sites).
  final String instruction;
  final IconData icon;

  /// Prefer street name on the secondary line (Komoot-style glance).
  final String? street;

  /// Optional maneuver short label (unused in layout when [street] is set;
  /// kept for API completeness / future dual-line).
  final String? maneuver;

  @override
  Widget build(BuildContext context) {
    final distanceDp = NavHudTokens.nextTurnDistanceSize(context);
    final glyphDp = NavHudTokens.nextTurnGlyphSize(context);
    final streetDp = NavHudTokens.nextTurnStreetSize(context);
    final line = (street != null && street!.trim().isNotEmpty)
        ? street!.trim()
        : instruction;

    return Material(
      elevation: 6,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: AppColors.accent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: NavHudTokens.nextTurnDistanceMinDp,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.l,
            AppSpacing.m,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: glyphDp),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      distance,
                      style: TextStyle(
                        fontWeight: NavHudTokens.nextTurnDistanceWeight,
                        fontSize: distanceDp,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line,
                      maxLines: NavHudTokens.nextTurnStreetMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: NavHudTokens.nextTurnStreetWeight,
                        fontSize: streetDp,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
