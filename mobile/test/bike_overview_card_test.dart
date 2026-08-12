import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/garage/garage_primary_cta.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/bike_overview.dart';

void main() {
  testWidgets('BikeOverviewCard zeigt Typ, E-Bike und Wartungsstatus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BikeOverviewCard(
            bike: const Bike(
              id: 'b1',
              name: 'Trail Buddy',
              category: BikeCategory.mtbTrail,
              isActive: true,
              isEbike: true,
              odometerKm: 120,
            ),
            partsCount: 2,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Trail Buddy'), findsWidgets);
    expect(find.text('E-MTB'), findsOneWidget);
    expect(find.text('Alles in Ordnung'), findsOneWidget);
    expect(find.textContaining('120 km'), findsOneWidget);
    expect(find.textContaining('2 Teile'), findsOneWidget);
  });

  testWidgets('BikeOverviewCard zeigt Primär-CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BikeOverviewCard(
            bike: const Bike(
              id: 'b1',
              name: 'Trail Buddy',
              category: BikeCategory.mtbTrail,
              isActive: true,
              odometerKm: 10,
            ),
            partsCount: 0,
            primaryAction: GaragePrimaryAction.addPart,
            onPrimaryAction: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Teil hinzufügen'), findsOneWidget);
    await tester.tap(find.text('Teil hinzufügen'));
    expect(tapped, isTrue);
  });

  testWidgets('BikeTechDetailsPanel zeigt Federweg', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BikeTechDetailsPanel(
            initiallyExpanded: true,
            bike: const Bike(
              id: 'b1',
              name: 'Enduro',
              category: BikeCategory.mtbEnduro,
              travelFrontMm: 170,
              travelRearMm: 160,
              frameSize: 'L',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Technische Details'), findsOneWidget);
    expect(find.textContaining('170/160 mm'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
  });
}
