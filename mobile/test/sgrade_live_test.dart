import 'package:aetherride_mobile/data/routing/osm_trail_network_client.dart';
import 'package:aetherride_mobile/data/routing/sgrade_live.dart';
import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';
import 'package:aetherride_mobile/domain/routing/trail_difficulty.dart';
import 'package:aetherride_mobile/domain/routing/tour_nav_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

OsmTrailSegment _seg({
  required TrailDifficulty difficulty,
  List<List<double>> geometry = const [
    [8.70, 49.40],
    [8.71, 49.41],
    [8.72, 49.42],
  ],
}) {
  return OsmTrailSegment(
    id: 'osm-way-1',
    name: 'Trail ${trailDifficultyLabel(difficulty)}',
    difficulty: difficulty,
    lengthKm: 0.4,
    center: const LatLng(49.41, 8.71),
    geometry: geometry,
    highway: 'path',
  );
}

void main() {
  test('S-Grade live fetch only with overlay + MTB class + character zoom', () {
    expect(
      shouldFetchSGradeLive(
        overlayOn: true,
        extraOn: kAllPaintedOverlayClasses,
        zoom: 12.5,
      ),
      isTrue,
    );
    expect(
      shouldFetchSGradeLive(
        overlayOn: true,
        extraOn: kAllPaintedOverlayClasses,
        zoom: 11,
      ),
      isFalse,
    );
    expect(
      shouldFetchSGradeLive(
        overlayOn: false,
        extraOn: kAllPaintedOverlayClasses,
        zoom: 14,
      ),
      isFalse,
    );
    expect(
      shouldFetchSGradeLive(
        overlayOn: true,
        extraOn: {BikeOverlayClass.road, BikeOverlayClass.gravel},
        zoom: 14,
      ),
      isFalse,
    );
    expect(
      shouldFetchSGradeLive(
        overlayOn: true,
        extraOn: {BikeOverlayClass.mtb},
        zoom: 10.9,
      ),
      isFalse,
    );
  });

  test('honest S-Grade collection drops offen / short / no TF pins', () {
    final fc = sGradeFeatureCollection([
      _seg(difficulty: TrailDifficulty.s0),
      _seg(difficulty: TrailDifficulty.s2),
      _seg(difficulty: TrailDifficulty.s3plus),
      _seg(difficulty: TrailDifficulty.open),
      _seg(
        difficulty: TrailDifficulty.s1,
        geometry: const [
          [8.70, 49.40],
        ],
      ),
    ]);
    final features = fc['features'] as List;
    expect(features, hasLength(3));
    for (final raw in features) {
      final f = raw as Map;
      expect(f['geometry'], isA<Map>());
      expect((f['geometry'] as Map)['type'], 'LineString');
      expect(f['geometry'], isNot(contains('Point')));
      final props = f['properties'] as Map;
      expect(props['bike_class'], 'mtb');
      expect(
        props['mtb_scale'],
        anyOf('S0', 'S1', 'S2', 'S3', 'S3+'),
      );
    }
    expect(shouldDrawTrailforksMapPin(), isFalse);
    expect(
      shouldDrawTrailforksMapPin(
        trackLngLat: [
          [8.70, 49.40],
          [8.76, 49.43],
        ],
      ),
      isFalse,
    );
  });

  test('viewport bbox is clamped so Overpass stays local', () {
    final box = clampSGradeBbox(
      west: 2,
      south: 43,
      east: 10,
      north: 51,
    );
    expect(box.east - box.west, closeTo(kOsmSGradeMaxBboxDeg, 1e-9));
    expect(box.north - box.south, closeTo(kOsmSGradeMaxBboxDeg, 1e-9));
    expect((box.west + box.east) / 2, closeTo(6, 1e-9));
    expect((box.south + box.north) / 2, closeTo(47, 1e-9));
  });
}
