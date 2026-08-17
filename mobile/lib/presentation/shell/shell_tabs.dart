/// Interne IndexedStack-Indizes. Die Leiste hat vier Ziele:
/// Start, Karte, Touren, Rad. Ride (HUD) ist kein Tab.
/// Shop ist eine Route aus dem Rad, kein fünfter Reiter.
class ShellTabs {
  static const hof = 0;
  static const werkstatt = 1;
  static const ride = 2;
  static const karte = 3;
  static const platz = 4;

  static const navCount = 4;

  static int stackIndex(int raw) {
    if (raw < 0) return hof;
    if (raw > platz) return hof;
    return raw;
  }

  /// 0 Start · 1 Karte · 2 Touren · 3 Rad. Ride-HUD wirkt wie Karte.
  static int navIndex(int stack) {
    return switch (stackIndex(stack)) {
      hof => 0,
      karte || ride => 1,
      platz => 2,
      werkstatt => 3,
      _ => 0,
    };
  }

  static int stackFromNav(int nav) {
    return switch (nav) {
      0 => hof,
      1 => karte,
      2 => platz,
      3 => werkstatt,
      _ => hof,
    };
  }

  /// Losfahren sitzt auf Start → HUD. Karte merkt den letzten Modus.
  static bool shouldOfferRideOutOnKarteNav({
    int fromStack = 0,
    int toStack = 0,
    bool hasLaunchIntent = false,
    bool hasPendingDiscoverTarget = false,
  }) {
    return false;
  }
}
