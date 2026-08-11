import 'config.dart';
import '../domain/component.dart';

/// Canonical Web shop URLs (S-FLOW-01 / S-FLOW-03).
/// App Storefront grid + deep-link into Web for Soft-Fit / product detail.
class ShopWebLinks {
  ShopWebLinks._();

  static String get origin =>
      AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');

  static String shopHub() => '$origin/shop';

  static String parts({
    String? bikeId,
    String? slot,
    bool fitBike = false,
  }) {
    final params = <String, String>{};
    if (slot != null && slot.isNotEmpty && slot != 'all') {
      params['slot'] = slot;
    }
    if (bikeId != null && bikeId.isNotEmpty) {
      params['bike'] = bikeId;
      params['fit'] = 'bike';
    } else if (fitBike) {
      params['fit'] = 'bike';
    }
    if (params.isEmpty) return '$origin/shop/parts';
    return Uri.parse('$origin/shop/parts')
        .replace(queryParameters: params)
        .toString();
  }

  static String product(String handle) =>
      '$origin/shop/p/${Uri.encodeComponent(handle)}';

  /// Map Garage ComponentSlot → Web parts browse slot (S-FLOW-05).
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
