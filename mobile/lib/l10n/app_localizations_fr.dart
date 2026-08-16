// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FlowLine';

  @override
  String get appTagline =>
      'Ride further. Flow better — MTB, gravel, route, city & e-bike.';

  @override
  String get navHome => 'Home';

  @override
  String get navGarage => 'Garage';

  @override
  String get navRide => 'Rouler';

  @override
  String get navDiscover => 'Tours';

  @override
  String get navParts => 'Pièces';

  @override
  String get navKarte => 'Carte';

  @override
  String get navWorkshop => 'Atelier';

  @override
  String get navShop => 'Magasin';

  @override
  String get navPlatz => 'Platz';

  @override
  String get hofJustRide => 'Juste rouler';

  @override
  String get hofShowTours => 'Afficher les tours';

  @override
  String get hofMapChoiceHint =>
      'Pars sans itinéraire, ou affiche les tours sur la carte.';

  @override
  String get werkstattPartsShelf => 'Shop';

  @override
  String get werkstattForYourBike => 'Pour ton vélo';

  @override
  String get werkstattMerch => 'Merchandise';

  @override
  String get werkstattShopParts => 'Pièces dans le magasin';

  @override
  String get shopGatewayKicker => 'De l\'autre côté de la cour';

  @override
  String get shopGatewayTitle => 'Le magasin';

  @override
  String get shopGatewayHint =>
      'Le vélo n\'habite pas ici. FlowLine montre des pièces honnêtes — achat et caisse chez Shopify, pas dans l\'app.';

  @override
  String get shopZumShop => 'Vers le magasin';

  @override
  String shopForYourBikeHint(String name) {
    return 'Pièces qui vont à $name — catégorie et roue. Pas de SKU inventés.';
  }

  @override
  String get shopForYourBikeEmpty =>
      'Gare un vélo dans l\'atelier — ensuite on ouvre les pièces qui collent, dans le magasin.';

  @override
  String get shopMerchHint =>
      'Vêtements et petites choses. Jamais filtrés selon le vélo.';

  @override
  String get shopNotConnected => 'Magasin non connecté';

  @override
  String get shopNotConnectedHint =>
      'Pas d\'URL storefront. Définis SHOPIFY_STOREFRONT_URL, ensuite cet onglet ouvre le magasin.';

  @override
  String get shopOpenFailed => 'Impossible d\'ouvrir le magasin.';

  @override
  String get shopPasswordWall =>
      'Le shop Shopify est encore en aperçu propriétaire (dev store). Les liens externes peuvent tomber sur la page mot de passe. Le catalogue peut vivre ici dans FlowLine.';

  @override
  String get shopLockedTitle => 'Online Store verrouillé';

  @override
  String get shopPasswordConfirm => 'Ouvrir quand même';

  @override
  String get shopPasswordCancel => 'Retour';

  @override
  String get shopCyclingParts => 'CYCLING PARTS';

  @override
  String get shopSearchHint => 'Pièces, marques, specs…';

  @override
  String get shopFeatured => 'Pièces qui collent';

  @override
  String get shopOpenProduct => 'Ouvrir dans le magasin';

  @override
  String get shopAllParts => 'Toutes les pièces';

  @override
  String shopFitBanner(String name) {
    return 'Pièces qui vont à $name';
  }

  @override
  String get shopShelfEmpty => 'Aucune pièce pour cette recherche.';

  @override
  String get shopCatalogEmpty =>
      'Pas encore de pièces en rayon. La porte ouvre quand même Shopify.';

  @override
  String get shopFitOnly => 'Seulement adaptées';

  @override
  String get shopFitAllBikes => 'Tous les vélos';

  @override
  String get shopFitBannerAll => 'Pièces qui vont à tes vélos';

  @override
  String get shopOpenInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get shopZumHaendler => 'Chez le revendeur';

  @override
  String get shopOpenInApp => 'Voir dans le magasin';

  @override
  String get shopProductMissing => 'Ce produit n\'est pas dans le magasin.';

  @override
  String get shopCatalogFailed =>
      'Catalogue injoignable pour l\'instant. La porte du magasin ouvre quand même Shopify.';

  @override
  String get shopRetry => 'Réessayer';

  @override
  String get shopSheetCheckout => 'Caisse chez Shopify, pas dans FlowLine.';

  @override
  String get shopDetails => 'Détails';

  @override
  String get shopFeaturedBikes => 'Vélos dans le magasin';

  @override
  String get garageSetupTabHintTires =>
      'Pression à la louche selon le poids et les pneus — mesure au vélo, pas un tableau OEM.';

  @override
  String get werkstattSetupTires => 'Pneus / pression à la louche';

  @override
  String get werkstattSetupSuspension =>
      'Suspension — SAG et air selon le débattement';

  @override
  String get werkstattSetupSuspensionUnknown =>
      'Suspension — débattement non inscrit';

  @override
  String get werkstattSetupDropper => 'Tige télesco (inscrite)';

  @override
  String werkstattSetupWheel(String size) {
    return 'Roue $size';
  }

  @override
  String get werkstattSetupCockpit => 'Cockpit — cintre et potence';

  @override
  String get werkstattSetupBagsCockpit => 'Sacoches / cockpit';

  @override
  String get werkstattSetupLightsRack =>
      'Éclairage et porte-bagages — seulement si inscrit';

  @override
  String get werkstattSetupDrivetrain => 'Transmission';

  @override
  String get werkstattBatteryHonest =>
      'Batterie seulement avec un vrai capteur';

  @override
  String get werkstattBatteryHonestHint =>
      'Pas de pourcentage sans capteur appairé. Bosch LDI reste G-1.';

  @override
  String get werkstattSensorEbike =>
      'Capteur roue (CSC) — vitesse et cadence. Batterie seulement avec un vrai capteur.';

  @override
  String get werkstattSensorAnalog =>
      'Capteur roue — vitesse et cadence sur le vélo.';

  @override
  String get hofYourWatch => 'Ta montre';

  @override
  String get hofWatchHint =>
      'Suivi fitness sur le rider — pas sur le vélo. Pouls seulement avec un vrai capteur. Apple Watch souvent sans BLE standard.';

  @override
  String get hofWatchPair => 'Appairer la montre';

  @override
  String get hofWatchReconnect => 'Connecter';

  @override
  String get hofWatchRemove => 'Retirer';

  @override
  String get hofWatchConnect => 'Connecter la montre';

  @override
  String get hofYou => 'Toi';

  @override
  String get hofYouSheetHint =>
      'Toi et ta montre. Le capteur roue reste sur le vélo, dans l\'atelier.';

  @override
  String get werkstattWatchEbike =>
      'Montre — pouls à côté du CSC. Pas de SoC inventé.';

  @override
  String get werkstattWatchAnalog => 'Montre / suivi fitness';

  @override
  String get setupTirePressureLabel => 'Pneu avant (psi)';

  @override
  String get setupCompareHintTires =>
      'Crée deux pressions à l\'aveugle. Après quelques sorties tu verras laquelle se sent mieux.';

  @override
  String setupTirePressureValue(String value) {
    return 'Pneus $value psi';
  }

  @override
  String get searchHome => 'Où tu vas ? Lieu, tour ou adresse';

  @override
  String get startRide => 'Démarrer la sortie';

  @override
  String get startFreeride => 'Rouler sans itinéraire';

  @override
  String get startWithRoute => 'Suivre l\'itinéraire';

  @override
  String get goRide => 'On y va';

  @override
  String get readyTitle => 'Prêt à rouler';

  @override
  String get readyMessage =>
      'Le GPS démarre tout de suite. Capteurs et itinéraire sont optionnels — trail, asphalte ou city.';

  @override
  String get optionalRoute =>
      'Optionnel : sous Tours, choisis un itinéraire et appuie sur « On y va ».';

  @override
  String get starting => 'Démarrage…';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String errorPrefix(String error) {
    return 'Erreur : $error';
  }

  @override
  String get discoverMenuPhotos => 'Photos autour';

  @override
  String get discoverMenuOffline => 'Cartes hors ligne';

  @override
  String get discoverMenuCollections => 'Collections';

  @override
  String get discoverMenuPrivacy => 'Heatmap & confidentialité';

  @override
  String get partsTitle => 'Pièces & accessoires';

  @override
  String get partsSubtitle =>
      'Pièces featured en live dans FlowLine — soft-fit et prix, sans impasse mot de passe Shopify.';

  @override
  String get weatherFallback => 'Météo indisponible';

  @override
  String get weatherLoading => 'Météo en cours…';

  @override
  String get statsRidesOne => 'sortie';

  @override
  String get statsRidesMany => 'sorties';

  @override
  String get profile => 'Profil';

  @override
  String get chat => 'Chat';

  @override
  String get hofRideOut => 'Sortir';

  @override
  String get hofOpenBike => 'Ouvrir le vélo';

  @override
  String get hofParkBike => 'Garer le vélo';

  @override
  String get hofRideWithoutBike => 'Rouler sans vélo';

  @override
  String get hofRideOutAgain => 'Ressortir';

  @override
  String get hofAtGate => 'devant le portail';

  @override
  String get hofEmptyStand => 'Emplacement vide';

  @override
  String get hofSkyUnknown => 'Ciel inconnu';

  @override
  String get hofNoHonestLoop => 'Pas de vraie boucle trail';

  @override
  String get hofNotYetOut => 'pas encore dehors';

  @override
  String get hofJustBack => 'vient de rentrer';

  @override
  String hofAgoMinutes(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String hofAgoHours(int hours) {
    return 'il y a $hours h';
  }

  @override
  String get hofWhatCameIn => 'Ce qui est rentré';

  @override
  String hofPackMissing(String name) {
    return 'Pas de pack pour $name';
  }

  @override
  String get hofLastRideNoGps => 'sans trace GPS — rien d\'inventé';

  @override
  String get hofGpsUnknown =>
      'Pas de position — ciel et portail attendent le GPS.';

  @override
  String get rideGpsUnavailable =>
      'Pas de GPS — la trace reste vide. Rien d\'inventé.';

  @override
  String get hofAtHof => 'au stand';

  @override
  String get hofSinceOneDay => 'depuis 1 jour';

  @override
  String hofSinceDays(int days) {
    return 'depuis $days jours';
  }

  @override
  String get hofNoBikeHere => 'Aucun vélo ici';

  @override
  String hofBringForward(String name) {
    return 'Mettre $name devant';
  }

  @override
  String hofCareInWorkshop(String label) {
    return '$label — dans l\'atelier';
  }

  @override
  String get hofSensorAwake => 'Capteur réveillé';

  @override
  String get hofOpenTours => 'Ouvrir les tours';

  @override
  String hofSkyDry(String temp) {
    return '$temp° · plutôt sec';
  }

  @override
  String hofSkyDamp(String temp) {
    return '$temp° · humidité possible';
  }

  @override
  String hofSkyWet(String temp) {
    return '$temp° · pluie · trails plutôt mouillés';
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
  String get hofGateAwayNear => 'moins d’1 km';

  @override
  String hofCommunityNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes sur cette boucle',
      one: '1 note sur cette boucle',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMtb => 'Trails, tours et ton setup';

  @override
  String get homeSubtitleGravel => 'Gravel, distance et navigation';

  @override
  String get homeSubtitleRoad => 'Asphalte, allure et entraînement';

  @override
  String get homeSubtitleUrban => 'Trajet, ville et quotidien';

  @override
  String get homeSubtitleEbike => 'Assist, autonomie et tours';

  @override
  String get homeSubtitleDefault =>
      'Toutes les façons de rouler — ton vélo, ton itinéraire';

  @override
  String homeSubtitleWithWeather(String weather, String base) {
    return '$weather · $base';
  }

  @override
  String get tipHeroTitleMtb => 'Aujourd\'hui, dehors à vélo';

  @override
  String get tipHeroTitleGravel => 'Aujourd\'hui gravel ou mix';

  @override
  String get tipHeroTitleRoad => 'Aujourd\'hui des kilomètres d\'asphalte';

  @override
  String get tipHeroTitleUrban => 'Aujourd\'hui à travers la ville';

  @override
  String get tipHeroTitleEbike => 'Aujourd\'hui avec assist';

  @override
  String get tipHeroTitleDefault => 'Aujourd\'hui une sortie colle';

  @override
  String get tipHeroSubtitleMtb =>
      'Choisis un itinéraire ou roule libre — trace locale.';

  @override
  String get tipHeroSubtitleGravel =>
      'Prévois une distance ou pars sans itinéraire.';

  @override
  String get tipHeroSubtitleRoad =>
      'Construis une boucle ou enregistre un entraînement libre.';

  @override
  String get tipHeroSubtitleUrban =>
      'Enregistre le trajet ou sauve une courte boucle.';

  @override
  String get tipHeroSubtitleEbike =>
      'Planifie un tour et garde l\'autonomie en vue.';

  @override
  String get tipHeroSubtitleDefault =>
      'MTB, gravel, route ou city — tout est ici.';

  @override
  String get chassisLayer => 'Suspension';

  @override
  String get sensorLayer => 'Capteurs';

  @override
  String get filter => 'Filtres';

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get filterResetFilters => 'Réinitialiser les filtres';

  @override
  String get filterDurationLens => 'Durée';

  @override
  String get filterSurfaceGroup => 'Revêtement';

  @override
  String get filterExertion => 'Difficulté';

  @override
  String get filterDistance => 'Distance';

  @override
  String get filterElevation => 'Dénivelé';

  @override
  String get filterForm => 'Forme';

  @override
  String get filterTrailNetwork => 'Réseau trail (carte)';

  @override
  String get filterLoopsOnly => 'Boucle';

  @override
  String get filterLoopsOnlyTooltip =>
      'Seulement de vraies boucles (départ≈arrivée). Pas de remplissage A→B.';

  @override
  String get filterNetworkOn => 'Réseau on';

  @override
  String get filterNetworkOff => 'Réseau off';

  @override
  String filterOsmScaleTooltip(String code) {
    return 'Échelle OSM : $code';
  }

  @override
  String filterShowTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count tours',
      one: 'Afficher 1 tour',
    );
    return '$_temp0';
  }

  @override
  String get filterNoTours => 'Aucun tour avec ces filtres.';

  @override
  String get filterNoToursHint =>
      'Aucun tour — appuie sur « Nouveau » ou desserre les filtres.';

  @override
  String get loopLabel => 'Boucle';

  @override
  String get computeRoute => 'Calculer l\'itinéraire';

  @override
  String get adaptTour => 'Adapter';

  @override
  String get adaptTourTitle => 'Adapter le tour';

  @override
  String get adaptTourHint =>
      'Change départ, arrivée ou stop — puis calcule l\'itinéraire.';

  @override
  String get planRouteTitle => 'Planifier l\'itinéraire';

  @override
  String get planRouteCta => '+ Planifier';

  @override
  String get discoverSearchHint => 'Lieu ou tour';

  @override
  String filterAroundKm(int km) {
    return 'dans $km km';
  }

  @override
  String get mapToggleFab => 'Carte';

  @override
  String get communityWriteReview => 'Écrire un avis';

  @override
  String get discoverModeExplore => 'Explorer';

  @override
  String get discoverModeNavigate => 'Naviguer';

  @override
  String get discoverModeMine => 'Les miens';

  @override
  String get navigateTitle => 'Naviguer';

  @override
  String get navigateSubtitle =>
      'Tape l\'arrivée ou une adresse — puis calcule';

  @override
  String get navigateStartLabel => 'Départ';

  @override
  String get navigateEndLabel => 'Arrivée';

  @override
  String get navigateStartHint => 'Adresse, lieu ou tap sur la carte';

  @override
  String get navigateEndHint => 'Où tu vas ?';

  @override
  String get navigateMyLocation => 'Ma position';

  @override
  String get navigateSwap => 'Inverser départ et arrivée';

  @override
  String get navigatePickStart => 'Départ sur la carte';

  @override
  String get navigatePickEnd => 'Arrivée sur la carte';

  @override
  String get navigateAddVia => 'Via';

  @override
  String get navigateNeedStartEnd => 'Fixe départ et arrivée';

  @override
  String get navigateComputeNeedBoth =>
      'Calculer l\'itinéraire (départ et arrivée requis)';

  @override
  String get navigateBackToExplore => 'Retour à Explorer';

  @override
  String get mineSheetHint => 'Tes traces, imports et parcours enregistrés';

  @override
  String get mineEmptyCtaNavigate => 'Itinéraire de A à B';

  @override
  String get gpxImportAction => 'Importer un GPX';

  @override
  String get exploreOpenNavigate => 'Naviguer A→B';

  @override
  String get sheetDragHandleMine => 'Tirer la barre Mes parcours';

  @override
  String get sheetDragHandleNavigate => 'Tirer la barre Navigation';

  @override
  String get browseMap => 'Carte';

  @override
  String get browseList => 'Liste';

  @override
  String get quickFilter1h => '1 h';

  @override
  String get sheetDragHandle => 'Tirer la barre Tours';

  @override
  String get sheetPeekHint => 'Tire vers le haut — tours et filtres';

  @override
  String get rideBarCollapseHint => 'Tire vers le bas pour replier';

  @override
  String get rideBarExpandHint => 'Ouvrir';

  @override
  String get rideBarStart => 'On y va';

  @override
  String get rideBarRoute => 'Parcours';

  @override
  String get rideBarPointToPoint => 'Parcours';

  @override
  String get emptyToursTitle => 'Aucun tour trouvé';

  @override
  String get emptyToursFiltersBody =>
      'Réinitialise les filtres — tu revois les tours autour.';

  @override
  String get emptyToursNearbyBody =>
      'Change le lieu ou la durée — ou réinitialise les filtres. Pas de remplissage A→B.';

  @override
  String get showOnMap => 'Sur la carte';

  @override
  String get tourDetails => 'Détails';

  @override
  String get moreFilters => 'Plus de filtres';

  @override
  String get moreActions => 'Autres actions';

  @override
  String get filterSurfaceAsphalt => 'Asphalte';

  @override
  String get filterSurfaceGravel => 'Gravier';

  @override
  String get filterSurfaceTrail => 'Trail';

  @override
  String get filterSurfaceMixed => 'Mixte';

  @override
  String get filterSurfaceAsphaltHint => 'Asphalte · piste cyclable · revêtu';

  @override
  String get filterSurfaceGravelHint => 'Gravier · forestier · compacté';

  @override
  String get filterSurfaceTrailHint => 'Naturel · singletrail · racines';

  @override
  String get filterSurfaceMixedHint => 'Ville · revêtement mixte';

  @override
  String get filterSurfaceAsphaltFull => 'Asphalte · revêtu';

  @override
  String get filterSurfaceGravelFull => 'Gravier · compacté';

  @override
  String get filterSurfaceTrailFull => 'Naturel · trail';

  @override
  String get filterSurfaceMixedFull => 'Ville · mixte';

  @override
  String get filterEffortEasy => 'Facile';

  @override
  String get filterEffortMid => 'Moyen';

  @override
  String get filterEffortHard => 'Exigeant';

  @override
  String get filterEffortEasyHint => 'S0 / cool / peu de technique';

  @override
  String get filterEffortMidHint => 'S1–S2 / sportif / mixte';

  @override
  String get filterEffortHardHint => 'S2+ / dur / technique';

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
  String get filterScaleMedium => 'Moyen';

  @override
  String get filterScaleHard => 'Exigeant';

  @override
  String get trailDiffEasy => 'Facile';

  @override
  String get trailDiffMedium => 'Moyen';

  @override
  String get trailDiffHard => 'Dur';

  @override
  String get trailDiffVeryHard => 'Très dur';

  @override
  String get trailDiffUnrated => 'Non classé';

  @override
  String get trailDiffOpen => 'ouvert';

  @override
  String get durationAny => 'peu importe';

  @override
  String get duration2to3h => '2–3 h';

  @override
  String get garageTitle => 'Garage';

  @override
  String get garageFabBike => 'Ajouter un vélo';

  @override
  String get garageEmptyTitle => 'Pas encore de vélo ici';

  @override
  String get garageEmptyMessage =>
      'Nom et type suffisent. Le catalogue est une recherche — les pièces série seulement si tu les prends.';

  @override
  String get garageAddBike => 'Ajouter un vélo';

  @override
  String get garageAddAnother => 'Autre vélo';

  @override
  String get garageStatBike => 'VÉLO';

  @override
  String get garageStatBikes => 'VÉLOS';

  @override
  String get garageStatKmTotal => 'KM TOTAL';

  @override
  String get garageQuickSwitch => 'Changement rapide';

  @override
  String get garageLastRides => 'Dernières sorties';

  @override
  String get garageNoRidesTitle => 'Pas encore de sorties';

  @override
  String get garageNoRidesMessage =>
      'Ta première sortie enregistrée apparaît ici.';

  @override
  String get garageActive => 'Actif';

  @override
  String garageActiveBike(String name) {
    return 'Vélo actif · $name';
  }

  @override
  String get garageEbikeBadge => 'E-bike';

  @override
  String get garageMaintOk => 'Tout va';

  @override
  String garageMaintDue(int count) {
    return '$count entretien(s) dû(s)';
  }

  @override
  String garageMaintOverdue(int count) {
    return '$count en retard';
  }

  @override
  String garagePartsCount(int count) {
    return '$count pièces';
  }

  @override
  String get garageParts => 'Pièces';

  @override
  String get garageMaintenance => 'Entretien';

  @override
  String get garageSetup => 'Setup';

  @override
  String get garageInstall => 'Ajouter une pièce';

  @override
  String get garageOtherBikes => 'Autres vélos';

  @override
  String get garageTechDetails => 'Détails techniques';

  @override
  String get garageTechHint =>
      'Débattement, cadre, bases du setup — pour amateurs';

  @override
  String get garageCtaMaintenance => 'Voir l\'entretien';

  @override
  String get garageCtaAddPart => 'Ajouter une pièce';

  @override
  String get garageCtaSetActive => 'Mettre en actif';

  @override
  String get garageCtaOpenSetup => 'Vers le setup';

  @override
  String get garageHours => 'Heures';

  @override
  String get garageTravel => 'Débattement';

  @override
  String get garageFrameSize => 'Taille de cadre';

  @override
  String get garageWheelSize => 'Roue';

  @override
  String get garageBrandModel => 'Modèle';

  @override
  String garageCompatFits(int count) {
    return 'Compatible $count';
  }

  @override
  String garageCompatCheck(int count) {
    return 'Vérifier $count';
  }

  @override
  String garageCompatNoFit(int count) {
    return 'Ne va pas $count';
  }

  @override
  String get garagePartsEmpty =>
      'Pas encore de pièces. Appuie sur « Ajouter une pièce » — ensuite on te rappelle l\'entretien et on montre si les pièces vont ensemble.';

  @override
  String get garageMaintEmpty => 'Tout au vert — aucun entretien dû.';

  @override
  String get garageSetupTabTitle => 'Ton setup';

  @override
  String get garageSetupTabHint =>
      'SAG = de combien la suspension s\'enfonce avec ton poids (souvent ~25–30 %).';

  @override
  String get garageYourParts => 'Tes pièces';

  @override
  String get garageMissingSlots => 'Pas encore inscrit (optionnel)';

  @override
  String get garageActiveBadge => 'Vélo actif';

  @override
  String get garageStatKm => 'KM';

  @override
  String get garageStatHours => 'H';

  @override
  String get garageStatMaint => 'ENTRETIEN';

  @override
  String get setupVersionsTitle => 'Versions et comparaison';

  @override
  String get setupVersionsHint =>
      'Chaque changement enregistre une nouvelle version. Tu peux revenir quand tu veux.';

  @override
  String get setupRiderWeightLabel => 'Poids rider (kg) pour les modèles';

  @override
  String get setupNewVersionCta => 'Nouvelle version';

  @override
  String get setupCompareCta => 'Tester deux variantes';

  @override
  String get setupCompareHint =>
      'Crée deux variantes à l\'aveugle (ex. détente). Après quelques sorties tu verras laquelle se sent mieux.';

  @override
  String get setupSavedVersions => 'Versions enregistrées';

  @override
  String get setupEmpty =>
      'Pas encore de version — pars d\'un modèle ou enregistre tes réglages.';

  @override
  String get setupActiveBadge => 'Active';

  @override
  String setupVersionMeta(int version) {
    return 'Version $version';
  }

  @override
  String get setupUseVersion => 'Utiliser';

  @override
  String setupForkReboundValue(String value) {
    return 'Détente $value';
  }

  @override
  String get setupSourceTemplate => 'Modèle';

  @override
  String get setupSourceBaseline => 'Base';

  @override
  String get setupSourceManual => 'Manuel';

  @override
  String get setupTemplatesTitle => 'Modèles pour démarrer';

  @override
  String get setupTemplatesHint =>
      'Point de départ — pas une reco personnelle.';

  @override
  String get setupApplyTemplate => 'Appliquer';

  @override
  String get setupNewVersionTitle => 'Nouvelle version de setup';

  @override
  String get setupNewVersionHint =>
      'Donne un nom que tu reconnaitras — ex. « Trail sec ».';

  @override
  String get setupVersionNameLabel => 'Nom';

  @override
  String get setupForkReboundLabel => 'Détente fourche (clics)';

  @override
  String get setupCancel => 'Annuler';

  @override
  String get setupSave => 'Enregistrer';

  @override
  String setupNewVersionDefaultName(int n) {
    return 'Version $n';
  }

  @override
  String get setupManualFallback => 'Manuel';

  @override
  String setupTemplateAppliedLabel(String label) {
    return '$label (modèle)';
  }

  @override
  String setupTemplateAppliedSnack(String disclaimer) {
    return 'Modèle appliqué — $disclaimer';
  }

  @override
  String get setupCompareVariantA => 'Variante test A';

  @override
  String get setupCompareVariantB => 'Variante test B';

  @override
  String setupCompareResultFromRides(int count, String summary) {
    return 'Variantes créées · lecture de $count sorties : $summary';
  }

  @override
  String setupCompareResultDemo(String summary) {
    return 'Variantes créées · encore peu de retours de sortie — exemple : $summary';
  }

  @override
  String get rideMap => 'Carte';

  @override
  String get rideData => 'Données';

  @override
  String get rideLiveData => 'Données live';

  @override
  String get rideMapReady => 'Carte prête — capteur optionnel après le départ';

  @override
  String get rideClearRoute => 'Retirer l\'itinéraire';

  @override
  String get postRideTitle => 'Activité';

  @override
  String get postRideFreeride => 'Freeride';

  @override
  String get postRideTrackMap => 'Trace roulée';

  @override
  String get postRideNoTrack =>
      'Pas de trace GPS — la carte n\'a rien à montrer.';

  @override
  String get postRideStatDistance => 'Distance';

  @override
  String get postRideStatDuration => 'Durée';

  @override
  String get postRideStatPace => 'Allure';

  @override
  String get postRideStatElevation => 'Dénivelé';

  @override
  String get postRideWeatherTitle => 'Météo';

  @override
  String get postRideWeatherStart => 'Départ';

  @override
  String get postRideWeatherEnd => 'Arrivée';

  @override
  String get postRideWeatherUnavailable => 'Météo indisponible';

  @override
  String get postRidePhotosTitle => 'Photos';

  @override
  String get postRidePhotosHint =>
      'Ajoute des photos à la sortie — stockées en local.';

  @override
  String get postRidePhotoCamera => 'Appareil photo';

  @override
  String get postRidePhotoGallery => 'Galerie';

  @override
  String get postRidePhotosShare => 'Partager';

  @override
  String get postRidePhotosShareText => 'Ma sortie FlowLine';

  @override
  String get postRidePhotosEmpty => 'Pas encore de photos à partager';

  @override
  String postRidePhotosMax(int count) {
    return 'Maximum $count photos';
  }

  @override
  String get postRideCommunityStub =>
      'Les photos restent locales. Les voix vivent sur le tour — pas dans un feed.';

  @override
  String get postRideOpenTour => 'Ouvrir le tour';

  @override
  String get postRideSaveAsTour => 'Enregistrer comme tour';

  @override
  String get postRideSaveAsTourDone => 'Enregistré dans Mes parcours';

  @override
  String get postRideSaveAsTourNeedTrack =>
      'Il faut une trace GPS pour enregistrer.';

  @override
  String get postRideSaveAsTourHint =>
      'Enregistre la trace comme parcours à toi — visible sous Tours.';

  @override
  String get myRoutesTitle => 'Mes parcours';

  @override
  String get myRoutesEmpty =>
      'Pas encore de parcours — importe un GPX ou enregistre une sortie.';

  @override
  String get myRoutesSourceImport => 'Import';

  @override
  String get myRoutesSourceRecorded => 'Enregistré';

  @override
  String get myRoutesSourceEngine => 'Planifié';

  @override
  String get myRoutesShowOnMap => 'Les miens sur la carte';

  @override
  String get myRoutesHideOnMap => 'Masquer les miens';

  @override
  String get myRouteNotesTitle => 'Note privée';

  @override
  String get myRouteNotesHint =>
      'Rien que pour toi. Les voix publiques seulement après partage, sous Voix.';

  @override
  String get myRouteNotesEmpty => 'Pas encore de note.';

  @override
  String get myRouteNotesPlaceholder => 'Rien que pour toi — pas une voix.';

  @override
  String get myRouteNotesAdd => 'Enregistrer';

  @override
  String get myRouteDetailPhotos => 'Photos';

  @override
  String get myRouteOpenDetail => 'Détails';

  @override
  String collectionRouteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itinéraires · appuie pour ouvrir',
      one: '1 itinéraire · appuie pour ouvrir',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get add => 'Ajouter';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get account => 'Compte';

  @override
  String get register => 'S\'inscrire';

  @override
  String get edit => 'Modifier';

  @override
  String get share => 'Partager';

  @override
  String get done => 'Fait';

  @override
  String get authSignedInSyncing => 'Connecté — sync en cours…';

  @override
  String authSignedInSyncFailed(String error) {
    return 'Connecté. Sync : $error';
  }

  @override
  String get authCloudUnavailable =>
      'Le cloud-sync n\'est pas dispo pour l\'instant.';

  @override
  String get authEmailPasswordRequired =>
      'E-mail et mot de passe (min. 8 caractères) requis.';

  @override
  String get authAccountCreatedConfirm =>
      'Compte créé — confirme l\'e-mail si besoin, puis connecte-toi.';

  @override
  String get authSupabaseMissing => 'Supabase n\'est pas configuré.';

  @override
  String get authBrowserOpened =>
      'Navigateur ouvert — après le login tu reviens tout seul.';

  @override
  String get authDeleteTitle => 'Supprimer le compte ?';

  @override
  String get authDeleteBody =>
      'Le compte distant et les données locales de l\'app seront supprimés. Exporte d\'abord GPX/JSON sous Données & confidentialité.';

  @override
  String get authRemoteDeleted => 'Compte distant supprimé.';

  @override
  String get authRemoteUnavailable =>
      'Suppression distante indisponible — seules les données locales ont été retirées.';

  @override
  String authRemoteFailed(int code) {
    return 'Suppression distante échouée ($code) — local quand même supprimé.';
  }

  @override
  String get authRemoteUnreachable =>
      'Serveur injoignable — seules les données locales ont été retirées.';

  @override
  String get authLocalDeleted =>
      'Données locales supprimées. Export éventuellement sous Confidentialité.';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEmailHint => 'Adresse e-mail';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get authNewHere => 'Nouveau ici ? S\'inscrire';

  @override
  String get authWithGoogle => 'Avec Google';

  @override
  String get authWithApple => 'Avec Apple';

  @override
  String get authPrivacy => 'Données & confidentialité';

  @override
  String get authOpenAssistant => 'Ouvrir l\'assistant';

  @override
  String get authDeleteAccount => 'Supprimer le compte';

  @override
  String get authSyncNow => 'Synchroniser maintenant';

  @override
  String get authSyncing => 'Sync en cours…';

  @override
  String get authSyncOk => 'Sync OK';

  @override
  String authSyncActive(String api) {
    return 'Sync avec $api est actif.';
  }

  @override
  String get authCreating => 'Création…';

  @override
  String get authSigningIn => 'Connexion…';

  @override
  String get billingTitle => 'FlowLine Pro';

  @override
  String get billingYouHavePro => 'Tu as Pro.';

  @override
  String get billingFreeToPro => 'Free → Pro';

  @override
  String get billingMoreBikes =>
      'Plus de vélos, avantages sync et régions hors ligne.';

  @override
  String get billingAlreadyPro =>
      'Pro est déjà actif — pas besoin de racheter.';

  @override
  String get billingForceProDebug =>
      'Debug : Force-Pro. Stripe/Play restent masqués.';

  @override
  String get billingStripeMonth => 'Stripe — mensuel';

  @override
  String get billingStripeYear => 'Stripe — annuel';

  @override
  String get billingPlayMonth => 'Google Play — mensuel';

  @override
  String get billingPlayRestore => 'Restaurer les achats Play';

  @override
  String get billingPlayHint =>
      'Note : sans GOOGLE_PLAY_SERVICE_ACCOUNT_JSON le serveur ne vérifie pas les achats auprès de Google.';

  @override
  String get billingSyncStatus => 'Synchroniser le statut d\'abo';

  @override
  String get billingSyncAfterPurchase => 'Synchroniser après l\'achat';

  @override
  String get billingPleaseSignIn => 'Connecte-toi d\'abord.';

  @override
  String get billingNoCheckoutUrl => 'Pas d\'URL checkout';

  @override
  String get billingBrowserFailed => 'Impossible d\'ouvrir le navigateur';

  @override
  String get billingCheckoutOpened =>
      'Checkout ouvert — ensuite « Sync after purchase ».';

  @override
  String get billingPlayOnlyAndroid => 'Play Billing seulement sur Android.';

  @override
  String get billingPlayStarted => 'Achat Play lancé…';

  @override
  String get billingVerifying => 'Vérification de l\'achat…';

  @override
  String get billingProTrusted =>
      'Pro activé (trusted-token MVP — sans Google Play Service Account). Sync OK.';

  @override
  String get billingProActive => 'Pro actif. Sync en cours.';

  @override
  String get billingRestoring => 'Restauration des achats…';

  @override
  String get billingRestoreStarted =>
      'Restore lancé — les abos valides seront vérifiés.';

  @override
  String billingSyncOkTier(String tier) {
    return 'Sync OK — tarif : $tier';
  }

  @override
  String billingPlayError(String error) {
    return 'Play : $error';
  }

  @override
  String billingSyncError(String error) {
    return 'Sync : $error';
  }

  @override
  String billingRestoreError(String error) {
    return 'Restore : $error';
  }

  @override
  String get chatAssistant => 'Assistant';

  @override
  String get chatWelcome =>
      'Demande-moi ce qui est dû — ou setup, itinéraires et pièces.';

  @override
  String get chatEmptyTitle => 'Demande-moi';

  @override
  String get chatEmptyMessage =>
      'Ce qui est dû, setup, itinéraires ou pièces — prends une suggestion en haut ou tape direct.';

  @override
  String get chatLockedRiding => 'Le chat est bloqué pendant la sortie.';

  @override
  String get chatHint => 'Message…';

  @override
  String get chatHintLocked => 'Bloqué pendant la sortie';

  @override
  String get chatAsk => 'Demander';

  @override
  String get chatSnooze7 => 'Silence 7 jours';

  @override
  String get chatNoAnswer => 'Pas de réponse.';

  @override
  String chatNetworkError(String error) {
    return 'Erreur réseau : $error';
  }

  @override
  String chatErrorStatus(int code) {
    return 'Erreur $code';
  }

  @override
  String get chatLimitReached => 'Limite atteinte.';

  @override
  String chatQuota(String used, String limit, String remaining) {
    return 'Quota : $used / $limit · encore $remaining';
  }

  @override
  String get chatToolDev => 'Outil (développeur)';

  @override
  String get chatToolAuto => 'Auto';

  @override
  String get chatPromptWatch => 'Qu\'est-ce qui est dû ?';

  @override
  String get chatPromptWatchQuery => 'Qu\'est-ce qui est dû ?';

  @override
  String get chatPromptGarage => 'Garage';

  @override
  String get chatPromptGarageQuery => 'Qu\'est-ce qu\'il y a dans mon garage ?';

  @override
  String get chatPromptRange => 'Autonomie';

  @override
  String get chatPromptRangeQuery =>
      'Quelle autonomie avec la batterie actuelle ?';

  @override
  String get chatPromptSetups => 'Setups';

  @override
  String get chatPromptSetupsQuery =>
      'Quels setups j\'ai eus et qu\'est-ce qui a changé ?';

  @override
  String get chatPromptRides => 'Sorties';

  @override
  String get chatPromptRidesQuery => 'Résumé de mes dernières sorties';

  @override
  String get chatPromptRoutes => 'Itinéraires';

  @override
  String get chatPromptRoutesQuery => 'Quels itinéraires me collent ?';

  @override
  String get chatPromptShop => 'Magasin';

  @override
  String get chatPromptShopQuery => 'Bientôt besoin de pièces d\'usure ?';

  @override
  String get chatToolWatch => 'Ce qui est dû';

  @override
  String get chatToolGarage => 'Atelier';

  @override
  String get chatToolCompat => 'Compatibilité';

  @override
  String get chatToolRange => 'Autonomie';

  @override
  String get chatToolSetupHistory => 'Historique setup';

  @override
  String get chatToolRides => 'Sorties';

  @override
  String get chatToolRoutes => 'Itinéraires';

  @override
  String get chatToolShop => 'Magasin';

  @override
  String get chatSubtitleDue => 'Ce qui est dû, setup, itinéraires, pièces';

  @override
  String coachHintsTooltip(int count) {
    return '$count conseils';
  }

  @override
  String get privacyTitle => 'Données & confidentialité';

  @override
  String get privacyConsents => 'Consentements';

  @override
  String get privacyHud => 'HUD';

  @override
  String get privacyZones => 'Zones privacy';

  @override
  String get privacyZoneAdd => 'Zone';

  @override
  String get privacyNoZones =>
      'Aucune zone — l\'entourage départ/arrivée peut être coupé.';

  @override
  String privacyZoneRadius(String label) {
    return 'Rayon $label';
  }

  @override
  String get privacyZoneDelete => 'Supprimer la zone';

  @override
  String get privacyFamilyHint =>
      'Famille / autres riders : sous Profil → Garage famille, ajoute des riders avec leur propre poids.';

  @override
  String get privacyExportTitle => 'Export (art. 20)';

  @override
  String get privacyExportGpx => 'Dernière sortie en GPX';

  @override
  String get privacyExportFit => 'Dernière sortie en FIT';

  @override
  String get privacyExportJson => 'Export JSON complet';

  @override
  String get privacyExportStravaStub => 'Payload Strava (local, développeur)';

  @override
  String get privacyStravaConnect => 'Connecter Strava';

  @override
  String get privacyStravaUpload => 'Dernière sortie vers Strava';

  @override
  String get privacyStravaLiveHint =>
      'L\'upload live utilise les tokens OAuth stockés (serveur).';

  @override
  String get privacyStravaOauthHint =>
      'OAuth ouvre le navigateur ; après l\'autorisation, continue dans l\'app.';

  @override
  String get privacyStravaMissing =>
      'Strava n\'est pas configuré. GPX, FIT et JSON restent les chemins d\'export.';

  @override
  String get privacyStravaConnected => 'Strava connecté';

  @override
  String get privacyStravaCallback => 'Callback Strava reçu';

  @override
  String privacyStravaStatus(String status) {
    return 'Strava : $status';
  }

  @override
  String get privacyStravaUnreachable =>
      'Statut Strava injoignable — l\'export stub reste local';

  @override
  String get privacyStravaUrlMissing =>
      'URL d\'autorisation Strava manquante — connecte-toi et réessaie.';

  @override
  String get privacyStravaBrowser =>
      'Strava dans le navigateur — reviens à l\'app après l\'autorisation, le statut se met à jour.';

  @override
  String get privacyNoRideUpload => 'Aucune sortie à uploader';

  @override
  String privacyChunksUploaded(int n, int left) {
    return '$n chunk(s) uploadé(s), $left en attente';
  }

  @override
  String privacyChunksBlocked(int left) {
    return 'Pas d\'upload (login/réseau ?) — $left en attente';
  }

  @override
  String get privacyChunksNone => 'Aucun chunk en attente';

  @override
  String privacyHeatmapCells(int n) {
    return 'Heatmap : $n cellules contribuées (visible seulement à k≥5).';
  }

  @override
  String get privacyHeatmapNone =>
      'Heatmap : aucune contribution (login/consentement/trace à vérifier).';

  @override
  String get privacyUploadNow => 'Uploader maintenant';

  @override
  String privacyChunksPending(int count) {
    return 'Chunks de données brutes : $count en attente';
  }

  @override
  String privacyChunksPendingConsentOff(int count) {
    return 'Chunks de données brutes : $count en attente (consentement off)';
  }

  @override
  String privacySharedGpx(String path) {
    return 'GPX partagé · $path';
  }

  @override
  String privacySharedFit(String path) {
    return 'FIT partagé · $path';
  }

  @override
  String privacySharedStravaStub(String path) {
    return 'Stub Strava partagé · $path';
  }

  @override
  String get privacyExportSubject => 'Export FlowLine';

  @override
  String get privacyNoRideExporting => 'Aucune sortie à exporter.';

  @override
  String privacySharedJson(String path) {
    return 'JSON partagé · $path';
  }

  @override
  String get privacyNoRideExport => 'Aucune sortie à exporter.';

  @override
  String get consentRawTitle => 'Upload de données brutes';

  @override
  String get consentRawBody =>
      'Données brutes des capteurs seulement en Wi-Fi et si tu acceptes. Révoquable à tout moment.';

  @override
  String get consentHeatmapTitle => 'Heatmap (tes sorties, anonyme)';

  @override
  String get consentHeatmapBody =>
      'En local : tes sorties. Avec un compte : cellules anonymisées sans horodatage. La carte de fréquentation n\'apparaît que quand assez de riders sont passés dans une cellule (k≥5).';

  @override
  String get consentRecoTitle => 'Recommandations produits';

  @override
  String get consentRecoBody =>
      'Seulement quand c\'est pertinent, avec un point de donnée traçable. Pas de marketing de tracking.';

  @override
  String get consentAnalyticsTitle => 'Analytics';

  @override
  String get consentAnalyticsBody =>
      'Métriques produit sans données de santé ni capteurs bruts.';

  @override
  String get consentHealthTitle => 'Données de santé';

  @override
  String get consentHealthBody =>
      'Préparation — Health Connect n\'est pas encore branché. Ce consentement enregistre seulement ta préférence pour plus tard.';

  @override
  String get privacyZoneTapHint => 'Tape la carte pour placer la zone.';

  @override
  String get privacyZoneRadiusHint =>
      'Le rayon s\'applique à l\'export et à la heatmap.';

  @override
  String get privacyZoneLabel => 'Label';

  @override
  String get privacyZoneRadiusWord => 'Rayon';

  @override
  String get privacyZoneApplyCoords => 'Appliquer les coordonnées';

  @override
  String get privacyZoneCoords => 'Coordonnées';

  @override
  String get privacyZoneCoordsHint =>
      'Seulement si tu veux poser le point en chiffres';

  @override
  String get profilePictureSet => 'Photo de profil définie';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get profileLocalOnly => 'Local seulement — connecte-toi pour le sync';

  @override
  String get profileSyncCloudKept => 'Sync : cloud conservé';

  @override
  String get profileSyncDeviceUploaded => 'Sync : appareil uploadé';

  @override
  String get profileSyncCurrent => 'Sync : à jour';

  @override
  String get profileSyncConflictTitle => 'Conflit de sync';

  @override
  String profileSyncConflictBody(String when) {
    return 'Le cloud et cet appareil diffèrent.\nCloud : $when\n\nQuelle version doit valoir ?';
  }

  @override
  String get profileKeepCloud => 'Garder le cloud';

  @override
  String get profileForceDevice => 'Forcer l\'appareil';

  @override
  String get profileConflictCloud => 'Conflit : cloud conservé';

  @override
  String get profileConflictDevice => 'Conflit : appareil forcé';

  @override
  String get profileSyncCancelled => 'Sync annulé';

  @override
  String get profileSignInForBilling => 'Connecte-toi pour gérer l\'abo';

  @override
  String get profileNoStripeSub =>
      'Pas encore d\'abo Stripe — passe d\'abord à Pro.';

  @override
  String profilePortalError(int code) {
    return 'Portail : $code';
  }

  @override
  String get profileNoPortalUrl => 'Pas d\'URL portail';

  @override
  String get profileFamilyRiderTitle => 'Rider famille';

  @override
  String get profileName => 'Nom';

  @override
  String get profileWeightKg => 'Poids kg';

  @override
  String get profileRiderAdded => 'Rider ajouté';

  @override
  String get profileRiderFallback => 'Rider';

  @override
  String profileActiveBike(String name, String category) {
    return 'Actif : $name · $category';
  }

  @override
  String get profileDisciplines => 'Tes disciplines';

  @override
  String get profileDisciplinesHint =>
      'Préférences pour les tours. Le routing suit le vélo actif, pas seulement cette liste.';

  @override
  String get profileRiderCard => 'Profil rider';

  @override
  String get profilePublic => 'Public';

  @override
  String get profileAccountSync => 'Compte & sync';

  @override
  String get profileCloudBilling => 'Cloud-sync & abo';

  @override
  String get profileSignedIn => 'Connecté';

  @override
  String get profileFamilyGarage => 'Garage famille';

  @override
  String get profileFamilyHint =>
      'D\'autres riders avec leur propre poids — ex. partenaire ou enfant.';

  @override
  String get profileLegal => 'Mentions légales';

  @override
  String get profilePrivacyPolicy => 'Confidentialité';

  @override
  String get profileImprint => 'Mentions légales';

  @override
  String get profileWithdrawal => 'Rétractation';

  @override
  String get profileSetPrimary => 'Définir comme discipline principale';

  @override
  String profilePrimarySuffix(String label) {
    return '$label · principale';
  }

  @override
  String get profileNeedOneDiscipline =>
      'Garde au moins une discipline cochée.';

  @override
  String get profileLocalUntilSignIn => 'Local — sync après connexion';

  @override
  String get profileChangePhoto => 'Changer la photo';

  @override
  String get profileActivityLabel => 'Activité — dernières sorties à la maison';

  @override
  String get profileBikeOne => 'Vélo';

  @override
  String get profileBikes => 'Vélos';

  @override
  String get profileRideOne => 'Sortie';

  @override
  String get profileRides => 'Sorties';

  @override
  String get profileKmTotal => 'km au total';

  @override
  String profileKmElevation(int hm) {
    return 'km · $hm hm';
  }

  @override
  String get profileProActive => 'FlowLine Pro actif';

  @override
  String get profileManage => 'Gérer';

  @override
  String get profileProPerks =>
      'Cartes hors ligne, vélos illimités, analyse de suspension et bracketing.';

  @override
  String get profileUpgradePro => 'Passer à Pro';

  @override
  String get profileDisplayName => 'Nom affiché';

  @override
  String get profileRiderWeight => 'Poids rider (kg)';

  @override
  String get profileRideStyle => 'Style de ride';

  @override
  String get profileSkillBeginner => 'Débutant';

  @override
  String get profileSkillBasics => 'Bases';

  @override
  String get profileSkillAdvanced => 'Confirmé';

  @override
  String get profileSkillExperienced => 'Expérimenté';

  @override
  String get profileSkillPro => 'Pro';

  @override
  String get profileSubGarage => 'Garage';

  @override
  String get profileSubWeight => 'Poids rider';

  @override
  String profileSubSkill(int skill) {
    return 'Niveau ($skill / 5)';
  }

  @override
  String get profileStyleEfficientPace => 'Efficace / allure';

  @override
  String get profileStyleSteady => 'Régulier';

  @override
  String get profileStyleExploring => 'Exploration';

  @override
  String get profileStyleCommute => 'Quotidien / trajet';

  @override
  String get profileStyleTours => 'Tours';

  @override
  String get profileStyleRelaxed => 'Cool';

  @override
  String get profileStyleAggressive => 'Agressif';

  @override
  String get profileStyleFlow => 'Flow';

  @override
  String get profileStyleLines => 'Chercher les lignes';

  @override
  String get profileStyleEfficient => 'Efficace';

  @override
  String profileDisciplinesSaved(String list) {
    return 'Disciplines : $list';
  }

  @override
  String profileAlsoList(String list) {
    return 'aussi $list';
  }

  @override
  String get publicProfileTitle => 'Profil public';

  @override
  String get publicProfileHint =>
      'Opt-in. Handle sur les voix, pas de traces, pas d\'onglet.';

  @override
  String get publicProfileHandle => 'Handle';

  @override
  String get publicProfileBio => 'Bio';

  @override
  String get publicProfileRegion => 'Région';

  @override
  String get publicProfileShowRides => 'Afficher le nombre de sorties';

  @override
  String get publicProfileFoot =>
      'Pas de trace publique, pas de DM. Le handle reste local jusqu\'au sync.';

  @override
  String get hudMediaTitle => 'Médias dans le HUD';

  @override
  String get hudMediaProfileHint =>
      'Accès optionnel pour que le HUD affiche le titre en cours. Play/Pause marche souvent déjà sans.';

  @override
  String get hudMediaPrivacyHint =>
      'Réglage sous Profil. Accès optionnel à la session média pour le titre dans le HUD.';

  @override
  String get onboardHowYouRide => 'Comment tu roules ?';

  @override
  String get onboardYourWeight => 'Ton poids';

  @override
  String get onboardFirstRide => 'Première sortie';

  @override
  String get onboardWeightHint =>
      'Pour setup, SAG et autonomie — local seulement, changeable à tout moment. Utile même sans fourche (ex. city).';

  @override
  String get onboardGpsHint =>
      'Vraie trace GPS — pas de démo. Vélo optionnel. MTB, gravel, route ou city : pareil.';

  @override
  String get onboardGpsStatus => 'Position pour la trace GPS…';

  @override
  String get onboardServicesOff =>
      'Active les services de localisation, puis réessaie.';

  @override
  String get onboardDeniedForever =>
      'Autorise la position dans les réglages de l\'app.';

  @override
  String get onboardNeedGps => 'Autorise la position — sans GPS, pas de trace.';

  @override
  String onboardWeightLabel(int kg) {
    return 'Poids rider : $kg kg';
  }

  @override
  String onboardDiscipline(String label) {
    return 'Discipline : $label';
  }

  @override
  String get onboardSensorsHint =>
      'Position pour la trace GPS. Capteurs Bluetooth plus tard dans l\'atelier — pour tous les types de vélo.';

  @override
  String get onboardNextRide => 'Continuer vers la sortie';

  @override
  String get onboardParkBikeFirst => 'D\'abord garer un vélo';

  @override
  String get onboardLater => 'Configurer plus tard';

  @override
  String get offlineMapsTitle => 'Cartes hors ligne';

  @override
  String get offlineMapsHint =>
      'Télécharge le graphe de routing et les tuiles pour la région. Hors réseau : carte chargée + routing graphe dans la bounding box. Les tuiles Valhalla ne sont pas encore dans les packs.';

  @override
  String get offlineRegionActive => 'Région active';

  @override
  String get offlineNoRegion => 'Aucune région active';

  @override
  String get offlineReadyBoth => 'Routing + tuiles prêts.';

  @override
  String get offlineReadyRouting =>
      'Routing prêt — carte pas encore hors ligne.';

  @override
  String get offlineLoadBelow => 'Charge un pack construit plus bas.';

  @override
  String get offlineRegions => 'Régions';

  @override
  String get offlineSearchRegion => 'Chercher une région';

  @override
  String get offlineNoneFound => 'Aucune région trouvée';

  @override
  String get offlineNoPacks =>
      'Aucun pack téléchargeable. Stubs en bas — pas de graphe démo sous un autre nom.';

  @override
  String offlineNotBuilt(int count) {
    return 'Pas encore construit ($count)';
  }

  @override
  String get offlineStubsHint => 'Stubs catalogue — téléchargement désactivé';

  @override
  String get offlineRemoveRegion => 'Retirer la région';

  @override
  String get offlineStyleTitle => 'Style de carte (optionnel)';

  @override
  String get offlineStyleHint =>
      'Défaut : DACH z11 style JSON. Change seulement pour ton propre style MapLibre.';

  @override
  String get offlineStyleUrl => 'URL style JSON';

  @override
  String get offlineSaveStyle => 'Enregistrer le style';

  @override
  String offlineRegionActiveSnack(String name) {
    return '$name actif';
  }

  @override
  String offlineActivateError(String error) {
    return 'Activer : $error';
  }

  @override
  String offlinePackError(String error) {
    return 'Pack région : $error';
  }

  @override
  String get offlineRemoved => 'Région retirée';

  @override
  String get offlineNoRemoteDach =>
      'Pas de packs distants — fallback DACH actif';

  @override
  String get offlineNoBuiltPacks => 'Aucun pack construit sur ce serveur';

  @override
  String get offlineDachCatalog => 'Hors ligne — régions DACH du catalogue app';

  @override
  String get offlineReadyMapRouting => 'Carte + routing prêts';

  @override
  String get offlineRoutingBg => 'Routing prêt, carte en cours en arrière-plan';

  @override
  String get offlineBasemapFail =>
      'Routing prêt — téléchargement basemap échoué, la carte a besoin du CDN';

  @override
  String get offlineTilesMissing =>
      'Routing prêt, tuiles manquantes (réseau/limite)';

  @override
  String offlineDemoGraph(String name) {
    return 'Graphe démo Forêt-Noire actif — pas la carte $name';
  }

  @override
  String get offlineStyleCleared =>
      'Override supprimé — style par défaut actif';

  @override
  String offlineStyleSaved(String url) {
    return 'Style enregistré. La carte va recharger : $url';
  }

  @override
  String get platzTogetherKicker => 'SORTIR ENSEMBLE';

  @override
  String get platzTogetherTitle => 'Sortir ensemble';

  @override
  String get platzTogetherHint =>
      'Inviter partage le lien. Le filtre Toutes, Privé, Public s\'applique aussi aux groupes.';

  @override
  String get platzTogetherListHint =>
      'Groupe devant le portail. Connecté : sur le serveur. Sinon seulement cet appareil — pas d\'utilisateur démo. Pins seulement dans le HUD après opt-in.';

  @override
  String get platzCreateGroup => 'Créer un groupe';

  @override
  String get platzJoinCode => 'Code';

  @override
  String get platzNoGroup =>
      'Pas encore de groupe. Seulement de vrais codes — rien de mis en scène.';

  @override
  String get platzHost => 'Host';

  @override
  String get platzGuest => 'Invité';

  @override
  String get platzYou => 'Toi';

  @override
  String get platzInvite => 'Inviter';

  @override
  String get platzDissolve => 'Dissoudre';

  @override
  String get platzLeave => 'Quitter';

  @override
  String get platzCopyLink => 'Copier le lien';

  @override
  String get platzInviteShares => 'Inviter partage le lien du groupe';

  @override
  String get platzInviteSharesProfile => ' et ton profil Platz';

  @override
  String platzMembersCount(int count) {
    return '$count avec';
  }

  @override
  String get platzOnServer => 'sur le serveur';

  @override
  String get platzOnDevice => 'seulement sur cet appareil';

  @override
  String platzCollectionDefaultName(int day, int month) {
    return 'Collection $day.$month.';
  }

  @override
  String get platzPinsOff => 'Pins off';

  @override
  String get platzPinsHudOnly => 'Pins seulement dans le HUD';

  @override
  String get platzCollectionsKicker => 'COLLECTIONS';

  @override
  String get platzNoCollection => 'Pas encore de collection — crée-en une ici.';

  @override
  String platzCollectionTours(int count) {
    return '$count tours';
  }

  @override
  String get platzCreateCollection => 'Créer une collection';

  @override
  String get platzJoinWithCode => 'Rejoindre avec un code';

  @override
  String get platzJoinCodeField => 'Join-code';

  @override
  String get platzJoin => 'Rejoindre';

  @override
  String get platzNeedSharedTour =>
      'Groupe seulement sur un tour partagé ou catalogue. Le GPX privé reste privé.';

  @override
  String get platzNoSharedTours =>
      'Aucun tour partagé ou catalogue. Le GPX privé reste dehors.';

  @override
  String platzGroupCreated(String code) {
    return 'Groupe $code — inviter partage le lien, pas d\'explore.';
  }

  @override
  String platzGroupCreatedNote(String code, String note) {
    return 'Groupe $code — $note';
  }

  @override
  String platzShareSubject(String title) {
    return 'Sortir ensemble : $title';
  }

  @override
  String get platzLinkCopied =>
      'Lien copié. Qui l\'a peut rejoindre tant que le groupe est ouvert.';

  @override
  String get platzWindowClosed => 'Fenêtre fermée';

  @override
  String platzWindowHours(int hours) {
    return 'Fenêtre $hours h';
  }

  @override
  String platzWindowMinutes(int minutes) {
    return 'Fenêtre $minutes min';
  }

  @override
  String get platzWindowOpen => 'Fenêtre ouverte';

  @override
  String platzCollectionShare(String name, String routes) {
    return 'Collection « $name » : $routes';
  }

  @override
  String get rerouteTitle => 'Hors de l\'itinéraire.';

  @override
  String get rerouteHint => 'Reste calme — c\'est toi qui décides.';

  @override
  String get rerouteRejoin => 'Retour à l\'itinéraire';

  @override
  String get rerouteStay => 'Rester';

  @override
  String get rerouteSkip => 'Sauter ce tronçon';

  @override
  String get bleOff => 'Bluetooth est off — allume-le.';

  @override
  String get bleDenied => 'Permission Bluetooth manquante.';

  @override
  String get bleUnavailable =>
      'Bluetooth LE n\'est pas dispo sur cet appareil.';

  @override
  String get bleScanFailed => 'Recherche échouée';

  @override
  String get bleConnecting => 'Connexion…';

  @override
  String get blePairFailed => 'Appairage échoué';

  @override
  String get bleNothingFound => 'Rien trouvé';

  @override
  String get bleScanAgain => 'Chercher encore';

  @override
  String get bleHowTo => 'Comment tu connectes';

  @override
  String get watchPairTitle => 'Appairer la montre';

  @override
  String get watchPairHint =>
      'Pouls seulement avec 0x180D. La batterie de la montre n\'est pas celle du vélo.';

  @override
  String get watchScanning => 'Recherche montre et ceinture cardio…';

  @override
  String get watchEmptyHint =>
      'Broadcast on, téléphone près. Apple Watch n\'envoie pas de pouls standard.';

  @override
  String get watchNoHr => 'Pas de Heart Rate 0x180D — vérifie le broadcast.';

  @override
  String get watchNoDeviceId => 'Connecté, mais sans ID d\'appareil';

  @override
  String get bleBikeTitle => 'Appairer le vélo';

  @override
  String get bleBikeHint =>
      'Batterie et assist seulement avec un vrai GATT — rien inventer.';

  @override
  String get bleRememberAnyway => 'Retenir quand même';

  @override
  String get bleScanningDrive => 'Recherche moteur et capteurs…';

  @override
  String get bleEmptyEbike =>
      'Réveille l\'écran, ferme Flow ou E-TUBE, garde le téléphone près.';

  @override
  String get bleEmptySensor =>
      'Pose le capteur près et active-le sur le vélo (aimant/pédalier).';

  @override
  String get bleConnectFailed => 'Connexion échouée';

  @override
  String get dieBoxReady => 'Prêt';

  @override
  String get dieBoxAlmost => 'Presque prêt';

  @override
  String get dieBoxUnknown => 'Tout juste arrivé';

  @override
  String get dieBoxNothingDueMonday =>
      'Prêt pour lundi — éclairage et chaîne sont là.';

  @override
  String get dieBoxNothingDue => 'Prêt — rien n’attend.';

  @override
  String get dieBoxCscHint =>
      'Couple le capteur du vélo ici. La montre reste sur toi en sortie.';

  @override
  String get dieBoxEmptyHint =>
      'Rien d’inscrit. Nom et type suffisent — des pièces seulement si elles sont vraiment sur le vélo.';

  @override
  String get dieBoxAddSomething => 'Inscrire quelque chose';

  @override
  String get dieBoxAddMore => 'Inscrire autre chose';

  @override
  String get dieBoxBatteryHint =>
      'La charge apparaît dès qu’un capteur sur le vélo est couplé. Pas de chiffre avant.';

  @override
  String get dieBoxPressureTitle => 'Noter la pression';

  @override
  String get dieBoxPressureHint => 'Lis avant et arrière à la valve.';

  @override
  String get dieBoxPressureFront => 'Avant';

  @override
  String get dieBoxPressureRear => 'Arrière';

  @override
  String get dieBoxPressureLogged => 'Pression notée';

  @override
  String get dieBoxSagTitle => 'Noter la suspension';

  @override
  String get dieBoxSagHint =>
      'Pourcent sur fourche et amortisseur. Le SAG, c’est l’enfoncement avec toi dessus.';

  @override
  String get dieBoxSagFork => 'SAG fourche %';

  @override
  String get dieBoxSagShock => 'SAG amortisseur %';

  @override
  String get dieBoxSagLogged => 'SAG noté';

  @override
  String get dieBoxTravelTitle => 'Inscrire le débattement';

  @override
  String get dieBoxTravelHint =>
      'Seulement le débattement inscrit sur le vélo.';

  @override
  String get dieBoxTravelFront => 'Avant mm';

  @override
  String get dieBoxTravelRear => 'Arrière mm';

  @override
  String get dieBoxTravelSave => 'Inscrire';

  @override
  String get dieBoxChainLogged => 'Chaîne mesurée';

  @override
  String get dieBoxChainNotes => 'Mesuré au calibre';

  @override
  String get dieBoxSetActiveTitle => 'Mettre ce vélo devant';

  @override
  String get dieBoxSetActiveHint =>
      'Un vélo tient dans le box — changer le met devant.';

  @override
  String get dieBoxSetActiveCta => 'Mettre en actif';

  @override
  String get dieBoxLightsTitle => 'Inscrire l’éclairage';

  @override
  String get dieBoxLightsHint =>
      'Seulement si l’éclairage est vraiment sur le vélo.';

  @override
  String get dieBoxLightsCta => 'Inscrire l\'éclairage';

  @override
  String get dieBoxLockTitle => 'Inscrire l’antivol';

  @override
  String get dieBoxLockHint => 'Seulement s’il y a un antivol sur le vélo.';

  @override
  String get dieBoxLockCta => 'Inscrire l\'antivol';

  @override
  String get dieBoxRackTitle => 'Inscrire le porte-bagages';

  @override
  String get dieBoxRackHint => 'Seulement si le vélo en a un.';

  @override
  String get dieBoxRackCta => 'Inscrire le porte-bagages';

  @override
  String get dieBoxBagsTitle => 'Inscrire les sacoches';

  @override
  String get dieBoxBagsHint => 'Seulement si des sacoches sont sur le vélo.';

  @override
  String get dieBoxBagsCta => 'Inscrire les sacoches';

  @override
  String get dieBoxPressureMissingTitle => 'Noter la pression';

  @override
  String get dieBoxPressureMissingHint => 'Lis avant et arrière à la valve.';

  @override
  String get dieBoxPressureMissingCta => 'Noter la pression';

  @override
  String get dieBoxTirePressureTitle => 'Noter la pression des pneus';

  @override
  String get dieBoxTirePressureHint => 'Lis avant et arrière à la valve.';

  @override
  String get dieBoxTravelMissingTitle => 'Inscrire le débattement';

  @override
  String get dieBoxTravelMissingHint =>
      'Seulement le débattement inscrit sur le vélo.';

  @override
  String get dieBoxTravelMissingCta => 'Inscrire le débattement';

  @override
  String get dieBoxSagMissingTitle => 'Noter la suspension';

  @override
  String get dieBoxSagMissingHint =>
      'Un chiffre sur fourche et amortisseur, lu sur le vélo.';

  @override
  String get dieBoxSagMissingCta => 'Noter la suspension';

  @override
  String get dieBoxChainTitle => 'Noter la chaîne';

  @override
  String get dieBoxChainHint => 'Mesure au calibre, puis note ici.';

  @override
  String get dieBoxChainCta => 'Chaîne mesurée';

  @override
  String get dieBoxBrakesTitle => 'Inscrire les freins';

  @override
  String get dieBoxBrakesHint =>
      'Seulement si les plaquettes sont sur le vélo.';

  @override
  String get dieBoxBrakesCta => 'Inscrire le frein';

  @override
  String get dieBoxChainDueTitle => 'Contrôler la chaîne avec la jauge';

  @override
  String get dieBoxChainDueHint => 'Regarde, puis mesure au calibre.';

  @override
  String get dieBoxParkTrailTitle => 'Park ou trail';

  @override
  String get dieBoxParkTrailHint =>
      'Les deux setups sont là — change si tu veux.';

  @override
  String get dieBoxParkTrailCta => 'Changer';

  @override
  String get dieBoxChipLight => 'Éclairage';

  @override
  String get dieBoxChipLock => 'Antivol';

  @override
  String get dieBoxChipRack => 'Porte-bagages';

  @override
  String get dieBoxChipBags => 'Sacoches';

  @override
  String get dieBoxChipTires => 'Pneus';

  @override
  String get dieBoxChipDropper => 'Télesco';

  @override
  String get dieBoxChipBrakes => 'Freins';

  @override
  String get dieBoxChipParkTrail => 'Park | Trail';

  @override
  String get dieBoxChipTravel => 'Débattement';

  @override
  String get dieBoxChipCsc => 'CSC';

  @override
  String get dieBoxChipBatteryHonest => 'Batterie honnête';

  @override
  String get dieBoxChipSag => 'SAG';

  @override
  String dieBoxSentenceEverydayReady(String name) {
    return '$name habite ici · prêt pour lundi';
  }

  @override
  String get dieBoxBitLightsChainOk => 'Éclairage et chaîne ok';

  @override
  String get dieBoxBitPressureUnknown => 'Pression non mesurée';

  @override
  String get dieBoxBitLightsMissing => 'Éclairage non inscrit';

  @override
  String dieBoxSentenceNotReady(String name) {
    return '$name habite ici';
  }

  @override
  String dieBoxSentenceBits(String name, String bits) {
    return '$name · $bits';
  }

  @override
  String get dieBoxWheelOpen => 'Roue ouverte';

  @override
  String get dieBoxBitPressureLogged => 'Pression notée';

  @override
  String get dieBoxBitPressureRough => 'Pression à la louche — à remesurer';

  @override
  String get dieBoxBitBagsYes => 'Sacoches là';

  @override
  String get dieBoxBitBagsNo => 'Sacoches non inscrites';

  @override
  String get dieBoxBitChainYes => 'Chaîne mesurée';

  @override
  String get dieBoxBitChainNo => 'Chaîne pas encore mesurée';

  @override
  String get dieBoxBitPressureToday => 'Pression encore ouverte aujourd\'hui';

  @override
  String get dieBoxSentencePark => 'Setup park';

  @override
  String get dieBoxSagLoggedShort => 'SAG noté';

  @override
  String get dieBoxSagMissingShort => 'SAG non mesuré';

  @override
  String dieBoxSentenceNoTravel(String name) {
    return '$name habite ici';
  }

  @override
  String get dieBoxDriveAssist => ' · e-assist';

  @override
  String dieBoxSentenceMtb(String name, String travel, String drive) {
    return '$name · $travel$drive';
  }

  @override
  String dieBoxSentenceFallback(String name) {
    return '$name habite ici';
  }

  @override
  String get close => 'Fermer';

  @override
  String get ok => 'OK';

  @override
  String get remove => 'Retirer';

  @override
  String get garageMoreOnBike => 'Plus sur le vélo';

  @override
  String get garageMoreOnBikeHint =>
      'Pièces, entretien, versions de setup — derrière la Box';

  @override
  String get garageDeleteBike => 'Supprimer le vélo';

  @override
  String get garageDeleteBikeTitle => 'Supprimer ce vélo ?';

  @override
  String get garageDeleteBikeBody =>
      'Les composants et setups de ce vélo disparaissent localement.';

  @override
  String get garageRemovePartTitle => 'Retirer la pièce ?';

  @override
  String garageRemovePartBody(String slot, String name) {
    return '$slot : $name sera retiré du garage.';
  }

  @override
  String get garageNotLogged => 'Pas encore noté';

  @override
  String get garageOptions => 'Options';

  @override
  String get garageFitTitle => 'Compatibilité';

  @override
  String garageFitStatus(String label) {
    return 'Statut : $label';
  }

  @override
  String garageFitSeverity(String label) {
    return 'Gravité : $label';
  }

  @override
  String get garageFitSeveritySafety => 'critique pour la sécurité';

  @override
  String get garageFitSeverityFunctional => 'fonctionnel';

  @override
  String get garageFitExplained => 'En clair';

  @override
  String garageFitCondition(String text) {
    return 'Condition : $text';
  }

  @override
  String garageFitHint(String text) {
    return 'Note : $text';
  }

  @override
  String get garageFitMissing => 'Infos encore manquantes';

  @override
  String garageFitSource(String url) {
    return 'Source : $url';
  }

  @override
  String garageGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String get garageVerdictFits => 'Ça va';

  @override
  String get garageVerdictCheck => 'À vérifier';

  @override
  String get garageVerdictNoFit => 'Ne va pas';

  @override
  String get garageVerdictUnclear => 'Incertain';

  @override
  String garageAllCount(int count) {
    return 'tous $count';
  }

  @override
  String get garageActiveStamp => 'ACTIF';

  @override
  String get garageFreeOneBikeTitle => 'Free : un vélo';

  @override
  String get garageFreeOneBikeBody =>
      'L\'offre Free prévoit un vélo. Tu peux quand même en créer d\'autres en local — les limites de sync s\'appliquent après connexion.';

  @override
  String get garageUnlockPro => 'Débloquer Pro';

  @override
  String get garageAddAnyway => 'Créer quand même';

  @override
  String get garageSlotFrame => 'Cadre';

  @override
  String get garageSlotFork => 'Fourche';

  @override
  String get garageSlotRearShock => 'Amortisseur';

  @override
  String get garageSlotHeadset => 'Jeu de direction';

  @override
  String get garageSlotStem => 'Potence';

  @override
  String get garageSlotHandlebar => 'Cintre';

  @override
  String get garageSlotGrips => 'Poignées';

  @override
  String get garageSlotSeatpost => 'Tige de selle';

  @override
  String get garageSlotSaddle => 'Selle';

  @override
  String get garageSlotFrontHub => 'Moyeu avant';

  @override
  String get garageSlotRearHub => 'Moyeu arrière';

  @override
  String get garageSlotFrontRim => 'Jante avant';

  @override
  String get garageSlotRearRim => 'Jante arrière';

  @override
  String get garageSlotTireFront => 'Pneu avant';

  @override
  String get garageSlotTireRear => 'Pneu arrière';

  @override
  String get garageSlotCassette => 'Cassette';

  @override
  String get garageSlotChain => 'Chaîne';

  @override
  String get garageSlotCrankset => 'Pédalier';

  @override
  String get garageSlotBottomBracket => 'Boîtier de pédalier';

  @override
  String get garageSlotFrontDerailleur => 'Dérailleur avant';

  @override
  String get garageSlotRearDerailleur => 'Dérailleur arrière';

  @override
  String get garageSlotShifter => 'Manette';

  @override
  String get garageSlotBrakeFront => 'Frein avant';

  @override
  String get garageSlotBrakeRear => 'Frein arrière';

  @override
  String get garageSlotRotorFront => 'Disque avant';

  @override
  String get garageSlotRotorRear => 'Disque arrière';

  @override
  String get garageSlotMotor => 'Moteur';

  @override
  String get garageSlotBattery => 'Batterie';

  @override
  String get garageSlotDisplay => 'Display';

  @override
  String get garageSlotLight => 'Éclairage';

  @override
  String get garageSlotLock => 'Antivol';

  @override
  String get garageSlotRack => 'Porte-bagages';

  @override
  String get garageSlotBags => 'Sacoches';

  @override
  String get garageSlotOther => 'Autre';

  @override
  String get garageGroupSuspension => 'Suspension';

  @override
  String get garageGroupWheels => 'Roues';

  @override
  String get garageGroupCockpit => 'Cockpit';

  @override
  String get garageGroupDrivetrain => 'Transmission';

  @override
  String get garageGroupBrakes => 'Freins';

  @override
  String get garageGroupPower => 'E-Bike';

  @override
  String get garageGroupOther => 'Autre';

  @override
  String get dieBoxZoneToday => 'Aujourd\'hui';

  @override
  String get dieBoxZoneOnBike => 'Sur le vélo';

  @override
  String get dieBoxZoneSensor => 'Capteur';

  @override
  String get garageCatalogOffline =>
      'Catalogue hors ligne — tu peux créer ton vélo sous « Mon vélo » ou « GPX ».';

  @override
  String get garageNoHit =>
      'Aucun résultat — utilise la liste ou cherche autrement.';

  @override
  String get garageSearchUnavailable =>
      'Recherche indisponible — utilise la liste.';

  @override
  String get garageFileUnreadable => 'Fichier illisible';

  @override
  String get garageGpxInvalid => 'Pas un track GPX valide (min. 2 points)';

  @override
  String get garageNeedMakeModel => 'Choisis marque et modèle';

  @override
  String garageCreateFailed(String error) {
    return 'Création ratée : $error';
  }

  @override
  String get garageOemSetup => 'Setup d\'origine';

  @override
  String get garageCatalogIdentity => 'Identité catalogue';

  @override
  String get garageImportBike => 'Vélo importé';

  @override
  String get garageImportNoGpx => 'Import sans GPX — pièces plus tard';

  @override
  String get garageBaseSetup => 'Setup de base';

  @override
  String get garageFreeExtraLocal =>
      'Free : vélo supplémentaire en local (multi-vélo est Pro).';

  @override
  String garageOemTakeover(int count) {
    return 'Reprendre les pièces d\'origine ($count)';
  }

  @override
  String get garageOemHint =>
      'Sinon identité seulement. Le catalogue reste une recherche.';

  @override
  String garageReachStack(String reach, String stack) {
    return 'Reach $reach mm · Stack $stack mm';
  }

  @override
  String get garageCatalogNotLoaded =>
      'Catalogue pas chargé — passe sur « Mon vélo » ou réessaie plus tard.';

  @override
  String get garageSearchBrandHint => 'Focus SAM, Canyon Grizl, Stevens …';

  @override
  String get garageSearchIntro =>
      'Cherche marque et modèle, prends une photo ou choisis dans la liste.';

  @override
  String get garageHideList => 'Masquer la liste';

  @override
  String get garagePickFromList => 'Choisir dans la liste';

  @override
  String get garageManufacturer => 'Fabricant';

  @override
  String get garageNickname => 'Surnom (optionnel)';

  @override
  String get garageNicknameHint => 'p. ex. trail';

  @override
  String get garageTravelFrontMm => 'Débattement avant (mm)';

  @override
  String get garageTravelRearMm => 'Débattement arrière (mm)';

  @override
  String get garageTravelOnlyIfPresent => 'Seulement s\'il est sur le vélo';

  @override
  String get garageOnBikeCheck =>
      'Sur le vélo — coche seulement si c\'est vraiment là';

  @override
  String get garageBagsOnBike => 'Sacoches sur le vélo';

  @override
  String get garageBrandOptional => 'Marque (optionnel)';

  @override
  String get garageModelOptional => 'Modèle (optionnel)';

  @override
  String get garagePickGpx => 'Choisir un fichier GPX';

  @override
  String get garageNameOptional => 'Nom (optionnel)';

  @override
  String get garageMyBike => 'Mon vélo';

  @override
  String get garageCatalog => 'Catalogue';

  @override
  String get garageImport => 'Importer';

  @override
  String get garageCreateBike => 'Créer le vélo';

  @override
  String garageGpxImported(String name, String km) {
    return 'GPX « $name » · $km km';
  }

  @override
  String get garageName => 'Nom';

  @override
  String get garageNameHint => 'p. ex. vélo du quotidien';

  @override
  String get garagePhoto => 'Photo';

  @override
  String get garageGallery => 'Galerie';

  @override
  String get garageSlotHeading => 'Slot';

  @override
  String get garageEditPart => 'Modifier la pièce';

  @override
  String get garageInstallPart => 'Installer la pièce';

  @override
  String get garageSearchParts => 'Chercher des pièces (API/cache)';

  @override
  String get garageSearchPartsHint => 'Marque / modèle — optionnel';

  @override
  String get garageSearchPartsHelper => 'Sans résultat : saisie manuelle';

  @override
  String get garageHits => 'Résultats';

  @override
  String get garageNoHitsManual =>
      'Aucun résultat — remplis à la main. Le cache peut être vide.';

  @override
  String garageCacheId(String id) {
    return 'ID cache : $id';
  }

  @override
  String garageCompatAttrs(String slot) {
    return 'Attributs de fit · $slot';
  }

  @override
  String get garageCompatAttrsHint =>
      'Source : fiche constructeur ou gravure sur la pièce. Laisse vide si inconnu — alors « données manquantes », pas de devinette.';

  @override
  String get garageExtraAttr => 'Attribut supplémentaire (avancé)';

  @override
  String get garageAttrKey => 'Clé d\'attribut';

  @override
  String get garageAttrValue => 'Valeur d\'attribut';

  @override
  String get garageCompatPlaceholder =>
      'Placeholders de fit posés (p. ex. 148×12 / Microspline) — pas une vérité catalogue. Vérifie les attributs.';

  @override
  String garageSagGuideTitle(String kg) {
    return 'Repères de suspension (cycliste $kg kg)';
  }

  @override
  String garageSagGuideFork(String psi, String min, String max, String sag) {
    return 'Fourche : $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String garageSagGuideShock(String psi, String min, String max, String sag) {
    return 'Amortisseur : $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String get garageSagGuideHint =>
      'Repère de départ — mesure sur le vélo, puis affine.';

  @override
  String get garageMeasureSag => 'Mesurer le SAG';

  @override
  String get garageShowMeasureSteps => 'Voir les étapes';

  @override
  String get garageOdometer => 'Kilométrage';

  @override
  String get garageOperatingHours => 'Heures';

  @override
  String garageOdoStand(String km) {
    return 'Relevé : $km km';
  }

  @override
  String garageHoursStand(String hours) {
    return 'Heures : $hours h';
  }

  @override
  String get garageAddKmNoGps => 'Ajouter des km sans track GPS';

  @override
  String get garageDistanceKm => 'Distance (km)';

  @override
  String get garageImportKm => 'Importer des km (sans ride GPS)';

  @override
  String get garageMaintLog => 'Journal d\'entretien';

  @override
  String get garageMaintLogEmpty =>
      'Pas encore d\'entrées — régler l\'odomètre écrit des logs.';

  @override
  String get garageBleScanning => 'Recherche d\'appareils …';

  @override
  String get garageBlePaired => 'Appareil couplé';

  @override
  String garageBlePairedNamed(String name) {
    return 'Couplé : $name';
  }

  @override
  String get garageBlePairFailed => 'Couplage raté';

  @override
  String get garageBleRemoved => 'Capteur retiré';

  @override
  String get garageBleDisconnected => 'Bluetooth pas connecté';

  @override
  String get garageBleHintEbike =>
      'Bosch, Shimano STEPS ou CSC. Allume le display.';

  @override
  String get garageBleHintSensor => 'Capteur sur le vélo, pas sur le cycliste.';

  @override
  String get discoverRefresh => 'Nouveau';

  @override
  String get discoverChangePlace => 'Changer de lieu';

  @override
  String get discoverSuggestDuration => 'Proposer une durée';

  @override
  String get discoverDemoCities => 'Villes démo';

  @override
  String discoverNearbyTitle(String profile) {
    return 'Près de toi · $profile';
  }

  @override
  String get discoverNearbyHintGps =>
      'Touche pour voir la trace · Sortir lance la navigation';

  @override
  String get discoverNearbyHintNoGps =>
      'Partage la position pour des tours d\'ici';

  @override
  String get discoverGrantLocation => 'Partager la position';

  @override
  String get discoverSuggestionsComputing => 'Calcul des propositions…';

  @override
  String get discoverNoSuggestions =>
      'Aucune proposition — pose un lieu, choisis un profil ou tape Nouveau.';

  @override
  String discoverAdaptSuggestion(String label) {
    return 'Ajuster la proposition : $label';
  }

  @override
  String get discoverTours => 'Tours';

  @override
  String discoverToursLoops(int count) {
    return 'Tours · $count boucles';
  }

  @override
  String discoverToursCount(int count) {
    return 'Tours · $count';
  }

  @override
  String get discoverNoGpsCurated =>
      'Sans GPS : tours choisis · position pour le proche';

  @override
  String get discoverGrantLocationNearby =>
      'Partage la position pour des tours près de toi';

  @override
  String discoverToursNearbyCount(int count) {
    return '$count tours à proximité';
  }

  @override
  String discoverCuratedLoops(int count) {
    return '$count boucles choisies';
  }

  @override
  String get discoverOfflineSuffix => ' · hors ligne';

  @override
  String get discoverHeatmapConsent =>
      'Heatmaps après consentement — ouvrir la vie privée';

  @override
  String get discoverRideToStartShort => 'Vers le départ';

  @override
  String get discoverLoopsNearby => 'Boucles près de toi';

  @override
  String get discoverNoLoop90 => 'Pas de boucle dans 90 km — régions suivantes';

  @override
  String get discoverRecommendedNoGps => 'Tours recommandés · aussi sans GPS';

  @override
  String discoverRecommended(int count) {
    return 'Recommandé ($count)';
  }

  @override
  String get discoverRecommendedHint =>
      'Pour tous les vélos · la trace se charge au départ';

  @override
  String discoverInRegion(int count) {
    return 'Dans la région ($count)';
  }

  @override
  String get discoverToursAround => 'Tours autour';

  @override
  String get discoverAfterLocation => 'Apparaît après la position';

  @override
  String get discoverNeedLocationTrails =>
      'Pose un lieu ou un départ pour le réseau de trails';

  @override
  String get discoverTrailLoading => 'Réseau de trails en cours…';

  @override
  String get discoverTrailEmpty => 'Pas de réseau OSM de trails à proximité';

  @override
  String discoverTrailCount(int count) {
    return 'Réseau $count · touche pour choisir';
  }

  @override
  String get discoverTrailOffline => 'Réseau de trails hors ligne';

  @override
  String get discoverOsmLivePath => 'Chemin OSM live';

  @override
  String get discoverOsmTags => 'Tags OpenStreetMap';

  @override
  String get discoverTapMapTrails => 'Toucher la carte choisit des trails.';

  @override
  String get discoverTrailApproachHint =>
      'Va jusqu\'à l\'entrée, puis enregistre l\'overlay ou pars.';

  @override
  String get discoverRideToTrailhead => 'Aller au départ';

  @override
  String get discoverPutOnRoute => 'Mettre sur la route';

  @override
  String get discoverOpenOsm => 'Ouvrir sur OpenStreetMap';

  @override
  String get discoverApproachTrailhead => 'Approche du trailhead…';

  @override
  String discoverApproachPlusTrail(String km, String diff) {
    return 'Approche + trail · $km km · $diff';
  }

  @override
  String discoverTrailLaid(String diff, String km) {
    return 'Trail posé · $diff · $km km — enregistrer ou partir';
  }

  @override
  String get discoverSurfaceNature => 'Naturel';

  @override
  String get discoverSurfaceGrass => 'Herbe';

  @override
  String get discoverSurfaceWood => 'Bois';

  @override
  String get discoverHighwayPath => 'Sentier';

  @override
  String get discoverHighwayTrack => 'Piste forestière';

  @override
  String get discoverHighwayCycle => 'Piste cyclable';

  @override
  String get discoverHighwayBridle => 'Chemin équestre';

  @override
  String get discoverHighwayFoot => 'Chemin piéton';

  @override
  String get discoverSetStartEnd =>
      'Pose départ et arrivée — puis calcule la route';

  @override
  String get discoverAdjustStops => 'Ajuste départ, arrivée ou un stop';

  @override
  String discoverNoHitsFor(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get discoverGeocodeFailed => 'Recherche d\'adresse ratée';

  @override
  String discoverStartEndHit(String kind, String label) {
    return '$kind : $label';
  }

  @override
  String get discoverIdeaStartSet =>
      'Idée de tour : départ = point, arrivée proposée — calcule la route.';

  @override
  String get discoverSuggestEnd => 'Arrivée proposée (modifiable)';

  @override
  String get discoverTourInPlan =>
      'Tour dans Planifier — départ/arrivée/via éditables';

  @override
  String get discoverNeedLocationTours =>
      'Pose un lieu ou un départ pour les tours';

  @override
  String get discoverOaOffline => 'Outdooractive hors ligne';

  @override
  String get discoverOaNoLive =>
      'Outdooractive — pas de tours live à proximité';

  @override
  String discoverOaCount(int count) {
    return 'Outdooractive $count · OSM/traces suivent';
  }

  @override
  String get discoverLocationOff =>
      'Localisation off — touche le départ ou une adresse';

  @override
  String get discoverLocationDenied =>
      'Permission de localisation manquante — utilise une adresse';

  @override
  String get discoverNoGpsFix =>
      'Pas de fix GPS — touche la carte ou cherche une adresse';

  @override
  String get discoverMyPosition => 'Ma position';

  @override
  String get discoverLocationReady => 'Position prête · chargement autour…';

  @override
  String get discoverLocationUnavailable =>
      'Position indisponible — adresse ou toucher';

  @override
  String get discoverComputing => 'Calcul de la route…';

  @override
  String discoverComputingN(int count) {
    return 'Calcul de $count routes…';
  }

  @override
  String get discoverHeadingNorth => 'Vers le nord';

  @override
  String get discoverHeadingEast => 'Vers l\'est';

  @override
  String get discoverHeadingSouthwest => 'Vers le sud-ouest';

  @override
  String get discoverTargetNorth =>
      'Arrivée au nord — retour pas encore inclus';

  @override
  String get discoverTargetEast =>
      'Arrivée à l\'est — retour pas encore inclus';

  @override
  String get discoverTargetSouthwest =>
      'Arrivée au sud-ouest — retour pas encore inclus';

  @override
  String discoverApproxLabel(String label) {
    return '$label (approx.)';
  }

  @override
  String get discoverQuickRoute => 'Route rapide';

  @override
  String get discoverRoutingLimit =>
      'Limite de routing — approx utilisée. Recalcule plus tard.';

  @override
  String get discoverNoQuickRoutes => 'Pas de routes rapides';

  @override
  String get discoverPartialApprox => 'Approx partielle — routing live limité';

  @override
  String get discoverPlannedRoute => 'Route planifiée';

  @override
  String get discoverStraightFallback =>
      'Ligne droite — le routing live n\'a pas donné de géométrie';

  @override
  String get discoverSaved => 'Enregistré';

  @override
  String discoverSavedNamed(String name) {
    return 'Enregistré : $name';
  }

  @override
  String get discoverSavedRouteLoaded => 'Route enregistrée chargée';

  @override
  String get discoverStartSetPickEnd => 'Départ posé — choisis l\'arrivée';

  @override
  String get discoverEndSetComputing => 'Arrivée posée — calcul de la route';

  @override
  String get discoverFromHere => 'D\'ici';

  @override
  String get discoverNearbyPhotos => 'Photos à proximité';

  @override
  String get discoverToMyTours => 'Vers Mes tours';

  @override
  String get discoverAlreadyInMappe => 'Déjà dans la Mappe';

  @override
  String discoverInMappeNamed(String name) {
    return 'Dans la Mappe : $name';
  }

  @override
  String get discoverAddRoute => 'Ajouter une route';

  @override
  String get discoverAddRouteHint =>
      'Nom + départ — pas de trace inventée. Calcule plus tard ou GPX.';

  @override
  String get discoverMapCenter => 'Centre de la carte';

  @override
  String get discoverSaveToMine => 'Enregistrer dans Mes tours';

  @override
  String discoverSavedToMine(String name) {
    return 'Dans Mes tours : $name';
  }

  @override
  String get discoverPickFileAgain => 'Choisir un autre fichier';

  @override
  String discoverGpxUnreadable(String name) {
    return 'Impossible de lire « $name » — abîmé ou GPX invalide.';
  }

  @override
  String get discoverGpxInvalid =>
      'GPX invalide ou trop peu de points — autre fichier ?';

  @override
  String discoverGpxImported(String name, String km) {
    return 'GPX importé : $name · $km km';
  }

  @override
  String discoverSavedDotName(String name) {
    return 'Enregistré · $name';
  }

  @override
  String get discoverAsActive => 'Comme actif';

  @override
  String get discoverLocalFoldersHint =>
      'Dossiers locaux pour les routes enregistrées — pas un fil social.';

  @override
  String get discoverNoSavedInCollection =>
      'Pas de routes enregistrées dans cette collection';

  @override
  String get discoverNoCollectionYet => 'Pas encore de collection.';

  @override
  String get discoverNewCollection => 'Nouvelle collection';

  @override
  String get discoverNeedRouteAndCollection =>
      'Il faut au moins une route enregistrée et une collection';

  @override
  String get discoverPickRoute => 'Choisir une route';

  @override
  String get discoverPickCollection => 'Choisir une collection';

  @override
  String get discoverAddedToCollection => 'Ajouté à la collection';

  @override
  String get discoverRouteToCollection => 'Route vers collection';

  @override
  String get discoverStartSavedNoTrack =>
      'Départ enregistré — pas encore de trace. Navigue ou GPX.';

  @override
  String get discoverComputedRoute => 'Route calculée';

  @override
  String get discoverSavedRoute => 'Route enregistrée';

  @override
  String discoverViaN(int n) {
    return 'Via $n';
  }

  @override
  String get discoverTourGone => 'Tour plus disponible';

  @override
  String get discoverTourGoneBody =>
      'Ce tour n\'est plus dans la liste — un filtre le cache peut-être.';

  @override
  String get discoverTourTimeline => 'Le long du tour';

  @override
  String get discoverNoTrackYet =>
      'Pas encore de trace — Calculer la route la construit en live.';

  @override
  String get discoverDuration => 'Durée';

  @override
  String get discoverLength => 'Longueur';

  @override
  String get discoverAscent => 'Montée';

  @override
  String get discoverElevationProfile => 'Profil';

  @override
  String discoverDescent(String m) {
    return '↓ $m m de descente';
  }

  @override
  String get discoverTip => 'Conseil';

  @override
  String get discoverBestTime => 'Meilleure période';

  @override
  String get discoverDiscipline => 'Discipline';

  @override
  String get discoverCorridor => 'Couloir';

  @override
  String get discoverTraits => 'Traits';

  @override
  String get discoverTipsInfo => 'Conseils & infos';

  @override
  String get discoverStartPoint => 'Départ';

  @override
  String discoverFromHereKm(String dist) {
    return '$dist d\'ici';
  }

  @override
  String get discoverApproach => 'Approche';

  @override
  String get discoverInMyTours => 'Dans Mes tours';

  @override
  String discoverPinIdeaNamed(String name) {
    return 'Idée « $name » — point seulement';
  }

  @override
  String get discoverPinIdea =>
      'Idée de tour — seulement un point sur la carte';

  @override
  String get discoverStartEndReady =>
      'Départ/arrivée posés. Calcule la route ou ajuste l\'arrivée.';

  @override
  String get discoverComputeAndSave => 'Calculer & enregistrer';

  @override
  String get discoverChangePlaceSearch =>
      'Changer de lieu — cherche une ville ou une adresse';

  @override
  String discoverDemoRegion(String name) {
    return 'Région démo : $name';
  }

  @override
  String get discoverPickProfile => 'Choisir le profil';

  @override
  String get discoverOwn => 'À toi';

  @override
  String discoverStartOnlyNoTrack(String badge) {
    return '$badge · départ — pas encore de trace';
  }

  @override
  String get discoverShowLess => 'Voir moins';

  @override
  String get discoverShowMore => 'Voir plus';

  @override
  String get discoverTrailView => 'Vue trail';

  @override
  String get discoverNoPhotosNearby => 'Pas de photos à proximité';

  @override
  String get discoverImageUnavailable => 'Image indisponible';

  @override
  String get discoverNoLivePhotos => 'Pas de photos live';

  @override
  String get discoverOpenMapillary => 'Ouvrir Mapillary';

  @override
  String get discoverMapillarySample => 'Exemple — Mapillary indisponible';

  @override
  String get discoverNoTrackOnMap =>
      'Pas de trace — charge-la d\'abord sur la carte ou GPX.';

  @override
  String get discoverNoClosedLoop =>
      'Pas de boucle fermée — rechoisis le tour ou Ajuste.';

  @override
  String get discoverNoLiveTrackPlan =>
      'Pas de trace live — Calculer ouvre Planifier avec une arrivée proposée.';

  @override
  String get discoverNotClosedLoopNav =>
      'La géométrie n\'est pas une boucle — navigation annulée.';

  @override
  String get discoverNoRealPolyline =>
      'Pas de vraie polyline — recalcule ou GPX.';

  @override
  String get discoverPoiIdeaHint =>
      'Approche du point — pas de trace de tour. Continue l\'arrivée ou GPX.';

  @override
  String discoverHybridKm(String km) {
    return 'Hybride · $km km';
  }

  @override
  String get discoverAroundPoiComputing =>
      'Calcul d\'une route autour du point…';

  @override
  String discoverLiveRouteReady(String km) {
    return 'Route live · $km km — enregistrer ou partir';
  }

  @override
  String discoverPoiNamed(String name) {
    return 'Point · $name';
  }

  @override
  String get discoverNotLoopAb =>
      'Pas une boucle — proposition A→B. Calcule la route ou touche l\'arrivée.';

  @override
  String get discoverApproxAb =>
      'Approx A→B · ajuste l\'arrivée sur la carte, puis recalcule.';

  @override
  String get discoverRoutingFailedRetry =>
      'Routing raté — touche l\'arrivée et réessaie.';

  @override
  String get discoverUnplausibleDropped =>
      'Résultat de routing peu plausible ignoré';

  @override
  String discoverAltChosen(String label) {
    return 'Alternative choisie : $label';
  }

  @override
  String get discoverLoading => 'Chargement';

  @override
  String get discoverCatalog => 'Catalogue';

  @override
  String get discoverShared => 'partagé';

  @override
  String get discoverPrivate => 'privé';

  @override
  String get discoverPrivateCap => 'Privé';

  @override
  String get discoverShareRelease => 'Partager';

  @override
  String discoverRiddenWith(String name) {
    return 'roulé avec $name';
  }

  @override
  String get discoverPrivateCommentHint =>
      'Encore privé — les autres commentent après le partage.';

  @override
  String get discoverRemoveFromMappe => 'Retirer de la Mappe';

  @override
  String get discoverLinkNoTrack =>
      'Lien sans trace — trop long pour l\'URL. Nom et stats, pas de GPS.';

  @override
  String get discoverLinkCopiedTrack =>
      'Lien copié. Contient une trace simplifiée.';

  @override
  String get discoverLinkCopiedStats =>
      'Lien copié. Nom et stats, pas de trace.';

  @override
  String get discoverTrackLocal => 'Trace locale. Sync entre tes appareils.';

  @override
  String get discoverNoTrackEntry =>
      'Pas encore de trace — juste l\'entrée dans la Mappe.';

  @override
  String get discoverVisibility => 'Visibilité';

  @override
  String get discoverCopyLink => 'Copier le lien';

  @override
  String get discoverNoSavedFilter => 'Aucun tour dans ce filtre.';

  @override
  String get discoverMineEmptyHint =>
      'Pas encore de traces à toi — ajoute une route, GPX ou enregistre.';

  @override
  String get overlayLegendTitle => 'Chemins · OSM';

  @override
  String get overlayRoadAsphalt => 'Piste / asphalte';

  @override
  String get overlayUnrated => 'non classé';

  @override
  String get stimmenTitle => 'Voix';

  @override
  String get stimmenHint =>
      'Étoiles, texte et photos — cloud après partage. Pas de voix inventées.';

  @override
  String get stimmenWrite => 'Écrire une voix';

  @override
  String get stimmenHowWas => 'Comment était le tour ?';

  @override
  String get stimmenEmptyName => 'Vide, c\'est toi';

  @override
  String get stimmenAddPhoto => 'Ajouter une photo';

  @override
  String get stimmenSaving => 'Enregistrement …';

  @override
  String get stimmenShareSubject => 'Partager le tour';

  @override
  String get stimmenEmpty => 'Pas encore de voix.';

  @override
  String get stimmenLabel => 'Voix';

  @override
  String get stimmenCloudApproved => 'Enregistré — publié (partage IA)';

  @override
  String get stimmenCloudRejected =>
      'Enregistré en local — le cloud a refusé le texte';

  @override
  String get stimmenCloudPending =>
      'Enregistré — local et en revue (IA/humain)';

  @override
  String get stimmenCloudLocal => 'Enregistré — local (cloud après connexion)';

  @override
  String get stimmenCloudFailed => 'Enregistré en local — cloud injoignable';

  @override
  String get akteHonestyCatalog =>
      'Les tours catalogue sont déjà publics. Partager rend ton dossier partageable — le lien montre nom et stats, pas de trace privée en plus.';

  @override
  String get akteHonestyTrack =>
      'Partager crée un lien. Le lien contient une trace simplifiée (coordonnées), pas seulement le nom. Repasser en privé le retire des filtres et enregistre le retrait sur le serveur si tu es connecté. Sans login, ça ne vaut que sur cet appareil.';

  @override
  String get akteHonestyNoTrack =>
      'Partager crée un lien avec nom et stats — sans trace, parce qu\'il n\'y en a pas.';

  @override
  String get stimmenSubmit => 'Envoyer';

  @override
  String get discoverRoundTrip => 'Aller-retour';

  @override
  String get discoverOutboundOnly => 'aller seulement';

  @override
  String get discoverOsmNoHitsSuffix => ' · OSM aucun résultat';

  @override
  String get discoverLiveRoutingUnavailable => ' · routage live indisponible';

  @override
  String get discoverUnplausibleLive =>
      ' · le routage live n\'a rien de plausible';

  @override
  String get discoverTapEndCompute =>
      'Tape un but ou une adresse — puis calcule la route.';

  @override
  String get discoverPlanYourself =>
      'Planifie la route toi-même — pose départ et but';

  @override
  String get discoverLoopBadge => '⟲ Boucle';

  @override
  String discoverElevMin(Object min) {
    return 'Min $min';
  }

  @override
  String get discoverHeatmapOffline => 'Heatmap hors ligne';

  @override
  String get discoverCreate => 'Créer';

  @override
  String get discoverRegionSource => 'Région';

  @override
  String get discoverTourNoun => 'Tour';

  @override
  String get discoverOsmLive => 'OSM live';

  @override
  String discoverApproachParen(Object name) {
    return '($name)';
  }

  @override
  String get discoverShop => 'Magasin';

  @override
  String get discoverPreview => 'Aperçu';

  @override
  String discoverApproachName(Object name) {
    return '$name (approche)';
  }

  @override
  String discoverFromHereName(Object name) {
    return '$name (d\'ici)';
  }

  @override
  String get rideLocationOff => 'Position coupée';

  @override
  String get rideLocationOffBody =>
      'Sans position, pas de trace GPS. Active les services de localisation.';

  @override
  String get rideSettings => 'Réglages';

  @override
  String get rideLocationPermission => 'Autorisation de position';

  @override
  String get rideLocationDeniedForever =>
      'Position refusée pour de bon. Active-la dans les réglages de l\'app, sinon la trace reste vide.';

  @override
  String get rideAppSettings => 'Réglages de l\'app';

  @override
  String get rideLocationNeeded =>
      'La position est nécessaire pour trace et navigation — relance et autorise.';

  @override
  String get rideGpsFix => 'GPS-Fix…';

  @override
  String rideGpsFixN(Object count) {
    return 'GPS-Fix $count…';
  }

  @override
  String get rideGpsStillSim => 'GPS immobile — Sim-Track (ne pas enregistrer)';

  @override
  String get rideGpsStillWeak => 'GPS immobile — signal faible / arrêt';

  @override
  String get rideGpsSimActive => 'Sim-Track actif (AETHER_SIM_MOTION)';

  @override
  String get rideBleOffSnack =>
      'Bluetooth éteint — tu peux rouler sans capteur ; couple plus tard.';

  @override
  String get rideBleDeniedSnack =>
      'Nearby/Bluetooth refusé — la navigation GPS tourne sans capteur.';

  @override
  String get rideNoBikeSensor => 'Aucun capteur vélo — la trace GPS continue.';

  @override
  String get rideOfflineRerouteToast =>
      'Le reroute a besoin d\'internet. Reste sur la route chargée.';

  @override
  String get rideNoGpsRejoin => 'Pas de GPS-Fix pour le rejoin';

  @override
  String rideRejoinFailed(Object error) {
    return 'Rejoin échoué : $error';
  }

  @override
  String get rideSkipAheadWhy => 'Tronçon sauté — retour à la route.';

  @override
  String get rideRejoinWhy => 'Retour à la route.';

  @override
  String get rideSkipAheadTts => 'Tronçon sauté';

  @override
  String get rideRouteRestoredTts => 'Route rétablie';

  @override
  String get rideOffRouteTts => 'Hors de la route';

  @override
  String get rideRerouting => 'La route se recalcule …';

  @override
  String get rideUndo10s => '10 s pour défaire';

  @override
  String get rideUndo => 'Défaire';

  @override
  String get rideStayOffHint => 'Tu restes hors route — tape pour les options.';

  @override
  String get rideRecalc => 'Recalculer …';

  @override
  String get rideTapOptions => 'Tape pour les options.';

  @override
  String get rideOptions => 'Options';

  @override
  String get ridePause => 'Pause';

  @override
  String get rideResume => 'Continuer';

  @override
  String get rideRunning => 'Trajet en cours';

  @override
  String get rideStop => 'Stop';

  @override
  String get rideTapAgain => 'Tape encore';

  @override
  String get rideStopNeedsTwo => 'Arrêter demande 2 tapes';

  @override
  String get rideQuietDisplay => 'Affichage calme';

  @override
  String get rideFollowCamera => 'Suivre la caméra';

  @override
  String get rideFollowOn => 'Suivi caméra on';

  @override
  String get rideFollowFree => 'Caméra libre';

  @override
  String get rideLiveRide => 'Trajet live';

  @override
  String get rideReady => 'Prêt';

  @override
  String get rideTtsOn => 'TTS on';

  @override
  String get rideTtsMute => 'TTS muet';

  @override
  String get rideNorthUp => 'Nord en haut';

  @override
  String get rideHeadingUp => 'Direction en haut';

  @override
  String rideHeadingCourse(Object cardinal, Object mode) {
    return '$mode, cap $cardinal';
  }

  @override
  String get rideAutoRerouteOn => 'Auto-Reroute on';

  @override
  String get rideAutoRerouteOff => 'Auto-Reroute off';

  @override
  String rideAutoRerouteActive(Object sec) {
    return 'Auto-Reroute actif (cooldown ${sec}s)';
  }

  @override
  String get rideAutoRerouteManual =>
      'Auto-Reroute off — le rejoin manuel reste';

  @override
  String get rideSunlightAuto => 'Sunlight Mode (Auto)';

  @override
  String get rideSunlightManual => 'Sunlight Mode (Manuel)';

  @override
  String rideDisplayNamed(Object name) {
    return 'Display : $name';
  }

  @override
  String rideDisplayNamedBattery(Object name) {
    return 'Display : $name (consomme de la batterie)';
  }

  @override
  String get rideCostsBattery => 'consomme de la batterie';

  @override
  String get rideBatteryTitle => 'Display & batterie';

  @override
  String get rideBatteryHint =>
      'Laisser le display allumé ? Ça consomme. Standard économise la batterie.';

  @override
  String get rideBatteryPocketSnack =>
      'Pocket — le display peut s\'éteindre (économiser).';

  @override
  String get rideBatteryLenkerSnack =>
      'Lenker — display allumé (consomme de la batterie).';

  @override
  String get rideBatteryUltraSnack =>
      'Ultra — display seulement aux virages (consomme de la batterie).';

  @override
  String get rideBatteryPocket => 'Pocket';

  @override
  String get rideBatteryLenker => 'Lenker';

  @override
  String get rideBatteryUltra => 'Ultra';

  @override
  String get rideBatteryPocketSub =>
      'Voix + haptique, display peut s\'éteindre';

  @override
  String get rideBatteryLenkerSub => 'Laisser le display allumé';

  @override
  String get rideBatteryUltraSub =>
      'Réveiller le display seulement aux virages';

  @override
  String get rideDefault => 'Standard';

  @override
  String get rideSpeed => 'Allure';

  @override
  String get rideSensorSpeed => 'Allure capteur';

  @override
  String get rideDistance => 'Distance';

  @override
  String get rideTime => 'Temps';

  @override
  String get rideHeart => 'Pouls';

  @override
  String get rideHeartWaiting => 'Pouls en attente';

  @override
  String get rideCadence => 'Cadence';

  @override
  String get rideBikeSensor => 'Capteur vélo';

  @override
  String get rideWatch => 'Smartwatch';

  @override
  String get rideConnected => 'Connecté';

  @override
  String get ridePower => 'Puissance';

  @override
  String get rideSoc => 'SoC';

  @override
  String get rideAssist => 'Assist';

  @override
  String get rideBatteryChip => 'Batterie';

  @override
  String get rideWheelSpeed => 'Roue';

  @override
  String get rideRestKm => 'Rest-km';

  @override
  String get rideEta => 'ETA';

  @override
  String get rideKmh => 'km/h';

  @override
  String get rideKm => 'km';

  @override
  String get rideChassisOff => 'Analyse châssis off';

  @override
  String get rideChassisHint =>
      'Fixe le téléphone au cintre et marque-le comme monté.';

  @override
  String get rideMarkMounted => 'Marquer comme monté';

  @override
  String get rideWaitingSensors => 'En attente des capteurs…';

  @override
  String get rideThereafter => 'Ensuite';

  @override
  String get rideAutoLock => 'Auto-Lock';

  @override
  String get rideAutoLockHint => 'Tape pour réveiller';

  @override
  String get rideWake => 'Réveiller';

  @override
  String get rideMusicHud => 'Musique dans le HUD';

  @override
  String get rideMusicHudHint => 'Afficher les titres de Spotify & Co.';

  @override
  String get rideDismissHint => 'Fermer l\'indice';

  @override
  String get rideMusicControls => 'Commandes musique';

  @override
  String get ridePrevTrack => 'Titre précédent';

  @override
  String get rideNextTrack => 'Titre suivant';

  @override
  String get ridePlay => 'Lire';

  @override
  String get rideNavSymbol => 'Symbole';

  @override
  String get rideChangeNavSymbol => 'Changer le symbole navi';

  @override
  String get rideNavPuckTitle => 'Symbole navi';

  @override
  String get rideNavPuckHint =>
      'Toutes les variantes sur fond sombre et clair. Tape pour choisir le symbole carte et HUD. 0° = pointe en haut.';

  @override
  String get rideRecommend => 'Recommandé';

  @override
  String get ridePuckDark => 'Sombre';

  @override
  String get ridePuckLight => 'Clair';

  @override
  String get ridePuckBergA => 'Berg-A';

  @override
  String get ridePuckTopDown => 'Vélo vu du haut';

  @override
  String get ridePuckHofTor => 'Hof-Tor';

  @override
  String get ridePuckKomet => 'Aether-Komet';

  @override
  String get ridePuckKiesel => 'Galet';

  @override
  String get ridePuckLenkerBug => 'Nez de cintre';

  @override
  String get ridePuckLichtkegel => 'Cône de lumière';

  @override
  String get ridePuckChevron => 'Chevron';

  @override
  String get ridePuckBergASub => 'Lettre, montagne et flèche en un';

  @override
  String get ridePuckTopDownSub =>
      'Vue du haut : nez, cornes, deux pneus — tourne avec toi';

  @override
  String get ridePuckHofTorSub => 'Deux jambes, ouvertes en bas';

  @override
  String get ridePuckKometSub => 'Fer de lance avec étincelle menthe';

  @override
  String get ridePuckKieselSub => 'Triangle doux avec halo';

  @override
  String get ridePuckLenkerBugSub => 'Nez pointu, deux cornes de cintre';

  @override
  String get ridePuckLichtkegelSub => 'Disque sombre, cône orange';

  @override
  String get ridePuckChevronSub => 'Flèche navi standard';

  @override
  String get rideChipLive => 'Live';

  @override
  String get rideChipRouteOffline => 'Route hors ligne';

  @override
  String get rideChipOfflineMapOk => 'Hors ligne · carte ok · Reroute : réseau';

  @override
  String get rideChipMapsMissing => 'Cartes manquantes';

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
  String get navCueArrive => 'Tu es arrivé';

  @override
  String get navCueSlightLeft => 'Légèrement à gauche';

  @override
  String get navCueSlightRight => 'Légèrement à droite';

  @override
  String get navCueTurnLeft => 'Tourne à gauche';

  @override
  String get navCueTurnRight => 'Tourne à droite';

  @override
  String get navCueSharpLeft => 'Fortement à gauche';

  @override
  String get navCueSharpRight => 'Fortement à droite';

  @override
  String liveHintBracketRun(String n) {
    return 'Passage $n enregistré';
  }

  @override
  String get liveHintImpactStreak => 'Série de chocs durs';

  @override
  String get liveHintStandSetup => 'Arrêt: tu peux régler';

  @override
  String get maintForkLower => 'Service lower-leg fourche';

  @override
  String get maintForkFull => 'Révision complète fourche (ressort/amortisseur)';

  @override
  String get maintShockAir => 'Service air-can amortisseur';

  @override
  String get maintShockFull => 'Révision complète amortisseur';

  @override
  String get maintChainWear => 'Contrôle usure chaîne';

  @override
  String get maintCassetteCheck => 'Contrôle cassette (après 2–3 chaînes)';

  @override
  String get maintPadsFront => 'Contrôle plaquettes avant';

  @override
  String get maintPadsRear => 'Contrôle plaquettes arrière';

  @override
  String get maintSealant => 'Renouveler le lait tubeless';

  @override
  String get maintDropper => 'Service lower-post dropper';

  @override
  String maintDays(String n) {
    return '$n j';
  }

  @override
  String get maintNoInterval => 'Pas d\'intervalle';

  @override
  String get compatTitleDrv011 =>
      'La cassette a besoin du corps de roue libre qui va';

  @override
  String get compatTitleFrm004 => 'La largeur arrière doit aller au moyeu';

  @override
  String get compatTitleSus007 => 'La cote d\'amortisseur doit aller au cadre';

  @override
  String get compatTitleSus012 =>
      'Pivot de fourche vs jeu de direction (S.H.I.S.)';

  @override
  String get compatTitleBrk003 => 'Fixation d\'étrier sur le cadre';

  @override
  String get compatTitleBrk008 => 'Fixation de disque vs moyeu';

  @override
  String get compatTitleBrk008f => 'Disque avant vs moyeu avant';

  @override
  String get compatTitleWhl005 => 'Largeur de pneu vs largeur interne de jante';

  @override
  String get compatTitleWhl005f => 'Pneu avant vs largeur interne de jante';

  @override
  String get compatTitleWhl009 => 'Largeur de pneu vs passage au cadre';

  @override
  String get compatTitleCkp002 => 'Diamètre de serrage cintre vs potence';

  @override
  String get compatTitleSpt006 => 'Diamètre de tige de selle vs tube de selle';

  @override
  String get compatTitleBb003 => 'Standard de boîtier vs axe de pédalier';

  @override
  String get compatTitleBb003f => 'Boîtier vs standard du cadre';

  @override
  String get compatTitleEbk002 => 'Interface moteur seulement avec accord OEM';

  @override
  String get compatTitleFrm004f => 'Axe avant vs fourche';

  @override
  String compatFailDrv011(String cassette, String hub) {
    return 'La cassette demande $cassette, ton moyeu a $hub.';
  }

  @override
  String compatFailFrm004(String frame, String hub) {
    return 'Largeur cadre $frame ≠ moyeu $hub.';
  }

  @override
  String compatFailSus007(String eye, String stroke, String mount) {
    return 'Amortisseur $eye×$stroke ($mount) ne va pas à la cote cadre.';
  }

  @override
  String compatFailSus012(String fork, String headset) {
    return 'Pivot $fork ne va pas au jeu de direction $headset.';
  }

  @override
  String compatFailBrk003(String caliper, String frame) {
    return 'Étrier $caliper vs fixation cadre $frame.';
  }

  @override
  String compatFailBrk008(String rotor, String hub) {
    return 'Disque $rotor ≠ moyeu $hub.';
  }

  @override
  String compatFailBrk008f(String rotor, String hub) {
    return 'Disque avant $rotor ≠ moyeu $hub.';
  }

  @override
  String compatFailWhl005(String tire, String rim) {
    return 'Largeur pneu $tire mm hors plage pour largeur interne $rim mm.';
  }

  @override
  String compatFailWhl005f(String tire, String rim) {
    return 'Pneu avant $tire mm hors plage pour $rim mm.';
  }

  @override
  String compatFailWhl009(String tire, String max) {
    return 'Largeur pneu $tire mm > passage cadre $max mm.';
  }

  @override
  String compatFailCkp002(String bar, String stem) {
    return 'Serrage cintre $bar mm ≠ potence $stem mm.';
  }

  @override
  String compatFailSpt006(String post, String frame) {
    return 'Tige Ø $post ne va pas au cadre Ø $frame.';
  }

  @override
  String compatFailBb003(String bb, String crank) {
    return 'Axe de boîtier $bb ≠ pédalier $crank.';
  }

  @override
  String compatFailBb003f(String bb, String frame) {
    return 'Boîtier $bb ≠ cadre $frame.';
  }

  @override
  String compatFailEbk002(String frame, String motor) {
    return 'Échange moteur hors accord OEM interdit. Cadre $frame ≠ moteur $motor.';
  }

  @override
  String compatFailFrm004f(String fork, String hub) {
    return 'Axe de fourche $fork ≠ moyeu $hub.';
  }

  @override
  String get compatRuleOk => 'Règle respectée.';

  @override
  String get compatConditional => 'Compatible sous condition';

  @override
  String get compatMissingFacts =>
      'Attributs manquants — pas de COMPATIBLE sans faits complets.';

  @override
  String get compatWorkshopHint =>
      'Montage lié à la sécurité: atelier. Couples uniquement depuis les docs constructeur.';

  @override
  String get compatConditionBrk003 =>
      'Seulement avec l\'adaptateur qui va (Post Mount ↔ IS).';

  @override
  String get compatDatasheet => 'Vérifie la fiche constructeur';

  @override
  String get attrFreehub => 'Standard de roue libre';

  @override
  String get attrRearSpacing => 'Largeur arrière';

  @override
  String get attrEyeToEye => 'Longueur œil-à-œil';

  @override
  String get attrStroke => 'Course';

  @override
  String get attrMountType => 'Type de montage';

  @override
  String get attrShockEyeToEye => 'Cote cadre: œil-à-œil';

  @override
  String get attrShockStroke => 'Cote cadre: course';

  @override
  String get attrShockMount => 'Cote cadre: type de montage';

  @override
  String get attrSteerer => 'Pivot de fourche';

  @override
  String get attrBrakeMount => 'Fixation d\'étrier';

  @override
  String get attrBrakeMountRear => 'Cadre: fixation frein arrière';

  @override
  String get attrRotorMount => 'Fixation de disque';

  @override
  String get attrTireWidth => 'Largeur de pneu';

  @override
  String get attrRimWidth => 'Largeur interne de jante';

  @override
  String get attrMaxTire => 'Cadre: passage pneu max.';

  @override
  String get attrBarClamp => 'Diamètre de serrage';

  @override
  String get attrStemClamp => 'Serrage de potence';

  @override
  String get attrSeatpostDia => 'Diamètre';

  @override
  String get attrMinInsert => 'Insertion min.';

  @override
  String get attrMaxInsert => 'Cadre: insertion max.';

  @override
  String get attrCrankAxle => 'Axe de pédalier';

  @override
  String get attrBbStandard => 'Standard de boîtier';

  @override
  String get attrMotorInterface => 'Interface moteur';

  @override
  String get attrAxleFront => 'Axe';

  @override
  String get howToFreehub => 'Marquage corps de roue libre / fiche moyeu';

  @override
  String get howToRearSpacing => 'Spec cadre/moyeu (Boost 148, 142×12, …)';

  @override
  String get howToEyeToEye => 'Marquage amortisseur';

  @override
  String get howToStroke => 'Catalogue amortisseur';

  @override
  String get howToMountType => 'Trunnion vs. Eyelet';

  @override
  String get howToSteerer => '1⅛″ ou tapered 1,5″ / S.H.I.S.';

  @override
  String get howToBrakeMount => 'Post Mount / Flat Mount / IS';

  @override
  String get howToBrakeMountRear => 'Spec cadre';

  @override
  String get howToRotorMount => 'Center Lock ou 6 trous';

  @override
  String get howToTireWidth => 'ETRTO';

  @override
  String get howToRimWidth => 'Fiche jante';

  @override
  String get howToMaxTire => 'Cote constructeur du cadre';

  @override
  String get howToBarClamp => '31,8 ou 35,0';

  @override
  String get howToStemClamp => 'Fiche potence';

  @override
  String get howToSeatpostDia => '27,2 / 30,9 / 31,6 / 34,9';

  @override
  String get howToMinInsert => 'Manuel dropper';

  @override
  String get howToMaxInsert => 'Géométrie du cadre';

  @override
  String get howToCrankAxle => 'DUB / 24mm / 30mm';

  @override
  String get howToBbStandard => 'BSA / T47 / PF92 / …';

  @override
  String get howToMotorInterface => 'ex. bosch_smart_system';

  @override
  String get howToAxleFront => '15×100 / 15×110 Boost / …';

  @override
  String postRideObsImpacts(String count, String km) {
    return 'Beaucoup d\'impacts durs ($count sur $km km) — avant/amortisseur très sollicités.';
  }

  @override
  String postRideObsSmooth(String km) {
    return 'Peu d\'impacts sur $km km — plutôt fluide ou sol lisse.';
  }

  @override
  String postRideObsFlowHigh(String flow) {
    return 'Flow élevé ($flow) — rythme et lignes semblaient justes.';
  }

  @override
  String postRideObsFlowLow(String flow) {
    return 'Flow bas ($flow) — beaucoup de cassures de rythme ou d\'arrêts.';
  }

  @override
  String postRideObsPeakG(String g) {
    return 'Peak $g g — chocs durs; vérifie setup et pression.';
  }

  @override
  String get postRideFrontTooFirm => 'trop dure';

  @override
  String get postRideFrontOk => 'ok';

  @override
  String get postRideBumpsHarsh => 'rudes';

  @override
  String postRideObsFbHarsh(String front, String bumps) {
    return 'Retour: avant $front · petits chocs $bumps.';
  }

  @override
  String get postRideObsFbSoft =>
      'Retour: l\'avant est mou / plonge au freinage.';

  @override
  String get postRideSugReboundSlowTitle =>
      'Détente fourche: 2 clics plus lent';

  @override
  String postRideSugReboundSlowContent(String current, String next) {
    return 'Environ $current clics depuis fermé → cible $next.';
  }

  @override
  String get postRideSugReboundSlowEffect =>
      'Avant plus calme sur les enchaînements, un peu moins de pop.';

  @override
  String get postRideSugReboundFastTitle =>
      'Détente fourche: 2 clics plus rapide';

  @override
  String postRideSugReboundFastContent(String current, String next) {
    return 'Environ $current clics → cible $next (moins de plongée).';
  }

  @override
  String get postRideSugReboundFastEffect =>
      'Freinage plus stable, moins de sensation de talonnage.';

  @override
  String get postRideSugPressureTitle => 'Vérifie la pression avant';

  @override
  String get postRideSugPressureContent =>
      'Peak-g très élevé — tiens pression et spacers volume sur le tableau constructeur.';

  @override
  String get postRideSugPressureEffect =>
      'Moins de risque de talonnage, retour plus clair.';

  @override
  String get postRideSugLimitsClicks =>
      'Plage constructeur typique 0–14 clics depuis fermé.';

  @override
  String get postRideSugLimitsPressure =>
      'Seulement dans la plage de pression validée du pneu/de la fourche.';

  @override
  String get postRideReasonHarshBumps => 'Retour « petits chocs rudes »';

  @override
  String get postRideReasonFrontFirm => 'Retour « avant trop dur »';

  @override
  String postRideReasonImpacts(String count, String km) {
    return '$count impacts / $km km';
  }

  @override
  String postRideReasonRms(String rms) {
    return 'RMS $rms g';
  }

  @override
  String get postRideReasonFrontLoad => 'Forte charge de chocs à l\'avant';

  @override
  String get postRideReasonDive => 'Retour « plonge »';

  @override
  String get postRideReasonFrontSoft => 'Retour « avant trop mou »';

  @override
  String get postRideReasonSoftDive => 'Avant trop mou / plongée';

  @override
  String get postRideReasonPeakLong => 'Peak ≥ 5 g sur une sortie plus longue';

  @override
  String get postRideAnalysis => 'Analyse';

  @override
  String postRideExpect(String text) {
    return 'Attendu: $text';
  }

  @override
  String postRideLimit(String text) {
    return 'Limite: $text';
  }

  @override
  String get postRideEvidence => 'Preuve';

  @override
  String postRideConfidence(String level) {
    return 'Confiance $level';
  }

  @override
  String get postRideConfHigh => 'haute';

  @override
  String get postRideConfMedium => 'moyenne';

  @override
  String get postRideConfLow => 'basse';

  @override
  String postRideFactRide(String km, String hm, String min) {
    return '$km km · $hm hm · $min min';
  }

  @override
  String postRideFactMetrics(String flow, String g, String impacts) {
    return 'Flow $flow · Peak $g g · $impacts impacts';
  }

  @override
  String postRideFactMetricsLean(
      String flow, String g, String impacts, String lean) {
    return 'Flow $flow · Peak $g g · $impacts impacts · Lean $lean°';
  }

  @override
  String postRideFactBike(String name) {
    return 'Vélo: $name';
  }

  @override
  String postRideFactSoc(String soc) {
    return 'SOC $soc%';
  }

  @override
  String get rideGPeak => 'G-Peak';

  @override
  String get rideLean => 'Lean °';

  @override
  String get rideFlow => 'Flow';

  @override
  String garageSetNamed(String name) {
    return 'Régler $name';
  }

  @override
  String get bleKindPower => 'Capteur de puissance';

  @override
  String get bleKindOtherDrive => 'Moteur';

  @override
  String get bleTipBosch => 'Ferme Flow complètement · 10–20 cm de l\'écran';

  @override
  String get bleTipShimano =>
      'Ferme E-TUBE · tape dans les 15 s après Power/bouton';

  @override
  String get bleTipYamaha => 'Ferme e-Sync · vitesse via capteur CSC';

  @override
  String get bleTipOtherDrive =>
      'Ferme l\'app constructeur · écran allumé, tiens près';

  @override
  String get bleTipCsc => 'Réveille le capteur sur le vélo, tiens près';

  @override
  String get bleTipPower => 'Allume le capteur de puissance, tiens près';

  @override
  String get blePairLeadEbike =>
      'Écran allumé, app constructeur fermée, téléphone près — puis tape.';

  @override
  String get blePairLeadSensor =>
      'Réveille le capteur sur le vélo, pas la montre au poignet.';

  @override
  String get bleNoteSensorBrand => 'Capteur';

  @override
  String get bleNoteSensorLine =>
      'Aimant ou pédalier, près du capteur — pas la montre.';

  @override
  String get bleNoteBoschLine =>
      'Ferme Flow complètement (pas seulement en fond). Écran allumé, 10–20 cm.';

  @override
  String get bleNoteShimanoLine =>
      'Ferme E-TUBE. Après Power ou bouton souvent 15 s seulement — puis tape.';

  @override
  String get bleNoteYamahaLine =>
      'Ferme e-Sync ou l\'app TQ. Vitesse live surtout via CSC.';

  @override
  String get bleNoteFazuaLine =>
      'Remote allumée — CSC et puissance comme un capteur normal.';

  @override
  String get bleNoteOtherBrand => 'Autres';

  @override
  String get bleNoteOtherLine =>
      'Ferme RideControl / Mission Control. Un téléphone, écran allumé.';

  @override
  String get bleGattWatchRejected =>
      'Connexion refusée — ferme l\'autre app fitness, tiens la montre près.';

  @override
  String get bleGattWatchTimeout =>
      'Timeout — tiens la montre près, vérifie la fréquence cardiaque en broadcast.';

  @override
  String get bleGattWatchFailed => 'Connexion montre échouée';

  @override
  String get bleGattRejectedBosch =>
      'Connexion refusée — ferme Bosch Flow, écran allumé, 10–20 cm.';

  @override
  String get bleGattRejectedShimano =>
      'Connexion refusée — ferme E-TUBE, écran allumé, tiens près.';

  @override
  String get bleGattRejectedGeneric =>
      'Connexion refusée — ferme Bosch Flow / Shimano E-TUBE, écran allumé, tiens près.';

  @override
  String get bleGattTimeoutBosch =>
      'Timeout — réveille l\'écran, ferme Flow, tiens près. Valeurs moteur seulement avec CSC ou LDI officiel.';

  @override
  String get bleGattTimeoutShimano =>
      'Timeout — ferme E-TUBE, tape dans les 15 s après Power/bouton.';

  @override
  String get bleGattTimeoutDrive =>
      'Timeout — ferme l\'app constructeur, écran allumé. Vitesse via capteur CSC.';

  @override
  String get bleGattTimeoutSensor =>
      'Timeout — réveille le capteur, approche-toi.';

  @override
  String get bleDriveFailBosch =>
      'Bosch vu, pas de valeurs moteur live. Ensuite couple un capteur vélo (CSC).';

  @override
  String get bleDriveFailShimano =>
      'Shimano vu, pas de valeurs moteur live. Ensuite couple un capteur vélo (CSC).';

  @override
  String get bleDriveFailYamaha =>
      'Yamaha vu, pas de valeurs moteur live. Couple la vitesse via un capteur CSC.';

  @override
  String get bleDriveFailGeneric =>
      'Moteur vu, pas de valeurs moteur live. Ensuite couple un capteur vélo (CSC).';

  @override
  String get bleStatusBtOff => 'Bluetooth éteint';

  @override
  String get bleStatusScanFailed => 'Recherche capteur vélo échouée';

  @override
  String get bleStatusNoSensor => 'Aucun capteur vélo trouvé';

  @override
  String get bleStatusNoneInRange => 'Aucun vélo, moteur ou capteur à portée';

  @override
  String get bleStatusDriveSeen =>
      'Moteur vu — couple-le à l\'atelier (Bosch/Shimano)';

  @override
  String get bleStatusNoCscInRange => 'Aucun capteur vélo à portée';

  @override
  String get bleStatusSensorDisconnected => 'Capteur vélo déconnecté';

  @override
  String get bleStatusReconnectLost =>
      'Connexion perdue — vérifie l\'écran, ferme Flow/E-TUBE, couple à nouveau à l\'atelier.';

  @override
  String bleStatusRetry(String n, String max) {
    return 'Connexion … essai $n/$max';
  }

  @override
  String bleStatusAttempt(String n, String max) {
    return 'Connexion … tentative $n/$max';
  }

  @override
  String bleStatusReconnect(String n, String max) {
    return 'Reconnexion … ($n/$max)';
  }

  @override
  String bleStatusDriveNoLive(String who) {
    return '$who · vu — vitesse via CSC, batterie seulement avec GATT standard';
  }

  @override
  String bleConnectedNamed(String name) {
    return '$name connecté';
  }

  @override
  String get bleWordSensor => 'Capteur';

  @override
  String get bleWordWatch => 'Montre';

  @override
  String get bleSectionDrive => 'Moteur';

  @override
  String get bleSectionSensors => 'Capteurs';

  @override
  String get watchStatusPickFromList => 'Choisis la montre dans la liste';

  @override
  String get watchStatusScanFailed => 'Recherche montre échouée';

  @override
  String get watchStatusConnectedSim => 'Montre connectée (sim)';

  @override
  String get watchStatusDisconnected => 'Montre déconnectée';

  @override
  String get watchStatusNoHrService =>
      'Montre vue, mais sans service pouls standard';

  @override
  String get watchStatusReconnectLost =>
      'Montre déconnectée — vérifie le broadcast, couple à nouveau près d\'elle.';

  @override
  String watchStatusReconnect(String n, String max) {
    return 'La montre se reconnecte … ($n/$max)';
  }

  @override
  String watchStatusBattery(String n) {
    return 'Batterie montre $n %';
  }

  @override
  String get watchHrSensorFallback => 'Capteur de fréquence cardiaque';

  @override
  String get watchCheckBluetooth => 'Vérifie Bluetooth';

  @override
  String get watchOutOfRange => 'Montre hors de portée';

  @override
  String get watchRemoved => 'Montre retirée';

  @override
  String watchRememberedOffline(String name) {
    return '$name · mémorisée, pas live';
  }

  @override
  String get watchRememberedOfflineNoName => 'Mémorisée, pas live';

  @override
  String watchLiveNamed(String name) {
    return '$name · live';
  }

  @override
  String watchLiveBpm(String name, String bpm) {
    return '$name · $bpm bpm';
  }

  @override
  String get watchHonestyHr => 'Pouls en BLE standard';

  @override
  String get watchHonestyGarmin => 'Garmin: active le broadcast HR';

  @override
  String get watchHonestyApple => 'Apple Watch: pas de pouls BLE standard';

  @override
  String get watchHonestyGalaxy => 'Galaxy: souvent pas de 0x180D';

  @override
  String get watchHonestyUnknown => 'Seulement avec Heart Rate 0x180D';

  @override
  String get watchTipHr => 'Mode capteur ou broadcast allumé, tiens près';

  @override
  String get watchTipGarmin =>
      'Sur la Garmin: envoyer la fréquence / broadcast';

  @override
  String get watchTipApple =>
      'Pas de pouls BLE vers Android — HealthKit seulement sur iPhone';

  @override
  String get watchTipGalaxy =>
      'Seulement si la montre envoie Heart Rate 0x180D — sinon Samsung Health';

  @override
  String get watchTipUnknown => 'Heart Rate 0x180D doit être actif';

  @override
  String get watchNotePolarBrand => 'Polar / sangle';

  @override
  String get watchNotePolarLine =>
      'Mode capteur allumé. Pouls standard 0x180D — c\'est ça qu\'on couple.';

  @override
  String get watchNoteGarminLine =>
      'Envoyer la fréquence / broadcast dans les réglages de la montre.';

  @override
  String get watchNoteAppleLine =>
      'Pas de pouls BLE standard vers Android. Ne couple pas.';

  @override
  String get watchNoteGalaxyLine =>
      'Surtout Samsung Health. Seulement avec 0x180D visible.';

  @override
  String get watchPairLeadText =>
      'Pouls sur toi, pas sur le vélo. Seulement un vrai service Heart Rate 0x180D.';

  @override
  String get blePairAgain => 'Coupler à nouveau';

  @override
  String get bleRemoveDevice => 'Retirer l\'appareil';

  @override
  String get bleSemanticsPaired => 'Bluetooth couplé';

  @override
  String get bleSemanticsPair => 'Coupler Bluetooth';

  @override
  String get bleTooltipPair => 'Coupler moteur ou capteur';

  @override
  String get watchOtherWatch => 'Une autre montre';

  @override
  String get bikeCatMtbTrail => 'Trail VTT';

  @override
  String get bikeCatMtb => 'VTT';

  @override
  String get bikeCatEnduro => 'Enduro';

  @override
  String get bikeCatDh => 'Descente';

  @override
  String get bikeCatGravel => 'Gravel';

  @override
  String get bikeCatRoad => 'Vélo de route';

  @override
  String get bikeCatUrban => 'City';

  @override
  String get bikeCatCargo => 'Cargo';

  @override
  String get bikeCatFolding => 'Pliant';

  @override
  String get bikeCatKids => 'Enfant';

  @override
  String get bikeCatEmtb => 'VTTAE';

  @override
  String get bikeCatEtrekking => 'E-trekking';

  @override
  String get bikeCatHiking => 'À pied';

  @override
  String get bikeCatEgravel => 'E-gravel';

  @override
  String get bikeCatEcity => 'E-city';

  @override
  String get bikeCatEcargo => 'E-cargo';

  @override
  String get bikeCatEfolding => 'E-pliant';

  @override
  String get bikeCatEkids => 'E-enfant';

  @override
  String get bikeCatEroad => 'E-route';

  @override
  String get bikeBlurbMtbTrail => 'Singletrails et forêt';

  @override
  String get bikeBlurbMtb => 'Trails et sorties';

  @override
  String get bikeBlurbEnduro => 'Raide et technique';

  @override
  String get bikeBlurbDh => 'Bikepark et descente';

  @override
  String get bikeBlurbGravel => 'Gravier et distance';

  @override
  String get bikeBlurbRoad => 'Asphalte et rythme';

  @override
  String get bikeBlurbUrban => 'Quotidien et trajet';

  @override
  String get bikeBlurbCargo => 'Charge et quotidien';

  @override
  String get bikeBlurbFolding => 'Plier et emporter';

  @override
  String get bikeBlurbKids => 'Vélo enfant';

  @override
  String get bikeBlurbEmtb => 'Trail avec assistance';

  @override
  String get bikeBlurbEtrekking => 'Sorties avec assistance';

  @override
  String get bikeBlurbHiking => 'À pied';

  @override
  String get bikeBlurbMtbTrailFocus => 'Focus singletrail';

  @override
  String get onboardSportTrail => 'Trail';

  @override
  String sportsSummaryPrimary(String label) {
    return 'Principal : $label';
  }

  @override
  String sportsSummaryPrimaryAlso(String label, String list) {
    return 'Principal : $label · aussi $list';
  }

  @override
  String get seasonYearRound => 'Toute l\'année';

  @override
  String get seasonSpringSummer => 'Printemps–été';

  @override
  String get seasonAutumn => 'Automne';

  @override
  String get seasonWinter => 'Hiver';

  @override
  String get naeheInYourRegion => '~60 min dans ta région';

  @override
  String get naeheAroundYou => '~60 min autour de toi';

  @override
  String get sportTagTouring => 'Randonnée';

  @override
  String get sportTagEbike => 'VAE';

  @override
  String get overlayRheinNeckar => 'Rhin-Neckar / Heidelberg';

  @override
  String get overlaySchwarzwaldNord => 'Forêt-Noire sud';

  @override
  String get overlayBodensee => 'Lac de Constance';

  @override
  String get overlayStuttgart => 'Stuttgart / Neckar moyen';

  @override
  String get overlayMuenchen => 'Munich et alentours';

  @override
  String get overlayNuernberg => 'Nuremberg / Franconie';

  @override
  String get overlayFrankfurtRheinMain => 'Francfort Rhin-Main';

  @override
  String get overlayKoelnRhein => 'Cologne / Rhénanie';

  @override
  String get overlayHamburg => 'Hambourg et alentours';

  @override
  String get overlayBerlin => 'Berlin et Brandebourg';

  @override
  String get overlayDresdenElbland => 'Dresde / Elbland';

  @override
  String get overlayWien => 'Vienne et Wienerwald';

  @override
  String get overlaySalzburg => 'Salzbourg';

  @override
  String get overlayInnsbruck => 'Innsbruck / Tyrol';

  @override
  String get overlayZuerich => 'Zurich et alentours';

  @override
  String get overlayBern => 'Berne / Plateau suisse';

  @override
  String get overlayBasel => 'Bâle / Trois Frontières';

  @override
  String get overlayRuhrgebiet => 'Ruhr';

  @override
  String get overlayDuesseldorf => 'Düsseldorf / Rhin inférieur';

  @override
  String get overlayHannover => 'Hanovre / Leine';

  @override
  String get overlayLeipzig => 'Leipzig / Neuseenland';

  @override
  String get overlayFreiburg => 'Fribourg-en-Brisgau / Schauinsland';

  @override
  String get overlayKarlsruhe => 'Karlsruhe / Hardt';

  @override
  String get overlayAugsburg => 'Augsbourg / Lech';

  @override
  String get overlayKiel => 'Kiel / fjord';

  @override
  String get overlayRostock => 'Rostock / Warnow';

  @override
  String get overlayKassel => 'Cassel / Bergpark';

  @override
  String get overlayTrierMosel => 'Trèves / Moselle';

  @override
  String get overlayPfalz => 'Forêt palatine';

  @override
  String get overlaySauerland => 'Sauerland';

  @override
  String get overlayEifelTrails => 'Eifel';

  @override
  String get overlayHarz => 'Harz';

  @override
  String get overlayThueringerWald => 'Forêt de Thuringe';

  @override
  String get overlayBayerischerWald => 'Forêt bavaroise';

  @override
  String get overlayAllgaeu => 'Allgäu';

  @override
  String get overlayChiemgau => 'Chiemgau';

  @override
  String get overlaySaarbruecken => 'Sarrebruck';

  @override
  String get overlayMuenster => 'Münsterland';

  @override
  String get overlayAachen => 'Aix-la-Chapelle / Trois Frontières';

  @override
  String get overlayLuebeck => 'Lübeck / Trave';

  @override
  String get overlayBremen => 'Brême / Weser';

  @override
  String get overlayMagdeburg => 'Magdebourg / Elbe';

  @override
  String get overlayErfurt => 'Erfurt';

  @override
  String get overlayKoblenz => 'Coblence / Rhin-Moselle';

  @override
  String get overlayGraz => 'Graz / vallée de la Mur';

  @override
  String get overlayLinz => 'Linz / Danube';

  @override
  String get overlayKlagenfurt => 'Klagenfurt / Wörthersee';

  @override
  String get overlayVillach => 'Villach / Drave';

  @override
  String get overlayBregenz => 'Bregenz / Vorarlberg';

  @override
  String get overlayKitzbuehel => 'Kitzbühel / Wilder Kaiser';

  @override
  String get overlayGenf => 'Genève / Lac Léman';

  @override
  String get overlayLausanne => 'Lausanne / Lavaux';

  @override
  String get overlayLuzern => 'Lucerne / Lac des Quatre-Cantons';

  @override
  String get overlayStGallen => 'Saint-Gall / Appenzell';

  @override
  String get overlayLugano => 'Lugano / Tessin';

  @override
  String get overlayInterlaken => 'Interlaken / Oberland bernois';

  @override
  String get overlayChur => 'Coire / Grisons';

  @override
  String get overlayZermatt => 'Zermatt / Mattertal';

  @override
  String get overlayStMoritz => 'Saint-Moritz / Engadine';

  @override
  String get overlayDavos => 'Davos / Landwasser';

  @override
  String get overlayStrasbourg => 'Strasbourg / Ill';

  @override
  String get overlayAlsaceVins => 'Alsace / Route des Vins';

  @override
  String get overlayVosges => 'Vosges / Ballon d\'Alsace';

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
  String get overlayParis => 'Paris / Bois et Seine';

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
    return 'Carte (zoom $min–$max)…';
  }

  @override
  String offlineProgressMapPercent(String percent) {
    return 'Carte $percent %';
  }

  @override
  String get offlineProgressActivating => 'Activation…';

  @override
  String get offlineProgressManifest => 'Manifeste…';

  @override
  String offlineProgressPackFile(String file) {
    return 'Pack $file…';
  }

  @override
  String get offlineProgressGraphFile => 'offline_graph.json…';

  @override
  String get offlineProgressDemoGraph => 'Graphe démo (Forêt-Noire)…';

  @override
  String get offlinePacksReadyOne => '1 pack téléchargeable';

  @override
  String offlinePacksReadyCount(int count) {
    return '$count packs téléchargeables';
  }

  @override
  String offlinePackNotBuilt(String name) {
    return '$name : pack pas encore construit — pas de téléchargement.';
  }

  @override
  String offlineShaMismatch(String sha) {
    return 'SHA-256 ne correspond à aucun téléchargement (attendu $sha)';
  }

  @override
  String offlineInvalidGraphFolder(String id) {
    return 'Le dossier $id n\'a pas de graphe valable pour cette région';
  }

  @override
  String offlineNoRemotePack(String name) {
    return 'Pas de pack distant pour $name. Les stubs du catalogue n\'activent pas le graphe démo d\'une autre région.';
  }

  @override
  String get offlineDownloadEmpty => 'Téléchargement vide';

  @override
  String get offlineNoGraphAfterExtract => 'Pas de graphe après extract';

  @override
  String get offlineRawPmtiles =>
      'Un .pmtiles brut n\'est pas pris en charge — il faut un style JSON MapLibre avec une source pmtiles://.';

  @override
  String get offlineInvalidUrl => 'URL invalide';

  @override
  String get offlineExpectStyleJson =>
      'Attends une URL de style JSON (*.json ou /styles/…), pas un fichier de tuiles.';

  @override
  String get offlineSubActive => 'Actif — appuie pour mettre à jour';

  @override
  String get offlineSubInstalled => 'Installé — appuie pour activer';

  @override
  String get offlineSubDemoGraph =>
      'Graphe démo dans l\'app (pas de pack distant)';

  @override
  String get offlineSubNotBuilt => 'Pas encore construit';

  @override
  String get offlineSubLoad => 'Charger routage + carte';

  @override
  String offlineSubLoadSized(String size) {
    return '$size · routage + carte';
  }

  @override
  String offlineGraphMissing(String name) {
    return 'Pas de graphe dans $name';
  }

  @override
  String offlineGraphSha(String name) {
    return 'Le SHA du graphe de $name ne correspond pas';
  }

  @override
  String offlineGraphDemoMismatch(String name) {
    return 'Le graphe démo Forêt-Noire ne correspond pas à $name';
  }

  @override
  String get offlineEngineLinkedNoTiles =>
      'Moteur graphe · Valhalla lié, tuiles régionales encore absentes';

  @override
  String get offlineEngineTilesNotBuilt =>
      'Moteur graphe · tuiles Valhalla pas construites';

  @override
  String get offlineNoTiles => 'pas de tuiles';

  @override
  String get offlineFfiMissing =>
      'FFI manquant — graph-only / flag Valhalla non lié';

  @override
  String get offlineValhallaTilesLinked => 'Tuiles Valhalla · libvalhalla lié';

  @override
  String offlineValhallaTilesUnlinked(String code) {
    return 'Tuiles Valhalla · UNLINKED (code $code)';
  }

  @override
  String get offlineValhallaFeature => 'Fonction Valhalla disponible';

  @override
  String get offlineValhallaNotLinked => 'Valhalla non lié';

  @override
  String get garageMuscle => 'Muscle';

  @override
  String garageOemTaken(String name, int count) {
    return '$name : $count pièces d\'origine reprises.';
  }

  @override
  String garageOemTakenPartial(String name, int taken, int skipped) {
    return '$name : $taken pièces d\'origine, $skipped ignorées.';
  }

  @override
  String garageOemKitOff(String name) {
    return '$name rangé — ajoute les pièces toi-même, le kit était désactivé.';
  }

  @override
  String garageGpxSaved(String name, String km) {
    return '$name : GPX enregistré ($km km).';
  }

  @override
  String garageKmImported(String km) {
    return '+$km km importés';
  }

  @override
  String get garageLogOdoUpdated => 'Compteur mis à jour';

  @override
  String get garageLogHoursUpdated => 'Heures moteur mises à jour';

  @override
  String get garageLogGpxImport => 'GPX importé';

  @override
  String get garageLogImportPlaceholder => 'Import sans pièces';

  @override
  String garageLogManualKm(String km) {
    return 'Manuel : $km km';
  }

  @override
  String garageLogManualHours(String hours) {
    return 'Manuel : $hours h';
  }

  @override
  String garageLogPsiFront(String psi) {
    return 'avant $psi psi';
  }

  @override
  String garageLogPsiRear(String psi) {
    return 'arrière $psi psi';
  }

  @override
  String garageLogBarFront(String bar) {
    return 'avant $bar bar';
  }

  @override
  String garageLogBarRear(String bar) {
    return 'arrière $bar bar';
  }

  @override
  String get bikeCatEmtbTrail => 'Trail VTTAE';

  @override
  String get bikeCatEenduro => 'E-Enduro';

  @override
  String get bikeCatEdh => 'E-DH';

  @override
  String discoverCatalogTours(int count) {
    return 'Catalogue $count tours';
  }

  @override
  String discoverCatalogToursSuffix(int count) {
    return ' · Catalogue $count';
  }

  @override
  String discoverToursOsmStatus(int tours, int withTrack, int osm) {
    return 'Tours $tours ($withTrack avec trace) · OSM $osm';
  }

  @override
  String discoverElevationApprox(String hm) {
    return '~$hm hm (estimation distance — API d\'altitude injoignable)';
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
  String get demoCityMuenchen => 'Munich';

  @override
  String get demoCityKoeln => 'Cologne';

  @override
  String get demoCityZuerich => 'Zurich';

  @override
  String get demoCityWien => 'Vienne';

  @override
  String get demoCityKonstanz => 'Constance';

  @override
  String get demoCityParis => 'Paris';

  @override
  String get demoCityStrasbourg => 'Strasbourg';

  @override
  String get demoCityNice => 'Nice';

  @override
  String get postRideStravaConnect =>
      'Connecte Strava sous Données & confidentialité.';

  @override
  String get postRideStravaKeysMissing =>
      'Clés Strava manquantes — utilise GPX/FIT.';

  @override
  String get postRideStravaStatusDown =>
      'Statut Strava injoignable — utilise GPX/FIT.';

  @override
  String get postRideStravaHint =>
      'Strava : avec trace GPS via Uploads-API ; sans trace, seulement les métadonnées.';

  @override
  String postRideStravaError(String error) {
    return 'Strava : $error';
  }

  @override
  String get postRideHeatmapPrivate =>
      'Heatmap : tour privé — trace pas envoyée.';

  @override
  String postRideHeatmapError(String error) {
    return 'Heatmap : $error';
  }

  @override
  String get postRideSetupSaved => 'Version de setup enregistrée';

  @override
  String postRideSetupSaveFailed(String error) {
    return 'Enregistrement du setup raté : $error';
  }

  @override
  String get postRideGpxEmpty => 'Pas de trace GPS — GPX serait vide';

  @override
  String postRideGpxExportError(String error) {
    return 'Export GPX : $error';
  }

  @override
  String postRideFitExportError(String error) {
    return 'Export FIT : $error';
  }

  @override
  String get postRideShareGpx => 'Partager GPX';

  @override
  String get postRideSimActive => 'Trace sim était active';

  @override
  String postRideSimDistance(String km) {
    return ' (~$km km simulés)';
  }

  @override
  String get postRideSimUnreliable =>
      ' — distance/analyse peu fiables. Pour les vraies sorties, coupe AETHER_SIM_MOTION.';

  @override
  String get postRideAvgSpeedHigh =>
      'Vitesse moyenne trop haute — vérifie GPS/sim.';

  @override
  String get postRideSuggestionTaken => 'Reprise';

  @override
  String get postRideSuggestionAccept => 'Prendre la reco';

  @override
  String get postRideAssistEstimate => 'Assist (estimation)';

  @override
  String postRideAssistDominant(String mode, String wh) {
    return 'Dominant : $mode · ~$wh Wh';
  }

  @override
  String postRideAssistApproach(String mode) {
    return 'Estimation : $mode (approche)';
  }

  @override
  String postRideAssistClimb(String mode, String pct) {
    return 'Estimation : $mode (montée, $pct %)';
  }

  @override
  String postRideAssistRest(String mode) {
    return 'Estimation : $mode (reste)';
  }

  @override
  String get postRideAssistDisclaimer =>
      'Estimations d\'après signature puissance/vitesse — pas de lecture OEM. Pas de commande moteur (F-EBK-000).';

  @override
  String get postRideFeelTitle => 'Ça donnait quoi ?';

  @override
  String get postRideFrontSuspension => 'Suspension avant';

  @override
  String get postRideFrontTooSoft => 'trop molle';

  @override
  String get postRideBrakeDive => 'Plongée au freinage';

  @override
  String get postRideBrakeDives => 'plonge';

  @override
  String get postRideBrakeNeutral => 'neutre';

  @override
  String get postRideBrakeHarsh => 'dur';

  @override
  String get postRideSmallBumps => 'Petits chocs';

  @override
  String get postRideBumpsVague => 'flou';

  @override
  String get postRideSaveFeedback => 'Enregistrer le feedback';

  @override
  String get postRideShortRideMetrics =>
      'Sortie courte — métriques limitées (< 0,5 km).';

  @override
  String get postRideMetricsTitle => 'Métriques';

  @override
  String get postRideDefaultName => 'Sortie';

  @override
  String get platzCreateGroupHint =>
      'Choisis la tour, la visibilité, puis partage le lien.';

  @override
  String get platzGroupPublicHint =>
      'Qui a le lien peut rejoindre. Le groupe peut figurer sur le Platz sous Public.';

  @override
  String get platzGroupPrivateHint =>
      'Seul qui a le lien peut rejoindre. Pas de roster public.';

  @override
  String get platzNoPrivateGroups => 'Aucun groupe privé dans ce filtre.';

  @override
  String get platzMakePrivate => 'Passer en privé';

  @override
  String get platzMakePublic => 'Passer en public';

  @override
  String get platzNoPublicGroups => 'Aucun groupe public sur le serveur.';

  @override
  String get platzPublicGroupsHint =>
      'Groupes publics — rejoindre avec login, pas de GPS Explore.';

  @override
  String get platzListedPublic => 'public';

  @override
  String get filterVisibilityAll => 'Toutes';

  @override
  String get filterVisibilityPublic => 'Public';

  @override
  String get mappeTitle => 'Die Mappe';

  @override
  String get mappeSubtitle =>
      'Tes tours, Stimmen et groupes. Les mêmes que sur la carte.';

  @override
  String get mappeAddHint =>
      'Nom + départ — sans trace inventée. GPX en option en dessous.';

  @override
  String get mappePutIn => 'Mettre dans la Mappe';

  @override
  String mappeSaved(String name) {
    return 'Dans la Mappe : $name';
  }

  @override
  String mappeImported(String name) {
    return 'Importé : $name';
  }

  @override
  String get mappeEmpty => 'Pas encore de traces à toi — ajoute une route.';

  @override
  String get mappeStimmenEmpty =>
      'Pas encore de Stimmen sur tes tours. Après partage, les autres peuvent écrire.';

  @override
  String get myRoutesSourceOwn => 'Perso';

  @override
  String get privacyZoneTitle => 'Privacy-Zone';

  @override
  String get privacyZoneEdit => 'Ajuster la zone';

  @override
  String get privacyZoneInvalidCoords => 'Indique des coordonnées valides';

  @override
  String get privacyZoneNeedTap => 'Tape d\'abord la carte';

  @override
  String get privacyZoneTapShort => 'Tape la carte';

  @override
  String get retry => 'Réessayer';

  @override
  String get hofSystemStatus => 'État du système';

  @override
  String get hofSystemOk =>
      'Tout est connecté — atelier, sorties et sync tournent normalement.';

  @override
  String get hofSupabaseMissing => 'Supabase n\'est pas configuré';

  @override
  String get hofSupabaseMissingHint =>
      'Le cloud-sync n\'est pas en place — connexion et sync sont off.';

  @override
  String get hofSyncSessionExpired => 'Sync : session expirée';

  @override
  String get hofSyncLoginOnly => 'Sync seulement avec login';

  @override
  String get hofSyncLocalHint =>
      'Garage/Rides restent locaux — compte pour le cloud-sync.';

  @override
  String get hofSystemNotice => 'État du système — indice présent';

  @override
  String get hofSystemHint => 'État du système — indice';

  @override
  String get hofSystemOkTooltip => 'État du système : ok';

  @override
  String get hofTafelTitle => 'Die Tafel';

  @override
  String hofTafelVoiceOne(String name) {
    return 'Nouvelle Stimme sur $name';
  }

  @override
  String hofTafelVoices(int count, String name) {
    return '$count Stimmen sur $name';
  }

  @override
  String hofTafelGroup(String title) {
    return 'Groupe devant le portail · $title';
  }

  @override
  String ridePuckSemantics(String name) {
    return 'Navigation, $name';
  }

  @override
  String dieBoxSentenceHome(String name) {
    return '$name habite ici';
  }

  @override
  String get dieBoxLater => 'Plus tard';

  @override
  String dieBoxSentenceMtbReady(String name, String travel, String drive) {
    return '$name · $travel$drive · prêt';
  }

  @override
  String dieBoxSentenceReadyBits(String name, String bits) {
    return '$name · $bits · prêt';
  }
}
