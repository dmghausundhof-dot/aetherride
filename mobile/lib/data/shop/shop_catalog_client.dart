import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/shop_web.dart';
import 'shop_product.dart';
import 'shop_soft_fit.dart';

/// Result of loading the App Shop collection (S-FLOW-02/03).
class ShopCatalogResult {
  const ShopCatalogResult({
    required this.products,
    required this.source,
    this.error,
    this.collectionHandle = 'featured-parts',
  });

  final List<ShopProduct> products;
  /// `storefront` | `featured` | `seed`
  final String source;
  final String? error;
  final String collectionHandle;

  bool get hasProducts => products.isNotEmpty;
}

/// Verified Shopify CDN product photos (store files) — never gray placeholders.
abstract final class ShopCdnImages {
  static const pool = <String>[
    'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e.jpg?v=1786479558',
    'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1571068316344-75bc76f77890.jpg?v=1786479566',
    'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e_24d45399-5a57-45a2-a6ac-da88f92d7199.jpg?v=1786479867',
    'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1532298229144-0ec0c57515c7.jpg?v=1786479572',
    'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1507035895480-2b3156c31fc8.jpg?v=1786479574',
  ];

  static String forHandle(String handle) {
    if (pool.isEmpty) {
      return 'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e.jpg?v=1786479558';
    }
    final i = handle.hashCode.abs() % pool.length;
    return pool[i];
  }
}

/// Bundled featured collection — real CDN photos for demo when API is offline.
/// Prefer live `/api/shop/parts` (featured-parts) whenever the server responds.
List<ShopProduct> featuredCollectionSeed() {
  const rows = <Map<String, Object>>[
    {
      'handle': 'orbea-terra-m20',
      'name': 'Orbea Terra M20',
      'manufacturer': 'Orbea',
      'priceEur': 2799.0,
      'chip': 'gravel',
      'description': 'Gravel-Allrounder aus dem AetherRide Shop.',
      'imageUrl':
          'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e.jpg?v=1786479558',
    },
    {
      'handle': 'specialized-diverge-carbon',
      'name': 'Specialized Diverge Carbon',
      'manufacturer': 'Specialized',
      'priceEur': 3499.0,
      'chip': 'gravel',
      'description': 'Carbon-Gravel aus dem AetherRide Shop.',
      'imageUrl':
          'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1571068316344-75bc76f77890.jpg?v=1786479566',
    },
    {
      'handle': 'cube-attain-gtc-race',
      'name': 'Cube Attain GTC Race',
      'manufacturer': 'Cube',
      'priceEur': 1499.0,
      'chip': 'road',
      'description': 'Leichtes Carbon-Rennrad aus dem AetherRide Shop.',
      'imageUrl':
          'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e_24d45399-5a57-45a2-a6ac-da88f92d7199.jpg?v=1786479867',
    },
    {
      'handle': 'canyon-ultimate-cf-sl-8',
      'name': 'Canyon Ultimate CF SL 8',
      'manufacturer': 'Canyon',
      'priceEur': 2499.0,
      'chip': 'road',
      'description': 'Rennrad Performance aus dem AetherRide Shop.',
      'imageUrl':
          'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1532298229144-0ec0c57515c7.jpg?v=1786479572',
    },
    {
      'handle': 'canyon-commuter-7-0',
      'name': 'Canyon Commuter 7.0',
      'manufacturer': 'Canyon',
      'priceEur': 1299.0,
      'chip': 'urban',
      'description': 'City / Light-E aus dem AetherRide Shop.',
      'imageUrl':
          'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1507035895480-2b3156c31fc8.jpg?v=1786479574',
    },
  ];

  return [
    for (final r in rows)
      ShopProduct(
        handle: r['handle']! as String,
        name: r['name']! as String,
        manufacturer: r['manufacturer']! as String,
        priceEur: r['priceEur']! as double,
        currency: 'EUR',
        imageUrl: r['imageUrl']! as String,
        description: r['description']! as String,
        chip: r['chip']! as String,
        collectionHandle: 'featured-parts',
      ),
  ];
}

class ShopCatalogClient {
  ShopCatalogClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Load featured-parts (primary) → featured bikes → seed with real photos.
  /// Optional [ctx] + [fit] apply Soft-Fit / Compat Gates ranking.
  Future<ShopCatalogResult> loadCollection({
    String slot = 'all',
    SoftFitContext? ctx,
    String fit = 'all',
  }) async {
    final origin = ShopWebLinks.origin;
    String? lastError;

    // Backend evaluate API (if present) — fail open to local Soft-Fit.
    final evaluated = await _tryEvaluateApi(
      origin: origin,
      slot: slot,
      bikeId: ctx?.bikeId,
      fit: fit,
    );
    if (evaluated != null && evaluated.products.isNotEmpty) {
      return evaluated;
    }

    try {
      final parts = await _fetchProducts(
        Uri.parse('$origin/api/shop/parts'),
        source: 'storefront',
        collectionHandle: 'featured-parts',
      );
      if (parts != null) {
        final filtered = _rankAndFilter(
          parts.products,
          slot: slot,
          ctx: ctx,
          fit: fit,
        );
        if (filtered.isNotEmpty) {
          return ShopCatalogResult(
            products: filtered,
            source: 'storefront',
            collectionHandle: parts.collectionHandle,
          );
        }
        lastError = parts.error ?? 'Collection leer für diesen Filter.';
      } else {
        lastError = 'Collection nicht erreichbar.';
      }
    } catch (_) {
      lastError = 'Shop vorübergehend offline.';
    }

    try {
      final featured = await _fetchProducts(
        Uri.parse('$origin/api/shop/featured'),
        source: 'featured',
        collectionHandle: 'featured',
      );
      if (featured != null && featured.products.isNotEmpty) {
        return ShopCatalogResult(
          products: _rankAndFilter(
            featured.products,
            slot: slot,
            ctx: ctx,
            fit: fit,
          ),
          source: 'featured',
          collectionHandle: featured.collectionHandle,
          error: lastError,
        );
      }
    } catch (_) {
      // fall through to seed
    }

    final seedAll = featuredCollectionSeed();
    final seed = _rankAndFilter(seedAll, slot: slot, ctx: ctx, fit: fit);
    // Default hub must always show real photos (S25). Unknown filters → full seed.
    final products = seed.isNotEmpty ? seed : seedAll;
    return ShopCatalogResult(
      products: products,
      source: 'seed',
      collectionHandle: 'featured-parts',
      error: seed.isEmpty && slot != 'all'
          ? 'Keine Treffer für diesen Filter — Collection wird vollständig gezeigt.'
          : lastError,
    );
  }

