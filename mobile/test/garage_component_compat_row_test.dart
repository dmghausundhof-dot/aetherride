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
import 'package:aetherride_mobile/presentation/garage/garage_screen.dart';
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingDoneProvider.overrideWith((ref) => true),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const AetherRideApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Zur Garage wechseln. pumpAndSettle() vermeiden — Home hat
      // Hintergrund-Polling (Wetter/GPS), das nie „settled" (siehe
      // widget_test.dart: dort ebenfalls feste pump()-Schritte).
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Garage'),
            )
            .first,
      );
      await _settle(tester);

      // Bike öffnen — Übersichtskarte oder Kachel (beide unter GarageScreen).
      final garageScrollable = find.descendant(
        of: find.byType(GarageScreen),
        matching: find.byType(Scrollable),
      );
      final bikeName = find.descendant(
        of: find.byType(GarageScreen),
        matching: find.text('Konflikt-Bike'),
      );
      if (bikeName.evaluate().isEmpty) {
        final overviewTitle = find.descendant(
          of: find.byType(GarageScreen),
          matching: find.textContaining('Konflikt-Bike'),
        );
        await tester.ensureVisible(overviewTitle.first);
        await tester.tap(overviewTitle.first);
      } else {
        await tester.scrollUntilVisible(
          bikeName.first,
          120,
          scrollable: garageScrollable.first,
        );
        await tester.tap(bikeName.first);
      }
      await _settle(tester);

      // Bauteil-Zeilen liegen unterhalb des Sheet-Viewports — die Sliver-
      // Liste baut sie erst, wenn dorthin gescrollt wird.
      final sheetScrollable = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Kassette'),
        150,
        scrollable: sheetScrollable,
      );
      await _settle(tester, steps: 2);

      // Beide betroffenen Bauteil-Zeilen zeigen Slot-Label, Bauteilname
      // *und* die Kompat-Kurzform in derselben Zeile.
      expect(find.text('Kassette'), findsOneWidget);
      expect(find.text('SRAM XO Eagle'), findsOneWidget);
      expect(find.text('Nabe hinten'), findsOneWidget);
      expect(find.text('DT Swiss 350'), findsOneWidget);
      expect(find.textContaining('Passt nicht'), findsWidgets);

      // Tap auf die Zeile öffnet die Evidence (Regelbegründung) statt einer
      // zweiten, unabhängigen Liste.
      await tester.tap(find.text('Kassette'));
      await _settle(tester);
      expect(find.text('RL-DRV-011'), findsOneWidget);
    },
  );
}
