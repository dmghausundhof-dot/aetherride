import 'package:aetherride_mobile/domain/routing/browse_clusters.dart';
import 'package:aetherride_mobile/domain/routing/browse_lod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overview stacks nearby pins instead of dropping them', () {
    final clustered = clusterBrowsePins(
      lod: BrowseLodId.overview,
      points: const [
        BrowseMapPoint(id: 'a', lat: 49.41, lng: 8.70, popularity: 90),
        BrowseMapPoint(id: 'b', lat: 49.42, lng: 8.71, popularity: 40),
        BrowseMapPoint(id: 'c', lat: 48.00, lng: 7.80, popularity: 80),
      ],
    );
    expect(clustered, hasLength(2));
    final heidelberg = clustered.firstWhere((c) => c.count > 1);
    expect(heidelberg.count, 2);
    expect(heidelberg.popularity, 90);
  });

  test('selected pin never joins a stack', () {
    final clustered = clusterBrowsePins(
      lod: BrowseLodId.overview,
      points: const [
        BrowseMapPoint(
          id: 'sel',
          lat: 49.41,
          lng: 8.70,
          popularity: 20,
          selected: true,
        ),
        BrowseMapPoint(id: 'n', lat: 49.412, lng: 8.701, popularity: 88),
      ],
    );
    expect(clustered, hasLength(2));
    expect(clustered.every((c) => c.isSingle), isTrue);
  });

  test('detail does not cluster', () {
    final clustered = clusterBrowsePins(
      lod: BrowseLodId.detail,
      points: const [
        BrowseMapPoint(id: 'a', lat: 49.41, lng: 8.70, popularity: 90),
        BrowseMapPoint(id: 'b', lat: 49.411, lng: 8.701, popularity: 80),
      ],
    );
    expect(clustered, hasLength(2));
  });

  test('zoom hint coaches overview and network', () {
    expect(browseLodZoomHint(BrowseLodId.overview), contains('Reinzoomen'));
    expect(browseLodZoomHintTarget(BrowseLodId.overview), 11.2);
    expect(browseLodZoomHint(BrowseLodId.character), isEmpty);
    expect(browseLodPublicHeatAllowed(BrowseLodId.overview), isTrue);
    expect(browseLodPublicHeatAllowed(BrowseLodId.detail), isFalse);
  });
}
