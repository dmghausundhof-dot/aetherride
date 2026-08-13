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

  test('Für dein Rad filtert nach Kategorie und Laufrad, nie merch', () {
    const bike = Bike(
      id: 'g1',
      name: 'Gravel',
      category: BikeCategory.gravel,
      wheelSize: WheelSize.c700,
    );
    final tags = ShopifyStorefront.fitTags(bike);
    expect(tags, ['category:gravel', 'wheel:700c']);
    final uri = ShopifyStorefront.partsFitUri(bike: bike)!;
    expect(uri.path, '/collections/featured-parts/category-gravel+wheel-700c');
    expect(uri.host, 'dmg-haus-und-hof-shop.myshopify.com');
  });

  test('Merchandise bleibt ungefiltert', () {
    final uri = ShopifyStorefront.merchUri()!;
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
}
