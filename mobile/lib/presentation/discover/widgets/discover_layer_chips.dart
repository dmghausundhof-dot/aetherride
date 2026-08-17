import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/browse_map_paint.dart';
import '../../../l10n/app_localizations.dart';

/// Karten-Layer: vier gleiche Toggles, keine FilterChip-Haken und kein „Tour…“.
class DiscoverLayerChips extends StatelessWidget {
  const DiscoverLayerChips({
    super.key,
    required this.toursOn,
    required this.trailsOn,
    required this.waysOn,
    required this.hillshadeOn,
    required this.onTours,
    required this.onTrails,
    required this.onWays,
    required this.onHillshade,
    this.showLegend = true,
  });

  final bool toursOn;
  final bool trailsOn;
  final bool waysOn;
  final bool hillshadeOn;
  final ValueChanged<bool> onTours;
  final ValueChanged<bool> onTrails;
  final ValueChanged<bool> onWays;
  final ValueChanged<bool> onHillshade;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final legendOn = showLegend && (trailsOn || waysOn);
    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _cell(
                  key: const Key('discover-layer-tours'),
                  icon: Icons.flag_outlined,
                  label: l10n.discoverLayerTours,
                  on: toursOn,
                  onTap: () => onTours(!toursOn),
                ),
                _cell(
                  key: const Key('discover-layer-trails'),
                  icon: Icons.terrain,
                  label: l10n.discoverLayerTrails,
                  on: trailsOn,
                  accent: BrowseMapPaint.trailHex,
                  onTap: () => onTrails(!trailsOn),
                ),
                _cell(
                  key: const Key('discover-layer-ways'),
                  icon: Icons.alt_route,
                  label: l10n.discoverLayerWays,
                  on: waysOn,
                  accent: BrowseMapPaint.wayHex,
                  onTap: () => onWays(!waysOn),
                ),
                _cell(
                  key: const Key('discover-layer-height'),
                  icon: Icons.landscape_outlined,
                  label: l10n.discoverLayerHeight,
                  on: hillshadeOn,
                  tooltip: l10n.discoverLayerHeightHint,
                  onTap: () => onHillshade(!hillshadeOn),
                ),
              ],
            ),
            if (legendOn) ...[
              const SizedBox(height: 2),
              const _LayerLegend(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cell({
    required Key key,
    required IconData icon,
    required String label,
    required bool on,
    required VoidCallback onTap,
    String? tooltip,
    String? accent,
  }) {
    final mark = accent == null
        ? null
        : Color(int.parse('FF${accent.replaceFirst('#', '')}', radix: 16));
    return Expanded(
      child: Tooltip(
        message: tooltip ?? label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: on
                    ? AppColors.overlay.withValues(alpha: 0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border(
                  bottom: BorderSide(
                    color: on
                        ? (mark ?? AppColors.accent)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: on
                        ? (mark ?? AppColors.accent)
                        : AppColors.muted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: on
                          ? AppColors.chipIdleText
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayerLegend extends StatelessWidget {
  const _LayerLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const Key('browse-map-legend'),
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      child: Row(
        children: [
          _dot(BrowseMapPaint.wayHex, l10n.browseMapLegendPaved),
          const SizedBox(width: 10),
          _dot(BrowseMapPaint.gravelHex, l10n.browseMapLegendGravel),
          const SizedBox(width: 10),
          _dot(BrowseMapPaint.trailHex, l10n.browseMapLegendTrail),
        ],
      ),
    );
  }

  Widget _dot(String hex, String label) {
    final h = hex.replaceFirst('#', '');
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
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
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
