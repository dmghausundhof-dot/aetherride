import 'package:aetherride_mobile/domain/routing/heatmap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('corridor heat uses real tour tracks, not demo cells', () {
    final segs = corridorHeatFromTourTracks(
      tours: [
        (
          id: 'koenigstuhl',
          coordinatesLngLat: const [
            [8.71, 49.41],
            [8.72, 49.40],
            [8.73, 49.39],
          ],
          popularity: 90,
        ),
        (
          id: 'quiet',
          coordinatesLngLat: const [
            [8.1, 49.2],
            [8.2, 49.3],
          ],
          popularity: 20,
        ),
      ],
    );
    expect(segs, hasLength(1));
    expect(segs.first.id, 'corridor-koenigstuhl');
    expect(segs.first.visible, isTrue);
    expect(segs.first.intensity, greaterThan(0.2));
  });
}
