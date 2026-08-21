import '../community/ride_group.dart';
import '../community/ride_group_policy.dart';
import '../routing/route_progress.dart';
import '../routing/track_elevation.dart';
import '../saved_route.dart';
import 'tour_line.dart';

/// Sortierung der Mappe — nicht der öffentlichen Karte.
enum MappeSort { recent, distance, name }

bool savedRouteHasTrack(SavedRouteEntry s) =>
    s.coordinates.length >= 2 || s.tour.length >= 2;

/// Inbox-Titel: Tourname, sonst erster Satz, nie eine Roh-ID.
String stimmeInboxTitle({
  required String untitled,
  String? routeName,
  String body = '',
}) {
  final name = routeName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final line = body.trim().split(RegExp(r'\s*\n\s*')).first.trim();
  if (line.isEmpty) return untitled;
  if (line.length <= 42) return line;
  return '${line.substring(0, 41)}…';
}

/// Untertitel: Body nicht wiederholen, wenn er schon der Titel ist.
bool stimmeInboxShowsBody({
  required String title,
  required String body,
}) {
  final line = body.trim().split(RegExp(r'\s*\n\s*')).first.trim();
  if (line.isEmpty) return false;
  if (line == title) return false;
  if (title.endsWith('…')) {
    final stem = title.substring(0, title.length - 1);
    if (stem.isNotEmpty && line.startsWith(stem)) return false;
  }
  return true;
}

/// Runde nur aus der echten Spur — nie ohne Track.
bool savedRouteIsLoop(SavedRouteEntry s) =>
    fitTourLine(
      trackCoordsOf(coordinates: s.coordinates, tour: s.tour),
    )?.loop ==
    true;

List<SavedRouteEntry> sortMappe(
  List<SavedRouteEntry> input,
  MappeSort sort,
) {
  final out = [...input];
  switch (sort) {
    case MappeSort.recent:
      out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    case MappeSort.distance:
      out.sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
    case MappeSort.name:
      out.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }
  return out;
}

List<SavedRouteEntry> filterMappeQuery(
  List<SavedRouteEntry> input,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return input;
  return [
    for (final s in input)
      if (s.name.toLowerCase().contains(q)) s
  ];
}

class MappeCardStatParts {
  const MappeCardStatParts({
    required this.km,
    this.hm,
    required this.min,
  });

  final String km;
  final String? hm;
  final String min;
}

String _mappeKm(double km) {
  if (km == km.roundToDouble()) return '${km.round()} km';
  return '${km.toStringAsFixed(1)} km';
}

/// 0 und absurde hm/km (>50) sind unbekannt — nie 3 % der Distanz.
int? mappeHonestHm(
  double elevationM,
  double distanceKm, {
  String? source,
  bool hasRealElev = false,
}) {
  if (!elevationM.isFinite || elevationM <= 0) return null;
  if (mappeElevLooksInvented(
    elevationM,
    distanceKm,
    source: source,
    hasRealElev: hasRealElev,
  )) {
    return null;
  }
  if (distanceKm > 0 && elevationM / distanceKm > 50) return null;
  return elevationM.round();
}

/// Fingerabdruck von `distanceM * 0.03` — nur Engine/2D-Import, nie Katalog.
bool mappeElevLooksInvented(
  double elevationM,
  double distanceKm, {
  String? source,
  bool hasRealElev = false,
}) {
  if (!(elevationM > 0) || !(distanceKm > 0)) return false;
  if ((elevationM - distanceKm * 30).abs() > 1) return false;
  switch (source?.trim().toLowerCase() ?? '') {
    case 'suggestion':
    case 'recorded':
    case 'library':
      return false;
    case 'import':
      return !hasRealElev;
    case 'engine':
    case '':
      return true;
    default:
      return !hasRealElev;
  }
}

bool mappeStoredHmNeedsReplace(
  double elevationM,
  double distanceKm, {
  String? source,
  bool hasRealElev = false,
}) {
  if (!(elevationM > 0)) return true;
  return mappeElevLooksInvented(
    elevationM,
    distanceKm,
    source: source,
    hasRealElev: hasRealElev,
  );
}

/// Summe positiver Schritte. Lücken setzen den vorigen Wert zurück.
double? mappeTrackClimbM(List<List<double>> coordsLngLat) {
  double? prev;
  var gain = 0.0;
  var steps = 0;
  for (final p in coordsLngLat) {
    if (p.length < 3 || !p[2].isFinite) {
      prev = null;
      continue;
    }
    final elev = p[2];
    if (prev != null) {
      final d = elev - prev;
      if (d > 0) gain += d;
      steps++;
    }
    prev = elev;
  }
  if (steps < 1 || gain <= 0) return null;
  return gain;
}

/// km / hm / min — null ohne Track, hm nur wenn die Zahl ehrlich ist.
MappeCardStatParts? mappeCardStatParts(SavedRouteEntry s) {
  if (!savedRouteHasTrack(s)) return null;
  final coords = trackCoordsOf(
    coordinates: s.coordinates,
    tour: s.tour,
  );
  final hm = mappeHonestHm(
    s.elevationM,
    s.distanceKm,
    source: s.source,
    hasRealElev: trackHasRealElev(coords),
  );
  return MappeCardStatParts(
    km: _mappeKm(s.distanceKm),
    hm: hm == null ? null : '$hm hm',
    min: '${s.durationMin} min',
  );
}

/// km · hm · min — leer ohne Track, hm weggelassen wenn unbekannt.
String mappeCardStats(SavedRouteEntry s) {
  final parts = mappeCardStatParts(s);
  if (parts == null) return '';
  return [
    parts.km,
    if (parts.hm != null) parts.hm!,
    parts.min,
  ].join(' · ');
}

