import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/browse_map_paint.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../garage/rad_glyph.dart';
import '../../library/mappe_glyph.dart';
import '../../shell/hof_threshold_nav.dart';

/// Werkzeuge im Karteninhalt — keine Layer-Toggles.
enum DiscoverMapContentsTool { collections, photos, offline }

/// Packname, plus Übersicht nur wenn sie wirklich fehlt.
String? mapContentsOfflineSubtitle({
  required AppLocalizations l10n,
  required bool offlineReady,
  String? packLabel,
  String? packId,
  bool? overviewReady,
}) {
  if (!offlineReady) return null;
  final name = packLabel?.trim() ?? '';
  final routing = name.isEmpty
      ? l10n.offlineRoutingOn
      : l10n.offlineCoverageLabelFor(name, packId: packId);
  if (overviewReady == false) {
    return '$routing · ${l10n.offlineOverviewOff}';
  }
  return routing;
}

/// Trails / Heat / Orte stay online — quiet, not a fake empty map.
String? mapContentsLayersNeedNetCaption({
  required AppLocalizations l10n,
  required bool browseOnline,
  required bool trailsOn,
  required bool heatOn,
  required bool placesOn,
}) {
  if (browseOnline) return null;
  if (!trailsOn && !heatOn && !placesOn) return null;
  return l10n.discoverLayersNeedNet;
}

/// Karteninhalt: Layer als Kacheln, Werkzeuge darunter.
///
/// Filter bleiben in der Leiste. Offline, Fotos und Sammlungen sitzen
/// hier einmal — nicht nochmal als Chip oder Junk-Menü.
class DiscoverMapContentsSheet extends StatelessWidget {
  const DiscoverMapContentsSheet({
    super.key,
    required this.toursOn,
    required this.trailsOn,
    required this.waysOn,
    required this.hillshadeOn,
    required this.placesOn,
    required this.heatOn,
    required this.heatLocked,
    required this.offlineReady,
    this.offlinePackLabel,
    this.offlinePackId,
    this.offlineOverviewReady,
    this.browseOnline = true,
    required this.onTours,
    required this.onTrails,
    required this.onWays,
    required this.onHillshade,
    this.farmTracksOn = true,
    this.onFarmTracks,
    required this.onPlaces,
    required this.onHeat,
    required this.onTool,
  });

