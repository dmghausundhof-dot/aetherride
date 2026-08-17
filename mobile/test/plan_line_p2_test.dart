import 'package:aetherride_mobile/domain/community/filmstrip.dart';
import 'package:aetherride_mobile/domain/routing/plan_line_points.dart';
import 'package:aetherride_mobile/domain/routing/route_variant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRouteVariant', () {
    expect(parseRouteVariant('flatter'), RouteVariant.flatter);
    expect(parseRouteVariant('UNPAVED'), RouteVariant.unpaved);
    expect(parseRouteVariant('x'), RouteVariant.planned);
  });

  test('maxElevAlong uses distKm on the line', () {
    const line = <List<double>>[
      [8.67, 49.4],
      [8.68, 49.41],
      [8.69, 49.42],
    ];
    final summit = maxElevAlong(
      line: line,
      points: [
        {'distKm': 0, 'elevM': 110},
        {'distKm': 1.2, 'elevM': 180},
        {'distKm': 2.4, 'elevM': 140},
      ],
    );
    expect(summit, isNotNull);
    expect(summit!.elevM, 180);
  });

  test('filmstrip drops demo and far shots', () {
    const line = <List<double>>[
      [8.67, 49.4],
      [8.68, 49.4],
      [8.69, 49.4],
    ];
    final picked = filmstripAlongLine(
      shots: const [
        FilmstripShot(
          id: 'on',
          imageUrl: 'https://ex/a.jpg',
          lat: 49.4002,
          lng: 8.68,
          source: 'mapillary',
        ),
        FilmstripShot(
          id: 'demo',
          imageUrl: 'https://ex/d.jpg',
          lat: 49.4002,
          lng: 8.68,
          source: 'demo',
        ),
        FilmstripShot(
          id: 'far',
          imageUrl: 'https://ex/f.jpg',
          lat: 49.5,
          lng: 8.68,
          source: 'stimme',
        ),
      ],
      line: line,
    );
    expect(picked.map((e) => e.id).toList(), ['on']);
  });
}
