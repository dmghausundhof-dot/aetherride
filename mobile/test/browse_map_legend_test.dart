import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/browse_map_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('idle map legend is three short swatches', (tester) async {
    await tester.pumpWidget(_wrap(const BrowseMapLegend()));
    expect(find.byKey(const Key('browse-map-legend')), findsOneWidget);
    expect(find.text('Asphalt'), findsOneWidget);
    expect(find.text('Schotter'), findsOneWidget);
    expect(find.text('Pfad'), findsOneWidget);
  });

  testWidgets('legend hides when ways and trails are off', (tester) async {
    await tester.pumpWidget(_wrap(const BrowseMapLegend(visible: false)));
    expect(find.byKey(const Key('browse-map-legend')), findsNothing);
    expect(find.text('Asphalt'), findsNothing);
  });
}
