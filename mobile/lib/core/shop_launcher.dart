import 'package:url_launcher/url_launcher.dart';

/// Chrome Custom Tabs (Android) / SFSafariViewController (iOS).
/// Checkout bleibt Shopify. Katalog lebt in FlowLine.
Future<bool> openShopifyStorefront(Uri? uri) async {
  if (uri == null) return false;
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
