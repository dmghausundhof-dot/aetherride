import 'dart:convert';
import 'dart:math' as math;

/// Minimal GPX → Track (trkpt / rtept).
class GpxTrack {
  const GpxTrack({
    required this.name,
    required this.points,
    required this.distanceKm,
    required this.elevationM,
  });

  final String name;
  /// [lng, lat]
  final List<List<double>> points;
  final double distanceKm;
  final double elevationM;

  int get durationMinEstimate =>
      math.max(10, (distanceKm / 12 * 60).round());
}

/// Decode GPX bytes as UTF-8 (with BOM strip); fallback latin1.
String decodeGpxBytes(List<int> bytes) {
  try {
    var s = utf8.decode(bytes, allowMalformed: true);
    if (s.startsWith('\uFEFF')) s = s.substring(1);
    return s;
  } catch (_) {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

GpxTrack? parseGpx(String xml, {String fallbackName = 'GPX-Import'}) {
  final pts = <({double lat, double lng, double? elev})>[];

  void addFromAttrs(String attrs, [String body = '']) {
    final latM = RegExp(r'''lat\s*=\s*["']([^"']+)["']''', caseSensitive: false)
        .firstMatch(attrs);
    final lonM = RegExp(
      r'''(?:lon|lng)\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(attrs);
    final lat = double.tryParse(latM?.group(1) ?? '');
    final lng = double.tryParse(lonM?.group(1) ?? '');
    if (lat == null || lng == null) return;
    final elevM = RegExp(r'<ele>\s*([-0-9.]+)\s*</ele>', caseSensitive: false)
        .firstMatch(body);
    pts.add((
      lat: lat,
      lng: lng,
      elev: elevM != null ? double.tryParse(elevM.group(1)!) : null,
    ));
  }

  final re = RegExp(
    r'<(?:trkpt|rtept)\s+([^>]+?)>(.*?)</(?:trkpt|rtept)>',
    caseSensitive: false,
    dotAll: true,
  );
  for (final m in re.allMatches(xml)) {
    addFromAttrs(m.group(1) ?? '', m.group(2) ?? '');
  }
  if (pts.length < 2) {
    final re2 = RegExp(
      r'<(?:trkpt|rtept)\s+([^>]+?)/\s*>',
      caseSensitive: false,
    );
    for (final m in re2.allMatches(xml)) {
      addFromAttrs(m.group(1) ?? '');
    }
  }
  if (pts.length < 2) return null;

  var dist = 0.0;
  var elevGain = 0.0;
  for (var i = 1; i < pts.length; i++) {
    dist += _hav(pts[i - 1].lat, pts[i - 1].lng, pts[i].lat, pts[i].lng);
    final a = pts[i - 1].elev;
    final b = pts[i].elev;
    if (a != null && b != null && b - a > 0.5) elevGain += b - a;
  }

  final nameM = RegExp(r'<name>\s*([^<]+)\s*</name>', caseSensitive: false)
      .firstMatch(xml);
  final name = (nameM?.group(1)?.trim().isNotEmpty == true)
      ? nameM!.group(1)!.trim()
      : fallbackName;

  return GpxTrack(
    name: name,
    points: [
      for (final p in pts)
        if (p.elev != null && p.elev!.isFinite) [p.lng, p.lat, p.elev!]
        else [p.lng, p.lat],
    ],
    distanceKm: dist / 1000,
    elevationM: elevGain,
  );
}

double _hav(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final dLat = _r(lat2 - lat1);
  final dLng = _r(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_r(lat1)) *
          math.cos(_r(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * R * math.asin(math.min(1.0, math.sqrt(a)));
}

double _r(double d) => d * math.pi / 180;
