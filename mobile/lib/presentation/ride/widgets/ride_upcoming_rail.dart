import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/upcoming_rail.dart';
import '../../../l10n/l10n_ext.dart';
import '../../library/mappe_glyph.dart';

/// One-line peek under next-turn (N-07) — stays thin in Clean Mode.
class RideUpcomingRail extends StatelessWidget {
  const RideUpcomingRail({
    super.key,
    required this.item,
  });

  final UpcomingRailItem item;

  @override
  Widget build(BuildContext context) {
    final mark = switch (item.kind) {
      'poi' => const MappeGlyph('mappe', size: 16),
      'climb' => const MappeGlyph('elevation', size: 16),
      _ => const MappeGlyph('distance', size: 16),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Material(
        color: Theme.of(context).cardColor.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              mark,
              const SizedBox(width: 6),
              Text(
                context.l10nOrNull?.rideThereafter ?? 'Danach',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.meta(context).withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.detail != null) ...[
                const SizedBox(width: 6),
                Text(
                  item.detail!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.meta(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
