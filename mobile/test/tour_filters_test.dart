import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/tour_filters.dart';

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
}
