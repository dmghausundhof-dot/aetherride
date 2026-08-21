import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/shop_launcher.dart';
import '../../core/shop_web.dart';
import '../../core/shopify_storefront.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/flowline_mark.dart';
import '../../data/shop/shop_catalog.dart';
import '../../domain/bike.dart';
import '../../domain/shop/garage_fit.dart';
import '../../domain/shop/shop_product.dart';
import '../../domain/shop/shop_slot_labels.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../../providers/shop_providers.dart';
import '../garage/rad_nav_mark.dart';
import '../garage/rad_stand_frame.dart';
import '../shell/shell_tabs.dart';
import 'shop_product_sheet.dart';

/// Laden-Gateway: FlowLine-Regal + Tür zu Shopify. Kein Tab, keine In-App-Kasse.
/// Push nur über [openShopGateway] / Deep-Link, und nur wenn [AppConfig.shopEnabled].
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _search = TextEditingController();
  String _slot = 'all';
  bool _fitOnly = false;
  String? _focusBikeId;
  String? _queuedHandle;
  bool _openingHandle = false;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(shopPendingSlotProvider);
    if (pending != null && pending.isNotEmpty) {
      _slot = pending;
    }
    final handle = ref.read(shopPendingHandleProvider);
    if (handle != null && handle.isNotEmpty) {
      _queuedHandle = handle;
    }
    final fitOnly = ref.read(shopPendingFitOnlyProvider);
    if (fitOnly == true) {
      _fitOnly = true;
    }
    final pendingBike = ref.read(shopPendingBikeIdProvider);
    if (pendingBike != null && pendingBike.isNotEmpty) {
      _focusBikeId = pendingBike;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearShopPending();
    });
  }

  void _clearShopPending() {
    if (ref.read(shopPendingSlotProvider) != null) {
      ref.read(shopPendingSlotProvider.notifier).state = null;
    }
    if (ref.read(shopPendingHandleProvider) != null) {
      ref.read(shopPendingHandleProvider.notifier).state = null;
    }
    if (ref.read(shopPendingFitOnlyProvider) != null) {
      ref.read(shopPendingFitOnlyProvider.notifier).state = null;
    }
    if (ref.read(shopPendingBikeIdProvider) != null) {
      ref.read(shopPendingBikeIdProvider.notifier).state = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Bike> _rideable(List<Bike>? bikes) {
    if (bikes == null) return const [];
    return [
      for (final b in bikes)
        if (isRideableGarageBike(b.category)) b,
    ];
  }

  List<Bike> _fitBikes(List<Bike> rideable) {
    if (rideable.isEmpty) return const [];
    final id = _focusBikeId;
    if (id != null) {
      final one = [for (final b in rideable) if (b.id == id) b];
      if (one.isNotEmpty) return one;
    }
    return rideable;
  }

  Bike? _doorBike(List<Bike> rideable) {
    if (rideable.isEmpty) return null;
    final focused = _fitBikes(rideable);
    if (focused.length == 1) return focused.first;
    for (final b in rideable) {
      if (b.isActive) return b;
    }
    return rideable.first;
  }

  String? _fitLabel(ShopProduct p, List<Bike> bikes) {
    final profiles = <GarageBikeProfile>[];
    for (final b in bikes) {
      final profile = profileFromBike(b);
      if (profile != null) profiles.add(profile);
    }
    if (profiles.isEmpty) return null;
    final result = matchGarageFit(
      parseGarageFitConstraint(
        tags: p.tags,
        title: p.name,
        productType: p.productType,
        slotKey: p.slotKey,
        description: p.description,
      ),
      profiles,
      selectedBikeId: profiles.length == 1 ? profiles.first.id : null,
    );
    if (result.kind != 'match') return null;
    return result.label;
  }

  Future<void> _openWeb(
    BuildContext context,
    AppLocalizations l10n,
    Uri uri,
  ) async {
    final ok = await openShopifyStorefront(uri);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shopOpenFailed)),
    );
  }

  Future<void> _open(
    BuildContext context,
    AppLocalizations l10n,
    Uri? uri,
  ) async {
    final localized = uri == null
        ? null
        : isShopifyOnlineStoreUri(uri)
            ? ShopifyStorefront.withLocale(
                uri,
                Localizations.localeOf(context).languageCode,
              )
            : uri;
    if (localized != null && !allowInAppShopOutbound(localized)) {
      return;
    }
    final ok = await openShopifyStorefront(localized);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shopOpenFailed)),
    );
  }

  Future<void> _showProduct(
    BuildContext context,
    AppLocalizations l10n,
    ShopProduct product,
    List<Bike> fitBikes,
  ) {
    final connected = ShopifyStorefront.isConfigured;
    final dealer = merchantCtaUri(product.affiliateUrl);
    return showShopProductSheet(
      context: context,
      product: product,
      l10n: l10n,
      fitLabel: _fitLabel(product, fitBikes),
      onOpenShop:
          connected && AppConfig.shopifyCommerceEnabled
              ? () => _open(context, l10n, _productUri(product))
              : null,
      onOpenWeb: () =>
          _openWeb(context, l10n, FlowLineWeb.product(product.handle)),
      onOpenDealer:
          dealer == null ? null : () => _open(context, l10n, dealer),
    );
  }

  Uri? _productUri(ShopProduct p) {
    return ShopifyStorefront.productUri(p.handle);
  }

  List<ShopProduct> _visible(List<ShopProduct> all, List<Bike> fitBikes) {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final p in all)
        if ((_slot == 'all' || p.slotKey == _slot) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.manufacturer.toLowerCase().contains(q) ||
                p.slotKey.toLowerCase().contains(q)) &&
            (!_fitOnly ||
                fitBikes.isEmpty ||
                _fitLabel(p, fitBikes) != null))
          p,
    ];
  }

  Future<void> _tryOpenQueuedHandle() async {
    final handle = _queuedHandle;
    if (handle == null || _openingHandle || !mounted) return;
    final async = ref.read(shopShelvesProvider);
    if (async.isLoading) return;
    _openingHandle = true;
    ShopProduct? found;
    final catalog = async.valueOrNull;
    if (catalog != null) {
      for (final p in [...catalog.parts, ...catalog.merch, ...catalog.bikes]) {
        if (p.handle == handle) {
          found = p;
          break;
        }
      }
    }
    found ??= await fetchShopProduct(handle);
    if (!mounted) return;
    _queuedHandle = null;
    _openingHandle = false;
    final l10n = AppLocalizations.of(context);
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shopProductMissing)),
      );
      return;
    }
    await _showProduct(
      context,
      l10n,
      found,
      _fitBikes(_rideable(ref.read(bikesProvider).valueOrNull)),
    );
  }

  void _applyPendingSlot(String? next) {
    if (next == null || next.isEmpty) return;
    setState(() => _slot = next);
    Future<void>(() {
      if (!mounted) return;
      if (ref.read(shopPendingSlotProvider) == next) {
        ref.read(shopPendingSlotProvider.notifier).state = null;
      }
    });
  }

  void _applyPendingHandle(String? next) {
    if (next == null || next.isEmpty) return;
    setState(() => _queuedHandle = next);
    Future<void>(() {
      if (!mounted) return;
      if (ref.read(shopPendingHandleProvider) == next) {
        ref.read(shopPendingHandleProvider.notifier).state = null;
      }
    });
  }

  void _applyPendingFitOnly(bool? next) {
    if (next != true) return;
    setState(() => _fitOnly = true);
    Future<void>(() {
      if (!mounted) return;
      if (ref.read(shopPendingFitOnlyProvider) == true) {
        ref.read(shopPendingFitOnlyProvider.notifier).state = null;
      }
    });
  }

  void _applyPendingBike(String? next) {
    if (next == null || next.isEmpty) return;
    setState(() => _focusBikeId = next);
    Future<void>(() {
      if (!mounted) return;
      if (ref.read(shopPendingBikeIdProvider) == next) {
        ref.read(shopPendingBikeIdProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(shopPendingSlotProvider, (_, next) {
      _applyPendingSlot(next);
    });
    ref.listen<String?>(shopPendingHandleProvider, (_, next) {
      _applyPendingHandle(next);
    });
    ref.listen<bool?>(shopPendingFitOnlyProvider, (_, next) {
      _applyPendingFitOnly(next);
    });
    ref.listen<String?>(shopPendingBikeIdProvider, (_, next) {
      _applyPendingBike(next);
    });

    final l10n = AppLocalizations.of(context);
    final rideable = _rideable(ref.watch(bikesProvider).valueOrNull);
    final fitBikes = _fitBikes(rideable);
    final doorBike = _doorBike(rideable);
    final connected = ShopifyStorefront.isConfigured;
    final shelves = ref.watch(shopShelvesProvider);
    final catalog = shelves.valueOrNull;
    final parts = _visible(catalog?.parts ?? const [], fitBikes);
    if (_queuedHandle != null && !shelves.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryOpenQueuedHandle();
      });
    }
    final merch = catalog?.merch ?? const [];
    final slots = <String>{
      'all',
      if (_slot != 'all') _slot,
      for (final p in catalog?.parts ?? const [])
        if (p.slotKey.isNotEmpty) p.slotKey,
    }.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FlowLineWordmark(fontSize: 18, markSize: 22),
            Text(
              l10n.shopGatewayTitle,
              key: const Key('shop-appbar-title'),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(shopShelvesProvider);
            await ref.read(shopShelvesProvider.future);
          },
          child: SingleChildScrollView(
            key: const Key('shop-gateway'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.shopGatewayKicker,
                  style: const TextStyle(
                    color: AppColors.chrome,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.shopGatewayTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.shopGatewayHint,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (AppConfig.shopifyCommerceEnabled &&
                    AppConfig.shopifyOnlineStoreLocked) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.shopPasswordWall,
                    key: const Key('shop-password-wall'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (catalog != null &&
                    catalog.ok &&
                    !catalog.hasParts &&
                    merch.isEmpty &&
                    !shelves.isLoading) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.shopCatalogEmpty,
                    key: const Key('shop-catalog-empty'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (catalog != null && !catalog.ok && !shelves.isLoading) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.shopCatalogFailed,
                    key: const Key('shop-catalog-failed'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('shop-retry'),
                      onPressed: () => ref.invalidate(shopShelvesProvider),
                      child: Text(l10n.shopRetry),
                    ),
                  ),
                ],
                if (catalog != null && catalog.hasParts) ...[
                const SizedBox(height: AppSpacing.l),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.shopSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                if (slots.length > 1) ...[
                  const SizedBox(height: AppSpacing.m),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: slots.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final id = slots[i];
                        final selected = _slot == id;
                        final label =
                            id == 'all' ? l10n.shopAllParts : shopSlotLabel(id);
                        return FilterChip(
                          selected: selected,
                          showCheckmark: false,
                          label: Text(label),
                          onSelected: (_) => setState(() => _slot = id),
                          selectedColor: AppColors.sage.withValues(alpha: 0.35),
                          backgroundColor: AppColors.surfaceDark,
                          side: BorderSide(
                            color: selected ? AppColors.sage : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: selected
                                ? AppColors.sageOnDark
                                : AppColors.muted,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (rideable.length > 1) ...[
                  const SizedBox(height: AppSpacing.m),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            key: const Key('shop-bike-all'),
                            selected: _focusBikeId == null,
                            showCheckmark: false,
                            label: Text(l10n.shopFitAllBikes),
                            onSelected: (_) =>
                                setState(() => _focusBikeId = null),
                            selectedColor:
                                AppColors.sage.withValues(alpha: 0.35),
                            backgroundColor: AppColors.surfaceDark,
                            side: BorderSide(
                              color: _focusBikeId == null
                                  ? AppColors.sage
                                  : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _focusBikeId == null
                                  ? AppColors.sageOnDark
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        for (final b in rideable)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              key: Key('shop-bike-${b.id}'),
                              selected: _focusBikeId == b.id,
                              showCheckmark: false,
                              label: Text(b.name),
                              onSelected: (_) =>
                                  setState(() => _focusBikeId = b.id),
                              selectedColor:
                                  AppColors.sage.withValues(alpha: 0.35),
                              backgroundColor: AppColors.surfaceDark,
                              side: BorderSide(
                                color: _focusBikeId == b.id
                                    ? AppColors.sage
                                    : AppColors.border,
                              ),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: _focusBikeId == b.id
                                    ? AppColors.sageOnDark
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (fitBikes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      fitBikes.length == 1
                          ? l10n.shopFitBanner(fitBikes.first.name)
                          : l10n.shopFitBannerAll,
                      style: const TextStyle(
                        color: AppColors.sageOnDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      key: const Key('shop-fit-only'),
                      selected: _fitOnly,
                      showCheckmark: false,
                      label: Text(l10n.shopFitOnly),
                      onSelected: (v) => setState(() => _fitOnly = v),
                      selectedColor: AppColors.sage.withValues(alpha: 0.35),
                      backgroundColor: AppColors.surfaceDark,
                      side: BorderSide(
                        color: _fitOnly ? AppColors.sage : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _fitOnly
                            ? AppColors.sageOnDark
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ],
                ],
                const SizedBox(height: AppSpacing.xl),
                if (AppConfig.shopifyCommerceEnabled && !connected) ...[
                  Text(
                    l10n.shopNotConnected,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.shopNotConnectedHint,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ] else if (AppConfig.shopifyCommerceEnabled) ...[
                  FilledButton(
                    key: const Key('shop-go'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () =>
                        _open(context, l10n, ShopifyStorefront.homeUri()),
                    child: Text(
                      l10n.shopZumShop,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                if (shelves.isLoading) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (catalog != null && catalog.hasBikes) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.shopFeaturedBikes,
                    key: const Key('shop-featured-bikes'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final p in catalog.bikes.take(8))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: _ShopProductCard(
                        key: Key('shop-featured-${p.handle}'),
                        product: p,
                        onOpen: () =>
                            _showProduct(context, l10n, p, const []),
                        openLabel: l10n.shopDetails,
                      ),
                    ),
                ],
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.shopFeatured,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final p in parts.take(24))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: _ShopProductCard(
                        key: Key('shop-product-${p.handle}'),
                        product: p,
                        fitLabel: _fitLabel(p, fitBikes),
                        onOpen: () => _showProduct(context, l10n, p, fitBikes),
                        openLabel: l10n.shopDetails,
                      ),
                    ),
                ] else if (catalog?.ok == true &&
                    (catalog?.hasParts ?? false) &&
                    (_search.text.trim().isNotEmpty ||
                        _slot != 'all' ||
                        _fitOnly)) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.shopShelfEmpty,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (merch.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.shopMerchTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final p in merch.take(12))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: _ShopProductCard(
                        key: Key('shop-product-${p.handle}'),
                        product: p,
                        onOpen: () =>
                            _showProduct(context, l10n, p, const []),
                        openLabel: l10n.shopDetails,
                      ),
                    ),
                ] else if (catalog != null &&
                    catalog.ok &&
                    catalog.hasParts &&
                    !shelves.isLoading) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.shopMerchTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    l10n.shopMerchEmpty,
                    key: const Key('shop-merch-empty'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                if (doorBike == null)
                  _ShopDoor(
                    mark: const RadNavMark(color: AppColors.chrome, size: 22),
                    title: l10n.werkstattForYourBike,
                    hint: l10n.shopForYourBikeEmpty,
                    actionLabel: l10n.garageAddBike,
                    onTap: () {
                      ref.read(garageOpenAddPendingProvider.notifier).state =
                          true;
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      ref.read(shellTabIndexProvider.notifier).state =
                          ShellTabs.werkstatt;
                    },
                  )
                else if (catalog == null || !catalog.ok || !catalog.hasParts)
                  _ShopDoor(
                    key: const Key('shop-parts'),
                    mark: const RadNavMark(color: AppColors.chrome, size: 22),
                    title: l10n.werkstattForYourBike,
                    hint: l10n.shopForYourBikeHint(doorBike.name),
                    onTap: connected
                        ? () => _open(
                              context,
                              l10n,
                              ShopifyStorefront.partsFitUri(bike: doorBike),
                            )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({
    super.key,
    required this.product,
    required this.openLabel,
    this.fitLabel,
    this.onOpen,
  });

  final ShopProduct product;
  final String openLabel;
  final String? fitLabel;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final price = shopPriceLabel(product);
    final desc = product.description.trim();

    return Material(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _ShopImageFallback(),
                            )
                          : const _ShopImageFallback(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.manufacturer.isNotEmpty)
                      Text(
                        product.manufacturer.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (fitLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          fitLabel!,
                          style: const TextStyle(
                            color: AppColors.sageOnDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      openLabel,
                      style: const TextStyle(
                        color: AppColors.chrome,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.north_east, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopDoor extends StatelessWidget {
  const _ShopDoor({
    super.key,
    this.icon,
    this.mark,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onTap,
  });

  final IconData? icon;
  final Widget? mark;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.charcoal.withValues(alpha: 0.10),
        highlightColor: AppColors.charcoal.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mark ??
                  Icon(
                    icon ?? Icons.storefront_outlined,
                    color: AppColors.chrome,
                    size: 22,
                  ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: AppColors.chrome,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                actionLabel != null ? Icons.arrow_forward : Icons.north_east,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopImageFallback extends StatelessWidget {
  const _ShopImageFallback();

  @override
  Widget build(BuildContext context) {
    return const RadShopStandFallback();
  }
}

/// Rad → Laden. Push, kein Tab. Fit und Slot sitzen in den Pending-Providern.
void openShopGateway(
  BuildContext context,
  WidgetRef ref, {
  String? bikeId,
  String? slot,
  bool fitOnly = true,
}) {
  if (!AppConfig.shopEnabled) return;
  if (bikeId != null && bikeId.isNotEmpty) {
    ref.read(shopPendingBikeIdProvider.notifier).state = bikeId;
  }
  if (slot != null && slot.isNotEmpty) {
    ref.read(shopPendingSlotProvider.notifier).state = slot;
  }
  if (fitOnly) {
    ref.read(shopPendingFitOnlyProvider.notifier).state = true;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
  );
}
