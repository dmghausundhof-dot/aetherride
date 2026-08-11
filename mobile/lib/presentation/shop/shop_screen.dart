import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/shop_web.dart';
import '../../core/theme/app_theme.dart';
import '../../data/shop/shop_catalog_client.dart';
import '../../data/shop/shop_product.dart';
import '../../data/shop/shop_soft_fit.dart';
import '../../domain/bike.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../providers/app_providers.dart';

/// App Shop hub — featured-parts / Storefront collection (S-FLOW-02/03/05).
/// Single AppBar title · real product photos · in-app PDP ≤2 taps after tab.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _client = ShopCatalogClient();
  List<ShopProduct> _products = [];
  bool _loading = true;
  String? _error;
  String _slot = 'all';
  String? _filterBikeId;
  String _fit = 'all';

  String? _bikeIdFrom(List<Bike>? bikes) {
    if (_filterBikeId != null && _filterBikeId!.isNotEmpty) {
      return _filterBikeId;
    }
    if (bikes == null || bikes.isEmpty) return null;
    Bike? active;
    for (final b in bikes) {
      if (b.isActive) {
        active = b;
        break;
      }
    }
    return (active ?? bikes.first).id;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingFilter();
      _load();
    });
  }

  void _consumePendingFilter() {
    final pending = ref.read(shopPendingFilterProvider);
    if (pending == null) return;
    ref.read(shopPendingFilterProvider.notifier).state = null;
    setState(() {
      if (pending.slot != null && pending.slot!.isNotEmpty) {
        _slot = normalizePartsSlot(pending.slot);
      }
      if (pending.bikeId != null && pending.bikeId!.isNotEmpty) {
        _filterBikeId = pending.bikeId;
      }
      _fit = pending.fit == 'bike' ? 'bike' : 'all';
    });
  }

  Future<SoftFitContext?> _softFitContext(String? bikeId) async {
    if (bikeId == null || bikeId.isEmpty) return null;
    final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
    Bike? bike;
    for (final b in bikes) {
      if (b.id == bikeId) {
        bike = b;
        break;
      }
    }
    final installed =
        await ref.read(componentRepositoryProvider).listInstalled(bikeId);
    return AttrsDimMap.fromInstalled(
      bikeId: bikeId,
      bikeName: bike?.name ?? 'Bike',
      installed: installed,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bikeId = _bikeIdFrom(ref.read(bikesProvider).valueOrNull);
      final ctx = _fit == 'bike' ? await _softFitContext(bikeId) : null;
      // Prefer missing-part slot when Garage opened Shop without explicit slot.
      var slot = _slot;
      if (slot == 'all' &&
          ctx != null &&
          ctx.missingSlots.isNotEmpty &&
          _filterBikeId != null) {
        final mapped =
            ShopWebLinks.partsSlotFromComponent(ctx.missingSlots.first);
        if (mapped != null) slot = mapped;
      }
      final result = await _client.loadCollection(
        slot: slot,
        ctx: ctx,
        fit: _fit,
      );
      if (!mounted) return;
      setState(() {
        if (slot != _slot && slot != 'all') _slot = slot;
        _products = result.products;
        _source = result.source;
        _loading = false;
        _error = result.products.isEmpty
            ? (result.error ?? 'Keine Produkte geladen.')
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      final seed = featuredCollectionSeed();
      setState(() {
        _products = seed;
        _source = 'seed';
        _loading = false;
        _error = seed.isEmpty ? 'Shop offline — bitte erneut versuchen.' : null;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
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

  String _priceLabel(ShopProduct p) {
    final v = p.priceEur.toStringAsFixed(
      p.priceEur == p.priceEur.roundToDouble() ? 0 : 2,
    );
    return '$v €';
  }

  void _openPdp(ShopProduct product) {
    // Tap 2: in-app PDP with real photo (no double title / no merchant chrome).
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height;
        return SafeArea(
          child: SizedBox(
            height: h * 0.92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Schließen',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _ProductPhoto(
                            url: product.imageUrl,
                            handle: product.handle,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.manufacturer,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _priceLabel(product),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          product.description,
                          style: const TextStyle(
                            height: 1.4,
                            fontSize: 15,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openUrl(ShopWebLinks.product(product.handle));
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Im Shop öffnen'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Garage / deep link → filtered Shop (S-FLOW-05).
    ref.listen<ShopPendingFilter?>(shopPendingFilterProvider, (prev, next) {
      if (next == null) return;
      ref.read(shopPendingFilterProvider.notifier).state = null;
      setState(() {
        if (next.slot != null && next.slot!.isNotEmpty) {
          _slot = normalizePartsSlot(next.slot);
        }
        if (next.bikeId != null && next.bikeId!.isNotEmpty) {
          _filterBikeId = next.bikeId;
        }
        _fit = next.fit == 'bike' ? 'bike' : 'all';
      });
      _load();
    });

    final bikeId = _bikeIdFrom(ref.watch(bikesProvider).valueOrNull);
    final partsBridge = ShopWebLinks.parts(
      bikeId: bikeId,
      slot: _slot == 'all' ? null : _slot,
      fitBike: bikeId != null && _fit == 'bike',
    );

    return Scaffold(
      // Single title only — no duplicate body headline (S25 BASELINE).
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _fit == 'bike' && bikeId != null
                      ? 'Passend zu deinem Bike — Foto & Preis, tippen für Details.'
                      : MultiSportCopy.partsSubtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(_slot),
                  initialValue: _slot,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Alle')),
                    DropdownMenuItem(
                      value: 'brake_pads',
                      child: Text('Beläge'),
                    ),
                    DropdownMenuItem(value: 'grips', child: Text('Griffe')),
                    DropdownMenuItem(value: 'fluid', child: Text('Fluid')),
                    DropdownMenuItem(value: 'chain', child: Text('Kette')),
                    DropdownMenuItem(value: 'tire', child: Text('Reifen')),
                    DropdownMenuItem(
                      value: 'cassette',
                      child: Text('Kassette'),
                    ),
                    DropdownMenuItem(
                      value: 'bar_tape',
                      child: Text('Lenkerband'),
                    ),
                    DropdownMenuItem(value: 'gravel', child: Text('Gravel')),
                    DropdownMenuItem(value: 'road', child: Text('Rennrad')),
                    DropdownMenuItem(value: 'urban', child: Text('City')),
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
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          setState(() {
                            _filterBikeId = bikeId;
                            _fit = 'bike';
                          });
                          _load();
                        },
                        icon: const Icon(Icons.pedal_bike, size: 18),
                        label: Text(
                          _fit == 'bike' ? 'Filter: mein Bike' : 'Für mein Bike',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () => _openUrl(partsBridge),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Im Web'),
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
                : _error != null && _products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                size: 40,
                                color: AppColors.muted,
                              ),
                              const SizedBox(height: 12),
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
                                onPressed: () => _openUrl(partsBridge),
                                child: const Text('Im Browser öffnen'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, i) {
                            final p = _products[i];
                            return Material(
                              color: Theme.of(context).cardColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                // Tap 1 from Shop tab → PDP (≤3 taps total).
                                onTap: () => _openPdp(p),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _ProductPhoto(
                                        url: p.imageUrl,
                                        handle: p.handle,
                                        fit: BoxFit.cover,
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
                                          const SizedBox(height: 2),
                                          Text(
                                            p.chip,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: p.compatVerdict == 'passt'
                                                  ? AppColors.trail
                                                  : AppColors.muted,
                                              fontSize: 10,
                                              fontWeight: p.compatVerdict ==
                                                      'passt'
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
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

/// Network product photo with CDN failover — never a blank gray tile.
class _ProductPhoto extends StatefulWidget {
  const _ProductPhoto({
    required this.url,
    required this.handle,
    this.fit = BoxFit.cover,
  });

  final String url;
  final String handle;
  final BoxFit fit;

  @override
  State<_ProductPhoto> createState() => _ProductPhotoState();
}

class _ProductPhotoState extends State<_ProductPhoto> {
  late String _url;
  int _failover = 0;

  @override
  void initState() {
    super.initState();
    _url = widget.url.isNotEmpty
        ? widget.url
        : ShopCdnImages.forHandle(widget.handle);
  }

  @override
  void didUpdateWidget(covariant _ProductPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.handle != widget.handle) {
      _url = widget.url.isNotEmpty
          ? widget.url
          : ShopCdnImages.forHandle(widget.handle);
      _failover = 0;
    }
  }

  void _onError() {
    if (_failover >= ShopCdnImages.pool.length) return;
    final next = ShopCdnImages.pool[_failover % ShopCdnImages.pool.length];
    _failover++;
    if (next == _url && _failover < ShopCdnImages.pool.length) {
      _onError();
      return;
    }
    if (mounted) setState(() => _url = next);
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _url,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: AppColors.surfaceDark,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
        return const ColoredBox(
          color: AppColors.surfaceDark,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
