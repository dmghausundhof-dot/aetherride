import 'dart:convert';

/// Persistierte Discover-Route (Spiegel Web SavedRoute).
class SavedRouteEntry {
  const SavedRouteEntry({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    required this.durationMin,
    required this.savedAt,
    this.source = 'engine',
    this.coordinates = const [],
    this.waypoints = const [],
    this.approach = const [],
    this.tour = const [],
    this.trail = const [],
  });

  final String id;
  final String name;
  final double distanceKm;
  final double elevationM;
  final int durationMin;
  final DateTime savedAt;
  final String source;

  /// Active/merged track as [lng, lat] pairs.
  final List<List<double>> coordinates;
  final List<SavedWaypoint> waypoints;
  final List<List<double>> approach;
  final List<List<double>> tour;
  final List<List<double>> trail;

  bool get hasLayerParts =>
      approach.length >= 2 || tour.length >= 2 || trail.length >= 2;
}

class SavedWaypoint {
  const SavedWaypoint({
    required this.role,
    required this.lng,
    required this.lat,
    this.label,
  });

  final String role;
  final double lng;
  final double lat;
  final String? label;
}

String coordsToJson(List<List<double>> coords) => jsonEncode(coords);

List<List<double>> coordsFromJson(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return decoded
      .whereType<List>()
      .map((e) => e.map((v) => (v as num).toDouble()).toList())
      .where((e) => e.length >= 2)
      .toList();
}

String waypointsToJson(List<SavedWaypoint> wps) => jsonEncode([
      for (final w in wps)
        {
          'role': w.role,
          'lngLat': [w.lng, w.lat],
          if (w.label != null) 'label': w.label,
        },
    ]);

List<SavedWaypoint> waypointsFromJson(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return [
    for (final e in decoded)
      if (e is Map)
        SavedWaypoint(
          role: e['role'] as String? ?? 'via',
          lng: ((e['lngLat'] as List?)?[0] as num?)?.toDouble() ?? 0,
          lat: ((e['lngLat'] as List?)?[1] as num?)?.toDouble() ?? 0,
          label: e['label'] as String?,
        ),
  ];
}

String? layersToJson({
  List<List<double>> approach = const [],
  List<List<double>> tour = const [],
  List<List<double>> trail = const [],
}) {
  if (approach.isEmpty && tour.isEmpty && trail.isEmpty) return null;
  return jsonEncode({
    if (approach.isNotEmpty) 'approach': approach,
    if (tour.isNotEmpty) 'tour': tour,
    if (trail.isNotEmpty) 'trail': trail,
  });
}

({
  List<List<double>> approach,
  List<List<double>> tour,
  List<List<double>> trail,
}) layersFromJson(String? raw) {
  if (raw == null || raw.isEmpty) {
    return (approach: const [], tour: const [], trail: const []);
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    return (approach: const [], tour: const [], trail: const []);
  }
  List<List<double>> read(String key) {
    final v = decoded[key];
    if (v is! List) return const [];
    return v
        .whereType<List>()
        .map((e) => e.map((x) => (x as num).toDouble()).toList())
        .where((e) => e.length >= 2)
        .toList();
  }

  return (
    approach: read('approach'),
    tour: read('tour'),
    trail: read('trail'),
  );
}
