import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/billing/play_billing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../shared/chrome_glyph.dart';

/// Pro upgrade: Stripe Checkout (web) + Play Billing (Android) + sync.
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _busy = false;
  String? _message;
  PlayBilling? _play;
  StreamSubscription<PurchaseUpdate>? _playSub;
  StreamSubscription<String>? _playErrSub;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      _play = PlayBilling();
      unawaited(_play!.start());
      _playSub = _play!.updates.listen(_onPlayPurchase);
      _playErrSub = _play!.errors.listen((msg) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        setState(() => _message = l10n.billingPlayError(msg));
      });
    }
  }

  @override
  void dispose() {
    _playSub?.cancel();
    _playErrSub?.cancel();
    unawaited(_play?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _onPlayPurchase(PurchaseUpdate update) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = l10n.billingVerifying;
    });
    try {
      final mode = await _verifyPlay(
        purchaseToken: update.purchaseToken,
        productId: update.productId,
      );
      await ref.read(syncEngineProvider).syncNow();
      if (!mounted) return;
      setState(() {
        _message = mode == 'trusted_token_mvp'
            ? (kDebugMode ? l10n.billingProTrusted : l10n.billingProActive)
            : l10n.billingProActive;
      });
    } catch (e) {
      if (mounted) setState(() => _message = l10n.billingPlayError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _accessToken() async {
    if (!AppConfig.isSupabaseConfigured) return null;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _stripeCheckout(String interval) async {
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.commerceEnabled) {
      setState(() => _message = l10n.billingCommerceClosed);
      return;
    }
    final token = await _accessToken();
    if (token == null) {
      setState(() => _message = l10n.billingPleaseSignIn);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/billing/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'interval': interval}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'checkout ${res.statusCode}');
      }
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        setState(() => _message = l10n.billingNoCheckoutUrl);
        return;
      }
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        setState(() => _message = l10n.billingBrowserFailed);
        return;
      }
      setState(() => _message = l10n.billingCheckoutOpened);
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _verifyPlay({
    required String purchaseToken,
    required String productId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final token = await _accessToken();
    if (token == null) throw Exception(l10n.billingPleaseSignIn);
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/billing/play-verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
        'packageName': 'com.aetherride.aetherride_mobile',
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'verify ${res.statusCode}');
    }
    final mode = data['mode'] as String?;
    final tier = data['tier'] as String?;
    if (tier == 'pro' || tier == 'free') {
      final effective = AppConfig.forcePro ? 'pro' : tier!;
      ref.read(subscriptionTierProvider.notifier).state = effective;
      ref.read(garageRepositoryProvider).subscriptionTier = effective;
    }
    return mode;
  }

  Future<void> _playBuy() async {
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.commerceEnabled) {
      setState(() => _message = l10n.billingCommerceClosed);
      return;
    }
    final play = _play;
    if (play == null) {
      setState(() => _message = l10n.billingPlayOnlyAndroid);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await play.buyProMonthly();
      setState(() => _message = l10n.billingPlayStarted);
    } catch (e) {
      setState(() => _message = l10n.billingPlayError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playRestore() async {
    final l10n = AppLocalizations.of(context);
    final play = _play;
    if (play == null) {
      setState(() => _message = l10n.billingPlayOnlyAndroid);
      return;
    }
    setState(() {
      _busy = true;
      _message = l10n.billingRestoring;
    });
    try {
      await play.restorePurchases();
      setState(() => _message = l10n.billingRestoreStarted);
    } catch (e) {
      setState(() => _message = l10n.billingRestoreError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyTierFromMe(String accessToken) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final user = data['user'];
      final tier = user is Map
          ? user['subscriptionTier'] as String?
          : data['subscriptionTier'] as String?;
      if (tier == 'pro' || tier == 'free') {
        final effective = AppConfig.forcePro ? 'pro' : tier!;
        ref.read(subscriptionTierProvider.notifier).state = effective;
        ref.read(garageRepositoryProvider).subscriptionTier = effective;
      }
    } catch (_) {}
  }

  Future<void> _syncAfterPurchase() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final token = await _accessToken();
      await ref.read(syncEngineProvider).syncNow();
      if (token != null) await _applyTierFromMe(token);
      final tier = ref.read(subscriptionTierProvider);
      setState(() => _message = l10n.billingSyncOkTier(tier));
    } catch (e) {
      setState(() => _message = l10n.billingSyncError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tier = ref.watch(subscriptionTierProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tier == 'pro' ? l10n.billingYouHavePro : l10n.billingFreeToPro,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.billingMoreBikes,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          if (tier == 'pro') ...[
            Text(
              l10n.billingAlreadyPro,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (AppConfig.forcePro && kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                l10n.billingForceProDebug,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ] else if (!AppConfig.commerceEnabled) ...[
            Text(
              l10n.billingCommerceClosed,
              style: const TextStyle(color: AppColors.muted),
            ),
          ] else ...[
            FilledButton(
              style: FilledButton.styleFrom(),
              onPressed: _busy ? null : () => _stripeCheckout('month'),
              child: Text(l10n.billingStripeMonth),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : () => _stripeCheckout('year'),
              child: Text(l10n.billingStripeYear),
            ),
            if (defaultTargetPlatform == TargetPlatform.android) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _playBuy,
                icon: const ChromeGlyph('shop', size: 20),
                label: Text(l10n.billingPlayMonth),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _playRestore,
                child: Text(l10n.billingPlayRestore),
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text(
                  l10n.billingPlayHint,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : _syncAfterPurchase,
            child: Text(
              tier == 'pro'
                  ? l10n.billingSyncStatus
                  : l10n.billingSyncAfterPurchase,
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

void openUpgradeScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
  );
}
