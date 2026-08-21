import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/ride.dart';
import 'export_trimmed.dart';
import 'gpx.dart';
import 'strava_stub.dart';

class StravaClientStatus {
  const StravaClientStatus({
    required this.configured,
    required this.connected,
    this.authorizeUrl,
    this.message,
    this.requiresAuth = false,
  });

  final bool configured;
  final bool connected;
  final String? authorizeUrl;
  final String? message;
  final bool requiresAuth;
}

Future<String?> _bearer() async {
  return Supabase.instance.client.auth.currentSession?.accessToken;
}

Future<StravaClientStatus> fetchStravaStatus() async {
  final token = await _bearer();
  final headers = <String, String>{'Accept': 'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';

  final statusUri = Uri.parse('${AppConfig.apiBaseUrl}/api/strava/status');
  try {
    final statusRes = await http
        .get(statusUri, headers: headers)
        .timeout(const Duration(seconds: 8));
    if (statusRes.statusCode == 200) {
      final m = jsonDecode(statusRes.body);
      if (m is Map && m['configured'] == true) {
        final connected = m['connected'] == true;
        String? authorizeUrl;
        if (!connected && token != null) {
          final start = await http
              .get(
                Uri.parse('${AppConfig.apiBaseUrl}/api/strava?mobile=1'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 8));
          if (start.statusCode == 200) {
            final s = jsonDecode(start.body);
            if (s is Map) {
              authorizeUrl = s['authorizeUrl'] as String?;
            }
          }
        }
        return StravaClientStatus(
          configured: true,
          connected: connected,
          authorizeUrl: authorizeUrl,
          message: connected
              ? 'Strava verbunden — Upload mit Track wenn GPS da'
              : (token == null
                  ? 'Einloggen, dann mit Strava verbinden'
                  : 'Konfiguriert — noch nicht verbunden'),
          requiresAuth: token == null,
        );
      }
      if (m is Map) {
        return StravaClientStatus(
          configured: false,
          connected: false,
          message: m['message'] as String? ??
              'Strava nicht konfiguriert — Stub/GPX',
        );
      }
    }
  } catch (_) {}

  // Fallback: public configured probe
  try {
    final res = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/strava'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      return const StravaClientStatus(
        configured: false,
        connected: false,
        message: 'Strava-Status nicht erreichbar',
      );
    }
    final data = jsonDecode(res.body);
    if (data is! Map) {
      return const StravaClientStatus(
        configured: false,
        connected: false,
        message: 'Ungültige Strava-Antwort',
      );
    }
    return StravaClientStatus(
      configured: data['configured'] == true,
      connected: false,
      authorizeUrl: data['authorizeUrl'] as String?,
      message: data['message'] as String? ??
          (data['configured'] == true
              ? 'Strava konfiguriert'
              : 'Strava nicht konfiguriert'),
      requiresAuth: data['requiresAuth'] == true || token == null,
    );
  } catch (e) {
    return StravaClientStatus(
      configured: false,
      connected: false,
      message: 'Strava offline ($e)',
    );
  }
}

Future<({bool ok, String message})> uploadRideToStrava(
  RideRecord ride, {
  List<PrivacyZone> zones = const [],
}) async {
  final token = await _bearer();
  if (token == null) {
    return (ok: false, message: 'Nicht eingeloggt');
  }
  final forUpload = rideWithTrimmedTrack(ride, zones);
  final stub = rideToStravaActivityStub(forUpload);
  final hasTrack = rideHasExportableTrack(forUpload);
  final gpx = hasTrack ? rideToGpx(forUpload) : null;
  if (!hasTrack && ((stub['elapsed_time'] as num?)?.toInt() ?? 0) <= 0) {
    return (
      ok: false,
      message: 'Kein GPS-Track und keine Dauer — Upload abgebrochen',
    );
  }

  final body = <String, dynamic>{
    'name': stub['name'],
    'type': stub['type'],
    'sport_type': stub['sport_type'],
    'start_date_local': stub['start_date_local'],
    'elapsed_time': stub['elapsed_time'],
    'distance': stub['distance'],
    'total_elevation_gain': stub['total_elevation_gain'],
    'description': stub['description'],
    if (gpx != null) 'gpx': gpx,
  };

  final res = await http
      .post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/strava/upload'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 60));
  if (res.statusCode >= 200 && res.statusCode < 300) {
    try {
      final m = jsonDecode(res.body);
      if (m is Map) {
        final mode = m['mode'] as String?;
        if (mode == 'gpx_upload') {
          return (ok: true, message: 'Bei Strava hochgeladen (mit Track)');
        }
        if (mode == 'metadata') {
          return (
            ok: true,
            message: m['warning'] as String? ??
                'Bei Strava hochgeladen (nur Metadaten)',
          );
        }
      }
    } catch (_) {}
    return (ok: true, message: 'Bei Strava hochgeladen');
  }
  try {
    final m = jsonDecode(res.body);
    if (m is Map) {
      return (
        ok: false,
        message: (m['message'] ?? m['error'] ?? res.body).toString(),
      );
    }
  } catch (_) {}
  return (ok: false, message: 'Upload fehlgeschlagen (${res.statusCode})');
}
