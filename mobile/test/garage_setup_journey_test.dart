import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/garage/garage_primary_cta.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/bike_overview.dart';

void main() {
  testWidgets('Primär-CTA zeigt Zum Setup, nicht Setup öffnen', (tester) async {
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
            partsCount: 2,
            primaryAction: GaragePrimaryAction.openSetup,
            onPrimaryAction: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Zum Setup'), findsOneWidget);
    expect(find.text('Setup öffnen'), findsNothing);
  });
}
