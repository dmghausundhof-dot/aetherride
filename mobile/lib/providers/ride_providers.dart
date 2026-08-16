import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/active_route.dart';
import '../domain/bike.dart';
import '../data/sync/sync_engine.dart' show SyncAuthStatus;

export '../data/sync/sync_engine.dart' show SyncAuthStatus;

final activeRouteProvider = StateProvider<ActiveRoute?>((ref) => null);

/// Discover-Einstieg von Home: einmalig in DiscoverScreen konsumieren.
/// Discover ist der Normalzustand; `plan` öffnet zusätzlich das Planen-Panel.
/// `rideOut` ist Rausfahren: Karte mit Wahl Einfach fahren / Touren anzeigen.
enum DiscoverLaunchMode { discover, plan, rideOut }

final discoverLaunchModeProvider =
    StateProvider<DiscoverLaunchMode?>((ref) => null);

/// Deep-Link: Discover mit Loop-Highlight (`?loop=<id>` ohne start=1).
final discoverPendingLoopIdProvider = StateProvider<String?>((ref) => null);

/// Deep-Link Dauer-Lens (`?lens=60`).
final discoverPendingLensMinutesProvider = StateProvider<int?>((ref) => null);

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

/// Garage: Bike-Detail öffnen (Hof „Rad öffnen“).
final garagePendingBikeIdProvider = StateProvider<String?>((ref) => null);

/// Shop: Bike für Garage-Fit, einmalig aus der Werkstatt setzen.
final shopPendingBikeIdProvider = StateProvider<String?>((ref) => null);

/// Shop: Slot-Chip aus Wartung/Werkstatt (`chain`, `tire`, …).
final shopPendingSlotProvider = StateProvider<String?>((ref) => null);

/// Shop: nur Teile mit ehrlichem Garage-Fit (`fit=bike` / Werkstatt).
final shopPendingFitOnlyProvider = StateProvider<bool?>((ref) => null);

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
