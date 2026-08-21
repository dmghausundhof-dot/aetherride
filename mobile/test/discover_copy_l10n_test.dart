import 'package:aetherride_mobile/domain/routing/route_variant.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/l10n/app_localizations_de.dart';
import 'package:aetherride_mobile/l10n/app_localizations_en.dart';
import 'package:aetherride_mobile/l10n/app_localizations_fr.dart';
import 'package:aetherride_mobile/l10n/app_localizations_it.dart';
import 'package:aetherride_mobile/l10n/app_localizations_nl.dart';
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
      AppLocalizationsNl().discoverVariantValhallaOnly,
    ];
    expect(lines[0],
        'Weniger hm und mehr Schotter nur mit Live-Strecke — du siehst die geplante Linie.');
    expect(lines[1],
        'Flatter and more gravel need a live route — this is the planned line.');
    expect(lines[2],
        'Moins de dénivelé et plus de graviers uniquement avec la route live.');
    expect(lines[3], 'Meno dislivello e più ghiaia solo con la route live.');
    expect(lines[4],
        'Minder hm en meer grind alleen met live-route — dit is de geplande lijn.');
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('valhalla')));
      expect(lower, isNot(contains('osrm')));
      expect(lower, isNot(contains('graphhopper')));
    }
    final de = AppLocalizationsDe();
    expect(
      de.discoverRiderHonestyFor(
        'Weniger hm und mehr Schotter nur mit Live-Strecke — du siehst die geplante Linie.',
      ),
      de.discoverVariantValhallaOnly,
    );
    expect(
      de.discoverRiderHonestyFor(
        'Ohne Live-Strecke keine Varianten — Route wie geplant.',
      ),
      de.discoverVariantValhallaOnly,
      reason: 'legacy engine warning still maps',
    );
  });

  test('quick-limit hint is Hof copy, no routing engine', () {
    final lines = <String>[
      AppLocalizationsDe().discoverGhMinuteLimit,
      AppLocalizationsEn().discoverGhMinuteLimit,
      AppLocalizationsFr().discoverGhMinuteLimit,
      AppLocalizationsIt().discoverGhMinuteLimit,
      AppLocalizationsNl().discoverGhMinuteLimit,
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
    expect(
      lines[4],
      'Suggesties en tijden zijn beperkt — wacht even of plan spaarzaam.',
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
      en.discoverRiderHonestyFor(de.discoverHonestyFarmTail),
      en.discoverHonestyFarmTail,
    );
    expect(
      en.discoverRiderHonestyFor(de.discoverHonestyFarmMid),
      en.discoverHonestyFarmMid,
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
      de.discoverHonestyFarmTail,
      de.discoverHonestyFarmMid,
      en.discoverHonestyRoad,
      en.discoverHonestyCycleway,
      en.discoverHonestyFarmTail,
      en.discoverHonestyFarmMid,
      fr.discoverHonestyRoad,
      fr.discoverHonestyCycleway,
      fr.discoverHonestyFarmTail,
      it.discoverHonestyRoad,
      it.discoverHonestyCycleway,
    ];
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('valhalla')));
      expect(lower, isNot(contains('osrm')));
      expect(lower, isNot(contains('graphhopper')));
    }
    expect(
        fr.discoverOaOffline.toLowerCase(), isNot(contains('outdooractive')));
  });

  testWidgets('RouteVariantChips show planned plus live-route hint when off', (
    tester,
  ) async {
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
    expect(find.text('Wie geplant'), findsOneWidget);
    expect(
      find.textContaining('geplante Linie'),
      findsOneWidget,
    );
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
      '1 tour à proximité',
    );
    expect(
      fr.discoverOaCount(2),
      '2 tours à proximité',
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

  test('offline coverage labels distinguish loaded vs suggested', () {
    final de = AppLocalizationsDe();
    expect(
      de.offlineCoverageLabel('Schwarzwald Süd'),
      'Schwarzwald Süd · Routing',
    );
    expect(
      de.offlineCoverageLabelFor('Saarland', packId: 'de-saarland'),
      'Saarland · Routing · Landesfläche',
    );
    expect(
      de.offlineCoverageLabelFor('Rhein-Neckar', packId: 'rhein-neckar'),
      'Rhein-Neckar · Routing',
    );
    expect(de.offlineOverviewExplain, contains('Straßenkarte'));
    expect(de.offlineMapsHint.toLowerCase(), isNot(contains('street-tiles')));
    expect(de.offlineOverviewExplain.toLowerCase(),
        isNot(contains('street-tiles')));
    expect(de.offlineConfirmLargeBody('X', '1 MB').toLowerCase(),
        isNot(contains('street tiles')));
    expect(
      AppLocalizationsEn().offlineConfirmLargeBody('X', '1 MB').toLowerCase(),
      isNot(contains('street tiles')),
    );
    expect(de.rideHudStreetNeedsNet, 'Straßenkarte braucht Netz');
    expect(de.rideHudStreetOutside, contains('nicht hier'));
    expect(de.hofRefreshStreetMap, contains('erneuern'));
    expect(
      de.hofPackReadyRideMap('Rhein-Neckar'),
      'Rhein-Neckar · Routing offline. Ride-Karte: Netz.',
    );
    expect(
      de.hofPackReadyRideStreet('Rhein-Neckar'),
      'Rhein-Neckar · Routing und Straßenkarte offline.',
    );
    expect(de.hofPackReadyRideMap('X').toLowerCase(), isNot(contains('tile')));
    expect(
      de.offlineMapsProfileSubtitle(
        ready: false,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
      ),
      de.profileOfflineMapsHint,
    );
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
      ),
      de.hofPackReadyRideMap('Rhein-Neckar'),
    );
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
        streetReady: true,
      ),
      de.hofPackReadyRideStreet('Rhein-Neckar'),
    );
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar / Heidelberg',
      ),
      de.hofPackReadyRideMap('Rhein-Neckar'),
    );
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
        outside: true,
      ),
      de.offlineCoverageOutside('Rhein-Neckar'),
    );
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
        outside: true,
        streetReady: true,
      ),
      de.offlineCoverageOutsideStreet('Rhein-Neckar'),
    );
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
        streetAway: true,
      ),
      de.offlineCoverageStreetAway('Rhein-Neckar'),
    );
    // Same copy as Discover snack after activate when GPS is outside.
    expect(
      de.offlineMapsProfileSubtitle(
        ready: true,
        packId: 'rhein-neckar',
        packName: 'Rhein-Neckar',
        outside: true,
        streetAway: true,
      ),
      de.offlineCoverageOutsideStreetAway('Rhein-Neckar'),
    );
    expect(de.offlineStreetCorridorCta('12 MB'), contains('Standort'));
    expect(de.offlineStreetRouteCta('8 MB'), contains('Tour'));
    expect(de.hofLoadStreetMap, contains('Straßenkarte'));
    expect(de.offlineSketchStreet, 'Straße');
    expect(de.hofSkyNeedNet, 'Himmel braucht Netz.');
    expect(de.dieBoxChipCsc, 'Tacho');
    expect(de.postRideFactSoc('42'), 'Akku 42%');
    expect(de.werkstattWatchEbike.toLowerCase(), isNot(contains('csc')));
    expect(de.werkstattWatchEbike.toLowerCase(), isNot(contains('soc')));
    expect(de.profileBikeBleIdle.toLowerCase(), isNot(contains('csc')));
    expect(
      AppLocalizationsEn().werkstattBatteryHonestHint.toLowerCase(),
      isNot(contains('gatt')),
    );
    expect(
      AppLocalizationsFr().discoverOaCount(1).toLowerCase(),
      isNot(contains('outdooractive')),
    );
    expect(de.discoverOaOffline, contains('Netz'));
    expect(de.discoverTrailOffline, contains('Netz'));
    expect(
      AppLocalizationsFr().discoverOaOffline.toLowerCase(),
      isNot(contains('outdooractive')),
    );
    expect(
      AppLocalizationsFr().discoverOaNoLive.toLowerCase(),
      isNot(contains('outdooractive')),
    );
    expect(de.rerouteHintOffline, contains('Netz'));
    expect(de.rerouteHintOffline.toLowerCase(),
        isNot(contains('offline-reroute')));
    expect(de.rideChipRoutingOfflineShort, 'Routing offline');
    expect(de.discoverLayersNeedNet, contains('Netz'));
    expect(de.discoverSearchNeedNet, 'Suche braucht Netz.');
    expect(de.discoverViasNeedNet, 'Zwischenziele brauchen Netz.');
    expect(de.discoverViasDropAndGo, 'Ohne Zwischenziele weiter');
    expect(de.dieBoxChipSag, 'Federung');
    expect(de.dieBoxChipSag.toLowerCase(), isNot(contains('sag')));
    expect(de.garageMeasureSag, 'Federung merken');
    expect(de.garageMeasureSag.toLowerCase(), isNot(contains('sag')));
    expect(de.dieBoxSagFork.toLowerCase(), isNot(contains('sag')));
    expect(de.werkstattSetupSuspension.toLowerCase(), isNot(contains('sag')));
    expect(de.dieBoxSagHint.toLowerCase(), contains('sag'));
    expect(de.postRideReasonRms('1.2').toLowerCase(), isNot(contains('rms')));
    expect(
      de.postRideSugReboundFastContent('8', '10').toLowerCase(),
      isNot(contains('dive')),
    );
    expect(
      AppLocalizationsEn().postRideSugReboundFastEffect.toLowerCase(),
      isNot(contains('bottom-out')),
    );
    expect(
      AppLocalizationsEn().postRideBrakeDive.toLowerCase(),
      isNot(contains('dive')),
    );
    expect(de.dieBoxSagLoggedShort, 'Federung gemerkt');
    expect(de.rideGPeak, 'g-Spitze');
    expect(de.rideLean, 'Neigung');
    expect(de.hudPeekLabelFor('Lean'), 'Neigung');
    expect(
      de.postRideObsImpacts('12', '18').toLowerCase(),
      contains('stöße'),
    );
    expect(
      de.postRideFactMetrics('1.2', '5.1', '8').toLowerCase(),
      isNot(contains('impact')),
    );
    expect(
      de.postRideFactMetricsLean('1.2', '5.1', '8', '12').toLowerCase(),
      isNot(contains('lean')),
    );
    expect(
      de.postRideSugPressureEffect.toLowerCase(),
      isNot(contains('bottom-out')),
    );
    expect(de.bleStatusRetry('2', '4'), de.bleStatusAttempt('2', '4'));
    expect(AppLocalizationsEn().rideGPeak.toLowerCase(),
        isNot(contains('g-peak')));
    expect(
      AppLocalizationsEn().postRideFactMetrics('1', '2', '3').toLowerCase(),
      isNot(contains('impact')),
    );
    expect(de.offlineSearchRegion, 'Pack suchen');
    expect(
        AppLocalizationsEn().offlineCoverageSuggested('Alps'), 'Load · Alps');
    expect(de.offlineCoverageOutside('Rhein-Neckar'), 'Außerhalb Rhein-Neckar');
    expect(
      de.offlineCoverageOutsideStreet('Rhein-Neckar'),
      'Außerhalb Rhein-Neckar · Straße offline',
    );
    expect(de.offlineRoutingAway, 'Routing nicht hier');
    expect(
      de.offlineReadyStreetHereRoutingAway,
      'Straßenkarte bereit. Routing nicht am Standort.',
    );
    expect(
      AppLocalizationsEn().offlineCoverageOutside('Alps'),
      'Outside Alps',
    );
    expect(de.offlineCoverageShowOnMap, 'Region auf der Karte zeigen');
    expect(
      de.offlineCoverageEdgeFor('Rhein-Neckar / Heidelberg', outside: true),
      'Außerhalb Rhein-Neckar',
    );
    expect(
      de.offlineCoverageEdgeFor(
        'Rhein-Neckar / Heidelberg',
        outside: true,
        streetReady: true,
      ),
      'Außerhalb Rhein-Neckar · Straße offline',
    );
    expect(
      de.offlineCoverageEdgeFor('Rhein-Neckar / Heidelberg', outside: false),
      de.offlineCoverageLabelFor('Rhein-Neckar'),
    );
    expect(
      de.offlineCoverageEdgeFor(
        'Rhein-Neckar',
        outside: false,
        overviewStyle: true,
      ),
      'Rhein-Neckar · Übersicht',
    );
    expect(
      de.offlineCoverageEdgeFor(
        'Rhein-Neckar',
        outside: false,
        mapNeedsNet: true,
      ),
      'Rhein-Neckar · Karte: Netz',
    );
    expect(
      de.offlineCoverageEdgeFor(
        'Rhein-Neckar',
        outside: false,
        streetAway: true,
      ),
      'Rhein-Neckar · Straße nicht hier',
    );
    expect(
      de.offlineCoverageEdgeFor(
        'Rhein-Neckar',
        outside: true,
        streetAway: true,
      ),
      'Außerhalb Rhein-Neckar · Straße nicht hier',
    );
    expect(de.offlineStreetAway, 'Straße nicht hier');
    expect(de.offlineGraphReadySnack, contains('orangen Box'));
    expect(de.offlineBrowseOverviewSnack, contains('Zoom 0–11'));
    expect(de.offlineSketchRouting, 'Routing');
    expect(de.offlineSketchOverview, 'Übersicht');
    expect(de.offlineSubInstalled, 'Installiert');
    expect(de.offlineSubInstalled.toLowerCase(), isNot(contains('tippen')));
    expect(de.offlineNoneFound, 'Kein Pack gefunden');
    expect(de.offlineSubValhalla.toLowerCase(), isNot(contains('valhalla')));
    expect(de.offlineDachCatalog.toLowerCase(), isNot(contains('region')));
    expect(de.offlineSubEnvelope, contains('Landesfläche'));
    expect(de.offlineEnvelopesHint.toLowerCase(), isNot(contains('bbox')));
    expect(de.offlineEnvelopesHint.toLowerCase(), isNot(contains('bounding')));
    expect(
      de.overlayRegionNameFor('de-saarland'),
      'Saarland',
    );
    expect(de.overlayRegionNameFor('ch-wallis'), 'Wallis');
    expect(AppLocalizationsFr().overlayRegionNameFor('ch-wallis'), 'Valais');
    expect(AppLocalizationsIt().overlayRegionNameFor('ch-tessin'), 'Ticino');
    expect(
      de.discoverOfflineAfterSaveForPack('Saarland', '54.2 MB',
          packId: 'de-saarland'),
      'Saarland · 54.2 MB — Landesfläche laden?',
    );
    expect(de.discoverOfflineNoRoute.toLowerCase(), contains('pack'));
    expect(
      de.offlineSubEnvelopeSized('54.2 MB'),
      '54.2 MB · Routing · Landesfläche',
    );
    expect(de.billingMoreBikes.toLowerCase(), contains('free'));
    expect(de.billingMoreBikes.toLowerCase(), contains('pro'));
    expect(de.billingMoreBikes.toLowerCase(), isNot(contains('region')));
    expect(de.offlineInvalidGraphFolder('x'), contains('Pack'));
    expect(
      de.offlineInvalidGraphFolder('x').toLowerCase(),
      isNot(contains('region')),
    );
    expect(
      de.navigateOfflineHintForPack('Rhein-Neckar', '10.5 MB'),
      'Rhein-Neckar · 10.5 MB — Routing in dieser Box',
    );
    expect(
      de.navigateOfflineHintForPack(
        'Saarland',
        '54.2 MB',
        packId: 'de-saarland',
      ),
      'Saarland · 54.2 MB — Routing auf der Landesfläche',
    );
    expect(
      de
          .navigateOfflineHintForPack(
            'Saarland',
            '54.2 MB',
            packId: 'de-saarland',
          )
          .toLowerCase(),
      isNot(contains('box')),
    );
  });

  test('filter length is not the Around distance chip', () {
    final de = AppLocalizationsDe();
    final en = AppLocalizationsEn();
    expect(de.filterTourLength, 'Tourenlänge');
    expect(en.filterTourLength, 'Tour length');
    expect(de.filterTourLength, isNot(de.filterDistance));
    expect(de.filterSportDh, 'DH-Rad');
    expect(en.filterSportDh, 'DH bike');
    expect(de.filterSportDh, isNot(de.filterFormDownhill));
    expect(en.discoverPeekAwayKm(11), '11 km away');
    expect(de.discoverPeekAwayKm(11), '11 km entfernt');
  });

  test('plan sheet copy: Planen, Start tippen, Ziel setzen', () {
    final de = AppLocalizationsDe();
    final en = AppLocalizationsEn();
    expect(de.planRouteTitle, 'Planen');
    expect(de.planRouteCta, 'Planen');
    expect(de.discoverModeNavigate, 'Planen');
    expect(de.discoverBackToGps, 'Zurück zu GPS');
    expect(de.navigateSubtitleShape.contains('Zwischenstopp'), isTrue);
    expect(de.navigateSubtitleShape.contains('Langer Druck'), isTrue);
    expect(de.planUndo, 'Rückgängig');
    expect(de.planRedo, 'Wiederholen');
    expect(de.discoverTapStart, 'Start tippen');
    expect(de.discoverSetEndCta, 'Ziel setzen');
    expect(de.discoverReplaceDest, 'Ziel ersetzen');
    expect(de.discoverReplaceStart, 'Start ersetzen');
    expect(de.discoverRecently, 'Zuletzt');
    expect(de.discoverOnMapPlace, 'Punkt auf der Karte');
    expect(de.planEditLineHint.contains('Scheiben'), isTrue);
    expect(de.planEditLineHint.contains('Halten'), isTrue);
    expect(de.planLineCoach.contains('Höhenprofil'), isTrue);
    expect(de.planLineCoachShort.contains('Halten'), isTrue);
    expect(de.planLineCoachAdopt.contains('merken'), isTrue);
    expect(de.planMapSteep, 'Steil');
    expect(de.planMapUnknown, 'Unbekannt');
    expect(de.navigateViaHint.contains('Höhenprofil'), isTrue);
    expect(de.planTickKm('5'), '5 km');
    expect(de.planAlongKm('1.5').contains('1.5'), isTrue);
    expect(de.discoverPlaceHoldForDest.contains('Halten'), isTrue);
    expect(de.planUndo, 'Rückgängig');
    expect(de.planRedo, 'Wiederholen');
    expect(de.planStopSetHint.contains('Stopp gesetzt'), isTrue);
    expect(de.discoverLastDestApplied.contains('Ziel'), isTrue);
    expect(en.discoverLastDestApplied.toLowerCase(), contains('destination'));
    expect(
        de.planElevSteepHint, 'Rot steil · Orange flach · Blau ab · Braun Weg');
    expect(de.discoverPlaceOnRoute, 'In die Route');
    expect(de.navigateCloseLoopHint, 'Runde: Ziel wird der Start.');
    expect(AppLocalizationsEn().discoverSetEndCta, 'Set destination');
    expect(AppLocalizationsEn().discoverTapStart, 'Tap start');
    expect(AppLocalizationsEn().planRouteCta, 'Plan');
    expect(AppLocalizationsEn().navigateCloseLoopHint,
        'Loop: destination becomes start.');
  });

  test('around-you loop copy is Hof copy, no routing engine', () {
    expect(AppLocalizationsDe().discoverAroundYouCta, 'Hier rundherum');
    expect(
      AppLocalizationsDe().discoverAroundYouLoop,
      'Rundkurs um dich · OSM-Wege',
    );
    final lines = <String>[
      AppLocalizationsDe().discoverAroundYouCta,
      AppLocalizationsDe().discoverAroundYouAnother,
      AppLocalizationsDe().discoverAroundYouLoop,
      AppLocalizationsDe().discoverAroundYouHint,
      AppLocalizationsDe().discoverAroundYouBusy,
      AppLocalizationsDe().discoverAroundYouFail,
      AppLocalizationsDe().discoverAroundYouSport,
      AppLocalizationsDe().discoverAroundYouUncertain,
      AppLocalizationsDe().discoverAroundYouUncertainShort,
      AppLocalizationsDe().discoverAroundYouStats('18.2', 61),
      AppLocalizationsDe().discoverLoopReasonDuration('61', '60'),
      AppLocalizationsDe().discoverLoopReasonSurface('Asphalt'),
      AppLocalizationsDe().discoverLoopReasonOsmTags,
      AppLocalizationsEn().discoverAroundYouCta,
      AppLocalizationsFr().discoverAroundYouCta,
      AppLocalizationsIt().discoverAroundYouCta,
      AppLocalizationsNl().discoverAroundYouCta,
    ];
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('valhalla')));
      expect(lower, isNot(contains('osrm')));
      expect(lower, isNot(contains('graphhopper')));
      expect(lower, isNot(contains('openrouteservice')));
    }
  });
}
