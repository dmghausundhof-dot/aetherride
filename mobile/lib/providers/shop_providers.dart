import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop/shop_catalog.dart';
import '../domain/shop/shop_product.dart';

final shopShelvesProvider = FutureProvider<ShopShelves>((ref) {
  return fetchShopShelves();
});
