import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/tour_filters.dart';
import 'package:aetherride_mobile/domain/routing/trail_difficulty.dart';

void main() {
  group('TourFilters surface', () {
    test('parses catalog and seed surfaces', () {
      expect(TourFilters.parseSurface('asphalt/bike-lane'), TourSurfaceKey.asphalt);
      expect(TourFilters.parseSurface('gravel/asphalt'), TourSurfaceKey.gravel);
      expect(TourFilters.parseSurface('trail/forest'), TourSurfaceKey.trail);
      expect(TourFilters.parseSurface('flow/compact'), TourSurfaceKey.gravel);
      expect(TourFilters.parseSurface('mixed/urban'), TourSurfaceKey.mixed);
    });

    test('soft surface groups match related beläge', () {
      expect(
        TourFilters.surfaceMatches('asphalt/paved', TourSurfaceKey.asphalt),
        isTrue,
      );
      expect(
        TourFilters.surfaceMatches('mixed/urban', TourSurfaceKey.asphalt),
        isTrue,
      );
      expect(
        TourFilters.surfaceMatches('trail/root', TourSurfaceKey.asphalt),
        isFalse,
      );
    });
  });

  group('TourFilters effort', () {
    test('unrated catalog tours match easy+mid, not hard', () {
      expect(TourFilters.effortMatches('—', TourEffortKey.easy), isTrue);
      expect(TourFilters.effortMatches('—', TourEffortKey.mid), isTrue);
      expect(TourFilters.effortMatches('—', TourEffortKey.hard), isFalse);
    });

    test('S-scale and effort labels', () {
      expect(TourFilters.effortMatches('S0', TourEffortKey.easy), isTrue);
      expect(TourFilters.effortMatches('S1–S2', TourEffortKey.mid), isTrue);
      expect(TourFilters.effortMatches('S2–S3', TourEffortKey.hard), isTrue);
      expect(TourFilters.effortMatches('Leicht', TourEffortKey.easy), isTrue);
      expect(TourFilters.effortMatches('Mittel', TourEffortKey.mid), isTrue);
    });
  });

  group('TourFilters elevation / distance', () {
    test('elevation bands', () {
      expect(TourFilters.elevationMatches(80, TourElevationKey.flat), isTrue);
      expect(TourFilters.elevationMatches(700, TourElevationKey.hilly), isTrue);
      expect(
        TourFilters.elevationMatches(1200, TourElevationKey.alpine),
        isTrue,
      );
    });

    test('distance max', () {
      expect(TourFilters.distanceMatches(19.5, 20), isTrue);
      expect(TourFilters.distanceMatches(40.1, 40), isFalse);
      expect(TourFilters.distanceMatches(100, null), isTrue);
    });
  });

  group('TourFilters form / downhill / S-scale', () {
    test('form chips include loop, A→B and downhill', () {
      expect(
        TourFilters.formFilterChips,
        containsAll([
          TourFormKey.all,
          TourFormKey.loop,
          TourFormKey.pointToPoint,
          TourFormKey.downhill,
        ]),
      );
    });

    test('downhill from category or tags, not from a gravel loop', () {
      expect(
        TourFilters.isDownhillTour(
          categories: [BikeCategory.dh],
          tags: const [],
          title: 'Königstuhl Line',
          isLoop: false,
        ),
        isTrue,
      );
      expect(
        TourFilters.isDownhillTour(
          categories: [BikeCategory.mtbEnduro],
          tags: const [],
          title: 'Enduro A nach B',
          isLoop: false,
        ),
        isTrue,
      );
      expect(
        TourFilters.isDownhillTour(
          categories: [BikeCategory.mtbEnduro],
          tags: const [],
          title: 'Enduro Runde',
          isLoop: true,
        ),
        isFalse,
      );
      expect(
        TourFilters.isDownhillTour(
          categories: [BikeCategory.gravel],
          tags: const ['gravel'],
          title: 'Neckartal Gravel',
          isLoop: false,
        ),
        isFalse,
      );
    });

    test('S-scale range S1–S2 matches S1 and S2, not S3', () {
      final grades = trailDifficultiesIn('S1–S2');
      expect(grades, containsAll([TrailDifficulty.s1, TrailDifficulty.s2]));
      expect(grades.contains(TrailDifficulty.s3), isFalse);
      expect(
        TourFilters.scaleMatches(
          'S1–S2',
          [BikeCategory.mtbAm],
          {TrailDifficulty.s2},
        ),
        isTrue,
      );
      expect(
        TourFilters.scaleMatches(
          'S1–S2',
          [BikeCategory.mtbAm],
          {TrailDifficulty.s3},
        ),
        isFalse,
      );
    });

    test('S3 and S3+ stay distinct', () {
      expect(parseTrailDifficulty('S3'), TrailDifficulty.s3);
      expect(parseTrailDifficulty('S3+'), TrailDifficulty.s3plus);
      expect(parseTrailDifficulty('4'), TrailDifficulty.s3plus);
      expect(trailDifficultyLabel(TrailDifficulty.s3), 'S3');
    });

    test('gravel effort is not mapped to S-scale', () {
      expect(
        TourFilters.honestScaleTag(
          effortLabel: 'Leicht',
          categories: [BikeCategory.gravel, BikeCategory.road],
        ),
        'offen',
      );
      expect(
        TourFilters.honestScaleTag(
          effortLabel: 'Leicht',
          categories: [BikeCategory.mtbAm],
        ),
        'S0',
      );
    });

    test('unrated tours miss S-grade filter (honest empty)', () {
      expect(
        TourFilters.scaleMatches(
          '—',
          [BikeCategory.road],
          {TrailDifficulty.s0},
        ),
        isFalse,
      );
    });

    test('sport hard-filter gravel vs mtb', () {
      expect(
        TourFilters.sportMatches(
          [BikeCategory.gravel],
          [TourSportKey.gravel],
        ),
        isTrue,
      );
      expect(
        TourFilters.sportMatches(
          [BikeCategory.road],
          [TourSportKey.gravel],
        ),
        isFalse,
      );
      expect(
        TourFilters.sportMatches(
          [BikeCategory.road],
          const [],
        ),
        isTrue,
      );
      expect(
        TourFilters.sportOf([BikeCategory.dh]),
        TourSportKey.dh,
      );
      expect(
        TourFilters.sportOf([BikeCategory.road]),
        TourSportKey.road,
      );
    });

    test('inferCategories does not stamp MTB on city rides', () {
      expect(
        TourFilters.inferCategories(title: 'Heidelberg City Loop', type: 'city'),
        isNot(contains(BikeCategory.mtbAm)),
      );
      expect(
        TourFilters.inferCategories(title: 'Bikepark Flow', type: 'dh'),
        contains(BikeCategory.dh),
      );
    });
  });

  group('TourFilters soft sport', () {
    test('family proximity for e-mtb / touring', () {
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.mtbAm],
          BikeCategory.emtb,
        ),
        isTrue,
      );
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.road, BikeCategory.gravel],
          BikeCategory.etrekking,
        ),
        isTrue,
      );
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.road],
          BikeCategory.mtbAm,
        ),
        isFalse,
      );
      expect(
        TourFilters.softSportMatchAny(
          [BikeCategory.road],
          [BikeCategory.mtbAm, BikeCategory.road],
        ),
        isTrue,
      );
      expect(
        TourFilters.softSportMatchAny(
          [BikeCategory.road],
          [BikeCategory.mtbAm],
        ),
        isFalse,
      );
    });

    test('E-City (urban) vs E-MTB soft-match diverge', () {
      // Persistierte E-City = urban (+ isEbike); Soft-Match über Kategorie.
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.urban],
          BikeCategory.urban,
        ),
        isTrue,
      );
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.mtbAm, BikeCategory.emtb],
          BikeCategory.urban,
        ),
        isFalse,
      );
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.urban],
          BikeCategory.emtb,
        ),
        isFalse,
      );
      expect(
        TourFilters.softSportMatch(
          [BikeCategory.emtb],
          BikeCategory.emtb,
        ),
        isTrue,
      );
    });
  });

  group('TourFilters visibility', () {
    test('default missing field is private', () {
      expect(
        TourFilters.visibilityMatches(null, TourVisibilityKey.allMine),
        isTrue,
      );
      expect(
        TourFilters.visibilityMatches(null, TourVisibilityKey.privateOnly),
        isTrue,
      );
      expect(
        TourFilters.visibilityMatches(null, TourVisibilityKey.sharedOnly),
        isFalse,
      );
      expect(
        TourFilters.visibilityMatches('shared', TourVisibilityKey.sharedOnly),
        isTrue,
      );
      expect(
        TourFilters.visibilityMatches('private', TourVisibilityKey.sharedOnly),
        isFalse,
      );
    });
  });

  group('TourFilters S-scale sheet visibility', () {
    test('City overlay hides S-scale unless MTB/DH filter', () {
      expect(
        TourFilters.filterSheetShowsSScale(
          mtbOverlayFamily: false,
          sportFilter: {},
          form: TourFormKey.all,
        ),
        isFalse,
      );
      expect(
        TourFilters.filterSheetShowsSScale(
          mtbOverlayFamily: false,
          sportFilter: {TourSportKey.urban, TourSportKey.road},
          form: TourFormKey.all,
        ),
        isFalse,
      );
      expect(
        TourFilters.filterSheetShowsSScale(
          mtbOverlayFamily: true,
          sportFilter: {},
          form: TourFormKey.all,
        ),
        isTrue,
      );
      expect(
        TourFilters.filterSheetShowsSScale(
          mtbOverlayFamily: false,
          sportFilter: {TourSportKey.mtb},
          form: TourFormKey.all,
        ),
        isTrue,
      );
      expect(
        TourFilters.filterSheetShowsSScale(
          mtbOverlayFamily: false,
          sportFilter: {},
          form: TourFormKey.downhill,
        ),
        isTrue,
      );
    });
  });

  group('TourFilters honest sport label', () {
    test('lone ebike on asphalt is city', () {
      expect(
        TourFilters.honestSportLabel(
          sportLabel: 'ebike',
          surface: 'asphalt/paved',
        ),
        'city',
      );
      expect(
        TourFilters.honestSportLabel(
          sportLabel: 'gravel',
          surface: 'gravel/compacted',
        ),
        'gravel',
      );
    });
  });

  group('TourFilters primary UX defaults', () {
    test('primary quick chips stay aligned with chip catalogs', () {
      expect(TourFilters.primaryQuickDurationMin, 60);
      expect(TourFilters.primaryQuickDistanceKm, 40);
      expect(TourFilters.primaryQuickSurface, TourSurfaceKey.asphalt);
      expect(
        TourFilters.distanceMaxChips.map((c) => c.id),
        contains(TourFilters.primaryQuickDistanceKm),
      );
      expect(
        TourFilters.surfaceChipLabel(TourFilters.primaryQuickSurface),
        'Asphalt',
      );
    });
  });

  group('browse tour markers', () {
    test('map badge is minutes, never GR/RR', () {
      expect(TourFilters.browseTourTimeLabel(55), '55′');
      expect(TourFilters.browseTourTimeLabel(0), '');
      expect(TourFilters.pinLabel(TourSportKey.gravel), 'GR');
      expect(
        TourFilters.browseTourShowsTime(selected: true, zoom: 12),
        isTrue,
      );
      expect(
        TourFilters.browseTourShowsTime(selected: false, zoom: 14),
        isFalse,
      );
    });
  });
}
