import '../domain/component.dart';
import 'config.dart';

/// Slot-Handles für Shopify-Tag-Filter (`slot:chain` → `slot-chain`).
/// Storefront-URLs: [ShopifyStorefront].
class ShopWebLinks {
  ShopWebLinks._();

  static String? partsSlotFromComponent(ComponentSlot slot) {
    return switch (slot) {
      ComponentSlot.chain => 'chain',
      ComponentSlot.cassette => 'cassette',
      ComponentSlot.grips => 'grips',
      ComponentSlot.tireFront || ComponentSlot.tireRear => 'tire',
      ComponentSlot.brakeFront || ComponentSlot.brakeRear => 'brake_pads',
      _ => null,
    };
  }
}

/// FlowLine-Web-Katalog (S-FLOW-03). Keine Shopify-Passwortseite.
class FlowLineWeb {
  FlowLineWeb._();

  static String get _origin =>
      AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');

  static Uri hub() => Uri.parse('$_origin/shop');

  static Uri product(String handle) {
    final h = handle.trim();
    return Uri.parse('$_origin/shop/p/${Uri.encodeComponent(h)}');
  }

  static Uri parts({String? bikeId, String? slot, String fit = 'bike'}) {
    final params = <String, String>{'door': 'parts'};
    if (slot != null && slot.isNotEmpty && slot != 'all') {
      params['slot'] = slot;
    }
    if (bikeId != null && bikeId.isNotEmpty) {
      params['bike'] = bikeId;
      params['fit'] = fit;
    }
    return Uri.parse('$_origin/shop').replace(queryParameters: params);
  }
}

bool isShopifyOnlineStoreUri(Uri uri) {
  final host = uri.host.toLowerCase();
  return host.endsWith('.myshopify.com') || host.contains('shopify.com');
}

/// Custom Tabs: myshopify nur mit Shopify-Kasse. Händler- und FlowLine-URLs bleiben.
bool allowInAppShopOutbound(Uri uri) {
  if (isShopifyOnlineStoreUri(uri)) return AppConfig.shopifyCommerceEnabled;
  return true;
}

/// S-FLOW-04: echte Produkt- oder Produktsuche-URLs, keine Händler-Homepages.
bool isDeepProductUri(Uri uri) {
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  final path = uri.path.replaceAll(RegExp(r'/+$'), '');
  final host = uri.host.toLowerCase();
  if (isShopifyOnlineStoreUri(uri)) {
    return RegExp(r'/products/[^/]+').hasMatch(path);
  }
  if (path.isEmpty) return false;
  if (RegExp(r'/products?/', caseSensitive: false).hasMatch(path)) return true;
  if (RegExp(r'/(dp|gp|item|p)/', caseSensitive: false).hasMatch(path)) {
    return true;
  }
  // Bike24 DE: /p2391234.html (no slash after p)
  if (RegExp(r'/p\d+(\.html)?$', caseSensitive: false).hasMatch(path)) {
    return true;
  }
  if (host.contains('bike24.') &&
      RegExp(r'p\d+(\.html)?$', caseSensitive: false).hasMatch(path)) {
    return true;
  }
  if (RegExp(r'/product/', caseSensitive: false).hasMatch(path)) return true;
  for (final key in const ['q', 'query', 'searchterm', 'searchparam']) {
    final v = uri.queryParameters[key]?.trim() ?? '';
    if (v.length >= 3) return true;
  }
  return false;
}

Uri trackedMerchantUri(Uri uri) {
  final host = uri.host.toLowerCase();
  final isBike24 = host.contains('bike24.');
  final prefix = AppConfig.bike24DeepLinkPrefix.trim();
  if (!isBike24 || prefix.isEmpty) return uri;
  final raw = uri.toString();
  if (raw.startsWith(prefix)) return uri;
  return Uri.parse('$prefix${Uri.encodeComponent(raw)}');
}

/// Händler-CTA oder null (Shopify-Kasse bleibt [ShopifyStorefront.productUri]).
Uri? merchantCtaUri(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty || t.startsWith('/')) return null;
  final uri = Uri.tryParse(t);
  if (uri == null || !isDeepProductUri(uri)) return null;
  if (isShopifyOnlineStoreUri(uri)) return null;
  return trackedMerchantUri(uri);
}
