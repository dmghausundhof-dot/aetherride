import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'chrome_glyph.dart';

/// Round locate / follow control used on Browse and Ride HUD.
class MapLocateFab extends StatelessWidget {
  const MapLocateFab({
    super.key,
    required this.onTap,
    this.onLongPress,
    this.tooltip,
    this.active = false,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final bool active;

  static const fabKey = Key('map-locate-fab');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.charcoal,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        key: fabKey,
        customBorder: const CircleBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.accent : AppColors.border,
                width: active ? 1.5 : 1,
              ),
            ),
            child: ChromeGlyph(
              'locate',
              size: 22,
              color: active ? AppColors.accent : AppColors.chipIdleText,
            ),
          ),
        ),
      ),
    );
  }
}
