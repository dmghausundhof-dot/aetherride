import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/post_ride/analyze.dart';
import '../../domain/setup.dart';
import 'app_database.dart';

class SetupRepository {
  SetupRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<BikeSetup>> listForBike(String bikeId) async {
    final rows = await (_db.select(_db.setups)
          ..where((t) => t.bikeId.equals(bikeId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<BikeSetup?> getCurrent(String bikeId) async {
    final row = await (_db.select(_db.setups)
          ..where(
            (t) => t.bikeId.equals(bikeId) & t.isCurrent.equals(true),
          ))
        .getSingleOrNull();
    if (row != null) return _toDomain(row);
    final any = await (_db.select(_db.setups)
          ..where((t) => t.bikeId.equals(bikeId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return any == null ? null : _toDomain(any);
  }

  Future<BikeSetup?> getById(String id) async {
    final row = await (_db.select(_db.setups)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Neue immutable Version; markiert sie als current.
  Future<BikeSetup> createVersion({
    required String bikeId,
    required String label,
    required List<SetupValue> values,
    String conditions = 'general',
    String createdBy = 'user',
    String? parentSetupId,
    String? linkedRideId,
  }) async {
    final existing = await listForBike(bikeId);
    final version = existing.isEmpty
        ? 1
        : existing.map((s) => s.version).reduce((a, b) => a > b ? a : b) + 1;
    final id = _uuid.v4();
    final setup = BikeSetup(
      id: id,
      bikeId: bikeId,
      label: label,
      values: values,
      createdAt: DateTime.now().toUtc(),
      isCurrent: true,
      conditions: conditions,
      version: version,
      parentSetupId: parentSetupId,
      linkedRideId: linkedRideId,
      createdBy: createdBy,
    );
    await _db.transaction(() async {
      await (_db.update(_db.setups)..where((t) => t.bikeId.equals(bikeId)))
          .write(const SetupsCompanion(isCurrent: Value(false)));
      await _db.into(_db.setups).insert(_toCompanion(setup));
    });
    await _touchSync();
    return setup;
  }

  Future<void> setCurrent(String bikeId, String setupId) async {
    await _db.transaction(() async {
      await (_db.update(_db.setups)..where((t) => t.bikeId.equals(bikeId)))
          .write(const SetupsCompanion(isCurrent: Value(false)));
      await (_db.update(_db.setups)..where((t) => t.id.equals(setupId))).write(
            const SetupsCompanion(isCurrent: Value(true)),
          );
    });
    await _touchSync();
  }

  /// Post-Ride-Empfehlung → neue Setup-Version (max. 1 Suggestion pro Ride).
  Future<BikeSetup> applySuggestion({
    required String bikeId,
    required SetupChangeSuggestion suggestion,
    String? linkedRideId,
  }) async {
    final current = await getCurrent(bikeId);
    final baseValues = List<SetupValue>.from(
      current?.values ?? BikeSetup.defaultValues(),
    );
    final key = suggestion.adjusterKey;
    final delta = suggestion.suggestedDelta;
    final next = <SetupValue>[];
    var found = false;
    if (key != null) {
      for (final v in baseValues) {
        if (v.adjusterKey == key) {
          found = true;
          final raw = delta != null ? v.valueNum + delta : v.valueNum;
          final clamped = key.contains('rebound') || key.contains('lsc')
              ? raw.clamp(0, 14).toDouble()
              : raw;
          next.add(
            SetupValue(
              adjusterKey: v.adjusterKey,
              valueNum: clamped,
              unit: v.unit,
              slot: v.slot,
              bikeComponentId: v.bikeComponentId,
            ),
          );
        } else {
          next.add(v);
        }
      }
      if (!found) {
        next.add(
          SetupValue(
            adjusterKey: key,
            valueNum: (delta ?? 0).toDouble().clamp(0, 14),
            unit: key.contains('pressure') ? 'psi' : 'clicks',
          ),
        );
      }
    } else {
      next.addAll(baseValues);
    }

    return createVersion(
      bikeId: bikeId,
      label: suggestion.title,
      values: next,
      parentSetupId: current?.id,
      linkedRideId: linkedRideId,
      createdBy: 'recommendation',
    );
  }

  /// Upsert aus Sync-Payload (Web oder Mobile).
  Future<void> upsertFromSync(Map<String, dynamic> m) async {
    final id = m['id'] as String?;
    final bikeId = m['bikeId'] as String?;
    if (id == null || bikeId == null) return;
    final values = _parseValues(m['values']);
    final createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    await _db.into(_db.setups).insertOnConflictUpdate(
          SetupsCompanion.insert(
            id: id,
            bikeId: bikeId,
            label: (m['label'] as String?) ??
                (m['name'] as String?) ??
                'Setup',
            valuesJson: jsonEncode(values.map((v) => v.toJson()).toList()),
            createdAt: createdAt,
            immutable: Value(m['immutable'] != false),
            isCurrent: Value(m['isCurrent'] == true),
            conditions: Value((m['conditions'] as String?) ?? 'general'),
            version: Value((m['version'] as num?)?.toInt() ?? 1),
            parentSetupId: Value(m['parentSetupId'] as String?),
            linkedRideId: Value(m['linkedRideId'] as String?),
            createdBy: Value((m['createdBy'] as String?) ?? 'user'),
          ),
        );
  }

  Future<void> _touchSync() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.into(_db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            id: const Value(1),
            localUpdatedAt: Value(now),
            lastDirection: const Value('local'),
          ),
        );
  }

  SetupsCompanion _toCompanion(BikeSetup s) {
    return SetupsCompanion.insert(
      id: s.id,
      bikeId: s.bikeId,
      label: s.label,
      valuesJson: jsonEncode(s.values.map((v) => v.toJson()).toList()),
      createdAt: s.createdAt,
      immutable: Value(s.immutable),
      isCurrent: Value(s.isCurrent),
      conditions: Value(s.conditions),
      version: Value(s.version),
      parentSetupId: Value(s.parentSetupId),
      linkedRideId: Value(s.linkedRideId),
      createdBy: Value(s.createdBy),
    );
  }

  BikeSetup _toDomain(SetupRow row) {
    return BikeSetup(
      id: row.id,
      bikeId: row.bikeId,
      label: row.label,
      values: _parseValues(jsonDecode(row.valuesJson)),
      createdAt: row.createdAt,
      immutable: row.immutable,
      isCurrent: row.isCurrent,
      conditions: row.conditions,
      version: row.version,
      parentSetupId: row.parentSetupId,
      linkedRideId: row.linkedRideId,
      createdBy: row.createdBy,
    );
  }

  List<SetupValue> _parseValues(dynamic raw) {
    if (raw is List) {
      return [
        for (final e in raw)
          if (e is Map) SetupValue.fromJson(Map<String, dynamic>.from(e)),
      ];
    }
    if (raw is Map) {
      return [
        for (final e in raw.entries)
          SetupValue(
            adjusterKey: e.key.toString(),
            valueNum: (e.value as num?)?.toDouble() ?? 0,
          ),
      ];
    }
    return BikeSetup.defaultValues();
  }
}
