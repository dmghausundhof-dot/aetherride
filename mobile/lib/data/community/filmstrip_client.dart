import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/community/filmstrip.dart';
import '../../domain/routing/plan_line_points.dart';
import '../routing/routing_client.dart';

class FilmstripClient {
  FilmstripClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<List<FilmstripShot>> fetchAlong(List<GeoPoint> track) async {
    if (track.length < 2) return const [];
    final samples = sampleAlongLine(
      [for (final p in track) [p.lng, p.lat]],
      4,
    );
    final along = samples.map((c) => '${c[0]},${c[1]}').join('|');
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/trail?honest=1&along=${Uri.encodeQueryComponent(along)}',
      );
      final res = await _http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body);
      if (data is! Map) return const [];
      if (data['usingDemo'] == true) return const [];
      final raw = data['photos'];
      if (raw is! List) return const [];
      final shots = <FilmstripShot>[];
      for (final e in raw) {
        if (e is! Map) continue;
        if (e['demo'] == true) continue;
        final url = '${e['imageUrl'] ?? e['url'] ?? ''}'.trim();
        final lat = (e['lat'] as num?)?.toDouble();
        final lng = (e['lng'] as num?)?.toDouble();
        if (url.isEmpty || lat == null || lng == null) continue;
        if (!url.startsWith('http')) continue;
        shots.add(
          FilmstripShot(
            id: '${e['id'] ?? url}',
            imageUrl: url,
            lat: lat,
            lng: lng,
            source: '${e['source'] ?? 'mapillary'}',
            attribution: e['attributionHtml'] as String? ??
                e['attribution'] as String?,
          ),
        );
      }
      return filmstripAlongLine(
        shots: shots,
        line: [for (final p in track) [p.lng, p.lat]],
      );
    } catch (_) {
      return const [];
    }
  }
}
