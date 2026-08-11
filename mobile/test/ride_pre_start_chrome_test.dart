import 'package:aetherride_mobile/domain/sport/discipline_ux.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_next_turn_banner.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_pre_start_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RidePreStartChrome (N-START-01)', () {
    test('primary CTA is Losfahren when route is loaded', () {
      expect(
        RidePreStartChrome.primaryLabel(hasRoute: true),
        MultiSportCopy.goRide,
      );
      expect(RidePreStartChrome.primaryLabel(hasRoute: true), 'Losfahren');
    });

    test('primary CTA is freeride when no route', () {
      expect(
        RidePreStartChrome.primaryLabel(hasRoute: false),
        MultiSportCopy.startFreeride,
      );
    });

    testWidgets('map-first chrome: one primary CTA, no sensor checklist',
        (tester) async {
      var started = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 720,
              child: Stack(
                children: [
                  const ColoredBox(color: Color(0xFF1A2A22)),
                  RidePreStartChrome(
                    routeName: 'Tempelhofer 60',
                    onStart: () => started = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Losfahren'), findsOneWidget);
      expect(find.byKey(const Key('ride-primary-start')), findsOneWidget);
      expect(find.text('Tempelhofer 60'), findsOneWidget);

      // Sensor / Nearby / BLE must never gate the map (regression from checklist UI).
      expect(find.textContaining('Radsensor'), findsNothing);
      expect(find.textContaining('Nearby'), findsNothing);
      expect(find.textContaining('Bluetooth'), findsNothing);
      expect(find.textContaining('Handy am Lenker'), findsNothing);
      expect(find.text('Ja — Analyse an'), findsNothing);
      expect(find.text(MultiSportCopy.readyTitle), findsNothing);

      await tester.tap(find.byKey(const Key('ride-primary-start')));
      await tester.pump();
      expect(started, isTrue);
    });

    testWidgets('starting state disables CTA and shows Startet…', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RidePreStartChrome(
              routeName: 'Spree',
              starting: true,
              onStart: () {},
            ),
          ),
        ),
      );

      expect(find.text('Startet…'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('ride-primary-start')),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('RideNextTurnBanner (N-HUD-01)', () {
    testWidgets('next-turn distance paints at 48dp Bold (token)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RideNextTurnBanner(
                distance: '120 m',
                instruction: 'Links abbiegen',
                icon: Icons.turn_left,
              ),
            ),
          ),
        ),
      );

      final distance = tester.widget<Text>(find.text('120 m'));
      expect(distance.style?.fontSize, 48);
      expect(distance.style?.fontWeight, FontWeight.w700);

      final box = tester.renderObject<RenderBox>(
        find.byType(RideNextTurnBanner),
      );
      expect(box.size.height, greaterThanOrEqualTo(40));
    });
  });
}
