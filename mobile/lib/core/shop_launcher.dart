import 'package:url_launcher/url_launcher.dart';

import 'shop_web.dart';

/// Chrome Custom Tabs (Android) / SFSafariViewController (iOS).
/// Checkout bleibt Shopify. Katalog lebt in FlowLine.
/// myshopify öffnet nur, wenn die Shopify-Kasse an ist.
Future<bool> openShopifyStorefront(Uri? uri) async {
  if (uri == null) return false;
  if (!allowInAppShopOutbound(uri)) return false;
  try {
    final inApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (inApp) return true;
  } catch (_) {}
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
