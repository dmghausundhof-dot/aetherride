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
  });

  final String label;
  final double lat;
  final double lng;
  final String? kind;
}

/// Adresssuche über Next `/api/geocode` (Photon).
class GeocodeClient {
  GeocodeClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<List<GeocodeHit>> search(
    String query, {
    int limit = 5,
    double? biasLat,
    double? biasLng,
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
    final params = <String, String>{
      'q': q,
      'limit': '$limit',
      'lang': AppLocaleBinding.chromeLanguageCode,
    };
    if (biasLat != null && biasLng != null) {
      params['lat'] = biasLat.toStringAsFixed(5);
      params['lon'] = biasLng.toStringAsFixed(5);
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/geocode').replace(
      queryParameters: params,
    );
    final res = await _http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw StateError('Geocode ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is! Map) return const [];
    final raw = data['hits'];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map)
          GeocodeHit(
            label: (e['label'] as String?)?.trim() ?? '',
            lat: (e['lat'] as num?)?.toDouble() ?? 0,
            lng: (e['lng'] as num?)?.toDouble() ?? 0,
            kind: e['kind'] as String?,
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
  }
}
