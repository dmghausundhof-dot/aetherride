import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../data/catalog/catalog_client.dart';
import '../data/local/app_database.dart';
import '../data/local/component_repository.dart';
import '../data/local/garage_repository.dart';
import '../data/local/ride_chunk_repository.dart';
import '../data/local/ride_repository.dart';
import '../data/local/setup_repository.dart';
import '../data/local/user_profile_store.dart';
import '../data/routing/route_repository.dart';
import '../data/sync/sync_engine.dart';
import '../data/weather/weather_client.dart';
import '../domain/bike.dart';
import '../domain/component.dart';
import '../domain/ride.dart';
import '../domain/rider_profile.dart';
import '../domain/saved_route.dart';
import '../domain/setup.dart';
import '../native/ble_core_channel.dart';
import '../native/location_core_channel.dart';
import '../native/sensor_core_channel.dart';
import 'ride_providers.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final userProfileStoreProvider = Provider<UserProfileStore>((ref) {
  return UserProfileStore();
});

final weatherClientProvider = Provider<WeatherClient>((ref) => WeatherClient());

final riderProfileProvider = FutureProvider<RiderProfile>((ref) async {
  final store = ref.watch(userProfileStoreProvider);
  await store.load();
  return store.riderProfile;
});

final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  final garage = GarageRepository(ref.watch(appDatabaseProvider));
  garage.profileStore = ref.watch(userProfileStoreProvider);
  if (AppConfig.forcePro) {
    garage.subscriptionTier = 'pro';
  }
  return garage;
});

final componentRepositoryProvider = Provider<ComponentRepository>((ref) {
  return ComponentRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(garageRepositoryProvider),
  );
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(garageRepositoryProvider),
  );
});

final rideChunkRepositoryProvider = Provider<RideChunkRepository>((ref) {
  return RideChunkRepository(ref.watch(appDatabaseProvider));
});

final catalogClientProvider = Provider<CatalogClient>((ref) {
  return CatalogClient(ref.watch(appDatabaseProvider));
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(ref.watch(appDatabaseProvider));
});

final savedRoutesProvider = FutureProvider<List<SavedRouteEntry>>((ref) {
  return ref.watch(routeRepositoryProvider).listSaved();
});

final bikesProvider = FutureProvider<List<Bike>>((ref) {
  return ref.watch(garageRepositoryProvider).listBikes();
});

final recentRidesProvider = FutureProvider<List<RideRecord>>((ref) {
  return ref.watch(rideRepositoryProvider).listRides(limit: 20);
});

final bikeComponentsProvider =
    FutureProvider.family<List<BikeComponent>, String>((ref, bikeId) {
  return ref.watch(componentRepositoryProvider).listInstalled(bikeId);
});

final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  return SetupRepository(ref.watch(appDatabaseProvider));
});

final currentSetupProvider =
    FutureProvider.family<BikeSetup?, String>((ref, bikeId) {
  return ref.watch(setupRepositoryProvider).getCurrent(bikeId);
});

/// 'free' | 'pro' — from sync payload when present.
/// Debug/Test: [AppConfig.forcePro] hält den Tarif dauerhaft auf Pro.
final subscriptionTierProvider = StateProvider<String>((ref) {
  return AppConfig.forcePro ? 'pro' : 'free';
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final garage = ref.watch(garageRepositoryProvider);
  if (AppConfig.forcePro) {
    garage.subscriptionTier = 'pro';
  }
  final engine = SyncEngine(
    db: ref.watch(appDatabaseProvider),
    garage: garage,
    rideChunks: ref.watch(rideChunkRepositoryProvider),
    onSynced: (merged) {
      if (AppConfig.forcePro) {
        ref.read(subscriptionTierProvider.notifier).state = 'pro';
        garage.subscriptionTier = 'pro';
        return;
      }
      final tier = merged.subscriptionTier;
      if (tier == 'pro' || tier == 'free') {
        ref.read(subscriptionTierProvider.notifier).state = tier!;
        garage.subscriptionTier = tier;
      }
    },
    onAuthStatus: (status) {
      ref.read(syncAuthStatusProvider.notifier).state = status;
    },
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
  try {
    final client = Supabase.instance.client;
    return client.auth.onAuthStateChange.map((e) => e.session);
  } catch (_) {
    // Supabase noch nicht initialisiert (Boot läuft async).
    return Stream.value(null);
  }
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
