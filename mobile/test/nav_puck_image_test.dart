import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/presentation/map/nav_puck_image.dart';
import 'package:aetherride_mobile/presentation/map/nav_puck_profile_tile.dart';
import 'package:aetherride_mobile/presentation/map/nav_puck_style_sheet.dart';
import 'package:aetherride_mobile/presentation/map/rider_map_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('navPuckIconRotateDeg: Norden-oben = Heading', () {
    expect(
      navPuckIconRotateDeg(
        headingDeg: 90,
        cameraBearingDeg: 40,
        northUp: true,
      ),
      90,
    );
  });

  test('navPuckIconRotateDeg: Heading-up = Heading minus Kamera', () {
    expect(
      navPuckIconRotateDeg(
        headingDeg: 90,
        cameraBearingDeg: 90,
        northUp: false,
      ),
      0,
    );
    expect(
      navPuckIconRotateDeg(
        headingDeg: 10,
        cameraBearingDeg: 350,
        northUp: false,
      ),
      20,
    );
  });

  test('navPuckIconRotateDeg wrappt negativ', () {
    expect(
      navPuckIconRotateDeg(
        headingDeg: 10,
        cameraBearingDeg: 30,
        northUp: false,
      ),
      340,
    );
  });

  test('3D-Puck ist größer als der klassische Pfeil', () {
    expect(NavPuckStyle.rider.mapIconSize, RiderMapIconSize.nav);
    expect(NavPuckStyle.chevron.mapIconSize, RiderMapIconSize.navClassic);
    expect(
      NavPuckStyle.chevron.mapIconSize,
      lessThan(NavPuckStyle.rider.mapIconSize),
    );
    expect(NavPuckStyle.bergA.mapIconSize, RiderMapIconSize.navClassic);
  });

  test('Profil-Wahl ist 3D plus klassischer Pfeil', () {
    expect(navPuckProfileChoices(NavPuckStyle.rider), [
      NavPuckStyle.rider,
      NavPuckStyle.chevron,
    ]);
    expect(navPuckProfileChoices(NavPuckStyle.chevron), [
      NavPuckStyle.rider,
      NavPuckStyle.chevron,
    ]);
    expect(navPuckProfileChoices(NavPuckStyle.kiesel), [
      NavPuckStyle.rider,
      NavPuckStyle.chevron,
      NavPuckStyle.kiesel,
    ]);
  });

  test('NavPuckStyle fromId default ist Fahrer', () {
    expect(NavPuckStyleX.fromId(null), NavPuckStyle.rider);
    expect(NavPuckStyleX.fromId('nope'), NavPuckStyle.rider);
    expect(NavPuckStyleX.fromId('chevron'), NavPuckStyle.chevron);
    expect(NavPuckStyleX.fromId('rider'), NavPuckStyle.rider);
    expect(NavPuckStyleX.fromId('bergA'), NavPuckStyle.bergA);
    expect(NavPuckStyleX.fromId('kiesel'), NavPuckStyle.kiesel);
    expect(NavPuckStyleX.fromId('topDownBike'), NavPuckStyle.topDownBike);
    expect(NavPuckStyle.rider.isRecommended, isTrue);
    expect(NavPuckStyle.chevron.isRecommended, isFalse);
    expect(NavPuckStyle.bergA.isRecommended, isFalse);
    expect(NavPuckStyle.topDownBike.isRecommended, isFalse);
    expect(NavPuckStyle.values.length, greaterThanOrEqualTo(9));
  });

  test('jede Style-Id hat eigene MapLibre image id', () {
    final ids = {for (final s in NavPuckStyle.values) s.imageId};
    expect(ids.length, NavPuckStyle.values.length);
    expect(NavPuckStyle.rider.imageId, 'aether-nav-puck-rider');
    expect(NavPuckStyle.bergA.imageId, 'aether-nav-puck-bergA');
    expect(
      NavPuckStyle.topDownBike.imageId,
      'aether-nav-puck-topDownBike',
    );
  });

  testWidgets('buildNavPuckPng liefert gültiges PNG', (tester) async {
    late Uint8List bytes;
    await tester.runAsync(() async {
      bytes = await buildNavPuckPng(pixelSize: 64);
    });
    expect(bytes.length, greaterThan(80));
    expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 64);
      expect(frame.image.height, 64);
    });
  });

  testWidgets('jedes NavPuckStyle malt ein PNG', (tester) async {
    for (final style in NavPuckStyle.values) {
      late Uint8List bytes;
      await tester.runAsync(() async {
        bytes = await buildNavPuckPng(style: style, pixelSize: 64);
      });
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10],
          reason: style.id);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 64);
        expect(frame.image.height, 64);
      });
    }
  });

  testWidgets('AetherNavMark rendert Chevron in Markenfarbe', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AetherNavMark(
              size: 44,
              color: AppColors.accent,
              style: NavPuckStyle.chevron,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AetherNavMark), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    final box = tester.renderObject<RenderBox>(find.byType(AetherNavMark));
    expect(box.size, const Size(44, 44));
  });

  testWidgets('Picker zeigt alle Stile auf dunkel und hell', (tester) async {
    NavPuckStyle? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavPuckStylePicker(
            current: NavPuckStyle.rider,
            onSelect: (s) => picked = s,
          ),
        ),
      ),
    );
    for (final s in NavPuckStyle.values) {
      expect(find.text(s.titleDe), findsOneWidget);
    }
    expect(
      find.byType(AetherNavMark),
      findsNWidgets(NavPuckStyle.values.length * 4),
    );
    expect(find.text('Dunkel'), findsWidgets);
    expect(find.text('Hell'), findsWidgets);
    expect(find.text('Empfehlung'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('nav-puck-style-kiesel')));
    await tester.tap(find.byKey(const Key('nav-puck-style-kiesel')));
    expect(picked, NavPuckStyle.kiesel);
  });

  testWidgets('Profil-Kachel öffnet 3D und klassischen Pfeil', (tester) async {
    NavPuckStyle saved = NavPuckStyle.rider;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavPuckProfileTile(
            loadStyle: () async => saved,
            onSave: (s) async => saved = s,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(NavPuckProfileTile.tileKey), findsOneWidget);
    expect(find.text('Navi-Symbol'), findsOneWidget);
    await tester.tap(find.byKey(NavPuckProfileTile.tileKey));
    await tester.pumpAndSettle();
    expect(find.text('Fahrer'), findsWidgets);
    expect(find.text('Chevron'), findsOneWidget);
    expect(find.text('Kiesel'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('nav-puck-style-chevron')));
    await tester.tap(find.byKey(const Key('nav-puck-style-chevron')));
    await tester.pumpAndSettle();
    expect(saved, NavPuckStyle.chevron);
  });
}
