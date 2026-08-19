import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/community/ride_group_pin.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/hof_threshold_nav.dart';

/// Distanz und Richtung — kein erfundenes „kommt / wartet“.
class RideGroupFriendSheet extends StatelessWidget {
  const RideGroupFriendSheet({
    super.key,
    required this.mate,
    this.onFlyTo,
  });

  final RideGroupHudMate mate;
  final VoidCallback? onFlyTo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rel = friendRelLabel(
      mate.rel,
      ahead: l10n.rideGroupAhead,
      behind: l10n.rideGroupBehind,
      left: l10n.rideGroupLeft,
      right: l10n.rideGroupRight,
    );
    final line = mate.sharing
        ? friendPinChip(
            name: mate.label,
            meters: mate.meters,
            stale: mate.stale,
            staleLabel: l10n.rideGroupPinStale,
            relLabel: mate.stale ? null : rel,
          )
        : '${friendPinName(mate.label)} · ${l10n.rideGroupOffline}';
    final canFly = onFlyTo != null && mate.lat != null && mate.lng != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          HofThresholdNav.sheetBottomInset(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      mate.sharing ? AppColors.accent : AppColors.overlay,
                  foregroundColor:
                      mate.sharing ? AppColors.onAccent : AppColors.muted,
                  child: Text(
                    friendPinInitials(mate.label),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (canFly) ...[
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('ride-group-fly-to'),
                onPressed: () {
                  onFlyTo!();
                  Navigator.of(context).maybePop();
                },
                child: Text(l10n.rideGroupFlyTo),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
