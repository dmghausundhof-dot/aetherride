// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FlowLine';

  @override
  String get appTagline =>
      'Ride further. Flow better — MTB, gravel, road, city & e-bike.';

  @override
  String get navHome => 'Home';

  @override
  String get navGarage => 'Garage';

  @override
  String get navRide => 'Ride';

  @override
  String get navDiscover => 'Tours';

  @override
  String get navParts => 'Parts';

  @override
  String get navKarte => 'Map';

  @override
  String get navWorkshop => 'Workshop';

  @override
  String get navShop => 'Shop';

  @override
  String get navPlatz => 'Platz';

  @override
  String navTabOf(int index, int count) {
    return 'Tab $index of $count';
  }

  @override
  String get hofJustRide => 'Just ride';

  @override
  String get hofShowTours => 'Show tours';

  @override
  String get hofMapChoiceHint =>
      'Ride without a route, or show tours on the map.';

  @override
  String get werkstattPartsShelf => 'Shop';

  @override
  String get werkstattForYourBike => 'For your bike';

  @override
  String get werkstattMerch => 'Merchandise';

  @override
  String get werkstattShopParts => 'Spare parts in the shop';

  @override
  String get werkstattPartsForBike => 'Parts for your bike';

  @override
  String get shopLookupInShop => 'Look up in the shop';

  @override
  String get shopGatewayKicker => 'Across the yard';

  @override
  String get shopGatewayTitle => 'The shop';

  @override
  String get shopGatewayHint =>
      'The bike does not live here. FlowLine shows honest parts — checkout on Shopify, not in the app.';

  @override
  String get shopZumShop => 'Open shop';

  @override
  String shopForYourBikeHint(String name) {
    return 'Parts that fit $name — category and wheel size. No invented SKUs.';
  }

  @override
  String get shopForYourBikeEmpty =>
      'Park a bike in the workshop — then we open matching parts in the shop.';

  @override
  String get shopMerchHint =>
      'Apparel and small goods. Never filtered by bike fit.';

  @override
  String get shopMerchTitle => 'Apparel';

  @override
  String get shopMerchEmpty =>
      'No merch on the shelf. Apparel stays in the shop, never filtered by bike.';

  @override
  String get shopNotConnected => 'Shop not connected';

  @override
  String get shopNotConnectedHint =>
      'No storefront URL. Set SHOPIFY_STOREFRONT_URL, then the workshop opens the store.';

  @override
  String get shopOpenFailed => 'Could not open the shop.';

  @override
  String get shopPasswordWall =>
      'The shop outside is not public yet — a password may appear. The shelf here stays.';

  @override
  String get shopLockedTitle => 'Shop still closed outside';

  @override
  String get shopPasswordConfirm => 'Open anyway';

  @override
  String get shopPasswordCancel => 'Back';

  @override
  String get shopCyclingParts => 'Parts';

  @override
  String get shopSearchHint => 'Parts, brands, sizes…';

  @override
  String get shopFeatured => 'Matching parts';

  @override
  String get shopOpenProduct => 'Open in shop';

  @override
  String get shopAllParts => 'All parts';

  @override
  String shopFitBanner(String name) {
    return 'Parts that fit $name';
  }

  @override
  String get shopShelfEmpty => 'No parts match this search.';

  @override
  String get shopCatalogEmpty =>
      'No parts on the shelf yet. The shop door still opens Shopify.';

  @override
  String get shopFitOnly => 'Matching only';

  @override
  String get shopFitAllBikes => 'All bikes';

  @override
  String get shopFitBannerAll => 'Parts that fit your bikes';

  @override
  String get shopOpenInBrowser => 'Open in browser';

  @override
  String get shopZumHaendler => 'To the dealer';

  @override
  String get shopOpenInApp => 'View in the shop';

  @override
  String get shopProductMissing => 'This product is not in the shop.';

  @override
  String get shopCatalogFailed =>
      'Catalog is unreachable right now. The shop door still opens Shopify.';

  @override
  String get shopRetry => 'Try again';

  @override
  String get shopSheetCheckout => 'Checkout on Shopify, not in FlowLine.';

  @override
  String get shopDetails => 'Details';

  @override
  String get shopFeaturedBikes => 'Bikes in the shop';

  @override
  String get garageSetupTabHintTires =>
      'Rough tire pressure by weight — measure on the bike, not an OEM chart.';

  @override
  String get werkstattSetupTires => 'Tires / rough pressure';

  @override
  String get werkstattSetupSuspension => 'Suspension — sag and air from travel';

  @override
  String get werkstattSetupSuspensionUnknown =>
      'Suspension — travel not logged';

  @override
  String get werkstattSetupDropper => 'Dropper (logged)';

  @override
  String werkstattSetupWheel(String size) {
    return 'Wheels $size';
  }

  @override
  String get werkstattSetupCockpit => 'Cockpit — bar and stem';

  @override
  String get werkstattSetupBagsCockpit => 'Bags / cockpit';

  @override
  String get werkstattSetupLightsRack => 'Lights and rack — only if logged';

  @override
  String get werkstattSetupDrivetrain => 'Drivetrain';

  @override
  String get werkstattBatteryHonest => 'Battery only with a real sensor';

  @override
  String get werkstattBatteryHonestHint =>
      'No percentage without a paired sensor. Bosch LDI stays G-1.';

  @override
  String get werkstattSensorEbike =>
      'Wheel sensor (CSC) — speed and cadence. Battery only with a real sensor.';

  @override
  String get werkstattSensorAnalog =>
      'Wheel sensor — speed and cadence on the bike.';

  @override
  String get hofYourWatch => 'Your watch';

  @override
  String get hofWatchHint => 'Heart rate from a real sensor.';

  @override
  String get hofWatchPair => 'Pair watch';

  @override
  String get hofWatchReconnect => 'Connect';

  @override
  String get hofWatchRemove => 'Remove';

  @override
  String get hofWatchConnect => 'Connect watch';

  @override
  String get hofYou => 'You';

  @override
  String get hofYouSheetHint =>
      'You and your watch. The wheel sensor stays on the bike in the workshop.';

  @override
  String get werkstattWatchEbike =>
      'Watch — heart rate next to CSC. No invented SoC.';

  @override
  String get werkstattWatchAnalog => 'Smartwatch / fitness tracking';

  @override
  String get setupTirePressureLabel => 'Front tire (psi)';

  @override
  String get setupCompareHintTires =>
      'Creates two blind tire pressures. After a few rides you’ll see which feels better.';

  @override
  String setupTirePressureValue(String value) {
    return 'Tires $value psi';
  }

  @override
  String get searchHome => 'Where to? Place, tour or address';

  @override
  String get startRide => 'Start ride';

  @override
  String get startFreeride => 'Ride without a route';

  @override
  String get startWithRoute => 'Ride route';

  @override
  String get goRide => 'Let\'s ride';

  @override
  String get readyTitle => 'Ready to ride';

  @override
  String get readyMessage =>
      'GPS tracking starts right away. Sensors and route are optional — trail, pavement or city.';

  @override
  String get optionalRoute =>
      'Optional: pick a route under Tours and tap “Let\'s ride”.';

  @override
  String get starting => 'Starting…';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get reset => 'Reset';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get discoverMenuPhotos => 'Nearby photos';

  @override
  String get discoverMenuOffline => 'Offline maps';

  @override
  String get discoverMenuCollections => 'Collections';

  @override
  String get discoverMenuPrivacy => 'Heatmap & privacy';

  @override
  String get partsTitle => 'Parts & gear';

  @override
  String get partsSubtitle =>
      'Live featured parts in FlowLine — soft-fit & prices, no Shopify password dead-end.';

  @override
  String get weatherFallback => 'Weather unavailable';

  @override
  String get weatherLoading => 'Loading weather…';

  @override
  String get statsRidesOne => 'ride';

  @override
  String get statsRidesMany => 'rides';

  @override
  String get profile => 'Profile';

  @override
  String get chat => 'Chat';

  @override
  String get hofRideOut => 'Ride out';

  @override
  String get hofOpenBike => 'Open bike';

  @override
  String get hofParkBike => 'Park the bike';

  @override
  String get hofRideWithoutBike => 'Ride without a bike';

  @override
  String get hofRideOutAgain => 'Ride out again';

  @override
  String get hofAtGate => 'at the gate';

  @override
  String get hofEmptyStand => 'Empty stand';

  @override
  String get hofSkyUnknown => 'Sky unknown';

  @override
  String get hofNoHonestLoop => 'No honest trail loop';

  @override
  String get hofGateWetClosed => 'Trails wet — no honest paved loop nearby';

  @override
  String get hofNotYetOut => 'not out yet';

  @override
  String get hofJustBack => 'just back';

  @override
  String hofAgoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String hofAgoHours(int hours) {
    return '$hours h ago';
  }

  @override
  String get hofWhatCameIn => 'What came in';

  @override
  String hofPackMissing(String name) {
    return 'No pack for $name';
  }

  @override
  String get hofLastRideNoGps => 'no GPS track — nothing invented';

  @override
  String get hofGpsUnknown => 'No location — sky and gate wait for GPS.';

  @override
  String get rideGpsUnavailable =>
      'No GPS — track stays empty. Nothing invented.';

  @override
  String get hofAtHof => 'at the stand';

  @override
  String hofGarageType(String type) {
    return 'Type $type';
  }

  @override
  String get hofSinceOneDay => '1 day';

  @override
  String hofSinceDays(int days) {
    return '$days days';
  }

  @override
  String get hofNoBikeHere => 'No bike here';

  @override
  String hofBringForward(String name) {
    return 'Bring $name forward';
  }

  @override
  String hofCareInWorkshop(String label) {
    return '$label — in the workshop';
  }

  @override
  String get hofSensorAwake => 'Sensor awake';

  @override
  String get hofOpenTours => 'Open tours';

  @override
  String hofSkyDry(String temp) {
    return '$temp° · rather dry';
  }

  @override
  String hofSkyDamp(String temp) {
    return '$temp° · damp possible';
  }

  @override
  String hofSkyWet(String temp) {
    return '$temp° · rain · trails likely wet';
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
  String get hofGateAwayNear => 'under 1 km';

  @override
  String hofCommunityNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes on this loop',
      one: '1 note on this loop',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMtb => 'Trails, tours & your setup';

  @override
  String get homeSubtitleGravel => 'Gravel, distance & navigation';

  @override
  String get homeSubtitleRoad => 'Pavement, pace & training';

  @override
  String get homeSubtitleUrban => 'Commute, city & everyday';

  @override
  String get homeSubtitleEbike => 'Assist, range & tours';

  @override
  String get homeSubtitleDefault => 'Any way you ride — your bike, your route';

  @override
  String homeSubtitleWithWeather(String weather, String base) {
    return '$weather · $base';
  }

  @override
  String get tipHeroTitleMtb => 'Get out on the bike today';

  @override
  String get tipHeroTitleGravel => 'Gravel or mixed today';

  @override
  String get tipHeroTitleRoad => 'Pavement miles today';

  @override
  String get tipHeroTitleUrban => 'Through the city today';

  @override
  String get tipHeroTitleEbike => 'Ride with assist today';

  @override
  String get tipHeroTitleDefault => 'A ride fits today';

  @override
  String get tipHeroSubtitleMtb =>
      'Pick a route or freeride — track stays local.';

  @override
  String get tipHeroSubtitleGravel =>
      'Plan a distance or start without a route.';

  @override
  String get tipHeroSubtitleRoad => 'Build a loop or log free training.';

  @override
  String get tipHeroSubtitleUrban => 'Track a commute or save a short loop.';

  @override
  String get tipHeroSubtitleEbike => 'Plan a tour and keep range in view.';

  @override
  String get tipHeroSubtitleDefault => 'MTB, gravel, road or city — all here.';

  @override
  String get chassisLayer => 'Suspension';

  @override
  String get sensorLayer => 'Sensors';

  @override
  String get filter => 'Filter';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterResetFilters => 'Reset filters';

  @override
  String get filterDurationLens => 'Duration';

  @override
  String get filterSurfaceGroup => 'Surface';

  @override
  String get filterExertion => 'Difficulty';

  @override
  String get filterDistance => 'Distance';

  @override
  String get filterElevation => 'Elevation';

  @override
  String get filterForm => 'Shape';

  @override
  String get filterFormAll => 'All';

  @override
  String get filterFormPointToPoint => 'A→B';

  @override
  String get filterFormPointToPointTooltip =>
      'Stages and linear trails (start≠end).';

  @override
  String get filterFormDownhill => 'Downhill';

  @override
  String get filterFormDownhillTooltip =>
      'Descents, bike park, enduro A→B. Loops are not auto-DH.';

  @override
  String get filterBikeType => 'Bike type';

  @override
  String get filterBikeTypeHonesty =>
      'Colors filter the tours. Navigation: one bike route, except walking.';

  @override
  String get filterSingletrail => 'Singletrack (S-scale)';

  @override
  String get filterSingletrailHint =>
      'Only tours/ways with an honest grade. No tag: no matches.';

  @override
  String get filterNoDownhillTours => 'No downhill tours nearby';

  @override
  String get filterNoDownhillToursHint =>
      'OSM trails by S-grade stay on the map. No DH round in the catalog here.';

  @override
  String get filterNoScaleTours => 'No tour with this S-grade';

  @override
  String get filterTrailNetwork => 'Trail network (map)';

  @override
  String get filterLoopsOnly => 'Loop';

  @override
  String get filterLoopsOnlyTooltip =>
      'Loops only — start and end are the same.';

  @override
  String get filterNetworkOn => 'Ways on the map';

  @override
  String get filterNetworkOff => 'Hide ways';

  @override
  String filterOsmScaleTooltip(String code) {
    return 'OSM scale: $code';
  }

  @override
  String filterShowTours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count tours',
      one: 'Show 1 tour',
    );
    return '$_temp0';
  }

  @override
  String get filterNoTours => 'No tours match these filters.';

  @override
  String get filterNoToursHint => 'No tours — tap “New” or loosen filters.';

  @override
  String get loopLabel => 'Loop';

  @override
  String get computeRoute => 'Compute route';

  @override
  String get adaptTour => 'Edit';

  @override
  String get adaptTourTitle => 'Edit tour';

  @override
  String get adaptTourHint =>
      'Change start, end or stops — then compute the route.';

  @override
  String get planRouteTitle => 'Plan route';

  @override
  String get planRouteCta => 'Navigate';

  @override
  String get discoverSearchHint => 'Place or tour';

  @override
  String filterAroundKm(int km) {
    return 'within $km km';
  }

  @override
  String get mapToggleFab => 'Map';

  @override
  String get communityWriteReview => 'Write a review';

  @override
  String get discoverModeExplore => 'Explore';

  @override
  String get discoverModeNavigate => 'Navigate';

  @override
  String get discoverModeMine => 'Mine';

  @override
  String get navigateTitle => 'Navigate';

  @override
  String get navigateSubtitle => 'Tap destination or type an address';

  @override
  String get navigateStartLabel => 'Start';

  @override
  String get navigateEndLabel => 'Destination';

  @override
  String get navigateStartHint => 'Address, place, or tap map';

  @override
  String get navigateEndHint => 'Where to?';

  @override
  String get navigateMyLocation => 'My location';

  @override
  String get navigateSwap => 'Swap start and destination';

  @override
  String get navigatePickStart => 'Tap start on map';

  @override
  String get navigatePickEnd => 'Tap destination on map';

  @override
  String get navigateAddVia => 'Add stop';

  @override
  String get navigateNeedStartEnd => 'Set start and destination';

  @override
  String get navigateComputeNeedBoth =>
      'Compute route (need start & destination)';

  @override
  String get navigateBackToExplore => 'Back to Explore';

  @override
  String get mineSheetHint => 'Your recordings, imports and saved routes';

  @override
  String get mineEmptyCtaNavigate => 'Plan A to B';

  @override
  String get gpxImportAction => 'Import GPX';

  @override
  String get exploreOpenNavigate => 'A→B navigate';

  @override
  String get sheetDragHandleMine => 'Drag my-routes sheet';

  @override
  String get sheetDragHandleNavigate => 'Drag navigation sheet';

  @override
  String get browseMap => 'Map';

  @override
  String get browseList => 'List';

  @override
  String get quickFilter1h => '1 hr';

  @override
  String get sheetDragHandle => 'Drag tours sheet';

  @override
  String get sheetPeekHint => 'Pull up — tours & filters';

  @override
  String get rideBarCollapseHint => 'Swipe down to collapse';

  @override
  String get rideBarExpandHint => 'Open';

  @override
  String get rideBarStart => 'Start';

  @override
  String get rideBarRoute => 'Route';

  @override
  String get rideBarPointToPoint => 'Route';

  @override
  String get emptyToursTitle => 'No tours found';

  @override
  String get emptyToursFiltersBody =>
      'Reset filters to see nearby tours again.';

  @override
  String get emptyToursNearbyBody =>
      'Change place or duration — or reset filters.';

  @override
  String get showOnMap => 'Show on map';

  @override
  String get tourDetails => 'Details';

  @override
  String get moreFilters => 'More filters';

  @override
  String get moreActions => 'More actions';

  @override
  String get filterSurfaceAsphalt => 'Pavement';

  @override
  String get filterSurfaceGravel => 'Gravel';

  @override
  String get filterSurfaceTrail => 'Trail';

  @override
  String get filterSurfaceMixed => 'Mixed';

  @override
  String get filterSurfaceAsphaltHint => 'Pavement · bike lane · paved';

  @override
  String get filterSurfaceGravelHint => 'Gravel · forest · compacted';

  @override
  String get filterSurfaceTrailHint => 'Natural · singletrack · roots';

  @override
  String get filterSurfaceMixedHint => 'Urban · mixed surface';

  @override
  String get filterSurfaceAsphaltFull => 'Pavement · paved';

  @override
  String get filterSurfaceGravelFull => 'Gravel · compacted';

  @override
  String get filterSurfaceTrailFull => 'Natural · trail';

  @override
  String get filterSurfaceMixedFull => 'Urban · mixed';

  @override
  String get filterEffortEasy => 'Easy';

  @override
  String get filterEffortMid => 'Moderate';

  @override
  String get filterEffortHard => 'Challenging';

  @override
  String get filterEffortEasyHint => 'S0 / relaxed / low tech';

  @override
  String get filterEffortMidHint => 'S1–S2 / sporty / mixed';

  @override
  String get filterEffortHardHint => 'S2+ / hard / technical';

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
  String get filterScaleEasy => 'Easy';

  @override
  String get filterScaleMedium => 'Moderate';

  @override
  String get filterScaleHard => 'Challenging';

  @override
  String get trailDiffEasy => 'Easy';

  @override
  String get trailDiffMedium => 'Moderate';

  @override
  String get trailDiffHard => 'Hard';

  @override
  String get trailDiffVeryHard => 'Very hard';

  @override
  String get trailDiffUnrated => 'Unrated';

  @override
  String get trailDiffOpen => 'open';

  @override
  String get durationAny => 'any';

  @override
  String get duration2to3h => '2–3 h';

  @override
  String get garageTitle => 'Garage';

  @override
  String get garageFabBike => 'Add a bike';

  @override
  String get garageEmptyTitle => 'No bike here yet';

  @override
  String get garageEmptyMessage =>
      'Name and type are enough. Catalog is search — take the kit only if you want it.';

  @override
  String get garageAddBike => 'Add a bike';

  @override
  String get garageAddAnother => 'Another bike';

  @override
  String get garageStatBike => 'BIKE';

  @override
  String get garageStatBikes => 'BIKES';

  @override
  String get garageStatKmTotal => 'KM TOTAL';

  @override
  String get garageQuickSwitch => 'Quick switch';

  @override
  String get garageLastRides => 'Recent rides';

  @override
  String get garageNoRidesTitle => 'No rides yet';

  @override
  String get garageNoRidesMessage => 'Your first saved ride will show up here.';

  @override
  String get garageActive => 'Active';

  @override
  String garageActiveBike(String name) {
    return 'Active bike · $name';
  }

  @override
  String get garageEbikeBadge => 'E-bike';

  @override
  String get garageMaintOk => 'All good';

  @override
  String garageMaintDue(int count) {
    return '$count due for service';
  }

  @override
  String garageMaintOverdue(int count) {
    return '$count overdue';
  }

  @override
  String garagePartsCount(int count) {
    return '$count parts';
  }

  @override
  String get garageParts => 'Parts';

  @override
  String get garageMaintenance => 'Maintenance';

  @override
  String get garageSetup => 'Setup';

  @override
  String get garageInstall => 'Add part';

  @override
  String get garageOtherBikes => 'Other bikes';

  @override
  String get garageTechDetails => 'Technical details';

  @override
  String get garageTechHint => 'Travel, frame, setup basics — for enthusiasts';

  @override
  String get garageCtaMaintenance => 'View maintenance';

  @override
  String get garageCtaAddPart => 'Add part';

  @override
  String get garageCtaSetActive => 'Set as active';

  @override
  String get garageCtaOpenSetup => 'Go to setup';

  @override
  String get garageHours => 'Hours';

  @override
  String get garageTravel => 'Travel';

  @override
  String get garageFrameSize => 'Frame size';

  @override
  String get garageWheelSize => 'Wheel size';

  @override
  String get garageBrandModel => 'Model';

  @override
  String garageCompatFits(int count) {
    return 'Fits $count';
  }

  @override
  String garageCompatCheck(int count) {
    return 'Check $count';
  }

  @override
  String garageCompatNoFit(int count) {
    return 'No fit $count';
  }

  @override
  String get garagePartsEmpty =>
      'No parts logged yet. Tap “Add part” — then we remind you about service and show whether parts fit together.';

  @override
  String get garageMaintEmpty => 'All good — nothing due for service.';

  @override
  String get garageSetupTabTitle => 'Your setup';

  @override
  String get garageSetupTabHint =>
      'SAG = how far the suspension sinks with your weight (often ~25–30%).';

  @override
  String get garageYourParts => 'Your parts';

  @override
  String get garageMissingSlots => 'Not logged yet (optional)';

  @override
  String get garageActiveBadge => 'Active bike';

  @override
  String get garageStatKm => 'KM';

  @override
  String get garageStatHours => 'HRS';

  @override
  String get garageStatMaint => 'SERVICE';

  @override
  String get setupVersionsTitle => 'Versions & compare';

  @override
  String get setupVersionsHint =>
      'Each change saves a new version. You can switch back anytime.';

  @override
  String get setupRiderWeightLabel => 'Rider weight (kg) for templates';

  @override
  String get setupNewVersionCta => 'New version';

  @override
  String get setupCompareCta => 'Try two variants';

  @override
  String get setupCompareHint =>
      'Creates two blind variants (e.g. rebound). After a few rides you’ll see which feels better.';

  @override
  String get setupSavedVersions => 'Saved versions';

  @override
  String get setupEmpty =>
      'No versions yet — start from a template or save your settings.';

  @override
  String get setupActiveBadge => 'Active';

  @override
  String setupVersionMeta(int version) {
    return 'Version $version';
  }

  @override
  String get setupUseVersion => 'Use';

  @override
  String setupForkReboundValue(String value) {
    return 'Rebound $value';
  }

  @override
  String get setupSourceTemplate => 'Template';

  @override
  String get setupSourceBaseline => 'Baseline';

  @override
  String get setupSourceManual => 'Manual';

  @override
  String get setupTemplatesTitle => 'Starter templates';

  @override
  String get setupTemplatesHint =>
      'Starting point — not a personal recommendation.';

  @override
  String get setupApplyTemplate => 'Apply';

  @override
  String get setupNewVersionTitle => 'New setup version';

  @override
  String get setupNewVersionHint =>
      'Give it a name you’ll recognize — e.g. “Dry trail”.';

  @override
  String get setupVersionNameLabel => 'Name';

  @override
  String get setupForkReboundLabel => 'Fork rebound (clicks)';

  @override
  String get setupCancel => 'Cancel';

  @override
  String get setupSave => 'Save';

  @override
  String setupNewVersionDefaultName(int n) {
    return 'Version $n';
  }

  @override
  String get setupManualFallback => 'Manual';

  @override
  String setupTemplateAppliedLabel(String label) {
    return '$label (template)';
  }

  @override
  String setupTemplateAppliedSnack(String disclaimer) {
    return 'Template applied — $disclaimer';
  }

  @override
  String get setupCompareVariantA => 'Test variant A';

  @override
  String get setupCompareVariantB => 'Test variant B';

  @override
  String setupCompareResultFromRides(int count, String summary) {
    return 'Variants created · result from $count rides: $summary';
  }

  @override
  String setupCompareResultDemo(String summary) {
    return 'Variants created · little ride feedback yet — sample result: $summary';
  }

  @override
  String get rideMap => 'Map';

  @override
  String get rideData => 'Data';

  @override
  String get rideLiveData => 'Live data';

  @override
  String get rideMapReady =>
      'Map is ready. Sensor after you start, if you want.';

  @override
  String get rideClearRoute => 'Remove route';

  @override
  String get postRideTitle => 'Activity';

  @override
  String get postRideFreeride => 'Freeride';

  @override
  String get postRideTrackMap => 'Ridden track';

  @override
  String get postRideNoTrack => 'No GPS track — map has nothing to show.';

  @override
  String get postRideStatDistance => 'Distance';

  @override
  String get postRideStatDuration => 'Duration';

  @override
  String get postRideStatPace => 'Pace';

  @override
  String get postRideStatElevation => 'Elevation';

  @override
  String get postRideWeatherTitle => 'Weather';

  @override
  String get postRideWeatherStart => 'Start';

  @override
  String get postRideWeatherEnd => 'End';

  @override
  String get postRideWeatherUnavailable => 'Weather unavailable';

  @override
  String get postRidePhotosTitle => 'Photos';

  @override
  String get postRidePhotosHint => 'Add photos to this ride — stored locally.';

  @override
  String get postRidePhotoCamera => 'Camera';

  @override
  String get postRidePhotoGallery => 'Gallery';

  @override
  String get postRidePhotosShare => 'Share';

  @override
  String get postRidePhotosShareText => 'My FlowLine ride';

  @override
  String get postRidePhotosEmpty => 'No photos to share yet';

  @override
  String postRidePhotosMax(int count) {
    return 'Maximum $count photos';
  }

  @override
  String get postRideCommunityStub =>
      'Photos stay local. Voices live on the tour — not in a feed.';

  @override
  String get postRideOpenTour => 'Open tour';

  @override
  String get postRideSaveAsTour => 'Save as tour';

  @override
  String get postRideSaveAsTourDone => 'Saved to My routes';

  @override
  String get postRideSaveAsTourNeedTrack => 'A GPS track is required to save.';

  @override
  String get postRideSaveAsTourHint =>
      'Saves the track as your own route — visible under Tours.';

  @override
  String get myRoutesTitle => 'My routes';

  @override
  String get myRoutesEmpty => 'No routes yet — import GPX or record a ride.';

  @override
  String get myRoutesSourceImport => 'Import';

  @override
  String get myRoutesSourceRecorded => 'Recorded';

  @override
  String get myRoutesSourceEngine => 'Planned';

  @override
  String get myRoutesShowOnMap => 'Own on map';

  @override
  String get myRoutesHideOnMap => 'Hide own';

  @override
  String get myRouteNotesTitle => 'Private note';

  @override
  String get myRouteNotesHint =>
      'Just for you. Public voices only after you share — under Voices.';

  @override
  String get myRouteNotesEmpty => 'No note yet.';

  @override
  String get myRouteNotesPlaceholder => 'Just for you — not a voice.';

  @override
  String get myRouteNotesAdd => 'Save';

  @override
  String get myRouteDetailPhotos => 'Photos';

  @override
  String get myRouteOpenDetail => 'Details';

  @override
  String collectionRouteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routes · tap to open',
      one: '1 route · tap to open',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get account => 'Account';

  @override
  String get register => 'Register';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get done => 'Done';

  @override
  String get authSignedInSyncing => 'Signed in — syncing…';

  @override
  String authSignedInSyncFailed(String error) {
    return 'Signed in. Sync: $error';
  }

  @override
  String get authCloudUnavailable => 'Cloud sync is unavailable right now.';

  @override
  String get authEmailPasswordRequired =>
      'Email and password (min. 8 characters) required.';

  @override
  String get authAccountCreatedConfirm =>
      'Account created — confirm email if needed, then sign in.';

  @override
  String get authSupabaseMissing => 'Supabase is not configured.';

  @override
  String get authBrowserOpened =>
      'Browser opened — you’ll return here after signing in.';

  @override
  String get authDeleteTitle => 'Delete account?';

  @override
  String get authDeleteBody =>
      'Remote account and local app data will be deleted. Export GPX/JSON under Data & privacy first.';

  @override
  String get authRemoteDeleted => 'Remote account deleted.';

  @override
  String get authRemoteUnavailable =>
      'Remote delete unavailable — local data removed only.';

  @override
  String authRemoteFailed(int code) {
    return 'Remote delete failed ($code) — local data still deleted.';
  }

  @override
  String get authRemoteUnreachable =>
      'Server unreachable — local data removed only.';

  @override
  String get authLocalDeleted =>
      'Local data deleted. Export under Privacy if you still need a copy.';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Email address';

  @override
  String get authPassword => 'Password';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNewHere => 'New here? Register';

  @override
  String get authWithGoogle => 'Continue with Google';

  @override
  String get authWithApple => 'Continue with Apple';

  @override
  String get authPrivacy => 'Data & privacy';

  @override
  String get authOpenAssistant => 'Open assistant';

  @override
  String get authDeleteAccount => 'Delete account';

  @override
  String get authSyncNow => 'Sync now';

  @override
  String get authSyncing => 'Syncing…';

  @override
  String get authSyncOk => 'Sync OK';

  @override
  String authSyncActive(String api) {
    return 'Sync with $api is active.';
  }

  @override
  String get authCreating => 'Creating…';

  @override
  String get authSigningIn => 'Signing in…';

  @override
  String get billingTitle => 'FlowLine Pro';

  @override
  String get billingYouHavePro => 'You have Pro.';

  @override
  String get billingFreeToPro => 'Free → Pro';

  @override
  String get billingMoreBikes => 'More bikes, sync perks, and offline regions.';

  @override
  String get billingAlreadyPro =>
      'Pro is already active — no need to buy again.';

  @override
  String get billingForceProDebug =>
      'Debug: Force-Pro. Stripe/Play stay hidden.';

  @override
  String get billingStripeMonth => 'Stripe — monthly';

  @override
  String get billingStripeYear => 'Stripe — yearly';

  @override
  String get billingPlayMonth => 'Google Play — monthly';

  @override
  String get billingPlayRestore => 'Restore Play purchases';

  @override
  String get billingPlayHint =>
      'Note: without GOOGLE_PLAY_SERVICE_ACCOUNT_JSON the server cannot verify purchases against Google.';

  @override
  String get billingSyncStatus => 'Sync subscription status';

  @override
  String get billingSyncAfterPurchase => 'Sync after purchase';

  @override
  String get billingPleaseSignIn => 'Please sign in first.';

  @override
  String get billingNoCheckoutUrl => 'No checkout URL';

  @override
  String get billingBrowserFailed => 'Could not open the browser';

  @override
  String get billingCheckoutOpened =>
      'Checkout opened — then tap “Sync after purchase”.';

  @override
  String get billingPlayOnlyAndroid => 'Play Billing is Android only.';

  @override
  String get billingPlayStarted => 'Play purchase started…';

  @override
  String get billingVerifying => 'Verifying purchase…';

  @override
  String get billingProTrusted =>
      'Pro set (trusted-token MVP — no Google Play service account). Sync OK.';

  @override
  String get billingProActive => 'Pro active. Syncing.';

  @override
  String get billingRestoring => 'Restoring purchases…';

  @override
  String get billingRestoreStarted =>
      'Restore started — valid subscriptions will be verified.';

  @override
  String billingSyncOkTier(String tier) {
    return 'Sync OK — plan: $tier';
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
  String get chatAssistant => 'Assistant';

  @override
  String get chatWelcome =>
      'Ask what’s due — or about setup, routes, and parts.';

  @override
  String get chatEmptyTitle => 'Ask me';

  @override
  String get chatEmptyMessage =>
      'What’s due, setup, routes, or parts — try a suggestion above or type away.';

  @override
  String get chatLockedRiding => 'Chat is locked while riding.';

  @override
  String get chatHint => 'Message…';

  @override
  String get chatHintLocked => 'Locked during the ride';

  @override
  String get chatAsk => 'Ask';

  @override
  String get chatSnooze7 => 'Quiet for 7 days';

  @override
  String get chatNoAnswer => 'No answer.';

  @override
  String get chatUnavailable =>
      'The assistant is unavailable right now. Try again later.';

  @override
  String chatNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String chatErrorStatus(int code) {
    return 'Error $code';
  }

  @override
  String get chatLimitReached => 'Limit reached.';

  @override
  String chatQuota(String used, String limit, String remaining) {
    return 'Quota: $used / $limit · $remaining left';
  }

  @override
  String get chatToolDev => 'Tool (developer)';

  @override
  String get chatToolAuto => 'Auto';

  @override
  String get chatPromptWatch => 'What’s due?';

  @override
  String get chatPromptWatchQuery => 'What’s due?';

  @override
  String get chatPromptGarage => 'Garage';

  @override
  String get chatPromptGarageQuery => 'What’s in my garage?';

  @override
  String get chatPromptRange => 'Range';

  @override
  String get chatPromptRangeQuery =>
      'What range do I have with the current battery?';

  @override
  String get chatPromptSetups => 'Setups';

  @override
  String get chatPromptSetupsQuery =>
      'Which setups have I used, and what changed?';

  @override
  String get chatPromptRides => 'Rides';

  @override
  String get chatPromptRidesQuery => 'Summary of my recent rides';

  @override
  String get chatPromptRoutes => 'Routes';

  @override
  String get chatPromptRoutesQuery => 'Which routes fit me?';

  @override
  String get chatPromptShop => 'Shop';

  @override
  String get chatPromptShopQuery => 'Will I need wear parts soon?';

  @override
  String get chatToolWatch => 'What’s due';

  @override
  String get chatToolGarage => 'Workshop';

  @override
  String get chatToolCompat => 'Compatibility';

  @override
  String get chatToolRange => 'Range';

  @override
  String get chatToolSetupHistory => 'Setup history';

  @override
  String get chatToolRides => 'Rides';

  @override
  String get chatToolRoutes => 'Routes';

  @override
  String get chatToolShop => 'Shop';

  @override
  String get chatSubtitleDue => 'What’s due, setup, routes, parts';

  @override
  String coachHintsTooltip(int count) {
    return '$count tips';
  }

  @override
  String get privacyTitle => 'Data & privacy';

  @override
  String get privacyConsents => 'Consents';

  @override
  String get privacyHud => 'HUD';

  @override
  String get privacyZones => 'Privacy zones';

  @override
  String get privacyZoneAdd => 'Zone';

  @override
  String get privacyNoZones =>
      'No zones — start/end surroundings can be trimmed.';

  @override
  String privacyZoneRadius(String label) {
    return '$label radius';
  }

  @override
  String get privacyZoneDelete => 'Delete zone';

  @override
  String get privacyFamilyHint =>
      'Family / extra riders: under Profile → Family garage add riders with their own weight.';

  @override
  String get privacyExportTitle => 'Export (Art. 20)';

  @override
  String get privacyExportGpx => 'Last ride as GPX';

  @override
  String get privacyExportFit => 'Last ride as FIT';

  @override
  String get privacyExportJson => 'Full JSON export';

  @override
  String get privacyExportStravaStub => 'Strava payload (local, developer)';

  @override
  String get privacyStravaConnect => 'Connect Strava';

  @override
  String get privacyStravaUpload => 'Last ride to Strava';

  @override
  String get privacyStravaLiveHint =>
      'Live upload uses stored OAuth tokens (server).';

  @override
  String get privacyStravaOauthHint =>
      'OAuth opens the browser; continue in the app after granting access.';

  @override
  String get privacyStravaMissing =>
      'Strava is not set up. GPX, FIT, and JSON are the export paths.';

  @override
  String get privacyStravaConnected => 'Strava connected';

  @override
  String get privacyStravaCallback => 'Strava callback received';

  @override
  String privacyStravaStatus(String status) {
    return 'Strava: $status';
  }

  @override
  String get privacyStravaUnreachable =>
      'Strava status unreachable — stub export stays local';

  @override
  String get privacyStravaUrlMissing =>
      'Strava authorize URL missing — sign in and try again.';

  @override
  String get privacyStravaBrowser =>
      'Strava in the browser — return to the app after granting access; status will refresh.';

  @override
  String get privacyNoRideUpload => 'No ride to upload';

  @override
  String privacyChunksUploaded(int n, int left) {
    return '$n chunk(s) uploaded, $left pending';
  }

  @override
  String privacyChunksBlocked(int left) {
    return 'No upload (sign-in/network?) — $left pending';
  }

  @override
  String get privacyChunksNone => 'No pending chunks';

  @override
  String privacyHeatmapCells(int n) {
    return 'Heatmap: contributed $n cells (visible only at k≥5).';
  }

  @override
  String get privacyHeatmapNone =>
      'Heatmap: no contribution (check sign-in/consent/track).';

  @override
  String get privacyUploadNow => 'Upload now';

  @override
  String privacyChunksPending(int count) {
    return 'Raw-data chunks: $count pending';
  }

  @override
  String privacyChunksPendingConsentOff(int count) {
    return 'Raw-data chunks: $count pending (consent off)';
  }

  @override
  String privacySharedGpx(String path) {
    return 'GPX shared · $path';
  }

  @override
  String privacySharedFit(String path) {
    return 'FIT shared · $path';
  }

  @override
  String privacySharedStravaStub(String path) {
    return 'Strava stub shared · $path';
  }

  @override
  String get privacyExportSubject => 'FlowLine export';

  @override
  String get privacyNoRideExporting => 'No ride to export.';

  @override
  String privacySharedJson(String path) {
    return 'JSON shared · $path';
  }

  @override
  String get privacyNoRideExport => 'No ride to export.';

  @override
  String get consentRawTitle => 'Raw data upload';

  @override
  String get consentRawBody =>
      'Sensor raw data only on Wi-Fi and if you agree. Revocable anytime.';

  @override
  String get consentHeatmapTitle => 'Heatmap (your rides, anonymous)';

  @override
  String get consentHeatmapBody =>
      'Local: your rides. With an account: anonymized cells without timestamps. The popularity map appears only once enough riders have been in a cell (k≥5).';

  @override
  String get consentRecoTitle => 'Product recommendations';

  @override
  String get consentRecoBody =>
      'Only when relevant, with a traceable data point. No tracking marketing.';

  @override
  String get consentAnalyticsTitle => 'Analytics';

  @override
  String get consentAnalyticsBody =>
      'Product metrics without health or raw sensor data.';

  @override
  String get consentHealthTitle => 'Health data';

  @override
  String get consentHealthBody =>
      'Prep — Health Connect is not wired yet. This consent only stores your preference for later.';

  @override
  String get privacyZoneTapHint => 'Tap the map to place the zone.';

  @override
  String get privacyZoneRadiusHint => 'Radius applies to export and heatmap.';

  @override
  String get privacyZoneLabel => 'Label';

  @override
  String get privacyZoneRadiusWord => 'Radius';

  @override
  String get privacyZoneApplyCoords => 'Apply coordinates';

  @override
  String get privacyZoneCoords => 'Coordinates';

  @override
  String get privacyZoneCoordsHint =>
      'Only if you want to set the point by numbers';

  @override
  String get profilePictureSet => 'Profile photo set';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileLocalOnly => 'Local only — sign in to sync';

  @override
  String get profileSyncCloudKept => 'Sync: kept cloud';

  @override
  String get profileSyncDeviceUploaded => 'Sync: uploaded device';

  @override
  String get profileSyncCurrent => 'Sync: up to date';

  @override
  String get profileSyncConflictTitle => 'Sync conflict';

  @override
  String profileSyncConflictBody(String when) {
    return 'Cloud and this device differ.\nCloud: $when\n\nWhich version should apply?';
  }

  @override
  String get profileKeepCloud => 'Keep cloud';

  @override
  String get profileForceDevice => 'Force device';

  @override
  String get profileConflictCloud => 'Conflict: kept cloud';

  @override
  String get profileConflictDevice => 'Conflict: forced device';

  @override
  String get profileSyncCancelled => 'Sync cancelled';

  @override
  String get profileSignInForBilling =>
      'Please sign in to manage the subscription';

  @override
  String get profileNoStripeSub =>
      'No Stripe subscription yet — upgrade to Pro first.';

  @override
  String profilePortalError(int code) {
    return 'Portal: $code';
  }

  @override
  String get profileNoPortalUrl => 'No portal URL';

  @override
  String get profileFamilyRiderTitle => 'Family rider';

  @override
  String get profileName => 'Name';

  @override
  String get profileWeightKg => 'Weight kg';

  @override
  String get profileRiderAdded => 'Rider added';

  @override
  String get profileRiderFallback => 'Rider';

  @override
  String profileActiveBike(String name, String category) {
    return 'Active: $name · $category';
  }

  @override
  String get profileDisciplines => 'Your disciplines';

  @override
  String get profileDisciplinesHint =>
      'Preferences for tours. Routing follows the active bike, not this list alone.';

  @override
  String get profileRiderCard => 'Rider profile';

  @override
  String get profilePublic => 'Public';

  @override
  String get profileAccountSync => 'Account & sync';

  @override
  String get profileCloudBilling => 'Cloud sync & billing';

  @override
  String get profileSignedIn => 'Signed in';

  @override
  String get profileFamilyGarage => 'Family garage';

  @override
  String get profileFamilyHint =>
      'More riders with their own weight — e.g. partner or child.';

  @override
  String get profileLegal => 'Legal';

  @override
  String get profilePrivacyPolicy => 'Privacy policy';

  @override
  String get profileImprint => 'Imprint';

  @override
  String get profileWithdrawal => 'Withdrawal';

  @override
  String get profileSetPrimary => 'Set as primary discipline';

  @override
  String profilePrimarySuffix(String label) {
    return '$label · primary';
  }

  @override
  String get profileNeedOneDiscipline =>
      'Keep at least one discipline selected.';

  @override
  String get profileLocalUntilSignIn => 'Local — sync after sign-in';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileActivityLabel => 'Activity — recent rides at home';

  @override
  String get profileBikeOne => 'Bike';

  @override
  String get profileBikes => 'Bikes';

  @override
  String get profileRideOne => 'Ride';

  @override
  String get profileRides => 'Rides';

  @override
  String get profileKmTotal => 'km total';

  @override
  String profileKmElevation(int hm) {
    return 'km · $hm hm';
  }

  @override
  String get profileProActive => 'FlowLine Pro active';

  @override
  String get profileManage => 'Manage';

  @override
  String get profileProPerks =>
      'Offline maps, unlimited bikes, suspension analysis & bracketing.';

  @override
  String get profileUpgradePro => 'Upgrade to Pro';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileRiderWeight => 'Rider weight (kg)';

  @override
  String get profileRideStyle => 'Riding style';

  @override
  String get profileSkillBeginner => 'Beginner';

  @override
  String get profileSkillBasics => 'Fundamentals';

  @override
  String get profileSkillAdvanced => 'Advanced';

  @override
  String get profileSkillExperienced => 'Experienced';

  @override
  String get profileSkillPro => 'Pro';

  @override
  String get profileSubGarage => 'Garage';

  @override
  String get profileSubWeight => 'Rider weight';

  @override
  String profileSubSkill(int skill) {
    return 'Skill ($skill / 5)';
  }

  @override
  String get profileStyleEfficientPace => 'Efficient / pace';

  @override
  String get profileStyleSteady => 'Steady';

  @override
  String get profileStyleExploring => 'Exploring';

  @override
  String get profileStyleCommute => 'Everyday / commute';

  @override
  String get profileStyleTours => 'Tours';

  @override
  String get profileStyleRelaxed => 'Relaxed';

  @override
  String get profileStyleAggressive => 'Aggressive';

  @override
  String get profileStyleFlow => 'Flow';

  @override
  String get profileStyleLines => 'Hunting lines';

  @override
  String get profileStyleEfficient => 'Efficient';

  @override
  String profileDisciplinesSaved(String list) {
    return 'Disciplines: $list';
  }

  @override
  String profileAlsoList(String list) {
    return 'also $list';
  }

  @override
  String get publicProfileTitle => 'Public profile';

  @override
  String get publicProfileHint =>
      'Opt-in. Handle on voices, no tracks, no tab.';

  @override
  String get publicProfileHandle => 'Handle';

  @override
  String get publicProfileBio => 'Bio';

  @override
  String get publicProfileRegion => 'Region';

  @override
  String get publicProfileShowRides => 'Show ride count';

  @override
  String get publicProfileFoot =>
      'No public track, no DMs. Handle stays local until sync.';

  @override
  String get hudMediaTitle => 'Media in the HUD';

  @override
  String get hudMediaProfileHint =>
      'Optional access so the HUD can show the current title. Play/Pause often works without it.';

  @override
  String get hudMediaPrivacyHint =>
      'Setting lives under Profile. Optional media-session access for the HUD title.';

  @override
  String get onboardHowYouRide => 'How do you ride?';

  @override
  String get onboardYourWeight => 'Your weight';

  @override
  String get onboardFirstRide => 'First ride';

  @override
  String get onboardWeightHint =>
      'For setup, SAG & range — local only, change anytime. Useful even without a fork (e.g. city).';

  @override
  String get onboardGpsHint =>
      'Real GPS track — no demo. Bike optional. MTB, gravel, road, or city: equally welcome.';

  @override
  String get onboardGpsStatus => 'Location for GPS track…';

  @override
  String get onboardServicesOff => 'Turn on location services, then try again.';

  @override
  String get onboardDeniedForever => 'Allow location in the app settings.';

  @override
  String get onboardNeedGps => 'Allow location — no GPS, no track.';

  @override
  String onboardWeightLabel(int kg) {
    return 'Rider weight: $kg kg';
  }

  @override
  String onboardDiscipline(String label) {
    return 'Discipline: $label';
  }

  @override
  String get onboardSensorsHint =>
      'Location for the GPS track. Bluetooth sensors later in the workshop — for every bike type.';

  @override
  String get onboardNextRide => 'Continue to the ride';

  @override
  String get onboardParkBikeFirst => 'Park a bike first';

  @override
  String get onboardLater => 'Set up later';

  @override
  String get offlineMapsTitle => 'Offline maps';

  @override
  String get offlineMapsHint =>
      'Downloads the routing graph and map tiles for the region. Offline: loaded map + graph routing in the bounding box. Valhalla tiles are not in the packs yet.';

  @override
  String get offlineRegionActive => 'Region active';

  @override
  String get offlineNoRegion => 'No region active';

  @override
  String get offlineReadyBoth => 'Routing + map tiles ready.';

  @override
  String get offlineReadyRouting => 'Routing ready — map not offline yet.';

  @override
  String get offlineLoadBelow => 'Load a built pack below.';

  @override
  String get offlineRegions => 'Regions';

  @override
  String get offlineSearchRegion => 'Search region';

  @override
  String get offlineNoneFound => 'No region found';

  @override
  String get offlineNoPacks =>
      'No downloadable packs. Stubs below — no demo graph under another name.';

  @override
  String offlineNotBuilt(int count) {
    return 'Not built yet ($count)';
  }

  @override
  String get offlineStubsHint => 'Catalog stubs — download disabled';

  @override
  String get offlineRemoveRegion => 'Remove region';

  @override
  String get offlineStyleTitle => 'Map style (optional)';

  @override
  String get offlineStyleHint =>
      'Default: DACH z11 style JSON. Change only for your own MapLibre style.';

  @override
  String get offlineStyleUrl => 'Style JSON URL';

  @override
  String get offlineSaveStyle => 'Save style';

  @override
  String offlineRegionActiveSnack(String name) {
    return '$name active';
  }

  @override
  String offlineActivateError(String error) {
    return 'Activate: $error';
  }

  @override
  String offlinePackError(String error) {
    return 'Region pack: $error';
  }

  @override
  String get offlineRemoved => 'Region removed';

  @override
  String get offlineNoRemoteDach => 'No remote packs — DACH fallback active';

  @override
  String get offlineNoBuiltPacks => 'No built packs on this server';

  @override
  String get offlineDachCatalog =>
      'Offline — DACH regions from the app catalog';

  @override
  String get offlineReadyMapRouting => 'Map + routing ready';

  @override
  String get offlineRoutingBg => 'Routing ready, map loading in the background';

  @override
  String get offlineBasemapFail =>
      'Routing ready — basemap download failed, map needs the CDN';

  @override
  String get offlineTilesMissing =>
      'Routing ready, map tiles missing (network/limit)';

  @override
  String offlineDemoGraph(String name) {
    return 'Black Forest demo graph active — not the $name map';
  }

  @override
  String get offlineStyleCleared => 'Override cleared — default style active';

  @override
  String offlineStyleSaved(String url) {
    return 'Style saved. Map will reload: $url';
  }

  @override
  String get platzTogetherKicker => 'RIDE TOGETHER';

  @override
  String get platzTogetherTitle => 'Ride together';

  @override
  String get platzTogetherHint =>
      'Invite shares the link. The All, Private, Public filter applies to groups too.';

  @override
  String get platzTogetherListHint =>
      'Group at the gate. Signed in: on the server. Otherwise this device only — no demo user. Pins in the HUD only after opt-in.';

  @override
  String get platzCreateGroup => 'Create group';

  @override
  String get platzJoinCode => 'Code';

  @override
  String get platzNoGroup => 'No group yet. Real codes only — nothing staged.';

  @override
  String get platzHost => 'Host';

  @override
  String get platzGuest => 'Guest';

  @override
  String get platzYou => 'You';

  @override
  String get platzInvite => 'Invite';

  @override
  String get platzDissolve => 'Dissolve';

  @override
  String get platzLeave => 'Leave';

  @override
  String get platzCopyLink => 'Copy link';

  @override
  String get platzInviteShares => 'Invite shares the group link';

  @override
  String get platzInviteSharesProfile => ' and your Platz profile';

  @override
  String platzMembersCount(int count) {
    return '$count in';
  }

  @override
  String get platzOnServer => 'on the server';

  @override
  String get platzOnDevice => 'this device only';

  @override
  String platzCollectionDefaultName(int day, int month) {
    return 'Collection $day.$month.';
  }

  @override
  String get platzPinsOff => 'Pins off';

  @override
  String get platzPinsHudOnly => 'Pins in HUD only';

  @override
  String get platzCollectionsKicker => 'COLLECTIONS';

  @override
  String get platzNoCollection => 'No collection yet — create one here.';

  @override
  String platzCollectionTours(int count) {
    return '$count tours';
  }

  @override
  String get platzCreateCollection => 'Create collection';

  @override
  String get platzJoinWithCode => 'Join with a link';

  @override
  String get platzJoinCodeField => 'Invite link';

  @override
  String get platzJoinLinkHint =>
      'Paste the link from WhatsApp or Messages. Private groups need the token in the link — no code to type.';

  @override
  String get platzJoinEmpty => 'Link missing.';

  @override
  String get platzJoinInvalid => 'Not a valid invite link.';

  @override
  String get platzJoin => 'Join';

  @override
  String get platzStartLabel => 'Start';

  @override
  String get platzStartNow => 'Now';

  @override
  String get platzStartIn1h => 'In 1 h';

  @override
  String get platzStartToday18 => 'Today 18:00';

  @override
  String get platzStartTomorrow10 => 'Tomorrow 10:00';

  @override
  String get platzDurationLabel => 'Duration';

  @override
  String get platzMeetingPlaceholder => 'Meeting point (optional)';

  @override
  String get platzMeetingHint => 'e.g. car park at the pool';

  @override
  String get platzPinsOnHud => 'Pins on in HUD';

  @override
  String get platzTourNotInMappe =>
      'Tour is not in the mappe — open it on the map.';

  @override
  String get platzCollectionsHint =>
      'Sharing only includes released or catalogue tours. Private GPX stays out.';

  @override
  String get akteTourKicker => 'Tour';

  @override
  String get stimmenShareNeedRelease =>
      'Share under Mein first — otherwise the link goes nowhere.';

  @override
  String get platzNeedSharedTour =>
      'Groups only on a shared or catalog tour. Private GPX stays private.';

  @override
  String get platzNoSharedTours =>
      'No shared or catalog tours. Private GPX stays out.';

  @override
  String platzGroupCreated(String code) {
    return 'Group $code — invite shares the link.';
  }

  @override
  String platzGroupCreatedNote(String code, String note) {
    return 'Group $code — $note';
  }

  @override
  String platzShareSubject(String title) {
    return 'Ride together: $title';
  }

  @override
  String get platzLinkCopied =>
      'Link copied. Anyone with it can join while the group is open.';

  @override
  String get platzWindowClosed => 'Window closed';

  @override
  String platzWindowHours(int hours) {
    return 'Window $hours h';
  }

  @override
  String platzWindowMinutes(int minutes) {
    return 'Window $minutes min';
  }

  @override
  String get platzWindowOpen => 'Window open';

  @override
  String platzCollectionShare(String name, String routes) {
    return 'Collection “$name”: $routes';
  }

  @override
  String get rerouteTitle => 'Off the route.';

  @override
  String get rerouteHint => 'Stay calm — you decide.';

  @override
  String get rerouteRejoin => 'Back to the route';

  @override
  String get rerouteStay => 'Stay';

  @override
  String get rerouteSkip => 'Skip this section';

  @override
  String get bleOff => 'Bluetooth is off — please turn it on.';

  @override
  String get bleDenied => 'Bluetooth permission is missing.';

  @override
  String get bleUnavailable => 'Bluetooth LE is not available on this device.';

  @override
  String get bleScanFailed => 'Scan failed';

  @override
  String get bleConnecting => 'Connecting…';

  @override
  String get blePairFailed => 'Pairing failed';

  @override
  String get bleNothingFound => 'Nothing found';

  @override
  String get bleScanAgain => 'Scan again';

  @override
  String get bleHowTo => 'How to connect';

  @override
  String get watchPairTitle => 'Pair watch';

  @override
  String get watchPairHint =>
      'Heart rate only with 0x180D. Watch battery is not the bike battery.';

  @override
  String get watchScanning => 'Looking for watch and HR strap…';

  @override
  String get watchEmptyHint =>
      'Broadcast on, phone close. Apple Watch does not send standard HR.';

  @override
  String get watchNoHr => 'No Heart Rate 0x180D — check broadcast.';

  @override
  String get watchNoDeviceId => 'Connected, but no device ID';

  @override
  String get bleBikeTitle => 'Pair bike';

  @override
  String get bleBikeHint =>
      'Battery and assist only with real GATT — nothing invented.';

  @override
  String get bleRememberAnyway => 'Remember anyway';

  @override
  String get bleScanningDrive => 'Looking for drive and sensors…';

  @override
  String get bleEmptyEbike =>
      'Wake the display, close Flow or E-TUBE, keep the phone close.';

  @override
  String get bleEmptySensor =>
      'Place the sensor nearby and activate it on the bike (magnet/crank).';

  @override
  String get bleConnectFailed => 'Connection failed';

  @override
  String get dieBoxReady => 'Ready';

  @override
  String get dieBoxAlmost => 'Almost ready';

  @override
  String get dieBoxUnknown => 'Just arrived';

  @override
  String get dieBoxNothingDueMonday =>
      'Monday-ready — lights and chain are set.';

  @override
  String get dieBoxNothingDue => 'Ready — nothing waiting.';

  @override
  String get dieBoxCscHint =>
      'Pair the bike sensor here. The watch stays with you when you ride.';

  @override
  String get dieBoxEmptyHint =>
      'Nothing logged yet. Name and type are enough — parts only if they’re really on the bike.';

  @override
  String get dieBoxAddSomething => 'Log something';

  @override
  String get dieBoxAddMore => 'Log more';

  @override
  String get dieBoxBatteryHint =>
      'Charge appears once a sensor on the bike pairs. No number until then.';

  @override
  String get dieBoxPressureTitle => 'Log pressure';

  @override
  String get dieBoxPressureHint => 'Read front and rear at the valve.';

  @override
  String get dieBoxPressureFront => 'Front';

  @override
  String get dieBoxPressureRear => 'Rear';

  @override
  String get dieBoxPressureLogged => 'Pressure logged';

  @override
  String get dieBoxSagTitle => 'Log suspension';

  @override
  String get dieBoxSagHint =>
      'Percent on fork and shock. SAG is how far the suspension sinks with you on it.';

  @override
  String get dieBoxSagFork => 'Fork SAG %';

  @override
  String get dieBoxSagShock => 'Shock SAG %';

  @override
  String get dieBoxSagLogged => 'SAG logged';

  @override
  String get dieBoxTravelTitle => 'Log travel';

  @override
  String get dieBoxTravelHint => 'Only the travel that’s on the bike.';

  @override
  String get dieBoxTravelFront => 'Front mm';

  @override
  String get dieBoxTravelRear => 'Rear mm';

  @override
  String get dieBoxTravelSave => 'Log it';

  @override
  String get dieBoxChainLogged => 'Chain measured';

  @override
  String get dieBoxChainNotes => 'Measured with a gauge';

  @override
  String get dieBoxSetActiveTitle => 'Bring this bike forward';

  @override
  String get dieBoxSetActiveHint =>
      'One bike stands in the stall — switching brings it forward.';

  @override
  String get dieBoxSetActiveCta => 'Set as active';

  @override
  String get dieBoxLightsTitle => 'Log lights';

  @override
  String get dieBoxLightsHint => 'Only if lights are really on the bike.';

  @override
  String get dieBoxLightsCta => 'Log lights';

  @override
  String get dieBoxLockTitle => 'Log lock';

  @override
  String get dieBoxLockHint => 'Only if a lock is on the bike.';

  @override
  String get dieBoxLockCta => 'Log lock';

  @override
  String get dieBoxRackTitle => 'Log rack';

  @override
  String get dieBoxRackHint => 'Only if the bike has a rack.';

  @override
  String get dieBoxRackCta => 'Log rack';

  @override
  String get dieBoxBagsTitle => 'Log bags';

  @override
  String get dieBoxBagsHint => 'Only if bags are on the bike.';

  @override
  String get dieBoxBagsCta => 'Log bags';

  @override
  String get dieBoxPressureMissingTitle => 'Log pressure';

  @override
  String get dieBoxPressureMissingHint => 'Read front and rear at the valve.';

  @override
  String get dieBoxPressureMissingCta => 'Log pressure';

  @override
  String get dieBoxTirePressureTitle => 'Log tire pressure';

  @override
  String get dieBoxTirePressureHint => 'Read front and rear at the valve.';

  @override
  String get dieBoxTravelMissingTitle => 'Log travel';

  @override
  String get dieBoxTravelMissingHint => 'Only the travel that’s on the bike.';

  @override
  String get dieBoxTravelMissingCta => 'Log travel';

  @override
  String get dieBoxSagMissingTitle => 'Log suspension';

  @override
  String get dieBoxSagMissingHint =>
      'One number on fork and shock, read on the bike.';

  @override
  String get dieBoxSagMissingCta => 'Log suspension';

  @override
  String get dieBoxChainTitle => 'Log the chain';

  @override
  String get dieBoxChainHint => 'Measure with a gauge, then log it here.';

  @override
  String get dieBoxChainCta => 'Chain measured';

  @override
  String get dieBoxBrakesTitle => 'Log brakes';

  @override
  String get dieBoxBrakesHint => 'Only if pads are on the bike.';

  @override
  String get dieBoxBrakesCta => 'Log brake';

  @override
  String get dieBoxChainDueTitle => 'Check the chain with a gauge';

  @override
  String get dieBoxChainDueHint => 'Look, then measure with a gauge.';

  @override
  String get dieBoxParkTrailTitle => 'Park or trail';

  @override
  String get dieBoxParkTrailHint =>
      'Both setups are here — switch if you want.';

  @override
  String get dieBoxParkTrailCta => 'Switch';

  @override
  String get dieBoxChipLight => 'Lights';

  @override
  String get dieBoxChipLock => 'Lock';

  @override
  String get dieBoxChipRack => 'Rack';

  @override
  String get dieBoxChipBags => 'Bags';

  @override
  String get dieBoxChipTires => 'Tires';

  @override
  String get dieBoxChipDropper => 'Dropper';

  @override
  String get dieBoxChipBrakes => 'Brakes';

  @override
  String get dieBoxChipParkTrail => 'Park | Trail';

  @override
  String get dieBoxChipTravel => 'Travel';

  @override
  String get dieBoxChipCsc => 'CSC';

  @override
  String get dieBoxChipBatteryHonest => 'Honest battery';

  @override
  String get dieBoxChipSag => 'SAG';

  @override
  String get dieBoxChipChain => 'Chain';

  @override
  String get dieBoxChipPressure => 'Pressure';

  @override
  String get dieBoxChipCockpit => 'Cockpit';

  @override
  String lastRideKm(String km) {
    return 'Last $km km';
  }

  @override
  String get lastRideNoGps => 'Last out — no GPS track';

  @override
  String dieBoxSentenceEverydayReady(String name) {
    return '$name lives here · Monday-ready';
  }

  @override
  String get dieBoxBitLightsChainOk => 'Lights and chain ok';

  @override
  String get dieBoxBitPressureUnknown => 'Pressure not measured';

  @override
  String get dieBoxBitLightsMissing => 'Lights not logged';

  @override
  String dieBoxSentenceNotReady(String name) {
    return '$name lives here';
  }

  @override
  String dieBoxSentenceBits(String name, String bits) {
    return '$name · $bits';
  }

  @override
  String get dieBoxWheelOpen => 'Wheel open';

  @override
  String get dieBoxBitPressureLogged => 'Pressure logged';

  @override
  String get dieBoxBitPressureRough => 'Pressure rough — remeasure';

  @override
  String get dieBoxBitBagsYes => 'Bags on';

  @override
  String get dieBoxBitBagsNo => 'Bags not logged';

  @override
  String get dieBoxBitChainYes => 'Chain measured';

  @override
  String get dieBoxBitChainNo => 'Chain not measured yet';

  @override
  String get dieBoxBitPressureToday => 'Pressure still open today';

  @override
  String get dieBoxSentencePark => 'Park setup';

  @override
  String get dieBoxSagLoggedShort => 'SAG logged';

  @override
  String get dieBoxSagMissingShort => 'SAG not measured';

  @override
  String dieBoxSentenceNoTravel(String name) {
    return '$name lives here';
  }

  @override
  String get dieBoxDriveAssist => ' · e-assist';

  @override
  String dieBoxSentenceMtb(String name, String travel, String drive) {
    return '$name · $travel$drive';
  }

  @override
  String dieBoxSentenceFallback(String name) {
    return '$name lives here';
  }

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get remove => 'Remove';

  @override
  String get garageMoreOnBike => 'More on the bike';

  @override
  String get garageMoreOnBikeHint =>
      'Parts, maintenance, setup versions — behind the Box';

  @override
  String get garageDeleteBike => 'Delete bike';

  @override
  String get garageDeleteBikeTitle => 'Delete this bike?';

  @override
  String get garageDeleteBikeBody =>
      'Components and setups for this bike go away locally.';

  @override
  String get garageRemovePartTitle => 'Remove this part?';

  @override
  String garageRemovePartBody(String slot, String name) {
    return '$slot: $name will be removed from the garage.';
  }

  @override
  String get garageNotLogged => 'Not logged';

  @override
  String get garageOptions => 'Options';

  @override
  String get garageFitTitle => 'Fit';

  @override
  String garageFitStatus(String label) {
    return 'Status: $label';
  }

  @override
  String garageFitSeverity(String label) {
    return 'Severity: $label';
  }

  @override
  String get garageFitSeveritySafety => 'safety-critical';

  @override
  String get garageFitSeverityFunctional => 'functional';

  @override
  String get garageFitExplained => 'In plain words';

  @override
  String garageFitCondition(String text) {
    return 'Condition: $text';
  }

  @override
  String garageFitHint(String text) {
    return 'Note: $text';
  }

  @override
  String get garageFitMissing => 'Still missing';

  @override
  String garageFitSource(String url) {
    return 'Source: $url';
  }

  @override
  String garageGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String get garageVerdictFits => 'Fits';

  @override
  String get garageVerdictCheck => 'Check';

  @override
  String get garageVerdictNoFit => 'Doesn\'t fit';

  @override
  String get garageVerdictUnclear => 'Unclear';

  @override
  String garageAllCount(int count) {
    return 'all $count';
  }

  @override
  String get garageActiveStamp => 'ACTIVE';

  @override
  String get garageFreeOneBikeTitle => 'Free: one bike';

  @override
  String get garageFreeOneBikeBody =>
      'Free includes one bike. You can still add more locally — sync limits apply after you sign in.';

  @override
  String get garageUnlockPro => 'Unlock Pro';

  @override
  String get garageAddAnyway => 'Add anyway';

  @override
  String get garageSlotFrame => 'Frame';

  @override
  String get garageSlotFork => 'Fork';

  @override
  String get garageSlotRearShock => 'Shock';

  @override
  String get garageSlotHeadset => 'Headset';

  @override
  String get garageSlotStem => 'Stem';

  @override
  String get garageSlotHandlebar => 'Handlebar';

  @override
  String get garageSlotGrips => 'Grips';

  @override
  String get garageSlotSeatpost => 'Seatpost';

  @override
  String get garageSlotSaddle => 'Saddle';

  @override
  String get garageSlotFrontHub => 'Front hub';

  @override
  String get garageSlotRearHub => 'Rear hub';

  @override
  String get garageSlotFrontRim => 'Front rim';

  @override
  String get garageSlotRearRim => 'Rear rim';

  @override
  String get garageSlotTireFront => 'Front tire';

  @override
  String get garageSlotTireRear => 'Rear tire';

  @override
  String get garageSlotCassette => 'Cassette';

  @override
  String get garageSlotChain => 'Chain';

  @override
  String get garageSlotCrankset => 'Crankset';

  @override
  String get garageSlotBottomBracket => 'Bottom bracket';

  @override
  String get garageSlotFrontDerailleur => 'Front derailleur';

  @override
  String get garageSlotRearDerailleur => 'Rear derailleur';

  @override
  String get garageSlotShifter => 'Shifter';

  @override
  String get garageSlotBrakeFront => 'Front brake';

  @override
  String get garageSlotBrakeRear => 'Rear brake';

  @override
  String get garageSlotRotorFront => 'Front rotor';

  @override
  String get garageSlotRotorRear => 'Rear rotor';

  @override
  String get garageSlotMotor => 'Motor';

  @override
  String get garageSlotBattery => 'Battery';

  @override
  String get garageSlotDisplay => 'Display';

  @override
  String get garageSlotLight => 'Lights';

  @override
  String get garageSlotLock => 'Lock';

  @override
  String get garageSlotRack => 'Rack';

  @override
  String get garageSlotBags => 'Bags';

  @override
  String get garageSlotOther => 'Other';

  @override
  String get garageGroupSuspension => 'Suspension';

  @override
  String get garageGroupWheels => 'Wheels';

  @override
  String get garageGroupCockpit => 'Cockpit';

  @override
  String get garageGroupDrivetrain => 'Drivetrain';

  @override
  String get garageGroupBrakes => 'Brakes';

  @override
  String get garageGroupPower => 'E-bike';

  @override
  String get garageGroupOther => 'Other';

  @override
  String get dieBoxZoneToday => 'Today';

  @override
  String get dieBoxZoneOnBike => 'On the bike';

  @override
  String get dieBoxZoneSensor => 'Sensor';

  @override
  String get garageCatalogOffline =>
      'Catalog offline — you can still add a bike under “My bike” or “GPX”.';

  @override
  String get garageNoHit => 'No match — use the list or try another search.';

  @override
  String get garageSearchUnavailable =>
      'Search is down right now — use the list.';

  @override
  String get garageFileUnreadable => 'Couldn\'t read that file';

  @override
  String get garageGpxInvalid =>
      'Not a valid GPX track (need at least 2 points)';

  @override
  String get garageNeedMakeModel => 'Pick a make and model';

  @override
  String garageCreateFailed(String error) {
    return 'Couldn\'t add the bike: $error';
  }

  @override
  String get garageOemSetup => 'Stock setup';

  @override
  String get garageCatalogIdentity => 'Catalog identity';

  @override
  String get garageImportBike => 'Import bike';

  @override
  String get garageImportNoGpx => 'Import without GPX — add parts later';

  @override
  String get garageBaseSetup => 'Base setup';

  @override
  String get garageFreeExtraLocal =>
      'Free: extra bike stored locally (multi-bike is Pro).';

  @override
  String garageOemTakeover(int count) {
    return 'Take over stock parts ($count)';
  }

  @override
  String get garageOemHint => 'Otherwise identity only. Catalog stays search.';

  @override
  String garageReachStack(String reach, String stack) {
    return 'Reach $reach mm · Stack $stack mm';
  }

  @override
  String get garageCatalogNotLoaded =>
      'Catalog not loaded — switch to “My bike” or try later.';

  @override
  String get garageSearchBrandHint => 'Focus SAM, Canyon Grizl, Stevens …';

  @override
  String get garageSearchIntro =>
      'Search by brand and model, take a photo, or pick from the list.';

  @override
  String get garageHideList => 'Hide list';

  @override
  String get garagePickFromList => 'Pick from list';

  @override
  String get garageManufacturer => 'Manufacturer';

  @override
  String get garageNickname => 'Nickname (optional)';

  @override
  String get garageNicknameHint => 'e.g. trail bike';

  @override
  String get garageTravelFrontMm => 'Front travel (mm)';

  @override
  String get garageTravelRearMm => 'Rear travel (mm)';

  @override
  String get garageTravelOnlyIfPresent => 'Only if it\'s on the bike';

  @override
  String get garageOnBikeCheck =>
      'On the bike — tick only if it\'s really there';

  @override
  String get garageBagsOnBike => 'Bags on the bike';

  @override
  String get garageBrandOptional => 'Brand (optional)';

  @override
  String get garageModelOptional => 'Model (optional)';

  @override
  String get garagePickGpx => 'Choose GPX file';

  @override
  String get garageNameOptional => 'Name (optional)';

  @override
  String get garageMyBike => 'My bike';

  @override
  String get garageCatalog => 'Catalog';

  @override
  String get garageImport => 'Import';

  @override
  String get garageCreateBike => 'Add bike';

  @override
  String garageGpxImported(String name, String km) {
    return 'GPX “$name” · $km km';
  }

  @override
  String get garageName => 'Name';

  @override
  String get garageNameHint => 'e.g. everyday bike';

  @override
  String get garagePhoto => 'Photo';

  @override
  String get garageGallery => 'Gallery';

  @override
  String get garageSlotHeading => 'Slot';

  @override
  String get garageEditPart => 'Edit part';

  @override
  String get garageInstallPart => 'Install part';

  @override
  String get garageSearchParts => 'Search parts (API/cache)';

  @override
  String get garageSearchPartsHint => 'Make / model — optional';

  @override
  String get garageSearchPartsHelper => 'No hits: fill in the basics by hand';

  @override
  String get garageHits => 'Hits';

  @override
  String get garageNoHitsManual =>
      'No hits — fill in by hand. Cache may be empty.';

  @override
  String garageCacheId(String id) {
    return 'Cache ID: $id';
  }

  @override
  String garageCompatAttrs(String slot) {
    return 'Fit attributes · $slot';
  }

  @override
  String get garageCompatAttrsHint =>
      'From the spec sheet or the stamp on the part. Leave blank if unknown — then “data missing”, no guessing.';

  @override
  String get garageExtraAttr => 'Extra attribute (advanced)';

  @override
  String get garageAttrKey => 'Attribute key';

  @override
  String get garageAttrValue => 'Attribute value';

  @override
  String get garageCompatPlaceholder =>
      'Fit placeholders set (e.g. 148×12 / Microspline) — not catalog truth. Check the attributes.';

  @override
  String garageSagGuideTitle(String kg) {
    return 'Suspension starting points (rider $kg kg)';
  }

  @override
  String garageSagGuideFork(String psi, String min, String max, String sag) {
    return 'Fork: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String garageSagGuideShock(String psi, String min, String max, String sag) {
    return 'Shock: $psi psi ($min–$max) · SAG $sag%';
  }

  @override
  String get garageSagGuideHint =>
      'Starting point — measure on the bike, then fine-tune.';

  @override
  String get garageMeasureSag => 'Measure SAG';

  @override
  String get garageShowMeasureSteps => 'Show the steps';

  @override
  String get garageOdometer => 'Odometer';

  @override
  String get garageOperatingHours => 'Hours';

  @override
  String garageOdoStand(String km) {
    return 'Reading: $km km';
  }

  @override
  String garageHoursStand(String hours) {
    return 'Hours: $hours h';
  }

  @override
  String get garageAddKmNoGps => 'Add km without a GPS track';

  @override
  String get garageDistanceKm => 'Distance (km)';

  @override
  String get garageImportKm => 'Import km (no GPS ride)';

  @override
  String get garageMaintLog => 'Maintenance log';

  @override
  String get garageMaintLogEmpty =>
      'No entries yet — setting the odometer writes logs.';

  @override
  String get garageBleScanning => 'Looking for devices …';

  @override
  String get garageBlePaired => 'Device paired';

  @override
  String garageBlePairedNamed(String name) {
    return 'Paired: $name';
  }

  @override
  String get garageBlePairFailed => 'Pairing failed';

  @override
  String get garageBleRemoved => 'Sensor removed';

  @override
  String get garageBleDisconnected => 'Bluetooth not connected';

  @override
  String get garageBleHintEbike =>
      'Bosch, Shimano STEPS or CSC. Turn the display on.';

  @override
  String get garageBleHintSensor => 'Sensor on the bike, not on the rider.';

  @override
  String get discoverRefresh => 'Refresh';

  @override
  String get discoverChangePlace => 'Change place';

  @override
  String get discoverSuggestDuration => 'Suggest duration';

  @override
  String get discoverDemoCities => 'Demo cities';

  @override
  String discoverNearbyTitle(String profile) {
    return 'Near you · $profile';
  }

  @override
  String get discoverNearbyHintGps =>
      'Tap to see the route · Ride starts navigation';

  @override
  String get discoverNearbyHintNoGps => 'Share location for tours from here';

  @override
  String get discoverGrantLocation => 'Share location';

  @override
  String get discoverSuggestionsComputing => 'Computing suggestions…';

  @override
  String get discoverNoSuggestions =>
      'No suggestions — set a location, pick a bike profile, or tap Refresh.';

  @override
  String discoverAdaptSuggestion(String label) {
    return 'Adjust suggestion: $label';
  }

  @override
  String get discoverTours => 'Tours';

  @override
  String discoverToursLoops(int count) {
    return 'Tours · $count loops';
  }

  @override
  String discoverToursCount(int count) {
    return 'Tours · $count';
  }

  @override
  String get discoverNoGpsCurated =>
      'Without GPS: curated tours · location for nearby';

  @override
  String get discoverGrantLocationNearby => 'Share location for tours near you';

  @override
  String discoverToursNearbyCount(int count) {
    return '$count tours nearby';
  }

  @override
  String discoverCuratedLoops(int count) {
    return '$count curated loops';
  }

  @override
  String get discoverOfflineSuffix => ' · offline';

  @override
  String get discoverHeatmapConsent => 'Heatmaps after consent — open privacy';

  @override
  String get discoverRideToStartShort => 'To the start';

  @override
  String get discoverLoopsNearby => 'Loops near you';

  @override
  String get discoverNoLoop90 => 'No loop within 90 km — next regions';

  @override
  String get discoverRecommendedNoGps => 'Recommended tours · also without GPS';

  @override
  String discoverRecommended(int count) {
    return 'Recommended ($count)';
  }

  @override
  String get discoverRecommendedHint =>
      'For all bike types · geometry loads when you ride';

  @override
  String discoverInRegion(int count) {
    return 'In the region ($count)';
  }

  @override
  String get discoverToursAround => 'Tours around here';

  @override
  String get discoverAfterLocation => 'Shows up after location';

  @override
  String get discoverNeedLocationTrails =>
      'Set location or start for the trail network';

  @override
  String get discoverTrailLoading => 'Trail network loading…';

  @override
  String get discoverTrailEmpty => 'No OSM trail network nearby';

  @override
  String discoverTrailCount(int count) {
    return 'Trail network $count · tap to pick';
  }

  @override
  String get discoverTrailOffline => 'Trail network offline';

  @override
  String get discoverOsmLivePath => 'OSM live path';

  @override
  String get discoverOsmTags => 'Tags from OpenStreetMap';

  @override
  String get discoverTapMapTrails => 'Tap the map to pick trails.';

  @override
  String get discoverTrailApproachHint =>
      'Ride to the entry, then save the overlay or go.';

  @override
  String get discoverTrailGravityHint =>
      'DH: drive or walk to the top entry. The descent follows the trail, not the road.';

  @override
  String get discoverRideToTrailhead => 'Ride to the start';

  @override
  String get discoverApproachByCar => 'Drive to the trail';

  @override
  String get discoverApproachOnFoot => 'Walk to the entry';

  @override
  String get discoverAtTrailStart => 'I\'m at the start';

  @override
  String get discoverApproachByBike => 'Ride there';

  @override
  String discoverTrailUnsuitableForBike(String bike) {
    return 'Not with $bike on this trail. Switch bikes in the garage — don\'t secretly MTB-route.';
  }

  @override
  String get discoverTrailOrientedDownhill => 'Entry at the top (elevation)';

  @override
  String get discoverTrailStartUphillUnknown =>
      'Elevation unknown — nearer entry';

  @override
  String get discoverPutOnRoute => 'Put on the route';

  @override
  String get discoverOpenOsm => 'Open on OpenStreetMap';

  @override
  String get discoverApproachTrailhead => 'Approaching the trail start…';

  @override
  String discoverApproachPlusTrail(String km, String diff) {
    return 'Approach + trail · $km km · $diff';
  }

  @override
  String discoverTrailLaid(String diff, String km) {
    return 'Trail laid · $diff · $km km — save or go';
  }

  @override
  String get discoverSurfaceNature => 'Natural';

  @override
  String get discoverSurfaceGrass => 'Grass';

  @override
  String get discoverSurfaceWood => 'Wood';

  @override
  String get discoverHighwayPath => 'Path';

  @override
  String get discoverHighwayTrack => 'Forest track';

  @override
  String get discoverHighwayCycle => 'Cycleway';

  @override
  String get discoverHighwayBridle => 'Bridleway';

  @override
  String get discoverHighwayFoot => 'Footway';

  @override
  String get discoverSetStartEnd =>
      'Set start and end — then compute the route';

  @override
  String get discoverAdjustStops => 'Adjust start, end or a stop';

  @override
  String discoverNoHitsFor(String query) {
    return 'No matches for “$query”';
  }

  @override
  String get discoverGeocodeFailed => 'Address search failed';

  @override
  String discoverStartEndHit(String kind, String label) {
    return '$kind: $label';
  }

  @override
  String get discoverIdeaStartSet =>
      'Tour idea: start = place pin, end suggested — compute the route.';

  @override
  String get discoverSuggestEnd => 'Suggested end (editable)';

  @override
  String get discoverTourInPlan =>
      'Tour in Navigate — change start, end or stop';

  @override
  String get discoverNeedLocationTours => 'Set location or start for tours';

  @override
  String get discoverOaOffline => 'Tours unreachable right now';

  @override
  String get discoverOaNoLive => 'No live tours nearby';

  @override
  String discoverOaCount(int count) {
    return '$count tours nearby';
  }

  @override
  String get discoverLocationOff =>
      'Location off — tap start or use an address';

  @override
  String get discoverLocationDenied =>
      'Location permission missing — use an address';

  @override
  String get discoverNoGpsFix =>
      'No GPS fix — tap the map or search an address';

  @override
  String get discoverMyPosition => 'My position';

  @override
  String get discoverLocationReady => 'Location ready · loading nearby…';

  @override
  String get discoverLocationUnavailable =>
      'Position unavailable — address or tap';

  @override
  String get discoverComputing => 'Computing route…';

  @override
  String discoverComputingN(int count) {
    return 'Computing $count routes…';
  }

  @override
  String get discoverHeadingNorth => 'Heading north';

  @override
  String get discoverHeadingEast => 'Heading east';

  @override
  String get discoverHeadingSouthwest => 'Heading southwest';

  @override
  String get discoverTargetNorth =>
      'End in the north — return not included yet';

  @override
  String get discoverTargetEast => 'End in the east — return not included yet';

  @override
  String get discoverTargetSouthwest =>
      'End in the southwest — return not included yet';

  @override
  String discoverApproxLabel(String label) {
    return '$label (approx.)';
  }

  @override
  String get discoverQuickRoute => 'Short route';

  @override
  String get discoverRoutingLimit =>
      'Routing limit — used an approximation. Compute again later.';

  @override
  String get discoverNoQuickRoutes => 'No short routes';

  @override
  String get discoverPartialApprox =>
      'Partial approximation — live routing limited';

  @override
  String get discoverPlannedRoute => 'Planned route';

  @override
  String get discoverStraightFallback =>
      'No track from the map — set the destination again.';

  @override
  String get discoverSaved => 'Saved';

  @override
  String discoverSavedNamed(String name) {
    return 'Saved: $name';
  }

  @override
  String get discoverSavedRouteLoaded => 'Saved route loaded';

  @override
  String get discoverStartSetPickEnd => 'Start set — now pick the end';

  @override
  String get discoverEndSetComputing => 'End set — computing the route';

  @override
  String get discoverFromHere => 'From here';

  @override
  String get discoverNearbyPhotos => 'Photos nearby';

  @override
  String get discoverToMyTours => 'To My tours';

  @override
  String get discoverAlreadyInMappe => 'Already in the Mappe';

  @override
  String discoverInMappeNamed(String name) {
    return 'In the Mappe: $name';
  }

  @override
  String get discoverAddRoute => 'Add a route';

  @override
  String get discoverAddRouteHint =>
      'Name + start — no invented track. Compute later or GPX.';

  @override
  String get discoverMapCenter => 'Map center';

  @override
  String get discoverSaveToMine => 'Save to My tours';

  @override
  String discoverSavedToMine(String name) {
    return 'In My tours: $name';
  }

  @override
  String get discoverPickFileAgain => 'Pick another file';

  @override
  String discoverGpxUnreadable(String name) {
    return 'Couldn\'t read “$name” — damaged or not valid GPX.';
  }

  @override
  String get discoverGpxInvalid =>
      'Invalid GPX or too few points — pick another file?';

  @override
  String discoverGpxImported(String name, String km) {
    return 'GPX imported: $name · $km km';
  }

  @override
  String discoverSavedDotName(String name) {
    return 'Saved · $name';
  }

  @override
  String get discoverAsActive => 'As active';

  @override
  String get discoverLocalFoldersHint =>
      'Local folders for saved routes — not a social feed.';

  @override
  String get discoverNoSavedInCollection =>
      'No matching saved routes in this collection';

  @override
  String get discoverNoCollectionYet => 'No collection yet.';

  @override
  String get discoverNewCollection => 'New collection';

  @override
  String get discoverNeedRouteAndCollection =>
      'Needs at least one saved route and a collection';

  @override
  String get discoverPickRoute => 'Pick a route';

  @override
  String get discoverPickCollection => 'Pick a collection';

  @override
  String get discoverAddedToCollection => 'Added to the collection';

  @override
  String get discoverRouteToCollection => 'Route to collection';

  @override
  String get discoverStartSavedNoTrack =>
      'Start saved — no track yet. Navigate or GPX.';

  @override
  String get discoverComputedRoute => 'Computed route';

  @override
  String get discoverSavedRoute => 'Saved route';

  @override
  String discoverViaN(int n) {
    return 'Stop $n';
  }

  @override
  String get discoverTourGone => 'Tour no longer available';

  @override
  String get discoverTourGoneBody =>
      'This tour isn\'t in the list right now — a filter may be hiding it.';

  @override
  String get discoverTourTimeline => 'Along the way';

  @override
  String get discoverNoTrackYet =>
      'No track yet — Compute route builds it live.';

  @override
  String get discoverDuration => 'Duration';

  @override
  String get discoverLength => 'Length';

  @override
  String get discoverAscent => 'Climb';

  @override
  String get discoverElevationProfile => 'Elevation';

  @override
  String discoverDescent(String m) {
    return '↓ $m m descent';
  }

  @override
  String get discoverTip => 'Tip';

  @override
  String get discoverBestTime => 'Best time';

  @override
  String get discoverDiscipline => 'Discipline';

  @override
  String get discoverCorridor => 'Corridor';

  @override
  String get discoverTraits => 'Traits';

  @override
  String get discoverTipsInfo => 'Tips & info';

  @override
  String get discoverStartPoint => 'Start';

  @override
  String discoverFromHereKm(String dist) {
    return '$dist from here';
  }

  @override
  String get discoverApproach => 'Approach';

  @override
  String get discoverInMyTours => 'In My tours';

  @override
  String discoverPinIdeaNamed(String name) {
    return 'Idea “$name” — place pin only';
  }

  @override
  String get discoverPinIdea => 'Tour idea — place pin on the map only';

  @override
  String get discoverStartEndReady =>
      'Start/end set. Compute the route or adjust the end.';

  @override
  String get discoverComputeAndSave => 'Compute & save';

  @override
  String get discoverChangePlaceSearch =>
      'Change place — search a city or address';

  @override
  String discoverDemoRegion(String name) {
    return 'Demo region: $name';
  }

  @override
  String get discoverPickProfile => 'Pick profile';

  @override
  String get discoverOwn => 'Own';

  @override
  String discoverStartOnlyNoTrack(String badge) {
    return '$badge · start — no track yet';
  }

  @override
  String get discoverShowLess => 'Show less';

  @override
  String get discoverShowMore => 'Show more';

  @override
  String get discoverTrailView => 'Trail view';

  @override
  String get discoverNoPhotosNearby => 'No photos nearby';

  @override
  String get discoverImageUnavailable => 'Image unavailable';

  @override
  String get discoverNoLivePhotos => 'No live photos';

  @override
  String get discoverOpenMapillary => 'Open Mapillary';

  @override
  String get discoverMapillarySample => 'Sample — Mapillary unavailable';

  @override
  String get discoverNoTrackOnMap =>
      'No track — load it on the map first or GPX.';

  @override
  String get discoverNoClosedLoop =>
      'No closed loop track — pick the tour again or Adapt.';

  @override
  String get discoverNoLiveTrackPlan =>
      'No live track — Compute route opens Plan with a suggested end.';

  @override
  String get discoverNotClosedLoopNav =>
      'Geometry isn\'t a closed loop — navigation cancelled.';

  @override
  String get discoverNoRealPolyline => 'No real track — recompute or GPX.';

  @override
  String get discoverPoiIdeaHint =>
      'Approach to the place pin — no tour track. Keep planning the end or GPX.';

  @override
  String discoverHybridKm(String km) {
    return 'Hybrid · $km km';
  }

  @override
  String get discoverAroundPoiComputing =>
      'Computing a route around the place pin…';

  @override
  String discoverLiveRouteReady(String km) {
    return 'Live route · $km km — save or ride';
  }

  @override
  String discoverPoiNamed(String name) {
    return 'Place pin · $name';
  }

  @override
  String get discoverNotLoopAb =>
      'Not a loop — A→B suggestion set. Compute route or tap the end.';

  @override
  String get discoverApproxAb =>
      'Approximate A→B · adjust the end on the map, then compute again.';

  @override
  String get discoverRoutingFailedRetry =>
      'Routing failed — tap the end and try again.';

  @override
  String get discoverUnplausibleDropped => 'Implausible routing result dropped';

  @override
  String discoverAltChosen(String label) {
    return 'Alternative chosen: $label';
  }

  @override
  String get discoverLoading => 'Loading';

  @override
  String get discoverCatalog => 'Catalog';

  @override
  String get discoverShared => 'shared';

  @override
  String get discoverPrivate => 'private';

  @override
  String get discoverPrivateCap => 'Private';

  @override
  String get discoverShareRelease => 'Share';

  @override
  String discoverRiddenWith(String name) {
    return 'ridden with $name';
  }

  @override
  String get discoverPrivateCommentHint =>
      'Still private — others can comment after you share.';

  @override
  String get discoverRemoveFromMappe => 'Remove from the Mappe';

  @override
  String get discoverLinkNoTrack =>
      'Link without a trace — too long for the URL. Name and stats, no GPS.';

  @override
  String get discoverLinkCopiedTrack =>
      'Link copied. Includes a simplified trace.';

  @override
  String get discoverLinkCopiedStats =>
      'Link copied. Name and stats, no track.';

  @override
  String get discoverTrackLocal =>
      'Track is local. Syncs between your devices.';

  @override
  String get discoverNoTrackEntry => 'No track yet — just the Mappe entry.';

  @override
  String get discoverVisibility => 'Visibility';

  @override
  String get discoverCopyLink => 'Copy link';

  @override
  String get discoverNoSavedFilter => 'No tours in this filter.';

  @override
  String get discoverMineEmptyHint =>
      'No own routes yet — add a route, GPX, or record.';

  @override
  String get overlayLegendTitle => 'Ways · OSM';

  @override
  String get overlayLegendCompactCity => 'City';

  @override
  String get overlayLegendCompactMtb => 'MTB';

  @override
  String get overlayScaleNote =>
      'S0–S3+ only when the trail is graded. Otherwise unrated.';

  @override
  String get overlayRoadAsphalt => 'Cycleway / asphalt';

  @override
  String get overlayUnrated => 'unrated';

  @override
  String get overlayLegendEmpty =>
      'No overlay here. OSM ways from zoom 12 on the DACH sheet. The bike network follows the map underneath.';

  @override
  String get overlayLegendMeshTitle => 'Bike network · OSM';

  @override
  String get overlayLegendMeshNote =>
      'Signed cycle routes (ICN/NCN/RCN) on this sheet. Ways from zoom 12 across the DACH sheet.';

  @override
  String get overlayLegendCompactGravel => 'Gravel';

  @override
  String get discoverChipTooltip => 'Tours and ways by bike type';

  @override
  String get discoverLocateLongPress => 'My location · long-press: nav symbol';

  @override
  String get discoverNavHonestyBike => 'Bike profiles: same route';

  @override
  String get discoverNavHonestyFoot => 'Nav: walking';

  @override
  String get stimmenTitle => 'Voices';

  @override
  String get stimmenHint =>
      'Stars, text and photos — cloud after share. No invented voices.';

  @override
  String get stimmenWrite => 'Write a voice';

  @override
  String get stimmenHowWas => 'How was the tour?';

  @override
  String get stimmenEmptyName => 'Empty stays you';

  @override
  String get stimmenAddPhoto => 'Add a photo';

  @override
  String get stimmenSaving => 'Saving …';

  @override
  String get stimmenShareSubject => 'Share tour';

  @override
  String get stimmenEmpty => 'No voices yet.';

  @override
  String get stimmenLabel => 'Voice';

  @override
  String get stimmenCloudApproved => 'Saved — published (AI share)';

  @override
  String get stimmenCloudRejected => 'Saved locally — cloud rejected the text';

  @override
  String get stimmenCloudPending => 'Saved — local and in review (AI/human)';

  @override
  String get stimmenCloudLocal => 'Saved — local (cloud after sign-in)';

  @override
  String get stimmenCloudFailed =>
      'Saved locally — cloud unreachable right now';

  @override
  String get akteHonestyCatalog =>
      'Catalog tours are already public. Sharing makes your file linkable — the link shows name and stats, no private extra track.';

  @override
  String get akteHonestyTrack =>
      'Sharing creates a link. The link includes a simplified trace (coordinates), not just the name. Back to private drops it from filters and records the revoke on the server if you\'re signed in. Without login it only applies on this device.';

  @override
  String get akteHonestyNoTrack =>
      'Sharing creates a link with name and stats — no track, because none is saved.';

  @override
  String get stimmenSubmit => 'Send';

  @override
  String get ortSheetVia => 'Add as stop';

  @override
  String get ortSheetHere => 'Tours to here';

  @override
  String get ortSheetMaps => 'Open in Maps';

  @override
  String get ortKindCafe => 'Café';

  @override
  String get ortKindWater => 'Water';

  @override
  String get ortKindViewpoint => 'Viewpoint';

  @override
  String get ortKindShop => 'Shop';

  @override
  String get ortKindRepair => 'Repair';

  @override
  String get ortKindTrailhead => 'Trailhead';

  @override
  String get ortKindTip => 'Tip';

  @override
  String get ortKindMeet => 'Meeting point';

  @override
  String get ortKindOther => 'Place';

  @override
  String get viaMoveUp => 'Move up';

  @override
  String get viaMoveDown => 'Move down';

  @override
  String get stimmeTagsHint => 'Conditions — optional, max three';

  @override
  String get stimmeTagNass => 'wet';

  @override
  String get stimmeTagZu => 'closed';

  @override
  String get stimmeTagVielLos => 'busy';

  @override
  String get stimmeTagTop => 'great';

  @override
  String get stimmeTagBaustelle => 'works';

  @override
  String get postRideStimmeTitle => 'Voice for this tour?';

  @override
  String get postRideStimmeHint =>
      'This tour only, no track in the text. Skip is fine.';

  @override
  String get postRideStimmeSkip => 'Not now';

  @override
  String get postRideStimmeDone => 'Voice saved.';

  @override
  String get postRideOrtTitle => 'Remember this place?';

  @override
  String get postRideOrtHint =>
      'Always private on this ride. Public only with login, on the line, after review.';

  @override
  String get postRideOrtSkip => 'Not now';

  @override
  String get postRideOrtDone => 'Place saved.';

  @override
  String get postRideOrtNameHint => 'Place name';

  @override
  String get postRideOrtSave => 'Save';

  @override
  String get postRideOrtOffTrack =>
      'No point on the ridden line — private note only, no pin.';

  @override
  String get postRideOrtPrivateOnly =>
      'Just for you — no community place without login or a public tour.';

  @override
  String get postRideOrtPending =>
      'The cloud keeps the place after review. Until then only on this device.';

  @override
  String get postRideOrtFailed =>
      'The cloud did not take the place — it stays private on this device.';

  @override
  String get stimmeDifficultyHint =>
      'Difficulty vs the marked grade — optional';

  @override
  String get stimmeDifficultyEasier => 'easier';

  @override
  String get stimmeDifficultyAsMarked => 'as marked';

  @override
  String get stimmeDifficultyHarder => 'harder';

  @override
  String akteDifficultyCrowdEasier(int n) {
    return 'Riders: easier than marked ($n)';
  }

  @override
  String akteDifficultyCrowdAsMarked(int n) {
    return 'Riders: as marked ($n)';
  }

  @override
  String akteDifficultyCrowdHarder(int n) {
    return 'Riders: harder than marked ($n)';
  }

  @override
  String get akteAddToCollection => 'Add to collection';

  @override
  String get discoverEditorialSets => 'Editorial';

  @override
  String get discoverEditorialHonesty =>
      'Editorial ideas — not user collections.';

  @override
  String get discoverEditorialEmpty =>
      'This region is in the catalog; those tours are not in the list right now.';

  @override
  String get discoverLayerTours => 'Tours';

  @override
  String get discoverLayerPlaces => 'Places';

  @override
  String get discoverLayerHeat => 'Heat';

  @override
  String get discoverLayerHeatOff => 'Heat off';

  @override
  String get discoverVariantPlanned => 'As planned';

  @override
  String get discoverVariantFlatter => 'Less climb';

  @override
  String get discoverVariantUnpaved => 'More unpaved';

  @override
  String get discoverVariantValhallaOnly => 'Variants need live Valhalla';

  @override
  String get discoverTrailWet => 'likely wet';

  @override
  String get discoverTrailDamp => 'maybe damp';

  @override
  String get discoverTrailDry => 'likely dry';

  @override
  String discoverWeatherStart(String temp, String hint) {
    return 'Start $temp° · $hint';
  }

  @override
  String discoverWeatherSummit(String temp, String hint) {
    return 'Summit $temp° · $hint';
  }

  @override
  String get discoverFilmstripAttribution => 'Mapillary CC BY-SA';

  @override
  String get discoverOfflineAfterSave => 'Download the region offline?';

  @override
  String get discoverOfflineAfterSaveAction => 'Packs';

  @override
  String get discoverRoundTrip => 'Out and back';

  @override
  String get discoverOutboundOnly => 'outbound only';

  @override
  String get discoverOsmNoHitsSuffix => ' · no ways nearby';

  @override
  String get discoverLiveRoutingUnavailable => ' · live routing unavailable';

  @override
  String get discoverUnplausibleLive =>
      ' · live routing returned nothing plausible';

  @override
  String get discoverTapEndCompute =>
      'Tap a destination or address — then compute the route.';

  @override
  String get discoverPlanYourself =>
      'Plan the route yourself — set start and end';

  @override
  String get discoverLoopBadge => '⟲ Loop';

  @override
  String discoverElevMin(Object min) {
    return 'Min $min';
  }

  @override
  String get discoverHeatmapOffline => 'Heatmap offline';

  @override
  String get discoverCreate => 'Create';

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
  String get discoverShop => 'Shop';

  @override
  String get discoverPreview => 'Preview';

  @override
  String discoverApproachName(Object name) {
    return '$name (approach)';
  }

  @override
  String discoverFromHereName(Object name) {
    return '$name (from here)';
  }

  @override
  String get rideLocationOff => 'Location off';

  @override
  String get rideLocationOffBody =>
      'No GPS track without location. Please turn on location services.';

  @override
  String get rideSettings => 'Settings';

  @override
  String get rideLocationPermission => 'Location permission';

  @override
  String get rideLocationDeniedForever =>
      'Location denied for good. Allow it in app settings, or the track stays empty.';

  @override
  String get rideAppSettings => 'App settings';

  @override
  String get rideLocationNeeded =>
      'Location needed for track and navigation — start again and allow.';

  @override
  String get rideGpsFix => 'GPS-Fix…';

  @override
  String rideGpsFixN(Object count) {
    return 'GPS-Fix $count…';
  }

  @override
  String get rideGpsStillSim => 'GPS still — Sim-Track (do not save)';

  @override
  String get rideGpsStillWeak => 'GPS still — weak signal / stationary';

  @override
  String get rideGpsSimActive => 'Sim-Track active (AETHER_SIM_MOTION)';

  @override
  String get rideBleOffSnack =>
      'Bluetooth off — you can ride without a sensor; connect later.';

  @override
  String get rideBleDeniedSnack =>
      'Nearby/Bluetooth denied — GPS navigation runs without a sensor.';

  @override
  String get rideNoBikeSensor => 'No bike sensor found — GPS track continues.';

  @override
  String get rideOfflineRerouteToast =>
      'Reroute needs internet. Stay on the loaded route.';

  @override
  String get rideStayOnTrail => 'Stay on the trail — no road reroute.';

  @override
  String get rideFollowTrail => 'Follow the trail';

  @override
  String get rideNoGpsRejoin => 'No GPS-Fix for rejoin';

  @override
  String rideRejoinFailed(Object error) {
    return 'Rejoin failed: $error';
  }

  @override
  String get rideSkipAheadWhy => 'Section skipped — back to the route.';

  @override
  String get rideRejoinWhy => 'Back to the route.';

  @override
  String get rideSkipAheadTts => 'Section skipped';

  @override
  String get rideRouteRestoredTts => 'Route restored';

  @override
  String get rideOffRouteTts => 'Off the route';

  @override
  String get rideRerouting => 'Recalculating route …';

  @override
  String get rideUndo10s => '10 s Undo';

  @override
  String get rideUndo => 'Undo';

  @override
  String get rideStayOffHint => 'You stay off-route — tap for options.';

  @override
  String get rideRecalc => 'Recalculating …';

  @override
  String get rideTapOptions => 'Tap for options.';

  @override
  String get rideOptions => 'Options';

  @override
  String get ridePause => 'Pause';

  @override
  String get rideResume => 'Resume';

  @override
  String get rideRunning => 'Ride running';

  @override
  String get rideStop => 'End ride';

  @override
  String get rideTapAgain => 'Tap again';

  @override
  String get rideStopNeedsTwo => 'Stop needs 2 taps';

  @override
  String get rideQuietDisplay => 'Quiet display';

  @override
  String get rideFollowCamera => 'Follow camera';

  @override
  String get rideFollowOn => 'Camera follow on';

  @override
  String get rideFollowFree => 'Camera free';

  @override
  String get rideLiveRide => 'Live ride';

  @override
  String get rideReady => 'Ready';

  @override
  String get rideTtsOn => 'TTS on';

  @override
  String get rideTtsMute => 'TTS muted';

  @override
  String get rideNorthUp => 'North up';

  @override
  String get rideHeadingUp => 'Heading up';

  @override
  String rideHeadingCourse(Object cardinal, Object mode) {
    return '$mode, heading $cardinal';
  }

  @override
  String get rideAutoRerouteOn => 'Auto-Reroute on';

  @override
  String get rideAutoRerouteOff => 'Auto-Reroute off';

  @override
  String rideAutoRerouteActive(Object sec) {
    return 'Auto-Reroute active (cooldown ${sec}s)';
  }

  @override
  String get rideAutoRerouteManual =>
      'Auto-Reroute off — manual rejoin remains';

  @override
  String get rideSunlightAuto => 'Sunlight Mode (Auto)';

  @override
  String get rideSunlightManual => 'Sunlight Mode (Manual)';

  @override
  String rideDisplayNamed(Object name) {
    return 'Display: $name';
  }

  @override
  String rideDisplayNamedBattery(Object name) {
    return 'Display: $name (uses battery)';
  }

  @override
  String get rideCostsBattery => 'uses battery';

  @override
  String get rideBatteryTitle => 'Display & battery';

  @override
  String get rideBatteryHint =>
      'Keep the display on? Uses more battery. Standard saves battery.';

  @override
  String get rideBatteryPocketSnack =>
      'Pocket — display may sleep (save battery).';

  @override
  String get rideBatteryLenkerSnack => 'Lenker — display on (uses battery).';

  @override
  String get rideBatteryUltraSnack =>
      'Ultra — display only on turns (uses battery).';

  @override
  String get rideBatteryPocket => 'Pocket';

  @override
  String get rideBatteryLenker => 'Lenker';

  @override
  String get rideBatteryUltra => 'Ultra';

  @override
  String get rideBatteryPocketSub => 'Voice + haptics, display may sleep';

  @override
  String get rideBatteryLenkerSub => 'Keep display on';

  @override
  String get rideBatteryUltraSub => 'Wake display only on turns';

  @override
  String get rideDefault => 'Standard';

  @override
  String get rideSpeed => 'Speed';

  @override
  String get rideSensorSpeed => 'Sensor speed';

  @override
  String get rideDistance => 'Distance';

  @override
  String get rideTime => 'Time';

  @override
  String get rideHeart => 'Heart';

  @override
  String get rideHeartWaiting => 'Heart waiting';

  @override
  String get rideCadence => 'Cadence';

  @override
  String get rideBikeSensor => 'Bike sensor';

  @override
  String get rideWatch => 'Smartwatch';

  @override
  String get rideConnected => 'Connected';

  @override
  String get ridePower => 'Power';

  @override
  String get rideSoc => 'Battery';

  @override
  String get rideAssist => 'Assist';

  @override
  String get rideBatteryChip => 'Battery';

  @override
  String get rideWheelSpeed => 'Wheel';

  @override
  String get rideRestKm => 'km left';

  @override
  String get rideUntilJoin => 'to route';

  @override
  String get rideRestLoop => 'loop left';

  @override
  String rideKmToRoute(String km) {
    return '$km km to the route';
  }

  @override
  String get rideEta => 'ETA';

  @override
  String get rideKmh => 'km/h';

  @override
  String get rideKm => 'km';

  @override
  String get rideChassisOff => 'Chassis analysis off';

  @override
  String get rideChassisHint =>
      'Mount the phone on the bars and mark it as mounted.';

  @override
  String get rideMarkMounted => 'Mark as mounted';

  @override
  String get rideWaitingSensors => 'Waiting for sensors…';

  @override
  String get rideThereafter => 'Next';

  @override
  String get rideAutoLock => 'Auto-Lock';

  @override
  String get rideAutoLockHint => 'Tap to wake';

  @override
  String get rideWake => 'Wake';

  @override
  String get rideMusicHud => 'Music in the HUD';

  @override
  String get rideMusicHudHint => 'Show titles from Spotify & Co.';

  @override
  String get rideDismissHint => 'Dismiss hint';

  @override
  String get rideMusicControls => 'Music controls';

  @override
  String get ridePrevTrack => 'Previous track';

  @override
  String get rideNextTrack => 'Next track';

  @override
  String get ridePlay => 'Play';

  @override
  String get rideNavSymbol => 'Symbol';

  @override
  String get rideChangeNavSymbol => 'Change nav symbol';

  @override
  String get rideNavPuckTitle => 'Nav symbol';

  @override
  String get rideNavPuckHint =>
      'All variants on dark and light. Tap to pick the symbol for map and HUD. 0° = tip up.';

  @override
  String get rideRecommend => 'Recommended';

  @override
  String get ridePuckDark => 'Dark';

  @override
  String get ridePuckLight => 'Light';

  @override
  String get ridePuckBergA => 'Berg-A';

  @override
  String get ridePuckTopDown => 'Bike from above';

  @override
  String get ridePuckHofTor => 'Hof-Tor';

  @override
  String get ridePuckKomet => 'Aether-Komet';

  @override
  String get ridePuckKiesel => 'Pebble';

  @override
  String get ridePuckLenkerBug => 'Bar nose';

  @override
  String get ridePuckLichtkegel => 'Light cone';

  @override
  String get ridePuckChevron => 'Chevron';

  @override
  String get ridePuckBergASub => 'Letter, mountain and arrow in one';

  @override
  String get ridePuckTopDownSub =>
      'Top-down: nose, horns, two tires — turns with you';

  @override
  String get ridePuckHofTorSub => 'Two legs, open at the bottom';

  @override
  String get ridePuckKometSub => 'Spearhead with an orange spark';

  @override
  String get ridePuckKieselSub => 'Soft triangle with halo';

  @override
  String get ridePuckLenkerBugSub => 'Pointed nose, two bar-ends';

  @override
  String get ridePuckLichtkegelSub => 'Dark disc, orange cone';

  @override
  String get ridePuckChevronSub => 'Standard nav arrow';

  @override
  String get rideChipLive => 'Live';

  @override
  String get rideChipRouteOffline => 'Route offline';

  @override
  String get rideChipOfflineMapOk => 'Offline · map ok · Reroute: net';

  @override
  String get rideChipMapsMissing => 'Maps missing';

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
  String get rideCardinalSW => 'SW';

  @override
  String get rideCardinalW => 'W';

  @override
  String get rideCardinalNW => 'NW';

  @override
  String get navCueArrive => 'Destination';

  @override
  String get navCueSlightLeft => 'Slight left';

  @override
  String get navCueSlightRight => 'Slight right';

  @override
  String get navCueTurnLeft => 'Turn left';

  @override
  String get navCueTurnRight => 'Turn right';

  @override
  String get navCueSharpLeft => 'Sharp left';

  @override
  String get navCueSharpRight => 'Sharp right';

  @override
  String liveHintBracketRun(String n) {
    return 'Run $n logged';
  }

  @override
  String get liveHintImpactStreak => 'Hard hits in a row';

  @override
  String get liveHintStandSetup => 'Stopped: check setup';

  @override
  String get maintForkLower => 'Fork lower-leg service';

  @override
  String get maintForkFull => 'Fork full service (spring/damper)';

  @override
  String get maintShockAir => 'Shock air-can service';

  @override
  String get maintShockFull => 'Shock full service';

  @override
  String get maintChainWear => 'Check chain wear';

  @override
  String get maintCassetteCheck => 'Check cassette (after 2–3 chains)';

  @override
  String get maintPadsFront => 'Check front brake pads';

  @override
  String get maintPadsRear => 'Check rear brake pads';

  @override
  String get maintSealant => 'Refresh tubeless sealant';

  @override
  String get maintDropper => 'Dropper lower-post service';

  @override
  String maintDays(String n) {
    return '$n days';
  }

  @override
  String get maintNoInterval => 'No interval';

  @override
  String get compatTitleDrv011 => 'Cassette needs matching freehub body';

  @override
  String get compatTitleFrm004 => 'Rear spacing must match the hub';

  @override
  String get compatTitleSus007 => 'Shock size must match the frame spec';

  @override
  String get compatTitleSus012 => 'Fork steerer vs headset (S.H.I.S.)';

  @override
  String get compatTitleBrk003 => 'Brake caliper mount on the frame';

  @override
  String get compatTitleBrk008 => 'Rotor mount vs hub';

  @override
  String get compatTitleBrk008f => 'Front rotor vs front hub';

  @override
  String get compatTitleWhl005 => 'Tire width vs internal rim width';

  @override
  String get compatTitleWhl005f => 'Front tire vs internal rim width';

  @override
  String get compatTitleWhl009 => 'Tire width vs frame clearance';

  @override
  String get compatTitleCkp002 => 'Handlebar clamp diameter vs stem';

  @override
  String get compatTitleSpt006 => 'Seatpost diameter vs seat tube';

  @override
  String get compatTitleBb003 => 'Bottom bracket standard vs crank axle';

  @override
  String get compatTitleBb003f => 'Bottom bracket vs frame standard';

  @override
  String get compatTitleEbk002 => 'Motor interface only with OEM approval';

  @override
  String get compatTitleFrm004f => 'Front axle vs fork';

  @override
  String compatFailDrv011(String cassette, String hub) {
    return 'The cassette needs $cassette, your hub has $hub.';
  }

  @override
  String compatFailFrm004(String frame, String hub) {
    return 'Frame spacing $frame ≠ hub $hub.';
  }

  @override
  String compatFailSus007(String eye, String stroke, String mount) {
    return 'Shock $eye×$stroke ($mount) does not match the frame spec.';
  }

  @override
  String compatFailSus012(String fork, String headset) {
    return 'Fork steerer $fork does not match headset $headset.';
  }

  @override
  String compatFailBrk003(String caliper, String frame) {
    return 'Caliper $caliper vs frame mount $frame.';
  }

  @override
  String compatFailBrk008(String rotor, String hub) {
    return 'Rotor $rotor ≠ hub $hub.';
  }

  @override
  String compatFailBrk008f(String rotor, String hub) {
    return 'Front rotor $rotor ≠ hub $hub.';
  }

  @override
  String compatFailWhl005(String tire, String rim) {
    return 'Tire width $tire mm outside range for internal width $rim mm.';
  }

  @override
  String compatFailWhl005f(String tire, String rim) {
    return 'Front tire $tire mm outside range for $rim mm.';
  }

  @override
  String compatFailWhl009(String tire, String max) {
    return 'Tire width $tire mm > frame clearance $max mm.';
  }

  @override
  String compatFailCkp002(String bar, String stem) {
    return 'Bar clamp $bar mm ≠ stem $stem mm.';
  }

  @override
  String compatFailSpt006(String post, String frame) {
    return 'Post Ø $post does not match frame Ø $frame.';
  }

  @override
  String compatFailBb003(String bb, String crank) {
    return 'BB axle $bb ≠ crank $crank.';
  }

  @override
  String compatFailBb003f(String bb, String frame) {
    return 'Bottom bracket $bb ≠ frame $frame.';
  }

  @override
  String compatFailEbk002(String frame, String motor) {
    return 'Motor swap outside OEM approval is not allowed. Frame $frame ≠ motor $motor.';
  }

  @override
  String compatFailFrm004f(String fork, String hub) {
    return 'Fork axle $fork ≠ hub $hub.';
  }

  @override
  String get compatRuleOk => 'Rule met.';

  @override
  String get compatConditional => 'Conditionally compatible';

  @override
  String get compatMissingFacts =>
      'Missing attributes — no COMPATIBLE without complete facts.';

  @override
  String get compatWorkshopHint =>
      'Safety-critical fit: use a workshop. Torque values only from manufacturer docs.';

  @override
  String get compatConditionBrk003 =>
      'Only with a matching adapter (Post Mount ↔ IS).';

  @override
  String get compatDatasheet => 'Check the manufacturer datasheet';

  @override
  String get attrFreehub => 'Freehub standard';

  @override
  String get attrRearSpacing => 'Rear spacing';

  @override
  String get attrEyeToEye => 'Eye-to-eye length';

  @override
  String get attrStroke => 'Stroke';

  @override
  String get attrMountType => 'Mount type';

  @override
  String get attrShockEyeToEye => 'Frame spec: eye-to-eye';

  @override
  String get attrShockStroke => 'Frame spec: stroke';

  @override
  String get attrShockMount => 'Frame spec: mount type';

  @override
  String get attrSteerer => 'Steerer';

  @override
  String get attrBrakeMount => 'Caliper mount';

  @override
  String get attrBrakeMountRear => 'Frame: rear brake mount';

  @override
  String get attrRotorMount => 'Rotor mount';

  @override
  String get attrTireWidth => 'Tire width';

  @override
  String get attrRimWidth => 'Internal rim width';

  @override
  String get attrMaxTire => 'Frame: max tire clearance';

  @override
  String get attrBarClamp => 'Clamp diameter';

  @override
  String get attrStemClamp => 'Stem clamp';

  @override
  String get attrSeatpostDia => 'Diameter';

  @override
  String get attrMinInsert => 'Min. insertion';

  @override
  String get attrMaxInsert => 'Frame: max insertion';

  @override
  String get attrCrankAxle => 'Crank axle';

  @override
  String get attrBbStandard => 'Bottom bracket standard';

  @override
  String get attrMotorInterface => 'Motor interface';

  @override
  String get attrAxleFront => 'Axle';

  @override
  String get howToFreehub => 'Freehub body stamp / hub datasheet';

  @override
  String get howToRearSpacing => 'Frame/hub spec (Boost 148, 142×12, …)';

  @override
  String get howToEyeToEye => 'Shock stamp';

  @override
  String get howToStroke => 'Shock catalog';

  @override
  String get howToMountType => 'Trunnion vs. Eyelet';

  @override
  String get howToSteerer => '1⅛″ or tapered 1.5″ / S.H.I.S.';

  @override
  String get howToBrakeMount => 'Post Mount / Flat Mount / IS';

  @override
  String get howToBrakeMountRear => 'Frame spec';

  @override
  String get howToRotorMount => 'Center Lock or 6-bolt';

  @override
  String get howToTireWidth => 'ETRTO';

  @override
  String get howToRimWidth => 'Rim datasheet';

  @override
  String get howToMaxTire => 'Frame manufacturer spec';

  @override
  String get howToBarClamp => '31.8 or 35.0';

  @override
  String get howToStemClamp => 'Stem datasheet';

  @override
  String get howToSeatpostDia => '27.2 / 30.9 / 31.6 / 34.9';

  @override
  String get howToMinInsert => 'Dropper manual';

  @override
  String get howToMaxInsert => 'Frame geometry';

  @override
  String get howToCrankAxle => 'DUB / 24mm / 30mm';

  @override
  String get howToBbStandard => 'BSA / T47 / PF92 / …';

  @override
  String get howToMotorInterface => 'e.g. bosch_smart_system';

  @override
  String get howToAxleFront => '15×100 / 15×110 Boost / …';

  @override
  String postRideObsImpacts(String count, String km) {
    return 'Many hard impacts ($count over $km km) — fork/shock heavily loaded.';
  }

  @override
  String postRideObsSmooth(String km) {
    return 'Few impacts over $km km — more flowy or smoother ground.';
  }

  @override
  String postRideObsFlowHigh(String flow) {
    return 'High flow score ($flow) — pace and line choice felt in sync.';
  }

  @override
  String postRideObsFlowLow(String flow) {
    return 'Low flow score ($flow) — many pace breaks or stops.';
  }

  @override
  String postRideObsPeakG(String g) {
    return 'Peak $g g — hard hits; check setup and tire pressure.';
  }

  @override
  String get postRideFrontTooFirm => 'too firm';

  @override
  String get postRideFrontOk => 'ok';

  @override
  String get postRideBumpsHarsh => 'harsh';

  @override
  String postRideObsFbHarsh(String front, String bumps) {
    return 'Feedback: front $front · small bumps $bumps.';
  }

  @override
  String get postRideObsFbSoft =>
      'Feedback: front feels soft / dives under braking.';

  @override
  String get postRideSugReboundSlowTitle => 'Fork rebound: 2 clicks slower';

  @override
  String postRideSugReboundSlowContent(String current, String next) {
    return 'About $current clicks from closed → target $next.';
  }

  @override
  String get postRideSugReboundSlowEffect =>
      'Calmer front on hit sequences, a bit less pop.';

  @override
  String get postRideSugReboundFastTitle => 'Fork rebound: 2 clicks faster';

  @override
  String postRideSugReboundFastContent(String current, String next) {
    return 'About $current clicks → target $next (less dive).';
  }

  @override
  String get postRideSugReboundFastEffect =>
      'More stable braking, less bottom-out feel.';

  @override
  String get postRideSugPressureTitle => 'Check front air pressure';

  @override
  String get postRideSugPressureContent =>
      'Very high peak-g — keep pressure and volume spacers against the manufacturer chart.';

  @override
  String get postRideSugPressureEffect =>
      'Less bottom-out risk, clearer feedback.';

  @override
  String get postRideSugLimitsClicks =>
      'Manufacturer range typically 0–14 clicks from closed.';

  @override
  String get postRideSugLimitsPressure =>
      'Only within the approved pressure range of the tire/fork.';

  @override
  String get postRideReasonHarshBumps => 'Feedback “small bumps harsh”';

  @override
  String get postRideReasonFrontFirm => 'Feedback “front too firm”';

  @override
  String postRideReasonImpacts(String count, String km) {
    return '$count impacts / $km km';
  }

  @override
  String postRideReasonRms(String rms) {
    return 'RMS $rms g';
  }

  @override
  String get postRideReasonFrontLoad => 'High hit load on the front';

  @override
  String get postRideReasonDive => 'Feedback “dives”';

  @override
  String get postRideReasonFrontSoft => 'Feedback “front too soft”';

  @override
  String get postRideReasonSoftDive => 'Front too soft / dive';

  @override
  String get postRideReasonPeakLong => 'Peak ≥ 5 g on a longer ride';

  @override
  String get postRideAnalysis => 'Analysis';

  @override
  String postRideExpect(String text) {
    return 'Expected: $text';
  }

  @override
  String postRideLimit(String text) {
    return 'Limit: $text';
  }

  @override
  String get postRideEvidence => 'Evidence';

  @override
  String postRideConfidence(String level) {
    return 'Confidence $level';
  }

  @override
  String get postRideConfHigh => 'high';

  @override
  String get postRideConfMedium => 'medium';

  @override
  String get postRideConfLow => 'low';

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
    return 'Bike: $name';
  }

  @override
  String postRideFactSoc(String soc) {
    return 'SOC $soc%';
  }

  @override
  String get rideGPeak => 'G-Peak';

  @override
  String get rideLean => 'Lean';

  @override
  String get rideFlow => 'Flow';

  @override
  String garageSetNamed(String name) {
    return 'Set $name';
  }

  @override
  String get bleKindPower => 'Power meter';

  @override
  String get bleKindOtherDrive => 'E-drive';

  @override
  String get bleTipBosch => 'Fully close Flow · 10–20 cm from the display';

  @override
  String get bleTipShimano =>
      'Close E-TUBE · tap within 15 s after power/button';

  @override
  String get bleTipYamaha => 'Close e-Sync · speed via CSC sensor';

  @override
  String get bleTipOtherDrive => 'Close the maker app · display on, hold close';

  @override
  String get bleTipCsc => 'Wake the sensor on the bike, hold close';

  @override
  String get bleTipPower => 'Turn the power meter on, hold close';

  @override
  String get blePairLeadEbike =>
      'Display on, maker app closed, phone close — then tap.';

  @override
  String get blePairLeadSensor =>
      'Wake the sensor on the bike, not the watch on your wrist.';

  @override
  String get bleNoteSensorBrand => 'Sensor';

  @override
  String get bleNoteSensorLine =>
      'Magnet or crank, close to the sensor — not the watch.';

  @override
  String get bleNoteBoschLine =>
      'Fully close Flow (not just background). Display on, 10–20 cm.';

  @override
  String get bleNoteShimanoLine =>
      'Close E-TUBE. After power or button often only 15 s — then tap.';

  @override
  String get bleNoteYamahaLine =>
      'Close e-Sync or the TQ app. Live speed usually only via CSC.';

  @override
  String get bleNoteFazuaLine =>
      'Remote on — CSC and power like a normal sensor.';

  @override
  String get bleNoteOtherBrand => 'Other';

  @override
  String get bleNoteOtherLine =>
      'Close RideControl / Mission Control. One phone, display on.';

  @override
  String get bleGattWatchRejected =>
      'Connection refused — close the other fitness app, hold the watch close.';

  @override
  String get bleGattWatchTimeout =>
      'Timeout — hold the watch close, check broadcast heart rate.';

  @override
  String get bleGattWatchFailed => 'Watch connection failed';

  @override
  String get bleGattRejectedBosch =>
      'Connection refused — close Bosch Flow, display on, 10–20 cm.';

  @override
  String get bleGattRejectedShimano =>
      'Connection refused — close E-TUBE, display on, hold close.';

  @override
  String get bleGattRejectedGeneric =>
      'Connection refused — close Bosch Flow / Shimano E-TUBE, display on, hold close.';

  @override
  String get bleGattTimeoutBosch =>
      'Timeout — wake the display, close Flow, hold close. Motor values only with CSC or official LDI.';

  @override
  String get bleGattTimeoutShimano =>
      'Timeout — close E-TUBE, tap within 15 s after power/button.';

  @override
  String get bleGattTimeoutDrive =>
      'Timeout — close the maker app, display on. Speed via CSC sensor.';

  @override
  String get bleGattTimeoutSensor => 'Timeout — wake the sensor, move closer.';

  @override
  String get bleDriveFailBosch =>
      'Bosch found, no live motor values. Pair a wheel sensor (CSC) next.';

  @override
  String get bleDriveFailShimano =>
      'Shimano found, no live motor values. Pair a wheel sensor (CSC) next.';

  @override
  String get bleDriveFailYamaha =>
      'Yamaha found, no live motor values. Pair speed via a CSC sensor.';

  @override
  String get bleDriveFailGeneric =>
      'Drive found, no live motor values. Pair a wheel sensor (CSC) next.';

  @override
  String get bleStatusBtOff => 'Bluetooth off';

  @override
  String get bleStatusScanFailed => 'Wheel sensor scan failed';

  @override
  String get bleStatusNoSensor => 'No wheel sensor found';

  @override
  String get bleStatusNoneInRange => 'No bike, drive or sensor in range';

  @override
  String get bleStatusDriveSeen =>
      'Drive seen — pair in the workshop (Bosch/Shimano)';

  @override
  String get bleStatusNoCscInRange => 'No wheel sensor in range';

  @override
  String get bleStatusSensorDisconnected => 'Wheel sensor disconnected';

  @override
  String get bleStatusReconnectLost =>
      'Connection lost — check the display, close Flow/E-TUBE, pair again in the workshop.';

  @override
  String bleStatusRetry(String n, String max) {
    return 'Connecting … retry $n/$max';
  }

  @override
  String bleStatusAttempt(String n, String max) {
    return 'Connecting … attempt $n/$max';
  }

  @override
  String bleStatusReconnect(String n, String max) {
    return 'Reconnecting … ($n/$max)';
  }

  @override
  String bleStatusDriveNoLive(String who) {
    return '$who · found — speed via CSC, battery only with standard GATT';
  }

  @override
  String get bleStatusNeedBond =>
      'Display needs a Bluetooth pairing for the battery.';

  @override
  String get bleStatusBonding => 'System pairing …';

  @override
  String bleStatusDriveNeedBond(String who) {
    return '$who · found — battery after Bluetooth pairing in the workshop';
  }

  @override
  String bleConnectedNamed(String name) {
    return '$name connected';
  }

  @override
  String get bleWordSensor => 'Sensor';

  @override
  String get bleWordWatch => 'Watch';

  @override
  String get bleSectionDrive => 'Drive';

  @override
  String get bleSectionSensors => 'Sensors';

  @override
  String get watchStatusPickFromList => 'Pick the watch from the list';

  @override
  String get watchStatusScanFailed => 'Watch scan failed';

  @override
  String get watchStatusConnectedSim => 'Watch connected (sim)';

  @override
  String get watchStatusDisconnected => 'Watch disconnected';

  @override
  String get watchStatusNoHrService =>
      'Watch found, but no standard heart-rate service';

  @override
  String get watchStatusReconnectLost =>
      'Watch disconnected — check broadcast, pair again nearby.';

  @override
  String watchStatusReconnect(String n, String max) {
    return 'Watch reconnecting … ($n/$max)';
  }

  @override
  String watchStatusBattery(String n) {
    return 'Watch battery $n %';
  }

  @override
  String get watchHrSensorFallback => 'Heart rate sensor';

  @override
  String get watchCheckBluetooth => 'Check Bluetooth';

  @override
  String get watchOutOfRange => 'Watch not in range';

  @override
  String get watchRemoved => 'Watch removed';

  @override
  String watchRememberedOffline(String name) {
    return '$name · saved, not live';
  }

  @override
  String get watchRememberedOfflineNoName => 'Saved, not live';

  @override
  String watchLiveNamed(String name) {
    return '$name · live';
  }

  @override
  String watchLiveBpm(String name, String bpm) {
    return '$name · $bpm bpm';
  }

  @override
  String get watchHonestyHr => 'Heart rate via standard BLE';

  @override
  String get watchHonestyGarmin => 'Garmin: turn on broadcast HR';

  @override
  String get watchHonestyApple => 'Apple Watch: no standard BLE heart rate';

  @override
  String get watchHonestyGalaxy => 'Galaxy: usually no 0x180D';

  @override
  String get watchHonestyUnknown => 'Only with Heart Rate 0x180D';

  @override
  String get watchTipHr => 'Sensor or broadcast mode on, hold close';

  @override
  String get watchTipGarmin =>
      'On the Garmin watch: send heart rate / broadcast';

  @override
  String get watchTipApple =>
      'No BLE heart rate to Android — HealthKit only on iPhone';

  @override
  String get watchTipGalaxy =>
      'Only if the watch sends Heart Rate 0x180D — otherwise Samsung Health';

  @override
  String get watchTipUnknown => 'Heart Rate 0x180D must be on';

  @override
  String get watchNotePolarBrand => 'Polar / strap';

  @override
  String get watchNotePolarLine =>
      'Sensor mode on. Standard heart rate 0x180D — that is what we pair.';

  @override
  String get watchNoteGarminLine =>
      'Send heart rate / broadcast in the watch settings.';

  @override
  String get watchNoteAppleLine =>
      'No standard BLE heart rate to Android. Do not pair.';

  @override
  String get watchNoteGalaxyLine =>
      'Usually Samsung Health only. Only with visible 0x180D.';

  @override
  String get watchPairLeadText =>
      'Heart rate on the rider, not the bike. Only a real Heart Rate service 0x180D.';

  @override
  String get blePairAgain => 'Pair again';

  @override
  String get bleRemoveDevice => 'Remove device';

  @override
  String get bleSemanticsPaired => 'Bluetooth paired';

  @override
  String get bleSemanticsPair => 'Pair Bluetooth';

  @override
  String get bleTooltipPair => 'Pair drive or sensor';

  @override
  String get bleRemoveWheel => 'Remove wheel sensor';

  @override
  String get bleRemoveDrive => 'Remove drive';

  @override
  String get bleSemanticsLive => 'Bluetooth live';

  @override
  String get bleTooltipSaved => 'Paired, not connected';

  @override
  String get watchOtherWatch => 'Another watch';

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
  String get bikeCatRoad => 'Road';

  @override
  String get bikeCatUrban => 'City';

  @override
  String get bikeCatCargo => 'Cargo';

  @override
  String get bikeCatFolding => 'Folding';

  @override
  String get bikeCatKids => 'Kids';

  @override
  String get bikeCatEmtb => 'E-MTB';

  @override
  String get bikeCatEtrekking => 'E-trekking';

  @override
  String get bikeCatHiking => 'On foot';

  @override
  String get bikeCatEgravel => 'E-gravel';

  @override
  String get bikeCatEcity => 'E-city';

  @override
  String get bikeCatEcargo => 'E-cargo';

  @override
  String get bikeCatEfolding => 'E-folding';

  @override
  String get bikeCatEkids => 'E-kids';

  @override
  String get bikeCatEroad => 'E-road';

  @override
  String get bikeBlurbMtbTrail => 'Singletrack & woods';

  @override
  String get bikeBlurbMtb => 'Trails & tours';

  @override
  String get bikeBlurbEnduro => 'Steep & technical';

  @override
  String get bikeBlurbDh => 'Bike park & descents';

  @override
  String get bikeBlurbGravel => 'Gravel & distance';

  @override
  String get bikeBlurbRoad => 'Tarmac & pace';

  @override
  String get bikeBlurbUrban => 'Everyday & commuting';

  @override
  String get bikeBlurbCargo => 'Cargo & everyday';

  @override
  String get bikeBlurbFolding => 'Fold & take along';

  @override
  String get bikeBlurbKids => 'Kids\' bike';

  @override
  String get bikeBlurbEmtb => 'Trail with assist';

  @override
  String get bikeBlurbEtrekking => 'Tours with assist';

  @override
  String get bikeBlurbHiking => 'Out on foot';

  @override
  String get bikeBlurbMtbTrailFocus => 'Singletrack focus';

  @override
  String get onboardSportTrail => 'Trail';

  @override
  String sportsSummaryPrimary(String label) {
    return 'Main: $label';
  }

  @override
  String sportsSummaryPrimaryAlso(String label, String list) {
    return 'Main: $label · also $list';
  }

  @override
  String get seasonYearRound => 'Year-round';

  @override
  String get seasonSpringSummer => 'Spring–summer';

  @override
  String get seasonAutumn => 'Autumn';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get naeheInYourRegion => '~60 min in your area';

  @override
  String get naeheAroundYou => '~60 min around you';

  @override
  String get sportTagTouring => 'Touring';

  @override
  String get sportTagEbike => 'E-bike';

  @override
  String get overlayRheinNeckar => 'Rhine-Neckar / Heidelberg';

  @override
  String get overlaySchwarzwaldNord => 'Southern Black Forest';

  @override
  String get overlayBodensee => 'Lake Constance';

  @override
  String get overlayStuttgart => 'Stuttgart / Middle Neckar';

  @override
  String get overlayMuenchen => 'Munich & surroundings';

  @override
  String get overlayNuernberg => 'Nuremberg / Franconia';

  @override
  String get overlayFrankfurtRheinMain => 'Frankfurt Rhine-Main';

  @override
  String get overlayKoelnRhein => 'Cologne / Rhineland';

  @override
  String get overlayHamburg => 'Hamburg & surroundings';

  @override
  String get overlayBerlin => 'Berlin & Brandenburg';

  @override
  String get overlayDresdenElbland => 'Dresden / Elbe valley';

  @override
  String get overlayWien => 'Vienna & Vienna Woods';

  @override
  String get overlaySalzburg => 'Salzburg';

  @override
  String get overlayInnsbruck => 'Innsbruck / Tyrol';

  @override
  String get overlayZuerich => 'Zurich & surroundings';

  @override
  String get overlayBern => 'Bern / Swiss Plateau';

  @override
  String get overlayBasel => 'Basel / tripoint';

  @override
  String get overlayRuhrgebiet => 'Ruhr';

  @override
  String get overlayDuesseldorf => 'Düsseldorf / Lower Rhine';

  @override
  String get overlayHannover => 'Hanover / Leine';

  @override
  String get overlayLeipzig => 'Leipzig / New Lakeland';

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
  String get overlayTrierMosel => 'Trier / Moselle';

  @override
  String get overlayPfalz => 'Palatinate Forest';

  @override
  String get overlaySauerland => 'Sauerland';

  @override
  String get overlayEifelTrails => 'Eifel';

  @override
  String get overlayHarz => 'Harz';

  @override
  String get overlayThueringerWald => 'Thuringian Forest';

  @override
  String get overlayBayerischerWald => 'Bavarian Forest';

  @override
  String get overlayAllgaeu => 'Allgäu';

  @override
  String get overlayChiemgau => 'Chiemgau';

  @override
  String get overlaySaarbruecken => 'Saarbrücken';

  @override
  String get overlayMuenster => 'Münsterland';

  @override
  String get overlayAachen => 'Aachen / tripoint';

  @override
  String get overlayLuebeck => 'Lübeck / Trave';

  @override
  String get overlayBremen => 'Bremen / Weser';

  @override
  String get overlayMagdeburg => 'Magdeburg / Elbe';

  @override
  String get overlayErfurt => 'Erfurt';

  @override
  String get overlayKoblenz => 'Koblenz / Rhine-Moselle';

  @override
  String get overlayGraz => 'Graz / Mur valley';

  @override
  String get overlayLinz => 'Linz / Danube';

  @override
  String get overlayKlagenfurt => 'Klagenfurt / Lake Wörth';

  @override
  String get overlayVillach => 'Villach / Drava';

  @override
  String get overlayBregenz => 'Bregenz / Vorarlberg';

  @override
  String get overlayKitzbuehel => 'Kitzbühel / Wilder Kaiser';

  @override
  String get overlayGenf => 'Geneva / Lake Geneva';

  @override
  String get overlayLausanne => 'Lausanne / Lavaux';

  @override
  String get overlayLuzern => 'Lucerne / Lake Lucerne';

  @override
  String get overlayStGallen => 'St. Gallen / Appenzell';

  @override
  String get overlayLugano => 'Lugano / Ticino';

  @override
  String get overlayInterlaken => 'Interlaken / Bernese Oberland';

  @override
  String get overlayChur => 'Chur / Grisons';

  @override
  String get overlayZermatt => 'Zermatt / Mattertal';

  @override
  String get overlayStMoritz => 'St. Moritz / Engadin';

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
  String get overlayParis => 'Paris / Bois & Seine';

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
    return 'Map (zoom $min–$max)…';
  }

  @override
  String offlineProgressMapPercent(String percent) {
    return 'Map $percent%';
  }

  @override
  String get offlineProgressActivating => 'Activating…';

  @override
  String get offlineProgressManifest => 'Manifest…';

  @override
  String offlineProgressPackFile(String file) {
    return 'Pack $file…';
  }

  @override
  String get offlineProgressGraphFile => 'offline_graph.json…';

  @override
  String get offlineProgressDemoGraph => 'Demo graph (Black Forest)…';

  @override
  String get offlinePacksReadyOne => '1 pack ready to download';

  @override
  String offlinePacksReadyCount(int count) {
    return '$count packs ready to download';
  }

  @override
  String offlinePackNotBuilt(String name) {
    return '$name: pack not built yet — no download.';
  }

  @override
  String offlineShaMismatch(String sha) {
    return 'SHA-256 matches none of the downloads (expected $sha)';
  }

  @override
  String offlineInvalidGraphFolder(String id) {
    return 'Folder $id has no valid graph for this region';
  }

  @override
  String offlineNoRemotePack(String name) {
    return 'No remote pack for $name. Catalog stubs do not activate another region\'s demo graph.';
  }

  @override
  String get offlineDownloadEmpty => 'Download empty';

  @override
  String get offlineNoGraphAfterExtract => 'No graph after extract';

  @override
  String get offlineRawPmtiles =>
      'Raw .pmtiles is not supported — need MapLibre style JSON with a pmtiles:// source.';

  @override
  String get offlineInvalidUrl => 'Invalid URL';

  @override
  String get offlineExpectStyleJson =>
      'Expect a style JSON URL (*.json or /styles/…), not a tile file.';

  @override
  String get offlineSubActive => 'Active — tap to refresh';

  @override
  String get offlineSubInstalled => 'Installed — tap to activate';

  @override
  String get offlineSubDemoGraph => 'Demo graph in the app (no remote pack)';

  @override
  String get offlineSubNotBuilt => 'Not built yet';

  @override
  String get offlineSubLoad => 'Load routing + map';

  @override
  String offlineSubLoadSized(String size) {
    return '$size · routing + map';
  }

  @override
  String offlineGraphMissing(String name) {
    return 'No graph in $name';
  }

  @override
  String offlineGraphSha(String name) {
    return 'Graph SHA for $name does not match';
  }

  @override
  String offlineGraphDemoMismatch(String name) {
    return 'Black Forest demo graph does not belong to $name';
  }

  @override
  String get offlineEngineLinkedNoTiles =>
      'Graph engine · Valhalla linked, region tiles still missing';

  @override
  String get offlineEngineTilesNotBuilt =>
      'Graph engine · Valhalla tiles not built';

  @override
  String get offlineNoTiles => 'no tiles';

  @override
  String get offlineFfiMissing =>
      'FFI missing — graph-only / Valhalla flag not linked';

  @override
  String get offlineValhallaTilesLinked =>
      'Valhalla tiles · libvalhalla linked';

  @override
  String offlineValhallaTilesUnlinked(String code) {
    return 'Valhalla tiles · UNLINKED (code $code)';
  }

  @override
  String get offlineValhallaFeature => 'Valhalla feature available';

  @override
  String get offlineValhallaNotLinked => 'Valhalla not linked';

  @override
  String get garageMuscle => 'Pedal';

  @override
  String garageOemTaken(String name, int count) {
    return '$name: took over $count stock parts.';
  }

  @override
  String garageOemTakenPartial(String name, int taken, int skipped) {
    return '$name: $taken stock parts, skipped $skipped.';
  }

  @override
  String garageOemKitOff(String name) {
    return '$name parked — add parts yourself, kit was off.';
  }

  @override
  String garageGpxSaved(String name, String km) {
    return '$name: GPX saved ($km km).';
  }

  @override
  String garageKmImported(String km) {
    return '+$km km imported';
  }

  @override
  String get garageLogOdoUpdated => 'Odometer updated';

  @override
  String get garageLogHoursUpdated => 'Hours updated';

  @override
  String get garageLogGpxImport => 'GPX imported';

  @override
  String get garageLogImportPlaceholder => 'Import without parts';

  @override
  String garageLogManualKm(String km) {
    return 'Manual: $km km';
  }

  @override
  String garageLogManualHours(String hours) {
    return 'Manual: $hours h';
  }

  @override
  String garageLogPsiFront(String psi) {
    return 'front $psi psi';
  }

  @override
  String garageLogPsiRear(String psi) {
    return 'rear $psi psi';
  }

  @override
  String garageLogBarFront(String bar) {
    return 'front $bar bar';
  }

  @override
  String garageLogBarRear(String bar) {
    return 'rear $bar bar';
  }

  @override
  String get bikeCatEmtbTrail => 'E-MTB trail';

  @override
  String get bikeCatEenduro => 'E-Enduro';

  @override
  String get bikeCatEdh => 'E-DH';

  @override
  String discoverCatalogTours(int count) {
    return 'Catalog $count tours';
  }

  @override
  String discoverCatalogToursSuffix(int count) {
    return ' · Catalog $count';
  }

  @override
  String discoverToursOsmStatus(int tours, int withTrack, int osm) {
    return 'Tours $tours · $withTrack with a track';
  }

  @override
  String discoverElevationApprox(String hm) {
    return '~$hm hm (estimate — elevation unavailable)';
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
  String get demoCityWien => 'Vienna';

  @override
  String get demoCityKonstanz => 'Constance';

  @override
  String get demoCityParis => 'Paris';

  @override
  String get demoCityStrasbourg => 'Strasbourg';

  @override
  String get demoCityNice => 'Nice';

  @override
  String get postRideStravaConnect => 'Connect Strava under Data & privacy.';

  @override
  String get postRideStravaKeysMissing => 'Strava keys missing — use GPX/FIT.';

  @override
  String get postRideStravaStatusDown =>
      'Strava status unreachable — use GPX/FIT.';

  @override
  String get postRideStravaHint =>
      'Strava: with GPS track via Uploads API; without track, metadata only.';

  @override
  String postRideStravaError(String error) {
    return 'Strava: $error';
  }

  @override
  String get postRideHeatmapPrivate =>
      'Heatmap: tour is private — track not contributed.';

  @override
  String postRideHeatmapError(String error) {
    return 'Heatmap: $error';
  }

  @override
  String get postRideSetupSaved => 'Setup version saved';

  @override
  String postRideSetupSaveFailed(String error) {
    return 'Couldn\'t save setup: $error';
  }

  @override
  String get postRideGpxEmpty => 'No GPS track — GPX would be empty';

  @override
  String postRideGpxExportError(String error) {
    return 'GPX export: $error';
  }

  @override
  String postRideFitExportError(String error) {
    return 'FIT export: $error';
  }

  @override
  String get postRideShareGpx => 'Share GPX';

  @override
  String get postRideSimActive => 'Sim track was on';

  @override
  String postRideSimDistance(String km) {
    return ' (~$km km simulated)';
  }

  @override
  String get postRideSimUnreliable =>
      ' — distance/analysis may be unreliable. For real rides turn AETHER_SIM_MOTION off.';

  @override
  String get postRideAvgSpeedHigh =>
      'Unusually high average speed — check GPS/sim.';

  @override
  String get postRideSuggestionTaken => 'Applied';

  @override
  String get postRideSuggestionAccept => 'Take recommendation';

  @override
  String get postRideAssistEstimate => 'Assist (estimate)';

  @override
  String postRideAssistDominant(String mode, String wh) {
    return 'Dominant: $mode · ~$wh Wh';
  }

  @override
  String postRideAssistApproach(String mode) {
    return 'Estimate: $mode (approach)';
  }

  @override
  String postRideAssistClimb(String mode, String pct) {
    return 'Estimate: $mode (climb, $pct %)';
  }

  @override
  String postRideAssistRest(String mode) {
    return 'Estimate: $mode (rest)';
  }

  @override
  String get postRideAssistDisclaimer =>
      'Estimates from power/speed signature — not OEM readout. No motor control (F-EBK-000).';

  @override
  String get postRideFeelTitle => 'How did it feel?';

  @override
  String get postRideFrontSuspension => 'Front suspension';

  @override
  String get postRideFrontTooSoft => 'too soft';

  @override
  String get postRideBrakeDive => 'Brake dive';

  @override
  String get postRideBrakeDives => 'dives';

  @override
  String get postRideBrakeNeutral => 'neutral';

  @override
  String get postRideBrakeHarsh => 'harsh';

  @override
  String get postRideSmallBumps => 'Small bumps';

  @override
  String get postRideBumpsVague => 'vague';

  @override
  String get postRideSaveFeedback => 'Save feedback';

  @override
  String get postRideShortRideMetrics =>
      'Short ride — metrics limited (< 0.5 km).';

  @override
  String get postRideMetricsTitle => 'Metrics';

  @override
  String get postRideDefaultName => 'Ride';

  @override
  String get platzCreateGroupHint =>
      'Pick a tour, visibility, then share the link.';

  @override
  String get platzGroupPublicHint =>
      'Anyone with the link can join. The group can show on Platz under Public.';

  @override
  String get platzGroupPrivateHint =>
      'Only people with the link can join. No public list.';

  @override
  String get platzNoPrivateGroups => 'No private groups in this filter.';

  @override
  String get platzMakePrivate => 'Make private';

  @override
  String get platzMakePublic => 'Make public';

  @override
  String get platzNoPublicGroups => 'No public groups on the server.';

  @override
  String get platzPublicGroupsHint =>
      'Public groups — join with login, no Explore GPS.';

  @override
  String get platzListedPublic => 'public';

  @override
  String get filterVisibilityAll => 'All';

  @override
  String get filterVisibilityPublic => 'Public';

  @override
  String get mappeTitle => 'Die Mappe';

  @override
  String get mappeSubtitle =>
      'Your tours, Stimmen and groups. The same ones as on the map.';

  @override
  String get mappeAddHint =>
      'Name + start — no invented track. GPX as an option below.';

  @override
  String get mappePutIn => 'Put in the Mappe';

  @override
  String mappeSaved(String name) {
    return 'In the Mappe: $name';
  }

  @override
  String mappeImported(String name) {
    return 'Imported: $name';
  }

  @override
  String get mappeEmpty => 'No saved tracks yet — add a route.';

  @override
  String get mappeStimmenEmpty =>
      'No Stimmen on your tours yet. After you share, others can write.';

  @override
  String get myRoutesSourceOwn => 'Own';

  @override
  String get privacyZoneTitle => 'Privacy zone';

  @override
  String get privacyZoneEdit => 'Edit zone';

  @override
  String get privacyZoneInvalidCoords => 'Enter valid coordinates';

  @override
  String get privacyZoneNeedTap => 'Tap the map first';

  @override
  String get privacyZoneTapShort => 'Tap the map';

  @override
  String get retry => 'Retry';

  @override
  String get hofSystemStatus => 'System status';

  @override
  String get hofSystemOk =>
      'All connected — workshop, rides and sync are running normally.';

  @override
  String get hofSupabaseMissing => 'Supabase not configured';

  @override
  String get hofSupabaseMissingHint =>
      'Cloud sync is not set up — sign-in and sync are off.';

  @override
  String get hofSyncSessionExpired => 'Sync: session expired';

  @override
  String get hofSyncLoginOnly => 'Sync only with login';

  @override
  String get hofSyncLocalHint =>
      'Garage/Rides stay local — account for cloud sync.';

  @override
  String get hofSystemNotice => 'System status — notice present';

  @override
  String get hofSystemHint => 'System status — notice';

  @override
  String get hofSystemOkTooltip => 'System status: ok';

  @override
  String get hofTafelTitle => 'Die Tafel';

  @override
  String hofTafelVoiceOne(String name) {
    return 'New Stimme on $name';
  }

  @override
  String hofTafelVoices(int count, String name) {
    return '$count Stimmen on $name';
  }

  @override
  String hofTafelGroup(String title) {
    return 'Group at the gate · $title';
  }

  @override
  String ridePuckSemantics(String name) {
    return 'Navigation, $name';
  }

  @override
  String dieBoxSentenceHome(String name) {
    return '$name lives here';
  }

  @override
  String get dieBoxLater => 'Later';

  @override
  String dieBoxSentenceMtbReady(String name, String travel, String drive) {
    return '$name · $travel$drive · ready';
  }

  @override
  String dieBoxSentenceReadyBits(String name, String bits) {
    return '$name · $bits · ready';
  }
}
