/// Interne IndexedStack-Indizes. Die Leiste hat vier Ziele:
/// Hof, Karte, Platz, Werkstatt. Ride (HUD) ist kein Tab.
/// Shop ist eine Route aus der Werkstatt, kein fünfter Reiter.
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

  /// 0 Hof · 1 Karte · 2 Platz · 3 Werkstatt. Ride-HUD wirkt wie Karte.
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

  /// Karte-Tab aus der Leiste: gleiche Wahl wie Hof „Rausfahren“ /
  /// „Noch mal raus“ (Einfach fahren / Touren anzeigen).
  ///
  /// Nicht bei erneutem Tap auf Karte, HUD-Rückkehr, gesetztem Launch
  /// (Hof-CTA, Deep-Link, Planen) oder pending Loop/Mappe/Lens.
  static bool shouldOfferRideOutOnKarteNav({
    required int fromStack,
    required int toStack,
    bool hasLaunchIntent = false,
    bool hasPendingDiscoverTarget = false,
  }) {
    if (toStack != karte) return false;
    final from = stackIndex(fromStack);
    if (from == karte || from == ride) return false;
    if (hasLaunchIntent || hasPendingDiscoverTarget) return false;
    return true;
  }
}
