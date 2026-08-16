import 'package:aetherride_mobile/core/theme/nav_hud_tokens.dart';
import 'package:aetherride_mobile/domain/hud_bike_peek.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_bike_peek.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_data_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudBikePeek.speedCaption', () {
    test('Rad when wheel/LDI drives the slot', () {
      expect(
        HudBikePeek.speedCaption(wheelDrives: true, hasRouteRest: true),
        'Rad',
      );
      expect(
        HudBikePeek.speedCaption(wheelDrives: true, hasRouteRest: false),
        'Rad',
      );
    });

    test('locked Tempo token when GPS drives a routed ride', () {
      expect(
        HudBikePeek.speedCaption(wheelDrives: false, hasRouteRest: true),
        NavHudTokens.labelSpeed,
      );
    });

    test('km/h when GPS drives a free ride', () {
      expect(
        HudBikePeek.speedCaption(wheelDrives: false, hasRouteRest: false),
        'km/h',
      );
    });
  });

  group('HudBikePeek.wheelDrivesSpeed', () {
    test('same 0.5 km/h threshold as HUD fusion', () {
      expect(HudBikePeek.wheelDrivesSpeed(null), isFalse);
      expect(HudBikePeek.wheelDrivesSpeed(0.4), isFalse);
      expect(HudBikePeek.wheelDrivesSpeed(0.51), isTrue);
    });
  });

  group('HudBikePeek.crankLive', () {
    test('stoplight 0 rpm stays while the sensor is connected', () {
      expect(
        HudBikePeek.crankLive(
          bikeConnected: true,
          previouslySeen: true,
          cadenceRpm: 0,
        ),
        isTrue,
      );
    });

    test('disconnect hides cadence — no leftover 0 rpm', () {
      expect(
        HudBikePeek.crankLive(
          bikeConnected: false,
          previouslySeen: true,
          cadenceRpm: 0,
        ),
        isFalse,
      );
    });

    test('first crank sample arms the chip', () {
      expect(
        HudBikePeek.crankLive(
          bikeConnected: true,
          previouslySeen: false,
          cadenceRpm: 0,
        ),
        isFalse,
      );
      expect(
        HudBikePeek.crankLive(
          bikeConnected: true,
          previouslySeen: false,
          cadenceRpm: 0.6,
        ),
        isTrue,
      );
    });
  });

  group('HudBikePeek.chips', () {
    test('Clean never adds a fifth nav-like chip row', () {
      expect(
        HudBikePeek.chips(
          cleanMode: true,
          hasCrank: true,
          cadenceRpm: 78,
          heartRateBpm: 132,
          riderPowerW: 210,
          batterySocPercent: 64,
        ),
        isEmpty,
      );
    });

    test('CSC without crank or SoC invents nothing', () {
      expect(
        HudBikePeek.chips(cleanMode: false, hasCrank: false, cadenceRpm: 0),
        isEmpty,
      );
    });

    test('Pro shows live streams only, 0 rpm stays at a stoplight', () {
      expect(
        HudBikePeek.chips(
          cleanMode: false,
          hasCrank: true,
          cadenceRpm: 0,
          heartRateBpm: 132,
          riderPowerW: 0,
        ),
        [
          const HudBikePeekChip(value: '132', label: 'Puls'),
          const HudBikePeekChip(value: '0', label: 'rpm'),
          const HudBikePeekChip(value: '0', label: 'W'),
        ],
      );
    });

    test('SoC only when native sent a percent', () {
      final chips = HudBikePeek.chips(
        cleanMode: false,
        hasCrank: false,
        batterySocPercent: 64,
        assistMode: 'Tour',
      );
      expect(chips, [
        const HudBikePeekChip(value: '64%', label: 'Akku'),
        const HudBikePeekChip(value: 'Tour', label: 'Assist'),
      ]);
    });

    test('Lean only with chassis UX and a live IMU sample', () {
      expect(
        HudBikePeek.chips(
          cleanMode: false,
          hasCrank: false,
          leanAngleDeg: 12.4,
        ),
        isEmpty,
      );
      expect(
        HudBikePeek.chips(
          cleanMode: false,
          hasCrank: false,
          leanAngleDeg: 12.4,
          showChassis: true,
        ),
        [const HudBikePeekChip(value: '12°', label: 'Lean')],
      );
    });

    test('Pro caps at four chips — BLE before Lean', () {
      final chips = HudBikePeek.chips(
        cleanMode: false,
        hasCrank: true,
        cadenceRpm: 78,
        heartRateBpm: 140,
        riderPowerW: 210,
        batterySocPercent: 50,
        assistMode: 'Turbo',
        leanAngleDeg: 8,
        showChassis: true,
      );
      expect(chips.length, HudBikePeek.maxPro);
      expect(chips.map((c) => c.label).toList(), ['Puls', 'rpm', 'W', 'Akku']);
    });
  });

  group('RideBikePeek', () {
    testWidgets('renders nothing without chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RideBikePeek(chips: []))),
      );
      expect(find.byKey(RideBikePeek.rowKey), findsNothing);
    });

    testWidgets('shows live labels in German', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideBikePeek(
              chips: [
                HudBikePeekChip(value: '78', label: 'rpm'),
                HudBikePeekChip(value: '64%', label: 'Akku'),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(RideBikePeek.rowKey), findsOneWidget);
      expect(find.text('78'), findsOneWidget);
      expect(find.text('rpm'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('Akku'), findsOneWidget);
    });
  });

  testWidgets('data strip Speed caption becomes Rad without extra stats',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RideDataStrip(
            speedLabel: '24',
            speedCaption: 'Rad',
            midValue: '4.2',
            midLabel: NavHudTokens.labelRestKm,
            rightValue: '18:40',
            rightLabel: NavHudTokens.labelEta,
          ),
        ),
      ),
    );
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Rad'), findsOneWidget);
    expect(find.text(NavHudTokens.labelSpeed), findsNothing);
    expect(find.text(NavHudTokens.labelRestKm), findsOneWidget);
    expect(find.text(NavHudTokens.labelEta), findsOneWidget);
  });
}
