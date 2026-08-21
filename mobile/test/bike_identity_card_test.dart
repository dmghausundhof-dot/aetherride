import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/bike_identity_card.dart';

void main() {
  testWidgets('empty identity card asks for Rahmennummer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeIdentityCard(
            bike: Bike(
              id: 'b1',
              name: 'City',
              category: BikeCategory.urban,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('bike-identity-card')), findsOneWidget);
    expect(find.textContaining('Rahmennummer hinterlegen'), findsOneWidget);
  });

  testWidgets('filled identity card shows serial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeIdentityCard(
            bike: Bike(
              id: 'b1',
              name: 'Trail',
              category: BikeCategory.mtbAm,
              owner: BikeOwner(
                serialNumber: 'WS-1847',
                color: 'Graphit',
                insuranceName: 'ADAC',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('WS-1847'), findsOneWidget);
    expect(find.text('Graphit'), findsOneWidget);
    expect(find.text('ADAC'), findsOneWidget);
  });

  testWidgets('Identität zeigt Werkstatt ohne Namen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeIdentityCard(
            bike: Bike(
              id: 'b1',
              name: 'City',
              category: BikeCategory.urban,
              owner: BikeOwner(
                workshopAddress: 'Hauptstr. 1',
                workshopPhone: '06227 1',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Hauptstr. 1'), findsOneWidget);
    expect(find.textContaining('06227 1'), findsOneWidget);
  });

  testWidgets('Identität zeigt keine Tech-Duplikate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BikeIdentityCard(
            bike: Bike(
              id: 'b1',
              name: 'Trail',
              category: BikeCategory.mtbAm,
              year: 2022,
              frameSize: 'M',
              travelFrontMm: 140,
              travelRearMm: 140,
              wheelSize: WheelSize.w29,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Rahmennummer hinterlegen'), findsOneWidget);
    expect(find.text('2022'), findsNothing);
    expect(find.text('140/140 mm'), findsNothing);
    expect(find.text('29"'), findsNothing);
  });
}
