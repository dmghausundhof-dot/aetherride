import 'package:aetherride_mobile/domain/routing/tour_filters.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:aetherride_mobile/domain/tours/route_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

SavedRouteEntry _route(String id) => SavedRouteEntry(
      id: id,
      name: id,
      distanceKm: 10,
      elevationM: 100,
      durationMin: 40,
      savedAt: DateTime.utc(2026, 8, 15),
      source: 'import',
    );

void main() {
  test('default visibility is private', () {
    expect(RouteVisibility.visibilityOf(null), RouteVisibility.private);
    expect(
      RouteVisibility.visibilityOf(SavedRouteMeta.empty),
      RouteVisibility.private,
    );
    expect(
      RouteVisibility.visibilityOf(const SavedRouteMeta()),
      RouteVisibility.private,
    );
    expect(
      SavedRouteMeta.fromJson({}).visibility,
      RouteVisibility.private,
    );
    expect(SavedRouteMeta.fromJson({}).toJson().containsKey('visibility'), isFalse);
  });

  test('shared persists, private stays default', () {
    const shared = SavedRouteMeta(visibility: RouteVisibility.shared);
    expect(shared.isEmpty, isFalse);
    expect(shared.toJson()['visibility'], 'shared');
    expect(RouteVisibility.isShared(shared), isTrue);
    expect(RouteVisibility.visibleInPublicExplore(shared), isTrue);
    expect(RouteVisibility.mayContributeSavedGeometry(shared), isTrue);
    expect(
      RouteVisibility.mayContributeSavedGeometry(SavedRouteMeta.empty),
      isFalse,
    );
  });

  test('Stimmen only for catalog or shared', () {
    expect(RouteVisibility.allowsStimmen('gpx-1'), isFalse);
    expect(RouteVisibility.stimmenTourIdOf('gpx-1'), isNull);
    expect(
      RouteVisibility.allowsStimmen(
        'gpx-2',
        const SavedRouteMeta(visibility: RouteVisibility.shared),
      ),
      isTrue,
    );
    expect(
      RouteVisibility.stimmenTourIdOf(
        'gpx-2',
        const SavedRouteMeta(visibility: RouteVisibility.shared),
      ),
      'gpx-2',
    );
    expect(
      RouteVisibility.stimmenTourIdOf(
        'saved-x',
        const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
      ),
      'r-bodensee-road',
    );
    expect(RouteVisibility.allowsStimmen('recorded-abc'), isFalse);
    expect(RouteVisibility.stimmenTourIdOf('recorded-abc'), isNull);
  });

  test('filter chips respect visibility', () {
    final routes = [_route('gpx-1'), _route('gpx-2'), _route('r-bodensee-road')];
    final metas = {
      'gpx-2': const SavedRouteMeta(visibility: RouteVisibility.shared),
      'r-bodensee-road':
          const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    };
    expect(
      RouteVisibility.filter(routes, TourVisibilityKey.allMine, metas).length,
      3,
    );
    expect(
      RouteVisibility.filter(routes, TourVisibilityKey.privateOnly, metas)
          .map((r) => r.id),
      ['gpx-1', 'r-bodensee-road'],
    );
    expect(
      RouteVisibility.filter(routes, TourVisibilityKey.sharedOnly, metas)
          .map((r) => r.id),
      ['gpx-2'],
    );
    expect(
      TourFilters.visibilityMatches(null, TourVisibilityKey.privateOnly),
      isTrue,
    );
    expect(
      TourFilters.visibilityMatches('shared', TourVisibilityKey.sharedOnly),
      isTrue,
    );
  });

  test('heatmap ride skip for private GPX, allow freeride and catalog', () {
    expect(RouteVisibility.mayContributeRide(null, null), isTrue);
    expect(
      RouteVisibility.mayContributeRide('gpx-1', SavedRouteMeta.empty),
      isFalse,
    );
    expect(
      RouteVisibility.mayContributeRide(
        'gpx-2',
        const SavedRouteMeta(visibility: RouteVisibility.shared),
      ),
      isTrue,
    );
    expect(
      RouteVisibility.mayContributeRide(
        'saved-x',
        const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
      ),
      isTrue,
    );
  });

  test('shareHonesty mentions server revoke when logged in', () {
    final text = RouteVisibility.shareHonesty(
      routeId: 'gpx-1',
      hasTrack: true,
    );
    expect(text, contains('Server'));
    expect(text, contains('eingeloggt'));
  });

  test('catalog honesty avoids öffentlich and Akte', () {
    final text = RouteVisibility.shareHonesty(
      routeId: 'r-bodensee-road',
      hasTrack: false,
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    expect(text, contains('freigegeben'));
    expect(text, isNot(contains('öffentlich')));
    expect(text, isNot(contains('Akte')));
  });

  test('collection share drops private GPX ids', () {
    expect(
      RouteVisibility.shareableRouteIds(
        ['gpx-1', 'gpx-2', 'r-bodensee-road'],
        {
          'gpx-2': const SavedRouteMeta(visibility: RouteVisibility.shared),
          'r-bodensee-road':
              const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
        },
      ),
      ['gpx-2', 'r-bodensee-road'],
    );
  });
}
