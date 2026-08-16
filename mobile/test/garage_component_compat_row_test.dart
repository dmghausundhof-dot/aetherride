import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/app.dart';
import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/component_repository.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';

/// pumpAndSettle() funktioniert in dieser App nicht — Home hat
/// Hintergrund-Polling (Wetter/GPS), das nie „settled" (siehe auch
/// widget_test.dart: dort ebenfalls feste pump()-Schritte statt
/// pumpAndSettle()). Mehrere kurze pump()s statt einem langen Timeout.
Future<void> _settle(WidgetTester tester, {int steps = 8}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// End-to-End-Beleg für das zentrale Redesign-Ziel: Kompatibilitäts-Ampel
/// direkt in der Bauteil-Zeile statt in einer separaten Liste
/// (`_groupCompatBySlot` in garage_screen.dart).
void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'),
      );
    }
  });

  testWidgets(
    'Bike-Detailsheet zeigt Bauteil und Kompat-Verdikt in einer Zeile',
    (tester) async {
      final db = createMemoryDatabase();
      addTearDown(db.close);
      final garage = GarageRepository(db);
      final components = ComponentRepository(db, garage);

      final bike = await garage.addBikeBasic(
        name: 'Konflikt-Bike',
        category: BikeCategory.mtbTrail,
        makeActive: true,
      );
      // Freilauf-Standard bewusst inkompatibel (RL-DRV-011) — löst einen
      // Konflikt aus, der an Kassette *und* Nabe hinten hängen muss.
      await components.install(
        bikeId: bike.id,
        slot: ComponentSlot.cassette,
        manufacturer: 'SRAM',
        model: 'XO Eagle',
        attributes: const {'freehub_standard': 'microspline'},
      );
      await components.install(
        bikeId: bike.id,
        slot: ComponentSlot.rearHub,
        manufacturer: 'DT Swiss',
        model: '350',
        attributes: const {'freehub_standard': 'xd'},
      );

      tester.platformDispatcher.localeTestValue = const Locale('de', 'DE');
      tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
      addTearDown(() {
        tester.platformDispatcher.clearLocaleTestValue();
        tester.platformDispatcher.clearLocalesTestValue();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingDoneProvider.overrideWith((ref) => true),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const FlowLineApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('hof-threshold-nav')),
              matching: find.text('Werkstatt'),
            )
            .first,
      );
      await _settle(tester);

      await tester.tap(find.byKey(const Key('werkstatt-bike-hero')));
      await _settle(tester, steps: 12);

      expect(find.byKey(const Key('bike-detail')), findsOneWidget);

      final detailScrollable = find.descendant(
        of: find.byKey(const Key('bike-detail')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('garage-more-on-bike')),
        200,
        scrollable: detailScrollable.first,
      );
      await tester.tap(find.byKey(const Key('garage-more-on-bike')));
      await _settle(tester);

      await tester.scrollUntilVisible(
        find.text('Kassette'),
        200,
        scrollable: detailScrollable.first,
      );
      await _settle(tester, steps: 2);

      expect(find.text('Kassette'), findsWidgets);
      expect(find.text('SRAM XO Eagle'), findsOneWidget);
      expect(find.text('Nabe hinten'), findsWidgets);
      expect(find.text('DT Swiss 350'), findsOneWidget);
      expect(find.text('Passt nicht'), findsWidgets);

      await tester.tap(find.text('Kassette').last);
      await _settle(tester);
      expect(find.text('RL-DRV-011'), findsOneWidget);
    },
  );
}
