import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

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

  @override
  void dispose() {
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
          await ref.read(syncEngineProvider).syncNow();
          if (mounted) Navigator.of(context).pop(true);
        }
      } else {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
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

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).pop(true);
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
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Abmelden'),
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
