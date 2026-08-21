import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/coach_inbox.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../chat/chat_screen.dart';
import 'hof_hinweise_sheet.dart';

class HofCoachBellButton extends ConsumerWidget {
  const HofCoachBellButton({
    super.key,
    this.careText,
    this.stimmenText,
    this.groupText,
    this.listingText,
    this.onOpenCare,
    this.onOpenTours,
  });

  final String? careText;
  final String? stimmenText;
  final String? groupText;
  final String? listingText;
  final VoidCallback? onOpenCare;
  final VoidCallback? onOpenTours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(coachWatchProvider).valueOrNull ?? const <CoachInboxItem>[];
    final unread = unreadCoachCount(items);
    final l10n = AppLocalizations.of(context);
    final label =
        unread > 0 ? l10n.coachHintsTooltip(unread) : l10n.hofHintsTooltip;
    return IconButton(
      key: const Key('coach-bell'),
      tooltip: label,
      onPressed: () => showHofHinweiseSheet(
        context,
        careText: careText,
        stimmenText: stimmenText,
        groupText: groupText,
        listingText: listingText,
        onOpenCare: onOpenCare,
        onOpenTours: onOpenTours,
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class HofChatButton extends StatelessWidget {
  const HofChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const Key('coach-chat'),
      tooltip: l10n.chatAssistant,
      onPressed: () => openChatScreen(context),
      icon: const Icon(Icons.chat_bubble_outline),
    );
  }
}
