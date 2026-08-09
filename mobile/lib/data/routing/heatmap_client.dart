import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/privacy/track_trim.dart';
import '../../domain/routing/heatmap.dart';

Future<String?> _bearer() async =>
    Supabase.instance.client.auth.currentSession?.accessToken;

/// Contribute trimmed ride points as privacy cells (requires login + consent).
Future<int> contributeHeatmapTrack({
  required List<Map<String, dynamic>> track,
  required List<PrivacyZone> privacyZones,
}) async {
  final token = await _bearer();
  if (token == null) return 0;
  final trimmed = trimTrackForPrivacyZones(track, privacyZones);
  if (trimmed.length < 4) return 0;
  final points = <Map<String, double>>[];
  for (final p in trimmed) {
    final lat = (p['lat'] as num?)?.toDouble();
    final lng =
        (p['lng'] as num?)?.toDouble() ?? (p['lon'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    points.add({'lat': lat, 'lng': lng});
  }
  if (points.length < 4) return 0;

  final res = await http
      .post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/heatmap/contribute'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'consent': true, 'track': points}),
      )
      .timeout(const Duration(seconds: 20));
  if (res.statusCode < 200 || res.statusCode >= 300) return 0;
  final m = jsonDecode(res.body);
  if (m is Map && m['upserted'] is num) {
    return (m['upserted'] as num).toInt();
  }
  return 0;
}

/// Fetch community segments (already k-filtered server-side).
Future<HeatmapResult?> fetchCommunityHeatmap({
  required double west,
  required double south,
  required double east,
  required double north,
}) async {
  final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/heatmap').replace(
    queryParameters: {
      'west': '$west',
      'south': '$south',
      'east': '$east',
      'north': '$north',
    },
  );
  try {
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final m = jsonDecode(res.body);
    if (m is! Map) return null;
    final segs = <HeatSegment>[];
    final raw = m['segments'];
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        final coords = <List<double>>[];
        final c = e['coordinates'];
        if (c is List) {
          for (final p in c) {
            if (p is List && p.length >= 2) {
              coords.add([
                (p[0] as num).toDouble(),
                (p[1] as num).toDouble(),
              ]);
            }
          }
        }
        if (coords.length < 2) continue;
        final users = (e['uniqueUsers'] as num?)?.toInt() ?? kHeatmapThreshold;
        segs.add(
          HeatSegment(
            id: (e['id'] ?? 'c').toString(),
            coordinatesLngLat: coords,
            uniqueUsers: users,
            intensity: (e['intensity'] as num?)?.toDouble() ?? 0.5,
            visible: true,
          ),
        );
      }
    }
    return HeatmapResult(
      segments: segs,
      coldStart: m['coldStart'] == true || segs.isEmpty,
      kThreshold: (m['kThreshold'] as num?)?.toInt() ?? kHeatmapThreshold,
      attribution: (m['attribution'] as String?) ??
          '© OpenStreetMap · AetherRide k≥5',
      disclaimer: (m['disclaimer'] as String?) ??
          'Community-Heatmap (k≥$kHeatmapThreshold).',
    );
  } catch (_) {
    return null;
  }
}
