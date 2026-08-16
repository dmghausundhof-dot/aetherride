/// Zustand an der Stimme — Fahrer-Wahrnehmung, kein Wetter-Orakel.
const kStimmeTagWires = <String>[
  'nass',
  'zu',
  'viel_los',
  'top',
  'baustelle',
];

const kStimmeTagsMax = 3;

Set<String> stimmeTagAllowlist() => {...kStimmeTagWires};

/// Unbekannte Werte fallen weg. Max [kStimmeTagsMax], Reihenfolge bleibt.
List<String> parseStimmeTags(Object? raw) {
  if (raw is! List) return const [];
  final allow = stimmeTagAllowlist();
  final out = <String>[];
  final seen = <String>{};
  for (final e in raw) {
    final t = '$e'.trim().toLowerCase().replaceAll(' ', '_');
    if (!allow.contains(t) || !seen.add(t)) continue;
    out.add(t);
    if (out.length >= kStimmeTagsMax) break;
  }
  return out;
}

List<String> toggleStimmeTag(List<String> current, String wire) {
  final allow = stimmeTagAllowlist();
  if (!allow.contains(wire)) return parseStimmeTags(current);
  final next = [...parseStimmeTags(current)];
  if (next.contains(wire)) {
    next.remove(wire);
    return next;
  }
  if (next.length >= kStimmeTagsMax) return next;
  return [...next, wire];
}
