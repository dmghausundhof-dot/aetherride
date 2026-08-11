/// Mid-ride connectivity honesty (N-03 / N-08).
///
/// Never claims offline reroute. Map offline ≠ route offline ≠ reroute offline.
///
/// UX lock (post-#14 review):
/// - online → [ConnectivityChipState.live] (hidden in Clean Mode)
/// - [ConnectivityChipState.routeOffline] only when *offline* + local route geometry
/// - Chip string for map-ok offline: `Offline · Karte ok · Reroute: Netz`
enum ConnectivityChipState {
  /// Online — quiet trust; optional label „Live“ (hidden in Clean).
  live,

  /// Offline + Stage A: active route geometry is local (TBT ohne Netz).
  routeOffline,

  /// Offline; basemap usable; auto-replan needs net (no / freeride geometry).
  offlineMapOk,

  /// Offline and no usable offline basemap.
  mapsMissing,
}

/// Resolve chip state from live signals. Pure / testable.
ConnectivityChipState resolveConnectivityChip({
  required bool online,
  required bool hasRouteGeometry,
  required bool offlineMapAvailable,
}) {
  if (online) {
    return ConnectivityChipState.live;
  }
  if (!offlineMapAvailable) {
    return ConnectivityChipState.mapsMissing;
  }
  if (hasRouteGeometry) {
    return ConnectivityChipState.routeOffline;
  }
  return ConnectivityChipState.offlineMapOk;
}

/// German UI labels — calm, honest, glanceable (UX-locked strings).
String connectivityChipLabel(ConnectivityChipState state) {
  return switch (state) {
    ConnectivityChipState.live => 'Live',
    ConnectivityChipState.routeOffline => 'Route offline',
    ConnectivityChipState.offlineMapOk =>
      'Offline · Karte ok · Reroute: Netz',
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
