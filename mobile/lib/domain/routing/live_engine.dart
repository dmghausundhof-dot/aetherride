/// Live DACH engines the rider can pick. Offline Valhalla/OSRM stay a
/// separate pack path — not this picker.
enum LiveRoutingEngine {
  hybrid,
  graphhopper,
  openrouteservice,
}

extension LiveRoutingEngineX on LiveRoutingEngine {
  /// Query value for `/api/route?engine=`. Null = server hybrid.
  String? get apiId => switch (this) {
        LiveRoutingEngine.hybrid => null,
        LiveRoutingEngine.graphhopper => 'graphhopper',
        LiveRoutingEngine.openrouteservice => 'openrouteservice',
      };

  static LiveRoutingEngine parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'graphhopper':
      case 'gh':
        return LiveRoutingEngine.graphhopper;
      case 'openrouteservice':
      case 'ors':
        return LiveRoutingEngine.openrouteservice;
      default:
        return LiveRoutingEngine.hybrid;
    }
  }
}
