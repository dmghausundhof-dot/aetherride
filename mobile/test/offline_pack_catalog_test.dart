import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/offline_pack_catalog.dart';
import 'package:aetherride_mobile/data/routing/overlay_regions.dart';

void main() {
  test('parse marks stubs without files as not downloadable', () {
    final stub = parseOfflinePackRow({
      'id': 'frankfurt-rhein-main',
      'name': 'Frankfurt Rhein-Main',
      'downloadable': false,
      'status': 'stub',
      'bytes': null,
    });
    expect(stub, isNotNull);
    expect(stub!.isReady, isFalse);
    expect(
      offlinePackSubtitle(stub, active: false, installed: false),
      'Noch nicht gebaut',
    );
  });

  test('parse infers ready from downloadable + size', () {
    final row = parseOfflinePackRow({
      'id': 'rhein-neckar',
      'name': 'Rhein-Neckar / Heidelberg',
      'bbox': [8.2, 49.2, 9.0, 49.6],
      'downloadable': true,
      'status': 'ready',
      'bytes': 10518381,
    });
    expect(row!.isReady, isTrue);
    expect(formatPackBytes(row.bytes), '10.5 MB');
    expect(
      offlinePackSubtitle(row, active: false, installed: false),
      '10.5 MB · Routing + Karte',
    );
  });

  test('mergePreferReady keeps CDN-ready over API stubs', () {
    final api = [
      parseOfflinePackRow({
        'id': 'zuerich',
        'name': 'Zürich',
        'downloadable': false,
        'status': 'stub',
      })!,
    ];
    final cdn = [
      parseOfflinePackRow({
        'id': 'zuerich',
        'name': 'Zürich',
        'downloadable': true,
        'status': 'ready',
        'bytes': 2545729,
      })!,
    ];
    final merged = mergePreferReady(api, cdn);
    expect(merged.single.isReady, isTrue);
    expect(merged.single.bytes, 2545729);
  });

  test('sort puts ready packs first, then nearest bbox', () {
    final merged = mergeOfflineCatalog(
      api: [
        parseOfflinePackRow({
          'id': 'rhein-neckar',
          'name': 'Rhein-Neckar / Heidelberg',
          'bbox': [8.2, 49.2, 9.0, 49.6],
          'downloadable': true,
          'status': 'ready',
        })!,
        parseOfflinePackRow({
          'id': 'berlin',
          'name': 'Berlin',
          'downloadable': false,
          'status': 'stub',
        })!,
      ],
      local: kOverlayRegions,
    );
    final sorted = sortOfflinePacks(
      merged,
      userLng: 8.68,
      userLat: 49.4,
    );
    expect(sorted.first.id, 'rhein-neckar');
    expect(sorted.first.bbox, isNotNull);
    expect(
      sorted.where((p) => !p.isReady).length,
      greaterThan(10),
    );
  });

  test('bundled demo copy is honest for Schwarzwald', () {
    final row = OfflinePackRow(
      id: kBundledOfflineGraphRegionId,
      name: 'Schwarzwald Süd',
    );
    expect(
      offlinePackSubtitle(row, active: false, installed: false),
      contains('Demo-Graph'),
    );
  });

  test('bbox + zoom helpers', () {
    expect(pointInLngLatBbox([8.2, 49.2, 9.0, 49.6], 8.68, 49.4), isTrue);
    expect(pointInLngLatBbox([8.2, 49.2, 9.0, 49.6], 13.4, 52.5), isFalse);
    expect(maxBasemapZoomForBbox([8.2, 49.2, 9.0, 49.6]), 13);
    expect(maxBasemapZoomForBbox([6, 47, 15, 55]), 11);
    expect(normalizeOfflineProgress(0.4), 0.4);
    expect(normalizeOfflineProgress(40), 0.4);
    expect(normalizeOfflineProgress(100), 1.0);
  });

  test('packGraphBelongsToRegion rejects bundled graph in stub folder', () {
    expect(
      packGraphBelongsToRegion(
        regionId: 'frankfurt-rhein-main',
        graphBytes: 5443442,
      ),
      isFalse,
    );
    expect(
      packGraphBelongsToRegion(
        regionId: 'frankfurt-rhein-main',
        graphBytes: 5443442,
        graphSha256: kBundledOfflineGraphSha256,
      ),
      isFalse,
    );
    expect(
      packGraphBelongsToRegion(
        regionId: kBundledOfflineGraphRegionId,
        graphBytes: 5443442,
        graphSha256: kBundledOfflineGraphSha256,
      ),
      isTrue,
    );
    expect(
      packGraphBelongsToRegion(
        regionId: 'rhein-neckar',
        graphBytes: 8 * 1024 * 1024,
        manifestId: 'rhein-neckar',
      ),
      isTrue,
    );
    expect(
      packGraphBelongsToRegion(
        regionId: 'frankfurt-rhein-main',
        graphBytes: 8 * 1024 * 1024,
        manifestId: 'schwarzwald-nord',
      ),
      isFalse,
    );
  });

  test('checkExtractedGraph catches SHA mismatch and mislabel', () {
    expect(
      checkExtractedGraph(
        regionId: 'rhein-neckar',
        graphBytes: 2000,
        actualSha256: 'aaa',
        expectedSha256: 'bbb',
        manifestId: 'rhein-neckar',
      ),
      ExtractedGraphCheck.shaMismatch,
    );
    expect(
      checkExtractedGraph(
        regionId: 'frankfurt-rhein-main',
        graphBytes: 5443442,
        actualSha256: kBundledOfflineGraphSha256,
      ),
      ExtractedGraphCheck.bundledMislabel,
    );
    expect(
      checkExtractedGraph(
        regionId: 'rhein-neckar',
        graphBytes: 8000,
        actualSha256: 'abc',
        expectedSha256: 'abc',
        manifestId: 'rhein-neckar',
      ),
      ExtractedGraphCheck.ok,
    );
  });

  test('search surfaces stubs instead of collapsing them', () {
    final rn = OfflinePackRow(
      id: 'rhein-neckar',
      name: 'Rhein-Neckar / Heidelberg',
      downloadable: true,
      status: 'ready',
      bytes: 10518381,
    );
    final ffm = OfflinePackRow(
      id: 'frankfurt-rhein-main',
      name: 'Frankfurt Rhein-Main',
    );
    final filtered = [rn, ffm];
    expect(
      visibleReadyPacks(
        filtered: filtered,
        installed: {},
        searching: false,
      ).map((r) => r.id),
      ['rhein-neckar'],
    );
    expect(
      visibleStubPacks(
        filtered: filtered,
        installed: {},
        searching: false,
      ).map((r) => r.id),
      ['frankfurt-rhein-main'],
    );
    expect(
      visibleReadyPacks(
        filtered: [ffm],
        installed: {},
        searching: true,
      ).map((r) => r.id),
      ['frankfurt-rhein-main'],
    );
    expect(
      visibleStubPacks(
        filtered: [ffm],
        installed: {},
        searching: true,
      ),
      isEmpty,
    );
  });

  test('engine status line does not duplicate hint', () {
    expect(
      offlineEngineStatusLine(
        valhallaStatus: 'offline_graph · Valhalla nicht gelinkt',
        engineHint: 'offline_graph',
      ),
      'offline_graph · Valhalla nicht gelinkt',
    );
    expect(
      offlineEngineStatusLine(
        valhallaStatus: 'offline_graph · Valhalla nicht gelinkt',
        engineHint: 'valhalla',
      ),
      'offline_graph · Valhalla nicht gelinkt · valhalla',
    );
    expect(
      honestOfflineEngineCopy(
        valhallaStatus: 'offline_graph · Valhalla-Feature verfügbar',
        engineHint: 'offline_graph',
      ),
      'Graph-Engine · Valhalla gelinkt, Region-Tiles fehlen noch',
    );
    expect(
      honestOfflineEngineCopy(
        valhallaStatus: 'offline_graph · Valhalla nicht gelinkt',
        engineHint: 'offline_graph',
      ),
      'Graph-Engine · Valhalla-Tiles nicht gebaut',
    );
  });
}
