import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../../domain/ride_media.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import 'route_repository.dart';
import 'saved_route_meta_store.dart';

/// Brücke Freeride/Nav-Recording → eigene Tour (SavedRoute).
SavedRouteEntry rideRecordToSavedEntry(
  RideRecord ride, {
  String? name,
  String? id,
}) {
  final coords = trackToLngLat(ride.track);
  final durationMin = ride.movingTimeSec > 0
      ? (ride.movingTimeSec / 60).round().clamp(1, 24 * 60)
      : ((ride.distanceKm / 18) * 60).round().clamp(1, 24 * 60);
  final label = (name ?? ride.name)?.trim();
  return SavedRouteEntry(
    id: id ?? 'recorded-${const Uuid().v4()}',
    name: (label != null && label.isNotEmpty) ? label : _defaultName(ride),
    distanceKm: ride.distanceKm > 0 ? ride.distanceKm : _pathKm(coords),
    elevationM: honestClimbM(ride.track, ride.elevationM).toDouble(),
    durationMin: durationMin,
    savedAt: DateTime.now().toUtc(),
    source: 'recorded',
    coordinates: coords,
    tour: coords,
  );
}

List<List<double>> trackToLngLat(List<Map<String, dynamic>> track) {
  final out = <List<double>>[];
  for (final p in track) {
    final lat = (p['lat'] as num?)?.toDouble();
    final lng = (p['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (lat.abs() > 90 || lng.abs() > 180) continue;
    final elevRaw = p['elev'] ?? p['ele'] ?? p['altitude'];
    final elev = elevRaw is num ? elevRaw.toDouble() : null;
    if (elev != null && elev.isFinite && elev >= -50 && elev <= 8900) {
      out.add([lng, lat, elev]);
    } else {
      out.add([lng, lat]);
    }
  }
  return out;
}

/// Speichert Ride als SavedRoute und hängt optionale Post-Ride-Fotos/Notizen an.
Future<SavedRouteEntry> saveRideAsTour({
  required RouteRepository routes,
  required RideRecord ride,
  String? name,
  String? id,
  List<String> photoPaths = const [],
  List<RideMedia> media = const [],
  List<SavedRouteNote> notes = const [],
  String? description,
}) async {
  final entry = rideRecordToSavedEntry(ride, name: name, id: id);
  await routes.saveEntry(entry);
  final photos = [
    for (final path in photoPaths)
      if (path.trim().isNotEmpty) path.trim(),
  ];
  final tagged = [
    for (final m in media)
      if (m.path.trim().isNotEmpty) m,
  ];
  final desc = description?.trim() ?? '';
  if (photos.isNotEmpty ||
      tagged.isNotEmpty ||
      notes.isNotEmpty ||
      desc.isNotEmpty ||
      ride.id.isNotEmpty) {
    final cur = await SavedRouteMetaStore.get(entry.id);
    final nextPhotos = photos.isNotEmpty
        ? photos
        : [for (final m in tagged) if (m.isPhoto) m.path];
    await SavedRouteMetaStore.put(
      entry.id,
      cur.copyWith(
        description: desc.isNotEmpty ? desc : null,
        photoPaths: nextPhotos.isNotEmpty ? nextPhotos : null,
        media: tagged.isNotEmpty ? tagged : null,
        notes: notes.isNotEmpty ? [...cur.notes, ...notes] : null,
        rideId: ride.id,
      ),
    );
  }
  return entry;
}

String _defaultName(RideRecord ride) {
  final d = (ride.endedAt ?? ride.startedAt).toLocal();
  final stamp =
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  return 'Aufgezeichnet $stamp';
}

double _pathKm(List<List<double>> coords) {
  if (coords.length < 2) return 0;
  var sum = 0.0;
  for (var i = 1; i < coords.length; i++) {
    sum += _haversineKm(
      coords[i - 1][1],
      coords[i - 1][0],
      coords[i][1],
      coords[i][0],
    );
  }
  return sum;
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final p = math.pi / 180;
  final a = math.sin((lat2 - lat1) * p / 2) * math.sin((lat2 - lat1) * p / 2) +
      math.cos(lat1 * p) *
          math.cos(lat2 * p) *
          math.sin((lng2 - lng1) * p / 2) *
          math.sin((lng2 - lng1) * p / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}
