import '../../../l10n/app_localizations.dart';

enum OsmSurfaceGroup { asphalt, gravel, trail }

const _asphalt = {
  'asphalt',
  'paved',
  'concrete',
  'paving_stones',
  'sett',
  'chipseal',
  'concrete:plates',
  'concrete:lanes',
};

const _gravel = {
  'gravel',
  'compacted',
  'fine_gravel',
  'pebblestone',
  'unpaved',
  'ground',
};

const _trail = {
  'dirt',
  'earth',
  'grass',
  'path',
  'trail',
  'root',
  'mud',
  'sand',
  'wood',
  'winter_road',
};

OsmSurfaceGroup? osmSurfaceGroup(String? raw) {
  final key = (raw ?? '').trim().toLowerCase();
  if (key.isEmpty) return null;
  if (_asphalt.contains(key)) return OsmSurfaceGroup.asphalt;
  if (_gravel.contains(key)) return OsmSurfaceGroup.gravel;
  if (_trail.contains(key)) return OsmSurfaceGroup.trail;
  return null;
}

String osmSurfaceDisplay(String raw, AppLocalizations l10n) {
  final key = raw.trim();
  if (key.isEmpty) return '';
  final group = osmSurfaceGroup(key);
  if (group == OsmSurfaceGroup.asphalt) return l10n.filterSurfaceAsphalt;
  if (group == OsmSurfaceGroup.gravel) return l10n.filterSurfaceGravel;
  if (group == OsmSurfaceGroup.trail) return l10n.filterSurfaceTrail;
  return raw.replaceAll('_', ' ');
}
