import 'package:aetherride_mobile/domain/routing/track_elevation.dart';
import 'package:aetherride_mobile/domain/tours/tour_community_ux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const line = [
    [8.60, 49.40],
    [8.61, 49.40],
    [8.62, 49.40],
    [8.63, 49.40],
  ];

  test('zips equal-length samples without inventing extras', () {
    final out = attachRealElevToTrack(
      trackLngLat: line,
      samples: const [
        TrackElevSample(elev: 100),
        TrackElevSample(elev: 110),
        TrackElevSample(elev: 140),
        TrackElevSample(elev: 130),
      ],
    );
    expect(out.map((p) => p.length), [3, 3, 3, 3]);
    expect(out.map((p) => p[2]), [100, 110, 140, 130]);
    expect(mappeElevSpark(out), isNotEmpty);
  });

  test('places geo samples on nearest vertex only', () {
    final out = attachRealElevToTrack(
      trackLngLat: line,
      samples: const [
        TrackElevSample(elev: 90, lat: 49.40, lng: 8.60),
        TrackElevSample(elev: 160, lat: 49.40, lng: 8.63),
      ],
    );
    expect(out[0][2], 90);
    expect(out[1].length, 2);
    expect(out[2].length, 2);
    expect(out[3][2], 160);
  });

  test('does not overwrite existing ele', () {
    final out = attachRealElevToTrack(
      trackLngLat: const [
        [8.60, 49.40, 42],
        [8.61, 49.40],
        [8.62, 49.40],
        [8.63, 49.40],
      ],
      samples: const [
        TrackElevSample(elev: 90, lat: 49.40, lng: 8.60),
        TrackElevSample(elev: 160, lat: 49.40, lng: 8.61),
      ],
    );
    expect(out[0][2], 42);
    expect(out[1][2], 160);
  });

  test('skips demo source', () {
    final out = attachRealElevToTrack(
      trackLngLat: line,
      samples: const [
        TrackElevSample(elev: 100),
        TrackElevSample(elev: 200),
        TrackElevSample(elev: 300),
        TrackElevSample(elev: 400),
      ],
      source: 'demo',
    );
    expect(out.every((p) => p.length == 2), isTrue);
  });

  test('trackHasRealElev and maps parser', () {
    expect(trackHasRealElev(line), isFalse);
    expect(
      trackHasRealElev(const [
        [8.6, 49.4, 120],
        [8.7, 49.5],
      ]),
      isTrue,
    );
    final samples = trackElevSamplesFromMaps(const [
      {'lat': 49.4, 'lng': 8.6, 'elevM': 110, 'distKm': 0},
      {'lat': 49.4, 'lng': 8.61, 'elevM': 180, 'distKm': 0.8},
    ]);
    expect(samples, hasLength(2));
    expect(samples.first.elev, 110);
    expect(samples.first.lat, 49.4);
  });
}
