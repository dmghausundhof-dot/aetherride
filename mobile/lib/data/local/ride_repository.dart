import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ride.dart';
import '../local/app_database.dart';
import '../local/garage_repository.dart';

/// Aggregierte Fahrer-Kennzahlen fürs Profil (Komoot/AllTrails-Stil:
/// Aktivität statt reinem Einstellungsformular).
class RideStats {
  const RideStats({
    required this.rideCount,
    required this.totalKm,
    required this.totalElevationM,
    this.distanceKnown = true,
  });

  final int rideCount;
  final double totalKm;
  final double totalElevationM;

  /// false, wenn Rides existieren, aber weder Distanz-Spalte noch Track
  /// eine Strecke hergeben — UI soll dann „—" statt „0 km" zeigen.
  final bool distanceKnown;
}

class RideRepository {
  RideRepository(this._db, this._garage);

  final AppDatabase _db;
  final GarageRepository _garage;
  final _uuid = const Uuid();

  Future<List<RideRecord>> listRides({int limit = 50}) async {
    final rows = await (_db.select(_db.rides)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<RideRecord?> lastEndedForBike(String bikeId) async {
    if (bikeId.isEmpty) return null;
    final rows = await (_db.select(_db.rides)
          ..where((t) => t.bikeId.equals(bikeId) & t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return _toDomain(rows.first);
  }

  /// SQL-Aggregat statt „limit hoch genug setzen und clientseitig summieren"
  /// — korrekt unabhängig von der Ride-Anzahl.
  Future<RideStats> statsSummary() async {
    final countExp = _db.rides.id.count();
    final kmExp = _db.rides.distanceKm.sum();
    final hmExp = _db.rides.elevationM.sum();
    final query = _db.selectOnly(_db.rides)
      ..addColumns([countExp, kmExp, hmExp]);
    final row = await query.getSingle();
    final rideCount = row.read(countExp) ?? 0;
    var totalKm = row.read(kmExp) ?? 0.0;
    if (rideCount > 0) {
      final zeros = await (_db.select(_db.rides)
            ..where((t) => t.distanceKm.isSmallerThanValue(0.05)))
          .get();
      var fromTrack = 0.0;
      for (final z in zeros) {
        fromTrack += distanceKmFromTrack(_parseTrackJson(z.trackJson));
      }
      if (fromTrack > 0) totalKm += fromTrack;
    }
    return RideStats(
      rideCount: rideCount,
      totalKm: totalKm,
      totalElevationM: row.read(hmExp) ?? 0.0,
      distanceKnown: rideCount == 0 || totalKm >= 0.05,
    );
  }

  Future<RideRecord?> getById(String id) async {
    final row = await (_db.select(_db.rides)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<RideRecord> endRide({
    String? bikeId,
    String? setupId,
    required DateTime startedAt,
    required DateTime endedAt,
    required double distanceKm,
    required int movingTimeSec,
    String? id,
    String? name,
    String? routeId,
    List<TrackPoint> track = const [],
    Map<String, dynamic> summary = const {},
    double elevationM = 0,
  }) async {
    final rideId = id ?? _uuid.v4();
    final resolvedBike = (bikeId != null &&
            bikeId.isNotEmpty &&
            bikeId != 'unknown')
        ? bikeId
        : '';
    final honestKm = distanceKm.isFinite && distanceKm > 0 ? distanceKm : 0.0;
    final honestSec = movingTimeSec > 0 ? movingTimeSec : 0;
    final mergedSummary = <String, dynamic>{
      ...summary,
      if (setupId != null && setupId.isNotEmpty) 'setupId': setupId,
      if (routeId != null && routeId.isNotEmpty) 'savedRouteId': routeId,
      if (resolvedBike.isEmpty) 'unassigned': true,
    };
    final record = RideRecord(
      id: rideId,
      bikeId: resolvedBike,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceKm: honestKm,
      movingTimeSec: honestSec,
      elevationM: elevationM,
      name: name,
      routeId: routeId,
      setupId: setupId,
      track: track.map((t) => t.toJson()).toList(),
      summary: mergedSummary,
    );
    await _db.into(_db.rides).insert(
          RidesCompanion.insert(
            id: record.id,
            bikeId: record.bikeId,
            startedAt: record.startedAt.toUtc(),
            endedAt: Value(record.endedAt?.toUtc()),
            distanceKm: Value(record.distanceKm),
            movingTimeSec: Value(record.movingTimeSec),
            elevationM: Value(record.elevationM),
            name: Value(record.name),
            routeId: Value(record.routeId),
            trackJson: Value(jsonEncode(record.track)),
            summaryJson: Value(jsonEncode(record.summary)),
          ),
        );
    if (resolvedBike.isNotEmpty && (honestKm > 0 || honestSec > 0)) {
      await _garage.addOdometer(
        bikeId: resolvedBike,
        distanceKm: honestKm,
        hours: honestSec / 3600.0,
      );
    }
    await _garage.touchLocalSync();
    return record;
  }

  Future<void> submitFeedback(String rideId, RideFeedback feedback) async {
    await (_db.update(_db.rides)..where((t) => t.id.equals(rideId))).write(
      RidesCompanion(
        feedbackJson: Value(jsonEncode(feedback.toJson())),
      ),
    );
    await _garage.touchLocalSync();
  }

  /// Hängt die Fahrt an eine Mappe-Akte (Live-Tour nach Stopp).
  Future<void> attachSavedRoute(String rideId, String routeId) async {
    final id = routeId.trim();
    if (id.isEmpty) return;
    await (_db.update(_db.rides)..where((t) => t.id.equals(rideId))).write(
      RidesCompanion(routeId: Value(id)),
    );
    await mergeSummary(rideId, {'savedRouteId': id, 'liveTour': true});
  }

  /// Merges keys into [RideRecord.summary] (weather snapshot, photo paths, …).
  Future<void> mergeSummary(
    String rideId,
    Map<String, dynamic> patch,
  ) async {
    final ride = await getById(rideId);
    if (ride == null) return;
    final next = <String, dynamic>{...ride.summary, ...patch};
    await (_db.update(_db.rides)..where((t) => t.id.equals(rideId))).write(
      RidesCompanion(summaryJson: Value(jsonEncode(next))),
    );
    await _garage.touchLocalSync();
  }

  RideRecord _toDomain(Ride row) {
    Map<String, dynamic> summary = {};
    try {
      final decoded = jsonDecode(row.summaryJson);
      if (decoded is Map) summary = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    final track = _parseTrackJson(row.trackJson);
    RideFeedback? feedback;
    if (row.feedbackJson != null && row.feedbackJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.feedbackJson!);
        if (decoded is Map) {
          feedback = RideFeedback.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return RideRecord(
      id: row.id,
      bikeId: row.bikeId,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      distanceKm: row.distanceKm,
      movingTimeSec: row.movingTimeSec,
      elevationM: row.elevationM,
      name: row.name,
      routeId: row.routeId,
      setupId: summary['setupId'] as String?,
      track: track,
      feedback: feedback,
      summary: summary,
    );
  }

  List<Map<String, dynamic>> _parseTrackJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return [
          for (final e in decoded)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      }
    } catch (_) {}
    return const [];
  }
}
