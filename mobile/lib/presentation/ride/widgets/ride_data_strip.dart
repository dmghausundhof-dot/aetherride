import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';

/// Bottom data strip: Tempo · noch km · Ziel (N-HUD-01 / nav-hud-tokens-v1).
/// Charcoal on orange — same chrome as next-turn / Pause, with or without a route.
class RideDataStrip extends StatelessWidget {
  const RideDataStrip({
    super.key,
    required this.speedLabel,
    required this.midValue,
    required this.midLabel,
    required this.rightValue,
    required this.rightLabel,
    this.speedCaption = NavHudTokens.labelSpeed,
    this.onTap,
  });

  final String speedLabel;
  final String speedCaption;
  final String midValue;
  final String midLabel;
  final String rightValue;
  final String rightLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.chromeFill(context);
    final ink = AppColors.inkOnChrome(context);
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: fill,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s,
            horizontal: AppSpacing.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(speedLabel, speedCaption, ink),
              _stat(midValue, midLabel, ink),
              _stat(rightValue, rightLabel, ink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color ink) {
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: NavHudTokens.statValueDp,
                fontWeight: NavHudTokens.statValueWeight,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.05,
                color: ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: NavHudTokens.statLabelDp,
                fontWeight: NavHudTokens.statLabelWeight,
                color: ink.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
