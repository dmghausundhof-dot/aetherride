import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_pin.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../l10n/app_localizations.dart';
import '../ride/widgets/ride_group_extend_sheet.dart';
import '../shell/hof_threshold_nav.dart';

/// Eine Primary, Zeit als Zeile, Rest hinter Mehr.
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

  bool get _host => selfIds.contains(group.hostUserId);

  int get _otherCount =>
      members.where((m) => !selfIds.contains(m.userId)).length;

  bool get _invitePrimary => RideGroupPolicy.platzPrimaryIsInvite(
        selfIsHost: _host,
        otherMemberCount: _otherCount,
      );

  bool get _showCode =>
      _host && RideGroupPolicy.canJoinByTypedCode(group.visibility);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = formatRideGroupWhenLine(
      start: group.startWindowStart,
      end: group.startWindowEnd,
      l10n: l10n,
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
    return Card(
      key: Key('platz-group-${group.id}'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  group.visibility == RideGroupVisibility.public
                      ? l10n.platzListedPublic
                      : l10n.discoverPrivate,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.overlay,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                key: Key('platz-group-time-${group.id}'),
                borderRadius: BorderRadius.circular(8),
                onTap: _host ? onEditTime : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        when,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_host)
                        Text(
                          l10n.platzTimeTapHint,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (group.meetingPoint != null &&
                group.meetingPoint!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                group.meetingPoint!.trim(),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            if (roster.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                roster,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            if (!group.onServer) ...[
              const SizedBox(height: 6),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_showCode)
                  Text(
                    key: Key('platz-group-code-${group.id}'),
                    group.joinCode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                if (_host || group.onServer)
                  TextButton(
                    onPressed: onCopyLink,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      _showCode ? l10n.platzCopyLink : l10n.platzShareLink,
                    ),
                  ),
                if (_showCode)
                  TextButton(
                    key: Key('platz-group-copy-code-${group.id}'),
                    onPressed: onCopyCode,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.platzCopyCode),
                  ),
                TextButton(
                  onPressed: onLeave,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_host ? l10n.platzDissolve : l10n.platzLeave),
                ),
                TextButton(
                  key: Key('platz-group-more-${group.id}'),
                  onPressed: () => _openMore(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.platzMore),
                ),
              ],
            ),
            if (_host || group.onServer) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.platzShareInRide,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Switch.adaptive(
                    key: Key('platz-group-pins-${group.id}'),
                    value: optIn,
                    onChanged: onOptIn,
                  ),
                ],
              ),
              Text(
                l10n.platzPinsHint,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
            16,
            8,
            16,
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
