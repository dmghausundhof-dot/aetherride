import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Entdecken: Touren | Orte | Heat. Heat zeichnet nur mit Consent.
class DiscoverLayerChips extends StatelessWidget {
  const DiscoverLayerChips({
    super.key,
    required this.toursOn,
    required this.placesOn,
    required this.heatOn,
    required this.heatConsent,
    required this.onTours,
    required this.onPlaces,
    required this.onHeat,
  });

  final bool toursOn;
  final bool placesOn;
  final bool heatOn;
  final bool heatConsent;
  final ValueChanged<bool> onTours;
  final ValueChanged<bool> onPlaces;
  final VoidCallback onHeat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Wrap(
          spacing: 4,
          children: [
            FilterChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(l10n.discoverLayerTours, style: const TextStyle(fontSize: 11)),
              selected: toursOn,
              onSelected: onTours,
            ),
            FilterChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(l10n.discoverLayerPlaces, style: const TextStyle(fontSize: 11)),
              selected: placesOn,
              onSelected: onPlaces,
            ),
            FilterChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(
                heatConsent ? l10n.discoverLayerHeat : l10n.discoverLayerHeatOff,
                style: const TextStyle(fontSize: 11),
              ),
              selected: heatOn && heatConsent,
              onSelected: (_) => onHeat(),
            ),
          ],
        ),
      ),
    );
  }
}
