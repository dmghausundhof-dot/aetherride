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
  if (list.isEmpty) return list;
  final j = index + delta;
  if (index < 0 || index >= list.length || j < 0 || j >= list.length) {
    return list;
  }
  final next = List<LabeledVia>.from(list);
  final item = next.removeAt(index);
  next.insert(j, item);
  return next;
}
