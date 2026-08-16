import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/community/map_place.dart';
import '../../domain/community/map_place_merge.dart';

class CommunityPlacesSnapshot {
  const CommunityPlacesSnapshot({
    required this.places,
    required this.stub,
    required this.honesty,
  });

  final List<MapPlace> places;
  final bool stub;
  final String honesty;
}

/// GET `/api/community/places` — Coverage bleibt separat.
class CommunityPlacesClient {
  CommunityPlacesClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<CommunityPlacesSnapshot> fetch({
    required double lat,
    required double lng,
    String? tourId,
  }) async {
    try {
      final q = <String, String>{
        'lat': lat.toStringAsFixed(5),
        'lng': lng.toStringAsFixed(5),
        if (tourId != null && tourId.trim().isNotEmpty) 'tourId': tourId.trim(),
      };
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/community/places')
          .replace(queryParameters: q);
      final res = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return const CommunityPlacesSnapshot(
          places: [],
          stub: true,
          honesty: 'Orte-Cloud gerade nicht erreichbar.',
        );
      }
      final data = jsonDecode(res.body);
      if (data is! Map) {
        return const CommunityPlacesSnapshot(
          places: [],
          stub: true,
          honesty: 'Orte-Cloud lieferte kein Objekt.',
        );
      }
      final places = <MapPlace>[];
      final raw = data['places'];
      if (raw is List) {
        for (final e in raw) {
          final p = mapPlaceFromApi(e);
          if (p != null) places.add(p);
        }
      }
      return CommunityPlacesSnapshot(
        places: places,
        stub: data['stub'] == true,
        honesty: '${data['honesty'] ?? ''}'.trim(),
      );
    } catch (_) {
      return const CommunityPlacesSnapshot(
        places: [],
        stub: true,
        honesty: 'Orte-Cloud gerade nicht erreichbar.',
      );
    }
  }
}
