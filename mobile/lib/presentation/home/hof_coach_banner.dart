import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/coach_inbox.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../chat/chat_screen.dart';

class HofCoachBellButton extends ConsumerWidget {
  const HofCoachBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(coachWatchProvider).valueOrNull ?? const <CoachInboxItem>[];
    final unread = unreadCoachCount(items);
    if (unread <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const Key('coach-bell'),
      tooltip: l10n.coachHintsTooltip(unread),
      onPressed: () => openChatScreen(context),
      icon: Badge(
        isLabelVisible: true,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
