// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AetherRide';

  @override
  String get appTagline =>
      'Für MTB, Gravel, Rennrad, City & E-Bike — eine App fürs Rad.';

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
      'Live featured-parts in AetherRide — Soft-Fit & Preise, ohne Shopify-Passwort-Dead-End.';

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
    return '$count Touren zeigen';
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
  String get garageFabBike => 'Bike';

  @override
  String get garageEmptyTitle => 'Noch kein Bike in der Garage';

  @override
  String get garageEmptyMessage =>
      'Leg dein Rad an — Typ, Status und Teile siehst du danach auf einen Blick.';

  @override
  String get garageAddBike => 'Bike anlegen';

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
  String get postRidePhotosShareText => 'Meine AetherRide-Fahrt';

  @override
  String get postRidePhotosEmpty => 'Noch keine Fotos zum Teilen';

  @override
  String postRidePhotosMax(int count) {
    return 'Maximal $count Fotos';
  }

  @override
  String get postRideCommunityStub =>
      'Community-Feed folgt — Fotos bleiben lokal; teilen über die System-Share-Sheet.';

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
  String get myRouteNotesTitle => 'Kommentare';

  @override
  String get myRouteNotesHint =>
      'Lokale Notizen an dieser Strecke. Öffentliche Community-Kommentare folgen mit Konto.';

  @override
  String get myRouteNotesEmpty => 'Noch keine Kommentare.';

  @override
  String get myRouteNotesPlaceholder => 'Kommentar schreiben…';

  @override
  String get myRouteNotesAdd => 'Senden';

  @override
  String get myRouteDetailPhotos => 'Fotos';

  @override
  String get myRouteOpenDetail => 'Details';
}
