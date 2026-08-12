// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AetherRide';

  @override
  String get appTagline =>
      'For MTB, gravel, road, city & e-bike — one app for the ride.';

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
      'Live featured parts in AetherRide — soft-fit & prices, no Shopify password dead-end.';

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
  String get filterTrailNetwork => 'Trail network (map)';

  @override
  String get filterLoopsOnly => 'Loop';

  @override
  String get filterLoopsOnlyTooltip =>
      'Honest loops only (start≈end). No A→B fillers.';

  @override
  String get filterNetworkOn => 'Network on';

  @override
  String get filterNetworkOff => 'Network off';

  @override
  String filterOsmScaleTooltip(String code) {
    return 'OSM scale: $code';
  }

  @override
  String filterShowTours(int count) {
    return 'Show $count tours';
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
  String get planRouteCta => '+ Plan';

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
  String get navigateAddVia => 'Via';

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
      'Change place or duration — or reset filters. No A→B fillers.';

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
  String get garageFabBike => 'Bike';

  @override
  String get garageEmptyTitle => 'No bike in the garage yet';

  @override
  String get garageEmptyMessage =>
      'Add your bike — type, status and parts show up right in the garage.';

  @override
  String get garageAddBike => 'Add bike';

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
  String get rideMapReady => 'Map ready — sensor optional after start';

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
  String get postRidePhotosShareText => 'My AetherRide ride';

  @override
  String get postRidePhotosEmpty => 'No photos to share yet';

  @override
  String postRidePhotosMax(int count) {
    return 'Maximum $count photos';
  }

  @override
  String get postRideCommunityStub =>
      'Community feed coming soon — photos stay local; share via the system share sheet.';

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
  String get myRouteNotesTitle => 'Comments';

  @override
  String get myRouteNotesHint =>
      'Local notes on this route. Public community comments come with an account.';

  @override
  String get myRouteNotesEmpty => 'No comments yet.';

  @override
  String get myRouteNotesPlaceholder => 'Write a comment…';

  @override
  String get myRouteNotesAdd => 'Send';

  @override
  String get myRouteDetailPhotos => 'Photos';

  @override
  String get myRouteOpenDetail => 'Details';
}
