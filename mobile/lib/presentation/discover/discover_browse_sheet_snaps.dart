/// Snap-Punkte für das Discover-/Touren-Browse-Sheet (Komoot-ähnlich).
///
/// - [closed]: nur der Griff — Karte frei, ohne Tour ganz zu.
/// - [peek]: eine Tourkarte
/// - [half]: Liste lesbar, Karte bleibt >50 %
/// - [full]: Filter + lange Liste
class DiscoverBrowseSheetSnaps {
  DiscoverBrowseSheetSnaps._();

  /// Nur Griff + Mappe-Label — 48 dp Hit-Target, nicht in der Systemgeste.
  static const double closed = 0.10;

  /// Eine Tourkarte (Komoot-Peek).
  static const double peek = 0.34;

  /// Medium — Tourenkarten + Primärfilter, Map bleibt sichtbar.
  static const double half = 0.42;

  /// Expanded — volle Browse-Fläche.
  static const double full = 0.84;

  static List<double> snapSizes({required bool hasSelection}) => hasSelection
      ? const <double>[peek, half, full]
      : const <double>[closed, peek, half, full];

  /// Intermediate snaps for [DraggableScrollableSheet.snapSizes]
  /// (min/max are implicit — must not be listed again).
  static List<double> sheetSnapSizes({required bool hasSelection}) =>
      hasSelection
          ? const <double>[half]
          : const <double>[peek, half];

  static double minSize({required bool hasSelection}) =>
      hasSelection ? peek : closed;

  static const double _closedPeekMid = (closed + peek) / 2;
  static const double _peekHalfMid = (peek + half) / 2;
  static const double _halfFullMid = (half + full) / 2;

  static bool isClosed(double extent) => extent < _closedPeekMid;

  static bool isPeek(double extent) =>
      extent >= _closedPeekMid && extent < _peekHalfMid;

  static bool isFull(double extent) => extent >= _halfFullMid;

  static bool isHalf(double extent) =>
      !isClosed(extent) && !isPeek(extent) && !isFull(extent);

  /// Nächster Snap für programmatisches `animateTo`.
  static double nearest(double extent, {required bool hasSelection}) {
    final snaps = snapSizes(hasSelection: hasSelection);
    var best = snaps.first;
    var bestDist = (extent - best).abs();
    for (final s in snaps) {
      final d = (extent - s).abs();
      if (d < bestDist) {
        best = s;
        bestDist = d;
      }
    }
    return best;
  }

  /// Liste-Taste: von Closed/Peek → Half, von Half/Full → Full.
  static double listTarget(double current) {
    if (isClosed(current) || isPeek(current)) return half;
    return full;
  }

  /// Antippen am Griff — ohne Swipe aus der Systemgeste.
  /// Zu/Peek → halb, halb → voll, voll → Peek/Zu (wieder Karte).
  static double handleTapTarget(
    double current, {
    required bool hasSelection,
  }) {
    if (isFull(current)) return mapTarget(hasSelection: hasSelection);
    if (isHalf(current)) return full;
    return half;
  }

  /// Karte-Taste: Peek mit Tour, sonst ganz zu.
  static double mapTarget({required bool hasSelection}) =>
      hasSelection ? peek : closed;
}
