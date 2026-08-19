import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_group_extend_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Extend-Sheet: +30 Min und +2 h', (tester) async {
    RideGroupExtendChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async {
                choice = await showRideGroupExtendSheet(ctx);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Fenster verlängern'), findsWidgets);
    expect(find.text('Maximal bis jetzt + 12 Stunden.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ride-group-extend-30m')));
    await tester.pumpAndSettle();
    expect(choice?.addHours, 0.5);
  });
}
