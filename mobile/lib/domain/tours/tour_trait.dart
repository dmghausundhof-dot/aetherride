/// Nutzer-sichtbare Tour-Merkmale aus Catalog-Tags.
///
/// Wire-Tags (`feierabend`, `60min`, `rhein-neckar`) sind intern. Die
/// Anzeige ist umschaltbar (Chip an/aus filtert die Liste) und lesbar.
abstract final class TourTrait {
  static const _skip = {
    'osm',
    'catalog',
    'seed',
    'outdooractive',
    'api',
    'gpx',
    'import',
  };

  static const _labels = {
    'feierabend': 'Abendrunde',
    '60min': '~1 h',
    '45min': '~45 min',
    '90min': '~1,5 h',
    'rhein-neckar': 'Rhein-Neckar',
    'wiesloch': 'Wiesloch',
    'hockenheim': 'Hockenheim',
    'heidelberg': 'Heidelberg',
    'rundkurs': 'Rundkurs',
    'loop': 'Rundkurs',
    'gravel': 'Gravel',
    'mtb': 'MTB',
    'emtb': 'E-MTB',
    'city': 'City',
    'road': 'Rennrad',
    'asphalt': 'Asphalt',
    'trail': 'Trail',
    'schotter': 'Schotter',
  };

  /// Anzeigename. Unbekannte slugs werden zu Wörtern (`box-berg` → Box Berg).
  static String keyOf(String raw) => _key(raw);

  /// Anzeigename. Unbekannte slugs werden zu Wörtern (`box-berg` → Box Berg).
  static String label(String raw) {
    final key = _key(raw);
    if (key.isEmpty) return raw.trim();
    final known = _labels[key];
    if (known != null) return known;
    if (RegExp(r'^\d+min$').hasMatch(key)) {
      final n = int.tryParse(key.replaceAll('min', ''));
      if (n != null) return n >= 60 ? '~${n ~/ 60} h' : '~$n min';
    }
    return key
        .split(RegExp(r'[-_]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  static String _key(String raw) =>
      raw.trim().toLowerCase().replaceAll(' ', '-');

  /// Catalog-Rauschen und Duplikate streichen, Reihenfolge behalten.
  static List<String> visibleWires(
    Iterable<String> tags, {
    Iterable<String> extraSkip = const [],
  }) {
    final skip = <String>{
      ..._skip,
      for (final s in extraSkip) _key(s),
    };
    final seen = <String>{};
    final out = <String>[];
    for (final raw in tags) {
      final key = _key(raw);
      if (key.isEmpty || skip.contains(key) || seen.contains(key)) continue;
      seen.add(key);
      out.add(raw.trim());
      if (out.length >= 8) break;
    }
    return out;
  }

  /// Chip-Filter: Tag am Datensatz oder als Wort im Namen.
  static bool matches({
    required Iterable<String> tags,
    required String name,
    required String wire,
  }) {
    final key = _key(wire);
    if (key.isEmpty) return true;
    for (final t in tags) {
      if (_key(t) == key) return true;
    }
    final hay = name.toLowerCase();
    if (hay.contains(key.replaceAll('-', ' '))) return true;
    if (hay.contains(key.replaceAll('-', ''))) return true;
    final pretty = label(wire).toLowerCase();
    return pretty.isNotEmpty && hay.contains(pretty);
  }
}
