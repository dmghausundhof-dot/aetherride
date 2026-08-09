import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../billing/upgrade_screen.dart';
import '../chat/chat_screen.dart';
import '../privacy/privacy_screen.dart';

/// E-Mail/Passwort-Login für Sync (Supabase).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;
  StreamSubscription<AuthState>? _authSub;
  bool _handledOAuthSession = false;
  bool _awaitingOAuth = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.isSupabaseConfigured) {
      try {
        _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (!_awaitingOAuth || _handledOAuthSession) return;
          if (data.session != null && data.event == AuthChangeEvent.signedIn) {
            unawaited(_onSessionReady());
          }
        });
      } catch (_) {}
    }
  }

  Future<void> _onSessionReady() async {
    if (!mounted || _handledOAuthSession) return;
    _handledOAuthSession = true;
    setState(() {
      _busy = true;
      _message = 'Angemeldet — synchronisiere…';
    });
    try {
      await ref.read(syncEngineProvider).syncNow();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Angemeldet. Sync: $e';
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel() ?? Future.value());
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!AppConfig.isSupabaseConfigured) {
      setState(() => _message = 'Supabase nicht konfiguriert (SUPABASE_ANON_KEY).');
      return;
    }
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 8) {
      setState(() => _message = 'E-Mail und Passwort (min. 8 Zeichen) nötig.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final client = Supabase.instance.client;
      if (_register) {
        final res = await client.auth.signUp(
          email: email,
          password: password,
        );
        if (res.session == null) {
          setState(
            () => _message =
                'Konto erstellt — ggf. E-Mail bestätigen, dann anmelden.',
          );
        } else {
          _handledOAuthSession = true;
          await ref.read(syncEngineProvider).syncNow();
          if (mounted) Navigator.of(context).pop(true);
        }
      } else {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _handledOAuthSession = true;
        await ref.read(syncEngineProvider).syncNow();
        if (mounted) Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    if (!AppConfig.isSupabaseConfigured) {
      setState(() => _message = 'Supabase nicht konfiguriert.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _handledOAuthSession = false;
      _awaitingOAuth = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: AppConfig.oauthRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (mounted) {
        setState(
          () => _message =
              'Browser geöffnet — nach Login kehrst du automatisch zurück.',
        );
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konto löschen?'),
        content: const Text(
          'Remote-Konto und lokale App-Daten werden gelöscht. '
          'Exportiere vorher GPX/JSON unter Daten & Privatsphäre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      String? remoteMsg;
      if (AppConfig.isSupabaseConfigured) {
        final token =
            Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          try {
            final res = await http.post(
              Uri.parse('${AppConfig.apiBaseUrl}/api/account/delete'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: '{"confirm":"DELETE"}',
            );
            if (res.statusCode == 200) {
              remoteMsg = 'Remote-Konto gelöscht.';
            } else if (res.statusCode == 503) {
              remoteMsg =
                  'Remote-Löschung nicht verfügbar — nur lokale Daten entfernt.';
            } else {
              remoteMsg =
                  'Remote-Löschung fehlgeschlagen (${res.statusCode}) — lokal trotzdem gelöscht.';
            }
          } catch (_) {
            remoteMsg =
                'Server nicht erreichbar — nur lokale Daten entfernt.';
          }
        }
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      }
      await ref.read(garageRepositoryProvider).wipeLocalData();
      ref.read(subscriptionTierProvider.notifier).state = 'free';
      ref.invalidate(bikesProvider);
      ref.invalidate(recentRidesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remoteMsg ??
                  'Lokale Daten gelöscht. Export ggf. unter Privatsphäre nachholen.',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final loggedIn = session != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(loggedIn ? 'Konto' : (_register ? 'Registrieren' : 'Anmelden')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (loggedIn) ...[
            Text(
              session.user.email ?? 'Angemeldet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Sync mit ${AppConfig.apiBaseUrl} ist aktiv.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await ref.read(syncEngineProvider).syncNow();
                        setState(() => _message = 'Sync OK');
                      } catch (e) {
                        setState(() => _message = 'Sync: $e');
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: const Text('Jetzt synchronisieren'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openUpgradeScreen(context),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('AetherRide Pro'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    },
              child: const Text('Daten & Privatsphäre'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openChatScreen(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat öffnen'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Abmelden'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _deleteAccount,
              child: const Text(
                'Konto löschen',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ] else ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _busy ? null : _submit,
              child: Text(_busy
                  ? '…'
                  : (_register ? 'Konto erstellen' : 'Anmelden')),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _register = !_register;
                        _message = null;
                      }),
              child: Text(
                _register
                    ? 'Bereits Konto? Anmelden'
                    : 'Neu hier? Registrieren',
              ),
            ),
            if (AppConfig.isSupabaseConfigured &&
                (AppConfig.enableGoogleOAuth ||
                    AppConfig.enableAppleOAuth)) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              if (AppConfig.enableGoogleOAuth) ...[
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _oauth(OAuthProvider.google),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Mit Google'),
                ),
                const SizedBox(height: 8),
              ],
              if (AppConfig.enableAppleOAuth)
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _oauth(OAuthProvider.apple),
                  icon: const Icon(Icons.apple),
                  label: const Text('Mit Apple'),
                ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openUpgradeScreen(context),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('AetherRide Pro'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyScreen(),
                  ),
                );
              },
              child: const Text('Daten & Privatsphäre'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => openChatScreen(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat öffnen'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

void openAuthScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
  );
}
