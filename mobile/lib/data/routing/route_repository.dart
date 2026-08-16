import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/routing/engine_steps_along.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/saved_route.dart';
import '../local/app_database.dart';
import 'elevation_client.dart';
import 'offline_maps_prefs.dart';
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
    double? elevationGainM,
  }) async {
    final entry = SavedRouteEntry(
      id: 'saved-${_uuid.v4()}',
      name: name,
      distanceKm: result.distanceM / 1000,
      elevationM: elevationGainM != null && elevationGainM > 0
          ? elevationGainM
          : result.distanceM * 0.03,
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
    bool fetchElevation = true,
  }) async {
    final key = _cacheKey(from, to, profile, vias);
    final cached = await _readCache(key);
    if (cached != null &&
        !isImplausibleAbDetour(
          distanceM: cached.distanceM,
          fromLat: from.lat,
          fromLng: from.lng,
          toLat: to.lat,
          toLng: to.lng,
          vias: [
            for (final v in vias) (lat: v.lat, lng: v.lng),
          ],
        )) {
      lastElevationGainM = null;
      return cached;
    }
    if (cached != null) {
      await invalidateRoute(from: from, to: to, profile: profile, vias: vias);
    }

    final result = await _client.requestRoute(
      from: from,
      to: to,
      profile: profile,
      vias: vias,
      preferOffline: preferOffline,
    );
    final packCovers = await OfflineMapsPrefs.coversRoute(
      fromLng: from.lng,
      fromLat: from.lat,
      toLng: to.lng,
      toLat: to.lat,
    );
    if (fetchElevation && !preferOffline && !packCovers) {
      final elev = await _elevation.fetchForTrack(result.coordinates);
      lastElevationGainM = elev?.gainM;
    } else {
      lastElevationGainM = null;
    }
    // Fallback-/Näherungs-Geometrie (Live-Routing lieferte keine echte
    // Route) nicht persistent cachen — sonst überlebt ein einmaliger
    // Ausfall den nächsten echten Versuch (siehe _readCache-Gegenstück).
    if (result.engine != 'fallback-line' && result.engine != 'approx') {
      await _writeCache(key, profile, result);
    }
    return result;
  }

  /// Turn-by-turn entlang eines bestehenden Tracks: Engine-Steps, Track bleibt.
  Future<RouteResult> planNavAlongTrack({
    required List<GeoPoint> track,
    RoutingProfile profile = RoutingProfile.mtbTrail,
  }) async {
    final samples = sampleTrackWaypoints(track, maxPoints: 8);
    if (samples.length < 2) {
      return RouteResult(
        coordinates: track,
        distanceM: 0,
        durationS: 0,
        engine: 'none',
        steps: const [],
      );
    }
    return planRoute(
      from: samples.first,
      to: samples.last,
      vias: samples.length > 2
          ? samples.sublist(1, samples.length - 1)
          : const [],
      profile: profile,
      preferOffline: false,
      fetchElevation: false,
    );
  }

  Future<({double? startM, double? endM})> endpointElevations(
    GeoPoint a,
    GeoPoint b,
  ) {
    return _elevation.fetchEndpointElevations(a, b);
  }

  /// Löscht einen einzelnen Cache-Eintrag — für Aufrufer, die ein
  /// zurückgegebenes Ergebnis nachträglich als unplausibel erkennen (z. B.
  /// Discover-Quick: Distanz passt nicht zum angefragten Zeitbudget) und vor
  /// einem Retry sicherstellen wollen, dass nicht wieder derselbe Eintrag
  /// zurückkommt.
  Future<void> invalidateRoute({
    required GeoPoint from,
    required GeoPoint to,
    RoutingProfile profile = RoutingProfile.mtbTrail,
    List<GeoPoint> vias = const [],
  }) async {
    final key = _cacheKey(from, to, profile, vias);
    await (_db.delete(_db.routeCache)..where((t) => t.cacheKey.equals(key)))
        .go();
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

  /// Kein zeitloser Cache: eine Route, die heute stimmt, kann durch
  /// Sperrungen/Bauarbeiten/Trail-Änderungen morgen falsch sein — und ein
  /// einmal geschriebener Fallback-/Fehler-Eintrag darf nicht für immer
  /// als „Ergebnis" durchgehen (siehe [_writeCache]: solche Engines werden
  /// gar nicht erst gecacht, das hier ist die zweite Absicherung für
  /// Alt-Einträge aus einer Zeit vor diesem Fix).
  static const _cacheTtl = Duration(hours: 6);

  Future<RouteResult?> _readCache(String key) async {
    final row = await (_db.select(_db.routeCache)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    if (DateTime.now().toUtc().difference(row.fetchedAt) > _cacheTtl) {
      await (_db.delete(_db.routeCache)..where((t) => t.cacheKey.equals(key)))
          .go();
      return null;
    }
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
      final engine = data['engine'] as String?;
      // Fallback-/Näherungs-Ergebnisse nie als Cache-Hit ausgeben — sonst
      // klebt ein einmaliger Routing-Ausfall (Geometrie fehlte) für die
      // gesamte TTL als scheinbares Ergebnis fest, statt beim nächsten
      // Versuch live neu zu rechnen.
      if (engine == 'fallback-line' || engine == 'approx') return null;
      final rawWarnings = data['warnings'];
      final warnings = <String>[];
      if (rawWarnings is List) {
        for (final w in rawWarnings) {
          if (w is String && w.trim().isNotEmpty) warnings.add(w.trim());
        }
      }
      return RouteResult(
        coordinates: coords,
        distanceM: (data['distanceM'] as num?)?.toDouble() ?? 0,
        durationS: (data['durationS'] as num?)?.toDouble() ?? 0,
        engine: engine ?? 'cache',
        warnings: warnings,
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
      'warnings': result.warnings,
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
