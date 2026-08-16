import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/privacy/privacy_zone_map.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/privacy/privacy_zone_editor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('privacy zone radius', () {
    test('parses comma decimals and clamps', () {
      expect(parsePrivacyZoneRadius('200'), 200);
      expect(parsePrivacyZoneRadius('200,5'), 200.5);
      expect(parsePrivacyZoneRadius('10'), kPrivacyZoneMinRadiusM);
      expect(parsePrivacyZoneRadius('99999'), kPrivacyZoneMaxRadiusM);
      expect(parsePrivacyZoneRadius('abc'), kPrivacyZoneDefaultRadiusM);
      expect(parsePrivacyZoneRadius(''), kPrivacyZoneDefaultRadiusM);
    });

    test('clamp keeps default on junk', () {
      expect(clampPrivacyZoneRadius(double.nan), kPrivacyZoneDefaultRadiusM);
      expect(clampPrivacyZoneRadius(-4), kPrivacyZoneDefaultRadiusM);
    });
  });

  group('privacy zone coords', () {
    test('rejects Null Island and out of range', () {
      expect(isPlausiblePrivacyCoord(0, 0), isFalse);
      expect(isPlausiblePrivacyCoord(0.00001, 0.00002), isFalse);
      expect(isPlausiblePrivacyCoord(91, 10), isFalse);
      expect(isPlausiblePrivacyCoord(47.4, 12.1), isTrue);
    });

    test('parsePrivacyZoneCoord accepts comma and rejects junk', () {
      expect(parsePrivacyZoneCoord('47,45', isLat: true), 47.45);
      expect(parsePrivacyZoneCoord('12.15', isLat: false), 12.15);
      expect(parsePrivacyZoneCoord('95', isLat: true), isNull);
      expect(parsePrivacyZoneCoord('foo', isLat: false), isNull);
    });
  });

  group('privacy zone map origin', () {
    test('prefers GPS, then ride, then country — never 0,0', () {
      final gps = resolvePrivacyZoneMapOrigin(
        gpsLat: 49.41,
        gpsLng: 8.69,
        lastRideTrack: [
          {'lat': 47.45, 'lng': 12.15},
        ],
        countryCode: 'DE',
      );
      expect(gps.source, PrivacyZoneMapOriginSource.gps);
      expect(gps.lat, closeTo(49.41, 1e-9));

      final ride = resolvePrivacyZoneMapOrigin(
        gpsLat: 0,
        gpsLng: 0,
        lastRideTrack: [
          {'lat': 0, 'lng': 0},
          {'lat': 48.14, 'lng': 11.58},
        ],
        countryCode: 'DE',
      );
      expect(ride.source, PrivacyZoneMapOriginSource.ride);
      expect(ride.lat, closeTo(48.14, 1e-9));

      final de = resolvePrivacyZoneMapOrigin(countryCode: 'DE');
      expect(de.lat, isNot(0));
      expect(de.lng, isNot(0));
      expect(isPlausiblePrivacyCoord(de.lat, de.lng), isTrue);

      final ch = resolvePrivacyZoneMapOrigin(countryCode: 'CH');
      expect(ch.source, PrivacyZoneMapOriginSource.country);
      expect(ch.lat, closeTo(46.8182, 1e-4));

      final unknown = resolvePrivacyZoneMapOrigin();
      expect(unknown.source, PrivacyZoneMapOriginSource.germany);
      expect(unknown.lat, kPrivacyZoneGermanyCenter.lat);
      expect(unknown.lng, kPrivacyZoneGermanyCenter.lng);
    });

    test('pre-place only for GPS/ride, not country fallback', () {
      expect(
        resolvePrivacyZoneMapOrigin(
          gpsLat: 49.4,
          gpsLng: 8.7,
        ).shouldPrePlace,
        isTrue,
      );
      expect(
        resolvePrivacyZoneMapOrigin(countryCode: 'DE').shouldPrePlace,
        isFalse,
      );
    });
  });

  group('privacy zone circle ring', () {
    test('is closed and ~radiusM from center', () {
      const lat = 47.45;
      const lng = 12.15;
      const radius = 200.0;
      final ring = privacyZoneCircleRing(lat: lat, lng: lng, radiusM: radius);
      expect(ring.length, 65);
      expect(ring.first.lat, closeTo(ring.last.lat, 1e-9));
      expect(ring.first.lng, closeTo(ring.last.lng, 1e-9));
      for (final p in ring) {
        final d = privacyHaversineM(
          lat1: lat,
          lng1: lng,
          lat2: p.lat,
          lng2: p.lng,
        );
        expect(d, closeTo(radius, 2));
      }
    });

    test('larger radius grows the ring', () {
      const lat = 51.16;
      const lng = 10.45;
      final small = privacyZoneCircleRing(lat: lat, lng: lng, radiusM: 50);
      final large = privacyZoneCircleRing(lat: lat, lng: lng, radiusM: 2000);
      final dSmall = privacyHaversineM(
        lat1: lat,
        lng1: lng,
        lat2: small.first.lat,
        lng2: small.first.lng,
      );
      final dLarge = privacyHaversineM(
        lat1: lat,
        lng1: lng,
        lat2: large.first.lat,
        lng2: large.first.lng,
      );
      expect(dLarge, greaterThan(dSmall * 10));
    });
  });

  test('privacyZoneFromDraft roundtrip matches stored fields', () {
    final zone = privacyZoneFromDraft(
      id: 'pz-1',
      label: '  Zuhause  ',
      lat: 47.45,
      lng: 12.15,
      radiusM: 200,
    );
    expect(zone.label, 'Zuhause');
    expect(zone.radiusM, 200);
    final json = zone.toJson();
    final back = PrivacyZone.fromJson(json);
    expect(back.id, zone.id);
    expect(back.label, zone.label);
    expect(back.lat, zone.lat);
    expect(back.lng, zone.lng);
    expect(back.radiusM, zone.radiusM);

    final empty = privacyZoneFromDraft(
      id: 'pz-2',
      label: '   ',
      lat: 48.1,
      lng: 11.5,
      radiusM: 10,
    );
    expect(empty.label, 'Zone');
    expect(empty.radiusM, kPrivacyZoneMinRadiusM);
  });

  test('list subtitle is radius-first, coords secondary', () {
    expect(privacyZoneRadiusLabel(200), '200 m');
    expect(privacyZoneCoordHint(47.45, 12.15), '47.4500, 12.1500');
  });

  testWidgets('editor panel is map-first: slider + label, coords behind tile',
      (tester) async {
    final label = TextEditingController(text: kPrivacyZoneDefaultLabel);
    final lat = TextEditingController();
    final lng = TextEditingController();
    var radius = kPrivacyZoneDefaultRadiusM;
    var applied = false;
    addTearDown(label.dispose);
    addTearDown(lat.dispose);
    addTearDown(lng.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PrivacyZoneEditorPanel(
            labelController: label,
            radiusM: radius,
            onRadiusChanged: (v) => radius = v,
            latController: lat,
            lngController: lng,
            onApplyCoords: () => applied = true,
            placed: false,
          ),
        ),
      ),
    );

    expect(find.text('Tippe auf die Karte, um die Zone zu setzen.'), findsOneWidget);
    expect(find.text(kPrivacyZoneDefaultLabel), findsWidgets);
    expect(find.text('200 m'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Koordinaten'), findsOneWidget);
    expect(find.text('Lat'), findsNothing);
    expect(find.text('Lng'), findsNothing);

    await tester.tap(find.text('Koordinaten'));
    await tester.pumpAndSettle();
    expect(find.text('Lat'), findsOneWidget);
    expect(find.text('Lng'), findsOneWidget);
    await tester.tap(find.text('Koordinaten übernehmen'));
    expect(applied, isTrue);
  });
}
