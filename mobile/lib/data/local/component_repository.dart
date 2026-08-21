import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/component.dart';
import '../local/app_database.dart';
import '../local/garage_repository.dart';

class ComponentRepository {
  ComponentRepository(this._db, this._garage);

  final AppDatabase _db;
  final GarageRepository _garage;
  final _uuid = const Uuid();

  Future<List<BikeComponent>> listInstalled(String bikeId) async {
    final rows = await (_db.select(_db.components)
          ..where((t) => t.bikeId.equals(bikeId)))
        .get();
    return rows.map(_toDomain).where((c) => c.isInstalled).toList();
  }

  Future<List<BikeComponent>> listAll(String bikeId) async {
    final rows = await (_db.select(_db.components)
          ..where((t) => t.bikeId.equals(bikeId)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<BikeComponent> install({
    required String bikeId,
    required ComponentSlot slot,
    String? manufacturer,
    String? model,
    String? catalogModelId,
    Map<String, dynamic> attributes = const {},
  }) async {
    final now = DateTime.now().toUtc();
    // Soft-remove existing installed on same slot
    final existing = await (_db.select(_db.components)
          ..where((t) => t.bikeId.equals(bikeId) & t.slot.equals(slot.apiId)))
        .get();
    for (final row in existing) {
      if (row.removedAt == null) {
        await (_db.update(_db.components)..where((t) => t.id.equals(row.id)))
            .write(ComponentsCompanion(removedAt: Value(now)));
      }
    }

    final id = _uuid.v4();
    final bike = await _garage.getById(bikeId);
    final attrs = <String, dynamic>{
      ...attributes,
      BikeComponent.hoursAtInstallAttr: bike?.hours ?? 0,
    };
    await _db.into(_db.components).insert(
          ComponentsCompanion.insert(
            id: id,
            bikeId: bikeId,
            slot: slot.apiId,
            manufacturer: Value(manufacturer),
            model: Value(model),
            catalogModelId: Value(catalogModelId),
            installedAt: Value(now),
            odometerKm: Value(bike?.odometerKm ?? 0),
            attributesJson: Value(jsonEncode(attrs)),
            updatedAt: now,
          ),
        );
    await _garage.touchLocalSync();
    return BikeComponent(
      id: id,
      bikeId: bikeId,
      slot: slot,
      manufacturer: manufacturer,
      model: model,
      catalogModelId: catalogModelId,
      installedAt: now,
      odometerKm: bike?.odometerKm ?? 0,
      hoursAtInstall: bike?.hours ?? 0,
      attributes: attrs,
    );
  }

  Future<void> remove(String componentId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.components)..where((t) => t.id.equals(componentId)))
        .write(ComponentsCompanion(removedAt: Value(now), updatedAt: Value(now)));
    await _garage.touchLocalSync();
  }

  Future<void> reinstall(String componentId) async {
    final now = DateTime.now().toUtc();
    final row = await (_db.select(_db.components)
          ..where((t) => t.id.equals(componentId)))
        .getSingleOrNull();
    if (row == null || row.removedAt == null) return;
    final occupied = await (_db.select(_db.components)
          ..where(
            (t) =>
                t.bikeId.equals(row.bikeId) &
                t.slot.equals(row.slot) &
                t.removedAt.isNull(),
          ))
        .get();
    for (final o in occupied) {
      await (_db.update(_db.components)..where((t) => t.id.equals(o.id)))
          .write(ComponentsCompanion(removedAt: Value(now), updatedAt: Value(now)));
    }
    await (_db.update(_db.components)..where((t) => t.id.equals(componentId)))
        .write(
      ComponentsCompanion(
        removedAt: const Value(null),
        installedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await _garage.touchLocalSync();
  }

  BikeComponent _toDomain(ComponentRow row) {
    Map<String, dynamic> attrs = {};
    try {
      final decoded = jsonDecode(row.attributesJson);
      if (decoded is Map) attrs = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return BikeComponent(
      id: row.id,
      bikeId: row.bikeId,
      slot: ComponentSlotLabel.fromApiId(row.slot) ?? ComponentSlot.other,
      manufacturer: row.manufacturer,
      model: row.model,
      catalogModelId: row.catalogModelId,
      installedAt: row.installedAt,
      removedAt: row.removedAt,
      odometerKm: row.odometerKm,
      hoursAtInstall: attrs[BikeComponent.hoursAtInstallAttr] is num
          ? (attrs[BikeComponent.hoursAtInstallAttr] as num).toDouble()
          : null,
      attributes: attrs,
    );
  }
}
