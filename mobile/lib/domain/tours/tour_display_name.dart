/// Kurzer Anzeigename für Karten/Hof — Editorial-Englisch nicht 1:1 zeigen.
String tourDisplayName(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  final lower = t.toLowerCase();
  if (lower.contains('boxberg')) return 'Boxberg-Gravel';
  if (lower.contains('hardtwald')) return 'Hardtwald-MTB';
  if (lower.contains('wiesloch')) return 'Wiesloch Feierabend';
  if (lower.contains('hockenheim')) return 'Hockenheim Rheinebene';

  final parts = t.split(RegExp(r'\s+[—–]\s+'));
  var core = parts.last.trim();
  core = core.replaceFirst(RegExp(r'\s+gravel$', caseSensitive: false), '');
  core = core.replaceFirst(RegExp(r'\s+foothills$', caseSensitive: false), '');
  core = core.trim();
  if (core.length <= 32) return core.isEmpty ? t : core;
  final comma = core.split(',');
  final short = comma.first.trim();
  return short.isEmpty ? t : short;
}
