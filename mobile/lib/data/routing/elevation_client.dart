import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'routing_client.dart';

class ElevationProfile {
  const ElevationProfile({
    required this.gainM,
    required this.lossM,
    this.points = const [],
    this.source,
  });

  final double gainM;
  final double lossM;
  final List<Map<String, dynamic>> points;
  final String? source;
}

/// Calls `${AppConfig.apiBaseUrl}/api/elevation`.
class ElevationClient {
  ElevationClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<ElevationProfile?> fetchForTrack(List<GeoPoint> track) async {
    if (track.length < 2) return null;
    try {
      final res = await _http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/elevation'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'track': [
                for (final p in track) {'lat': p.lat, 'lng': p.lng},
              ],
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['error'] != null) return null;
      return ElevationProfile(
        gainM: (data['totalClimbM'] as num?)?.toDouble() ??
            (data['gainM'] as num?)?.toDouble() ??
            (data['elevationGainM'] as num?)?.toDouble() ??
            0,
        lossM: (data['lossM'] as num?)?.toDouble() ??
            (data['elevationLossM'] as num?)?.toDouble() ??
            0,
        points: (data['points'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
        source: data['source'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<({double? startM, double? endM})> fetchEndpointElevations(
    GeoPoint start,
    GeoPoint end,
  ) async {
    final p = await fetchForTrack([start, end]);
    if (p == null || p.points.length < 2) {
      return (startM: null, endM: null);
    }
    double? elev(Map<String, dynamic> m) {
      final a = m['elevM'] ?? m['elev'] ?? m['elevation'];
      return a is num ? a.toDouble() : null;
    }

    return (startM: elev(p.points.first), endM: elev(p.points.last));
  }
}
