import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

class NearbyListingsHit {
  const NearbyListingsHit({
    required this.nearbyWaiting,
    this.stub = true,
  });

  final int nearbyWaiting;
  final bool stub;
}

class NearbyListingsClient {
  NearbyListingsClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<NearbyListingsHit> fetchViewport({
    required double west,
    required double south,
    required double east,
    required double north,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/community/listings')
        .replace(queryParameters: {
      'west': '$west',
      'south': '$south',
      'east': '$east',
      'north': '$north',
    });
    try {
      final res = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        return const NearbyListingsHit(nearbyWaiting: 0);
      }
      final data = jsonDecode(res.body);
      if (data is! Map) return const NearbyListingsHit(nearbyWaiting: 0);
      final n = data['nearbyWaiting'];
      final waiting = n is num ? n.round().clamp(0, 24) : 0;
      return NearbyListingsHit(
        nearbyWaiting: waiting,
        stub: data['stub'] == true,
      );
    } catch (_) {
      return const NearbyListingsHit(nearbyWaiting: 0);
    }
  }
}
