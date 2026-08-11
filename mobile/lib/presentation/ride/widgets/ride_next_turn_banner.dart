import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';

/// Dominant next-turn HUD pill — glanceable at speed (N-HUD-01 / nav-hud-tokens-v1).
/// Hierarchy: large distance → turn glyph → street (1-line) secondary.
class RideNextTurnBanner extends StatelessWidget {
  const RideNextTurnBanner({
    super.key,
    required this.distance,
    required this.instruction,
    required this.icon,
  });

  final String distance;
  final String instruction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final distanceDp = NavHudTokens.nextTurnDistanceSize(context);
    final glyphDp = NavHudTokens.nextTurnGlyphSize(context);
    final streetDp = NavHudTokens.nextTurnStreetSize(context);

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
                      instruction,
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
