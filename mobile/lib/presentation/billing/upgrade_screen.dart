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
import '../../providers/app_providers.dart';

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
        if (mounted) setState(() => _message = 'Play: $msg');
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
    setState(() {
      _busy = true;
      _message = 'Kauf wird verifiziert…';
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
            ? 'Pro gesetzt (Trusted-Token-MVP — ohne Google Play Service Account). Sync OK.'
            : 'Pro aktiv (Play). Sync OK.';
      });
    } catch (e) {
      if (mounted) setState(() => _message = 'Play: $e');
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
    final token = await _accessToken();
    if (token == null) {
      setState(() => _message = 'Bitte zuerst anmelden.');
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
      if (url == null || url.isEmpty) throw Exception('Keine Checkout-URL');
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('Browser konnte nicht geöffnet werden');
      setState(() => _message = 'Checkout geöffnet — danach „Sync after purchase“.');
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
    final token = await _accessToken();
    if (token == null) throw Exception('Bitte zuerst anmelden.');
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
    final play = _play;
    if (play == null) {
      setState(() => _message = 'Play Billing nur auf Android.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await play.buyProMonthly();
      setState(() => _message = 'Play-Kauf gestartet…');
    } catch (e) {
      setState(() => _message = 'Play: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playRestore() async {
    final play = _play;
    if (play == null) {
      setState(() => _message = 'Play Billing nur auf Android.');
      return;
    }
    setState(() {
      _busy = true;
      _message = 'Käufe werden wiederhergestellt…';
    });
    try {
      await play.restorePurchases();
      setState(
        () => _message =
            'Restore gestartet — gültige Abos werden verifiziert.',
      );
    } catch (e) {
      setState(() => _message = 'Restore: $e');
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
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final token = await _accessToken();
      await ref.read(syncEngineProvider).syncNow();
      if (token != null) await _applyTierFromMe(token);
      final tier = ref.read(subscriptionTierProvider);
      setState(() => _message = 'Sync OK — Tarif: $tier');
    } catch (e) {
      setState(() => _message = 'Sync: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(subscriptionTierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AetherRide Pro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tier == 'pro' ? 'Du hast Pro.' : 'Free → Pro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mehr Bikes, Sync-Vorteile und Offline-Regionen.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: _busy ? null : () => _stripeCheckout('month'),
            child: const Text('Stripe — monatlich'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _busy ? null : () => _stripeCheckout('year'),
            child: const Text('Stripe — jährlich'),
          ),
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _playBuy,
              icon: const Icon(Icons.shop_outlined),
              label: const Text('Google Play — monatlich'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _playRestore,
              child: const Text('Play-Käufe wiederherstellen'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hinweis: Ohne GOOGLE_PLAY_SERVICE_ACCOUNT_JSON prüft der Server '
              'nur den Trusted-Token (MVP) — kein Publisher-API-Verify.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : _syncAfterPurchase,
            child: const Text('Nach Kauf synchronisieren'),
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
