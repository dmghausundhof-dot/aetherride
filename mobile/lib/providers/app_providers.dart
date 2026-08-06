import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/garage_repository.dart';
import '../data/sync/sync_engine.dart';
import '../domain/bike.dart';
import '../native/ble_core_channel.dart';
import '../native/sensor_core_channel.dart';

final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  return GarageRepository();
});

final bikesProvider = FutureProvider<List<Bike>>((ref) {
  return ref.watch(garageRepositoryProvider).listBikes();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine();
  ref.onDispose(engine.stop);
  return engine;
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

/// Aktiver Bottom-Tab-Index (0 Home … 4 Shop).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);
