import 'package:aetherride_mobile/domain/ride_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no route is freeride until drawn or saved', () {
    expect(rideActivityKind(routeId: null), RideActivityKind.freeride);
    expect(rideActivityKind(routeId: ''), RideActivityKind.freeride);
    expect(
      rideActivityKind(routeId: null, liveTour: true),
      RideActivityKind.liveTour,
    );
    expect(
      rideActivityKind(routeId: 'recorded-abc'),
      RideActivityKind.liveTour,
    );
  });

  test('catalog or saved id is following, not a new tour', () {
    expect(
      rideActivityKind(routeId: 'seed-loop-heidelberg'),
      RideActivityKind.following,
    );
    expect(rideActivityCanDrawTour(activeRouteId: null), isTrue);
    expect(rideActivityCanDrawTour(activeRouteId: 'seed-1'), isFalse);
  });

  test('engine A–B is a navigation recap, not a catalog tour', () {
    expect(rideIsEngineNav('engine-1787060000'), isTrue);
    expect(rideIsEngineNav('seed-loop-heidelberg'), isFalse);
    expect(rideIsEngineNav(null), isFalse);
  });

  test('short session is honest about missing movement', () {
    expect(
      rideIsShortSession(distanceKm: 0.02, trackPoints: 4),
      isTrue,
    );
    expect(
      rideIsShortSession(distanceKm: 8.2, trackPoints: 1),
      isTrue,
    );
    expect(
      rideIsShortSession(distanceKm: 8.2, trackPoints: 40),
      isFalse,
    );
  });
}
