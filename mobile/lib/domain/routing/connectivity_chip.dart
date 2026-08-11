/// Mid-ride connectivity honesty (N-03 / N-08).
///
/// Never claims offline reroute. Stage A = route geometry is local (TBT works
/// without net). Map offline ≠ route offline ≠ reroute offline.
enum ConnectivityChipState {
  /// Online — quiet trust; optional label „Live“.
  live,

  /// Stage A: active route geometry is cached locally.
  routeOffline,

  /// No network; basemap/route usable; auto-replan needs net.
  offlineMapOk,

  /// No network and no usable offline basemap.
  mapsMissing,
}

/// Resolve chip state from live signals. Pure / testable.
ConnectivityChipState resolveConnectivityChip({
  required bool online,
  required bool hasRouteGeometry,
  required bool offlineMapAvailable,
}) {
  if (!online) {
    if (!offlineMapAvailable) {
      return ConnectivityChipState.mapsMissing;
    }
    return ConnectivityChipState.offlineMapOk;
  }
  // Online: Stage A trust when route is in memory (always local after load).
  if (hasRouteGeometry) {
    return ConnectivityChipState.routeOffline;
  }
  return ConnectivityChipState.live;
}

/// German UI labels — calm, honest, glanceable.
String connectivityChipLabel(ConnectivityChipState state) {
  return switch (state) {
    ConnectivityChipState.live => 'Live',
    ConnectivityChipState.routeOffline => 'Route offline',
    ConnectivityChipState.offlineMapOk =>
      'Offline · Karte ok · Reroute braucht Netz',
    ConnectivityChipState.mapsMissing => 'Karten fehlen',
  };
}

/// Whether the chip is worth showing in Clean Mode (hide quiet Live).
bool connectivityChipVisibleInClean(ConnectivityChipState state) {
  return state != ConnectivityChipState.live;
}
