import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Dominant next-turn HUD pill — glanceable at speed (N-01).
/// Hierarchy: large distance → turn affordance → instruction secondary.
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
    return Material(
      elevation: 6,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: AppColors.accent,
      child: ConstrainedBox(
        // N-HUD-01: next-turn glance target ≥48dp (distance numeral + chrome).
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.l,
            AppSpacing.m,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 52),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      distance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -0.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
