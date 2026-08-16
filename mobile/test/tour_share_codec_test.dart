import 'package:aetherride_mobile/data/community/tour_share_codec.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tour share token roundtrip includes downsampled track', () {
    final route = SavedRouteEntry(
      id: 'gpx-share',
      name: 'Neckar',
      distanceKm: 12,
      elevationM: 80,
      durationMin: 40,
      savedAt: DateTime.utc(2026, 8, 15),
      source: 'import',
      coordinates: [
        for (var i = 0; i < 20; i++) [8.2 + i * 0.01, 49.4 + i * 0.01],
      ],
    );
    final encoded = encodeTourShareToken(route);
    expect(encoded.includeTrack, isTrue);
    expect(encoded.droppedTrack, isFalse);
    final decoded = decodeTourSharePayload(encoded.token);
    expect(decoded, isNotNull);
    expect(decoded!['kind'], 'tour');
    expect(decoded['id'], 'gpx-share');
    expect(decoded['includeTrack'], isTrue);
    expect((decoded['track'] as List).length, 20);
    expect(shareTourPath(encoded.token).startsWith('/share/t/'), isTrue);
  });
}
