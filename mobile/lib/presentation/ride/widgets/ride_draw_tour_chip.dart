import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Freeride-HUD: Spur wird zur Tour, ohne vorher zu planen.
class RideDrawTourChip extends StatelessWidget {
  const RideDrawTourChip({
    super.key,
    required this.drawing,
    required this.onToggle,
  });

  final bool drawing;
  final VoidCallback onToggle;

  static const chipKey = Key('ride-draw-tour');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = drawing ? l10n.rideDrawingTour : l10n.rideDrawTour;
    return Material(
      color: drawing
          ? AppColors.accent.withValues(alpha: 0.18)
          : Theme.of(context).cardColor.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        key: chipKey,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                drawing ? Icons.timeline : Icons.timeline_outlined,
                size: 16,
                color: drawing ? AppColors.accent : AppColors.chipIdleText,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: drawing ? AppColors.accent : AppColors.chipIdleText,
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
