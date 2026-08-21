import 'dart:math' as math;

import 'consents.dart';

/// Port of web `trimTrackForHeatmap` — drop end caps + privacy-zone points.
/// Extra fields (elev, time, sensors) stay on the kept maps.
List<Map<String, dynamic>> trimTrackForPrivacyZones(
  List<Map<String, dynamic>> track,
  List<PrivacyZone> privacyZones, {
  double trimEndsM = 200,
}) {
  if (track.length < 3) return const [];

  double latOf(Map<String, dynamic> p) =>
      (p['lat'] as num?)?.toDouble() ?? 0;
  double lngOf(Map<String, dynamic> p) =>
      (p['lng'] as num?)?.toDouble() ?? (p['lon'] as num?)?.toDouble() ?? 0;

  var start = 0;
  var end = track.length - 1;
  // trimEndsM <= 0: only zone filter — do not nibble the first/last vertex.
  if (trimEndsM > 0) {
    var acc = 0.0;
    for (var i = 1; i < track.length; i++) {
      acc += _distM(
        lngOf(track[i - 1]),
        latOf(track[i - 1]),
        lngOf(track[i]),
        latOf(track[i]),
      );
      if (acc >= trimEndsM) {
        start = i;
        break;
      }
    }
    acc = 0;
    for (var i = track.length - 1; i > 0; i--) {
      acc += _distM(
        lngOf(track[i]),
        latOf(track[i]),
        lngOf(track[i - 1]),
        latOf(track[i - 1]),
      );
      if (acc >= trimEndsM) {
        end = i;
        break;
      }
    }
  }

  final sliced = track.sublist(start, end + 1);
  if (privacyZones.isEmpty) return sliced;

  return [
    for (final p in sliced)
      if (!pointInPrivacyZones(latOf(p), lngOf(p), privacyZones)) p,
  ];
}

/// True when [lat]/[lng] sits inside any zone radius (same rule as Presence).
bool pointInPrivacyZones(double lat, double lng, List<PrivacyZone> zones) {
  return _inAnyZone(lat, lng, zones);
}

bool _inAnyZone(double lat, double lng, List<PrivacyZone> zones) {
  for (final z in zones) {
    if (_distM(lng, lat, z.lng, z.lat) < z.radiusM) return true;
  }
  return false;
}

double _distM(double lng1, double lat1, double lng2, double lat2) {
  const r = 6371000.0;
  final la1 = lat1 * math.pi / 180;
  final la2 = lat2 * math.pi / 180;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(h));
}
