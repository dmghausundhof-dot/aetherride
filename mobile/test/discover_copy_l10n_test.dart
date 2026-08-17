import 'package:aetherride_mobile/domain/routing/route_variant.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/l10n/app_localizations_de.dart';
import 'package:aetherride_mobile/l10n/app_localizations_en.dart';
import 'package:aetherride_mobile/l10n/app_localizations_fr.dart';
import 'package:aetherride_mobile/l10n/app_localizations_it.dart';
import 'package:aetherride_mobile/l10n/l10n_ext.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/route_variant_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Navigieren variant chip is German, not unpaved', () {
    final de = AppLocalizationsDe();
    expect(de.discoverVariantUnpaved, 'Mehr Schotter');
    expect(de.discoverVariantUnpaved.toLowerCase(), isNot(contains('unpaved')));
    expect(de.discoverVariantPlanned, 'Wie geplant');
    expect(de.discoverVariantFlatter, 'Weniger hm');
  });

  test('variant hint is Hof copy, no routing engine', () {
    final lines = <String>[
      AppLocalizationsDe().discoverVariantValhallaOnly,
      AppLocalizationsEn().discoverVariantValhallaOnly,
      AppLocalizationsFr().discoverVariantValhallaOnly,
      AppLocalizationsIt().discoverVariantValhallaOnly,
    ];
    expect(lines[0], 'Ohne Live-Strecke keine Varianten');
    expect(lines[1], 'No variants without a live route');
    expect(lines[2], 'Sans route live, pas de variantes');
    expect(lines[3], 'Senza route live, niente varianti');
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('valhalla')));
      expect(lower, isNot(contains('osrm')));
      expect(lower, isNot(contains('graphhopper')));
    }
  });

  test('quick-limit hint is Hof copy, no routing engine', () {
    final lines = <String>[
      AppLocalizationsDe().discoverGhMinuteLimit,
      AppLocalizationsEn().discoverGhMinuteLimit,
      AppLocalizationsFr().discoverGhMinuteLimit,
      AppLocalizationsIt().discoverGhMinuteLimit,
    ];
    expect(
      lines[0],
      'Vorschläge und Zeit gerade gedrosselt — kurz warten oder sparsam planen.',
    );
    expect(
      lines[1],
      'Suggestions and times are limited — wait a bit or plan sparingly.',
    );
    expect(
      lines[2],
      'Suggestions et durées limitées — attends un peu ou planifie avec parcimonie.',
    );
    expect(
      lines[3],
      'Suggerimenti e tempi limitati — aspetta un po’ o pianifica con parsimonia.',
    );
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('valhalla')));
      expect(lower, isNot(contains('osrm')));
      expect(lower, isNot(contains('graphhopper')));
    }
  });

  test('live-route honesty is Hof copy, no routing engine', () {
    final de = AppLocalizationsDe();
    final en = AppLocalizationsEn();
    final fr = AppLocalizationsFr();
    final it = AppLocalizationsIt();
    expect(
      de.discoverHonestyRoad,
      'Route folgt überwiegend Straßen — Trail auf der Karte antippen und anhängen.',
    );
    expect(
      de.discoverHonestyCycleway,
      'Wenig eigener Radweg — Live-Strecke oft auf der Fahrbahn.',
    );
    expect(
      en.discoverHonestyRoad,
      'Route mostly follows roads — tap a trail on the map and attach it.',
    );
    expect(
      en.discoverHonestyCycleway,
      'Little dedicated bike path — the live route often stays on the road.',
    );
    expect(
      fr.discoverHonestyCycleway,
      'Peu de piste cyclable — la route live reste souvent sur la chaussée.',
    );
    expect(
      it.discoverHonestyCycleway,
      'Poco percorso ciclabile — la route live resta spesso sulla carreggiata.',
    );
    expect(
      de.discoverRiderHonestyFor(de.discoverHonestyRoad),
      de.discoverHonestyRoad,
    );
    expect(
      en.discoverRiderHonestyFor(de.discoverHonestyCycleway),
      en.discoverHonestyCycleway,
    );
    expect(
      fr.discoverRiderHonestyFor(
        'Route folgt überwiegend Straßen — Trail auf der Karte antippen und anhängen.',
      ),
      fr.discoverHonestyRoad,
    );
    final lines = <String>[
      de.discoverHonestyRoad,
      de.discoverHonestyCycleway,
      en.discoverHonestyRoad,
      en.discoverHonestyCycleway,
      fr.discoverHonestyRoad,
      fr.discoverHonestyCycleway,
      it.discoverHonestyRoad,
      it.discoverHonestyCycleway,
    ];
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('valhalla')));
      expect(lower, isNot(contains('osrm')));
      expect(lower, isNot(contains('graphhopper')));
    }
    expect(fr.discoverOaOffline, contains('Outdooractive'));
  });

  testWidgets('RouteVariantChips shows live-route hint when disabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RouteVariantChips(
            value: RouteVariant.planned,
            enabled: false,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Ohne Live-Strecke keine Varianten'), findsOneWidget);
    expect(find.textContaining('Valhalla'), findsNothing);
  });

  testWidgets('discoverCatalogTours is singular for one', (tester) async {
    late AppLocalizations de;
    late AppLocalizations en;
    late AppLocalizations fr;
    late AppLocalizations it;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            de = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(de.discoverCatalogTours(1), 'Katalog 1 Tour');
    expect(de.discoverCatalogTours(2), 'Katalog 2 Touren');
    expect(de.discoverCatalogTours(0), 'Katalog 0 Touren');
    expect(de.discoverToursNearbyCount(1), '1 Tour in der Nähe');
    expect(de.discoverToursNearbyCount(2), '2 Touren in der Nähe');
    expect(de.discoverToursNearbyCount(0), '0 Touren in der Nähe');
    expect(de.discoverOaCount(1), '1 Tour in der Nähe');
    expect(de.discoverOaCount(2), '2 Touren in der Nähe');
    expect(de.filterShowTours(1), '1 Tour zeigen');
    expect(de.filterShowTours(2), '2 Touren zeigen');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            en = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(en.discoverCatalogTours(1), 'Catalog 1 tour');
    expect(en.discoverCatalogTours(2), 'Catalog 2 tours');
    expect(en.discoverToursNearbyCount(1), '1 tour nearby');
    expect(en.discoverToursNearbyCount(2), '2 tours nearby');
    expect(en.discoverOaCount(1), '1 tour nearby');
    expect(en.discoverOaCount(2), '2 tours nearby');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            fr = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(fr.discoverCatalogTours(1), 'Catalogue 1 tour');
    expect(fr.discoverCatalogTours(2), 'Catalogue 2 tours');
    expect(fr.discoverToursNearbyCount(1), '1 tour à proximité');
    expect(fr.discoverToursNearbyCount(2), '2 tours à proximité');
    expect(
      fr.discoverOaCount(1),
      'Outdooractive 1 tour · OSM/traces suivent',
    );
    expect(
      fr.discoverOaCount(2),
      'Outdooractive 2 tours · OSM/traces suivent',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            it = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(it.discoverCatalogTours(1), 'Catalogo 1 tour');
    expect(it.discoverCatalogTours(2), 'Catalogo 2 tour');
    expect(it.discoverToursNearbyCount(1), '1 tour nelle vicinanze');
    expect(it.discoverToursNearbyCount(2), '2 tour nelle vicinanze');
    expect(it.discoverOaCount(1), '1 tour qui vicino');
    expect(it.discoverOaCount(2), '2 tour qui vicino');
  });
}
