import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/saved_route.dart';

void main() {
  test('SavedRoute JSON roundtrip keeps waypoints and layers', () {
    final waypoints = waypointsToJson(const [
      SavedWaypoint(role: 'start', lng: 8.4, lat: 48.0, label: 'Start'),
      SavedWaypoint(role: 'via', lng: 8.41, lat: 48.01, label: 'Via 1'),
      SavedWaypoint(role: 'end', lng: 8.42, lat: 48.02, label: 'Ziel'),
    ]);
    final again = waypointsFromJson(waypoints);
    expect(again, hasLength(3));
    expect(again[1].role, 'via');
    expect(again[1].lng, 8.41);

    final layersRaw = layersToJson(
      approach: const [
        [8.4, 48.0],
        [8.405, 48.005],
      ],
      trail: const [
        [8.41, 48.01],
        [8.42, 48.02],
      ],
    );
    expect(layersRaw, isNotNull);
    final layers = layersFromJson(layersRaw);
    expect(layers.approach, hasLength(2));
    expect(layers.trail, hasLength(2));
    expect(layers.tour, isEmpty);

    final geom = coordsToJson(const [
      [8.4, 48.0],
      [8.42, 48.02],
    ]);
    expect(coordsFromJson(geom), hasLength(2));
  });
}
