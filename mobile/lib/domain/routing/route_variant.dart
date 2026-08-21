enum RouteVariant { planned, flatter, unpaved }

RouteVariant parseRouteVariant(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'flatter':
      return RouteVariant.flatter;
    case 'unpaved':
      return RouteVariant.unpaved;
    default:
      return RouteVariant.planned;
  }
}

extension RouteVariantWire on RouteVariant {
  String get apiId => switch (this) {
        RouteVariant.planned => 'planned',
        RouteVariant.flatter => 'flatter',
        RouteVariant.unpaved => 'unpaved',
      };
}

/// Undo frames include variant so flatter/unpaved is reversible (Web `planEditKey`).
bool planVariantChanged({
  required RouteVariant before,
  required RouteVariant after,
}) =>
    before != after;
