import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/bike_stand_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stand-Dialog nimmt km und Stunden, ohne Stunden aus km',
      (tester) async {
    BikeStandReading? saved;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await showBikeStandEditor(
                    context: context,
                    km: 0,
                    hours: 0,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Kilometer & Stunden'), findsOneWidget);
    expect(
      find.textContaining('Stunden rechnen wir nicht aus km'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('bike-stand-km')), '412');
    await tester.enterText(find.byKey(const Key('bike-stand-hours')), '12.5');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(saved?.km, 412);
    expect(saved?.hours, 12.5);
  });
}
