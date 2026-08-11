import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/sport/discipline_ux.dart';

class _ShopPart {
  const _ShopPart({
    required this.handle,
    required this.name,
    required this.manufacturer,
    required this.priceEur,
    required this.currency,
    this.imageUrl,
    this.chip = 'universal',
  });

  final String handle;
  final String name;
  final String manufacturer;
  final double priceEur;
  final String currency;
  final String? imageUrl;
  final String chip;
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  List<_ShopPart> _parts = [];
  bool _loading = true;
  String? _error;
  bool _storeLocked = true;
  bool _apiConfigured = false;
  String _slot = 'all';

  static String get _webOrigin => AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  static String get _webShopUrl => '$_webOrigin/shop';
  static String get _webPartsUrl => '$_webOrigin/shop/parts';
  static String _webProductUrl(String handle) =>
      '$_webOrigin/shop/p/${Uri.encodeComponent(handle)}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statusUri = Uri.parse('$_webOrigin/api/shop/status');
      final partsUri = Uri.parse('$_webOrigin/api/shop/parts');
      final results = await Future.wait([
        http.get(statusUri).timeout(const Duration(seconds: 12)),
        http.get(partsUri).timeout(const Duration(seconds: 20)),
      ]);
      final statusRes = results[0];
      final partsRes = results[1];

      var locked = true;
      var configured = false;
      if (statusRes.statusCode == 200) {
        final s = jsonDecode(statusRes.body);
        if (s is Map) {
          locked = s['onlineStoreLocked'] != false;
          configured = s['storefrontApiConfigured'] == true;
        }
      }

      if (partsRes.statusCode != 200) {
        final body = jsonDecode(partsRes.body);
        final msg = body is Map
            ? (body['error'] as String? ?? 'Collection nicht geladen')
            : 'Collection nicht geladen';
        if (mounted) {
          setState(() {
            _storeLocked = locked;
            _apiConfigured = configured;
            _parts = [];
            _loading = false;
            _error = msg;
          });
        }
        return;
      }

      final json = jsonDecode(partsRes.body);
      final raw = json is Map ? json['products'] : null;
      final list = <_ShopPart>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final handle = '${e['handle'] ?? ''}'.trim();
          if (handle.isEmpty) continue;
          final soft = e['softFit'];
          final slots = soft is Map && soft['slots'] is List
              ? (soft['slots'] as List).map((x) => '$x').toList()
              : const <String>[];
          final slotKey = slots.isNotEmpty
              ? slots.first
              : '${e['slotKey'] ?? 'other'}';
          if (_slot != 'all' && slotKey != _slot) continue;
          final price = (e['priceEur'] is num)
              ? (e['priceEur'] as num).toDouble()
              : double.tryParse('${e['priceEur']}') ?? 0;
          list.add(
            _ShopPart(
              handle: handle,
              name: '${e['name'] ?? handle}',
              manufacturer: '${e['manufacturer'] ?? 'AetherRide'}',
              priceEur: price,
              currency: '${e['currencyCode'] ?? 'EUR'}',
              imageUrl: e['imageUrl'] as String?,
              chip: slotKey,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _storeLocked = locked;
          _apiConfigured = configured;
          _parts = list;
          _loading = false;
          _error = list.isEmpty
              ? (configured
                  ? 'Keine Treffer in featured-parts.'
                  : 'Storefront API nicht konfiguriert — Token auf dem Server setzen.')
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Shop offline (${AppConfig.apiBaseUrl}). Bitte später erneut.';
          _parts = [];
        });
      }
    }
  }

  Future<void> _openUrl(String url, {required bool warnLockedExternal}) async {
    final uri = Uri.parse(url);
    final isMyshopify = url.contains('myshopify.com');
    if (isMyshopify && (_storeLocked || warnLockedExternal)) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Online Store gesperrt'),
          content: const Text(
            'Der Shopify Online Store ist passwortgeschützt (Owner Preview). '
            'Der Link öffnet die Passwort-Seite — kein stiller Dead End.\n\n'
            'Katalog & Soft-Fit laufen in AetherRide über die Storefront API. '
            'Store-Passwort wird nicht in der App ausgeliefert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zurück'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Trotzdem öffnen'),
            ),
          ],
        ),
      );
      if (go != true) return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Öffnen: $url')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Browser: $url')),
        );
      }
    }
  }

  String _priceLabel(_ShopPart p) {
    final v = p.priceEur.toStringAsFixed(p.priceEur == p.priceEur.roundToDouble() ? 0 : 2);
    return '$v €';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(MultiSportCopy.partsTitle),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  MultiSportCopy.partsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Live Collection featured-parts — Soft-Fit & Preise in AetherRide.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                if (_storeLocked) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _apiConfigured
                                ? 'Owner Preview: Online Store gesperrt. Katalog via Storefront API — keine Passwort-Dead-Ends in der App.'
                                : 'Owner Preview: Store gesperrt · Storefront API fehlt auf dem Server.',
                            style: const TextStyle(fontSize: 12, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _slot,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Alle')),
                    DropdownMenuItem(value: 'brake_pads', child: Text('Beläge')),
                    DropdownMenuItem(value: 'grips', child: Text('Griffe')),
                    DropdownMenuItem(value: 'fluid', child: Text('Fluid')),
                    DropdownMenuItem(value: 'chain', child: Text('Kette')),
                    DropdownMenuItem(value: 'tire', child: Text('Reifen')),
                    DropdownMenuItem(value: 'cassette', child: Text('Kassette')),
                  ],
                  onChanged: (v) {
                    setState(() => _slot = v ?? 'all');
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openUrl(
                          '$_webPartsUrl?fit=bike',
                          warnLockedExternal: false,
                        ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Web · Parts'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(
                          _webShopUrl,
                          warnLockedExternal: false,
                        ),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Shop-Hub'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _parts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _load,
                                child: const Text('Erneut laden'),
                              ),
                              TextButton(
                                onPressed: () => _openUrl(
                                  _webPartsUrl,
                                  warnLockedExternal: false,
                                ),
                                child: const Text('Im Browser öffnen'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _parts.length,
                          itemBuilder: (context, i) {
                            final p = _parts[i];
                            return Material(
                              color: Theme.of(context).cardColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _openUrl(
                                  _webProductUrl(p.handle),
                                  warnLockedExternal: false,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (p.imageUrl != null &&
                                              p.imageUrl!.isNotEmpty)
                                            Image.network(
                                              p.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const ColoredBox(
                                                color: AppColors.chipIdle,
                                                child: Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            )
                                          else
                                            const ColoredBox(
                                              color: AppColors.chipIdle,
                                              child: Icon(
                                                Icons.pedal_bike,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          Positioned(
                                            left: 6,
                                            top: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                p.chip,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        8,
                                        10,
                                        10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.manufacturer,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _priceLabel(p),
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
