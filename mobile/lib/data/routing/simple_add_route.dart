import 'package:uuid/uuid.dart';

import '../../domain/saved_route.dart';

/// Ehrliches Mini-„Route hinzufügen“: Name + Start, kein Fake-Track.
class SimpleAddRoute {
  SimpleAddRoute._();

  static String defaultName(DateTime now) {
    final d = now.toLocal();
    return 'Route ${d.day}.${d.month}.';
  }

  /// Pin-only Bibliothekseintrag — Strecke später berechnen oder GPX.
  /// Ohne lat/lng: Name ohne Fake-Pin.
  static SavedRouteEntry fromStart({
    required String name,
    double? lat,
    double? lng,
    DateTime? now,
    String? id,
  }) {
    final at = now ?? DateTime.now();
    final trimmed = name.trim();
    final label = trimmed.isEmpty ? defaultName(at) : trimmed;
    final hasPin = lat != null && lng != null;
    return SavedRouteEntry(
      id: id ?? 'library-${const Uuid().v4()}',
      name: label,
      distanceKm: 0,
      elevationM: 0,
      durationMin: 0,
      savedAt: at.toUtc(),
      source: 'library',
      coordinates: const [],
      waypoints: hasPin
          ? [
              SavedWaypoint(
                role: 'start',
                lng: lng,
                lat: lat,
                label: 'Start',
              ),
            ]
          : const [],
    );
  }

  /// Bestehende Tour (Seed/Katalog) in dieselbe Saved-Liste legen.
  static SavedRouteEntry fromExistingTour({
    required String id,
    required String name,
    required double distanceKm,
    required double elevationM,
    required int durationMin,
    required double startLat,
    required double startLng,
    List<List<double>> coordinates = const [],
  }) {
    return SavedRouteEntry(
      id: id,
      name: name.trim().isEmpty ? 'Tour' : name.trim(),
      distanceKm: distanceKm,
      elevationM: elevationM,
      durationMin: durationMin,
      savedAt: DateTime.now().toUtc(),
      source: 'suggestion',
      coordinates: coordinates,
      waypoints: [
        SavedWaypoint(
          role: 'start',
          lng: startLng,
          lat: startLat,
          label: 'Start',
        ),
        if (coordinates.length >= 2)
          SavedWaypoint(
            role: 'end',
            lng: coordinates.last[0],
            lat: coordinates.last[1],
            label: 'Ziel',
          ),
      ],
    );
  }
}
