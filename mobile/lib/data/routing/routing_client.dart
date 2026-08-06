import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

enum RoutingProfile {
  mtbTrail,
  mtbEnduro,
  gravel,
  road,
  ebikeTour,
  emtb,
  hiking,
}

extension RoutingProfileApi on RoutingProfile {
  String get apiId => switch (this) {
        RoutingProfile.mtbTrail => 'mtb_allmountain',
        RoutingProfile.mtbEnduro => 'mtb_enduro',
        RoutingProfile.gravel => 'gravel',
        RoutingProfile.road => 'road',
        RoutingProfile.ebikeTour => 'ebike',
        RoutingProfile.emtb => 'emtb',
        RoutingProfile.hiking => 'hiking',
      };

  String get label => switch (this) {
        RoutingProfile.mtbTrail => 'MTB Trail',
        RoutingProfile.mtbEnduro => 'Enduro',
        RoutingProfile.gravel => 'Gravel',
        RoutingProfile.road => 'Rennrad',
        RoutingProfile.ebikeTour => 'E-Bike Tour',
        RoutingProfile.emtb => 'E-MTB',
        RoutingProfile.hiking => 'Wandern',
      };
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class RouteResult {
  const RouteResult({
    required this.coordinates,
    required this.distanceM,
    required this.durationS,
    this.engine,
  });

  final List<GeoPoint> coordinates;
  final double distanceM;
  final double durationS;
  final String? engine;
}

/// Online routing via Next.js `/api/route` (Valhalla/OSRM). Offline FFI = S7.
class RoutingClient {
  RoutingClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<RouteResult> requestRoute({
    required GeoPoint from,
    required GeoPoint to,
    RoutingProfile profile = RoutingProfile.mtbTrail,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/route').replace(
      queryParameters: {
        'fromLat': '${from.lat}',
        'fromLng': '${from.lng}',
        'toLat': '${to.lat}',
        'toLng': '${to.lng}',
        'profile': profile.apiId,
      },
    );
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Route failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final coords = <GeoPoint>[];
    final geom = data['geometry'] ?? data['coordinates'];
    if (geom is List) {
      for (final c in geom) {
        if (c is List && c.length >= 2) {
          coords.add(GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        } else if (c is Map) {
          coords.add(
            GeoPoint(
              (c['lat'] as num).toDouble(),
              (c['lng'] as num? ?? c['lon'] as num).toDouble(),
            ),
          );
        }
      }
    }
    if (coords.isEmpty) {
      coords.addAll([from, to]);
    }
    return RouteResult(
      coordinates: coords,
      distanceM: (data['distance'] as num?)?.toDouble() ??
          (data['distanceM'] as num?)?.toDouble() ??
          0,
      durationS: (data['duration'] as num?)?.toDouble() ??
          (data['durationS'] as num?)?.toDouble() ??
          0,
      engine: data['engine'] as String?,
    );
  }
}
