/// Interne IndexedStack-Indizes. Die Leiste hat vier Ziele;
/// Ride (HUD) ist kein Tab.
class ShellTabs {
  static const hof = 0;
  static const werkstatt = 1;
  static const ride = 2;
  static const karte = 3;
  static const shop = 4;

  static int stackIndex(int raw) {
    if (raw < 0) return hof;
    if (raw > shop) return hof;
    return raw;
  }

  /// 0 Hof · 1 Karte · 2 Werkstatt · 3 Shop. Ride-HUD wirkt wie Karte.
  static int navIndex(int stack) {
    return switch (stackIndex(stack)) {
      hof => 0,
      karte || ride => 1,
      werkstatt => 2,
      shop => 3,
      _ => 0,
    };
  }

  static int stackFromNav(int nav) {
    return switch (nav) {
      0 => hof,
      1 => karte,
      2 => werkstatt,
      3 => shop,
      _ => hof,
    };
  }
}
