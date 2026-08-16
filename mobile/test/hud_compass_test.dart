import 'package:aetherride_mobile/domain/hud_compass.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_compass_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compassCardinalDe', () {
    test('maps 45° sectors to German labels', () {
      expect(compassCardinalDe(0), 'N');
      expect(compassCardinalDe(360), 'N');
      expect(compassCardinalDe(-5), 'N');
      expect(compassCardinalDe(45), 'NO');
      expect(compassCardinalDe(90), 'O');
      expect(compassCardinalDe(135), 'SO');
      expect(compassCardinalDe(180), 'S');
      expect(compassCardinalDe(225), 'SW');
      expect(compassCardinalDe(270), 'W');
      expect(compassCardinalDe(315), 'NW');
    });

    test('sector edges sit on the nearer cardinal', () {
      expect(compassCardinalDe(22), 'N');
      expect(compassCardinalDe(23), 'NO');
    });
  });

  group('compassRoseDeg', () {
    test('north-up keeps N at the top', () {
      expect(compassRoseDeg(90, northUp: true), 0);
      expect(compassRoseDeg(180, northUp: true), 0);
    });

    test('heading-up rotates rose against rider heading', () {
      expect(compassRoseDeg(90, northUp: false), -90);
      expect(compassRoseDeg(-10, northUp: false), -350);
    });
  });

  group('RideCompassChip', () {
    testWidgets('tap toggles north-up', (tester) async {
      var northUp = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RideCompassChip(
                  headingDeg: 90,
                  northUp: northUp,
                  onToggle: () => setState(() => northUp = !northUp),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(RideCompassChip.toggleKey), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      expect(find.byTooltip('Fahrtrichtung oben'), findsOneWidget);

      await tester.tap(find.byKey(RideCompassChip.toggleKey));
      await tester.pump();

      expect(northUp, isTrue);
      expect(find.byTooltip('Norden oben'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });
  });
}
