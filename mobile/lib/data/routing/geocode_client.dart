import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

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
    final params = <String, String>{
      'q': q,
      'limit': '$limit',
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
