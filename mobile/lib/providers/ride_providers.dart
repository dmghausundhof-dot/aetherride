import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/active_route.dart';
import '../data/sync/sync_engine.dart' show SyncAuthStatus;

export '../data/sync/sync_engine.dart' show SyncAuthStatus;

final activeRouteProvider = StateProvider<ActiveRoute?>((ref) => null);

/// Discover-Einstieg von Home: einmalig in DiscoverScreen konsumieren.
enum DiscoverLaunchMode { quick, plan, tours }

final discoverLaunchModeProvider =
    StateProvider<DiscoverLaunchMode?>((ref) => null);

final syncAuthStatusProvider =
    StateProvider<SyncAuthStatus>((ref) => SyncAuthStatus.unknown);

final isRidingProvider = StateProvider<bool>((ref) => false);

final isPausedProvider = StateProvider<bool>((ref) => false);

final rideLayerProvider =
    StateProvider<RideLiveLayer>((ref) => RideLiveLayer.map);

final mountCheckProvider =
    StateProvider<MountCheck>((ref) => MountCheck.unknown);

final sunlightModeProvider = StateProvider<bool>((ref) => false);

final autoLockedProvider = StateProvider<bool>((ref) => false);

final rideElapsedSecProvider = StateProvider<int>((ref) => 0);

final rideDistanceMProvider = StateProvider<double>((ref) => 0);
