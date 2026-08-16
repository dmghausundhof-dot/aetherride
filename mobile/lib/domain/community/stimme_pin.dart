import '../routing/route_progress.dart';

/// Stimme-Pin nur auf der Linie. Weiter weg: kein Pin.
const kStimmePinMaxCrossTrackM = 80.0;

class SnappedStimmePin {
  const SnappedStimmePin({
    required this.lat,
    required this.lng,
    required this.alongM,
  });

  final double lat;
  final double lng;
  final double alongM;
}

SnappedStimmePin? snapStimmePin({
  required List<List<double>> coordinates,
  required double lat,
  required double lng,
  double maxCrossTrackM = kStimmePinMaxCrossTrackM,
}) {
  if (coordinates.length < 2) return null;
  final p = projectOntoRoute(
    coordinates: coordinates,
    lat: lat,
    lng: lng,
  );
  if (p.crossTrackM > maxCrossTrackM) return null;
  final pt = pointAlongRoute(coordinates, p.distanceAlongM);
  return SnappedStimmePin(lat: pt[1], lng: pt[0], alongM: p.distanceAlongM);
}

final _coordRe = RegExp(r'(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)');

/// Freitext mit Koordinatenpaar → Pin. „Parkplatz Zoo“ ohne Zahlen: null.
({double lat, double lng, String label})? parseMeetingLatLng(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  final m = _coordRe.firstMatch(t);
  if (m == null) return null;
  final lat = double.tryParse(m.group(1)!);
  final lng = double.tryParse(m.group(2)!);
  if (lat == null || lng == null) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  final label = t.replaceFirst(_coordRe, '').replaceAll(RegExp(r'[@,]'), ' ').trim();
  return (lat: lat, lng: lng, label: label.isEmpty ? 'Treffpunkt' : label);
}
