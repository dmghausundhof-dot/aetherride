import 'dart:convert';

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

const _stationKinds = {'station', 'railway', 'halt'};

List<String> _normalizePlaceTokens(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('hauptbahnhof', 'bahnhof')
      .replaceAll(RegExp(r'\bhbf\b'), 'bahnhof')
      .replaceAll(RegExp(r'\bstation\b'), 'bahnhof')
      .replaceAll(RegExp(r'\bgare\b'), 'bahnhof')
      .replaceAll(RegExp(r'\bstazione\b'), 'bahnhof')
      .split(RegExp(r'[^a-z0-9äöüß]+', caseSensitive: false))
      .where((t) => t.length >= 2)
      .toList();
}

bool queryLooksLikeStation(String query) =>
    _normalizePlaceTokens(query).contains('bahnhof');

bool geocodeTokensCovered(String query, String hay) {
  final tokens = _normalizePlaceTokens(query);
  if (tokens.isEmpty) return false;
  final have = _normalizePlaceTokens(hay).toSet();
  return tokens.every(have.contains);
}

int geocodeHitScore(String query, GeocodeHit hit) {
  final q = query.trim().toLowerCase();
  final name = hit.matchName.toLowerCase();
  final hay = '$name ${hit.label}';
  var s = 0;
  if (name == q) {
    s += 100;
  } else if (geocodeNameMatchesQuery(name, q)) {
    s += 45;
  }
  if (geocodeTokensCovered(query, hay)) s += 80;
  final kind = hit.kind ?? '';
  final stationQ = queryLooksLikeStation(query);
  if (kind == 'city' || kind == 'locality') s += stationQ ? 10 : 25;
  if (_stationKinds.contains(kind)) s += stationQ ? 40 : 5;
  if (kind == 'street' || kind == 'house') s -= 15;
  return s;
}

List<GeocodeHit> rankGeocodeHits(String query, List<GeocodeHit> hits) {
  final copy = [...hits];
  copy.sort(
    (a, b) => geocodeHitScore(query, b).compareTo(geocodeHitScore(query, a)),
  );
  return copy;
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
    final hits = [
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
    return preferPlaces ? rankGeocodeHits(q, hits).take(limit).toList() : hits;
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
}
