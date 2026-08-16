import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/privacy/track_trim.dart';
import '../../domain/routing/heatmap.dart';

Future<String?> _bearer() async =>
    Supabase.instance.client.auth.currentSession?.accessToken;

class HeatmapContributeResult {
  const HeatmapContributeResult({
    required this.upserted,
    required this.message,
    this.ok = false,
  });

  final int upserted;
  final String message;
  final bool ok;
}

/// Contribute trimmed ride points as privacy cells (requires login + consent).
Future<HeatmapContributeResult> contributeHeatmapTrack({
  required List<Map<String, dynamic>> track,
  required List<PrivacyZone> privacyZones,
}) async {
  final token = await _bearer();
  if (token == null) {
    return const HeatmapContributeResult(
      upserted: 0,
      message: 'Heatmap: eingeloggt nötig für den Beitrag',
    );
  }
  final trimmed = trimTrackForPrivacyZones(track, privacyZones);
  if (trimmed.length < 4) {
    return const HeatmapContributeResult(
      upserted: 0,
      message: 'Heatmap: zu wenig Track-Punkte nach Privacy-Trim',
    );
  }
  final points = <Map<String, double>>[];
  for (final p in trimmed) {
    final lat = (p['lat'] as num?)?.toDouble();
    final lng =
        (p['lng'] as num?)?.toDouble() ?? (p['lon'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (lat.abs() < 1e-6 && lng.abs() < 1e-6) continue;
    points.add({'lat': lat, 'lng': lng});
  }
  if (points.length < 4) {
    return const HeatmapContributeResult(
      upserted: 0,
      message: 'Heatmap: keine gültigen GPS-Punkte',
    );
  }

  try {
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
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String detail = 'HTTP ${res.statusCode}';
      try {
        final m = jsonDecode(res.body);
        if (m is Map && m['message'] != null) detail = m['message'].toString();
        if (m is Map && m['error'] != null) detail = m['error'].toString();
      } catch (_) {}
      return HeatmapContributeResult(
        upserted: 0,
        message: 'Heatmap-Beitrag fehlgeschlagen ($detail)',
      );
    }
    final m = jsonDecode(res.body);
    final n = (m is Map && m['upserted'] is num)
        ? (m['upserted'] as num).toInt()
        : 0;
    if (n <= 0) {
      return const HeatmapContributeResult(
        upserted: 0,
        message: 'Heatmap: keine neuen Zellen (bereits beigetragen?)',
      );
    }
    return HeatmapContributeResult(
      upserted: n,
      ok: true,
      message: 'Heatmap: $n Zellen beigetragen (sichtbar ab k≥$kHeatmapThreshold)',
    );
  } catch (e) {
    return HeatmapContributeResult(
      upserted: 0,
      message: 'Heatmap offline ($e)',
    );
  }
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
          '© OpenStreetMap · FlowLine k≥5',
      disclaimer: (m['disclaimer'] as String?) ??
          'Heatmap (k≥$kHeatmapThreshold), anonym, ohne Zeitstempel.',
    );
  } catch (_) {
    return null;
  }
}
