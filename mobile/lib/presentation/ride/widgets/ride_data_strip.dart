import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bottom data strip: Speed · Rest/Dist · ETA (N-01 Clean Mode).
class RideDataStrip extends StatelessWidget {
  const RideDataStrip({
    super.key,
    required this.speedLabel,
    required this.midValue,
    required this.midLabel,
    required this.rightValue,
    required this.rightLabel,
    this.onTap,
  });

  final String speedLabel;
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
      color: theme.cardColor.withValues(alpha: 0.94),
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
              _stat(speedLabel, 'km/h'),
              _stat(midValue, midLabel),
              _stat(rightValue, rightLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
