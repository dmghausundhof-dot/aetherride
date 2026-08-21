import 'dart:ui' as ui;

import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/community/map_place.dart';
import 'package:aetherride_mobile/domain/routing/tour_filters.dart';
import 'package:aetherride_mobile/presentation/map/map_pin_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('marker kinds paint distinct PNGs', () async {
    final drop = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.drop,
    );
    final meet = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.meet,
    );
    final stimme = await buildMapMarkerPng(
      fill: const Color(0xFF6D4C41),
      kind: MapPinKind.stimme,
    );
    final flow = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.flow,
    );
    final tour = await buildMapMarkerPng(
      fill: const Color(0xFF2A2E32),
      kind: MapPinKind.tour,
    );
    final tourOn = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.tour,
    );
    final start = await buildMapMarkerPng(
      fill: const Color(0xFF2E7D32),
      kind: MapPinKind.start,
    );
    final finish = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.finish,
    );
    final via = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.via,
    );
    final halo = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.halo,
    );
    final circle = await buildMapPinPng(fill: AppColors.accent);
    expect(drop.length, greaterThan(80));
    expect(halo, isNot(equals(drop)));
    expect(meet, isNot(equals(drop)));
    expect(stimme, isNot(equals(drop)));
    expect(flow, isNot(equals(meet)));
    expect(tour, isNot(equals(drop)));
    expect(tourOn, isNot(equals(tour)));
    expect(start, isNot(equals(drop)));
    expect(finish, isNot(equals(start)));
    final finishOut = await buildMapMarkerPng(
      fill: AppColors.sage,
      kind: MapPinKind.finish,
    );
    final startOut = await buildMapMarkerPng(
      fill: AppColors.sage,
      kind: MapPinKind.start,
    );
    expect(finishOut, isNot(equals(finish)));
    expect(startOut, isNot(equals(start)));
    expect(via, isNot(equals(finish)));
    expect(circle, isNot(equals(drop)));
    final poiCafe = await buildMapMarkerPng(
      fill: const Color(0xFF2A2E32),
      kind: MapPinKind.poi,
      poiKind: MapPoiKind.cafe,
    );
    final poiView = await buildMapMarkerPng(
      fill: const Color(0xFF2A2E32),
      kind: MapPinKind.poi,
      poiKind: MapPoiKind.viewpoint,
    );
    expect(poiCafe, isNot(equals(drop)));
    expect(poiCafe, isNot(equals(tour)));
    expect(poiView, isNot(equals(poiCafe)));
    expect(mapPoiKindFromRaw('cafe'), MapPoiKind.cafe);
    expect(mapPoiKindFromRaw('café'), MapPoiKind.cafe);
    expect(mapPoiKindFromRaw('Café'), MapPoiKind.cafe);
    expect(mapPoiKindFromRaw('kultur'), MapPoiKind.culture);
    expect(mapPoiKindFromRaw('Kultur'), MapPoiKind.culture);
    expect(mapPoiKindFromRaw('aussicht'), MapPoiKind.viewpoint);
    expect(mapPoiKindFromRaw('see'), MapPoiKind.water);
    expect(mapPoiKindFromRaw('bahn'), MapPoiKind.transit);
    expect(mapPoiKindFromRaw('park'), MapPoiKind.place);
    expect(poiStopIconSize(selected: false), closeTo(36 / 320, 0.0001));
    expect(poiStopIconSize(selected: true), closeTo(42 / 320, 0.0001));
    expect(poiStopIconSize(selected: false),
        lessThan(poiStopIconSize(selected: true)));
    expect(poiStopIconSize(selected: true), lessThan(0.2));
    expect(poiFracFitsAlong(0.04, const []), isFalse);
    expect(poiFracFitsAlong(0.5, const [0.48]), isFalse);
    expect(poiFracFitsAlong(0.4, const [0.2]), isTrue);
    expect(
      coverageMapPoiKind(
        const MapPlace(
          id: 'c',
          name: 'Café',
          kind: MapPlaceKind.cafe,
          lat: 0,
          lng: 0,
        ),
      ),
      MapPoiKind.cafe,
    );
    expect(
      coverageMapPoiKind(
        const MapPlace(
          id: 's',
          name: 'Shop',
          kind: MapPlaceKind.shop,
          lat: 0,
          lng: 0,
        ),
      ),
      MapPoiKind.place,
    );
    expect(
      coverageMapPoiKind(
        const MapPlace(
          id: 'r',
          name: 'Werkstatt',
          kind: MapPlaceKind.repair,
          lat: 0,
          lng: 0,
        ),
      ),
      MapPoiKind.place,
    );
    expect(
      coverageMapPoiKind(
        const MapPlace(
          id: 'o',
          name: 'Ort',
          kind: MapPlaceKind.other,
          lat: 0,
          lng: 0,
        ),
      ),
      isNull,
    );
    expect(poiPinLabel(index: 2, title: 'Café am Feld', zoom: 11), '2');
    expect(poiPinLabel(index: 2, title: 'Café am Feld', zoom: 12),
        '2 · Café am Feld');
    expect(poiPinImageId(MapPoiKind.place), 'aether-poi');
    expect(poiPinImageId(MapPoiKind.water), 'aether-poi-water');
    expect(poiPinAssetPath(MapPoiKind.place), 'assets/map/pins/poi.png');
    expect(poiPinAssetPath(MapPoiKind.cafe), 'assets/map/pins/poi-cafe.png');
    expect(routePinAssetPath(MapPinKind.start), 'assets/map/pins/pin-start.png');
    expect(
      routePinAssetPath(MapPinKind.finish, outside: true),
      'assets/map/pins/pin-finish-out.png',
    );
    expect(routePinAssetPath(MapPinKind.via), 'assets/map/pins/pin-via.png');
    expect(viaDiscIconSize(pulse: false), closeTo(30 / 256, 0.0001));
    expect(viaHandleIconSize(), closeTo(18 / 256, 0.0001));
    expect(tourPinIconSize(selected: false), lessThan(tourPinIconSize(selected: true)));
    final loadedCafe = await loadPoiPinPng(MapPoiKind.cafe);
    final loadedView = await loadPoiPinPng(MapPoiKind.viewpoint);
    final loadedPlace = await loadPoiPinPng(MapPoiKind.place);
    expect(loadedCafe[0], 0x89);
    expect(loadedCafe, isNot(equals(loadedView)));
    expect(loadedPlace, isNot(equals(loadedCafe)));
    expect(loadedCafe, equals(poiCafe));
    expect(loadedCafe.length, greaterThan(30000));
    final loadedIds = <int>{};
    for (final kind in MapPoiKind.values) {
      final png = await loadPoiPinPng(kind);
      expect(png[0], 0x89);
      loadedIds.add(Object.hashAll(png));
    }
    expect(loadedIds.length, MapPoiKind.values.length);
    expect(drop[0], 0x89);
    expect(drop[1], 0x50);
    expect(tour[0], 0x89);
    final tourMtb = await buildMapMarkerPng(
      fill: const Color(0xFF2A2E32),
      kind: MapPinKind.tour,
      glyph: MapPinGlyph.mtb,
    );
    final tourHike = await buildMapMarkerPng(
      fill: const Color(0xFF2A2E32),
      kind: MapPinKind.tour,
      glyph: MapPinGlyph.hike,
    );
    expect(tourMtb, isNot(equals(tour)));
    expect(tourHike, isNot(equals(tourMtb)));
    expect(tourPinImageId(TourSportKey.gravel, selected: false),
        'aether-pin-tour-gravel');
    expect(tourPinImageId(TourSportKey.mtb, selected: true),
        'aether-pin-tour-on-mtb');
    final chevron = await buildRouteChevronPng();
    expect(chevron.length, greaterThan(80));
    expect(chevron[0], 0x89);
    expect(chevron, isNot(equals(tour)));
  });

  test('SDF discs tint via MapLibre icon-color', () async {
    final disc = await buildMapSdfDiscPng();
    final ring = await buildMapSdfDiscPng(ring: true);
    expect(disc.length, greaterThan(80));
    expect(ring, isNot(equals(disc)));
    expect(mapPinRasterIconSize(0.52), closeTo(0.26, 0.0001));
    expect(mapPinSdfIconSize(0.52), closeTo(1.04, 0.0001));
    expect(mapChevronIconSize(0.32), closeTo(0.16, 0.0001));
    final start = await buildMapMarkerPng(
      fill: const Color(0xFF2E7D32),
      kind: MapPinKind.start,
    );
    final via = await buildMapMarkerPng(
      fill: AppColors.accent,
      kind: MapPinKind.via,
    );
    expect(start.length, greaterThan(via.length));
    final loadedStart = await loadRoutePinPng(MapPinKind.start);
    expect(loadedStart[0], 0x89);
    expect(loadedStart.length, greaterThan(30000));
    expect(loadedStart, equals(start));
  });

  test('SDF disc corners are transparent', () async {
    final disc = await buildMapSdfDiscPng();
    final codec = await ui.instantiateImageCodec(disc);
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);
    // Top-left pixel sits outside the spread.
    expect(bytes!.getUint8(3), 0);
  });

  testWidgets('MapPinBadge paints start, finish and numbered via',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              MapPinBadge(kind: MapPinKind.start),
              MapPinBadge(kind: MapPinKind.finish),
              MapPinBadge(kind: MapPinKind.via, label: '1'),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(MapPinBadge), findsNWidgets(3));
  });

  testWidgets('MapPinBadge outside pack uses sage fill', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPinBadge(
            kind: MapPinKind.start,
            fill: AppColors.sage,
          ),
        ),
      ),
    );
    final badge = tester.widget<MapPinBadge>(find.byType(MapPinBadge));
    expect(badge.fill, AppColors.sage);
  });
}
