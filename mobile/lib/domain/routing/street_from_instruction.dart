/// Extrahiert Straßenname aus DE/EN Nav-Instructions (OSRM/Valhalla-Stil).
///
/// Beispiele:
/// - `Rechts abbiegen auf Hauptstraße`
/// - `Turn left onto Main Street`
/// - `Weiter nach Neckarstaden`
String? extractStreetNameFromInstruction(String instruction) {
  final t = instruction.trim();
  if (t.isEmpty) return null;

  // EN: "… onto X" / "… on X"
  final onto = RegExp(
    r'\b(?:onto|on)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(t);
  if (onto != null) {
    final s = _cleanStreet(onto.group(1)!);
    if (s != null) return s;
  }

  // FR: "… sur X" / "… vers X"
  final sur = RegExp(
    r'\b(?:sur|vers)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(t);
  if (sur != null) {
    final s = _cleanStreet(sur.group(1)!);
    if (s != null) return s;
  }

  // IT: "… su X" / "… verso X"
  final su = RegExp(
    r'\b(?:su|verso)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(t);
  if (su != null) {
    final s = _cleanStreet(su.group(1)!);
    if (s != null) return s;
  }

  // DE: "… auf X" / "… nach X" / "… in die X" / "… in den X" / "… in der X"
  final auf = RegExp(
    r'\b(?:auf|nach|in die|in den|in der|in dem)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(t);
  if (auf != null) {
    final s = _cleanStreet(auf.group(1)!);
    if (s != null) return s;
  }

  return null;
}

/// Manöver-Kurztext ohne Straßenanteil (für HUD-Glyph-Zeile).
String maneuverLabelFromInstruction(String instruction) {
  final street = extractStreetNameFromInstruction(instruction);
  if (street == null) return instruction.trim();
  var base = instruction;
  for (final pat in [
    RegExp(r'\s+(?:onto|on)\s+.+$', caseSensitive: false),
    RegExp(
      r'\s+(?:auf|nach|in die|in den|in der|in dem)\s+.+$',
      caseSensitive: false,
    ),
  ]) {
    base = base.replaceFirst(pat, '');
  }
  final out = base.trim();
  return out.isEmpty ? instruction.trim() : out;
}

String? _cleanStreet(String raw) {
  var s = raw.trim();
  // Trailing punctuation / filler.
  s = s.replaceAll(RegExp(r'[.,;:]+$'), '').trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return null;
  // Avoid returning the whole instruction when regex was too greedy.
  if (s.length > 80) return null;
  final lower = s.toLowerCase();
  if (lower == 'ziel' ||
      lower.contains('ziel erreicht') ||
      lower == 'destination' ||
      lower == 'arrivée' ||
      lower.contains('vous êtes arrivé') ||
      lower == 'destinazione' ||
      lower.contains('destinazione raggiunta')) {
    return null;
  }
  return s;
}
