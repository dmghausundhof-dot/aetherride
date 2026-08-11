import 'config.dart';
import '../domain/component.dart';

/// Canonical Web shop URLs (S-FLOW-01 / S-FLOW-03).
/// App shows Storefront collection in-grid; Web is the Soft-Fit bridge.
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

  /// In-app deep link: aetherride://shop?bikeId=&slot=&fit=bike
  static String appShopDeepLink({
    String? bikeId,
    String? slot,
    bool fitBike = true,
  }) {
    final params = <String, String>{};
    if (bikeId != null && bikeId.isNotEmpty) {
      params['bikeId'] = bikeId;
    }
    if (slot != null && slot.isNotEmpty && slot != 'all') {
      params['slot'] = slot;
    }
    if (fitBike && bikeId != null && bikeId.isNotEmpty) {
      params['fit'] = 'bike';
    }
    if (params.isEmpty) return 'aetherride://shop';
    return Uri(
      scheme: 'aetherride',
      host: 'shop',
      queryParameters: params,
    ).toString();
  }

  /// Map Garage ComponentSlot → Web/App parts browse slot (S-FLOW-05).
  static String? partsSlotFromComponent(ComponentSlot slot) {
    return switch (slot) {
      ComponentSlot.chain => 'chain',
      ComponentSlot.cassette => 'cassette',
      ComponentSlot.grips => 'grips',
      ComponentSlot.tireFront || ComponentSlot.tireRear => 'tire',
      ComponentSlot.brakeFront || ComponentSlot.brakeRear => 'brake_pads',
      ComponentSlot.rotorFront || ComponentSlot.rotorRear => 'brake_pads',
      _ => null,
    };
  }
}
