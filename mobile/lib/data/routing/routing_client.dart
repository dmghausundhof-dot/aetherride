import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/bike.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../native/routing_core_ffi.dart';
import 'offline_tiles.dart';

enum RoutingProfile {
  mtbTrail,
  mtbEnduro,
  gravel,
  road,
  urban,
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
        RoutingProfile.urban => 'urban',
        RoutingProfile.ebikeTour => 'ebike',
        RoutingProfile.emtb => 'emtb',
        RoutingProfile.hiking => 'hiking',
      };

  /// Multi-Sport UI-Labels (alle Disziplinen gleichwertig).
  String get label => switch (this) {
        RoutingProfile.mtbTrail => 'MTB',
        RoutingProfile.mtbEnduro => 'Enduro',
        RoutingProfile.gravel => 'Gravel',
        RoutingProfile.road => 'Rennrad',
        RoutingProfile.urban => 'City',
        RoutingProfile.ebikeTour => 'E-Trekking',
        RoutingProfile.emtb => 'E-MTB',
        RoutingProfile.hiking => 'Zu Fuß',
      };
}

RoutingProfile routingProfileForBike(BikeCategory category) =>
    switch (category) {
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.dh =>
        RoutingProfile.mtbTrail,
      BikeCategory.mtbEnduro => RoutingProfile.mtbEnduro,
      BikeCategory.gravel => RoutingProfile.gravel,
      BikeCategory.road => RoutingProfile.road,
      BikeCategory.urban => RoutingProfile.urban,
      BikeCategory.emtb => RoutingProfile.emtb,
      BikeCategory.etrekking => RoutingProfile.ebikeTour,
      BikeCategory.hiking => RoutingProfile.hiking,
    };

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
    this.steps = const [],
  });

  final List<GeoPoint> coordinates;
  final double distanceM;
  final double durationS;
  final String? engine;
  final List<RouteStep> steps;
}

class RouteStep {
  const RouteStep({
    required this.id,
    required this.instruction,
    required this.distanceAlongM,
    this.streetName,
    this.lat,
    this.lng,
  });

  final String id;
  final String instruction;
  final double distanceAlongM;
  final String? streetName;
  final double? lat;
  final double? lng;
}

List<RouteStep> stepsFromCoordinates(List<GeoPoint> coords) {
  final raw = navStepsFromPolyline([
    for (final p in coords) (lat: p.lat, lng: p.lng),
  ]);
  return [
    for (final s in raw)
      RouteStep(
        id: s.id,
        instruction: s.instruction,
        distanceAlongM: s.distanceAlongM,
      ),
  ];
}

/// Online `/api/route` + offline `routing_core` FFI (Spec §5.4).
class RoutingClient {
  RoutingClient({
    http.Client? httpClient,
    RoutingCoreFfi? ffi,
  })  : _http = httpClient ?? http.Client(),
        _ffi = ffi ?? RoutingCoreFfi();

  final http.Client _http;
  final RoutingCoreFfi _ffi;

  Future<RouteResult> requestRoute({
    required GeoPoint from,
    required GeoPoint to,
    RoutingProfile profile = RoutingProfile.mtbTrail,
    bool preferOffline = false,
    List<GeoPoint> vias = const [],
  }) async {
    if (preferOffline || AppConfig.preferOfflineRouting) {
      final offline = await _tryOffline(from, to, profile);
      if (offline != null) return offline;
    }

    try {
      return await _requestOnline(from, to, profile, vias: vias);
    } catch (_) {
      final offline = await _tryOffline(from, to, profile);
      if (offline != null) return offline;
      rethrow;
    }
  }

  Future<RouteResult?> _tryOffline(
    GeoPoint from,
    GeoPoint to,
    RoutingProfile profile,
  ) async {
    if (!_ffi.available) return null;
    final tiles = await OfflineTilesStore.instance.ensureTilesPath(
      overridePath: AppConfig.offlineTilesPath.isEmpty
          ? null
          : AppConfig.offlineTilesPath,
    );
    if (tiles == null || !_ffi.tilesOk(tiles)) return null;
    try {
      final r = _ffi.tryOfflineRoute(
        fromLat: from.lat,
        fromLng: from.lng,
        toLat: to.lat,
        toLng: to.lng,
        profile: profile.apiId,
        tilesPath: tiles,
      );
      if (r == null) return null;
      final coords = r.coordinatesLngLat
          .map((c) => GeoPoint(c[1], c[0]))
          .toList();
      return RouteResult(
        coordinates: coords,
        distanceM: r.distanceM,
        durationS: r.durationS,
        engine: r.engine,
        steps: stepsFromCoordinates(coords),
      );
    } on RoutingCoreException {
      return null;
    }
  }

