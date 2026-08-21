import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../domain/active_route.dart';
import '../../shared/chrome_glyph.dart';
import 'ride_hud_island.dart';

/// Karte / Daten / Fahrwerk — charcoal HUD island, orange only for the active tab.
class RideHudLayerBar extends StatelessWidget {
  const RideHudLayerBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.mapLabel,
    required this.dataLabel,
    this.chassisLabel,
    this.onClose,
    this.closeLabel,
    this.body,
  });

  final RideLiveLayer selected;
  final ValueChanged<RideLiveLayer> onSelected;
  final String mapLabel;
  final String dataLabel;
  final String? chassisLabel;
  final VoidCallback? onClose;
  final String? closeLabel;

  /// Daten / Fahrwerk — same island as the tabs, not a second overlay.
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final tabs = Row(
      children: [
        _seg(
          context,
          value: RideLiveLayer.map,
          label: mapLabel,
          mark: 'karte',
          keyName: 'ride-hud-layer-map',
        ),
        _seg(
          context,
          value: RideLiveLayer.data,
          label: dataLabel,
          mark: 'heat',
          keyName: 'ride-hud-layer-data',
        ),
        if (chassisLabel != null)
          _seg(
            context,
            value: RideLiveLayer.suspension,
            label: chassisLabel!,
            mark: 'filter',
            keyName: 'ride-hud-layer-suspension',
          ),
        if (onClose != null) _close(context),
      ],
    );
    return RideHudIsland(
      key: const Key('ride-hud-layer-bar'),
      padding: body == null
          ? const EdgeInsets.all(4)
          : const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: body == null
          ? tabs
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabs,
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: body,
                ),
              ],
            ),
    );
  }

  Widget _close(BuildContext context) {
    final sunlight = AppColors.isSunlight(context);
    final idle = sunlight ? AppColors.sunText : AppColors.chipIdleText;
    final label = closeLabel ?? 'HUD zu';
    return Material(
      key: const Key('ride-hud-close'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onClose,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 56,
            minHeight: NavHudTokens.layerBarMinHeightDp,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.close,
                  size: NavHudTokens.layerIconDp,
                  color: AppColors.meta(context),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: NavHudTokens.layerLabelDp,
                    fontWeight: NavHudTokens.layerLabelWeight,
                    height: 1.1,
                    color: idle.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seg(
    BuildContext context, {
    required RideLiveLayer value,
    required String label,
    required String mark,
    required String keyName,
  }) {
    final sunlight = AppColors.isSunlight(context);
    final on = selected == value;
    final accent = sunlight ? AppColors.sunAccent : AppColors.accent;
    final idle = sunlight ? AppColors.sunText : AppColors.chipIdleText;
    return Expanded(
      child: Material(
        key: Key(keyName),
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minHeight: NavHudTokens.layerBarMinHeightDp,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              color: on
                  ? accent.withValues(alpha: sunlight ? 0.12 : 0.16)
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChromeGlyph(
                  mark,
                  size: NavHudTokens.layerIconDp,
                  color: on ? accent : AppColors.meta(context),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: NavHudTokens.layerLabelDp,
                    fontWeight: NavHudTokens.layerLabelWeight,
                    height: 1.1,
                    color: on ? accent : idle.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
