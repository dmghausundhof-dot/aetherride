/// Mid-ride connectivity honesty (N-03 / N-08).
///
/// Map offline ≠ route offline ≠ live ORS. Graph A→B and splice-rejoin
/// can run without net; the chip never says „Reroute offline“.
/// Overview PMTiles (z0–11) are not a ride map — TBT still works from geometry.
///
/// - online → [ConnectivityChipState.live] (hidden in Clean Mode)
/// - [ConnectivityChipState.routeOffline] when *offline* + local route geometry
/// - Chip string for street-HUD offline: `Offline · Straßenkarte · Reroute: Netz`
/// - Graph without a loaded route: [ConnectivityChipState.routingOffline]
enum ConnectivityChipState {
  /// Online — quiet trust; optional label „Live“ (hidden in Clean).
  live,

  /// Offline + Stage A: active route geometry is local (TBT ohne Netz).
  routeOffline,

  /// Offline; local street HUD; auto-replan needs net (no / freeride geometry).
  offlineMapOk,

  /// Offline; routing graph active; street map still needs net.
  routingOffline,

  /// Offline and no usable street HUD, graph, or loaded route.
  mapsMissing,
}

/// Resolve chip state from live signals. Pure / testable.
ConnectivityChipState resolveConnectivityChip({
  required bool online,
  required bool hasRouteGeometry,
  required bool offlineMapAvailable,
  bool offlineRoutingReady = false,
}) {
  if (online) {
    return ConnectivityChipState.live;
  }
  if (hasRouteGeometry) {
    return ConnectivityChipState.routeOffline;
  }
  if (offlineRoutingReady) {
    return ConnectivityChipState.routingOffline;
  }
  if (offlineMapAvailable) {
    return ConnectivityChipState.offlineMapOk;
  }
  return ConnectivityChipState.mapsMissing;
}

/// German UI labels — calm, honest, glanceable (UX-locked strings).
String connectivityChipLabel(
  ConnectivityChipState state, {
  bool mapHintVisible = false,
}) {
  return switch (state) {
    ConnectivityChipState.live => 'Live',
    ConnectivityChipState.routeOffline => 'Route offline',
    ConnectivityChipState.offlineMapOk =>
      'Offline · Straßenkarte · Reroute: Netz',
    ConnectivityChipState.routingOffline =>
      mapHintVisible ? 'Routing offline' : 'Routing offline · Karte: Netz',
    ConnectivityChipState.mapsMissing => 'Karten fehlen',
  };
}

/// Offline toast when user tries / would auto-replan without net (UX Spec).
const String kOfflineRerouteToast =
    'Reroute braucht Internet. Auf der geladenen Route bleiben.';

/// Whether the chip is worth showing in Clean Mode (hide quiet Live).
bool connectivityChipVisibleInClean(ConnectivityChipState state) {
  return state != ConnectivityChipState.live;
}

/// Canvas / puck already says the street map needs net — drop chips that
/// only repeat that. „Route offline“ stays (TBT is a different fact).
bool connectivityChipVisibleBesideMapHint({
  required ConnectivityChipState state,
  required bool mapHintVisible,
}) {
  if (!mapHintVisible) return true;
  return state != ConnectivityChipState.mapsMissing &&
      state != ConnectivityChipState.routingOffline;
}
