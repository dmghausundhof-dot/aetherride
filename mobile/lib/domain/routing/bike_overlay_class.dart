import '../bike.dart';

/// OSM-Way → Bike-Overlay-Klasse. Spiegel von `src/lib/routing/bikeOverlayClass.ts`.
///
/// Honesty: S0–S3+ nur aus `mtb:scale` / `mtb:scale:imba`, nie aus `sac_scale`.
enum BikeOverlayClass {
  mtb,
  mtbUnrated,
  gravel,
  road,
  urban,
  hidden,
}

enum MtbScaleLabel { s0, s1, s2, s3 }

enum BikeOverlayFamily { mtb, gravel, road, urban }

class BikeOverlayClassification {
  const BikeOverlayClassification({
    required this.bikeClass,
    this.mtbScale,
  });

  final BikeOverlayClass bikeClass;
  final MtbScaleLabel? mtbScale;
}

const _pathTrack = {'path', 'track', 'bridleway'};
const _roadLike = {
  'primary',
  'secondary',
  'tertiary',
  'unclassified',
  'residential',
  'service',
};
const _paved = {
  'asphalt',
  'paved',
  'concrete',
  'concrete:plates',
  'concrete:lanes',
  'chipseal',
};
const _gravelSurface = {
  'unpaved',
  'compacted',
  'fine_gravel',
  'gravel',
  'pebblestone',
};
const _gravelTracktype = {'grade2', 'grade3', 'grade4'};
const _cyclewayInfra = {
  'lane',
  'track',
  'share_busway',
  'opposite_lane',
  'opposite_track',
  'shared_lane',
};

String _tag(Map<String, String?> tags, String key) =>
    (tags[key] ?? '').trim().toLowerCase();

/// Parse OSM MTB scale. Liest **nicht** `sac_scale`. 3+ → S3+ (Anzeige).
MtbScaleLabel? parseOsmMtbScale(String? mtbScale, [String? mtbScaleImba]) {
  final raw = (mtbScale ?? '').trim().isNotEmpty
      ? mtbScale!.trim()
      : (mtbScaleImba ?? '').trim();
  if (raw.isEmpty) return null;
  final t = raw.toLowerCase();
  final head = t.replaceFirst(RegExp(r'^s'), '').replaceFirst(RegExp(r'[^0-9].*$'), '');
  if (t == '0' || t.startsWith('0') || t.startsWith('s0') || head == '0') {
    return MtbScaleLabel.s0;
  }
  if (t == '1' || t.startsWith('1') || t.startsWith('s1') || head == '1') {
    return MtbScaleLabel.s1;
  }
  if (t == '2' || t.startsWith('2') || t.startsWith('s2') || head == '2') {
    return MtbScaleLabel.s2;
  }
  if (t == '3' ||
      t == '4' ||
      t == '5' ||
      t == '6' ||
      t.startsWith('s3') ||
      t.startsWith('s4') ||
      t.startsWith('s5') ||
      head == '3' ||
      head == '4' ||
      head == '5' ||
      head == '6') {
    return MtbScaleLabel.s3;
  }
  return null;
}

bool _hasCyclewayInfra(Map<String, String?> tags) {
  for (final key in [
    'cycleway',
    'cycleway:left',
    'cycleway:right',
    'cycleway:both',
  ]) {
    if (_cyclewayInfra.contains(_tag(tags, key))) return true;
  }
  return false;
}

BikeOverlayClassification classifyBikeWay(Map<String, String?> tags) {
  final bicycle = _tag(tags, 'bicycle');
  final mtb = _tag(tags, 'mtb');
  if (bicycle == 'no' || mtb == 'no') {
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.hidden);
  }

  final highway = _tag(tags, 'highway');
  final surface = _tag(tags, 'surface');
  final tracktype = _tag(tags, 'tracktype');
  final mtbScale = parseOsmMtbScale(tags['mtb:scale'], tags['mtb:scale:imba']);

  if (_pathTrack.contains(highway) && mtbScale != null) {
    return BikeOverlayClassification(
      bikeClass: BikeOverlayClass.mtb,
      mtbScale: mtbScale,
    );
  }

  if (highway == 'living_street') {
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.urban);
  }

  if (_hasCyclewayInfra(tags) && _roadLike.contains(highway)) {
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.urban);
  }

  final gravelish =
      _gravelSurface.contains(surface) || _gravelTracktype.contains(tracktype);
  final paved = _paved.contains(surface);

  if (highway == 'cycleway') {
    if (gravelish && !paved) {
      return const BikeOverlayClassification(bikeClass: BikeOverlayClass.gravel);
    }
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.road);
  }

  if ((bicycle == 'designated' || bicycle == 'yes') &&
      paved &&
      _roadLike.contains(highway)) {
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.road);
  }

  if (gravelish && (_pathTrack.contains(highway) || highway == 'unclassified')) {
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.gravel);
  }

  if (_pathTrack.contains(highway)) {
    return const BikeOverlayClassification(
      bikeClass: BikeOverlayClass.mtbUnrated,
    );
  }

  if (highway == 'footway' &&
      (bicycle == 'yes' || bicycle == 'designated')) {
    return const BikeOverlayClassification(bikeClass: BikeOverlayClass.urban);
  }

  return const BikeOverlayClassification(bikeClass: BikeOverlayClass.hidden);
}

BikeOverlayFamily overlayFamilyForBike(BikeCategory category) =>
    switch (category) {
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.mtbEnduro ||
      BikeCategory.dh ||
      BikeCategory.emtb ||
      BikeCategory.hiking =>
        BikeOverlayFamily.mtb,
      BikeCategory.gravel || BikeCategory.etrekking => BikeOverlayFamily.gravel,
      BikeCategory.urban ||
      BikeCategory.cargo ||
      BikeCategory.folding ||
      BikeCategory.kids =>
        BikeOverlayFamily.urban,
      BikeCategory.road => BikeOverlayFamily.road,
    };

