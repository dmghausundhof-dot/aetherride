import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/home/home_screen.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _hofApp({
  required List<Bike> bikes,
  Locale locale = const Locale('de', 'DE'),
}) {
  return ProviderScope(
    overrides: [
      onboardingDoneProvider.overrideWith((ref) => true),
      bikesProvider.overrideWith((ref) async => bikes),
      recentRidesProvider.overrideWith((ref) async => []),
      savedRoutesProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      locale: locale,
      localeResolutionCallback: (device, supported) {
        final l = device ?? locale;
        return Locale(l.languageCode, l.countryCode);
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  testWidgets('Hof Home zeigt Bewohner und Rausfahren, keine Suche',
      (tester) async {
    await tester.pumpWidget(
      _hofApp(
        bikes: const [
          Bike(
            id: 'test',
            name: 'Luna',
            category: BikeCategory.mtbTrail,
            isActive: true,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Der Hof'), findsOneWidget);
    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Rausfahren'), findsOneWidget);
    expect(find.text('Rad öffnen'), findsOneWidget);
    expect(find.text('Deine Uhr'), findsOneWidget);
    expect(find.textContaining('Tour finden'), findsNothing);
    expect(find.textContaining('HEUTE FAHREN'), findsNothing);
    expect(find.text('Assistent fragen'), findsNothing);
    expect(find.textContaining('Reichweite'), findsNothing);
  });

  testWidgets('Querformat: Rausfahren und Uhr bleiben sichtbar', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _hofApp(
        bikes: const [
          Bike(
            id: 'test',
            name: 'Luna',
            category: BikeCategory.mtbTrail,
            isActive: true,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('hof-ride-out')), findsOneWidget);
    expect(find.text('Rausfahren'), findsOneWidget);
    expect(find.text('Deine Uhr'), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('hof-ride-out'))).bottom,
        lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio));
    expect(tester.getRect(find.byKey(const Key('hof-watch'))).bottom,
        lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio + 1));
  });

  testWidgets('Phone-Querformat: Rausfahren und Uhr-Icon bleiben über der Nav',
      (tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = FakeViewPadding(
      top: 24 * 2.625,
      bottom: 48 * 2.625,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      _hofApp(
        bikes: const [
          Bike(
            id: 'test',
            name: 'Luna',
            category: BikeCategory.mtbTrail,
            isActive: true,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final h =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(find.byKey(const Key('hof-ride-out')), findsOneWidget);
    expect(find.text('Rausfahren'), findsOneWidget);
    expect(find.text('Deine Uhr'), findsOneWidget);
    expect(find.text('Uhr koppeln'), findsNothing);
    expect(find.byKey(const Key('hof-watch-bar')), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('hof-ride-out'))).bottom,
        lessThan(h - 8));
    expect(tester.getRect(find.byKey(const Key('hof-watch-bar'))).bottom,
        lessThan(h - 8));
  });

  testWidgets('Leerer Hof: Rad abstellen, kein Demo-Bike', (tester) async {
    await tester.pumpWidget(_hofApp(bikes: const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Der Hof'), findsOneWidget);
    expect(find.text('Leerer Stand'), findsOneWidget);
    expect(find.text('Einfach fahren'), findsOneWidget);
    expect(find.text('Rad abstellen'), findsOneWidget);
    expect(find.text('Deine Uhr'), findsOneWidget);
    expect(find.textContaining('0 km'), findsNothing);
  });

  testWidgets('English UI in Germany keeps title Der Hof', (tester) async {
    await tester.pumpWidget(
      _hofApp(
        locale: const Locale('en', 'DE'),
        bikes: const [
          Bike(
            id: 'test',
            name: 'Luna',
            category: BikeCategory.mtbTrail,
            isActive: true,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Der Hof'), findsOneWidget);
    expect(find.text('Ride out'), findsOneWidget);
  });
}
