// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'FlowLine';

  @override
  String get appTagline =>
      'Ride further. Flow better — MTB, gravel, strada, city & e-bike.';

  @override
  String get navHome => 'Home';

  @override
  String get navGarage => 'Garage';

  @override
  String get navRide => 'Pedala';

  @override
  String get navDiscover => 'Tour';

  @override
  String get navParts => 'Pezzi';

  @override
  String get navKarte => 'Mappa';

  @override
  String get navWorkshop => 'Officina';

  @override
  String get navShop => 'Negozio';

  @override
  String get navPlatz => 'Platz';

  @override
  String navTabOf(int index, int count) {
    return 'Scheda $index di $count';
  }

  @override
  String get hofJustRide => 'Pedala e basta';

  @override
  String get hofShowTours => 'Mostra i tour';

  @override
  String get hofMapChoiceHint =>
      'Parti senza itinerario, o mostra i tour sulla mappa.';

  @override
  String get werkstattPartsShelf => 'Shop';

  @override
  String get werkstattForYourBike => 'Per la tua bici';

  @override
  String get werkstattMerch => 'Merchandise';

  @override
  String get werkstattShopParts => 'Ricambi nel negozio';

  @override
  String get werkstattPartsForBike => 'Pezzi per la tua bici';

  @override
  String get shopLookupInShop => 'Cerca nel negozio';

  @override
  String get shopGatewayKicker => 'Dall\'altra parte del cortile';

  @override
  String get shopGatewayTitle => 'Il negozio';

  @override
  String get shopGatewayHint =>
      'La bici non vive qui. FlowLine mostra pezzi onesti — acquisto e cassa su Shopify, non nell\'app.';

  @override
  String get shopZumShop => 'Al negozio';

  @override
  String shopForYourBikeHint(String name) {
    return 'Pezzi che stanno a $name — categoria e ruota. Niente SKU inventati.';
  }

  @override
  String get shopForYourBikeEmpty =>
      'Parcheggia una bici in officina — poi apriamo i pezzi che calzano, nel negozio.';

  @override
  String get shopMerchHint =>
      'Abbigliamento e oggettistica. Mai filtrati sulla bici.';

  @override
  String get shopMerchTitle => 'Abbigliamento';

  @override
  String get shopMerchEmpty =>
      'Niente merch in scaffale. L\'abbigliamento resta nel negozio, mai filtrato sulla bici.';

  @override
  String get shopNotConnected => 'Negozio non collegato';

  @override
  String get shopNotConnectedHint =>
      'Nessun URL storefront. Imposta SHOPIFY_STOREFRONT_URL, poi l\'officina apre il negozio.';

  @override
  String get shopOpenFailed => 'Impossibile aprire il negozio.';

  @override
  String get shopPasswordWall =>
      'Il negozio fuori non è ancora pubblico — può comparire una password. Lo scaffale qui resta.';

  @override
  String get shopLockedTitle => 'Negozio ancora chiuso fuori';

  @override
  String get shopPasswordConfirm => 'Apri lo stesso';

  @override
  String get shopPasswordCancel => 'Indietro';

  @override
  String get shopCyclingParts => 'Pezzi';

  @override
  String get shopSearchHint => 'Pezzi, marche, misure…';

  @override
  String get shopFeatured => 'Pezzi che calzano';

  @override
  String get shopOpenProduct => 'Apri nel negozio';

  @override
  String get shopAllParts => 'Tutti i pezzi';

  @override
  String shopFitBanner(String name) {
    return 'Pezzi che stanno a $name';
  }

  @override
  String get shopShelfEmpty => 'Nessun pezzo per questa ricerca.';

  @override
  String get shopCatalogEmpty =>
      'Ancora nessun pezzo in scaffale. La porta apre comunque Shopify.';

  @override
  String get shopFitOnly => 'Solo adatti';

  @override
  String get shopFitAllBikes => 'Tutte le bici';

  @override
  String get shopFitBannerAll => 'Pezzi che stanno alle tue bici';

  @override
  String get shopOpenInBrowser => 'Apri nel browser';

  @override
  String get shopZumHaendler => 'Dal rivenditore';

  @override
  String get shopOpenInApp => 'Vedi nel negozio';

  @override
  String get shopProductMissing => 'Questo prodotto non è nel negozio.';

  @override
  String get shopCatalogFailed =>
      'Catalogo irraggiungibile al momento. La porta del negozio apre comunque Shopify.';

  @override
  String get shopRetry => 'Riprova';

  @override
  String get shopSheetCheckout => 'Cassa su Shopify, non in FlowLine.';

  @override
  String get shopDetails => 'Dettagli';

  @override
  String get shopFeaturedBikes => 'Bici nel negozio';

  @override
  String get garageSetupTabHintTires =>
      'Pressione a occhio da peso e gomme — misura sulla bici, non una tabella OEM.';

  @override
  String get werkstattSetupTires => 'Gomme / pressione a occhio';

  @override
  String get werkstattSetupSuspension =>
      'Sospensione — SAG e aria in base all\'escursione';

  @override
  String get werkstattSetupSuspensionUnknown =>
      'Sospensione — escursione non iscritta';

  @override
  String get werkstattSetupDropper => 'Telescopica (iscritta)';

  @override
  String werkstattSetupWheel(String size) {
    return 'Ruota $size';
  }

  @override
  String get werkstattSetupCockpit => 'Cockpit — piega e attacco';

  @override
  String get werkstattSetupBagsCockpit => 'Borse / cockpit';

  @override
  String get werkstattSetupLightsRack =>
      'Luci e portapacchi — solo se iscritto';

  @override
  String get werkstattSetupDrivetrain => 'Trasmissione';

  @override
  String get werkstattBatteryHonest => 'Batteria solo con un sensore vero';

  @override
  String get werkstattBatteryHonestHint =>
      'Niente percentuale senza sensore abbinato. Bosch LDI resta G-1.';

  @override
  String get werkstattSensorEbike =>
      'Sensore ruota (CSC) — velocità e cadenza. Batteria solo con un sensore vero.';

  @override
  String get werkstattSensorAnalog =>
      'Sensore ruota — velocità e cadenza sulla bici.';

  @override
  String get hofYourWatch => 'Il tuo orologio';

  @override
  String get hofWatchHint =>
      'Fitness sul rider — non sulla bici. Polso solo con un sensore vero. Apple Watch spesso senza BLE standard.';

  @override
  String get hofWatchPair => 'Associa orologio';

  @override
  String get hofWatchReconnect => 'Collega';

  @override
  String get hofWatchRemove => 'Rimuovi';

  @override
  String get hofWatchConnect => 'Collega orologio';

  @override
  String get hofYou => 'Tu';

  @override
  String get hofYouSheetHint =>
      'Tu e il tuo orologio. Il sensore ruota resta sulla bici, in officina.';

  @override
  String get werkstattWatchEbike =>
      'Orologio — polso accanto al CSC. Niente SoC inventato.';

  @override
  String get werkstattWatchAnalog => 'Smartwatch / fitness';

  @override
  String get setupTirePressureLabel => 'Gomma anteriore (psi)';

  @override
  String get setupCompareHintTires =>
      'Crea due pressioni alla cieca. Dopo qualche uscita vedi quale si sente meglio.';

  @override
  String setupTirePressureValue(String value) {
    return 'Gomme $value psi';
  }

  @override
  String get searchHome => 'Dove vai? Luogo, tour o indirizzo';

  @override
  String get startRide => 'Avvia l\'uscita';

  @override
  String get startFreeride => 'Pedala senza itinerario';

  @override
  String get startWithRoute => 'Segui l\'itinerario';

  @override
  String get goRide => 'Si parte';

  @override
  String get readyTitle => 'Pronto a partire';

  @override
  String get readyMessage =>
      'Il GPS parte subito. Sensori e itinerario sono opzionali — trail, asfalto o city.';

  @override
  String get optionalRoute =>
      'Opzionale: sotto Tour scegli un itinerario e tocca « Si parte ».';

  @override
  String get starting => 'Avvio…';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get reset => 'Azzera';

  @override
  String errorPrefix(String error) {
    return 'Errore: $error';
  }

  @override
  String get discoverMenuPhotos => 'Foto intorno';

  @override
  String get discoverMenuOffline => 'Mappe offline';

  @override
  String get discoverMenuCollections => 'Raccolte';

  @override
  String get discoverMenuPrivacy => 'Heatmap e privacy';

  @override
  String get partsTitle => 'Pezzi e accessori';

  @override
  String get partsSubtitle =>
      'Pezzi featured live in FlowLine — soft-fit e prezzi, senza vicolo cieco password Shopify.';

  @override
  String get weatherFallback => 'Meteo non disponibile';

  @override
  String get weatherLoading => 'Caricamento meteo…';

  @override
  String get statsRidesOne => 'uscita';

  @override
  String get statsRidesMany => 'uscite';

  @override
  String get profile => 'Profilo';

  @override
  String get chat => 'Chat';

  @override
  String get hofRideOut => 'Esci';

  @override
  String get hofOpenBike => 'Apri la bici';

  @override
  String get hofParkBike => 'Parcheggia la bici';

  @override
  String get hofRideWithoutBike => 'Pedala senza bici';

  @override
  String get hofRideOutAgain => 'Esci di nuovo';

  @override
  String get hofAtGate => 'davanti al cancello';

  @override
  String get hofEmptyStand => 'Posto vuoto';

  @override
  String get hofSkyUnknown => 'Cielo sconosciuto';

  @override
  String get hofNoHonestLoop => 'Nessun anello trail onesto';

  @override
  String get hofGateWetClosed =>
      'Trail bagnati — nessun anello asfaltato onesto qui vicino';

  @override
  String get hofNotYetOut => 'non ancora fuori';

  @override
  String get hofJustBack => 'appena rientrato';

  @override
  String hofAgoMinutes(int minutes) {
    return '$minutes min fa';
  }

  @override
  String hofAgoHours(int hours) {
    return '$hours h fa';
  }

  @override
  String get hofWhatCameIn => 'Cosa è rientrato';

  @override
  String hofPackMissing(String name) {
    return 'Manca il pack per $name';
  }

  @override
  String get hofLastRideNoGps => 'senza traccia GPS — niente di inventato';

  @override
  String get hofGpsUnknown =>
      'Nessuna posizione — cielo e cancello aspettano il GPS.';

  @override
  String get rideGpsUnavailable =>
      'Niente GPS — la traccia resta vuota. Niente di inventato.';

  @override
  String get hofAtHof => 'al posto';

  @override
  String hofGarageType(String type) {
    return 'Tipo $type';
  }

  @override
  String get hofSinceOneDay => 'da 1 giorno';

  @override
  String hofSinceDays(int days) {
    return 'da $days giorni';
  }

  @override
  String get hofNoBikeHere => 'Nessuna bici qui';

  @override
  String hofBringForward(String name) {
    return 'Porta avanti $name';
  }

  @override
  String hofCareInWorkshop(String label) {
    return '$label — in officina';
  }

  @override
  String get hofSensorAwake => 'Sensore sveglio';

  @override
  String get hofOpenTours => 'Apri i tour';

  @override
  String hofSkyDry(String temp) {
    return '$temp° · piuttosto secco';
  }

  @override
  String hofSkyDamp(String temp) {
    return '$temp° · umido possibile';
  }

  @override
  String hofSkyWet(String temp) {
    return '$temp° · pioggia · trail piuttosto bagnati';
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
  String get hofGateAwayNear => 'meno di 1 km';

  @override
  String hofCommunityNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note su questo anello',
      one: '1 nota su questo anello',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMtb => 'Trail, tour e il tuo setup';

  @override
  String get homeSubtitleGravel => 'Gravel, distanza e navigazione';

  @override
  String get homeSubtitleRoad => 'Asfalto, ritmo e allenamento';

  @override
  String get homeSubtitleUrban => 'Pendolarismo, città e quotidiano';

  @override
  String get homeSubtitleEbike => 'Assist, autonomia e tour';

  @override
  String get homeSubtitleDefault =>
      'Ogni modo di pedalare — la tua bici, il tuo itinerario';

  @override
  String homeSubtitleWithWeather(String weather, String base) {
    return '$weather · $base';
  }

  @override
  String get tipHeroTitleMtb => 'Oggi fuori in bici';

  @override
  String get tipHeroTitleGravel => 'Oggi gravel o mix';

  @override
  String get tipHeroTitleRoad => 'Oggi chilometri d\'asfalto';

  @override
  String get tipHeroTitleUrban => 'Oggi attraverso la città';

  @override
  String get tipHeroTitleEbike => 'Oggi con assist';

  @override
  String get tipHeroTitleDefault => 'Oggi un\'uscita ci sta';

  @override
  String get tipHeroSubtitleMtb =>
      'Scegli un itinerario o pedala libero — traccia locale.';

  @override
  String get tipHeroSubtitleGravel =>
      'Pianifica una distanza o parti senza itinerario.';

  @override
  String get tipHeroSubtitleRoad =>
      'Costruisci un anello o registra un allenamento libero.';

  @override
  String get tipHeroSubtitleUrban =>
      'Traccia il tragitto o salva un anello corto.';

  @override
  String get tipHeroSubtitleEbike =>
      'Pianifica un tour e tieni d\'occhio l\'autonomia.';

  @override
  String get tipHeroSubtitleDefault =>
      'MTB, gravel, strada o city — tutto qui.';

  @override
  String get chassisLayer => 'Sospensione';

  @override
  String get sensorLayer => 'Sensori';

  @override
  String get filter => 'Filtri';

  @override
  String get filterReset => 'Azzera';

  @override
  String get filterResetFilters => 'Azzera i filtri';

  @override
  String get filterDurationLens => 'Durata';

  @override
  String get filterSurfaceGroup => 'Fondo';

  @override
  String get filterExertion => 'Difficoltà';

  @override
  String get filterDistance => 'Distanza';

  @override
  String get filterElevation => 'Dislivello';

  @override
  String get filterForm => 'Forma';

  @override
  String get filterFormAll => 'Tutte';

  @override
  String get filterFormPointToPoint => 'A→B';

  @override
  String get filterFormPointToPointTooltip =>
      'Tappe e trail lineari (partenza≠arrivo).';

  @override
  String get filterFormDownhill => 'Downhill';

  @override
  String get filterFormDownhillTooltip =>
      'Discese, bike park, enduro A→B. Gli anelli non sono auto-DH.';

  @override
  String get filterBikeType => 'Tipo di bici';

  @override
  String get filterBikeTypeHonesty =>
      'I colori filtrano i tour. Navigazione: un percorso bici, tranne a piedi.';

  @override
  String get filterSingletrail => 'Singletrack (scala S)';

  @override
  String get filterSingletrailHint =>
      'Solo tour/sentieri con scala onesta. Senza tag: nessun risultato.';

  @override
  String get filterNoDownhillTours => 'Nessun downhill vicino';

  @override
  String get filterNoDownhillToursHint =>
      'I trail OSM per scala S restano sulla mappa. Nessun DH in catalogo qui.';

  @override
  String get filterNoScaleTours => 'Nessun tour con questo grado S';

  @override
  String get filterTrailNetwork => 'Rete trail (mappa)';

  @override
  String get filterLoopsOnly => 'Anello';

  @override
  String get filterLoopsOnlyTooltip =>
      'Solo anelli — partenza e arrivo coincidono.';

  @override
  String get filterNetworkOn => 'Vie sulla mappa';

  @override
  String get filterNetworkOff => 'Nascondi le vie';

  @override
  String filterOsmScaleTooltip(String code) {
    return 'Scala OSM: $code';
  }

  @override
  String filterShowTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostra $count tour',
      one: 'Mostra 1 tour',
    );
    return '$_temp0';
  }

  @override
  String get filterNoTours => 'Nessun tour con questi filtri.';

  @override
  String get filterNoToursHint =>
      'Nessun tour — tocca « Nuovo » o allenta i filtri.';

  @override
  String get loopLabel => 'Anello';

  @override
  String get computeRoute => 'Calcola itinerario';

  @override
  String get adaptTour => 'Modifica';

  @override
  String get adaptTourTitle => 'Modifica tour';

  @override
  String get adaptTourHint =>
      'Cambia partenza, arrivo o stop — poi calcola l\'itinerario.';

  @override
  String get planRouteTitle => 'Pianifica itinerario';

  @override
  String get planRouteCta => 'Naviga';

  @override
  String get discoverSearchHint => 'Luogo o tour';

  @override
  String filterAroundKm(int km) {
    return 'entro $km km';
  }

  @override
  String get mapToggleFab => 'Mappa';

  @override
  String get communityWriteReview => 'Scrivi una recensione';

  @override
  String get discoverModeExplore => 'Esplora';

  @override
  String get discoverModeNavigate => 'Naviga';

  @override
  String get discoverModeMine => 'Miei';

  @override
  String get navigateTitle => 'Naviga';

  @override
  String get navigateSubtitle => 'Tocca l\'arrivo o un indirizzo — poi calcola';

  @override
  String get navigateStartLabel => 'Partenza';

  @override
  String get navigateEndLabel => 'Arrivo';

  @override
  String get navigateStartHint => 'Indirizzo, luogo o tap sulla mappa';

  @override
  String get navigateEndHint => 'Dove vai?';

  @override
  String get navigateMyLocation => 'La mia posizione';

  @override
  String get navigateSwap => 'Inverti partenza e arrivo';

  @override
  String get navigatePickStart => 'Partenza sulla mappa';

  @override
  String get navigatePickEnd => 'Arrivo sulla mappa';

  @override
  String get navigateAddVia => 'Fermata intermedia';

  @override
  String get navigateNeedStartEnd => 'Imposta partenza e arrivo';

  @override
  String get navigateComputeNeedBoth =>
      'Calcola itinerario (servono partenza e arrivo)';

  @override
  String get navigateBackToExplore => 'Torna a Esplora';

  @override
  String get mineSheetHint => 'Le tue registrazioni, import e percorsi salvati';

  @override
  String get mineEmptyCtaNavigate => 'Itinerario da A a B';

  @override
  String get gpxImportAction => 'Importa GPX';

  @override
  String get exploreOpenNavigate => 'Naviga A→B';

  @override
  String get sheetDragHandleMine => 'Trascina il foglio I miei percorsi';

  @override
  String get sheetDragHandleNavigate => 'Trascina il foglio Navigazione';

  @override
  String get browseMap => 'Mappa';

  @override
  String get browseList => 'Elenco';

  @override
  String get quickFilter1h => '1 h';

  @override
  String get sheetDragHandle => 'Trascina il foglio Tour';

  @override
  String get sheetPeekHint => 'Tira su — tour e filtri';

  @override
  String get rideBarCollapseHint => 'Tira giù per chiudere';

  @override
  String get rideBarExpandHint => 'Apri';

  @override
  String get rideBarStart => 'Si parte';

  @override
  String get rideBarRoute => 'Percorso';

  @override
  String get rideBarPointToPoint => 'Percorso';

  @override
  String get emptyToursTitle => 'Nessun tour trovato';

  @override
  String get emptyToursFiltersBody => 'Azzera i filtri — rivedi i tour vicini.';

  @override
  String get emptyToursNearbyBody =>
      'Cambia luogo o durata — o azzera i filtri.';

  @override
  String get showOnMap => 'Sulla mappa';

  @override
  String get tourDetails => 'Dettagli';

  @override
  String get moreFilters => 'Altri filtri';

  @override
  String get moreActions => 'Altre azioni';

  @override
  String get filterSurfaceAsphalt => 'Asfalto';

  @override
  String get filterSurfaceGravel => 'Sterrato';

  @override
  String get filterSurfaceTrail => 'Trail';

  @override
  String get filterSurfaceMixed => 'Misto';

  @override
  String get filterSurfaceAsphaltHint => 'Asfalto · ciclabile · asfaltato';

  @override
  String get filterSurfaceGravelHint => 'Sterrato · forestale · compatto';

  @override
  String get filterSurfaceTrailHint => 'Naturale · singletrail · radici';

  @override
  String get filterSurfaceMixedHint => 'Città · fondo misto';

  @override
  String get filterSurfaceAsphaltFull => 'Asfalto · asfaltato';

  @override
  String get filterSurfaceGravelFull => 'Sterrato · compatto';

  @override
  String get filterSurfaceTrailFull => 'Naturale · trail';

  @override
  String get filterSurfaceMixedFull => 'Città · misto';

  @override
  String get filterEffortEasy => 'Facile';

  @override
  String get filterEffortMid => 'Medio';

  @override
  String get filterEffortHard => 'Impegnativo';

  @override
  String get filterEffortEasyHint => 'S0 / rilassato / poca tecnica';

  @override
  String get filterEffortMidHint => 'S1–S2 / sportivo / misto';

  @override
  String get filterEffortHardHint => 'S2+ / duro / tecnico';

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
  String get filterScaleEasy => 'Facile';

  @override
  String get filterScaleMedium => 'Medio';

  @override
  String get filterScaleHard => 'Impegnativo';

  @override
  String get trailDiffEasy => 'Facile';

  @override
  String get trailDiffMedium => 'Medio';

  @override
  String get trailDiffHard => 'Duro';

  @override
  String get trailDiffVeryHard => 'Molto duro';

  @override
  String get trailDiffUnrated => 'Non classificato';

  @override
  String get trailDiffOpen => 'aperto';

  @override
  String get durationAny => 'indifferente';

  @override
  String get duration2to3h => '2–3 h';

  @override
  String get garageTitle => 'Garage';

  @override
  String get garageFabBike => 'Aggiungi una bici';

  @override
  String get garageEmptyTitle => 'Nessuna bici qui';

  @override
  String get garageEmptyMessage =>
      'Nome e tipo bastano. Il catalogo è ricerca — i pezzi di serie solo se li prendi.';

  @override
  String get garageAddBike => 'Aggiungi una bici';

  @override
  String get garageAddAnother => 'Altra bici';

  @override
  String get garageStatBike => 'BICI';

  @override
  String get garageStatBikes => 'BICI';

  @override
  String get garageStatKmTotal => 'KM TOTALI';

  @override
  String get garageQuickSwitch => 'Cambio rapido';

  @override
  String get garageLastRides => 'Ultime uscite';

  @override
  String get garageNoRidesTitle => 'Ancora nessuna uscita';

  @override
  String get garageNoRidesMessage => 'La tua prima uscita salvata compare qui.';

  @override
  String get garageActive => 'Attiva';

  @override
  String garageActiveBike(String name) {
    return 'Bici attiva · $name';
  }

  @override
  String get garageEbikeBadge => 'E-bike';

  @override
  String get garageMaintOk => 'Tutto ok';

  @override
  String garageMaintDue(int count) {
    return '$count manutenzioni in scadenza';
  }

  @override
  String garageMaintOverdue(int count) {
    return '$count in ritardo';
  }

  @override
  String garagePartsCount(int count) {
    return '$count pezzi';
  }

  @override
  String get garageParts => 'Pezzi';

  @override
  String get garageMaintenance => 'Manutenzione';

  @override
  String get garageSetup => 'Setup';

  @override
  String get garageInstall => 'Aggiungi pezzo';

  @override
  String get garageOtherBikes => 'Altre bici';

  @override
  String get garageTechDetails => 'Dettagli tecnici';

  @override
  String get garageTechHint =>
      'Escursione, telaio, basi del setup — per amatori';

  @override
  String get garageCtaMaintenance => 'Vedi manutenzione';

  @override
  String get garageCtaAddPart => 'Aggiungi pezzo';

  @override
  String get garageCtaSetActive => 'Imposta come attiva';

  @override
  String get garageCtaOpenSetup => 'Vai al setup';

  @override
  String get garageHours => 'Ore';

  @override
  String get garageTravel => 'Escursione';

  @override
  String get garageFrameSize => 'Taglia telaio';

  @override
  String get garageWheelSize => 'Ruota';

  @override
  String get garageBrandModel => 'Modello';

  @override
  String garageCompatFits(int count) {
    return 'Calza $count';
  }

  @override
  String garageCompatCheck(int count) {
    return 'Controlla $count';
  }

  @override
  String garageCompatNoFit(int count) {
    return 'Non calza $count';
  }

  @override
  String get garagePartsEmpty =>
      'Ancora nessun pezzo. Tocca « Aggiungi pezzo » — poi ti ricordiamo la manutenzione e mostriamo se i pezzi stanno insieme.';

  @override
  String get garageMaintEmpty =>
      'Tutto a posto — nessuna manutenzione in scadenza.';

  @override
  String get garageSetupTabTitle => 'Il tuo setup';

  @override
  String get garageSetupTabHint =>
      'SAG = quanto affonda la sospensione col tuo peso (spesso ~25–30 %).';

  @override
  String get garageYourParts => 'I tuoi pezzi';

  @override
  String get garageMissingSlots => 'Non ancora iscritto (opzionale)';

  @override
  String get garageActiveBadge => 'Bici attiva';

  @override
  String get garageStatKm => 'KM';

  @override
  String get garageStatHours => 'ORE';

  @override
  String get garageStatMaint => 'MANUT.';

  @override
  String get setupVersionsTitle => 'Versioni e confronto';

  @override
  String get setupVersionsHint =>
      'Ogni modifica salva una nuova versione. Puoi tornare indietro quando vuoi.';

  @override
  String get setupRiderWeightLabel => 'Peso rider (kg) per i modelli';

  @override
  String get setupNewVersionCta => 'Nuova versione';

  @override
  String get setupCompareCta => 'Prova due varianti';

  @override
  String get setupCompareHint =>
      'Crea due varianti alla cieca (es. ritorno). Dopo qualche uscita vedi quale si sente meglio.';

  @override
  String get setupSavedVersions => 'Versioni salvate';

  @override
  String get setupEmpty =>
      'Ancora nessuna versione — parti da un modello o salva i tuoi settaggi.';

  @override
  String get setupActiveBadge => 'Attiva';

  @override
  String setupVersionMeta(int version) {
    return 'Versione $version';
  }

  @override
  String get setupUseVersion => 'Usa';

  @override
  String setupForkReboundValue(String value) {
    return 'Ritorno $value';
  }

  @override
  String get setupSourceTemplate => 'Modello';

  @override
  String get setupSourceBaseline => 'Base';

  @override
  String get setupSourceManual => 'Manuale';

  @override
  String get setupTemplatesTitle => 'Modelli per iniziare';

  @override
  String get setupTemplatesHint =>
      'Punto di partenza — non una reco personale.';

  @override
  String get setupApplyTemplate => 'Applica';

  @override
  String get setupNewVersionTitle => 'Nuova versione setup';

  @override
  String get setupNewVersionHint =>
      'Dagli un nome che riconosci — es. « Trail asciutto ».';

  @override
  String get setupVersionNameLabel => 'Nome';

  @override
  String get setupForkReboundLabel => 'Ritorno forcella (click)';

  @override
  String get setupCancel => 'Annulla';

  @override
  String get setupSave => 'Salva';

  @override
  String setupNewVersionDefaultName(int n) {
    return 'Versione $n';
  }

  @override
  String get setupManualFallback => 'Manuale';

  @override
  String setupTemplateAppliedLabel(String label) {
    return '$label (modello)';
  }

  @override
  String setupTemplateAppliedSnack(String disclaimer) {
    return 'Modello applicato — $disclaimer';
  }

  @override
  String get setupCompareVariantA => 'Variante test A';

  @override
  String get setupCompareVariantB => 'Variante test B';

  @override
  String setupCompareResultFromRides(int count, String summary) {
    return 'Varianti create · lettura da $count uscite: $summary';
  }

  @override
  String setupCompareResultDemo(String summary) {
    return 'Varianti create · ancora pochi feedback di uscita — esempio: $summary';
  }

  @override
  String get rideMap => 'Mappa';

  @override
  String get rideData => 'Dati';

  @override
  String get rideLiveData => 'Dati live';

  @override
  String get rideMapReady =>
      'La mappa c\'è. Sensore dopo la partenza, se vuoi.';

  @override
  String get rideClearRoute => 'Rimuovi itinerario';

  @override
  String get postRideTitle => 'Attività';

  @override
  String get postRideFreeride => 'Freeride';

  @override
  String get postRideTrackMap => 'Traccia percorsa';

  @override
  String get postRideNoTrack =>
      'Nessuna traccia GPS — la mappa non ha nulla da mostrare.';

  @override
  String get postRideStatDistance => 'Distanza';

  @override
  String get postRideStatDuration => 'Durata';

  @override
  String get postRideStatPace => 'Ritmo';

  @override
  String get postRideStatElevation => 'Dislivello';

  @override
  String get postRideWeatherTitle => 'Meteo';

  @override
  String get postRideWeatherStart => 'Partenza';

  @override
  String get postRideWeatherEnd => 'Arrivo';

  @override
  String get postRideWeatherUnavailable => 'Meteo non disponibile';

  @override
  String get postRidePhotosTitle => 'Foto';

  @override
  String get postRidePhotosHint =>
      'Aggiungi foto all\'uscita — salvate in locale.';

  @override
  String get postRidePhotoCamera => 'Fotocamera';

  @override
  String get postRidePhotoGallery => 'Galleria';

  @override
  String get postRidePhotosShare => 'Condividi';

  @override
  String get postRidePhotosShareText => 'La mia uscita FlowLine';

  @override
  String get postRidePhotosEmpty => 'Ancora nessuna foto da condividere';

  @override
  String postRidePhotosMax(int count) {
    return 'Massimo $count foto';
  }

  @override
  String get postRideCommunityStub =>
      'Le foto restano locali. Le voci stanno sul tour — non in un feed.';

  @override
  String get postRideOpenTour => 'Apri il tour';

  @override
  String get postRideSaveAsTour => 'Salva come tour';

  @override
  String get postRideSaveAsTourDone => 'Salvato in I miei percorsi';

  @override
  String get postRideSaveAsTourNeedTrack =>
      'Serve una traccia GPS per salvare.';

  @override
  String get postRideSaveAsTourHint =>
      'Salva la traccia come percorso tuo — visibile sotto Tour.';

  @override
  String get myRoutesTitle => 'I miei percorsi';

  @override
  String get myRoutesEmpty =>
      'Ancora nessun percorso — importa un GPX o registra un\'uscita.';

  @override
  String get myRoutesSourceImport => 'Import';

  @override
  String get myRoutesSourceRecorded => 'Registrato';

  @override
  String get myRoutesSourceEngine => 'Pianificato';

  @override
  String get myRoutesShowOnMap => 'I miei sulla mappa';

  @override
  String get myRoutesHideOnMap => 'Nascondi i miei';

  @override
  String get myRouteNotesTitle => 'Nota privata';

  @override
  String get myRouteNotesHint =>
      'Solo per te. Voci pubbliche solo dopo la condivisione, sotto Voci.';

  @override
  String get myRouteNotesEmpty => 'Ancora nessuna nota.';

  @override
  String get myRouteNotesPlaceholder => 'Solo per te — non una voce.';

  @override
  String get myRouteNotesAdd => 'Salva';

  @override
  String get myRouteDetailPhotos => 'Foto';

  @override
  String get myRouteOpenDetail => 'Dettagli';

  @override
  String collectionRouteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itinerari · tocca per aprire',
      one: '1 itinerario · tocca per aprire',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get add => 'Aggiungi';

  @override
  String get skip => 'Salta';

  @override
  String get next => 'Avanti';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get signIn => 'Accedi';

  @override
  String get signOut => 'Esci';

  @override
  String get account => 'Account';

  @override
  String get register => 'Registrati';

  @override
  String get edit => 'Modifica';

  @override
  String get share => 'Condividi';

  @override
  String get done => 'Fatto';

  @override
  String get authSignedInSyncing => 'Accesso effettuato — sync in corso…';

  @override
  String authSignedInSyncFailed(String error) {
    return 'Accesso effettuato. Sync: $error';
  }

  @override
  String get authCloudUnavailable => 'Il cloud-sync non è disponibile adesso.';

  @override
  String get authEmailPasswordRequired =>
      'E-mail e password (min. 8 caratteri) obbligatori.';

  @override
  String get authAccountCreatedConfirm =>
      'Account creato — conferma l\'e-mail se serve, poi accedi.';

  @override
  String get authSupabaseMissing => 'Supabase non è configurato.';

  @override
  String get authBrowserOpened =>
      'Browser aperto — dopo il login torni da solo.';

  @override
  String get authDeleteTitle => 'Eliminare l\'account?';

  @override
  String get authDeleteBody =>
      'Account remoto e dati locali dell\'app verranno eliminati. Esporta prima GPX/JSON sotto Dati e privacy.';

  @override
  String get authRemoteDeleted => 'Account remoto eliminato.';

  @override
  String get authRemoteUnavailable =>
      'Eliminazione remota non disponibile — rimossi solo i dati locali.';

  @override
  String authRemoteFailed(int code) {
    return 'Eliminazione remota fallita ($code) — locale comunque eliminato.';
  }

  @override
  String get authRemoteUnreachable =>
      'Server irraggiungibile — rimossi solo i dati locali.';

  @override
  String get authLocalDeleted =>
      'Dati locali eliminati. Export eventualmente sotto Privacy.';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEmailHint => 'Indirizzo e-mail';

  @override
  String get authPassword => 'Password';

  @override
  String get authCreateAccount => 'Crea account';

  @override
  String get authHaveAccount => 'Hai già un account? Accedi';

  @override
  String get authNewHere => 'Nuovo qui? Registrati';

  @override
  String get authWithGoogle => 'Con Google';

  @override
  String get authWithApple => 'Con Apple';

  @override
  String get authPrivacy => 'Dati e privacy';

  @override
  String get authOpenAssistant => 'Apri assistente';

  @override
  String get authDeleteAccount => 'Elimina account';

  @override
  String get authSyncNow => 'Sincronizza ora';

  @override
  String get authSyncing => 'Sincronizzo…';

  @override
  String get authSyncOk => 'Sync OK';

  @override
  String authSyncActive(String api) {
    return 'Sync con $api è attivo.';
  }

  @override
  String get authCreating => 'Creazione…';

  @override
  String get authSigningIn => 'Accesso…';

  @override
  String get billingTitle => 'FlowLine Pro';

  @override
  String get billingYouHavePro => 'Hai Pro.';

  @override
  String get billingFreeToPro => 'Free → Pro';

  @override
  String get billingMoreBikes => 'Più bici, vantaggi sync e regioni offline.';

  @override
  String get billingAlreadyPro => 'Pro è già attivo — non serve ricomprare.';

  @override
  String get billingForceProDebug =>
      'Debug: Force-Pro. Stripe/Play restano nascosti.';

  @override
  String get billingStripeMonth => 'Stripe — mensile';

  @override
  String get billingStripeYear => 'Stripe — annuale';

  @override
  String get billingPlayMonth => 'Google Play — mensile';

  @override
  String get billingPlayRestore => 'Ripristina acquisti Play';

  @override
  String get billingPlayHint =>
      'Nota: senza GOOGLE_PLAY_SERVICE_ACCOUNT_JSON il server non verifica gli acquisti con Google.';

  @override
  String get billingSyncStatus => 'Sincronizza stato abbonamento';

  @override
  String get billingSyncAfterPurchase => 'Sincronizza dopo l\'acquisto';

  @override
  String get billingPleaseSignIn => 'Accedi prima.';

  @override
  String get billingNoCheckoutUrl => 'Nessun URL checkout';

  @override
  String get billingBrowserFailed => 'Impossibile aprire il browser';

  @override
  String get billingCheckoutOpened =>
      'Checkout aperto — poi « Sync after purchase ».';

  @override
  String get billingPlayOnlyAndroid => 'Play Billing solo su Android.';

  @override
  String get billingPlayStarted => 'Acquisto Play avviato…';

  @override
  String get billingVerifying => 'Verifica acquisto…';

  @override
  String get billingProTrusted =>
      'Pro impostato (trusted-token MVP — senza Google Play Service Account). Sync OK.';

  @override
  String get billingProActive => 'Pro attivo. Sync in corso.';

  @override
  String get billingRestoring => 'Ripristino acquisti…';

  @override
  String get billingRestoreStarted =>
      'Restore avviato — gli abbonamenti validi verranno verificati.';

  @override
  String billingSyncOkTier(String tier) {
    return 'Sync OK — piano: $tier';
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
  String get chatAssistant => 'Assistente';

  @override
  String get chatWelcome =>
      'Chiedimi cosa è in scadenza — o setup, itinerari e pezzi.';

  @override
  String get chatEmptyTitle => 'Chiedimi';

  @override
  String get chatEmptyMessage =>
      'Cosa è in scadenza, setup, itinerari o pezzi — prova un suggerimento sopra o scrivi.';

  @override
  String get chatLockedRiding => 'La chat è bloccata durante l\'uscita.';

  @override
  String get chatHint => 'Messaggio…';

  @override
  String get chatHintLocked => 'Bloccata durante l\'uscita';

  @override
  String get chatAsk => 'Chiedi';

  @override
  String get chatSnooze7 => 'Silenzio 7 giorni';

  @override
  String get chatNoAnswer => 'Nessuna risposta.';

  @override
  String get chatUnavailable =>
      'L\'assistente non è disponibile al momento. Riprova più tardi.';

  @override
  String chatNetworkError(String error) {
    return 'Errore di rete: $error';
  }

  @override
  String chatErrorStatus(int code) {
    return 'Errore $code';
  }

  @override
  String get chatLimitReached => 'Limite raggiunto.';

  @override
  String chatQuota(String used, String limit, String remaining) {
    return 'Quota: $used / $limit · ancora $remaining';
  }

  @override
  String get chatToolDev => 'Strumento (sviluppatore)';

  @override
  String get chatToolAuto => 'Auto';

  @override
  String get chatPromptWatch => 'Cosa è in scadenza?';

  @override
  String get chatPromptWatchQuery => 'Cosa è in scadenza?';

  @override
  String get chatPromptGarage => 'Garage';

  @override
  String get chatPromptGarageQuery => 'Cosa c\'è nel mio garage?';

  @override
  String get chatPromptRange => 'Autonomia';

  @override
  String get chatPromptRangeQuery =>
      'Che autonomia ho con la batteria attuale?';

  @override
  String get chatPromptSetups => 'Setup';

  @override
  String get chatPromptSetupsQuery => 'Quali setup ho avuto e cosa è cambiato?';

  @override
  String get chatPromptRides => 'Uscite';

  @override
  String get chatPromptRidesQuery => 'Riassunto delle mie ultime uscite';

  @override
  String get chatPromptRoutes => 'Itinerari';

  @override
  String get chatPromptRoutesQuery => 'Quali itinerari mi calzano?';

  @override
  String get chatPromptShop => 'Negozio';

  @override
  String get chatPromptShopQuery => 'Presto mi servono consumabili?';

  @override
  String get chatToolWatch => 'In scadenza';

  @override
  String get chatToolGarage => 'Officina';

  @override
  String get chatToolCompat => 'Compatibilità';

  @override
  String get chatToolRange => 'Autonomia';

  @override
  String get chatToolSetupHistory => 'Storico setup';

  @override
  String get chatToolRides => 'Uscite';

  @override
  String get chatToolRoutes => 'Itinerari';

  @override
  String get chatToolShop => 'Negozio';

  @override
  String get chatSubtitleDue => 'In scadenza, setup, itinerari, pezzi';

  @override
  String coachHintsTooltip(int count) {
    return '$count suggerimenti';
  }

  @override
  String get privacyTitle => 'Dati e privacy';

  @override
  String get privacyConsents => 'Consensi';

  @override
  String get privacyHud => 'HUD';

  @override
  String get privacyZones => 'Zone privacy';

  @override
  String get privacyZoneAdd => 'Zona';

  @override
  String get privacyNoZones =>
      'Nessuna zona — l\'intorno partenza/arrivo può essere tagliato.';

  @override
  String privacyZoneRadius(String label) {
    return 'Raggio $label';
  }

  @override
  String get privacyZoneDelete => 'Elimina zona';

  @override
  String get privacyFamilyHint =>
      'Famiglia / altri rider: sotto Profilo → Garage famiglia aggiungi rider con il proprio peso.';

  @override
  String get privacyExportTitle => 'Export (art. 20)';

  @override
  String get privacyExportGpx => 'Ultima uscita come GPX';

  @override
  String get privacyExportFit => 'Ultima uscita come FIT';

  @override
  String get privacyExportJson => 'Export JSON completo';

  @override
  String get privacyExportStravaStub => 'Payload Strava (locale, sviluppatore)';

  @override
  String get privacyStravaConnect => 'Collega Strava';

  @override
  String get privacyStravaUpload => 'Ultima uscita su Strava';

  @override
  String get privacyStravaLiveHint =>
      'L\'upload live usa i token OAuth salvati (server).';

  @override
  String get privacyStravaOauthHint =>
      'OAuth apre il browser; dopo l\'autorizzazione continua nell\'app.';

  @override
  String get privacyStravaMissing =>
      'Strava non è configurato. GPX, FIT e JSON restano le vie di export.';

  @override
  String get privacyStravaConnected => 'Strava collegato';

  @override
  String get privacyStravaCallback => 'Callback Strava ricevuto';

  @override
  String privacyStravaStatus(String status) {
    return 'Strava: $status';
  }

  @override
  String get privacyStravaUnreachable =>
      'Stato Strava irraggiungibile — l\'export stub resta locale';

  @override
  String get privacyStravaUrlMissing =>
      'URL di autorizzazione Strava mancante — accedi e riprova.';

  @override
  String get privacyStravaBrowser =>
      'Strava nel browser — torna all\'app dopo l\'autorizzazione, lo stato si aggiorna.';

  @override
  String get privacyNoRideUpload => 'Nessuna uscita da caricare';

  @override
  String privacyChunksUploaded(int n, int left) {
    return '$n chunk caricati, $left in attesa';
  }

  @override
  String privacyChunksBlocked(int left) {
    return 'Nessun upload (login/rete?) — $left in attesa';
  }

  @override
  String get privacyChunksNone => 'Nessun chunk in attesa';

  @override
  String privacyHeatmapCells(int n) {
    return 'Heatmap: $n celle contribute (visibile solo a k≥5).';
  }

  @override
  String get privacyHeatmapNone =>
      'Heatmap: nessun contributo (controlla login/consenso/traccia).';

  @override
  String get privacyUploadNow => 'Carica ora';

  @override
  String privacyChunksPending(int count) {
    return 'Chunk dati grezzi: $count in attesa';
  }

  @override
  String privacyChunksPendingConsentOff(int count) {
    return 'Chunk dati grezzi: $count in attesa (consenso off)';
  }

  @override
  String privacySharedGpx(String path) {
    return 'GPX condiviso · $path';
  }

  @override
  String privacySharedFit(String path) {
    return 'FIT condiviso · $path';
  }

  @override
  String privacySharedStravaStub(String path) {
    return 'Stub Strava condiviso · $path';
  }

  @override
  String get privacyExportSubject => 'Export FlowLine';

  @override
  String get privacyNoRideExporting => 'Nessuna uscita da esportare.';

  @override
  String privacySharedJson(String path) {
    return 'JSON condiviso · $path';
  }

  @override
  String get privacyNoRideExport => 'Nessuna uscita da esportare.';

  @override
  String get consentRawTitle => 'Upload dati grezzi';

  @override
  String get consentRawBody =>
      'Dati grezzi dei sensori solo su Wi-Fi e se accetti. Revocabile in qualsiasi momento.';

  @override
  String get consentHeatmapTitle => 'Heatmap (le tue uscite, anonima)';

  @override
  String get consentHeatmapBody =>
      'In locale: le tue uscite. Con un account: celle anonimizzate senza timestamp. La mappa di frequentazione compare solo quando abbastanza rider sono passati in una cella (k≥5).';

  @override
  String get consentRecoTitle => 'Raccomandazioni prodotti';

  @override
  String get consentRecoBody =>
      'Solo quando è pertinente, con un dato tracciabile. Niente marketing di tracking.';

  @override
  String get consentAnalyticsTitle => 'Analytics';

  @override
  String get consentAnalyticsBody =>
      'Metriche prodotto senza dati di salute né sensori grezzi.';

  @override
  String get consentHealthTitle => 'Dati di salute';

  @override
  String get consentHealthBody =>
      'Preparazione — Health Connect non è ancora collegato. Questo consenso salva solo la tua preferenza per dopo.';

  @override
  String get privacyZoneTapHint => 'Tocca la mappa per posizionare la zona.';

  @override
  String get privacyZoneRadiusHint => 'Il raggio vale per export e heatmap.';

  @override
  String get privacyZoneLabel => 'Etichetta';

  @override
  String get privacyZoneRadiusWord => 'Raggio';

  @override
  String get privacyZoneApplyCoords => 'Applica coordinate';

  @override
  String get privacyZoneCoords => 'Coordinate';

  @override
  String get privacyZoneCoordsHint =>
      'Solo se vuoi impostare il punto con i numeri';

  @override
  String get profilePictureSet => 'Foto profilo impostata';

  @override
  String get profileSaved => 'Profilo salvato';

  @override
  String get profileLocalOnly => 'Solo locale — accedi per il sync';

  @override
  String get profileSyncCloudKept => 'Sync: cloud tenuto';

  @override
  String get profileSyncDeviceUploaded => 'Sync: dispositivo caricato';

  @override
  String get profileSyncCurrent => 'Sync: aggiornato';

  @override
  String get profileSyncConflictTitle => 'Conflitto di sync';

  @override
  String profileSyncConflictBody(String when) {
    return 'Cloud e questo dispositivo differiscono.\nCloud: $when\n\nQuale versione deve valere?';
  }

  @override
  String get profileKeepCloud => 'Tieni il cloud';

  @override
  String get profileForceDevice => 'Forza il dispositivo';

  @override
  String get profileConflictCloud => 'Conflitto: cloud tenuto';

  @override
  String get profileConflictDevice => 'Conflitto: dispositivo forzato';

  @override
  String get profileSyncCancelled => 'Sync annullato';

  @override
  String get profileSignInForBilling => 'Accedi per gestire l\'abbonamento';

  @override
  String get profileNoStripeSub =>
      'Ancora nessun abbonamento Stripe — passa prima a Pro.';

  @override
  String profilePortalError(int code) {
    return 'Portale: $code';
  }

  @override
  String get profileNoPortalUrl => 'Nessun URL portale';

  @override
  String get profileFamilyRiderTitle => 'Rider famiglia';

  @override
  String get profileName => 'Nome';

  @override
  String get profileWeightKg => 'Peso kg';

  @override
  String get profileRiderAdded => 'Rider aggiunto';

  @override
  String get profileRiderFallback => 'Rider';

  @override
  String profileActiveBike(String name, String category) {
    return 'Attiva: $name · $category';
  }

  @override
  String get profileDisciplines => 'Le tue discipline';

  @override
  String get profileDisciplinesHint =>
      'Preferenze per i tour. Il routing segue la bici attiva, non solo questa lista.';

  @override
  String get profileRiderCard => 'Profilo rider';

  @override
  String get profilePublic => 'Pubblico';

  @override
  String get profileAccountSync => 'Account e sync';

  @override
  String get profileCloudBilling => 'Cloud-sync e abbonamento';

  @override
  String get profileSignedIn => 'Accesso effettuato';

  @override
  String get profileFamilyGarage => 'Garage famiglia';

  @override
  String get profileFamilyHint =>
      'Altri rider con il proprio peso — es. partner o figlio.';

  @override
  String get profileLegal => 'Note legali';

  @override
  String get profilePrivacyPolicy => 'Privacy';

  @override
  String get profileImprint => 'Impressum';

  @override
  String get profileWithdrawal => 'Recesso';

  @override
  String get profileSetPrimary => 'Imposta come disciplina principale';

  @override
  String profilePrimarySuffix(String label) {
    return '$label · principale';
  }

  @override
  String get profileNeedOneDiscipline =>
      'Tieni almeno una disciplina selezionata.';

  @override
  String get profileLocalUntilSignIn => 'Locale — sync dopo l\'accesso';

  @override
  String get profileChangePhoto => 'Cambia foto';

  @override
  String get profileActivityLabel => 'Attività — ultime uscite a casa';

  @override
  String get profileBikeOne => 'Bici';

  @override
  String get profileBikes => 'Bici';

  @override
  String get profileRideOne => 'Uscita';

  @override
  String get profileRides => 'Uscite';

  @override
  String get profileKmTotal => 'km totali';

  @override
  String profileKmElevation(int hm) {
    return 'km · $hm hm';
  }

  @override
  String get profileProActive => 'FlowLine Pro attivo';

  @override
  String get profileManage => 'Gestisci';

  @override
  String get profileProPerks =>
      'Mappe offline, bici illimitate, analisi sospensione e bracketing.';

  @override
  String get profileUpgradePro => 'Passa a Pro';

  @override
  String get profileDisplayName => 'Nome visualizzato';

  @override
  String get profileRiderWeight => 'Peso rider (kg)';

  @override
  String get profileRideStyle => 'Stile di guida';

  @override
  String get profileSkillBeginner => 'Principiante';

  @override
  String get profileSkillBasics => 'Basi';

  @override
  String get profileSkillAdvanced => 'Avanzato';

  @override
  String get profileSkillExperienced => 'Esperto';

  @override
  String get profileSkillPro => 'Pro';

  @override
  String get profileSubGarage => 'Garage';

  @override
  String get profileSubWeight => 'Peso rider';

  @override
  String profileSubSkill(int skill) {
    return 'Livello ($skill / 5)';
  }

  @override
  String get profileStyleEfficientPace => 'Efficiente / ritmo';

  @override
  String get profileStyleSteady => 'Costante';

  @override
  String get profileStyleExploring => 'Esplorazione';

  @override
  String get profileStyleCommute => 'Quotidiano / pendolare';

  @override
  String get profileStyleTours => 'Tour';

  @override
  String get profileStyleRelaxed => 'Rilassato';

  @override
  String get profileStyleAggressive => 'Aggressivo';

  @override
  String get profileStyleFlow => 'Flow';

  @override
  String get profileStyleLines => 'Cercare le linee';

  @override
  String get profileStyleEfficient => 'Efficiente';

  @override
  String profileDisciplinesSaved(String list) {
    return 'Discipline: $list';
  }

  @override
  String profileAlsoList(String list) {
    return 'anche $list';
  }

  @override
  String get publicProfileTitle => 'Profilo pubblico';

  @override
  String get publicProfileHint =>
      'Opt-in. Handle sulle voci, niente tracce, niente scheda.';

  @override
  String get publicProfileHandle => 'Handle';

  @override
  String get publicProfileBio => 'Bio';

  @override
  String get publicProfileRegion => 'Regione';

  @override
  String get publicProfileShowRides => 'Mostra il numero di uscite';

  @override
  String get publicProfileFoot =>
      'Niente traccia pubblica, niente DM. L\'handle resta locale fino al sync.';

  @override
  String get hudMediaTitle => 'Media nell\'HUD';

  @override
  String get hudMediaProfileHint =>
      'Accesso opzionale perché l\'HUD mostri il titolo in corso. Play/Pause spesso già funziona senza.';

  @override
  String get hudMediaPrivacyHint =>
      'Impostazione sotto Profilo. Accesso opzionale alla sessione media per il titolo nell\'HUD.';

  @override
  String get onboardHowYouRide => 'Come pedali?';

  @override
  String get onboardYourWeight => 'Il tuo peso';

  @override
  String get onboardFirstRide => 'Prima uscita';

  @override
  String get onboardWeightHint =>
      'Per setup, SAG e autonomia — solo locale, modificabile quando vuoi. Utile anche senza forcella (es. city).';

  @override
  String get onboardGpsHint =>
      'Traccia GPS vera — niente demo. Bici opzionale. MTB, gravel, strada o city: allo stesso modo.';

  @override
  String get onboardGpsStatus => 'Posizione per la traccia GPS…';

  @override
  String get onboardServicesOff =>
      'Attiva i servizi di localizzazione, poi riprova.';

  @override
  String get onboardDeniedForever =>
      'Consenti la posizione nelle impostazioni dell\'app.';

  @override
  String get onboardNeedGps =>
      'Consenti la posizione — senza GPS niente traccia.';

  @override
  String onboardWeightLabel(int kg) {
    return 'Peso rider: $kg kg';
  }

  @override
  String onboardDiscipline(String label) {
    return 'Disciplina: $label';
  }

  @override
  String get onboardSensorsHint =>
      'Posizione per la traccia GPS. Sensori Bluetooth più tardi in officina — per ogni tipo di bici.';

  @override
  String get onboardNextRide => 'Continua verso l\'uscita';

  @override
  String get onboardParkBikeFirst => 'Prima parcheggia una bici';

  @override
  String get onboardLater => 'Configura più tardi';

  @override
  String get offlineMapsTitle => 'Mappe offline';

  @override
  String get offlineMapsHint =>
      'Scarica il grafo di routing e le tile per la regione. Offline: mappa caricata + routing grafo nella bounding box. Le tile Valhalla non sono ancora nei pack.';

  @override
  String get offlineRegionActive => 'Regione attiva';

  @override
  String get offlineNoRegion => 'Nessuna regione attiva';

  @override
  String get offlineReadyBoth => 'Routing + tile pronti.';

  @override
  String get offlineReadyRouting =>
      'Routing pronto — mappa non ancora offline.';

  @override
  String get offlineLoadBelow => 'Carica un pack costruito più sotto.';

  @override
  String get offlineRegions => 'Regioni';

  @override
  String get offlineSearchRegion => 'Cerca regione';

  @override
  String get offlineNoneFound => 'Nessuna regione trovata';

  @override
  String get offlineNoPacks =>
      'Nessun pack scaricabile. Stub sotto — niente grafo demo sotto un altro nome.';

  @override
  String offlineNotBuilt(int count) {
    return 'Non ancora costruito ($count)';
  }

  @override
  String get offlineStubsHint => 'Stub catalogo — download disattivato';

  @override
  String get offlineRemoveRegion => 'Rimuovi regione';

  @override
  String get offlineStyleTitle => 'Stile mappa (opzionale)';

  @override
  String get offlineStyleHint =>
      'Default: DACH z11 style JSON. Cambia solo per il tuo stile MapLibre.';

  @override
  String get offlineStyleUrl => 'URL style JSON';

  @override
  String get offlineSaveStyle => 'Salva stile';

  @override
  String offlineRegionActiveSnack(String name) {
    return '$name attiva';
  }

  @override
  String offlineActivateError(String error) {
    return 'Attiva: $error';
  }

  @override
  String offlinePackError(String error) {
    return 'Pack regione: $error';
  }

  @override
  String get offlineRemoved => 'Regione rimossa';

  @override
  String get offlineNoRemoteDach => 'Nessun pack remoto — fallback DACH attivo';

  @override
  String get offlineNoBuiltPacks => 'Nessun pack costruito su questo server';

  @override
  String get offlineDachCatalog => 'Offline — regioni DACH dal catalogo app';

  @override
  String get offlineReadyMapRouting => 'Mappa + routing pronti';

  @override
  String get offlineRoutingBg =>
      'Routing pronto, mappa in caricamento in background';

  @override
  String get offlineBasemapFail =>
      'Routing pronto — download basemap fallito, la mappa serve il CDN';

  @override
  String get offlineTilesMissing =>
      'Routing pronto, tile mancanti (rete/limite)';

  @override
  String offlineDemoGraph(String name) {
    return 'Grafo demo Foresta Nera attivo — non la mappa $name';
  }

  @override
  String get offlineStyleCleared =>
      'Override cancellato — stile default attivo';

  @override
  String offlineStyleSaved(String url) {
    return 'Stile salvato. La mappa si ricarica: $url';
  }

  @override
  String get platzTogetherKicker => 'USCIRE INSIEME';

  @override
  String get platzTogetherTitle => 'Uscire insieme';

  @override
  String get platzTogetherHint =>
      'Invita condivide il link. Il filtro Tutte, Privato, Pubblico vale anche per i gruppi.';

  @override
  String get platzTogetherListHint =>
      'Gruppo davanti al cancello. Accesso: sul server. Altrimenti solo questo dispositivo — niente utente demo. Pin solo nell\'HUD dopo opt-in.';

  @override
  String get platzCreateGroup => 'Crea gruppo';

  @override
  String get platzJoinCode => 'Codice';

  @override
  String get platzNoGroup =>
      'Ancora nessun gruppo. Solo codici veri — niente di recitato.';

  @override
  String get platzHost => 'Organizzatore';

  @override
  String get platzGuest => 'Ospite';

  @override
  String get platzYou => 'Tu';

  @override
  String get platzInvite => 'Invita';

  @override
  String get platzDissolve => 'Sciogli';

  @override
  String get platzLeave => 'Lascia';

  @override
  String get platzCopyLink => 'Copia link';

  @override
  String get platzInviteShares => 'Invita condivide il link del gruppo';

  @override
  String get platzInviteSharesProfile => ' e il tuo profilo Platz';

  @override
  String platzMembersCount(int count) {
    return '$count dentro';
  }

  @override
  String get platzOnServer => 'sul server';

  @override
  String get platzOnDevice => 'solo su questo dispositivo';

  @override
  String platzCollectionDefaultName(int day, int month) {
    return 'Raccolta $day.$month.';
  }

  @override
  String get platzPinsOff => 'Pin off';

  @override
  String get platzPinsHudOnly => 'Pin solo nell\'HUD';

  @override
  String get platzCollectionsKicker => 'RACCOLTE';

  @override
  String get platzNoCollection => 'Ancora nessuna raccolta — creane una qui.';

  @override
  String platzCollectionTours(int count) {
    return '$count tour';
  }

  @override
  String get platzCreateCollection => 'Crea raccolta';

  @override
  String get platzJoinWithCode => 'Entra con un link';

  @override
  String get platzJoinCodeField => 'Link d’invito';

  @override
  String get platzJoinLinkHint =>
      'Incolla il link da WhatsApp o Messages. Il privato serve il token nel link — niente codice da digitare.';

  @override
  String get platzJoinEmpty => 'Manca il link.';

  @override
  String get platzJoinInvalid => 'Link d’invito non valido.';

  @override
  String get platzJoin => 'Entra';

  @override
  String get platzStartLabel => 'Partenza';

  @override
  String get platzStartNow => 'Ora';

  @override
  String get platzStartIn1h => 'Tra 1 h';

  @override
  String get platzStartToday18 => 'Oggi 18:00';

  @override
  String get platzStartTomorrow10 => 'Domani 10:00';

  @override
  String get platzDurationLabel => 'Durata';

  @override
  String get platzMeetingPlaceholder => 'Punto d\'incontro (opzionale)';

  @override
  String get platzMeetingHint => 'es. parcheggio della piscina';

  @override
  String get platzPinsOnHud => 'Pin nell\'HUD';

  @override
  String get platzTourNotInMappe =>
      'Uscita non nella mappe — apri sulla mappa.';

  @override
  String get platzCollectionsHint =>
      'Si condividono solo uscite condivise o di catalogo. Il GPX privato resta fuori.';

  @override
  String get akteTourKicker => 'Uscita';

  @override
  String get stimmenShareNeedRelease =>
      'Prima condividi sotto Mein — altrimenti il link non porta da nessuna parte.';

  @override
  String get platzNeedSharedTour =>
      'Gruppo solo su un tour condiviso o di catalogo. Il GPX privato resta privato.';

  @override
  String get platzNoSharedTours =>
      'Nessun tour condiviso o di catalogo. Il GPX privato resta fuori.';

  @override
  String platzGroupCreated(String code) {
    return 'Gruppo $code — invita condivide il link.';
  }

  @override
  String platzGroupCreatedNote(String code, String note) {
    return 'Gruppo $code — $note';
  }

  @override
  String platzShareSubject(String title) {
    return 'Uscire insieme: $title';
  }

  @override
  String get platzLinkCopied =>
      'Link copiato. Chi ce l\'ha può entrare finché il gruppo è aperto.';

  @override
  String get platzWindowClosed => 'Finestra chiusa';

  @override
  String platzWindowHours(int hours) {
    return 'Finestra $hours h';
  }

  @override
  String platzWindowMinutes(int minutes) {
    return 'Finestra $minutes min';
  }

  @override
  String get platzWindowOpen => 'Finestra aperta';

  @override
  String platzCollectionShare(String name, String routes) {
    return 'Raccolta « $name »: $routes';
  }

  @override
  String get rerouteTitle => 'Fuori itinerario.';

  @override
  String get rerouteHint => 'Stai calmo — decidi tu.';

  @override
  String get rerouteRejoin => 'Torna all\'itinerario';

  @override
  String get rerouteStay => 'Resta';

  @override
  String get rerouteSkip => 'Salta questo tratto';

  @override
  String get bleOff => 'Bluetooth è off — accendilo.';

  @override
  String get bleDenied => 'Permesso Bluetooth mancante.';

  @override
  String get bleUnavailable =>
      'Bluetooth LE non è disponibile su questo dispositivo.';

  @override
  String get bleScanFailed => 'Ricerca fallita';

  @override
  String get bleConnecting => 'Connessione…';

  @override
  String get blePairFailed => 'Associazione fallita';

  @override
  String get bleNothingFound => 'Niente trovato';

  @override
  String get bleScanAgain => 'Cerca di nuovo';

  @override
  String get bleHowTo => 'Come colleghi';

  @override
  String get watchPairTitle => 'Associa orologio';

  @override
  String get watchPairHint =>
      'Polso solo con 0x180D. La batteria dell\'orologio non è quella della bici.';

  @override
  String get watchScanning => 'Cerco orologio e fascia cardio…';

  @override
  String get watchEmptyHint =>
      'Broadcast on, telefono vicino. Apple Watch non invia polso standard.';

  @override
  String get watchNoHr => 'Niente Heart Rate 0x180D — controlla il broadcast.';

  @override
  String get watchNoDeviceId => 'Collegato, ma senza ID dispositivo';

  @override
  String get bleBikeTitle => 'Associa bici';

  @override
  String get bleBikeHint =>
      'Batteria e assist solo con GATT vero — niente da inventare.';

  @override
  String get bleRememberAnyway => 'Ricorda lo stesso';

  @override
  String get bleScanningDrive => 'Cerco motore e sensori…';

  @override
  String get bleEmptyEbike =>
      'Sveglia il display, chiudi Flow o E-TUBE, tieni il telefono vicino.';

  @override
  String get bleEmptySensor =>
      'Metti il sensore vicino e attivalo sulla bici (magnete/pedivella).';

  @override
  String get bleConnectFailed => 'Connessione fallita';

  @override
  String get dieBoxReady => 'Pronto';

  @override
  String get dieBoxAlmost => 'Quasi pronto';

  @override
  String get dieBoxUnknown => 'Appena arrivato';

  @override
  String get dieBoxNothingDueMonday =>
      'Pronto per lunedì — luci e catena a posto.';

  @override
  String get dieBoxNothingDue => 'Pronto — niente in attesa.';

  @override
  String get dieBoxCscHint =>
      'Accoppia il sensore della bici qui. L’orologio resta su di te in uscita.';

  @override
  String get dieBoxEmptyHint =>
      'Niente iscritto. Nome e tipo bastano — parti solo se sono davvero sulla bici.';

  @override
  String get dieBoxAddSomething => 'Iscrivi qualcosa';

  @override
  String get dieBoxAddMore => 'Iscrivi altro';

  @override
  String get dieBoxBatteryHint =>
      'La carica compare quando un sensore sulla bici si accoppia. Nessun numero prima.';

  @override
  String get dieBoxPressureTitle => 'Segna la pressione';

  @override
  String get dieBoxPressureHint => 'Leggi anteriore e posteriore alla valvola.';

  @override
  String get dieBoxPressureFront => 'Anteriore';

  @override
  String get dieBoxPressureRear => 'Posteriore';

  @override
  String get dieBoxPressureLogged => 'Pressione segnata';

  @override
  String get dieBoxSagTitle => 'Segna la sospensione';

  @override
  String get dieBoxSagHint =>
      'Percentuale su forcella e ammortizzatore. Il SAG è quanto affonda con te sopra.';

  @override
  String get dieBoxSagFork => 'SAG forcella %';

  @override
  String get dieBoxSagShock => 'SAG ammortizzatore %';

  @override
  String get dieBoxSagLogged => 'SAG segnato';

  @override
  String get dieBoxTravelTitle => 'Iscrivi l\'escursione';

  @override
  String get dieBoxTravelHint => 'Solo l’escursione scritta sulla bici.';

  @override
  String get dieBoxTravelFront => 'Anteriore mm';

  @override
  String get dieBoxTravelRear => 'Posteriore mm';

  @override
  String get dieBoxTravelSave => 'Iscrivi';

  @override
  String get dieBoxChainLogged => 'Catena misurata';

  @override
  String get dieBoxChainNotes => 'Misurata col calibro';

  @override
  String get dieBoxSetActiveTitle => 'Porta avanti questa bici';

  @override
  String get dieBoxSetActiveHint =>
      'Una bici sta nel box — cambiare la porta avanti.';

  @override
  String get dieBoxSetActiveCta => 'Imposta come attiva';

  @override
  String get dieBoxLightsTitle => 'Iscrivi le luci';

  @override
  String get dieBoxLightsHint => 'Solo se le luci sono davvero sulla bici.';

  @override
  String get dieBoxLightsCta => 'Iscrivi luci';

  @override
  String get dieBoxLockTitle => 'Iscrivi il lucchetto';

  @override
  String get dieBoxLockHint => 'Solo se c’è un lucchetto sulla bici.';

  @override
  String get dieBoxLockCta => 'Iscrivi lucchetto';

  @override
  String get dieBoxRackTitle => 'Iscrivi il portapacchi';

  @override
  String get dieBoxRackHint => 'Solo se la bici ce l’ha.';

  @override
  String get dieBoxRackCta => 'Iscrivi portapacchi';

  @override
  String get dieBoxBagsTitle => 'Iscrivi le borse';

  @override
  String get dieBoxBagsHint => 'Solo se le borse sono sulla bici.';

  @override
  String get dieBoxBagsCta => 'Iscrivi borse';

  @override
  String get dieBoxPressureMissingTitle => 'Segna la pressione';

  @override
  String get dieBoxPressureMissingHint =>
      'Leggi anteriore e posteriore alla valvola.';

  @override
  String get dieBoxPressureMissingCta => 'Segna la pressione';

  @override
  String get dieBoxTirePressureTitle => 'Segna la pressione gomme';

  @override
  String get dieBoxTirePressureHint =>
      'Leggi anteriore e posteriore alla valvola.';

  @override
  String get dieBoxTravelMissingTitle => 'Iscrivi l’escursione';

  @override
  String get dieBoxTravelMissingHint => 'Solo l’escursione scritta sulla bici.';

  @override
  String get dieBoxTravelMissingCta => 'Iscrivi l\'escursione';

  @override
  String get dieBoxSagMissingTitle => 'Segna la sospensione';

  @override
  String get dieBoxSagMissingHint =>
      'Un numero su forcella e ammortizzatore, letto sulla bici.';

  @override
  String get dieBoxSagMissingCta => 'Segna la sospensione';

  @override
  String get dieBoxChainTitle => 'Segna la catena';

  @override
  String get dieBoxChainHint => 'Misura col calibro, poi segna qui.';

  @override
  String get dieBoxChainCta => 'Catena misurata';

  @override
  String get dieBoxBrakesTitle => 'Iscrivi i freni';

  @override
  String get dieBoxBrakesHint => 'Solo se le pastiglie sono sulla bici.';

  @override
  String get dieBoxBrakesCta => 'Iscrivi freno';

  @override
  String get dieBoxChainDueTitle => 'Controlla la catena col calibro';

  @override
  String get dieBoxChainDueHint => 'Guarda, poi misura col calibro.';

  @override
  String get dieBoxParkTrailTitle => 'Park o trail';

  @override
  String get dieBoxParkTrailHint =>
      'Entrambi i setup ci sono — cambia se vuoi.';

  @override
  String get dieBoxParkTrailCta => 'Cambia';

  @override
  String get dieBoxChipLight => 'Luci';

  @override
  String get dieBoxChipLock => 'Lucchetto';

  @override
  String get dieBoxChipRack => 'Portapacchi';

  @override
  String get dieBoxChipBags => 'Borse';

  @override
  String get dieBoxChipTires => 'Gomme';

  @override
  String get dieBoxChipDropper => 'Telescopica';

  @override
  String get dieBoxChipBrakes => 'Freni';

  @override
  String get dieBoxChipParkTrail => 'Park | Trail';

  @override
  String get dieBoxChipTravel => 'Escursione';

  @override
  String get dieBoxChipCsc => 'CSC';

  @override
  String get dieBoxChipBatteryHonest => 'Batteria onesta';

  @override
  String get dieBoxChipSag => 'SAG';

  @override
  String get dieBoxChipChain => 'Catena';

  @override
  String get dieBoxChipPressure => 'Pressione';

  @override
  String get dieBoxChipCockpit => 'Cockpit';

  @override
  String lastRideKm(String km) {
    return 'Ultimi $km km';
  }

  @override
  String get lastRideNoGps => 'Ultima uscita — senza traccia GPS';

  @override
  String dieBoxSentenceEverydayReady(String name) {
    return '$name vive qui · pronto per lunedì';
  }

  @override
  String get dieBoxBitLightsChainOk => 'Luci e catena ok';

  @override
  String get dieBoxBitPressureUnknown => 'Pressione non misurata';

  @override
  String get dieBoxBitLightsMissing => 'Luci non iscritte';

  @override
  String dieBoxSentenceNotReady(String name) {
    return '$name vive qui';
  }

  @override
  String dieBoxSentenceBits(String name, String bits) {
    return '$name · $bits';
  }

  @override
  String get dieBoxWheelOpen => 'Ruota aperta';

  @override
  String get dieBoxBitPressureLogged => 'Pressione segnata';

  @override
  String get dieBoxBitPressureRough => 'Pressione a occhio — rimisura';

  @override
  String get dieBoxBitBagsYes => 'Borse ci sono';

  @override
  String get dieBoxBitBagsNo => 'Borse non iscritte';

  @override
  String get dieBoxBitChainYes => 'Catena misurata';

  @override
  String get dieBoxBitChainNo => 'Catena non ancora misurata';

  @override
  String get dieBoxBitPressureToday => 'Pressione ancora aperta oggi';

  @override
  String get dieBoxSentencePark => 'Setup park';

  @override
  String get dieBoxSagLoggedShort => 'SAG segnato';

  @override
  String get dieBoxSagMissingShort => 'SAG non misurato';

  @override
  String dieBoxSentenceNoTravel(String name) {
    return '$name vive qui';
  }

  @override
  String get dieBoxDriveAssist => ' · e-assist';

  @override
  String dieBoxSentenceMtb(String name, String travel, String drive) {
    return '$name · $travel$drive';
  }

  @override
  String dieBoxSentenceFallback(String name) {
    return '$name vive qui';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get ok => 'OK';

  @override
  String get remove => 'Rimuovi';

  @override
  String get garageMoreOnBike => 'Altro sulla bici';

  @override
  String get garageMoreOnBikeHint =>
      'Parti, manutenzione, versioni di setup — dietro la Box';

  @override
  String get garageDeleteBike => 'Elimina bici';

  @override
  String get garageDeleteBikeTitle => 'Eliminare questa bici?';

  @override
  String get garageDeleteBikeBody =>
      'Componenti e setup di questa bici spariscono in locale.';

  @override
  String get garageRemovePartTitle => 'Rimuovere il componente?';

  @override
  String garageRemovePartBody(String slot, String name) {
    return '$slot: $name verrà rimosso dal garage.';
  }

  @override
  String get garageNotLogged => 'Non registrato';

  @override
  String get garageOptions => 'Opzioni';

  @override
  String get garageFitTitle => 'Compatibilità';

  @override
  String garageFitStatus(String label) {
    return 'Stato: $label';
  }

  @override
  String garageFitSeverity(String label) {
    return 'Gravità: $label';
  }

  @override
  String get garageFitSeveritySafety => 'critico per la sicurezza';

  @override
  String get garageFitSeverityFunctional => 'funzionale';

  @override
  String get garageFitExplained => 'In parole semplici';

  @override
  String garageFitCondition(String text) {
    return 'Condizione: $text';
  }

  @override
  String garageFitHint(String text) {
    return 'Nota: $text';
  }

  @override
  String get garageFitMissing => 'Info ancora mancanti';

  @override
  String garageFitSource(String url) {
    return 'Fonte: $url';
  }

  @override
  String garageGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String get garageVerdictFits => 'Va bene';

  @override
  String get garageVerdictCheck => 'Controlla';

  @override
  String get garageVerdictNoFit => 'Non va';

  @override
  String get garageVerdictUnclear => 'Incerto';

  @override
  String garageAllCount(int count) {
    return 'tutti $count';
  }

  @override
  String get garageActiveStamp => 'ATTIVO';

  @override
  String get garageFreeOneBikeTitle => 'Free: una bici';

  @override
  String get garageFreeOneBikeBody =>
      'Il piano Free prevede una bici. Puoi comunque crearne altre in locale — i limiti di sync valgono dopo l\'accesso.';

  @override
  String get garageUnlockPro => 'Sblocca Pro';

  @override
  String get garageAddAnyway => 'Crea comunque';

  @override
  String get garageSlotFrame => 'Telaio';

  @override
  String get garageSlotFork => 'Forcella';

  @override
  String get garageSlotRearShock => 'Ammortizzatore';

  @override
  String get garageSlotHeadset => 'Serie sterzo';

  @override
  String get garageSlotStem => 'Attacco';

  @override
  String get garageSlotHandlebar => 'Manubrio';

  @override
  String get garageSlotGrips => 'Manopole';

  @override
  String get garageSlotSeatpost => 'Reggisella';

  @override
  String get garageSlotSaddle => 'Sella';

  @override
  String get garageSlotFrontHub => 'Mozzo anteriore';

  @override
  String get garageSlotRearHub => 'Mozzo posteriore';

  @override
  String get garageSlotFrontRim => 'Cerchio anteriore';

  @override
  String get garageSlotRearRim => 'Cerchio posteriore';

  @override
  String get garageSlotTireFront => 'Gomma anteriore';

  @override
  String get garageSlotTireRear => 'Gomma posteriore';

  @override
  String get garageSlotCassette => 'Cassetta';

  @override
  String get garageSlotChain => 'Catena';

  @override
  String get garageSlotCrankset => 'Guarnitura';

  @override
  String get garageSlotBottomBracket => 'Movimento centrale';

  @override
  String get garageSlotFrontDerailleur => 'Deragliatore';

  @override
  String get garageSlotRearDerailleur => 'Cambio';

  @override
  String get garageSlotShifter => 'Comando';

  @override
  String get garageSlotBrakeFront => 'Freno anteriore';

  @override
  String get garageSlotBrakeRear => 'Freno posteriore';

  @override
  String get garageSlotRotorFront => 'Disco anteriore';

  @override
  String get garageSlotRotorRear => 'Disco posteriore';

  @override
  String get garageSlotMotor => 'Motore';

  @override
  String get garageSlotBattery => 'Batteria';

  @override
  String get garageSlotDisplay => 'Display';

  @override
  String get garageSlotLight => 'Luci';

  @override
  String get garageSlotLock => 'Lucchetto';

  @override
  String get garageSlotRack => 'Portapacchi';

  @override
  String get garageSlotBags => 'Borse';

  @override
  String get garageSlotOther => 'Altro';

  @override
  String get garageGroupSuspension => 'Sospensione';

  @override
  String get garageGroupWheels => 'Ruote';

  @override
  String get garageGroupCockpit => 'Cockpit';

  @override
  String get garageGroupDrivetrain => 'Trasmissione';

  @override
  String get garageGroupBrakes => 'Freni';

  @override
  String get garageGroupPower => 'E-Bike';

  @override
  String get garageGroupOther => 'Altro';

  @override
  String get dieBoxZoneToday => 'Oggi';

  @override
  String get dieBoxZoneOnBike => 'Sulla bici';

  @override
  String get dieBoxZoneSensor => 'Sensore';

  @override
  String get garageCatalogOffline =>
      'Catalogo offline — puoi creare la bici sotto «La mia bici» o «GPX».';

  @override
  String get garageNoHit =>
      'Nessun risultato — usa l\'elenco o cerca diversamente.';

  @override
  String get garageSearchUnavailable =>
      'Ricerca non disponibile — usa l\'elenco.';

  @override
  String get garageFileUnreadable => 'File illeggibile';

  @override
  String get garageGpxInvalid => 'Track GPX non valido (min. 2 punti)';

  @override
  String get garageNeedMakeModel => 'Scegli marca e modello';

  @override
  String garageCreateFailed(String error) {
    return 'Creazione fallita: $error';
  }

  @override
  String get garageOemSetup => 'Setup di serie';

  @override
  String get garageCatalogIdentity => 'Identità catalogo';

  @override
  String get garageImportBike => 'Bici importata';

  @override
  String get garageImportNoGpx => 'Import senza GPX — componenti dopo';

  @override
  String get garageBaseSetup => 'Setup di base';

  @override
  String get garageFreeExtraLocal =>
      'Free: altra bici in locale (multi-bici è Pro).';

  @override
  String garageOemTakeover(int count) {
    return 'Prendi i pezzi di serie ($count)';
  }

  @override
  String get garageOemHint =>
      'Altrimenti solo identità. Il catalogo resta una ricerca.';

  @override
  String garageReachStack(String reach, String stack) {
    return 'Reach $reach mm · Stack $stack mm';
  }

  @override
  String get garageCatalogNotLoaded =>
      'Catalogo non caricato — passa a «La mia bici» o riprova più tardi.';

  @override
  String get garageSearchBrandHint => 'Focus SAM, Canyon Grizl, Stevens …';

  @override
  String get garageSearchIntro =>
      'Cerca marca e modello, fai una foto o scegli dall\'elenco.';

  @override
  String get garageHideList => 'Nascondi elenco';

  @override
  String get garagePickFromList => 'Scegli dall\'elenco';

  @override
  String get garageManufacturer => 'Produttore';

  @override
  String get garageNickname => 'Soprannome (opzionale)';

  @override
  String get garageNicknameHint => 'es. trail';

  @override
  String get garageTravelFrontMm => 'Escursione anteriore (mm)';

  @override
  String get garageTravelRearMm => 'Escursione posteriore (mm)';

  @override
  String get garageTravelOnlyIfPresent => 'Solo se è sulla bici';

  @override
  String get garageOnBikeCheck => 'Sulla bici — spunta solo se c\'è davvero';

  @override
  String get garageBagsOnBike => 'Borse sulla bici';

  @override
  String get garageBrandOptional => 'Marca (opzionale)';

  @override
  String get garageModelOptional => 'Modello (opzionale)';

  @override
  String get garagePickGpx => 'Scegli file GPX';

  @override
  String get garageNameOptional => 'Nome (opzionale)';

  @override
  String get garageMyBike => 'La mia bici';

  @override
  String get garageCatalog => 'Catalogo';

  @override
  String get garageImport => 'Importa';

  @override
  String get garageCreateBike => 'Crea bici';

  @override
  String garageGpxImported(String name, String km) {
    return 'GPX «$name» · $km km';
  }

  @override
  String get garageName => 'Nome';

  @override
  String get garageNameHint => 'es. bici di tutti i giorni';

  @override
  String get garagePhoto => 'Foto';

  @override
  String get garageGallery => 'Galleria';

  @override
  String get garageSlotHeading => 'Slot';

  @override
  String get garageEditPart => 'Modifica pezzo';

  @override
  String get garageInstallPart => 'Installa pezzo';

  @override
  String get garageSearchParts => 'Cerca pezzi (API/cache)';

  @override
  String get garageSearchPartsHint => 'Marca / modello — opzionale';

  @override
  String get garageSearchPartsHelper => 'Senza risultati: dati base a mano';

  @override
  String get garageHits => 'Risultati';

  @override
  String get garageNoHitsManual =>
      'Nessun risultato — compila a mano. La cache può essere vuota.';

  @override
  String garageCacheId(String id) {
    return 'ID cache: $id';
  }

  @override
  String garageCompatAttrs(String slot) {
    return 'Attributi di fit · $slot';
  }

  @override
  String get garageCompatAttrsHint =>
      'Fonte: scheda tecnica o stampa sul pezzo. Lascia vuoto se sconosciuto — allora «dati mancanti», niente indovinelli.';

  @override
  String get garageExtraAttr => 'Altro attributo (avanzato)';

  @override
  String get garageAttrKey => 'Chiave attributo';

  @override
  String get garageAttrValue => 'Valore attributo';

  @override
  String get garageCompatPlaceholder =>
      'Placeholder di fit impostati (es. 148×12 / Microspline) — non è verità da catalogo. Controlla gli attributi.';

  @override
  String garageSagGuideTitle(String kg) {
    return 'Valori di partenza sospensione (ciclista $kg kg)';
  }

  @override
  String garageSagGuideFork(String psi, String min, String max, String sag) {
    return 'Forcella: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String garageSagGuideShock(String psi, String min, String max, String sag) {
    return 'Ammortizzatore: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String get garageSagGuideHint =>
      'Valore di partenza — misura sulla bici, poi raffina.';

  @override
  String get garageMeasureSag => 'Misura SAG';

  @override
  String get garageShowMeasureSteps => 'Mostra i passi';

  @override
  String get garageOdometer => 'Chilometraggio';

  @override
  String get garageOperatingHours => 'Ore di esercizio';

  @override
  String garageOdoStand(String km) {
    return 'Lettura: $km km';
  }

  @override
  String garageHoursStand(String hours) {
    return 'Ore: $hours h';
  }

  @override
  String get garageAddKmNoGps => 'Aggiungi km senza track GPS';

  @override
  String get garageDistanceKm => 'Distanza (km)';

  @override
  String get garageImportKm => 'Importa km (senza ride GPS)';

  @override
  String get garageMaintLog => 'Log manutenzione';

  @override
  String get garageMaintLogEmpty =>
      'Ancora nessuna voce — impostare l\'odometro scrive i log.';

  @override
  String get garageBleScanning => 'Cerco dispositivi …';

  @override
  String get garageBlePaired => 'Dispositivo accoppiato';

  @override
  String garageBlePairedNamed(String name) {
    return 'Accoppiato: $name';
  }

  @override
  String get garageBlePairFailed => 'Accoppiamento fallito';

  @override
  String get garageBleRemoved => 'Sensore rimosso';

  @override
  String get garageBleDisconnected => 'Bluetooth non collegato';

  @override
  String get garageBleHintEbike =>
      'Bosch, Shimano STEPS o CSC. Accendi il display.';

  @override
  String get garageBleHintSensor => 'Sensore sulla bici, non sul ciclista.';

  @override
  String get discoverRefresh => 'Aggiorna';

  @override
  String get discoverChangePlace => 'Cambia luogo';

  @override
  String get discoverSuggestDuration => 'Proponi durata';

  @override
  String get discoverDemoCities => 'Città demo';

  @override
  String discoverNearbyTitle(String profile) {
    return 'Vicino a te · $profile';
  }

  @override
  String get discoverNearbyHintGps =>
      'Tocca per vedere il tracciato · Parti avvia la navigazione';

  @override
  String get discoverNearbyHintNoGps =>
      'Condividi la posizione per tour da qui';

  @override
  String get discoverGrantLocation => 'Condividi posizione';

  @override
  String get discoverSuggestionsComputing => 'Calcolo dei suggerimenti…';

  @override
  String get discoverNoSuggestions =>
      'Nessun suggerimento — imposta un luogo, scegli un profilo o tocca Aggiorna.';

  @override
  String discoverAdaptSuggestion(String label) {
    return 'Adatta il suggerimento: $label';
  }

  @override
  String get discoverTours => 'Tour';

  @override
  String discoverToursLoops(int count) {
    return 'Tour · $count anelli';
  }

  @override
  String discoverToursCount(int count) {
    return 'Tour · $count';
  }

  @override
  String get discoverNoGpsCurated =>
      'Senza GPS: tour scelti · posizione per i vicini';

  @override
  String get discoverGrantLocationNearby =>
      'Condividi la posizione per tour vicino a te';

  @override
  String discoverToursNearbyCount(int count) {
    return '$count tour nelle vicinanze';
  }

  @override
  String discoverCuratedLoops(int count) {
    return '$count anelli scelti';
  }

  @override
  String get discoverOfflineSuffix => ' · offline';

  @override
  String get discoverHeatmapConsent =>
      'Heatmap dopo il consenso — apri privacy';

  @override
  String get discoverRideToStartShort => 'Al via';

  @override
  String get discoverLoopsNearby => 'Anelli vicino a te';

  @override
  String get discoverNoLoop90 =>
      'Nessun anello entro 90 km — regioni successive';

  @override
  String get discoverRecommendedNoGps => 'Tour consigliati · anche senza GPS';

  @override
  String discoverRecommended(int count) {
    return 'Consigliati ($count)';
  }

  @override
  String get discoverRecommendedHint =>
      'Per tutti i tipi di bici · il tracciato arriva quando parti';

  @override
  String discoverInRegion(int count) {
    return 'In zona ($count)';
  }

  @override
  String get discoverToursAround => 'Tour qui intorno';

  @override
  String get discoverAfterLocation => 'Compare dopo la posizione';

  @override
  String get discoverNeedLocationTrails =>
      'Imposta luogo o partenza per la rete trail';

  @override
  String get discoverTrailLoading => 'Rete trail in caricamento…';

  @override
  String get discoverTrailEmpty => 'Nessuna rete OSM di trail qui vicino';

  @override
  String discoverTrailCount(int count) {
    return 'Rete $count · tocca per scegliere';
  }

  @override
  String get discoverTrailOffline => 'Rete trail offline';

  @override
  String get discoverOsmLivePath => 'Percorso OSM live';

  @override
  String get discoverOsmTags => 'Tag da OpenStreetMap';

  @override
  String get discoverTapMapTrails => 'Tocca la mappa per scegliere i trail.';

  @override
  String get discoverTrailApproachHint =>
      'Arriva all\'ingresso, poi salva l\'overlay o parti.';

  @override
  String get discoverTrailGravityHint =>
      'DH: auto o a piedi all\'ingresso in alto. La discesa segue il trail, non la strada.';

  @override
  String get discoverRideToTrailhead => 'Vai al via';

  @override
  String get discoverApproachByCar => 'Arriva in auto';

  @override
  String get discoverApproachOnFoot => 'A piedi all\'ingresso';

  @override
  String get discoverAtTrailStart => 'Sono al via';

  @override
  String get discoverApproachByBike => 'Arriva in bici';

  @override
  String discoverTrailUnsuitableForBike(String bike) {
    return 'Non con $bike su questo trail. Cambia bici in garage — niente routing MTB nascosto.';
  }

  @override
  String get discoverTrailOrientedDownhill => 'Ingresso in alto (quota)';

  @override
  String get discoverTrailStartUphillUnknown =>
      'Quota sconosciuta — ingresso più vicino';

  @override
  String get discoverPutOnRoute => 'Metti sul percorso';

  @override
  String get discoverOpenOsm => 'Apri su OpenStreetMap';

  @override
  String get discoverApproachTrailhead => 'Avvicinamento all\'ingresso…';

  @override
  String discoverApproachPlusTrail(String km, String diff) {
    return 'Avvicinamento + trail · $km km · $diff';
  }

  @override
  String discoverTrailLaid(String diff, String km) {
    return 'Trail posato · $diff · $km km — salva o parti';
  }

  @override
  String get discoverSurfaceNature => 'Naturale';

  @override
  String get discoverSurfaceGrass => 'Erba';

  @override
  String get discoverSurfaceWood => 'Legno';

  @override
  String get discoverHighwayPath => 'Sentiero';

  @override
  String get discoverHighwayTrack => 'Pista forestale';

  @override
  String get discoverHighwayCycle => 'Ciclabile';

  @override
  String get discoverHighwayBridle => 'Ippovia';

  @override
  String get discoverHighwayFoot => 'Pedonale';

  @override
  String get discoverSetStartEnd =>
      'Imposta partenza e arrivo — poi calcola il percorso';

  @override
  String get discoverAdjustStops => 'Regola partenza, arrivo o uno stop';

  @override
  String discoverNoHitsFor(String query) {
    return 'Nessun risultato per «$query»';
  }

  @override
  String get discoverGeocodeFailed => 'Ricerca indirizzo fallita';

  @override
  String discoverStartEndHit(String kind, String label) {
    return '$kind: $label';
  }

  @override
  String get discoverIdeaStartSet =>
      'Idea di tour: partenza = punto, arrivo proposto — calcola il percorso.';

  @override
  String get discoverSuggestEnd => 'Arrivo proposto (modificabile)';

  @override
  String get discoverTourInPlan =>
      'Tour in Pianifica — partenza/arrivo/via modificabili';

  @override
  String get discoverNeedLocationTours => 'Imposta luogo o partenza per i tour';

  @override
  String get discoverOaOffline => 'Tour non raggiungibili ora';

  @override
  String get discoverOaNoLive => 'Nessun tour live qui vicino';

  @override
  String discoverOaCount(int count) {
    return '$count tour qui vicino';
  }

  @override
  String get discoverLocationOff =>
      'Localizzazione off — tocca la partenza o un indirizzo';

  @override
  String get discoverLocationDenied =>
      'Permesso posizione mancante — usa un indirizzo';

  @override
  String get discoverNoGpsFix =>
      'Nessun fix GPS — tocca la mappa o cerca un indirizzo';

  @override
  String get discoverMyPosition => 'La mia posizione';

  @override
  String get discoverLocationReady => 'Posizione pronta · carico i vicini…';

  @override
  String get discoverLocationUnavailable =>
      'Posizione non disponibile — indirizzo o tocca';

  @override
  String get discoverComputing => 'Calcolo del percorso…';

  @override
  String discoverComputingN(int count) {
    return 'Calcolo di $count percorsi…';
  }

  @override
  String get discoverHeadingNorth => 'Verso nord';

  @override
  String get discoverHeadingEast => 'Verso est';

  @override
  String get discoverHeadingSouthwest => 'Verso sud-ovest';

  @override
  String get discoverTargetNorth =>
      'Arrivo a nord — ritorno non ancora incluso';

  @override
  String get discoverTargetEast => 'Arrivo a est — ritorno non ancora incluso';

  @override
  String get discoverTargetSouthwest =>
      'Arrivo a sud-ovest — ritorno non ancora incluso';

  @override
  String discoverApproxLabel(String label) {
    return '$label (approx.)';
  }

  @override
  String get discoverQuickRoute => 'Percorso rapido';

  @override
  String get discoverRoutingLimit =>
      'Limite di routing — usata un\'approx. Ricalcola dopo.';

  @override
  String get discoverNoQuickRoutes => 'Nessun percorso rapido';

  @override
  String get discoverPartialApprox => 'Approx parziale — routing live limitato';

  @override
  String get discoverPlannedRoute => 'Percorso pianificato';

  @override
  String get discoverStraightFallback =>
      'Linea dritta — il routing live non ha dato geometria';

  @override
  String get discoverSaved => 'Salvato';

  @override
  String discoverSavedNamed(String name) {
    return 'Salvato: $name';
  }

  @override
  String get discoverSavedRouteLoaded => 'Percorso salvato caricato';

  @override
  String get discoverStartSetPickEnd =>
      'Partenza impostata — ora scegli l\'arrivo';

  @override
  String get discoverEndSetComputing =>
      'Arrivo impostato — calcolo del percorso';

  @override
  String get discoverFromHere => 'Da qui';

  @override
  String get discoverNearbyPhotos => 'Foto qui vicino';

  @override
  String get discoverToMyTours => 'Ai Miei tour';

  @override
  String get discoverAlreadyInMappe => 'Già nella Mappe';

  @override
  String discoverInMappeNamed(String name) {
    return 'Nella Mappe: $name';
  }

  @override
  String get discoverAddRoute => 'Aggiungi un percorso';

  @override
  String get discoverAddRouteHint =>
      'Nome + partenza — niente traccia inventata. Calcola dopo o GPX.';

  @override
  String get discoverMapCenter => 'Centro mappa';

  @override
  String get discoverSaveToMine => 'Salva nei Miei tour';

  @override
  String discoverSavedToMine(String name) {
    return 'Nei Miei tour: $name';
  }

  @override
  String get discoverPickFileAgain => 'Scegli un altro file';

  @override
  String discoverGpxUnreadable(String name) {
    return 'Impossibile leggere «$name» — danneggiato o GPX non valido.';
  }

  @override
  String get discoverGpxInvalid =>
      'GPX non valido o troppi pochi punti — altro file?';

  @override
  String discoverGpxImported(String name, String km) {
    return 'GPX importato: $name · $km km';
  }

  @override
  String discoverSavedDotName(String name) {
    return 'Salvato · $name';
  }

  @override
  String get discoverAsActive => 'Come attivo';

  @override
  String get discoverLocalFoldersHint =>
      'Cartelle locali per i percorsi salvati — non un feed social.';

  @override
  String get discoverNoSavedInCollection =>
      'Nessun percorso salvato in questa raccolta';

  @override
  String get discoverNoCollectionYet => 'Ancora nessuna raccolta.';

  @override
  String get discoverNewCollection => 'Nuova raccolta';

  @override
  String get discoverNeedRouteAndCollection =>
      'Serve almeno un percorso salvato e una raccolta';

  @override
  String get discoverPickRoute => 'Scegli un percorso';

  @override
  String get discoverPickCollection => 'Scegli una raccolta';

  @override
  String get discoverAddedToCollection => 'Aggiunto alla raccolta';

  @override
  String get discoverRouteToCollection => 'Percorso alla raccolta';

  @override
  String get discoverStartSavedNoTrack =>
      'Partenza salvata — ancora nessuna traccia. Naviga o GPX.';

  @override
  String get discoverComputedRoute => 'Percorso calcolato';

  @override
  String get discoverSavedRoute => 'Percorso salvato';

  @override
  String discoverViaN(int n) {
    return 'Stop $n';
  }

  @override
  String get discoverTourGone => 'Tour non più disponibile';

  @override
  String get discoverTourGoneBody =>
      'Questo tour non è in elenco — magari un filtro lo nasconde.';

  @override
  String get discoverTourTimeline => 'Lungo il tour';

  @override
  String get discoverNoTrackYet =>
      'Ancora nessuna traccia — Calcola percorso la costruisce in live.';

  @override
  String get discoverDuration => 'Durata';

  @override
  String get discoverLength => 'Lunghezza';

  @override
  String get discoverAscent => 'Salita';

  @override
  String get discoverElevationProfile => 'Profilo';

  @override
  String discoverDescent(String m) {
    return '↓ $m m di discesa';
  }

  @override
  String get discoverTip => 'Consiglio';

  @override
  String get discoverBestTime => 'Periodo migliore';

  @override
  String get discoverDiscipline => 'Disciplina';

  @override
  String get discoverCorridor => 'Corridoio';

  @override
  String get discoverTraits => 'Tratti';

  @override
  String get discoverTipsInfo => 'Consigli e info';

  @override
  String get discoverStartPoint => 'Partenza';

  @override
  String discoverFromHereKm(String dist) {
    return '$dist da qui';
  }

  @override
  String get discoverApproach => 'Avvicinamento';

  @override
  String get discoverInMyTours => 'Nei Miei tour';

  @override
  String discoverPinIdeaNamed(String name) {
    return 'Idea «$name» — solo punto';
  }

  @override
  String get discoverPinIdea => 'Idea di tour — solo un punto sulla mappa';

  @override
  String get discoverStartEndReady =>
      'Partenza/arrivo impostati. Calcola il percorso o regola l\'arrivo.';

  @override
  String get discoverComputeAndSave => 'Calcola e salva';

  @override
  String get discoverChangePlaceSearch =>
      'Cambia luogo — cerca città o indirizzo';

  @override
  String discoverDemoRegion(String name) {
    return 'Regione demo: $name';
  }

  @override
  String get discoverPickProfile => 'Scegli profilo';

  @override
  String get discoverOwn => 'Tue';

  @override
  String discoverStartOnlyNoTrack(String badge) {
    return '$badge · partenza — ancora nessuna traccia';
  }

  @override
  String get discoverShowLess => 'Mostra meno';

  @override
  String get discoverShowMore => 'Mostra di più';

  @override
  String get discoverTrailView => 'Vista trail';

  @override
  String get discoverNoPhotosNearby => 'Nessuna foto qui vicino';

  @override
  String get discoverImageUnavailable => 'Immagine non disponibile';

  @override
  String get discoverNoLivePhotos => 'Nessuna foto live';

  @override
  String get discoverOpenMapillary => 'Apri Mapillary';

  @override
  String get discoverMapillarySample => 'Esempio — Mapillary non disponibile';

  @override
  String get discoverNoTrackOnMap =>
      'Nessuna traccia — caricala prima sulla mappa o GPX.';

  @override
  String get discoverNoClosedLoop =>
      'Nessun anello chiuso — scegli di nuovo il tour o Adatta.';

  @override
  String get discoverNoLiveTrackPlan =>
      'Nessuna traccia live — Calcola apre Pianifica con un arrivo proposto.';

  @override
  String get discoverNotClosedLoopNav =>
      'La geometria non è un anello — navigazione annullata.';

  @override
  String get discoverNoRealPolyline =>
      'Nessun tracciato vero — ricalcola o GPX.';

  @override
  String get discoverPoiIdeaHint =>
      'Avvicinamento al punto — niente traccia del tour. Continua l\'arrivo o GPX.';

  @override
  String discoverHybridKm(String km) {
    return 'Ibrido · $km km';
  }

  @override
  String get discoverAroundPoiComputing =>
      'Calcolo di un percorso intorno al punto…';

  @override
  String discoverLiveRouteReady(String km) {
    return 'Percorso live · $km km — salva o parti';
  }

  @override
  String discoverPoiNamed(String name) {
    return 'Punto · $name';
  }

  @override
  String get discoverNotLoopAb =>
      'Non è un anello — proposta A→B. Calcola il percorso o tocca l\'arrivo.';

  @override
  String get discoverApproxAb =>
      'Approx A→B · regola l\'arrivo sulla mappa, poi ricalcola.';

  @override
  String get discoverRoutingFailedRetry =>
      'Routing fallito — tocca l\'arrivo e riprova.';

  @override
  String get discoverUnplausibleDropped =>
      'Risultato di routing poco plausibile scartato';

  @override
  String discoverAltChosen(String label) {
    return 'Alternativa scelta: $label';
  }

  @override
  String get discoverLoading => 'Caricamento';

  @override
  String get discoverCatalog => 'Catalogo';

  @override
  String get discoverShared => 'condiviso';

  @override
  String get discoverPrivate => 'privato';

  @override
  String get discoverPrivateCap => 'Privato';

  @override
  String get discoverShareRelease => 'Condividi';

  @override
  String discoverRiddenWith(String name) {
    return 'pedalato con $name';
  }

  @override
  String get discoverPrivateCommentHint =>
      'Ancora privato — gli altri commentano dopo la condivisione.';

  @override
  String get discoverRemoveFromMappe => 'Togli dalla Mappe';

  @override
  String get discoverLinkNoTrack =>
      'Link senza traccia — troppo lungo per l\'URL. Nome e stats, niente GPS.';

  @override
  String get discoverLinkCopiedTrack =>
      'Link copiato. Include una traccia semplificata.';

  @override
  String get discoverLinkCopiedStats =>
      'Link copiato. Nome e stats, niente traccia.';

  @override
  String get discoverTrackLocal =>
      'Traccia in locale. Sync tra i tuoi dispositivi.';

  @override
  String get discoverNoTrackEntry =>
      'Ancora nessuna traccia — solo la voce nella Mappe.';

  @override
  String get discoverVisibility => 'Visibilità';

  @override
  String get discoverCopyLink => 'Copia link';

  @override
  String get discoverNoSavedFilter => 'Nessun tour in questo filtro.';

  @override
  String get discoverMineEmptyHint =>
      'Ancora nessun percorso tuo — aggiungi un percorso, GPX o registra.';

  @override
  String get overlayLegendTitle => 'Vie · OSM';

  @override
  String get overlayLegendCompactCity => 'City';

  @override
  String get overlayLegendCompactMtb => 'MTB';

  @override
  String get overlayScaleNote =>
      'S0–S3+ solo se il sentiero è valutato. Altrimenti non valutato.';

  @override
  String get overlayRoadAsphalt => 'Ciclabile / asfalto';

  @override
  String get overlayUnrated => 'non classificato';

  @override
  String get overlayLegendEmpty =>
      'Nessun overlay di vie qui. La rete bici segue la mappa sotto.';

  @override
  String get overlayLegendMeshTitle => 'Rete bici · OSM';

  @override
  String get overlayLegendMeshNote =>
      'Percorsi ciclabili segnalati su questa mappa.';

  @override
  String get overlayLegendCompactGravel => 'Gravel';

  @override
  String get discoverChipTooltip => 'Tour e percorsi per tipo di bici';

  @override
  String get discoverLocateLongPress =>
      'La mia posizione · pressione lunga: simbolo navi';

  @override
  String get discoverNavHonestyBike => 'Profili bici: stesso percorso';

  @override
  String get discoverNavHonestyFoot => 'Navi: a piedi';

  @override
  String get stimmenTitle => 'Voci';

  @override
  String get stimmenHint =>
      'Stelle, testo e foto — cloud dopo la condivisione. Niente voci inventate.';

  @override
  String get stimmenWrite => 'Scrivi una voce';

  @override
  String get stimmenHowWas => 'Com\'era il tour?';

  @override
  String get stimmenEmptyName => 'Vuoto resti tu';

  @override
  String get stimmenAddPhoto => 'Aggiungi una foto';

  @override
  String get stimmenSaving => 'Salvataggio …';

  @override
  String get stimmenShareSubject => 'Condividi tour';

  @override
  String get stimmenEmpty => 'Ancora nessuna voce.';

  @override
  String get stimmenLabel => 'Voce';

  @override
  String get stimmenCloudApproved => 'Salvato — pubblicato (condivisione IA)';

  @override
  String get stimmenCloudRejected =>
      'Salvato in locale — il cloud ha rifiutato il testo';

  @override
  String get stimmenCloudPending =>
      'Salvato — locale e in revisione (IA/umano)';

  @override
  String get stimmenCloudLocal => 'Salvato — locale (cloud dopo l\'accesso)';

  @override
  String get stimmenCloudFailed =>
      'Salvato in locale — cloud non raggiungibile';

  @override
  String get akteHonestyCatalog =>
      'I tour da catalogo sono già pubblici. Condividere rende la tua cartella collegabile — il link mostra nome e stats, nessuna traccia privata extra.';

  @override
  String get akteHonestyTrack =>
      'Condividere crea un link. Il link contiene una traccia semplificata (coordinate), non solo il nome. Tornare a privato lo toglie dai filtri e registra la revoca sul server se sei collegato. Senza login vale solo su questo dispositivo.';

  @override
  String get akteHonestyNoTrack =>
      'Condividere crea un link con nome e stats — senza traccia, perché non ce n\'è una.';

  @override
  String get stimmenSubmit => 'Invia';

  @override
  String get ortSheetVia => 'Aggiungi come tappa';

  @override
  String get ortSheetHere => 'Tour verso qui';

  @override
  String get ortSheetMaps => 'Apri in Maps';

  @override
  String get ortKindCafe => 'Caffè';

  @override
  String get ortKindWater => 'Acqua';

  @override
  String get ortKindViewpoint => 'Belvedere';

  @override
  String get ortKindShop => 'Negozio';

  @override
  String get ortKindRepair => 'Officina';

  @override
  String get ortKindTrailhead => 'Partenza';

  @override
  String get ortKindTip => 'Consiglio';

  @override
  String get ortKindMeet => 'Ritrovo';

  @override
  String get ortKindOther => 'Luogo';

  @override
  String get viaMoveUp => 'Su';

  @override
  String get viaMoveDown => 'Giù';

  @override
  String get stimmeTagsHint => 'Stato — opzionale, max tre';

  @override
  String get stimmeTagNass => 'bagnato';

  @override
  String get stimmeTagZu => 'chiuso';

  @override
  String get stimmeTagVielLos => 'affollato';

  @override
  String get stimmeTagTop => 'top';

  @override
  String get stimmeTagBaustelle => 'cantiere';

  @override
  String get postRideStimmeTitle => 'Voce sul tour?';

  @override
  String get postRideStimmeHint =>
      'Solo questo tour, niente traccia nel testo. Saltare va bene.';

  @override
  String get postRideStimmeSkip => 'Non ora';

  @override
  String get postRideStimmeDone => 'Voce salvata.';

  @override
  String get postRideOrtTitle => 'Ricordare questo posto?';

  @override
  String get postRideOrtHint =>
      'Sempre privato su questo giro. Pubblico solo con login, sulla linea, dopo revisione.';

  @override
  String get postRideOrtSkip => 'Non ora';

  @override
  String get postRideOrtDone => 'Posto salvato.';

  @override
  String get postRideOrtNameHint => 'Nome del posto';

  @override
  String get postRideOrtSave => 'Salva';

  @override
  String get postRideOrtOffTrack =>
      'Nessun punto sulla linea percorsa — solo nota privata, senza pin.';

  @override
  String get postRideOrtPrivateOnly =>
      'Solo per te — niente posto community senza login o tour pubblico.';

  @override
  String get postRideOrtPending =>
      'Il cloud tiene il posto dopo la revisione. Fino ad allora solo sul dispositivo.';

  @override
  String get postRideOrtFailed =>
      'Il cloud non ha preso il posto — resta privato sul dispositivo.';

  @override
  String get stimmeDifficultyHint =>
      'Difficoltà rispetto al grado indicato — opzionale';

  @override
  String get stimmeDifficultyEasier => 'più facile';

  @override
  String get stimmeDifficultyAsMarked => 'come indicato';

  @override
  String get stimmeDifficultyHarder => 'più duro';

  @override
  String akteDifficultyCrowdEasier(int n) {
    return 'Rider: più facile del segnato ($n)';
  }

  @override
  String akteDifficultyCrowdAsMarked(int n) {
    return 'Rider: come indicato ($n)';
  }

  @override
  String akteDifficultyCrowdHarder(int n) {
    return 'Rider: più duro del segnato ($n)';
  }

  @override
  String get akteAddToCollection => 'Aggiungi alla raccolta';

  @override
  String get discoverEditorialSets => 'Redazione';

  @override
  String get discoverEditorialHonesty =>
      'Idee redazionali — non raccolte utente.';

  @override
  String get discoverEditorialEmpty =>
      'Questa regione è in catalogo; quei tour non sono in elenco ora.';

  @override
  String get discoverLayerTours => 'Tour';

  @override
  String get discoverLayerPlaces => 'Luoghi';

  @override
  String get discoverLayerHeat => 'Heat';

  @override
  String get discoverLayerHeatOff => 'Heat off';

  @override
  String get discoverVariantPlanned => 'Come previsto';

  @override
  String get discoverVariantFlatter => 'Meno dislivello';

  @override
  String get discoverVariantUnpaved => 'Più sterrato';

  @override
  String get discoverVariantValhallaOnly => 'Varianti solo con Valhalla live';

  @override
  String get discoverTrailWet => 'piuttosto bagnato';

  @override
  String get discoverTrailDamp => 'umido possibile';

  @override
  String get discoverTrailDry => 'piuttosto asciutto';

  @override
  String discoverWeatherStart(String temp, String hint) {
    return 'Partenza $temp° · $hint';
  }

  @override
  String discoverWeatherSummit(String temp, String hint) {
    return 'Cima $temp° · $hint';
  }

  @override
  String get discoverFilmstripAttribution => 'Mapillary CC BY-SA';

  @override
  String get discoverOfflineAfterSave => 'Scaricare la regione offline?';

  @override
  String get discoverOfflineAfterSaveAction => 'Pack';

  @override
  String get discoverRoundTrip => 'Andata e ritorno';

  @override
  String get discoverOutboundOnly => 'solo andata';

  @override
  String get discoverOsmNoHitsSuffix => ' · nessuna via';

  @override
  String get discoverLiveRoutingUnavailable =>
      ' · routing live non disponibile';

  @override
  String get discoverUnplausibleLive =>
      ' · il routing live non ha dato un risultato plausibile';

  @override
  String get discoverTapEndCompute =>
      'Tocca una destinazione o un indirizzo — poi calcola la route.';

  @override
  String get discoverPlanYourself =>
      'Pianifica la route tu — imposta partenza e arrivo';

  @override
  String get discoverLoopBadge => '⟲ Giro';

  @override
  String discoverElevMin(Object min) {
    return 'Min $min';
  }

  @override
  String get discoverHeatmapOffline => 'Heatmap offline';

  @override
  String get discoverCreate => 'Crea';

  @override
  String get discoverRegionSource => 'Regione';

  @override
  String get discoverTourNoun => 'Tour';

  @override
  String get discoverOsmLive => 'OSM live';

  @override
  String discoverApproachParen(Object name) {
    return '($name)';
  }

  @override
  String get discoverShop => 'Negozio';

  @override
  String get discoverPreview => 'Anteprima';

  @override
  String discoverApproachName(Object name) {
    return '$name (avvicinamento)';
  }

  @override
  String discoverFromHereName(Object name) {
    return '$name (da qui)';
  }

  @override
  String get rideLocationOff => 'Posizione spenta';

  @override
  String get rideLocationOffBody =>
      'Senza posizione niente traccia GPS. Attiva i servizi di localizzazione.';

  @override
  String get rideSettings => 'Impostazioni';

  @override
  String get rideLocationPermission => 'Autorizzazione posizione';

  @override
  String get rideLocationDeniedForever =>
      'Posizione negata per sempre. Attivala nelle impostazioni dell\'app, altrimenti la traccia resta vuota.';

  @override
  String get rideAppSettings => 'Impostazioni app';

  @override
  String get rideLocationNeeded =>
      'Serve la posizione per traccia e navigazione — riparti e consenti.';

  @override
  String get rideGpsFix => 'GPS-Fix…';

  @override
  String rideGpsFixN(Object count) {
    return 'GPS-Fix $count…';
  }

  @override
  String get rideGpsStillSim => 'GPS fermo — Sim-Track (non salvare)';

  @override
  String get rideGpsStillWeak => 'GPS fermo — segnale debole / fermo';

  @override
  String get rideGpsSimActive => 'Sim-Track attivo (AETHER_SIM_MOTION)';

  @override
  String get rideBleOffSnack =>
      'Bluetooth spento — puoi pedalare senza sensore; abbina dopo.';

  @override
  String get rideBleDeniedSnack =>
      'Nearby/Bluetooth negato — la navigazione GPS gira senza sensore.';

  @override
  String get rideNoBikeSensor =>
      'Nessun sensore bici — la traccia GPS continua.';

  @override
  String get rideOfflineRerouteToast =>
      'Il reroute serve internet. Resta sulla route caricata.';

  @override
  String get rideStayOnTrail =>
      'Resta sul trail — niente deviazione su strada.';

  @override
  String get rideFollowTrail => 'Segui il trail';

  @override
  String get rideNoGpsRejoin => 'Nessun GPS-Fix per il rejoin';

  @override
  String rideRejoinFailed(Object error) {
    return 'Rejoin fallito: $error';
  }

  @override
  String get rideSkipAheadWhy => 'Tratto saltato — torna alla route.';

  @override
  String get rideRejoinWhy => 'Torna alla route.';

  @override
  String get rideSkipAheadTts => 'Tratto saltato';

  @override
  String get rideRouteRestoredTts => 'Route ripristinata';

  @override
  String get rideOffRouteTts => 'Fuori dalla route';

  @override
  String get rideRerouting => 'La route si ricalcola …';

  @override
  String get rideUndo10s => '10 s per annullare';

  @override
  String get rideUndo => 'Annulla';

  @override
  String get rideStayOffHint => 'Resti fuori route — tocca per le opzioni.';

  @override
  String get rideRecalc => 'Ricalcolo …';

  @override
  String get rideTapOptions => 'Tocca per le opzioni.';

  @override
  String get rideOptions => 'Opzioni';

  @override
  String get ridePause => 'Pausa';

  @override
  String get rideResume => 'Riprendi';

  @override
  String get rideRunning => 'Percorso in corso';

  @override
  String get rideStop => 'Termina';

  @override
  String get rideTapAgain => 'Tocca di nuovo';

  @override
  String get rideStopNeedsTwo => 'Fermare chiede 2 tocchi';

  @override
  String get rideQuietDisplay => 'Vista calma';

  @override
  String get rideFollowCamera => 'Segui la camera';

  @override
  String get rideFollowOn => 'Follow camera on';

  @override
  String get rideFollowFree => 'Camera libera';

  @override
  String get rideLiveRide => 'Percorso live';

  @override
  String get rideReady => 'Pronto';

  @override
  String get rideTtsOn => 'TTS on';

  @override
  String get rideTtsMute => 'TTS muto';

  @override
  String get rideNorthUp => 'Nord in alto';

  @override
  String get rideHeadingUp => 'Direzione in alto';

  @override
  String rideHeadingCourse(Object cardinal, Object mode) {
    return '$mode, rotta $cardinal';
  }

  @override
  String get rideAutoRerouteOn => 'Auto-Reroute on';

  @override
  String get rideAutoRerouteOff => 'Auto-Reroute off';

  @override
  String rideAutoRerouteActive(Object sec) {
    return 'Auto-Reroute attivo (cooldown ${sec}s)';
  }

  @override
  String get rideAutoRerouteManual =>
      'Auto-Reroute off — il rejoin manuale resta';

  @override
  String get rideSunlightAuto => 'Sunlight Mode (Auto)';

  @override
  String get rideSunlightManual => 'Sunlight Mode (Manuale)';

  @override
  String rideDisplayNamed(Object name) {
    return 'Display: $name';
  }

  @override
  String rideDisplayNamedBattery(Object name) {
    return 'Display: $name (consuma batteria)';
  }

  @override
  String get rideCostsBattery => 'consuma batteria';

  @override
  String get rideBatteryTitle => 'Display e batteria';

  @override
  String get rideBatteryHint =>
      'Lasciare il display acceso? Consuma di più. Standard risparmia batteria.';

  @override
  String get rideBatteryPocketSnack =>
      'Pocket — il display può spegnersi (risparmiare).';

  @override
  String get rideBatteryLenkerSnack =>
      'Lenker — display acceso (consuma batteria).';

  @override
  String get rideBatteryUltraSnack =>
      'Ultra — display solo in curva (consuma batteria).';

  @override
  String get rideBatteryPocket => 'Pocket';

  @override
  String get rideBatteryLenker => 'Lenker';

  @override
  String get rideBatteryUltra => 'Ultra';

  @override
  String get rideBatteryPocketSub => 'Voce + aptica, display può spegnersi';

  @override
  String get rideBatteryLenkerSub => 'Lascia il display acceso';

  @override
  String get rideBatteryUltraSub => 'Sveglia il display solo in curva';

  @override
  String get rideDefault => 'Standard';

  @override
  String get rideSpeed => 'Andatura';

  @override
  String get rideSensorSpeed => 'Andatura sensore';

  @override
  String get rideDistance => 'Distanza';

  @override
  String get rideTime => 'Tempo';

  @override
  String get rideHeart => 'Polso';

  @override
  String get rideHeartWaiting => 'Polso in attesa';

  @override
  String get rideCadence => 'Cadenza';

  @override
  String get rideBikeSensor => 'Sensore bici';

  @override
  String get rideWatch => 'Smartwatch';

  @override
  String get rideConnected => 'Collegato';

  @override
  String get ridePower => 'Potenza';

  @override
  String get rideSoc => 'Batteria';

  @override
  String get rideAssist => 'Assist';

  @override
  String get rideBatteryChip => 'Batteria';

  @override
  String get rideWheelSpeed => 'Ruota';

  @override
  String get rideRestKm => 'km rest.';

  @override
  String get rideUntilJoin => 'fino all\'ingresso';

  @override
  String get rideRestLoop => 'resto giro';

  @override
  String rideKmToRoute(String km) {
    return '$km km dalla route';
  }

  @override
  String get rideEta => 'Arrivo';

  @override
  String get rideKmh => 'km/h';

  @override
  String get rideKm => 'km';

  @override
  String get rideChassisOff => 'Analisi telaio off';

  @override
  String get rideChassisHint =>
      'Fissa il telefono al manubrio e segnalo come montato.';

  @override
  String get rideMarkMounted => 'Segna come montato';

  @override
  String get rideWaitingSensors => 'In attesa dei sensori…';

  @override
  String get rideThereafter => 'Poi';

  @override
  String get rideAutoLock => 'Auto-Lock';

  @override
  String get rideAutoLockHint => 'Tocca per svegliare';

  @override
  String get rideWake => 'Sveglia';

  @override
  String get rideMusicHud => 'Musica nel HUD';

  @override
  String get rideMusicHudHint => 'Mostra i titoli di Spotify & Co.';

  @override
  String get rideDismissHint => 'Chiudi avviso';

  @override
  String get rideMusicControls => 'Comandi musica';

  @override
  String get ridePrevTrack => 'Brano precedente';

  @override
  String get rideNextTrack => 'Brano successivo';

  @override
  String get ridePlay => 'Play';

  @override
  String get rideNavSymbol => 'Simbolo';

  @override
  String get rideChangeNavSymbol => 'Cambia simbolo navi';

  @override
  String get rideNavPuckTitle => 'Simbolo navi';

  @override
  String get rideNavPuckHint =>
      'Tutte le varianti su scuro e chiaro. Tocca per scegliere il simbolo mappa e HUD. 0° = punta in alto.';

  @override
  String get rideRecommend => 'Consigliato';

  @override
  String get ridePuckDark => 'Scuro';

  @override
  String get ridePuckLight => 'Chiaro';

  @override
  String get ridePuckBergA => 'Berg-A';

  @override
  String get ridePuckTopDown => 'Bici dall\'alto';

  @override
  String get ridePuckHofTor => 'Hof-Tor';

  @override
  String get ridePuckKomet => 'Aether-Komet';

  @override
  String get ridePuckKiesel => 'Ciottolo';

  @override
  String get ridePuckLenkerBug => 'Prua manubrio';

  @override
  String get ridePuckLichtkegel => 'Cono di luce';

  @override
  String get ridePuckChevron => 'Chevron';

  @override
  String get ridePuckBergASub => 'Lettera, monte e freccia in uno';

  @override
  String get ridePuckTopDownSub =>
      'Dall\'alto: naso, corna, due gomme — gira con te';

  @override
  String get ridePuckHofTorSub => 'Due gambe, aperte in basso';

  @override
  String get ridePuckKometSub => 'Punta di lancia con scintilla arancio';

  @override
  String get ridePuckKieselSub => 'Triangolo morbido con halo';

  @override
  String get ridePuckLenkerBugSub => 'Naso a punta, due corna del manubrio';

  @override
  String get ridePuckLichtkegelSub => 'Disco scuro, cono arancio';

  @override
  String get ridePuckChevronSub => 'Freccia navi standard';

  @override
  String get rideChipLive => 'Live';

  @override
  String get rideChipRouteOffline => 'Route offline';

  @override
  String get rideChipOfflineMapOk => 'Offline · mappa ok · Reroute: rete';

  @override
  String get rideChipMapsMissing => 'Mappe mancanti';

  @override
  String get rideCardinalN => 'N';

  @override
  String get rideCardinalNE => 'NE';

  @override
  String get rideCardinalE => 'E';

  @override
  String get rideCardinalSE => 'SE';

  @override
  String get rideCardinalS => 'S';

  @override
  String get rideCardinalSW => 'SO';

  @override
  String get rideCardinalW => 'O';

  @override
  String get rideCardinalNW => 'NO';

  @override
  String get navCueArrive => 'Destinazione';

  @override
  String get navCueSlightLeft => 'Leggermente a sinistra';

  @override
  String get navCueSlightRight => 'Leggermente a destra';

  @override
  String get navCueTurnLeft => 'Gira a sinistra';

  @override
  String get navCueTurnRight => 'Gira a destra';

  @override
  String get navCueSharpLeft => 'Netta a sinistra';

  @override
  String get navCueSharpRight => 'Netta a destra';

  @override
  String liveHintBracketRun(String n) {
    return 'Passaggio $n rilevato';
  }

  @override
  String get liveHintImpactStreak => 'Sequenza di urti duri';

  @override
  String get liveHintStandSetup => 'Fermo: puoi sistemare';

  @override
  String get maintForkLower => 'Service lower-leg forcella';

  @override
  String get maintForkFull =>
      'Revisione completa forcella (molla/ammortizzatore)';

  @override
  String get maintShockAir => 'Service air-can ammortizzatore';

  @override
  String get maintShockFull => 'Revisione completa ammortizzatore';

  @override
  String get maintChainWear => 'Controlla usura catena';

  @override
  String get maintCassetteCheck => 'Controlla cassetta (dopo 2–3 catene)';

  @override
  String get maintPadsFront => 'Controlla pastiglie anteriori';

  @override
  String get maintPadsRear => 'Controlla pastiglie posteriori';

  @override
  String get maintSealant => 'Rinnova latte tubeless';

  @override
  String get maintDropper => 'Service lower-post dropper';

  @override
  String maintDays(String n) {
    return '$n giorni';
  }

  @override
  String get maintNoInterval => 'Nessun intervallo';

  @override
  String get compatTitleDrv011 =>
      'La cassetta richiede il corpo ruota libera giusto';

  @override
  String get compatTitleFrm004 =>
      'La larghezza del carro deve coincidere col mozzo';

  @override
  String get compatTitleSus007 =>
      'La misura dell\'ammortizzatore deve coincidere col telaio';

  @override
  String get compatTitleSus012 =>
      'Cannotto forcella vs serie sterzo (S.H.I.S.)';

  @override
  String get compatTitleBrk003 => 'Attacco pinza sul telaio';

  @override
  String get compatTitleBrk008 => 'Attacco disco vs mozzo';

  @override
  String get compatTitleBrk008f => 'Disco anteriore vs mozzo anteriore';

  @override
  String get compatTitleWhl005 => 'Larghezza gomma vs canale interno cerchio';

  @override
  String get compatTitleWhl005f => 'Gomma anteriore vs canale interno cerchio';

  @override
  String get compatTitleWhl009 => 'Larghezza gomma vs passaggio telaio';

  @override
  String get compatTitleCkp002 => 'Diametro morsetto manubrio vs attacco';

  @override
  String get compatTitleSpt006 => 'Diametro reggisella vs tubo sella';

  @override
  String get compatTitleBb003 =>
      'Standard movimento centrale vs perno pedivelle';

  @override
  String get compatTitleBb003f => 'Movimento centrale vs standard telaio';

  @override
  String get compatTitleEbk002 => 'Interfaccia motore solo con omologa OEM';

  @override
  String get compatTitleFrm004f => 'Perno anteriore vs forcella';

  @override
  String compatFailDrv011(String cassette, String hub) {
    return 'La cassetta richiede $cassette, il tuo mozzo ha $hub.';
  }

  @override
  String compatFailFrm004(String frame, String hub) {
    return 'Larghezza telaio $frame ≠ mozzo $hub.';
  }

  @override
  String compatFailSus007(String eye, String stroke, String mount) {
    return 'Ammortizzatore $eye×$stroke ($mount) non coincide col telaio.';
  }

  @override
  String compatFailSus012(String fork, String headset) {
    return 'Cannotto $fork non coincide con la serie sterzo $headset.';
  }

  @override
  String compatFailBrk003(String caliper, String frame) {
    return 'Pinza $caliper vs attacco telaio $frame.';
  }

  @override
  String compatFailBrk008(String rotor, String hub) {
    return 'Disco $rotor ≠ mozzo $hub.';
  }

  @override
  String compatFailBrk008f(String rotor, String hub) {
    return 'Disco anteriore $rotor ≠ mozzo $hub.';
  }

  @override
  String compatFailWhl005(String tire, String rim) {
    return 'Larghezza gomma $tire mm fuori range per canale $rim mm.';
  }

  @override
  String compatFailWhl005f(String tire, String rim) {
    return 'Gomma anteriore $tire mm fuori range per $rim mm.';
  }

  @override
  String compatFailWhl009(String tire, String max) {
    return 'Larghezza gomma $tire mm > passaggio telaio $max mm.';
  }

  @override
  String compatFailCkp002(String bar, String stem) {
    return 'Morsetto manubrio $bar mm ≠ attacco $stem mm.';
  }

  @override
  String compatFailSpt006(String post, String frame) {
    return 'Reggisella Ø $post non coincide col telaio Ø $frame.';
  }

  @override
  String compatFailBb003(String bb, String crank) {
    return 'Perno movimento $bb ≠ pedivelle $crank.';
  }

  @override
  String compatFailBb003f(String bb, String frame) {
    return 'Movimento centrale $bb ≠ telaio $frame.';
  }

  @override
  String compatFailEbk002(String frame, String motor) {
    return 'Cambio motore fuori omologa OEM non ammesso. Telaio $frame ≠ motore $motor.';
  }

  @override
  String compatFailFrm004f(String fork, String hub) {
    return 'Perno forcella $fork ≠ mozzo $hub.';
  }

  @override
  String get compatRuleOk => 'Regola soddisfatta.';

  @override
  String get compatConditional => 'Compatibile con riserva';

  @override
  String get compatMissingFacts =>
      'Attributi mancanti — niente COMPATIBLE senza fatti completi.';

  @override
  String get compatWorkshopHint =>
      'Montaggio rilevante per la sicurezza: officina. Coppie solo dai documenti del produttore.';

  @override
  String get compatConditionBrk003 =>
      'Solo con l\'adattatore giusto (Post Mount ↔ IS).';

  @override
  String get compatDatasheet => 'Controlla la scheda del produttore';

  @override
  String get attrFreehub => 'Standard ruota libera';

  @override
  String get attrRearSpacing => 'Larghezza carro';

  @override
  String get attrEyeToEye => 'Lunghezza occhio-occhio';

  @override
  String get attrStroke => 'Corsa';

  @override
  String get attrMountType => 'Tipo di montaggio';

  @override
  String get attrShockEyeToEye => 'Spec telaio: occhio-occhio';

  @override
  String get attrShockStroke => 'Spec telaio: corsa';

  @override
  String get attrShockMount => 'Spec telaio: tipo di montaggio';

  @override
  String get attrSteerer => 'Cannotto forcella';

  @override
  String get attrBrakeMount => 'Attacco pinza';

  @override
  String get attrBrakeMountRear => 'Telaio: attacco freno posteriore';

  @override
  String get attrRotorMount => 'Attacco disco';

  @override
  String get attrTireWidth => 'Larghezza gomma';

  @override
  String get attrRimWidth => 'Canale interno cerchio';

  @override
  String get attrMaxTire => 'Telaio: passaggio gomma max.';

  @override
  String get attrBarClamp => 'Diametro morsetto';

  @override
  String get attrStemClamp => 'Morsetto attacco manubrio';

  @override
  String get attrSeatpostDia => 'Diametro';

  @override
  String get attrMinInsert => 'Inserimento min.';

  @override
  String get attrMaxInsert => 'Telaio: inserimento max.';

  @override
  String get attrCrankAxle => 'Perno pedivelle';

  @override
  String get attrBbStandard => 'Standard movimento centrale';

  @override
  String get attrMotorInterface => 'Interfaccia motore';

  @override
  String get attrAxleFront => 'Perno';

  @override
  String get howToFreehub => 'Stampa corpo ruota libera / scheda mozzo';

  @override
  String get howToRearSpacing => 'Spec telaio/mozzo (Boost 148, 142×12, …)';

  @override
  String get howToEyeToEye => 'Stampa ammortizzatore';

  @override
  String get howToStroke => 'Catalogo ammortizzatore';

  @override
  String get howToMountType => 'Trunnion vs. Eyelet';

  @override
  String get howToSteerer => '1⅛″ o tapered 1,5″ / S.H.I.S.';

  @override
  String get howToBrakeMount => 'Post Mount / Flat Mount / IS';

  @override
  String get howToBrakeMountRear => 'Spec telaio';

  @override
  String get howToRotorMount => 'Center Lock o 6 fori';

  @override
  String get howToTireWidth => 'ETRTO';

  @override
  String get howToRimWidth => 'Scheda cerchio';

  @override
  String get howToMaxTire => 'Dato del produttore telaio';

  @override
  String get howToBarClamp => '31,8 o 35,0';

  @override
  String get howToStemClamp => 'Scheda attacco manubrio';

  @override
  String get howToSeatpostDia => '27,2 / 30,9 / 31,6 / 34,9';

  @override
  String get howToMinInsert => 'Manuale dropper';

  @override
  String get howToMaxInsert => 'Geometria telaio';

  @override
  String get howToCrankAxle => 'DUB / 24mm / 30mm';

  @override
  String get howToBbStandard => 'BSA / T47 / PF92 / …';

  @override
  String get howToMotorInterface => 'es. bosch_smart_system';

  @override
  String get howToAxleFront => '15×100 / 15×110 Boost / …';

  @override
  String postRideObsImpacts(String count, String km) {
    return 'Molti impact duri ($count su $km km) — anteriore/ammortizzatore molto caricati.';
  }

  @override
  String postRideObsSmooth(String km) {
    return 'Pochi impact su $km km — più fluido o fondo liscio.';
  }

  @override
  String postRideObsFlowHigh(String flow) {
    return 'Flow alto ($flow) — ritmo e linea sembravano giusti.';
  }

  @override
  String postRideObsFlowLow(String flow) {
    return 'Flow basso ($flow) — molte interruzioni di ritmo o fermate.';
  }

  @override
  String postRideObsPeakG(String g) {
    return 'Peak $g g — urti duri; controlla setup e pressione.';
  }

  @override
  String get postRideFrontTooFirm => 'troppo dura';

  @override
  String get postRideFrontOk => 'ok';

  @override
  String get postRideBumpsHarsh => 'ruvidi';

  @override
  String postRideObsFbHarsh(String front, String bumps) {
    return 'Feedback: anteriore $front · piccoli urti $bumps.';
  }

  @override
  String get postRideObsFbSoft =>
      'Feedback: l\'anteriore è morbido / affonda in frenata.';

  @override
  String get postRideSugReboundSlowTitle =>
      'Ritorno forcella: 2 click più lento';

  @override
  String postRideSugReboundSlowContent(String current, String next) {
    return 'Circa $current click da chiuso → obiettivo $next.';
  }

  @override
  String get postRideSugReboundSlowEffect =>
      'Anteriore più calmo sulle sequenze, un po\' meno pop.';

  @override
  String get postRideSugReboundFastTitle =>
      'Ritorno forcella: 2 click più veloce';

  @override
  String postRideSugReboundFastContent(String current, String next) {
    return 'Circa $current click → obiettivo $next (meno affondo).';
  }

  @override
  String get postRideSugReboundFastEffect =>
      'Frenata più stabile, meno sensazione di fondocorsa.';

  @override
  String get postRideSugPressureTitle => 'Controlla la pressione anteriore';

  @override
  String get postRideSugPressureContent =>
      'Peak-g molto alto — tieni pressione e spacer volume sulla tabella del produttore.';

  @override
  String get postRideSugPressureEffect =>
      'Meno rischio di fondocorsa, feedback più chiaro.';

  @override
  String get postRideSugLimitsClicks =>
      'Range produttore tipico 0–14 click da chiuso.';

  @override
  String get postRideSugLimitsPressure =>
      'Solo nel range di pressione omologato di gomma/forcella.';

  @override
  String get postRideReasonHarshBumps => 'Feedback “piccoli urti ruvidi”';

  @override
  String get postRideReasonFrontFirm => 'Feedback “anteriore troppo duro”';

  @override
  String postRideReasonImpacts(String count, String km) {
    return '$count impact / $km km';
  }

  @override
  String postRideReasonRms(String rms) {
    return 'RMS $rms g';
  }

  @override
  String get postRideReasonFrontLoad => 'Alto carico di urti sull\'anteriore';

  @override
  String get postRideReasonDive => 'Feedback “affonda”';

  @override
  String get postRideReasonFrontSoft => 'Feedback “anteriore troppo morbido”';

  @override
  String get postRideReasonSoftDive => 'Anteriore troppo morbido / affondo';

  @override
  String get postRideReasonPeakLong => 'Peak ≥ 5 g su un giro più lungo';

  @override
  String get postRideAnalysis => 'Analisi';

  @override
  String postRideExpect(String text) {
    return 'Atteso: $text';
  }

  @override
  String postRideLimit(String text) {
    return 'Limite: $text';
  }

  @override
  String get postRideEvidence => 'Evidenza';

  @override
  String postRideConfidence(String level) {
    return 'Confidenza $level';
  }

  @override
  String get postRideConfHigh => 'alta';

  @override
  String get postRideConfMedium => 'media';

  @override
  String get postRideConfLow => 'bassa';

  @override
  String postRideFactRide(String km, String hm, String min) {
    return '$km km · $hm hm · $min min';
  }

  @override
  String postRideFactMetrics(String flow, String g, String impacts) {
    return 'Flow $flow · Peak $g g · $impacts impact';
  }

  @override
  String postRideFactMetricsLean(
      String flow, String g, String impacts, String lean) {
    return 'Flow $flow · Peak $g g · $impacts impact · Lean $lean°';
  }

  @override
  String postRideFactBike(String name) {
    return 'Bici: $name';
  }

  @override
  String postRideFactSoc(String soc) {
    return 'SOC $soc%';
  }

  @override
  String get rideGPeak => 'G-Peak';

  @override
  String get rideLean => 'Inclin.';

  @override
  String get rideFlow => 'Flow';

  @override
  String garageSetNamed(String name) {
    return 'Imposta $name';
  }

  @override
  String get bleKindPower => 'Powermeter';

  @override
  String get bleKindOtherDrive => 'Motore';

  @override
  String get bleTipBosch => 'Chiudi Flow del tutto · 10–20 cm dal display';

  @override
  String get bleTipShimano =>
      'Chiudi E-TUBE · tocca entro 15 s dopo Power/tasto';

  @override
  String get bleTipYamaha => 'Chiudi e-Sync · velocità via sensore CSC';

  @override
  String get bleTipOtherDrive =>
      'Chiudi l\'app del produttore · display acceso, tieni vicino';

  @override
  String get bleTipCsc => 'Sveglia il sensore sulla bici, tieni vicino';

  @override
  String get bleTipPower => 'Accendi il powermeter, tieni vicino';

  @override
  String get blePairLeadEbike =>
      'Display acceso, app del produttore chiusa, telefono vicino — poi tocca.';

  @override
  String get blePairLeadSensor =>
      'Sveglia il sensore sulla bici, non l\'orologio al polso.';

  @override
  String get bleNoteSensorBrand => 'Sensore';

  @override
  String get bleNoteSensorLine =>
      'Magnete o pedivella, vicino al sensore — non l\'orologio.';

  @override
  String get bleNoteBoschLine =>
      'Chiudi Flow del tutto (non solo in background). Display acceso, 10–20 cm.';

  @override
  String get bleNoteShimanoLine =>
      'Chiudi E-TUBE. Dopo Power o tasto spesso solo 15 s — poi tocca.';

  @override
  String get bleNoteYamahaLine =>
      'Chiudi e-Sync o l\'app TQ. Velocità live di solito solo via CSC.';

  @override
  String get bleNoteFazuaLine =>
      'Remote accesa — CSC e power come un sensore normale.';

  @override
  String get bleNoteOtherBrand => 'Altri';

  @override
  String get bleNoteOtherLine =>
      'Chiudi RideControl / Mission Control. Un telefono, display acceso.';

  @override
  String get bleGattWatchRejected =>
      'Connessione rifiutata — chiudi l\'altra app fitness, tieni l\'orologio vicino.';

  @override
  String get bleGattWatchTimeout =>
      'Timeout — tieni l\'orologio vicino, controlla la frequenza in broadcast.';

  @override
  String get bleGattWatchFailed => 'Connessione orologio fallita';

  @override
  String get bleGattRejectedBosch =>
      'Connessione rifiutata — chiudi Bosch Flow, display acceso, 10–20 cm.';

  @override
  String get bleGattRejectedShimano =>
      'Connessione rifiutata — chiudi E-TUBE, display acceso, tieni vicino.';

  @override
  String get bleGattRejectedGeneric =>
      'Connessione rifiutata — chiudi Bosch Flow / Shimano E-TUBE, display acceso, tieni vicino.';

  @override
  String get bleGattTimeoutBosch =>
      'Timeout — sveglia il display, chiudi Flow, tieni vicino. Valori motore solo con CSC o LDI ufficiale.';

  @override
  String get bleGattTimeoutShimano =>
      'Timeout — chiudi E-TUBE, tocca entro 15 s dopo Power/tasto.';

  @override
  String get bleGattTimeoutDrive =>
      'Timeout — chiudi l\'app del produttore, display acceso. Velocità via sensore CSC.';

  @override
  String get bleGattTimeoutSensor =>
      'Timeout — sveglia il sensore, avvicinati.';

  @override
  String get bleDriveFailBosch =>
      'Bosch trovato, nessun valore motore live. Poi associa un sensore ruota (CSC).';

  @override
  String get bleDriveFailShimano =>
      'Shimano trovato, nessun valore motore live. Poi associa un sensore ruota (CSC).';

  @override
  String get bleDriveFailYamaha =>
      'Yamaha trovato, nessun valore motore live. Associa la velocità via sensore CSC.';

  @override
  String get bleDriveFailGeneric =>
      'Motore trovato, nessun valore motore live. Poi associa un sensore ruota (CSC).';

  @override
  String get bleStatusBtOff => 'Bluetooth spento';

  @override
  String get bleStatusScanFailed => 'Ricerca sensore ruota fallita';

  @override
  String get bleStatusNoSensor => 'Nessun sensore ruota trovato';

  @override
  String get bleStatusNoneInRange => 'Nessuna bici, motore o sensore a portata';

  @override
  String get bleStatusDriveSeen =>
      'Motore visto — associa in officina (Bosch/Shimano)';

  @override
  String get bleStatusNoCscInRange => 'Nessun sensore ruota a portata';

  @override
  String get bleStatusSensorDisconnected => 'Sensore ruota disconnesso';

  @override
  String get bleStatusReconnectLost =>
      'Connessione persa — controlla il display, chiudi Flow/E-TUBE, associa di nuovo in officina.';

  @override
  String bleStatusRetry(String n, String max) {
    return 'Connessione … retry $n/$max';
  }

  @override
  String bleStatusAttempt(String n, String max) {
    return 'Connessione … tentativo $n/$max';
  }

  @override
  String bleStatusReconnect(String n, String max) {
    return 'Riconnessione … ($n/$max)';
  }

  @override
  String bleStatusDriveNoLive(String who) {
    return '$who · trovato — velocità via CSC, batteria solo con GATT standard';
  }

  @override
  String get bleStatusNeedBond =>
      'Il display richiede l\'associazione Bluetooth per la batteria.';

  @override
  String get bleStatusBonding => 'Associazione di sistema …';

  @override
  String bleStatusDriveNeedBond(String who) {
    return '$who · trovato — batteria dopo associazione Bluetooth in officina';
  }

  @override
  String bleConnectedNamed(String name) {
    return '$name connesso';
  }

  @override
  String get bleWordSensor => 'Sensore';

  @override
  String get bleWordWatch => 'Orologio';

  @override
  String get bleSectionDrive => 'Motore';

  @override
  String get bleSectionSensors => 'Sensori';

  @override
  String get watchStatusPickFromList => 'Scegli l\'orologio dalla lista';

  @override
  String get watchStatusScanFailed => 'Ricerca orologio fallita';

  @override
  String get watchStatusConnectedSim => 'Orologio connesso (sim)';

  @override
  String get watchStatusDisconnected => 'Orologio disconnesso';

  @override
  String get watchStatusNoHrService =>
      'Orologio trovato, ma senza servizio polso standard';

  @override
  String get watchStatusReconnectLost =>
      'Orologio disconnesso — controlla il broadcast, associa di nuovo da vicino.';

  @override
  String watchStatusReconnect(String n, String max) {
    return 'L\'orologio si riconnette … ($n/$max)';
  }

  @override
  String watchStatusBattery(String n) {
    return 'Batteria orologio $n %';
  }

  @override
  String get watchHrSensorFallback => 'Sensore di frequenza cardiaca';

  @override
  String get watchCheckBluetooth => 'Controlla Bluetooth';

  @override
  String get watchOutOfRange => 'Orologio fuori portata';

  @override
  String get watchRemoved => 'Orologio rimosso';

  @override
  String watchRememberedOffline(String name) {
    return '$name · memorizzato, non live';
  }

  @override
  String get watchRememberedOfflineNoName => 'Memorizzato, non live';

  @override
  String watchLiveNamed(String name) {
    return '$name · live';
  }

  @override
  String watchLiveBpm(String name, String bpm) {
    return '$name · $bpm bpm';
  }

  @override
  String get watchHonestyHr => 'Polso via BLE standard';

  @override
  String get watchHonestyGarmin => 'Garmin: attiva il broadcast HR';

  @override
  String get watchHonestyApple => 'Apple Watch: niente polso BLE standard';

  @override
  String get watchHonestyGalaxy => 'Galaxy: di solito niente 0x180D';

  @override
  String get watchHonestyUnknown => 'Solo con Heart Rate 0x180D';

  @override
  String get watchTipHr => 'Modalità sensore o broadcast accesa, tieni vicino';

  @override
  String get watchTipGarmin =>
      'Sull\'orologio Garmin: invia frequenza / broadcast';

  @override
  String get watchTipApple =>
      'Niente polso BLE verso Android — HealthKit solo su iPhone';

  @override
  String get watchTipGalaxy =>
      'Solo se l\'orologio invia Heart Rate 0x180D — altrimenti Samsung Health';

  @override
  String get watchTipUnknown => 'Heart Rate 0x180D deve essere attivo';

  @override
  String get watchNotePolarBrand => 'Polar / fascia';

  @override
  String get watchNotePolarLine =>
      'Modalità sensore accesa. Polso standard 0x180D — quello associamo.';

  @override
  String get watchNoteGarminLine =>
      'Invia frequenza / broadcast nelle impostazioni dell\'orologio.';

  @override
  String get watchNoteAppleLine =>
      'Niente polso BLE standard verso Android. Non associare.';

  @override
  String get watchNoteGalaxyLine =>
      'Di solito solo Samsung Health. Solo con 0x180D visibile.';

  @override
  String get watchPairLeadText =>
      'Polso sul rider, non sulla bici. Solo un vero servizio Heart Rate 0x180D.';

  @override
  String get blePairAgain => 'Associa di nuovo';

  @override
  String get bleRemoveDevice => 'Rimuovi dispositivo';

  @override
  String get bleSemanticsPaired => 'Bluetooth associato';

  @override
  String get bleSemanticsPair => 'Associa Bluetooth';

  @override
  String get bleTooltipPair => 'Associa motore o sensore';

  @override
  String get bleRemoveWheel => 'Rimuovi sensore ruota';

  @override
  String get bleRemoveDrive => 'Rimuovi motore';

  @override
  String get bleSemanticsLive => 'Bluetooth live';

  @override
  String get bleTooltipSaved => 'Associato, non connesso';

  @override
  String get watchOtherWatch => 'Un altro orologio';

  @override
  String get bikeCatMtbTrail => 'Trail MTB';

  @override
  String get bikeCatMtb => 'MTB';

  @override
  String get bikeCatEnduro => 'Enduro';

  @override
  String get bikeCatDh => 'Downhill';

  @override
  String get bikeCatGravel => 'Gravel';

  @override
  String get bikeCatRoad => 'Bici da corsa';

  @override
  String get bikeCatUrban => 'City';

  @override
  String get bikeCatCargo => 'Cargo';

  @override
  String get bikeCatFolding => 'Pieghevole';

  @override
  String get bikeCatKids => 'Bambini';

  @override
  String get bikeCatEmtb => 'E-MTB';

  @override
  String get bikeCatEtrekking => 'E-trekking';

  @override
  String get bikeCatHiking => 'A piedi';

  @override
  String get bikeCatEgravel => 'E-gravel';

  @override
  String get bikeCatEcity => 'E-city';

  @override
  String get bikeCatEcargo => 'E-cargo';

  @override
  String get bikeCatEfolding => 'E-pieghevole';

  @override
  String get bikeCatEkids => 'E-bambini';

  @override
  String get bikeCatEroad => 'E-road';

  @override
  String get bikeBlurbMtbTrail => 'Singletrail e bosco';

  @override
  String get bikeBlurbMtb => 'Trail e giri';

  @override
  String get bikeBlurbEnduro => 'Ripido e tecnico';

  @override
  String get bikeBlurbDh => 'Bike park e discesa';

  @override
  String get bikeBlurbGravel => 'Sterrato e distanza';

  @override
  String get bikeBlurbRoad => 'Asfalto e ritmo';

  @override
  String get bikeBlurbUrban => 'Quotidiano e pendolari';

  @override
  String get bikeBlurbCargo => 'Carico e quotidiano';

  @override
  String get bikeBlurbFolding => 'Piegare e portare';

  @override
  String get bikeBlurbKids => 'Bici per bambini';

  @override
  String get bikeBlurbEmtb => 'Trail con assistenza';

  @override
  String get bikeBlurbEtrekking => 'Giri con assistenza';

  @override
  String get bikeBlurbHiking => 'In cammino a piedi';

  @override
  String get bikeBlurbMtbTrailFocus => 'Focus singletrail';

  @override
  String get onboardSportTrail => 'Trail';

  @override
  String sportsSummaryPrimary(String label) {
    return 'Principale: $label';
  }

  @override
  String sportsSummaryPrimaryAlso(String label, String list) {
    return 'Principale: $label · anche $list';
  }

  @override
  String get seasonYearRound => 'Tutto l\'anno';

  @override
  String get seasonSpringSummer => 'Primavera–estate';

  @override
  String get seasonAutumn => 'Autunno';

  @override
  String get seasonWinter => 'Inverno';

  @override
  String get naeheInYourRegion => '~60 min nella tua zona';

  @override
  String get naeheAroundYou => '~60 min intorno a te';

  @override
  String get sportTagTouring => 'Turismo';

  @override
  String get sportTagEbike => 'E-bike';

  @override
  String get overlayRheinNeckar => 'Reno-Neckar / Heidelberg';

  @override
  String get overlaySchwarzwaldNord => 'Foresta Nera sud';

  @override
  String get overlayBodensee => 'Lago di Costanza';

  @override
  String get overlayStuttgart => 'Stoccarda / Neckar medio';

  @override
  String get overlayMuenchen => 'Monaco di Baviera e dintorni';

  @override
  String get overlayNuernberg => 'Norimberga / Franconia';

  @override
  String get overlayFrankfurtRheinMain => 'Francoforte Reno-Meno';

  @override
  String get overlayKoelnRhein => 'Colonia / Renania';

  @override
  String get overlayHamburg => 'Amburgo e dintorni';

  @override
  String get overlayBerlin => 'Berlino e Brandeburgo';

  @override
  String get overlayDresdenElbland => 'Dresda / Elbland';

  @override
  String get overlayWien => 'Vienna e Wienerwald';

  @override
  String get overlaySalzburg => 'Salisburgo';

  @override
  String get overlayInnsbruck => 'Innsbruck / Tirolo';

  @override
  String get overlayZuerich => 'Zurigo e dintorni';

  @override
  String get overlayBern => 'Berna / Altopiano svizzero';

  @override
  String get overlayBasel => 'Basilea / triplice frontiera';

  @override
  String get overlayRuhrgebiet => 'Ruhr';

  @override
  String get overlayDuesseldorf => 'Düsseldorf / Basso Reno';

  @override
  String get overlayHannover => 'Hannover / Leine';

  @override
  String get overlayLeipzig => 'Lipsia / Neuseenland';

  @override
  String get overlayFreiburg => 'Friburgo / Schauinsland';

  @override
  String get overlayKarlsruhe => 'Karlsruhe / Hardt';

  @override
  String get overlayAugsburg => 'Augusta / Lech';

  @override
  String get overlayKiel => 'Kiel / fiordo';

  @override
  String get overlayRostock => 'Rostock / Warnow';

  @override
  String get overlayKassel => 'Kassel / Bergpark';

  @override
  String get overlayTrierMosel => 'Treviri / Mosella';

  @override
  String get overlayPfalz => 'Foresta Palatina';

  @override
  String get overlaySauerland => 'Sauerland';

  @override
  String get overlayEifelTrails => 'Eifel';

  @override
  String get overlayHarz => 'Harz';

  @override
  String get overlayThueringerWald => 'Foresta di Turingia';

  @override
  String get overlayBayerischerWald => 'Foresta Bavarese';

  @override
  String get overlayAllgaeu => 'Algovia';

  @override
  String get overlayChiemgau => 'Chiemgau';

  @override
  String get overlaySaarbruecken => 'Saarbrücken';

  @override
  String get overlayMuenster => 'Münsterland';

  @override
  String get overlayAachen => 'Aquisgrana / triplice frontiera';

  @override
  String get overlayLuebeck => 'Lubecca / Trave';

  @override
  String get overlayBremen => 'Brema / Weser';

  @override
  String get overlayMagdeburg => 'Magdeburgo / Elba';

  @override
  String get overlayErfurt => 'Erfurt';

  @override
  String get overlayKoblenz => 'Coblenza / Reno-Mosella';

  @override
  String get overlayGraz => 'Graz / valle della Mur';

  @override
  String get overlayLinz => 'Linz / Danubio';

  @override
  String get overlayKlagenfurt => 'Klagenfurt / Wörthersee';

  @override
  String get overlayVillach => 'Villach / Drava';

  @override
  String get overlayBregenz => 'Bregenz / Vorarlberg';

  @override
  String get overlayKitzbuehel => 'Kitzbühel / Wilder Kaiser';

  @override
  String get overlayGenf => 'Ginevra / Lago Lemano';

  @override
  String get overlayLausanne => 'Losanna / Lavaux';

  @override
  String get overlayLuzern => 'Lucerna / Lago dei Quattro Cantoni';

  @override
  String get overlayStGallen => 'San Gallo / Appenzello';

  @override
  String get overlayLugano => 'Lugano / Ticino';

  @override
  String get overlayInterlaken => 'Interlaken / Oberland bernese';

  @override
  String get overlayChur => 'Coira / Grigioni';

  @override
  String get overlayZermatt => 'Zermatt / Mattertal';

  @override
  String get overlayStMoritz => 'St. Moritz / Engadina';

  @override
  String get overlayDavos => 'Davos / Landwasser';

  @override
  String get overlayStrasbourg => 'Strasburgo / Ill';

  @override
  String get overlayAlsaceVins => 'Alsazia / Route des Vins';

  @override
  String get overlayVosges => 'Vosgi / Ballon d\'Alsace';

  @override
  String get overlayNancyMoselle => 'Nancy / Mosella';

  @override
  String get overlayJuraFr => 'Giura / Pontarlier';

  @override
  String get overlayAnnecy => 'Annecy / Semnoz';

  @override
  String get overlayMorzine => 'Morzine / Portes du Soleil';

  @override
  String get overlayLyon => 'Lione / Tête d\'Or';

  @override
  String get overlayGrenoble => 'Grenoble / Isère';

  @override
  String get overlayDijon => 'Digione / Canal de Bourgogne';

  @override
  String get overlayChambery => 'Chambéry / Lac du Bourget';

  @override
  String get overlayParis => 'Parigi / Bois e Senna';

  @override
  String get overlayLille => 'Lilla / Cittadella';

  @override
  String get overlayNice => 'Nizza / Promenade des Anglais';

  @override
  String get overlayMarseille => 'Marsiglia / Corniche';

  @override
  String get overlayBordeaux => 'Bordeaux / Garonna';

  @override
  String get overlayToulouse => 'Tolosa / Canal du Midi';

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
    return 'Mappa (zoom $min–$max)…';
  }

  @override
  String offlineProgressMapPercent(String percent) {
    return 'Mappa $percent%';
  }

  @override
  String get offlineProgressActivating => 'Attivazione…';

  @override
  String get offlineProgressManifest => 'Manifest…';

  @override
  String offlineProgressPackFile(String file) {
    return 'Pack $file…';
  }

  @override
  String get offlineProgressGraphFile => 'offline_graph.json…';

  @override
  String get offlineProgressDemoGraph => 'Grafo demo (Foresta Nera)…';

  @override
  String get offlinePacksReadyOne => '1 pack scaricabile';

  @override
  String offlinePacksReadyCount(int count) {
    return '$count pack scaricabili';
  }

  @override
  String offlinePackNotBuilt(String name) {
    return '$name: pack non ancora costruito — nessun download.';
  }

  @override
  String offlineShaMismatch(String sha) {
    return 'SHA-256 non corrisponde a nessun download (atteso $sha)';
  }

  @override
  String offlineInvalidGraphFolder(String id) {
    return 'La cartella $id non contiene un grafo valido per questa regione';
  }

  @override
  String offlineNoRemotePack(String name) {
    return 'Nessun pack remoto per $name. Gli stub del catalogo non attivano il grafo demo di un\'altra regione.';
  }

  @override
  String get offlineDownloadEmpty => 'Download vuoto';

  @override
  String get offlineNoGraphAfterExtract => 'Nessun grafo dopo l\'extract';

  @override
  String get offlineRawPmtiles =>
      'Un .pmtiles grezzo non è supportato — serve uno style JSON MapLibre con source pmtiles://.';

  @override
  String get offlineInvalidUrl => 'URL non valido';

  @override
  String get offlineExpectStyleJson =>
      'Serve un URL di style JSON (*.json o /styles/…), non un file di tile.';

  @override
  String get offlineSubActive => 'Attivo — tocca per aggiornare';

  @override
  String get offlineSubInstalled => 'Installato — tocca per attivare';

  @override
  String get offlineSubDemoGraph => 'Grafo demo nell\'app (nessun pack remoto)';

  @override
  String get offlineSubNotBuilt => 'Non ancora costruito';

  @override
  String get offlineSubLoad => 'Carica routing + mappa';

  @override
  String offlineSubLoadSized(String size) {
    return '$size · routing + mappa';
  }

  @override
  String offlineGraphMissing(String name) {
    return 'Nessun grafo in $name';
  }

  @override
  String offlineGraphSha(String name) {
    return 'Lo SHA del grafo di $name non corrisponde';
  }

  @override
  String offlineGraphDemoMismatch(String name) {
    return 'Il grafo demo Foresta Nera non corrisponde a $name';
  }

  @override
  String get offlineEngineLinkedNoTiles =>
      'Motore grafo · Valhalla collegato, tile regionali ancora assenti';

  @override
  String get offlineEngineTilesNotBuilt =>
      'Motore grafo · tile Valhalla non costruite';

  @override
  String get offlineNoTiles => 'nessuna tile';

  @override
  String get offlineFfiMissing =>
      'FFI mancante — solo grafo / flag Valhalla non collegato';

  @override
  String get offlineValhallaTilesLinked =>
      'Tile Valhalla · libvalhalla collegato';

  @override
  String offlineValhallaTilesUnlinked(String code) {
    return 'Tile Valhalla · UNLINKED (codice $code)';
  }

  @override
  String get offlineValhallaFeature => 'Funzione Valhalla disponibile';

  @override
  String get offlineValhallaNotLinked => 'Valhalla non collegato';

  @override
  String get garageMuscle => 'Muscolare';

  @override
  String garageOemTaken(String name, int count) {
    return '$name: $count pezzi di serie presi.';
  }

  @override
  String garageOemTakenPartial(String name, int taken, int skipped) {
    return '$name: $taken pezzi di serie, $skipped saltati.';
  }

  @override
  String garageOemKitOff(String name) {
    return '$name parcheggiata — aggiungi i pezzi tu, il kit era spento.';
  }

  @override
  String garageGpxSaved(String name, String km) {
    return '$name: GPX salvato ($km km).';
  }

  @override
  String garageKmImported(String km) {
    return '+$km km importati';
  }

  @override
  String get garageLogOdoUpdated => 'Contachilometri aggiornato';

  @override
  String get garageLogHoursUpdated => 'Ore di esercizio aggiornate';

  @override
  String get garageLogGpxImport => 'GPX importato';

  @override
  String get garageLogImportPlaceholder => 'Import senza componenti';

  @override
  String garageLogManualKm(String km) {
    return 'Manuale: $km km';
  }

  @override
  String garageLogManualHours(String hours) {
    return 'Manuale: $hours h';
  }

  @override
  String garageLogPsiFront(String psi) {
    return 'anteriore $psi psi';
  }

  @override
  String garageLogPsiRear(String psi) {
    return 'posteriore $psi psi';
  }

  @override
  String garageLogBarFront(String bar) {
    return 'anteriore $bar bar';
  }

  @override
  String garageLogBarRear(String bar) {
    return 'posteriore $bar bar';
  }

  @override
  String get bikeCatEmtbTrail => 'Trail E-MTB';

  @override
  String get bikeCatEenduro => 'E-Enduro';

  @override
  String get bikeCatEdh => 'E-DH';

  @override
  String discoverCatalogTours(int count) {
    return 'Catalogo $count tour';
  }

  @override
  String discoverCatalogToursSuffix(int count) {
    return ' · Catalogo $count';
  }

  @override
  String discoverToursOsmStatus(int tours, int withTrack, int osm) {
    return 'Tour $tours · $withTrack con traccia';
  }

  @override
  String discoverElevationApprox(String hm) {
    return '~$hm hm (stima — altitudine non disponibile)';
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
    return '$name (piano)';
  }

  @override
  String get demoCityMuenchen => 'Monaco di Baviera';

  @override
  String get demoCityKoeln => 'Colonia';

  @override
  String get demoCityZuerich => 'Zurigo';

  @override
  String get demoCityWien => 'Vienna';

  @override
  String get demoCityKonstanz => 'Costanza';

  @override
  String get demoCityParis => 'Parigi';

  @override
  String get demoCityStrasbourg => 'Strasburgo';

  @override
  String get demoCityNice => 'Nizza';

  @override
  String get postRideStravaConnect => 'Collega Strava in Dati e privacy.';

  @override
  String get postRideStravaKeysMissing =>
      'Chiavi Strava mancanti — usa GPX/FIT.';

  @override
  String get postRideStravaStatusDown =>
      'Stato Strava non raggiungibile — usa GPX/FIT.';

  @override
  String get postRideStravaHint =>
      'Strava: con traccia GPS via Uploads-API; senza traccia solo metadati.';

  @override
  String postRideStravaError(String error) {
    return 'Strava: $error';
  }

  @override
  String get postRideHeatmapPrivate =>
      'Heatmap: tour privato — traccia non inviata.';

  @override
  String postRideHeatmapError(String error) {
    return 'Heatmap: $error';
  }

  @override
  String get postRideSetupSaved => 'Versione setup salvata';

  @override
  String postRideSetupSaveFailed(String error) {
    return 'Salvataggio setup fallito: $error';
  }

  @override
  String get postRideGpxEmpty => 'Nessuna traccia GPS — GPX sarebbe vuoto';

  @override
  String postRideGpxExportError(String error) {
    return 'Export GPX: $error';
  }

  @override
  String postRideFitExportError(String error) {
    return 'Export FIT: $error';
  }

  @override
  String get postRideShareGpx => 'Condividi GPX';

  @override
  String get postRideSimActive => 'Traccia sim era attiva';

  @override
  String postRideSimDistance(String km) {
    return ' (~$km km simulati)';
  }

  @override
  String get postRideSimUnreliable =>
      ' — distanza/analisi poco affidabili. Per uscite vere spegni AETHER_SIM_MOTION.';

  @override
  String get postRideAvgSpeedHigh =>
      'Velocità media insolitamente alta — controlla GPS/sim.';

  @override
  String get postRideSuggestionTaken => 'Applicata';

  @override
  String get postRideSuggestionAccept => 'Accetta consiglio';

  @override
  String get postRideAssistEstimate => 'Assist (stima)';

  @override
  String postRideAssistDominant(String mode, String wh) {
    return 'Dominante: $mode · ~$wh Wh';
  }

  @override
  String postRideAssistApproach(String mode) {
    return 'Stima: $mode (avvicinamento)';
  }

  @override
  String postRideAssistClimb(String mode, String pct) {
    return 'Stima: $mode (salita, $pct %)';
  }

  @override
  String postRideAssistRest(String mode) {
    return 'Stima: $mode (resto)';
  }

  @override
  String get postRideAssistDisclaimer =>
      'Stime da firma potenza/velocità — niente lettura OEM. Niente controllo motore (F-EBK-000).';

  @override
  String get postRideFeelTitle => 'Com\'era la sensazione?';

  @override
  String get postRideFrontSuspension => 'Sospensione anteriore';

  @override
  String get postRideFrontTooSoft => 'troppo morbida';

  @override
  String get postRideBrakeDive => 'Affondo in frenata';

  @override
  String get postRideBrakeDives => 'affonda';

  @override
  String get postRideBrakeNeutral => 'neutro';

  @override
  String get postRideBrakeHarsh => 'duro';

  @override
  String get postRideSmallBumps => 'Piccoli urti';

  @override
  String get postRideBumpsVague => 'vago';

  @override
  String get postRideSaveFeedback => 'Salva feedback';

  @override
  String get postRideShortRideMetrics =>
      'Uscita breve — metriche limitate (< 0,5 km).';

  @override
  String get postRideMetricsTitle => 'Metriche';

  @override
  String get postRideDefaultName => 'Uscita';

  @override
  String get platzCreateGroupHint =>
      'Scegli il tour, la visibilità, poi condividi il link.';

  @override
  String get platzGroupPublicHint =>
      'Chi ha il link può entrare. Il gruppo può stare sul Platz sotto Pubblico.';

  @override
  String get platzGroupPrivateHint =>
      'Solo chi ha il link può entrare. Niente elenco pubblico.';

  @override
  String get platzNoPrivateGroups => 'Nessun gruppo privato in questo filtro.';

  @override
  String get platzMakePrivate => 'Rendi privato';

  @override
  String get platzMakePublic => 'Rendi pubblico';

  @override
  String get platzNoPublicGroups => 'Nessun gruppo pubblico sul server.';

  @override
  String get platzPublicGroupsHint =>
      'Gruppi pubblici — entra con login, niente GPS Explore.';

  @override
  String get platzListedPublic => 'pubblico';

  @override
  String get filterVisibilityAll => 'Tutte';

  @override
  String get filterVisibilityPublic => 'Pubblico';

  @override
  String get mappeTitle => 'Die Mappe';

  @override
  String get mappeSubtitle =>
      'I tuoi tour, Stimmen e gruppi. Gli stessi della mappa.';

  @override
  String get mappeAddHint =>
      'Nome + partenza — senza traccia inventata. GPX come opzione sotto.';

  @override
  String get mappePutIn => 'Metti nella Mappe';

  @override
  String mappeSaved(String name) {
    return 'Nella Mappe: $name';
  }

  @override
  String mappeImported(String name) {
    return 'Importato: $name';
  }

  @override
  String get mappeEmpty => 'Ancora nessuna traccia tua — aggiungi un percorso.';

  @override
  String get mappeStimmenEmpty =>
      'Ancora nessuna Stimme sui tuoi tour. Dopo la condivisione gli altri possono scrivere.';

  @override
  String get myRoutesSourceOwn => 'Proprie';

  @override
  String get privacyZoneTitle => 'Privacy-Zone';

  @override
  String get privacyZoneEdit => 'Modifica zona';

  @override
  String get privacyZoneInvalidCoords => 'Inserisci coordinate valide';

  @override
  String get privacyZoneNeedTap => 'Tocca prima la mappa';

  @override
  String get privacyZoneTapShort => 'Tocca la mappa';

  @override
  String get retry => 'Riprova';

  @override
  String get hofSystemStatus => 'Stato di sistema';

  @override
  String get hofSystemOk => 'Tutto collegato — officina, uscite e sync vanno.';

  @override
  String get hofSupabaseMissing => 'Supabase non configurato';

  @override
  String get hofSupabaseMissingHint =>
      'Cloud-sync non è impostato — accesso e sync sono off.';

  @override
  String get hofSyncSessionExpired => 'Sync: sessione scaduta';

  @override
  String get hofSyncLoginOnly => 'Sync solo con login';

  @override
  String get hofSyncLocalHint =>
      'Garage/Rides restano locali — account per il cloud-sync.';

  @override
  String get hofSystemNotice => 'Stato di sistema — avviso presente';

  @override
  String get hofSystemHint => 'Stato di sistema — avviso';

  @override
  String get hofSystemOkTooltip => 'Stato di sistema: ok';

  @override
  String get hofTafelTitle => 'Die Tafel';

  @override
  String hofTafelVoiceOne(String name) {
    return 'Nuova Stimme su $name';
  }

  @override
  String hofTafelVoices(int count, String name) {
    return '$count Stimmen su $name';
  }

  @override
  String hofTafelGroup(String title) {
    return 'Gruppo davanti al cancello · $title';
  }

  @override
  String ridePuckSemantics(String name) {
    return 'Navigazione, $name';
  }

  @override
  String dieBoxSentenceHome(String name) {
    return '$name vive qui';
  }

  @override
  String get dieBoxLater => 'Più tardi';

  @override
  String dieBoxSentenceMtbReady(String name, String travel, String drive) {
    return '$name · $travel$drive · pronto';
  }

  @override
  String dieBoxSentenceReadyBits(String name, String bits) {
    return '$name · $bits · pronto';
  }
}
