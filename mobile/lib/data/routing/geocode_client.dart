import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../l10n/app_locale.dart';

/// `49.398, 8.715` (lat,lng) or `8.715, 49.398` (lng,lat).
GeocodeHit? geocodeHitFromCoordinates(String query) {
  final m = RegExp(
    r'^\s*(-?\d+(?:\.\d+)?)\s*[,;]\s*(-?\d+(?:\.\d+)?)\s*$',
  ).firstMatch(query.trim());
  if (m == null) return null;
  final a = double.tryParse(m.group(1)!);
  final b = double.tryParse(m.group(2)!);
  if (a == null || b == null) return null;
  final double lat;
  final double lng;
  if (a.abs() <= 90 && b.abs() <= 180 && a.abs() > b.abs() && b.abs() <= 90) {
    lat = a;
    lng = b;
  } else if (b.abs() <= 90 && a.abs() <= 180) {
    lng = a;
    lat = b;
  } else {
    return null;
  }
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return GeocodeHit(
    label: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
    lat: lat,
    lng: lng,
    kind: 'coords',
  );
}

class GeocodeHit {
  const GeocodeHit({
    required this.label,
    required this.lat,
    required this.lng,
    this.kind,
    this.name,
  });

  final String label;
  final double lat;
  final double lng;
  final String? kind;
  final String? name;

  String get matchName => (name ?? label.split(',').first).trim();
}

/// Prefix match only when the next character is not another letter
/// ("Berlin" matches, "Berlingen" does not).
bool geocodeNameMatchesQuery(String name, String query) {
  final n = name.trim().toLowerCase();
  final q = query.trim().toLowerCase();
  if (q.isEmpty || !n.startsWith(q)) return false;
  if (n.length == q.length) return true;
  final next = n[q.length];
  return next == ' ' || next == '-' || next == '/' || next == ',';
}

bool isCinemaQuery(String query) {
  return RegExp(
    r'\b(kino|cinema|kinopolis|cineplex|filmpalast|kinotreff)\b',
    caseSensitive: false,
  ).hasMatch(query.trim());
}

