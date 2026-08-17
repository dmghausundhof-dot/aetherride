import '../active_route.dart';
import '../routing/route_progress.dart';
import '../saved_route.dart';
import 'labeled_via.dart';

/// Vias weiter als so vom Track zählen nicht als HUD-Ort (nicht auf der Linie).
const kPoiViaMaxCrossTrackM = 400.0;

/// Erster Namensblock einer Adresse — HUD-POI und Via-Label, nicht die ganze Photon-Zeile.
String? namedPlaceHudTitle(String? raw, {String? skipExact}) {
  final t = (raw ?? '').trim();
  if (t.isEmpty) return null;
  if (skipExact != null && t == skipExact) return null;
  if (RegExp(r'^-?\d+[.,]\d+').hasMatch(t)) return null;
  final head = t.split(',').first.trim();
  return head.isEmpty ? null : head;
}

/// Trail-Snap nur für namenlose Map-Taps. Benannter Ort bleibt auf seinem Punkt.
bool viaMaySnapOntoTrail({String? label}) => namedPlaceHudTitle(label) == null;

/// Benannte Vias → HUD-Stops. Unbenannt oder abseits der Linie: weg.
/// [destinationLabel] hängt das geocodierte Ziel ans Ende, wenn es kein Via ist.
List<ActiveRoutePoi> poiStopsFromVias({
  required List<LabeledVia> vias,
  required List<List<double>> coordinates,
  required int durationMin,
  String? destinationLabel,
}) {
  final total = routeLengthM(coordinates);
  if (total <= 0 || durationMin <= 0) return const [];
  final out = <ActiveRoutePoi>[];
  for (final v in vias) {
    final title = v.trimmedLabel;
    if (title == null) continue;
    final p = projectOntoRoute(
      coordinates: coordinates,
      lat: v.lat,
      lng: v.lng,
    );
    if (p.crossTrackM > kPoiViaMaxCrossTrackM) continue;
    final atMin =
        ((p.distanceAlongM / total) * durationMin).round().clamp(1, durationMin);
    out.add(
      ActiveRoutePoi(
        atMin: atMin,
        title: title,
        kind: (v.kind ?? '').trim().isEmpty ? 'poi' : v.kind!.trim(),
      ),
    );
  }
  final destTitle = namedPlaceHudTitle(destinationLabel);
  if (destTitle != null &&
      !out.any((s) => s.title.toLowerCase() == destTitle.toLowerCase())) {
    out.add(
      ActiveRoutePoi(
        atMin: durationMin.clamp(1, durationMin),
        title: destTitle,
        kind: 'poi',
      ),
    );
  }
  out.sort((a, b) => a.atMin.compareTo(b.atMin));
  return out;
}

List<LabeledVia> labeledViasFromSaved(List<SavedWaypoint> waypoints) {
  return [
    for (final w in waypoints)
      if (w.role == 'via')
        LabeledVia(
          lat: w.lat,
          lng: w.lng,
          label: w.label,
        ),
  ];
}
