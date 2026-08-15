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
  });

  final int rideCount;
  final double totalKm;
  final double totalElevationM;
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

  /// SQL-Aggregat statt „limit hoch genug setzen und clientseitig summieren"
  /// — korrekt unabhängig von der Ride-Anzahl.
  Future<RideStats> statsSummary() async {
    final countExp = _db.rides.id.count();
    final kmExp = _db.rides.distanceKm.sum();
    final hmExp = _db.rides.elevationM.sum();
    final query = _db.selectOnly(_db.rides)
      ..addColumns([countExp, kmExp, hmExp]);
    final row = await query.getSingle();
    return RideStats(
      rideCount: row.read(countExp) ?? 0,
      totalKm: row.read(kmExp) ?? 0.0,
      totalElevationM: row.read(hmExp) ?? 0.0,
    );
  }

  Future<RideRecord?> getById(String id) async {
    final row = await (_db.select(_db.rides)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<RideRecord> endRide({
    required String bikeId,
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
    final record = RideRecord(
      id: rideId,
      bikeId: bikeId,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceKm: distanceKm,
      movingTimeSec: movingTimeSec,
      elevationM: elevationM,
      name: name,
      routeId: routeId,
      track: track.map((t) => t.toJson()).toList(),
      summary: summary,
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
    await _garage.addOdometer(
      bikeId: bikeId,
      distanceKm: distanceKm,
      hours: movingTimeSec / 3600.0,
    );
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
    List<Map<String, dynamic>> track = [];
    try {
      final decoded = jsonDecode(row.trackJson);
      if (decoded is List) {
        track = [
          for (final e in decoded)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      }
    } catch (_) {}
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
      track: track,
      feedback: feedback,
      summary: summary,
    );
  }
}
