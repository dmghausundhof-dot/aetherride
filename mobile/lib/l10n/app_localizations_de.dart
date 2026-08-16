// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'FlowLine';

  @override
  String get appTagline =>
      'Ride further. Flow better — MTB, Gravel, Rennrad, City & E-Bike.';

  @override
  String get navHome => 'Home';

  @override
  String get navGarage => 'Garage';

  @override
  String get navRide => 'Fahren';

  @override
  String get navDiscover => 'Touren';

  @override
  String get navParts => 'Teile';

  @override
  String get navKarte => 'Karte';

  @override
  String get navWorkshop => 'Werkstatt';

  @override
  String get navShop => 'Laden';

  @override
  String get navPlatz => 'Platz';

  @override
  String get hofJustRide => 'Einfach fahren';

  @override
  String get hofShowTours => 'Touren anzeigen';

  @override
  String get hofMapChoiceHint =>
      'Ohne Touren losfahren, oder Touren auf der Karte zeigen.';

  @override
  String get werkstattPartsShelf => 'Shop';

  @override
  String get werkstattForYourBike => 'Für dein Rad';

  @override
  String get werkstattMerch => 'Merchandise';

  @override
  String get werkstattShopParts => 'Ersatzteile im Shop';

  @override
  String get shopGatewayKicker => 'Über den Hof';

  @override
  String get shopGatewayTitle => 'Der Laden';

  @override
  String get shopGatewayHint =>
      'Hier wohnt das Rad nicht. FlowLine zeigt ehrliche Teile — Kauf und Kasse bei Shopify, nicht in der App.';

  @override
  String get shopZumShop => 'Zum Shop';

  @override
  String shopForYourBikeHint(String name) {
    return 'Ersatzteile passend zu $name — Kategorie und Laufrad. Keine erfundenen SKUs.';
  }

  @override
  String get shopForYourBikeEmpty =>
      'Stell ein Rad in der Werkstatt ab — dann öffnen wir die passenden Teile im Shop.';

  @override
  String get shopMerchHint =>
      'Kleidung und Kleinzeug. Unabhängig vom Rad, nie nach Fit gefiltert.';

  @override
  String get shopNotConnected => 'Shop nicht verbunden';

  @override
  String get shopNotConnectedHint =>
      'Keine Storefront-URL. SHOPIFY_STOREFRONT_URL setzen, dann führt dieser Tab in den Laden.';

  @override
  String get shopOpenFailed => 'Shop konnte nicht geöffnet werden.';

  @override
  String get shopPasswordWall =>
      'Der Shopify-Shop ist noch Inhaber-Vorschau (Dev-Store). Externe Links können zur Passwort-Seite führen. Katalog kann hier in FlowLine stehen.';

  @override
  String get shopLockedTitle => 'Online Store gesperrt';

  @override
  String get shopPasswordConfirm => 'Trotzdem öffnen';

  @override
  String get shopPasswordCancel => 'Zurück';

  @override
  String get shopCyclingParts => 'CYCLING PARTS';

  @override
  String get shopSearchHint => 'Teile, Marken, Specs…';

  @override
  String get shopFeatured => 'Passende Teile';

  @override
  String get shopOpenProduct => 'Im Shop öffnen';

  @override
  String get shopAllParts => 'Alle Teile';

  @override
  String shopFitBanner(String name) {
    return 'Teile passend zu $name';
  }

  @override
  String get shopShelfEmpty => 'Keine Teile zu dieser Suche.';

  @override
  String get shopCatalogEmpty =>
      'Noch keine Teile im Regal. Der Laden bleibt die Tür zu Shopify.';

  @override
  String get shopFitOnly => 'Nur passende';

  @override
  String get shopFitAllBikes => 'Alle Räder';

  @override
  String get shopFitBannerAll => 'Teile passend zu deinen Rädern';

  @override
  String get shopOpenInBrowser => 'Im Browser öffnen';

  @override
  String get shopZumHaendler => 'Zum Händler';

  @override
  String get shopOpenInApp => 'Im Laden ansehen';

  @override
  String get shopProductMissing => 'Dieses Produkt liegt nicht im Laden.';

  @override
  String get shopCatalogFailed =>
      'Katalog gerade nicht erreichbar. Der Laden bleibt die Tür zu Shopify.';

  @override
  String get shopRetry => 'Erneut laden';

  @override
  String get shopSheetCheckout =>
      'Kauf und Kasse bei Shopify, nicht in FlowLine.';

  @override
  String get shopDetails => 'Details';

  @override
  String get shopFeaturedBikes => 'Räder im Laden';

  @override
  String get garageSetupTabHintTires =>
      'Luftdruck grob nach Gewicht und Reifen — am Rad nachmessen, keine OEM-Tabelle.';

  @override
  String get werkstattSetupTires => 'Reifen / Druck grob';

  @override
  String get werkstattSetupSuspension =>
      'Fahrwerk — SAG und Luft nach Federweg';

  @override
  String get werkstattSetupSuspensionUnknown =>
      'Fahrwerk — Federweg nicht eingetragen';

  @override
  String get werkstattSetupDropper => 'Vario-Stütze (eingetragen)';

  @override
  String werkstattSetupWheel(String size) {
    return 'Laufrad $size';
  }

  @override
  String get werkstattSetupCockpit => 'Cockpit — Lenker und Vorbau';

  @override
  String get werkstattSetupBagsCockpit => 'Taschen / Cockpit';

  @override
  String get werkstattSetupLightsRack =>
      'Licht und Gepäckträger — nur wenn eingetragen';

  @override
  String get werkstattSetupDrivetrain => 'Schaltung';

  @override
  String get werkstattBatteryHonest => 'Akku nur mit echtem Sensor';

  @override
  String get werkstattBatteryHonestHint =>
      'Kein Prozent ohne gekoppelten Sensor. Bosch LDI bleibt G-1.';

  @override
  String get werkstattSensorEbike =>
      'Radsensor (CSC) — Tempo und Trittfrequenz. Akku-Stand nur mit echtem Sensor.';

  @override
  String get werkstattSensorAnalog =>
      'Radsensor — Tempo und Trittfrequenz am Rad.';

  @override
  String get hofYourWatch => 'Deine Uhr';

  @override
  String get hofWatchHint => 'Puls nur mit echtem Sensor.';

  @override
  String get hofWatchPair => 'Uhr koppeln';

  @override
  String get hofWatchReconnect => 'Verbinden';

  @override
  String get hofWatchRemove => 'Entfernen';

  @override
  String get hofWatchConnect => 'Uhr verbinden';

  @override
  String get hofYou => 'Du';

  @override
  String get hofYouSheetHint =>
      'Du und deine Uhr. Der Radsensor bleibt am Rad in der Werkstatt.';

  @override
  String get werkstattWatchEbike =>
      'Smartwatch — Puls neben CSC. Kein erfundener SoC.';

  @override
  String get werkstattWatchAnalog => 'Smartwatch / Fitnesstracking';

  @override
  String get setupTirePressureLabel => 'Vorderreifen (psi)';

  @override
  String get setupCompareHintTires =>
      'Legt zwei verdeckte Reifendrücke an. Nach ein paar Fahrten siehst du, welcher sich besser anfühlt.';

  @override
  String setupTirePressureValue(String value) {
    return 'Reifen $value psi';
  }

  @override
  String get searchHome => 'Wohin willst du? Ort, Tour oder Adresse';

  @override
  String get startRide => 'Fahrt starten';

  @override
  String get startFreeride => 'Ohne Route fahren';

  @override
  String get startWithRoute => 'Route fahren';

  @override
  String get goRide => 'Losfahren';

  @override
  String get readyTitle => 'Bereit zum Fahren';

  @override
  String get readyMessage =>
      'GPS-Track startet sofort. Sensoren und Route sind optional — egal ob Trail, Asphalt oder City.';

  @override
  String get optionalRoute =>
      'Optional: unter Touren eine Route wählen und „Losfahren“.';

  @override
  String get starting => 'Startet…';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String errorPrefix(String error) {
    return 'Fehler: $error';
  }

  @override
  String get discoverMenuPhotos => 'Umgebungsfotos';

  @override
  String get discoverMenuOffline => 'Offline-Karten';

  @override
  String get discoverMenuCollections => 'Sammlungen';

  @override
  String get discoverMenuPrivacy => 'Heatmap & Privatsphäre';

  @override
  String get partsTitle => 'Teile & Zubehör';

  @override
  String get partsSubtitle =>
      'Live featured-parts in FlowLine — Soft-Fit & Preise, ohne Shopify-Passwort-Dead-End.';

  @override
  String get weatherFallback => 'Wetter nicht verfügbar';

  @override
  String get weatherLoading => 'Wetter wird geladen…';

  @override
  String get statsRidesOne => 'Fahrt';

  @override
  String get statsRidesMany => 'Fahrten';

  @override
  String get profile => 'Profil';

  @override
  String get chat => 'Chat';

  @override
  String get hofRideOut => 'Rausfahren';

  @override
  String get hofOpenBike => 'Rad öffnen';

  @override
  String get hofParkBike => 'Rad abstellen';

  @override
  String get hofRideWithoutBike => 'Ohne Rad fahren';

  @override
  String get hofRideOutAgain => 'Noch mal raus';

  @override
  String get hofAtGate => 'vor dem Tor';

  @override
  String get hofEmptyStand => 'Leerer Stand';

  @override
  String get hofSkyUnknown => 'Himmel unbekannt';

  @override
  String get hofNoHonestLoop => 'Kein ehrlicher Trail-Rundkurs';

  @override
  String get hofNotYetOut => 'noch nicht draußen';

  @override
  String get hofJustBack => 'gerade reingekommen';

  @override
  String hofAgoMinutes(int minutes) {
    return 'vor $minutes min';
  }

  @override
  String hofAgoHours(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String get hofWhatCameIn => 'Was reinkam';

  @override
  String hofPackMissing(String name) {
    return 'Pack für $name fehlt';
  }

  @override
  String get hofLastRideNoGps => 'ohne GPS-Track — kein erfundener Verlauf';

  @override
  String get hofGpsUnknown => 'Kein Standort — Himmel und Tor warten auf GPS.';

  @override
  String get rideGpsUnavailable =>
      'Kein GPS — Track bleibt leer. Kein erfundener Verlauf.';

  @override
  String get hofAtHof => 'am Hof';

  @override
  String hofGarageType(String type) {
    return 'Typ $type';
  }

  @override
  String get hofSinceOneDay => 'seit 1 Tag';

  @override
  String hofSinceDays(int days) {
    return 'seit $days Tagen';
  }

  @override
  String get hofNoBikeHere => 'Kein Rad steht hier';

  @override
  String hofBringForward(String name) {
    return '$name nach vorn';
  }

  @override
  String hofCareInWorkshop(String label) {
    return '$label — in der Werkstatt';
  }

  @override
  String get hofSensorAwake => 'Sensor wach';

  @override
  String get hofOpenTours => 'Touren öffnen';

  @override
  String hofSkyDry(String temp) {
    return '$temp° · eher trocken';
  }

  @override
  String hofSkyDamp(String temp) {
    return '$temp° · feucht möglich';
  }

  @override
  String hofSkyWet(String temp) {
    return '$temp° · Regen · Trails eher nass';
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
  String get hofGateAwayNear => 'unter 1 km';

  @override
  String hofCommunityNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stimmen zu dieser Runde',
      one: '1 Stimme zu dieser Runde',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMtb => 'Trails, Touren & dein Setup';

  @override
  String get homeSubtitleGravel => 'Schotter, Distanz & Navigation';

  @override
  String get homeSubtitleRoad => 'Asphalt, Tempo & Training';

  @override
  String get homeSubtitleUrban => 'Pendeln, Stadt & Alltag';

  @override
  String get homeSubtitleEbike => 'Assist, Reichweite & Touren';

  @override
  String get homeSubtitleDefault =>
      'Jede Art zu fahren — dein Rad, deine Route';

  @override
  String homeSubtitleWithWeather(String weather, String base) {
    return '$weather · $base';
  }

  @override
  String get tipHeroTitleMtb => 'Heute raus aufs Rad';

  @override
  String get tipHeroTitleGravel => 'Heute Schotter oder Mix';

  @override
  String get tipHeroTitleRoad => 'Heute Asphalt-Kilometer';

  @override
  String get tipHeroTitleUrban => 'Heute durch die Stadt';

  @override
  String get tipHeroTitleEbike => 'Heute mit Assist unterwegs';

  @override
  String get tipHeroTitleDefault => 'Heute passt eine Fahrt';

  @override
  String get tipHeroSubtitleMtb =>
      'Route wählen oder einfach freifahren — Track lokal.';

  @override
  String get tipHeroSubtitleGravel =>
      'Plane eine Distanz oder starte ohne Route.';

  @override
  String get tipHeroSubtitleRoad =>
      'Runde bauen oder freies Training aufzeichnen.';

  @override
  String get tipHeroSubtitleUrban =>
      'Pendeln tracken oder kurze Runde speichern.';

  @override
  String get tipHeroSubtitleEbike =>
      'Tour planen und Reichweite im Blick behalten.';

  @override
  String get tipHeroSubtitleDefault =>
      'MTB, Gravel, Rennrad oder City — alles hier.';

  @override
  String get chassisLayer => 'Fahrwerk';

  @override
  String get sensorLayer => 'Sensorik';

  @override
  String get filter => 'Filter';

  @override
  String get filterReset => 'Zurücksetzen';

  @override
  String get filterResetFilters => 'Filter zurücksetzen';

  @override
  String get filterDurationLens => 'Dauer';

  @override
  String get filterSurfaceGroup => 'Untergrund';

  @override
  String get filterExertion => 'Schwierigkeit';

  @override
  String get filterDistance => 'Distanz';

  @override
  String get filterElevation => 'Höhenmeter';

  @override
  String get filterForm => 'Form';

  @override
  String get filterFormAll => 'Alle';

  @override
  String get filterFormPointToPoint => 'A→B';

  @override
  String get filterFormPointToPointTooltip =>
      'Etappen und lineare Trails (Start≠Ziel).';

  @override
  String get filterFormDownhill => 'Downhill';

  @override
  String get filterFormDownhillTooltip =>
      'Abfahrten, Bikepark, Enduro A→B. Rundkurse nicht automatisch DH.';

  @override
  String get filterBikeType => 'Fahrradtyp';

  @override
  String get filterBikeTypeHonesty =>
      'Farben filtern Touren. Navigation: Fahrrad (GraphHopper Basic), außer Zu Fuß.';

  @override
  String get filterSingletrail => 'Singletrail (S-Skala)';

  @override
  String get filterSingletrailHint =>
      'Nur Touren/Wege mit ehrlicher Skala. Ohne Tag: keine Treffer.';

  @override
  String get filterNoDownhillTours => 'Keine Downhill-Touren in der Nähe';

  @override
  String get filterNoDownhillToursHint =>
      'OSM-Trails nach S-Skala bleiben auf der Karte. Katalog hat hier keine DH-Runde.';

  @override
  String get filterNoScaleTours => 'Keine Tour mit dieser S-Stufe';

  @override
  String get filterTrailNetwork => 'Trailnetz (Karte)';

  @override
  String get filterLoopsOnly => 'Rundkurs';

  @override
  String get filterLoopsOnlyTooltip =>
      'Nur ehrliche Rundkurse (Start≈Ziel). Keine A→B-Füllung.';

  @override
  String get filterNetworkOn => 'Netz an';

  @override
  String get filterNetworkOff => 'Netz aus';

  @override
  String filterOsmScaleTooltip(String code) {
    return 'OSM-Skala: $code';
  }

  @override
  String filterShowTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Touren zeigen',
      one: '1 Tour zeigen',
    );
    return '$_temp0';
  }

  @override
  String get filterNoTours => 'Keine Tour bei diesen Filtern.';

  @override
  String get filterNoToursHint =>
      'Keine Touren — „Neu“ tippen oder Filter lockern.';

  @override
  String get loopLabel => 'Rundkurs';

  @override
  String get computeRoute => 'Route berechnen';

  @override
  String get adaptTour => 'Anpassen';

  @override
  String get adaptTourTitle => 'Tour anpassen';

  @override
  String get adaptTourHint =>
      'Start, Ziel oder Stopp ändern — dann Route berechnen.';

  @override
  String get planRouteTitle => 'Route planen';

  @override
  String get planRouteCta => '+ Planen';

  @override
  String get discoverSearchHint => 'Ort oder Tour';

  @override
  String filterAroundKm(int km) {
    return 'in $km km';
  }

  @override
  String get mapToggleFab => 'Karte';

  @override
  String get communityWriteReview => 'Bewertung schreiben';

  @override
  String get discoverModeExplore => 'Entdecken';

  @override
  String get discoverModeNavigate => 'Navigieren';

  @override
  String get discoverModeMine => 'Meine';

  @override
  String get navigateTitle => 'Navigieren';

  @override
  String get navigateSubtitle => 'Ziel tippen oder Adresse — dann berechnen';

  @override
  String get navigateStartLabel => 'Start';

  @override
  String get navigateEndLabel => 'Ziel';

  @override
  String get navigateStartHint => 'Adresse, Ort oder Tippen';

  @override
  String get navigateEndHint => 'Wohin willst du?';

  @override
  String get navigateMyLocation => 'Mein Standort';

  @override
  String get navigateSwap => 'Start und Ziel tauschen';

  @override
  String get navigatePickStart => 'Start auf Karte';

  @override
  String get navigatePickEnd => 'Ziel auf Karte';

  @override
  String get navigateAddVia => 'Via';

  @override
  String get navigateNeedStartEnd => 'Start und Ziel setzen';

  @override
  String get navigateComputeNeedBoth => 'Route berechnen (Start & Ziel nötig)';

  @override
  String get navigateBackToExplore => 'Zurück zu Entdecken';

  @override
  String get mineSheetHint =>
      'Deine Aufzeichnungen, Importe und gespeicherten Strecken';

  @override
  String get mineEmptyCtaNavigate => 'Route von A nach B';

  @override
  String get gpxImportAction => 'GPX importieren';

  @override
  String get exploreOpenNavigate => 'A→B navigieren';

  @override
  String get sheetDragHandleMine => 'Meine-Strecken-Leiste ziehen';

  @override
  String get sheetDragHandleNavigate => 'Navigations-Leiste ziehen';

  @override
  String get browseMap => 'Karte';

  @override
  String get browseList => 'Liste';

  @override
  String get quickFilter1h => '1 Std';

  @override
  String get sheetDragHandle => 'Touren-Leiste ziehen';

  @override
  String get sheetPeekHint => 'Nach oben ziehen — Touren & Filter';

  @override
  String get rideBarCollapseHint => 'Nach unten ziehen zum Einklappen';

  @override
  String get rideBarExpandHint => 'Öffnen';

  @override
  String get rideBarStart => 'Losfahren';

  @override
  String get rideBarRoute => 'Strecke';

  @override
  String get rideBarPointToPoint => 'Strecke';

  @override
  String get emptyToursTitle => 'Keine Touren gefunden';

  @override
  String get emptyToursFiltersBody =>
      'Filter zurücksetzen — dann siehst du wieder Touren in der Nähe.';

  @override
  String get emptyToursNearbyBody =>
      'Ort oder Dauer anpassen — oder Filter zurücksetzen. Keine A→B-Füllung.';

  @override
  String get showOnMap => 'Auf Karte';

  @override
  String get tourDetails => 'Details';

  @override
  String get moreFilters => 'Mehr Filter';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get filterSurfaceAsphalt => 'Asphalt';

  @override
  String get filterSurfaceGravel => 'Schotter';

  @override
  String get filterSurfaceTrail => 'Trail';

  @override
  String get filterSurfaceMixed => 'Gemischt';

  @override
  String get filterSurfaceAsphaltHint => 'Asphalt · Radweg · befestigt';

  @override
  String get filterSurfaceGravelHint => 'Schotter · Forst · verdichtet';

  @override
  String get filterSurfaceTrailHint => 'Naturboden · Singletrail · Wurzel';

  @override
  String get filterSurfaceMixedHint => 'Stadt · gemischter Belag';

  @override
  String get filterSurfaceAsphaltFull => 'Asphalt · befestigt';

  @override
  String get filterSurfaceGravelFull => 'Schotter · verdichtet';

  @override
  String get filterSurfaceTrailFull => 'Naturboden · Trail';

  @override
  String get filterSurfaceMixedFull => 'Stadt · gemischt';

  @override
  String get filterEffortEasy => 'Leicht';

  @override
  String get filterEffortMid => 'Mittel';

  @override
  String get filterEffortHard => 'Anspruchsvoll';

  @override
  String get filterEffortEasyHint => 'S0 / entspannt / wenig Technik';

  @override
  String get filterEffortMidHint => 'S1–S2 / sportlich / gemischt';

  @override
  String get filterEffortHardHint => 'S2+ / schwer / technisch';

  @override
  String get filterElevFlat => '< 400 hm';

  @override
  String get filterElevHilly => '400–1100 hm';

  @override
  String get filterElevAlpine => '1100+ hm';

  @override
  String get filterDistMax20 => '≤ 20 km';

  @override
  String get filterDistMax40 => '≤ 40 km';

  @override
  String get filterDistMax70 => '≤ 70 km';

  @override
  String get filterScaleEasy => 'Leicht';

  @override
  String get filterScaleMedium => 'Mittel';

  @override
  String get filterScaleHard => 'Anspruchsvoll';

  @override
  String get trailDiffEasy => 'Leicht';

  @override
  String get trailDiffMedium => 'Mittel';

  @override
  String get trailDiffHard => 'Schwer';

  @override
  String get trailDiffVeryHard => 'Sehr schwer';

  @override
  String get trailDiffUnrated => 'Nicht eingestuft';

  @override
  String get trailDiffOpen => 'offen';

  @override
  String get durationAny => 'egal';

  @override
  String get duration2to3h => '2–3 h';

  @override
  String get garageTitle => 'Garage';

  @override
  String get garageFabBike => 'Rad anlegen';

  @override
  String get garageEmptyTitle => 'Noch kein Rad hier';

  @override
  String get garageEmptyMessage =>
      'Name und Typ reichen. Katalog ist Suche — Serienteile nur wenn du sie übernimmst.';

  @override
  String get garageAddBike => 'Rad anlegen';

  @override
  String get garageAddAnother => 'Weiteres Rad';

  @override
  String get garageStatBike => 'RAD';

  @override
  String get garageStatBikes => 'RÄDER';

  @override
  String get garageStatKmTotal => 'KM GESAMT';

  @override
  String get garageQuickSwitch => 'Schnellwechsel';

  @override
  String get garageLastRides => 'Letzte Fahrten';

  @override
  String get garageNoRidesTitle => 'Noch keine Fahrten';

  @override
  String get garageNoRidesMessage =>
      'Deine erste gespeicherte Fahrt erscheint hier.';

  @override
  String get garageActive => 'Aktiv';

  @override
  String garageActiveBike(String name) {
    return 'Aktives Bike · $name';
  }

  @override
  String get garageEbikeBadge => 'E-Bike';

  @override
  String get garageMaintOk => 'Alles in Ordnung';

  @override
  String garageMaintDue(int count) {
    return '$count Wartung fällig';
  }

  @override
  String garageMaintOverdue(int count) {
    return '$count überfällig';
  }

  @override
  String garagePartsCount(int count) {
    return '$count Teile';
  }

  @override
  String get garageParts => 'Teile';

  @override
  String get garageMaintenance => 'Wartung';

  @override
  String get garageSetup => 'Setup';

  @override
  String get garageInstall => 'Teil hinzufügen';

  @override
  String get garageOtherBikes => 'Weitere Räder';

  @override
  String get garageTechDetails => 'Technische Details';

  @override
  String get garageTechHint => 'Federweg, Rahmen, Setup-Basics — für Amateure';

  @override
  String get garageCtaMaintenance => 'Wartung ansehen';

  @override
  String get garageCtaAddPart => 'Teil hinzufügen';

  @override
  String get garageCtaSetActive => 'Als aktiv setzen';

  @override
  String get garageCtaOpenSetup => 'Zum Setup';

  @override
  String get garageHours => 'Stunden';

  @override
  String get garageTravel => 'Federweg';

  @override
  String get garageFrameSize => 'Rahmengröße';

  @override
  String get garageWheelSize => 'Laufrad';

  @override
  String get garageBrandModel => 'Modell';

  @override
  String garageCompatFits(int count) {
    return 'Passt $count';
  }

  @override
  String garageCompatCheck(int count) {
    return 'Prüfen $count';
  }

  @override
  String garageCompatNoFit(int count) {
    return 'Passt nicht $count';
  }

  @override
  String get garagePartsEmpty =>
      'Noch keine Teile erfasst. Tippe auf „Teil hinzufügen“, dann erinnern wir dich an Wartung und zeigen, ob Teile zusammenpassen.';

  @override
  String get garageMaintEmpty =>
      'Alles im grünen Bereich — keine Wartung fällig.';

  @override
  String get garageSetupTabTitle => 'Dein Setup';

  @override
  String get garageSetupTabHint =>
      'SAG = wie weit die Federung mit deinem Gewicht einsinkt (Richtwert oft ~25–30 %).';

  @override
  String get garageYourParts => 'Deine Teile';

  @override
  String get garageMissingSlots => 'Noch nicht erfasst (optional)';

  @override
  String get garageActiveBadge => 'Aktives Bike';

  @override
  String get garageStatKm => 'KM';

  @override
  String get garageStatHours => 'STD.';

  @override
  String get garageStatMaint => 'WARTUNG';

  @override
  String get setupVersionsTitle => 'Versionen & Vergleich';

  @override
  String get setupVersionsHint =>
      'Jede Änderung speichert eine neue Version. Du kannst jederzeit zurückwechseln.';

  @override
  String get setupRiderWeightLabel => 'Fahrergewicht (kg) für Vorlagen';

  @override
  String get setupNewVersionCta => 'Neue Version';

  @override
  String get setupCompareCta => 'Zwei Varianten testen';

  @override
  String get setupCompareHint =>
      'Legt zwei verdeckte Varianten an (z. B. Zugstufe). Nach ein paar Fahrten siehst du, welche sich besser anfühlt.';

  @override
  String get setupSavedVersions => 'Gespeicherte Versionen';

  @override
  String get setupEmpty =>
      'Noch keine Version — starte mit einer Vorlage oder speichere deine Einstellungen.';

  @override
  String get setupActiveBadge => 'Aktiv';

  @override
  String setupVersionMeta(int version) {
    return 'Version $version';
  }

  @override
  String get setupUseVersion => 'Nutzen';

  @override
  String setupForkReboundValue(String value) {
    return 'Zug $value';
  }

  @override
  String get setupSourceTemplate => 'Vorlage';

  @override
  String get setupSourceBaseline => 'Basis';

  @override
  String get setupSourceManual => 'Manuell';

  @override
  String get setupTemplatesTitle => 'Vorlagen zum Start';

  @override
  String get setupTemplatesHint =>
      'Ausgangspunkt — keine persönliche Empfehlung.';

  @override
  String get setupApplyTemplate => 'Übernehmen';

  @override
  String get setupNewVersionTitle => 'Neue Setup-Version';

  @override
  String get setupNewVersionHint =>
      'Gib der Version einen Namen, den du wiedererkennst — z. B. „Trail trocken“.';

  @override
  String get setupVersionNameLabel => 'Name';

  @override
  String get setupForkReboundLabel => 'Gabel Zugstufe (Klicks)';

  @override
  String get setupCancel => 'Abbrechen';

  @override
  String get setupSave => 'Speichern';

  @override
  String setupNewVersionDefaultName(int n) {
    return 'Version $n';
  }

  @override
  String get setupManualFallback => 'Manuell';

  @override
  String setupTemplateAppliedLabel(String label) {
    return '$label (Vorlage)';
  }

  @override
  String setupTemplateAppliedSnack(String disclaimer) {
    return 'Vorlage übernommen — $disclaimer';
  }

  @override
  String get setupCompareVariantA => 'Testvariante A';

  @override
  String get setupCompareVariantB => 'Testvariante B';

  @override
  String setupCompareResultFromRides(int count, String summary) {
    return 'Varianten angelegt · Auswertung aus $count Fahrten: $summary';
  }

  @override
  String setupCompareResultDemo(String summary) {
    return 'Varianten angelegt · noch wenig Fahr-Feedback — Beispiel-Auswertung: $summary';
  }

  @override
  String get rideMap => 'Karte';

  @override
  String get rideData => 'Daten';

  @override
  String get rideLiveData => 'Live-Daten';

  @override
  String get rideMapReady => 'Karte bereit — Sensor optional nach Start';

  @override
  String get rideClearRoute => 'Route entfernen';

  @override
  String get postRideTitle => 'Aktivität';

  @override
  String get postRideFreeride => 'Freeride';

  @override
  String get postRideTrackMap => 'Gefahrener Track';

  @override
  String get postRideNoTrack => 'Kein GPS-Track — Karte zeigt keinen Verlauf.';

  @override
  String get postRideStatDistance => 'Distanz';

  @override
  String get postRideStatDuration => 'Dauer';

  @override
  String get postRideStatPace => 'Tempo';

  @override
  String get postRideStatElevation => 'Höhenmeter';

  @override
  String get postRideWeatherTitle => 'Wetter';

  @override
  String get postRideWeatherStart => 'Start';

  @override
  String get postRideWeatherEnd => 'Ende';

  @override
  String get postRideWeatherUnavailable => 'Wetter nicht verfügbar';

  @override
  String get postRidePhotosTitle => 'Fotos';

  @override
  String get postRidePhotosHint =>
      'Bilder zur Fahrt hinzufügen — lokal gespeichert.';

  @override
  String get postRidePhotoCamera => 'Kamera';

  @override
  String get postRidePhotoGallery => 'Galerie';

  @override
  String get postRidePhotosShare => 'Teilen';

  @override
  String get postRidePhotosShareText => 'Meine FlowLine-Fahrt';

  @override
  String get postRidePhotosEmpty => 'Noch keine Fotos zum Teilen';

  @override
  String postRidePhotosMax(int count) {
    return 'Maximal $count Fotos';
  }

  @override
  String get postRideCommunityStub =>
      'Fotos bleiben lokal. Stimmen hängen an der Tour, nicht in einem Feed.';

  @override
  String get postRideOpenTour => 'Tour öffnen';

  @override
  String get postRideSaveAsTour => 'Als Tour speichern';

  @override
  String get postRideSaveAsTourDone => 'In Meine Strecken gespeichert';

  @override
  String get postRideSaveAsTourNeedTrack =>
      'Zum Speichern braucht es einen GPS-Track.';

  @override
  String get postRideSaveAsTourHint =>
      'Speichert den Track als eigene Strecke (Import/Recorded) — sichtbar in Touren.';

  @override
  String get myRoutesTitle => 'Meine Strecken';

  @override
  String get myRoutesEmpty =>
      'Noch keine eigenen Strecken — GPX importieren oder eine Fahrt aufzeichnen.';

  @override
  String get myRoutesSourceImport => 'Import';

  @override
  String get myRoutesSourceRecorded => 'Aufgezeichnet';

  @override
  String get myRoutesSourceEngine => 'Geplant';

  @override
  String get myRoutesShowOnMap => 'Eigene auf Karte';

  @override
  String get myRoutesHideOnMap => 'Eigene ausblenden';

  @override
  String get myRouteNotesTitle => 'Private Notiz';

  @override
  String get myRouteNotesHint =>
      'Nur für dich. Öffentliche Stimmen erst nach Freigabe, unter Stimmen.';

  @override
  String get myRouteNotesEmpty => 'Noch keine Notiz.';

  @override
  String get myRouteNotesPlaceholder => 'Nur für dich — keine Stimme.';

  @override
  String get myRouteNotesAdd => 'Speichern';

  @override
  String get myRouteDetailPhotos => 'Fotos';

  @override
  String get myRouteOpenDetail => 'Details';

  @override
  String collectionRouteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Routen · tippen zum Öffnen',
      one: '1 Route · tippen zum Öffnen',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get skip => 'Überspringen';

  @override
  String get next => 'Weiter';

  @override
  String get onLabel => 'An';

  @override
  String get offLabel => 'Aus';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get account => 'Konto';

  @override
  String get register => 'Registrieren';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get share => 'Teilen';

  @override
  String get done => 'Erledigt';

  @override
  String get authSignedInSyncing => 'Angemeldet — synchronisiere…';

  @override
  String authSignedInSyncFailed(String error) {
    return 'Angemeldet. Sync: $error';
  }

  @override
  String get authCloudUnavailable => 'Cloud-Sync ist gerade nicht verfügbar.';

  @override
  String get authEmailPasswordRequired =>
      'E-Mail und Passwort (min. 8 Zeichen) nötig.';

  @override
  String get authAccountCreatedConfirm =>
      'Konto erstellt — ggf. E-Mail bestätigen, dann anmelden.';

  @override
  String get authSupabaseMissing => 'Supabase nicht konfiguriert.';

  @override
  String get authBrowserOpened =>
      'Browser geöffnet — nach Login kehrst du automatisch zurück.';

  @override
  String get authDeleteTitle => 'Konto löschen?';

  @override
  String get authDeleteBody =>
      'Remote-Konto und lokale App-Daten werden gelöscht. Exportiere vorher GPX/JSON unter Daten & Privatsphäre.';

  @override
  String get authRemoteDeleted => 'Remote-Konto gelöscht.';

  @override
  String get authRemoteUnavailable =>
      'Remote-Löschung nicht verfügbar — nur lokale Daten entfernt.';

  @override
  String authRemoteFailed(int code) {
    return 'Remote-Löschung fehlgeschlagen ($code) — lokal trotzdem gelöscht.';
  }

  @override
  String get authRemoteUnreachable =>
      'Server nicht erreichbar — nur lokale Daten entfernt.';

  @override
  String get authLocalDeleted =>
      'Lokale Daten gelöscht. Export ggf. unter Privatsphäre nachholen.';

  @override
  String get authEmail => 'E-Mail';

  @override
  String get authEmailHint => 'E-Mail-Adresse';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authHaveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get authNewHere => 'Neu hier? Registrieren';

  @override
  String get authWithGoogle => 'Mit Google';

  @override
  String get authWithApple => 'Mit Apple';

  @override
  String get authPrivacy => 'Daten & Privatsphäre';

  @override
  String get authOpenAssistant => 'Assistent öffnen';

  @override
  String get authDeleteAccount => 'Konto löschen';

  @override
  String get authSyncNow => 'Jetzt synchronisieren';

  @override
  String get authSyncing => 'Synchronisiere…';

  @override
  String get authSyncOk => 'Sync OK';

  @override
  String authSyncActive(String api) {
    return 'Sync mit $api ist aktiv.';
  }

  @override
  String get authCreating => 'Erstelle…';

  @override
  String get authSigningIn => 'Melde an…';

  @override
  String get billingTitle => 'FlowLine Pro';

  @override
  String get billingYouHavePro => 'Du hast Pro.';

  @override
  String get billingFreeToPro => 'Free → Pro';

  @override
  String get billingMoreBikes =>
      'Mehr Bikes, Sync-Vorteile und Offline-Regionen.';

  @override
  String get billingAlreadyPro =>
      'Pro ist bereits aktiv — kein erneuter Kauf nötig.';

  @override
  String get billingForceProDebug =>
      'Debug: Force-Pro. Stripe/Play bleiben ausgeblendet.';

  @override
  String get billingStripeMonth => 'Stripe — monatlich';

  @override
  String get billingStripeYear => 'Stripe — jährlich';

  @override
  String get billingPlayMonth => 'Google Play — monatlich';

  @override
  String get billingPlayRestore => 'Play-Käufe wiederherstellen';

  @override
  String get billingPlayHint =>
      'Hinweis: Ohne GOOGLE_PLAY_SERVICE_ACCOUNT_JSON prüft der Server Käufe nicht gegen Google.';

  @override
  String get billingSyncStatus => 'Abo-Status synchronisieren';

  @override
  String get billingSyncAfterPurchase => 'Nach Kauf synchronisieren';

  @override
  String get billingPleaseSignIn => 'Bitte zuerst anmelden.';

  @override
  String get billingNoCheckoutUrl => 'Keine Checkout-URL';

  @override
  String get billingBrowserFailed => 'Browser konnte nicht geöffnet werden';

  @override
  String get billingCheckoutOpened =>
      'Checkout geöffnet — danach „Sync after purchase“.';

  @override
  String get billingPlayOnlyAndroid => 'Play Billing nur auf Android.';

  @override
  String get billingPlayStarted => 'Play-Kauf gestartet…';

  @override
  String get billingVerifying => 'Kauf wird verifiziert…';

  @override
  String get billingProTrusted =>
      'Pro gesetzt (Trusted-Token-MVP — ohne Google Play Service Account). Sync OK.';

  @override
  String get billingProActive => 'Pro aktiv. Sync läuft.';

  @override
  String get billingRestoring => 'Käufe werden wiederhergestellt…';

  @override
  String get billingRestoreStarted =>
      'Restore gestartet — gültige Abos werden verifiziert.';

  @override
  String billingSyncOkTier(String tier) {
    return 'Sync OK — Tarif: $tier';
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
    return 'Restore: $error';
  }

  @override
  String get chatAssistant => 'Assistent';

  @override
  String get chatWelcome =>
      'Frag mich, was ansteht — oder zu Setup, Routen und Teilen.';

  @override
  String get chatEmptyTitle => 'Frag mich';

  @override
  String get chatEmptyMessage =>
      'Was ansteht, Setup, Routen oder Teile — probier einen Vorschlag oben oder tipp direkt los.';

  @override
  String get chatLockedRiding => 'Während der Fahrt ist Chat gesperrt.';

  @override
  String get chatHint => 'Nachricht…';

  @override
  String get chatHintLocked => 'Gesperrt während Ride';

  @override
  String get chatAsk => 'Fragen';

  @override
  String get chatSnooze7 => '7 Tage still';

  @override
  String get chatNoAnswer => 'Keine Antwort.';

  @override
  String chatNetworkError(String error) {
    return 'Netzwerkfehler: $error';
  }

  @override
  String chatErrorStatus(int code) {
    return 'Fehler $code';
  }

  @override
  String get chatLimitReached => 'Limit erreicht.';

  @override
  String chatQuota(String used, String limit, String remaining) {
    return 'Kontingent: $used / $limit · noch $remaining';
  }

  @override
  String get chatToolDev => 'Werkzeug (Entwickler)';

  @override
  String get chatToolAuto => 'Auto';

  @override
  String get chatPromptWatch => 'Was steht an?';

  @override
  String get chatPromptWatchQuery => 'Was steht an?';

  @override
  String get chatPromptGarage => 'Garage';

  @override
  String get chatPromptGarageQuery => 'Was steckt in meiner Garage?';

  @override
  String get chatPromptRange => 'Reichweite';

  @override
  String get chatPromptRangeQuery =>
      'Welche Reichweite habe ich mit aktuellem Akku?';

  @override
  String get chatPromptSetups => 'Setups';

  @override
  String get chatPromptSetupsQuery =>
      'Welche Setups hatte ich und was hat sich geändert?';

  @override
  String get chatPromptRides => 'Fahrten';

  @override
  String get chatPromptRidesQuery => 'Zusammenfassung meiner letzten Fahrten';

  @override
  String get chatPromptRoutes => 'Routen';

  @override
  String get chatPromptRoutesQuery => 'Welche Routen passen zu mir?';

  @override
  String get chatPromptShop => 'Laden';

  @override
  String get chatPromptShopQuery => 'Brauche ich bald neue Verschleißteile?';

  @override
  String get chatToolWatch => 'Was steht an';

  @override
  String get chatToolGarage => 'Werkstatt';

  @override
  String get chatToolCompat => 'Kompatibilität';

  @override
  String get chatToolRange => 'Reichweite';

  @override
  String get chatToolSetupHistory => 'Setup-Historie';

  @override
  String get chatToolRides => 'Fahrten';

  @override
  String get chatToolRoutes => 'Routen';

  @override
  String get chatToolShop => 'Laden';

  @override
  String get chatSubtitleDue => 'Was ansteht, Setup, Routen, Teile';

  @override
  String coachHintsTooltip(int count) {
    return '$count Hinweise';
  }

  @override
  String get privacyTitle => 'Daten & Privatsphäre';

  @override
  String get privacyConsents => 'Einwilligungen';

  @override
  String get privacyHud => 'HUD';

  @override
  String get privacyZones => 'Privacy-Zonen';

  @override
  String get privacyZoneAdd => 'Zone';

  @override
  String get privacyNoZones =>
      'Keine Zonen — Start/Ziel-Umgebung kann getrimmt werden.';

  @override
  String privacyZoneRadius(String label) {
    return '$label Radius';
  }

  @override
  String get privacyZoneDelete => 'Zone löschen';

  @override
  String get privacyFamilyHint =>
      'Familien-Link / Mitfahrer: unter Profil → Familien-Garage weitere Fahrer mit eigenem Gewicht anlegen.';

  @override
  String get privacyExportTitle => 'Export (Art. 20)';

  @override
  String get privacyExportGpx => 'Letzter Ride als GPX';

  @override
  String get privacyExportFit => 'Letzter Ride als FIT';

  @override
  String get privacyExportJson => 'JSON-Vollexport';

  @override
  String get privacyExportStravaStub => 'Strava-Payload (lokal, Entwickler)';

  @override
  String get privacyStravaConnect => 'Mit Strava verbinden';

  @override
  String get privacyStravaUpload => 'Letzten Ride zu Strava';

  @override
  String get privacyStravaLiveHint =>
      'Live-Upload nutzt gespeicherte OAuth-Tokens (Server).';

  @override
  String get privacyStravaOauthHint =>
      'OAuth öffnet den Browser; nach Freigabe App fortsetzen.';

  @override
  String get privacyStravaMissing =>
      'Strava ist nicht eingerichtet. GPX, FIT und JSON sind die Exportwege.';

  @override
  String get privacyStravaConnected => 'Strava verbunden';

  @override
  String get privacyStravaCallback => 'Strava-Callback empfangen';

  @override
  String privacyStravaStatus(String status) {
    return 'Strava: $status';
  }

  @override
  String get privacyStravaUnreachable =>
      'Strava-Status nicht erreichbar — Stub-Export bleibt lokal';

  @override
  String get privacyStravaUrlMissing =>
      'Strava-Authorize-URL fehlt — einloggen und erneut versuchen.';

  @override
  String get privacyStravaBrowser =>
      'Strava im Browser — nach Freigabe zurück zur App, Status aktualisiert sich.';

  @override
  String get privacyNoRideUpload => 'Kein Ride zum Upload';

  @override
  String privacyChunksUploaded(int n, int left) {
    return '$n Chunk(s) hochgeladen, $left ausstehend';
  }

  @override
  String privacyChunksBlocked(int left) {
    return 'Kein Upload (Login/Netz?) — $left ausstehend';
  }

  @override
  String get privacyChunksNone => 'Keine ausstehenden Chunks';

  @override
  String privacyHeatmapCells(int n) {
    return 'Heatmap: $n Zellen beigetragen (sichtbar erst ab k≥5).';
  }

  @override
  String get privacyHeatmapNone =>
      'Heatmap: kein Beitrag (Login/Consent/Track prüfen).';

  @override
  String get privacyUploadNow => 'Jetzt hochladen';

  @override
  String privacyChunksPending(int count) {
    return 'Rohdaten-Chunks: $count ausstehend';
  }

  @override
  String privacyChunksPendingConsentOff(int count) {
    return 'Rohdaten-Chunks: $count ausstehend (Consent aus)';
  }

  @override
  String privacySharedGpx(String path) {
    return 'GPX geteilt · $path';
  }

  @override
  String privacySharedFit(String path) {
    return 'FIT geteilt · $path';
  }

  @override
  String privacySharedStravaStub(String path) {
    return 'Strava-Stub geteilt · $path';
  }

  @override
  String get privacyExportSubject => 'FlowLine Export';

  @override
  String get privacyNoRideExporting => 'Kein Ride zum Exportieren.';

  @override
  String privacySharedJson(String path) {
    return 'JSON geteilt · $path';
  }

  @override
  String get privacyNoRideExport => 'Kein Ride zum Exportieren.';

  @override
  String get consentRawTitle => 'Rohdaten-Upload';

  @override
  String get consentRawBody =>
      'Sensor-Rohdaten nur bei WLAN und wenn du zustimmst. Jederzeit widerrufbar.';

  @override
  String get consentHeatmapTitle => 'Heatmap (eigene Fahrten, anonym)';

  @override
  String get consentHeatmapBody =>
      'Lokal: deine Fahrten. Mit Konto: anonymisierte Zellen ohne Zeitstempel. Die Beliebtheitskarte erscheint erst, wenn genug Fahrer in einer Zelle unterwegs waren (k≥5).';

  @override
  String get consentRecoTitle => 'Produktempfehlungen';

  @override
  String get consentRecoBody =>
      'Nur anlassbezogen, mit nachvollziehbarem Datenpunkt. Kein Tracking-Marketing.';

  @override
  String get consentAnalyticsTitle => 'Analytics';

  @override
  String get consentAnalyticsBody =>
      'Produktmetriken ohne Gesundheits- oder Rohsensordaten.';

  @override
  String get consentHealthTitle => 'Gesundheitsdaten';

  @override
  String get consentHealthBody =>
      'Vorbereitung — noch keine Anbindung an Health Connect. Die Einwilligung speichert nur deine Präferenz für später.';

  @override
  String get privacyZoneTapHint =>
      'Tippe auf die Karte, um die Zone zu setzen.';

  @override
  String get privacyZoneRadiusHint => 'Radius gilt für Export und Heatmap.';

  @override
  String get privacyZoneLabel => 'Label';

  @override
  String get privacyZoneRadiusWord => 'Radius';

  @override
  String get privacyZoneApplyCoords => 'Koordinaten übernehmen';

  @override
  String get privacyZoneCoords => 'Koordinaten';

  @override
  String get privacyZoneCoordsHint =>
      'Nur falls du den Punkt zahlenbasiert setzen willst';

  @override
  String get profilePictureSet => 'Profilbild gesetzt';

  @override
  String get profileSaved => 'Profil gespeichert';

  @override
  String get profileLocalOnly => 'Nur lokal — zum Sync anmelden';

  @override
  String get profileSyncCloudKept => 'Sync: Cloud übernommen';

  @override
  String get profileSyncDeviceUploaded => 'Sync: Gerät hochgeladen';

  @override
  String get profileSyncCurrent => 'Sync: aktuell';

  @override
  String get profileSyncConflictTitle => 'Sync-Konflikt';

  @override
  String profileSyncConflictBody(String when) {
    return 'Cloud und dieses Gerät unterscheiden sich.\nCloud: $when\n\nWelche Version soll gelten?';
  }

  @override
  String get profileKeepCloud => 'Cloud behalten';

  @override
  String get profileForceDevice => 'Gerät erzwingen';

  @override
  String get profileConflictCloud => 'Konflikt: Cloud behalten';

  @override
  String get profileConflictDevice => 'Konflikt: Gerät erzwingen';

  @override
  String get profileSyncCancelled => 'Sync abgebrochen';

  @override
  String get profileSignInForBilling => 'Bitte anmelden für Aboverwaltung';

  @override
  String get profileNoStripeSub =>
      'Noch kein Stripe-Abo — zuerst Pro upgraden.';

  @override
  String profilePortalError(int code) {
    return 'Portal: $code';
  }

  @override
  String get profileNoPortalUrl => 'Keine Portal-URL';

  @override
  String get profileFamilyRiderTitle => 'Familien-Fahrer';

  @override
  String get profileName => 'Name';

  @override
  String get profileWeightKg => 'Gewicht kg';

  @override
  String get profileRiderAdded => 'Fahrer hinzugefügt';

  @override
  String get profileRiderFallback => 'Fahrer';

  @override
  String profileActiveBike(String name, String category) {
    return 'Aktiv: $name · $category';
  }

  @override
  String get profileDisciplines => 'Deine Disziplinen';

  @override
  String get profileDisciplinesHint =>
      'Vorlieben für Touren. Routing folgt dem aktiven Rad, nicht dieser Liste allein.';

  @override
  String get profileRiderCard => 'Fahrerprofil';

  @override
  String get profilePublic => 'Öffentlich';

  @override
  String get profileAccountSync => 'Konto & Sync';

  @override
  String get profileCloudBilling => 'Cloud-Sync & Abo';

  @override
  String get profileSignedIn => 'Angemeldet';

  @override
  String get profileFamilyGarage => 'Familien-Garage';

  @override
  String get profileFamilyHint =>
      'Weitere Fahrer mit eigenem Gewicht — z. B. Partner oder Kind.';

  @override
  String get profileLegal => 'Rechtliches';

  @override
  String get profilePrivacyPolicy => 'Datenschutz';

  @override
  String get profileImprint => 'Impressum';

  @override
  String get profileWithdrawal => 'Widerruf';

  @override
  String get profileSetPrimary => 'Als Haupt-Disziplin setzen';

  @override
  String profilePrimarySuffix(String label) {
    return '$label · Haupt';
  }

  @override
  String get profileNeedOneDiscipline =>
      'Mindestens eine Disziplin bleibt gewählt.';

  @override
  String get profileLocalUntilSignIn => 'Lokal — Sync nach Anmeldung';

  @override
  String get profileChangePhoto => 'Foto ändern';

  @override
  String get profileActivityLabel => 'Aktivität — letzte Fahrten auf dem Hof';

  @override
  String get profileBikeOne => 'Bike';

  @override
  String get profileBikes => 'Bikes';

  @override
  String get profileRideOne => 'Ride';

  @override
  String get profileRides => 'Rides';

  @override
  String get profileKmTotal => 'km gesamt';

  @override
  String profileKmElevation(int hm) {
    return 'km · $hm hm';
  }

  @override
  String get profileProActive => 'FlowLine Pro aktiv';

  @override
  String get profileManage => 'Verwalten';

  @override
  String get profileProPerks =>
      'Offline-Karten, unbegrenzte Bikes, Fahrwerksanalyse & Bracketing.';

  @override
  String get profileUpgradePro => 'Pro upgraden';

  @override
  String get profileDisplayName => 'Anzeigename';

  @override
  String get profileRiderWeight => 'Fahrergewicht (kg)';

  @override
  String get profileRideStyle => 'Fahrstil';

  @override
  String get profileSkillBeginner => 'Einsteiger';

  @override
  String get profileSkillBasics => 'Grundlagen';

  @override
  String get profileSkillAdvanced => 'Fortgeschritten';

  @override
  String get profileSkillExperienced => 'Erfahren';

  @override
  String get profileSkillPro => 'Profi';

  @override
  String get profileSubGarage => 'Garage';

  @override
  String get profileSubWeight => 'Fahrergewicht';

  @override
  String profileSubSkill(int skill) {
    return 'Können ($skill / 5)';
  }

  @override
  String get profileStyleEfficientPace => 'Effizient / Tempo';

  @override
  String get profileStyleSteady => 'Gleichmäßig';

  @override
  String get profileStyleExploring => 'Entdeckend';

  @override
  String get profileStyleCommute => 'Alltag / Pendeln';

  @override
  String get profileStyleTours => 'Touren';

  @override
  String get profileStyleRelaxed => 'Locker';

  @override
  String get profileStyleAggressive => 'Aggressiv';

  @override
  String get profileStyleFlow => 'Flow';

  @override
  String get profileStyleLines => 'Linien suchen';

  @override
  String get profileStyleEfficient => 'Effizient';

  @override
  String profileDisciplinesSaved(String list) {
    return 'Disziplinen: $list';
  }

  @override
  String profileAlsoList(String list) {
    return 'auch $list';
  }

  @override
  String get publicProfileTitle => 'Öffentliches Profil';

  @override
  String get publicProfileHint =>
      'Opt-in. Handle an Stimmen, keine Tracks, kein Tab.';

  @override
  String get publicProfileHandle => 'Handle';

  @override
  String get publicProfileBio => 'Bio';

  @override
  String get publicProfileRegion => 'Region';

  @override
  String get publicProfileShowRides => 'Fahrtenzahl zeigen';

  @override
  String get publicProfileFoot =>
      'Kein öffentlicher Track, keine DMs. Handle bleibt lokal bis Sync.';

  @override
  String get hudMediaTitle => 'Medien im HUD';

  @override
  String get hudMediaProfileHint =>
      'Optionaler Zugriff, damit das HUD den aktuellen Titel zeigt. Play/Pause geht oft schon ohne.';

  @override
  String get hudMediaPrivacyHint =>
      'Einstellung unter Profil. Optionaler Zugriff auf die Medien-Session für den Titel im HUD.';

  @override
  String get onboardHowYouRide => 'Wie fährst du?';

  @override
  String get onboardYourWeight => 'Dein Gewicht';

  @override
  String get onboardFirstRide => 'Erste Fahrt';

  @override
  String get onboardWeightHint =>
      'Für Setup, SAG & Reichweite — nur lokal, jederzeit änderbar. Auch ohne Federgabel sinnvoll (z. B. City).';

  @override
  String get onboardGpsHint =>
      'Echter GPS-Track — ohne Demo. Bike optional. MTB, Gravel, Rennrad oder City: gleich gut.';

  @override
  String get onboardGpsStatus => 'Standort für GPS-Track…';

  @override
  String get onboardServicesOff =>
      'Ortungsdienste einschalten, dann erneut versuchen.';

  @override
  String get onboardDeniedForever =>
      'Standort in den App-Einstellungen erlauben.';

  @override
  String get onboardNeedGps => 'Standort erlauben — ohne GPS kein Track.';

  @override
  String onboardWeightLabel(int kg) {
    return 'Fahrergewicht: $kg kg';
  }

  @override
  String onboardDiscipline(String label) {
    return 'Disziplin: $label';
  }

  @override
  String get onboardSensorsHint =>
      'Standort für den GPS-Track. Bluetooth-Sensoren später in der Werkstatt — gilt für alle Bike-Typen.';

  @override
  String get onboardNextRide => 'Weiter zur Fahrt';

  @override
  String get onboardParkBikeFirst => 'Zuerst Rad abstellen';

  @override
  String get onboardLater => 'Später einrichten';

  @override
  String get offlineMapsTitle => 'Offline-Karten';

  @override
  String get offlineMapsHint =>
      'Lädt Routing-Graph und Kartenkacheln für die Region. Ohne Netz: geladene Karte + Graph-Routing in der Bounding Box. Valhalla-Kacheln sind noch nicht Teil der Packs.';

  @override
  String get offlineRegionActive => 'Region aktiv';

  @override
  String get offlineNoRegion => 'Keine Region aktiv';

  @override
  String get offlineReadyBoth => 'Routing + Kartenkacheln bereit.';

  @override
  String get offlineReadyRouting =>
      'Routing bereit — Karte noch nicht offline.';

  @override
  String get offlineLoadBelow => 'Unten ein gebautes Pack laden.';

  @override
  String get offlineRegions => 'Regionen';

  @override
  String get offlineSearchRegion => 'Region suchen';

  @override
  String get offlineNoneFound => 'Keine Region gefunden';

  @override
  String get offlineNoPacks =>
      'Keine ladbaren Packs. Stubs unten — kein Demo-Graph unter fremdem Namen.';

  @override
  String offlineNotBuilt(int count) {
    return 'Noch nicht gebaut ($count)';
  }

  @override
  String get offlineStubsHint => 'Catalog-Stubs — Download deaktiviert';

  @override
  String get offlineRemoveRegion => 'Region entfernen';

  @override
  String get offlineStyleTitle => 'Kartenstil (optional)';

  @override
  String get offlineStyleHint =>
      'Default: DACH z11 Style-JSON. Nur ändern für eigenen MapLibre-Style.';

  @override
  String get offlineStyleUrl => 'Style-JSON-URL';

  @override
  String get offlineSaveStyle => 'Style speichern';

  @override
  String offlineRegionActiveSnack(String name) {
    return '$name aktiv';
  }

  @override
  String offlineActivateError(String error) {
    return 'Aktivieren: $error';
  }

  @override
  String offlinePackError(String error) {
    return 'Region-Pack: $error';
  }

  @override
  String get offlineRemoved => 'Region entfernt';

  @override
  String get offlineNoRemoteDach => 'Keine Remote-Packs — DACH-Fallback aktiv';

  @override
  String get offlineNoBuiltPacks => 'Keine gebauten Packs auf diesem Server';

  @override
  String get offlineDachCatalog => 'Offline — DACH-Regionen aus App-Katalog';

  @override
  String get offlineReadyMapRouting => 'Karte + Routing bereit';

  @override
  String get offlineRoutingBg => 'Routing bereit, Karte lädt im Hintergrund';

  @override
  String get offlineBasemapFail =>
      'Routing bereit — Basemap-Download fehlgeschlagen, Karte braucht CDN';

  @override
  String get offlineTilesMissing =>
      'Routing bereit, Kartenkacheln fehlen (Netz/Limit)';

  @override
  String offlineDemoGraph(String name) {
    return 'Demo-Graph Schwarzwald aktiv — nicht $name-Karte';
  }

  @override
  String get offlineStyleCleared => 'Override gelöscht — Default-Style aktiv';

  @override
  String offlineStyleSaved(String url) {
    return 'Style gespeichert. Karte wird neu geladen: $url';
  }

  @override
  String get platzTogetherKicker => 'ZUSAMMEN RAUS';

  @override
  String get platzTogetherTitle => 'Zusammen raus';

  @override
  String get platzTogetherHint =>
      'Einladen teilt den Link. Filter Alle, Privat, Öffentlich gilt auch für Gruppen.';

  @override
  String get platzTogetherListHint =>
      'Gruppe vor dem Tor. Eingeloggt: auf dem Server. Sonst nur dieses Gerät — kein Demo-User. Pins nur im HUD nach Opt-in.';

  @override
  String get platzCreateGroup => 'Gruppe anlegen';

  @override
  String get platzJoinCode => 'Code';

  @override
  String get platzNoGroup =>
      'Noch keine Gruppe. Einladen teilt den Link — nichts Vorgespieltes.';

  @override
  String get platzHost => 'Host';

  @override
  String get platzGuest => 'Gast';

  @override
  String get platzYou => 'Du';

  @override
  String get platzInvite => 'Einladen';

  @override
  String get platzDissolve => 'Auflösen';

  @override
  String get platzLeave => 'Verlassen';

  @override
  String get platzCopyLink => 'Link kopieren';

  @override
  String get platzInviteShares => 'Einladen teilt den Gruppenlink';

  @override
  String get platzInviteSharesProfile => ' und dein Platz-Profil';

  @override
  String platzMembersCount(int count) {
    return '$count dabei';
  }

  @override
  String get platzOnServer => 'auf dem Server';

  @override
  String get platzOnDevice => 'nur auf diesem Gerät';

  @override
  String platzCollectionDefaultName(int day, int month) {
    return 'Sammlung $day.$month.';
  }

  @override
  String get platzPinsOff => 'Pins aus';

  @override
  String get platzPinsHudOnly => 'Pins nur im HUD';

  @override
  String get platzCollectionsKicker => 'SAMMLUNGEN';

  @override
  String get platzNoCollection => 'Noch keine Sammlung — hier anlegen.';

  @override
  String platzCollectionTours(int count) {
    return '$count Touren';
  }

  @override
  String get platzCreateCollection => 'Sammlung anlegen';

  @override
  String get platzJoinWithCode => 'Mit Code beitreten';

  @override
  String get platzJoinCodeField => 'Join-Code';

  @override
  String get platzJoin => 'Beitreten';

  @override
  String get platzNeedSharedTour =>
      'Gruppe nur an freigegebener oder Katalog-Tour. Private GPX bleibt privat.';

  @override
  String get platzNoSharedTours =>
      'Keine freigegebenen oder Katalog-Touren. Private GPX bleibt draußen.';

  @override
  String platzGroupCreated(String code) {
    return 'Gruppe $code — Einladen teilt den Link, kein Explore.';
  }

  @override
  String platzGroupCreatedNote(String code, String note) {
    return 'Gruppe $code — $note';
  }

  @override
  String platzShareSubject(String title) {
    return 'Zusammen raus: $title';
  }

  @override
  String get platzLinkCopied =>
      'Link kopiert. Wer ihn hat, kann beitreten, solange die Gruppe offen ist.';

  @override
  String get platzWindowClosed => 'Fenster zu';

  @override
  String platzWindowHours(int hours) {
    return 'Fenster $hours h';
  }

  @override
  String platzWindowMinutes(int minutes) {
    return 'Fenster $minutes min';
  }

  @override
  String get platzWindowOpen => 'Fenster offen';

  @override
  String platzCollectionShare(String name, String routes) {
    return 'Sammlung „$name“: $routes';
  }

  @override
  String get rerouteTitle => 'Abseits der Route.';

  @override
  String get rerouteHint => 'Ruhig bleiben — du entscheidest.';

  @override
  String get rerouteRejoin => 'Zurück zur Route';

  @override
  String get rerouteStay => 'Bleiben';

  @override
  String get rerouteSkip => 'Abschnitt überspringen';

  @override
  String get bleOff => 'Bluetooth ist aus — bitte einschalten.';

  @override
  String get bleDenied => 'Bluetooth-Berechtigung fehlt.';

  @override
  String get bleUnavailable =>
      'Bluetooth LE ist auf diesem Gerät nicht verfügbar.';

  @override
  String get bleScanFailed => 'Suche fehlgeschlagen';

  @override
  String get bleConnecting => 'Verbinde …';

  @override
  String get blePairFailed => 'Kopplung fehlgeschlagen';

  @override
  String get bleNothingFound => 'Nichts gefunden';

  @override
  String get bleScanAgain => 'Erneut suchen';

  @override
  String get bleHowTo => 'So verbindest du';

  @override
  String get watchPairTitle => 'Uhr koppeln';

  @override
  String get watchPairHint =>
      'Puls nur mit 0x180D. Uhr-Akku ist nicht der Rad-Akku.';

  @override
  String get watchScanning => 'Suche Uhr und Puls-Gurt …';

  @override
  String get watchEmptyHint =>
      'Broadcast an, Handy nah. Apple Watch sendet keinen Standard-Puls.';

  @override
  String get watchNoHr => 'Kein Heart Rate 0x180D — Broadcast prüfen.';

  @override
  String get watchNoDeviceId => 'Verbunden, aber ohne Geräte-ID';

  @override
  String get bleBikeTitle => 'Rad koppeln';

  @override
  String get bleBikeHint =>
      'Akku und Assist nur bei echtem GATT — nichts erfinden.';

  @override
  String get bleRememberAnyway => 'Trotzdem merken';

  @override
  String get bleScanningDrive => 'Suche Antrieb und Sensoren …';

  @override
  String get bleEmptyEbike =>
      'Display wecken, Flow oder E-TUBE zu, Handy nah halten.';

  @override
  String get bleEmptySensor =>
      'Sensor in die Nähe legen und am Rad aktivieren (Magnet/Kurbel).';

  @override
  String get bleConnectFailed => 'Verbindung fehlgeschlagen';

  @override
  String get dieBoxReady => 'Bereit';

  @override
  String get dieBoxAlmost => 'Fast bereit';

  @override
  String get dieBoxUnknown => 'Neu hier';

  @override
  String get dieBoxNothingDueMonday =>
      'Montag-bereit — Licht und Kette sitzen.';

  @override
  String get dieBoxNothingDue => 'Bereit — nichts liegt an.';

  @override
  String get dieBoxCscHint =>
      'Tacho am Rad koppeln. Die Uhr bleibt beim Fahren.';

  @override
  String get dieBoxEmptyHint =>
      'Noch nichts eingetragen. Name und Typ reichen — Teile nur, wenn sie wirklich dran sind.';

  @override
  String get dieBoxAddSomething => 'Etwas eintragen';

  @override
  String get dieBoxAddMore => 'Weiteres eintragen';

  @override
  String get dieBoxBatteryHint =>
      'Akkustand erscheint, sobald ein Sensor am Rad koppelt. Bis dahin keine Zahl.';

  @override
  String get dieBoxPressureTitle => 'Druck merken';

  @override
  String get dieBoxPressureHint => 'Vorn und hinten am Ventil ablesen.';

  @override
  String get dieBoxPressureFront => 'Vorn';

  @override
  String get dieBoxPressureRear => 'Hinten';

  @override
  String get dieBoxPressureLogged => 'Druck gemerkt';

  @override
  String get dieBoxSagTitle => 'Federung merken';

  @override
  String get dieBoxSagHint =>
      'Prozent an Gabel und Dämpfer. SAG ist, wie weit die Federung mit dir einsinkt.';

  @override
  String get dieBoxSagFork => 'Gabel SAG %';

  @override
  String get dieBoxSagShock => 'Dämpfer SAG %';

  @override
  String get dieBoxSagLogged => 'SAG gemerkt';

  @override
  String get dieBoxTravelTitle => 'Federweg eintragen';

  @override
  String get dieBoxTravelHint => 'Nur der Federweg, der am Rad steht.';

  @override
  String get dieBoxTravelFront => 'Vorn mm';

  @override
  String get dieBoxTravelRear => 'Hinten mm';

  @override
  String get dieBoxTravelSave => 'Eintragen';

  @override
  String get dieBoxChainLogged => 'Kette gemessen';

  @override
  String get dieBoxChainNotes => 'Mit der Lehre gemessen';

  @override
  String get dieBoxSetActiveTitle => 'Dieses Rad nach vorn';

  @override
  String get dieBoxSetActiveHint =>
      'Eines steht in der Box — Umschalten holt es nach vorn.';

  @override
  String get dieBoxSetActiveCta => 'Als aktiv setzen';

  @override
  String get dieBoxLightsTitle => 'Licht eintragen';

  @override
  String get dieBoxLightsHint => 'Nur wenn Licht wirklich am Rad ist.';

  @override
  String get dieBoxLightsCta => 'Licht eintragen';

  @override
  String get dieBoxLockTitle => 'Schloss eintragen';

  @override
  String get dieBoxLockHint => 'Nur wenn ein Schloss am Rad ist.';

  @override
  String get dieBoxLockCta => 'Schloss eintragen';

  @override
  String get dieBoxRackTitle => 'Träger eintragen';

  @override
  String get dieBoxRackHint => 'Nur wenn das Rad einen Gepäckträger hat.';

  @override
  String get dieBoxRackCta => 'Träger eintragen';

  @override
  String get dieBoxBagsTitle => 'Taschen eintragen';

  @override
  String get dieBoxBagsHint => 'Nur wenn Taschen am Rad sind.';

  @override
  String get dieBoxBagsCta => 'Taschen eintragen';

  @override
  String get dieBoxPressureMissingTitle => 'Druck merken';

  @override
  String get dieBoxPressureMissingHint => 'Vorn und hinten am Ventil ablesen.';

  @override
  String get dieBoxPressureMissingCta => 'Druck merken';

  @override
  String get dieBoxTirePressureTitle => 'Reifendruck merken';

  @override
  String get dieBoxTirePressureHint => 'Vorn und hinten am Ventil ablesen.';

  @override
  String get dieBoxTravelMissingTitle => 'Federweg eintragen';

  @override
  String get dieBoxTravelMissingHint => 'Nur der Federweg, der am Rad steht.';

  @override
  String get dieBoxTravelMissingCta => 'Federweg eintragen';

  @override
  String get dieBoxSagMissingTitle => 'Federung merken';

  @override
  String get dieBoxSagMissingHint =>
      'Eine Zahl an Gabel und Dämpfer, abgelesen am Rad.';

  @override
  String get dieBoxSagMissingCta => 'Federung merken';

  @override
  String get dieBoxChainTitle => 'Kette merken';

  @override
  String get dieBoxChainHint => 'Mit der Lehre messen, dann hier merken.';

  @override
  String get dieBoxChainCta => 'Kette gemessen';

  @override
  String get dieBoxBrakesTitle => 'Bremsen eintragen';

  @override
  String get dieBoxBrakesHint => 'Nur wenn Beläge am Rad sind.';

  @override
  String get dieBoxBrakesCta => 'Bremse eintragen';

  @override
  String get dieBoxChainDueTitle => 'Kette mit der Lehre prüfen';

  @override
  String get dieBoxChainDueHint => 'Anschauen und mit der Lehre messen.';

  @override
  String get dieBoxParkTrailTitle => 'Park oder Trail';

  @override
  String get dieBoxParkTrailHint =>
      'Beide Setups sind da — wechseln, wenn du willst.';

  @override
  String get dieBoxParkTrailCta => 'Wechseln';

  @override
  String get dieBoxChipLight => 'Licht';

  @override
  String get dieBoxChipLock => 'Schloss';

  @override
  String get dieBoxChipRack => 'Träger';

  @override
  String get dieBoxChipBags => 'Taschen';

  @override
  String get dieBoxChipTires => 'Reifen';

  @override
  String get dieBoxChipDropper => 'Vario';

  @override
  String get dieBoxChipBrakes => 'Bremsen';

  @override
  String get dieBoxChipParkTrail => 'Park | Trail';

  @override
  String get dieBoxChipTravel => 'Federweg';

  @override
  String get dieBoxChipCsc => 'CSC';

  @override
  String get dieBoxChipBatteryHonest => 'Akku ehrlich';

  @override
  String get dieBoxChipSag => 'SAG';

  @override
  String get dieBoxChipChain => 'Kette';

  @override
  String get dieBoxChipPressure => 'Druck';

  @override
  String get dieBoxChipCockpit => 'Cockpit';

  @override
  String lastRideKm(String km) {
    return 'Zuletzt $km km';
  }

  @override
  String get lastRideNoGps => 'Zuletzt unterwegs — ohne GPS-Strecke';

  @override
  String dieBoxSentenceEverydayReady(String name) {
    return '$name wohnt hier · Montag-bereit';
  }

  @override
  String get dieBoxBitLightsChainOk => 'Licht und Kette ok';

  @override
  String get dieBoxBitPressureUnknown => 'Druck nicht gemessen';

  @override
  String get dieBoxBitLightsMissing => 'Licht nicht eingetragen';

  @override
  String dieBoxSentenceNotReady(String name) {
    return '$name wohnt hier';
  }

  @override
  String dieBoxSentenceBits(String name, String bits) {
    return '$name · $bits';
  }

  @override
  String get dieBoxWheelOpen => 'Laufrad offen';

  @override
  String get dieBoxBitPressureLogged => 'Druck gemerkt';

  @override
  String get dieBoxBitPressureRough => 'Druck grob — nachmessen';

  @override
  String get dieBoxBitBagsYes => 'Taschen da';

  @override
  String get dieBoxBitBagsNo => 'Taschen nicht eingetragen';

  @override
  String get dieBoxBitChainYes => 'Kette gemessen';

  @override
  String get dieBoxBitChainNo => 'Kette noch nicht gemessen';

  @override
  String get dieBoxBitPressureToday => 'Druck heute offen';

  @override
  String get dieBoxSentencePark => 'Park-Setup';

  @override
  String get dieBoxSagLoggedShort => 'SAG gemerkt';

  @override
  String get dieBoxSagMissingShort => 'SAG nicht gemessen';

  @override
  String dieBoxSentenceNoTravel(String name) {
    return '$name wohnt hier';
  }

  @override
  String get dieBoxDriveAssist => ' · E-Antrieb';

  @override
  String dieBoxSentenceMtb(String name, String travel, String drive) {
    return '$name · $travel$drive';
  }

  @override
  String dieBoxSentenceFallback(String name) {
    return '$name wohnt hier';
  }

  @override
  String get close => 'Schließen';

  @override
  String get ok => 'OK';

  @override
  String get remove => 'Entfernen';

  @override
  String get garageMoreOnBike => 'Mehr am Rad';

  @override
  String get garageMoreOnBikeHint =>
      'Teile, Wartung, Setup-Versionen — hinter der Box';

  @override
  String get garageDeleteBike => 'Rad löschen';

  @override
  String get garageDeleteBikeTitle => 'Rad löschen?';

  @override
  String get garageDeleteBikeBody =>
      'Komponenten und Setups dieses Bikes entfallen lokal.';

  @override
  String get garageRemovePartTitle => 'Bauteil entfernen?';

  @override
  String garageRemovePartBody(String slot, String name) {
    return '$slot: $name wird aus der Garage entfernt.';
  }

  @override
  String get garageNotLogged => 'Nicht erfasst';

  @override
  String get garageOptions => 'Optionen';

  @override
  String get garageFitTitle => 'Passgenauigkeit';

  @override
  String garageFitStatus(String label) {
    return 'Status: $label';
  }

  @override
  String garageFitSeverity(String label) {
    return 'Schwere: $label';
  }

  @override
  String get garageFitSeveritySafety => 'sicherheitskritisch';

  @override
  String get garageFitSeverityFunctional => 'funktional';

  @override
  String get garageFitExplained => 'Einfach erklärt';

  @override
  String garageFitCondition(String text) {
    return 'Bedingung: $text';
  }

  @override
  String garageFitHint(String text) {
    return 'Hinweis: $text';
  }

  @override
  String get garageFitMissing => 'Noch fehlende Infos';

  @override
  String garageFitSource(String url) {
    return 'Quelle: $url';
  }

  @override
  String garageGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String get garageVerdictFits => 'Passt';

  @override
  String get garageVerdictCheck => 'Prüfen';

  @override
  String get garageVerdictNoFit => 'Passt nicht';

  @override
  String get garageVerdictUnclear => 'Unklar';

  @override
  String garageAllCount(int count) {
    return 'alle $count';
  }

  @override
  String get garageActiveStamp => 'AKTIV';

  @override
  String get garageFreeOneBikeTitle => 'Free: ein Rad';

  @override
  String get garageFreeOneBikeBody =>
      'Im Free-Tarif ist ein Rad vorgesehen. Du kannst lokal trotzdem weitere anlegen — Sync-Limits gelten nach dem Anmelden.';

  @override
  String get garageUnlockPro => 'Pro freischalten';

  @override
  String get garageAddAnyway => 'Trotzdem anlegen';

  @override
  String get garageSlotFrame => 'Rahmen';

  @override
  String get garageSlotFork => 'Gabel';

  @override
  String get garageSlotRearShock => 'Dämpfer';

  @override
  String get garageSlotHeadset => 'Steuersatz';

  @override
  String get garageSlotStem => 'Vorbau';

  @override
  String get garageSlotHandlebar => 'Lenker';

  @override
  String get garageSlotGrips => 'Griffe';

  @override
  String get garageSlotSeatpost => 'Sattelstütze';

  @override
  String get garageSlotSaddle => 'Sattel';

  @override
  String get garageSlotFrontHub => 'Nabe vorn';

  @override
  String get garageSlotRearHub => 'Nabe hinten';

  @override
  String get garageSlotFrontRim => 'Felge vorn';

  @override
  String get garageSlotRearRim => 'Felge hinten';

  @override
  String get garageSlotTireFront => 'Reifen vorn';

  @override
  String get garageSlotTireRear => 'Reifen hinten';

  @override
  String get garageSlotCassette => 'Kassette';

  @override
  String get garageSlotChain => 'Kette';

  @override
  String get garageSlotCrankset => 'Kurbel';

  @override
  String get garageSlotBottomBracket => 'Innenlager';

  @override
  String get garageSlotFrontDerailleur => 'Umwerfer';

  @override
  String get garageSlotRearDerailleur => 'Schaltwerk';

  @override
  String get garageSlotShifter => 'Schalthebel';

  @override
  String get garageSlotBrakeFront => 'Bremse vorn';

  @override
  String get garageSlotBrakeRear => 'Bremse hinten';

  @override
  String get garageSlotRotorFront => 'Scheibe vorn';

  @override
  String get garageSlotRotorRear => 'Scheibe hinten';

  @override
  String get garageSlotMotor => 'Motor';

  @override
  String get garageSlotBattery => 'Akku';

  @override
  String get garageSlotDisplay => 'Display';

  @override
  String get garageSlotLight => 'Licht';

  @override
  String get garageSlotLock => 'Schloss';

  @override
  String get garageSlotRack => 'Gepäckträger';

  @override
  String get garageSlotBags => 'Taschen';

  @override
  String get garageSlotOther => 'Sonstiges';

  @override
  String get garageGroupSuspension => 'Fahrwerk';

  @override
  String get garageGroupWheels => 'Laufräder';

  @override
  String get garageGroupCockpit => 'Cockpit';

  @override
  String get garageGroupDrivetrain => 'Antrieb';

  @override
  String get garageGroupBrakes => 'Bremsen';

  @override
  String get garageGroupPower => 'E-Bike';

  @override
  String get garageGroupOther => 'Weiteres';

  @override
  String get dieBoxZoneToday => 'Heute';

  @override
  String get dieBoxZoneOnBike => 'Am Rad';

  @override
  String get dieBoxZoneSensor => 'Sensor';

  @override
  String get garageCatalogOffline =>
      'Katalog offline — du kannst dein Bike unter „Mein Rad“ oder „GPX“ anlegen.';

  @override
  String get garageNoHit => 'Kein Treffer — Liste nutzen oder anders suchen.';

  @override
  String get garageSearchUnavailable =>
      'Suche gerade nicht möglich — Liste nutzen.';

  @override
  String get garageFileUnreadable => 'Datei konnte nicht gelesen werden';

  @override
  String get garageGpxInvalid => 'Kein gültiger GPX-Track (min. 2 Punkte)';

  @override
  String get garageNeedMakeModel => 'Bitte Hersteller und Modell wählen';

  @override
  String garageCreateFailed(String error) {
    return 'Anlegen fehlgeschlagen: $error';
  }

  @override
  String get garageOemSetup => 'Serien-Setup';

  @override
  String get garageCatalogIdentity => 'Katalog-Identität';

  @override
  String get garageImportBike => 'Import-Bike';

  @override
  String get garageImportNoGpx =>
      'Import ohne GPX — Komponenten später ergänzen';

  @override
  String get garageBaseSetup => 'Basis-Setup';

  @override
  String get garageFreeExtraLocal =>
      'Free: weiteres Bike lokal angelegt (Multi-Bike ist Pro).';

  @override
  String garageOemTakeover(int count) {
    return 'Serienteile übernehmen ($count)';
  }

  @override
  String get garageOemHint => 'Sonst nur Identität. Katalog bleibt Suche.';

  @override
  String garageReachStack(String reach, String stack) {
    return 'Reach $reach mm · Stack $stack mm';
  }

  @override
  String get garageCatalogNotLoaded =>
      'Katalog nicht geladen — wechsle auf „Mein Rad“ oder versuch es später.';

  @override
  String get garageSearchBrandHint => 'Focus SAM, Canyon Grizl, Stevens …';

  @override
  String get garageSearchIntro =>
      'Suche nach Marke und Modell, mach ein Foto oder wähle aus der Liste.';

  @override
  String get garageHideList => 'Liste ausblenden';

  @override
  String get garagePickFromList => 'Aus Liste wählen';

  @override
  String get garageManufacturer => 'Hersteller';

  @override
  String get garageNickname => 'Spitzname (optional)';

  @override
  String get garageNicknameHint => 'z. B. Trail-Bike';

  @override
  String get garageTravelFrontMm => 'Federweg vorn (mm)';

  @override
  String get garageTravelRearMm => 'Federweg hinten (mm)';

  @override
  String get garageTravelOnlyIfPresent => 'Nur wenn am Rad steht';

  @override
  String get garageOnBikeCheck => 'Am Rad — nur anhaken wenn wirklich da';

  @override
  String get garageBagsOnBike => 'Taschen am Rad';

  @override
  String get garageBrandOptional => 'Marke (optional)';

  @override
  String get garageModelOptional => 'Modell (optional)';

  @override
  String get garagePickGpx => 'GPX-Datei wählen';

  @override
  String get garageNameOptional => 'Name (optional)';

  @override
  String get garageMyBike => 'Mein Rad';

  @override
  String get garageCatalog => 'Katalog';

  @override
  String get garageImport => 'Importieren';

  @override
  String get garageCreateBike => 'Rad anlegen';

  @override
  String garageGpxImported(String name, String km) {
    return 'GPX „$name“ · $km km';
  }

  @override
  String get garageName => 'Name';

  @override
  String get garageNameHint => 'z. B. Alltagsrad';

  @override
  String get garagePhoto => 'Foto';

  @override
  String get garageGallery => 'Galerie';

  @override
  String get garageSlotHeading => 'Slot';

  @override
  String get garageEditPart => 'Teil bearbeiten';

  @override
  String get garageInstallPart => 'Teil installieren';

  @override
  String get garageSearchParts => 'Teile suchen (API/Cache)';

  @override
  String get garageSearchPartsHint => 'Hersteller / Modell — optional';

  @override
  String get garageSearchPartsHelper => 'Ohne Treffer: Basisdaten manuell';

  @override
  String get garageHits => 'Treffer';

  @override
  String get garageNoHitsManual =>
      'Keine Treffer — manuell ausfüllen (Basis). Cache kann leer sein.';

  @override
  String garageCacheId(String id) {
    return 'Cache-ID: $id';
  }

  @override
  String garageCompatAttrs(String slot) {
    return 'Kompat-Attribute · $slot';
  }

  @override
  String get garageCompatAttrsHint =>
      'Woher: Herstellerdatenblatt oder Aufdruck am Bauteil. Leer lassen, wenn unbekannt — dann „Daten fehlen\\\" statt Rätselraten.';

  @override
  String get garageExtraAttr => 'Weiteres Attribut (fortgeschritten)';

  @override
  String get garageAttrKey => 'Attribut-Key';

  @override
  String get garageAttrValue => 'Attribut-Wert';

  @override
  String get garageCompatPlaceholder =>
      'Kompat-Platzhalter gesetzt (z. B. 148×12 / Microspline) — keine Katalog-Wahrheit. Attribute prüfen.';

  @override
  String garageSagGuideTitle(String kg) {
    return 'Federungs-Richtwerte (Fahrer $kg kg)';
  }

  @override
  String garageSagGuideFork(String psi, String min, String max, String sag) {
    return 'Gabel: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String garageSagGuideShock(String psi, String min, String max, String sag) {
    return 'Dämpfer: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String get garageSagGuideHint =>
      'Richtwert zum Einstieg — am Bike messen, dann feinjustieren.';

  @override
  String get garageMeasureSag => 'SAG messen';

  @override
  String get garageShowMeasureSteps => 'Messschritte anzeigen';

  @override
  String get garageOdometer => 'Kilometerstand';

  @override
  String get garageOperatingHours => 'Betriebsstunden';

  @override
  String garageOdoStand(String km) {
    return 'Stand: $km km';
  }

  @override
  String garageHoursStand(String hours) {
    return 'Stunden: $hours h';
  }

  @override
  String get garageAddKmNoGps => 'km ohne GPS-Track hinzufügen';

  @override
  String get garageDistanceKm => 'Distanz (km)';

  @override
  String get garageImportKm => 'km importieren (ohne GPS-Ride)';

  @override
  String get garageMaintLog => 'Wartungslog';

  @override
  String get garageMaintLogEmpty =>
      'Noch keine Einträge — Odometer-Set erzeugt Logs.';

  @override
  String get garageBleScanning => 'Suche Geräte …';

  @override
  String get garageBlePaired => 'Gerät gekoppelt';

  @override
  String garageBlePairedNamed(String name) {
    return 'Gekoppelt: $name';
  }

  @override
  String get garageBlePairFailed => 'Kopplung fehlgeschlagen';

  @override
  String get garageBleRemoved => 'Sensor entfernt';

  @override
  String get garageBleDisconnected => 'Bluetooth nicht verbunden';

  @override
  String get garageBleHintEbike =>
      'Bosch, Shimano STEPS oder CSC. Display einschalten.';

  @override
  String get garageBleHintSensor => 'Sensor am Rad, nicht am Fahrer.';

  @override
  String get discoverRefresh => 'Neu';

  @override
  String get discoverChangePlace => 'Ort ändern';

  @override
  String get discoverSuggestDuration => 'Dauer vorschlagen';

  @override
  String get discoverDemoCities => 'Demo-Städte';

  @override
  String discoverNearbyTitle(String profile) {
    return 'In deiner Nähe · $profile';
  }

  @override
  String get discoverNearbyHintGps =>
      'Tippen zeigt die Strecke · Losfahren startet die Navigation';

  @override
  String get discoverNearbyHintNoGps => 'Standort freigeben für Touren ab hier';

  @override
  String get discoverGrantLocation => 'Standort freigeben';

  @override
  String get discoverSuggestionsComputing => 'Vorschläge werden berechnet…';

  @override
  String get discoverNoSuggestions =>
      'Keine Vorschläge — Standort setzen, Rad-Profil wählen oder „Neu“.';

  @override
  String discoverAdaptSuggestion(String label) {
    return 'Vorschlag anpassen: $label';
  }

  @override
  String get discoverTours => 'Touren';

  @override
  String discoverToursLoops(int count) {
    return 'Touren · $count Rundkurse';
  }

  @override
  String discoverToursCount(int count) {
    return 'Touren · $count';
  }

  @override
  String get discoverNoGpsCurated =>
      'Ohne GPS: kuratierte Touren · Standort für Nähe';

  @override
  String get discoverGrantLocationNearby =>
      'Standort freigeben für Touren in deiner Nähe';

  @override
  String discoverToursNearbyCount(int count) {
    return '$count Touren in der Nähe';
  }

  @override
  String discoverCuratedLoops(int count) {
    return '$count kuratierte Rundkurse';
  }

  @override
  String get discoverOfflineSuffix => ' · offline';

  @override
  String get discoverHeatmapConsent =>
      'Heatmaps nach Consent — Privatsphäre öffnen';

  @override
  String get discoverRideToStartShort => 'Zum Startpunkt';

  @override
  String get discoverLoopsNearby => 'Rundkurse in deiner Nähe';

  @override
  String get discoverNoLoop90 => 'Keine Runde in 90 km — nächste Regionen';

  @override
  String get discoverRecommendedNoGps => 'Empfohlene Touren · auch ohne GPS';

  @override
  String discoverRecommended(int count) {
    return 'Empfohlen ($count)';
  }

  @override
  String get discoverRecommendedHint =>
      'Für alle Radtypen · Strecke beim Losfahren';

  @override
  String discoverInRegion(int count) {
    return 'In der Region ($count)';
  }

  @override
  String get discoverToursAround => 'Touren aus der Umgebung';

  @override
  String get discoverAfterLocation => 'Erscheint nach Standort';

  @override
  String get discoverNeedLocationTrails =>
      'Standort oder Start setzen für Trailnetz';

  @override
  String get discoverTrailLoading => 'Trailnetz lädt…';

  @override
  String get discoverTrailEmpty => 'Kein OSM-Trailnetz in der Nähe';

  @override
  String discoverTrailCount(int count) {
    return 'Trailnetz $count · Tippen zum Auswählen';
  }

  @override
  String get discoverTrailOffline => 'Trailnetz offline';

  @override
  String get discoverOsmLivePath => 'OSM-Live-Pfad';

  @override
  String get discoverOsmTags => 'Tags aus OpenStreetMap';

  @override
  String get discoverTapMapTrails => 'Tippen auf der Karte wählt Trails.';

  @override
  String get discoverTrailApproachHint =>
      'Anfahrt zum Einstieg, dann Overlay speichern oder fahren.';

  @override
  String get discoverTrailGravityHint =>
      'DH: Auto oder zu Fuß zum oberen Einstieg. Die Abfahrt folgt dem Trail, nicht der Straße.';

  @override
  String get discoverRideToTrailhead => 'Zum Startpunkt anfahren';

  @override
  String get discoverApproachByCar => 'Anfahrt mit Auto';

  @override
  String get discoverApproachOnFoot => 'Zu Fuß zum Einstieg';

  @override
  String get discoverAtTrailStart => 'Ich bin am Start';

  @override
  String get discoverApproachByBike => 'Mit dem Rad anfahren';

  @override
  String discoverTrailUnsuitableForBike(String bike) {
    return 'Mit $bike nicht auf diesen Trail. Garage wechseln — nicht heimlich als MTB routen.';
  }

  @override
  String get discoverTrailOrientedDownhill => 'Einstieg oben (Höhe)';

  @override
  String get discoverTrailStartUphillUnknown =>
      'Höhe unklar — näherer Einstieg';

  @override
  String get discoverPutOnRoute => 'Auf Route legen';

  @override
  String get discoverOpenOsm => 'Auf OpenStreetMap öffnen';

  @override
  String get discoverApproachTrailhead => 'Anfahrt zum Trailhead…';

  @override
  String discoverApproachPlusTrail(String km, String diff) {
    return 'Anfahrt + Trail · $km km · $diff';
  }

  @override
  String discoverTrailLaid(String diff, String km) {
    return 'Trail gelegt · $diff · $km km — speichern oder Los';
  }

  @override
  String get discoverSurfaceNature => 'Naturweg';

  @override
  String get discoverSurfaceGrass => 'Gras';

  @override
  String get discoverSurfaceWood => 'Holz';

  @override
  String get discoverHighwayPath => 'Pfad';

  @override
  String get discoverHighwayTrack => 'Forstweg';

  @override
  String get discoverHighwayCycle => 'Radweg';

  @override
  String get discoverHighwayBridle => 'Reitweg';

  @override
  String get discoverHighwayFoot => 'Fußweg';

  @override
  String get discoverSetStartEnd =>
      'Start & Ziel setzen — dann Route berechnen';

  @override
  String get discoverAdjustStops => 'Start, Ziel oder Stopp anpassen';

  @override
  String discoverNoHitsFor(String query) {
    return 'Keine Treffer für „$query“';
  }

  @override
  String get discoverGeocodeFailed => 'Adresssuche fehlgeschlagen';

  @override
  String discoverStartEndHit(String kind, String label) {
    return '$kind: $label';
  }

  @override
  String get discoverIdeaStartSet =>
      'Tour-Idee: Start = Ortspunkt, Ziel-Vorschlag gesetzt — Route berechnen.';

  @override
  String get discoverSuggestEnd => 'Ziel-Vorschlag (anpassbar)';

  @override
  String get discoverTourInPlan => 'Tour in Planen — Start/Ziel/Via editierbar';

  @override
  String get discoverNeedLocationTours =>
      'Standort oder Start setzen für Touren';

  @override
  String get discoverOaOffline => 'Outdooractive offline';

  @override
  String get discoverOaNoLive =>
      'Outdooractive — keine Live-Touren in der Nähe';

  @override
  String discoverOaCount(int count) {
    return 'Outdooractive $count · OSM/Tracks folgen';
  }

  @override
  String get discoverLocationOff =>
      'Ortungsdienst aus — Start tippen oder Adresse';

  @override
  String get discoverLocationDenied =>
      'Standort-Berechtigung fehlt — Adresse nutzen';

  @override
  String get discoverNoGpsFix =>
      'Kein GPS-Fix — Karte tippen oder Adresse suchen';

  @override
  String get discoverMyPosition => 'Meine Position';

  @override
  String get discoverLocationReady =>
      'Standort bereit · In der Nähe wird geladen…';

  @override
  String get discoverLocationUnavailable =>
      'Position nicht verfügbar — Adresse oder Tippen';

  @override
  String get discoverComputing => 'Route wird berechnet…';

  @override
  String discoverComputingN(int count) {
    return '$count Routen werden berechnet…';
  }

  @override
  String get discoverHeadingNorth => 'Richtung Norden';

  @override
  String get discoverHeadingEast => 'Richtung Osten';

  @override
  String get discoverHeadingSouthwest => 'Richtung Südwest';

  @override
  String get discoverTargetNorth =>
      'Ziel im Norden — Rückweg noch nicht enthalten';

  @override
  String get discoverTargetEast =>
      'Ziel im Osten — Rückweg noch nicht enthalten';

  @override
  String get discoverTargetSouthwest =>
      'Ziel im Südwest — Rückweg noch nicht enthalten';

  @override
  String discoverApproxLabel(String label) {
    return '$label (Näherung)';
  }

  @override
  String get discoverQuickRoute => 'Quick-Route';

  @override
  String get discoverRoutingLimit =>
      'Routing-Limit — Näherung genutzt. Später erneut berechnen.';

  @override
  String get discoverNoQuickRoutes => 'Keine Quick-Routen';

  @override
  String get discoverPartialApprox =>
      'Teilweise Näherung — Live-Routing eingeschränkt';

  @override
  String get discoverPlannedRoute => 'Geplante Route';

  @override
  String get discoverStraightFallback =>
      'Gerade Fallback — Live-Routing lieferte keine Geometrie';

  @override
  String get discoverSaved => 'Gespeichert';

  @override
  String discoverSavedNamed(String name) {
    return 'Gespeichert: $name';
  }

  @override
  String get discoverSavedRouteLoaded => 'Gespeicherte Route geladen';

  @override
  String get discoverStartSetPickEnd => 'Start gesetzt — jetzt Ziel wählen';

  @override
  String get discoverEndSetComputing => 'Ziel gesetzt — Route wird berechnet';

  @override
  String get discoverFromHere => 'Von hier';

  @override
  String get discoverNearbyPhotos => 'Fotos in der Nähe';

  @override
  String get discoverToMyTours => 'Zu Meine Touren';

  @override
  String get discoverAlreadyInMappe => 'Schon in der Mappe';

  @override
  String discoverInMappeNamed(String name) {
    return 'In der Mappe: $name';
  }

  @override
  String get discoverAddRoute => 'Route hinzufügen';

  @override
  String get discoverAddRouteHint =>
      'Name + Start — ohne erfundenen Track. Strecke später berechnen oder GPX.';

  @override
  String get discoverMapCenter => 'Kartenmitte';

  @override
  String get discoverSaveToMine => 'In Meine Touren speichern';

  @override
  String discoverSavedToMine(String name) {
    return 'In Meine Touren: $name';
  }

  @override
  String get discoverPickFileAgain => 'Datei erneut wählen';

  @override
  String discoverGpxUnreadable(String name) {
    return '„$name“ konnte nicht gelesen werden — beschädigt oder kein gültiges GPX.';
  }

  @override
  String get discoverGpxInvalid =>
      'GPX ungültig oder zu wenige Punkte — andere Datei wählen?';

  @override
  String discoverGpxImported(String name, String km) {
    return 'GPX importiert: $name · $km km';
  }

  @override
  String discoverSavedDotName(String name) {
    return 'Gespeichert · $name';
  }

  @override
  String get discoverAsActive => 'Als aktiv';

  @override
  String get discoverLocalFoldersHint =>
      'Lokale Ordner für gespeicherte Routen — kein Social-Feed.';

  @override
  String get discoverNoSavedInCollection =>
      'Keine passenden gespeicherten Routen in dieser Sammlung';

  @override
  String get discoverNoCollectionYet => 'Noch keine Sammlung.';

  @override
  String get discoverNewCollection => 'Neue Sammlung';

  @override
  String get discoverNeedRouteAndCollection =>
      'Braucht mindestens eine gespeicherte Route und eine Sammlung';

  @override
  String get discoverPickRoute => 'Route wählen';

  @override
  String get discoverPickCollection => 'Sammlung wählen';

  @override
  String get discoverAddedToCollection => 'Zur Sammlung hinzugefügt';

  @override
  String get discoverRouteToCollection => 'Route zu Sammlung';

  @override
  String get discoverStartSavedNoTrack =>
      'Startpunkt gespeichert — noch keine Strecke. Navigieren oder GPX.';

  @override
  String get discoverComputedRoute => 'Berechnete Route';

  @override
  String get discoverSavedRoute => 'Gespeicherte Route';

  @override
  String discoverViaN(int n) {
    return 'Via $n';
  }

  @override
  String get discoverTourGone => 'Tour nicht mehr verfügbar';

  @override
  String get discoverTourGoneBody =>
      'Diese Tour ist gerade nicht in der Liste — z. B. weil ein Filter sie ausschließt.';

  @override
  String get discoverTourTimeline => 'Tourverlauf';

  @override
  String get discoverNoTrackYet =>
      'Noch keine Strecke — „Route berechnen“ baut sie live.';

  @override
  String get discoverDuration => 'Dauer';

  @override
  String get discoverLength => 'Länge';

  @override
  String get discoverAscent => 'Aufstieg';

  @override
  String get discoverElevationProfile => 'Höhenprofil';

  @override
  String discoverDescent(String m) {
    return '↓ $m m Abstieg';
  }

  @override
  String get discoverTip => 'Tipp';

  @override
  String get discoverBestTime => 'Beste Zeit';

  @override
  String get discoverDiscipline => 'Disziplin';

  @override
  String get discoverCorridor => 'Korridor';

  @override
  String get discoverTraits => 'Merkmale';

  @override
  String get discoverTipsInfo => 'Tipps & Infos';

  @override
  String get discoverStartPoint => 'Startpunkt';

  @override
  String discoverFromHereKm(String dist) {
    return '$dist von hier';
  }

  @override
  String get discoverApproach => 'Anfahrt';

  @override
  String get discoverInMyTours => 'In Meine Touren';

  @override
  String discoverPinIdeaNamed(String name) {
    return 'Idee „$name“ — nur Ortspunkt';
  }

  @override
  String get discoverPinIdea => 'Tour-Idee — nur Ortspunkt auf der Karte';

  @override
  String get discoverStartEndReady =>
      'Start/Ziel gesetzt. Route berechnen oder Ziel anpassen.';

  @override
  String get discoverComputeAndSave => 'Route berechnen & speichern';

  @override
  String get discoverChangePlaceSearch =>
      'Ort ändern — Stadt oder Adresse suchen';

  @override
  String discoverDemoRegion(String name) {
    return 'Demo-Region: $name';
  }

  @override
  String get discoverPickProfile => 'Profil wählen';

  @override
  String get discoverOwn => 'Eigene';

  @override
  String discoverStartOnlyNoTrack(String badge) {
    return '$badge · Startpunkt — noch keine Strecke';
  }

  @override
  String get discoverShowLess => 'Weniger anzeigen';

  @override
  String get discoverShowMore => 'Mehr anzeigen';

  @override
  String get discoverTrailView => 'Trail-Ansicht';

  @override
  String get discoverNoPhotosNearby => 'Keine Fotos in der Nähe';

  @override
  String get discoverImageUnavailable => 'Bild nicht verfügbar';

  @override
  String get discoverNoLivePhotos => 'Keine Live-Fotos';

  @override
  String get discoverOpenMapillary => 'Mapillary öffnen';

  @override
  String get discoverMapillarySample => 'Beispiel — Mapillary nicht verfügbar';

  @override
  String get discoverNoTrackOnMap =>
      'Kein Track — erst auf der Karte laden oder GPX.';

  @override
  String get discoverNoClosedLoop =>
      'Kein geschlossener Rundkurs-Track — Tour erneut wählen oder Anpassen.';

  @override
  String get discoverNoLiveTrackPlan =>
      'Kein Live-Track — Route berechnen öffnet Planen mit Ziel-Vorschlag.';

  @override
  String get discoverNotClosedLoopNav =>
      'Geometrie ist keine geschlossene Runde — Navigation abgebrochen.';

  @override
  String get discoverNoRealPolyline =>
      'Keine echte Track-Polyline — Route neu berechnen oder GPX.';

  @override
  String get discoverPoiIdeaHint =>
      'Anfahrt zum Ortspunkt — kein Tour-Track. Ziel weiterplanen oder GPX.';

  @override
  String discoverHybridKm(String km) {
    return 'Hybrid · $km km';
  }

  @override
  String get discoverAroundPoiComputing => 'Route um Ortspunkt wird berechnet…';

  @override
  String discoverLiveRouteReady(String km) {
    return 'Live-Route · $km km — speichern oder Losfahren';
  }

  @override
  String discoverPoiNamed(String name) {
    return 'Ortspunkt · $name';
  }

  @override
  String get discoverNotLoopAb =>
      'Kein Rundkurs — A→B-Vorschlag gesetzt. „Route berechnen“ oder Ziel tippen.';

  @override
  String get discoverApproxAb =>
      'Näherungsroute A→B · Ziel auf Karte anpassen, dann erneut berechnen.';

  @override
  String get discoverRoutingFailedRetry =>
      'Routing fehlgeschlagen — Ziel tippen und erneut berechnen.';

  @override
  String get discoverUnplausibleDropped =>
      'Unplausibles Routing-Ergebnis verworfen';

  @override
  String discoverAltChosen(String label) {
    return 'Alternative gewählt: $label';
  }

  @override
  String get discoverLoading => 'Laden';

  @override
  String get discoverCatalog => 'Katalog';

  @override
  String get discoverShared => 'freigegeben';

  @override
  String get discoverPrivate => 'privat';

  @override
  String get discoverPrivateCap => 'Privat';

  @override
  String get discoverShareRelease => 'Freigeben';

  @override
  String discoverRiddenWith(String name) {
    return 'gefahren mit $name';
  }

  @override
  String get discoverPrivateCommentHint =>
      'Noch privat — nach Freigabe können andere kommentieren.';

  @override
  String get discoverRemoveFromMappe => 'Aus der Mappe nehmen';

  @override
  String get discoverLinkNoTrack =>
      'Link ohne Spur — zu lang für die URL. Name und Stats, kein GPS.';

  @override
  String get discoverLinkCopiedTrack =>
      'Link kopiert. Enthält eine vereinfachte Spur.';

  @override
  String get discoverLinkCopiedStats =>
      'Link kopiert. Name und Stats, kein Track.';

  @override
  String get discoverTrackLocal =>
      'Track liegt lokal. Sync zwischen deinen Geräten.';

  @override
  String get discoverNoTrackEntry =>
      'Noch kein Track — nur der Eintrag in der Mappe.';

  @override
  String get discoverVisibility => 'Sichtbarkeit';

  @override
  String get discoverCopyLink => 'Link kopieren';

  @override
  String get discoverNoSavedFilter => 'Keine Touren in diesem Filter.';

  @override
  String get discoverMineEmptyHint =>
      'Noch keine eigenen Strecken — Route hinzufügen, GPX oder aufzeichnen.';

  @override
  String get overlayLegendTitle => 'Wege · OSM';

  @override
  String get overlayLegendCompactCity => 'City';

  @override
  String get overlayLegendCompactMtb => 'MTB';

  @override
  String get overlayScaleNote => 'S0–S3+ nur bei OSM-Tag. Sonst unbewertet.';

  @override
  String get overlayRoadAsphalt => 'Radweg / Asphalt';

  @override
  String get overlayUnrated => 'unbewertet';

  @override
  String get discoverChipTooltip =>
      'Touren und Wege — nicht der Navigationsmotor';

  @override
  String get discoverNavHonestyBike =>
      'Navi: Fahrrad — GraphHopper Basic, gleiche Route';

  @override
  String get discoverNavHonestyFoot => 'Navi: Zu Fuß';

  @override
  String get stimmenTitle => 'Stimmen';

  @override
  String get stimmenHint =>
      'Sterne, Text und Fotos — Cloud nach Freigabe. Keine erfundenen Stimmen.';

  @override
  String get stimmenWrite => 'Stimme schreiben';

  @override
  String get stimmenHowWas => 'Wie war die Tour?';

  @override
  String get stimmenEmptyName => 'Leer bleibt Du';

  @override
  String get stimmenAddPhoto => 'Foto hinzufügen';

  @override
  String get stimmenSaving => 'Speichern …';

  @override
  String get stimmenShareSubject => 'Tour teilen';

  @override
  String get stimmenEmpty => 'Noch keine Stimmen.';

  @override
  String get stimmenLabel => 'Stimme';

  @override
  String get stimmenCloudApproved =>
      'Gespeichert — veröffentlicht (AI-Freigabe)';

  @override
  String get stimmenCloudRejected =>
      'Lokal gespeichert — Cloud hat den Text abgelehnt';

  @override
  String get stimmenCloudPending =>
      'Gespeichert — lokal und in Prüfung (AI/Mensch)';

  @override
  String get stimmenCloudLocal => 'Gespeichert — lokal (Cloud nach Login)';

  @override
  String get stimmenCloudFailed =>
      'Gespeichert lokal — Cloud gerade nicht erreichbar';

  @override
  String get akteHonestyCatalog =>
      'Katalog-Tour ist schon öffentlich. Freigeben macht deine Akte teilbar — der Link zeigt Name und Stats, keinen privaten Extra-Track.';

  @override
  String get akteHonestyTrack =>
      'Freigeben erzeugt einen Link. Der Link enthält eine vereinfachte Spur (Koordinaten), nicht nur den Namen. Zurück auf Privat nimmt die Tour aus Filtern und speichert den Widerruf auf dem Server, wenn du eingeloggt bist. Ohne Login gilt er nur auf diesem Gerät.';

  @override
  String get akteHonestyNoTrack =>
      'Freigeben erzeugt einen Link mit Name und Stats — ohne Track, weil keiner gespeichert ist.';

  @override
  String get stimmenSubmit => 'Absenden';

  @override
  String get ortSheetVia => 'Als Zwischenziel';

  @override
  String get ortSheetHere => 'Touren hierher';

  @override
  String get ortSheetMaps => 'In Maps öffnen';

  @override
  String get ortKindCafe => 'Café';

  @override
  String get ortKindWater => 'Wasser';

  @override
  String get ortKindViewpoint => 'Aussicht';

  @override
  String get ortKindShop => 'Laden';

  @override
  String get ortKindRepair => 'Werkstatt';

  @override
  String get ortKindTrailhead => 'Start';

  @override
  String get ortKindTip => 'Tipp';

  @override
  String get ortKindMeet => 'Treffpunkt';

  @override
  String get ortKindOther => 'Ort';

  @override
  String get viaMoveUp => 'Nach oben';

  @override
  String get viaMoveDown => 'Nach unten';

  @override
  String get stimmeTagsHint => 'Zustand — optional, max. drei';

  @override
  String get stimmeTagNass => 'nass';

  @override
  String get stimmeTagZu => 'zu';

  @override
  String get stimmeTagVielLos => 'viel los';

  @override
  String get stimmeTagTop => 'top';

  @override
  String get stimmeTagBaustelle => 'Baustelle';

  @override
  String get postRideStimmeTitle => 'Stimme zur Tour?';

  @override
  String get postRideStimmeHint =>
      'Nur diese Tour, kein Track im Text. Skip ist in Ordnung.';

  @override
  String get postRideStimmeSkip => 'Jetzt nicht';

  @override
  String get postRideStimmeDone => 'Stimme gespeichert.';

  @override
  String get discoverLayerTours => 'Touren';

  @override
  String get discoverLayerPlaces => 'Orte';

  @override
  String get discoverLayerHeat => 'Heat';

  @override
  String get discoverLayerHeatOff => 'Heat aus';

  @override
  String get discoverRoundTrip => 'Hin & zurück';

  @override
  String get discoverOutboundOnly => 'nur Hinweg';

  @override
  String get discoverOsmNoHitsSuffix => ' · OSM keine Treffer';

  @override
  String get discoverLiveRoutingUnavailable =>
      ' · Live-Routing nicht verfügbar';

  @override
  String get discoverUnplausibleLive =>
      ' · Live-Routing lieferte kein plausibles Ergebnis';

  @override
  String get discoverTapEndCompute =>
      'Ziel tippen oder Adresse — dann Route berechnen.';

  @override
  String get discoverPlanYourself =>
      'Route selbst planen — Start & Ziel setzen';

  @override
  String get discoverLoopBadge => '⟲ Rundkurs';

  @override
  String discoverElevMin(Object min) {
    return 'Min $min';
  }

  @override
  String get discoverHeatmapOffline => 'Heatmap offline';

  @override
  String get discoverCreate => 'Anlegen';

  @override
  String get discoverRegionSource => 'Region';

  @override
  String get discoverTourNoun => 'Tour';

  @override
  String get discoverOsmLive => 'OSM live';

  @override
  String discoverApproachParen(Object name) {
    return '($name)';
  }

  @override
  String get discoverShop => 'Laden';

  @override
  String get discoverPreview => 'Vorschau';

  @override
  String discoverApproachName(Object name) {
    return '$name (Anfahrt)';
  }

  @override
  String discoverFromHereName(Object name) {
    return '$name (von hier)';
  }

  @override
  String get rideLocationOff => 'Standort aus';

  @override
  String get rideLocationOffBody =>
      'Ohne Standort kein GPS-Track. Bitte Ortungsdienste einschalten.';

  @override
  String get rideSettings => 'Einstellungen';

  @override
  String get rideLocationPermission => 'Standort-Berechtigung';

  @override
  String get rideLocationDeniedForever =>
      'Standort dauerhaft verweigert. In den App-Einstellungen freigeben, sonst bleibt der Track leer.';

  @override
  String get rideAppSettings => 'App-Einstellungen';

  @override
  String get rideLocationNeeded =>
      'Standort nötig für Track & Navigation — erneut starten und erlauben.';

  @override
  String get rideGpsFix => 'GPS-Fix…';

  @override
  String rideGpsFixN(Object count) {
    return 'GPS-Fix $count…';
  }

  @override
  String get rideGpsStillSim => 'GPS still — Sim-Track (nicht speichern)';

  @override
  String get rideGpsStillWeak => 'GPS still — Signal schwach / Stand';

  @override
  String get rideGpsSimActive => 'Sim-Track aktiv (AETHER_SIM_MOTION)';

  @override
  String get rideBleOffSnack =>
      'Bluetooth aus — Fahren auch ohne Sensor möglich; später verbinden.';

  @override
  String get rideBleDeniedSnack =>
      'Nearby/Bluetooth verweigert — GPS-Navigation läuft ohne Sensor.';

  @override
  String get rideNoBikeSensor =>
      'Kein Radsensor gefunden — GPS-Track läuft weiter.';

  @override
  String get rideOfflineRerouteToast =>
      'Reroute braucht Internet. Auf der geladenen Route bleiben.';

  @override
  String get rideStayOnTrail =>
      'Auf dem Trail bleiben — keine Straßen-Umleitung.';

  @override
  String get rideFollowTrail => 'Trail folgen';

  @override
  String get rideNoGpsRejoin => 'Kein GPS-Fix für Rejoin';

  @override
  String rideRejoinFailed(Object error) {
    return 'Rejoin fehlgeschlagen: $error';
  }

  @override
  String get rideSkipAheadWhy => 'Abschnitt übersprungen — zurück zur Route.';

  @override
  String get rideRejoinWhy => 'Zurück zur Route.';

  @override
  String get rideSkipAheadTts => 'Abschnitt übersprungen';

  @override
  String get rideRouteRestoredTts => 'Route wiederhergestellt';

  @override
  String get rideOffRouteTts => 'Abseits der Route';

  @override
  String get rideRerouting => 'Route wird neu berechnet …';

  @override
  String get rideUndo10s => '10 s Rückgängig';

  @override
  String get rideUndo => 'Rückgängig';

  @override
  String get rideStayOffHint => 'Du bleibst abseits — tippe für Optionen.';

  @override
  String get rideRecalc => 'Neu berechnen …';

  @override
  String get rideTapOptions => 'Tippe für Optionen.';

  @override
  String get rideOptions => 'Optionen';

  @override
  String get ridePause => 'Pause';

  @override
  String get rideResume => 'Weiter';

  @override
  String get rideRunning => 'Fahrt läuft';

  @override
  String get rideStop => 'Stop';

  @override
  String get rideTapAgain => 'Nochmal tippen';

  @override
  String get rideStopNeedsTwo => 'Beenden erfordert 2 Tipps';

  @override
  String get rideQuietDisplay => 'Ruhige Anzeige';

  @override
  String get rideFollowCamera => 'Kamera folgen';

  @override
  String get rideFollowOn => 'Kamera-Follow an';

  @override
  String get rideFollowFree => 'Kamera frei';

  @override
  String get rideLiveRide => 'Live-Fahrt';

  @override
  String get rideReady => 'Bereit';

  @override
  String get rideTtsOn => 'TTS an';

  @override
  String get rideTtsMute => 'TTS stumm';

  @override
  String get rideNorthUp => 'Norden oben';

  @override
  String get rideHeadingUp => 'Fahrtrichtung oben';

  @override
  String rideHeadingCourse(Object cardinal, Object mode) {
    return '$mode, Kurs $cardinal';
  }

  @override
  String get rideAutoRerouteOn => 'Auto-Reroute an';

  @override
  String get rideAutoRerouteOff => 'Auto-Reroute aus';

  @override
  String rideAutoRerouteActive(Object sec) {
    return 'Auto-Reroute aktiv (Cooldown ${sec}s)';
  }

  @override
  String get rideAutoRerouteManual =>
      'Auto-Reroute aus — manueller Rejoin bleibt';

  @override
  String get rideSunlightAuto => 'Sunlight Mode (Auto)';

  @override
  String get rideSunlightManual => 'Sunlight Mode (Manuell)';

  @override
  String rideDisplayNamed(Object name) {
    return 'Display: $name';
  }

  @override
  String rideDisplayNamedBattery(Object name) {
    return 'Display: $name (kostet Akku)';
  }

  @override
  String get rideCostsBattery => 'kostet Akku';

  @override
  String get rideBatteryTitle => 'Display & Akku';

  @override
  String get rideBatteryHint =>
      'Display an lassen? Mehr Akku-Verbrauch. Standard spart Akku.';

  @override
  String get rideBatteryPocketSnack =>
      'Pocket — Display darf aus (Akku sparen).';

  @override
  String get rideBatteryLenkerSnack => 'Lenker — Display an (kostet Akku).';

  @override
  String get rideBatteryUltraSnack =>
      'Ultra — Display nur bei Abbiegen (kostet Akku).';

  @override
  String get rideBatteryPocket => 'Pocket';

  @override
  String get rideBatteryLenker => 'Lenker';

  @override
  String get rideBatteryUltra => 'Ultra';

  @override
  String get rideBatteryPocketSub => 'Stimme + Haptik, Display darf aus';

  @override
  String get rideBatteryLenkerSub => 'Display an lassen';

  @override
  String get rideBatteryUltraSub => 'Display nur bei Abbiegen wecken';

  @override
  String get rideDefault => 'Standard';

  @override
  String get rideSpeed => 'Tempo';

  @override
  String get rideSensorSpeed => 'Sensor-Tempo';

  @override
  String get rideDistance => 'Distanz';

  @override
  String get rideTime => 'Zeit';

  @override
  String get rideHeart => 'Puls';

  @override
  String get rideHeartWaiting => 'Puls wartet';

  @override
  String get rideCadence => 'Kadenz';

  @override
  String get rideBikeSensor => 'Radsensor';

  @override
  String get rideWatch => 'Smartwatch';

  @override
  String get rideConnected => 'Verbunden';

  @override
  String get ridePower => 'Leistung';

  @override
  String get rideSoc => 'Akku';

  @override
  String get rideAssist => 'Assist';

  @override
  String get rideBatteryChip => 'Akku';

  @override
  String get rideWheelSpeed => 'Rad';

  @override
  String get rideRestKm => 'noch km';

  @override
  String get rideUntilJoin => 'bis Route';

  @override
  String get rideRestLoop => 'Rest Runde';

  @override
  String rideKmToRoute(String km) {
    return '$km km zur Route';
  }

  @override
  String get rideEta => 'Ziel';

  @override
  String get rideKmh => 'km/h';

  @override
  String get rideKm => 'km';

  @override
  String get rideChassisOff => 'Fahrwerksanalyse aus';

  @override
  String get rideChassisHint =>
      'Handy am Lenker befestigen und als montiert markieren.';

  @override
  String get rideMarkMounted => 'Als montiert markieren';

  @override
  String get rideWaitingSensors => 'Warte auf Sensorik…';

  @override
  String get rideThereafter => 'Danach';

  @override
  String get rideAutoLock => 'Auto-Lock';

  @override
  String get rideAutoLockHint => 'Tippen zum Aufwecken';

  @override
  String get rideWake => 'Aufwecken';

  @override
  String get rideMusicHud => 'Musik im HUD';

  @override
  String get rideMusicHudHint => 'Titel von Spotify & Co. anzeigen';

  @override
  String get rideDismissHint => 'Hinweis schließen';

  @override
  String get rideMusicControls => 'Musiksteuerung';

  @override
  String get ridePrevTrack => 'Vorheriger Titel';

  @override
  String get rideNextTrack => 'Nächster Titel';

  @override
  String get ridePlay => 'Abspielen';

  @override
  String get rideNavSymbol => 'Symbol';

  @override
  String get rideChangeNavSymbol => 'Navi-Symbol ändern';

  @override
  String get rideNavPuckTitle => 'Navi-Symbol';

  @override
  String get rideNavPuckHint =>
      'Alle Varianten auf dunkel und hell. Tippen wählt das Symbol für Karte und HUD. 0° = Spitze oben.';

  @override
  String get rideRecommend => 'Empfehlung';

  @override
  String get ridePuckDark => 'Dunkel';

  @override
  String get ridePuckLight => 'Hell';

  @override
  String get ridePuckBergA => 'Berg-A';

  @override
  String get ridePuckTopDown => 'Rad von oben';

  @override
  String get ridePuckHofTor => 'Hof-Tor';

  @override
  String get ridePuckKomet => 'Aether-Komet';

  @override
  String get ridePuckKiesel => 'Kiesel';

  @override
  String get ridePuckLenkerBug => 'Lenker-Bug';

  @override
  String get ridePuckLichtkegel => 'Lichtkegel';

  @override
  String get ridePuckChevron => 'Chevron';

  @override
  String get ridePuckBergASub => 'Buchstabe, Berg und Pfeil in einem';

  @override
  String get ridePuckTopDownSub =>
      'Orthografisch: Nase, Hörner, zwei Reifen — dreht mit';

  @override
  String get ridePuckHofTorSub => 'Zwei Schenkel, unten offen';

  @override
  String get ridePuckKometSub => 'Speerblatt mit orangem Funken';

  @override
  String get ridePuckKieselSub => 'Weiches Dreieck mit Halo';

  @override
  String get ridePuckLenkerBugSub => 'Spitze Nase, zwei Lenkerhörner';

  @override
  String get ridePuckLichtkegelSub => 'Dunkle Scheibe, oranger Kegel';

  @override
  String get ridePuckChevronSub => 'Standard-Navi-Pfeil';

  @override
  String get rideChipLive => 'Live';

  @override
  String get rideChipRouteOffline => 'Route offline';

  @override
  String get rideChipOfflineMapOk => 'Offline · Karte ok · Reroute: Netz';

  @override
  String get rideChipMapsMissing => 'Karten fehlen';

  @override
  String get rideCardinalN => 'N';

  @override
  String get rideCardinalNE => 'NO';

  @override
  String get rideCardinalE => 'O';

  @override
  String get rideCardinalSE => 'SO';

  @override
  String get rideCardinalS => 'S';

  @override
  String get rideCardinalSW => 'SW';

  @override
  String get rideCardinalW => 'W';

  @override
  String get rideCardinalNW => 'NW';

  @override
  String get navCueArrive => 'Ziel erreicht';

  @override
  String get navCueSlightLeft => 'Leicht links';

  @override
  String get navCueSlightRight => 'Leicht rechts';

  @override
  String get navCueTurnLeft => 'Links abbiegen';

  @override
  String get navCueTurnRight => 'Rechts abbiegen';

  @override
  String get navCueSharpLeft => 'Scharf links';

  @override
  String get navCueSharpRight => 'Scharf rechts';

  @override
  String liveHintBracketRun(String n) {
    return 'Durchgang $n erfasst';
  }

  @override
  String get liveHintImpactStreak => 'Harte Schlagfolge erkannt';

  @override
  String get liveHintStandSetup => 'Stand: Setup prüfen möglich';

  @override
  String get maintForkLower => 'Gabel Lower-Leg Service';

  @override
  String get maintForkFull => 'Gabel Vollservice (Feder/Dämpfer)';

  @override
  String get maintShockAir => 'Dämpfer Air-Can Service';

  @override
  String get maintShockFull => 'Dämpfer Vollservice';

  @override
  String get maintChainWear => 'Kettenverschleiß prüfen';

  @override
  String get maintCassetteCheck => 'Kassette prüfen (nach 2–3 Ketten)';

  @override
  String get maintPadsFront => 'Bremsbeläge vorne prüfen';

  @override
  String get maintPadsRear => 'Bremsbeläge hinten prüfen';

  @override
  String get maintSealant => 'Tubeless-Milch erneuern';

  @override
  String get maintDropper => 'Dropper Lower-Post Service';

  @override
  String maintDays(String n) {
    return '$n Tage';
  }

  @override
  String get maintNoInterval => 'Kein Intervall';

  @override
  String get compatTitleDrv011 => 'Kassette benötigt passenden Freilaufkörper';

  @override
  String get compatTitleFrm004 => 'Hinterbau-Einbaubreite muss zur Nabe passen';

  @override
  String get compatTitleSus007 => 'Dämpfer-Maß muss zur Rahmenvorgabe passen';

  @override
  String get compatTitleSus012 => 'Gabel-Schaft vs. Steuersatz (S.H.I.S.)';

  @override
  String get compatTitleBrk003 => 'Bremssattel-Aufnahme am Rahmen';

  @override
  String get compatTitleBrk008 => 'Bremsscheiben-Aufnahme vs. Nabe';

  @override
  String get compatTitleBrk008f => 'Bremsscheibe vorne vs. Vorderradnabe';

  @override
  String get compatTitleWhl005 => 'Reifenbreite zur Felgen-Maulweite';

  @override
  String get compatTitleWhl005f => 'Vorderreifen zur Felgen-Maulweite';

  @override
  String get compatTitleWhl009 => 'Reifen-Außenmaß vs. Rahmenfreigang';

  @override
  String get compatTitleCkp002 => 'Lenker-Klemmdurchmesser vs. Vorbau';

  @override
  String get compatTitleSpt006 => 'Sattelstützendurchmesser vs. Sitzrohr';

  @override
  String get compatTitleBb003 => 'Innenlager-Standard vs. Kurbelwelle';

  @override
  String get compatTitleBb003f => 'Innenlager vs. Rahmen-Standard';

  @override
  String get compatTitleEbk002 => 'Motor-Interface nur bei OEM-Freigabe';

  @override
  String get compatTitleFrm004f => 'Vorderrad-Achse vs. Gabel';

  @override
  String compatFailDrv011(String cassette, String hub) {
    return 'Die Kassette benötigt $cassette, deine Nabe hat $hub.';
  }

  @override
  String compatFailFrm004(String frame, String hub) {
    return 'Rahmen-Einbaubreite $frame ≠ Nabe $hub.';
  }

  @override
  String compatFailSus007(String eye, String stroke, String mount) {
    return 'Dämpfer $eye×$stroke ($mount) passt nicht zur Rahmenvorgabe.';
  }

  @override
  String compatFailSus012(String fork, String headset) {
    return 'Gabel-Schaft $fork passt nicht zum Steuersatz $headset.';
  }

  @override
  String compatFailBrk003(String caliper, String frame) {
    return 'Bremssattel $caliper vs. Rahmenaufnahme $frame.';
  }

  @override
  String compatFailBrk008(String rotor, String hub) {
    return 'Scheibe $rotor ≠ Nabe $hub.';
  }

  @override
  String compatFailBrk008f(String rotor, String hub) {
    return 'Vordere Scheibe $rotor ≠ Nabe $hub.';
  }

  @override
  String compatFailWhl005(String tire, String rim) {
    return 'Reifenbreite $tire mm außerhalb Bereich für Maulweite $rim mm.';
  }

  @override
  String compatFailWhl005f(String tire, String rim) {
    return 'Vorderreifen $tire mm außerhalb Bereich für $rim mm.';
  }

  @override
  String compatFailWhl009(String tire, String max) {
    return 'Reifenbreite $tire mm > Rahmenfreigang $max mm.';
  }

  @override
  String compatFailCkp002(String bar, String stem) {
    return 'Lenkerklemmung $bar mm ≠ Vorbau $stem mm.';
  }

  @override
  String compatFailSpt006(String post, String frame) {
    return 'Stütze Ø $post passt nicht zu Rahmen Ø $frame.';
  }

  @override
  String compatFailBb003(String bb, String crank) {
    return 'Innenlager-Welle $bb ≠ Kurbel $crank.';
  }

  @override
  String compatFailBb003f(String bb, String frame) {
    return 'Innenlager $bb ≠ Rahmen $frame.';
  }

  @override
  String compatFailEbk002(String frame, String motor) {
    return 'Motortausch außerhalb OEM-Freigabe unzulässig. Frame $frame ≠ Motor $motor.';
  }

  @override
  String compatFailFrm004f(String fork, String hub) {
    return 'Gabel-Achse $fork ≠ Nabe $hub.';
  }

  @override
  String get compatRuleOk => 'Regel erfüllt.';

  @override
  String get compatConditional => 'Bedingt kompatibel';

  @override
  String get compatMissingFacts =>
      'Fehlende Attribute — kein COMPATIBLE ohne vollständige Faktenlage.';

  @override
  String get compatWorkshopHint =>
      'Sicherheitsrelevante Montage: Fachwerkstatt. Drehmomente nur aus Herstellerdokumenten.';

  @override
  String get compatConditionBrk003 =>
      'Nur mit passendem Adapter (Post Mount ↔ IS).';

  @override
  String get compatDatasheet => 'Herstellerdatenblatt prüfen';

  @override
  String get attrFreehub => 'Freilauf-Standard';

  @override
  String get attrRearSpacing => 'Hinterbau-Einbaubreite';

  @override
  String get attrEyeToEye => 'Einbaulänge (Auge-zu-Auge)';

  @override
  String get attrStroke => 'Hub';

  @override
  String get attrMountType => 'Montage-Typ';

  @override
  String get attrShockEyeToEye => 'Rahmenvorgabe: Einbaulänge';

  @override
  String get attrShockStroke => 'Rahmenvorgabe: Hub';

  @override
  String get attrShockMount => 'Rahmenvorgabe: Montage-Typ';

  @override
  String get attrSteerer => 'Gabelschaft';

  @override
  String get attrBrakeMount => 'Bremssattel-Aufnahme';

  @override
  String get attrBrakeMountRear => 'Rahmen: Bremsaufnahme hinten';

  @override
  String get attrRotorMount => 'Scheiben-Aufnahme';

  @override
  String get attrTireWidth => 'Reifenbreite';

  @override
  String get attrRimWidth => 'Felgen-Maulweite (innen)';

  @override
  String get attrMaxTire => 'Rahmen: max. Reifenfreigang';

  @override
  String get attrBarClamp => 'Klemmdurchmesser';

  @override
  String get attrStemClamp => 'Vorbau-Klemmung';

  @override
  String get attrSeatpostDia => 'Durchmesser';

  @override
  String get attrMinInsert => 'Min. Einstecktiefe';

  @override
  String get attrMaxInsert => 'Rahmen: max. Einstecktiefe';

  @override
  String get attrCrankAxle => 'Kurbelwelle';

  @override
  String get attrBbStandard => 'Innenlager-Standard';

  @override
  String get attrMotorInterface => 'Motor-Interface';

  @override
  String get attrAxleFront => 'Achse';

  @override
  String get howToFreehub => 'Aufdruck Freilaufkörper / Naben-Datenblatt';

  @override
  String get howToRearSpacing => 'Rahmen-/Naben-Spec (Boost 148, 142×12, …)';

  @override
  String get howToEyeToEye => 'Dämpfer-Aufdruck';

  @override
  String get howToStroke => 'Dämpfer-Katalog';

  @override
  String get howToMountType => 'Trunnion vs. Eyelet';

  @override
  String get howToSteerer => '1⅛″ oder tapered 1,5″ / S.H.I.S.';

  @override
  String get howToBrakeMount => 'Post Mount / Flat Mount / IS';

  @override
  String get howToBrakeMountRear => 'Rahmen-Spec';

  @override
  String get howToRotorMount => 'Center Lock oder 6-Loch';

  @override
  String get howToTireWidth => 'ETRTO';

  @override
  String get howToRimWidth => 'Felgen-Datenblatt';

  @override
  String get howToMaxTire => 'Rahmen-Herstellerangabe';

  @override
  String get howToBarClamp => '31,8 oder 35,0';

  @override
  String get howToStemClamp => 'Vorbau-Datenblatt';

  @override
  String get howToSeatpostDia => '27,2 / 30,9 / 31,6 / 34,9';

  @override
  String get howToMinInsert => 'Dropper-Handbuch';

  @override
  String get howToMaxInsert => 'Rahmen-Geometrie';

  @override
  String get howToCrankAxle => 'DUB / 24mm / 30mm';

  @override
  String get howToBbStandard => 'BSA / T47 / PF92 / …';

  @override
  String get howToMotorInterface => 'z. B. bosch_smart_system';

  @override
  String get howToAxleFront => '15×100 / 15×110 Boost / …';

  @override
  String postRideObsImpacts(String count, String km) {
    return 'Viele harte Impacts ($count auf $km km) — Front/Dämpfer stark belastet.';
  }

  @override
  String postRideObsSmooth(String km) {
    return 'Wenige Impacts bei $km km — eher flowig oder glatter Untergrund.';
  }

  @override
  String postRideObsFlowHigh(String flow) {
    return 'Hoher Flow-Score ($flow) — Tempo und Linienwahl wirkten stimmig.';
  }

  @override
  String postRideObsFlowLow(String flow) {
    return 'Niedriger Flow-Score ($flow) — viele Tempo-Brüche oder Stopps.';
  }

  @override
  String postRideObsPeakG(String g) {
    return 'Peak $g g — harte Einschläge; Setup und Reifendruck prüfen.';
  }

  @override
  String get postRideFrontTooFirm => 'zu hart';

  @override
  String get postRideFrontOk => 'ok';

  @override
  String get postRideBumpsHarsh => 'rau';

  @override
  String postRideObsFbHarsh(String front, String bumps) {
    return 'Feedback: Front $front · kleine Schläge $bumps.';
  }

  @override
  String get postRideObsFbSoft =>
      'Feedback: Front wirkt weich / taucht beim Anbremsen ab.';

  @override
  String get postRideSugReboundSlowTitle =>
      'Zugstufe Gabel: 2 Klicks langsamer';

  @override
  String postRideSugReboundSlowContent(String current, String next) {
    return 'Aktuell ca. $current Klicks von geschlossen → Ziel $next.';
  }

  @override
  String get postRideSugReboundSlowEffect =>
      'Ruhigere Front bei Schlagfolgen, etwas weniger Pop.';

  @override
  String get postRideSugReboundFastTitle =>
      'Zugstufe Gabel: 2 Klicks schneller';

  @override
  String postRideSugReboundFastContent(String current, String next) {
    return 'Aktuell ca. $current Klicks → Ziel $next (weniger Dive).';
  }

  @override
  String get postRideSugReboundFastEffect =>
      'Stabileres Anbremsen, weniger Durchschlag-Gefühl.';

  @override
  String get postRideSugPressureTitle => 'Luftdruck Front prüfen';

  @override
  String get postRideSugPressureContent =>
      'Sehr hohe Peak-g — Druck und Volumen-Spacer gegen Hersteller-Tabelle halten.';

  @override
  String get postRideSugPressureEffect =>
      'Weniger Bottom-out-Risiko, klareres Feedback.';

  @override
  String get postRideSugLimitsClicks =>
      'Herstellerbereich typisch 0–14 Klicks von geschlossen.';

  @override
  String get postRideSugLimitsPressure =>
      'Nur im freigegebenen Druckbereich des Reifens/Gabel.';

  @override
  String get postRideReasonHarshBumps => 'Feedback „kleine Schläge rau“';

  @override
  String get postRideReasonFrontFirm => 'Feedback „Front zu hart“';

  @override
  String postRideReasonImpacts(String count, String km) {
    return '$count Impacts / $km km';
  }

  @override
  String postRideReasonRms(String rms) {
    return 'RMS $rms g';
  }

  @override
  String get postRideReasonFrontLoad => 'Hohe Schlagbelastung an der Front';

  @override
  String get postRideReasonDive => 'Feedback „taucht ab“';

  @override
  String get postRideReasonFrontSoft => 'Feedback „Front zu weich“';

  @override
  String get postRideReasonSoftDive => 'Front zu weich / Dive';

  @override
  String get postRideReasonPeakLong => 'Peak ≥ 5 g bei längerer Fahrt';

  @override
  String get postRideAnalysis => 'Analyse';

  @override
  String postRideExpect(String text) {
    return 'Erwartung: $text';
  }

  @override
  String postRideLimit(String text) {
    return 'Grenze: $text';
  }

  @override
  String get postRideEvidence => 'Evidenz';

  @override
  String postRideConfidence(String level) {
    return 'Konfidenz $level';
  }

  @override
  String get postRideConfHigh => 'hoch';

  @override
  String get postRideConfMedium => 'mittel';

  @override
  String get postRideConfLow => 'niedrig';

  @override
  String postRideFactRide(String km, String hm, String min) {
    return '$km km · $hm hm · $min min';
  }

  @override
  String postRideFactMetrics(String flow, String g, String impacts) {
    return 'Flow $flow · Peak $g g · $impacts Impacts';
  }

  @override
  String postRideFactMetricsLean(
      String flow, String g, String impacts, String lean) {
    return 'Flow $flow · Peak $g g · $impacts Impacts · Lean $lean°';
  }

  @override
  String postRideFactBike(String name) {
    return 'Bike: $name';
  }

  @override
  String postRideFactSoc(String soc) {
    return 'SOC $soc%';
  }

  @override
  String get rideGPeak => 'G-Peak';

  @override
  String get rideLean => 'Neig.';

  @override
  String get rideFlow => 'Flow';

  @override
  String garageSetNamed(String name) {
    return '$name setzen';
  }

  @override
  String get bleKindPower => 'Powermeter';

  @override
  String get bleKindOtherDrive => 'E-Antrieb';

  @override
  String get bleTipBosch => 'Flow komplett schließen · 10–20 cm am Display';

  @override
  String get bleTipShimano =>
      'E-TUBE schließen · in 15 s nach Power/Taster tippen';

  @override
  String get bleTipYamaha => 'e-Sync schließen · Tempo über CSC-Sensor';

  @override
  String get bleTipOtherDrive =>
      'Hersteller-App schließen · Display an, nah halten';

  @override
  String get bleTipCsc => 'Sensor am Rad wecken, nah halten';

  @override
  String get bleTipPower => 'Powermeter einschalten, nah halten';

  @override
  String get blePairLeadEbike =>
      'Display an, Hersteller-App zu, Handy nah — dann antippen.';

  @override
  String get blePairLeadSensor =>
      'Sensor am Rad wecken, nicht die Uhr am Handgelenk.';

  @override
  String get bleNoteSensorBrand => 'Sensor';

  @override
  String get bleNoteSensorLine =>
      'Magnet oder Kurbel, nah an den Sensor — nicht die Uhr.';

  @override
  String get bleNoteBoschLine =>
      'Flow komplett schließen (nicht nur Hintergrund). Display an, 10–20 cm.';

  @override
  String get bleNoteShimanoLine =>
      'E-TUBE schließen. Nach Power oder Taster oft nur 15 s — dann tippen.';

  @override
  String get bleNoteYamahaLine =>
      'e-Sync bzw. TQ-App zu. Live-Tempo meist nur über CSC-Sensor.';

  @override
  String get bleNoteFazuaLine =>
      'Remote an — CSC und Power wie ein normaler Sensor.';

  @override
  String get bleNoteOtherBrand => 'Andere';

  @override
  String get bleNoteOtherLine =>
      'RideControl / Mission Control schließen. Ein Phone, Display an.';

  @override
  String get bleGattWatchRejected =>
      'Verbindung abgelehnt — andere Fitness-App schließen, Uhr nah halten.';

  @override
  String get bleGattWatchTimeout =>
      'Timeout — Uhr nah halten, Broadcast-Herzfrequenz prüfen.';

  @override
  String get bleGattWatchFailed => 'Uhr-Verbindung fehlgeschlagen';

  @override
  String get bleGattRejectedBosch =>
      'Verbindung abgelehnt — Bosch Flow schließen, Display an, 10–20 cm.';

  @override
  String get bleGattRejectedShimano =>
      'Verbindung abgelehnt — E-TUBE schließen, Display an, nah halten.';

  @override
  String get bleGattRejectedGeneric =>
      'Verbindung abgelehnt — Bosch Flow / Shimano E-TUBE schließen, Display an, nah halten.';

  @override
  String get bleGattTimeoutBosch =>
      'Timeout — Display wecken, Flow zu, nah halten. Motorwerte nur mit CSC oder offiziellem LDI.';

  @override
  String get bleGattTimeoutShimano =>
      'Timeout — E-TUBE zu, in 15 s nach Power/Taster tippen.';

  @override
  String get bleGattTimeoutDrive =>
      'Timeout — Hersteller-App zu, Display an. Tempo über CSC-Sensor.';

  @override
  String get bleGattTimeoutSensor => 'Timeout — Sensor wecken, näher rangehen.';

  @override
  String get bleDriveFailBosch =>
      'Bosch erkannt, keine Live-Motorwerte. Als Nächstes einen Radsensor (CSC) koppeln.';

  @override
  String get bleDriveFailShimano =>
      'Shimano erkannt, keine Live-Motorwerte. Als Nächstes einen Radsensor (CSC) koppeln.';

  @override
  String get bleDriveFailYamaha =>
      'Yamaha erkannt, keine Live-Motorwerte. Tempo über CSC-Sensor koppeln.';

  @override
  String get bleDriveFailGeneric =>
      'Antrieb erkannt, keine Live-Motorwerte. Als Nächstes einen Radsensor (CSC) koppeln.';

  @override
  String get bleStatusBtOff => 'Bluetooth aus';

  @override
  String get bleStatusScanFailed => 'Radsensor-Suche fehlgeschlagen';

  @override
  String get bleStatusNoSensor => 'Kein Radsensor gefunden';

  @override
  String get bleStatusNoneInRange =>
      'Kein Rad, Antrieb oder Sensor in Reichweite';

  @override
  String get bleStatusDriveSeen =>
      'Antrieb gesehen — in der Werkstatt koppeln (Bosch/Shimano)';

  @override
  String get bleStatusNoCscInRange => 'Kein Radsensor in Reichweite';

  @override
  String get bleStatusSensorDisconnected => 'Radsensor getrennt';

  @override
  String get bleStatusReconnectLost =>
      'Verbindung verloren — Display prüfen, Flow/E-TUBE schließen, in der Werkstatt erneut koppeln.';

  @override
  String bleStatusRetry(String n, String max) {
    return 'Verbinde … Retry $n/$max';
  }

  @override
  String bleStatusAttempt(String n, String max) {
    return 'Verbinde … Versuch $n/$max';
  }

  @override
  String bleStatusReconnect(String n, String max) {
    return 'Verbinde erneut … ($n/$max)';
  }

  @override
  String bleStatusDriveNoLive(String who) {
    return '$who · erkannt — Tempo über CSC, Akku nur mit Standard-GATT';
  }

  @override
  String get bleStatusNeedBond =>
      'Display braucht Bluetooth-Kopplung für den Akku.';

  @override
  String get bleStatusBonding => 'System-Kopplung …';

  @override
  String bleStatusDriveNeedBond(String who) {
    return '$who · erkannt — Akku nach Bluetooth-Kopplung in der Werkstatt';
  }

  @override
  String bleConnectedNamed(String name) {
    return '$name verbunden';
  }

  @override
  String get bleWordSensor => 'Sensor';

  @override
  String get bleWordWatch => 'Uhr';

  @override
  String get bleSectionDrive => 'Antrieb';

  @override
  String get bleSectionSensors => 'Sensoren';

  @override
  String get watchStatusPickFromList => 'Uhr in der Liste wählen';

  @override
  String get watchStatusScanFailed => 'Uhr-Suche fehlgeschlagen';

  @override
  String get watchStatusConnectedSim => 'Uhr verbunden (Sim)';

  @override
  String get watchStatusDisconnected => 'Uhr getrennt';

  @override
  String get watchStatusNoHrService =>
      'Uhr gefunden, aber ohne Standard-Puls-Service';

  @override
  String get watchStatusReconnectLost =>
      'Uhr getrennt — Broadcast prüfen, in der Nähe erneut koppeln.';

  @override
  String watchStatusReconnect(String n, String max) {
    return 'Uhr verbindet erneut … ($n/$max)';
  }

  @override
  String watchStatusBattery(String n) {
    return 'Uhr-Akku $n %';
  }

  @override
  String get watchHrSensorFallback => 'Herzfrequenz-Sensor';

  @override
  String get watchCheckBluetooth => 'Bluetooth prüfen';

  @override
  String get watchOutOfRange => 'Uhr nicht in Reichweite';

  @override
  String get watchRemoved => 'Uhr entfernt';

  @override
  String watchRememberedOffline(String name) {
    return '$name · gemerkt, nicht live';
  }

  @override
  String get watchRememberedOfflineNoName => 'Gemerkt, nicht live';

  @override
  String watchLiveNamed(String name) {
    return '$name · live';
  }

  @override
  String watchLiveBpm(String name, String bpm) {
    return '$name · $bpm bpm';
  }

  @override
  String get watchHonestyHr => 'Puls per Standard-BLE';

  @override
  String get watchHonestyGarmin => 'Garmin: Broadcast-HR einschalten';

  @override
  String get watchHonestyApple => 'Apple Watch: kein Standard-BLE-Puls';

  @override
  String get watchHonestyGalaxy => 'Galaxy: meist kein 0x180D';

  @override
  String get watchHonestyUnknown => 'Nur mit Heart Rate 0x180D';

  @override
  String get watchTipHr => 'Sensor- oder Broadcast-Modus an, nah halten';

  @override
  String get watchTipGarmin =>
      'In der Garmin-Uhr: Herzfrequenz senden / Broadcast';

  @override
  String get watchTipApple =>
      'Kein BLE-Puls zu Android — HealthKit nur auf iPhone';

  @override
  String get watchTipGalaxy =>
      'Nur wenn die Uhr Heart Rate 0x180D sendet — sonst Samsung Health';

  @override
  String get watchTipUnknown => 'Heart Rate 0x180D muss aktiv sein';

  @override
  String get watchNotePolarBrand => 'Polar / Gurt';

  @override
  String get watchNotePolarLine =>
      'Sensor-Modus an. Standard-Puls 0x180D — das koppeln wir.';

  @override
  String get watchNoteGarminLine =>
      'Herzfrequenz senden / Broadcast in den Uhr-Einstellungen.';

  @override
  String get watchNoteAppleLine =>
      'Kein Standard-BLE-Puls zu Android. Nicht koppeln.';

  @override
  String get watchNoteGalaxyLine =>
      'Meist nur Samsung Health. Nur mit sichtbarem 0x180D.';

  @override
  String get watchPairLeadText =>
      'Puls am Fahrer, nicht am Rad. Nur echter Heart-Rate-Service 0x180D.';

  @override
  String get blePairAgain => 'Neu koppeln';

  @override
  String get bleRemoveDevice => 'Gerät entfernen';

  @override
  String get bleSemanticsPaired => 'Bluetooth gekoppelt';

  @override
  String get bleSemanticsPair => 'Bluetooth koppeln';

  @override
  String get bleTooltipPair => 'Antrieb oder Sensor koppeln';

  @override
  String get bleRemoveWheel => 'Radsensor entfernen';

  @override
  String get bleRemoveDrive => 'Antrieb entfernen';

  @override
  String get bleSemanticsLive => 'Bluetooth live';

  @override
  String get bleTooltipSaved => 'Gekoppelt, nicht verbunden';

  @override
  String get watchOtherWatch => 'Andere Uhr';

  @override
  String get bikeCatMtbTrail => 'MTB Trail';

  @override
  String get bikeCatMtb => 'MTB';

  @override
  String get bikeCatEnduro => 'Enduro';

  @override
  String get bikeCatDh => 'Downhill';

  @override
  String get bikeCatGravel => 'Gravel';

  @override
  String get bikeCatRoad => 'Rennrad';

  @override
  String get bikeCatUrban => 'City';

  @override
  String get bikeCatCargo => 'Lastenrad';

  @override
  String get bikeCatFolding => 'Faltrad';

  @override
  String get bikeCatKids => 'Kinderrad';

  @override
  String get bikeCatEmtb => 'E-MTB';

  @override
  String get bikeCatEtrekking => 'E-Trekking';

  @override
  String get bikeCatHiking => 'Zu Fuß';

  @override
  String get bikeCatEgravel => 'E-Gravel';

  @override
  String get bikeCatEcity => 'E-City';

  @override
  String get bikeCatEcargo => 'E-Lastenrad';

  @override
  String get bikeCatEfolding => 'E-Faltrad';

  @override
  String get bikeCatEkids => 'E-Kinderrad';

  @override
  String get bikeCatEroad => 'E-Road';

  @override
  String get bikeBlurbMtbTrail => 'Singletrails & Wald';

  @override
  String get bikeBlurbMtb => 'Trails & Touren';

  @override
  String get bikeBlurbEnduro => 'Steil & technisch';

  @override
  String get bikeBlurbDh => 'Bikepark & Abfahrt';

  @override
  String get bikeBlurbGravel => 'Schotter & Distanz';

  @override
  String get bikeBlurbRoad => 'Asphalt & Tempo';

  @override
  String get bikeBlurbUrban => 'Alltag & Pendeln';

  @override
  String get bikeBlurbCargo => 'Lasten & Alltag';

  @override
  String get bikeBlurbFolding => 'Falten & mitnehmen';

  @override
  String get bikeBlurbKids => 'Kinderrad';

  @override
  String get bikeBlurbEmtb => 'Trail mit Assist';

  @override
  String get bikeBlurbEtrekking => 'Touren mit Assist';

  @override
  String get bikeBlurbHiking => 'Zu Fuß unterwegs';

  @override
  String get bikeBlurbMtbTrailFocus => 'Singletrail-Fokus';

  @override
  String get onboardSportTrail => 'Trail';

  @override
  String sportsSummaryPrimary(String label) {
    return 'Haupt: $label';
  }

  @override
  String sportsSummaryPrimaryAlso(String label, String list) {
    return 'Haupt: $label · auch $list';
  }

  @override
  String get seasonYearRound => 'Ganzjährig';

  @override
  String get seasonSpringSummer => 'Frühling–Sommer';

  @override
  String get seasonAutumn => 'Herbst';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get naeheInYourRegion => '~60 Min in deiner Region';

  @override
  String get naeheAroundYou => '~60 Min um dich';

  @override
  String get sportTagTouring => 'Touring';

  @override
  String get sportTagEbike => 'E-Bike';

  @override
  String get overlayRheinNeckar => 'Rhein-Neckar / Heidelberg';

  @override
  String get overlaySchwarzwaldNord => 'Schwarzwald Süd';

  @override
  String get overlayBodensee => 'Bodensee';

  @override
  String get overlayStuttgart => 'Stuttgart / Mittlerer Neckar';

  @override
  String get overlayMuenchen => 'München & Umland';

  @override
  String get overlayNuernberg => 'Nürnberg / Franken';

  @override
  String get overlayFrankfurtRheinMain => 'Frankfurt Rhein-Main';

  @override
  String get overlayKoelnRhein => 'Köln / Rheinland';

  @override
  String get overlayHamburg => 'Hamburg & Umland';

  @override
  String get overlayBerlin => 'Berlin & Brandenburg';

  @override
  String get overlayDresdenElbland => 'Dresden / Elbland';

  @override
  String get overlayWien => 'Wien & Wienerwald';

  @override
  String get overlaySalzburg => 'Salzburg';

  @override
  String get overlayInnsbruck => 'Innsbruck / Tirol';

  @override
  String get overlayZuerich => 'Zürich & Umland';

  @override
  String get overlayBern => 'Bern / Mittelland';

  @override
  String get overlayBasel => 'Basel / Dreiländereck';

  @override
  String get overlayRuhrgebiet => 'Ruhrgebiet';

  @override
  String get overlayDuesseldorf => 'Düsseldorf / Niederrhein';

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
  String get overlayKiel => 'Kiel / Förde';

  @override
  String get overlayRostock => 'Rostock / Warnow';

  @override
  String get overlayKassel => 'Kassel / Bergpark';

  @override
  String get overlayTrierMosel => 'Trier / Mosel';

  @override
  String get overlayPfalz => 'Pfälzerwald';

  @override
  String get overlaySauerland => 'Sauerland';

  @override
  String get overlayEifelTrails => 'Eifel';

  @override
  String get overlayHarz => 'Harz';

  @override
  String get overlayThueringerWald => 'Thüringer Wald';

  @override
  String get overlayBayerischerWald => 'Bayerischer Wald';

  @override
  String get overlayAllgaeu => 'Allgäu';

  @override
  String get overlayChiemgau => 'Chiemgau';

  @override
  String get overlaySaarbruecken => 'Saarbrücken';

  @override
  String get overlayMuenster => 'Münsterland';

  @override
  String get overlayAachen => 'Aachen / Dreiländereck';

  @override
  String get overlayLuebeck => 'Lübeck / Trave';

  @override
  String get overlayBremen => 'Bremen / Weser';

  @override
  String get overlayMagdeburg => 'Magdeburg / Elbe';

  @override
  String get overlayErfurt => 'Erfurt';

  @override
  String get overlayKoblenz => 'Koblenz / Rhein-Mosel';

  @override
  String get overlayGraz => 'Graz / Murtal';

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
  String get overlayGenf => 'Genf / Lac Léman';

  @override
  String get overlayLausanne => 'Lausanne / Lavaux';

  @override
  String get overlayLuzern => 'Luzern / Vierwaldstättersee';

  @override
  String get overlayStGallen => 'St. Gallen / Appenzell';

  @override
  String get overlayLugano => 'Lugano / Tessin';

  @override
  String get overlayInterlaken => 'Interlaken / Berner Oberland';

  @override
  String get overlayChur => 'Chur / Graubünden';

  @override
  String get overlayZermatt => 'Zermatt / Mattertal';

  @override
  String get overlayStMoritz => 'St. Moritz / Engadin';

  @override
  String get overlayDavos => 'Davos / Landwasser';

  @override
  String get overlayStrasbourg => 'Straßburg / Ill';

  @override
  String get overlayAlsaceVins => 'Elsass / Route des Vins';

  @override
  String get overlayVosges => 'Vogesen / Ballon d\'Alsace';

  @override
  String get overlayNancyMoselle => 'Nancy / Moselle';

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
  String get overlayParis => 'Paris / Bois & Seine';

  @override
  String get overlayLille => 'Lille / Citadelle';

  @override
  String get overlayNice => 'Nizza / Promenade des Anglais';

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
    return 'Karte (Zoom $min–$max)…';
  }

  @override
  String offlineProgressMapPercent(String percent) {
    return 'Karte $percent%';
  }

  @override
  String get offlineProgressActivating => 'Aktivieren…';

  @override
  String get offlineProgressManifest => 'Manifest…';

  @override
  String offlineProgressPackFile(String file) {
    return 'Pack $file…';
  }

  @override
  String get offlineProgressGraphFile => 'offline_graph.json…';

  @override
  String get offlineProgressDemoGraph => 'Demo-Graph (Schwarzwald)…';

  @override
  String get offlinePacksReadyOne => '1 Pack ladbar';

  @override
  String offlinePacksReadyCount(int count) {
    return '$count Packs ladbar';
  }

  @override
  String offlinePackNotBuilt(String name) {
    return '$name: Pack noch nicht gebaut — kein Download.';
  }

  @override
  String offlineShaMismatch(String sha) {
    return 'SHA-256 stimmt mit keinem Download überein (erwartet $sha)';
  }

  @override
  String offlineInvalidGraphFolder(String id) {
    return 'Ordner $id enthält keinen gültigen Graph für diese Region';
  }

  @override
  String offlineNoRemotePack(String name) {
    return 'Kein Remote-Pack für $name. Catalog-Stubs aktivieren keinen fremden Demo-Graph.';
  }

  @override
  String get offlineDownloadEmpty => 'Download leer';

  @override
  String get offlineNoGraphAfterExtract => 'Kein Graph nach Extract';

  @override
  String get offlineRawPmtiles =>
      'Roh-.pmtiles wird nicht unterstützt — MapLibre-Style-JSON mit pmtiles://-Source nötig.';

  @override
  String get offlineInvalidUrl => 'Ungültige URL';

  @override
  String get offlineExpectStyleJson =>
      'Erwarte Style-JSON-URL (*.json oder /styles/…), keine Tile-Datei.';

  @override
  String get offlineSubActive => 'Aktiv — tippen zum Aktualisieren';

  @override
  String get offlineSubInstalled => 'Installiert — tippen zum Aktivieren';

  @override
  String get offlineSubDemoGraph => 'Demo-Graph in der App (kein Remote-Pack)';

  @override
  String get offlineSubNotBuilt => 'Noch nicht gebaut';

  @override
  String get offlineSubLoad => 'Routing + Karte laden';

  @override
  String offlineSubLoadSized(String size) {
    return '$size · Routing + Karte';
  }

  @override
  String offlineGraphMissing(String name) {
    return 'Kein Graph in $name';
  }

  @override
  String offlineGraphSha(String name) {
    return 'Graph-SHA von $name stimmt nicht';
  }

  @override
  String offlineGraphDemoMismatch(String name) {
    return 'Demo-Graph Schwarzwald passt nicht zu $name';
  }

  @override
  String get offlineEngineLinkedNoTiles =>
      'Graph-Engine · Valhalla gelinkt, Region-Tiles fehlen noch';

  @override
  String get offlineEngineTilesNotBuilt =>
      'Graph-Engine · Valhalla-Tiles nicht gebaut';

  @override
  String get offlineNoTiles => 'keine Tiles';

  @override
  String get offlineFfiMissing =>
      'FFI fehlt — graph-only / Valhalla-Flag nicht gelinkt';

  @override
  String get offlineValhallaTilesLinked =>
      'Valhalla-Tiles · libvalhalla gelinkt';

  @override
  String offlineValhallaTilesUnlinked(String code) {
    return 'Valhalla-Tiles · UNLINKED (Code $code)';
  }

  @override
  String get offlineValhallaFeature => 'Valhalla-Feature verfügbar';

  @override
  String get offlineValhallaNotLinked => 'Valhalla nicht gelinkt';

  @override
  String get garageMuscle => 'Muskel';

  @override
  String garageOemTaken(String name, int count) {
    return '$name: $count Serienteile übernommen.';
  }

  @override
  String garageOemTakenPartial(String name, int taken, int skipped) {
    return '$name: $taken Serienteile, $skipped übersprungen.';
  }

  @override
  String garageOemKitOff(String name) {
    return '$name abgestellt — Teile selbst anlegen, Kit war aus.';
  }

  @override
  String garageGpxSaved(String name, String km) {
    return '$name: GPX gespeichert ($km km).';
  }

  @override
  String garageKmImported(String km) {
    return '+$km km importiert';
  }

  @override
  String get garageLogOdoUpdated => 'Kilometerstand aktualisiert';

  @override
  String get garageLogHoursUpdated => 'Betriebsstunden aktualisiert';

  @override
  String get garageLogGpxImport => 'GPX importiert';

  @override
  String get garageLogImportPlaceholder => 'Import ohne Komponenten';

  @override
  String garageLogManualKm(String km) {
    return 'Manuell: $km km';
  }

  @override
  String garageLogManualHours(String hours) {
    return 'Manuell: $hours h';
  }

  @override
  String garageLogPsiFront(String psi) {
    return 'vorn $psi psi';
  }

  @override
  String garageLogPsiRear(String psi) {
    return 'hinten $psi psi';
  }

  @override
  String garageLogBarFront(String bar) {
    return 'vorn $bar bar';
  }

  @override
  String garageLogBarRear(String bar) {
    return 'hinten $bar bar';
  }

  @override
  String get bikeCatEmtbTrail => 'E-MTB Trail';

  @override
  String get bikeCatEenduro => 'E-Enduro';

  @override
  String get bikeCatEdh => 'E-DH';

  @override
  String discoverCatalogTours(int count) {
    return 'Katalog $count Touren';
  }

  @override
  String discoverCatalogToursSuffix(int count) {
    return ' · Katalog $count';
  }

  @override
  String discoverToursOsmStatus(int tours, int withTrack, int osm) {
    return 'Touren $tours ($withTrack mit Track) · OSM $osm';
  }

  @override
  String discoverElevationApprox(String hm) {
    return '~$hm hm (Distanz-Schätzung — Höhen-API nicht erreichbar)';
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
    return '$n Min';
  }

  @override
  String discoverPlanName(String name) {
    return '$name (Plan)';
  }

  @override
  String get demoCityMuenchen => 'München';

  @override
  String get demoCityKoeln => 'Köln';

  @override
  String get demoCityZuerich => 'Zürich';

  @override
  String get demoCityWien => 'Wien';

  @override
  String get demoCityKonstanz => 'Konstanz';

  @override
  String get demoCityParis => 'Paris';

  @override
  String get demoCityStrasbourg => 'Straßburg';

  @override
  String get demoCityNice => 'Nizza';

  @override
  String get postRideStravaConnect =>
      'Strava verbinden unter Daten & Privatsphäre.';

  @override
  String get postRideStravaKeysMissing =>
      'Strava-Keys fehlen — GPX/FIT nutzen.';

  @override
  String get postRideStravaStatusDown =>
      'Strava-Status nicht erreichbar — GPX/FIT nutzen.';

  @override
  String get postRideStravaHint =>
      'Strava: mit GPS-Track via Uploads-API; ohne Track nur Metadaten.';

  @override
  String postRideStravaError(String error) {
    return 'Strava: $error';
  }

  @override
  String get postRideHeatmapPrivate =>
      'Heatmap: Tour ist privat — Track nicht beigetragen.';

  @override
  String postRideHeatmapError(String error) {
    return 'Heatmap: $error';
  }

  @override
  String get postRideSetupSaved => 'Setup-Version gespeichert';

  @override
  String postRideSetupSaveFailed(String error) {
    return 'Setup speichern fehlgeschlagen: $error';
  }

  @override
  String get postRideGpxEmpty => 'Kein GPS-Track — GPX wäre leer';

  @override
  String postRideGpxExportError(String error) {
    return 'GPX-Export: $error';
  }

  @override
  String postRideFitExportError(String error) {
    return 'FIT-Export: $error';
  }

  @override
  String get postRideShareGpx => 'GPX teilen';

  @override
  String get postRideSimActive => 'Sim-Track war aktiv';

  @override
  String postRideSimDistance(String km) {
    return ' (~$km km simuliert)';
  }

  @override
  String get postRideSimUnreliable =>
      ' — Distanz/Analyse ggf. unzuverlässig. Für echte Rides AETHER_SIM_MOTION aus.';

  @override
  String get postRideAvgSpeedHigh =>
      'Ungewöhnlich hohe Durchschnittsgeschwindigkeit — GPS/Sim prüfen.';

  @override
  String get postRideSuggestionTaken => 'Übernommen';

  @override
  String get postRideSuggestionAccept => 'Empfehlung annehmen';

  @override
  String get postRideAssistEstimate => 'Assist (Schätzung)';

  @override
  String postRideAssistDominant(String mode, String wh) {
    return 'Dominant: $mode · ~$wh Wh';
  }

  @override
  String postRideAssistApproach(String mode) {
    return 'Schätzung: $mode (Anfahrt)';
  }

  @override
  String postRideAssistClimb(String mode, String pct) {
    return 'Schätzung: $mode (Steigung, $pct %)';
  }

  @override
  String postRideAssistRest(String mode) {
    return 'Schätzung: $mode (Rest)';
  }

  @override
  String get postRideAssistDisclaimer =>
      'Schätzungen aus Leistungs-/Geschwindigkeitssignatur — kein OEM-Auslesen. Keine Motorsteuerung (F-EBK-000).';

  @override
  String get postRideFeelTitle => 'Wie hat es sich angefühlt?';

  @override
  String get postRideFrontSuspension => 'Federung vorne';

  @override
  String get postRideFrontTooSoft => 'zu weich';

  @override
  String get postRideBrakeDive => 'Bremsnick';

  @override
  String get postRideBrakeDives => 'taucht';

  @override
  String get postRideBrakeNeutral => 'neutral';

  @override
  String get postRideBrakeHarsh => 'hart';

  @override
  String get postRideSmallBumps => 'Kleine Schläge';

  @override
  String get postRideBumpsVague => 'schwammig';

  @override
  String get postRideSaveFeedback => 'Feedback speichern';

  @override
  String get postRideShortRideMetrics =>
      'Kurzride — Metriken eingeschränkt (< 0,5 km).';

  @override
  String get postRideMetricsTitle => 'Metriken';

  @override
  String get postRideDefaultName => 'Fahrt';

  @override
  String get platzCreateGroupHint =>
      'Tour wählen, Sichtbarkeit, dann den Link teilen.';

  @override
  String get platzGroupPublicHint =>
      'Wer den Link hat, kann beitreten. Die Gruppe kann auf dem Platz unter Öffentlich stehen.';

  @override
  String get platzGroupPrivateHint =>
      'Nur wer den Link hat, kann beitreten. Kein öffentliches Roster.';

  @override
  String get platzNoPrivateGroups => 'Keine privaten Gruppen in diesem Filter.';

  @override
  String get platzMakePrivate => 'Privat machen';

  @override
  String get platzMakePublic => 'Öffentlich machen';

  @override
  String get platzNoPublicGroups =>
      'Keine öffentlichen Gruppen auf dem Server.';

  @override
  String get platzPublicGroupsHint =>
      'Öffentliche Gruppen — Beitritt mit Login, kein Explore-GPS.';

  @override
  String get platzListedPublic => 'öffentlich';

  @override
  String get filterVisibilityAll => 'Alle';

  @override
  String get filterVisibilityPublic => 'Öffentlich';

  @override
  String get mappeTitle => 'Die Mappe';

  @override
  String get mappeSubtitle =>
      'Deine Touren, Stimmen und Gruppen. Dieselben wie auf der Karte.';

  @override
  String get mappeAddHint =>
      'Name + Start — ohne erfundenen Track. GPX als Option darunter.';

  @override
  String get mappePutIn => 'In die Mappe legen';

  @override
  String mappeSaved(String name) {
    return 'In der Mappe: $name';
  }

  @override
  String mappeImported(String name) {
    return 'Importiert: $name';
  }

  @override
  String get mappeEmpty => 'Noch keine eigenen Strecken — Route hinzufügen.';

  @override
  String get mappeStimmenEmpty =>
      'Noch keine Stimmen zu deinen Touren. Nach Freigabe können andere schreiben.';

  @override
  String get myRoutesSourceOwn => 'Eigene';

  @override
  String get privacyZoneTitle => 'Privacy-Zone';

  @override
  String get privacyZoneEdit => 'Zone anpassen';

  @override
  String get privacyZoneInvalidCoords => 'Bitte gültige Koordinaten angeben';

  @override
  String get privacyZoneNeedTap => 'Bitte auf die Karte tippen';

  @override
  String get privacyZoneTapShort => 'Tippe auf die Karte';

  @override
  String get retry => 'Erneut';

  @override
  String get hofSystemStatus => 'Systemstatus';

  @override
  String get hofSystemOk =>
      'Alles verbunden — Werkstatt, Fahrten und Sync laufen normal.';

  @override
  String get hofSupabaseMissing => 'Supabase nicht konfiguriert';

  @override
  String get hofSupabaseMissingHint =>
      'Cloud-Sync ist nicht eingerichtet — Anmeldung und Sync sind aus.';

  @override
  String get hofSyncSessionExpired => 'Sync: Sitzung abgelaufen';

  @override
  String get hofSyncLoginOnly => 'Sync nur mit Login';

  @override
  String get hofSyncLocalHint =>
      'Garage/Rides bleiben lokal — Konto für Cloud-Sync.';

  @override
  String get hofSystemNotice => 'Systemstatus — Hinweis vorhanden';

  @override
  String get hofSystemHint => 'Systemstatus — Hinweis';

  @override
  String get hofSystemOkTooltip => 'Systemstatus: ok';

  @override
  String get hofTafelTitle => 'Die Tafel';

  @override
  String hofTafelVoiceOne(String name) {
    return 'Neue Stimme zu $name';
  }

  @override
  String hofTafelVoices(int count, String name) {
    return '$count Stimmen zu $name';
  }

  @override
  String hofTafelGroup(String title) {
    return 'Gruppe vor dem Tor · $title';
  }

  @override
  String ridePuckSemantics(String name) {
    return 'Navigation, $name';
  }

  @override
  String dieBoxSentenceHome(String name) {
    return '$name wohnt hier';
  }

  @override
  String get dieBoxLater => 'Später';

  @override
  String dieBoxSentenceMtbReady(String name, String travel, String drive) {
    return '$name · $travel$drive · bereit';
  }

  @override
  String dieBoxSentenceReadyBits(String name, String bits) {
    return '$name · $bits · bereit';
  }
}
