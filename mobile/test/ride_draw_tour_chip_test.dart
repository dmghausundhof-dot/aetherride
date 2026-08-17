import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_draw_tour_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chip toggles draw vs recording copy', (tester) async {
    var drawing = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RideDrawTourChip(
                drawing: drawing,
                onToggle: () => setState(() => drawing = !drawing),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Als Tour zeichnen'), findsOneWidget);
    await tester.tap(find.byKey(RideDrawTourChip.chipKey));
    await tester.pump();
    expect(find.text('Neue Tour · zeichnet'), findsOneWidget);
  });
}