/// Place tokens without the cinema keyword, or "" when the query is only "Kino".
String? cinemaPlaceQuery(String query) {
  if (!isCinemaQuery(query)) return null;
  return query
      .replaceAll(
        RegExp(
          r'\b(kino|cinema|kinopolis|cineplex|filmpalast|kinotreff)\b',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double geocodeHaversineKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  double toRad(double d) => d * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) *
          math.cos(toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * 6371 * math.asin(math.min(1, math.sqrt(a)));
}

int geocodeHitScore(
  String query,
  GeocodeHit hit, {
  double? biasLat,
  double? biasLng,
}) {
  final q = query.trim().toLowerCase();
  final name = hit.matchName.toLowerCase();
  var s = 0;
  if (name == q) {
    s += 100;
  } else if (geocodeNameMatchesQuery(name, q)) {
    s += 45;
  }
  final kind = hit.kind ?? '';
  if (kind == 'city' || kind == 'locality') s += 25;
  if (kind == 'street' || kind == 'house') s -= 15;
  final hay = '$name ${hit.label}'.toLowerCase();
  for (final token in q.split(RegExp(r'\s+')).where((t) => t.length >= 3)) {
    if (hay.contains(token)) s += 12;
  }
  if (isCinemaQuery(query) &&
      RegExp(
        r'(kino|cinema|filmpalast|kinopolis|cineplex|kinotreff)',
        caseSensitive: false,
      ).hasMatch(hay)) {
    s += 20;
  }
  if (biasLat != null &&
      biasLng != null &&
      biasLat.isFinite &&
      biasLng.isFinite) {
    final km = geocodeHaversineKm(biasLat, biasLng, hit.lat, hit.lng);
    if (km <= 8) {
      s += 55;
    } else if (km <= 25) {
      s += 28;
    } else if (km <= 60) {
      s += 8;
    } else {
      s -= ((km - 60) / 4).clamp(0, 50).round();
    }
  }
  return s;
}

List<GeocodeHit> rankGeocodeHits(
  String query,
  List<GeocodeHit> hits, {
  double? biasLat,
  double? biasLng,
}) {
  final copy = [...hits];
  copy.sort(
    (a, b) => geocodeHitScore(
      query,
      b,
      biasLat: biasLat,
      biasLng: biasLng,
    ).compareTo(
      geocodeHitScore(
        query,
        a,
        biasLat: biasLat,
        biasLng: biasLng,
      ),
    ),
  );
  return copy;
}

List<GeocodeHit> dedupeGeocodeHits(List<GeocodeHit> hits) {
  final seen = <String>{};
  final out = <GeocodeHit>[];
  for (final h in hits) {
    final key = '${h.lat.toStringAsFixed(4)},${h.lng.toStringAsFixed(4)}';
    if (seen.add(key)) out.add(h);
  }
  return out;
}

/// Adresssuche über Next `/api/geocode` (Photon).
class GeocodeClient {
  GeocodeClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _photonUa = 'AetherRide/1.0 (browse-geocode)';

  Future<List<GeocodeHit>> search(
    String query, {
    int limit = 5,
    double? biasLat,
    double? biasLng,
    bool preferPlaces = false,
  }) async {
    var q = query.trim();
    // Adb/%-Eingaben und Copy-Paste mit Encoding robust machen.
    try {
      if (q.contains('%')) q = Uri.decodeComponent(q);
    } catch (_) {}
    q = q.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (q.length < 2) return const [];
    final coords = geocodeHitFromCoordinates(q);
    if (coords != null) return [coords];
    if (preferPlaces) {
      try {
        final places = await _photon(
          q,
          limit: limit,
          biasLat: biasLat,
          biasLng: biasLng,
          osmTag: 'place',
        );
        if (places.isNotEmpty) {
          return rankGeocodeHits(q, places).take(limit).toList();
        }
      } catch (_) {}
    }
    final params = <String, String>{
      'q': q,
      'limit': '$limit',
      'lang': AppLocaleBinding.chromeLanguageCode,
    };
    if (biasLat != null && biasLng != null) {
      params['lat'] = biasLat.toStringAsFixed(5);
      params['lon'] = biasLng.toStringAsFixed(5);
    }
    if (preferPlaces) params['prefer'] = 'place';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/geocode').replace(
      queryParameters: params,
    );
    final res = await _http.get(uri, headers: {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw StateError('Geocode ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is! Map) return const [];
    final raw = data['hits'];
    if (raw is! List) return const [];
    var hits = [
      for (final e in raw)
        if (e is Map)
          GeocodeHit(
            label: (e['label'] as String?)?.trim() ?? '',
            lat: (e['lat'] as num?)?.toDouble() ?? 0,
            lng: (e['lng'] as num?)?.toDouble() ?? 0,
            kind: e['kind'] as String?,
            name: (e['name'] as String?)?.trim(),
          ),
    ]
        .where(
          (h) =>
              h.label.isNotEmpty &&
              (h.lat.abs() > 1e-6 || h.lng.abs() > 1e-6) &&
              h.lat.abs() <= 90 &&
              h.lng.abs() <= 180,
        )
        .toList();
    if (isCinemaQuery(q) && biasLat != null && biasLng != null) {
      try {
        final place = cinemaPlaceQuery(q);
        final extra = await _photon(
          (place == null || place.isEmpty) ? q : place,
          limit: limit,
          biasLat: biasLat,
          biasLng: biasLng,
          osmTag: 'amenity:cinema',
        );
        hits = [...extra, ...hits];
      } catch (_) {}
    }
    return rankGeocodeHits(
      q,
      dedupeGeocodeHits(hits),
      biasLat: biasLat,
      biasLng: biasLng,
    ).take(limit).toList();
  }

  Future<List<GeocodeHit>> _photon(
    String q, {
    required int limit,
    double? biasLat,
    double? biasLng,
    String? osmTag,
  }) async {
    final lang = AppLocaleBinding.chromeLanguageCode;
    final params = <String, String>{
      'q': q,
      'limit': '$limit',
      'lang': lang == 'nl' ? 'en' : lang,
    };
    if (biasLat != null && biasLng != null) {
      params['lat'] = biasLat.toStringAsFixed(5);
      params['lon'] = biasLng.toStringAsFixed(5);
    }
    if (osmTag != null) params['osm_tag'] = osmTag;
    final uri = Uri.https('photon.komoot.io', '/api/', params);
    final res = await _http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': _photonUa,
      },
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body);
    if (data is! Map) return const [];
    final raw = data['features'];
    if (raw is! List) return const [];
    final hits = <GeocodeHit>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final geometry = e['geometry'];
      final properties = e['properties'];
      if (geometry is! Map || properties is! Map) continue;
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) continue;
      final lng = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final name = (properties['name'] as String?)?.trim() ?? '';
      final parts = <String>[
        name,
        if (properties['street'] is String)
          (properties['street'] as String).trim(),
        if (properties['housenumber'] is String)
          (properties['housenumber'] as String).trim(),
        if (properties['postcode'] is String)
          (properties['postcode'] as String).trim(),
        if (properties['city'] is String)
          (properties['city'] as String).trim()
        else if (properties['town'] is String)
          (properties['town'] as String).trim()
        else if (properties['village'] is String)
          (properties['village'] as String).trim()
        else if (properties['county'] is String)
          (properties['county'] as String).trim(),
        if (properties['state'] is String)
          (properties['state'] as String).trim(),
        if (properties['country'] is String)
          (properties['country'] as String).trim(),
      ].where((p) => p.isNotEmpty).toList();
      final label = <String>{...parts}.join(', ');
      if (label.isEmpty) continue;
      hits.add(
        GeocodeHit(
          label: label,
          lat: lat,
          lng: lng,
          kind: properties['type'] as String?,
          name: name.isEmpty ? null : name,
        ),
      );
    }
    return hits;
  }

  /// Photon reverse — name for a map pin. Null when unknown.
  Future<GeocodeHit?> reverse(double lat, double lng) async {
    if (!lat.isFinite || !lng.isFinite) return null;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/geocode').replace(
        queryParameters: {
          'lat': lat.toStringAsFixed(5),
          'lon': lng.toStringAsFixed(5),
          'lang': AppLocaleBinding.chromeLanguageCode,
        },
      );
      final res = await _http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final raw = data['hits'];
          if (raw is List && raw.isNotEmpty && raw.first is Map) {
            final e = raw.first as Map;
            final label = (e['label'] as String?)?.trim() ?? '';
            final hitLat = (e['lat'] as num?)?.toDouble() ?? lat;
            final hitLng = (e['lng'] as num?)?.toDouble() ?? lng;
            if (label.isNotEmpty) {
              return GeocodeHit(
                label: label,
                lat: hitLat,
                lng: hitLng,
                kind: e['kind'] as String?,
                name: (e['name'] as String?)?.trim(),
              );
            }
          }
        }
      }
    } catch (_) {}
    try {
      final lang = AppLocaleBinding.chromeLanguageCode;
      final uri = Uri.https('photon.komoot.io', '/reverse', {
        'lat': lat.toStringAsFixed(5),
        'lon': lng.toStringAsFixed(5),
        'lang': lang == 'nl' ? 'en' : lang,
      });
      final res = await _http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': _photonUa,
        },
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is! Map) return null;
      final features = data['features'];
      if (features is! List || features.isEmpty) return null;
      final parsed = _photonHitsFromFeatures(features);
      return parsed.isEmpty ? null : parsed.first;
    } catch (_) {
      return null;
    }
  }

  List<GeocodeHit> _photonHitsFromFeatures(List<dynamic> raw) {
    final hits = <GeocodeHit>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final geometry = e['geometry'];
      final properties = e['properties'];
      if (geometry is! Map || properties is! Map) continue;
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) continue;
      final lng = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final name = (properties['name'] as String?)?.trim() ?? '';
      final parts = <String>[
        name,
        if (properties['street'] is String)
          (properties['street'] as String).trim(),
        if (properties['housenumber'] is String)
          (properties['housenumber'] as String).trim(),
        if (properties['city'] is String)
          (properties['city'] as String).trim()
        else if (properties['town'] is String)
          (properties['town'] as String).trim()
        else if (properties['village'] is String)
          (properties['village'] as String).trim(),
        if (properties['country'] is String)
          (properties['country'] as String).trim(),
      ].where((p) => p.isNotEmpty).toList();
      final label = <String>{...parts}.join(', ');
      if (label.isEmpty) continue;
      hits.add(
        GeocodeHit(
          label: label,
          lat: lat,
          lng: lng,
          kind: properties['type'] as String?,
          name: name.isEmpty ? null : name,
        ),
      );
    }
    return hits;
  }
}
