import 'package:aetherride_mobile/data/community/tour_community_store.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/tours/tour_community_ux.dart';
import 'package:flutter_test/flutter_test.dart';

SavedRouteEntry _route({
  required String id,
  required String name,
  required DateTime savedAt,
  double km = 10,
  List<List<double>> coords = const [],
}) {
  return SavedRouteEntry(
    id: id,
    name: name,
    distanceKm: km,
    elevationM: 120,
    durationMin: 40,
    savedAt: savedAt,
    coordinates: coords,
  );
}

void main() {
  final a = _route(
    id: 'saved-a',
    name: 'Neckar',
    savedAt: DateTime.utc(2026, 8, 10),
    km: 16,
    coords: const [
      [8.6, 49.4],
      [8.7, 49.5],
    ],
  );
  final b = _route(
    id: 'saved-b',
    name: 'Alpenpass',
    savedAt: DateTime.utc(2026, 8, 16),
    km: 42,
  );

  test('sortMappe recent / distance / name', () {
    final recent = sortMappe([a, b], MappeSort.recent);
    expect(recent.map((e) => e.id), ['saved-b', 'saved-a']);
    final dist = sortMappe([a, b], MappeSort.distance);
    expect(dist.map((e) => e.id), ['saved-b', 'saved-a']);
    final name = sortMappe([a, b], MappeSort.name);
    expect(name.map((e) => e.id), ['saved-b', 'saved-a']);
  });

  test('filterMappeQuery is case-insensitive name match', () {
    expect(filterMappeQuery([a, b], 'neck').single.id, 'saved-a');
    expect(filterMappeQuery([a, b], '  '), [a, b]);
    expect(filterMappeQuery([a, b], 'xyz'), isEmpty);
  });

  test('mappeCardStats only with a real track', () {
    expect(mappeCardStats(a), '16.0 km · 120 hm · 40 min');
    expect(mappeCardStats(b), isEmpty);
    expect(savedRouteHasTrack(a), isTrue);
    expect(savedRouteHasTrack(b), isFalse);
  });

  test('latestFor and condition tag', () {
    final old = TourCommunityReview(
      id: '1',
      tourId: 't1',
      rating: 4,
      body: 'alt',
      authorLabel: 'A',
      createdAt: DateTime.utc(2026, 8, 1),
      tags: const ['top'],
    );
    final neu = TourCommunityReview(
      id: '2',
      tourId: 't1',
      rating: 3,
      body: 'nass',
      authorLabel: 'B',
      createdAt: DateTime.utc(2026, 8, 16),
      tags: const ['nass', 'viel_los'],
    );
    final hit = TourCommunityReview.latestFor([old, neu], 't1');
    expect(hit?.id, '2');
    expect(hit?.conditionTag, 'nass');
    expect(TourCommunityReview.latestFor([old], 'other'), isNull);
  });

  test('nextActiveMeeting skips closed and ended windows', () {
    final now = DateTime.utc(2026, 8, 17, 12);
    RideGroup g({
      required String id,
      required RideGroupStatus status,
      required DateTime start,
      required DateTime end,
    }) {
      return RideGroup(
        id: id,
        hostUserId: 'h',
        savedRouteId: 'saved-a',
        title: id,
        startWindowStart: start,
        startWindowEnd: end,
        joinCode: 'ABCDEF',
        status: status,
        livePinsAllowed: false,
        createdAt: start,
      );
    }

    final closed = g(
      id: 'closed',
      status: RideGroupStatus.closed,
      start: now.subtract(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 2)),
    );
    final ended = g(
      id: 'ended',
      status: RideGroupStatus.open,
      start: now.subtract(const Duration(hours: 3)),
      end: now.subtract(const Duration(minutes: 1)),
    );
    final later = g(
      id: 'later',
      status: RideGroupStatus.scheduled,
      start: now.add(const Duration(hours: 6)),
      end: now.add(const Duration(hours: 9)),
    );
    final soon = g(
      id: 'soon',
      status: RideGroupStatus.open,
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 4)),
    );
    expect(
      nextActiveMeeting([closed, ended, later, soon], now: now)?.id,
      'soon',
    );
    expect(nextActiveMeeting([closed, ended], now: now), isNull);
  });
}
