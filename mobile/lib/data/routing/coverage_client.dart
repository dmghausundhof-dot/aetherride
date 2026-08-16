import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../l10n/app_locale.dart';

class CoveragePlace {
  const CoveragePlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.center,
    required this.mapsUrl,
  });

  final String id;
  final String name;
  final String kind;
  final LatLng center;
  final String mapsUrl;
}

class CoverageSnapshot {
  const CoverageSnapshot({
    required this.inDach,
    required this.honesty,
    required this.honestyLabel,
    required this.places,
    required this.googleConfigured,
    this.googleWarning,
    this.overlayRegionId,
    this.overlayMode,
  });

  final bool inDach;
  final String honesty;
  final String honestyLabel;
  final List<CoveragePlace> places;
  final bool googleConfigured;
  final String? googleWarning;
  final String? overlayRegionId;
  final String? overlayMode;
}

/// GPS-first `/api/coverage` — Seeds bleiben lokal gebündelt; hier Live-POIs.
class CoverageClient {
  CoverageClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<CoverageSnapshot?> fetch({
    required double lat,
    required double lng,
    String bike = 'road',
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/coverage').replace(
        queryParameters: {
          'lat': lat.toStringAsFixed(5),
          'lng': lng.toStringAsFixed(5),
          'bike': bike,
          'lang': AppLocaleBinding.chromeLanguageCode,
        },
      );
      final res = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 14));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final data = jsonDecode(res.body);
      if (data is! Map) return null;
      final places = <CoveragePlace>[];
      final raw = data['places'];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final id = (e['id'] as String?) ?? '';
          final name = (e['name'] as String?) ?? '';
          final latP = (e['lat'] as num?)?.toDouble();
          final lngP = (e['lng'] as num?)?.toDouble();
          if (id.isEmpty || name.isEmpty || latP == null || lngP == null) {
            continue;
          }
          places.add(
            CoveragePlace(
              id: id,
              name: name,
              kind: (e['kind'] as String?) ?? 'other',
              center: LatLng(latP, lngP),
              mapsUrl: (e['mapsUrl'] as String?) ?? '',
            ),
          );
        }
      }
      final overlay = data['overlay'];
      final google = data['google'];
      return CoverageSnapshot(
        inDach: data['inDach'] == true,
        honesty: (data['honesty'] as String?) ?? '',
        honestyLabel: (data['honestyLabel'] as String?) ?? '',
        places: places,
        googleConfigured: google is Map && google['configured'] == true,
        googleWarning: google is Map ? google['warning'] as String? : null,
        overlayRegionId: overlay is Map ? overlay['regionId'] as String? : null,
        overlayMode: overlay is Map ? overlay['mode'] as String? : null,
      );
    } catch (_) {
      return null;
    }
  }
}
