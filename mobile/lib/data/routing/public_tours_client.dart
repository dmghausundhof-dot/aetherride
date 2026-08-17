import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/bike.dart';
import '../local/user_profile_store.dart';

/// Redaktionelle Tour aus GET /api/tours/catalog.
class PublicTourHit {
  const PublicTourHit({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    required this.durationMin,
    required this.difficulty,
    required this.surface,
    required this.loop,
    required this.regionSlug,
    required this.centerLng,
    required this.centerLat,
    required this.categories,
    this.summary,
    this.tags = const [],
  });

  final String id;
  final String name;
  final double distanceKm;
  final int elevationM;
  final int durationMin;
  final String difficulty;
  final String surface;
  final bool loop;
  final String regionSlug;
  final double centerLng;
  final double centerLat;
  final List<BikeCategory> categories;
  final String? summary;

  /// Redaktionelle Tags aus `/api/tours/catalog` (trail, region, …).
  final List<String> tags;

  factory PublicTourHit.fromJson(Map<String, dynamic> m) {
    final center = m['center'];
    double lng = 0;
    double lat = 0;
    if (center is List && center.length >= 2) {
      lng = (center[0] as num).toDouble();
      lat = (center[1] as num).toDouble();
    }
    final cats = <BikeCategory>[];
    final rawCats = m['categories'];
    if (rawCats is List) {
      for (final c in rawCats) {
        final cat = categoryFromApi(c?.toString());
        if (cat != null) cats.add(cat);
      }
    }
    final primary = categoryFromApi(m['primaryCategory'] as String?);
    if (primary != null && !cats.contains(primary)) cats.insert(0, primary);

    final tags = <String>[];
    final rawTags = m['tags'];
    if (rawTags is List) {
      for (final t in rawTags) {
        final s = t?.toString().trim();
        if (s != null && s.isNotEmpty && !tags.contains(s)) tags.add(s);
      }
    }

    return PublicTourHit(
      id: (m['id'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
      elevationM: (m['elevationM'] as num?)?.round() ?? 0,
      durationMin: (m['durationMin'] as num?)?.round() ?? 0,
      difficulty: (m['difficulty'] as String?) ?? '—',
      surface: (m['surface'] as String?) ?? 'mixed/urban',
      loop: m['loop'] == true,
      regionSlug: (m['regionSlug'] as String?) ?? '',
      centerLng: lng,
      centerLat: lat,
      categories: cats.isEmpty ? [BikeCategory.mtbAm] : cats,
      summary: m['summary'] as String?,
      tags: tags,
    );
  }
}

/// Live / editorial polyline from GET `/api/tours/geometry?id=`.
class CatalogTourGeometryHit {
  const CatalogTourGeometryHit({
    required this.coordinates,
    this.engine,
  });

  /// GeoJSON order: `[lng, lat]`.
  final List<List<double>> coordinates;
  final String? engine;
}

/// Redaktionelle Region-Gruppe aus GET `/api/tours/catalog` `sets`.
class EditorialSetHit {
  const EditorialSetHit({
    required this.id,
    required this.regionSlug,
    required this.name,
    required this.tourIds,
    required this.count,
  });

  final String id;
  final String regionSlug;
  final String name;
  final List<String> tourIds;
  final int count;

  factory EditorialSetHit.fromJson(Map<String, dynamic> m) {
    final ids = <String>[];
    final raw = m['tourIds'];
    if (raw is List) {
      for (final e in raw) {
        final id = '$e'.trim();
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return EditorialSetHit(
      id: (m['id'] as String?) ?? '',
      regionSlug: (m['regionSlug'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      tourIds: ids,
      count: (m['count'] as num?)?.round() ?? ids.length,
    );
  }
}

class PublicCatalogSnapshot {
  const PublicCatalogSnapshot({
    required this.tours,
    this.sets = const [],
    this.honesty = '',
  });

  final List<PublicTourHit> tours;
  final List<EditorialSetHit> sets;
  final String honesty;
}

class PublicToursClient {
  PublicToursClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// [sport]: road|gravel|mtb|urban|ebike|all
  Future<List<PublicTourHit>> fetchCatalog({
    String sport = 'all',
    String? region,
  }) async {
    final snap = await fetchCatalogSnapshot(sport: sport, region: region);
    return snap.tours;
  }

  Future<PublicCatalogSnapshot> fetchCatalogSnapshot({
    String sport = 'all',
    String? region,
  }) async {
    final q = <String, String>{'sport': sport};
    if (region != null && region.isNotEmpty) q['region'] = region;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/tours/catalog')
        .replace(queryParameters: q);
    try {
      final res = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return const PublicCatalogSnapshot(tours: []);
      final data = jsonDecode(res.body);
      if (data is! Map) return const PublicCatalogSnapshot(tours: []);
      final raw = data['tours'];
      final out = <PublicTourHit>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final hit =
                PublicTourHit.fromJson(Map<String, dynamic>.from(item));
            if (hit.id.isNotEmpty && hit.name.isNotEmpty) out.add(hit);
          }
        }
      }
      final sets = <EditorialSetHit>[];
      final rawSets = data['sets'];
      if (rawSets is List) {
        for (final item in rawSets) {
          if (item is Map) {
            final set =
                EditorialSetHit.fromJson(Map<String, dynamic>.from(item));
            if (set.id.isNotEmpty && set.tourIds.length >= 3) sets.add(set);
          }
        }
      }
      return PublicCatalogSnapshot(
        tours: out,
        sets: sets,
        honesty: '${data['honesty'] ?? ''}'.trim(),
      );
    } catch (_) {
      return const PublicCatalogSnapshot(tours: []);
    }
  }

  /// GET `/api/tours/geometry?id=` — editorial override or live ring.
  Future<CatalogTourGeometryHit?> fetchGeometry({
    required String tourId,
    String? profile,
  }) async {
    if (tourId.isEmpty) return null;
    final q = <String, String>{'id': tourId};
    if (profile != null && profile.isNotEmpty) q['profile'] = profile;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/tours/geometry')
        .replace(queryParameters: q);
    try {
      final res = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 22));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is! Map) return null;
      final geom = data['geometry'];
      List? raw;
      if (geom is Map) raw = geom['coordinates'] as List?;
      if (raw == null) return null;
      final coords = <List<double>>[];
      for (final c in raw) {
        if (c is List && c.length >= 2) {
          coords.add([
            (c[0] as num).toDouble(),
            (c[1] as num).toDouble(),
          ]);
        }
      }
      if (coords.length < 2) return null;
      return CatalogTourGeometryHit(
        coordinates: coords,
        engine: data['engine'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Map RoutingProfile / BikeCategory → catalog sport query.
String catalogSportForProfile(String profileApiId) {
  if (profileApiId.contains('road')) return 'road';
  if (profileApiId.contains('gravel')) return 'gravel';
  if (profileApiId.contains('urban')) return 'urban';
  if (profileApiId.contains('ebike') || profileApiId.contains('emtb')) {
    return 'ebike';
  }
  if (profileApiId.contains('mtb') || profileApiId.contains('enduro')) {
    return 'mtb';
  }
  return 'all';
}

/// API uses snake_case (`mtb_am`); Dart enum is camelCase (`mtbAm`).
BikeCategory? categoryFromApi(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final direct = bikeCategoryFromName(raw);
  if (direct != null) return direct;
  return switch (raw.replaceAll('-', '_').toLowerCase()) {
    'mtb_trail' => BikeCategory.mtbTrail,
    'mtb_am' || 'mtb' => BikeCategory.mtbAm,
    'mtb_enduro' || 'enduro' => BikeCategory.mtbEnduro,
    'dh' || 'downhill' => BikeCategory.dh,
    'gravel' => BikeCategory.gravel,
    'road' || 'rennrad' => BikeCategory.road,
    'urban' || 'city' => BikeCategory.urban,
    'cargo' || 'lastenrad' => BikeCategory.cargo,
    'folding' || 'faltrad' => BikeCategory.folding,
    'kids' || 'kinderrad' => BikeCategory.kids,
    'emtb' => BikeCategory.emtb,
    'etrekking' || 'ebike' || 'e_trekking' => BikeCategory.etrekking,
    'hiking' || 'wandern' => BikeCategory.hiking,
    _ => null,
  };
}
