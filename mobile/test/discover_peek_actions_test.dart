import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/discover_peek_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Peek zeigt Losfahren · Merken · Akte', (tester) async {
    var nav = 0;
    var save = 0;
    var akte = 0;
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
          body: DiscoverPeekActions(
            onNavigate: () => nav++,
            onSave: () => save++,
            onAkte: () => akte++,
          ),
        ),
      ),
    );
    expect(find.text('Losfahren'), findsOneWidget);
    expect(find.text('Merken'), findsOneWidget);
    expect(find.text('Akte'), findsOneWidget);
    await tester.tap(find.byKey(const Key('discover-peek-navigate')));
    await tester.tap(find.byKey(const Key('discover-peek-save')));
    await tester.tap(find.byKey(const Key('discover-peek-akte')));
    expect(nav, 1);
    expect(save, 1);
    expect(akte, 1);
  });
}
