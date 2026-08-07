import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/active_route.dart';

final activeRouteProvider = StateProvider<ActiveRoute?>((ref) => null);

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
