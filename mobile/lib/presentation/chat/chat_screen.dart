import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ride_providers.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final String role; // user | assistant
  final String text;
}

/// Einfache Chat-UI → POST `${API}/api/chat`.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[
    const ChatMessage(
      role: 'assistant',
      text: 'Frag mich zu Setup, Routen oder Teilen.',
    ),
  ];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final riding = ref.read(isRidingProvider);
    if (riding || _busy) return;
    final q = _input.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: q));
      _busy = true;
      _input.clear();
    });
    _scrollToEnd();

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'query': q, 'tool': 'auto'}),
      );
      String text;
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        text = (data['text'] as String?) ??
            (data['error'] as String?) ??
            'Keine Antwort.';
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(role: 'assistant', text: 'Netzwerkfehler: $e'),
          );
        });
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
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.82,
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
                        hintText: riding
                            ? 'Gesperrt während Ride'
                            : 'Nachricht…',
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
                    onPressed: blocked ? null : _send,
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
