import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/hud_bike_peek.dart';
import '../../../l10n/l10n_ext.dart';

/// Thin live-sensor row under the data strip (Pro). Empty when nothing streams.
class RideBikePeek extends StatelessWidget {
  const RideBikePeek({super.key, required this.chips});

  final List<HudBikePeekChip> chips;

  static const rowKey = Key('hud-bike-peek');

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return KeyedSubtree(
      key: rowKey,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s),
            Expanded(child: _chip(context, chips[i])),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, HudBikePeekChip chip) {
    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chip.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                height: 1.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              context.l10nOrNull?.hudPeekLabelFor(chip.label) ?? chip.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.meta(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
