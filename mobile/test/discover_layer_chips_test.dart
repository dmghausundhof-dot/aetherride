import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/discover_layer_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Explore-Layer sind Touren · Trails · Radwege · Höhe',
      (tester) async {
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
          body: DiscoverLayerChips(
            toursOn: true,
            trailsOn: true,
            waysOn: true,
            hillshadeOn: true,
            onTours: (_) {},
            onTrails: (_) {},
            onWays: (_) {},
            onHillshade: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Touren'), findsOneWidget);
    expect(find.text('Trails'), findsOneWidget);
    expect(find.text('Wege'), findsOneWidget);
    expect(find.text('Höhe'), findsOneWidget);
    expect(find.text('Tour…'), findsNothing);
    expect(find.text('Orte'), findsNothing);
    expect(find.text('Heat'), findsNothing);
    expect(find.text('Asphalt'), findsOneWidget);
    expect(find.text('Schotter'), findsOneWidget);
    expect(find.text('Pfad'), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-tours')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-trails')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-ways')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-height')), findsOneWidget);
  });
}
