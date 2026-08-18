import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/community/community_seed.dart';
import 'package:aetherride_mobile/domain/tours/tour_function_copy.dart';
import 'package:aetherride_mobile/domain/tours/tour_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reference tour exposes every function including event and club', () {
    const cats = [
      BikeCategory.gravel,
      BikeCategory.road,
      BikeCategory.etrekking,
      BikeCategory.urban,
    ];
    final events = eventsForTour(referenceTourId);
    expect(events, hasLength(1));
    expect(events.first.id, 'ev-neckar-voll');
    final clubs = clubsForTour(
      tourId: referenceTourId,
      regionSlug: 'rhein-neckar',
      categories: cats,
    );
    expect(clubs.any((c) => c.id == 'cl-rn-allround'), isTrue);
    final states = tourFunctionStates(
      tourId: referenceTourId,
      regionSlug: 'rhein-neckar',
      categories: cats,
    );
    expect(states.length, tourFunctionIds.length);
    expect(states.every((s) => s.available), isTrue);
  });

  test('every editorial event points at a catalog tour id', () {
    for (final event in communityEventSeeds) {
      expect(event.catalogTourId, isNotNull);
      expect(event.regionSlug, isNotEmpty);
    }
    expect(eventsForTour('r-heidelberg-city').first.id, 'ev-city-hd');
    expect(eventsForTour('missing'), isEmpty);
    expect(eventsForRegionSlug('rhein-neckar').length, greaterThanOrEqualTo(2));
  });

  test('sport match mirrors web catalog filters', () {
    const cats = [
      BikeCategory.gravel,
      BikeCategory.road,
      BikeCategory.etrekking,
      BikeCategory.urban,
    ];
    expect(tourMatchesSport(cats, 'gravel'), isTrue);
    expect(tourMatchesSport(cats, 'road'), isTrue);
    expect(tourMatchesSport(cats, 'urban'), isTrue);
    expect(tourMatchesSport(cats, 'hiking'), isFalse);
    expect(tourMatchesSport(cats, 'mtb'), isFalse);
  });

  test('copy keys cover every function id', () {
    for (final lang in ['de', 'en', 'fr', 'it', 'nl']) {
      final copy = tourFunctionCopy(lang);
      for (final id in tourFunctionIds) {
        expect(copy.label(id), isNot(id), reason: '$lang $id');
      }
    }
  });
}
