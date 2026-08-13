import '../domain/bike.dart';
import '../domain/component.dart';
import '../domain/shop/garage_fit.dart';
import 'config.dart';
import 'shop_web.dart';

/// Öffentliche Shopify-Storefront — kein Katalog, keine Kasse in der App.
///
/// Tag-Filter nutzen die handleisierte Form
/// (`category:gravel` → `/collections/featured-parts/category-gravel`).
/// Siehe https://shopify.dev/docs/storefronts/themes/navigation-search/filtering/tag-filtering
abstract final class ShopifyStorefront {
  ShopifyStorefront._();

  static const partsCollectionDefault = 'featured-parts';
  static const merchCollectionDefault = 'merchandise';

  static String get origin {
    var raw = AppConfig.shopifyStorefrontUrl.trim();
    if (raw.isEmpty) return '';
    if (!raw.contains('://')) raw = 'https://$raw';
    return raw.replaceAll(RegExp(r'/$'), '');
  }

  static bool get isConfigured => origin.isNotEmpty;

  static String get partsCollection {
    final h = AppConfig.shopifyPartsCollection.trim();
    return h.isEmpty ? partsCollectionDefault : h;
  }

  static String get merchCollection {
    final h = AppConfig.shopifyMerchCollection.trim();
    return h.isEmpty ? merchCollectionDefault : h;
  }

  /// Shopify `handleize`: Kleinbuchstaben, Nicht-Alphanumerik → Bindestrich.
  static String handleize(String raw) {
    final out = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-');
    return out.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static Uri? homeUri() {
    if (!isConfigured) return null;
    return Uri.parse('$origin/');
  }

  static Uri? merchUri() {
    if (!isConfigured) return null;
    return collectionUri(merchCollection);
  }

  static Uri? partsUri({List<String> tags = const []}) {
    if (!isConfigured) return null;
    return collectionUri(partsCollection, tags: tags);
  }

  static Uri collectionUri(String handle, {List<String> tags = const []}) {
    final h = handleize(handle);
    final path = StringBuffer('/collections/');
    path.write(h.isEmpty ? partsCollectionDefault : h);
    final handles = [
      for (final t in tags) handleize(t),
    ].where((t) => t.isNotEmpty).toList();
    if (handles.isNotEmpty) {
      path.write('/');
      path.write(handles.join('+'));
    }
    return Uri.parse('$origin$path');
  }

  /// Garage-Fit-Tags für die Collection-URL.
  /// Nur Kategorie (+ Laufrad oder Slot) — kein AND über Schaltung/E-Bike,
  /// sonst leere Trefferlisten. Kein `garage-bike`-Tag (interner Hook).
  static List<String> fitTags(
    Bike bike, {
    List<BikeComponent> components = const [],
    String? slot,
  }) {
    final profile = profileFromBike(bike, components: components);
    if (profile == null) return const [];
    final tags = <String>[];
    if (profile.families.isNotEmpty) {
      tags.add('category:${profile.families.first}');
    }
    final slotKey = slot?.trim() ?? '';
    if (slotKey.isNotEmpty && slotKey != 'all') {
      tags.add('slot:$slotKey');
    } else if (profile.wheelSizes.isNotEmpty) {
      tags.add('wheel:${profile.wheelSizes.first}');
    }
    return tags;
  }

  static Uri? partsFitUri({
    required Bike bike,
    List<BikeComponent> components = const [],
    String? slot,
  }) {
    return partsUri(
      tags: fitTags(bike, components: components, slot: slot),
    );
  }

  static String? slotFromComponent(ComponentSlot slot) =>
      ShopWebLinks.partsSlotFromComponent(slot);
}
