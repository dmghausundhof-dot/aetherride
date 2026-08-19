import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../domain/community/ride_group_pin.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/hof_threshold_nav.dart';
import 'ride_hud_island.dart';

/// Eine Zeile während der Fahrt: wer teilt, Restzeit, Opt-out.
class RideGroupLiveBar extends StatelessWidget {
  const RideGroupLiveBar({
    super.key,
    required this.snap,
    required this.onToggleOptIn,
    this.now,
    this.onFriend,
    this.onFrameAll,
    this.onExtend,
    this.onLeave,
    this.onInvite,
  });

  final RideGroupHudSnap snap;
  final ValueChanged<bool> onToggleOptIn;
  final DateTime? now;
  final ValueChanged<RideGroupHudMate>? onFriend;
  final VoidCallback? onFrameAll;
  final VoidCallback? onExtend;
  final VoidCallback? onLeave;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = friendWindowLeft(
      end: snap.windowEnd,
      now: now ?? DateTime.now(),
      closed: l10n.rideGroupHudClosed,
      hours: l10n.rideGroupHudHours,
      mins: l10n.rideGroupHudMins,
    );
    final line = rideGroupHudStatusLine(
      snap: snap,
      left: left,
      selfOn: l10n.rideGroupHudSelfOn,
      selfOff: l10n.rideGroupHudSelfOff,
      ratio: l10n.rideGroupHudLine,
      withDetail: l10n.rideGroupHudWithDetail,
      mateDetail: (m) {
        final rel = friendRelLabel(
          m.rel,
          ahead: l10n.rideGroupAhead,
          behind: l10n.rideGroupBehind,
          left: l10n.rideGroupLeft,
          right: l10n.rideGroupRight,
        );
        return friendPinChip(
          name: m.label,
          meters: m.meters,
          stale: m.stale,
          staleLabel: l10n.rideGroupPinStale,
          relLabel: m.stale ? null : rel,
        );
      },
    );
    final sunlight = AppColors.isSunlight(context);
    final ink = sunlight ? AppColors.sunText : AppColors.chipIdleText;
    return RideHudIsland(
      key: const Key('ride-group-live-bar'),
      onTap: () => _openRoster(context),
      padding: const EdgeInsets.fromLTRB(
        NavHudTokens.islandPadH,
        NavHudTokens.islandPadV,
        8,
        NavHudTokens.islandPadV,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NavHudTokens.islandHitDp),
        child: Row(
          children: [
            Icon(
              Icons.pedal_bike_outlined,
              size: 18,
              color: snap.optIn ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: NavHudTokens.layerLabelDp,
                  fontWeight: NavHudTokens.layerLabelWeight,
                  height: 1.1,
                  color: ink,
                ),
              ),
            ),
            Switch.adaptive(
              key: const Key('ride-group-live-opt'),
              value: snap.optIn,
              onChanged: onToggleOptIn,
            ),
          ],
        ),
      ),
    );
  }

  void _openRoster(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => RideGroupRosterSheet(
        snap: snap,
        now: now,
        onFriend: onFriend,
        onFrameAll: onFrameAll,
        onExtend: onExtend,
        onLeave: onLeave,
        onInvite: onInvite,
      ),
    );
  }
}

class RideGroupRosterSheet extends StatelessWidget {
  const RideGroupRosterSheet({
    super.key,
    required this.snap,
    this.now,
    this.onFriend,
    this.onFrameAll,
    this.onExtend,
    this.onLeave,
    this.onInvite,
  });

  final RideGroupHudSnap snap;
  final DateTime? now;
  final ValueChanged<RideGroupHudMate>? onFriend;
  final VoidCallback? onFrameAll;
  final VoidCallback? onExtend;
  final VoidCallback? onLeave;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          HofThresholdNav.sheetBottomInset(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              snap.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.rideGroupRosterTitle,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            for (final m in snap.mates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  key: Key('ride-group-roster-${m.userId}'),
                  onTap: m.self || onFriend == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onFriend!(m);
                        },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: m.sharing
                            ? AppColors.accent
                            : AppColors.overlay,
                        foregroundColor:
                            m.sharing ? AppColors.onAccent : AppColors.muted,
                        child: Text(
                          friendPinInitials(m.label),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _mateStatus(m, l10n),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (snap.isSession) ...[
              const SizedBox(height: 8),
              Text(
                snap.atCap
                    ? l10n.rideTogetherFull
                    : l10n.rideTogetherClosedHint,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (snap.joinCode != null && snap.joinCode!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    snap.joinCode!,
                    key: const Key('ride-together-roster-code'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              if (onInvite != null && !snap.atCap)
                OutlinedButton(
                  key: const Key('ride-together-invite'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onInvite!();
                  },
                  child: Text(l10n.rideTogetherInvite),
                ),
            ],
            if (onFrameAll != null || onExtend != null || onLeave != null) ...[
              const SizedBox(height: 8),
              if (onFrameAll != null)
                OutlinedButton(
                  key: const Key('ride-group-frame-all'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onFrameAll!();
                  },
                  child: Text(l10n.rideGroupFrameAll),
                ),
              if (onExtend != null && snap.selfIsHost)
                OutlinedButton(
                  key: const Key('ride-group-extend'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onExtend!();
                  },
                  child: Text(l10n.rideGroupExtend),
                ),
              if (onLeave != null)
                TextButton(
                  key: const Key('ride-group-leave'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onLeave!();
                  },
                  child: Text(
                    snap.isSession
                        ? l10n.platzLeave
                        : (snap.selfIsHost ? l10n.platzDissolve : l10n.platzLeave),
                  ),
                ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  String _mateStatus(RideGroupHudMate m, AppLocalizations l10n) {
    if (m.self) {
      return snap.optIn ? l10n.rideGroupShareOn : l10n.rideGroupMute;
    }
    if (!m.sharing) return l10n.rideGroupOffline;
    if (m.stale) return l10n.rideGroupPinStale;
    if (m.meters == null) return l10n.rideGroupShareOn;
    final rel = friendRelLabel(
      m.rel,
      ahead: l10n.rideGroupAhead,
      behind: l10n.rideGroupBehind,
      left: l10n.rideGroupLeft,
      right: l10n.rideGroupRight,
    );
    final dist = friendDistLabel(m.meters!);
    return rel == null || rel.isEmpty ? dist : '$dist $rel';
  }
}
