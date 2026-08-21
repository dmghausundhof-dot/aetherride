import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/chrome_glyph.dart';

/// Street-map honesty on the Ride HUD: overview tiles stop at z11.
class RideStreetNetHint extends StatelessWidget {
  const RideStreetNetHint({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ChromeGlyph(
            'offline',
            size: 16,
            color: AppColors.sageOnDark,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    return Material(
      color: AppColors.charcoal.withValues(alpha: 0.78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: const BorderSide(color: AppColors.sageOnDark, width: 1.2),
      ),
      child: Semantics(
        button: onTap != null,
        label: label,
        child: onTap == null
            ? child
            : InkWell(
                key: const Key('ride-street-net-hint-tap'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: child,
              ),
      ),
    );
  }
}