/// Alle Zeichen-Klassen — Nutzer kann sie in der Legende einzeln anschalten.
const kAllPaintedOverlayClasses = <BikeOverlayClass>{
  BikeOverlayClass.mtb,
  BikeOverlayClass.mtbUnrated,
  BikeOverlayClass.gravel,
  BikeOverlayClass.road,
  BikeOverlayClass.urban,
};

List<BikeOverlayClass> overlayClassesForFamily(BikeOverlayFamily family) =>
    switch (family) {
      BikeOverlayFamily.mtb => [
          BikeOverlayClass.mtb,
          BikeOverlayClass.mtbUnrated,
        ],
      BikeOverlayFamily.gravel => [BikeOverlayClass.gravel],
      BikeOverlayFamily.road => [BikeOverlayClass.road],
      BikeOverlayFamily.urban => [BikeOverlayClass.urban],
    };

/// Default-Sichtbarkeit: City sieht City+Asphalt, nicht die S-Skala.
Set<BikeOverlayClass> overlayDefaultExtraOn(BikeOverlayFamily family) =>
    switch (family) {
      BikeOverlayFamily.mtb => {
          BikeOverlayClass.mtb,
          BikeOverlayClass.mtbUnrated,
        },
      BikeOverlayFamily.gravel => {
          BikeOverlayClass.gravel,
          BikeOverlayClass.road,
        },
      BikeOverlayFamily.road => {
          BikeOverlayClass.road,
          BikeOverlayClass.urban,
        },
      BikeOverlayFamily.urban => {
          BikeOverlayClass.urban,
          BikeOverlayClass.road,
        },
    };

/// S0–S3+ nur bei MTB/Trail — nicht als permanente City-Legende.
bool overlayLegendShowsSScale(BikeOverlayFamily family) =>
    family == BikeOverlayFamily.mtb;

/// Kompakt-Kürzel für die eingeklappte Legende (ohne S-Zeilen).
String overlayLegendCompactKey(BikeOverlayFamily family) => switch (family) {
      BikeOverlayFamily.mtb => 'mtb',
      BikeOverlayFamily.gravel => 'gravel',
      BikeOverlayFamily.road => 'road',
      BikeOverlayFamily.urban => 'urban',
    };

/// Eine Legendenzeile. [key] ist S0/S1/S2/S3+/unrated/gravel/road/urban.
class OverlayLegendRow {
  const OverlayLegendRow({required this.cls, required this.key});
  final BikeOverlayClass cls;
  final String key;
}

/// Ausgeklappt: S-Skala nur bei MTB; City/Rennrad/Gravel ohne S0–S3+.
List<OverlayLegendRow> overlayLegendRows({
  required BikeOverlayFamily family,
  required bool expanded,
}) {
  if (!expanded) return const [];
  if (overlayLegendShowsSScale(family)) {
    return const [
      OverlayLegendRow(cls: BikeOverlayClass.mtb, key: 'S0'),
      OverlayLegendRow(cls: BikeOverlayClass.mtb, key: 'S1'),
      OverlayLegendRow(cls: BikeOverlayClass.mtb, key: 'S2'),
      OverlayLegendRow(cls: BikeOverlayClass.mtb, key: 'S3+'),
      OverlayLegendRow(cls: BikeOverlayClass.mtbUnrated, key: 'unrated'),
    ];
  }
  return switch (family) {
    BikeOverlayFamily.urban => const [
        OverlayLegendRow(cls: BikeOverlayClass.urban, key: 'urban'),
        OverlayLegendRow(cls: BikeOverlayClass.road, key: 'road'),
      ],
    BikeOverlayFamily.road => const [
        OverlayLegendRow(cls: BikeOverlayClass.road, key: 'road'),
        OverlayLegendRow(cls: BikeOverlayClass.urban, key: 'urban'),
      ],
    BikeOverlayFamily.gravel => const [
        OverlayLegendRow(cls: BikeOverlayClass.gravel, key: 'gravel'),
        OverlayLegendRow(cls: BikeOverlayClass.road, key: 'road'),
      ],
    BikeOverlayFamily.mtb => const [],
  };
}

/// Nutzer-Toggles in [extraOn] sind die Sichtbarkeit. Aus = weg, nicht 16 %.
Set<BikeOverlayClass> overlayClassesShown({
  required bool overlayOn,
  required Set<BikeOverlayClass> extraOn,
}) =>
    overlayOn ? extraOn : <BikeOverlayClass>{};

String mtbScaleCss(MtbScaleLabel s) => switch (s) {
      MtbScaleLabel.s0 => 'S0',
      MtbScaleLabel.s1 => 'S1',
      MtbScaleLabel.s2 => 'S2',
      MtbScaleLabel.s3 => 'S3+',
    };

String bikeOverlayClassId(BikeOverlayClass c) => switch (c) {
      BikeOverlayClass.mtb => 'mtb',
      BikeOverlayClass.mtbUnrated => 'mtb_unrated',
      BikeOverlayClass.gravel => 'gravel',
      BikeOverlayClass.road => 'road',
      BikeOverlayClass.urban => 'urban',
      BikeOverlayClass.hidden => 'hidden',
    };

abstract final class BikeOverlayColors {
  static const s0 = '#4CAF50';
  static const s1 = '#8BC34A';
  static const s2 = '#FFC107';
  static const s3 = '#E53935';
  static const unrated = '#90A4AE';
  static const gravel = '#C49A3C';
  static const road = '#1E88E5';
  static const urban = '#00897B';
}
