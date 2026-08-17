import 'package:aetherride_mobile/core/config.dart';
import 'package:aetherride_mobile/core/shopify_storefront.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('handleize folgt Shopify-Tag-URLs', () {
    expect(ShopifyStorefront.handleize('category:gravel'), 'category-gravel');
    expect(ShopifyStorefront.handleize('wheel:700c'), 'wheel-700c');
    expect(ShopifyStorefront.handleize('wheel:27.5'), 'wheel-27-5');
    expect(ShopifyStorefront.handleize('slot:brake_pads'), 'slot-brake-pads');
  });

  test('Storefront-URLs bleiben zu ohne SHOPIFY_COMMERCE_ENABLED', () {
    expect(AppConfig.shopifyCommerceEnabled, isFalse);
    expect(ShopifyStorefront.isConfigured, isFalse);
    expect(ShopifyStorefront.homeUri(), isNull);
    expect(ShopifyStorefront.productUri('sram-kette'), isNull);
    expect(ShopifyStorefront.merchUri(), isNull);
    expect(ShopifyStorefront.partsUri(), isNull);
    const bike = Bike(
      id: 'g1',
      name: 'Gravel',
      category: BikeCategory.gravel,
      wheelSize: WheelSize.c700,
    );
    expect(ShopifyStorefront.partsFitUri(bike: bike), isNull);
  });

  test('Für dein Rad filtert nach Kategorie und Laufrad, nie merch', () {
    const bike = Bike(
      id: 'g1',
      name: 'Gravel',
      category: BikeCategory.gravel,
      wheelSize: WheelSize.c700,
    );
    final tags = ShopifyStorefront.fitTags(bike);
    expect(tags, ['category:gravel', 'wheel:700c']);
    final uri = ShopifyStorefront.collectionUri(
      ShopifyStorefront.partsCollection,
      tags: tags,
    );
    expect(uri.path, '/collections/featured-parts/category-gravel+wheel-700c');
    expect(uri.host, 'dmg-haus-und-hof-shop.myshopify.com');
  });

  test('Merchandise bleibt ungefiltert', () {
    final uri = ShopifyStorefront.collectionUri(
      ShopifyStorefront.merchCollection,
    );
    expect(uri.path, '/collections/merchandise');
    expect(uri.path.contains('category'), isFalse);
  });

  test('Hiking erzeugt keine Fit-Tags', () {
    const bike = Bike(
      id: 'h1',
      name: 'Wander',
      category: BikeCategory.hiking,
    );
    expect(ShopifyStorefront.fitTags(bike), isEmpty);
  });

  test('withLocale hängt en/fr/it an, de bleibt ohne Prefix', () {
    final origin = Uri.parse('${ShopifyStorefront.origin}/');
    expect(ShopifyStorefront.withLocale(origin, 'de').path, '/');
    expect(ShopifyStorefront.withLocale(origin, 'en').path, '/en');
    expect(ShopifyStorefront.withLocale(origin, 'fr-CH').path, '/fr');
    final parts = ShopifyStorefront.collectionUri(
      ShopifyStorefront.merchCollection,
    );
    expect(
      ShopifyStorefront.withLocale(parts, 'it').path,
      '/it/collections/merchandise',
    );
    expect(
      ShopifyStorefront.withLocale(parts, 'de').path,
      '/collections/merchandise',
    );
    final foreign = Uri.parse('https://oneupcomponents.com/products/v3');
    expect(ShopifyStorefront.withLocale(foreign, 'fr'), foreign);
  });
}
