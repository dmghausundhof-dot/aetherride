import '../community/ride_group.dart';
import '../saved_route.dart';

/// Sortierung der Mappe — nicht der öffentlichen Karte.
enum MappeSort { recent, distance, name }

bool savedRouteHasTrack(SavedRouteEntry s) =>
    s.coordinates.length >= 2 || s.tour.length >= 2;

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
  return [for (final s in input) if (s.name.toLowerCase().contains(q)) s];
}

/// km · hm · min — leer ohne Track, damit die Karte nicht lügt.
String mappeCardStats(SavedRouteEntry s) {
  if (!savedRouteHasTrack(s)) return '';
  final km = s.distanceKm.toStringAsFixed(1);
  return '$km km · ${s.elevationM.round()} hm · ${s.durationMin} min';
}

/// Nächstes offenes Treffen — geschlossen oder abgelaufen fällt weg.
RideGroup? nextActiveMeeting(
  List<RideGroup> groups, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final open = [
    for (final g in groups)
      if (g.status != RideGroupStatus.closed && !n.isAfter(g.startWindowEnd)) g,
  ];
  if (open.isEmpty) return null;
  open.sort((a, b) => a.startWindowStart.compareTo(b.startWindowStart));
  return open.first;
}
