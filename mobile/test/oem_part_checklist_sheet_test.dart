import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/bike_photo_fill.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/oem_part_checklist_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Prüfliste trennt Katalog und Grok visuell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOemPartChecklist(
                context: context,
                suggestions: const [
                  OemPartSuggestion(
                    slot: ComponentSlot.fork,
                    manufacturer: 'Fox',
                    model: '36',
                    catalogModelId: 'cm-fox-36',
                  ),
                  OemPartSuggestion(
                    slot: ComponentSlot.rearShock,
                    manufacturer: 'Fox',
                    model: 'Float',
                    source: OemPartSource.vision,
                  ),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Teile am Rad prüfen'), findsOneWidget);
    expect(find.byKey(const Key('oem-source-catalog')), findsOneWidget);
    expect(find.byKey(const Key('oem-source-grok')), findsOneWidget);
    expect(find.text('Von Grok, nicht im Katalog'), findsOneWidget);
    expect(find.text('Katalog'), findsOneWidget);
    expect(find.text('Ohne Teile weiter'), findsOneWidget);
  });

  testWidgets('Leere Prüfliste ist handlungsfähig', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOemPartChecklist(
                context: context,
                suggestions: const [],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Nichts erkannt'), findsOneWidget);
    expect(find.text('Teil hinzufügen'), findsOneWidget);
    expect(find.text('Ohne Teile weiter'), findsOneWidget);
  });

  testWidgets('Prüfliste bleibt ohne Katalogtreffer offen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOemPartChecklist(
                context: context,
                suggestions: const [],
                identifyReason: 'no_catalog',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kein Treffer im Katalog'), findsOneWidget);
    expect(find.text('Teil hinzufügen'), findsOneWidget);
  });
}
