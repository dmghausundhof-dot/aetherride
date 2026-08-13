/// Sheet-Liste: die Auswahl bleibt Index 0, der Rest behält seine Rangfolge.
List<T> pinSelectedFirst<T>(List<T> ranked, bool Function(T) isSelected) {
  final i = ranked.indexWhere(isSelected);
  if (i <= 0) return List<T>.from(ranked);
  final out = List<T>.from(ranked);
  final item = out.removeAt(i);
  return [item, ...out];
}
