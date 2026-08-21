import 'package:aetherride_mobile/data/community/tour_community_store.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_group_policy.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/tours/tour_community_ux.dart';
import 'package:flutter_test/flutter_test.dart';

SavedRouteEntry _route({
  required String id,
  required String name,
  required DateTime savedAt,
  double km = 10,
  double elevationM = 120,
  String source = 'engine',
  List<List<double>> coords = const [],
  List<List<double>> tour = const [],
}) {
  return SavedRouteEntry(
    id: id,
    name: name,
    distanceKm: km,
    elevationM: elevationM,
    durationMin: 40,
    savedAt: savedAt,
    source: source,
    coordinates: coords,
    tour: tour,
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
    expect(mappeCardStats(a), '16 km · 120 hm · 40 min');
    expect(mappeCardStatParts(a)?.km, '16 km');
    expect(mappeCardStatParts(a)?.hm, '120 hm');
    expect(mappeCardStatParts(a)?.min, '40 min');
    expect(mappeCardStats(b), isEmpty);
    expect(mappeCardStatParts(b), isNull);
    expect(savedRouteHasTrack(a), isTrue);
    expect(savedRouteHasTrack(b), isFalse);
    expect(
      mappeCardStats(
        _route(
          id: 'zero',
          name: 'Flach',
          savedAt: DateTime.utc(2026, 8, 18),
          km: 16,
          elevationM: 0,
          coords: const [
            [8.6, 49.4],
            [8.7, 49.5],
          ],
        ),
      ),
      '16 km · 40 min',
    );
    expect(
      mappeHonestHm(0, 16),
      isNull,
    );
    expect(mappeHonestHm(1670, 16), isNull);
    expect(mappeHonestHm(120, 16), 120);
    expect(mappeElevLooksInvented(480, 16), isTrue);
    expect(mappeHonestHm(480, 16), isNull);
    expect(mappeElevLooksInvented(480, 16, source: 'suggestion'), isFalse);
    expect(mappeHonestHm(480, 16, source: 'suggestion'), 480);
    expect(
      mappeElevLooksInvented(480, 16, source: 'import', hasRealElev: true),
      isFalse,
    );
    expect(mappeElevLooksInvented(480, 16, source: 'import'), isTrue);
    expect(mappeElevLooksInvented(480, 16, source: 'recorded'), isFalse);
    expect(
        mappeSourceChip('engine',
            importLabel: 'Import', recordedLabel: 'Aufgezeichnet'),
        isNull);
    expect(
      mappeSourceChip('import',
          importLabel: 'Import', recordedLabel: 'Aufgezeichnet'),
      'Import',
    );
    expect(
      mappeSourceChip('recorded',
          importLabel: 'Import', recordedLabel: 'Aufgezeichnet'),
      'Aufgezeichnet',
    );
    expect(
      mappeSourceChip(
        'library',
        importLabel: 'Import',
        recordedLabel: 'Aufgezeichnet',
        ownLabel: 'Eigene',
      ),
      'Eigene',
    );
    expect(mappeElevLooksInvented(120, 16), isFalse);
    expect(savedRouteIsLoop(a), isFalse);
    expect(savedRouteIsLoop(b), isFalse);
    expect(
      savedRouteIsLoop(
        _route(
          id: 'loop',
          name: 'Schleife',
          savedAt: DateTime.utc(2026, 8, 18),
          coords: const [
            [8.68, 49.4],
            [8.7, 49.41],
            [8.72, 49.4],
            [8.7, 49.39],
            [8.68, 49.4],
          ],
        ),
      ),
      isTrue,
    );
  });

  test('mappeStartAwayKm only with GPS and a real start', () {
    const line = [
      [8.67, 49.4],
      [8.71, 49.41],
    ];
    expect(
      mappeStartAwayKm(
        coordsLngLat: line,
        userLat: 49.4,
        userLng: 8.67,
      ),
      isNull,
    );
    expect(
      mappeStartAwayKm(
        coordsLngLat: line,
        userLat: 52.52,
        userLng: 13.4,
      ),
      greaterThan(400),
    );
    expect(
      mappeStartAwayKm(
        coordsLngLat: const [],
        userLat: 49.4,
        userLng: 8.67,
      ),
      isNull,
    );
  });

  test('mappeFaceTag skips placeholders', () {
    expect(mappeFaceTag('S2'), 'S2');
    expect(mappeFaceTag('gravel'), 'gravel');
    expect(mappeFaceTag('import'), isNull);
    expect(mappeFaceTag('offen'), isNull);
    expect(mappeFaceTag('—'), isNull);
  });

  test('mappeElevSpark only from real ele and amplitude', () {
    expect(
      mappeElevSpark(const [
        [8.6, 49.4, 100],
        [8.61, 49.4, 110],
        [8.62, 49.4, 140],
        [8.63, 49.4, 130],
      ]),
      [0, 10 / 40, 1, 30 / 40],
    );
    expect(
      mappeElevSpark(const [
        [8.6, 49.4],
        [8.61, 49.4],
      ]),
      isEmpty,
    );
  });

  test('mappeCollectionTracks keeps id order and real tracks only', () {
    final withTrack = _route(
      id: 'saved-a',
      name: 'Neckar',
      savedAt: DateTime.utc(2026, 8, 10),
      coords: const [
        [8.6, 49.4],
        [8.7, 49.5],
      ],
    );
    final noTrack = _route(
      id: 'saved-b',
      name: 'Alpenpass',
      savedAt: DateTime.utc(2026, 8, 16),
    );
    final other = _route(
      id: 'saved-c',
      name: 'See',
      savedAt: DateTime.utc(2026, 8, 18),
      coords: const [
        [8.8, 49.2],
        [8.9, 49.3],
      ],
    );
    expect(
      mappeCollectionTracks(
        routeIds: ['saved-b', 'saved-a', 'saved-c'],
        saved: [withTrack, noTrack, other],
      ).map((t) => t.first.first),
      [8.6, 8.8],
    );
    expect(
      mappeCollectionTrackCount(
        routeIds: ['saved-b', 'saved-a', 'saved-c'],
        saved: [withTrack, noTrack, other],
      ),
      2,
    );
    expect(
      mappeCollectionRestLine(toursLabel: '5 Touren', extraTracks: 2),
      '5 Touren · +2',
    );
    expect(
      mappeCollectionRestLine(toursLabel: '2 Touren', extraTracks: 0),
      '2 Touren',
    );
  });

  test('applyElevBackfill keeps catalog hm and writes ele', () {
    final flat = _route(
      id: 'saved-a',
      name: 'Neckar',
      savedAt: DateTime.utc(2026, 8, 10),
      km: 16,
      elevationM: 120,
      coords: const [
        [8.6, 49.4],
        [8.7, 49.5],
      ],
    );
    expect(savedRouteNeedsElevBackfill(flat), isTrue);
    expect(
      savedRouteNeedsElevBackfill(
        _route(
          id: 'ele',
          name: 'Mit Höhe',
          savedAt: DateTime.utc(2026, 8, 10),
          coords: const [
            [8.6, 49.4, 110],
            [8.7, 49.5, 180],
          ],
        ),
      ),
      isFalse,
    );
    final next = applyElevBackfill(
      entry: flat,
      nextCoords: const [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
      climbM: 70,
    );
    expect(next?.elevationM, 120);
    expect(next?.coordinates.first[2], 110);
    final unknown = applyElevBackfill(
      entry: _route(
        id: 'zero',
        name: 'Flach',
        savedAt: DateTime.utc(2026, 8, 10),
        elevationM: 0,
        coords: const [
          [8.6, 49.4],
          [8.7, 49.5],
        ],
      ),
      nextCoords: const [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
      climbM: 70,
    );
    expect(unknown?.elevationM, 70);
    expect(
      applyElevBackfill(
        entry: flat,
        nextCoords: const [
          [8.6, 49.4],
          [8.7, 49.5],
        ],
        climbM: 70,
      ),
      isNull,
    );
    final layered = applyElevBackfill(
      entry: _route(
        id: 'tour',
        name: 'Layer',
        savedAt: DateTime.utc(2026, 8, 10),
        elevationM: 0,
        tour: const [
          [8.1, 49.1],
          [8.2, 49.2],
        ],
      ),
      nextCoords: const [
        [8.1, 49.1, 90],
        [8.2, 49.2, 140],
      ],
      climbM: 50,
    );
    expect(layered?.tour.first[2], 90);
    expect(layered?.coordinates, isEmpty);
    final invented = applyElevBackfill(
      entry: _route(
        id: 'pct',
        name: 'Formel',
        savedAt: DateTime.utc(2026, 8, 10),
        km: 16,
        elevationM: 480,
        coords: const [
          [8.6, 49.4],
          [8.7, 49.5],
        ],
      ),
      nextCoords: const [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
      climbM: 70,
    );
    expect(invented?.elevationM, 70);
    expect(
      mappeTrackClimbM(const [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ]),
      70,
    );
    expect(
      savedRouteNeedsElevBackfill(
        _route(
          id: 'pct-ele',
          name: 'Formel mit ele',
          savedAt: DateTime.utc(2026, 8, 10),
          km: 16,
          elevationM: 480,
          coords: const [
            [8.6, 49.4, 110],
            [8.7, 49.5, 180],
          ],
        ),
      ),
      isTrue,
    );
    final catalog = applyElevBackfill(
      entry: _route(
        id: 'cat',
        name: 'Katalog',
        savedAt: DateTime.utc(2026, 8, 10),
        km: 16,
        elevationM: 480,
        source: 'suggestion',
        coords: const [
          [8.6, 49.4],
          [8.7, 49.5],
        ],
      ),
      nextCoords: const [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
      climbM: 70,
    );
    expect(catalog?.elevationM, 480);
    expect(
      mappeCardStatParts(
        _route(
          id: 'cat-face',
          name: 'Katalog',
          savedAt: DateTime.utc(2026, 8, 10),
          km: 16,
          elevationM: 480,
          source: 'suggestion',
          coords: const [
            [8.6, 49.4],
            [8.7, 49.5],
          ],
        ),
      )?.hm,
      '480 hm',
    );
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

    final session = RideGroup(
      id: 'session',
      hostUserId: 'h',
      savedRouteId: RideGroupPolicy.sessionRouteId,
      title: 'Zusammen',
      startWindowStart: now.subtract(const Duration(minutes: 10)),
      startWindowEnd: now.add(const Duration(hours: 2)),
      joinCode: 'ABCDEF',
      status: RideGroupStatus.riding,
      livePinsAllowed: true,
      createdAt: now,
    );
    expect(nextActiveMeeting([session, soon], now: now)?.id, 'soon');
  });

  test('stimmeInboxTitle never uses a raw id', () {
    expect(
      stimmeInboxTitle(untitled: 'Stimme', routeName: 'Neckar', body: 'nass'),
      'Neckar',
    );
    expect(
      stimmeInboxTitle(
        untitled: 'Stimme',
        body: 'Nasser Belag am See.\nRest',
      ),
      'Nasser Belag am See.',
    );
    expect(stimmeInboxTitle(untitled: 'Stimme'), 'Stimme');
    expect(
      stimmeInboxShowsBody(
          title: 'Nasser Belag am See.', body: 'Nasser Belag am See.\nRest'),
      isFalse,
    );
    expect(
      stimmeInboxShowsBody(title: 'Neckar', body: 'nass am See'),
      isTrue,
    );
  });
}
