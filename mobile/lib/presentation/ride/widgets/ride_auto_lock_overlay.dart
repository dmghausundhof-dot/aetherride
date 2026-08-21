import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n_ext.dart';

/// Dims chrome, keeps the map readable. Must sit above the map in a [Stack].
///
/// Uses an opaque [Listener] (not InkWell tap+double-tap) so a single touch
/// unlocks even when MapLibre's [EagerGestureRecognizer] would win the
/// gesture arena. Pair with [IgnorePointer] on the map while locked.
class RideAutoLockOverlay extends StatelessWidget {
  const RideAutoLockOverlay({
    super.key,
    required this.backgroundColor,
    required this.onUnlock,
    this.routeName,
  });

  final Color backgroundColor;
  final VoidCallback onUnlock;
  final String? routeName;

  static const Key overlayKey = Key('ride-auto-lock');
  static const Key unlockButtonKey = Key('ride-auto-lock-unlock');
  static const String title = 'Auto-Lock';
  static const String hint = 'Tippen zum Aufwecken';
  static const String action = 'Aufwecken';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    final titleText = l10n?.rideAutoLock ?? title;
    final hintText = l10n?.rideAutoLockHint ?? hint;
    final actionText = l10n?.rideWake ?? action;
    final dim = backgroundColor.withValues(alpha: 0.42);

    return Positioned.fill(
      child: Listener(
        key: overlayKey,
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onUnlock(),
        child: SizedBox.expand(
          child: ColoredBox(
            color: dim,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Material(
                  color: AppColors.isSunlight(context)
                      ? AppColors.sunSurface.withValues(alpha: 0.94)
                      : AppColors.hofGround.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.m,
                      AppSpacing.m,
                      AppSpacing.m,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          size: 28,
                          color: AppColors.chromeFill(context),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.sheetInk(context),
                                ),
                              ),
                              Text(
                                hintText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.meta(context),
                                ),
                              ),
                              if (routeName != null &&
                                  routeName!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    routeName!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sheetInk(context),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        FilledButton(
                          key: unlockButtonKey,
                          onPressed: onUnlock,
                          child: Text(actionText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
