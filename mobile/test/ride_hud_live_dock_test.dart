import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/active_route.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_hud_island.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_hud_live_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('Daten-Dock zeigt kompakte Werte, keine Vollkarte', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RideHudDataDock(
          metrics: [
            HudDockMetric('Distanz', '4.20'),
            HudDockMetric('Zeit', '12:04'),
          ],
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.dockKey), findsOneWidget);
    expect(find.byKey(RideHudLiveDock.dataKey), findsOneWidget);
    expect(find.text('4.20'), findsOneWidget);
    expect(find.text('Distanz'), findsOneWidget);
    expect(find.text('12:04'), findsOneWidget);
  });

  testWidgets('Daten-Dock cappt auf sechs Chips', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RideHudDataDock(
          metrics: [
            for (var i = 0; i < 8; i++) HudDockMetric('L$i', '$i'),
          ],
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('Fahrwerk unmontiert: ein Tipp kalibriert', (tester) async {
    var marked = false;
    var calibrated = false;
    await tester.pumpWidget(
      _wrap(
        RideHudChassisDock(
          mount: MountCheck.unknown,
          onMarkMounted: () => marked = true,
          onCalibrate: () => calibrated = true,
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.chassisKey), findsOneWidget);
    expect(find.text('Fahrwerksanalyse aus'), findsNothing);
    expect(find.byKey(RideHudLiveDock.gaugeKey), findsNothing);
    expect(find.text('Kalibrieren'), findsOneWidget);
    await tester.tap(find.byKey(RideHudLiveDock.calibrateKey));
    expect(marked, isTrue);
    expect(calibrated, isTrue);
  });

  testWidgets('Fahrwerk zeigt Gauge auch ohne Mount-Gate', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RideHudChassisDock(
          mount: MountCheck.unknown,
          leanDeg: -6.2,
          gPeak: 1.4,
          flow: 0.55,
          onMarkMounted: () {},
          onCalibrate: () {},
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.gaugeKey), findsOneWidget);
    expect(find.text('-6.2°'), findsOneWidget);
    expect(find.text('Kalibrieren'), findsOneWidget);
  });

  testWidgets('Fahrwerk: Gauge, Werte und Kalibrieren', (tester) async {
    var calibrated = false;
    await tester.pumpWidget(
      _wrap(
        RideHudChassisDock(
          mount: MountCheck.mounted,
          leanDeg: 12.4,
          gPeak: 2.10,
          flow: 0.72,
          onMarkMounted: () {},
          onCalibrate: () => calibrated = true,
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.gaugeKey), findsOneWidget);
    expect(find.text('12.4°'), findsOneWidget);
    expect(find.text('2.10'), findsOneWidget);
    expect(find.text('0.72'), findsOneWidget);
    expect(find.text('Kalibrieren'), findsOneWidget);
    expect(find.byKey(RideHudLiveDock.resetCalKey), findsNothing);
    await tester.tap(find.byKey(RideHudLiveDock.calibrateKey));
    expect(calibrated, isTrue);
  });

  testWidgets('Fahrwerk in Fahrt: Kalibrieren gesperrt', (tester) async {
    var calibrated = false;
    await tester.pumpWidget(
      _wrap(
        RideHudChassisDock(
          mount: MountCheck.mounted,
          leanDeg: 8,
          gPeak: 1.4,
          flow: 0.6,
          calibrateEnabled: false,
          onMarkMounted: () {},
          onCalibrate: () => calibrated = true,
        ),
      ),
    );
    final btn = tester.widget<OutlinedButton>(
      find.byKey(RideHudLiveDock.calibrateKey),
    );
    expect(btn.onPressed, isNull);
    await tester.tap(find.byKey(RideHudLiveDock.calibrateKey));
    expect(calibrated, isFalse);
  });

  testWidgets('Fahrwerk kalibriert: Nullung zurück', (tester) async {
    var reset = false;
    await tester.pumpWidget(
      _wrap(
        RideHudChassisDock(
          mount: MountCheck.mounted,
          leanDeg: 0,
          gPeak: 1.02,
          flow: 0.80,
          calibrated: true,
          onMarkMounted: () {},
          onCalibrate: () {},
          onResetCal: () => reset = true,
        ),
      ),
    );
    await tester.tap(find.byKey(RideHudLiveDock.resetCalKey));
    expect(reset, isTrue);
  });

  testWidgets('embedded Dock hat keine zweite Insel', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RideHudDataDock(
          embedded: true,
          metrics: [HudDockMetric('Zeit', '01:00')],
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.dockKey), findsOneWidget);
    expect(find.byType(RideHudIsland), findsNothing);
  });
}
