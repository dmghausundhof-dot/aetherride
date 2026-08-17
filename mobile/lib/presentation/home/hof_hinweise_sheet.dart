import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/ai/coach_inbox.dart';
import '../../domain/ai/coach_watch.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';

/// Hinweis-Liste: Coach + Tafel-relevantes. Nicht die Chat-Historie.
Future<void> showHofHinweiseSheet(
  BuildContext context, {
  String? careText,
  String? stimmenText,
  String? groupText,
  VoidCallback? onOpenCare,
  VoidCallback? onOpenTours,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => HofHinweiseSheet(
      careText: careText,
      stimmenText: stimmenText,
      groupText: groupText,
      onOpenCare: onOpenCare,
      onOpenTours: onOpenTours,
    ),
  );
}

class HofHinweiseSheet extends ConsumerWidget {
  const HofHinweiseSheet({
    super.key,
    this.careText,
    this.stimmenText,
    this.groupText,
    this.onOpenCare,
    this.onOpenTours,
  });

  final String? careText;
  final String? stimmenText;
  final String? groupText;
  final VoidCallback? onOpenCare;
  final VoidCallback? onOpenTours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items =
        ref.watch(coachWatchProvider).valueOrNull ?? const <CoachInboxItem>[];
    final unread = [for (final i in items) if (i.unread) i];
    final read = [for (final i in items) if (!i.unread) i];
    final coach = [...unread, ...read.take(3)].take(5).toList();
    final care = careText?.trim();
    final stimmen = stimmenText?.trim();
    final group = groupText?.trim();
    final hasTafel = (care != null && care.isNotEmpty) ||
        (stimmen != null && stimmen.isNotEmpty) ||
        (group != null && group.isNotEmpty);
    final empty = coach.isEmpty && !hasTafel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.hofHintsTitle,
              key: const Key('hof-hinweise-title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            if (empty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Text(
                  l10n.hofHintsEmpty,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            if (care != null && care.isNotEmpty)
              ListTile(
                key: const Key('hof-hinweise-care'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.build_outlined),
                title: Text(care),
                onTap: () {
                  Navigator.pop(context);
                  onOpenCare?.call();
                },
              ),
            if (group != null && group.isNotEmpty)
              ListTile(
                key: const Key('hof-hinweise-group'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_outlined),
                title: Text(group),
                onTap: () {
                  Navigator.pop(context);
                  onOpenTours?.call();
                },
              ),
            if (stimmen != null && stimmen.isNotEmpty)
              ListTile(
                key: const Key('hof-hinweise-stimmen'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.record_voice_over_outlined),
                title: Text(stimmen),
                onTap: () {
                  Navigator.pop(context);
                  onOpenTours?.call();
                },
              ),
            for (final item in coach)
              ListTile(
                key: Key('hof-hinweise-coach-${item.notice.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.unread
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                ),
                title: Text(item.notice.title),
                subtitle: item.notice.detail.trim().isEmpty
                    ? null
                    : Text(
                        item.notice.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () async {
                  await ref
                      .read(userProfileStoreProvider)
                      .markCoachNoticesRead([item.notice]);
                  ref.invalidate(coachWatchProvider);
                  if (!context.mounted) return;
                  final toCare = item.notice.kind == CoachKind.maintenance ||
                      item.notice.kind == CoachKind.wear ||
                      item.notice.kind == CoachKind.setup;
                  Navigator.pop(context);
                  if (toCare) {
                    onOpenCare?.call();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
