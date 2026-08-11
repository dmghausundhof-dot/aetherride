import 'shop_soft_fit.dart';

/// Storefront / featured-parts product for the App Shop hub + PDP.
class ShopProduct {
  const ShopProduct({
    required this.handle,
    required this.name,
    required this.manufacturer,
    required this.priceEur,
    required this.currency,
    required this.imageUrl,
    this.description = '',
    this.chip = 'universal',
    this.collectionHandle = 'featured-parts',
    this.tags = const [],
    this.softFit = const SoftFitTags(),
    this.compatVerdict = 'universal',
  });

  final String handle;
  final String name;
  final String manufacturer;
  final double priceEur;
  final String currency;
  /// Always a real HTTPS product image (CDN) — never empty for hub/PDP.
  final String imageUrl;
  final String description;
  final String chip;
  final String collectionHandle;
  final List<String> tags;
  final SoftFitTags softFit;
  /// Soft-fit / compat gate verdict for active bike filter.
  final SoftFitVerdict compatVerdict;

  ShopProduct copyWith({
    SoftFitVerdict? compatVerdict,
    String? chip,
  }) {
    return ShopProduct(
      handle: handle,
      name: name,
      manufacturer: manufacturer,
      priceEur: priceEur,
      currency: currency,
      imageUrl: imageUrl,
      description: description,
      chip: chip ?? this.chip,
      collectionHandle: collectionHandle,
      tags: tags,
      softFit: softFit,
      compatVerdict: compatVerdict ?? this.compatVerdict,
    );
  }

  factory ShopProduct.fromJson(
    Map<String, dynamic> e, {
    required String fallbackImage,
    String collectionHandle = 'featured-parts',
  }) {
    final handle = '${e['handle'] ?? ''}'.trim();
    final tagsRaw = e['tags'];
    final tags = tagsRaw is List
        ? [for (final t in tagsRaw) '$t'.trim()].where((s) => s.isNotEmpty).toList()
        : const <String>[];
    final softJson = e['softFit'] is Map
        ? Map<String, dynamic>.from(e['softFit'] as Map)
        : null;
    final soft = softJson != null
        ? SoftFitTags.fromJson(softJson)
        : parseSoftFitTags(tags);
    final slots = soft.slots;
    final slotKey = slots.isNotEmpty
        ? slots.first
        : '${e['slotKey'] ?? e['slot'] ?? 'other'}';
    final price = (e['priceEur'] is num)
        ? (e['priceEur'] as num).toDouble()
        : double.tryParse('${e['priceEur']}') ?? 0;
    final rawImg = '${e['imageUrl'] ?? ''}'.trim();
    return ShopProduct(
      handle: handle.isEmpty ? 'product' : handle,
      name: '${e['name'] ?? e['title'] ?? handle}',
      manufacturer: '${e['manufacturer'] ?? e['vendor'] ?? 'AetherRide'}',
      priceEur: price,
      currency: '${e['currencyCode'] ?? e['currency'] ?? 'EUR'}',
      imageUrl: rawImg.isNotEmpty ? rawImg : fallbackImage,
      description: '${e['description'] ?? ''}'.trim(),
      chip: slotKey,
      collectionHandle: collectionHandle,
      tags: tags,
      softFit: soft,
    );
  }
}
