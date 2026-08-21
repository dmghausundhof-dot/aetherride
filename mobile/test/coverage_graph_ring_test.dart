import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/data/routing/coverage_graph_ring.dart';
import 'package:aetherride_mobile/data/routing/coverage_label.dart';
import 'package:aetherride_mobile/presentation/discover/offline_coverage_sketch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('occupancy ring follows a blob, not the bbox rectangle', () {
    const box = [8.0, 48.0, 9.0, 49.0];
    final pts = <List<double>>[
      for (var i = 0; i < 40; i++)
        for (var j = 0; j < 40; j++)
          if ((i - 20) * (i - 20) + (j - 20) * (j - 20) < 14 * 14)
            [8.2 + i * 0.015, 48.2 + j * 0.015],
    ];
    expect(pts.length, greaterThan(80));
    final occ = coverageOccupancy(lngLat: pts, bbox: box);
    expect(occ.solid, isFalse);
    final ring = occ.outline!;
    expect(ring.length, greaterThan(8));
    expect(ring.first, ring.last);
    expect(
      coveragePointInRing(lng: 8.5, lat: 48.5, ring: ring),
      isTrue,
    );
    expect(
      coveragePointInRing(lng: 8.05, lat: 48.05, ring: ring),
      isFalse,
    );
    expect(
      coveragePointInCoverage(
        lng: 8.05,
        lat: 48.05,
        bbox: box,
        ring: ring,
      ),
      isFalse,
    );
    expect(
      coveragePointInCoverage(lng: 8.05, lat: 48.05, bbox: box),
      isTrue,
    );
    expect(
      coverageCoversLngLats(
        points: [(lng: 8.5, lat: 48.5)],
        bbox: box,
        ring: ring,
      ),
      isTrue,
    );
    expect(
      coverageCoversLngLats(
        points: [(lng: 8.05, lat: 48.05)],
        bbox: box,
        ring: ring,
      ),
      isFalse,
    );
  });

  test('a filled rectangle extract keeps the chamfered bbox', () {
    const box = [8.0, 48.0, 9.0, 49.0];
    final pts = <List<double>>[
      for (var i = 0; i <= 40; i++)
        for (var j = 0; j <= 40; j++) [8.0 + i * 0.025, 48.0 + j * 0.025],
    ];
    final occ = coverageOccupancy(lngLat: pts, bbox: box);
    expect(occ.solid, isTrue);
    expect(occ.outline, isNull);
    expect(coverageOccupancyRing(lngLat: pts, bbox: box), isEmpty);
  });

  test('graph json cache invalidates when bytes or version change', () {
    final ring = [
      [8.0, 48.0],
      [9.0, 48.0],
      [9.0, 49.0],
      [8.0, 49.0],
      [8.0, 48.0],
    ];
    final raw = coverageRingCacheJson(ring: ring, graphBytes: 100);
    expect(
      coverageRingFromCacheJson(raw, graphBytes: 100)!.outline!.length,
      greaterThanOrEqualTo(5),
    );
    expect(coverageRingFromCacheJson(raw, graphBytes: 99), isNull);
    expect(
      coverageRingFromCacheJson(
        '{"v":2,"cells":64,"graphBytes":100,"solid":false,"ring":[[8.0,48.0],[9.0,48.0],[9.0,49.0],[8.0,49.0],[8.0,48.0]]}',
        graphBytes: 100,
      ),
      isNull,
    );
    expect(
      coverageRingFromCacheJson(
        '{"graphBytes":100,"ring":[[8.0,48.0],[9.0,48.0],[9.0,49.0],[8.0,49.0],[8.0,48.0]]}',
        graphBytes: 100,
      ),
      isNull,
    );
    final solid = coverageRingCacheJson(
      ring: const [],
      graphBytes: 50,
      solid: true,
    );
    expect(coverageRingFromCacheJson(solid, graphBytes: 50)!.solid, isTrue);
    expect(coverageRingFromCacheJson(solid, graphBytes: 50)!.outline, isNull);
  });

  test('wash geojson uses the graph ring and drops bbox ticks', () {
    const box = [8.2, 48.9, 8.6, 49.2];
    final ring = [
      [8.25, 49.0],
      [8.45, 48.95],
      [8.55, 49.05],
      [8.4, 49.15],
      [8.3, 49.12],
      [8.25, 49.0],
    ];
    final fc = coverageBboxFeatureCollection(box, ring: ring);
    final features = fc['features'] as List;
    expect(features, hasLength(2));
    final poly = features.first['geometry'] as Map;
    final coords = (poly['coordinates'] as List).first as List;
    expect(coords.length, greaterThanOrEqualTo(6));
    expect(coords.length, isNot(9));
  });

  test('plan line splits on the graph ring, not the bbox corner', () {
    final ring = [
      [8.3, 49.0],
      [8.5, 49.0],
      [8.5, 49.15],
      [8.3, 49.15],
      [8.3, 49.0],
    ];
    const box = [8.2, 48.9, 8.6, 49.2];
    final mixed = coverageSplitLineByBbox(
      lineLngLat: const [
        [8.0, 49.07],
        [8.4, 49.07],
      ],
      bbox: box,
      ring: ring,
      routingReady: true,
    );
    expect(mixed, hasLength(2));
    expect(mixed.first.outside, isTrue);
    expect(mixed.last.outside, isFalse);
  });

  test('sketch GPS is sage when the rider sits outside the occupancy ring', () {
    final ring = [
      [8.3, 49.0],
      [8.5, 49.0],
      [8.5, 49.15],
      [8.3, 49.15],
      [8.3, 49.0],
    ];
    expect(
      coverageSketchUserFill(lng: 8.4, lat: 49.07, ring: ring),
      AppColors.chrome,
    );
    expect(
      coverageSketchUserFill(lng: 8.05, lat: 48.95, ring: ring),
      AppColors.sage,
    );
    expect(
      coverageSketchUserFill(lng: 8.05, lat: 48.95, ring: null),
      AppColors.chrome,
    );
    expect(
      coverageSketchUserFill(
        lng: 8.4,
        lat: 49.07,
        ring: ring,
        streetBbox: [8.35, 49.0, 8.45, 49.1],
      ),
      AppColors.chrome,
    );
    expect(
      coverageSketchUserFill(
        lng: 8.4,
        lat: 49.07,
        ring: ring,
        streetBbox: [8.0, 48.0, 8.2, 48.2],
      ),
      AppColors.sage,
    );
  });

  test('Chaikin rounds a square without losing the interior', () {
    final square = [
      [8.0, 48.0],
      [9.0, 48.0],
      [9.0, 49.0],
      [8.0, 49.0],
      [8.0, 48.0],
    ];
    final smooth = coverageChaikinClosedRing(square);
    expect(smooth.length, greaterThan(square.length));
    expect(smooth.first, smooth.last);
    expect(
      coveragePointInRing(lng: 8.5, lat: 48.5, ring: smooth),
      isTrue,
    );
    expect(
      coveragePointInRing(lng: 7.9, lat: 47.9, ring: smooth),
      isFalse,
    );
  });

  test('sketch dots sample the graph instead of faking relief', () {
    final pts = [
      for (var i = 0; i < 400; i++) [8.0 + i * 0.001, 48.0],
    ];
    final dots = coverageSketchDots(pts, cap: 40);
    expect(dots.length, 40);
    expect(dots.first[0], 8.0);
    expect(dots.last[0], greaterThan(8.3));
    final occ = coverageOccupancy(
      lngLat: [
        for (var i = 0; i < 40; i++)
          for (var j = 0; j < 40; j++)
            if ((i - 20) * (i - 20) + (j - 20) * (j - 20) < 14 * 14)
              [8.2 + i * 0.015, 48.2 + j * 0.015],
      ],
      bbox: const [8.0, 48.0, 9.0, 49.0],
    );
    expect(occ.dots, isNotEmpty);
    expect(occ.dots.length, lessThanOrEqualTo(kCoverageSketchDotCap));
  });

  test('sketch traces sample graph edges', () {
    final decoded = {
      'nodes': [
        {'id': 'a', 'lng': 8.0, 'lat': 48.0},
        {'id': 'b', 'lng': 8.1, 'lat': 48.05},
        {'id': 'c', 'lng': 8.2, 'lat': 48.1},
      ],
      'edges': [
        {'from': 'a', 'to': 'b'},
        {'from': 'b', 'to': 'c'},
      ],
    };
    final traces = coverageSketchTracesFromGraphJson(decoded);
    expect(traces.length, 2);
    expect(traces.first, [8.0, 48.0, 8.1, 48.05]);
    final cached = coverageRingCacheJson(
      ring: const [
        [8.0, 48.0],
        [8.2, 48.0],
        [8.2, 48.1],
        [8.0, 48.1],
        [8.0, 48.0],
      ],
      graphBytes: 12,
      traces: traces,
    );
    expect(cached, contains('"v":5'));
    final hit = coverageRingFromCacheJson(cached, graphBytes: 12)!;
    expect(hit.traces.length, 2);
  });

  test('sketch traces sample graph edges', () {
    final decoded = {
      'nodes': [
        {'id': 'a', 'lng': 8.0, 'lat': 48.0},
        {'id': 'b', 'lng': 8.1, 'lat': 48.05},
        {'id': 'c', 'lng': 8.2, 'lat': 48.1},
      ],
      'edges': [
        {'from': 'a', 'to': 'b'},
        {'from': 'b', 'to': 'c'},
      ],
    };
    final traces = coverageSketchTracesFromGraphJson(decoded);
    expect(traces.length, 2);
    expect(traces.first, [8.0, 48.0, 8.1, 48.05]);
    final raw = coverageRingCacheJson(
      ring: const [
        [8.0, 48.0],
        [9.0, 48.0],
        [9.0, 49.0],
        [8.0, 49.0],
        [8.0, 48.0],
      ],
      graphBytes: 12,
      traces: traces,
    );
    expect(raw, contains('"v":$kCoverageRingCacheVersion'));
    final hit = coverageRingFromCacheJson(raw, graphBytes: 12)!;
    expect(hit.traces.length, 2);
  });
}
