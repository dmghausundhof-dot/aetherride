import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/location/safe_position.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/ai/chat_context.dart';
import '../../domain/ai/chat_surface.dart';
import '../../domain/ai/coach_inbox.dart';
import '../../domain/ai/coach_watch.dart';
import '../../domain/component.dart';
import '../../domain/setup.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../shared/empty_state.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final String role; // user | assistant
  final String text;
}

class _SuggestedPrompt {
  const _SuggestedPrompt({
    required this.label,
    required this.query,
    required this.tool,
  });
  final String label;
  final String query;
  final String tool;
}

/// Chat-UI → POST `${API}/api/chat` (Web-Parität inkl. Prompts/Tools/Bearer).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _busy = false;
  bool _historyLoaded = false;
  String _tool = 'auto';
  String? _quotaNote;
  String _welcomeText = '';

  /// Statt der Welcome-Bubble (früher: einzige, kaum sichtbare Zeile vor
  /// viel leerer Fläche — UX-Review „Void-Empty-States") eine echte
  /// Leerzustand-Illustration zeigen.
  bool get _isEmptyConversation =>
      _historyLoaded &&
      _messages.length == 1 &&
      _messages.first.role == 'assistant' &&
      _messages.first.text == _welcomeText;

  List<_SuggestedPrompt> _promptsFor(AppLocalizations l10n) => [
        _SuggestedPrompt(
          label: l10n.chatPromptWatch,
          query: l10n.chatPromptWatchQuery,
          tool: 'watch',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptGarage,
          query: l10n.chatPromptGarageQuery,
          tool: 'garage',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptRange,
          query: l10n.chatPromptRangeQuery,
          tool: 'range',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptSetups,
          query: l10n.chatPromptSetupsQuery,
          tool: 'setup_history',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptRides,
          query: l10n.chatPromptRidesQuery,
          tool: 'ride_stats',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptRoutes,
          query: l10n.chatPromptRoutesQuery,
          tool: 'route_search',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptWindow,
          query: l10n.chatPromptWindowQuery,
          tool: 'ride_window',
        ),
        _SuggestedPrompt(
          label: l10n.chatPromptShop,
          query: l10n.chatPromptShopQuery,
          tool: 'product_search',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final text = AppLocalizations.of(context).chatWelcome;
    if (text == _welcomeText) return;
    final previous = _welcomeText;
    _welcomeText = text;
    if (_messages.length == 1 &&
        _messages.first.role == 'assistant' &&
        (previous.isEmpty || _messages.first.text == previous)) {
      _messages[0] = ChatMessage(role: 'assistant', text: text);
    }
  }

  Future<void> _loadHistory() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final welcome = ChatMessage(role: 'assistant', text: l10n.chatWelcome);
    setState(() {
      _welcomeText = l10n.chatWelcome;
      _messages
        ..clear()
        ..addAll([
          for (final e in store.chatHistory)
            ChatMessage(
              role: (e['role'] as String?) ?? 'assistant',
              text: _historyText(
                role: (e['role'] as String?) ?? 'assistant',
                text: (e['text'] as String?) ?? '',
                fallback: l10n.chatUnavailable,
              ),
            ),
        ]);
      if (_messages.isEmpty) {
        _messages.add(welcome);
      }
      _historyLoaded = true;
    });
    _scrollToEnd();
  }

  Future<void> _persist(String role, String text) async {
    await ref.read(userProfileStoreProvider).appendChat(role, text);
  }

  String _historyText({
    required String role,
    required String text,
    required String fallback,
  }) {
    if (role != 'assistant') return text;
    return sanitizeStoredAssistantText(text, fallback: fallback);
  }

  String _assistantSurface({
    required AppLocalizations l10n,
    required int statusCode,
    String? jsonText,
    String? jsonError,
  }) {
    final fault = chatSurfaceFault(
      statusCode: statusCode,
      jsonText: jsonText,
      jsonError: jsonError,
    );
    switch (fault) {
      case ChatSurfaceFault.limit:
        return l10n.chatLimitReached;
      case ChatSurfaceFault.unavailable:
        return l10n.chatUnavailable;
      case null:
        final t = jsonText?.trim() ?? '';
        return t.isEmpty ? l10n.chatNoAnswer : t;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({String? query, String? tool}) async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final riding = ref.read(isRidingProvider);
    if (riding || _busy) return;
    final q = (query ?? _input.text).trim();
    if (q.isEmpty) return;
    final toolName = tool ?? _tool;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: q));
      _busy = true;
      if (query == null) _input.clear();
      _quotaNote = null;
    });
    await _persist('user', q);
    _scrollToEnd();

    try {
      final store = ref.read(userProfileStoreProvider);
      await store.load();
      final garage = ref.read(garageRepositoryProvider);
      final bikes = await garage.listBikes();
      final active = await garage.getActiveBike();
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 12);
      final compsRepo = ref.read(componentRepositoryProvider);
      final setupsRepo = ref.read(setupRepositoryProvider);
      final componentsByBike = <String, List<BikeComponent>>{};
      final setupsByBike = <String, List<BikeSetup>>{};
      for (final b in bikes) {
        componentsByBike[b.id] = await compsRepo.listAll(b.id);
        setupsByBike[b.id] = await setupsRepo.listForBike(b.id);
      }
      final coachItems =
          ref.read(coachWatchProvider).valueOrNull ?? const <CoachInboxItem>[];
      final pos = await readCachedPosition();
      final body = buildChatApiBody(
        query: q,
        tool: toolName,
        profile: store.riderProfile,
        effectiveWeightKg: store.effectiveWeightKg,
        bikes: bikes,
        active: active,
        componentsByBike: componentsByBike,
        setupsByBike: setupsByBike,
        rides: rides,
        calibration: store.rangeCalibration,
        notices: [for (final i in coachItems) i.notice],
        lang: lang,
        lat: pos?.latitude,
        lon: pos?.longitude,
        routingProfile: active != null
            ? routingProfileForBike(active.category).apiId
            : null,
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (AppConfig.isSupabaseConfigured) {
        try {
          final token =
              Supabase.instance.client.auth.currentSession?.accessToken;
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
      }

      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/chat'),
        headers: headers,
        body: jsonEncode(body),
      );
      String? jsonText;
      String? jsonError;
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        jsonText = data['text'] as String?;
        jsonError = data['error'] as String?;
        final quota = data['quota'];
        if (quota is Map) {
          final remaining = quota['remaining'];
          final dayLimit = quota['dayLimit'];
          final dayUsed = quota['dayUsed'];
          if (remaining is num && dayLimit is num) {
            _quotaNote = l10n.chatQuota(
              dayUsed is num ? '${dayUsed.toInt()}' : '?',
              '${dayLimit.toInt()}',
              '${remaining.toInt()}',
            );
          }
        }
      } catch (_) {}
      final text = _assistantSurface(
        l10n: l10n,
        statusCode: res.statusCode,
        jsonText: jsonText,
        jsonError: jsonError,
      );
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', text: text));
        });
        await _persist('assistant', text);
      }
    } catch (_) {
      final err = l10n.chatUnavailable;
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', text: err));
        });
        await _persist('assistant', err);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final riding = ref.watch(isRidingProvider);
    final blocked = riding || _busy;
    final prompts = _promptsFor(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatAssistant)),
      body: Column(
        children: [
          if (riding)
            Material(
              color: AppColors.accent.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.chatLockedRiding,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!riding)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final p in prompts) ...[
                          ActionChip(
                            label: Text(p.label),
                            onPressed: blocked
                                ? null
                                : () => _send(query: p.query, tool: p.tool),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (AppConfig.showChatDevTools) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _tool,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: l10n.chatToolDev,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'auto',
                          child: Text(l10n.chatToolAuto),
                        ),
                        DropdownMenuItem(
                          value: 'watch',
                          child: Text(l10n.chatToolWatch),
                        ),
                        DropdownMenuItem(
                          value: 'garage',
                          child: Text(l10n.chatToolGarage),
                        ),
                        DropdownMenuItem(
                          value: 'compat',
                          child: Text(l10n.chatToolCompat),
                        ),
                        DropdownMenuItem(
                          value: 'range',
                          child: Text(l10n.chatToolRange),
                        ),
                        DropdownMenuItem(
                          value: 'setup_history',
                          child: Text(l10n.chatToolSetupHistory),
                        ),
                        DropdownMenuItem(
                          value: 'ride_stats',
                          child: Text(l10n.chatToolRides),
                        ),
                        DropdownMenuItem(
                          value: 'route_search',
                          child: Text(l10n.chatToolRoutes),
                        ),
                        DropdownMenuItem(
                          value: 'product_search',
                          child: Text(l10n.chatToolShop),
                        ),
                      ],
                      onChanged: blocked
                          ? null
                          : (v) {
                              if (v != null) setState(() => _tool = v);
                            },
                    ),
                  ],
                  if (_quotaNote != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _quotaNote!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  _CoachInboxStrip(
                    blocked: blocked,
                    onAsk: (item) async {
                      await ref
                          .read(userProfileStoreProvider)
                          .markCoachNoticesRead([item.notice]);
                      ref.invalidate(coachWatchProvider);
                      await _send(
                        query: item.notice.query,
                        tool: item.notice.tool,
                      );
                    },
                    onSnooze: (item) async {
                      await ref
                          .read(userProfileStoreProvider)
                          .snoozeCoachNotice(item.notice);
                      ref.invalidate(coachWatchProvider);
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: !_historyLoaded
                ? const Center(child: CircularProgressIndicator())
                : _isEmptyConversation
                    ? Center(
                        child: EmptyStateIllustration(
                          compact: true,
                          icon: Icons.chat_bubble_outline,
                          title: l10n.chatEmptyTitle,
                          message: l10n.chatEmptyMessage,
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isUser = m.role == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.82,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.accent.withValues(alpha: 0.22)
                                    : AppColors.elevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(m.text),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !riding,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            riding ? l10n.chatHintLocked : l10n.chatHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: blocked ? null : (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                    ),
                    onPressed: blocked ? null : () => _send(),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachInboxStrip extends ConsumerWidget {
  const _CoachInboxStrip({
    required this.blocked,
    required this.onAsk,
    required this.onSnooze,
  });

  final bool blocked;
  final Future<void> Function(CoachInboxItem item) onAsk;
  final Future<void> Function(CoachInboxItem item) onSnooze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(coachWatchProvider);
    final items = async.valueOrNull ?? const <CoachInboxItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: item.notice.severity == CoachSeverity.overdue
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.elevated,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.notice.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item.notice.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: blocked ? null : () => onAsk(item),
                            child: Text(l10n.chatAsk),
                          ),
                          TextButton(
                            onPressed: blocked ? null : () => onSnooze(item),
                            child: Text(l10n.chatSnooze7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Convenience: open chat from Home/Auth.
void openChatScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
  );
}