  Future<RouteResult> _requestOnline(
    GeoPoint from,
    GeoPoint to,
    RoutingProfile profile, {
    List<GeoPoint> vias = const [],
  }) async {
    // Web-API: from=lng,lat&to=lng,lat&via=... (Spec /api/route)
    final qp = <String, String>{
      'from': '${from.lng},${from.lat}',
      'to': '${to.lng},${to.lat}',
      'profile': profile.apiId,
    };
    var url = Uri.parse('${AppConfig.apiBaseUrl}/api/route').replace(
      queryParameters: qp,
    );
    if (vias.isNotEmpty) {
      final extra = vias.map((v) => 'via=${v.lng},${v.lat}').join('&');
      url = Uri.parse('${url.toString()}&$extra');
    }
    final res = await _http
        .get(url, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Route failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final coords = <GeoPoint>[];
    final geom = data['geometry'];
    if (geom is Map && geom['coordinates'] is List) {
      for (final c in geom['coordinates'] as List) {
        if (c is List && c.length >= 2) {
          coords.add(
            GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          );
        }
      }
    } else if (geom is List) {
      for (final c in geom) {
        if (c is List && c.length >= 2) {
          coords.add(
            GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          );
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
    final usedFallback = coords.isEmpty;
    if (usedFallback) {
      coords.addAll([from, to]);
    }

    final rawSteps = data['steps'];
    final steps = <RouteStep>[];
    if (rawSteps is List) {
      for (final s in rawSteps) {
        if (s is! Map) continue;
        final instruction = '${s['instruction'] ?? 'Weiter'}';
        final streetRaw = s['streetName'] ?? s['street'] ?? s['name'];
        final streetFromField =
            streetRaw is String && streetRaw.trim().isNotEmpty
                ? streetRaw.trim()
                : null;
        final coord = s['coordinate'];
        double? lat;
        double? lng;
        if (coord is Map) {
          lat = (coord['lat'] as num?)?.toDouble();
          lng = (coord['lng'] as num? ?? coord['lon'] as num?)?.toDouble();
        }
        steps.add(
          RouteStep(
            id: '${s['id']}',
            instruction: instruction,
            distanceAlongM: (s['distanceAlongM'] as num?)?.toDouble() ?? 0,
            streetName: streetFromField ??
                extractStreetNameFromInstruction(instruction),
            lat: lat,
            lng: lng,
          ),
        );
      }
    }

    return RouteResult(
      coordinates: coords,
      distanceM: (data['distance'] as num?)?.toDouble() ??
          (data['distanceM'] as num?)?.toDouble() ??
          0,
      durationS: (data['duration'] as num?)?.toDouble() ??
          (data['durationS'] as num?)?.toDouble() ??
          0,
      engine: usedFallback
          ? 'fallback-line'
          : data['engine'] as String?,
      steps: steps.isNotEmpty ? steps : stepsFromCoordinates(coords),
    );
  }
}

/// Gerade-Linie Out-and-back wenn Live-Routing fehlt / Limit (Web-Parität).
RouteResult approximateOutAndBack({
  required GeoPoint from,
  required GeoPoint to,
  required String label,
}) {
  final mid = GeoPoint((from.lat + to.lat) / 2, (from.lng + to.lng) / 2);
  final coords = [from, mid, to, mid, from];
  final deg = math.sqrt(
    math.pow(to.lat - from.lat, 2) + math.pow(to.lng - from.lng, 2),
  );
  final distM = deg * 111000 * 2 * 1.15;
  return RouteResult(
    coordinates: coords,
    distanceM: distM.roundToDouble(),
    durationS: (distM / 4.5).roundToDouble(),
    engine: 'approx',
    steps: [
      RouteStep(
        id: 'approx-out',
        instruction: 'Näherung „$label“ — Live-Routing später erneut',
        distanceAlongM: distM / 2,
      ),
    ],
  );
}
