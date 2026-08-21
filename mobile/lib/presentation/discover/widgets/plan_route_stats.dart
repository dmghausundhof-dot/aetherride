import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class PlanRouteStats extends StatelessWidget {
  const PlanRouteStats({
    super.key,
    required this.distanceKm,
    required this.durationMin,
    this.ascentM,
    this.surfaceLine,
    this.looped = false,
    this.uncertainShort,
    this.reasons = const [],
  });

  final double distanceKm;
  final int durationMin;
  final double? ascentM;
  final String? surfaceLine;
  final bool looped;
  final String? uncertainShort;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget cell(String label, String value) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget vSep() => Container(width: 1, height: 36, color: AppColors.border);
    final km = distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0);
    final climb = ascentM != null && ascentM! > 0
        ? '↑ ${ascentM!.round()} m'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (looped)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              uncertainShort == null || uncertainShort!.isEmpty
                  ? l10n.discoverLoopBadge
                  : '${l10n.discoverLoopBadge} · $uncertainShort',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.chrome,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  cell(l10n.discoverDuration, '$durationMin min'),
                  vSep(),
                  cell(l10n.discoverLength, '$km km'),
                ],
              ),
              Container(height: 1, color: AppColors.border),
              Row(
                children: [
                  cell(l10n.discoverAscent, climb),
                  vSep(),
                  cell(
                    l10n.filterSurfaceGroup,
                    (surfaceLine ?? '').trim().isEmpty ? '—' : surfaceLine!,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (reasons.length == 3) ...[
          const SizedBox(height: 6),
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                r,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
        ],
      ],
    );
  }
}
