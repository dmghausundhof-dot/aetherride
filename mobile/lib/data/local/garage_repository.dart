import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/bike.dart';
import '../sync/sync_payload.dart';
import 'app_database.dart';

/// Offline-First: UI liest ausschließlich aus Drift.
class GarageRepository {
  GarageRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<Bike>> listBikes() async {
    final rows = await _db.select(_db.bikes).get();
    if (rows.isEmpty) {
      await seedDemoIfEmpty();
      return listBikes();
    }
    return rows.map(_toDomain).toList();
  }

  Future<Bike?> getById(String id) async {
    final row = await (_db.select(_db.bikes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> upsert(Bike bike) async {
    await _db.into(_db.bikes).insertOnConflictUpdate(
          BikesCompanion.insert(
            id: bike.id,
            name: bike.name,
            category: bike.category.name,
            brand: Value(bike.brand),
            model: Value(bike.model),
            year: Value(bike.year),
            wheelSize: Value(bike.wheelSize?.name),
            odometerKm: Value(bike.odometerKm),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    await touchLocalSync();
  }

  Future<void> setActiveBike(String id) async {
    await _db.transaction(() async {
      await _db.update(_db.bikes).write(
            const BikesCompanion(isActive: Value(false)),
          );
      await (_db.update(_db.bikes)..where((t) => t.id.equals(id))).write(
            const BikesCompanion(isActive: Value(true)),
          );
    });
    await touchLocalSync();
  }

  Future<void> seedDemoIfEmpty() async {
    final count = await _db.select(_db.bikes).get();
    if (count.isNotEmpty) return;
    final id = _uuid.v4();
    await upsert(
      Bike(
        id: id,
        name: 'Trail E-MTB',
        category: BikeCategory.emtb,
        brand: 'Demo',
        model: 'Aether 1',
        year: 2025,
        wheelSize: WheelSize.w29,
        odometerKm: 412,
      ),
    );
    await setActiveBike(id);
  }

  Future<void> touchLocalSync() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.into(_db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            id: const Value(1),
            localUpdatedAt: Value(now),
          ),
        );
  }

  Future<SyncPayload> buildSyncPayload() async {
    final bikes = await _db.select(_db.bikes).get();
    final setups = await _db.select(_db.setups).get();
    final rides = await _db.select(_db.rides).get();
    final consents = await _db.select(_db.consents).get();
    final state = await (_db.select(_db.syncState)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    final active = bikes.where((b) => b.isActive).map((b) => b.id).firstOrNull;

    return SyncPayload(
      bikes: bikes
          .map(
            (b) => {
              'id': b.id,
              'name': b.name,
              'category': b.category,
              'brand': b.brand,
              'model': b.model,
              'year': b.year,
              'wheelSize': b.wheelSize,
              'odometerKm': b.odometerKm,
              'isActive': b.isActive,
            },
          )
          .toList(),
      setups: setups
          .map(
            (s) => {
              'id': s.id,
              'bikeId': s.bikeId,
              'label': s.label,
              'values': jsonDecode(s.valuesJson),
              'createdAt': s.createdAt.toIso8601String(),
            },
          )
          .toList(),
      rides: rides
          .map(
            (r) => {
              'id': r.id,
              'bikeId': r.bikeId,
              'startedAt': r.startedAt.toIso8601String(),
              'endedAt': r.endedAt?.toIso8601String(),
              'distanceKm': r.distanceKm,
              'movingTimeSec': r.movingTimeSec,
            },
          )
          .toList(),
      consents: {
        for (final c in consents) c.key: c.granted,
      },
      activeBikeId: active,
      updatedAt: state?.localUpdatedAt,
      payloadVersion: state?.payloadVersion ?? 1,
    );
  }

  Future<void> applyRemotePayload(SyncPayload payload) async {
    await _db.transaction(() async {
      if (payload.bikes is List) {
        for (final raw in payload.bikes as List) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final id = m['id'] as String?;
          if (id == null) continue;
          await _db.into(_db.bikes).insertOnConflictUpdate(
                BikesCompanion.insert(
                  id: id,
                  name: (m['name'] as String?) ?? 'Bike',
                  category: (m['category'] as String?) ?? 'mtbAm',
                  brand: Value(m['brand'] as String?),
                  model: Value(m['model'] as String?),
                  year: Value((m['year'] as num?)?.toInt()),
                  wheelSize: Value(m['wheelSize'] as String?),
                  odometerKm: Value((m['odometerKm'] as num?)?.toDouble() ?? 0),
                  isActive: Value(m['isActive'] == true),
                  updatedAt: DateTime.now().toUtc(),
                ),
              );
        }
      }

      await _db.into(_db.syncState).insertOnConflictUpdate(
            SyncStateCompanion.insert(
              id: const Value(1),
              remoteUpdatedAt: Value(payload.updatedAt),
              localUpdatedAt: Value(payload.updatedAt),
              lastDirection: const Value('pulled'),
              payloadVersion: Value(payload.payloadVersion),
            ),
          );
    });
  }

  Bike _toDomain(BikeRow row) {
    return Bike(
      id: row.id,
      name: row.name,
      category: BikeCategory.values.firstWhere(
        (c) => c.name == row.category,
        orElse: () => BikeCategory.mtbAm,
      ),
      brand: row.brand,
      model: row.model,
      year: row.year,
      wheelSize: row.wheelSize == null
          ? null
          : WheelSize.values.firstWhere(
              (w) => w.name == row.wheelSize,
              orElse: () => WheelSize.w29,
            ),
      odometerKm: row.odometerKm,
    );
  }
}
