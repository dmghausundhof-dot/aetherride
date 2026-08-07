import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

/// F-NAV-006 Trail View — Antwort von `GET /api/trail`.
class TrailPhoto {
  const TrailPhoto({
    required this.id,
    required this.source,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.headingDeg,
    required this.username,
    required this.title,
    required this.license,
    required this.attributionHtml,
    this.demo = false,
  });

  final String id;
  final String source;
  final String imageUrl;
  final double lat;
  final double lng;
  final double headingDeg;
  final String username;
  final String title;
  final String license;
  final String attributionHtml;
  final bool demo;

  factory TrailPhoto.fromJson(Map<String, dynamic> m) {
    return TrailPhoto(
      id: (m['id'] as String?) ?? 'photo',
      source: (m['source'] as String?) ?? 'mapillary',
      imageUrl: (m['imageUrl'] as String?) ?? '',
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
      headingDeg: (m['headingDeg'] as num?)?.toDouble() ?? 0,
      username: (m['username'] as String?) ?? 'mapillary',
      title: (m['title'] as String?) ?? 'Trail',
      license: (m['license'] as String?) ?? 'CC BY-SA 4.0',
      attributionHtml: (m['attributionHtml'] as String?) ?? '',
      demo: m['demo'] == true,
    );
  }

  bool get isNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
}

class TrailViewResult {
  const TrailViewResult({
    required this.photos,
    required this.attribution,
    required this.disclaimer,
    required this.usingDemo,
  });

  final List<TrailPhoto> photos;
  final String attribution;
  final String disclaimer;
  final bool usingDemo;

  factory TrailViewResult.fromJson(Map<String, dynamic> m) {
    return TrailViewResult(
      photos: [
        for (final raw in (m['photos'] as List? ?? const []))
          if (raw is Map)
            TrailPhoto.fromJson(Map<String, dynamic>.from(raw)),
      ],
      attribution: (m['attribution'] as String?) ?? '',
      disclaimer: (m['disclaimer'] as String?) ?? '',
      usingDemo: m['usingDemo'] == true,
    );
  }
}

Future<TrailViewResult> fetchTrailViewNear({
  required double lat,
  required double lng,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  try {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/trail').replace(
      queryParameters: {
        'lat': lat.toStringAsFixed(5),
        'lng': lng.toStringAsFixed(5),
      },
    );
    final res = await httpClient
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      return TrailViewResult(
        photos: const [],
        attribution: 'Mapillary CC BY-SA 4.0',
        disclaimer: 'Trail View offline (${res.statusCode}).',
        usingDemo: true,
      );
    }
    final data = jsonDecode(res.body);
    if (data is! Map) {
      return const TrailViewResult(
        photos: [],
        attribution: '',
        disclaimer: 'Ungültige Trail-Antwort.',
        usingDemo: true,
      );
    }
    return TrailViewResult.fromJson(Map<String, dynamic>.from(data));
  } finally {
    if (client == null) httpClient.close();
  }
}
