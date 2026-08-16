import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../domain/sport/discipline_ux.dart';
import '../../../l10n/app_localizations.dart';

/// Map-first pre-ride chrome (N-START-01): one primary CTA, no sensor checklist.
///
/// Sensor / Nearby / BLE must never gate the map — they run after HUD is stable.
/// Freeride from „Einfach fahren“ autostarts and skips this chrome.
class RidePreStartChrome extends StatelessWidget {
  const RidePreStartChrome({
    super.key,
    required this.routeName,
    required this.onStart,
    this.starting = false,
    this.onClearRoute,
  });

  /// Active route title, or null for freeride.
  final String? routeName;

  /// Primary Start / Losfahren action.
  final VoidCallback? onStart;

  /// True while permissions / start handoff is in flight.
  final bool starting;

  /// Optional dismiss for the loaded route chip.
  final VoidCallback? onClearRoute;

  /// Primary CTA label — DE-Fallback für Unit-Tests ohne Locale-Binding.
  static String primaryLabel({required bool hasRoute}) =>
      hasRoute ? MultiSportCopy.goRide : MultiSportCopy.startFreeride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasRoute = routeName != null && routeName!.isNotEmpty;
    final label = starting
        ? l10n.starting
        : (hasRoute ? l10n.goRide : l10n.startFreeride);

    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        if (hasRoute)
          Positioned(
            top: topInset + 12,
            left: 12,
            right: 12,
            child: Material(
              color: theme.cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: ListTile(
                dense: true,
                title: Text(
                  routeName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l10n.rideMapReady,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: onClearRoute == null
                    ? null
                    : IconButton(
                        tooltip: l10n.rideClearRoute,
                        icon: const Icon(Icons.close),
                        onPressed: starting ? null : onClearRoute,
                      ),
              ),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: FilledButton(
              key: const Key('ride-primary-start'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.chromeFill(context),
                foregroundColor: AppColors.inkOnChrome(context),
                disabledBackgroundColor:
                    AppColors.chromeFill(context).withValues(alpha: 0.7),
                minimumSize: const Size.fromHeight(
                  NavHudTokens.startCtaMinHeightDp,
                ),
              ),
              onPressed: starting ? null : onStart,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
