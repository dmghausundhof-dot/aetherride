import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../domain/community/ride_group_pin.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/hof_threshold_nav.dart';
import 'ride_hud_island.dart';

/// Eine Statusleiste während der Fahrt: wer teilt, Restzeit, Opt-out.
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
    const sep = ' · ';
    final cut = line.lastIndexOf(sep);
    final head = cut < 0 ? line : line.substring(0, cut);
    final tail = cut < 0 ? left : line.substring(cut + sep.length);
    final sunlight = AppColors.isSunlight(context);
    final ink = sunlight ? AppColors.sunText : AppColors.chipIdleText;
    final meta = AppColors.meta(context);
    return RideHudIsland(
      key: const Key('ride-group-live-bar'),
      onTap: () => _openRoster(context),
      padding: const EdgeInsets.fromLTRB(
        NavHudTokens.islandPadH,
        NavHudTokens.islandCompactPadV,
        6,
        NavHudTokens.islandCompactPadV,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NavHudTokens.islandHitDp),
        child: Row(
          children: [
            Icon(
              Icons.pedal_bike_outlined,
              size: 16,
              color: snap.optIn ? AppColors.chromeFill(context) : meta,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      head,
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
                  if (tail.isNotEmpty) ...[
                    Text(
                      sep,
                      style: TextStyle(
                        fontSize: NavHudTokens.layerLabelDp,
                        fontWeight: FontWeight.w500,
                        color: meta,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        tail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: NavHudTokens.layerLabelDp,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          color: meta,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Transform.scale(
              scale: 0.78,
              alignment: Alignment.centerRight,
              child: Switch.adaptive(
                key: const Key('ride-group-live-opt'),
                value: snap.optIn,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onToggleOptIn,
              ),
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
    final meta = AppColors.meta(context);
    final quiet = TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: meta,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          HofThresholdNav.sheetBottomInset(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                snap.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sheetInk(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.rideGroupRosterTitle,
                style: TextStyle(fontSize: 13, color: meta),
              ),
              const SizedBox(height: AppSpacing.m),
              for (final m in snap.mates)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
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
                              ? AppColors.chromeFill(context)
                              : AppColors.overlay,
                          foregroundColor: m.sharing
                              ? AppColors.inkOnChrome(context)
                              : meta,
                          child: Text(
                            friendPinInitials(m.label),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            m.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.sheetInk(context),
                            ),
                          ),
                        ),
                        Text(
                          _mateStatus(m, l10n),
                          style: TextStyle(fontSize: 12, color: meta),
                        ),
                      ],
                    ),
                  ),
                ),
              if (snap.isSession) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  snap.atCap
                      ? l10n.rideTogetherFull
                      : l10n.rideTogetherClosedHint,
                  style: TextStyle(fontSize: 13, color: meta),
                ),
                if (snap.joinCode != null && snap.joinCode!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s),
                    child: Text(
                      snap.joinCode!,
                      key: const Key('ride-together-roster-code'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppColors.sheetInk(context),
                      ),
                    ),
                  ),
                if (onInvite != null && !snap.atCap)
                  TextButton(
                    key: const Key('ride-together-invite'),
                    style: quiet,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onInvite!();
                    },
                    child: Text(l10n.rideTogetherInvite),
                  ),
              ],
              if (onFrameAll != null || onExtend != null || onLeave != null) ...[
                const SizedBox(height: AppSpacing.s),
                if (onFrameAll != null)
                  TextButton(
                    key: const Key('ride-group-frame-all'),
                    style: quiet,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onFrameAll!();
                    },
                    child: Text(l10n.rideGroupFrameAll),
                  ),
                if (onExtend != null && snap.selfIsHost)
                  TextButton(
                    key: const Key('ride-group-extend'),
                    style: quiet,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onExtend!();
                    },
                    child: Text(l10n.rideGroupExtend),
                  ),
                if (onLeave != null)
                  TextButton(
                    key: const Key('ride-group-leave'),
                    style: quiet,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onLeave!();
                    },
                    child: Text(
                      snap.isSession
                          ? l10n.platzLeave
                          : (snap.selfIsHost
                              ? l10n.platzDissolve
                              : l10n.platzLeave),
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
