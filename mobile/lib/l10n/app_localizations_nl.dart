// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'FlowLine';

  @override
  String get appTagline =>
      'Ride further. Flow better — MTB, gravel, race, city & e-bike.';

  @override
  String get navHome => 'Start';

  @override
  String get navGarage => 'Garage';

  @override
  String get navRide => 'Rijden';

  @override
  String get navDiscover => 'Tochten';

  @override
  String get navParts => 'Onderdelen';

  @override
  String get navKarte => 'Kaart';

  @override
  String get navWorkshop => 'Fiets';

  @override
  String get navShop => 'Winkel';

  @override
  String get navPlatz => 'Tochten';

  @override
  String navTabOf(int index, int count) {
    return 'Tab $index van $count';
  }

  @override
  String get hofJustRide => 'Gewoon rijden';

  @override
  String get hofShowTours => 'Tochten tonen';

  @override
  String get hofMapChoiceHint =>
      'Rijd zonder route, of toon tochten op de kaart.';

  @override
  String get werkstattPartsShelf => 'Winkel';

  @override
  String get werkstattForYourBike => 'Voor jouw fiets';

  @override
  String get werkstattMerch => 'Merchandise';

  @override
  String get werkstattShopParts => 'Onderdelen in de winkel';

  @override
  String get werkstattPartsForBike => 'Onderdelen voor jouw fiets';

  @override
  String get shopLookupInShop => 'Opzoeken in de winkel';

  @override
  String get shopGatewayKicker => 'Over het erf';

  @override
  String get shopGatewayTitle => 'De winkel';

  @override
  String get shopGatewayHint =>
      'De fiets woont hier niet. FlowLine toont onderdelen — je koopt bij de handelaar, niet in de app. Shopify-kassa staat voorlopig uit.';

  @override
  String get shopZumShop => 'Naar de winkel';

  @override
  String shopForYourBikeHint(String name) {
    return 'Onderdelen die passen bij $name — categorie en wielmaat. Geen verzonnen SKU’s.';
  }

  @override
  String get shopForYourBikeEmpty =>
      'Zet een fiets in de werkplaats — dan openen we passende onderdelen in de winkel.';

  @override
  String get shopMerchHint =>
      'Kleding en klein spul. Nooit gefilterd op fietspassing.';

  @override
  String get shopMerchTitle => 'Kleding';

  @override
  String get shopMerchEmpty =>
      'Geen merch in het schap. Kleding blijft in de winkel, nooit gefilterd op de fiets.';

  @override
  String get shopNotConnected => 'Winkel niet verbonden';

  @override
  String get shopNotConnectedHint =>
      'Geen storefront-URL. Zet SHOPIFY_STOREFRONT_URL, dan opent de werkplaats de winkel.';

  @override
  String get shopOpenFailed => 'Winkel kon niet worden geopend.';

  @override
  String get shopPasswordWall =>
      'De winkel buiten is nog niet openbaar — er kan een wachtwoord staan. Het schap hier blijft.';

  @override
  String get shopLockedTitle => 'Winkel buiten nog dicht';

  @override
  String get shopPasswordConfirm => 'Toch openen';

  @override
  String get shopPasswordCancel => 'Terug';

  @override
  String get shopCyclingParts => 'Onderdelen';

  @override
  String get shopSearchHint => 'Onderdelen, merken, maten…';

  @override
  String get shopFeatured => 'Passende onderdelen';

  @override
  String get shopOpenProduct => 'Openen in de winkel';

  @override
  String get shopAllParts => 'Alle onderdelen';

  @override
  String shopFitBanner(String name) {
    return 'Onderdelen die passen bij $name';
  }

  @override
  String get shopShelfEmpty => 'Geen onderdelen bij deze zoekopdracht.';

  @override
  String get shopCatalogEmpty => 'Nog geen onderdelen in het schap.';

  @override
  String get shopFitOnly => 'Alleen passend';

  @override
  String get shopFitAllBikes => 'Alle fietsen';

  @override
  String get shopFitBannerAll => 'Onderdelen die passen bij jouw fietsen';

  @override
  String get shopOpenInBrowser => 'Openen in de browser';

  @override
  String get shopZumHaendler => 'Koop bij de handelaar';

  @override
  String get shopOpenInApp => 'Bekijk in de winkel';

  @override
  String get shopProductMissing => 'Dit product ligt niet in de winkel.';

  @override
  String get shopCatalogFailed =>
      'Catalogus nu niet bereikbaar. Probeer later opnieuw.';

  @override
  String get shopRetry => 'Opnieuw';

  @override
  String get shopSheetCheckout =>
      'De handelaar is verkoper en contractpartner — niet FlowLine.';

  @override
  String get shopDetails => 'Details';

  @override
  String get shopFeaturedBikes => 'Fietsen in de winkel';

  @override
  String get garageSetupTabHintTires =>
      'Grove bandenspanning naar gewicht — meet op de fiets, geen OEM-tabel.';

  @override
  String get werkstattSetupTires => 'Banden / grove spanning';

  @override
  String get werkstattSetupSuspension => 'Vering — SAG en lucht uit veerweg';

  @override
  String get werkstattSetupSuspensionUnknown =>
      'Vering — veerweg niet vastgelegd';

  @override
  String get werkstattSetupDropper => 'Dropper (vastgelegd)';

  @override
  String werkstattSetupWheel(String size) {
    return 'Wielen $size';
  }

  @override
  String get werkstattSetupCockpit => 'Cockpit — stuur en stuurpen';

  @override
  String get werkstattSetupBagsCockpit => 'Tassen / cockpit';

  @override
  String get werkstattSetupLightsRack =>
      'Verlichting en rek — alleen als vastgelegd';

  @override
  String get werkstattSetupDrivetrain => 'Aandrijving';

  @override
  String get werkstattBatteryHonest => 'Accu alleen met een echte sensor';

  @override
  String get werkstattBatteryHonestHint =>
      'Geen percentage zonder gekoppelde sensor. Bosch SoC via LDI (Flow → Components) of standaard GATT.';

  @override
  String get werkstattSensorEbike =>
      'Wielsensor (CSC) — snelheid en cadans. Accu alleen met een echte sensor.';

  @override
  String get werkstattSensorAnalog =>
      'Wielsensor — snelheid en cadans op de fiets.';

  @override
  String get hofYourWatch => 'Jouw horloge';

  @override
  String get hofWatchHint => 'Hartslag van een echte sensor.';

  @override
  String get hofWatchPair => 'Hartslagsensor';

  @override
  String get hofWatchReconnect => 'Verbinden';

  @override
  String get hofWatchRemove => 'Verwijderen';

  @override
  String get hofWatchConnect => 'Horloge verbinden';

  @override
  String get werkstattWatchEbike =>
      'Horloge — hartslag naast CSC. Geen verzonnen SoC.';

  @override
  String get werkstattWatchAnalog => 'Smartwatch / fitnesstracking';

  @override
  String get setupTirePressureLabel => 'Voorband (psi)';

  @override
  String get setupCompareHintTires =>
      'Maakt twee blinde bandenspanningen. Na een paar ritten zie je wat beter voelt.';

  @override
  String setupTirePressureValue(String value) {
    return 'Banden $value psi';
  }

  @override
  String get searchHome => 'Waarheen? Plaats, tocht of adres';

  @override
  String get startRide => 'Start rit';

  @override
  String get startFreeride => 'Rijden zonder route';

  @override
  String get startWithRoute => 'Route rijden';

  @override
  String get goRide => 'Rijden maar';

  @override
  String get readyTitle => 'Klaar om te rijden';

  @override
  String get readyMessage =>
      'GPS-tracking start meteen. Sensoren en route zijn optioneel — trail, asfalt of stad.';

  @override
  String get optionalRoute =>
      'Optioneel: kies een route onder Tochten en tik op “Rijden maar”.';

  @override
  String get starting => 'Starten…';

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get reset => 'Resetten';

  @override
  String errorPrefix(String error) {
    return 'Fout: $error';
  }

  @override
  String get discoverMenuPhotos => 'Foto’s in de buurt';

  @override
  String get discoverMenuOffline => 'Offlinekaarten';

  @override
  String get discoverMenuCollections => 'Collecties';

  @override
  String get discoverMenuPrivacy => 'Gegevens & privacy';

  @override
  String get partsTitle => 'Onderdelen & spullen';

  @override
  String get partsSubtitle =>
      'Live uitgelichte onderdelen in FlowLine — zachte passing & prijzen, geen Shopify-wachtwoorddoodlopend.';

  @override
  String get weatherFallback => 'Weer niet beschikbaar';

  @override
  String get weatherLoading => 'Weer laden…';

  @override
  String get statsRidesOne => 'rit';

  @override
  String get statsRidesMany => 'ritten';

  @override
  String get profile => 'Profiel';

  @override
  String get chat => 'Chat';

  @override
  String get hofRideOut => 'Rijden';

  @override
  String get hofOpenBike => 'Fiets openen';

  @override
  String get hofParkBike => 'Fiets toevoegen';

  @override
  String get hofRideWithoutBike => 'Rijden zonder fiets';

  @override
  String get hofRideOutAgain => 'Opnieuw rijden';

  @override
  String get hofAtGate => 'bij de poort';

  @override
  String get hofEmptyStand => 'Lege stand';

  @override
  String get hofSkyUnknown => 'Hemel onbekend';

  @override
  String get hofNoHonestLoop => 'Geen lus in de buurt';

  @override
  String get hofGateWetClosed =>
      'Trails nat — geen eerlijke verharde lus in de buurt';

  @override
  String get hofNotYetOut => 'nog niet weg';

  @override
  String get hofJustBack => 'net terug';

  @override
  String hofAgoMinutes(int minutes) {
    return '$minutes min geleden';
  }

  @override
  String hofAgoHours(int hours) {
    return '$hours u geleden';
  }

  @override
  String get hofWhatCameIn => 'Wat binnenkwam';

  @override
  String hofPackMissing(String name) {
    return 'Geen pack voor $name';
  }

  @override
  String get hofLastRideNoGps => 'geen GPS-track — niets verzonnen';

  @override
  String get hofGpsUnknown => 'Locatie toestaan';

  @override
  String get hofAllowLocation => 'Locatie toestaan';

  @override
  String get hofHintsTitle => 'Meldingen';

  @override
  String get hofHintsEmpty => 'Niets open.';

  @override
  String get hofHintsTooltip => 'Meldingen';

  @override
  String get rideGpsUnavailable =>
      'Geen GPS — track blijft leeg. Niets verzonnen.';

  @override
  String get hofAtHof => 'op de stand';

  @override
  String hofGarageType(String type) {
    return 'Type $type';
  }

  @override
  String get hofSinceOneDay => '1 dag';

  @override
  String hofSinceDays(int days) {
    return '$days dagen';
  }

  @override
  String get hofNoBikeHere => 'Geen fiets hier';

  @override
  String hofBringForward(String name) {
    return 'Haal $name naar voren';
  }

  @override
  String hofCareInWorkshop(String label) {
    return '$label — in de werkplaats';
  }

  @override
  String get hofSensorAwake => 'Sensor wakker';

  @override
  String get hofOpenTours => 'Tochten op de kaart';

  @override
  String hofSkyDry(String temp) {
    return '$temp° · eerder droog';
  }

  @override
  String hofSkyDamp(String temp) {
    return '$temp° · vochtig mogelijk';
  }

  @override
  String hofSkyWet(String temp) {
    return '$temp° · regen · trails waarschijnlijk nat';
  }

  @override
  String hofLoopDuration(int minutes) {
    return '⟲ $minutes min';
  }

  @override
  String hofGateAwayKm(int km) {
    return '$km km';
  }

  @override
  String get hofGateAwayNear => 'onder 1 km';

  @override
  String hofCommunityNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stimmen bij deze lus',
      one: '1 Stimme bij deze lus',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMtb => 'Trails, tochten & jouw setup';

  @override
  String get homeSubtitleGravel => 'Gravel, afstand & navigatie';

  @override
  String get homeSubtitleRoad => 'Asfalt, tempo & training';

  @override
  String get homeSubtitleUrban => 'Woon-werk, stad & alledag';

  @override
  String get homeSubtitleEbike => 'Ondersteuning, bereik & tochten';

  @override
  String get homeSubtitleDefault => 'Hoe je ook rijdt — jouw fiets, jouw route';

  @override
  String homeSubtitleWithWeather(String weather, String base) {
    return '$weather · $base';
  }

  @override
  String get tipHeroTitleMtb => 'Vandaag de fiets pakken';

  @override
  String get tipHeroTitleGravel => 'Vandaag gravel of mixed';

  @override
  String get tipHeroTitleRoad => 'Vandaag asfaltkilometers';

  @override
  String get tipHeroTitleUrban => 'Vandaag door de stad';

  @override
  String get tipHeroTitleEbike => 'Vandaag met ondersteuning';

  @override
  String get tipHeroTitleDefault => 'Een rit past vandaag';

  @override
  String get tipHeroSubtitleMtb =>
      'Kies een route of freeride — track blijft lokaal.';

  @override
  String get tipHeroSubtitleGravel => 'Plan een afstand of start zonder route.';

  @override
  String get tipHeroSubtitleRoad => 'Bouw een lus of log vrije training.';

  @override
  String get tipHeroSubtitleUrban => 'Log woon-werk of bewaar een korte lus.';

  @override
  String get tipHeroSubtitleEbike => 'Plan een tocht en houd bereik in beeld.';

  @override
  String get tipHeroSubtitleDefault =>
      'MTB, gravel, race of stad — allemaal hier.';

  @override
  String get chassisLayer => 'Vering';

  @override
  String get sensorLayer => 'Sensoren';

  @override
  String get filter => 'Filter';

  @override
  String get filterReset => 'Resetten';

  @override
  String get filterResetFilters => 'Filters resetten';

  @override
  String get filterDurationLens => 'Duur';

  @override
  String get filterSurfaceGroup => 'Ondergrond';

  @override
  String get filterExertion => 'Moeilijkheid';

  @override
  String get filterDistance => 'Afstand';

  @override
  String get filterElevation => 'Hoogte';

  @override
  String get filterForm => 'Vorm';

  @override
  String get filterFormAll => 'Alle';

  @override
  String get filterFormPointToPoint => 'A→B';

  @override
  String get filterFormPointToPointTooltip =>
      'Etappes en lineaire trails (start≠einde).';

  @override
  String get filterFormDownhill => 'Downhill';

  @override
  String get filterFormDownhillTooltip =>
      'Afdalingen, bikepark, enduro A→B. Lussen zijn niet automatisch DH.';

  @override
  String get filterBikeType => 'Fietstype';

  @override
  String get filterBikeTypeHonesty =>
      'Kleuren filteren de tochten. Navigatie: één fietsroute, behalve lopen.';

  @override
  String get filterSingletrail => 'Singletrack (S-schaal)';

  @override
  String get filterSingletrailHint =>
      'Alleen tochten/paden met een eerlijke graad. Geen tag: geen treffers.';

  @override
  String get filterNoDownhillTours => 'Geen downhill-tochten in de buurt';

  @override
  String get filterNoDownhillToursHint =>
      'OSM-trails op S-graad blijven op de kaart. Geen DH-ronde in de catalogus hier.';

  @override
  String get filterNoScaleTours => 'Geen tocht met deze S-graad';

  @override
  String get filterTrailNetwork => 'Trailnetwerk (kaart)';

  @override
  String get filterLoopsOnly => 'Lus';

  @override
  String get filterLoopsOnlyTooltip =>
      'Alleen lussen — start en einde zijn hetzelfde.';

  @override
  String get filterNetworkOn => 'Paden op de kaart';

  @override
  String get filterNetworkOff => 'Paden verbergen';

  @override
  String filterOsmScaleTooltip(String code) {
    return 'OSM-schaal: $code';
  }

  @override
  String filterShowTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toon $count tochten',
      one: 'Toon 1 tocht',
    );
    return '$_temp0';
  }

  @override
  String get filterNoTours => 'Geen tochten bij deze filters.';

  @override
  String get filterNoToursHint =>
      'Geen tochten — tik op “Nieuw” of maak filters ruimer.';

  @override
  String get loopLabel => 'Lus';

  @override
  String get computeRoute => 'Route berekenen';

  @override
  String get adaptTour => 'Bewerken';

  @override
  String get adaptTourTitle => 'Tocht bewerken';

  @override
  String get adaptTourHint =>
      'Wijzig start, einde of stops — dan bereken je de route.';

  @override
  String get planRouteTitle => 'Route plannen';

  @override
  String get planRouteCta => 'Navigeren';

  @override
  String get discoverSearchHint => 'Plaats of tocht';

  @override
  String filterAroundKm(int km) {
    return 'binnen $km km';
  }

  @override
  String get discoverAroundIdle => 'Omgeving';

  @override
  String discoverAroundAwayKm(int km) {
    return '$km km verder';
  }

  @override
  String discoverPeekLoopKm(String km) {
    return '$km km lus';
  }

  @override
  String discoverPeekAwayKm(int km) {
    return '$km km naar de start';
  }

  @override
  String get discoverPeekAwayNear => 'onder 1 km naar de start';

  @override
  String get discoverPeekSave => 'Bewaren';

  @override
  String get discoverPeekAkte => 'Dossier';

  @override
  String get mapToggleFab => 'Kaart';

  @override
  String get communityWriteReview => 'Schrijf een recensie';

  @override
  String get discoverModeExplore => 'Ontdekken';

  @override
  String get discoverModeNavigate => 'Navigeren';

  @override
  String get discoverModeMine => 'Tochten';

  @override
  String get navigateTitle => 'Navigeren';

  @override
  String get navigateSubtitle => 'Tik op bestemming of typ een adres';

  @override
  String get navigateStartLabel => 'Start';

  @override
  String get navigateEndLabel => 'Bestemming';

  @override
  String get navigateStartHint => 'Adres, plaats, of tik op de kaart';

  @override
  String get navigateEndHint => 'Waarheen?';

  @override
  String get navigateMyLocation => 'Mijn locatie';

  @override
  String get navigateSwap => 'Wissel start en bestemming';

  @override
  String get navigatePickStart => 'Tik start op de kaart';

  @override
  String get navigatePickEnd => 'Tik bestemming op de kaart';

  @override
  String get navigateAddVia => 'Stop toevoegen';

  @override
  String get navigateNeedStartEnd => 'Zet start en bestemming';

  @override
  String get navigateComputeNeedBoth =>
      'Route berekenen (start & bestemming nodig)';

  @override
  String get navigateBackToExplore => 'Terug naar Ontdekken';

  @override
  String get mineSheetHint => 'Dezelfde lijst als Tochten — hier op de kaart.';

  @override
  String get mineEmptyCtaNavigate => 'Plan A naar B';

  @override
  String get gpxImportAction => 'GPX importeren';

  @override
  String get exploreOpenNavigate => 'A→B navigeren';

  @override
  String get sheetDragHandleMine => 'Tochtenblad slepen';

  @override
  String get sheetDragHandleNavigate => 'Navigatieblad slepen';

  @override
  String get browseMap => 'Kaart';

  @override
  String get browseList => 'Lijst';

  @override
  String get quickFilter1h => '1 u';

  @override
  String get sheetDragHandle => 'Tochtenblad slepen';

  @override
  String get sheetPeekHint => 'Omhoog trekken — tochten & filters';

  @override
  String get rideBarCollapseHint => 'Veeg omlaag om in te klappen';

  @override
  String get rideBarExpandHint => 'Openen';

  @override
  String get rideBarStart => 'Start';

  @override
  String get rideBarRoute => 'Route';

  @override
  String get rideBarPointToPoint => 'Route';

  @override
  String get emptyToursTitle => 'Geen tochten gevonden';

  @override
  String get emptyToursFiltersBody =>
      'Reset filters om tochten in de buurt weer te zien.';

  @override
  String get emptyToursNearbyBody =>
      'Wijzig plaats of duur — of reset filters.';

  @override
  String get showOnMap => 'Toon op de kaart';

  @override
  String get tourDetails => 'Details';

  @override
  String get moreFilters => 'Meer filters';

  @override
  String get moreActions => 'Meer acties';

  @override
  String get filterSurfaceAsphalt => 'Asfalt';

  @override
  String get filterSurfaceGravel => 'Gravel';

  @override
  String get filterSurfaceTrail => 'Trail';

  @override
  String get filterSurfaceMixed => 'Gemengd';

  @override
  String get filterSurfaceAsphaltHint => 'Asfalt · fietspad · verhard';

  @override
  String get filterSurfaceGravelHint => 'Gravel · bos · verdicht';

  @override
  String get filterSurfaceTrailHint => 'Natuur · singletrack · wortels';

  @override
  String get filterSurfaceMixedHint => 'Stad · gemengde ondergrond';

  @override
  String get filterSurfaceAsphaltFull => 'Asfalt · verhard';

  @override
  String get filterSurfaceGravelFull => 'Gravel · verdicht';

  @override
  String get filterSurfaceTrailFull => 'Natuur · trail';

  @override
  String get filterSurfaceMixedFull => 'Stad · gemengd';

  @override
  String get filterEffortEasy => 'Licht';

  @override
  String get filterEffortMid => 'Matig';

  @override
  String get filterEffortHard => 'Uitdagend';

  @override
  String get filterEffortEasyHint => 'S0 / relaxed / weinig tech';

  @override
  String get filterEffortMidHint => 'S1–S2 / sportief / mixed';

  @override
  String get filterEffortHardHint => 'S2+ / zwaar / technisch';

  @override
  String get filterElevFlat => '< 400 m';

  @override
  String get filterElevHilly => '400–1100 m';

  @override
  String get filterElevAlpine => '1100+ m';

  @override
  String get filterDistMax20 => '≤ 20 km';

  @override
  String get filterDistMax40 => '≤ 40 km';

  @override
  String get filterDistMax70 => '≤ 70 km';

  @override
  String get filterScaleEasy => 'Licht';

  @override
  String get filterScaleMedium => 'Matig';

  @override
  String get filterScaleHard => 'Uitdagend';

  @override
  String get trailDiffEasy => 'Licht';

  @override
  String get trailDiffMedium => 'Matig';

  @override
  String get trailDiffHard => 'Zwaar';

  @override
  String get trailDiffVeryHard => 'Zeer zwaar';

  @override
  String get trailDiffUnrated => 'Zonder graad';

  @override
  String get trailDiffOpen => 'open';

  @override
  String get durationAny => 'alle';

  @override
  String get duration2to3h => '2–3 u';

  @override
  String get garageTitle => 'Garage';

  @override
  String get garageFabBike => 'Fiets toevoegen';

  @override
  String get garageEmptyTitle => 'Nog geen fiets hier';

  @override
  String get garageEmptyMessage =>
      'Naam en type volstaan. De catalogus is zoeken — voorraadonderdelen alleen als je ze overneemt.';

  @override
  String get garageAddBike => 'Fiets toevoegen';

  @override
  String get garageAddAnother => 'Nog een fiets';

  @override
  String get garageStatBike => 'FIETS';

  @override
  String get garageStatBikes => 'FIETSEN';

  @override
  String get garageStatKmTotal => 'KM TOTAAL';

  @override
  String get garageQuickSwitch => 'Snel wisselen';

  @override
  String get garageLastRides => 'Recente ritten';

  @override
  String get garageNoRidesTitle => 'Nog geen ritten';

  @override
  String get garageNoRidesMessage =>
      'Je eerste opgeslagen rit verschijnt hier.';

  @override
  String get garageActive => 'Actief';

  @override
  String garageActiveBike(String name) {
    return 'Actieve fiets · $name';
  }

  @override
  String get garageEbikeBadge => 'E-bike';

  @override
  String get garageMaintOk => 'Alles oké';

  @override
  String garageMaintDue(int count) {
    return '$count toe aan onderhoud';
  }

  @override
  String garageMaintOverdue(int count) {
    return '$count te laat';
  }

  @override
  String garagePartsCount(int count) {
    return '$count onderdelen';
  }

  @override
  String get garageParts => 'Onderdelen';

  @override
  String get garageMaintenance => 'Onderhoud';

  @override
  String get garageSetup => 'Setup';

  @override
  String get garageInstall => 'Onderdeel toevoegen';

  @override
  String get garageOtherBikes => 'Andere fietsen';

  @override
  String get garageTechDetails => 'Technische details';

  @override
  String get garageTechHint =>
      'Veerweg, frame, setup-basics — voor liefhebbers';

  @override
  String get garageCtaMaintenance => 'Onderhoud bekijken';

  @override
  String get garageCtaAddPart => 'Onderdeel toevoegen';

  @override
  String get garageCtaSetActive => 'Als actief zetten';

  @override
  String get garageCtaOpenSetup => 'Naar setup';

  @override
  String get garageHours => 'Uren';

  @override
  String get garageTravel => 'Veerweg';

  @override
  String get garageFrameSize => 'Framemaat';

  @override
  String get garageWheelSize => 'Wielmaat';

  @override
  String get garageBrandModel => 'Model';

  @override
  String garageCompatFits(int count) {
    return 'Past $count';
  }

  @override
  String garageCompatCheck(int count) {
    return 'Controleer $count';
  }

  @override
  String garageCompatNoFit(int count) {
    return 'Past niet $count';
  }

  @override
  String get garagePartsEmpty =>
      'Nog geen onderdelen vastgelegd. Tik op “Onderdeel toevoegen” — dan herinneren we je aan onderhoud en tonen we of onderdelen bij elkaar passen.';

  @override
  String get garageMaintEmpty => 'Alles oké — niets toe aan onderhoud.';

  @override
  String get garageSetupTabTitle => 'Jouw setup';

  @override
  String get garageSetupTabHint =>
      'SAG = hoe ver de vering inzakt met jouw gewicht (vaak ~25–30%).';

  @override
  String get garageYourParts => 'Jouw onderdelen';

  @override
  String get garageMissingSlots => 'Nog niet vastgelegd (optioneel)';

  @override
  String get garageActiveBadge => 'Actieve fiets';

  @override
  String get garageStatKm => 'KM';

  @override
  String get garageStatHours => 'UREN';

  @override
  String get garageStatMaint => 'ONDERHOUD';

  @override
  String get setupVersionsTitle => 'Versies & vergelijken';

  @override
  String get setupVersionsHint =>
      'Elke wijziging slaat een nieuwe versie op. Je kunt altijd teruggaan.';

  @override
  String get setupRiderWeightLabel => 'Rijdersgewicht (kg) voor templates';

  @override
  String get setupNewVersionCta => 'Nieuwe versie';

  @override
  String get setupCompareCta => 'Twee varianten proberen';

  @override
  String get setupCompareHint =>
      'Maakt twee blinde varianten (bijv. rebound). Na een paar ritten zie je wat beter voelt.';

  @override
  String get setupSavedVersions => 'Opgeslagen versies';

  @override
  String get setupEmpty =>
      'Nog geen versies — start vanaf een sjabloon of sla je instellingen op.';

  @override
  String get setupActiveBadge => 'Actief';

  @override
  String setupVersionMeta(int version) {
    return 'Versie $version';
  }

  @override
  String get setupUseVersion => 'Gebruiken';

  @override
  String setupForkReboundValue(String value) {
    return 'Rebound $value';
  }

  @override
  String get setupSourceTemplate => 'Sjabloon';

  @override
  String get setupSourceBaseline => 'Basis';

  @override
  String get setupSourceManual => 'Handmatig';

  @override
  String get setupTemplatesTitle => 'Startsjablonen';

  @override
  String get setupTemplatesHint => 'Startpunt — geen persoonlijk advies.';

  @override
  String get setupApplyTemplate => 'Toepassen';

  @override
  String get setupNewVersionTitle => 'Nieuwe setupversie';

  @override
  String get setupNewVersionHint =>
      'Geef een naam die je herkent — bijv. “Droge trail”.';

  @override
  String get setupVersionNameLabel => 'Naam';

  @override
  String get setupForkReboundLabel => 'Vork-rebound (clicks)';

  @override
  String get setupCancel => 'Annuleren';

  @override
  String get setupSave => 'Opslaan';

  @override
  String setupNewVersionDefaultName(int n) {
    return 'Versie $n';
  }

  @override
  String get setupManualFallback => 'Handmatig';

  @override
  String setupTemplateAppliedLabel(String label) {
    return '$label (sjabloon)';
  }

  @override
  String setupTemplateAppliedSnack(String disclaimer) {
    return 'Sjabloon toegepast — $disclaimer';
  }

  @override
  String get setupCompareVariantA => 'Testvariant A';

  @override
  String get setupCompareVariantB => 'Testvariant B';

  @override
  String setupCompareResultFromRides(int count, String summary) {
    return 'Varianten gemaakt · resultaat uit $count ritten: $summary';
  }

  @override
  String setupCompareResultDemo(String summary) {
    return 'Varianten gemaakt · nog weinig ritfeedback — voorbeeldresultaat: $summary';
  }

  @override
  String get rideMap => 'Kaart';

  @override
  String get rideData => 'Data';

  @override
  String get rideLiveData => 'Livedata';

  @override
  String get rideMapReady => 'Kaart klaar. Sensor is optioneel.';

  @override
  String get rideClearRoute => 'Route verwijderen';

  @override
  String get rideDrawTour => 'Als tour tekenen';

  @override
  String get rideDrawingTour => 'Nieuwe tour · tekent';

  @override
  String get postRideTitle => 'Activiteit';

  @override
  String get postRideFreeride => 'Freeride';

  @override
  String get postRideLiveTour => 'Nieuwe tour';

  @override
  String get postRideToMappe => 'Naar Tours';

  @override
  String get postRideTrackMap => 'Gereden track';

  @override
  String get postRideNoTrack =>
      'Geen GPS-track — de kaart heeft niets te tonen.';

  @override
  String get postRideStatDistance => 'Afstand';

  @override
  String get postRideStatDuration => 'Duur';

  @override
  String get postRideStatPace => 'Tempo';

  @override
  String get postRideStatElevation => 'Hoogte';

  @override
  String get postRideWeatherTitle => 'Weer';

  @override
  String get postRideWeatherStart => 'Start';

  @override
  String get postRideWeatherEnd => 'Einde';

  @override
  String get postRideWeatherUnavailable => 'Weer niet beschikbaar';

  @override
  String get postRidePhotosTitle => 'Foto’s';

  @override
  String get postRidePhotosHint =>
      'Voeg foto’s toe aan deze rit — lokaal opgeslagen.';

  @override
  String get postRidePhotoCamera => 'Camera';

  @override
  String get postRidePhotoGallery => 'Galerij';

  @override
  String get postRidePhotosShare => 'Delen';

  @override
  String get postRidePhotosShareText => 'Mijn FlowLine-rit';

  @override
  String get postRidePhotosEmpty => 'Nog geen foto’s om te delen';

  @override
  String postRidePhotosMax(int count) {
    return 'Maximaal $count foto’s';
  }

  @override
  String get postRideCommunityStub =>
      'Foto’s blijven lokaal. Stimmen hangen aan de tocht — niet in een feed.';

  @override
  String get postRideOpenTour => 'Tocht openen';

  @override
  String get postRideSaveAsTour => 'Opslaan als tocht';

  @override
  String get postRideSaveAsTourDone => 'Opgeslagen onder Tochten';

  @override
  String get postRideSaveAsTourNeedTrack =>
      'Een GPS-track is nodig om op te slaan.';

  @override
  String get postRideSaveAsTourHint =>
      'Slaat de track op als jouw eigen route — zichtbaar onder Tochten.';

  @override
  String get myRoutesTitle => 'Tochten';

  @override
  String get myRoutesEmpty =>
      'Nog geen routes — importeer GPX of neem een rit op.';

  @override
  String get myRoutesSourceImport => 'Import';

  @override
  String get myRoutesSourceRecorded => 'Opgenomen';

  @override
  String get myRoutesSourceEngine => 'Gepland';

  @override
  String get myRoutesShowOnMap => 'Eigen op de kaart';

  @override
  String get myRoutesHideOnMap => 'Eigen verbergen';

  @override
  String get myRouteNotesTitle => 'Privénotitie';

  @override
  String get myRouteNotesHint => 'Alleen voor jou. Tips na delen — onder Tips.';

  @override
  String get myRouteNotesEmpty => 'Nog geen notitie.';

  @override
  String get myRouteNotesPlaceholder => 'Alleen voor jou — geen Stimme.';

  @override
  String get myRouteNotesAdd => 'Opslaan';

  @override
  String get myRouteDetailPhotos => 'Foto’s';

  @override
  String get myRouteOpenDetail => 'Details';

  @override
  String collectionRouteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routes · tik om te openen',
      one: '1 route · tik om te openen',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Verwijderen';

  @override
  String get add => 'Toevoegen';

  @override
  String get skip => 'Overslaan';

  @override
  String get next => 'Volgende';

  @override
  String get onLabel => 'Aan';

  @override
  String get offLabel => 'Uit';

  @override
  String get signIn => 'Inloggen';

  @override
  String get signOut => 'Uitloggen';

  @override
  String get account => 'Account';

  @override
  String get register => 'Registreren';

  @override
  String get edit => 'Bewerken';

  @override
  String get share => 'Delen';

  @override
  String get done => 'Klaar';

  @override
  String get authSignedInSyncing => 'Ingelogd — synchroniseren…';

  @override
  String authSignedInSyncFailed(String error) {
    return 'Ingelogd. Sync: $error';
  }

  @override
  String get authCloudUnavailable => 'Cloudsync is nu niet beschikbaar.';

  @override
  String get authEmailPasswordRequired =>
      'E-mail en wachtwoord (min. 8 tekens) verplicht.';

  @override
  String get authAccountCreatedConfirm =>
      'Account aangemaakt — bevestig e-mail indien nodig, log daarna in.';

  @override
  String get authSupabaseMissing => 'Supabase is niet geconfigureerd.';

  @override
  String get authBrowserOpened =>
      'Browser geopend — je komt hier terug na het inloggen.';

  @override
  String get authDeleteTitle => 'Account verwijderen?';

  @override
  String get authDeleteBody =>
      'Remote-account en lokale appdata worden verwijderd. Exporteer eerst GPX/JSON onder Data & privacy.';

  @override
  String get authRemoteDeleted => 'Remote-account verwijderd.';

  @override
  String get authRemoteUnavailable =>
      'Remote verwijderen niet mogelijk — alleen lokale data weg.';

  @override
  String authRemoteFailed(int code) {
    return 'Remote verwijderen mislukt ($code) — lokale data toch verwijderd.';
  }

  @override
  String get authRemoteUnreachable =>
      'Server onbereikbaar — alleen lokale data weg.';

  @override
  String get authLocalDeleted =>
      'Lokale data verwijderd. Exporteer onder Privacy als je nog een kopie nodig hebt.';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEmailHint => 'E-mailadres';

  @override
  String get authPassword => 'Wachtwoord';

  @override
  String get authCreateAccount => 'Account aanmaken';

  @override
  String get authHaveAccount => 'Al een account? Inloggen';

  @override
  String get authNewHere => 'Nieuw hier? Registreren';

  @override
  String get authWithGoogle => 'Doorgaan met Google';

  @override
  String get authWithApple => 'Doorgaan met Apple';

  @override
  String get authPrivacy => 'Gegevens & privacy';

  @override
  String get authOpenAssistant => 'Assistent openen';

  @override
  String get authDeleteAccount => 'Account verwijderen';

  @override
  String get authSyncNow => 'Nu synchroniseren';

  @override
  String get authSyncing => 'Synchroniseren…';

  @override
  String get authSyncOk => 'Sync OK';

  @override
  String authSyncActive(String api) {
    return 'Sync met $api is actief.';
  }

  @override
  String get authCreating => 'Aanmaken…';

  @override
  String get authSigningIn => 'Inloggen…';

  @override
  String get billingTitle => 'FlowLine Pro';

  @override
  String get billingYouHavePro => 'Je hebt Pro.';

  @override
  String get billingFreeToPro => 'Free → Pro';

  @override
  String get billingMoreBikes =>
      'Meer fietsen, sync-voordelen en offlineregio’s.';

  @override
  String get billingAlreadyPro => 'Pro is al actief — niet opnieuw kopen.';

  @override
  String get billingForceProDebug =>
      'Debug: Force-Pro. Stripe/Play blijven verborgen.';

  @override
  String get billingCommerceClosed =>
      'Ontwikkelstand — geen aankopen. Geen openbaar abonnement.';

  @override
  String get billingStripeMonth => 'Stripe — maandelijks';

  @override
  String get billingStripeYear => 'Stripe — jaarlijks';

  @override
  String get billingPlayMonth => 'Google Play — maandelijks';

  @override
  String get billingPlayRestore => 'Play-aankopen herstellen';

  @override
  String get billingPlayHint =>
      'Let op: zonder GOOGLE_PLAY_SERVICE_ACCOUNT_JSON kan de server aankopen niet tegen Google verifiëren.';

  @override
  String get billingSyncStatus => 'Abonnementsstatus synchroniseren';

  @override
  String get billingSyncAfterPurchase => 'Sync na aankoop';

  @override
  String get billingPleaseSignIn => 'Log eerst in.';

  @override
  String get billingNoCheckoutUrl => 'Geen checkout-URL';

  @override
  String get billingBrowserFailed => 'Browser kon niet worden geopend';

  @override
  String get billingCheckoutOpened =>
      'Checkout geopend — tik daarna op “Sync na aankoop”.';

  @override
  String get billingPlayOnlyAndroid => 'Play Billing is alleen Android.';

  @override
  String get billingPlayStarted => 'Play-aankoop gestart…';

  @override
  String get billingVerifying => 'Aankoop verifiëren…';

  @override
  String get billingProTrusted =>
      'Pro gezet (trusted-token MVP — geen Google Play-serviceaccount). Sync OK.';

  @override
  String get billingProActive => 'Pro actief. Synchroniseren.';

  @override
  String get billingRestoring => 'Aankopen herstellen…';

  @override
  String get billingRestoreStarted =>
      'Herstel gestart — geldige abonnementen worden geverifieerd.';

  @override
  String billingSyncOkTier(String tier) {
    return 'Sync OK — abonnement: $tier';
  }

  @override
  String billingPlayError(String error) {
    return 'Play: $error';
  }

  @override
  String billingSyncError(String error) {
    return 'Sync: $error';
  }

  @override
  String billingRestoreError(String error) {
    return 'Herstel: $error';
  }

  @override
  String get chatAssistant => 'Assistent';

  @override
  String get chatWelcome =>
      'Vraag wat er toe is — of over setup, routes en onderdelen.';

  @override
  String get chatEmptyTitle => 'Vraag me';

  @override
  String get chatEmptyMessage =>
      'Wat er toe is, setup, routes of onderdelen — probeer een suggestie hierboven of typ gewoon.';

  @override
  String get chatLockedRiding => 'Chat is vergrendeld tijdens het rijden.';

  @override
  String get chatHint => 'Bericht…';

  @override
  String get chatHintLocked => 'Vergrendeld tijdens de rit';

  @override
  String get chatAsk => 'Vragen';

  @override
  String get chatSnooze7 => '7 dagen stil';

  @override
  String get chatNoAnswer => 'Geen antwoord.';

  @override
  String get chatUnavailable =>
      'De assistent is nu niet beschikbaar. Probeer later opnieuw.';

  @override
  String chatNetworkError(String error) {
    return 'Netwerkfout: $error';
  }

  @override
  String chatErrorStatus(int code) {
    return 'Fout $code';
  }

  @override
  String get chatLimitReached => 'Limiet bereikt.';

  @override
  String chatQuota(String used, String limit, String remaining) {
    return 'Quota: $used / $limit · $remaining over';
  }

  @override
  String get chatToolDev => 'Tool (ontwikkelaar)';

  @override
  String get chatToolAuto => 'Auto';

  @override
  String get chatPromptWatch => 'Wat is toe?';

  @override
  String get chatPromptWatchQuery => 'Wat is toe?';

  @override
  String get chatPromptGarage => 'Garage';

  @override
  String get chatPromptGarageQuery => 'Wat staat er in mijn garage?';

  @override
  String get chatPromptRange => 'Bereik';

  @override
  String get chatPromptRangeQuery => 'Welk bereik heb ik met de huidige accu?';

  @override
  String get chatPromptSetups => 'Setups';

  @override
  String get chatPromptSetupsQuery =>
      'Welke setups heb ik gebruikt, en wat veranderde?';

  @override
  String get chatPromptRides => 'Ritten';

  @override
  String get chatPromptRidesQuery => 'Samenvatting van mijn recente ritten';

  @override
  String get chatPromptRoutes => 'Routes';

  @override
  String get chatPromptRoutesQuery => 'Welke routes passen bij mij?';

  @override
  String get chatPromptShop => 'Winkel';

  @override
  String get chatPromptShopQuery =>
      'Heb ik binnenkort slijtageonderdelen nodig?';

  @override
  String get chatToolWatch => 'Wat is toe';

  @override
  String get chatToolGarage => 'Werkplaats';

  @override
  String get chatToolCompat => 'Compatibiliteit';

  @override
  String get chatToolRange => 'Bereik';

  @override
  String get chatToolSetupHistory => 'Setupgeschiedenis';

  @override
  String get chatToolRides => 'Ritten';

  @override
  String get chatToolRoutes => 'Routes';

  @override
  String get chatToolShop => 'Winkel';

  @override
  String get chatSubtitleDue => 'Wat is toe, setup, routes, onderdelen';

  @override
  String coachHintsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tips van de assistent',
      one: '1 tip van de assistent',
    );
    return '$_temp0';
  }

  @override
  String get privacyTitle => 'Gegevens & privacy';

  @override
  String get privacyConsents => 'Toestemmingen';

  @override
  String get privacyHud => 'HUD';

  @override
  String get privacyZones => 'Privacyzones';

  @override
  String get privacyZoneAdd => 'Zone';

  @override
  String get privacyNoZones =>
      'Geen zones — omgeving van start/einde kan worden afgeknipt.';

  @override
  String privacyZoneRadius(String label) {
    return '$label straal';
  }

  @override
  String get privacyZoneDelete => 'Zone verwijderen';

  @override
  String get privacyFamilyHint =>
      'Gezin / extra rijders: onder Profiel → Gezinsgarage rijders toevoegen met eigen gewicht.';

  @override
  String get privacyExportTitle => 'Exporteren (art. 20)';

  @override
  String get privacyExportGpx => 'Laatste rit als GPX';

  @override
  String get privacyExportFit => 'Laatste rit als FIT';

  @override
  String get privacyExportJson => 'Volledige JSON-export';

  @override
  String get privacyExportStravaStub => 'Strava-payload (lokaal, ontwikkelaar)';

  @override
  String get privacyStravaConnect => 'Strava verbinden';

  @override
  String get privacyStravaUpload => 'Laatste rit naar Strava';

  @override
  String get privacyStravaLiveHint =>
      'Live-upload gebruikt opgeslagen OAuth-tokens (server).';

  @override
  String get privacyStravaOauthHint =>
      'OAuth opent de browser; ga verder in de app na toegang.';

  @override
  String get privacyStravaMissing =>
      'Strava is niet ingesteld. GPX, FIT en JSON zijn de exportpaden.';

  @override
  String get privacyStravaConnected => 'Strava verbonden';

  @override
  String get privacyStravaCallback => 'Strava-callback ontvangen';

  @override
  String privacyStravaStatus(String status) {
    return 'Strava: $status';
  }

  @override
  String get privacyStravaUnreachable =>
      'Strava-status onbereikbaar — stub-export blijft lokaal';

  @override
  String get privacyStravaUrlMissing =>
      'Strava-authorize-URL ontbreekt — log in en probeer opnieuw.';

  @override
  String get privacyStravaBrowser =>
      'Strava in de browser — keer terug naar de app na toegang; status vernieuwt.';

  @override
  String get privacyNoRideUpload => 'Geen rit om te uploaden';

  @override
  String privacyChunksUploaded(int n, int left) {
    return '$n chunk(s) geüpload, $left in wacht';
  }

  @override
  String privacyChunksBlocked(int left) {
    return 'Geen upload (inloggen/netwerk?) — $left in wacht';
  }

  @override
  String get privacyChunksNone => 'Geen chunks in wacht';

  @override
  String privacyHeatmapCells(int n) {
    return 'Waar velen rijden: $n cellen bijgedragen (zichtbaar vanaf 5).';
  }

  @override
  String get privacyHeatmapNone =>
      'Waar velen rijden: geen bijdrage — log in, stem toe, of de tocht is privé.';

  @override
  String get privacyUploadNow => 'Nu uploaden';

  @override
  String privacyChunksPending(int count) {
    return 'Raw-data-chunks: $count in wacht';
  }

  @override
  String privacyChunksPendingConsentOff(int count) {
    return 'Raw-data-chunks: $count in wacht (toestemming uit)';
  }

  @override
  String privacySharedGpx(String path) {
    return 'GPX gedeeld · $path';
  }

  @override
  String privacySharedFit(String path) {
    return 'FIT gedeeld · $path';
  }

  @override
  String privacySharedStravaStub(String path) {
    return 'Strava-stub gedeeld · $path';
  }

  @override
  String get privacyExportSubject => 'FlowLine-export';

  @override
  String get privacyNoRideExporting => 'Geen rit om te exporteren.';

  @override
  String privacySharedJson(String path) {
    return 'JSON gedeeld · $path';
  }

  @override
  String get privacyNoRideExport => 'Geen rit om te exporteren.';

  @override
  String get consentRawTitle => 'Raw-data-upload';

  @override
  String get consentRawBody =>
      'Sensor-raw-data alleen via wifi en als je toestemt. Altijd intrekbaar.';

  @override
  String get consentHeatmapTitle => 'Waar velen rijden (anoniem, vanaf 5)';

  @override
  String get consentHeatmapBody =>
      'Lokaal: jouw ritten. Met account: geanonimiseerde cellen zonder tijdstempels. De kaart verschijnt als 5 rijders in een cel zijn geweest.';

  @override
  String get consentRecoTitle => 'Productaanbevelingen';

  @override
  String get consentRecoBody =>
      'Alleen als het relevant is, met een navolgbaar datapunt. Geen tracking-marketing.';

  @override
  String get consentAnalyticsTitle => 'Analytics';

  @override
  String get consentAnalyticsBody =>
      'Productmetrics zonder gezondheid of raw-sensordata.';

  @override
  String get consentHealthTitle => 'Gezondheidsdata';

  @override
  String get consentHealthBody =>
      'Voorbereiding — Health Connect is nog niet gekoppeld. Deze toestemming slaat alleen je voorkeur op voor later.';

  @override
  String get privacyZoneTapHint => 'Tik op de kaart om de zone te plaatsen.';

  @override
  String get privacyZoneRadiusHint =>
      'Straal geldt voor export en waar velen rijden.';

  @override
  String get privacyZoneLabel => 'Label';

  @override
  String get privacyZoneRadiusWord => 'Straal';

  @override
  String get privacyZoneApplyCoords => 'Coördinaten toepassen';

  @override
  String get privacyZoneCoords => 'Coördinaten';

  @override
  String get privacyZoneCoordsHint =>
      'Alleen als je het punt met cijfers wilt zetten';

  @override
  String get profilePictureSet => 'Profielfoto gezet';

  @override
  String get profileSaved => 'Profiel opgeslagen';

  @override
  String get profileLocalOnly => 'Alleen lokaal — log in om te synchroniseren';

  @override
  String get profileSyncCloudKept => 'Sync: cloud behouden';

  @override
  String get profileSyncDeviceUploaded => 'Sync: apparaat geüpload';

  @override
  String get profileSyncCurrent => 'Sync: up-to-date';

  @override
  String get profileSyncConflictTitle => 'Syncconflict';

  @override
  String profileSyncConflictBody(String when) {
    return 'Cloud en dit apparaat verschillen.\nCloud: $when\n\nWelke versie moet gelden?';
  }

  @override
  String get profileKeepCloud => 'Cloud behouden';

  @override
  String get profileForceDevice => 'Apparaat forceren';

  @override
  String get profileConflictCloud => 'Conflict: cloud behouden';

  @override
  String get profileConflictDevice => 'Conflict: apparaat geforceerd';

  @override
  String get profileSyncCancelled => 'Sync geannuleerd';

  @override
  String get profileSignInForBilling => 'Log in om het abonnement te beheren';

  @override
  String get profileNoStripeSub =>
      'Nog geen Stripe-abonnement — upgrade eerst naar Pro.';

  @override
  String profilePortalError(int code) {
    return 'Portal: $code';
  }

  @override
  String get profileNoPortalUrl => 'Geen portal-URL';

  @override
  String get profileFamilyRiderTitle => 'Gezinsrijder';

  @override
  String get profileName => 'Naam';

  @override
  String get profileWeightKg => 'Gewicht kg';

  @override
  String get profileRiderAdded => 'Rijder toegevoegd';

  @override
  String get profileRiderFallback => 'Rijder';

  @override
  String profileActiveBike(String name, String category) {
    return 'Actief: $name · $category';
  }

  @override
  String get profileDisciplines => 'Jouw disciplines';

  @override
  String get profileDisciplinesHint =>
      'Voorkeuren voor tochten. Routing volgt de actieve fiets, niet alleen deze lijst.';

  @override
  String get profileRiderCard => 'Rijdersprofiel';

  @override
  String get profileNameUnset => 'Nog geen naam';

  @override
  String get profilePublic => 'Openbaar';

  @override
  String get profileAccountSync => 'Account & sync';

  @override
  String get profileConnections => 'Verbindungen';

  @override
  String get profileWatchTitle => 'Uhr / Puls';

  @override
  String get profileWatchIdle => 'Keine Uhr gekoppelt — Garmin, Polar, Wahoo.';

  @override
  String get profileBikeBleTitle => 'Rad / Bosch LDI';

  @override
  String get profileBikeBleIdle => 'Display, Motor oder CSC am aktiven Rad.';

  @override
  String get profileBikeBleNeedBike =>
      'Zuerst ein Rad in die Werkstatt stellen.';

  @override
  String get profileCloudBilling => 'Cloudsync & facturatie';

  @override
  String get profileSignedIn => 'Ingelogd';

  @override
  String get profileFamilyGarage => 'Gezinsgarage';

  @override
  String get profileFamilyHint =>
      'Meer rijders met eigen gewicht — bijv. partner of kind.';

  @override
  String get profileLegal => 'Juridisch';

  @override
  String get profilePrivacyPolicy => 'Privacybeleid';

  @override
  String get profileImprint => 'Colofon';

  @override
  String get profileWithdrawal => 'Herroeping';

  @override
  String get profileSetPrimary => 'Als hoofddiscipline zetten';

  @override
  String profilePrimarySuffix(String label) {
    return '$label · primair';
  }

  @override
  String get profileNeedOneDiscipline =>
      'Houd minstens één discipline geselecteerd.';

  @override
  String get profileLocalUntilSignIn => 'Lokaal — sync na inloggen';

  @override
  String get profileChangePhoto => 'Foto wijzigen';

  @override
  String get profileActivityLabel => 'Activiteit — recente ritten op Start';

  @override
  String get profileBikeOne => 'Fiets';

  @override
  String get profileBikes => 'Fietsen';

  @override
  String get profileRideOne => 'Rit';

  @override
  String get profileRides => 'Ritten';

  @override
  String get profileKmTotal => 'km totaal';

  @override
  String profileKmElevation(int hm) {
    return 'km · $hm hm';
  }

  @override
  String get profileProActive => 'FlowLine Pro actief';

  @override
  String get profileManage => 'Beheren';

  @override
  String get profileProPerks =>
      'Offlinekaarten, onbeperkt fietsen, veringsanalyse & bracketing.';

  @override
  String get profileUpgradePro => 'Upgraden naar Pro';

  @override
  String get profileDisplayName => 'Weergavenaam';

  @override
  String get profileRiderWeight => 'Rijdersgewicht (kg)';

  @override
  String get profileRideStyle => 'Rijstijl';

  @override
  String get profileSkillBeginner => 'Beginner';

  @override
  String get profileSkillBasics => 'Basis';

  @override
  String get profileSkillAdvanced => 'Gevorderd';

  @override
  String get profileSkillExperienced => 'Ervaren';

  @override
  String get profileSkillPro => 'Pro';

  @override
  String get profileSubGarage => 'Garage';

  @override
  String get profileSubWeight => 'Rijdersgewicht';

  @override
  String profileSubSkill(int skill) {
    return 'Niveau ($skill / 5)';
  }

  @override
  String get profileStyleEfficientPace => 'Efficiënt / tempo';

  @override
  String get profileStyleSteady => 'Gelijkmatig';

  @override
  String get profileStyleExploring => 'Ontdekken';

  @override
  String get profileStyleCommute => 'Alledag / woon-werk';

  @override
  String get profileStyleTours => 'Tochten';

  @override
  String get profileStyleRelaxed => 'Relaxed';

  @override
  String get profileStyleAggressive => 'Agressief';

  @override
  String get profileStyleFlow => 'Flow';

  @override
  String get profileStyleLines => 'Lijnen jagen';

  @override
  String get profileStyleEfficient => 'Efficiënt';

  @override
  String profileDisciplinesSaved(String list) {
    return 'Disciplines: $list';
  }

  @override
  String profileAlsoList(String list) {
    return 'ook $list';
  }

  @override
  String get publicProfileTitle => 'Openbaar profiel';

  @override
  String get publicProfileHint =>
      'Opt-in. Handle bij Stimmen, geen tracks, geen tab.';

  @override
  String get publicProfileHandle => 'Handle';

  @override
  String get publicProfileBio => 'Bio';

  @override
  String get publicProfileRegion => 'Regio';

  @override
  String get publicProfileShowRides => 'Rittaantal tonen';

  @override
  String get publicProfileFoot =>
      'Geen openbare track, geen DM’s. Handle blijft lokaal tot sync.';

  @override
  String get hudMediaTitle => 'Media in de HUD';

  @override
  String get hudMediaProfileHint =>
      'Optionele toegang zodat de HUD de huidige titel kan tonen. Play/Pause werkt vaak zonder.';

  @override
  String get hudMediaPrivacyHint =>
      'Instelling staat onder Profiel. Optionele media-session-toegang voor de HUD-titel.';

  @override
  String get onboardHowYouRide => 'Hoe rij je?';

  @override
  String get onboardYourWeight => 'Jouw gewicht';

  @override
  String get onboardFirstRide => 'Eerste rit';

  @override
  String get onboardWeightHint =>
      'Voor setup en bereik — alleen lokaal, altijd wijzigbaar.';

  @override
  String get onboardGpsHint =>
      'Echte GPS-track — geen demo. Fiets optioneel. MTB, gravel, race of stad: even welkom.';

  @override
  String get onboardGpsStatus => 'Locatie voor GPS-track…';

  @override
  String get onboardServicesOff =>
      'Zet locatieservices aan, probeer daarna opnieuw.';

  @override
  String get onboardDeniedForever => 'Sta locatie toe in de app-instellingen.';

  @override
  String get onboardNeedGps => 'Sta locatie toe — geen GPS, geen track.';

  @override
  String onboardWeightLabel(int kg) {
    return 'Rijdersgewicht: $kg kg';
  }

  @override
  String onboardDiscipline(String label) {
    return 'Discipline: $label';
  }

  @override
  String get onboardSensorsHint =>
      'Locatie voor de GPS-track. Bluetooth-sensoren later onder Fiets — voor elk fietstype.';

  @override
  String get onboardNextRide => 'Door naar de rit';

  @override
  String get onboardParkBikeFirst => 'Zet eerst een fiets neer';

  @override
  String get onboardLater => 'Later instellen';

  @override
  String get offlineMapsTitle => 'Offlinekaarten';

  @override
  String get offlineMapsHint =>
      'Downloadt routing en kaarttegels voor de regio. Offline: geladen kaart en routing in het gebied.';

  @override
  String get offlineRegionActive => 'Regio actief';

  @override
  String get offlineNoRegion => 'Geen regio actief';

  @override
  String get offlineReadyBoth => 'Routing + kaarttegels klaar.';

  @override
  String get offlineReadyRouting => 'Routing klaar — kaart nog niet offline.';

  @override
  String get offlineLoadBelow => 'Laad hieronder een gebouwd pack.';

  @override
  String get offlineRegions => 'Regio’s';

  @override
  String get offlineSearchRegion => 'Regio zoeken';

  @override
  String get offlineNoneFound => 'Geen regio gevonden';

  @override
  String get offlineNoPacks =>
      'Nu geen packs om te laden. Regio’s die nog niet klaar zijn staan hieronder.';

  @override
  String offlineNotBuilt(int count) {
    return 'Nog niet klaar ($count)';
  }

  @override
  String get offlineStubsHint => 'Nog niet te downloaden.';

  @override
  String get offlineRemoveRegion => 'Regio verwijderen';

  @override
  String get offlineStyleTitle => 'Kaartstijl (optioneel)';

  @override
  String get offlineStyleHint =>
      'Standaard: DACH z11-stijl-JSON. Alleen wijzigen voor je eigen MapLibre-stijl.';

  @override
  String get offlineStyleUrl => 'Stijl-JSON-URL';

  @override
  String get offlineSaveStyle => 'Stijl opslaan';

  @override
  String offlineRegionActiveSnack(String name) {
    return '$name actief';
  }

  @override
  String offlineActivateError(String error) {
    return 'Activeren: $error';
  }

  @override
  String offlinePackError(String error) {
    return 'Regiopack: $error';
  }

  @override
  String get offlineRemoved => 'Regio verwijderd';

  @override
  String get offlineNoRemoteDach => 'Geen remote packs — DACH-fallback actief';

  @override
  String get offlineNoBuiltPacks => 'Geen gebouwde packs op deze server';

  @override
  String get offlineDachCatalog => 'Offline — DACH-regio’s uit de appcatalogus';

  @override
  String get offlineReadyMapRouting => 'Kaart + routing klaar';

  @override
  String get offlineRoutingBg => 'Routing klaar, kaart laadt op de achtergrond';

  @override
  String get offlineBasemapFail =>
      'Routing klaar — basemap-download mislukt, kaart heeft de CDN nodig';

  @override
  String get offlineTilesMissing =>
      'Routing klaar, kaarttegels ontbreken (netwerk/limiet)';

  @override
  String offlineDemoGraph(String name) {
    return 'Zwarte Woud-demograaf actief — niet de $name-kaart';
  }

  @override
  String get offlineStyleCleared => 'Override gewist — standaardstijl actief';

  @override
  String offlineStyleSaved(String url) {
    return 'Stijl opgeslagen. Kaart herlaadt: $url';
  }

  @override
  String get platzTogetherKicker => 'Groep';

  @override
  String get platzTogetherTitle => 'Samen rijden';

  @override
  String get platzTogetherHint =>
      'Uitnodigen deelt de link. Jouw groepen blijven — geen feed.';

  @override
  String get platzTogetherListHint =>
      'Groep. Ingelogd: op de server. Anders alleen dit apparaat — de host ziet je niet. Vrienden op de kaart alleen tijdens het rijden, na opt-in.';

  @override
  String get platzCreateGroup => 'Groep maken';

  @override
  String get platzJoinCode => 'Code';

  @override
  String get platzNoGroup => 'Nog geen groep. Een link volstaat.';

  @override
  String get platzHost => 'Host';

  @override
  String get platzGuest => 'Gast';

  @override
  String get platzYou => 'Jij';

  @override
  String get platzInvite => 'Uitnodigen';

  @override
  String get platzDissolve => 'Opheffen';

  @override
  String get platzLeave => 'Verlaten';

  @override
  String get platzCopyLink => 'Link kopiëren';

  @override
  String get platzInviteShares => 'Uitnodigen deelt de groeplink';

  @override
  String get platzInviteSharesProfile => ' en jouw profiel';

  @override
  String get platzInviteAsYou =>
      'Op de uitnodiging sta je als Jij. Naam zetten in het profiel?';

  @override
  String get platzInviteAsYouLater => 'Later';

  @override
  String get platzInviteOpenProfile => 'Naar profiel';

  @override
  String platzMembersCount(int count) {
    return '$count mee';
  }

  @override
  String get platzOnServer => 'op de server';

  @override
  String get platzOnDevice => 'alleen dit apparaat';

  @override
  String platzCollectionDefaultName(int day, int month) {
    return 'Collectie $day.$month.';
  }

  @override
  String get platzPinsOff => 'Vrienden op de kaart · uit';

  @override
  String get platzPinsHudOnly => 'Vrienden alleen tijdens het rijden';

  @override
  String get platzCollectionsKicker => 'Collecties';

  @override
  String get platzNoCollection =>
      'Nog geen collectie — maak er een onder Delen bij een tocht.';

  @override
  String platzCollectionTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tochten',
      one: '1 tocht',
    );
    return '$_temp0';
  }

  @override
  String get platzCreateCollection => 'Collectie maken';

  @override
  String get platzJoinWithCode => 'Meedoen met een link';

  @override
  String get platzJoinCodeField => 'Uitnodigingslink';

  @override
  String get platzJoinLinkHint =>
      'Plak de link uit WhatsApp of Berichten. Privégroepen hebben de uitnodigingslink nodig — geen code om in te typen.';

  @override
  String get platzJoinEmpty => 'Link ontbreekt.';

  @override
  String get platzJoinInvalid => 'Geen geldige uitnodigingslink.';

  @override
  String get platzJoin => 'Meedoen';

  @override
  String get platzStartLabel => 'Start';

  @override
  String get platzStartNow => 'Nu';

  @override
  String get platzStartIn1h => 'Over 1 u';

  @override
  String get platzStartToday18 => 'Vandaag 18:00';

  @override
  String get platzStartTomorrow10 => 'Morgen 10:00';

  @override
  String get platzDurationLabel => 'Duur';

  @override
  String get platzMeetingPlaceholder => 'Verzamelpunt (optioneel)';

  @override
  String get platzMeetingHint => 'bijv. parkeerplaats bij het zwembad';

  @override
  String get platzPinsOnHud => 'Vrienden op de kaart · aan';

  @override
  String get platzPinsHint =>
      'Alleen tijdens het rijden, niet op de openbare kaart.';

  @override
  String get platzTourNotInMappe => 'Tocht staat niet onder Tochten.';

  @override
  String get platzTourNotInMappeHint =>
      'Rijden maar zet catalogustochten onder Tochten. Privé-GPX heeft de link van de host nodig — geen verzonnen track.';

  @override
  String get platzCollectionsHint =>
      'Maken onder Delen. Delen omvat alleen vrijgegeven of catalogustochten — privé-GPX blijft erbuiten.';

  @override
  String get akteTourKicker => 'Tocht';

  @override
  String get stimmenShareNeedRelease =>
      'Tik eerst op Delen — anders gaat de link nergens heen.';

  @override
  String get platzNeedSharedTour =>
      'Groepen alleen op een gedeelde of catalogustocht. Privé-GPX blijft privé.';

  @override
  String get platzShareTourFirst => 'Deel eerst een tocht';

  @override
  String get platzShareTourFirstHint =>
      'Zonder delen zien vrienden de groep niet. Tik op een tocht, dan Delen, dan de groep maken.';

  @override
  String get platzHostCannotSee =>
      'Alleen dit apparaat. De host ziet je niet — log in.';

  @override
  String platzJoinLocal(String title) {
    return 'Alleen dit apparaat: $title. De host ziet je niet — log in.';
  }

  @override
  String get platzJoinLocalCta => 'Opslaan op dit apparaat';

  @override
  String get platzJoinUnsignedHint => 'Zonder inloggen ziet de host je niet.';

  @override
  String get platzNoSharedTours =>
      'Geen gedeelde of catalogustochten. Privé-GPX blijft erbuiten.';

  @override
  String platzGroupCreated(String code) {
    return 'Groep $code — uitnodigen deelt de link.';
  }

  @override
  String platzGroupCreatedNote(String code, String note) {
    return 'Groep $code — $note';
  }

  @override
  String platzShareSubject(String title) {
    return 'Samen rijden: $title';
  }

  @override
  String get platzLinkCopied =>
      'Link gekopieerd. Wie hem heeft, kan meedoen zolang de groep open is.';

  @override
  String get platzWindowClosed => 'Venster dicht';

  @override
  String platzWindowHours(int hours) {
    return 'Venster $hours u';
  }

  @override
  String platzWindowMinutes(int minutes) {
    return 'Venster $minutes min';
  }

  @override
  String get platzWindowOpen => 'Venster open';

  @override
  String platzCollectionShare(String name, String routes) {
    return 'Collectie “$name”: $routes';
  }

  @override
  String get rerouteTitle => 'Van de route.';

  @override
  String get rerouteHint => 'Blijf kalm — jij beslist.';

  @override
  String get rerouteRejoin => 'Terug naar de route';

  @override
  String get rerouteStay => 'Blijven';

  @override
  String get rerouteSkip => 'Dit stuk overslaan';

  @override
  String get bleOff => 'Bluetooth is uit — zet het aan.';

  @override
  String get bleDenied => 'Bluetooth-toestemming ontbreekt.';

  @override
  String get bleUnavailable =>
      'Bluetooth LE is niet beschikbaar op dit apparaat.';

  @override
  String get bleScanFailed => 'Scan mislukt';

  @override
  String get bleConnecting => 'Verbinden…';

  @override
  String get blePairFailed => 'Koppelen mislukt';

  @override
  String get bleNothingFound => 'Niets gevonden';

  @override
  String get bleScanAgain => 'Opnieuw scannen';

  @override
  String get bleHowTo => 'Zo koppelen';

  @override
  String get watchPairTitle => 'Horloge koppelen';

  @override
  String get watchPairHint =>
      'Hartslag alleen met een echte sensor. Horloge-accu is niet de fietsaccu.';

  @override
  String get watchScanning => 'Horloge en HR-band zoeken…';

  @override
  String get watchEmptyHint =>
      'Broadcast aan, telefoon dichtbij. Apple Watch stuurt geen standaard-HR.';

  @override
  String get watchNoHr =>
      'Geen hartslagsignaal — check broadcast op het horloge.';

  @override
  String get watchNoDeviceId => 'Verbonden, maar geen apparaat-ID';

  @override
  String get bleBikeTitle => 'Fiets koppelen';

  @override
  String get bleBikeHint =>
      'Accu en ondersteuning alleen met echte GATT — niets verzonnen.';

  @override
  String get bleRememberAnyway => 'Toch onthouden';

  @override
  String get bleScanningDrive => 'Aandrijving en sensoren zoeken…';

  @override
  String get bleEmptyEbike =>
      'Display wekken, Flow of E-TUBE sluiten, telefoon dichtbij houden.';

  @override
  String get bleEmptySensor =>
      'Zet de sensor in de buurt en activeer hem op de fiets (magneet/crank).';

  @override
  String get bleConnectFailed => 'Verbinding mislukt';

  @override
  String get dieBoxReady => 'Klaar';

  @override
  String get dieBoxAlmost => 'Bijna klaar';

  @override
  String get dieBoxUnknown => 'Net aangekomen';

  @override
  String get dieBoxNothingDueMonday =>
      'Maandag-klaar — lichten en ketting staan.';

  @override
  String get dieBoxNothingDue => 'Klaar — niets in de wacht.';

  @override
  String get dieBoxCscHint =>
      'Koppel hier de fietssensor. Het horloge blijft bij jou als je rijdt.';

  @override
  String get dieBoxEmptyHint =>
      'Nog niets vastgelegd. Naam en type volstaan — onderdelen alleen als ze echt op de fiets zitten.';

  @override
  String get dieBoxAddSomething => 'Iets vastleggen';

  @override
  String get dieBoxAddMore => 'Meer vastleggen';

  @override
  String get dieBoxBatteryHint =>
      'Lading verschijnt zodra een sensor op de fiets koppelt. Tot dan geen getal.';

  @override
  String get dieBoxPressureTitle => 'Spanning vastleggen';

  @override
  String get dieBoxPressureHint => 'Lees voor en achter bij het ventiel.';

  @override
  String get dieBoxPressureFront => 'Voor';

  @override
  String get dieBoxPressureRear => 'Achter';

  @override
  String get dieBoxPressureLogged => 'Spanning vastgelegd';

  @override
  String get dieBoxSagTitle => 'Vering vastleggen';

  @override
  String get dieBoxSagHint =>
      'Procent op vork en demper. SAG is hoe ver de vering inzakt met jou erop.';

  @override
  String get dieBoxSagFork => 'Vork-SAG %';

  @override
  String get dieBoxSagShock => 'Demper-SAG %';

  @override
  String get dieBoxSagLogged => 'SAG vastgelegd';

  @override
  String get dieBoxTravelTitle => 'Veerweg vastleggen';

  @override
  String get dieBoxTravelHint => 'Alleen de veerweg die op de fiets zit.';

  @override
  String get dieBoxTravelFront => 'Voor mm';

  @override
  String get dieBoxTravelRear => 'Achter mm';

  @override
  String get dieBoxTravelSave => 'Vastleggen';

  @override
  String get dieBoxChainLogged => 'Ketting gemeten';

  @override
  String get dieBoxChainNotes => 'Gemeten met een meter';

  @override
  String get dieBoxSetActiveTitle => 'Deze fiets naar voren';

  @override
  String get dieBoxSetActiveHint =>
      'Eén fiets staat in de stalling — wisselen haalt hem naar voren.';

  @override
  String get dieBoxSetActiveCta => 'Als actief zetten';

  @override
  String get dieBoxLightsTitle => 'Lichten vastleggen';

  @override
  String get dieBoxLightsHint =>
      'Alleen als er echt lichten op de fiets zitten.';

  @override
  String get dieBoxLightsCta => 'Lichten vastleggen';

  @override
  String get dieBoxLockTitle => 'Slot vastleggen';

  @override
  String get dieBoxLockHint => 'Alleen als er een slot op de fiets zit.';

  @override
  String get dieBoxLockCta => 'Slot vastleggen';

  @override
  String get dieBoxRackTitle => 'Rek vastleggen';

  @override
  String get dieBoxRackHint => 'Alleen als de fiets een rek heeft.';

  @override
  String get dieBoxRackCta => 'Rek vastleggen';

  @override
  String get dieBoxBagsTitle => 'Tassen vastleggen';

  @override
  String get dieBoxBagsHint => 'Alleen als er tassen op de fiets zitten.';

  @override
  String get dieBoxBagsCta => 'Tassen vastleggen';

  @override
  String get dieBoxPressureMissingTitle => 'Spanning vastleggen';

  @override
  String get dieBoxPressureMissingHint =>
      'Lees voor en achter bij het ventiel.';

  @override
  String get dieBoxPressureMissingCta => 'Spanning vastleggen';

  @override
  String get dieBoxTirePressureTitle => 'Bandenspanning vastleggen';

  @override
  String get dieBoxTirePressureHint => 'Lees voor en achter bij het ventiel.';

  @override
  String get dieBoxTravelMissingTitle => 'Veerweg vastleggen';

  @override
  String get dieBoxTravelMissingHint =>
      'Alleen de veerweg die op de fiets zit.';

  @override
  String get dieBoxTravelMissingCta => 'Veerweg vastleggen';

  @override
  String get dieBoxSagMissingTitle => 'Vering vastleggen';

  @override
  String get dieBoxSagMissingHint =>
      'Eén getal op vork en demper, afgelezen op de fiets.';

  @override
  String get dieBoxSagMissingCta => 'Vering vastleggen';

  @override
  String get dieBoxChainTitle => 'De ketting vastleggen';

  @override
  String get dieBoxChainHint => 'Meet met een meter, leg het hier vast.';

  @override
  String get dieBoxChainCta => 'Ketting gemeten';

  @override
  String get dieBoxBrakesTitle => 'Remmen vastleggen';

  @override
  String get dieBoxBrakesHint => 'Alleen als er blokken op de fiets zitten.';

  @override
  String get dieBoxBrakesCta => 'Rem vastleggen';

  @override
  String get dieBoxChainDueTitle => 'Ketting checken met een meter';

  @override
  String get dieBoxChainDueHint => 'Kijk, meet daarna met een meter.';

  @override
  String get dieBoxParkTrailTitle => 'Park of trail';

  @override
  String get dieBoxParkTrailHint =>
      'Beide setups staan hier — wissel als je wilt.';

  @override
  String get dieBoxParkTrailCta => 'Wisselen';

  @override
  String get dieBoxChipLight => 'Lichten';

  @override
  String get dieBoxChipLock => 'Slot';

  @override
  String get dieBoxChipRack => 'Rek';

  @override
  String get dieBoxChipBags => 'Tassen';

  @override
  String get dieBoxChipTires => 'Banden';

  @override
  String get dieBoxChipDropper => 'Dropper';

  @override
  String get dieBoxChipBrakes => 'Remmen';

  @override
  String get dieBoxChipParkTrail => 'Park | Trail';

  @override
  String get dieBoxChipTravel => 'Veerweg';

  @override
  String get dieBoxChipCsc => 'CSC';

  @override
  String get dieBoxChipBatteryHonest => 'Eerlijke accu';

  @override
  String get dieBoxChipSag => 'SAG';

  @override
  String get dieBoxChipChain => 'Ketting';

  @override
  String get dieBoxChipPressure => 'Spanning';

  @override
  String get dieBoxChipCockpit => 'Cockpit';

  @override
  String lastRideKm(String km) {
    return 'Laatste $km km';
  }

  @override
  String get lastRideNoGps => 'Laatst weg — geen GPS-track';

  @override
  String dieBoxSentenceEverydayReady(String name) {
    return '$name woont hier · maandag-klaar';
  }

  @override
  String get dieBoxBitLightsChainOk => 'Lichten en ketting oké';

  @override
  String get dieBoxBitPressureUnknown => 'Spanning niet gemeten';

  @override
  String get dieBoxBitLightsMissing => 'Lichten niet vastgelegd';

  @override
  String dieBoxSentenceNotReady(String name) {
    return '$name woont hier';
  }

  @override
  String dieBoxSentenceBits(String name, String bits) {
    return '$name · $bits';
  }

  @override
  String get dieBoxWheelOpen => 'Wiel open';

  @override
  String get dieBoxBitPressureLogged => 'Spanning vastgelegd';

  @override
  String get dieBoxBitPressureRough => 'Spanning grof — opnieuw meten';

  @override
  String get dieBoxBitBagsYes => 'Tassen erop';

  @override
  String get dieBoxBitBagsNo => 'Tassen niet vastgelegd';

  @override
  String get dieBoxBitChainYes => 'Ketting gemeten';

  @override
  String get dieBoxBitChainNo => 'Ketting nog niet gemeten';

  @override
  String get dieBoxBitPressureToday => 'Spanning vandaag nog open';

  @override
  String get dieBoxSentencePark => 'Park-setup';

  @override
  String get dieBoxSagLoggedShort => 'SAG vastgelegd';

  @override
  String get dieBoxSagMissingShort => 'SAG niet gemeten';

  @override
  String dieBoxSentenceNoTravel(String name) {
    return '$name woont hier';
  }

  @override
  String get dieBoxDriveAssist => ' · e-ondersteuning';

  @override
  String dieBoxSentenceMtb(String name, String travel, String drive) {
    return '$name · $travel$drive';
  }

  @override
  String dieBoxSentenceFallback(String name) {
    return '$name woont hier';
  }

  @override
  String get close => 'Sluiten';

  @override
  String get ok => 'OK';

  @override
  String get remove => 'Verwijderen';

  @override
  String get garageMoreOnBike => 'Meer op de fiets';

  @override
  String get garageMoreOnBikeHint =>
      'Onderdelen, onderhoud, setupversies — achter Die Box';

  @override
  String get garageDeleteBike => 'Fiets verwijderen';

  @override
  String get garageDeleteBikeTitle => 'Deze fiets verwijderen?';

  @override
  String get garageDeleteBikeBody =>
      'Componenten en setups van deze fiets gaan lokaal weg.';

  @override
  String get garageRemovePartTitle => 'Dit onderdeel verwijderen?';

  @override
  String garageRemovePartBody(String slot, String name) {
    return '$slot: $name wordt uit de garage gehaald.';
  }

  @override
  String get garageNotLogged => 'Niet vastgelegd';

  @override
  String get garageOptions => 'Opties';

  @override
  String get garageFitTitle => 'Passing';

  @override
  String garageFitStatus(String label) {
    return 'Status: $label';
  }

  @override
  String garageFitSeverity(String label) {
    return 'Ernst: $label';
  }

  @override
  String get garageFitSeveritySafety => 'veiligheidskritisch';

  @override
  String get garageFitSeverityFunctional => 'functioneel';

  @override
  String get garageFitExplained => 'In gewone woorden';

  @override
  String garageFitCondition(String text) {
    return 'Conditie: $text';
  }

  @override
  String garageFitHint(String text) {
    return 'Opmerking: $text';
  }

  @override
  String get garageFitMissing => 'Nog ontbrekend';

  @override
  String garageFitSource(String url) {
    return 'Bron: $url';
  }

  @override
  String garageGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String get garageVerdictFits => 'Past';

  @override
  String get garageVerdictCheck => 'Controleer';

  @override
  String get garageVerdictNoFit => 'Past niet';

  @override
  String get garageVerdictUnclear => 'Onzeker';

  @override
  String garageAllCount(int count) {
    return 'alle $count';
  }

  @override
  String get garageActiveStamp => 'ACTIEF';

  @override
  String get garageFreeOneBikeTitle => 'Free: één fiets';

  @override
  String get garageFreeOneBikeBody =>
      'Free omvat één fiets. Je kunt lokaal nog meer toevoegen — synclimieten gelden na inloggen.';

  @override
  String get garageUnlockPro => 'Pro ontgrendelen';

  @override
  String get garageAddAnyway => 'Toch toevoegen';

  @override
  String get garageSlotFrame => 'Frame';

  @override
  String get garageSlotFork => 'Vork';

  @override
  String get garageSlotRearShock => 'Demper';

  @override
  String get garageSlotHeadset => 'Balhoofd';

  @override
  String get garageSlotStem => 'Stuurpen';

  @override
  String get garageSlotHandlebar => 'Stuur';

  @override
  String get garageSlotGrips => 'Grips';

  @override
  String get garageSlotSeatpost => 'Zadelpen';

  @override
  String get garageSlotSaddle => 'Zadel';

  @override
  String get garageSlotFrontHub => 'Voornaaf';

  @override
  String get garageSlotRearHub => 'Achternaaf';

  @override
  String get garageSlotFrontRim => 'Voorvelg';

  @override
  String get garageSlotRearRim => 'Achtervelg';

  @override
  String get garageSlotTireFront => 'Voorband';

  @override
  String get garageSlotTireRear => 'Achterband';

  @override
  String get garageSlotCassette => 'Cassette';

  @override
  String get garageSlotChain => 'Ketting';

  @override
  String get garageSlotCrankset => 'Crankstel';

  @override
  String get garageSlotBottomBracket => 'Trapas';

  @override
  String get garageSlotFrontDerailleur => 'Voorderailleur';

  @override
  String get garageSlotRearDerailleur => 'Achterderailleur';

  @override
  String get garageSlotShifter => 'Shifter';

  @override
  String get garageSlotBrakeFront => 'Voorrem';

  @override
  String get garageSlotBrakeRear => 'Achterrem';

  @override
  String get garageSlotRotorFront => 'Voorremschijf';

  @override
  String get garageSlotRotorRear => 'Achterremschijf';

  @override
  String get garageSlotMotor => 'Motor';

  @override
  String get garageSlotBattery => 'Accu';

  @override
  String get garageSlotDisplay => 'Display';

  @override
  String get garageSlotLight => 'Lichten';

  @override
  String get garageSlotLock => 'Slot';

  @override
  String get garageSlotRack => 'Rek';

  @override
  String get garageSlotBags => 'Tassen';

  @override
  String get garageSlotOther => 'Overig';

  @override
  String get garageGroupSuspension => 'Vering';

  @override
  String get garageGroupWheels => 'Wielen';

  @override
  String get garageGroupCockpit => 'Cockpit';

  @override
  String get garageGroupDrivetrain => 'Aandrijving';

  @override
  String get garageGroupBrakes => 'Remmen';

  @override
  String get garageGroupPower => 'E-bike';

  @override
  String get garageGroupOther => 'Overig';

  @override
  String get dieBoxZoneToday => 'Vandaag';

  @override
  String get dieBoxZoneOnBike => 'Op de fiets';

  @override
  String get dieBoxZoneSensor => 'Sensor';

  @override
  String get garageCatalogOffline =>
      'Catalogus offline — je kunt nog een fiets toevoegen onder “Mijn fiets” of “GPX”.';

  @override
  String get garageNoHit =>
      'Geen treffer — gebruik de lijst of probeer een andere zoekopdracht.';

  @override
  String get garageSearchUnavailable => 'Zoeken is nu down — gebruik de lijst.';

  @override
  String get garageFileUnreadable => 'Dat bestand kon niet worden gelezen';

  @override
  String get garageGpxInvalid =>
      'Geen geldige GPX-track (minstens 2 punten nodig)';

  @override
  String get garageNeedMakeModel => 'Kies merk en model';

  @override
  String garageCreateFailed(String error) {
    return 'Fiets kon niet worden toegevoegd: $error';
  }

  @override
  String get garageOemSetup => 'Voorraadsetup';

  @override
  String get garageCatalogIdentity => 'Catalogusidentiteit';

  @override
  String get garageImportBike => 'Fiets importeren';

  @override
  String get garageImportNoGpx =>
      'Importeren zonder GPX — onderdelen later toevoegen';

  @override
  String get garageBaseSetup => 'Basissetup';

  @override
  String get garageFreeExtraLocal =>
      'Free: extra fiets lokaal opgeslagen (meerdere fietsen is Pro).';

  @override
  String garageOemTakeover(int count) {
    return 'Voorraadonderdelen overnemen ($count)';
  }

  @override
  String get garageOemHint =>
      'Anders alleen identiteit. Catalogus blijft zoeken.';

  @override
  String garageReachStack(String reach, String stack) {
    return 'Reach $reach mm · Stack $stack mm';
  }

  @override
  String get garageCatalogNotLoaded =>
      'Catalogus niet geladen — schakel naar “Mijn fiets” of probeer later.';

  @override
  String get garageSearchBrandHint => 'Focus SAM, Canyon Grizl, Stevens …';

  @override
  String get garageSearchIntro =>
      'Zoek op merk en model, maak een foto, of kies uit de lijst.';

  @override
  String get garageHideList => 'Lijst verbergen';

  @override
  String get garagePickFromList => 'Kies uit lijst';

  @override
  String get garageManufacturer => 'Fabrikant';

  @override
  String get garageNickname => 'Bijnaam (optioneel)';

  @override
  String get garageNicknameHint => 'bijv. trail';

  @override
  String get garageTravelFrontMm => 'Voorveerweg (mm)';

  @override
  String get garageTravelRearMm => 'Achterveerweg (mm)';

  @override
  String get garageTravelOnlyIfPresent => 'Alleen als het op de fiets zit';

  @override
  String get garageOnBikeCheck =>
      'Op de fiets — vink alleen aan als het er echt op zit';

  @override
  String get garageBagsOnBike => 'Tassen op de fiets';

  @override
  String get garageBrandOptional => 'Merk (optioneel)';

  @override
  String get garageModelOptional => 'Model (optioneel)';

  @override
  String get garagePickGpx => 'GPX-bestand kiezen';

  @override
  String get garageNameOptional => 'Naam (optioneel)';

  @override
  String get garageMyBike => 'Mijn fiets';

  @override
  String get garageCatalog => 'Catalogus';

  @override
  String get garageImport => 'Importeren';

  @override
  String get garageCreateBike => 'Fiets toevoegen';

  @override
  String garageGpxImported(String name, String km) {
    return 'GPX “$name” · $km km';
  }

  @override
  String get garageName => 'Naam';

  @override
  String get garageNameHint => 'bijv. Gravel, City, MTB';

  @override
  String get garagePhoto => 'Foto';

  @override
  String get garageGallery => 'Galerij';

  @override
  String get garageSlotHeading => 'Slot';

  @override
  String get garageEditPart => 'Onderdeel bewerken';

  @override
  String get garageInstallPart => 'Onderdeel monteren';

  @override
  String get garageSearchParts => 'Onderdelen zoeken (API/cache)';

  @override
  String get garageSearchPartsHint => 'Merk / model — optioneel';

  @override
  String get garageSearchPartsHelper =>
      'Geen treffers: vul de basis met de hand in';

  @override
  String get garageHits => 'Treffers';

  @override
  String get garageNoHitsManual =>
      'Geen treffers — vul met de hand in. Cache kan leeg zijn.';

  @override
  String garageCacheId(String id) {
    return 'Cache-ID: $id';
  }

  @override
  String garageCompatAttrs(String slot) {
    return 'Pasattributen · $slot';
  }

  @override
  String get garageCompatAttrsHint =>
      'Van het datasheet of de stempel op het onderdeel. Leeg laten als onbekend — dan “data ontbreekt”, geen gok.';

  @override
  String get garageExtraAttr => 'Extra attribuut (gevorderd)';

  @override
  String get garageAttrKey => 'Attribuutsleutel';

  @override
  String get garageAttrValue => 'Attribuutwaarde';

  @override
  String get garageCompatPlaceholder =>
      'Pas-placeholders gezet (bijv. 148×12 / Microspline) — geen cataloguswaarheid. Controleer de attributen.';

  @override
  String garageSagGuideTitle(String kg) {
    return 'Vering-startpunten (rijder $kg kg)';
  }

  @override
  String garageSagGuideFork(String psi, String min, String max, String sag) {
    return 'Vork: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String garageSagGuideShock(String psi, String min, String max, String sag) {
    return 'Demper: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String get garageSagGuideHint =>
      'Startpunt — meet op de fiets, daarna fijnstellen.';

  @override
  String get garageMeasureSag => 'SAG meten';

  @override
  String get garageShowMeasureSteps => 'Stappen tonen';

  @override
  String get garageOdometer => 'Kilometerteller';

  @override
  String get garageOperatingHours => 'Uren';

  @override
  String garageOdoStand(String km) {
    return 'Stand: $km km';
  }

  @override
  String garageHoursStand(String hours) {
    return 'Uren: $hours u';
  }

  @override
  String get garageAddKmNoGps => 'Km toevoegen zonder GPS-track';

  @override
  String get garageDistanceKm => 'Afstand (km)';

  @override
  String get garageImportKm => 'Km importeren (geen GPS-rit)';

  @override
  String get garageMaintLog => 'Onderhoudslog';

  @override
  String get garageMaintLogEmpty =>
      'Nog geen vermeldingen — de kilometerteller zetten schrijft logs.';

  @override
  String get garageBleScanning => 'Apparaten zoeken …';

  @override
  String get garageBlePaired => 'Apparaat gekoppeld';

  @override
  String garageBlePairedNamed(String name) {
    return 'Gekoppeld: $name';
  }

  @override
  String get garageBlePairFailed => 'Koppelen mislukt';

  @override
  String get garageBleRemoved => 'Sensor verwijderd';

  @override
  String get garageBleDisconnected => 'Bluetooth niet verbonden';

  @override
  String get garageBleHintEbike =>
      'Bosch, Shimano STEPS of CSC. Zet het display aan.';

  @override
  String get garageBleHintSensor => 'Sensor op de fiets, niet op de rijder.';

  @override
  String get discoverRefresh => 'Vernieuwen';

  @override
  String get discoverChangePlace => 'Plaats wijzigen';

  @override
  String get discoverSuggestDuration => 'Duur voorstellen';

  @override
  String get discoverDemoCities => 'Demo-steden';

  @override
  String discoverNearbyTitle(String profile) {
    return 'Bij jou · $profile';
  }

  @override
  String get discoverNearbyHintGps =>
      'Tik om de route te zien · Rit start navigatie';

  @override
  String get discoverNearbyHintNoGps => 'Deel locatie voor tochten vanaf hier';

  @override
  String get discoverGrantLocation => 'Locatie delen';

  @override
  String get discoverSuggestionsComputing => 'Suggesties berekenen…';

  @override
  String get discoverNoSuggestions =>
      'Geen suggesties — zet een locatie, kies een fietsprofiel, of tik op Vernieuwen.';

  @override
  String discoverAdaptSuggestion(String label) {
    return 'Suggestie aanpassen: $label';
  }

  @override
  String get discoverTours => 'Tochten';

  @override
  String discoverToursLoops(int count) {
    return 'Tochten · $count lussen';
  }

  @override
  String discoverToursCount(int count) {
    return 'Tochten · $count';
  }

  @override
  String get discoverNoGpsCurated =>
      'Zonder GPS: samengestelde tochten · locatie voor in de buurt';

  @override
  String get discoverGrantLocationNearby => 'Deel locatie voor tochten bij jou';

  @override
  String discoverToursNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tochten in de buurt',
      one: '1 tocht in de buurt',
    );
    return '$_temp0';
  }

  @override
  String discoverCuratedLoops(int count) {
    return '$count samengestelde lussen';
  }

  @override
  String get discoverOfflineSuffix => ' · offline';

  @override
  String get discoverHeatmapConsent =>
      'Waar velen rijden — nadat je toestemt. Privacy openen';

  @override
  String get discoverRideToStartShort => 'Naar de start';

  @override
  String get discoverLoopsNearby => 'Lussen bij jou';

  @override
  String get discoverNearbySection => 'Dichtbij';

  @override
  String get discoverNoLoop90 => 'Geen lus binnen 90 km — volgende regio’s';

  @override
  String get discoverRecommendedNoGps => 'Aanbevolen tochten · ook zonder GPS';

  @override
  String discoverRecommended(int count) {
    return 'Aanbevolen ($count)';
  }

  @override
  String get discoverRecommendedHint =>
      'Voor alle fietstypen · geometrie laadt als je rijdt';

  @override
  String discoverInRegion(int count) {
    return 'In de regio ($count)';
  }

  @override
  String get discoverToursAround => 'Tochten hieromheen';

  @override
  String get discoverAfterLocation => 'Verschijnt na locatie';

  @override
  String get discoverNeedLocationTrails =>
      'Zet locatie of start voor het trailnetwerk';

  @override
  String get discoverTrailLoading => 'Trailnetwerk laden…';

  @override
  String get discoverTrailEmpty => 'Geen OSM-trailnetwerk in de buurt';

  @override
  String discoverTrailCount(int count) {
    return 'Trailnetwerk $count · tik om te kiezen';
  }

  @override
  String get discoverTrailOffline => 'Trailnetwerk offline';

  @override
  String get discoverOsmLivePath => 'OSM-livepad';

  @override
  String get discoverOsmTags => 'Tags van OpenStreetMap';

  @override
  String get discoverTapMapTrails => 'Tik op de kaart om trails te kiezen.';

  @override
  String get discoverTrailApproachHint =>
      'Rijd naar de ingang, sla daarna de overlay op of ga.';

  @override
  String get discoverTrailGravityHint =>
      'DH: rijd of loop naar de bovenste ingang. De afdaling volgt de trail, niet de weg.';

  @override
  String get discoverRideToTrailhead => 'Naar de start rijden';

  @override
  String get discoverApproachByCar => 'Naar de trail rijden';

  @override
  String get discoverApproachOnFoot => 'Naar de ingang lopen';

  @override
  String get discoverAtTrailStart => 'Ik ben bij de start';

  @override
  String get discoverApproachByBike => 'Erheen rijden';

  @override
  String discoverTrailUnsuitableForBike(String bike) {
    return 'Niet met $bike op deze trail. Wissel fietsen in de garage — geen stiekeme MTB-route.';
  }

  @override
  String get discoverTrailOrientedDownhill => 'Ingang boven (hoogte)';

  @override
  String get discoverTrailStartUphillUnknown =>
      'Hoogte onbekend — dichtere ingang';

  @override
  String get discoverPutOnRoute => 'Op de route zetten';

  @override
  String get discoverOpenOsm => 'Openen op OpenStreetMap';

  @override
  String get discoverApproachTrailhead => 'Naderen van de trailstart…';

  @override
  String discoverApproachPlusTrail(String km, String diff) {
    return 'Aanrijden + trail · $km km · $diff';
  }

  @override
  String discoverTrailLaid(String diff, String km) {
    return 'Trail gelegd · $diff · $km km — opslaan of gaan';
  }

  @override
  String get discoverSurfaceNature => 'Natuur';

  @override
  String get discoverSurfaceGrass => 'Gras';

  @override
  String get discoverSurfaceWood => 'Hout';

  @override
  String get discoverHighwayPath => 'Pad';

  @override
  String get discoverHighwayTrack => 'Bosweg';

  @override
  String get discoverHighwayCycle => 'Fietspad';

  @override
  String get discoverHighwayBridle => 'Ruiterpad';

  @override
  String get discoverHighwayFoot => 'Voetpad';

  @override
  String get discoverSetStartEnd =>
      'Zet start en einde — dan bereken je de route';

  @override
  String get discoverAdjustStops => 'Pas start, einde of een stop aan';

  @override
  String discoverNoHitsFor(String query) {
    return 'Geen treffers voor “$query”';
  }

  @override
  String get discoverGeocodeFailed => 'Adreszoeken mislukt';

  @override
  String discoverStartEndHit(String kind, String label) {
    return '$kind: $label';
  }

  @override
  String get discoverIdeaStartSet =>
      'Tochtidee: start = plaatspin, einde voorgesteld — bereken de route.';

  @override
  String get discoverSuggestEnd => 'Voorgesteld einde (bewerkbaar)';

  @override
  String get discoverTourInPlan =>
      'Tocht in Navigeren — wijzig start, einde of stop';

  @override
  String get discoverNeedLocationTours => 'Zet locatie of start voor tochten';

  @override
  String get discoverOaOffline => 'Tochten nu onbereikbaar';

  @override
  String get discoverOaNoLive => 'Geen live-tochten in de buurt';

  @override
  String discoverOaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tochten in de buurt',
      one: '1 tocht in de buurt',
    );
    return '$_temp0';
  }

  @override
  String get discoverLocationOff =>
      'Locatie uit — tik start of gebruik een adres';

  @override
  String get discoverLocationDenied =>
      'Locatietoestemming ontbreekt — gebruik een adres';

  @override
  String get discoverNoGpsFix =>
      'Geen GPS-fix — tik op de kaart of zoek een adres';

  @override
  String get discoverMyPosition => 'Mijn positie';

  @override
  String get discoverLocationReady => 'Locatie klaar · in de buurt laden…';

  @override
  String get discoverLocationUnavailable =>
      'Positie onbeschikbaar — adres of tik';

  @override
  String get discoverComputing => 'Route berekenen…';

  @override
  String discoverComputingN(int count) {
    return '$count routes berekenen…';
  }

  @override
  String get discoverHeadingNorth => 'Richting noord';

  @override
  String get discoverHeadingEast => 'Richting oost';

  @override
  String get discoverHeadingSouthwest => 'Richting zuidwest';

  @override
  String get discoverTargetNorth =>
      'Einde in het noorden — terugweg nog niet inbegrepen';

  @override
  String get discoverTargetEast =>
      'Einde in het oosten — terugweg nog niet inbegrepen';

  @override
  String get discoverTargetSouthwest =>
      'Einde in het zuidwesten — terugweg nog niet inbegrepen';

  @override
  String discoverApproxLabel(String label) {
    return '$label (ca.)';
  }

  @override
  String get discoverQuickRoute => 'Korte route';

  @override
  String get discoverRoutingLimit =>
      'Routinglimiet — benadering gebruikt. Later opnieuw berekenen.';

  @override
  String get discoverNoQuickRoutes => 'Geen korte routes';

  @override
  String get discoverPartialApprox =>
      'Gedeeltelijke benadering — live-routing beperkt';

  @override
  String get discoverPlannedRoute => 'Geplande route';

  @override
  String get discoverStraightFallback =>
      'Geen track van de kaart — zet de bestemming opnieuw.';

  @override
  String get discoverSaved => 'Opgeslagen';

  @override
  String discoverSavedNamed(String name) {
    return 'Opgeslagen: $name';
  }

  @override
  String get discoverSavedRouteLoaded => 'Opgeslagen route geladen';

  @override
  String get discoverStartSetPickEnd => 'Start gezet — kies nu het einde';

  @override
  String get discoverEndSetComputing => 'Einde gezet — route berekenen';

  @override
  String get discoverFromHere => 'Vanaf hier';

  @override
  String get discoverNearbyPhotos => 'Foto’s in de buurt';

  @override
  String get discoverToMyTours => 'Naar Mijn tochten';

  @override
  String get discoverAlreadyInMappe => 'Al onder Tochten';

  @override
  String discoverInMappeNamed(String name) {
    return 'In Die Mappe: $name';
  }

  @override
  String get discoverAddRoute => 'Route toevoegen';

  @override
  String get discoverAddRouteHint =>
      'Naam + start — geen verzonnen track. Later berekenen of GPX.';

  @override
  String get discoverMapCenter => 'Kaartmidden';

  @override
  String get discoverSaveToMine => 'Opslaan in Mijn tochten';

  @override
  String discoverSavedToMine(String name) {
    return 'In Mijn tochten: $name';
  }

  @override
  String get discoverPickFileAgain => 'Ander bestand kiezen';

  @override
  String discoverGpxUnreadable(String name) {
    return '“$name” kon niet worden gelezen — beschadigd of geen geldige GPX.';
  }

  @override
  String get discoverGpxInvalid =>
      'Ongeldige GPX of te weinig punten — ander bestand kiezen?';

  @override
  String discoverGpxImported(String name, String km) {
    return 'GPX geïmporteerd: $name · $km km';
  }

  @override
  String discoverSavedDotName(String name) {
    return 'Opgeslagen · $name';
  }

  @override
  String get discoverAsActive => 'Als actief';

  @override
  String get discoverLocalFoldersHint =>
      'Lokale mappen voor opgeslagen routes — geen social feed.';

  @override
  String get discoverNoSavedInCollection =>
      'Geen passende opgeslagen routes in deze collectie';

  @override
  String get discoverNoCollectionYet => 'Nog geen collectie.';

  @override
  String get discoverNewCollection => 'Nieuwe collectie';

  @override
  String get discoverNeedRouteAndCollection =>
      'Minstens één opgeslagen route en een collectie nodig';

  @override
  String get discoverPickRoute => 'Route kiezen';

  @override
  String get discoverPickCollection => 'Collectie kiezen';

  @override
  String get discoverAddedToCollection => 'Toegevoegd aan de collectie';

  @override
  String get discoverRouteToCollection => 'Route naar collectie';

  @override
  String get discoverStartSavedNoTrack =>
      'Start opgeslagen — nog geen track. Navigeren of GPX.';

  @override
  String get discoverComputedRoute => 'Berekende route';

  @override
  String get discoverSavedRoute => 'Opgeslagen route';

  @override
  String discoverViaN(int n) {
    return 'Stop $n';
  }

  @override
  String get discoverTourGone => 'Tocht niet meer beschikbaar';

  @override
  String get discoverTourGoneBody =>
      'Deze tocht staat nu niet in de lijst — een filter kan hem verbergen.';

  @override
  String get discoverTourTimeline => 'Onderweg';

  @override
  String get discoverNoTrackYet =>
      'Nog geen track — Route berekenen bouwt hem live.';

  @override
  String get discoverDuration => 'Duur';

  @override
  String get discoverLength => 'Lengte';

  @override
  String get discoverAscent => 'Klim';

  @override
  String get discoverElevationProfile => 'Hoogte';

  @override
  String discoverDescent(String m) {
    return '↓ $m m afdaling';
  }

  @override
  String get discoverTip => 'Tip';

  @override
  String get discoverBestTime => 'Beste tijd';

  @override
  String get discoverDiscipline => 'Discipline';

  @override
  String get discoverCorridor => 'Corridor';

  @override
  String get discoverTraits => 'Kenmerken';

  @override
  String get discoverTipsInfo => 'Tips & info';

  @override
  String get discoverStartPoint => 'Start';

  @override
  String discoverFromHereKm(String dist) {
    return '$dist vanaf hier';
  }

  @override
  String get discoverApproach => 'Aanrijden';

  @override
  String get discoverInMyTours => 'In Mijn tochten';

  @override
  String discoverPinIdeaNamed(String name) {
    return 'Idee “$name” — alleen plaatspin';
  }

  @override
  String get discoverPinIdea => 'Tochtidee — alleen plaatspin op de kaart';

  @override
  String get discoverStartEndReady =>
      'Start/einde gezet. Bereken de route of pas het einde aan.';

  @override
  String get discoverComputeAndSave => 'Berekenen & opslaan';

  @override
  String get discoverChangePlaceSearch =>
      'Plaats wijzigen — zoek een stad of adres';

  @override
  String discoverDemoRegion(String name) {
    return 'Demoregio: $name';
  }

  @override
  String get discoverPickProfile => 'Profiel kiezen';

  @override
  String get discoverOwn => 'Eigen';

  @override
  String discoverStartOnlyNoTrack(String badge) {
    return '$badge · start — nog geen track';
  }

  @override
  String get discoverShowLess => 'Minder tonen';

  @override
  String get discoverShowMore => 'Meer tonen';

  @override
  String get discoverTrailView => 'Trailweergave';

  @override
  String get discoverNoPhotosNearby => 'Geen foto’s in de buurt';

  @override
  String get discoverImageUnavailable => 'Beeld niet beschikbaar';

  @override
  String get discoverNoLivePhotos => 'Geen live-foto’s';

  @override
  String get discoverOpenMapillary => 'Mapillary openen';

  @override
  String get discoverMapillarySample =>
      'Voorbeeld — Mapillary niet beschikbaar';

  @override
  String get discoverNoTrackOnMap =>
      'Geen track — laad hem eerst op de kaart of GPX.';

  @override
  String get discoverNoClosedLoop =>
      'Geen gesloten lustrack — kies de tocht opnieuw of Bewerken.';

  @override
  String get discoverNoLiveTrackPlan =>
      'Geen live-track — Route berekenen opent Plan met een voorgesteld einde.';

  @override
  String get discoverNotClosedLoopNav =>
      'Geometrie is geen gesloten lus — navigatie geannuleerd.';

  @override
  String get discoverNoRealPolyline =>
      'Geen echte track — opnieuw berekenen of GPX.';

  @override
  String get discoverPoiIdeaHint =>
      'Aanrijden naar de plaatspin — geen tochttrack. Blijf het einde plannen of GPX.';

  @override
  String discoverHybridKm(String km) {
    return 'Hybrid · $km km';
  }

  @override
  String get discoverAroundPoiComputing => 'Route rond de plaatspin berekenen…';

  @override
  String discoverLiveRouteReady(String km) {
    return 'Live-route · $km km — opslaan of rijden';
  }

  @override
  String discoverPoiNamed(String name) {
    return 'Plaatspin · $name';
  }

  @override
  String get discoverNotLoopAb =>
      'Geen lus — A→B-voorstel gezet. Route berekenen of tik op het einde.';

  @override
  String get discoverApproxAb =>
      'Geschatte A→B · pas het einde op de kaart aan, bereken daarna opnieuw.';

  @override
  String get discoverRoutingFailedRetry =>
      'Routing mislukt — tik op het einde en probeer opnieuw.';

  @override
  String get discoverUnplausibleDropped =>
      'Onaannemelijk routingresultaat weggelaten';

  @override
  String discoverAltChosen(String label) {
    return 'Alternatief gekozen: $label';
  }

  @override
  String get discoverLoading => 'Laden';

  @override
  String get discoverCatalog => 'Catalogus';

  @override
  String get discoverShared => 'gedeeld';

  @override
  String get discoverPrivate => 'privé';

  @override
  String get discoverPrivateCap => 'Privé';

  @override
  String get discoverShareRelease => 'Delen';

  @override
  String discoverRiddenWith(String name) {
    return 'gereden met $name';
  }

  @override
  String get discoverPrivateCommentHint =>
      'Nog privé — anderen kunnen reageren nadat je deelt.';

  @override
  String get discoverRemoveFromMappe => 'Uit Die Mappe halen';

  @override
  String get discoverLinkNoTrack =>
      'Link zonder spoor — te lang voor de URL. Naam en stats, geen GPS.';

  @override
  String get discoverLinkCopiedTrack =>
      'Link gekopieerd. Inclusief vereenvoudigd spoor.';

  @override
  String get discoverLinkCopiedStats =>
      'Link gekopieerd. Naam en stats, geen track.';

  @override
  String get discoverTrackLocal =>
      'Track is lokaal. Sync tussen jouw apparaten.';

  @override
  String get discoverNoTrackEntry =>
      'Nog geen track — alleen het Tochten-item.';

  @override
  String get discoverVisibility => 'Delen';

  @override
  String get discoverCopyLink => 'Link kopiëren';

  @override
  String get discoverNoSavedFilter => 'Geen tochten in dit filter.';

  @override
  String get discoverMineEmptyHint =>
      'Nog geen eigen routes — voeg een route, GPX of opname toe.';

  @override
  String get overlayLegendTitle => 'Paden · OSM';

  @override
  String get overlayLegendCompactCity => 'Stad';

  @override
  String get overlayLegendCompactMtb => 'MTB';

  @override
  String get overlayScaleNote =>
      'S0–S3+ alleen als de trail een graad heeft. Anders zonder graad.';

  @override
  String get overlayRoadAsphalt => 'Fietspad / asfalt';

  @override
  String get overlayUnrated => 'zonder graad';

  @override
  String get overlayLegendEmpty =>
      'Hier geen overlay. OSM-paden vanaf zoom 12 op het DACH-blad. Het fietsnetwerk volgt de kaart eronder.';

  @override
  String get overlayLegendMeshTitle => 'Fietsnetwerk · OSM';

  @override
  String get overlayLegendMeshNote =>
      'Bewegwijzerde fietsroutes (ICN/NCN/RCN) op dit blad. Paden vanaf zoom 12 over het DACH-blad.';

  @override
  String get overlayLegendCompactGravel => 'Gravel';

  @override
  String get discoverChipTooltip => 'Tochten en paden per fietstype';

  @override
  String get discoverLocateLongPress =>
      'Mijn locatie · lang indrukken: nav-symbool';

  @override
  String get discoverNavHonestyBike => 'Fietsprofielen: dezelfde route';

  @override
  String get discoverNavHonestyFoot => 'Nav: lopen';

  @override
  String get stimmenTitle => 'Tips';

  @override
  String get stimmenHint =>
      'Sterren, tekst en foto’s — cloud na delen. Geen verzonnen tips.';

  @override
  String get stimmenWrite => 'Stimme schrijven';

  @override
  String get stimmenHowWas => 'Hoe was de tocht?';

  @override
  String get stimmenEmptyName => 'Leeg blijft jij';

  @override
  String get stimmenAddPhoto => 'Foto toevoegen';

  @override
  String get stimmenSaving => 'Opslaan …';

  @override
  String get stimmenShareSubject => 'Tocht delen';

  @override
  String get stimmenEmpty => 'Nog geen tips.';

  @override
  String get stimmenLabel => 'Stimme';

  @override
  String get stimmenCloudApproved => 'Opgeslagen — zichtbaar (AI-delen)';

  @override
  String get stimmenCloudRejected =>
      'Lokaal opgeslagen — cloud wees de tekst af';

  @override
  String get stimmenCloudPending =>
      'Opgeslagen — lokaal en in beoordeling (AI/mens)';

  @override
  String get stimmenCloudLocal => 'Opgeslagen — lokaal (cloud na inloggen)';

  @override
  String get stimmenCloudFailed => 'Lokaal opgeslagen — cloud nu onbereikbaar';

  @override
  String get stimmenStatusPending => 'In beoordeling';

  @override
  String get stimmenStatusLocal => 'Alleen dit apparaat';

  @override
  String get akteHonestyCatalog =>
      'Catalogustochten zijn al gedeeld. Delen maakt jouw tocht linkbaar — de link toont naam en stats, geen extra privétrack.';

  @override
  String get akteHonestyTrack =>
      'Delen maakt een link. De link bevat een vereenvoudigd spoor (coördinaten), niet alleen de naam. Terug naar privé haalt hem uit filters en registreert de intrekking op de server als je bent ingelogd. Zonder login geldt het alleen op dit apparaat.';

  @override
  String get akteHonestyNoTrack =>
      'Delen maakt een link met naam en stats — geen track, omdat er geen is opgeslagen.';

  @override
  String get stimmenSubmit => 'Versturen';

  @override
  String get ortSheetVia => 'Als stop toevoegen';

  @override
  String get ortSheetHere => 'Tochten hierheen';

  @override
  String get ortSheetMaps => 'Openen in Maps';

  @override
  String get ortKindCafe => 'Café';

  @override
  String get ortKindWater => 'Water';

  @override
  String get ortKindViewpoint => 'Uitzicht';

  @override
  String get ortKindShop => 'Winkel';

  @override
  String get ortKindRepair => 'Reparatie';

  @override
  String get ortKindTrailhead => 'Start';

  @override
  String get ortKindTip => 'Tip';

  @override
  String get ortKindMeet => 'Verzamelpunt';

  @override
  String get ortKindOther => 'Plaats';

  @override
  String get viaMoveUp => 'Omhoog';

  @override
  String get viaMoveDown => 'Omlaag';

  @override
  String get stimmeTagsHint => 'Condities — optioneel, max drie';

  @override
  String get stimmeTagNass => 'nat';

  @override
  String get stimmeTagZu => 'dicht';

  @override
  String get stimmeTagVielLos => 'druk';

  @override
  String get stimmeTagTop => 'top';

  @override
  String get stimmeTagBaustelle => 'werkzaamheden';

  @override
  String get postRideStimmeTitle => 'Stimme voor deze tocht?';

  @override
  String get postRideStimmeHint =>
      'Alleen deze tocht, geen track in de tekst. Overslaan mag.';

  @override
  String get postRideStimmePrivate =>
      'Een Stimme pas nadat je deelt. Deze tocht is privé — open hem en tik op Delen.';

  @override
  String get postRideStimmePrivateCta => 'Openen en delen';

  @override
  String get postRideStimmeSkip => 'Niet nu';

  @override
  String get postRideStimmeDone => 'Stimme opgeslagen.';

  @override
  String get postRideOrtTitle => 'Deze plek onthouden?';

  @override
  String get postRideOrtHint =>
      'Altijd privé op deze rit. Op de kaart alleen met login, op de lijn, na review.';

  @override
  String get postRideOrtSkip => 'Niet nu';

  @override
  String get postRideOrtDone => 'Plek opgeslagen.';

  @override
  String get postRideOrtNameHint => 'Pleksnaam';

  @override
  String get postRideOrtSave => 'Opslaan';

  @override
  String get postRideOrtOffTrack =>
      'Geen punt op de gereden lijn — alleen privénotitie, geen pin.';

  @override
  String get postRideOrtPrivateOnly =>
      'Alleen voor jou — geen communityplek zonder login of gedeelde tocht.';

  @override
  String get postRideOrtPending =>
      'De cloud houdt de plek na review. Tot dan alleen op dit apparaat.';

  @override
  String get postRideOrtFailed =>
      'De cloud nam de plek niet — hij blijft privé op dit apparaat.';

  @override
  String get stimmeDifficultyHint =>
      'Moeilijkheid vs de gemarkeerde graad — optioneel';

  @override
  String get stimmeDifficultyEasier => 'makkelijker';

  @override
  String get stimmeDifficultyAsMarked => 'zoals gemarkeerd';

  @override
  String get stimmeDifficultyHarder => 'zwaarder';

  @override
  String akteDifficultyCrowdEasier(int n) {
    return 'Rijders: makkelijker dan gemarkeerd ($n)';
  }

  @override
  String akteDifficultyCrowdAsMarked(int n) {
    return 'Rijders: zoals gemarkeerd ($n)';
  }

  @override
  String akteDifficultyCrowdHarder(int n) {
    return 'Rijders: zwaarder dan gemarkeerd ($n)';
  }

  @override
  String get akteAddToCollection => 'Aan collectie toevoegen';

  @override
  String get discoverEditorialSets => 'Redactioneel';

  @override
  String get discoverEditorialHonesty =>
      'Redactionele ideeën — geen gebruikerscollecties.';

  @override
  String get discoverEditorialEmpty =>
      'Deze regio staat in de catalogus; die tochten staan nu niet in de lijst.';

  @override
  String get discoverLayerTours => 'Tochten';

  @override
  String get discoverLayerTrails => 'Trails';

  @override
  String get discoverLayerWays => 'Fietspaden';

  @override
  String get discoverLayerHeight => 'Hoogte';

  @override
  String get discoverLayerHeightHint =>
      'Alleen reliëf — geen hoogtelijnen op deze kaart.';

  @override
  String get browseMapLegendPaved => 'Asfalt';

  @override
  String get browseMapLegendGravel => 'Gravel';

  @override
  String get browseMapLegendTrail => 'Pad';

  @override
  String get discoverDurationAll => 'alle';

  @override
  String get overlayLegendTrailsTitle => 'Trails · OSM';

  @override
  String get overlayLegendWaysTitle => 'Fietspaden · OSM';

  @override
  String get overlayLegendAllTitle => 'Wegen · OSM';

  @override
  String get discoverLayerPlaces => 'Plekken';

  @override
  String get discoverLayerHeat => 'Heat';

  @override
  String get discoverLayerHeatOff => 'Heat uit';

  @override
  String get discoverVariantPlanned => 'Zoals gepland';

  @override
  String get discoverVariantFlatter => 'Minder klim';

  @override
  String get discoverVariantUnpaved => 'Meer onverhard';

  @override
  String get discoverVariantValhallaOnly => 'Geen varianten zonder live-route';

  @override
  String get discoverGhMinuteLimit =>
      'Suggesties en tijden zijn beperkt — wacht even of plan spaarzaam.';

  @override
  String get discoverHonestyRoad =>
      'Route volgt vooral wegen — tik een trail op de kaart en koppel hem.';

  @override
  String get discoverHonestyCycleway =>
      'Weinig eigen fietspad — de live-route blijft vaak op de weg.';

  @override
  String get discoverTrailWet => 'waarschijnlijk nat';

  @override
  String get discoverTrailDamp => 'misschien vochtig';

  @override
  String get discoverTrailDry => 'waarschijnlijk droog';

  @override
  String discoverWeatherStart(String temp, String hint) {
    return 'Start $temp° · $hint';
  }

  @override
  String discoverWeatherSummit(String temp, String hint) {
    return 'Top $temp° · $hint';
  }

  @override
  String get discoverFilmstripAttribution => 'Mapillary CC BY-SA';

  @override
  String get discoverOfflineAfterSave => 'Regio offline downloaden?';

  @override
  String get discoverOfflineAfterSaveAction => 'Packs';

  @override
  String get discoverRoundTrip => 'Heen en terug';

  @override
  String get discoverOutboundOnly => 'alleen heen';

  @override
  String get discoverOsmNoHitsSuffix => ' · geen paden in de buurt';

  @override
  String get discoverLiveRoutingUnavailable =>
      ' · live-routing niet beschikbaar';

  @override
  String get discoverUnplausibleLive =>
      ' · live-routing gaf niets aannemelijks';

  @override
  String get discoverTapEndCompute =>
      'Tik een bestemming of adres — dan bereken je de route.';

  @override
  String get discoverPlanYourself => 'Plan de route zelf — zet start en einde';

  @override
  String get discoverLoopBadge => '⟲ Lus';

  @override
  String discoverElevMin(Object min) {
    return 'Min $min';
  }

  @override
  String get discoverHeatmapOffline => 'Waar velen rijden: offline';

  @override
  String get discoverCreate => 'Maken';

  @override
  String get discoverRegionSource => 'Regio';

  @override
  String get discoverTourNoun => 'Tocht';

  @override
  String get discoverOsmLive => 'OSM live';

  @override
  String discoverApproachParen(Object name) {
    return '($name)';
  }

  @override
  String get discoverShop => 'Winkel';

  @override
  String get discoverPreview => 'Voorbeeld';

  @override
  String discoverApproachName(Object name) {
    return '$name (aanrijden)';
  }

  @override
  String discoverFromHereName(Object name) {
    return '$name (vanaf hier)';
  }

  @override
  String get rideLocationOff => 'Locatie uit';

  @override
  String get rideLocationOffBody =>
      'Geen GPS-track zonder locatie. Zet locatieservices aan.';

  @override
  String get rideSettings => 'Instellingen';

  @override
  String get rideLocationPermission => 'Locatietoestemming';

  @override
  String get rideLocationDeniedForever =>
      'Locatie definitief geweigerd. Sta het toe in de app-instellingen, anders blijft de track leeg.';

  @override
  String get rideAppSettings => 'App-instellingen';

  @override
  String get rideLocationNeeded =>
      'Locatie nodig voor track en navigatie — start opnieuw en sta toe.';

  @override
  String get rideGpsFix => 'GPS-fix…';

  @override
  String rideGpsFixN(Object count) {
    return 'GPS-fix $count…';
  }

  @override
  String get rideGpsStillSim => 'GPS stil — sim-track (niet opslaan)';

  @override
  String get rideGpsStillWeak => 'GPS stil — zwak signaal / stilstaand';

  @override
  String get rideGpsSimActive => 'Sim-track actief (AETHER_SIM_MOTION)';

  @override
  String get rideBleOffSnack =>
      'Bluetooth uit — je kunt zonder sensor rijden; later verbinden.';

  @override
  String get rideBleDeniedSnack =>
      'In de buurt/Bluetooth geweigerd — GPS-navigatie loopt zonder sensor.';

  @override
  String get rideNoBikeSensor =>
      'Geen fietssensor gevonden — GPS-track gaat door.';

  @override
  String get rideOfflineRerouteToast =>
      'Reroute heeft internet nodig. Blijf op de geladen route.';

  @override
  String get rideStayOnTrail => 'Blijf op de trail — geen wegreroute.';

  @override
  String get rideFollowTrail => 'Volg de trail';

  @override
  String get rideNoGpsRejoin => 'Geen GPS-fix voor rejoin';

  @override
  String rideRejoinFailed(Object error) {
    return 'Rejoin mislukt: $error';
  }

  @override
  String get rideSkipAheadWhy => 'Stuk overgeslagen — terug naar de route.';

  @override
  String get rideRejoinWhy => 'Terug naar de route.';

  @override
  String get rideSkipAheadTts => 'Stuk overgeslagen';

  @override
  String get rideRouteRestoredTts => 'Route hersteld';

  @override
  String get rideOffRouteTts => 'Van de route';

  @override
  String get rideRerouting => 'Route herberekenen …';

  @override
  String get rideUndo10s => '10 s ongedaan';

  @override
  String get rideUndo => 'Ongedaan';

  @override
  String get rideStayOffHint => 'Je blijft van de route — tik voor opties.';

  @override
  String get rideRecalc => 'Herberekenen …';

  @override
  String get rideTapOptions => 'Tik voor opties.';

  @override
  String get rideOptions => 'Opties';

  @override
  String get ridePause => 'Pauze';

  @override
  String get rideResume => 'Hervatten';

  @override
  String get rideRunning => 'Rit loopt';

  @override
  String get rideStop => 'Rit beëindigen';

  @override
  String get rideTapAgain => 'Nog eens tikken';

  @override
  String get rideStopNeedsTwo => 'Stoppen vraagt 2 tikken';

  @override
  String get rideQuietDisplay => 'Stil display';

  @override
  String get rideFollowCamera => 'Camera volgen';

  @override
  String get rideFollowOn => 'Camera volgen aan';

  @override
  String get rideFollowFree => 'Camera vrij';

  @override
  String get rideLiveRide => 'Live-rit';

  @override
  String get rideReady => 'Klaar';

  @override
  String get rideTtsOn => 'TTS aan';

  @override
  String get rideTtsMute => 'TTS gedempt';

  @override
  String get rideNorthUp => 'Noord omhoog';

  @override
  String get rideHeadingUp => 'Koers omhoog';

  @override
  String rideHeadingCourse(Object cardinal, Object mode) {
    return '$mode, koers $cardinal';
  }

  @override
  String get rideAutoRerouteOn => 'Auto-reroute aan';

  @override
  String get rideAutoRerouteOff => 'Auto-reroute uit';

  @override
  String rideAutoRerouteActive(Object sec) {
    return 'Auto-reroute actief (cooldown ${sec}s)';
  }

  @override
  String get rideAutoRerouteManual =>
      'Auto-reroute uit — handmatig rejoin blijft';

  @override
  String get rideSunlightAuto => 'Zonlichtmodus (auto)';

  @override
  String get rideSunlightManual => 'Zonlichtmodus (handmatig)';

  @override
  String rideDisplayNamed(Object name) {
    return 'Display: $name';
  }

  @override
  String rideDisplayNamedBattery(Object name) {
    return 'Display: $name (gebruikt accu)';
  }

  @override
  String get rideCostsBattery => 'gebruikt accu';

  @override
  String get rideBatteryTitle => 'Display & accu';

  @override
  String get rideBatteryHint =>
      'Display aanhouden? Gebruikt meer accu. Standaard spaart accu.';

  @override
  String get rideBatteryPocketSnack =>
      'Pocket — display mag slapen (accu sparen).';

  @override
  String get rideBatteryLenkerSnack => 'Lenker — display aan (gebruikt accu).';

  @override
  String get rideBatteryUltraSnack =>
      'Ultra — display alleen bij bochten (gebruikt accu).';

  @override
  String get rideBatteryPocket => 'Pocket';

  @override
  String get rideBatteryLenker => 'Lenker';

  @override
  String get rideBatteryUltra => 'Ultra';

  @override
  String get rideBatteryPocketSub => 'Stem + haptiek, display mag slapen';

  @override
  String get rideBatteryLenkerSub => 'Display aanhouden';

  @override
  String get rideBatteryUltraSub => 'Display alleen wekken bij bochten';

  @override
  String get rideDefault => 'Standaard';

  @override
  String get rideSpeed => 'Snelheid';

  @override
  String get rideSensorSpeed => 'Sensorsnelheid';

  @override
  String get rideDistance => 'Afstand';

  @override
  String get rideTime => 'Tijd';

  @override
  String get rideHeart => 'Hart';

  @override
  String get rideHeartWaiting => 'Hart wacht';

  @override
  String get rideCadence => 'Cadans';

  @override
  String get rideBikeSensor => 'Fietssensor';

  @override
  String get rideWatch => 'Smartwatch';

  @override
  String get rideConnected => 'Verbonden';

  @override
  String get ridePower => 'Vermogen';

  @override
  String get rideSoc => 'Accu';

  @override
  String get rideAssist => 'Ondersteuning';

  @override
  String get rideBatteryChip => 'Accu';

  @override
  String get rideWheelSpeed => 'Wiel';

  @override
  String get rideRestKm => 'km over';

  @override
  String get rideUntilJoin => 'km tot route';

  @override
  String get rideRestLoop => 'lus over';

  @override
  String rideKmToRoute(String km) {
    return '$km km tot de route';
  }

  @override
  String get rideEta => 'ETA';

  @override
  String get rideKmh => 'km/u';

  @override
  String get rideKm => 'km';

  @override
  String get rideChassisOff => 'Chassisanalyse uit';

  @override
  String get rideChassisHint =>
      'Zet de telefoon op het stuur en markeer hem als gemonteerd.';

  @override
  String get rideMarkMounted => 'Als gemonteerd markeren';

  @override
  String get rideWaitingSensors => 'Wachten op sensoren…';

  @override
  String get rideThereafter => 'Volgende';

  @override
  String get rideAutoLock => 'Auto-lock';

  @override
  String get rideAutoLockHint => 'Tik om te wekken';

  @override
  String get rideWake => 'Wekken';

  @override
  String get rideMusicHud => 'Muziek in de HUD';

  @override
  String get rideMusicHudHint => 'Titels van Spotify & Co. tonen.';

  @override
  String get rideDismissHint => 'Hint sluiten';

  @override
  String get rideMusicControls => 'Muziekbediening';

  @override
  String get ridePrevTrack => 'Vorige track';

  @override
  String get rideNextTrack => 'Volgende track';

  @override
  String get ridePlay => 'Afspelen';

  @override
  String get rideNavSymbol => 'Symbool';

  @override
  String get rideChangeNavSymbol => 'Nav-symbool wijzigen';

  @override
  String get rideNavPuckTitle => 'Nav-symbool';

  @override
  String get rideNavPuckHint =>
      'Alle varianten op donker en licht. Tik om het symbool voor kaart en HUD te kiezen. 0° = punt omhoog.';

  @override
  String get rideRecommend => 'Aanbevolen';

  @override
  String get ridePuckDark => 'Donker';

  @override
  String get ridePuckLight => 'Licht';

  @override
  String get ridePuckBergA => 'Berg-A';

  @override
  String get ridePuckTopDown => 'Fiets van boven';

  @override
  String get ridePuckHofTor => 'Hof-Tor';

  @override
  String get ridePuckKomet => 'Aether-Komet';

  @override
  String get ridePuckKiesel => 'Kiezel';

  @override
  String get ridePuckLenkerBug => 'Stuurneus';

  @override
  String get ridePuckLichtkegel => 'Lichtkegel';

  @override
  String get ridePuckChevron => 'Chevron';

  @override
  String get ridePuckBergASub => 'Letter, berg en pijl in één';

  @override
  String get ridePuckTopDownSub =>
      'Van boven: neus, hoorns, twee banden — draait met jou mee';

  @override
  String get ridePuckHofTorSub => 'Twee benen, onder open';

  @override
  String get ridePuckKometSub => 'Speerpunt met oranje vonk';

  @override
  String get ridePuckKieselSub => 'Zachte driehoek met halo';

  @override
  String get ridePuckLenkerBugSub => 'Puntige neus, twee stuuruiteinden';

  @override
  String get ridePuckLichtkegelSub => 'Donkere schijf, oranje kegel';

  @override
  String get ridePuckChevronSub => 'Standaard nav-pijl';

  @override
  String get rideChipLive => 'Live';

  @override
  String get rideChipRouteOffline => 'Route offline';

  @override
  String get rideChipOfflineMapOk => 'Offline · kaart oké · Reroute: net';

  @override
  String get rideChipMapsMissing => 'Kaarten ontbreken';

  @override
  String get rideCardinalN => 'N';

  @override
  String get rideCardinalNE => 'NO';

  @override
  String get rideCardinalE => 'O';

  @override
  String get rideCardinalSE => 'ZO';

  @override
  String get rideCardinalS => 'Z';

  @override
  String get rideCardinalSW => 'ZW';

  @override
  String get rideCardinalW => 'W';

  @override
  String get rideCardinalNW => 'NW';

  @override
  String get navCueArrive => 'Bestemming';

  @override
  String get navCueSlightLeft => 'Licht links';

  @override
  String get navCueSlightRight => 'Licht rechts';

  @override
  String get navCueTurnLeft => 'Linksaf';

  @override
  String get navCueTurnRight => 'Rechtsaf';

  @override
  String get navCueSharpLeft => 'Scherpe linkerbocht';

  @override
  String get navCueSharpRight => 'Scherpe rechterbocht';

  @override
  String liveHintBracketRun(String n) {
    return 'Run $n vastgelegd';
  }

  @override
  String get liveHintImpactStreak => 'Harde klappen achter elkaar';

  @override
  String get liveHintStandSetup => 'Gestopt: setup checken';

  @override
  String get maintForkLower => 'Vork-onderbeenonderhoud';

  @override
  String get maintForkFull => 'Vork volledig onderhoud (veer/demper)';

  @override
  String get maintShockAir => 'Demper air-can-onderhoud';

  @override
  String get maintShockFull => 'Demper volledig onderhoud';

  @override
  String get maintChainWear => 'Kettingsslijtage checken';

  @override
  String get maintCassetteCheck => 'Cassette checken (na 2–3 kettingen)';

  @override
  String get maintPadsFront => 'Voorremblokken checken';

  @override
  String get maintPadsRear => 'Achterremblokken checken';

  @override
  String get maintSealant => 'Tubeless-sealant verversen';

  @override
  String get maintDropper => 'Dropper-onderbuisonderhoud';

  @override
  String maintDays(String n) {
    return '$n dagen';
  }

  @override
  String get maintNoInterval => 'Geen interval';

  @override
  String get compatTitleDrv011 => 'Cassette vraagt passende freehub-body';

  @override
  String get compatTitleFrm004 => 'Achteras-afstand moet bij de naaf passen';

  @override
  String get compatTitleSus007 => 'Dempermaat moet bij de framespec passen';

  @override
  String get compatTitleSus012 => 'Vork-steerer vs balhoofd (S.H.I.S.)';

  @override
  String get compatTitleBrk003 => 'Remklauw-montage op het frame';

  @override
  String get compatTitleBrk008 => 'Schijfmontage vs naaf';

  @override
  String get compatTitleBrk008f => 'Voorschijf vs voornaaf';

  @override
  String get compatTitleWhl005 => 'Bandbreedte vs interne velgbreedte';

  @override
  String get compatTitleWhl005f => 'Voorband vs interne velgbreedte';

  @override
  String get compatTitleWhl009 => 'Bandbreedte vs framedoorgang';

  @override
  String get compatTitleCkp002 => 'Stuurklem-diameter vs stuurpen';

  @override
  String get compatTitleSpt006 => 'Zadelpen-diameter vs zadelbuis';

  @override
  String get compatTitleBb003 => 'Trapasstandaard vs crankas';

  @override
  String get compatTitleBb003f => 'Trapas vs framestandaard';

  @override
  String get compatTitleEbk002 => 'Motorinterface alleen met OEM-goedkeuring';

  @override
  String get compatTitleFrm004f => 'Vooras vs vork';

  @override
  String compatFailDrv011(String cassette, String hub) {
    return 'De cassette vraagt $cassette, jouw naaf heeft $hub.';
  }

  @override
  String compatFailFrm004(String frame, String hub) {
    return 'Frame-afstand $frame ≠ naaf $hub.';
  }

  @override
  String compatFailSus007(String eye, String stroke, String mount) {
    return 'Demper $eye×$stroke ($mount) past niet bij de framespec.';
  }

  @override
  String compatFailSus012(String fork, String headset) {
    return 'Vork-steerer $fork past niet bij balhoofd $headset.';
  }

  @override
  String compatFailBrk003(String caliper, String frame) {
    return 'Klauw $caliper vs framemontage $frame.';
  }

  @override
  String compatFailBrk008(String rotor, String hub) {
    return 'Schijf $rotor ≠ naaf $hub.';
  }

  @override
  String compatFailBrk008f(String rotor, String hub) {
    return 'Voorschijf $rotor ≠ naaf $hub.';
  }

  @override
  String compatFailWhl005(String tire, String rim) {
    return 'Bandbreedte $tire mm buiten bereik voor interne breedte $rim mm.';
  }

  @override
  String compatFailWhl005f(String tire, String rim) {
    return 'Voorband $tire mm buiten bereik voor $rim mm.';
  }

  @override
  String compatFailWhl009(String tire, String max) {
    return 'Bandbreedte $tire mm > framedoorgang $max mm.';
  }

  @override
  String compatFailCkp002(String bar, String stem) {
    return 'Stuurklem $bar mm ≠ stuurpen $stem mm.';
  }

  @override
  String compatFailSpt006(String post, String frame) {
    return 'Pen Ø $post past niet bij frame Ø $frame.';
  }

  @override
  String compatFailBb003(String bb, String crank) {
    return 'Trapasas $bb ≠ crank $crank.';
  }

  @override
  String compatFailBb003f(String bb, String frame) {
    return 'Trapas $bb ≠ frame $frame.';
  }

  @override
  String compatFailEbk002(String frame, String motor) {
    return 'Motorwissel buiten OEM-goedkeuring is niet toegestaan. Frame $frame ≠ motor $motor.';
  }

  @override
  String compatFailFrm004f(String fork, String hub) {
    return 'Vorkas $fork ≠ naaf $hub.';
  }

  @override
  String get compatRuleOk => 'Regel gehaald.';

  @override
  String get compatConditional => 'Voorwaardelijk compatibel';

  @override
  String get compatMissingFacts =>
      'Attributen ontbreken — geen COMPATIBLE zonder complete feiten.';

  @override
  String get compatWorkshopHint =>
      'Veiligheidskritische passing: naar een werkplaats. Momentwaarden alleen uit fabrikantendocs.';

  @override
  String get compatConditionBrk003 =>
      'Alleen met passende adapter (Post Mount ↔ IS).';

  @override
  String get compatDatasheet => 'Controleer het fabrikantendatasheet';

  @override
  String get attrFreehub => 'Freehub-standaard';

  @override
  String get attrRearSpacing => 'Achteras-afstand';

  @override
  String get attrEyeToEye => 'Eye-to-eye-lengte';

  @override
  String get attrStroke => 'Stroke';

  @override
  String get attrMountType => 'Montagetype';

  @override
  String get attrShockEyeToEye => 'Framespec: eye-to-eye';

  @override
  String get attrShockStroke => 'Framespec: stroke';

  @override
  String get attrShockMount => 'Framespec: montagetype';

  @override
  String get attrSteerer => 'Steerer';

  @override
  String get attrBrakeMount => 'Klauwmontage';

  @override
  String get attrBrakeMountRear => 'Frame: achterremmontage';

  @override
  String get attrRotorMount => 'Schijfmontage';

  @override
  String get attrTireWidth => 'Bandbreedte';

  @override
  String get attrRimWidth => 'Interne velgbreedte';

  @override
  String get attrMaxTire => 'Frame: max banddoorgang';

  @override
  String get attrBarClamp => 'Klemdiameter';

  @override
  String get attrStemClamp => 'Stuurpenklem';

  @override
  String get attrSeatpostDia => 'Diameter';

  @override
  String get attrMinInsert => 'Min. insteek';

  @override
  String get attrMaxInsert => 'Frame: max insteek';

  @override
  String get attrCrankAxle => 'Crankas';

  @override
  String get attrBbStandard => 'Trapasstandaard';

  @override
  String get attrMotorInterface => 'Motorinterface';

  @override
  String get attrAxleFront => 'As';

  @override
  String get howToFreehub => 'Freehub-body-stempel / naafdatasheet';

  @override
  String get howToRearSpacing => 'Frame/naaf-spec (Boost 148, 142×12, …)';

  @override
  String get howToEyeToEye => 'Demperstempel';

  @override
  String get howToStroke => 'Dempercatalogus';

  @override
  String get howToMountType => 'Trunnion vs. Eyelet';

  @override
  String get howToSteerer => '1⅛″ of tapered 1.5″ / S.H.I.S.';

  @override
  String get howToBrakeMount => 'Post Mount / Flat Mount / IS';

  @override
  String get howToBrakeMountRear => 'Framespec';

  @override
  String get howToRotorMount => 'Center Lock of 6-bolt';

  @override
  String get howToTireWidth => 'ETRTO';

  @override
  String get howToRimWidth => 'Velgdatasheet';

  @override
  String get howToMaxTire => 'Framespec van de fabrikant';

  @override
  String get howToBarClamp => '31.8 of 35.0';

  @override
  String get howToStemClamp => 'Stuurpendatasheet';

  @override
  String get howToSeatpostDia => '27.2 / 30.9 / 31.6 / 34.9';

  @override
  String get howToMinInsert => 'Dropper-handleiding';

  @override
  String get howToMaxInsert => 'Framegeometrie';

  @override
  String get howToCrankAxle => 'DUB / 24mm / 30mm';

  @override
  String get howToBbStandard => 'BSA / T47 / PF92 / …';

  @override
  String get howToMotorInterface => 'bijv. bosch_smart_system';

  @override
  String get howToAxleFront => '15×100 / 15×110 Boost / …';

  @override
  String postRideObsImpacts(String count, String km) {
    return 'Veel harde klappen ($count over $km km) — vork/demper zwaar belast.';
  }

  @override
  String postRideObsSmooth(String km) {
    return 'Weinig klappen over $km km — meer flow of gladdere ondergrond.';
  }

  @override
  String postRideObsFlowHigh(String flow) {
    return 'Hoge flowscore ($flow) — tempo en lijnkeuze voelden synchroon.';
  }

  @override
  String postRideObsFlowLow(String flow) {
    return 'Lage flowscore ($flow) — veel tempobreuken of stops.';
  }

  @override
  String postRideObsPeakG(String g) {
    return 'Piek $g g — harde klappen; check setup en bandenspanning.';
  }

  @override
  String get postRideFrontTooFirm => 'te stug';

  @override
  String get postRideFrontOk => 'oké';

  @override
  String get postRideBumpsHarsh => 'hard';

  @override
  String postRideObsFbHarsh(String front, String bumps) {
    return 'Feedback: voor $front · kleine klappen $bumps.';
  }

  @override
  String get postRideObsFbSoft =>
      'Feedback: voor voelt zacht / duikt bij remmen.';

  @override
  String get postRideSugReboundSlowTitle => 'Vork-rebound: 2 clicks langzamer';

  @override
  String postRideSugReboundSlowContent(String current, String next) {
    return 'Ongeveer $current clicks vanaf dicht → doel $next.';
  }

  @override
  String get postRideSugReboundSlowEffect =>
      'Kalmere voorkant bij klapreeksen, iets minder pop.';

  @override
  String get postRideSugReboundFastTitle => 'Vork-rebound: 2 clicks sneller';

  @override
  String postRideSugReboundFastContent(String current, String next) {
    return 'Ongeveer $current clicks → doel $next (minder duiken).';
  }

  @override
  String get postRideSugReboundFastEffect =>
      'Stabieler remmen, minder bottom-out-gevoel.';

  @override
  String get postRideSugPressureTitle => 'Voorluchtdruk checken';

  @override
  String get postRideSugPressureContent =>
      'Zeer hoge piek-g — houd druk en volume spacers tegen de fabrikantentabel.';

  @override
  String get postRideSugPressureEffect =>
      'Minder bottom-out-risico, duidelijker feedback.';

  @override
  String get postRideSugLimitsClicks =>
      'Fabrikantenbereik typisch 0–14 clicks vanaf dicht.';

  @override
  String get postRideSugLimitsPressure =>
      'Alleen binnen het goedgekeurde drukbereik van band/vork.';

  @override
  String get postRideReasonHarshBumps => 'Feedback “kleine klappen hard”';

  @override
  String get postRideReasonFrontFirm => 'Feedback “voor te stug”';

  @override
  String postRideReasonImpacts(String count, String km) {
    return '$count klappen / $km km';
  }

  @override
  String postRideReasonRms(String rms) {
    return 'RMS $rms g';
  }

  @override
  String get postRideReasonFrontLoad => 'Hoge klapbelasting vooraan';

  @override
  String get postRideReasonDive => 'Feedback “duikt”';

  @override
  String get postRideReasonFrontSoft => 'Feedback “voor te zacht”';

  @override
  String get postRideReasonSoftDive => 'Voor te zacht / duiken';

  @override
  String get postRideReasonPeakLong => 'Piek ≥ 5 g op een langere rit';

  @override
  String get postRideAnalysis => 'Analyse';

  @override
  String postRideExpect(String text) {
    return 'Verwacht: $text';
  }

  @override
  String postRideLimit(String text) {
    return 'Limiet: $text';
  }

  @override
  String get postRideEvidence => 'Bewijs';

  @override
  String postRideConfidence(String level) {
    return 'Zekerheid $level';
  }

  @override
  String get postRideConfHigh => 'hoog';

  @override
  String get postRideConfMedium => 'middel';

  @override
  String get postRideConfLow => 'laag';

  @override
  String postRideFactRide(String km, String hm, String min) {
    return '$km km · $hm hm · $min min';
  }

  @override
  String postRideFactMetrics(String flow, String g, String impacts) {
    return 'Flow $flow · Piek $g g · $impacts klappen';
  }

  @override
  String postRideFactMetricsLean(
      String flow, String g, String impacts, String lean) {
    return 'Flow $flow · Piek $g g · $impacts klappen · Lean $lean°';
  }

  @override
  String postRideFactBike(String name) {
    return 'Fiets: $name';
  }

  @override
  String postRideFactSoc(String soc) {
    return 'SOC $soc%';
  }

  @override
  String get rideGPeak => 'G-piek';

  @override
  String get rideLean => 'Lean';

  @override
  String get rideFlow => 'Flow';

  @override
  String garageSetNamed(String name) {
    return '$name zetten';
  }

  @override
  String get bleKindPower => 'Powermeter';

  @override
  String get bleKindOtherDrive => 'E-aandrijving';

  @override
  String get bleTipBosch =>
      'Flow: Components → FlowLine toevoegen · firmware ≥19';

  @override
  String get bleTipShimano => 'E-TUBE sluiten · tik binnen 15 s na power/knop';

  @override
  String get bleTipYamaha => 'e-Sync sluiten · snelheid via CSC-sensor';

  @override
  String get bleTipOtherDrive =>
      'Maker-app sluiten · display aan, dichtbij houden';

  @override
  String get bleTipCsc => 'Sensor op de fiets wekken, dichtbij houden';

  @override
  String get bleTipPower => 'Powermeter aanzetten, dichtbij houden';

  @override
  String get blePairLeadEbike =>
      'Display aan, maker-app dicht, telefoon dichtbij — dan tikken.';

  @override
  String get blePairLeadSensor =>
      'Sensor op de fiets wekken, niet het horloge om je pols.';

  @override
  String get bleNoteSensorBrand => 'Sensor';

  @override
  String get bleNoteSensorLine =>
      'Magneet of crank, dicht bij de sensor — niet het horloge.';

  @override
  String get bleNoteBoschLine =>
      'SoC: open Flow → Components → FlowLine toevoegen (besturing ≥19). CSC nog uit de lijst, Flow daarna dicht.';

  @override
  String get bleNoteShimanoLine =>
      'E-TUBE sluiten. Na power of knop vaak maar 15 s — dan tikken.';

  @override
  String get bleNoteYamahaLine =>
      'e-Sync of de TQ-app sluiten. Livesnelheid meestal alleen via CSC.';

  @override
  String get bleNoteFazuaLine =>
      'Remote aan — CSC en vermogen als een normale sensor.';

  @override
  String get bleNoteOtherBrand => 'Overig';

  @override
  String get bleNoteOtherLine =>
      'RideControl / Mission Control sluiten. Eén telefoon, display aan.';

  @override
  String get bleGattWatchRejected =>
      'Verbinding geweigerd — sluit de andere fitness-app, houd het horloge dichtbij.';

  @override
  String get bleGattWatchTimeout =>
      'Timeout — houd het horloge dichtbij, check broadcast-hartslag.';

  @override
  String get bleGattWatchFailed => 'Horlogeverbinding mislukt';

  @override
  String get bleGattRejectedBosch =>
      'Verbinding geweigerd — sluit Bosch Flow, display aan, 10–20 cm.';

  @override
  String get bleGattRejectedShimano =>
      'Verbinding geweigerd — sluit E-TUBE, display aan, dichtbij houden.';

  @override
  String get bleGattRejectedGeneric =>
      'Verbinding geweigerd — sluit Bosch Flow / Shimano E-TUBE, display aan, dichtbij houden.';

  @override
  String get bleLdiPairCta => 'Bosch LDI — toevoegen in Flow';

  @override
  String get bleLdiPairHint =>
      'Fiets aan, open Flow → Settings → Components → Add device. Bevestig op het display. Besturingsfirmware 19+.';

  @override
  String get bleLdiTimeout =>
      'Geen LDI-link. Firmware ≥19? Voeg FlowLine opnieuw toe onder Components in Flow.';

  @override
  String get bleLdiWaitingFlow =>
      'Wachten op de fiets — voeg “FlowLine” toe in Flow.';

  @override
  String get bleLdiNeedAndroid12 => 'Bosch LDI vraagt Android 12 of nieuwer.';

  @override
  String get bleLdiIosPending =>
      'Bosch LDI is op dit apparaat nog niet gekoppeld.';

  @override
  String get bleGattTimeoutBosch =>
      'Timeout — wek het display. SoC via LDI in Flow, snelheid via CSC.';

  @override
  String get bleGattTimeoutShimano =>
      'Timeout — sluit E-TUBE, tik binnen 15 s na power/knop.';

  @override
  String get bleGattTimeoutDrive =>
      'Timeout — sluit de maker-app, display aan. Snelheid via CSC-sensor.';

  @override
  String get bleGattTimeoutSensor => 'Timeout — wek de sensor, kom dichterbij.';

  @override
  String get bleDriveFailBosch =>
      'Bosch zonder live-SoC. Voeg in Flow FlowLine toe onder Components, of koppel een wielsensor (CSC).';

  @override
  String get bleDriveFailShimano =>
      'Shimano gevonden, geen live-motorwaarden. Koppel daarna een wielsensor (CSC).';

  @override
  String get bleDriveFailYamaha =>
      'Yamaha gevonden, geen live-motorwaarden. Koppel snelheid via een CSC-sensor.';

  @override
  String get bleDriveFailGeneric =>
      'Aandrijving gevonden, geen live-motorwaarden. Koppel daarna een wielsensor (CSC).';

  @override
  String get bleStatusBtOff => 'Bluetooth uit';

  @override
  String get bleStatusScanFailed => 'Wielsensorscan mislukt';

  @override
  String get bleStatusNoSensor => 'Geen wielsensor gevonden';

  @override
  String get bleStatusNoneInRange =>
      'Geen fiets, aandrijving of sensor in bereik';

  @override
  String get bleStatusDriveSeen =>
      'Aandrijving gezien — koppelen in de werkplaats (Bosch/Shimano)';

  @override
  String get bleStatusNoCscInRange => 'Geen wielsensor in bereik';

  @override
  String get bleStatusSensorDisconnected => 'Wielsensor verbroken';

  @override
  String get bleStatusReconnectLost =>
      'Verbinding verloren — check het display, sluit Flow/E-TUBE, koppel opnieuw in de werkplaats.';

  @override
  String bleStatusRetry(String n, String max) {
    return 'Verbinden … poging $n/$max';
  }

  @override
  String bleStatusAttempt(String n, String max) {
    return 'Verbinden … poging $n/$max';
  }

  @override
  String bleStatusReconnect(String n, String max) {
    return 'Opnieuw verbinden … ($n/$max)';
  }

  @override
  String bleStatusDriveNoLive(String who) {
    return '$who · gevonden — snelheid via CSC, accu alleen met standaard GATT';
  }

  @override
  String get bleStatusNeedBond =>
      'Display vraagt Bluetooth-koppeling voor de accu.';

  @override
  String get bleStatusBonding => 'Systeemkoppeling …';

  @override
  String bleStatusDriveNeedBond(String who) {
    return '$who · gevonden — accu na Bluetooth-koppeling in de werkplaats';
  }

  @override
  String bleConnectedNamed(String name) {
    return '$name verbonden';
  }

  @override
  String get bleWordSensor => 'Sensor';

  @override
  String get bleWordWatch => 'Horloge';

  @override
  String get bleSectionDrive => 'Aandrijving';

  @override
  String get bleSectionSensors => 'Sensoren';

  @override
  String get watchStatusPickFromList => 'Kies het horloge uit de lijst';

  @override
  String get watchStatusScanFailed => 'Horlogescan mislukt';

  @override
  String get watchStatusConnectedSim => 'Horloge verbonden (sim)';

  @override
  String get watchStatusDisconnected => 'Horloge verbroken';

  @override
  String get watchStatusNoHrService =>
      'Horloge gevonden, maar geen standaard-hartslagservice';

  @override
  String get watchStatusReconnectLost =>
      'Horloge verbroken — check broadcast, koppel opnieuw dichtbij.';

  @override
  String watchStatusReconnect(String n, String max) {
    return 'Horloge opnieuw verbinden … ($n/$max)';
  }

  @override
  String watchStatusBattery(String n) {
    return 'Horloge-accu $n %';
  }

  @override
  String get watchHrSensorFallback => 'Hartslagsensor';

  @override
  String get watchCheckBluetooth => 'Bluetooth checken';

  @override
  String get watchOutOfRange => 'Horloge niet in bereik';

  @override
  String get watchRemoved => 'Horloge verwijderd';

  @override
  String watchRememberedOffline(String name) {
    return '$name · opgeslagen, niet live';
  }

  @override
  String get watchRememberedOfflineNoName => 'Opgeslagen, niet live';

  @override
  String watchLiveNamed(String name) {
    return '$name · live';
  }

  @override
  String watchLiveBpm(String name, String bpm) {
    return '$name · $bpm bpm';
  }

  @override
  String get watchHonestyHr => 'Hartslag via standaard BLE';

  @override
  String get watchHonestyGarmin => 'Garmin: broadcast-HR aanzetten';

  @override
  String get watchHonestyApple => 'Apple Watch: geen standaard-BLE-hartslag';

  @override
  String get watchHonestyGalaxy => 'Galaxy: meestal geen standaard-hartslag';

  @override
  String get watchHonestyUnknown => 'Alleen met zichtbare hartslag-broadcast';

  @override
  String get watchTipHr => 'Sensor of broadcastmodus aan, dichtbij houden';

  @override
  String get watchTipGarmin =>
      'Op het Garmin-horloge: hartslag versturen / broadcast';

  @override
  String get watchTipApple =>
      'Geen BLE-hartslag naar Android — HealthKit alleen op iPhone';

  @override
  String get watchTipGalaxy =>
      'Alleen als het horloge hartslag over Bluetooth stuurt — anders Samsung Health';

  @override
  String get watchTipUnknown =>
      'Hartslag-broadcast op het horloge moet aan staan';

  @override
  String get watchNotePolarBrand => 'Polar / band';

  @override
  String get watchNotePolarLine =>
      'Sensormodus aan. Standaard-hartslag — dat koppelen we.';

  @override
  String get watchNoteGarminLine =>
      'Hartslag versturen / broadcast in de horloge-instellingen.';

  @override
  String get watchNoteAppleLine =>
      'Geen standaard-BLE-hartslag naar Android. Niet koppelen.';

  @override
  String get watchNoteGalaxyLine =>
      'Meestal alleen Samsung Health. Alleen met zichtbare hartslag-broadcast.';

  @override
  String get watchPairLeadText =>
      'Hartslag op de rijder, niet de fiets. Alleen een echte hartslagsensor.';

  @override
  String get blePairAgain => 'Opnieuw koppelen';

  @override
  String get bleRemoveDevice => 'Apparaat verwijderen';

  @override
  String get bleSemanticsPaired => 'Bluetooth gekoppeld';

  @override
  String get bleSemanticsPair => 'Bluetooth koppelen';

  @override
  String get bleTooltipPair => 'Aandrijving of sensor koppelen';

  @override
  String get bleRemoveWheel => 'Wielsensor verwijderen';

  @override
  String get bleRemoveDrive => 'Aandrijving verwijderen';

  @override
  String get bleSemanticsLive => 'Bluetooth live';

  @override
  String get bleTooltipSaved => 'Gekoppeld, niet verbonden';

  @override
  String get watchOtherWatch => 'Ander horloge';

  @override
  String get bikeCatMtbTrail => 'MTB trail';

  @override
  String get bikeCatMtb => 'MTB';

  @override
  String get bikeCatEnduro => 'Enduro';

  @override
  String get bikeCatDh => 'Downhill';

  @override
  String get bikeCatGravel => 'Gravel';

  @override
  String get bikeCatRoad => 'Race';

  @override
  String get bikeCatUrban => 'Stad';

  @override
  String get bikeCatCargo => 'Cargo';

  @override
  String get bikeCatFolding => 'Vouwfiets';

  @override
  String get bikeCatKids => 'Kinderen';

  @override
  String get bikeCatEmtb => 'E-MTB';

  @override
  String get bikeCatEtrekking => 'E-trekking';

  @override
  String get bikeCatHiking => 'Te voet';

  @override
  String get bikeCatEgravel => 'E-gravel';

  @override
  String get bikeCatEcity => 'E-city';

  @override
  String get bikeCatEcargo => 'E-cargo';

  @override
  String get bikeCatEfolding => 'E-vouw';

  @override
  String get bikeCatEkids => 'E-kinderen';

  @override
  String get bikeCatEroad => 'E-race';

  @override
  String get bikeBlurbMtbTrail => 'Singletrack & bos';

  @override
  String get bikeBlurbMtb => 'Trails & tochten';

  @override
  String get bikeBlurbEnduro => 'Steil & technisch';

  @override
  String get bikeBlurbDh => 'Bikepark & afdalingen';

  @override
  String get bikeBlurbGravel => 'Gravel & afstand';

  @override
  String get bikeBlurbRoad => 'Asfalt & tempo';

  @override
  String get bikeBlurbUrban => 'Alledag & woon-werk';

  @override
  String get bikeBlurbCargo => 'Cargo & alledag';

  @override
  String get bikeBlurbFolding => 'Vouwen & meenemen';

  @override
  String get bikeBlurbKids => 'Kinderfiets';

  @override
  String get bikeBlurbEmtb => 'Trail met ondersteuning';

  @override
  String get bikeBlurbEtrekking => 'Tochten met ondersteuning';

  @override
  String get bikeBlurbHiking => 'Te voet eropuit';

  @override
  String get bikeBlurbMtbTrailFocus => 'Singletrack-focus';

  @override
  String get onboardSportTrail => 'Trail';

  @override
  String sportsSummaryPrimary(String label) {
    return 'Hoofd: $label';
  }

  @override
  String sportsSummaryPrimaryAlso(String label, String list) {
    return 'Hoofd: $label · ook $list';
  }

  @override
  String get seasonYearRound => 'Het hele jaar';

  @override
  String get seasonSpringSummer => 'Lente–zomer';

  @override
  String get seasonAutumn => 'Herfst';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get naeheInYourRegion => '~60 min in jouw streek';

  @override
  String get naeheAroundYou => '~60 min om je heen';

  @override
  String get sportTagTouring => 'Toeren';

  @override
  String get sportTagEbike => 'E-bike';

  @override
  String get overlayRheinNeckar => 'Rijn-Neckar / Heidelberg';

  @override
  String get overlaySchwarzwaldNord => 'Zuidelijk Zwarte Woud';

  @override
  String get overlayBodensee => 'Bodenmeer';

  @override
  String get overlayStuttgart => 'Stuttgart / Midden-Neckar';

  @override
  String get overlayMuenchen => 'München & omgeving';

  @override
  String get overlayNuernberg => 'Neurenberg / Franken';

  @override
  String get overlayFrankfurtRheinMain => 'Frankfurt Rijn-Main';

  @override
  String get overlayKoelnRhein => 'Keulen / Rijnland';

  @override
  String get overlayHamburg => 'Hamburg & omgeving';

  @override
  String get overlayBerlin => 'Berlijn & Brandenburg';

  @override
  String get overlayDresdenElbland => 'Dresden / Elbedal';

  @override
  String get overlayWien => 'Wenen & Wienerwald';

  @override
  String get overlaySalzburg => 'Salzburg';

  @override
  String get overlayInnsbruck => 'Innsbruck / Tirol';

  @override
  String get overlayZuerich => 'Zürich & omgeving';

  @override
  String get overlayBern => 'Bern / Mittelland';

  @override
  String get overlayBasel => 'Bazel / drielandenpunt';

  @override
  String get overlayRuhrgebiet => 'Ruhrgebied';

  @override
  String get overlayDuesseldorf => 'Düsseldorf / Nederrijn';

  @override
  String get overlayHannover => 'Hannover / Leine';

  @override
  String get overlayLeipzig => 'Leipzig / Neuseenland';

  @override
  String get overlayFreiburg => 'Freiburg / Schauinsland';

  @override
  String get overlayKarlsruhe => 'Karlsruhe / Hardt';

  @override
  String get overlayAugsburg => 'Augsburg / Lech';

  @override
  String get overlayKiel => 'Kiel / fjord';

  @override
  String get overlayRostock => 'Rostock / Warnow';

  @override
  String get overlayKassel => 'Kassel / Bergpark';

  @override
  String get overlayTrierMosel => 'Trier / Moezel';

  @override
  String get overlayPfalz => 'Paltserwoud';

  @override
  String get overlaySauerland => 'Sauerland';

  @override
  String get overlayEifelTrails => 'Eifel';

  @override
  String get overlayHarz => 'Harz';

  @override
  String get overlayThueringerWald => 'Thüringer Woud';

  @override
  String get overlayBayerischerWald => 'Beierse Woud';

  @override
  String get overlayAllgaeu => 'Allgäu';

  @override
  String get overlayChiemgau => 'Chiemgau';

  @override
  String get overlaySaarbruecken => 'Saarbrücken';

  @override
  String get overlayMuenster => 'Münsterland';

  @override
  String get overlayAachen => 'Aken / drielandenpunt';

  @override
  String get overlayLuebeck => 'Lübeck / Trave';

  @override
  String get overlayBremen => 'Bremen / Weser';

  @override
  String get overlayMagdeburg => 'Maagdenburg / Elbe';

  @override
  String get overlayErfurt => 'Erfurt';

  @override
  String get overlayKoblenz => 'Koblenz / Rijn-Moezel';

  @override
  String get overlayGraz => 'Graz / Murdal';

  @override
  String get overlayLinz => 'Linz / Donau';

  @override
  String get overlayKlagenfurt => 'Klagenfurt / Wörthersee';

  @override
  String get overlayVillach => 'Villach / Drau';

  @override
  String get overlayBregenz => 'Bregenz / Vorarlberg';

  @override
  String get overlayKitzbuehel => 'Kitzbühel / Wilder Kaiser';

  @override
  String get overlayGenf => 'Genève / Meer van Genève';

  @override
  String get overlayLausanne => 'Lausanne / Lavaux';

  @override
  String get overlayLuzern => 'Luzern / Vierwaldstättersee';

  @override
  String get overlayStGallen => 'Sankt Gallen / Appenzell';

  @override
  String get overlayLugano => 'Lugano / Ticino';

  @override
  String get overlayInterlaken => 'Interlaken / Berner Oberland';

  @override
  String get overlayChur => 'Chur / Graubünden';

  @override
  String get overlayZermatt => 'Zermatt / Mattertal';

  @override
  String get overlayStMoritz => 'Sankt Moritz / Engadin';

  @override
  String get overlayDavos => 'Davos / Landwasser';

  @override
  String get overlayStrasbourg => 'Straatsburg / Ill';

  @override
  String get overlayAlsaceVins => 'Elzas / Route des Vins';

  @override
  String get overlayVosges => 'Vogezen / Ballon d\'Alsace';

  @override
  String get overlayNancyMoselle => 'Nancy / Moezel';

  @override
  String get overlayJuraFr => 'Jura / Pontarlier';

  @override
  String get overlayAnnecy => 'Annecy / Semnoz';

  @override
  String get overlayMorzine => 'Morzine / Portes du Soleil';

  @override
  String get overlayLyon => 'Lyon / Tête d\'Or';

  @override
  String get overlayGrenoble => 'Grenoble / Isère';

  @override
  String get overlayDijon => 'Dijon / Canal de Bourgogne';

  @override
  String get overlayChambery => 'Chambéry / Lac du Bourget';

  @override
  String get overlayParis => 'Parijs / Bois & Seine';

  @override
  String get overlayLille => 'Lille / Citadelle';

  @override
  String get overlayNice => 'Nice / Promenade des Anglais';

  @override
  String get overlayMarseille => 'Marseille / Corniche';

  @override
  String get overlayBordeaux => 'Bordeaux / Garonne';

  @override
  String get overlayToulouse => 'Toulouse / Canal du Midi';

  @override
  String get overlayNantes => 'Nantes / Erdre';

  @override
  String offlineProgressPack(String got, String total) {
    return 'Pack $got / $total';
  }

  @override
  String offlineProgressBasemap(String id) {
    return 'Basemap $id…';
  }

  @override
  String offlineProgressBasemapBytes(String got, String total) {
    return 'Basemap $got / $total';
  }

  @override
  String offlineProgressMapZoom(String min, String max) {
    return 'Kaart (zoom $min–$max)…';
  }

  @override
  String offlineProgressMapPercent(String percent) {
    return 'Kaart $percent%';
  }

  @override
  String get offlineProgressActivating => 'Activeren…';

  @override
  String get offlineProgressManifest => 'Manifest…';

  @override
  String offlineProgressPackFile(String file) {
    return 'Pack $file…';
  }

  @override
  String get offlineProgressGraphFile => 'offline_graph.json…';

  @override
  String get offlineProgressDemoGraph => 'Demograaf (Zwarte Woud)…';

  @override
  String get offlinePacksReadyOne => '1 pack klaar om te downloaden';

  @override
  String offlinePacksReadyCount(int count) {
    return '$count packs klaar om te downloaden';
  }

  @override
  String offlinePackNotBuilt(String name) {
    return '$name: pack nog niet gebouwd — geen download.';
  }

  @override
  String offlineShaMismatch(String sha) {
    return 'SHA-256 matcht geen van de downloads (verwacht $sha)';
  }

  @override
  String offlineInvalidGraphFolder(String id) {
    return 'Map $id heeft geen geldige graaf voor deze regio';
  }

  @override
  String offlineNoRemotePack(String name) {
    return 'Nog geen pack om te laden voor $name.';
  }

  @override
  String get offlineDownloadEmpty => 'Download leeg';

  @override
  String get offlineNoGraphAfterExtract => 'Geen graaf na uitpakken';

  @override
  String get offlineRawPmtiles =>
      'Ruwe .pmtiles wordt niet ondersteund — MapLibre-stijl-JSON met pmtiles://-bron nodig.';

  @override
  String get offlineInvalidUrl => 'Ongeldige URL';

  @override
  String get offlineExpectStyleJson =>
      'Verwacht een stijl-JSON-URL (*.json of /styles/…), geen tegelbestand.';

  @override
  String get offlineSubActive => 'Actief — tik om te vernieuwen';

  @override
  String get offlineSubInstalled => 'Geïnstalleerd — tik om te activeren';

  @override
  String get offlineSubDemoGraph => 'Demograaf in de app (geen remote pack)';

  @override
  String get offlineSubNotBuilt => 'Nog niet gebouwd';

  @override
  String get offlineSubLoad => 'Routing + kaart laden';

  @override
  String offlineSubLoadSized(String size) {
    return '$size · routing + kaart';
  }

  @override
  String offlineGraphMissing(String name) {
    return 'Geen graaf in $name';
  }

  @override
  String offlineGraphSha(String name) {
    return 'Graaf-SHA voor $name komt niet overeen';
  }

  @override
  String offlineGraphDemoMismatch(String name) {
    return 'Zwarte Woud-demograaf hoort niet bij $name';
  }

  @override
  String get offlineEngineLinkedNoTiles =>
      'Graaf-engine · Valhalla gekoppeld, regiotegels ontbreken nog';

  @override
  String get offlineEngineTilesNotBuilt =>
      'Graaf-engine · Valhalla-tegels niet gebouwd';

  @override
  String get offlineNoTiles => 'geen tegels';

  @override
  String get offlineFfiMissing =>
      'FFI ontbreekt — alleen graaf / Valhalla-vlag niet gekoppeld';

  @override
  String get offlineValhallaTilesLinked =>
      'Valhalla-tegels · libvalhalla gekoppeld';

  @override
  String offlineValhallaTilesUnlinked(String code) {
    return 'Valhalla-tegels · UNLINKED (code $code)';
  }

  @override
  String get offlineValhallaFeature => 'Valhalla-feature beschikbaar';

  @override
  String get offlineValhallaNotLinked => 'Valhalla niet gekoppeld';

  @override
  String get garageMuscle => 'Trappen';

  @override
  String garageOemTaken(String name, int count) {
    return '$name: $count voorraadonderdelen overgenomen.';
  }

  @override
  String garageOemTakenPartial(String name, int taken, int skipped) {
    return '$name: $taken voorraadonderdelen, $skipped overgeslagen.';
  }

  @override
  String garageOemKitOff(String name) {
    return '$name geparkeerd — voeg zelf onderdelen toe, kit stond uit.';
  }

  @override
  String garageGpxSaved(String name, String km) {
    return '$name: GPX opgeslagen ($km km).';
  }

  @override
  String garageKmImported(String km) {
    return '+$km km geïmporteerd';
  }

  @override
  String get garageLogOdoUpdated => 'Kilometerteller bijgewerkt';

  @override
  String get garageLogHoursUpdated => 'Uren bijgewerkt';

  @override
  String get garageLogGpxImport => 'GPX geïmporteerd';

  @override
  String get garageLogImportPlaceholder => 'Import zonder onderdelen';

  @override
  String garageLogManualKm(String km) {
    return 'Handmatig: $km km';
  }

  @override
  String garageLogManualHours(String hours) {
    return 'Handmatig: $hours u';
  }

  @override
  String garageLogPsiFront(String psi) {
    return 'voor $psi psi';
  }

  @override
  String garageLogPsiRear(String psi) {
    return 'achter $psi psi';
  }

  @override
  String garageLogBarFront(String bar) {
    return 'voor $bar bar';
  }

  @override
  String garageLogBarRear(String bar) {
    return 'achter $bar bar';
  }

  @override
  String get bikeCatEmtbTrail => 'E-MTB trail';

  @override
  String get bikeCatEenduro => 'E-Enduro';

  @override
  String get bikeCatEdh => 'E-DH';

  @override
  String discoverCatalogTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Catalogus $count tochten',
      one: 'Catalogus 1 tocht',
    );
    return '$_temp0';
  }

  @override
  String discoverCatalogToursSuffix(int count) {
    return ' · Catalogus $count';
  }

  @override
  String discoverToursOsmStatus(int tours, int withTrack, int osm) {
    return 'Tochten $tours · $withTrack met een track';
  }

  @override
  String discoverElevationApprox(String hm) {
    return '~$hm hm (schatting — hoogte niet beschikbaar)';
  }

  @override
  String discoverElevationGainLoss(String gain, String loss) {
    return '+$gain / −$loss hm';
  }

  @override
  String discoverElevationGainLossSource(
      String gain, String loss, String source) {
    return '+$gain / −$loss hm · $source';
  }

  @override
  String discoverDurationMin(String n) {
    return '$n min';
  }

  @override
  String discoverPlanName(String name) {
    return '$name (plan)';
  }

  @override
  String get demoCityMuenchen => 'München';

  @override
  String get demoCityKoeln => 'Keulen';

  @override
  String get demoCityZuerich => 'Zürich';

  @override
  String get demoCityWien => 'Wenen';

  @override
  String get demoCityKonstanz => 'Konstanz';

  @override
  String get demoCityParis => 'Parijs';

  @override
  String get demoCityStrasbourg => 'Straatsburg';

  @override
  String get demoCityNice => 'Nice';

  @override
  String get postRideStravaConnect => 'Verbind Strava onder Data & privacy.';

  @override
  String get postRideStravaKeysMissing =>
      'Strava-keys ontbreken — gebruik GPX/FIT.';

  @override
  String get postRideStravaStatusDown =>
      'Strava-status onbereikbaar — gebruik GPX/FIT.';

  @override
  String get postRideStravaHint =>
      'Strava: met GPS-track via Uploads API; zonder track alleen metadata.';

  @override
  String postRideStravaError(String error) {
    return 'Strava: $error';
  }

  @override
  String get postRideHeatmapPrivate =>
      'Waar velen rijden: privétocht — track niet bijgedragen.';

  @override
  String postRideHeatmapError(String error) {
    return 'Waar velen rijden: $error';
  }

  @override
  String get postRideSetupSaved => 'Setupversie opgeslagen';

  @override
  String postRideSetupSaveFailed(String error) {
    return 'Setup kon niet worden opgeslagen: $error';
  }

  @override
  String get postRideGpxEmpty => 'Geen GPS-track — GPX zou leeg zijn';

  @override
  String postRideGpxExportError(String error) {
    return 'GPX-export: $error';
  }

  @override
  String postRideFitExportError(String error) {
    return 'FIT-export: $error';
  }

  @override
  String get postRideShareGpx => 'GPX delen';

  @override
  String get postRideSimActive => 'Sim-track stond aan';

  @override
  String postRideSimDistance(String km) {
    return ' (~$km km gesimuleerd)';
  }

  @override
  String get postRideSimUnreliable =>
      ' — afstand/analyse kan onbetrouwbaar zijn. Voor echte ritten AETHER_SIM_MOTION uit.';

  @override
  String get postRideAvgSpeedHigh =>
      'Ongewoon hoge gemiddelde snelheid — check GPS/sim.';

  @override
  String get postRideSuggestionTaken => 'Toegepast';

  @override
  String get postRideSuggestionAccept => 'Aanbeveling overnemen';

  @override
  String get postRideAssistEstimate => 'Ondersteuning (schatting)';

  @override
  String postRideAssistDominant(String mode, String wh) {
    return 'Dominant: $mode · ~$wh Wh';
  }

  @override
  String postRideAssistApproach(String mode) {
    return 'Schatting: $mode (aanrijden)';
  }

  @override
  String postRideAssistClimb(String mode, String pct) {
    return 'Schatting: $mode (klim, $pct %)';
  }

  @override
  String postRideAssistRest(String mode) {
    return 'Schatting: $mode (rest)';
  }

  @override
  String get postRideAssistDisclaimer =>
      'Schattingen uit vermogen/snelheid-signatuur — geen OEM-uitlezing. Geen motorsturing (F-EBK-000).';

  @override
  String get postRideFeelTitle => 'Hoe voelde het?';

  @override
  String get postRideFrontSuspension => 'Voorvering';

  @override
  String get postRideFrontTooSoft => 'te zacht';

  @override
  String get postRideBrakeDive => 'Remduik';

  @override
  String get postRideBrakeDives => 'duikt';

  @override
  String get postRideBrakeNeutral => 'neutraal';

  @override
  String get postRideBrakeHarsh => 'hard';

  @override
  String get postRideSmallBumps => 'Kleine klappen';

  @override
  String get postRideBumpsVague => 'vaag';

  @override
  String get postRideSaveFeedback => 'Feedback opslaan';

  @override
  String get postRideShortRideMetrics =>
      'Korte rit — metrics beperkt (< 0,5 km).';

  @override
  String get postRideMetricsTitle => 'Metriek';

  @override
  String get postRideDefaultName => 'Rit';

  @override
  String get platzCreateGroupHint =>
      'Kies een tocht, privé of zichtbaar, deel daarna de link.';

  @override
  String get platzGroupPublicHint =>
      'Wie de link heeft, kan meedoen. Onder Gedeeld kunnen anderen de groep op Platz zien.';

  @override
  String get platzGroupPrivateHint =>
      'Alleen mensen met de link kunnen meedoen. Niet openbaar vermeld.';

  @override
  String get platzNoPrivateGroups => 'Geen privégroepen in dit filter.';

  @override
  String get platzMakePrivate => 'Privé maken';

  @override
  String get platzMakePublic => 'Op Platz zetten';

  @override
  String get platzGroupListedNote =>
      'Zichtbaar vermeld — wie de link heeft, kan meedoen.';

  @override
  String get platzGroupUnlistedNote => 'Alleen per link — niet op Platz.';

  @override
  String get platzNoPublicGroups => 'Geen open groepen op de server.';

  @override
  String get platzPublicGroupsHint =>
      'Open groepen — meedoen met login, geen Ontdekken-GPS.';

  @override
  String get platzListedPublic => 'op Platz';

  @override
  String get filterVisibilityAll => 'Alle';

  @override
  String get filterVisibilityPublic => 'Gedeeld';

  @override
  String get mappeTitle => 'Tochten';

  @override
  String get mappeSubtitle =>
      'Tochten bewaren, Stimmen en vrienden op de route — dezelfde als op de kaart.';

  @override
  String get mappeAddHint =>
      'Naam bewaren, start via GPS of laatste kaartmidden, anders geen pin. GPX eronder — geen verzonnen track.';

  @override
  String get mappeKeep => 'Bewaren';

  @override
  String get mappeSearch => 'Tocht zoeken';

  @override
  String get mappeSortRecent => 'Recent';

  @override
  String get mappeSortDistance => 'Lengte';

  @override
  String get mappeSortName => 'Naam';

  @override
  String get mappeKicker => 'Mappe';

  @override
  String get mappeInviteFriends => 'Vrienden meenemen';

  @override
  String mappeActiveMeet(String title, String when) {
    return '$title · $when';
  }

  @override
  String get mappeCollectionNew => 'Verzameling maken';

  @override
  String get mappeStartNone => 'Start: nog geen pin — open GPS of de kaart.';

  @override
  String mappeStartPin(String lat, String lng) {
    return 'Start: $lat°N, $lng°O';
  }

  @override
  String mappeStartGps(String coords) {
    return 'Start: jouw locatie ($coords)';
  }

  @override
  String mappeStartMap(String coords) {
    return 'Start: laatste kaartmidden ($coords)';
  }

  @override
  String get mappePutIn => 'In Die Mappe leggen';

  @override
  String mappeSaved(String name) {
    return 'In Die Mappe: $name';
  }

  @override
  String mappeImported(String name) {
    return 'Geïmporteerd: $name';
  }

  @override
  String get mappeEmpty => 'Nog geen tochten — bewaren of GPX importeren.';

  @override
  String get mappeStimmenEmpty =>
      'Nog geen tips bij jouw tochten. Na delen kunnen anderen schrijven.';

  @override
  String get myRoutesSourceOwn => 'Eigen';

  @override
  String get privacyZoneTitle => 'Privacyzone';

  @override
  String get privacyZoneEdit => 'Zone bewerken';

  @override
  String get privacyZoneInvalidCoords => 'Voer geldige coördinaten in';

  @override
  String get privacyZoneNeedTap => 'Tik eerst op de kaart';

  @override
  String get privacyZoneTapShort => 'Tik op de kaart';

  @override
  String get retry => 'Opnieuw';

  @override
  String get hofSystemStatus => 'Systeemstatus';

  @override
  String get hofSystemOk =>
      'Alles verbonden — werkplaats, ritten en sync lopen normaal.';

  @override
  String get hofSupabaseMissing => 'Supabase niet geconfigureerd';

  @override
  String get hofSupabaseMissingHint =>
      'Cloudsync is niet ingesteld — inloggen en sync staan uit.';

  @override
  String get hofSyncSessionExpired => 'Sync: sessie verlopen';

  @override
  String get hofSyncLoginOnly => 'Sync alleen met login';

  @override
  String get hofSyncLocalHint =>
      'Garage/ritten blijven lokaal — account voor cloudsync.';

  @override
  String get hofSystemNotice => 'Systeemstatus — melding aanwezig';

  @override
  String get hofSystemHint => 'Systeemstatus — melding';

  @override
  String get hofSystemOkTooltip => 'Systeemstatus: oké';

  @override
  String get hofTafelTitle => 'Open';

  @override
  String get hofTafelHint => 'Een tip of een groep — geen feed.';

  @override
  String hofTafelVoiceOne(String name) {
    return 'Nieuwe tip bij $name';
  }

  @override
  String hofTafelVoices(int count, String name) {
    return '$count tips bij $name';
  }

  @override
  String hofTafelGroup(String title) {
    return 'Groep · $title';
  }

  @override
  String ridePuckSemantics(String name) {
    return 'Navigatie, $name';
  }

  @override
  String dieBoxSentenceHome(String name) {
    return '$name woont hier';
  }

  @override
  String get dieBoxLater => 'Later';

  @override
  String dieBoxSentenceMtbReady(String name, String travel, String drive) {
    return '$name · $travel$drive · klaar';
  }

  @override
  String dieBoxSentenceReadyBits(String name, String bits) {
    return '$name · $bits · klaar';
  }
}
