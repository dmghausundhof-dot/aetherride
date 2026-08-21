import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../data/catalog/catalog_client.dart';
import '../data/community/ride_group_store.dart';
import '../data/community/tour_community_store.dart';
import '../data/local/app_database.dart';
import '../data/local/component_repository.dart';
import '../data/local/garage_repository.dart';
import '../data/local/ride_chunk_repository.dart';
import '../data/local/ride_repository.dart';
import '../data/local/setup_repository.dart';
import '../data/local/user_profile_store.dart';
import '../data/routing/route_repository.dart';
import '../data/routing/saved_route_meta_store.dart';
import '../data/sensor/bike_ble_store.dart';
import '../data/sync/sync_engine.dart';
import '../data/weather/weather_client.dart';
import '../domain/ai/coach_inbox.dart';
import '../domain/ai/coach_watch.dart';
import '../domain/bike.dart';
import '../domain/component.dart';
import '../domain/maintenance/intervals.dart';
import '../domain/ride.dart';
import '../domain/rider_profile.dart';
import '../domain/saved_route.dart';
import '../domain/setup.dart';
import '../domain/tours/route_visibility.dart';
import '../domain/tours/tour_listing.dart';
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

/// Fahrer-Kennzahlen fürs Profil (Anzahl Rides, Gesamt-km/-hm).
final rideStatsProvider = FutureProvider<RideStats>((ref) {
  return ref.watch(rideRepositoryProvider).statsSummary();
});

final bikeComponentsProvider =
    FutureProvider.family<List<BikeComponent>, String>((ref, bikeId) {
  return ref.watch(componentRepositoryProvider).listInstalled(bikeId);
});

/// Neue Stimmen auf dem Platz — Pille wie Wartung, ohne Zahl.
final platzInboxBadgeProvider = FutureProvider<int>((ref) async {
  ref.watch(savedRoutesProvider);
  final saved = await ref.watch(savedRoutesProvider.future);
  final metas = await SavedRouteMetaStore.listAll();
  final all = await TourCommunityStore().allReviews();
  final ids = <String>{};
  for (final s in saved) {
    final id = RouteVisibility.stimmenTourIdOf(s.id, metas[s.id]);
    if (id != null) ids.add(id);
  }
  final inbox = [for (final r in all) if (ids.contains(r.tourId)) r];
  final seen = await RideGroupStore().inboxSeen();
  var extra = 0;
  for (final s in saved) {
    final listing = parseListingState(metas[s.id]?.listing);
    if (listing == TourListingState.candidate ||
        listing == TourListingState.reverted) {
      extra++;
    }
  }
  final n = inbox.length + extra - seen;
  return n < 0 ? 0 : n;
});

/// Fällige Wartungen über die ganze Flotte — Badge auf der Werkstatt-Tür.
final fleetDueCountProvider = FutureProvider<int>((ref) async {
  final bikes = await ref.watch(bikesProvider.future);
  final repo = ref.watch(componentRepositoryProvider);
  var n = 0;
  for (final bike in bikes) {
    final comps = await repo.listInstalled(bike.id);
    n += listDueMaintenance(
      bike: bike,
      components: comps,
      logs: ref.read(userProfileStoreProvider).maintenanceLogs,
    ).length;
  }
  return n;
});

final coachWatchProvider = FutureProvider<List<CoachInboxItem>>((ref) async {
  final bikes = await ref.watch(bikesProvider.future);
  final rides = await ref.watch(recentRidesProvider.future);
  final compsRepo = ref.watch(componentRepositoryProvider);
  final setupsRepo = ref.watch(setupRepositoryProvider);
  final store = ref.watch(userProfileStoreProvider);
  await store.load();
  final componentsByBike = <String, List<BikeComponent>>{};
  final setupsByBike = <String, List<BikeSetup>>{};
  for (final b in bikes) {
    componentsByBike[b.id] = await compsRepo.listInstalled(b.id);
    setupsByBike[b.id] = await setupsRepo.listForBike(b.id);
  }
  final notices = buildCoachWatch(
    CoachWatchInput(
      bikes: bikes,
      componentsByBike: componentsByBike,
      rides: rides,
      setupsByBike: setupsByBike,
      calibration: store.rangeCalibration,
    ),
  );
  return mergeCoachInbox(notices, store.coachMeta);
});

final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  return SetupRepository(ref.watch(appDatabaseProvider));
});

final currentSetupProvider =
    FutureProvider.family<BikeSetup?, String>((ref, bikeId) {
  return ref.watch(setupRepositoryProvider).getCurrent(bikeId);
});

/// Alle Versionen — Hof und Rad-Tab brauchen dieselbe Druck/SAG-Wahrheit.
final setupsForBikeProvider =
    FutureProvider.family<List<BikeSetup>, String>((ref, bikeId) async {
  ref.watch(currentSetupProvider(bikeId));
  return ref.watch(setupRepositoryProvider).listForBike(bikeId);
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

/// Gekoppelte BLE-Sensoren je Bike plus rider-level Smartwatch.
final bikeBleStoreProvider = Provider<BikeBleStore>((ref) {
  return BikeBleStore();
});

final locationCoreProvider = Provider<LocationCoreChannel>((ref) {
  final channel = LocationCoreChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

/// Aktiver Bottom-Tab-Index (0 Home … 4 Shop).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);
