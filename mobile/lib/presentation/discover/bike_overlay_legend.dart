import 'package:flutter/material.dart';

import '../../domain/routing/bike_overlay_class.dart';
import '../../l10n/app_localizations.dart';

class BikeOverlayLegend extends StatefulWidget {
  const BikeOverlayLegend({
    super.key,
    required this.family,
    required this.visible,
    required this.extraOn,
    required this.onToggleVisible,
    required this.onToggleClass,
  });

  final BikeOverlayFamily family;
  final bool visible;
  final Set<BikeOverlayClass> extraOn;
  final VoidCallback onToggleVisible;
  final ValueChanged<BikeOverlayClass> onToggleClass;

  @override
  State<BikeOverlayLegend> createState() => _BikeOverlayLegendState();
}

class _BikeOverlayLegendState extends State<BikeOverlayLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = overlayLegendRows(
      family: widget.family,
      expanded: _expanded,
    );
    final compact = overlayLegendCompactKey(widget.family);
    final compactLabel = switch (compact) {
      'mtb' => l10n.overlayLegendCompactMtb,
      'gravel' => 'Gravel',
      'road' => 'Asphalt',
      _ => l10n.overlayLegendCompactCity,
    };
    final showNote = _expanded && overlayLegendShowsSScale(widget.family);

    return Material(
      key: const Key('bike-overlay-legend'),
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 168),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.overlayLegendTitle} · $compactLabel',
                                key: const Key('bike-overlay-legend-title'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: widget.onToggleVisible,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        widget.visible ? l10n.onLabel : l10n.offLabel,
                        key: const Key('bike-overlay-legend-visible'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              for (final row in rows)
                InkWell(
                  onTap: () => widget.onToggleClass(row.cls),
                  child: Opacity(
                    opacity: widget.visible && widget.extraOn.contains(row.cls)
                        ? 1
                        : 0.38,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _colorFor(row.key),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _labelFor(l10n, row.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (showNote) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.overlayScaleNote,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    height: 1.25,
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

String _labelFor(AppLocalizations l10n, String key) => switch (key) {
      'unrated' => l10n.overlayUnrated,
      'road' => l10n.overlayRoadAsphalt,
      'urban' => l10n.overlayLegendCompactCity,
      'gravel' => 'Gravel',
      _ => key,
    };

Color _colorFor(String key) {
  final css = switch (key) {
    'S0' => BikeOverlayColors.s0,
    'S1' => BikeOverlayColors.s1,
    'S2' => BikeOverlayColors.s2,
    'S3+' => BikeOverlayColors.s3,
    'unrated' => BikeOverlayColors.unrated,
    'gravel' => BikeOverlayColors.gravel,
    'road' => BikeOverlayColors.road,
    _ => BikeOverlayColors.urban,
  };
  final h = css.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
