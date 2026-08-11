import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../domain/sport/discipline_ux.dart';

/// Map-first pre-ride chrome (N-START-01): one primary CTA, no sensor checklist.
///
/// Sensor / Nearby / BLE must never gate the map — they run after HUD is stable.
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

  /// Primary CTA label — one green action (Discover + Ride parity).
  static String primaryLabel({required bool hasRoute}) =>
      hasRoute ? MultiSportCopy.goRide : MultiSportCopy.startFreeride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRoute = routeName != null && routeName!.isNotEmpty;
    final label = starting
        ? 'Startet…'
        : primaryLabel(hasRoute: hasRoute);

    return Stack(
      children: [
        if (hasRoute)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              color: theme.cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.navigation,
                  color: NavHudTokens.startCtaGreen,
                ),
                title: Text(
                  routeName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Karte bereit — Sensor optional nach Start',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: onClearRoute == null
                    ? null
                    : IconButton(
                        tooltip: 'Route entfernen',
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
                backgroundColor: NavHudTokens.startCtaGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    NavHudTokens.startCtaGreen.withValues(alpha: 0.7),
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
