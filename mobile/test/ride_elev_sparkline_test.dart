import 'package:aetherride_mobile/domain/ride/ride_telemetry.dart';
import 'package:aetherride_mobile/presentation/ride/ride_elev_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sparkline paints when elevation exists', (tester) async {
    final tel = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 600 / 111320, 'lng': 8.0, 'elev': 260},
      {'lat': 48.0 + 1200 / 111320, 'lng': 8.0, 'elev': 220},
    ]);
    expect(tel.hasElev, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideElevSparkline(telemetry: tel, height: 32),
        ),
      ),
    );
    expect(find.byType(RideElevSparkline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sparkline stays empty without elevation', (tester) async {
    final tel = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0},
      {'lat': 48.01, 'lng': 8.0},
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RideElevSparkline(telemetry: tel)),
      ),
    );
    expect(find.byType(RideElevSparkline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('terrain peek shows caption and ribbon', (tester) async {
    final tel = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 600 / 111320, 'lng': 8.0, 'elev': 260},
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideTerrainPeek(telemetry: tel, caption: '60 hm'),
        ),
      ),
    );
    expect(find.text('60 hm'), findsOneWidget);
    expect(find.byType(RideElevSparkline), findsOneWidget);
    expect(find.byType(RideGradeRibbon), findsOneWidget);
  });
}
