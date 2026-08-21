import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/bike_overview.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';

void main() {
  testWidgets('BikeTechDetailsPanel zeigt Federweg', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSetupProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
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
      ),
    );
    await tester.pump();
    expect(find.text('Technische Details'), findsOneWidget);
    expect(find.textContaining('170/160 mm'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
  });
}
