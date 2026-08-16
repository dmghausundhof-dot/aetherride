import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';

/// Bottom data strip: Tempo · noch km · Ziel (N-HUD-01 / nav-hud-tokens-v1).
/// Together with next-turn these are the only four Clean Mode HUD elements.
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
    final theme = Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: theme.cardColor.withValues(alpha: 0.78),
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
              _stat(context, speedLabel, speedCaption),
              _stat(context, midValue, midLabel),
              _stat(context, rightValue, rightLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: NavHudTokens.statValueDp,
              fontWeight: NavHudTokens.statValueWeight,
              fontFeatures: [FontFeature.tabularFigures()],
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: NavHudTokens.statLabelDp,
              fontWeight: NavHudTokens.statLabelWeight,
              color: AppColors.meta(context),
            ),
          ),
        ],
      ),
    );
  }
}
