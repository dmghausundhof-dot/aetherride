import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_pin.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../l10n/app_localizations.dart';
import '../ride/widgets/ride_group_extend_sheet.dart';
import '../shell/hof_threshold_nav.dart';

/// Eine Primary, Zeit als Meta-Zeile, Rest hinter Mehr.
class PlatzGroupCard extends StatelessWidget {
  const PlatzGroupCard({
    super.key,
    required this.group,
    required this.members,
    required this.selfIds,
    required this.signedIn,
    required this.optIn,
    required this.onInvite,
    required this.onRide,
    required this.onLeave,
    required this.onCopyLink,
    required this.onCopyCode,
    required this.onToggleListing,
    required this.onEditTime,
    required this.onOptIn,
    this.onSignIn,
    this.now,
    this.embedded = false,
  });

  final RideGroup group;
  final List<RideGroupMember> members;
  final Set<String> selfIds;
  final bool signedIn;
  final bool optIn;
  final VoidCallback onInvite;
  final VoidCallback onRide;
  final VoidCallback onLeave;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyCode;
  final VoidCallback onToggleListing;
  final VoidCallback onEditTime;
  final ValueChanged<bool> onOptIn;
  final VoidCallback? onSignIn;
  final DateTime? now;
  final bool embedded;

  bool get _host => selfIds.contains(group.hostUserId);

  int get _otherCount =>
      members.where((m) => !selfIds.contains(m.userId)).length;

  bool get _invitePrimary => RideGroupPolicy.platzPrimaryIsInvite(
        selfIsHost: _host,
        otherMemberCount: _otherCount,
        windowOpen: RideGroupPolicy.isEventWindowOpen(
          now: now ?? DateTime.now(),
          start: group.startWindowStart,
          end: group.startWindowEnd,
          status: group.status,
        ),
      );

  bool get _showCode =>
      _host && RideGroupPolicy.canJoinByTypedCode(group.visibility);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clock = now ?? DateTime.now();
    final meta = AppColors.meta(context);
    final when = formatRideGroupWhenLine(
      start: group.startWindowStart,
      end: group.startWindowEnd,
      l10n: l10n,
      now: clock,
    );
    final numbers = friendUnnamedNumbers(members: members, selfIds: selfIds);
    final roster = [
      for (final m in members)
        friendMemberLine(
          displayLabel: m.displayLabel,
          self: selfIds.contains(m.userId),
          isHost: m.userId == group.hostUserId,
          friendN: numbers[m.userId],
          fallbackSelf: l10n.platzYou,
          fallbackOther: l10n.platzGuest,
          hostRole: l10n.platzHost,
          guestRole: l10n.platzGuest,
          friendLabel: l10n.rideGroupFriendN,
        ),
    ].join('  ·  ');
    final quietBtn = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      foregroundColor: meta,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
    return Card(
      key: Key('platz-group-${group.id}'),
      margin: embedded
          ? const EdgeInsets.only(bottom: AppSpacing.s)
          : const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  group.visibility == RideGroupVisibility.public
                      ? l10n.platzListedPublic
                      : l10n.discoverPrivate,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: meta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            InkWell(
              key: Key('platz-group-time-${group.id}'),
              onTap: _host ? onEditTime : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          when,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: AppColors.sheetInk(context),
                          ),
                        ),
                        if (_host)
                          Text(
                            l10n.platzTimeTapHint,
                            style: TextStyle(fontSize: 11, color: meta),
                          ),
                      ],
                    ),
                  ),
                  if (_host)
                    Icon(Icons.chevron_right, size: 18, color: meta),
                ],
              ),
            ),
            if (group.meetingPoint != null &&
                group.meetingPoint!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                group.meetingPoint!.trim(),
                style: TextStyle(fontSize: 12, color: meta),
              ),
            ],
            if (roster.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                roster,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: meta),
              ),
            ],
            if (!group.onServer && !_host) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.platzHostCannotSee,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                ),
              ),
              if (!signedIn && onSignIn != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.signIn),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              width: double.infinity,
              child: _invitePrimary
                  ? FilledButton(
                      key: Key('platz-group-invite-${group.id}'),
                      onPressed: onInvite,
                      child: Text(l10n.platzInvite),
                    )
                  : FilledButton(
                      key: Key('platz-group-ride-${group.id}'),
                      onPressed: onRide,
                      child: Text(l10n.goRide),
                    ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                TextButton(
                  key: Key('platz-group-leave-${group.id}'),
                  onPressed: onLeave,
                  style: quietBtn,
                  child: Text(_host ? l10n.platzDissolve : l10n.platzLeave),
                ),
                if (_showCode) ...[
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    key: Key('platz-group-code-${group.id}'),
                    group.joinCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: meta,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  key: Key('platz-group-more-${group.id}'),
                  onPressed: () => _openMore(context),
                  style: quietBtn,
                  child: Text(l10n.platzMore),
                ),
              ],
            ),
            if (_host || group.onServer) ...[
              Divider(height: AppSpacing.l, color: AppColors.border.withValues(alpha: 0.7)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.platzShareInRide,
                      style: TextStyle(fontSize: 12, color: meta),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.82,
                    alignment: Alignment.centerRight,
                    child: Switch.adaptive(
                      key: Key('platz-group-pins-${group.id}'),
                      value: optIn,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: onOptIn,
                    ),
                  ),
                ],
              ),
              Text(
                l10n.platzPinsHint,
                style: TextStyle(fontSize: 11, color: meta),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMore(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_invitePrimary)
                ListTile(
                  key: Key('platz-group-ride-${group.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.goRide),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRide();
                  },
                )
              else if (_host)
                ListTile(
                  key: Key('platz-group-invite-${group.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.platzInvite),
                  onTap: () {
                    Navigator.pop(ctx);
                    onInvite();
                  },
                ),
              if (_host)
                ListTile(
                  key: Key('platz-group-extend-${group.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.rideGroupExtend),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEditTime();
                  },
                ),
              if (_host || group.onServer)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.platzCopyLink),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCopyLink();
                  },
                ),
              if (_showCode)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.platzCopyCode),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCopyCode();
                  },
                ),
              if (_host)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    group.visibility == RideGroupVisibility.public
                        ? l10n.platzMakePrivate
                        : l10n.platzMakePublic,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onToggleListing();
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_host ? l10n.platzDissolve : l10n.platzLeave),
                onTap: () {
                  Navigator.pop(ctx);
                  onLeave();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
