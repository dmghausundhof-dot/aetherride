import 'package:aetherride_mobile/presentation/discover/pending_ab_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rubber overlay carries the live-line km at the finger', () {
    final geo = pendingAbFeatureCollection(
      lineLngLat: [
        [8.67, 49.4],
        [8.69, 49.405],
        [8.71, 49.41],
      ],
      alongLabel: '1.5 km',
      labelLngLat: [8.69, 49.405],
    );
    final features = geo['features'] as List;
    expect(features, hasLength(2));
    expect(features[0]['geometry']['type'], 'LineString');
    expect(features[1]['geometry']['type'], 'Point');
    expect(features[1]['properties']['label'], '1.5 km');
    expect(features[1]['geometry']['coordinates'], [8.69, 49.405]);
  });

  test('shared disc can sit on the line without a km label', () {
    final geo = pendingAbFeatureCollection(
      lineLngLat: const [],
      labelLngLat: [8.69, 49.405],
    );
    final features = geo['features'] as List;
    expect(features, hasLength(1));
    expect(features.first['geometry']['type'], 'Point');
    expect(features.first['properties']['label'], '');
  });

  test('empty overlay has no invented line or km', () {
    final geo = pendingAbFeatureCollection(
      lineLngLat: const [],
      alongLabel: '1.5 km',
    );
    expect(geo['features'], isEmpty);
  });

  test('ghost without finger omits the km point', () {
    final geo = pendingAbFeatureCollection(
      lineLngLat: [
        [8.67, 49.4],
        [8.71, 49.41],
      ],
    );
    final features = geo['features'] as List;
    expect(features, hasLength(1));
    expect(features.first['geometry']['type'], 'LineString');
  });
}
