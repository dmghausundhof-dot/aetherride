/// Benannter Zwischenzielpunkt. Routing bleibt lat/lng; HUD braucht den Namen.
class LabeledVia {
  const LabeledVia({
    required this.lat,
    required this.lng,
    this.label,
    this.placeId,
    this.kind,
  });

  final double lat;
  final double lng;
  final String? label;
  final String? placeId;
  final String? kind;

  String? get trimmedLabel {
    final t = label?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  LabeledVia copyWith({String? label}) => LabeledVia(
        lat: lat,
        lng: lng,
        label: label ?? this.label,
        placeId: placeId,
        kind: kind,
      );
}

/// Index ±1, sonst unverändert. Keine Wrap-around-Magie.
List<LabeledVia> moveLabeledVia(List<LabeledVia> list, int index, int delta) {
  return moveLabeledViaTo(list, index, index + delta);
}

/// Drag in the stacked list. Out-of-range is a no-op.
List<LabeledVia> moveLabeledViaTo(List<LabeledVia> list, int from, int to) {
  if (list.isEmpty) return list;
  if (from < 0 ||
      to < 0 ||
      from >= list.length ||
      to >= list.length ||
      from == to) {
    return list;
  }
  final next = List<LabeledVia>.from(list);
  final item = next.removeAt(from);
  next.insert(to, item);
  return next;
}
