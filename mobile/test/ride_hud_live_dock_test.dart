import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/active_route.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
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
            HudDockMetric('Tempo', '22.0'),
            HudDockMetric('Distanz', '4.20'),
          ],
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.dockKey), findsOneWidget);
    expect(find.byKey(RideHudLiveDock.dataKey), findsOneWidget);
    expect(find.text('22.0'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('4.20'), findsOneWidget);
  });

  testWidgets('Fahrwerk unmontiert: Hinweis, kein Gauge', (tester) async {
    var marked = false;
    await tester.pumpWidget(
      _wrap(
        RideHudChassisDock(
          mount: MountCheck.unknown,
          onMarkMounted: () => marked = true,
        ),
      ),
    );
    expect(find.byKey(RideHudLiveDock.chassisKey), findsOneWidget);
    expect(find.text('Fahrwerksanalyse aus'), findsOneWidget);
    expect(find.byKey(RideHudLiveDock.gaugeKey), findsNothing);
    expect(find.byKey(RideHudLiveDock.calibrateKey), findsNothing);
    await tester.tap(find.text('Als montiert markieren'));
    expect(marked, isTrue);
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
    expect(find.text('genullt'), findsNothing);
    expect(find.byKey(RideHudLiveDock.resetCalKey), findsNothing);
    await tester.tap(find.byKey(RideHudLiveDock.calibrateKey));
    expect(calibrated, isTrue);
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
    expect(find.text('genullt'), findsOneWidget);
    await tester.tap(find.byKey(RideHudLiveDock.resetCalKey));
    expect(reset, isTrue);
  });
}
