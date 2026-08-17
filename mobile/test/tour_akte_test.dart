import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:aetherride_mobile/domain/tours/tour_akte.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogTourIdOf prefers explicit meta, rejects private prefixes', () {
    expect(
      catalogTourIdOf('idea-grunewald'),
      'idea-grunewald',
    );
    expect(
      catalogTourIdOf(
        'saved-abc',
        const SavedRouteMeta(catalogTourId: 'idea-grunewald'),
      ),
      'idea-grunewald',
    );
    expect(catalogTourIdOf('gpx-neckar'), isNull);
    expect(catalogTourIdOf('recorded-1'), isNull);
    expect(catalogTourIdOf('import-2'), isNull);
    expect(catalogTourIdOf('library-3'), isNull);
    expect(catalogTourIdOf('engine-123'), isNull);
  });

  test('wear is counter minus install snapshot, not the snapshot', () {
    const bike = Bike(
      id: 'b1',
      name: 'Luna',
      category: BikeCategory.mtbAm,
      odometerKm: 2200,
      hours: 80,
    );
    const chain = BikeComponent(
      id: 'c1',
      bikeId: 'b1',
      slot: ComponentSlot.chain,
      odometerKm: 1000,
      hoursAtInstall: 20,
    );
    final wear = componentWearSinceInstall(bike, chain);
    expect(wear.km, 1200);
    expect(wear.hours, 60);
  });

  test('formatTourCount is singular for one', () {
    expect(formatTourCount(1, suffix: 'in der Mappe'), '1 Tour in der Mappe');
    expect(formatTourCount(2, suffix: 'in der Mappe'), '2 Touren in der Mappe');
    expect(formatTourCount(0), '0 Touren');
  });

  test('startRidePendingIdForGroup nimmt Mappe oder Katalog, nicht library-fremd',
      () {
    final saved = SavedRouteEntry(
      id: 'saved-abc',
      name: 'Neckar',
      distanceKm: 16,
      elevationM: 80,
      durationMin: 60,
      savedAt: DateTime.utc(2026, 8, 15),
    );
    const metas = {
      'saved-abc': SavedRouteMeta(catalogTourId: 'r-heidelberg-city'),
    };
    expect(
      startRidePendingIdForGroup(
        savedRouteId: 'saved-abc',
        catalogTourId: 'r-heidelberg-city',
        saved: [saved],
        metas: metas,
      ),
      'saved-abc',
    );
    expect(
      startRidePendingIdForGroup(
        savedRouteId: 'library-fremd',
        catalogTourId: 'r-heidelberg-city',
        saved: const [],
        metas: const {},
      ),
      'r-heidelberg-city',
    );
    expect(
      startRidePendingIdForGroup(
        savedRouteId: 'library-fremd',
        catalogTourId: null,
        saved: const [],
        metas: const {},
      ),
      isNull,
    );
    expect(
      startRidePendingIdForGroup(
        savedRouteId: 'r-bodensee-road',
        catalogTourId: null,
        saved: const [],
        metas: const {},
      ),
      'r-bodensee-road',
    );
  });

  test('resolveAkteSavedRoute matches id or catalog join', () {
    final saved = SavedRouteEntry(
      id: 'saved-abc',
      name: 'Neckar',
      distanceKm: 16,
      elevationM: 80,
      durationMin: 60,
      savedAt: DateTime.utc(2026, 8, 15),
    );
    const metas = {
      'saved-abc': SavedRouteMeta(catalogTourId: 'r-heidelberg-city'),
    };
    expect(
      resolveAkteSavedRoute(
        pendingId: 'saved-abc',
        saved: [saved],
        metas: metas,
      )?.id,
      'saved-abc',
    );
    expect(
      resolveAkteSavedRoute(
        pendingId: 'r-heidelberg-city',
        saved: [saved],
        metas: metas,
      )?.id,
      'saved-abc',
    );
    expect(
      resolveAkteSavedRoute(
        pendingId: 'other',
        saved: [saved],
        metas: metas,
      ),
      isNull,
    );
  });

  test('buildHofTafel is at most three lines and counts all saved routes', () {
    final lines = buildHofTafel(
      careText: 'Kette — in der Werkstatt',
      stimmenText: 'Neue Stimme zu Neckar',
      groupText: 'Gruppe vor dem Tor · Freitag',
      savedCount: 2,
    );
    expect(lines.map((e) => e.kind), [
      HofTafelKind.care,
      HofTafelKind.gruppe,
      HofTafelKind.stimmen,
    ]);
    final mappeOnly = buildHofTafel(savedCount: 1);
    expect(mappeOnly, hasLength(1));
    expect(mappeOnly.first.kind, HofTafelKind.mappe);
    expect(mappeOnly.first.text, '1 Tour');
  });

  test('shouldAssignRideWear rejects unknown and empty', () {
    expect(shouldAssignRideWear(null), isFalse);
    expect(shouldAssignRideWear(''), isFalse);
    expect(shouldAssignRideWear('unknown'), isFalse);
    expect(shouldAssignRideWear('bike-1'), isTrue);
  });
}
