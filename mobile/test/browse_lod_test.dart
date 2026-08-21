import 'package:aetherride_mobile/domain/routing/browse_lod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four lod bands match Komoot-style tasks', () {
    expect(browseLodFromZoom(8.2).id, BrowseLodId.overview);
    expect(browseLodFromZoom(10).id, BrowseLodId.network);
    expect(browseLodFromZoom(12.4).id, BrowseLodId.network);
    expect(browseLodFromZoom(12.5).id, BrowseLodId.character);
    expect(browseLodFromZoom(15.4).id, BrowseLodId.character);
    expect(browseLodFromZoom(15.5).id, BrowseLodId.detail);
    expect(BrowseLodBands.all, hasLength(4));
    expect(browseLodFromZoom(9).label, 'Überblick');
    expect(browseLodFromZoom(11).task, contains('Trailnetz'));
  });

  test('overview hides sparse trails, selected always stays', () {
    expect(
      browseLodPinVisible(
        lod: BrowseLodId.overview,
        popularity: 55,
        selected: false,
      ),
      isFalse,
    );
    expect(
      browseLodPinVisible(
        lod: BrowseLodId.overview,
        popularity: 80,
        selected: false,
      ),
      isTrue,
    );
    expect(
      browseLodPinVisible(
        lod: BrowseLodId.overview,
        popularity: 10,
        selected: true,
      ),
      isTrue,
    );
    expect(
      browseLodPinVisible(
        lod: BrowseLodId.network,
        popularity: 50,
        selected: false,
      ),
      isTrue,
    );
    expect(
      browseLodPinVisible(
        lod: BrowseLodId.character,
        popularity: 12,
        selected: false,
      ),
      isTrue,
    );
  });

  test('heatmap is the overview language and leaves the detail line', () {
    expect(browseLodShowsHeatmap(BrowseLodId.overview), isTrue);
    expect(browseLodShowsHeatmap(BrowseLodId.detail), isFalse);
    expect(
      browseLodHeatOpacity(BrowseLodId.overview, 0.6),
      greaterThan(browseLodHeatOpacity(BrowseLodId.character, 0.6)),
    );
    expect(browseLodHeatWidth(BrowseLodId.detail, 1), 0);
    expect(browseLodShowsTrailNetwork(BrowseLodId.overview), isFalse);
    expect(browseLodShowsTrailNetwork(BrowseLodId.network), isTrue);
    expect(browseLodShowsSurfaceStyle(BrowseLodId.network), isFalse);
    expect(browseLodShowsSurfaceStyle(BrowseLodId.character), isTrue);
    expect(browseLodShowsPhotos(BrowseLodId.character), isTrue);
    expect(browseLodShowsFineDetail(BrowseLodId.detail), isTrue);
    expect(browseLodShowsFineDetail(BrowseLodId.character), isFalse);
    expect(browseLodShowsCoveragePlaces(BrowseLodId.network), isFalse);
    expect(browseLodShowsStimmePlaces(BrowseLodId.network), isTrue);
  });

  test('lod change always needs a full map resync', () {
    expect(
      browseLodNeedsFullResync(BrowseLodId.overview, BrowseLodId.network),
      isTrue,
    );
    expect(
      browseLodNeedsFullResync(BrowseLodId.character, BrowseLodId.character),
      isFalse,
    );
    expect(BrowseLodBands.corridorMinZoom, lessThan(BrowseLodBands.network.minZoom));
    expect(BrowseLodBands.corridorMinZoom, greaterThanOrEqualTo(7));
  });
}
