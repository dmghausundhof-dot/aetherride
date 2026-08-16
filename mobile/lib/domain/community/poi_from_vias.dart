import '../active_route.dart';
import '../routing/route_progress.dart';
import '../saved_route.dart';
import 'labeled_via.dart';

/// Vias weiter als so vom Track zählen nicht als HUD-Ort (nicht auf der Linie).
const kPoiViaMaxCrossTrackM = 400.0;

/// Benannte Vias → HUD-Stops. Unbenannt oder abseits der Linie: weg.
List<ActiveRoutePoi> poiStopsFromVias({
  required List<LabeledVia> vias,
  required List<List<double>> coordinates,
  required int durationMin,
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
