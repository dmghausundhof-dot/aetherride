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
      '10.5 MB · Routing',
    );
    expect(
      offlinePackSubtitle(row, active: true, installed: true),
      'Aktiv',
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

  test('inferPackKind splits city / envelope / europe', () {
    expect(
      inferPackKind(
        const OfflinePackRow(
            id: 'berlin', name: 'Berlin', bbox: [13.1, 52.3, 13.7, 52.7]),
      ),
      OfflinePackKind.city,
    );
    expect(
      inferPackKind(
        const OfflinePackRow(id: 'de-saarland', name: 'Saarland'),
      ),
      OfflinePackKind.envelope,
    );
    expect(
      inferPackKind(
        const OfflinePackRow(
          id: 'milano',
          name: 'Mailand',
          bbox: [9.05, 45.38, 9.3, 45.55],
        ),
      ),
      OfflinePackKind.europe,
    );
    expect(
      inferPackKind(
        const OfflinePackRow(
          id: 'paris',
          name: 'Paris',
          bbox: [2.2, 48.8, 2.48, 48.92],
        ),
      ),
      OfflinePackKind.europe,
    );
    expect(isEnvelopePackId('ch-wallis'), isTrue);
    expect(isEnvelopePackId('li-liechtenstein'), isTrue);
    expect(isEnvelopePackId('berlin'), isFalse);
    expect(skipFitCameraForPackId('de-bayern'), isTrue);
    expect(skipFitCameraForPackId('karlsruhe'), isFalse);
    expect(skipFitCameraForPackId(null), isFalse);
    expect(skipFitCameraForPackId(''), isFalse);
    expect(kEnvelopePackNames['de-saarland'], 'Saarland');
    expect(kEnvelopePackNames['de-bayern'], 'Bayern');
    expect(isEnvelopePackId('de-saarland'), isTrue);
    expect(
        envelopePackDisplayName(id: 'ch-wallis', languageCode: 'de'), 'Wallis');
    expect(
        envelopePackDisplayName(id: 'ch-wallis', languageCode: 'fr'), 'Valais');
    expect(
        envelopePackDisplayName(id: 'ch-tessin', languageCode: 'it'), 'Ticino');
    expect(
        envelopePackDisplayName(id: 'de-bayern', languageCode: 'fr'), 'Bayern');
  });

  test('disk bbox wins over inflated prefs', () {
    const disk = [8.2, 49.2, 9.0, 49.6];
    const prefs = [6.0, 47.0, 15.0, 55.0];
    expect(
      preferDiskPackBbox(fromDisk: disk, fromPrefs: prefs),
      disk,
    );
    expect(
      preferDiskPackBbox(fromDisk: null, fromPrefs: prefs),
      prefs,
    );
    expect(preferDiskPackBbox(fromDisk: const [1], fromPrefs: prefs), prefs);
    expect(preferDiskPackBbox(fromDisk: null, fromPrefs: null), isNull);
    expect(
      bboxCoversLngLats(preferDiskPackBbox(fromDisk: disk, fromPrefs: prefs)!, [
        (lng: 8.68, lat: 49.41),
        (lng: 8.47, lat: 49.48),
      ]),
      isTrue,
    );
    expect(
      bboxCoversLngLats(preferDiskPackBbox(fromDisk: disk, fromPrefs: prefs)!, [
        (lng: 11.3, lat: 47.4),
      ]),
      isFalse,
    );
    expect(
      bboxCoversLngLats(prefs, [(lng: 11.3, lat: 47.4)]),
      isTrue,
    );
  });

  test('suggested pack is the smallest bbox covering the point', () {
    final rn = OfflinePackRow(
      id: 'rhein-neckar',
      name: 'Rhein-Neckar',
      bbox: [8.2, 49.2, 9.0, 49.6],
      downloadable: true,
      status: 'ready',
    );
    final env = OfflinePackRow(
      id: 'de-baden-wuerttemberg',
      name: 'Baden-Württemberg',
      bbox: [7.5, 47.5, 10.5, 49.8],
      downloadable: true,
      status: 'ready',
    );
    final hit = suggestedPackForPoint(
      packs: [env, rn],
      lng: 8.68,
      lat: 49.4,
    );
    expect(hit?.id, 'rhein-neckar');
  });

  test('download CTA stays off when the suggested pack is already installed',
      () {
    expect(
      shouldOfferOfflinePackDownload(
        covered: true,
        suggestedPackId: 'karlsruhe',
        installedIds: {'karlsruhe'},
        hasActivatedPack: true,
      ),
      isFalse,
    );
    expect(
      shouldOfferOfflinePackDownload(
        covered: false,
        suggestedPackId: 'karlsruhe',
        installedIds: {'karlsruhe'},
        hasActivatedPack: true,
      ),
      isFalse,
    );
    expect(
      shouldOfferOfflinePackDownload(
        covered: false,
        suggestedPackId: 'muenchen',
        installedIds: {'karlsruhe'},
        hasActivatedPack: true,
      ),
      isTrue,
    );
    expect(
      shouldOfferOfflinePackDownload(
        covered: false,
        suggestedPackId: null,
        installedIds: {'karlsruhe'},
        hasActivatedPack: true,
      ),
      isFalse,
    );
    expect(
      shouldOfferOfflinePackDownload(
        covered: false,
        suggestedPackId: null,
        installedIds: {},
        hasActivatedPack: false,
      ),
      isTrue,
    );
  });

  test('suggested pack for route prefers bbox covering both ends', () {
    final rn = OfflinePackRow(
      id: 'rhein-neckar',
      name: 'Rhein-Neckar',
      bbox: [8.2, 49.2, 9.0, 49.6],
      downloadable: true,
      status: 'ready',
      graphBytes: 10518381,
    );
    final berlin = OfflinePackRow(
      id: 'berlin',
      name: 'Berlin',
      bbox: [13.0, 52.3, 13.8, 52.7],
      downloadable: true,
      status: 'ready',
    );
    final env = OfflinePackRow(
      id: 'de-baden-wuerttemberg',
      name: 'Baden-Württemberg',
      bbox: [7.5, 47.5, 10.5, 49.8],
      downloadable: true,
      status: 'ready',
      bytes: 33000000,
    );
    expect(
      suggestedPackForRoute(
        packs: [env, rn, berlin],
        fromLng: 8.68,
        fromLat: 49.41,
        toLng: 8.47,
        toLat: 49.48,
      )?.id,
      'rhein-neckar',
    );
    expect(
      suggestedPackForRoute(
        packs: [env, rn, berlin],
        fromLng: 8.3,
        fromLat: 48.8,
        toLng: 9.1,
        toLat: 48.8,
      )?.id,
      'de-baden-wuerttemberg',
    );
    expect(
      suggestedPackForRoute(
        packs: [env, rn, berlin],
        fromLng: 8.68,
        fromLat: 49.41,
        toLng: 8.47,
        toLat: 49.48,
        extra: [(lng: 9.2, lat: 48.8)],
      )?.id,
      'de-baden-wuerttemberg',
    );
  });

  test('suggested pack for route falls back to unready overlay name', () {
    final stub = OfflinePackRow(
      id: 'muenchen',
      name: 'München',
      bbox: [11.3, 48.0, 11.8, 48.3],
    );
    expect(
      suggestedPackForRoute(
        packs: [stub],
        fromLng: 11.57,
        fromLat: 48.14,
        toLng: 11.58,
        toLat: 48.15,
      )?.id,
      'muenchen',
    );
  });

  test('parseOfflineCatalogPacks reads packs list', () {
    final packs = parseOfflineCatalogPacks({
      'packs': [
        {
          'id': 'berlin',
          'name': 'Berlin',
          'downloadable': true,
          'status': 'ready',
          'bytes': 2000000,
        },
      ],
    });
    expect(packs.single.id, 'berlin');
    expect(packs.single.isReady, isTrue);
  });

  test('bbox ring is closed west-south-east-north', () {
    expect(
      offlinePackBboxRing([8.2, 49.2, 9.0, 49.6]),
      [
        [8.2, 49.2],
        [9.0, 49.2],
        [9.0, 49.6],
        [8.2, 49.6],
        [8.2, 49.2],
      ],
    );
    expect(offlinePackBboxRing([8.2, 49.2]), isEmpty);
    expect(offlinePackCoverageRing([8.2, 49.2, 9.0, 49.6]), hasLength(9));
    expect(
      offlinePackCoverageRing([8.2, 49.2, 9.0, 49.6]).first,
      offlinePackCoverageRing([8.2, 49.2, 9.0, 49.6]).last,
    );
  });

  test('packRemoteIsNewer needs both timestamps', () {
    expect(
      packRemoteIsNewer(
        localBuiltAt: '2026-08-01T00:00:00Z',
        remoteBuiltAt: '2026-08-15T00:00:00Z',
      ),
      isTrue,
    );
    expect(
      packRemoteIsNewer(
        localBuiltAt: '2026-08-15T00:00:00Z',
        remoteBuiltAt: '2026-08-15T00:02:00Z',
      ),
      isFalse,
    );
    expect(
      packRemoteIsNewer(
          localBuiltAt: null, remoteBuiltAt: '2026-08-15T00:00:00Z'),
      isFalse,
    );
    expect(networkInterfaceLooksLikeWifi('wlan0'), isTrue);
    expect(networkInterfaceLooksLikeWifi('en0'), isTrue);
    expect(networkInterfaceLooksLikeWifi('rmnet_data0'), isFalse);
    expect(networkInterfaceLooksLikeCellular('pdp_ip0'), isTrue);
  });

  test('packCountryCode uses registry then prefix', () {
    expect(
      packCountryCode(const OfflinePackRow(id: 'berlin', name: 'Berlin')),
      'DE',
    );
    expect(
      packCountryCode(const OfflinePackRow(id: 'milano', name: 'Mailand')),
      'IT',
    );
    expect(
      packCountryCode(const OfflinePackRow(id: 'paris', name: 'Paris')),
      'FR',
    );
    expect(
      packCountryCode(const OfflinePackRow(id: 'groningen', name: 'Groningen')),
      'NL',
    );
    expect(
      packCountryCode(const OfflinePackRow(id: 'bodensee', name: 'Bodensee')),
      'DACH',
    );
    expect(
      packCountryCode(
          const OfflinePackRow(id: 'de-saarland', name: 'Saarland')),
      'DE',
    );
    expect(sortOfflineCountryCodes(['IT', 'DE'], focus: 'IT').first, 'IT');
    expect(
      packNeedsDownloadConfirm(
        const OfflinePackRow(id: 'berlin', name: 'Berlin', bytes: 2000000),
      ),
      isFalse,
    );
    expect(
      packNeedsDownloadConfirm(
        const OfflinePackRow(
          id: 'de-saarland',
          name: 'Saarland',
          bytes: 54209122,
        ),
      ),
      isTrue,
    );
  });

  test('groupOfflinePacks splits by country and keeps installed', () {
    final rn = OfflinePackRow(
      id: 'rhein-neckar',
      name: 'Rhein-Neckar',
      bbox: [8.2, 49.2, 9.0, 49.6],
      downloadable: true,
      status: 'ready',
      bytes: 10518381,
    );
    final ffm = const OfflinePackRow(
      id: 'frankfurt-rhein-main',
      name: 'Frankfurt',
    );
    final saar = OfflinePackRow(
      id: 'de-saarland',
      name: 'Saarland',
      downloadable: true,
      status: 'ready',
      bytes: 54209122,
      valhallaTiles: true,
    );
    final milano = OfflinePackRow(
      id: 'milano',
      name: 'Mailand',
      bbox: [9.05, 45.38, 9.3, 45.55],
      downloadable: true,
      status: 'ready',
      bytes: 2500000,
    );
    final g = groupOfflinePacks(
      filtered: [rn, ffm, saar, milano],
      installed: {'rhein-neckar'},
      userLng: 8.68,
      userLat: 49.4,
      searching: false,
    );
    expect(g.suggested?.id, 'rhein-neckar');
    expect(g.focusCountry, 'DE');
    expect(g.installed, isEmpty);
    expect(
      [for (final c in g.countries) ...c.packs.map((p) => p.id)],
      isNot(contains('rhein-neckar')),
    );
    expect(g.countries.first.code, 'DE');
    expect(g.countries.first.packs, isEmpty);
    expect(g.countries.first.envelopes.map((r) => r.id), ['de-saarland']);
    expect(g.countries.map((c) => c.code), contains('IT'));
    expect(g.stubs.map((r) => r.id), ['frankfurt-rhein-main']);
    expect(
      offlinePackSubtitle(saar, active: false, installed: false),
      '54.2 MB · Routing · Landesfläche',
    );

    final pinned = groupOfflinePacks(
      filtered: [rn, ffm, saar, milano],
      installed: {'rhein-neckar'},
      userLng: 8.68,
      userLat: 49.4,
      searching: false,
      focusPackId: 'milano',
    );
    expect(pinned.suggested?.id, 'milano');
    expect(pinned.focusCountry, 'IT');
    expect(pinned.installed.map((r) => r.id), ['rhein-neckar']);
    expect(
      [for (final c in pinned.countries) ...c.packs.map((p) => p.id)],
      isNot(contains('milano')),
    );

    final stubPin = groupOfflinePacks(
      filtered: [rn, ffm, saar, milano],
      installed: {'rhein-neckar'},
      userLng: 8.68,
      userLat: 49.4,
      searching: false,
      focusPackId: 'frankfurt-rhein-main',
    );
    expect(stubPin.suggested?.id, 'rhein-neckar');
  });

  test('packIsPinTarget rejects catalog stubs', () {
    const stub = OfflinePackRow(id: 'frankfurt-rhein-main', name: 'Frankfurt');
    expect(packIsPinTarget(stub, installed: {}), isFalse);
    expect(packIsPinTarget(stub, installed: {'frankfurt-rhein-main'}), isTrue);
    expect(
      packIsPinTarget(
        const OfflinePackRow(
          id: kBundledOfflineGraphRegionId,
          name: 'Schwarzwald Süd',
        ),
        installed: {},
      ),
      isTrue,
    );
  });

  test('sampleLngLats keeps ends and caps length', () {
    final pts = [
      for (var i = 0; i < 100; i++) (lng: i.toDouble(), lat: 0.0),
    ];
    final sampled = sampleLngLats(pts, maxPoints: 5);
    expect(sampled.length, 5);
    expect(sampled.first.lng, 0);
    expect(sampled.last.lng, 99);
  });

  test('collapseCountryPacks keeps nearest 8 and pins suggested', () {
    final packs = [
      for (var i = 0; i < 12; i++)
        OfflinePackRow(
          id: 'de-city-$i',
          name: 'City $i',
          bbox: [i.toDouble(), 50, i + 0.2, 50.2],
          downloadable: true,
          status: 'ready',
        ),
    ];
    final split = collapseCountryPacks(
      packs: packs,
      userLng: 0.1,
      userLat: 50.1,
      pinId: 'de-city-11',
    );
    expect(split.shown.length, 9);
    expect(split.more.length, 3);
    expect(split.shown.first.id, 'de-city-0');
    expect(split.shown.last.id, 'de-city-11');
    expect(split.more.map((p) => p.id), isNot(contains('de-city-11')));
    final all = collapseCountryPacks(
      packs: packs,
      searching: true,
    );
    expect(all.shown.length, 12);
    expect(all.more, isEmpty);
  });

  test('street HUD cache uses pack bbox, occupancy, or a GPS corridor', () {
    const city = [8.2, 48.9, 8.6, 49.2];
    expect(packOffersStreetHud(packId: 'karlsruhe', bbox: city), isTrue);
    expect(maxStreetZoomForBbox(city), 15);
    expect(streetHudTileCount(city), greaterThan(10));
    expect(estimatedStreetHudBytes(city), greaterThan(100000));
    expect(streetHudRegionId('karlsruhe'), 'street-karlsruhe');
    expect(isStreetHudRegionId('street-karlsruhe'), isTrue);
    expect(
      packOffersStreetHud(
        packId: 'de-bayern',
        bbox: [9.0, 47.2, 13.8, 50.6],
      ),
      isFalse,
    );
    expect(maxStreetZoomForBbox([6, 47, 15, 55]), 0);
    expect(
      streetHudOffer(
        packId: 'de-bayern',
        catalogBbox: [9.0, 47.2, 13.8, 50.6],
        occupancyBbox: [11.5, 48.1, 11.7, 48.25],
      )?.kind,
      StreetHudOfferKind.pack,
    );
    final corridor = streetHudOffer(
      packId: 'de-bayern',
      catalogBbox: [9.0, 47.2, 13.8, 50.6],
      userLng: 11.58,
      userLat: 48.14,
    );
    expect(corridor, isNotNull);
    expect(corridor!.isCorridor, isTrue);
    expect(streetHudTileCount(corridor.bbox), greaterThan(10));
    expect(streetHudTileCount(corridor.bbox), lessThan(kStreetHudMaxTiles));
    expect(
      streetHudOffer(
        packId: 'de-bayern',
        catalogBbox: [9.0, 47.2, 13.8, 50.6],
      ),
      isNull,
    );
    final along = streetHudOffer(
      packId: 'de-bayern',
      catalogBbox: [9.0, 47.2, 13.8, 50.6],
      routeBbox: streetHudBboxFromLngLats(const [
        [11.5, 48.1],
        [11.7, 48.2],
      ]),
    );
    expect(along?.kind, StreetHudOfferKind.route);
    expect(along!.isPartial, isTrue);
    expect(
      streetHudCoverageStale(
        kind: StreetHudOfferKind.corridor,
        storedBbox: corridor.bbox,
        userLng: 11.58,
        userLat: 48.14,
      ),
      isFalse,
    );
    expect(
      streetHudCoverageStale(
        kind: StreetHudOfferKind.corridor,
        storedBbox: corridor.bbox,
        userLng: 9.2,
        userLat: 47.4,
      ),
      isTrue,
    );
    expect(
      streetHudCoverageStale(
        kind: StreetHudOfferKind.pack,
        storedBbox: city,
        userLng: 0,
        userLat: 0,
      ),
      isTrue,
    );
    expect(
      streetHudCoverageStale(
        kind: StreetHudOfferKind.pack,
        storedBbox: city,
        userLng: 8.4,
        userLat: 49.05,
      ),
      isFalse,
    );
    // GPS outside occupancy → corridor clipped to catalog, not pack tiles elsewhere.
    final away = streetHudOffer(
      packId: 'rhein-neckar',
      occupancyBbox: [8.50, 49.30, 8.69, 49.48],
      catalogBbox: [8.2, 49.2, 9.0, 49.6],
      userLng: 8.670,
      userLat: 49.280,
    );
    expect(away?.kind, StreetHudOfferKind.corridor);
    expect(streetHudPointInBbox(8.670, 49.280, away!.bbox), isTrue);
    expect(
      offlineReadyStatusLine(
        hasPack: true,
        routingAway: true,
        streetReady: true,
        streetStale: false,
        basemapReady: false,
        loadBelow: 'load',
        bothAway: 'both-away',
        streetHereRoutingAway: 'street-here-routing-away',
        routingAwayLine: 'routing-away',
        allAway: 'all-away',
        streetAway: 'street-away',
        allReady: 'all',
        streetReadyLine: 'street',
        bothReady: 'both',
        routingReady: 'routing',
      ),
      'street-here-routing-away',
    );
    expect(
      offlineReadyStatusLine(
        hasPack: true,
        routingAway: true,
        streetReady: true,
        streetStale: true,
        basemapReady: false,
        loadBelow: 'load',
        bothAway: 'both-away',
        streetHereRoutingAway: 'street-here-routing-away',
        routingAwayLine: 'routing-away',
        allAway: 'all-away',
        streetAway: 'street-away',
        allReady: 'all',
        streetReadyLine: 'street',
        bothReady: 'both',
        routingReady: 'routing',
      ),
      'both-away',
    );
    expect(streetHudKindFromRaw('route'), StreetHudOfferKind.route);
    expect(lngLatBboxNearlyEqual(city, city), isTrue);
    expect(
      streetHudCoversHere(
        regionReady: true,
        kind: StreetHudOfferKind.corridor,
        storedBbox: corridor.bbox,
        userLng: 11.58,
        userLat: 48.14,
      ),
      isTrue,
    );
    expect(
      streetHudCoversHere(
        regionReady: true,
        kind: StreetHudOfferKind.corridor,
        storedBbox: corridor.bbox,
        userLng: 9.2,
        userLat: 47.4,
      ),
      isFalse,
    );
    expect(
      streetHudCoversHere(regionReady: false, kind: StreetHudOfferKind.pack),
      isFalse,
    );
    expect(
      streetHudCoversHere(
        regionReady: true,
        kind: StreetHudOfferKind.pack,
        storedBbox: city,
        userLng: 0,
        userLat: 0,
      ),
      isFalse,
    );
    expect(
      streetHudCoversHere(
        regionReady: true,
        kind: StreetHudOfferKind.pack,
        storedBbox: city,
        userLng: 8.4,
        userLat: 49.05,
      ),
      isTrue,
    );
    expect(
      streetHudSketchLine(const [
        [11.5, 48.1],
        [11.55, 48.12],
        [11.7, 48.2],
      ]).length,
      3,
    );
  });
}
