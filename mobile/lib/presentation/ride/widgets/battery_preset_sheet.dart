import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/battery_preset.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../shared/chrome_glyph.dart';

/// Opt-in battery / display preset picker (N-04 / N-09).
/// Default recommendation: Pocket (no Keep-Screen-On).
Future<RideBatteryPreset?> showBatteryPresetSheet(
  BuildContext context, {
  required RideBatteryPreset current,
}) {
  return showModalBottomSheet<RideBatteryPreset>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.rideBatteryTitle,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.rideBatteryHint,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.meta(ctx),
                    ),
              ),
              const SizedBox(height: AppSpacing.m),
              for (final p in RideBatteryPreset.values) ...[
                _PresetTile(
                  preset: p,
                  selected: p == current,
                  onTap: () => Navigator.of(ctx).pop(p),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final RideBatteryPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mark = switch (preset) {
      RideBatteryPreset.pocket => 'phone',
      RideBatteryPreset.lenker => 'lock',
      RideBatteryPreset.ultra => 'bell',
    };

    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              ChromeGlyph(
                mark,
                size: 22,
                color: selected ? AppColors.accent : null,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.batteryPresetTitle(preset),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (preset.costsBattery) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              l10n.rideCostsBattery,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                        if (preset == RideBatteryPreset.pocket) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.rideDefault,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sageOnDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.batteryPresetSubtitle(preset),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.meta(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const ChromeGlyph('check', size: 22, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
