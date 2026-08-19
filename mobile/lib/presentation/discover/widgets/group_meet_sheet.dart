import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/community/ride_group.dart';
import '../../../l10n/app_localizations.dart';
import '../../ride/widgets/ride_group_extend_sheet.dart';
import '../../shell/hof_threshold_nav.dart';

enum GroupMeetSheetAction { join, ride, dismiss }

Future<GroupMeetSheetAction?> showGroupMeetSheet(
  BuildContext context, {
  required RideGroup group,
  required bool isMember,
}) {
  return showModalBottomSheet<GroupMeetSheetAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => GroupMeetSheet(group: group, isMember: isMember),
  );
}

class GroupMeetSheet extends StatelessWidget {
  const GroupMeetSheet({
    super.key,
    required this.group,
    required this.isMember,
  });

  final RideGroup group;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = formatRideGroupWhenLine(
      start: group.startWindowStart,
      end: group.startWindowEnd,
      l10n: l10n,
    );
    final meet = group.meetingPoint?.trim() ?? '';
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
            Text(
              group.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                group.visibility == RideGroupVisibility.public
                    ? l10n.platzListedPublic
                    : l10n.discoverPrivate,
                when,
                if (meet.isNotEmpty) meet,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (!isMember)
              FilledButton.icon(
                key: const Key('group-meet-join'),
                onPressed: () =>
                    Navigator.pop(context, GroupMeetSheetAction.join),
                icon: const Icon(Icons.group_add),
                label: Text(l10n.platzJoin),
              )
            else
              FilledButton.icon(
                key: const Key('group-meet-ride'),
                onPressed: () =>
                    Navigator.pop(context, GroupMeetSheetAction.ride),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.goRide),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, GroupMeetSheetAction.dismiss),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }
}
