import 'dart:io';

import 'package:aetherride_mobile/domain/tours/add_route_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no GPS and no map → no pin, never Heidelberg', () {
    expect(resolveAddRouteStart(), isNull);
    expect(
      resolveAddRouteStart(gpsLat: null, gpsLng: null, mapLat: null, mapLng: null),
      isNull,
    );
  });

  test('GPS wins over map center', () {
    final pin = resolveAddRouteStart(
      gpsLat: 52.52,
      gpsLng: 13.4,
      mapLat: 49.41,
      mapLng: 8.69,
    );
    expect(pin!.source, AddRouteStartSource.gps);
    expect(pin.lat, 52.52);
    expect(pin.lng, 13.4);
  });

  test('map center used when GPS missing', () {
    final pin = resolveAddRouteStart(mapLat: 52.52, mapLng: 13.4);
    expect(pin!.source, AddRouteStartSource.map);
    expect(pin.lat, 52.52);
    expect(pin.lng, 13.4);
  });

  test('DACH overview and web fallback are not start pins', () {
    expect(resolveAddRouteStart(mapLat: 47.2, mapLng: 6.5), isNull);
    expect(resolveAddRouteStart(mapLat: 48.0, mapLng: 8.2), isNull);
    expect(isPlaceholderDiscoverCenter(47.2, 6.5), isTrue);
    expect(isPlaceholderDiscoverCenter(48.0, 8.2), isTrue);
    expect(isPlaceholderDiscoverCenter(52.52, 13.4), isFalse);
  });

  test('real GPS in Heidelberg stays — it is not a default', () {
    final pin = resolveAddRouteStart(gpsLat: 49.409, gpsLng: 8.694);
    expect(pin!.source, AddRouteStartSource.gps);
    expect(pin.lat, 49.409);
    expect(pin.lng, 8.694);
  });

  test('viewport JSON ignores overview zoom', () {
    expect(DiscoverViewport.fromJson({'lat': 52.52, 'lng': 13.4, 'zoom': 12}),
        isNotNull);
    expect(isLocalDiscoverZoom(5.5), isFalse);
    expect(isLocalDiscoverZoom(12), isTrue);
    expect(DiscoverViewport.fromJson('nope'), isNull);
  });

  test('Platz Mappe no longer ships Heidelberg constants', () {
    final candidates = [
      File('lib/presentation/library/mappe_screen.dart'),
      File('mobile/lib/presentation/library/mappe_screen.dart'),
    ];
    final src = candidates.firstWhere((f) => f.existsSync()).readAsStringSync();
    expect(src.contains('49.3988'), isFalse);
    expect(src.contains('8.6724'), isFalse);
    expect(src.contains('resolveAddRouteStart'), isTrue);
  });
}
