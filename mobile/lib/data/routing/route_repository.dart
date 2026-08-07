import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/saved_route.dart';
import '../local/app_database.dart';
import 'elevation_client.dart';
import 'routing_client.dart';

List<List<double>> _geoPointsToLngLat(List<GeoPoint> points) =>
    [for (final p in points) [p.lng, p.lat]];

/// Offline-First: UI liest Saved/Cache aus Drift; Netz nur hier.
class RouteRepository {
  RouteRepository(
    this._db, {
    RoutingClient? client,
    ElevationClient? elevation,
  })  : _client = client ?? RoutingClient(),
        _elevation = elevation ?? ElevationClient();

  final AppDatabase _db;
  final RoutingClient _client;
  final ElevationClient _elevation;
  final _uuid = const Uuid();

  /// Last elevation gain from online `/api/elevation` (nullable if offline/fail).
  double? lastElevationGainM;

  Future<List<SavedRouteEntry>> listSaved() async {
    final rows = await (_db.select(_db.savedRoutes)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .get();
    return rows.map(_rowToSaved).toList();
  }

  Future<void> saveEntry(SavedRouteEntry entry) async {
    await _db.into(_db.savedRoutes).insertOnConflictUpdate(
          SavedRoutesCompanion.insert(
            id: entry.id,
            name: entry.name,
            distanceKm: entry.distanceKm,
            elevationM: entry.elevationM,
            durationMin: entry.durationMin,
            source: Value(entry.source),
            geometryJson: Value(
              entry.coordinates.isEmpty
                  ? null
                  : coordsToJson(entry.coordinates),
            ),
            waypointsJson: Value(waypointsToJson(entry.waypoints)),
            layersJson: Value(
              layersToJson(
                approach: entry.approach,
                tour: entry.tour,
                trail: entry.trail,
              ),
            ),
            savedAt: entry.savedAt,
          ),
        );
  }

  Future<SavedRouteEntry> saveComputed({
    required String name,
    required RouteResult result,
    List<SavedWaypoint> waypoints = const [],
    List<GeoPoint> approach = const [],
    List<GeoPoint> tour = const [],
    List<GeoPoint> trail = const [],
    String source = 'engine',
  }) async {
    final entry = SavedRouteEntry(
      id: 'saved-${_uuid.v4()}',
      name: name,
      distanceKm: result.distanceM / 1000,
      elevationM: result.distanceM * 0.03,
      durationMin: (result.durationS / 60).round(),
      savedAt: DateTime.now().toUtc(),
      source: source,
      coordinates: _geoPointsToLngLat(result.coordinates),
      waypoints: waypoints,
      approach: _geoPointsToLngLat(approach),
      tour: _geoPointsToLngLat(tour),
      trail: _geoPointsToLngLat(trail),
    );
    await saveEntry(entry);
    return entry;
  }

  Future<void> deleteSaved(String id) async {
    await (_db.delete(_db.savedRoutes)..where((t) => t.id.equals(id))).go();
  }

  /// Plant A–B (optional Vias): Cache hit zuerst, sonst Client + Cache schreiben.
  Future<RouteResult> planRoute({
    required GeoPoint from,
    required GeoPoint to,
    RoutingProfile profile = RoutingProfile.mtbTrail,
    List<GeoPoint> vias = const [],
    bool preferOffline = false,
  }) async {
    final key = _cacheKey(from, to, profile, vias);
    final cached = await _readCache(key);
    if (cached != null) {
      lastElevationGainM = null;
      return cached;
    }

    final result = await _client.requestRoute(
      from: from,
      to: to,
      profile: profile,
      vias: vias,
      preferOffline: preferOffline,
    );
    if (!preferOffline) {
      final elev = await _elevation.fetchForTrack(result.coordinates);
      lastElevationGainM = elev?.gainM;
    } else {
      lastElevationGainM = null;
    }
    await _writeCache(key, profile, result);
    return result;
  }

  String _cacheKey(
    GeoPoint from,
    GeoPoint to,
    RoutingProfile profile,
    List<GeoPoint> vias,
  ) {
    final viaPart = vias.map((v) => '${v.lng},${v.lat}').join('|');
    return '${profile.apiId}|${from.lng},${from.lat}|${to.lng},${to.lat}|$viaPart';
  }

  Future<RouteResult?> _readCache(String key) async {
    final row = await (_db.select(_db.routeCache)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final data = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      final coords = (data['coordinates'] as List? ?? [])
          .whereType<List>()
          .map(
            (c) => GeoPoint(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ),
          )
          .toList();
      if (coords.length < 2) return null;
      return RouteResult(
        coordinates: coords,
        distanceM: (data['distanceM'] as num?)?.toDouble() ?? 0,
        durationS: (data['durationS'] as num?)?.toDouble() ?? 0,
        engine: data['engine'] as String? ?? 'cache',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String key,
    RoutingProfile profile,
    RouteResult result,
  ) async {
    final payload = jsonEncode({
      'coordinates': [
        for (final p in result.coordinates) [p.lng, p.lat],
      ],
      'distanceM': result.distanceM,
      'durationS': result.durationS,
      'engine': result.engine,
    });
    await _db.into(_db.routeCache).insertOnConflictUpdate(
          RouteCacheCompanion.insert(
            id: key,
            cacheKey: key,
            profile: profile.apiId,
            payloadJson: payload,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
  }

  SavedRouteEntry _rowToSaved(SavedRoute row) {
    final layers = layersFromJson(row.layersJson);
    return SavedRouteEntry(
      id: row.id,
      name: row.name,
      distanceKm: row.distanceKm,
      elevationM: row.elevationM,
      durationMin: row.durationMin,
      savedAt: row.savedAt,
      source: row.source,
      coordinates: coordsFromJson(row.geometryJson),
      waypoints: waypointsFromJson(row.waypointsJson),
      approach: layers.approach,
      tour: layers.tour,
      trail: layers.trail,
    );
  }
}
