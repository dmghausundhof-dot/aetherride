import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/routing/route_shape.dart';

/// Ring mit [radiusKm] um (lat, lng) als [[lng, lat], …].
/// [closed] = letzter Punkt gleich erstem.
List<List<double>> _ring({
  double lat = 48.0,
  double lng = 8.0,
  double radiusKm = 2.0,
  int points = 32,
  bool closed = true,
}) {
  final out = <List<double>>[];
  final dLat = radiusKm / 111.0;
  final dLng = radiusKm / (111.0 * math.cos(lat * math.pi / 180));
  final n = closed ? points : (points * 0.6).round();
  for (var i = 0; i <= n; i++) {
    final a = 2 * math.pi * i / points;
    out.add([lng + dLng * math.cos(a), lat + dLat * math.sin(a)]);
  }
  return out;
}

void main() {
  test('geschlossener Ring ist ein Rundkurs', () {
    expect(routeShapeOf(_ring()), RouteShape.loop);
    expect(routeShapeLabel(_ring()), 'Rundkurs');
  });

  test('offener Bogen ist eine Strecke', () {
    final open = _ring(closed: false);
    expect(routeShapeOf(open), RouteShape.pointToPoint);
    expect(routeShapeLabel(open), 'Strecke');
  });

  test('gerade Linie ist eine Strecke', () {
    final line = [
      for (var i = 0; i < 12; i++) [8.0 + i * 0.01, 48.0],
    ];
    expect(routeShapeOf(line), RouteShape.pointToPoint);
  });

  test('unbekannt statt Rateversuch: null, zu kurz, zu wenige Punkte', () {
    expect(routeShapeOf(null), isNull);
    expect(routeShapeLabel(null), isNull);
    // Nur drei Punkte — keine Aussage.
    expect(
      routeShapeOf([
        [8.0, 48.0],
        [8.01, 48.0],
        [8.0, 48.0],
      ]),
      isNull,
    );
    // Geschlossen, aber unter 1 km Gesamtlänge — keine Aussage.
    expect(routeShapeOf(_ring(radiusKm: 0.05)), isNull);
  });

  test('kleine Lücke am Trailhead gilt noch als Rundkurs', () {
    final almost = _ring(radiusKm: 3.0);
    // Endpunkt ~150 m neben dem Start — typisches GPS-/Parkplatz-Delta.
    almost.last = [almost.first[0] + 0.002, almost.first[1]];
    expect(routeShapeOf(almost), RouteShape.loop);
  });

  test('Trailhead-Lücke ~280 m noch Rundkurs (300 m Spec-Toleranz)', () {
    final almost = _ring(radiusKm: 3.0);
    // ~0.0035° lng ≈ 280–300 m near lat 48.
    almost.last = [almost.first[0] + 0.0035, almost.first[1]];
    expect(routeShapeOf(almost), RouteShape.loop);
  });

  test('große Lücke ist keine Schleife mehr', () {
    final broken = _ring(radiusKm: 3.0);
    // Endpunkt ~5 km neben dem Start.
    broken.last = [broken.first[0] + 0.07, broken.first[1]];
    expect(routeShapeOf(broken), RouteShape.pointToPoint);
  });
}
