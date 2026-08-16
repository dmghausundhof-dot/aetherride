/// Heading-Karten gehören nicht in die Default-Tourenliste.
/// Discover malt Heading-/Demo-A→B nicht als mintgrüne Tour-Leine.
abstract final class CompassHeading {
  /// Never list „Richtung Norden / Osten / Südwest“ as catalog tours.
  static const bool showBucketsInDefaultTourList = false;

  static String? peekTourId({
    required String? selectedTourId,
    required String? firstFilteredTourId,
  }) {
    if (selectedTourId != null) return selectedTourId;
    return firstFilteredTourId;
  }

  /// Live GH polyline is OK in the HUD; Discover must not paint demo/heading.
  static bool hideComputedRibbonOnDiscover({
    required bool isDemoOrApprox,
    required bool discoverExplore,
  }) {
    if (!discoverExplore) return false;
    return isDemoOrApprox;
  }
}
