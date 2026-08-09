import 'dart:math' as math;

/// Simplified bearing-based nav cues (web `buildNavCues` / `nextCue`).

class NavCue {
  const NavCue({
    required this.id,
    required this.distanceAlongM,
    required this.instruction,
    this.bearingDeg = 0,
  });

  final String id;
  final double distanceAlongM;
  final String instruction;
  final double bearingDeg;
}

double _haversineM(List<double> a, List<double> b) {
  const r = 6371000.0;
  final lat1 = a[1] * math.pi / 180;
  final lat2 = b[1] * math.pi / 180;
  final dLat = (b[1] - a[1]) * math.pi / 180;
  final dLng = (b[0] - a[0]) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}

double _bearingDeg(List<double> a, List<double> b) {
  final lat1 = a[1] * math.pi / 180;
  final lat2 = b[1] * math.pi / 180;
  final dLng = (b[0] - a[0]) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

String? _turnInstruction(double delta) {
  final d = ((delta + 540) % 360) - 180;
  final abs = d.abs();
  if (abs < 18) return null;
  if (abs < 40) return d > 0 ? 'Leicht rechts' : 'Leicht links';
  if (abs < 110) return d > 0 ? 'Rechts abbiegen' : 'Links abbiegen';
  return d > 0 ? 'Scharf rechts' : 'Scharf links';
}

/// [geometry] as [lng, lat] pairs (GeoJSON order).
List<NavCue> buildNavCues(List<List<double>> geometry) {
  if (geometry.length < 4) return [];

  final cues = <NavCue>[];
  var along = 0.0;
  var windowStart = 0;
  var windowAlong = 0.0;
  double? prevSampleBearing;

  for (var i = 1; i < geometry.length; i++) {
    final a = geometry[i - 1];
    final b = geometry[i];
    if (a.length < 2 || b.length < 2) continue;
    final seg = _haversineM(a, b);
    along += seg;
    windowAlong += seg;

    if (windowAlong < 120 && i < geometry.length - 1) continue;

    final start = geometry[windowStart];
    final br = _bearingDeg(start, b);
    if (prevSampleBearing != null) {
      final instruction = _turnInstruction(br - prevSampleBearing);
      if (instruction != null) {
        final last = cues.isEmpty ? null : cues.last;
        if (last == null || along - last.distanceAlongM > 150) {
          cues.add(
            NavCue(
              id: 'cue-${cues.length}',
              distanceAlongM: along.roundToDouble(),
              instruction: instruction,
              bearingDeg: br.roundToDouble(),
            ),
          );
        }
      }
    }
    prevSampleBearing = br;
    windowStart = i;
    windowAlong = 0;
  }

  cues.add(
    NavCue(
      id: 'cue-finish',
      distanceAlongM: along.roundToDouble(),
      instruction: 'Ziel erreicht',
      bearingDeg: prevSampleBearing ?? 0,
    ),
  );
  return cues;
}

({NavCue cue, int remainingM})? nextCue(
  List<NavCue> cues,
  double distanceAlongM,
) {
  for (final cue in cues) {
    final remaining = cue.distanceAlongM - distanceAlongM;
    if (remaining > 12) {
      return (cue: cue, remainingM: remaining.round());
    }
  }
  return null;
}

String cueBannerText(NavCue cue, int remainingM) {
  if (cue.instruction == 'Ziel erreicht') return 'Ziel erreicht';
  if (remainingM >= 1000) {
    return 'In ${(remainingM / 1000).toStringAsFixed(1)} km ${cue.instruction.toLowerCase()}';
  }
  return 'In $remainingM m ${cue.instruction.toLowerCase()}';
}

/// Bearing-Heuristik → RouteSteps (Offline / Online ohne Manöver-Liste).
/// [coordinates] als GeoPoint (lat/lng); intern [lng,lat] für [buildNavCues].
List<({String id, String instruction, double distanceAlongM})>
    navStepsFromPolyline(List<({double lat, double lng})> coordinates) {
  if (coordinates.length < 2) return const [];
  final geom = [
    for (final p in coordinates) [p.lng, p.lat],
  ];
  final cues = buildNavCues(geom);
  if (cues.isEmpty && coordinates.length >= 2) {
    return [
      (
        id: 'start',
        instruction: 'Losfahren',
        distanceAlongM: 0,
      ),
      (
        id: 'finish',
        instruction: 'Ziel erreicht',
        distanceAlongM: 0,
      ),
    ];
  }
  final out = <({String id, String instruction, double distanceAlongM})>[
    (id: 'start', instruction: 'Losfahren', distanceAlongM: 0),
  ];
  for (final c in cues) {
    out.add(
      (
        id: c.id,
        instruction: c.instruction,
        distanceAlongM: c.distanceAlongM,
      ),
    );
  }
  return out;
}

