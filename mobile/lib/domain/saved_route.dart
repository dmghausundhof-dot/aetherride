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
    this.engine,
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

  /// Routing engine that produced the track (`offline_graph`, `valhalla`, …).
  final String? engine;

  /// Active/merged track as [lng, lat] or [lng, lat, ele] pairs.
  final List<List<double>> coordinates;
  final List<SavedWaypoint> waypoints;
  final List<List<double>> approach;
  final List<List<double>> tour;
  final List<List<double>> trail;

  bool get hasLayerParts =>
      approach.length >= 2 || tour.length >= 2 || trail.length >= 2;

  SavedRouteEntry copyWith({
    String? id,
    String? name,
    double? distanceKm,
    double? elevationM,
    int? durationMin,
    DateTime? savedAt,
    String? source,
    String? engine,
    List<List<double>>? coordinates,
    List<SavedWaypoint>? waypoints,
    List<List<double>>? approach,
    List<List<double>>? tour,
    List<List<double>>? trail,
  }) {
    return SavedRouteEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationM: elevationM ?? this.elevationM,
      durationMin: durationMin ?? this.durationMin,
      savedAt: savedAt ?? this.savedAt,
      source: source ?? this.source,
      engine: engine ?? this.engine,
      coordinates: coordinates ?? this.coordinates,
      waypoints: waypoints ?? this.waypoints,
      approach: approach ?? this.approach,
      tour: tour ?? this.tour,
      trail: trail ?? this.trail,
    );
  }
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
  String? engine,
}) {
  final eng = engine?.trim() ?? '';
  if (approach.isEmpty && tour.isEmpty && trail.isEmpty && eng.isEmpty) {
    return null;
  }
  return jsonEncode({
    if (approach.isNotEmpty) 'approach': approach,
    if (tour.isNotEmpty) 'tour': tour,
    if (trail.isNotEmpty) 'trail': trail,
    if (eng.isNotEmpty) 'engine': eng,
  });
}

({
  List<List<double>> approach,
  List<List<double>> tour,
  List<List<double>> trail,
  String? engine,
}) layersFromJson(String? raw) {
  if (raw == null || raw.isEmpty) {
    return (
      approach: const [],
      tour: const [],
      trail: const [],
      engine: null,
    );
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    return (
      approach: const [],
      tour: const [],
      trail: const [],
      engine: null,
    );
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

  final eng = (decoded['engine'] as String?)?.trim();
  return (
    approach: read('approach'),
    tour: read('tour'),
    trail: read('trail'),
    engine: (eng == null || eng.isEmpty) ? null : eng,
  );
}

/// Reload keeps a stored engine; older rows without one stay `saved`.
String restoredSavedEngine(String? stored) {
  final e = stored?.trim() ?? '';
  return e.isEmpty ? 'saved' : e;
}
