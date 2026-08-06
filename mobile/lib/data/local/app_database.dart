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
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

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

class Setups extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId => text()();
  TextColumn get label => text()();
  TextColumn get valuesJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get immutable => boolean().withDefault(const Constant(true))();

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
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
