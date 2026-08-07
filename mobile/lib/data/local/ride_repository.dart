import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ride.dart';
import '../local/app_database.dart';
import '../local/garage_repository.dart';

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