  /// Optional backend: GET /api/shop/evaluate?bikeId=&slot=&fit=
  Future<ShopCatalogResult?> _tryEvaluateApi({
    required String origin,
    required String slot,
    String? bikeId,
    required String fit,
  }) async {
    if (bikeId == null || bikeId.isEmpty) return null;
    try {
      final uri = Uri.parse('$origin/api/shop/evaluate').replace(
        queryParameters: {
          'bikeId': bikeId,
          if (slot != 'all' && slot.isNotEmpty) 'slot': slot,
          'fit': fit,
        },
      );
      final res = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map || json['ok'] != true) return null;
      final raw = json['products'];
      if (raw is! List || raw.isEmpty) return null;
      final list = <ShopProduct>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final h = '${m['handle'] ?? ''}'.trim();
        if (h.isEmpty) continue;
        var p = ShopProduct.fromJson(
          m,
          fallbackImage: ShopCdnImages.forHandle(h),
          collectionHandle:
              '${json['collectionHandle'] ?? 'featured-parts'}',
        );
        final v = '${m['verdict'] ?? m['compatVerdict'] ?? ''}'.trim();
        if (v.isNotEmpty) p = p.copyWith(compatVerdict: v);
        list.add(p);
      }
      if (list.isEmpty) return null;
      return ShopCatalogResult(
        products: list,
        source: 'evaluate',
        collectionHandle: '${json['collectionHandle'] ?? 'featured-parts'}',
      );
    } catch (_) {
      return null;
    }
  }

  Future<ShopCatalogResult?> _fetchProducts(
    Uri uri, {
    required String source,
    required String collectionHandle,
  }) async {
    final res = await _http.get(uri, headers: {'Accept': 'application/json'}).timeout(
          const Duration(seconds: 18),
        );
    if (res.statusCode != 200) {
      String? msg;
      try {
        final body = jsonDecode(res.body);
        if (body is Map) msg = body['error'] as String?;
      } catch (_) {}
      return ShopCatalogResult(
        products: const [],
        source: source,
        collectionHandle: collectionHandle,
        error: msg ?? 'HTTP ${res.statusCode}',
      );
    }

    final json = jsonDecode(res.body);
    if (json is! Map) return null;
    final raw = json['products'];
    if (raw is! List) return null;
    final handle =
        '${json['collectionHandle'] ?? collectionHandle}'.trim().isEmpty
            ? collectionHandle
            : '${json['collectionHandle'] ?? collectionHandle}';
    final list = <ShopProduct>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final h = '${m['handle'] ?? ''}'.trim();
      if (h.isEmpty) continue;
      list.add(
        ShopProduct.fromJson(
          m,
          fallbackImage: ShopCdnImages.forHandle(h),
          collectionHandle: handle,
        ),
      );
    }
    return ShopCatalogResult(
      products: list,
      source: source,
      collectionHandle: handle,
      error: list.isEmpty ? (json['error'] as String?) : null,
    );
  }

  List<ShopProduct> _rankAndFilter(
    List<ShopProduct> products, {
    required String slot,
    SoftFitContext? ctx,
    required String fit,
  }) {
    final slotNorm = normalizePartsSlot(slot);
    final ranked = <ShopProduct>[];
    for (final p in products) {
      if (!productMatchesSlotFilter(p.softFit, p.chip, slotNorm)) continue;
      if (!productMatchesSoftFitFilter(p.softFit, ctx, fit)) continue;
      final verdict = softFitVerdict(p.softFit, ctx);
      final slotLabel =
          p.softFit.slots.isNotEmpty ? p.softFit.slots.first : p.chip;
      ranked.add(
        p.copyWith(
          compatVerdict: verdict,
          chip: softFitChipLabel(verdict, slotLabel),
        ),
      );
    }
    if (fit == 'bike' && ctx != null) {
      int rank(SoftFitVerdict v) =>
          v == 'passt' ? 0 : (v == 'universal' ? 1 : 2);
      ranked.sort(
        (a, b) => rank(a.compatVerdict).compareTo(rank(b.compatVerdict)),
      );
    }
    return ranked;
  }
}
