import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
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
  bool _obscurePassword = true;

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
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = l10n.authSignedInSyncing;
    });
    try {
      await ref.read(syncEngineProvider).syncNow();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = l10n.authSignedInSyncFailed('$e');
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
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.isSupabaseConfigured) {
      setState(() => _message = l10n.authCloudUnavailable);
      return;
    }
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 8) {
      setState(() => _message = l10n.authEmailPasswordRequired);
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
          setState(() => _message = l10n.authAccountCreatedConfirm);
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
      setState(() => _message = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.isSupabaseConfigured) {
      setState(() => _message = l10n.authCloudUnavailable);
      return;
    }
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _message = l10n.authResetNeedEmail);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: '${AppConfig.apiBaseUrl}/anmelden',
      );
      if (mounted) setState(() => _message = l10n.authResetSent);
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (e) {
      if (mounted) setState(() => _message = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.isSupabaseConfigured) {
      setState(() => _message = l10n.authSupabaseMissing);
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
        setState(() => _message = l10n.authBrowserOpened);
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(dialogL10n.authDeleteTitle),
          content: Text(dialogL10n.authDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.chipIdleText,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
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
              remoteMsg = l10n.authRemoteDeleted;
            } else if (res.statusCode == 503) {
              remoteMsg = l10n.authRemoteUnavailable;
            } else {
              remoteMsg = l10n.authRemoteFailed(res.statusCode);
            }
          } catch (_) {
            remoteMsg = l10n.authRemoteUnreachable;
          }
        }
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      }
      await ref.read(garageRepositoryProvider).wipeLocalData();
      ref.read(onboardingDoneProvider.notifier).state = false;
      ref.read(subscriptionTierProvider.notifier).state =
          AppConfig.forcePro ? 'pro' : 'free';
      ref.invalidate(bikesProvider);
      ref.invalidate(recentRidesProvider);
      ref.invalidate(riderProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(remoteMsg ?? l10n.authLocalDeleted),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _message = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final loggedIn = session != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loggedIn
              ? l10n.account
              : (_register ? l10n.register : l10n.signIn),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (loggedIn) ...[
            Text(
              session.user.email ?? l10n.profileSignedIn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.authSyncActive(AppConfig.apiBaseUrl),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await ref.read(syncEngineProvider).syncNow();
                        setState(() => _message = l10n.authSyncOk);
                      } catch (e) {
                        setState(() => _message = l10n.billingSyncError('$e'));
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(l10n.authSyncNow),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openUpgradeScreen(context),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(l10n.billingTitle),
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
              child: Text(l10n.authPrivacy),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openChatScreen(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.authOpenAssistant),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: Text(l10n.signOut),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _deleteAccount,
              child: Text(
                l10n.authDeleteAccount,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ] else ...[
            Semantics(
              label: l10n.authEmail,
              textField: true,
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.authEmail,
                  hintText: l10n.authEmailHint,
                  prefixIcon: Icon(Icons.email_outlined, semanticLabel: l10n.authEmail),
                  border: const OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                onChanged: (_) {
                  if (_message != null) setState(() => _message = null);
                },
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: l10n.authPassword,
              textField: true,
              child: TextField(
                controller: _password,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: l10n.authPassword,
                  hintText: l10n.authPassword,
                  prefixIcon: Icon(Icons.lock_outline, semanticLabel: l10n.authPassword),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? l10n.authPassword
                        : l10n.authPassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                onChanged: (_) {
                  if (_message != null) setState(() => _message = null);
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(),
              onPressed: _busy ? null : _submit,
              child: Text(
                _busy
                    ? (_register ? l10n.authCreating : l10n.authSigningIn)
                    : (_register ? l10n.authCreateAccount : l10n.signIn),
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _register = !_register;
                        _message = null;
                      }),
              child: Text(
                _register ? l10n.authHaveAccount : l10n.authNewHere,
              ),
            ),
            if (!_register)
              TextButton(
                onPressed: _busy ? null : _resetPassword,
                child: Text(l10n.authForgotPassword),
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
                  label: Text(l10n.authWithGoogle),
                ),
                const SizedBox(height: 8),
              ],
              if (AppConfig.enableAppleOAuth)
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _oauth(OAuthProvider.apple),
                  icon: const Icon(Icons.apple),
                  label: Text(l10n.authWithApple),
                ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openUpgradeScreen(context),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(l10n.billingTitle),
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
              child: Text(l10n.authPrivacy),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => openChatScreen(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.authOpenAssistant),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: const TextStyle(color: AppColors.muted)),
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
