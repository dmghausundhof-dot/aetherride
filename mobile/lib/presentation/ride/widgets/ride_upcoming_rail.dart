import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/upcoming_rail.dart';

/// One-line peek under next-turn (N-07) — stays thin in Clean Mode.
class RideUpcomingRail extends StatelessWidget {
  const RideUpcomingRail({
    super.key,
    required this.item,
  });

  final UpcomingRailItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.kind) {
      'poi' => Icons.place_outlined,
      'climb' => Icons.terrain_outlined,
      _ => Icons.subdirectory_arrow_right,
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
              Icon(icon, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                'Danach',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted.withValues(alpha: 0.9),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
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
