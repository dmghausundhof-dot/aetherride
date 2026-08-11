import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';
import '../../domain/compatibility/engine.dart';
import '../../domain/compatibility/rules.dart';
import '../../domain/component.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../providers/app_providers.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ComponentSlot? _slot;
  final _q = TextEditingController();
  List<CatalogCacheData> _items = [];
  bool _loading = false;
  int _wishlistTick = 0;

  static String get _webShopUrl => '${AppConfig.apiBaseUrl}/shop';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(catalogClientProvider).search(
          slot: _slot?.apiId,
          q: _q.text.trim().isEmpty ? null : _q.text.trim(),
          limit: 40,
        );
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _openFullShop() async {
    final uri = Uri.parse(_webShopUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop: $_webShopUrl')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop im Browser: $_webShopUrl')),
        );
      }
    }
  }

  Map<String, dynamic> _attrsFromPayload(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map) return {};
      final raw = decoded['attributes'];
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is List) {
        final out = <String, dynamic>{};
        for (final e in raw) {
          if (e is! Map) continue;
          final key = e['key'] as String?;
          if (key == null) continue;
          final val =
              e['valueNum'] ?? e['valueEnum'] ?? e['value'] ?? e['valueStr'];
          if (val != null) out[key] = val;
        }
        return out;
      }
    } catch (_) {}
    return {};
  }

  String _shopVerdictLabel(CompatVerdict v) => switch (v) {
        CompatVerdict.compatible => 'Compatible',
        CompatVerdict.conditional => 'Conditional',
        CompatVerdict.incompatible => 'Incompatible',
        CompatVerdict.insufficientData => 'Insufficient',
      };

  Color _verdictColor(CompatVerdict v) => switch (v) {
        CompatVerdict.compatible => Colors.green,
        CompatVerdict.conditional => Colors.orange,
        CompatVerdict.incompatible => Colors.redAccent,
        CompatVerdict.insufficientData => AppColors.muted,
      };

  Future<CompatVerdict> _compatFor(CatalogCacheData item) async {
    final bike = await ref.read(garageRepositoryProvider).getActiveBike();
    if (bike == null) return CompatVerdict.insufficientData;
    final slot = ComponentSlotLabel.fromApiId(item.slot);
    if (slot == null) return CompatVerdict.insufficientData;
    final installed =
        await ref.read(componentRepositoryProvider).listInstalled(bike.id);
    final attrs = _attrsFromPayload(item.payloadJson);
    final candidate = BikeComponent(
      id: 'candidate-${item.id}',
      bikeId: bike.id,
      slot: slot,
      manufacturer: item.manufacturer,
      model: item.model,
      catalogModelId: item.id,
      attributes: attrs,
    );
    final results = checkCandidateOnBike(installed, candidate);
    if (results.isEmpty) return CompatVerdict.insufficientData;
    return aggregateVerdict(results);
  }

  Future<void> _toggleWishlist(String id) async {
    await ref.read(userProfileStoreProvider).toggleWishlist(id);
    if (mounted) setState(() => _wishlistTick++);
  }

  Future<void> _showDetail(CatalogCacheData item) async {
    final attrs = _attrsFromPayload(item.payloadJson);
    final store = ref.read(userProfileStoreProvider);
    final wished = store.wishlistIds.contains(item.id);
    final verdict = await _compatFor(item);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var heartOn = wished;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.manufacturer} ${item.model}',
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: heartOn
                              ? 'Von Merkliste entfernen'
                              : 'Zur Merkliste',
                          onPressed: () async {
                            await _toggleWishlist(item.id);
                            setLocal(() => heartOn = !heartOn);
                          },
                          icon: Icon(
                            heartOn ? Icons.favorite : Icons.favorite_border,
                            color: heartOn ? Colors.redAccent : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Slot: ${item.slot}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      'Hersteller: ${item.manufacturer}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _verdictColor(verdict).withValues(alpha: 0.5),
                        ),
                        color: _verdictColor(verdict).withValues(alpha: 0.12),
                      ),
                      child: Text(
                        'Compat: ${_shopVerdictLabel(verdict)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _verdictColor(verdict),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Attribute',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    if (attrs.isEmpty)
                      const Text(
                        'Keine Attribute im Katalog-Payload.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      )
                    else
                      ...attrs.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openFullShop();
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: Text(
                        store.commerceMode == 'marketplace'
                            ? 'Im Marktplatz öffnen'
                            : 'Beispiel-Shop öffnen',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<CatalogCacheData> get _wishlistItems {
    // ignore: unused_local_variable — tick forces rebuild after toggle
    final _ = _wishlistTick;
    final ids = ref.read(userProfileStoreProvider).wishlistIds.toSet();
    if (ids.isEmpty) return const [];
    final byId = {for (final it in _items) it.id: it};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = _wishlistItems;
    // tick forces rebuild after wishlist toggle (store is not a Listenable)
    final wishedIds = {
      ...ref.read(userProfileStoreProvider).wishlistIds,
    };
    final _ = _wishlistTick;

    return Scaffold(
      appBar: AppBar(title: const Text(MultiSportCopy.partsTitle)),
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
                  MultiSportCopy.partsSubtitle,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ComponentSlot?>(
                  initialValue: _slot,
                  decoration: const InputDecoration(
                    labelText: 'Slot',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Alle'),
                    ),
                    for (final s in coreInstallSlots)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) {
                    setState(() => _slot = v);
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    labelText: 'Suche',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loading ? null : _load,
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openFullShop,
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(
                    ref.read(userProfileStoreProvider).commerceMode ==
                            'marketplace'
                        ? 'Marktplatz im Browser'
                        : 'Beispielkatalog im Browser',
                  ),
                ),
              ],
            ),
          ),
          if (wishlist.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'Merkliste',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: wishlist.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final it = wishlist[i];
                  return ActionChip(
                    avatar: const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                    label: Text('${it.manufacturer} ${it.model}'),
                    onPressed: () => _showDetail(it),
                  );
                },
              ),
            ),
          ],
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text(
                          'Keine Einträge — API offline oder Cache leer.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          final onList = wishedIds.contains(it.id);
                          return ListTile(
                            title: Text('${it.manufacturer} ${it.model}'),
                            subtitle: Text('${it.manufacturer} · ${it.model}'),
                            dense: true,
                            onTap: () => _showDetail(it),
                            trailing: IconButton(
                              tooltip: onList
                                  ? 'Von Merkliste entfernen'
                                  : 'Zur Merkliste',
                              icon: Icon(
                                onList
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: onList ? Colors.redAccent : null,
                              ),
                              onPressed: () => _toggleWishlist(it.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
