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
}
