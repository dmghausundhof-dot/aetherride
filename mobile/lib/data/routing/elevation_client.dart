import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'routing_client.dart';

/// Roh-Tokens der Elevation-API gehören nicht in die Nutzerzeile.
bool elevationSourceIsUserFacing(String? source) {
  final s = source?.trim() ?? '';
  if (s.isEmpty) return false;
  const hidden = {
    'api',
    'graphhopper',
    'valhalla',
    'osrm',
    'offline',
    'http',
    'engine',
    'fallback-line',
  };
  return !hidden.contains(s.toLowerCase());
}

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

List<double> elevationSamplesOf(ElevationProfile profile) {
  final out = <double>[];
  for (final m in profile.points) {
    final raw = m['elevM'] ?? m['elev'] ?? m['elevation'] ?? m['ele'] ?? m['z'];
    if (raw is num) out.add(raw.toDouble());
  }
  return out;
}

/// Along-track km aligned with [elevationSamplesOf]. Empty if any sample
/// is missing distKm (chart then uses uniform spacing).
List<double> elevationDistKmOf(ElevationProfile profile) {
  final out = <double>[];
  for (final m in profile.points) {
    final raw = m['elevM'] ?? m['elev'] ?? m['elevation'] ?? m['ele'] ?? m['z'];
    if (raw is! num) continue;
    final dist = m['distKm'] ?? m['dist_km'];
    if (dist is! num) return const [];
    out.add(dist.toDouble());
  }
  return out;
}

List<({double fromKm, double toKm, String? surface})> elevationSurfaceBandsOf(
  List<Map<String, dynamic>> points,
) {
  if (points.length < 2) return const [];
  final bands = <({double fromKm, double toKm, String? surface})>[];
  String? cur;
  double? start;
  var lastKm = 0.0;
  for (final m in points) {
    final dist = m['distKm'] ?? m['dist_km'];
    if (dist is! num) continue;
    final km = dist.toDouble();
    lastKm = km;
    final raw = m['surface'];
    final s = raw is String && raw.trim().isNotEmpty
        ? raw.trim().toLowerCase()
        : null;
    if (start == null) {
      start = km;
      cur = s;
      continue;
    }
    if (s != cur) {
      bands.add((fromKm: start, toKm: km, surface: cur));
      start = km;
      cur = s;
    }
  }
  if (start != null) {
    bands.add((fromKm: start, toKm: lastKm, surface: cur));
  }
  return bands;
}

class SurfaceShare {
  const SurfaceShare({required this.key, required this.share});
  final String key;
  final double share;
}

/// Mix from elevation points — unknown/null surfaces dropped.
List<SurfaceShare> surfaceSharesFromElevPoints(List<Map<String, dynamic>> points) {
  if (points.length < 2) return const [];
  final kmBy = <String, double>{};
  var known = 0.0;
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1]['distKm'] ?? points[i - 1]['dist_km'];
    final cur = points[i]['distKm'] ?? points[i]['dist_km'];
    if (prev is! num || cur is! num) continue;
    final km = (cur - prev).toDouble();
    if (km <= 0) continue;
    final raw = points[i]['surface'] ?? points[i - 1]['surface'];
    final key = raw is String ? raw.trim().toLowerCase() : '';
    if (key.isEmpty) continue;
    kmBy[key] = (kmBy[key] ?? 0) + km;
    known += km;
  }
  if (known <= 0) return const [];
  final out = [
    for (final e in kmBy.entries)
      SurfaceShare(key: e.key, share: e.value / known),
  ]..sort((a, b) => b.share.compareTo(a.share));
  return out;
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