bool savedRouteNeedsElevBackfill(SavedRouteEntry s) {
  final coords = trackCoordsOf(
    coordinates: s.coordinates,
    tour: s.tour,
  );
  if (coords.length < 2) return false;
  if (!trackHasRealElev(coords)) return true;
  if (!mappeStoredHmNeedsReplace(
    s.elevationM,
    s.distanceKm,
    source: s.source,
    hasRealElev: true,
  )) {
    return false;
  }
  return mappeTrackClimbM(coords) != null;
}

/// Hängt gemessene Höhe an. Catalog-hm bleibt; 0 und 3-%-Formel weichen der Messung.
SavedRouteEntry? applyElevBackfill({
  required SavedRouteEntry entry,
  required List<List<double>> nextCoords,
  required double climbM,
}) {
  if (!trackHasRealElev(nextCoords)) return null;
  final keepCatalog = !mappeStoredHmNeedsReplace(
    entry.elevationM,
    entry.distanceKm,
    source: entry.source,
    hasRealElev: true,
  );
  final hm =
      keepCatalog ? entry.elevationM : (climbM > 0 ? climbM : entry.elevationM);
  final useCoords = entry.coordinates.length >= 2;
  return entry.copyWith(
    coordinates: useCoords ? nextCoords : entry.coordinates,
    tour: useCoords ? entry.tour : nextCoords,
    elevationM: hm,
  );
}

/// Chip-Text nur wenn er ein ehrliches Tag ist — keine Defaults, kein „import“.
String? mappeFaceTag(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty || t == '—' || t == '-') return null;
  if (t.length > 22) return null;
  switch (t.toLowerCase()) {
    case 'offen':
    case 'import':
    case 'mixed':
    case 'mixed/urban':
    case 'unknown':
      return null;
  }
  return t;
}

/// Import und Aufzeichnung — nicht der Default „Geplant“.
String? mappeSourceChip(
  String source, {
  required String importLabel,
  required String recordedLabel,
  String? ownLabel,
}) {
  switch (source.trim().toLowerCase()) {
    case 'import':
      return importLabel;
    case 'recorded':
      return recordedLabel;
    case 'library':
      return ownLabel;
    default:
      return null;
  }
}

/// Höhenkurve nur aus echter 3. Koordinate, mit sichtbarer Amplitude.
List<double> mappeElevSpark(
  List<List<double>> coordsLngLat, {
  int maxPoints = 32,
}) {
  final raw = <double>[
    for (final p in coordsLngLat)
      if (p.length >= 3 && p[2].isFinite) p[2],
  ];
  if (raw.length < 4) return const [];
  var minE = raw.first;
  var maxE = raw.first;
  for (final e in raw) {
    if (e < minE) minE = e;
    if (e > maxE) maxE = e;
  }
  if (maxE - minE < 15) return const [];
  if (raw.length <= maxPoints) {
    return [for (final e in raw) (e - minE) / (maxE - minE)];
  }
  final step = (raw.length - 1) / (maxPoints - 1);
  return [
    for (var i = 0; i < maxPoints; i++)
      (raw[(i * step).round()] - minE) / (maxE - minE),
  ];
}

/// Kilometer vom GPS zum Start der echten Spur — nie ohne Track, nie unter 1 km.
int? mappeStartAwayKm({
  required List<List<double>> coordsLngLat,
  required double? userLat,
  required double? userLng,
}) {
  if (coordsLngLat.length < 2 || userLat == null || userLng == null) {
    return null;
  }
  final start = coordsLngLat.first;
  if (start.length < 2) return null;
  final km = haversineM(userLat, userLng, start[1], start[0]) / 1000;
  if (!km.isFinite || km < 1) return null;
  return km.round();
}

/// Echte Spuren einer Sammlung — Reihenfolge der IDs.
int mappeCollectionTrackCount({
  required List<String> routeIds,
  required List<SavedRouteEntry> saved,
}) {
  return mappeCollectionTracks(
    routeIds: routeIds,
    saved: saved,
    max: routeIds.length,
  ).length;
}

/// Tourenzahl, plus +N wenn der Stapel Linien weglässt.
String mappeCollectionRestLine({
  required String toursLabel,
  required int extraTracks,
}) {
  if (extraTracks <= 0) return toursLabel;
  return '$toursLabel · +$extraTracks';
}

/// Bis zu drei echte Spuren einer Sammlung — Reihenfolge der IDs.
List<List<List<double>>> mappeCollectionTracks({
  required List<String> routeIds,
  required List<SavedRouteEntry> saved,
  int max = 3,
}) {
  if (max <= 0) return const [];
  final out = <List<List<double>>>[];
  for (final id in routeIds) {
    SavedRouteEntry? hit;
    for (final s in saved) {
      if (s.id == id) {
        hit = s;
        break;
      }
    }
    if (hit == null) continue;
    final coords = trackCoordsOf(
      coordinates: hit.coordinates,
      tour: hit.tour,
    );
    if (coords.length < 2) continue;
    out.add(coords);
    if (out.length >= max) break;
  }
  return out;
}

/// Nächstes offenes Treffen — geschlossen oder abgelaufen fällt weg.
RideGroup? nextActiveMeeting(
  List<RideGroup> groups, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final open = [
    for (final g in groups)
      if (g.status != RideGroupStatus.closed &&
          g.savedRouteId.trim() != RideGroupPolicy.sessionRouteId &&
          !n.isAfter(g.startWindowEnd))
        g,
  ];
  if (open.isEmpty) return null;
  open.sort((a, b) => a.startWindowStart.compareTo(b.startWindowStart));
  return open.first;
}
