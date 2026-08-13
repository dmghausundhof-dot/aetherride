import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/shop/garage_fit.dart';

String _categoryApiId(BikeCategory c) => switch (c) {
      BikeCategory.mtbTrail => 'mtb_trail',
      BikeCategory.mtbAm => 'mtb_am',
      BikeCategory.mtbEnduro => 'mtb_enduro',
      BikeCategory.dh => 'dh',
      BikeCategory.gravel => 'gravel',
      BikeCategory.road => 'road',
      BikeCategory.urban => 'urban',
      BikeCategory.emtb => 'emtb',
      BikeCategory.etrekking => 'etrekking',
      BikeCategory.hiking => 'hiking',
    };

/// Fire-and-forget: Garage-Bike → Shopify Fit-Hook (kein Merch, keine OEM-SKU).
Future<void> notifyGarageBikeShopify(
  Bike bike, {
  List<BikeComponent> components = const [],
  http.Client? httpClient,
}) async {
  if (!isRideableGarageBike(bike.category)) return;
  final client = httpClient ?? http.Client();
  final owned = httpClient == null;
  try {
    final drivetrain = <String>{};
    for (final c in components) {
      if (!c.isInstalled) continue;
      drivetrain.addAll(
        inferDrivetrainTokens(c.manufacturer ?? '', c.model ?? ''),
      );
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/shop/garage-bike');
    await client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'bikeId': bike.id,
            'name': bike.name,
            'brand': bike.brand,
            'model': bike.model,
            'category': _categoryApiId(bike.category),
            'isEbike': bike.hasElectricAssist,
            'wheelSizeFront': wheelFromEnum(bike.wheelSize),
            'wheelSizeRear': wheelFromEnum(bike.wheelSize),
            'catalogBikeId': bike.catalogBikeId,
            'drivetrain': drivetrain.toList(),
            'components': [
              for (final c in components)
                if (c.isInstalled)
                  {
                    'slot': c.slot.apiId,
                    'manufacturer': c.manufacturer,
                    'model': c.model,
                  },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    // Lokal angelegt — Shop-Sync ist best-effort.
  } finally {
    if (owned) client.close();
  }
}
