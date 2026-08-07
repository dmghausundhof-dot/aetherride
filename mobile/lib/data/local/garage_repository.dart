import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/bike.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/privacy/track_trim.dart';
import '../../domain/rider_profile.dart';
import '../../domain/setup.dart';
import '../sync/sync_payload.dart';
import 'app_database.dart';
import 'setup_repository.dart';
import 'user_profile_store.dart';

/// Offline-First: UI liest ausschließlich aus Drift.
class GarageRepository {
  GarageRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Optional profile/family store for SyncPayload.
  UserProfileStore? profileStore;

  /// Local flag: free tier user added a 2nd bike (still allowed offline).
  bool freeTierExtraBike = false;
  String subscriptionTier = 'free';

  Future<List<Bike>> listBikes() async {
    final rows = await _db.select(_db.bikes).get();
    return rows.map(_toDomain).toList();
  }

  Future<Bike?> getById(String id) async {
    final row = await (_db.select(_db.bikes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<Bike?> getActiveBike() async {
    final row = await (_db.select(_db.bikes)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
    if (row != null) return _toDomain(row);
    final all = await listBikes();
    return all.isEmpty ? null : all.first;
  }

  Future<Bike> addBikeBasic({
    required String name,
    required BikeCategory category,
    String? brand,
    String? model,
    int? year,
    WheelSize? wheelSize,
    bool makeActive = true,
  }) async {
    final existing = await listBikes();
    if (existing.isNotEmpty && subscriptionTier != 'pro') {
      freeTierExtraBike = true;
    }
    final id = _uuid.v4();
    final bike = Bike(
      id: id,
      name: name.trim().isEmpty ? 'Mein Bike' : name.trim(),
      category: category,
      brand: brand?.trim().isEmpty == true ? null : brand?.trim(),
      model: model?.trim().isEmpty == true ? null : model?.trim(),
      year: year,
      wheelSize: wheelSize,
      isActive: makeActive || existing.isEmpty,
    );
    await upsert(bike);
    if (bike.isActive) await setActiveBike(id);
    return bike;
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
            hours: Value(bike.hours),
            isActive: Value(bike.isActive),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    await touchLocalSync();
  }

  Future<void> deleteBike(String id) async {
    await (_db.delete(_db.bikes)..where((t) => t.id.equals(id))).go();
    await (_db.delete(_db.components)..where((t) => t.bikeId.equals(id))).go();
    await (_db.delete(_db.setups)..where((t) => t.bikeId.equals(id))).go();
    final remaining = await listBikes();
    if (remaining.isNotEmpty && !remaining.any((b) => b.isActive)) {
      await setActiveBike(remaining.first.id);
    }
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

  Future<void> addOdometer({
    required String bikeId,
    required double distanceKm,
    required double hours,
  }) async {
    final bike = await getById(bikeId);
    if (bike == null) return;
    await upsert(
      bike.copyWith(
        odometerKm: bike.odometerKm + distanceKm,
        hours: bike.hours + hours,
      ),
    );
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
        hours: 28,
        isActive: true,
      ),
    );
    // Baseline-Setup für Demo-Bike
    await SetupRepository(_db).createVersion(
      bikeId: id,
      label: 'OEM Basis',
      values: BikeSetup.defaultValues(),
      createdBy: 'template',
    );
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
    final components = await _db.select(_db.components).get();
    final setups = await _db.select(_db.setups).get();
    final rides = await _db.select(_db.rides).get();
    final consents = await _db.select(_db.consents).get();
    final zones = await listPrivacyZones();
    final saved = await _db.select(_db.savedRoutes).get();
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
              'hours': b.hours,
              'isActive': b.isActive,
              'components': [
                for (final c in components.where((c) => c.bikeId == b.id))
                  {
                    'id': c.id,
                    'bikeId': c.bikeId,
                    'slot': c.slot,
                    'manufacturer': c.manufacturer,
                    'model': c.model,
                    'catalogModelId': c.catalogModelId,
                    'installedAt': c.installedAt?.toIso8601String(),
                    'removedAt': c.removedAt?.toIso8601String(),
                    'odometerKm': c.odometerKm,
                    'attributes': jsonDecode(c.attributesJson),
                  },
              ],
              'setups': [
                for (final s in setups.where((s) => s.bikeId == b.id))
                  _setupToSyncMap(s),
              ],
            },
          )
          .toList(),
      setups: setups.map(_setupToSyncMap).toList(),
      rides: rides
          .map(
            (r) => {
              'id': r.id,
              'bikeId': r.bikeId,
              'startTime': r.startedAt.toIso8601String(),
              'endTime': r.endedAt?.toIso8601String(),
              'distanceM': r.distanceKm * 1000,
              'elevationGainM': r.elevationM,
              'durationSec': r.movingTimeSec,
              'name': r.name,
              'routeId': r.routeId,
              'track': () {
                final raw = jsonDecode(r.trackJson);
                if (raw is! List) return <dynamic>[];
                final track = [
                  for (final e in raw)
                    if (e is Map) Map<String, dynamic>.from(e),
                ];
                return trimTrackForPrivacyZones(track, zones);
              }(),
              'feedback': _parseFeedbackJson(r.feedbackJson),
              'notes': r.feedbackJson,
              'summaryMetrics': jsonDecode(r.summaryJson),
            },
          )
          .toList(),
      consents: [
        for (final c in consents)
          {
            'purpose': c.key,
            'granted': c.granted,
            'updatedAt': c.updatedAt.toIso8601String(),
            'policyVersion': '1.0',
          },
      ],
      privacyZones: zones.map((z) => z.toJson()).toList(),
      savedRoutes: [
        for (final s in saved)
          {
            'id': s.id,
            'name': s.name,
            'distanceKm': s.distanceKm,
            'elevationM': s.elevationM,
            'durationMin': s.durationMin,
            'source': s.source,
            'geometry': s.geometryJson == null
                ? null
                : jsonDecode(s.geometryJson!),
            'waypoints': jsonDecode(s.waypointsJson),
            'layers': s.layersJson == null ? null : jsonDecode(s.layersJson!),
            'savedAt': s.savedAt.toIso8601String(),
          },
      ],
      subscriptionTier: subscriptionTier,
      freeTierExtraBike: freeTierExtraBike ? true : null,
      activeBikeId: active,
      riderProfile: profileStore?.riderProfile.toJson(),
      familyRiders: profileStore == null
          ? null
          : [for (final r in profileStore!.familyRiders) r.toJson()],
      commerceMode: profileStore?.commerceMode,
      updatedAt: state?.localUpdatedAt,
      payloadVersion: state?.payloadVersion ?? 1,
    );
  }

