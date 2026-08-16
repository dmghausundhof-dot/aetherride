import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/l10n/app_locale.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/home/home_screen.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _hofApp({
  required List<Bike> bikes,
  List<RideRecord> rides = const [],
  List<SavedRouteEntry> saved = const [],
  Locale locale = const Locale('de', 'DE'),
}) {
  return ProviderScope(
    overrides: [
      onboardingDoneProvider.overrideWith((ref) => true),
      bikesProvider.overrideWith((ref) async => bikes),
      recentRidesProvider.overrideWith((ref) async => rides),
      savedRoutesProvider.overrideWith((ref) async => saved),
      coachWatchProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      locale: locale,
      localeResolutionCallback: (device, supported) {
        final l = device ?? locale;
        return Locale(l.languageCode, l.countryCode);
      },
      builder: (context, child) {
        AppLocaleBinding.sync(context);
        return child ?? const SizedBox.shrink();
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
    expect(find.text('Uhr koppeln'), findsOneWidget);
    expect(find.text('?'), findsNothing);
    expect(find.textContaining('Tour finden'), findsNothing);
    expect(find.textContaining('HEUTE FAHREN'), findsNothing);
    expect(find.text('Assistent fragen'), findsNothing);
    expect(find.textContaining('Reichweite'), findsNothing);
    expect(find.byKey(const Key('hof-parked-mark')), findsOneWidget);
    expect(find.byKey(const Key('hof-shop-replace')), findsNothing);
    expect(find.text('Im Laden ansehen'), findsNothing);
    final rideOut = tester.widget<FilledButton>(
      find.byKey(const Key('hof-ride-out')),
    );
    expect(
      rideOut.style?.backgroundColor?.resolve({}),
      AppColors.accent,
    );
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
    expect(find.text('Uhr koppeln'), findsOneWidget);
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
    expect(find.byKey(const Key('hof-watch-bar')), findsNothing);
    expect(find.byKey(const Key('hof-watch')), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('hof-ride-out'))).bottom,
        lessThan(h - 8));
    expect(tester.getRect(find.byKey(const Key('hof-watch'))).bottom,
        lessThan(h - 8));
  });

  testWidgets('Leerer Hof: Rad abstellen, kein Demo-Bike', (tester) async {
    await tester.pumpWidget(_hofApp(bikes: const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Der Hof'), findsOneWidget);
    expect(find.text('Leerer Stand'), findsOneWidget);
    expect(find.text('Einfach fahren'), findsNothing);
    expect(find.text('Rad abstellen'), findsOneWidget);
    expect(find.text('Ohne Rad fahren'), findsOneWidget);
    expect(find.text('Uhr koppeln'), findsOneWidget);
    expect(find.byKey(const Key('hof-watch-bar')), findsNothing);
    expect(find.textContaining('0 km'), findsNothing);
    final park = tester.widget<FilledButton>(
      find.byKey(const Key('hof-ride-out')),
    );
    expect(
      park.style?.backgroundColor?.resolve({}),
      AppColors.chipIdleText,
    );
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

  testWidgets('fr-CH shows Le local vélo and French chrome',
      (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('fr', 'CH');
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CH')];
    addTearDown(() {
      tester.platformDispatcher.clearLocaleTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingDoneProvider.overrideWith((ref) => true),
          bikesProvider.overrideWith((ref) async => [
                const Bike(
                  id: 'test',
                  name: 'Luna',
                  category: BikeCategory.mtbTrail,
                  isActive: true,
                ),
              ]),
          recentRidesProvider.overrideWith((ref) async => []),
          savedRoutesProvider.overrideWith((ref) async => []),
          coachWatchProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localeResolutionCallback: AppLocaleBinding.resolve,
          builder: (context, child) {
            AppLocaleBinding.sync(context);
            return child ?? const SizedBox.shrink();
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Le local vélo'), findsOneWidget);
    expect(find.text('Sortir'), findsOneWidget);
    expect(find.text('Rausfahren'), findsNothing);
    expect(find.text('Ride out'), findsNothing);
  });

  testWidgets('Hochformat: Rausfahren ohne Scroll, keine SAG-Tafel',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
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

    final h =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(find.text('Rausfahren'), findsOneWidget);
    expect(find.byKey(const Key('coach-hof-banner')), findsNothing);
    expect(find.textContaining('SAG'), findsNothing);
    expect(
      tester.getRect(find.byKey(const Key('hof-ride-out'))).bottom,
      lessThan(h - 24),
    );
  });

  testWidgets('justBack: keine 0 km, Uhr-Hinweis eine Zeile, Noch mal raus',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
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
        rides: [
          RideRecord(
            id: 'r-back',
            bikeId: 'test',
            startedAt: now.subtract(const Duration(minutes: 40)),
            endedAt: now.subtract(const Duration(minutes: 5)),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('gerade reingekommen'), findsOneWidget);
    expect(find.textContaining('0.0 km'), findsNothing);
    expect(find.text('Noch mal raus'), findsOneWidget);
    expect(find.text('Puls nur mit echtem Sensor.'), findsOneWidget);
    expect(find.text('Was reinkam'), findsOneWidget);
    expect(find.textContaining('Apple Watch'), findsNothing);
    expect(find.byKey(const Key('hof-resident-meta')), findsOneWidget);
  });

  testWidgets('Hof: Tafel als Brett, kein Laden', (tester) async {
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
        saved: [
          SavedRouteEntry(
            id: 'saved-1',
            name: 'Hardtwald',
            distanceKm: 14,
            elevationM: 120,
            durationMin: 60,
            savedAt: DateTime(2026, 8, 1),
          ),
          SavedRouteEntry(
            id: 'saved-2',
            name: 'Feierabend',
            distanceKm: 18,
            elevationM: 80,
            durationMin: 55,
            savedAt: DateTime(2026, 8, 2),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('hof-tafel-board')), findsOneWidget);
    expect(find.text('Die Tafel'), findsOneWidget);
    expect(find.textContaining('in der Mappe'), findsOneWidget);
    expect(find.byKey(const Key('hof-shop-replace')), findsNothing);
  });
}
