import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/bike_value_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Werte-Leiste zeigt km, Stunden und echten Druck', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeValueStrip(
            km: 1240,
            hours: 42.5,
            pressure: '1.8 / 2.0 bar',
            serviceLabel: '12.09.2026',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('bike-value-strip')), findsOneWidget);
    expect(find.text('1240'), findsOneWidget);
    expect(find.text('42.5'), findsOneWidget);
    expect(find.text('1.8 / 2.0 bar'), findsOneWidget);
    expect(find.text('12.09.2026'), findsOneWidget);
  });

  testWidgets('km, Stunden, Druck und Termin sind antippbar', (tester) async {
    var km = 0;
    var hours = 0;
    var pressure = 0;
    var service = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BikeValueStrip(
            km: 10,
            hours: 1,
            pressure: '1.8 bar',
            serviceLabel: '12.09.2026',
            onKm: () => km++,
            onHours: () => hours++,
            onPressure: () => pressure++,
            onService: () => service++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('bike-value-km')));
    await tester.tap(find.byKey(const Key('bike-value-hours')));
    await tester.tap(find.byKey(const Key('bike-value-pressure')));
    await tester.tap(find.byKey(const Key('bike-value-service')));
    expect(km, 1);
    expect(hours, 1);
    expect(pressure, 1);
    expect(service, 1);
    expect(
      tester.getSemantics(find.byKey(const Key('bike-value-km'))),
      matchesSemantics(
        label: 'KM 10',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('bike-value-service'))),
      matchesSemantics(
        label: 'Termin 12.09.2026',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('bike-value-km'))).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('Druck und Termin passen auf schmale Breite ohne Overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeValueStrip(
            km: 1240,
            hours: 42.5,
            pressure: '1.8 / 2.0 bar',
            serviceLabel: '12.09.2026',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('1.8'), findsOneWidget);
  });

  testWidgets('0 km und 0 Stunden sind Gedankenstrich', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeValueStrip(km: 0, hours: 0),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('0.0'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });
}
