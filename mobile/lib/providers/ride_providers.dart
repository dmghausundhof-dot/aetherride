import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/active_route.dart';
import '../domain/bike.dart';
import '../data/sync/sync_engine.dart' show SyncAuthStatus;

export '../data/sync/sync_engine.dart' show SyncAuthStatus;

final activeRouteProvider = StateProvider<ActiveRoute?>((ref) => null);

/// Discover-Einstieg von Home: einmalig in DiscoverScreen konsumieren.
/// Discover ist der Normalzustand; `plan` öffnet zusätzlich das Planen-Panel.
/// Früher gab es hier drei Werte für drei Tabs — „quick" und „tours" sind
/// dasselbe geworden, seit Discover eine Liste ist.
enum DiscoverLaunchMode { discover, plan }

final discoverLaunchModeProvider =
    StateProvider<DiscoverLaunchMode?>((ref) => null);

final syncAuthStatusProvider =
    StateProvider<SyncAuthStatus>((ref) => SyncAuthStatus.unknown);

final isRidingProvider = StateProvider<bool>((ref) => false);

final isPausedProvider = StateProvider<bool>((ref) => false);

/// null = noch nicht aus Store geladen; false = Overlay zeigen.
final onboardingDoneProvider = StateProvider<bool?>((ref) => null);

/// Ride-Tab: einmalig Freeride starten (nach Onboarding).
final rideAutostartProvider = StateProvider<bool>((ref) => false);

/// Garage: Add-Sheet öffnen, sobald der Tab gemountet ist.
final garageOpenAddPendingProvider = StateProvider<bool>((ref) => false);

/// Kategorie-Vorbefüllung für Garage-Add aus Onboarding.
final garageAddCategoryProvider = StateProvider<BikeCategory?>((ref) => null);

final rideLayerProvider =
    StateProvider<RideLiveLayer>((ref) => RideLiveLayer.map);

final mountCheckProvider =
    StateProvider<MountCheck>((ref) => MountCheck.unknown);

final sunlightModeProvider = StateProvider<bool>((ref) => false);

final autoLockedProvider = StateProvider<bool>((ref) => false);

final rideElapsedSecProvider = StateProvider<int>((ref) => 0);

final rideDistanceMProvider = StateProvider<double>((ref) => 0);
