import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('BikeRow')
class Bikes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get wheelSize => text().nullable()();
  RealColumn get odometerKm => real().withDefault(const Constant(0.0))();
  RealColumn get hours => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ComponentRow')
class Components extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId => text()();
  TextColumn get slot => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get catalogModelId => text().nullable()();
  DateTimeColumn get installedAt => dateTime().nullable()();
  DateTimeColumn get removedAt => dateTime().nullable()();
  RealColumn get odometerKm => real().withDefault(const Constant(0.0))();
  TextColumn get attributesJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SetupRow')
class Setups extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId => text()();
  TextColumn get label => text()();
  TextColumn get valuesJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get immutable => boolean().withDefault(const Constant(true))();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  TextColumn get conditions => text().withDefault(const Constant('general'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get parentSetupId => text().nullable()();
  TextColumn get linkedRideId => text().nullable()();
  TextColumn get createdBy => text().withDefault(const Constant('user'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Rides extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get distanceKm => real().withDefault(const Constant(0.0))();
  IntColumn get movingTimeSec => integer().withDefault(const Constant(0))();
  RealColumn get elevationM => real().withDefault(const Constant(0.0))();
  TextColumn get name => text().nullable()();
  TextColumn get routeId => text().nullable()();
  TextColumn get trackJson => text().withDefault(const Constant('[]'))();
  TextColumn get feedbackJson => text().nullable()();
  TextColumn get summaryJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}

class RideChunksMeta extends Table {
  TextColumn get id => text()();
  TextColumn get rideId => text()();
  IntColumn get seq => integer()();
  DateTimeColumn get windowStart => dateTime()();
  DateTimeColumn get windowEnd => dateTime()();
  TextColumn get localPath => text().nullable()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();
  TextColumn get remotePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Consents extends Table {
  TextColumn get id => text()();
  TextColumn get key => text()();
  BoolColumn get granted => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get remoteUpdatedAt => text().nullable()();
  TextColumn get localUpdatedAt => text().nullable()();
  TextColumn get lastDirection => text().nullable()();
  IntColumn get payloadVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class CatalogCache extends Table {
  TextColumn get id => text()();
  TextColumn get slot => text()();
  TextColumn get manufacturer => text()();
  TextColumn get model => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persistierte Discover-Library (Geometry + Waypoints + Layer-Parts).
class SavedRoutes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get distanceKm => real()();
  RealColumn get elevationM => real()();
  IntColumn get durationMin => integer()();
  TextColumn get source => text().withDefault(const Constant('engine'))();
  TextColumn get geometryJson => text().nullable()();
  TextColumn get waypointsJson => text().withDefault(const Constant('[]'))();
  TextColumn get layersJson => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline-First Cache für zuletzt berechnete A–B-Routen.
class RouteCache extends Table {
  TextColumn get id => text()();
  TextColumn get cacheKey => text()();
  TextColumn get profile => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// F-ACC-005 Privatsphärenzonen (lat/lng/radius).
@DataClassName('PrivacyZoneRow')
class PrivacyZones extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get radiusM => real().withDefault(const Constant(200.0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Bikes,
    Components,
    Setups,
    Rides,
    RideChunksMeta,
    Consents,
    SyncState,
    CatalogCache,
    SavedRoutes,
    RouteCache,
    PrivacyZones,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(savedRoutes);
            await m.createTable(routeCache);
          }
          if (from < 3) {
            await m.addColumn(rides, rides.elevationM);
            await m.addColumn(rides, rides.name);
            await m.addColumn(rides, rides.routeId);
            await m.addColumn(rides, rides.trackJson);
            await m.addColumn(rides, rides.feedbackJson);
            try {
              await m.addColumn(bikes, bikes.isActive);
            } catch (_) {}
          }
          if (from < 4) {
            await m.addColumn(bikes, bikes.hours);
            await m.addColumn(setups, setups.isCurrent);
            await m.addColumn(setups, setups.conditions);
            await m.addColumn(setups, setups.version);
            await m.addColumn(setups, setups.parentSetupId);
            await m.addColumn(setups, setups.linkedRideId);
            await m.addColumn(setups, setups.createdBy);
          }
          if (from < 5) {
            await m.createTable(privacyZones);
          }
          if (from < 6) {
            await m.addColumn(rideChunksMeta, rideChunksMeta.uploadedAt);
            await m.addColumn(rideChunksMeta, rideChunksMeta.remotePath);
          }
        },
      );

  /// Löscht alle Zeilen (Konto löschen / lokaler Wipe).
  Future<void> clearAllTables() async {
    await transaction(() async {
      await delete(rideChunksMeta).go();
      await delete(rides).go();
      await delete(setups).go();
      await delete(components).go();
      await delete(bikes).go();
      await delete(consents).go();
      await delete(privacyZones).go();
      await delete(savedRoutes).go();
      await delete(routeCache).go();
      await delete(catalogCache).go();
      await delete(syncState).go();
    });
  }
}

/// Absolute path to the on-disk SQLite file (for wipe / delete account).
Future<String> appDatabaseFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'aetherride.sqlite');
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'aetherride.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// In-memory DB for tests.
AppDatabase createMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
