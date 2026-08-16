import '../../core/config.dart';

/// Share-Text für eine Tour — Seeds öffnen Discover, Katalog die Tour-URL.
abstract final class TourShare {
  static bool usesDiscoverLoop(String tourId) {
    final id = tourId.trim();
    return id.startsWith('seed-');
  }

  static String httpsUrl(String tourId) {
    final id = Uri.encodeComponent(tourId.trim());
    final origin = AppConfig.productionApiBaseUrl;
    if (usesDiscoverLoop(tourId)) {
      return '$origin/discover?loop=$id';
    }
    return '$origin/tours/$id';
  }

  static String appUrl(String tourId) {
    final id = Uri.encodeComponent(tourId.trim());
    if (usesDiscoverLoop(tourId)) {
      return 'aetherride://discover?loop=$id';
    }
    return 'aetherride://tours/$id';
  }

  static String text(String tourId) {
    return 'Tour auf FlowLine: ${httpsUrl(tourId)}\n${appUrl(tourId)}';
  }
}
