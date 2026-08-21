import 'package:flutter/material.dart';

import '../../../domain/routing/browse_map_paint.dart';
import '../../../l10n/app_localizations.dart';

/// Drei Farbpunkte unter den Layer-Chips: Asphalt · Schotter · Pfad.
class BrowseMapLegend extends StatelessWidget {
  const BrowseMapLegend({
    super.key,
    this.visible = true,
    this.trailsOn = true,
    this.waysOn = true,
  });

  final bool visible;
  final bool trailsOn;
  final bool waysOn;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final swatches = <Widget>[
      if (waysOn) _swatch(BrowseMapPaint.wayHex, l10n.browseMapLegendPaved),
      if (trailsOn) _swatch(BrowseMapPaint.gravelHex, l10n.browseMapLegendGravel),
      if (trailsOn) _swatch(BrowseMapPaint.trailHex, l10n.browseMapLegendTrail),
    ];
    if (swatches.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('browse-map-legend'),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          for (var i = 0; i < swatches.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            swatches[i],
          ],
        ],
      ),
    );
  }

  Widget _swatch(String hex, String label) {
    final h = hex.replaceFirst('#', '');
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(int.parse('FF$h', radix: 16)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