  /// Prefer structured feedback object; keep plain string as notes fallback.
  dynamic _parseFeedbackJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map || decoded is List) return decoded;
    } catch (_) {}
    return raw;
  }

  Map<String, dynamic> _setupToSyncMap(SetupRow s) {
    return {
      'id': s.id,
      'bikeId': s.bikeId,
      'label': s.label,
      'values': jsonDecode(s.valuesJson),
      'createdAt': s.createdAt.toIso8601String(),
      'immutable': s.immutable,
      'isCurrent': s.isCurrent,
      'conditions': s.conditions,
      'version': s.version,
      'parentSetupId': s.parentSetupId,
      'linkedRideId': s.linkedRideId,
      'createdBy': s.createdBy,
    };
  }

  Future<void> setConsent({
    required String purpose,
    required bool granted,
  }) async {
    final existing = await (_db.select(_db.consents)
          ..where((t) => t.key.equals(purpose)))
        .getSingleOrNull();
    final id = existing?.id ?? _uuid.v4();
    await _db.into(_db.consents).insertOnConflictUpdate(
          ConsentsCompanion.insert(
            id: id,
            key: purpose,
            granted: granted,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    await touchLocalSync();
  }

  Future<Map<String, bool>> listConsents() async {
    final rows = await _db.select(_db.consents).get();
    return {for (final c in rows) c.key: c.granted};
  }

  Future<List<PrivacyZone>> listPrivacyZones() async {
    final rows = await _db.select(_db.privacyZones).get();
    return [
      for (final r in rows)
        PrivacyZone(
          id: r.id,
          label: r.label,
          lat: r.lat,
          lng: r.lng,
          radiusM: r.radiusM,
        ),
    ];
  }

  Future<void> savePrivacyZones(List<PrivacyZone> zones) async {
    await _db.transaction(() async {
      await _db.delete(_db.privacyZones).go();
      for (final z in zones) {
        await _db.into(_db.privacyZones).insertOnConflictUpdate(
              PrivacyZonesCompanion.insert(
                id: z.id,
                label: z.label,
                lat: z.lat,
                lng: z.lng,
                radiusM: Value(z.radiusM),
                updatedAt: DateTime.now().toUtc(),
              ),
            );
      }
    });
    await touchLocalSync();
  }

  Future<void> upsertPrivacyZone(PrivacyZone zone) async {
    await _db.into(_db.privacyZones).insertOnConflictUpdate(
          PrivacyZonesCompanion.insert(
            id: zone.id,
            label: zone.label,
            lat: zone.lat,
            lng: zone.lng,
            radiusM: Value(zone.radiusM),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    await touchLocalSync();
  }

  Future<void> removePrivacyZone(String id) async {
    await (_db.delete(_db.privacyZones)..where((t) => t.id.equals(id))).go();
    await touchLocalSync();
  }

  Future<void> wipeLocalData() async {
    await _db.clearAllTables();
    freeTierExtraBike = false;
    subscriptionTier = 'free';
    await profileStore?.clear();
  }

  Future<void> applyRemotePayload(SyncPayload payload) async {
    if (payload.subscriptionTier == 'pro' ||
        payload.subscriptionTier == 'free') {
      subscriptionTier = payload.subscriptionTier!;
    }
    if (payload.freeTierExtraBike == true) {
      freeTierExtraBike = true;
    }
    final store = profileStore;
    if (store != null) {
      await store.load();
      if (payload.riderProfile is Map) {
        store.riderProfile = RiderProfile.fromJson(
          Map<String, dynamic>.from(payload.riderProfile as Map),
        );
      }
      if (payload.familyRiders is List) {
        store.familyRiders = [
          for (final e in payload.familyRiders as List)
            if (e is Map)
              FamilyRider.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
      final cm = payload.commerceMode;
      if (cm is String && (cm == 'affiliate' || cm == 'marketplace')) {
        store.commerceMode = cm;
      }
      await store.save();
    }
    final setupRepo = SetupRepository(_db);
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
                  hours: Value((m['hours'] as num?)?.toDouble() ?? 0),
                  isActive: Value(m['isActive'] == true),
                  updatedAt: DateTime.now().toUtc(),
                ),
              );
          final comps = m['components'];
          if (comps is List) {
            for (final rawC in comps) {
              if (rawC is! Map) continue;
              final c = Map<String, dynamic>.from(rawC);
              final cid = c['id'] as String?;
              if (cid == null) continue;
              await _db.into(_db.components).insertOnConflictUpdate(
                    ComponentsCompanion.insert(
                      id: cid,
                      bikeId: id,
                      slot: (c['slot'] as String?) ?? 'other',
                      manufacturer: Value(c['manufacturer'] as String?),
                      model: Value(c['model'] as String?),
                      catalogModelId: Value(c['catalogModelId'] as String?),
                      installedAt: Value(
                        c['installedAt'] != null
                            ? DateTime.tryParse(c['installedAt'] as String)
                            : null,
                      ),
                      removedAt: Value(
                        c['removedAt'] != null
                            ? DateTime.tryParse(c['removedAt'] as String)
                            : null,
                      ),
                      odometerKm:
                          Value((c['odometerKm'] as num?)?.toDouble() ?? 0),
                      attributesJson: Value(
                        jsonEncode(c['attributes'] ?? {}),
                      ),
                      updatedAt: DateTime.now().toUtc(),
                    ),
                  );
            }
          }
          // Web nestet setups unter bikes.
          final nested = m['setups'];
          if (nested is List) {
            for (final rawS in nested) {
              if (rawS is! Map) continue;
              final sm = Map<String, dynamic>.from(rawS);
              sm.putIfAbsent('bikeId', () => id);
              await setupRepo.upsertFromSync(sm);
            }
          }
        }
      }

      if (payload.setups is List) {
        for (final raw in payload.setups as List) {
          if (raw is! Map) continue;
          await setupRepo.upsertFromSync(Map<String, dynamic>.from(raw));
        }
      }

      if (payload.rides is List) {
        for (final raw in payload.rides as List) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final id = m['id'] as String?;
          final bikeId = m['bikeId'] as String?;
          if (id == null || bikeId == null) continue;
          final start = DateTime.tryParse(
                (m['startTime'] as String?) ??
                    (m['startedAt'] as String?) ??
                    '',
              ) ??
              DateTime.now().toUtc();
          final endRaw = (m['endTime'] as String?) ?? (m['endedAt'] as String?);
          final distanceM = (m['distanceM'] as num?)?.toDouble();
          final distanceKm = distanceM != null
              ? distanceM / 1000
              : (m['distanceKm'] as num?)?.toDouble() ?? 0;
          await _db.into(_db.rides).insertOnConflictUpdate(
                RidesCompanion.insert(
                  id: id,
                  bikeId: bikeId,
                  startedAt: start,
                  endedAt: Value(
                    endRaw != null ? DateTime.tryParse(endRaw) : null,
                  ),
                  distanceKm: Value(distanceKm),
                  movingTimeSec: Value(
                    (m['durationSec'] as num?)?.toInt() ??
                        (m['movingTimeSec'] as num?)?.toInt() ??
                        0,
                  ),
                  elevationM: Value(
                    (m['elevationGainM'] as num?)?.toDouble() ??
                        (m['elevationM'] as num?)?.toDouble() ??
                        0,
                  ),
                  name: Value(m['name'] as String?),
                  routeId: Value(m['routeId'] as String?),
                  trackJson: Value(jsonEncode(m['track'] ?? [])),
                  feedbackJson: Value(
                    m['feedback'] != null
                        ? jsonEncode(m['feedback'])
                        : m['notes'] as String?,
                  ),
                  summaryJson: Value(
                    jsonEncode(m['summaryMetrics'] ?? m['summary'] ?? {}),
                  ),
                ),
              );
        }
      }

      await _applyConsents(payload.consents);
      await _applyPrivacyZones(payload.privacyZones);
      await _applySavedRoutes(payload.savedRoutes);

      if (payload.activeBikeId is String) {
        final aid = payload.activeBikeId as String;
        final exists = await getById(aid);
        if (exists != null) {
          await _db.update(_db.bikes).write(
                const BikesCompanion(isActive: Value(false)),
              );
          await (_db.update(_db.bikes)..where((t) => t.id.equals(aid))).write(
                const BikesCompanion(isActive: Value(true)),
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

  Future<void> _applyPrivacyZones(dynamic raw) async {
    if (raw is! List) return;
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final id = m['id'] as String?;
      if (id == null) continue;
      await _db.into(_db.privacyZones).insertOnConflictUpdate(
            PrivacyZonesCompanion.insert(
              id: id,
              label: (m['label'] as String?) ?? 'Zone',
              lat: (m['lat'] as num?)?.toDouble() ?? 0,
              lng: (m['lng'] as num?)?.toDouble() ?? 0,
              radiusM: Value((m['radiusM'] as num?)?.toDouble() ?? 200),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    }
  }

  Future<void> _applySavedRoutes(dynamic raw) async {
    if (raw is! List) return;
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final id = m['id'] as String?;
      if (id == null) continue;
      await _db.into(_db.savedRoutes).insertOnConflictUpdate(
            SavedRoutesCompanion.insert(
              id: id,
              name: (m['name'] as String?) ?? 'Route',
              distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
              elevationM: (m['elevationM'] as num?)?.toDouble() ?? 0,
              durationMin: (m['durationMin'] as num?)?.toInt() ?? 0,
              source: Value((m['source'] as String?) ?? 'engine'),
              geometryJson: Value(
                m['geometry'] != null ? jsonEncode(m['geometry']) : null,
              ),
              waypointsJson: Value(
                jsonEncode(m['waypoints'] ?? []),
              ),
              layersJson: Value(
                m['layers'] != null ? jsonEncode(m['layers']) : null,
              ),
              savedAt: DateTime.tryParse(m['savedAt'] as String? ?? '') ??
                  DateTime.now().toUtc(),
            ),
          );
    }
  }

  Future<void> _applyConsents(dynamic raw) async {
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final purpose = (m['purpose'] as String?) ?? (m['key'] as String?);
        if (purpose == null) continue;
        final granted = m['granted'] == true;
        final existing = await (_db.select(_db.consents)
              ..where((t) => t.key.equals(purpose)))
            .getSingleOrNull();
        await _db.into(_db.consents).insertOnConflictUpdate(
              ConsentsCompanion.insert(
                id: existing?.id ?? _uuid.v4(),
                key: purpose,
                granted: granted,
                updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
                    DateTime.now().toUtc(),
              ),
            );
      }
    } else if (raw is Map) {
      for (final e in raw.entries) {
        final purpose = e.key.toString();
        final granted = e.value == true;
        final existing = await (_db.select(_db.consents)
              ..where((t) => t.key.equals(purpose)))
            .getSingleOrNull();
        await _db.into(_db.consents).insertOnConflictUpdate(
              ConsentsCompanion.insert(
                id: existing?.id ?? _uuid.v4(),
                key: purpose,
                granted: granted,
                updatedAt: DateTime.now().toUtc(),
              ),
            );
      }
    }
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
      hours: row.hours,
      isActive: row.isActive,
    );
  }
}
