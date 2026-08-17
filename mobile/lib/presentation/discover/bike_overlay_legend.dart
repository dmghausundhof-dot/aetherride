import 'package:flutter/material.dart';

import '../../data/routing/bike_overlay.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../l10n/app_localizations.dart';
import 'discover_explore_chrome.dart';

class BikeOverlayLegend extends StatefulWidget {
  const BikeOverlayLegend({
    super.key,
    required this.family,
    required this.visible,
    required this.extraOn,
    required this.onToggleVisible,
    required this.onToggleClass,
    this.hasOverlayData = true,
    this.overlayKind = OnlineBikeOverlayKind.ways,
    this.exploreAll = false,
    this.trailsOn = true,
    this.waysOn = true,
  });

  final BikeOverlayFamily family;
  final bool visible;
  final Set<BikeOverlayClass> extraOn;
  final VoidCallback onToggleVisible;
  final ValueChanged<BikeOverlayClass> onToggleClass;
  final bool hasOverlayData;
  final OnlineBikeOverlayKind overlayKind;
  final bool exploreAll;
  final bool trailsOn;
  final bool waysOn;

  @override
  State<BikeOverlayLegend> createState() => _BikeOverlayLegendState();
}

class _BikeOverlayLegendState extends State<BikeOverlayLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!widget.hasOverlayData) {
      return Material(
        key: const Key('bike-overlay-legend-empty'),
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 168),
            child: Text(
              l10n.overlayLegendEmpty,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ),
      );
    }
    final mesh = widget.overlayKind == OnlineBikeOverlayKind.mesh;
    final rows = mesh
        ? <OverlayLegendRow>[]
        : widget.exploreAll
            ? overlayLegendRowsExplore(
                trailsOn: widget.trailsOn,
                waysOn: widget.waysOn,
                expanded: _expanded,
              )
            : overlayLegendRows(
                family: widget.family,
                expanded: _expanded,
              );
    final compact = overlayLegendCompactKey(widget.family);
    final compactLabel = switch (compact) {
      'mtb' => l10n.overlayLegendCompactMtb,
      'gravel' => l10n.overlayLegendCompactGravel,
      'road' => 'Asphalt',
      _ => l10n.overlayLegendCompactCity,
    };
    final exploreTitle = !widget.trailsOn && widget.waysOn
        ? l10n.overlayLegendWaysTitle
        : widget.trailsOn && !widget.waysOn
            ? l10n.overlayLegendTrailsTitle
            : l10n.overlayLegendAllTitle;
    final title = mesh
        ? l10n.overlayLegendMeshTitle
        : widget.exploreAll
            ? exploreTitle
            : '${l10n.overlayLegendTitle} · $compactLabel';
    final showNote = _expanded &&
        (widget.exploreAll
            ? widget.trailsOn
            : overlayLegendShowsSScale(widget.family));
    final showMeshNote = DiscoverExploreChromeLogic.legendShowsMeshNote(
      isMesh: mesh,
      expanded: _expanded,
    );

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
                                title,
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
              if (showMeshNote || showNote) ...[
                const SizedBox(height: 4),
                Text(
                  showMeshNote
                      ? l10n.overlayLegendMeshNote
                      : l10n.overlayScaleNote,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    height: 1.25,
                  ),
                ),
              ],
              if (!mesh && _expanded) ...[
                const SizedBox(height: 4),
                const Text(
                  'Asphalt blau, Schotter gold, Natur braun. Ohne Tag grau — DACH-Wege noch ohne surface-Feld.',
                  style: TextStyle(
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
      'gravel' => l10n.overlayLegendCompactGravel,
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
