/// Snap-Punkte für Planen- und Tour-Detail-Sheets auf dem Phone.
///
/// - [peek]: ~20 % Sheet → ~80 % Karte. Weiterplanen auf der Karte
///   (Linie ziehen, Ziel tippen) bei kompakter Leiste.
/// - [form]: Start/Ziel-Felder, Karte bleibt sichtbar.
/// - [full]: ~80 % Sheet → ~20 % Karte frei. Recents, Vias, Tipps.
abstract final class PlanSheetSnaps {
  /// Kompakt — Karte ist der Editor.
  static const double peek = 0.22;

  /// Formular lesbar, Map nicht weg.
  static const double form = 0.50;

  /// Volle Planungsfläche, oben bleibt Karte.
  static const double full = 0.80;

  static const List<double> snapSizes = [peek, form, full];

  /// Intermediate snaps for [DraggableScrollableSheet.snapSizes]
  /// (min/max are implicit — must not be listed again).
  static const List<double> sheetSnapSizes = [form];

  static const double minSize = peek;
  static const double maxSize = full;

  static const double _peekFormMid = (peek + form) / 2;
  static const double _formFullMid = (form + full) / 2;

  static bool isPeek(double extent) => extent < _peekFormMid;

  static bool isFull(double extent) => extent >= _formFullMid;

  static bool isForm(double extent) => !isPeek(extent) && !isFull(extent);

  static double nearest(double extent) {
    var best = snapSizes.first;
    var bestDist = (extent - best).abs();
    for (final s in snapSizes) {
      final d = (extent - s).abs();
      if (d < bestDist) {
        best = s;
        bestDist = d;
      }
    }
    return best;
  }

  /// Griff-Tipp: Peek → Formular → voll → Peek (wieder 80 % Karte).
  static double handleTapTarget(double current) {
    if (isPeek(current)) return form;
    if (isForm(current)) return full;
    return peek;
  }

  /// Beim Öffnen: Anpassen braucht die Linie auf der Karte.
  static double openTarget({required bool adapting}) =>
      adapting ? peek : form;
}
