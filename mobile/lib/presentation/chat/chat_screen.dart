import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
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

  static const _welcome = ChatMessage(
    role: 'assistant',
    text: 'Frag mich zu Setup, Routen oder Teilen.',
  );

  /// Statt der `_welcome`-Bubble (früher: einzige, kaum sichtbare Zeile vor
  /// viel leerer Fläche — UX-Review „Void-Empty-States") eine echte
  /// Leerzustand-Illustration zeigen.
  bool get _isEmptyConversation =>
      _historyLoaded &&
      _messages.length == 1 &&
      _messages.first.role == _welcome.role &&
      _messages.first.text == _welcome.text;

  static const _prompts = <_SuggestedPrompt>[
    _SuggestedPrompt(
      label: 'Garage',
      query: 'Was steckt in meiner Garage?',
      tool: 'garage',
    ),
    _SuggestedPrompt(
      label: 'Reichweite',
      query: 'Welche Reichweite habe ich mit aktuellem Akku?',
      tool: 'range',
    ),
    _SuggestedPrompt(
      label: 'Setups',
      query: 'Welche Setups hatte ich und was hat sich geändert?',
      tool: 'setup_history',
    ),
    _SuggestedPrompt(
      label: 'Rides',
      query: 'Zusammenfassung meiner letzten Rides',
      tool: 'ride_stats',
    ),
    _SuggestedPrompt(
      label: 'Routen',
      query: 'Welche Routen passen zu mir?',
      tool: 'route_search',
    ),
    _SuggestedPrompt(
      label: 'Shop',
      query: 'Brauche ich bald neue Verschleißteile?',
      tool: 'product_search',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll([
          for (final e in store.chatHistory)
            ChatMessage(
              role: (e['role'] as String?) ?? 'assistant',
              text: (e['text'] as String?) ?? '',
            ),
        ]);
      if (_messages.isEmpty) {
        _messages.add(_welcome);
      }
      _historyLoaded = true;
    });
    _scrollToEnd();
  }

  Future<void> _persist(String role, String text) async {
    await ref.read(userProfileStoreProvider).appendChat(role, text);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({String? query, String? tool}) async {
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
      final profile = store.riderProfile;
      final profilePayload = {
        ...profile.toJson(),
        'riderWeightKg': store.effectiveWeightKg,
      };
      final bikeJson = active == null
          ? null
          : {
              'id': active.id,
              'name': active.name,
              'category': active.category.name,
              'brand': active.brand,
              'model': active.model,
            };

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
        body: jsonEncode({
          'query': q,
          'tool': toolName,
          'profile': profilePayload,
          'bike': bikeJson,
          'bikes': [
            for (final b in bikes)
              {
                'id': b.id,
                'name': b.name,
                'category': b.category.name,
                'brand': b.brand,
                'model': b.model,
              },
          ],
          'rides': [
            for (final r in rides)
              {
                'id': r.id,
                'bikeId': r.bikeId,
                'startedAt': r.startedAt.toIso8601String(),
                'distanceKm': r.distanceKm,
                'movingTimeSec': r.movingTimeSec,
                'summary': r.summary,
              },
          ],
          'calibration': store.rangeCalibration?.toJson(),
        }),
      );
      String text;
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        text = (data['text'] as String?) ??
            (data['error'] as String?) ??
            'Keine Antwort.';
        final remaining = data['remaining'];
        final dayLimit = data['dayLimit'];
        if (remaining is num && dayLimit is num) {
          _quotaNote = 'Quota: ${remaining.toInt()}/${dayLimit.toInt()} heute';
        }
        if (res.statusCode == 429) {
          text = '$text\n\nLimit erreicht.';
        }
      } catch (_) {
        text = res.statusCode >= 400
            ? 'Fehler ${res.statusCode}'
            : 'Keine Antwort.';
      }
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', text: text));
        });
        await _persist('assistant', text);
      }
    } catch (e) {
      final err = 'Netzwerkfehler: $e';
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
    final riding = ref.watch(isRidingProvider);
    final blocked = riding || _busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          if (riding)
            Material(
              color: AppColors.accent.withValues(alpha: 0.12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Während der Fahrt ist Chat gesperrt.',
                        style: TextStyle(fontSize: 13),
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
                        for (final p in _prompts) ...[
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
                  DropdownButtonFormField<String>(
                    initialValue: _tool,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Tool',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('Auto')),
                      DropdownMenuItem(value: 'garage', child: Text('Garage')),
                      DropdownMenuItem(
                          value: 'range', child: Text('Reichweite')),
                      DropdownMenuItem(
                        value: 'setup_history',
                        child: Text('Setup-Historie'),
                      ),
                      DropdownMenuItem(
                        value: 'ride_stats',
                        child: Text('Ride-Stats'),
                      ),
                      DropdownMenuItem(
                        value: 'route_search',
                        child: Text('Routen'),
                      ),
                      DropdownMenuItem(
                        value: 'product_search',
                        child: Text('Shop'),
                      ),
                    ],
                    onChanged: blocked
                        ? null
                        : (v) {
                            if (v != null) setState(() => _tool = v);
                          },
                  ),
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
                ],
              ),
            ),
          Expanded(
            child: !_historyLoaded
                ? const Center(child: CircularProgressIndicator())
                : _isEmptyConversation
                    ? const Center(
                        child: EmptyStateIllustration(
                          compact: true,
                          icon: Icons.chat_bubble_outline,
                          title: 'Frag mich',
                          message: 'Setup, Routen oder Teilen — probier einen '
                              'Vorschlag oben oder tipp direkt los.',
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
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.forest.withValues(alpha: 0.06),
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
                            riding ? 'Gesperrt während Ride' : 'Nachricht…',
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

/// Convenience: open chat from Home/Auth.
void openChatScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
  );
}
