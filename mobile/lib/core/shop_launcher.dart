import 'package:url_launcher/url_launcher.dart';

/// Chrome Custom Tabs (Android) / SFSafariViewController (iOS).
/// Shop-Flow bleibt im Browser-Chrome der App, ohne In-App-Katalog/Kasse.
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
