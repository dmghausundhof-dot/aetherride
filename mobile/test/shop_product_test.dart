import 'package:aetherride_mobile/domain/shop/shop_product.dart';
import 'package:aetherride_mobile/domain/shop/shop_slot_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShopShelves liest Storefront-JSON', () {
    final shelves = ShopShelves.fromJson({
      'ok': true,
      'products': [
        {
          'id': 'gid://shopify/Product/1',
          'handle': 'sram-kette',
          'name': 'SRAM Kette',
          'manufacturer': 'SRAM',
          'priceEur': 16.99,
          'currencyCode': 'EUR',
          'slotKey': 'chain',
          'tags': ['category:gravel', 'slot:chain'],
        },
      ],
      'merch': [],
    });
    expect(shelves.ok, isTrue);
    expect(shelves.hasParts, isTrue);
    expect(shelves.hasMerch, isFalse);
    expect(shelves.parts.single.tags, contains('category:gravel'));
    expect(shelves.parts.single.priceEur, 16.99);
  });

  test('Slot-Labels bleiben deutsch und ehrlich', () {
    expect(shopSlotLabel('chain'), 'Kette');
    expect(shopSlotLabel('brake_pads'), 'Beläge');
    expect(shopSlotLabel('unknown_slot'), 'unknown slot');
  });
}
