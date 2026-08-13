import 'package:aetherride_mobile/domain/shop/shop_shelf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Merch-Tags landen nicht im Teile-Regal', () {
    expect(
      classifyShopProduct(tags: const ['merch'], title: 'Cap'),
      ShopShelf.merch,
    );
    expect(
      isMerchProduct(productType: 'T-Shirt', title: 'Hof-Tee'),
      isTrue,
    );
  });

  test('Ersatzteile bleiben parts', () {
    expect(
      classifyShopProduct(slotKey: 'tire', title: 'Reifen 29'),
      ShopShelf.parts,
    );
    expect(
      classifyShopProduct(tags: const ['category:gravel'], title: 'Kette'),
      ShopShelf.parts,
    );
  });
}
