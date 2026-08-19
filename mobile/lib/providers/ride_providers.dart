import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/active_route.dart';
import '../domain/bike.dart';
import '../domain/routing/tour_filters.dart';
import '../data/sync/sync_engine.dart' show SyncAuthStatus;

export '../data/sync/sync_engine.dart' show SyncAuthStatus;

final activeRouteProvider = StateProvider<ActiveRoute?>((ref) => null);

/// Discover-Einstieg: einmalig in DiscoverScreen konsumieren.
/// `discover` ist Browse (Deep-Link). `plan` öffnet das Planen-Panel.
/// `rideOut` ist Losfahren: direkt HUD (Hof-CTA). `mine` ist Tafel → Touren.
enum DiscoverLaunchMode { discover, plan, rideOut, mine }

final discoverLaunchModeProvider =
    StateProvider<DiscoverLaunchMode?>((ref) => null);

/// Deep-Link: Discover mit Loop-Highlight (`?loop=<id>` ohne start=1).
final discoverPendingLoopIdProvider = StateProvider<String?>((ref) => null);

/// Hof-Tafel → Karte in „Touren“.
final discoverPendingMineProvider = StateProvider<bool>((ref) => false);

/// Sichtbarkeit der eigenen Touren — dieselbe Quelle für Tab und Karte.
final tourVisibilityProvider =
    StateProvider<TourVisibilityKey>((ref) => TourVisibilityKey.allMine);

/// Nach Meine: diese SavedRoute-Akte öffnen (Post-Ride / Tafel-Stimmen).
final discoverPendingAkteRouteIdProvider = StateProvider<String?>((ref) => null);

/// Deep-Link Dauer-Lens (`?lens=60`).
final discoverPendingLensMinutesProvider = StateProvider<int?>((ref) => null);

/// Deep-Link / App-Link: Platz-Gruppe beitreten (`?group=` / `?code=` + optional `g=`).
class PlatzPendingJoin {
  const PlatzPendingJoin({required this.code, this.token});

  final String code;
  final String? token;
}

final platzPendingJoinProvider = StateProvider<PlatzPendingJoin?>((ref) => null);

/// Akte / Karte → Touren legt eine Gruppe an dieser Strecke an.
final platzPendingCreateGroupRouteIdProvider =
    StateProvider<String?>((ref) => null);

/// „Eigene Tour als Gruppe planen“: nach Merken auf dem Platz den Create-Flow öffnen.
final platzPendingPlanAsGroupProvider = StateProvider<bool>((ref) => false);

/// Platz-Gruppenkarte → Karte startet dieselbe Tour.
final discoverPendingStartRideRouteIdProvider =
    StateProvider<String?>((ref) => null);

/// Losfahren aus der Gruppe — HUD dockt an diese Id, auch wenn die
/// ActiveRoute eine lokale Mappe-Kopie ist.
final ridePendingGroupIdProvider = StateProvider<String?>((ref) => null);

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

/// Shop: Produktakte öffnen (`/shop/p/{handle}` / `?handle=`).
final shopPendingHandleProvider = StateProvider<String?>((ref) => null);

/// Shop: nur Teile mit ehrlichem Garage-Fit (`fit=bike` / Werkstatt).
final shopPendingFitOnlyProvider = StateProvider<bool?>((ref) => null);

/// Shop-Gateway als Route pushen (kein Tab). Einmalig konsumieren.
final shopOpenRouteProvider = StateProvider<bool>((ref) => false);

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
