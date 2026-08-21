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
    final meta = AppColors.meta(context);
    final rel = friendRelLabel(
      mate.rel,
      ahead: l10n.rideGroupAhead,
      behind: l10n.rideGroupBehind,
      left: l10n.rideGroupLeft,
      right: l10n.rideGroupRight,
    );
    final dist = mate.meters == null ? null : friendDistLabel(mate.meters!);
    final rawDetail = !mate.sharing
        ? l10n.rideGroupOffline
        : mate.stale
            ? l10n.rideGroupPinStale
            : [
                if (dist != null) dist,
                if (rel != null && rel.isNotEmpty) rel,
              ].join(' ');
    final detail =
        rawDetail.trim().isEmpty ? l10n.rideGroupShareOn : rawDetail;
    final canFly = onFlyTo != null && mate.lat != null && mate.lng != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
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
                  backgroundColor: mate.sharing
                      ? AppColors.chromeFill(context)
                      : AppColors.overlay,
                  foregroundColor: mate.sharing
                      ? AppColors.inkOnChrome(context)
                      : meta,
                  child: Text(
                    friendPinInitials(mate.label),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendPinName(mate.label),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sheetInk(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: TextStyle(fontSize: 13, color: meta),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canFly) ...[
              const SizedBox(height: AppSpacing.l),
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
