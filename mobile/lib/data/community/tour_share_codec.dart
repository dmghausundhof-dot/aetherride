import 'dart:convert';

import '../../core/config.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/tour_akte.dart';

const _maxTrackPoints = 80;
const _maxTokenChars = 1800;

List<List<double>> downsampleTrack(List<List<double>> coords, [int max = _maxTrackPoints]) {
  if (coords.length <= max) return coords;
  final step = (coords.length - 1) / (max - 1);
  final out = <List<double>>[];
  for (var i = 0; i < max; i++) {
    final p = coords[(i * step).round()];
    if (p.length >= 2) {
      out.add([p[0], p[1]]);
    }
  }
  return out;
}

String _toBase64Url(String json) {
  return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
}

String? _fromBase64Url(String token) {
  try {
    var b64 = token.replaceAll('-', '+').replaceAll('_', '/');
    final pad = b64.length % 4 == 0 ? 0 : 4 - (b64.length % 4);
    b64 = b64.padRight(b64.length + pad, '=');
    return utf8.decode(base64.decode(b64));
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> buildTourSharePayload(
  SavedRouteEntry route, {
  SavedRouteMeta meta = SavedRouteMeta.empty,
  String authorLabel = 'FlowLine-Fahrer:in',
}) {
  final raw = route.coordinates.length >= 2
      ? route.coordinates
      : (route.tour.length >= 2 ? route.tour : const <List<double>>[]);
  final usable = [
    for (final p in raw)
      if (p.length >= 2) [p[0], p[1]],
  ];
  final includeTrack = usable.length >= 2;
  final catalog = catalogTourIdOf(route.id, meta);
  return {
    'v': 1,
    'kind': 'tour',
    'id': route.id,
    'name': route.name,
    'distanceKm': route.distanceKm,
    'elevationM': route.elevationM,
    'durationMin': route.durationMin,
    'source': route.source,
    if (catalog != null) 'catalogTourId': catalog,
    'includeTrack': includeTrack,
    if (includeTrack) 'track': downsampleTrack(usable),
    'authorLabel': authorLabel,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    if (meta.shareEpoch > 0) 'epoch': meta.shareEpoch,
  };
}

({String token, bool includeTrack, bool droppedTrack}) encodeTourShareToken(
  SavedRouteEntry route, {
  SavedRouteMeta meta = SavedRouteMeta.empty,
  String authorLabel = 'FlowLine-Fahrer:in',
}) {
  final full = buildTourSharePayload(
    route,
    meta: meta,
    authorLabel: authorLabel,
  );
  var token = _toBase64Url(jsonEncode(full));
  if (token.length <= _maxTokenChars) {
    return (
      token: token,
      includeTrack: full['includeTrack'] == true,
      droppedTrack: false,
    );
  }
  final slim = Map<String, dynamic>.from(full)
    ..['includeTrack'] = false
    ..remove('track');
  token = _toBase64Url(jsonEncode(slim));
  return (
    token: token,
    includeTrack: false,
    droppedTrack: full['includeTrack'] == true,
  );
}

Map<String, dynamic>? parseTourShareMap(Object? raw) {
  if (raw is! Map) return null;
  final data = Map<String, dynamic>.from(raw);
  if (data['v'] != 1 || data['kind'] != 'tour') return null;
  if (data['id'] == null || data['name'] == null) return null;
  return data;
}

Map<String, dynamic>? decodeTourSharePayload(String token) {
  final raw = _fromBase64Url(token);
  if (raw == null) return null;
  try {
    return parseTourShareMap(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}

List<List<double>> _trackFromShare(Object? raw) {
  if (raw is! List) return const [];
  final out = <List<double>>[];
  for (final e in raw) {
    if (e is! List || e.length < 2) continue;
    final lng = (e[0] as num?)?.toDouble();
    final lat = (e[1] as num?)?.toDouble();
    if (lng == null || lat == null) continue;
    out.add([lng, lat]);
  }
  return out;
}

/// Mitglieds-Kopie. [keepId] bleibt die Host-Id — Losfahren matcht.
SavedRouteEntry? savedRouteFromTourShare({
  required Map<String, dynamic> tour,
  required String keepId,
}) {
  if (parseTourShareMap(tour) == null) return null;
  final track = _trackFromShare(tour['track']);
  if (track.length < 2) return null;
  final name = '${tour['name'] ?? ''}'.trim();
  final source = '${tour['source'] ?? ''}';
  return SavedRouteEntry(
    id: keepId,
    name: name.isEmpty ? keepId : name,
    distanceKm: (tour['distanceKm'] as num?)?.toDouble() ?? 0,
    elevationM: (tour['elevationM'] as num?)?.toDouble() ?? 0,
    durationMin: (tour['durationMin'] as num?)?.toInt() ?? 0,
    savedAt: DateTime.now().toUtc(),
    source: source == 'engine' ? 'engine' : 'import',
    coordinates: track,
    waypoints: [
      SavedWaypoint(role: 'start', lng: track.first[0], lat: track.first[1]),
      SavedWaypoint(role: 'end', lng: track.last[0], lat: track.last[1]),
    ],
  );
}

String shareTourPath(String token) => '/share/t/$token';

String shareTourUrl(String token) => '${AppConfig.apiBaseUrl}${shareTourPath(token)}';
