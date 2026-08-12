/// Snap-Punkte für das Discover-/Touren-Browse-Sheet (Komoot-ähnlich).
///
/// - [peek]: Map dominant — Handle + Steuerzeile / Primärchips sichtbar
/// - [half]: Liste lesbar, Karte bleibt >50 %
/// - [full]: Filter + lange Liste
class DiscoverBrowseSheetSnaps {
  DiscoverBrowseSheetSnaps._();

  /// Collapsed — Karte dominant, Peek = eine Tourkarte (Komoot).
  static const double peek = 0.28;

  /// Medium — Tourenkarten + Primärfilter, Map bleibt sichtbar.
  static const double half = 0.42;

  /// Expanded — volle Browse-Fläche.
  static const double full = 0.84;

  static const List<double> snapSizes = <double>[peek, half, full];

  /// Intermediate snaps for [DraggableScrollableSheet.snapSizes]
  /// (min/max are implicit — must not be listed again).
  static const List<double> sheetSnapSizes = <double>[half];

  static const double _peekHalfMid = (peek + half) / 2;
  static const double _halfFullMid = (half + full) / 2;

  static bool isPeek(double extent) => extent < _peekHalfMid;

  static bool isFull(double extent) => extent >= _halfFullMid;

  static bool isHalf(double extent) => !isPeek(extent) && !isFull(extent);

  /// Nächster Snap für programmatisches `animateTo`.
  static double nearest(double extent) {
    var best = peek;
    var bestDist = (extent - peek).abs();
    for (final s in snapSizes) {
      final d = (extent - s).abs();
      if (d < bestDist) {
        best = s;
        bestDist = d;
      }
    }
    return best;
  }

  /// Liste-Taste: von Peek → Half, von Half/Full → Full (mehr Liste).
  static double listTarget(double current) {
    if (isPeek(current)) return half;
    return full;
  }

  /// Karte-Taste: immer Peek.
  static double get mapTarget => peek;
}
