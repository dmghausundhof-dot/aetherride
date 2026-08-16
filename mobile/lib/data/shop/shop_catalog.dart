import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../l10n/app_locale.dart';
import '../../domain/shop/shop_product.dart';

/// FlowLine-Regal aus `/api/shop/parts` (Storefront serverseitig).
Future<ShopShelves> fetchShopShelves({http.Client? httpClient}) async {
  final client = httpClient ?? http.Client();
  final owned = httpClient == null;
  try {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/shop/parts').replace(
      queryParameters: {'lang': AppLocaleBinding.chromeLanguageCode},
    );
    final res = await client.get(uri).timeout(const Duration(seconds: 12));
    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) {
      return const ShopShelves(ok: false);
    }
    return ShopShelves.fromJson(json);
  } catch (_) {
    return const ShopShelves(ok: false);
  } finally {
    if (owned) client.close();
  }
}

/// Einzelnes Produkt für Deep-Links `/shop/p/{handle}`.
Future<ShopProduct?> fetchShopProduct(
  String handle, {
  http.Client? httpClient,
}) async {
  final h = handle.trim();
  if (h.isEmpty) return null;
  final client = httpClient ?? http.Client();
  final owned = httpClient == null;
  try {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/shop/products/${Uri.encodeComponent(h)}',
    ).replace(
      queryParameters: {'lang': AppLocaleBinding.chromeLanguageCode},
    );
    final res = await client.get(uri).timeout(const Duration(seconds: 12));
    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic> || json['ok'] != true) return null;
    final product = json['product'];
    if (product is! Map<String, dynamic>) return null;
    return ShopProduct.fromJson(product);
  } catch (_) {
    return null;
  } finally {
    if (owned) client.close();
  }
}
