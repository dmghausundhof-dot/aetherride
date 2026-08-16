/// Ein Storefront-Produkt im FlowLine-Regal. Kauf bleibt Shopify.
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.handle,
    required this.name,
    this.manufacturer = '',
    this.description = '',
    this.priceEur = 0,
    this.currencyCode = 'EUR',
    this.imageUrl,
    this.imageAlt,
    this.affiliateUrl,
    this.slotKey = '',
    this.productType = '',
    this.tags = const [],
    this.availableForSale = true,
  });

  final String id;
  final String handle;
  final String name;
  final String manufacturer;
  final String description;
  final double priceEur;
  final String currencyCode;
  final String? imageUrl;
  final String? imageAlt;
  final String? affiliateUrl;
  final String slotKey;
  final String productType;
  final List<String> tags;
  final bool availableForSale;

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final price = json['priceEur'];
    final tagsRaw = json['tags'];
    return ShopProduct(
      id: '${json['id'] ?? json['handle'] ?? ''}',
      handle: '${json['handle'] ?? ''}',
      name: '${json['name'] ?? json['title'] ?? ''}',
      manufacturer: '${json['manufacturer'] ?? ''}',
      description: '${json['description'] ?? ''}',
      priceEur: price is num ? price.toDouble() : 0,
      currencyCode: '${json['currencyCode'] ?? 'EUR'}',
      imageUrl: json['imageUrl'] as String?,
      imageAlt: json['imageAlt'] as String?,
      affiliateUrl: (json['affiliateUrl'] ?? json['merchantUrl']) as String?,
      slotKey: '${json['slotKey'] ?? ''}',
      productType: '${json['productType'] ?? ''}',
      tags: [
        if (tagsRaw is List)
          for (final t in tagsRaw)
            '$t',
      ],
      availableForSale: json['availableForSale'] != false,
    );
  }
}

class ShopShelves {
  const ShopShelves({
    required this.ok,
    this.parts = const [],
    this.merch = const [],
    this.bikes = const [],
  });

  final bool ok;
  final List<ShopProduct> parts;
  final List<ShopProduct> merch;
  final List<ShopProduct> bikes;

  bool get hasParts => parts.isNotEmpty;
  bool get hasMerch => merch.isNotEmpty;
  bool get hasBikes => bikes.isNotEmpty;

  factory ShopShelves.fromJson(Map<String, dynamic> json) {
    List<ShopProduct> parse(dynamic raw) {
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map<String, dynamic>) ShopProduct.fromJson(item),
      ];
    }

    return ShopShelves(
      ok: json['ok'] == true,
      parts: parse(json['products']),
      merch: parse(json['merch']),
      bikes: parse(json['bikes']),
    );
  }
}
