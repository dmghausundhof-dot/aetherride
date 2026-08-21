import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/discover_map_contents_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    bool heatLocked = true,
    bool offlineReady = false,
    String? offlinePackLabel,
    String? offlinePackId,
    bool? offlineOverviewReady,
    bool browseOnline = true,
    ValueChanged<DiscoverMapContentsTool>? onTool,
  }) {
    return tester.pumpWidget(
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
          body: DiscoverMapContentsSheet(
            toursOn: true,
            trailsOn: true,
            waysOn: true,
            hillshadeOn: true,
            placesOn: true,
            heatOn: false,
            heatLocked: heatLocked,
            offlineReady: offlineReady,
            offlinePackLabel: offlinePackLabel,
            offlinePackId: offlinePackId,
            offlineOverviewReady: offlineOverviewReady,
            browseOnline: browseOnline,
            onTours: (_) {},
            onTrails: (_) {},
            onWays: (_) {},
            onHillshade: (_) {},
            onPlaces: (_) {},
            onHeat: () {},
            onTool: onTool ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('Karteninhalt bündelt Layer und Werkzeuge, kein Junk-Menü',
      (tester) async {
    await pumpSheet(tester);
    expect(find.text('Karteninhalt'), findsOneWidget);
    expect(find.text('Auf der Karte'), findsOneWidget);
    expect(find.text('Mehr'), findsOneWidget);
    expect(find.text('Touren'), findsOneWidget);
    expect(find.text('Trails'), findsOneWidget);
    expect(find.text('Wege'), findsOneWidget);
    expect(find.text('Feldwege'), findsOneWidget);
    expect(find.text('Höhe'), findsOneWidget);
    expect(find.text('Orte'), findsOneWidget);
    expect(find.text('Heat'), findsOneWidget);
    expect(find.text('Zustimmung nötig'), findsOneWidget);
    expect(find.text('Fotos'), findsOneWidget);
    expect(find.text('Offline-Routing'), findsOneWidget);
    expect(find.text('Umgebungsfotos'), findsOneWidget);
    expect(find.text('Sammlungen'), findsOneWidget);
    expect(find.text('Daten & Privatsphäre'), findsNothing);
    expect(find.text('Karten'), findsNothing);
    expect(find.text('Tour…'), findsNothing);
    expect(find.byKey(const Key('discover-layer-tours')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-farm-tracks')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-places')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-photos')), findsOneWidget);
    expect(find.byKey(const Key('discover-layer-heat')), findsOneWidget);
    expect(find.byKey(const Key('discover-map-tool-offline')), findsOneWidget);
    expect(find.text('Asphalt'), findsOneWidget);
    expect(find.text('Schotter'), findsOneWidget);
    expect(find.text('Pfad'), findsOneWidget);
  });

  testWidgets('Heat ohne Consent bleibt sichtbar gesperrt', (tester) async {
    await pumpSheet(tester, heatLocked: false);
    expect(find.text('Zustimmung nötig'), findsNothing);
    expect(find.text('Heat'), findsOneWidget);
  });

  testWidgets('Offline-Routing zeigt Routing an wenn Graph aktiv',
      (tester) async {
    await pumpSheet(tester, offlineReady: true);
    expect(find.text('Offline-Routing'), findsOneWidget);
    expect(find.text('Routing an'), findsOneWidget);
  });

  testWidgets('Offline-Routing nennt das aktive Pack', (tester) async {
    await pumpSheet(
      tester,
      offlineReady: true,
      offlinePackLabel: 'Rhein-Neckar',
    );
    expect(find.text('Rhein-Neckar · Routing'), findsOneWidget);
    expect(find.text('Routing an'), findsNothing);
  });

  testWidgets('Offline-Routing nennt fehlende Übersicht', (tester) async {
    await pumpSheet(
      tester,
      offlineReady: true,
      offlinePackLabel: 'Rhein-Neckar',
      offlineOverviewReady: false,
    );
    expect(
      find.text('Rhein-Neckar · Routing · Keine Übersicht'),
      findsOneWidget,
    );
  });

  testWidgets('Offline-Routing nennt Landesfläche beim Envelope',
      (tester) async {
    await pumpSheet(
      tester,
      offlineReady: true,
      offlinePackLabel: 'Saarland',
      offlinePackId: 'de-saarland',
    );
    expect(find.text('Saarland · Routing · Landesfläche'), findsOneWidget);
  });

  testWidgets('ohne Netz: Trails brauchen Netz, still', (tester) async {
    await pumpSheet(tester, browseOnline: false);
    expect(find.byKey(const Key('discover-layers-need-net')), findsOneWidget);
    expect(find.text('Trails, Heat und Orte brauchen Netz.'), findsOneWidget);
  });

  testWidgets('mit Netz: kein Layer-Netz-Hinweis', (tester) async {
    await pumpSheet(tester, browseOnline: true);
    expect(find.byKey(const Key('discover-layers-need-net')), findsNothing);
  });
}
