import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../l10n/app_localizations.dart';
import 'garage_chrome.dart';

/// Technische Specs hinter einer Klappe — ohne Duplikate der Werte-Leiste.
class BikeTechDetailsPanel extends StatelessWidget {
  const BikeTechDetailsPanel({
    super.key,
    required this.bike,
    this.initiallyExpanded = false,
  });

  final Bike bike;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String)>[
      if (bike.brand != null || bike.model != null)
        (
          l10n.garageBrandModel,
          [
            if (bike.brand != null) bike.brand!,
            if (bike.model != null) bike.model!,
            if (bike.year != null) '${bike.year}',
          ].join(' '),
        ),
      if (bike.frameSize != null && bike.frameSize!.isNotEmpty)
        (l10n.garageFrameSize, bike.frameSize!),
      if (bike.wheelSize != null) (l10n.garageWheelSize, bike.wheelSize!.label),
      if (bike.travelFrontMm != null)
        (
          l10n.garageTravel,
          '${bike.travelFrontMm}/${bike.travelRearMm ?? '–'} mm',
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.s),
        title: GarageSectionTitle(label: l10n.garageTechDetails),
        subtitle: Text(
          l10n.garageTechHint,
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