  final bool toursOn;
  final bool trailsOn;
  final bool waysOn;
  final bool hillshadeOn;
  final bool placesOn;
  final bool heatOn;
  final bool heatLocked;
  final bool offlineReady;
  final String? offlinePackLabel;
  final String? offlinePackId;
  final bool? offlineOverviewReady;
  final bool browseOnline;
  final ValueChanged<bool> onTours;
  final ValueChanged<bool> onTrails;
  final ValueChanged<bool> onWays;
  final bool farmTracksOn;
  final ValueChanged<bool>? onFarmTracks;
  final ValueChanged<bool> onHillshade;
  final ValueChanged<bool> onPlaces;
  final VoidCallback onHeat;
  final ValueChanged<DiscoverMapContentsTool> onTool;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          HofThresholdNav.sheetBottomInset(context),
        ),
        child: SingleChildScrollView(
          key: const Key('discover-map-contents-sheet'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.discoverMapContentsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.discoverMapContentsLayers,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.92,
                children: [
                  _LayerTile(
                    key: const Key('discover-layer-tours'),
                    mark: const MappeGlyph('mappe', size: 22),
                    label: l10n.discoverLayerTours,
                    on: toursOn,
                    accent: AppColors.accent,
                    onTap: () => onTours(!toursOn),
                  ),
                  _LayerTile(
                    key: const Key('discover-layer-trails'),
                    mark: const MappeGlyph('elevation', size: 22),
                    label: l10n.discoverLayerTrails,
                    on: trailsOn,
                    accent: _hex(BrowseMapPaint.trailHex),
                    onTap: () => onTrails(!trailsOn),
                  ),
                  _LayerTile(
                    key: const Key('discover-layer-ways'),
                    mark: const MappeGlyph('distance', size: 22),
                    label: l10n.discoverLayerWays,
                    on: waysOn,
                    accent: _hex(BrowseMapPaint.wayHex),
                    onTap: () => onWays(!waysOn),
                  ),
                  _LayerTile(
                    key: const Key('discover-layer-farm-tracks'),
                    mark: SvgPicture.asset(
                      'assets/map/pins/glyph-gravel.svg',
                      width: 22,
                      height: 14,
                      excludeFromSemantics: true,
                    ),
                    label: l10n.discoverLayerFarmTracks,
                    on: farmTracksOn && waysOn,
                    accent: _hex(BrowseMapPaint.gravelHex),
                    tooltip: l10n.discoverLayerFarmTracksHint,
                    onTap: () {
                      if (!waysOn) {
                        onWays(true);
                        onFarmTracks?.call(true);
                        return;
                      }
                      onFarmTracks?.call(!farmTracksOn);
                    },
                  ),
                  _LayerTile(
                    key: const Key('discover-layer-height'),
                    mark: SvgPicture.asset(
                      'assets/map/pins/logo-mark-compact.svg',
                      width: 22,
                      height: 12,
                      excludeFromSemantics: true,
                    ),
                    label: l10n.discoverLayerHeight,
                    on: hillshadeOn,
                    accent: AppColors.sage,
                    tooltip: l10n.discoverLayerHeightHint,
                    onTap: () => onHillshade(!hillshadeOn),
                  ),
                  _LayerTile(
                    key: const Key('discover-layer-places'),
                    mark: Image.asset(
                      'assets/map/pins/poi.png',
                      width: 18,
                      height: 22,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    label: l10n.discoverLayerPlaces,
                    on: placesOn,
                    accent: AppColors.accentHover,
                    onTap: () => onPlaces(!placesOn),
                  ),
                  _LayerTile(
                    key: const Key('discover-layer-heat'),
                    mark: heatLocked
                        ? const RadGlyph('lock', size: 22)
                        : SvgPicture.asset(
                            'assets/brand/boot/orange.svg',
                            width: 22,
                            height: 10,
                            excludeFromSemantics: true,
                            colorFilter: const ColorFilter.mode(
                              AppColors.warning,
                              BlendMode.srcIn,
                            ),
                          ),
                    label: l10n.discoverLayerHeat,
                    subtitle: heatLocked ? l10n.discoverLayerHeatLocked : null,
                    on: heatOn && !heatLocked,
                    accent: AppColors.warning,
                    onTap: onHeat,
                  ),
                ],
              ),
              if (mapContentsLayersNeedNetCaption(
                l10n: l10n,
                browseOnline: browseOnline,
                trailsOn: trailsOn,
                heatOn: heatOn,
                placesOn: placesOn,
              )
                  case final layersNet?) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  layersNet,
                  key: const Key('discover-layers-need-net'),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.muted,
                  ),
                ),
              ],
              if (trailsOn || waysOn) ...[
                const SizedBox(height: AppSpacing.s),
                DiscoverMapLegend(
                  padded: false,
                  trailsOn: trailsOn,
                  waysOn: waysOn,
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              Text(
                l10n.discoverMapContentsTools,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Material(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ToolRow(
                      key: const Key('discover-map-tool-offline'),
                      mark: RadGlyph(
                        offlineReady ? 'ready' : 'add',
                        size: 22,
                      ),
                      label: l10n.discoverMenuOffline,
                      subtitle: mapContentsOfflineSubtitle(
                        l10n: l10n,
                        offlineReady: offlineReady,
                        packLabel: offlinePackLabel,
                        packId: offlinePackId,
                        overviewReady: offlineOverviewReady,
                      ),
                      onTap: () => onTool(DiscoverMapContentsTool.offline),
                    ),
                    const Divider(height: 1),
                    _ToolRow(
                      key: const Key('discover-map-tool-photos'),
                      mark: const RadGlyph('photo', size: 22),
                      label: l10n.discoverMenuPhotos,
                      onTap: () => onTool(DiscoverMapContentsTool.photos),
                    ),
                    const Divider(height: 1),
                    _ToolRow(
                      key: const Key('discover-map-tool-collections'),
                      mark: const MappeGlyph('collection', size: 22),
                      label: l10n.discoverMenuCollections,
                      onTap: () => onTool(DiscoverMapContentsTool.collections),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _hex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.mark,
    required this.label,
    required this.on,
    required this.accent,
    required this.onTap,
    this.subtitle,
    this.tooltip,
  });

  final Widget mark;
  final String label;
  final String? subtitle;
  final bool on;
  final Color accent;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: on
          ? AppColors.overlay.withValues(alpha: 0.92)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: on ? accent.withValues(alpha: 0.85) : AppColors.border,
              width: on ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 22, height: 22, child: Center(child: mark)),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: on ? AppColors.chipIdleText : AppColors.muted,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: AppColors.muted,
                    ),
                  ),
                ] else
                  const SizedBox(height: 6),
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: on ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return tile;
    return Tooltip(message: tooltip, child: tile);
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    super.key,
    required this.mark,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final Widget mark;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(width: 24, height: 24, child: Center(child: mark)),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}

/// Kompakte Farblegende auf der Karte — kein zweiter Layer-Balken.
class DiscoverMapLegend extends StatelessWidget {
  const DiscoverMapLegend({
    super.key,
    this.padded = true,
    this.trailsOn = true,
    this.waysOn = true,
  });

  final bool padded;
  final bool trailsOn;
  final bool waysOn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final swatches = <Widget>[
      if (waysOn) _dot(BrowseMapPaint.wayHex, l10n.browseMapLegendPaved),
      if (trailsOn) _dot(BrowseMapPaint.gravelHex, l10n.browseMapLegendGravel),
      if (trailsOn) _dot(BrowseMapPaint.trailHex, l10n.browseMapLegendTrail),
    ];
    if (swatches.isEmpty) return const SizedBox.shrink();
    final row = Row(
      key: const Key('browse-map-legend'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < swatches.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          swatches[i],
        ],
      ],
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Theme.of(context).cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: padded
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
              : const EdgeInsets.fromLTRB(2, 2, 2, 2),
          child: row,
        ),
      ),
    );
  }

  Widget _dot(String hex, String label) {
    final h = hex.replaceFirst('#', '');
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.1,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
