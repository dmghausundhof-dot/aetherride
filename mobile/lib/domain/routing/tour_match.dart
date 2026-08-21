/// Bike-bewusster Match-Score für Discover-Karten (Komoot „passt zu dir“).
///
/// Score 12–99. Garage-Kategorie schlägt den Profil-Sport.
/// Surface + S-Skala sind ehrlich: ein AM auf S3+ verliert, Gravel auf
/// Root-Trail auch.
library;

import '../bike.dart';
import 'tour_filters.dart';
import 'trail_difficulty.dart';

int tourMatchScore({
  required BikeCategory bike,
  required List<BikeCategory> categories,
  required String surface,
  required String mtbScale,
  int durationMin = 0,
  bool isLoop = false,
}) {
  var score = 54;
  if (categories.contains(bike)) {
    score += 22;
  } else if (_softCategoryHit(bike, categories)) {
    score += 8;
  } else if (categories.isNotEmpty) {
    score -= 12;
  }

  final surf = TourFilters.parseSurface(surface);
  final scale = parseTrailDifficulty(mtbScale);

  switch (bike) {
    case BikeCategory.mtbAm:
    case BikeCategory.mtbTrail:
    case BikeCategory.emtb:
      if (surf == TourSurfaceKey.trail) score += 16;
      if (surf == TourSurfaceKey.gravel) score += 2;
      if (surf == TourSurfaceKey.asphalt) score -= 8;
      if (scale == TrailDifficulty.s1) score += 6;
      if (scale == TrailDifficulty.s2) score += 4;
      if (scale == TrailDifficulty.s0) score += 2;
      if (scale == TrailDifficulty.s3 || scale == TrailDifficulty.s3plus) {
        score -= bike == BikeCategory.mtbTrail ? 4 : 10;
      }
    case BikeCategory.mtbEnduro:
    case BikeCategory.dh:
      if (surf == TourSurfaceKey.trail) score += 14;
      if (surf == TourSurfaceKey.gravel) score -= 18;
      if (surf == TourSurfaceKey.asphalt) score -= 22;
      if (scale == TrailDifficulty.s2) score += 10;
      if (scale == TrailDifficulty.s3 || scale == TrailDifficulty.s3plus) {
        score += 12;
      }
      if (scale == TrailDifficulty.s0) score -= 8;
    case BikeCategory.gravel:
    case BikeCategory.etrekking:
      if (surf == TourSurfaceKey.gravel) score += 22;
      if (surf == TourSurfaceKey.trail) score += 4;
      if (surf == TourSurfaceKey.asphalt) score += 6;
      if (scale == TrailDifficulty.s2) score -= 12;
      if (scale == TrailDifficulty.s3 || scale == TrailDifficulty.s3plus) {
        score -= 20;
      }
    case BikeCategory.road:
      if (surf == TourSurfaceKey.asphalt) score += 22;
      if (surf == TourSurfaceKey.gravel) score -= 6;
      if (surf == TourSurfaceKey.trail) score -= 24;
      if (scale != TrailDifficulty.open) score -= 16;
    case BikeCategory.urban:
    case BikeCategory.cargo:
    case BikeCategory.folding:
    case BikeCategory.kids:
      if (surf == TourSurfaceKey.asphalt || surf == TourSurfaceKey.mixed) {
        score += 16;
      }
      if (surf == TourSurfaceKey.trail) score -= 14;
      if (scale == TrailDifficulty.s2 ||
          scale == TrailDifficulty.s3 ||
          scale == TrailDifficulty.s3plus) {
        score -= 18;
      }
    case BikeCategory.hiking:
      if (surf == TourSurfaceKey.trail) score += 10;
      if (surf == TourSurfaceKey.asphalt) score -= 4;
  }

  if (isLoop) score += 4;
  if (durationMin > 0 && durationMin <= 90) score += 2;
  return score.clamp(12, 99);
}

List<String> tourMatchReasons({
  required BikeCategory bike,
  required List<BikeCategory> categories,
  required String surface,
  required String mtbScale,
  required int score,
}) {
  final out = <String>[];
  if (categories.contains(bike) || _softCategoryHit(bike, categories)) {
    out.add('Passt zu deinem Rad');
  }
  final surf = TourFilters.parseSurface(surface);
  final scale = parseTrailDifficulty(mtbScale);
  if ((bike == BikeCategory.mtbAm ||
          bike == BikeCategory.mtbTrail ||
          bike == BikeCategory.emtb) &&
      surf == TourSurfaceKey.trail &&
      (scale == TrailDifficulty.s0 ||
          scale == TrailDifficulty.s1 ||
          scale == TrailDifficulty.open)) {
    out.add('Kompakter Flow');
  }
  if ((bike == BikeCategory.mtbEnduro || bike == BikeCategory.dh) &&
      (scale == TrailDifficulty.s2 ||
          scale == TrailDifficulty.s3 ||
          scale == TrailDifficulty.s3plus)) {
    out.add('Technischer Charakter');
  }
  if ((bike == BikeCategory.gravel || bike == BikeCategory.etrekking) &&
      surf == TourSurfaceKey.gravel) {
    out.add('Rollender Untergrund');
  }
  if (bike == BikeCategory.road && surf == TourSurfaceKey.asphalt) {
    out.add('Asphalt, rollt');
  }
  if (score >= 80) out.add('Stark empfohlen');
  if (out.isEmpty) out.add('In der Nähe');
  return out.take(3).toList();
}

bool _softCategoryHit(BikeCategory bike, List<BikeCategory> categories) {
  const families = <BikeCategory, Set<BikeCategory>>{
    BikeCategory.mtbAm: {
      BikeCategory.mtbTrail,
      BikeCategory.mtbEnduro,
      BikeCategory.emtb,
    },
    BikeCategory.mtbTrail: {
      BikeCategory.mtbAm,
      BikeCategory.emtb,
    },
    BikeCategory.mtbEnduro: {
      BikeCategory.mtbAm,
      BikeCategory.dh,
      BikeCategory.emtb,
    },
    BikeCategory.emtb: {
      BikeCategory.mtbAm,
      BikeCategory.mtbTrail,
      BikeCategory.mtbEnduro,
    },
    BikeCategory.gravel: {
      BikeCategory.etrekking,
      BikeCategory.road,
    },
    BikeCategory.etrekking: {
      BikeCategory.gravel,
      BikeCategory.urban,
    },
    BikeCategory.road: {BikeCategory.gravel},
    BikeCategory.urban: {
      BikeCategory.cargo,
      BikeCategory.folding,
      BikeCategory.etrekking,
    },
  };
  final kin = families[bike] ?? const <BikeCategory>{};
  for (final c in categories) {
    if (kin.contains(c)) return true;
  }
  return false;
}
