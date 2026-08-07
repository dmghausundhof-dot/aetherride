import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../data/local/app_database.dart';
import '../data/local/garage_repository.dart';
import '../data/sync/sync_engine.dart';
import '../domain/bike.dart';
import '../native/ble_core_channel.dart';
import '../native/location_core_channel.dart';
import '../native/sensor_core_channel.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  return GarageRepository(ref.watch(appDatabaseProvider));
});

final bikesProvider = FutureProvider<List<Bike>>((ref) {
  return ref.watch(garageRepositoryProvider).listBikes();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(appDatabaseProvider),
    garage: ref.watch(garageRepositoryProvider),
  );
  ref.onDispose(engine.stop);
  return engine;
});

final supabaseReadyProvider = Provider<bool>((ref) {
  return AppConfig.isSupabaseConfigured;
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  if (!AppConfig.isSupabaseConfigured) {
    return Stream.value(null);
  }
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((e) => e.session);
});

final sensorCoreProvider = Provider<SensorCoreChannel>((ref) {
  final channel = SensorCoreChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

final bleCoreProvider = Provider<BleCoreChannel>((ref) {
  final channel = BleCoreChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

final locationCoreProvider = Provider<LocationCoreChannel>((ref) {
  final channel = LocationCoreChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

/// Aktiver Bottom-Tab-Index (0 Home … 4 Shop).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);
