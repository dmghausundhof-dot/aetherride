import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme/app_theme.dart';
import '../../data/community/tour_community_store.dart';
import '../../data/community/community_places_client.dart';
import '../../data/community/filmstrip_client.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/weather/weather_client.dart';
import '../../data/location/safe_position.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/import/gpx_import.dart';
import '../../data/routing/elevation_client.dart';
import '../../data/routing/geocode_client.dart';
import '../../data/routing/osm_routes_client.dart';
import '../../data/routing/osm_trail_network_client.dart';
import '../../data/routing/basemap_street_contrast.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/hillshade.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/overview_browse_paint.dart';
import '../../data/routing/coverage_graph_ring.dart';
import '../../data/routing/coverage_label.dart';
import '../../data/routing/coverage_overlay.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_pack_catalog.dart';
import '../../data/routing/offline_pack_catalog_client.dart';
import '../../data/routing/offline_pack_dirs.dart';
import '../../data/routing/coverage_client.dart';
import '../../domain/community/labeled_via.dart';
import '../../domain/community/map_place.dart';
import '../../domain/community/map_place_merge.dart';
import '../../domain/community/poi_from_vias.dart';
import '../../domain/community/filmstrip.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_map.dart';
import '../../data/routing/sgrade_live.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/browse_map_paint.dart';
import '../../domain/routing/browse_place_search.dart';
import '../../domain/routing/navigate_workflow.dart';
import '../../data/routing/catalog_tour_geometry.dart';
import '../../data/routing/naehe_seeds.dart';
import '../../data/routing/public_tours_client.dart';
import '../../data/routing/route_collections.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/routing_client.dart';
import '../../data/routing/simple_add_route.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/routing/compass_heading.dart';
import '../../domain/routing/duration_lens.dart';
import '../../domain/routing/tour_filters.dart';
import '../../domain/routing/tour_coverage.dart';
import '../../domain/routing/heatmap.dart';
import '../../data/routing/heatmap_client.dart';
import '../../data/routing/offline_basemap.dart';
import '../../data/routing/offline_pmtiles_store.dart';
import '../../data/routing/routing_status_client.dart';
import '../../domain/routing/engine_steps_along.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../domain/routing/route_shape.dart';
import '../../domain/routing/route_progress.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/routing/plan_session.dart';
import '../../domain/routing/trail_difficulty.dart';
import '../../domain/routing/trail_last_mile.dart';
import '../../domain/routing/trail_access.dart';
import '../../domain/routing/nav_policy.dart';
import '../../domain/routing/trail_view.dart';
import '../../domain/routing/plan_line_points.dart';
import '../../domain/routing/track_elevation.dart';
import '../../domain/routing/live_routing_warmup.dart';
import '../../domain/routing/osm_surface_label.dart';
import '../../domain/routing/route_variant.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/add_route_start.dart';
import '../../domain/tours/tour_trait.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/saved_ride_start.dart';
import '../../domain/tours/tour_akte.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../domain/tours/tour_display_name.dart';
import '../../data/routing/saved_route_meta_store.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../auth/auth_screen.dart';
import '../privacy/privacy_screen.dart';
import '../home/hof_watch_card.dart';
import '../shell/shell_tabs.dart';
import '../shell/hof_threshold_nav.dart';
import '../map/map_pin_image.dart';
import '../map/nav_puck_image.dart';
import '../map/nav_puck_overlay.dart';
import '../map/nav_puck_style_sheet.dart';
import '../map/rider_map_image.dart';
import '../shared/weather_glyph.dart';
import '../shared/chrome_glyph.dart';
import '../shared/map_ornaments.dart';
import '../shared/map_locate_fab.dart';
import '../shared/map_loading_scrim.dart';
import '../shared/status_bar_scrim.dart';
import 'add_to_collection_sheet.dart';
import 'discover_browse_sheet_snaps.dart';
import 'plan_sheet_snaps.dart';
import 'discover_explore_chrome.dart';
import 'discover_shell_mode.dart';
import 'discover_map_line_style.dart';
import 'pending_ab_overlay.dart';
import 'plan_line_grab_layer.dart';
import 'plan_unpaved_overlay.dart';
import 'widgets/coverage_edge_pill.dart';
import 'widgets/discover_map_contents_sheet.dart';
import 'widgets/discover_peek_actions.dart';
import 'widgets/group_meet_sheet.dart';
import 'widgets/ort_sheet.dart';
import 'widgets/tour_akte_sheet.dart';
import 'widgets/saved_mappe_tile.dart';
import 'widgets/tour_community_section.dart';
import 'widgets/tour_function_kit.dart';
import 'widgets/tour_social_proof.dart';
import 'widgets/route_variant_chips.dart';
import 'widgets/plan_filmstrip.dart';
import 'widgets/plan_waypoint_stack.dart';
import 'widgets/plan_route_stats.dart';
import 'widgets/plan_adapt_banner.dart';
import 'widgets/plan_elevation_chart.dart';
import 'widgets/plan_surface_bar.dart';
import 'offline_maps_sheet.dart';
import '../library/mappe_empty.dart';
import '../garage/rad_nav_mark.dart';

/// MapLibre in Flutter braucht Eager-Gesten, sonst frisst Parent/PlatformView Zoom/Pan.
Set<Factory<OneSequenceGestureRecognizer>> get _mapGestures =>
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
    };

class _PlanEditSnap {
  const _PlanEditSnap({
    required this.start,
    required this.end,
    required this.vias,
    required this.startLabel,
    required this.endLabel,
    this.computed,
    this.approach,
    this.variant = RouteVariant.planned,
  });

  final GeoPoint? start;
  final GeoPoint? end;
  final List<LabeledVia> vias;
  final String startLabel;
  final String endLabel;
  final RouteResult? computed;
  final RouteResult? approach;
  final RouteVariant variant;

  String get key => [
        start == null
            ? ''
            : '${start!.lat.toStringAsFixed(5)},${start!.lng.toStringAsFixed(5)}',
        end == null
            ? ''
            : '${end!.lat.toStringAsFixed(5)},${end!.lng.toStringAsFixed(5)}',
        for (final v in vias)
          '${v.lat.toStringAsFixed(5)},${v.lng.toStringAsFixed(5)}',
        startLabel,
        endLabel,
        variant.apiId,
      ].join('|');
}

class _TfPin {
  const _TfPin({
    required this.id,
    required this.name,
    required this.center,
    required this.openUrl,
    this.difficulty,
  });
  final String id;
  final String name;
  final LatLng center;
  final String openUrl;
  final String? difficulty;
}

class _SeedPoiStop {
  const _SeedPoiStop({
    required this.id,
    required this.atMin,
    required this.title,
    required this.kind,
    this.whyGood,
  });

  final String id;
  final int atMin;
  final String title;
  final String kind;
  final String? whyGood;
}

class _RouteSuggestion {
  const _RouteSuggestion({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    required this.durationMin,
    required this.mtbScale,
    required this.surface,
    required this.matchScore,
    required this.reasons,
    required this.center,
    this.categories = const [
      BikeCategory.urban,
      BikeCategory.gravel,
      BikeCategory.road,
    ],
    this.trackLngLat,
    this.sourceKind = 'other',
    this.isLoopHint,
    this.poiStopsCount = 0,
    this.sportLabel,
    this.tip,
    this.seasonLabel,
    this.highlightPoi,
    this.disciplineNote,
    this.corridorNote,
    this.shortPitch,
    this.surfaceMixLabel,
    this.poiStops = const [],
    this.thumbnailUrl,
    this.photoUrls = const [],
    this.apiTags = const [],
  });

  final String id;
  final String name;
  final double distanceKm;
  final int elevationM;
  final int durationMin;
  final String mtbScale;
  final String surface;
  final int matchScore;
  final List<String> reasons;
  final LatLng center;
  final List<BikeCategory> categories;

  /// Optional echte Polyline [lng, lat] (z. B. Outdooractive).
  final List<List<double>>? trackLngLat;

  /// catalog | osm | outdooractive | seed | other
  final String sourceKind;

  /// Seed/Katalog-Hinweis „Rundkurs“ — nur wenn keine Geometrie widerspricht.
  final bool? isLoopHint;

  /// POI-Stops (Seeds) — günstig auf der Karte anzeigen.
  final int poiStopsCount;

  /// Premium-Pass card/detail (seeds; discover-seed-card-fields-v1).
  final String? sportLabel;
  final String? tip;
  final String? seasonLabel;
  final String? highlightPoi;
  final String? disciplineNote;
  final String? corridorNote;
  final String? shortPitch;
  final String? surfaceMixLabel;
  final List<_SeedPoiStop> poiStops;

  /// Hero photo (asset path or https) — S25 photo cards.
  final String? thumbnailUrl;

  /// Extra hero slides (assets/https). Empty → derived from [thumbnailUrl].
  final List<String> photoUrls;

  /// Catalog/OSM/OA tags for detail (trail, region, route type) — no chrome spam.
  final List<String> apiTags;

  /// Card P0 premium chrome present (tip / season / highlight).
  bool get isPremiumPassCard =>
      tip != null || seasonLabel != null || highlightPoi != null;

  bool get hasTrack => trackLngLat != null && trackLngLat!.length >= 2;

  /// Track dense enough to paint as a real path (not A→B ruler / demo).
  bool get hasUsableTrack => isUsableMapTrack(trackLngLat);

  bool get isCatalog => sourceKind == 'catalog';
  bool get isLiveOsm => sourceKind == 'osm';
  bool get isOutdooractive => sourceKind == 'outdooractive';
  bool get isSeed => sourceKind == 'seed';

  /// Ordered carousel URLs: seed photos → thumbnail → (detail may paint fallback).
  List<String> get heroPhotoUrls {
    final out = <String>[];
    void add(String? u) {
      final t = u?.trim();
      if (t == null || t.isEmpty) return;
      if (!out.contains(t)) out.add(t);
    }

    for (final u in photoUrls) {
      add(u);
    }
    add(thumbnailUrl);
    return out;
  }

  _RouteSuggestion copyWith({
    List<List<double>>? trackLngLat,
    LatLng? center,
  }) {
    return _RouteSuggestion(
      id: id,
      name: name,
      distanceKm: distanceKm,
      elevationM: elevationM,
      durationMin: durationMin,
      mtbScale: mtbScale,
      surface: surface,
      matchScore: matchScore,
      reasons: reasons,
      center: center ?? this.center,
      categories: categories,
      trackLngLat: trackLngLat ?? this.trackLngLat,
      sourceKind: sourceKind,
      isLoopHint: isLoopHint,
      poiStopsCount: poiStopsCount,
      sportLabel: sportLabel,
      tip: tip,
      seasonLabel: seasonLabel,
      highlightPoi: highlightPoi,
      disciplineNote: disciplineNote,
      corridorNote: corridorNote,
      shortPitch: shortPitch,
      surfaceMixLabel: surfaceMixLabel,
      poiStops: poiStops,
      thumbnailUrl: thumbnailUrl,
      photoUrls: photoUrls,
      apiTags: apiTags,
    );
  }
}

class _QuickOption {
  const _QuickOption({
    required this.id,
    required this.label,
    required this.reason,
    required this.result,
  });
  final String id;
  final String label;
  final String reason;
  final RouteResult result;
}

/// Komoot-style Dauer: `55 Min` / `1h 10m`.
String _fmtRideDuration(int minutes, AppLocalizations l10n) {
  if (minutes <= 0) return '—';
  if (minutes < 60) return l10n.discoverDurationMin('$minutes');
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

/// Icon je POI-Stop-Art — 3D-Pin, keine Material-Glyphe.
Widget _poiKindMark(String kind, {double size = 18}) {
  return Image.asset(
    poiPinAssetPath(mapPoiKindFromRaw(kind)),
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

/// Übersetzt eine rohe Schwierigkeits-Angabe (OSM S-Skala oder Outdooractive-
/// Klartext wie "mittel") in ein Label ohne Nachschlagen. Der Rohwert bleibt
/// über [trailDifficultyLabel]/Tooltips im Detail abrufbar.
String _difficultyDisplay(AppLocalizations l10n, String raw) {
  final parsed = parseTrailDifficulty(raw);
  if (parsed != TrailDifficulty.open) {
    return l10n.trailDifficultyFriendly(parsed);
  }
  final t = raw.trim();
  if (t.isEmpty || t.toLowerCase() == 'offen' || t.toLowerCase() == 'open') {
    return l10n.trailDiffUnrated;
  }
  return t[0].toUpperCase() + t.substring(1);
}

Color _difficultyDotColor(String raw) {
  final parsed = parseTrailDifficulty(raw);
  return Color(
    int.parse('FF${trailDifficultyColor(parsed).substring(1)}', radix: 16),
  );
}

String _inferSurfaceTag({
  required String title,
  String? type,
  String? difficulty,
  RoutingProfile? profile,
}) =>
    TourFilters.inferSurfaceTag(
      title: title,
      type: type,
      difficulty: difficulty,
      profileApiId: profile?.apiId,
    );

class _DifficultyDot extends StatelessWidget {
  const _DifficultyDot({required this.raw});
  final String raw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _difficultyDotColor(raw),
      ),
    );
  }
}

/// Discover ist der Dauerzustand, nicht einer von drei gleichrangigen Modi.
/// „Planen" und „Detail" sind keine Tabs oder eigenen Screens mehr, sondern
/// Panels, die kontextuell über die Karte fahren (Route bauen / Anpassen /
/// Karte lange drücken / Tour antippen) und mit „Zurück" wieder schließen —
/// Panel-Inhalt über der Karte. Die **Map-Shell-IA** steuert zusätzlich
/// [DiscoverShellMode] (Entdecken | Navigieren | Meine):
/// - Entdecken → `_Surface.discover` (Katalog / Trails)
/// - Navigieren → `_Surface.plan` (A→B Start/Ziel — erste Klasse, kein Nebenzweig)
/// - Meine → `_Surface.discover` + Mine-Liste (UGC / Saved)
/// `detail` bleibt Tour-Fokus ohne eigenen Scaffold.
enum _Surface { discover, plan, detail }

enum _PickMode { none, start, end, via }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with WidgetsBindingObserver {
  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _pinImagesReady = false;
  bool _bikeOverlayAttached = false;
  String? _bikeOverlayKey;
  bool _bikeOverlayOn = true;
  final Set<BikeOverlayClass> _bikeOverlayExtra = {
    ...overlayExploreAllClasses,
  };
  double _mapZoom = 12;
  int _drawGen = 0;
  int _sGradeGen = 0;
  int _styleAttachGen = 0;
  bool _styleAttachBusy = false;
  Timer? _sGradeDebounce;
  Timer? _viewportDebounce;
  Timer? _calcAbDebounce;
  Timer? _destPulseTimer;
  int _destPulseTick = 0;
  Timer? _browseNetTimer;
  bool _browseOnline = true;
  DateTime? _browseOnlineAt;
  int _syncMarkersGen = 0;
  bool _cameraMoving = false;
  DateTime? _cameraMovedAt;
  DateTime? _lastRoutePinAt;
  Timer? _routeFlowTimer;
  Symbol? _routeFlowSymbol;
  List<LatLng> _routeFlowGeom = const [];
  double _routeFlowT = 0;
  final List<Symbol> _meetPulseSymbols = [];
  final List<Symbol> _meetHaloSymbols = [];
  double _pinPulse = 0;
  LatLng? _ideaPin;
  List<Symbol> _tfSymbols = [];
  final Map<String, _TfPin> _tfBySymbolId = {};
  List<CoveragePlace> _googlePlaces = [];
  List<MapPlace> _communityPlaces = [];
  List<MapPlace> _stimmePlaces = [];
  List<RideGroup> _meetGroups = const [];
  Set<String> _meetMemberIds = {};
  final Map<String, MapPlace> _placeBySymbolId = {};
  final Map<String, _RouteSuggestion> _tourBySymbolId = {};
  final Map<String, _SeedPoiStop> _poiBySymbolId = {};
  final Map<String, Symbol> _poiSymbolByPoiId = {};
  final Map<String, int> _poiDrawIndexById = {};
  final List<Symbol> _placeSymbols = [];
  final List<Symbol> _tourSymbols = [];
  List<double> _poiFracsOnMap = const [];
  final Map<String, GlobalKey> _poiTileKeys = {};
  String? _highlightPoiId;
  String? _highlightPlaceId;
  String? _pendingPoiScrollId;
  Timer? _poiHighlightTimer;
  bool _showToursLayer = true;
  bool _showTrailsLayer = true;
  bool _showBikeWaysLayer = true;
  bool _showFarmTracksLayer = true;
  bool _showHillshade = BrowseMapPaint.hillshadeOnByDefault;
  bool _showPlacesLayer = true;
  bool _showHeatLayer = true;
  final NavPuckOverlay _navPuck = NavPuckOverlay();
  NavPuckStyle _navPuckStyle = NavPuckStyle.rider;
  UserLocation? _lastUserLoc;
  double _puckHeadingDeg = 0;

  /// Live-geroutete Loop-Geometrie pro Seed-Tour (ersetzt den synthetischen
  /// Kreis, sobald die Routing-Engine antwortet) — Komoot zeigt echte Wege.
  final Map<String, List<GeoPoint>> _routedLoopCache = {};
  final Set<String> _routedLoopPending = {};

  _Surface _surface = _Surface.discover;

  /// Primäre Map-Shell: Entdecken | Navigieren | Meine.
  DiscoverShellMode _shellMode = DiscoverShellMode.explore;

  /// Verhindert Doppel-Play, während Approach/HUD-Wechsel läuft.
  bool _launchingRide = false;

  /// Neutral bis Garage/Profil greift — nicht MTB-lastig vorwählen.
  RoutingProfile _profile = RoutingProfile.urban;

  double _joinAlongM = 0;
  bool _gravityComputed = false;

  /// Default: alle Dauer. 0 = egal — nicht still ~60 vom Rad.
  int _minutes = DiscoverExploreChromeLogic.defaultDurationMin;
  int _loopSeed = 1;
  bool _loopBusy = false;
  bool _aroundYouApplied = false;
  String? _aroundYouStats;
  bool _loading = false;
  bool _routeLineStale = false;
  GeoPoint? _lastMapPointer;
  DateTime? _lastMapPointerAt;
  String? _error;
  String? _status;
  bool _statusIsWarm = false;
  bool _statusIsApprox = false;
  bool _oaIsDegraded = false;
  bool _trailIsDegraded = false;

  GeoPoint? _userPos;
  String? _liveWarmupCell;
  GeoPoint? _start;
  GeoPoint? _end;

  /// Origin, für den Kamera + „Schnell"-Vorschläge zuletzt angewendet wurden.
  /// `null` = noch nie ein echter (nicht-Fallback-)Origin gesehen.
  /// Ersetzt einmalige Snapshots (Kaltstart-Fallback vor GPS-Fix) durch
  /// laufenden Abgleich in [_syncOriginDrift], aufgerufen bei jedem Rebuild.
  GeoPoint? _lastAppliedOrigin;

  /// GPS-Button: Kamera bleibt beim Standort. Auto-Fit auf Tour-Start/Bounds
  /// (Honesty, POI-Fahne, [_drawAll]) darf das nicht wieder wegziehen.
  bool _skipAutoCameraFit = false;
  bool _fitPackAfterStyle = false;
  final GlobalKey _exploreChromeKey = GlobalKey();
  double _exploreChromeHeight =
      DiscoverExploreChromeLogic.exploreChromeBodyHeight;
  final List<LabeledVia> _vias = [];
  _PickMode _pick = _PickMode.none;

  /// Explore long-press A–B uses live streets only. Planned editor does not.
  bool _abFromBrowsePin = false;

  /// km along the live line while a pin is dragged.
  String? _planDragAlongLabel;
  LatLng? _planShapeHintAt;
  LatLng? _planStopHintAt;
  String? _planStopHintLabel;
  DateTime? _planStopHintUntil;
  Timer? _planStopHintTimer;
  Timer? _planLineHoldTimer;
  bool _planPointerGrabbing = false;
  bool _planPointerHoldDidDest = false;
  final List<({Line line, double opacity})> _planRibbonLines = [];
  final Map<String, List<LatLng>> _planGrabGeom = {};
  final List<Line> _planGrabLines = [];
  final Set<String> _planLegendKinds = {};
  List<({String kind, List<List<double>> coords})> _planRibbonSlices = [];
  final List<Symbol> _planChevronSymbols = [];
  final List<Symbol> _planTickSymbols = [];
  bool _planRibbonDimmed = false;
  int _planRibbonDimGen = 0;
  LastPlanDest? _lastPlanDest;
  bool _lastPlanDestDismissed = false;
  final List<_PlanEditSnap> _planUndoStack = [];
  final List<_PlanEditSnap> _planRedoStack = [];
  static const _kPlanUndoMax = 24;
  bool _planLineCoach = false;
  bool _planLineTouched = false;
  bool _planLineExclusiveGrab = false;
  DateTime? _planChevronFreshUntil;
  Timer? _planChevronFreshTimer;
  bool _planPulseChevronsOnDraw = false;
  PlanGrabScreenCache? _planGrabScreen;
  int _planGrabScreenGen = 0;
  Timer? _planGrabScreenDebounce;
  final ValueNotifier<int> _planHintCamTick = ValueNotifier(0);
  final ValueNotifier<Offset?> _planHintScreen = ValueNotifier(null);
  Timer? _planHintScreenDebounce;
  int? _planPulseViaIndex;
  DateTime? _planBendHighlightUntil;
  DateTime? _planDestConfirmUntil;
  Timer? _planPulseTimer;
  Timer? _planDestPulseTimer;

  _PlanEditSnap _capturePlanSnap() => _PlanEditSnap(
        start: _start,
        end: _end,
        vias: List<LabeledVia>.from(_vias),
        startLabel: _startAddrCtrl.text,
        endLabel: _endAddrCtrl.text,
        computed: _copyRouteResult(_computed),
        approach: _copyRouteResult(_approach),
        variant: _routeVariant,
      );

  RouteResult? _copyRouteResult(RouteResult? r) {
    if (r == null) return null;
    return RouteResult(
      coordinates: List<GeoPoint>.from(r.coordinates),
      distanceM: r.distanceM,
      durationS: r.durationS,
      engine: r.engine,
      steps: r.steps,
      warnings: r.warnings,
      variant: r.variant,
      variantApplied: r.variantApplied,
    );
  }

  void _showPlanStopHint(GeoPoint at, {String? label}) {
    if (!mounted) return;
    _planStopHintTimer?.cancel();
    setState(() {
      _planStopHintAt = LatLng(at.lat, at.lng);
      _planStopHintLabel = label;
      _planStopHintUntil = DateTime.now().add(kPlanStopHint);
    });
    unawaited(_syncPlanHintScreen());
    _planStopHintTimer = Timer(kPlanStopHint, () {
      if (!mounted) return;
      setState(() {
        _planStopHintAt = null;
        _planStopHintLabel = null;
        _planStopHintUntil = null;
      });
      if (_planHintScreen.value != null && !_planMapHintOnMap) {
        _planHintScreen.value = null;
      }
    });
  }

  void _clearPlanStopHint() {
    _planStopHintTimer?.cancel();
    _planStopHintTimer = null;
    if (_planStopHintAt == null &&
        _planStopHintLabel == null &&
        _planStopHintUntil == null) {
      return;
    }
    if (!mounted) {
      _planStopHintAt = null;
      _planStopHintLabel = null;
      _planStopHintUntil = null;
      return;
    }
    setState(() {
      _planStopHintAt = null;
      _planStopHintLabel = null;
      _planStopHintUntil = null;
    });
    if (!_planMapHintOnMap && _planHintScreen.value != null) {
      _planHintScreen.value = null;
    }
  }

  void _pushPlanUndo() {
    final snap = _capturePlanSnap();
    if (_planUndoStack.isNotEmpty && _planUndoStack.last.key == snap.key) {
      return;
    }
    _planUndoStack.add(snap);
    if (_planUndoStack.length > _kPlanUndoMax) {
      _planUndoStack.removeAt(0);
    }
    _planRedoStack.clear();
  }

  void _applyPlanSnap(_PlanEditSnap snap) {
    _abFromBrowsePin = false;
    setState(() {
      _start = snap.start;
      _end = snap.end;
      _vias
        ..clear()
        ..addAll(snap.vias);
      _startAddrCtrl.text = snap.startLabel;
      _endAddrCtrl.text = snap.endLabel;
      _routeVariant = snap.variant;
      _pick = _PickMode.none;
      _error = null;
      _computed = snap.computed;
      _approach = snap.approach;
      _routeLineStale = false;
      _planLineTouched = snap.vias.isNotEmpty;
    });
    unawaited(HapticFeedback.selectionClick());
    unawaited(_syncMarkers());
    if (_start != null &&
        _end != null &&
        (snap.computed == null || snap.computed!.coordinates.length < 2)) {
      _schedulePlanReshape();
    } else {
      unawaited(_drawAll());
    }
  }

  void _undoPlan() {
    if (_planUndoStack.isEmpty) return;
    _clearPlanStopHint();
    _planShapeHintAt = null;
    final snap = _planUndoStack.removeLast();
    _planRedoStack.add(_capturePlanSnap());
    _applyPlanSnap(snap);
  }

  void _redoPlan() {
    if (_planRedoStack.isEmpty) return;
    _clearPlanStopHint();
    _planShapeHintAt = null;
    final snap = _planRedoStack.removeLast();
    _planUndoStack.add(_capturePlanSnap());
    _applyPlanSnap(snap);
  }

  bool get _planTypingInField {
    if (_startAddrFocus.hasFocus || _endAddrFocus.hasFocus) return true;
    return FocusManager.instance.primaryFocus?.context?.widget is EditableText;
  }

  void _onPlanUndoShortcut() {
    if (!_planEditorActive || _planTypingInField) return;
    _undoPlan();
  }

  void _onPlanRedoShortcut() {
    if (!_planEditorActive || _planTypingInField) return;
    _redoPlan();
  }

  String _planDestFlagTooltip(AppLocalizations l10n) =>
      _start != null && _end != null
          ? l10n.discoverReplaceDest
          : l10n.discoverSetEndCta;

  /// Returns true when the first-via coach was dismissed — skip the snack.
  bool _afterPlanViaInserted() {
    _planLineTouched = true;
    if (_vias.isEmpty) return false;
    _pulsePlanVia(_vias.length - 1);
    if (_planLineCoach && mounted) {
      setState(() => _planLineCoach = false);
      unawaited(RidePrefs.setPlanLineCoachDismissed(true));
      return true;
    }
    return false;
  }

  void _pulsePlanVia(int index) {
    _planPulseViaIndex = index;
    _planBendHighlightUntil =
        DateTime.now().add(const Duration(milliseconds: 2400));
    _planPulseTimer?.cancel();
    _planPulseTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _planPulseViaIndex = null;
        _planBendHighlightUntil = null;
      });
      unawaited(_syncMarkers());
    });
  }

  List<GeoPoint> get _viaPoints =>
      [for (final v in _vias) GeoPoint(v.lat, v.lng)];

  bool get _planEditorActive => planEditorIsActive(
        navigateMode: _shellMode == DiscoverShellMode.navigate,
        planSurface: _surface == _Surface.plan,
      );

  bool get _hasLivePlanLine =>
      _computed != null &&
      isPlanCustomizableLine(
        engine: _computed!.engine,
        coordinateCount: _computed!.coordinates.length,
      );

  /// Drops stale A→B results when a newer Ziel/Via wins the race.
  int _calcAbGen = 0;

  /// Drops in-flight seed/catalog preview after a new routing pin.
  int _previewGen = 0;

  RouteResult? _computed;

  /// Last library save of the live A→B line — reuse on Losfahren if unchanged.
  String? _lastPersistedPlanId;
  String? _lastPersistedPlanKey;
  RouteResult? _approach;
  RouteResult? _tourLayer;
  List<GeoPoint>? _trailOverlay;
  String? _label;
  List<_QuickOption> _quick = [];
  String? _detailId;
  final Map<String, List<String>> _communityHeroUrls = {};

  List<_RouteSuggestion> _tours = <_RouteSuggestion>[];
  List<EditorialSetHit> _editorialSets = [];
  String _editorialHonesty = '';
  final Map<String, _RouteSuggestion> _catalogById = {};

  /// Browse-Suche / Kameraschwenk — Nähe folgt diesem Punkt statt nur GPS.
  GeoPoint? _browseAnchor;
  bool _browseAnchorPinned = false;
  String? _browseAnchorLabel;
  GeoPoint? _lastMapTap;
  DateTime? _lastMapTapAt;
  DateTime? _lastPlanViaAlongAt;
  List<GeocodeHit> _placeHits = const [];
  bool _placeSearchNeedNet = false;
  GeocodeHit? _lastPlaceHit;
  Timer? _placeSearchDebounce;
  List<OsmTrailSegment> _trailNetwork = [];
  List<OsmTrailSegment> _sGradeTrails = [];
  OsmTrailSegment? _destinationTrail;
  bool _showTrailNetwork = true;

  /// Eigene SavedRoutes dauerhaft als Accent-Layer (nicht nur nach Tap).
  bool _showOwnTracks = true;
  Map<String, SavedRouteMeta> _savedMeta = {};
  String? _selectedTrailId;
  String? _trailNetworkStatus;
  final Set<TrailDifficulty> _trailScaleFilter = {};

  /// Filtert die Tourenliste auf Nähe zum Zeitbudget [_minutes].
  /// Default an: ~60-Min-Lens mit Band 45–75 (D-60-01).
  bool _matchTourDuration = false;
  TourSurfaceKey? _surfaceFilter;
  TourEffortKey? _effortFilter;
  TourElevationKey? _elevationFilter;

  /// Umkreis: Abstand Tour-Mitte → Standort. Nicht die Tourlänge.
  double? _maxDistanceKm;

  /// Tourlänge in km — Filter-Sheet, nicht Umkreis.
  double? _maxLengthKm;
  final Set<TourSportKey> _sportFilter = {};

  /// Form: Alle / Rundkurs / A→B / Downhill — Default Alle, nicht nur Loops.
  TourFormKey _formFilter = TourFormKey.all;

  bool get _loopOnlyActive => _formFilter == TourFormKey.loop;

  /// Discover-Browse: true ≈ Half/Full-Snap, false ≈ Peek (Map dominant).
  /// Wird mit [DraggableScrollableSheet] synchron gehalten; Liste/Karte-Toggle
  /// snappt das Sheet statt nur die feste Höhe umzuschalten.
  bool _listBrowseMode = false;

  /// Rausfahren: Karte mit Wahl, ohne Touren-Sheet.
  bool _hofChoice = false;

  final DraggableScrollableController _discoverSheetCtrl =
      DraggableScrollableController();
  final DraggableScrollableController _planSheetCtrl =
      DraggableScrollableController();

  /// Startgröße, bis der Plan-Sheet-Controller hängt.
  double _planInitialSnap = PlanSheetSnaps.form;
  double _planSheetExtentLogged = PlanSheetSnaps.form;

  /// Umschaltbare Merkmal-Chips (Detail + Liste).
  final Set<String> _activeTraits = {};

  /// Strecken-/Los-Leiste: einziehbar (Drag/Tap), sonst blockiert sie die Map.
  bool _rideBarExpanded = true;

  /// Gesetzt, wenn Planen aus einer Tour („Anpassen") kommt — klarerer Titel.
  String? _adaptingTourName;
  _RouteSuggestion? _adaptingTour;

  bool _heatmapConsent = false;
  bool _heatmapContributed = false;

  /// Bundled Nähe-Seeds (Berlin) — Fallback ohne GPS / leeres OA·OSM.
  NaeheSeedsBundle? _seedsBundle;
  String? _seedsStatus;
  bool _seedsOffline = false;

  String? _elevationSummary;
  double? _elevationGainM;
  List<double> _planElevSamples = const [];
  List<double> _planElevKm = const [];
  List<Map<String, dynamic>> _planElevPoints = const [];
  String? _planElevSource;
  List<({double fromKm, double toKm, String? surface})> _planSurfaceBands =
      const [];
  List<SurfaceShare> _planSurfaceMix = const [];
  double? _planElevScrubT;
  Symbol? _planElevSymbol;
  Symbol? _planStartSymbol;
  Symbol? _planEndSymbol;
  Symbol? _planEndGlowSymbol;
  final List<Symbol> _planViaSymbols = [];
  final List<Symbol> _planBendSymbols = [];
  final List<Symbol> _planBendDiscSymbols = [];
  WeatherSnapshot? _weatherStart;
  WeatherSnapshot? _weatherSummit;
  List<FilmstripShot> _filmstripShots = const [];
  RouteVariant _routeVariant = RouteVariant.planned;
  bool _valhallaLive = false;
  bool _showNavigateOfflineHint = false;
  OfflinePackRow? _navigateOfflinePack;
  List<OfflinePackRow>? _offlineCatalog;
  Future<List<OfflinePackRow>>? _offlineCatalogLoad;
  bool _offlineRoutingReady = false;
  bool _offlineOverviewReady = false;
  List<double>? _offlinePackBbox;
  List<List<double>>? _offlinePackRing;
  bool _offlinePackRingResolved = false;
  List<double>? _offlineStreetBbox;
  StreetHudOfferKind? _offlineStreetKind;
  bool _offlineStreetInstalled = false;
  String? _offlinePackLabel;
  String? _offlinePackId;
  bool _activeCoverageLayerReady = false;
  bool _suggestedCoverageLayerReady = false;
  int _offlineCoverageRetries = 0;

  /// Höhenprofil je Tour fürs Detail-Panel — getrennt vom globalen
  /// [_elevationSummary] (der gehört zur zuletzt berechneten Route und kann
  /// im Detail zu einer ganz anderen Tour gehören). Nur echte Geometrie
  /// (Routed-Cache oder Nicht-Seed-Track), nie synthetische Kreise.
  final Map<String, ({double gainM, double lossM, List<double> samples})>
      _detailElev = {};
  final Set<String> _detailElevPending = {};
  String? _oaStatus;
  List<_TfPin> _tfPins = [];
  String? _heatmapNote;
  String? _routingStatusNote;
  String _mapStyle = AppConfig.browseMapStyleUrl;
  final _geocode = GeocodeClient();
  final _startAddrCtrl = TextEditingController();
  final _startAddrFocus = FocusNode();
  final _endAddrCtrl = TextEditingController();
  final _endAddrFocus = FocusNode();
  final _exploreSearchCtrl = TextEditingController();
  String _exploreQuery = '';
  List<GeocodeHit> _addrHits = const [];
  List<GeocodeHit> _geocodeRecents = const [];
  bool _addrBusy = false;
  String? _addrTarget; // 'start' | 'end'
  Timer? _addrDebounce;
  int _quickGen = 0;
  String? _selectedTourId;

  /// Hof-/Deep-Link-Pin. Nähe-Ranking darf diese ID nicht überschreiben.
  String? _hofPinLoopId;

  /// Nur Karten-Übersicht DACH+FR bis GPS da ist — nie Tour-Origin.
  static const _regionOverview = GeoPoint(47.2, 6.5);

  /// Mindestplatz über dem Panel, der bei geöffneter Tastatur erhalten
  /// bleiben muss — Kopfzeile plus ein Rest Karte. Ohne das würde die
  /// Panel-Höhe (als Prozent der VOLLEN Bildschirmhöhe berechnet) bei
  /// geöffneter Tastatur zusammen mit ihr über den sichtbaren Bereich
  /// hinausragen und ihren oberen Rand — Griff und „Zurück" — nach oben
  /// aus dem Bild schieben, ohne dass ein Overflow-Fehler das anzeigt.


  RouteRepository get _routes => ref.read(routeRepositoryProvider);
  final _elevationClient = ElevationClient();
  final _filmstripClient = FilmstripClient();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RideGroupStore.revision.addListener(_onRideGroupRevision);
    RidePrefs.navPuckRevision.addListener(_onNavPuckPref);
    OfflineMapsPrefs.revision.addListener(_onPackRevision);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_locate());
      unawaited(_hydratePlanGeocodeRecents());
    });
    _prefetchBikeOverlay();
    unawaited(_loadNavPuckStyle());
    unawaited(_loadFarmTrackPref());
    _loadHeatmapConsent();
    unawaited(_reloadSavedMeta());
    unawaited(_fetchRoutingStatus());
    unawaited(_refreshOfflineChip());
    unawaited(_syncBrowseMapStyle());
    _browseNetTimer = Timer.periodic(kBrowseOnlineProbeTtl, (_) {
      if (!mounted) return;
      if (ref.read(shellTabIndexProvider) != ShellTabs.karte) return;
      unawaited(_syncBrowseMapStyle());
    });
    // Quick auch ohne GPS — sonst bleibt die Liste leer bis Locate ok ist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Localizations are not safe in initState — fetch after first frame.
      _fetchOutdooractive();
      _fetchOsmRoutes();
      _fetchTrailNetwork();
      _fetchTrailforks();
      unawaited(_fetchPublicCatalog());
      unawaited(_loadNaeheSeeds());
      final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
      final active = bikes.cast<Bike?>().firstWhere(
            (b) => b?.isActive == true,
            orElse: () => bikes.isEmpty ? null : bikes.first,
          );
      final sportCat =
          active?.category ?? ref.read(userProfileStoreProvider).preferredSport;
      if (active != null || sportCat != null) {
        setState(() => _applyBikeNavDefaults(active?.category ?? sportCat));
      }
      // Deep-Link: lens / loop highlight (ohne start=1; start läuft im Handler).
      final pendingLens = ref.read(discoverPendingLensMinutesProvider);
      if (pendingLens != null) {
        ref.read(discoverPendingLensMinutesProvider.notifier).state = null;
        setState(() {
          _minutes = pendingLens;
          _matchTourDuration = pendingLens > 0;
        });
      }
      _pinPendingLoop(ref.read(discoverPendingLoopIdProvider));
      final pendingMine = ref.read(discoverPendingMineProvider);
      final launch = ref.read(discoverLaunchModeProvider);
      if (pendingMine || launch == DiscoverLaunchMode.mine) {
        ref.read(discoverPendingMineProvider.notifier).state = false;
        if (launch == DiscoverLaunchMode.mine) {
          ref.read(discoverLaunchModeProvider.notifier).state = null;
        }
        _setShellMode(DiscoverShellMode.mine);
        unawaited(_consumePendingAkte());
        unawaited(_consumePendingStartRide());
      } else {
        _applyDiscoverLaunch(launch);
      }
      unawaited(_refreshMeetPlaces());
    });
  }

  void _onRideGroupRevision() {
    unawaited(_refreshMeetPlaces());
  }

  void _onNavPuckPref() {
    unawaited(_loadNavPuckStyle());
  }

  void _onPackRevision() {
    unawaited(_refreshOfflineChip());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RidePrefs.navPuckRevision.removeListener(_onNavPuckPref);
    RideGroupStore.revision.removeListener(_onRideGroupRevision);
    OfflineMapsPrefs.revision.removeListener(_onPackRevision);
    _stopRouteFlow();
    _browseNetTimer?.cancel();
    _browseNetTimer = null;
    _addrDebounce?.cancel();
    _sGradeDebounce?.cancel();
    _viewportDebounce?.cancel();
    _calcAbDebounce?.cancel();
    _stopDestPulse();
    _placeSearchDebounce?.cancel();
    _poiHighlightTimer?.cancel();
    _planPulseTimer?.cancel();
    _planDestPulseTimer?.cancel();
    _planLineHoldTimer?.cancel();
    _planChevronFreshTimer?.cancel();
    _planStopHintTimer?.cancel();
    _planStopHintTimer = null;
    _planStopHintAt = null;
    _planStopHintLabel = null;
    _planStopHintUntil = null;
    _planHintScreenDebounce?.cancel();
    _planGrabScreenDebounce?.cancel();
    _planHintCamTick.dispose();
    _planHintScreen.dispose();
    _map?.removeListener(_onMapCameraTick);
    _discoverSheetCtrl.dispose();
    _planSheetCtrl.dispose();
    _startAddrCtrl.dispose();
    _startAddrFocus.dispose();
    _endAddrCtrl.dispose();
    _endAddrFocus.dispose();
    _exploreSearchCtrl.dispose();
    super.dispose();
  }

  bool get _hasExploreSelection => DiscoverExploreChromeLogic.showIdlePeek(
        _hofPinLoopId ?? _selectedTourId,
      );

  double get _discoverSheetExtent {
    if (_discoverSheetCtrl.isAttached) return _discoverSheetCtrl.size;
    if (_listBrowseMode) return DiscoverBrowseSheetSnaps.half;
    return _hasExploreSelection
        ? DiscoverBrowseSheetSnaps.peek
        : DiscoverBrowseSheetSnaps.closed;
  }

  void _syncDiscoverSheetExtent(double extent) {
    final h = extent * MediaQuery.sizeOf(context).height;
    // Kamera-Padding live ohne Rebuild — FAB folgt über ListenableBuilder.
    _panelInset = h;
    final wantList = DiscoverBrowseSheetSnaps.isHalf(extent) ||
        DiscoverBrowseSheetSnaps.isFull(extent);
    if (_listBrowseMode == wantList) return;
    setState(() => _listBrowseMode = wantList);
  }

  Future<void> _snapDiscoverSheet(double size) async {
    final target = DiscoverBrowseSheetSnaps.nearest(
      size,
      hasSelection: _hasExploreSelection,
    );
    setState(() {
      _listBrowseMode = DiscoverBrowseSheetSnaps.isHalf(target) ||
          DiscoverBrowseSheetSnaps.isFull(target);
    });
    if (!_discoverSheetCtrl.isAttached) return;
    try {
      await _discoverSheetCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  bool get _planSheetActive =>
      _surface == _Surface.plan ||
      _surface == _Surface.detail ||
      _shellMode == DiscoverShellMode.navigate;

  double get _planSheetExtent {
    if (_planSheetCtrl.isAttached) return _planSheetCtrl.size;
    return _planInitialSnap;
  }

  /// Peek snap including the system inset so chrome is not clipped.
  double get _planPeekSnap {
    final mq = MediaQuery.of(context);
    return PlanSheetSnaps.peekSize(
      height: mq.size.height,
      bottomInset: mq.padding.bottom,
    );
  }

  bool get _planSheetIsPeek => PlanSheetSnaps.isPeek(_planSheetExtent);

  void _syncPlanSheetExtent(double extent) {
    final h = extent * MediaQuery.sizeOf(context).height;
    _panelInset = h;
    final wasPeek = PlanSheetSnaps.isPeek(_planSheetExtentLogged);
    final nowPeek = PlanSheetSnaps.isPeek(extent);
    final wasFull = PlanSheetSnaps.isFull(_planSheetExtentLogged);
    final nowFull = PlanSheetSnaps.isFull(extent);
    _planSheetExtentLogged = extent;
    if (wasPeek == nowPeek && wasFull == nowFull) return;
    setState(() {});
  }

  Future<void> _snapPlanSheet(double size) async {
    final target = PlanSheetSnaps.nearest(size, peekSnap: _planPeekSnap);
    _planInitialSnap = target;
    if (!_planSheetCtrl.isAttached) {
      if (mounted) setState(() {});
      return;
    }
    try {
      await _planSheetCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
    if (mounted) setState(() {});
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  /// GPS-Abstand zur ausgewählten Tour — nicht die Loop-Länge.
  double? get _selectedAwayKm {
    final id = _hofPinLoopId ?? _selectedTourId;
    if (id == null || !_hasRealOrigin) return null;
    final tour = _tourById(id);
    if (tour == null) return null;
    return _distKm(
      _origin.lat,
      _origin.lng,
      tour.center.latitude,
      tour.center.longitude,
    );
  }

  bool _isLiveRateLimited(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('too many requests') ||
        msg.contains('rate limit') ||
        msg.contains('minutely');
  }

  String _liveRouteError(Object e, {bool browsePin = false}) {
    if (_isLiveRateLimited(e)) return _l10n.discoverGhMinuteLimit;
    final msg = e.toString().toLowerCase();
    if (browsePin &&
        (isOfflineNoRouteError(e) ||
            msg.contains('browse-needs-network') ||
            msg.contains('timeout') ||
            msg.contains('timed out') ||
            msg.contains('failed host lookup') ||
            msg.contains('socketexception'))) {
      return _l10n.discoverBrowseNeedsNetwork;
    }
    if (isOfflineViasNeedNetworkError(e)) {
      return _l10n.discoverViasNeedNet;
    }
    if (isOfflineNoRouteError(e)) return _l10n.discoverOfflineNoRoute;
    if (isLoopProfileError(e)) return _l10n.discoverAroundYouSport;
    if (isLoopNotClosedError(e) || isLoopGeneratorError(e)) {
      return _l10n.discoverAroundYouFail;
    }
    return friendlyErrorMessage(e, context: _l10n.computeRoute);
  }

  void _setStatus(String? text, {bool warm = false, bool approx = false}) {
    _status = text;
    _statusIsWarm = text != null && warm;
    _statusIsApprox = text != null && approx;
  }

  String _sourceLabelOf(_RouteSuggestion r) => switch (r.sourceKind) {
        'catalog' => _l10n.discoverCatalog,
        'osm' => _l10n.discoverOsmLive,
        'outdooractive' => 'Outdooractive',
        'seed' => _l10n.discoverRegionSource,
        _ => _l10n.discoverTourNoun,
      };

  /// Wechselt die Map-Shell (Entdecken | Navigieren | Meine).
  /// Detail wird geschlossen; berechnete Route bleibt auf der Karte.
  void _applyDiscoverLaunch(DiscoverLaunchMode? launch) {
    if (launch == null) return;
    ref.read(discoverLaunchModeProvider.notifier).state = null;
    if (launch == DiscoverLaunchMode.plan) {
      _hofChoice = false;
      _setShellMode(
        DiscoverShellMode.navigate,
        status: _l10n.discoverSetStartEnd,
        pick: _PickMode.start,
      );
      return;
    }
    if (launch == DiscoverLaunchMode.discover) {
      if (_hofChoice) setState(() => _hofChoice = false);
      return;
    }
    if (launch == DiscoverLaunchMode.mine) {
      setState(() => _hofChoice = false);
      _setShellMode(DiscoverShellMode.mine);
      unawaited(_consumePendingAkte());
      unawaited(_consumePendingStartRide());
      return;
    }
    if (launch == DiscoverLaunchMode.rideOut) {
      _hofJustRide();
      return;
    }
  }

  void _hofJustRide() {
    setState(() {
      _hofChoice = false;
      _selectedTourId = null;
    });
    ref.read(activeRouteProvider.notifier).state = null;
    ref.read(ridePendingGroupIdProvider.notifier).state = null;
    // Ein Tipp: HUD startet sofort — kein Navi-Symbol / „Ohne Route fahren“.
    ref.read(rideAutostartProvider.notifier).state = true;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
  }

  void _hofShowTours() {
    setState(() {
      _hofChoice = false;
    });
    unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.half));
  }

  /// Wechselt die Map-Shell (Entdecken | Navigieren | Meine).
  /// Detail wird geschlossen; berechnete Route bleibt auf der Karte.
  void _setShellMode(
    DiscoverShellMode mode, {
    String? status,
    _PickMode pick = _PickMode.none,
    String? adaptingTourName,
    bool clearAdapting = true,
  }) {
    if (mode != DiscoverShellMode.navigate) {
      _clearPlanAsGroupIfUnused();
    }
    final adapting = adaptingTourName != null ||
        (!clearAdapting && _adaptingTourName != null);
    if (mode == DiscoverShellMode.navigate) {
      _planInitialSnap = PlanSheetSnaps.openTarget(
        adapting: adapting,
        peekSnap: _planPeekSnap,
      );
      _planSheetExtentLogged = _planInitialSnap;
    }
    setState(() {
      _shellMode = mode;
      _detailId = null;
      _addrHits = const [];
      _error = null;
      if (clearAdapting && adaptingTourName == null) {
        _adaptingTourName = null;
        _adaptingTour = null;
      }
      if (adaptingTourName != null) {
        _adaptingTourName = adaptingTourName;
      }
      switch (mode) {
        case DiscoverShellMode.navigate:
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          _pick = pick;
          if (status != null) {
            _setStatus(status);
          } else if (_adaptingTourName != null) {
            if (_status == null) {
              _setStatus(_l10n.discoverAdjustStops);
            }
          } else {
            // Subtitle am Panel reicht — kein zweiter Hinweis-Text.
            _setStatus(null);
          }
        case DiscoverShellMode.explore:
          _surface = _Surface.discover;
          _pick = _PickMode.none;
          // Keine A→B-Hinweise mehr unter der Tourenliste.
          _setStatus(null);
          _rideBarExpanded = false;
        case DiscoverShellMode.mine:
          _surface = _Surface.discover;
          _pick = _PickMode.none;
          _showOwnTracks = true;
          _setStatus(null);
          _rideBarExpanded = false;
          _hofChoice = false;
          unawaited(_reloadSavedMeta());
      }
    });
    if (mode == DiscoverShellMode.explore || mode == DiscoverShellMode.mine) {
      unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.half));
    }
    if (mode == DiscoverShellMode.navigate) {
      unawaited(_hydratePlanGeocodeRecents());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_snapPlanSheet(_planInitialSnap));
      });
    }
    unawaited(_syncBikeOverlayVisibility());
  }

  /// Navigieren öffnen — A→B ist erster Klasse (nicht nur FAB „Route bauen").
  void _openPlan({String? status, _PickMode pick = _PickMode.none}) {
    _setShellMode(
      DiscoverShellMode.navigate,
      status: status,
      pick: pick,
      clearAdapting: true,
    );
  }

  /// Zurück nach Entdecken. Berechnete Route bleibt auf der Karte.
  void _closePlan() {
    _setShellMode(DiscoverShellMode.explore);
  }

  /// Tour-Detail öffnen — dritter Einstieg neben Discover/Planen, kein
  /// eigener Screen mehr. Die Karte zentriert sich auf die Tour, damit klar
  /// ist, wovon das Panel gerade erzählt (Komoot/AllTrails tun das genauso).
  Future<void> _openDetail(String tourId, LatLng center) async {
    _skipAutoCameraFit = false;
    _planInitialSnap = PlanSheetSnaps.form;
    _planSheetExtentLogged = PlanSheetSnaps.form;
    setState(() {
      _detailId = tourId;
      _selectedTourId = tourId;
      _surface = _Surface.detail;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_snapPlanSheet(PlanSheetSnaps.form));
    });
    // Höhenprofil im Hintergrund — braucht echte Geometrie (lädt bei Seeds
    // nebenbei das Live-Routing für Karte + Mini-Map nach).
    final tour = _tourById(tourId);
    if (tour != null) unawaited(_ensureDetailElevation(tour));
    unawaited(_loadCommunityHeroes(tourId));
    unawaited(_fetchCommunityPlaces());
    unawaited(_refreshStimmePlaces());
    unawaited(_refreshMeetPlaces());
    await _drawAll();
    if (!mounted) return;
    try {
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(center, 12.5));
    } catch (_) {}
    final poiId = _pendingPoiScrollId;
    if (poiId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flashAndScrollToPoi(poiId);
      });
    }
  }

  Future<void> _loadCommunityHeroes(String tourId) async {
    try {
      final urls = await TourCommunityStore().cloudPhotoUrls(tourId);
      if (!mounted || urls.isEmpty) return;
      setState(() => _communityHeroUrls[tourId] = urls);
    } catch (_) {}
  }

  /// Zurück aus dem Detail nach Discover. `_selectedTourId` bleibt bewusst
  /// gesetzt — die Tour soll in Liste und Karte hervorgehoben bleiben,
  /// nicht beim Schließen des Panels wieder verschwinden.
  void _closeDetail() {
    setState(() {
      _detailId = null;
      _surface = _Surface.discover;
      _shellMode = DiscoverShellMode.explore;
      _highlightPoiId = null;
      _pendingPoiScrollId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.peek));
    });
  }

  /// Inner map/sheet state that system-back must pop before leaving Karte.
  bool get hasInnerBack {
    if (_hofChoice) return true;
    if (_surface == _Surface.detail) return true;
    if (_pick != _PickMode.none) return true;
    if (_shellMode == DiscoverShellMode.navigate) return true;
    if (_planSheetActive && !PlanSheetSnaps.isPeek(_planSheetExtent)) {
      return true;
    }
    if (_shellMode == DiscoverShellMode.mine) return true;
    if (_showRideBar && _rideBarExpanded) return true;
    if (_listBrowseMode) return true;
    if (DiscoverBrowseSheetSnaps.isHalf(_discoverSheetExtent) ||
        DiscoverBrowseSheetSnaps.isFull(_discoverSheetExtent)) {
      return true;
    }
    if (DiscoverExploreChromeLogic.showIdlePeek(
      _hofPinLoopId ?? _selectedTourId,
    )) {
      return true;
    }
    return false;
  }

  /// Tour-Detail → Liste → Karten-Peek. `false` = Shell soll nach Hof.
  bool handleSystemBack() {
    if (!mounted) return false;
    if (_hofChoice) {
      setState(() => _hofChoice = false);
      return true;
    }
    if (_surface == _Surface.detail) {
      if (!PlanSheetSnaps.isPeek(_planSheetExtent)) {
        unawaited(_snapPlanSheet(_planPeekSnap));
        return true;
      }
      _closeDetail();
      return true;
    }
    if (_pick != _PickMode.none) {
      setState(() => _pick = _PickMode.none);
      return true;
    }
    if (_shellMode == DiscoverShellMode.navigate) {
      if (!PlanSheetSnaps.isPeek(_planSheetExtent)) {
        unawaited(_snapPlanSheet(_planPeekSnap));
        return true;
      }
      _closePlan();
      return true;
    }
    if (_shellMode == DiscoverShellMode.mine) {
      _setShellMode(DiscoverShellMode.explore);
      return true;
    }
    if (_showRideBar && _rideBarExpanded) {
      setState(() => _rideBarExpanded = false);
      return true;
    }
    if (_listBrowseMode ||
        DiscoverBrowseSheetSnaps.isHalf(_discoverSheetExtent) ||
        DiscoverBrowseSheetSnaps.isFull(_discoverSheetExtent)) {
      unawaited(
        _snapDiscoverSheet(
          DiscoverBrowseSheetSnaps.mapTarget(
            hasSelection: _hasExploreSelection,
          ),
        ),
      );
      return true;
    }
    if (DiscoverExploreChromeLogic.backClearsSelection(
      selectedTourId: _hofPinLoopId ?? _selectedTourId,
      atPeek: true,
    )) {
      _clearExploreSelection();
      return true;
    }
    if (DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent) &&
        !_hasExploreSelection) {
      unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.closed));
      return true;
    }
    return false;
  }

  void _clearExploreSelection() {
    setState(() {
      _hofPinLoopId = null;
      _selectedTourId = null;
      _computed = null;
      _label = null;
      _approach = null;
      _tourLayer = null;
    });
    ref.read(discoverPendingLoopIdProvider.notifier).state = null;
    unawaited(_drawAll());
    unawaited(
      _snapDiscoverSheet(DiscoverBrowseSheetSnaps.closed),
    );
  }

  String _queryForAddrTarget(String target) {
    if (target == 'end') return _endAddrCtrl.text;
    if (target.startsWith('via:')) {
      final i = int.tryParse(target.substring(4));
      if (i != null && i >= 0 && i < _vias.length) {
        return _vias[i].trimmedLabel ?? '';
      }
      return '';
    }
    return _startAddrCtrl.text;
  }

  void _scheduleAddressSearch(String target, {String? query}) {
    _addrDebounce?.cancel();
    _addrDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_searchAddress(target, query: query));
    });
  }

  Future<void> _searchAddress(String target, {String? query}) async {
    final q = (query ?? _queryForAddrTarget(target)).trim();
    if (q.trim().length < 2) {
      setState(() {
        _addrHits = const [];
        _addrBusy = false;
        _addrTarget = target;
      });
      return;
    }
    setState(() {
      _addrBusy = true;
      _addrTarget = target;
    });
    if (BrowsePlaceSearch.needsNetwork(q) && !await _discoverHasNetwork()) {
      if (!mounted) return;
      setState(() {
        _addrHits = const [];
        _addrBusy = false;
        _setStatus(_l10n.discoverSearchNeedNet);
      });
      return;
    }
    try {
      final o = _origin;
      final hits = await _geocode.search(q, biasLat: o.lat, biasLng: o.lng);
      if (!mounted) return;
      if (hits.length == 1 && hits.first.kind == 'coords') {
        setState(() {
          _addrHits = const [];
          _addrBusy = false;
        });
        await _applyAddressHit(hits.first);
        return;
      }
      setState(() {
        _addrHits = hits;
        _addrBusy = false;
        if (hits.isEmpty) {
          _setStatus(_l10n.discoverNoHitsFor(q));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addrBusy = false;
        _setStatus(friendlyErrorMessage(
          e,
          context: _l10n.discoverGeocodeFailed,
        ));
      });
    }
  }

  PlanWaypointRole _planHitSlot() => planGeocodeHitSlot(
        hasStart: _start != null,
        hasEnd: _end != null,
        pickingVia: _pick == _PickMode.via,
        pickingEnd: _pick == _PickMode.end,
        pickingStart: _pick == _PickMode.start,
        startFieldFocused: _startAddrFocus.hasFocus,
        endFieldFocused: _endAddrFocus.hasFocus,
      );

  Future<void> _applyAddressHit(GeocodeHit hit) async {
    final viaIndex = _addrTarget != null && _addrTarget!.startsWith('via:')
        ? int.tryParse(_addrTarget!.substring(4))
        : null;
    // Active search hits keep their field target; Recents use focus/slot logic
    // so a stale `_addrTarget` cannot overwrite Start once A is set.
    final PlanWaypointRole slot;
    if (viaIndex != null) {
      slot = PlanWaypointRole.via;
    } else if (_addrHits.isNotEmpty && _addrTarget == 'end') {
      slot = PlanWaypointRole.end;
    } else if (_addrHits.isNotEmpty && _addrTarget == 'start') {
      slot = PlanWaypointRole.start;
    } else {
      slot = _planHitSlot();
    }
    if (slot == PlanWaypointRole.via && viaIndex == null) {
      _addGeocodeHitAsVia(hit);
      return;
    }
    final p = GeoPoint(hit.lat, hit.lng);
    final becameOrigin =
        slot == PlanWaypointRole.start && _userPos == null && _start == null;
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      if (slot == PlanWaypointRole.end) {
        _end = p;
        _endAddrCtrl.text = hit.label;
        _pick = _PickMode.none;
        _destinationTrail = null;
      } else if (slot == PlanWaypointRole.via &&
          viaIndex != null &&
          viaIndex >= 0 &&
          viaIndex < _vias.length) {
        final old = _vias[viaIndex];
        _vias[viaIndex] = LabeledVia(
          lat: p.lat,
          lng: p.lng,
          label: hit.label,
          placeId: old.placeId,
          kind: old.kind,
        );
        _pick = _PickMode.none;
      } else {
        _start = p;
        _startAddrCtrl.text = hit.label;
        _pick = _end == null ? _PickMode.end : _PickMode.none;
      }
      _addrHits = const [];
      _addrTarget = null;
      _geocodeRecents = _pushGeocodeRecentList(hit);
      _setStatus(_l10n.discoverStartEndHit(
        slot == PlanWaypointRole.end
            ? _l10n.navigateEndLabel
            : slot == PlanWaypointRole.via
                ? _l10n.navigateAddVia
                : _l10n.navigateStartLabel,
        hit.label,
      ));
    });
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_persistGeocodeRecents(_geocodeRecents));
    if (slot == PlanWaypointRole.end) unawaited(_rememberLastPlanDest());
    await _syncMarkers();
    if (_map != null && slot != PlanWaypointRole.via) {
      try {
        await _map!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(hit.lat, hit.lng), 12),
        );
      } catch (_) {}
    }
    if (slot == PlanWaypointRole.start || becameOrigin) {
      _refreshNearbyDataSources();
    }
    if (_start != null && _end != null) {
      await _calcAb(keepLine: _hasLivePlanLine, refitPins: false);
    }
  }

  void _addGeocodeHitAsVia(GeocodeHit hit) {
    if (_start == null || _end == null) {
      unawaited(_routeToGeocodeHit(hit));
      return;
    }
    _abFromBrowsePin = false;
    _pushPlanUndo();
    final p = GeoPoint(hit.lat, hit.lng);
    final next = PlanSession.fromParts(
      start: _start,
      end: _end,
      vias: _vias,
    ).insertViaAlong(
      p,
      line: _planComputedLineLngLat(),
      label: hit.label,
      kind: hit.kind,
    );
    final dismissCoach = _planLineCoach;
    setState(() {
      _vias
        ..clear()
        ..addAll(next.labeledVias);
      _addrHits = const [];
      _addrTarget = null;
      _pick = _PickMode.none;
      _geocodeRecents = _pushGeocodeRecentList(hit);
      _trailOverlay = null;
      _tourLayer = null;
      if (dismissCoach) _planLineCoach = false;
    });
    if (dismissCoach) {
      unawaited(RidePrefs.setPlanLineCoachDismissed(true));
    }
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_persistGeocodeRecents(_geocodeRecents));
    unawaited(_syncMarkers());
    _schedulePlanReshape();
    if (!_afterPlanViaInserted()) {
      final last = _vias.isNotEmpty ? _vias.last : null;
      _showPlanStopHint(
        last != null ? GeoPoint(last.lat, last.lng) : p,
      );
    }
  }

  /// Tour-Idee als Plan-Draft: mit Live-Track Start/Ziel aus Polyline;
  /// ohne Track nur Ortspunkt-Pin + Ziel wählen.
  Future<void> _adoptTourIntoPlan(_RouteSuggestion tour) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routed = await _geometryForTour(tour);
      if (!mounted) return;
      final l10n = _l10n;

      if (routed.demo || routed.points.length < 2) {
        final pin = GeoPoint(tour.center.latitude, tour.center.longitude);
        final ab = pinOnlyAbEndpoints(
          pinLat: pin.lat,
          pinLng: pin.lng,
          startLat: _start?.lat,
          startLng: _start?.lng,
          userLat: _userPos?.lat,
          userLng: _userPos?.lng,
          preferGps: true,
        );
        final start = ab != null ? GeoPoint(ab.startLat, ab.startLng) : pin;
        final fromGps = _userPos != null && ab != null;
        setState(() {
          _start = start;
          _end = ab != null ? pin : null;
          _destinationTrail = null;
          _vias.clear();
          _computed = null;
          _tourLayer = null;
          _approach = null;
          _ideaPin = tour.center;
          _selectedTourId = tour.id;
          _label = l10n.discoverPlanName(tour.name);
          _adaptingTourName = tour.name;
          _adaptingTour = tour;
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
          // Tour, die gar nicht mehr gemeint war.
          _detailId = null;
          _pick = _PickMode.none;
          _startAddrCtrl.text = ab == null
              ? l10n.discoverPoiNamed(tour.name)
              : (fromGps ? l10n.discoverMyPosition : l10n.discoverOnMapPlace);
          _endAddrCtrl.text = ab != null
              ? l10n.discoverPoiNamed(tour.name)
              : l10n.discoverSuggestEnd;
          _setStatus(l10n.discoverIdeaStartSet);
          _loading = false;
        });
        await _drawAll();
        await _syncMarkers();
        unawaited(_reversePlanFieldLabels());
        if (_start != null && _end != null) {
          await _fitCameraToAbPins();
        } else {
          final map = _map;
          if (map != null) {
            await map.animateCamera(
              CameraUpdate.newLatLngZoom(tour.center, 12),
            );
          }
        }
        return;
      }

      final pts = routed.points;
      final start = pts.first;
      final end = pts.last;
      final result = RouteResult(
        coordinates: pts,
        distanceM: tour.distanceKm * 1000,
        durationS: tour.durationMin * 60.0,
        engine: 'tour-adopt',
      );
      setState(() {
        _start = start;
        _end = end;
        _vias.clear();
        _computed = result;
        _ideaPin = null;
        _selectedTourId = tour.id;
        _label = l10n.discoverPlanName(tour.name);
        _adaptingTourName = tour.name;
        _adaptingTour = tour;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
        // Tour, die gar nicht mehr gemeint war.
        _detailId = null;
        _pick = _PickMode.none;
        _startAddrCtrl.text = l10n.discoverOnMapPlace;
        _endAddrCtrl.text = l10n.discoverOnMapPlace;
        _setStatus(_l10n.discoverTourInPlan);
        _loading = false;
      });
      await _drawRoute(result);
      await _syncMarkers();
      unawaited(_reversePlanFieldLabels());
      unawaited(_refreshElevation(result));
      _schedulePlanReshape();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _liveRouteError(e);
        });
      }
    }
  }

  Future<void> _loadHeatmapConsent() async {
    try {
      final consents = await ref.read(garageRepositoryProvider).listConsents();
      if (!mounted) return;
      setState(() {
        _heatmapConsent = consents['heatmap_contribution'] == true;
      });
      if (_heatmapConsent) await _drawAll();
    } catch (_) {}
  }

  Future<void> _onHeatLayerTapped() async {
    if (!_heatmapConsent) {
      await openPrivacyScreen(context);
      if (mounted) await _loadHeatmapConsent();
      return;
    }
    setState(() => _showHeatLayer = !_showHeatLayer);
    unawaited(_drawAll());
  }

  Future<void> _fetchRoutingStatus() async {
    final s = await fetchRoutingStatus();
    if (!mounted) return;
    final valhalla = s?.valhalla == true;
    // Prod: no Demo-Geometrie / Routing-Key chrome (Q-BAR-DIS-01 / S25).
    if (!AppConfig.showRoutingDebug || !AppConfig.allowDemoContent) {
      setState(() {
        _valhallaLive = valhalla;
        if (!valhalla) _routeVariant = RouteVariant.planned;
        _routingStatusNote = null;
      });
      return;
    }
    if (s == null) {
      setState(() => _valhallaLive = false);
      return;
    }
    final text = s.bannerText;
    if (_suppressDemoGeometryBanner(text)) {
      setState(() {
        _valhallaLive = valhalla;
        if (!valhalla) _routeVariant = RouteVariant.planned;
        _routingStatusNote = null;
      });
      return;
    }
    setState(() {
      _valhallaLive = valhalla;
      if (!valhalla) _routeVariant = RouteVariant.planned;
      _routingStatusNote = text;
    });
  }

  Future<List<OfflinePackRow>> _ensureOfflineCatalog() {
    if (_offlineCatalog != null) return Future.value(_offlineCatalog!);
    return _offlineCatalogLoad ??= _loadOfflineCatalog();
  }

  Future<List<OfflinePackRow>> _loadOfflineCatalog() async {
    final merged = await loadOfflinePackCatalog();
    _offlineCatalog = merged;
    _offlineCatalogLoad = null;
    return merged;
  }

  List<({double lng, double lat})> _offlineViaLngLats() => [
        for (final v in _vias) (lng: v.lng, lat: v.lat),
      ];

  List<({double lng, double lat})> _offlineAlongLngLats([
    List<GeoPoint>? coords,
  ]) {
    final c = coords ?? _computed?.coordinates;
    if (c == null || c.length < 3) return const [];
    return sampleLngLats([
      for (final p in c) (lng: p.lng, lat: p.lat),
    ]);
  }

  String _navigateOfflineHintLabel(AppLocalizations l10n) {
    final pack = _navigateOfflinePack;
    if (pack == null) return l10n.navigateOfflineHint;
    return l10n.navigateOfflineHintForPack(
      l10n.overlayRegionNameFor(pack.id, pack.name),
      formatPackBytes(pack.routingBytes),
      packId: pack.id,
    );
  }

  Future<void> _refreshNavigateOfflineHint() async {
    final a = _start;
    final b = _end;
    if (a == null || b == null) {
      if ((_showNavigateOfflineHint || _navigateOfflinePack != null) &&
          mounted) {
        setState(() {
          _showNavigateOfflineHint = false;
          _navigateOfflinePack = null;
        });
        unawaited(_syncOfflineCoverageOverlay());
        unawaited(_syncMarkers(coalesce: true));
      }
      return;
    }
    final covered = await OfflinePackDirs.legitimateCoversRoute(
      fromLng: a.lng,
      fromLat: a.lat,
      toLng: b.lng,
      toLat: b.lat,
      vias: _offlineViaLngLats(),
      along: _offlineAlongLngLats(),
    );
    if (!mounted) return;
    if (covered) {
      if (_showNavigateOfflineHint || _navigateOfflinePack != null) {
        setState(() {
          _showNavigateOfflineHint = false;
          _navigateOfflinePack = null;
        });
        unawaited(_syncOfflineCoverageOverlay());
        unawaited(_syncMarkers(coalesce: true));
      }
      return;
    }
    OfflinePackRow? pack;
    try {
      pack = suggestedPackForRoute(
        packs: await _ensureOfflineCatalog(),
        fromLng: a.lng,
        fromLat: a.lat,
        toLng: b.lng,
        toLat: b.lat,
        extra: [
          ..._offlineViaLngLats(),
          ..._offlineAlongLngLats(),
        ],
      );
    } catch (_) {}
    if (!mounted) return;
    final offer = shouldOfferOfflinePackDownload(
      covered: false,
      suggestedPackId: pack?.id,
      installedIds: await OfflinePackDirs.legitimateIds(),
      hasActivatedPack: await OfflinePackDirs.hasLegitimateActivatedPack(),
    );
    if (!mounted) return;
    if (!offer) {
      if (_showNavigateOfflineHint || _navigateOfflinePack != null) {
        setState(() {
          _showNavigateOfflineHint = false;
          _navigateOfflinePack = null;
        });
        unawaited(_syncOfflineCoverageOverlay());
        unawaited(_syncMarkers(coalesce: true));
      }
      return;
    }
    if (!_showNavigateOfflineHint) {
      setState(() => _showNavigateOfflineHint = true);
    }
    if (_navigateOfflinePack?.id == pack?.id) {
      if (pack != null && _styleReady && !_suggestedCoverageLayerReady) {
        unawaited(_syncOfflineCoverageOverlay());
      }
      return;
    }
    setState(() => _navigateOfflinePack = pack);
    unawaited(_syncOfflineCoverageOverlay());
    unawaited(_syncMarkers(coalesce: true));
  }

  Future<void> _refreshOfflineChip() async {
    try {
      final m = await OfflineMapsPrefs.read();
      final path = (m['activatedPackPath'] as String?)?.trim() ?? '';
      final routing = await OfflinePackDirs.hasLegitimateActivatedPack();
      final bbox =
          routing ? await OfflinePackDirs.activatedCoverageBbox() : null;
      var overview = false;
      if (bbox != null && bbox.length >= 4) {
        try {
          overview = await OfflinePmtilesStore.isReady(
            basemapArchiveIdForBbox(bbox),
          );
        } catch (_) {}
        if ((m['basemapReady'] == true) != overview) {
          try {
            await OfflineMapsPrefs.merge({'basemapReady': overview});
          } catch (_) {}
        }
      }
      final rawName = (m['regionPack'] as String?)?.trim() ?? '';
      final id = OfflineMapsPrefs.packIdFromActivatedPath(path) ?? '';
      final packId = routing && id.isNotEmpty ? id : null;
      final label = !routing
          ? null
          : (id.isNotEmpty
              ? _l10n.overlayRegionNameFor(
                  id,
                  rawName.isEmpty ? id : rawName,
                )
              : (rawName.isEmpty ? null : rawName));
      if (!mounted) return;
      List<double>? streetBbox;
      StreetHudOfferKind? streetKind;
      var streetInstalled = false;
      if (routing && packId != null) {
        try {
          streetInstalled = await OfflineBasemap.hasStreetHudRegion(packId);
        } catch (_) {}
        if (streetInstalled &&
            OfflineMapsPrefs.streetHudPackIdFrom(m) == packId) {
          streetBbox = OfflineMapsPrefs.streetHudBboxFrom(m);
          streetKind = streetHudKindFromRaw(
            OfflineMapsPrefs.streetHudKindRawFrom(m),
          );
        }
      }
      if (!mounted) return;
      final bboxChanged = !_sameBbox(_offlinePackBbox, bbox);
      final streetChanged = !_sameBbox(_offlineStreetBbox, streetBbox) ||
          streetInstalled != _offlineStreetInstalled ||
          streetKind != _offlineStreetKind;
      List<List<double>>? ring = _offlinePackRing;
      var ringResolved = _offlinePackRingResolved;
      if (!routing) {
        ring = null;
        ringResolved = true;
      } else if (!_offlinePackRingResolved ||
          bboxChanged ||
          packId != _offlinePackId) {
        try {
          ring = (await OfflinePackDirs.activatedCoverageRingResult())?.outline;
          ringResolved = true;
        } catch (_) {
          ring = null;
          ringResolved = true;
        }
      }
      if (!mounted) return;
      if (routing == _offlineRoutingReady &&
          overview == _offlineOverviewReady &&
          label == _offlinePackLabel &&
          packId == _offlinePackId &&
          !bboxChanged &&
          ringResolved == _offlinePackRingResolved &&
          _sameRing(_offlinePackRing, ring) &&
          !streetChanged) {
        if (routing &&
            bbox != null &&
            bbox.length >= 4 &&
            _styleReady &&
            !_activeCoverageLayerReady) {
          unawaited(_syncOfflineCoverageOverlay());
        }
        return;
      }
      setState(() {
        _offlineRoutingReady = routing;
        _offlineOverviewReady = overview;
        _offlinePackBbox = bbox;
        _offlinePackRing = ring;
        _offlinePackRingResolved = ringResolved;
        _offlinePackLabel = label;
        _offlinePackId = packId;
        _offlineStreetBbox = streetBbox;
        _offlineStreetKind = streetKind;
        _offlineStreetInstalled = streetInstalled;
      });
      unawaited(_syncOfflineCoverageOverlay());
      unawaited(_syncMarkers(coalesce: true));
    } catch (_) {}
  }

  bool _sameBbox(List<double>? a, List<double>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length < 4 || b.length < 4) {
      return a == null && b == null;
    }
    for (var i = 0; i < 4; i++) {
      if ((a[i] - b[i]).abs() > 1e-6) return false;
    }
    return true;
  }

  bool _sameRing(List<List<double>>? a, List<List<double>>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) {
      return a == null && b == null;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].length < 2 || b[i].length < 2) return false;
      if ((a[i][0] - b[i][0]).abs() > 1e-7) return false;
      if ((a[i][1] - b[i][1]).abs() > 1e-7) return false;
    }
    return true;
  }

  bool get _coverageRiderIsOutside => coverageRiderOutside(
        lng: _userPos?.lng,
        lat: _userPos?.lat,
        bbox: _offlinePackBbox,
        routingReady: _offlineRoutingReady,
        ring: _offlinePackRing,
      );

  ({
    String label,
    bool outside,
    bool overview,
    bool needsNet,
    bool streetAway,
  })? _coverageEdgeInfo(AppLocalizations l10n) {
    if (_hofChoice || _surface != _Surface.discover) return null;
    final overviewStyle = !_browseOnline && isLocalOverviewStyleUrl(_mapStyle);
    final mapNeedsNet = !_browseOnline && !overviewStyle;
    if (_offlineRoutingReady) {
      final name = _offlinePackLabel?.trim() ?? '';
      if (name.isEmpty) return null;
      final outside = _coverageRiderIsOutside;
      final streetStale = _offlineStreetInstalled &&
          streetHudCoverageStale(
            kind: _offlineStreetKind,
            storedBbox: _offlineStreetBbox,
            userLng: _userPos?.lng,
            userLat: _userPos?.lat,
          );
      final streetReadyHere =
          _offlineStreetInstalled && !streetStale;
      final streetAway = streetStale;
      return (
        label: l10n.offlineCoverageEdgeFor(
          name,
          outside: outside,
          packId: _offlinePackId,
          overviewStyle: overviewStyle,
          mapNeedsNet: mapNeedsNet,
          streetAway: streetAway,
          streetReady: outside && streetReadyHere,
        ),
        outside: outside,
        overview: overviewStyle && !outside,
        needsNet: mapNeedsNet && !outside && !overviewStyle,
        streetAway:
            streetAway && !overviewStyle && !mapNeedsNet && !streetReadyHere,
      );
    }
    final sug = _navigateOfflinePack;
    if (sug == null) return null;
    final sugName = l10n.overlayRegionNameFor(sug.id, sug.name);
    return (
      label: l10n.offlineCoverageSuggested(sugName),
      outside: false,
      overview: false,
      needsNet: false,
      streetAway: false,
    );
  }

  Future<void> _syncOfflineCoverageOverlay({bool force = false}) async {
    final c = _map;
    if (c == null || !_styleReady) return;
    if (_styleAttachBusy && !force) return;
    try {
      var active = _offlineRoutingReady ? _offlinePackBbox : null;
      var suggested = _navigateOfflinePack?.bbox;
      if (_sameBbox(active, suggested)) suggested = null;
      if (coverageSuggestedOccludesActive(
        active: active,
        suggested: suggested,
      )) {
        suggested = null;
      }
      if (active != null && !_offlinePackRingResolved) {
        active = null;
      }
      if (active != null &&
          !coverageOverlayVisible(
            zoom: _mapZoom,
            bbox: active,
            packId: _offlinePackId,
          )) {
        active = null;
      }
      if (suggested != null &&
          !coverageOverlayVisible(
            zoom: _mapZoom,
            bbox: suggested,
            packId: _navigateOfflinePack?.id,
          )) {
        suggested = null;
      }
      final outside = _coverageRiderIsOutside;
      String? below;
      try {
        below = coverageSeatBelowLayerId(await c.getLayerIds());
      } catch (_) {}
      await syncCoverageWashOverlay(
        c,
        kind: CoverageWashKind.suggested,
        bbox: suggested,
        dimmed: !outside && active != null,
        emphasized: outside,
        belowLayerId: below,
      );
      await syncCoverageWashOverlay(
        c,
        kind: CoverageWashKind.active,
        bbox: active,
        ring: active == null ? null : _offlinePackRing,
        dimmed: false,
        emphasized: outside,
        belowLayerId: below,
      );
      var street = coverageStreetWashBbox(
        kind: _offlineStreetKind,
        streetBbox: _offlineStreetBbox,
        packBbox: _offlinePackBbox,
      );
      if (street != null &&
          !streetHudOverlayVisible(zoom: _mapZoom, bbox: street)) {
        street = null;
      }
      await syncCoverageWashOverlay(
        c,
        kind: CoverageWashKind.street,
        bbox: street,
        ring: street == null ? null : coverageBboxClosedRect(street),
        dimmed: false,
        emphasized: streetHudCoverageStale(
          kind: _offlineStreetKind,
          storedBbox: _offlineStreetBbox,
          userLng: _userPos?.lng,
          userLat: _userPos?.lat,
        ),
        belowLayerId: below,
      );
      _activeCoverageLayerReady = true;
      _suggestedCoverageLayerReady = true;
      _offlineCoverageRetries = 0;
    } catch (_) {
      _activeCoverageLayerReady = false;
      _suggestedCoverageLayerReady = false;
      if (_offlineCoverageRetries >= 3 || !mounted || !_styleReady) return;
      _offlineCoverageRetries += 1;
      unawaited(Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        unawaited(_syncOfflineCoverageOverlay());
      }));
    }
  }

  Future<bool> _probeBrowseNetwork() async {
    final online = await OfflineBasemap.hasNetwork();
    _browseOnline = online;
    _browseOnlineAt = DateTime.now();
    return online;
  }

  /// Reuse a recent *online* poll. Cached offline re-probes so a stale
  /// airplane-mode flag does not skip ORS.
  Future<bool> _discoverHasNetwork() async {
    if (trustCachedOnlineProbe(
      cachedOnline: _browseOnline,
      cachedAt: _browseOnlineAt,
      ttl: kPlanOnlineProbeTtl,
    )) {
      return true;
    }
    return _probeBrowseNetwork();
  }

  Future<void> _syncBrowseMapStyle() async {
    final online = await _probeBrowseNetwork();
    if (!mounted) return;
    await OfflineBasemap.applyNetworkMode(online: online);
    if (!mounted) return;
    final lng = _map?.cameraPosition?.target.longitude ?? _mapCenter.lng;
    final lat = _map?.cameraPosition?.target.latitude ?? _mapCenter.lat;
    final s = online
        ? AppConfig.browseMapStyleUrlFor(lng, lat)
        : await AppConfig.resolveBrowseMapStyleUrl(
            currentStyle: _mapStyle,
            packBbox: _offlinePackBbox,
          );
    if (!mounted || s == _mapStyle) return;
    final enteringOverview = !online &&
        isLocalOverviewStyleUrl(s) &&
        !isLocalOverviewStyleUrl(_mapStyle);
    setState(() {
      _mapStyle = s;
      _styleReady = false;
      _pinImagesReady = false;
    });
    if (enteringOverview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.offlineBrowseOverviewSnack)),
      );
    }
  }

  Future<void> _fitOfflinePackBbox() async {
    final ring = _offlinePackRing;
    final fromRing =
        ring != null && ring.length >= 4 ? coverageBboxOfRing(ring) : null;
    final bbox = (fromRing != null && fromRing.length >= 4)
        ? fromRing
        : _offlinePackBbox;
    if (bbox == null) return;
    await _fitCameraToBbox(bbox);
  }

  Future<void> _fitCameraToBbox(List<double> bbox, {bool force = false}) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    if (bbox.length < 4) return;
    if (!force) {
      if (skipFitCameraForPackId(_offlinePackId)) return;
      if (_surface != _Surface.discover) return;
      if (_computed != null) return;
      if (_hofPinLoopId != null || _selectedTourId != null) return;
    }
    _skipAutoCameraFit = true;
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(bbox[1], bbox[0]),
          northeast: LatLng(bbox[3], bbox[2]),
        ),
        left: 36,
        top: 110,
        right: 36,
        bottom: _panelInset + 36,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_syncBrowseMapStyle());
    unawaited(_refreshOfflineChip());
  }

  List<double>? _streetHudRouteBbox() {
    final computed = _computed;
    if (computed != null && computed.coordinates.length >= 2) {
      return streetHudBboxFromLngLats([
        for (final p in computed.coordinates) [p.lng, p.lat],
      ]);
    }
    final start = _start;
    final end = _end;
    if (start != null && end != null) {
      return streetHudBboxFromLngLats([
        [start.lng, start.lat],
        [end.lng, end.lat],
      ]);
    }
    return null;
  }

  List<List<double>>? _streetHudRouteLine() {
    final computed = _computed;
    if (computed != null && computed.coordinates.length >= 2) {
      return streetHudSketchLine([
        for (final p in computed.coordinates) [p.lng, p.lat],
      ]);
    }
    final start = _start;
    final end = _end;
    if (start != null && end != null) {
      return streetHudSketchLine([
        [start.lng, start.lat],
        [end.lng, end.lat],
      ]);
    }
    return null;
  }

  Future<void> _openOfflineMaps({GeoPoint? focus, String? focusPackId}) async {
    var paused = false;
    final changed = await openOfflineMapsSheet(
      context,
      // Honesty / Street: only real GPS — never map center.
      userLng: _userPos?.lng,
      userLat: _userPos?.lat,
      // Catalog sort: dest / map view is fine as bias.
      nearLng: focus?.lng ?? _mapCenter.lng,
      nearLat: focus?.lat ?? _mapCenter.lat,
      routeBbox: _streetHudRouteBbox(),
      routeLine: _streetHudRouteLine(),
      focusPackId: focusPackId,
      onDownloadPaused: () => paused = true,
      onShowOnMap: (bbox) {
        unawaited(_fitCameraToBbox(bbox, force: true));
      },
    );
    if (!mounted) return;
    if (paused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.offlineDownloadPaused)),
      );
    }
    await _refreshOfflineChip();
    unawaited(_refreshNavigateOfflineHint());
    await _syncBrowseMapStyle();
    if (!mounted) return;
    unawaited(_syncOfflineCoverageOverlay());
    unawaited(_syncMarkers(coalesce: true));
    if (changed == true) {
      if (!_styleReady) {
        _fitPackAfterStyle = true;
      } else {
        unawaited(_fitOfflinePackBbox());
      }
      if (!paused && _offlineRoutingReady) {
        final name = coverageGlanceName(_offlinePackLabel ?? '');
        final street = await OfflineBasemap.streetHudCoversActivatedPack(
          lng: _userPos?.lng,
          lat: _userPos?.lat,
        );
        if (!mounted) return;
        final outside = _coverageRiderIsOutside;
        final streetAway = _offlineStreetInstalled && !street;
        final snack = name.isEmpty
            ? (outside
                ? _l10n.offlineRoutingAway
                : _l10n.offlineGraphReadySnack)
            : _l10n.offlineMapsProfileSubtitle(
                ready: true,
                packId: _offlinePackId,
                packName: name,
                streetReady: street,
                outside: outside,
                streetAway: streetAway,
              );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snack)),
        );
      }
    }
  }

  Widget _browseLoadMapPackButton() {
    return TextButton(
      key: const Key('discover-load-map-pack'),
      onPressed: () => unawaited(
        _openOfflineMaps(focus: _end ?? _start ?? _userPos),
      ),
      child: Text(_l10n.discoverLoadMapPack),
    );
  }

  Widget _dropViasAndGoButton() {
    return TextButton(
      key: const Key('discover-drop-vias'),
      onPressed: _dropViasAndReroute,
      child: Text(_l10n.discoverViasDropAndGo),
    );
  }

  void _dropViasAndReroute() {
    unawaited(HapticFeedback.selectionClick());
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      _vias.clear();
      _error = null;
    });
    unawaited(_calcAb(keepLine: true, refitPins: false));
  }

  double get _resolvedExploreChromeHeight =>
      DiscoverExploreChromeLogic.resolvedChromeHeight(
        measured: _exploreChromeHeight,
        width: MediaQuery.sizeOf(context).width,
      );

  Future<void> _hydratePlanGeocodeRecents() async {
    try {
      final stored = await RidePrefs.planGeocodeRecents();
      final last = await RidePrefs.lastPlanDest();
      final lastDismissed =
          last != null && await RidePrefs.lastPlanDestIsDismissed(last);
      if (!mounted) return;
      final merged = mergePlanGeocodeRecents(stored, last);
      setState(() {
        _geocodeRecents = [
          for (final h in merged)
            GeocodeHit(label: h.label, lat: h.lat, lng: h.lng),
        ];
        _lastPlanDest = last;
        _lastPlanDestDismissed = lastDismissed;
      });
      final dismissed = await RidePrefs.planLineCoachDismissed();
      if (mounted) setState(() => _planLineCoach = !dismissed);
    } catch (_) {}
  }

  Future<void> _persistGeocodeRecents(List<GeocodeHit> hits) async {
    try {
      await RidePrefs.setPlanGeocodeRecents([
        for (final h in hits.take(5))
          PlanGeocodeRecent(label: h.label, lat: h.lat, lng: h.lng),
      ]);
    } catch (_) {}
  }

  List<GeocodeHit> _pushGeocodeRecentList(GeocodeHit hit) {
    return [
      hit,
      ..._geocodeRecents.where((e) => e.label != hit.label),
    ].take(5).toList();
  }

  void _rememberGeocodeHit(GeocodeHit hit) {
    final next = _pushGeocodeRecentList(hit);
    setState(() => _geocodeRecents = next);
    unawaited(_persistGeocodeRecents(next));
  }

  Future<void> _syncBikeOverlayVisibility() async {
    final c = _map;
    if (c == null || !_bikeOverlayAttached) return;
    await applyBikeOverlayVisibility(
      c,
      family: _overlayFamily,
      visible: _bikeOverlayOn,
      extraOn: _bikeOverlayExtra,
      hideFarmTracks: _hideFarmTracksOnBrowse,
      liveNetwork: _liveNetworkFallback(),
    );
  }

  Future<void> _loadFarmTrackPref() async {
    final on = await RidePrefs.showFarmTracks();
    if (!mounted || on == _showFarmTracksLayer) return;
    setState(() => _showFarmTracksLayer = on);
    unawaited(_syncBikeOverlayVisibility());
  }

  Future<void> _rememberLastPlanDest() async {
    final e = _end;
    if (e == null) return;
    if (!lastPlanDestWorthRemembering(
      destLat: e.lat,
      destLng: e.lng,
      originLat: (_start ?? _userPos)?.lat,
      originLng: (_start ?? _userPos)?.lng,
    )) {
      return;
    }
    final label = _endAddrCtrl.text.trim();
    try {
      final saved = LastPlanDest(
        lat: e.lat,
        lng: e.lng,
        label:
            label.isEmpty || label == _l10n.discoverOnMapPlace ? null : label,
      );
      await RidePrefs.setLastPlanDest(saved);
      _lastPlanDest = saved;
      _lastPlanDestDismissed = false;
      if (label.isNotEmpty && label != _l10n.discoverOnMapPlace) {
        if (!mounted) return;
        _rememberGeocodeHit(GeocodeHit(label: label, lat: e.lat, lng: e.lng));
      }
    } catch (_) {}
  }

  bool get _destShouldPulse =>
      _loading ||
      (_end != null && _start == null) ||
      (_planDestConfirmUntil != null &&
          DateTime.now().isBefore(_planDestConfirmUntil!));

  void _pulsePlanDest() {
    if (!mounted) return;
    setState(() {
      _planDestConfirmUntil =
          DateTime.now().add(const Duration(milliseconds: 1600));
    });
    _startDestPulse();
    unawaited(_syncPlanHintScreen());
    _planDestPulseTimer?.cancel();
    _planDestPulseTimer = Timer(const Duration(milliseconds: 1650), () {
      if (!mounted) return;
      setState(() => _planDestConfirmUntil = null);
      if (!_destShouldPulse) _stopDestPulse();
      unawaited(_syncMarkers());
    });
  }

  bool get _showPlanDestConfirm =>
      _surface == _Surface.plan &&
      _planDestConfirmUntil != null &&
      DateTime.now().isBefore(_planDestConfirmUntil!);

  bool get _showPlanRoutingWait =>
      planMapShowsRoutingWait(
        editorActive: _surface == _Surface.plan,
        routingBusy: _loading,
        hasStart: _start != null,
        hasEnd: _end != null,
      ) ||
      (_showPlanDestConfirm && !_hasLivePlanLine);

  bool get _planFingerAdaptingHint => planMapAdaptingHintOnMap(
        routingBusy: _loading,
        hasLiveLine: _hasLivePlanLine,
        hasFinger: _planShapeHintAt != null,
      );

  bool get _planDestWaitHint => planMapDestWaitHintOnMap(
        editorActive: _surface == _Surface.plan,
        routingBusy: _loading,
        hasStart: _start != null,
        hasEnd: _end != null,
        fingerHint: _planFingerAdaptingHint,
        destConfirm: _showPlanDestConfirm,
        hasLiveLine: _hasLivePlanLine,
      );

  bool get _planWaitHintOnMap =>
      _planFingerAdaptingHint || _planDestWaitHint;

  bool get _planStopHintActive => planMapStopHintVisible(
        hasStopAt: _planStopHintAt != null &&
            _planStopHintUntil != null &&
            DateTime.now().isBefore(_planStopHintUntil!),
        waitHintOnMap: _planWaitHintOnMap,
        rubberBand: _planDragAlongLabel != null,
      );

  bool get _planMapHintOnMap =>
      _planWaitHintOnMap || _planStopHintActive;

  PlanMapDestWaitCopy get _planDestWaitCopy => planMapDestWaitCopy(
        hasStart: _start != null,
        hasLiveLine: _hasLivePlanLine,
      );

  bool get _planWaitHidesChrome =>
      _planFingerAdaptingHint || (_planDestWaitHint && _start != null);

  LatLng? get _planMapHintAt {
    if (_planFingerAdaptingHint) return _planShapeHintAt;
    if (_planDestWaitHint) {
      final end = _end;
      if (end == null) return null;
      return LatLng(end.lat, end.lng);
    }
    if (_planStopHintActive) return _planStopHintAt;
    return null;
  }

  bool get _planMapHintWideChip =>
      _planStopHintActive ||
      (_planDestWaitHint &&
          _planDestWaitCopy != PlanMapDestWaitCopy.adapting);

  bool get _keepPlanSharedDisc =>
      _planDragAlongLabel != null ||
      _planElevScrubT != null ||
      _planFingerAdaptingHint;

  bool get _planChevronFresh =>
      _planChevronFreshUntil != null &&
      DateTime.now().isBefore(_planChevronFreshUntil!);

  void _markPlanChevronsFresh() {
    _planChevronFreshTimer?.cancel();
    _planChevronFreshUntil = DateTime.now().add(kPlanChevronFresh);
    _planChevronFreshTimer = Timer(kPlanChevronFresh, () {
      _planChevronFreshUntil = null;
      if (!mounted || _planRibbonDimmed) return;
      unawaited(_refreshPlanChevronOpacity());
    });
    unawaited(_refreshPlanChevronOpacity());
  }

  Future<void> _refreshPlanChevronOpacity() async {
    final c = _map;
    if (c == null) return;
    final opacity = planChevronIconOpacity(
      dimmed: _planRibbonDimmed,
      fresh: _planChevronFresh,
    );
    for (final s in List<Symbol>.of(_planChevronSymbols)) {
      try {
        await c.updateSymbol(s, SymbolOptions(iconOpacity: opacity));
      } catch (_) {}
    }
  }

  bool get _offerLastPlanDest {
    final last = _lastPlanDest;
    if (last == null) return false;
    final cam = _map?.cameraPosition?.target;
    return planLastDestShouldOffer(
      hasEnd: _end != null,
      dismissed: _lastPlanDestDismissed,
      nearby: lastPlanDestIsNearby(
        destLat: last.lat,
        destLng: last.lng,
        gpsLat: _userPos?.lat,
        gpsLng: _userPos?.lng,
        viewLat: cam?.latitude ?? _mapCenter.lat,
        viewLng: cam?.longitude ?? _mapCenter.lng,
      ),
    );
  }

  String _lastPlanDestChipText() {
    final last = _lastPlanDest;
    if (last == null) return _l10n.discoverLastDestChipGeneric;
    final name = lastPlanDestChipLabel(
      savedLabel: last.label,
      generic: '',
    );
    if (name.isEmpty) return _l10n.discoverLastDestChipGeneric;
    return _l10n.discoverLastDestChip(name);
  }

  void _dismissLastPlanDestChip() {
    final last = _lastPlanDest;
    if (last == null) return;
    setState(() => _lastPlanDestDismissed = true);
    unawaited(RidePrefs.dismissLastPlanDest(last));
  }

  void _applyLastPlanDest() {
    final last = _lastPlanDest;
    if (last == null) return;
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      _end = GeoPoint(last.lat, last.lng);
      final name = last.label?.trim() ?? '';
      _endAddrCtrl.text = name.isEmpty ? _l10n.discoverOnMapPlace : name;
      if (_start == null) {
        final o = _riderOrigin ?? _userPos;
        if (o != null) {
          _start = o;
          _startAddrCtrl.text = _l10n.discoverMyPosition;
        }
      }
      _pick = _PickMode.none;
    });
    _pulsePlanDest();
    unawaited(_syncMarkers());
    if (_start != null) unawaited(_calcAb());
    _showPlanStopHint(
      GeoPoint(last.lat, last.lng),
      label: _l10n.discoverLastDestApplied,
    );
  }

  double get _destPinPulseT => (math.sin(_destPulseTick * 0.9) + 1) / 2;

  void _startDestPulse() {
    if (_destPulseTimer != null) return;
    _destPulseTick = 0;
    _destPulseTimer = Timer.periodic(const Duration(milliseconds: 720), (_) {
      unawaited(_tickDestPulse());
    });
  }

  void _stopDestPulse({bool reset = true}) {
    _destPulseTimer?.cancel();
    _destPulseTimer = null;
    _destPulseTick = 0;
    if (reset) unawaited(_applyDestPulseSize(reset: true));
  }

  Future<void> _tickDestPulse() async {
    if (!mounted || !_destShouldPulse) {
      _stopDestPulse();
      return;
    }
    if (_cameraMoving) return;
    _destPulseTick++;
    await _applyDestPulseSize();
  }

  Future<void> _applyDestPulseSize({bool reset = false}) async {
    final sym = _planEndSymbol;
    final glow = _planEndGlowSymbol;
    final c = _map;
    if (c == null) return;
    final pulsing = !reset && _destPulseTimer != null;
    final t = _destPinPulseT;
    final destBusy = _planningAb || _loading || _destShouldPulse;
    final size = destPinPulseIconSize(
      busy: destBusy,
      pulsing: pulsing,
      t: t,
    );
    try {
      if (sym != null) {
        await c.updateSymbol(
          sym,
          SymbolOptions(
            iconSize: size,
            textHaloWidth: pulsing ? (1.4 + t * 0.8) : 1.2,
          ),
        );
      }
      if (glow != null) {
        await c.updateSymbol(
          glow,
          SymbolOptions(
            iconSize: pulsing
                ? mapPinSdfIconSize(0.78 + t * 0.32)
                : mapPinSdfIconSize(0.88),
            iconOpacity: pulsing ? (0.35 + t * 0.28) : 0.5,
          ),
        );
      }
    } catch (_) {}
  }

  List<OsmTrailSegment> get _visibleTrailNetwork {
    var list = _trailNetwork;
    if (_trailScaleFilter.isNotEmpty) {
      list = [
        for (final t in list)
          if (_trailScaleFilter.contains(t.difficulty)) t,
      ];
    }
    return list;
  }

  Future<void> _fetchTrailNetwork() async {
    try {
      if (!_hasRealOrigin) {
        if (mounted) {
          setState(() {
            _trailNetworkStatus = _l10n.discoverNeedLocationTrails;
            _trailIsDegraded = true;
          });
        }
        return;
      }
      if (_browseOnlineAt == null) {
        await _probeBrowseNetwork();
        if (!mounted) return;
      }
      if (!_browseOnline) {
        if (mounted) {
          setState(() {
            _trailNetworkStatus = _l10n.discoverTrailOffline;
            _trailIsDegraded = true;
          });
        }
        return;
      }
      final o = _origin;
      if (mounted) {
        setState(() {
          _trailNetworkStatus = _l10n.discoverTrailLoading;
          _trailIsDegraded = false;
        });
      }
      final hits = await OsmTrailNetworkClient().fetchNearby(
        lat: o.lat,
        lon: o.lng,
        radiusKm: 8,
      );
      if (!mounted) return;
      setState(() {
        _trailNetwork = hits;
        _trailNetworkStatus = hits.isEmpty
            ? _l10n.discoverTrailEmpty
            : _l10n.discoverTrailCount(hits.length);
        _trailIsDegraded = hits.isEmpty;
      });
      await _drawAll();
    } catch (_) {
      if (mounted) {
        setState(() {
          _trailNetworkStatus = _l10n.discoverTrailOffline;
          _trailIsDegraded = true;
        });
      }
    }
  }

  /// Trail-Einstieg: Gravity nach Höhe (oben = Start), sonst nächstes Ende.
  Future<OrientedTrail> _orientTrail(OsmTrailSegment trail) async {
    final from = _riderOrigin ?? _origin;
    double? startElev;
    double? endElev;
    if (_navPolicy.orientByElevation && trail.geometry.length >= 2) {
      try {
        final e = await _routes.endpointElevations(
          GeoPoint(trail.geometry.first[1], trail.geometry.first[0]),
          GeoPoint(trail.geometry.last[1], trail.geometry.last[0]),
        );
        startElev = e.startM;
        endElev = e.endM;
      } catch (_) {}
    }
    return orientTrail(
      geometry: trail.geometry,
      fromLat: from.lat,
      fromLng: from.lng,
      startElevM: startElev,
      endElevM: endElev,
      preferDownhill: _navPolicy.orientByElevation,
    );
  }

  void _refreshNearbyDataSources() {
    unawaited(_fetchOutdooractive());
    unawaited(_fetchOsmRoutes());
    unawaited(_fetchTrailNetwork());
    unawaited(_fetchTrailforks());
    unawaited(_fetchCoverage());
  }

  Future<void> _fetchCoverage() async {
    if (!_hasRealOrigin) return;
    if (_browseOnlineAt == null) {
      await _probeBrowseNetwork();
      if (!mounted) return;
    }
    if (!_browseOnline) return;
    final o = _origin;
    final bike = switch (_overlayFamily) {
      BikeOverlayFamily.mtb => 'mtb',
      BikeOverlayFamily.gravel => 'gravel',
      BikeOverlayFamily.urban => 'urban',
      BikeOverlayFamily.road => 'road',
    };
    final snap = await CoverageClient().fetch(
      lat: o.lat,
      lng: o.lng,
      bike: bike,
    );
    if (!mounted || snap == null) return;
    setState(() {
      _googlePlaces = snap.places;
      if (!snap.inDach && snap.honestyLabel.isNotEmpty) {
        _setStatus(snap.honestyLabel);
      }
    });
    unawaited(_fetchCommunityPlaces());
    unawaited(_refreshStimmePlaces());
    unawaited(_refreshMeetPlaces());
    await _drawAll();
  }

  List<MapPlace> get _visibleMapPlaces {
    if (!_showPlacesLayer) return const [];
    final coverage = [
      for (final p in _googlePlaces)
        mapPlaceFromRaw(
          id: p.id,
          name: p.name,
          kind: p.kind,
          lat: p.center.latitude,
          lng: p.center.longitude,
          mapsUrl: p.mapsUrl,
        ),
    ];
    return mergeMapPlaces(
      coverage: coverage,
      community: _communityPlaces,
      stimme: _stimmePlaces,
      meets: _meetPlaces,
    );
  }

  List<GroupMeetPin> get _meetPins => groupMeetPinsOnExplore(
        groups: _meetGroups,
        memberGroupIds: _meetMemberIds,
        now: DateTime.now(),
        centerFor: (g) {
          final tour = _tourById(g.catalogTourId) ?? _tourById(g.savedRouteId);
          if (tour == null) return null;
          return (lat: tour.center.latitude, lng: tour.center.longitude);
        },
      );

  List<MapPlace> get _meetPlaces => [
        for (final p in _meetPins)
          MapPlace(
            id: p.placeId,
            name: p.label,
            kind: MapPlaceKind.meet,
            lat: p.lat,
            lng: p.lng,
            source: MapPlaceSource.meet,
            tourId: p.group.catalogTourId ?? p.group.savedRouteId,
          ),
      ];

  Future<void> _fetchCommunityPlaces() async {
    if (!_hasRealOrigin) return;
    final o = _origin;
    final snap = await CommunityPlacesClient().fetch(
      lat: o.lat,
      lng: o.lng,
      tourId: _selectedTourId ?? _detailId,
    );
    if (!mounted) return;
    setState(() => _communityPlaces = snap.places);
    unawaited(_syncMarkers());
  }

  Future<void> _refreshStimmePlaces() async {
    final id = _selectedTourId ?? _detailId;
    if (id == null || id.isEmpty) {
      if (_stimmePlaces.isNotEmpty && mounted) {
        setState(() => _stimmePlaces = const []);
      }
      return;
    }
    final bundle = await TourCommunityStore().mergeCloudBundle(id);
    if (!mounted) return;
    final pins = <MapPlace>[
      for (final r in bundle.reviews)
        if (r.pinLat != null && r.pinLng != null)
          MapPlace(
            id: 'stimme-${r.id}',
            name: r.tags.isNotEmpty
                ? r.tags.first
                : (r.body.trim().isEmpty || r.body.trim() == '—'
                    ? 'Stimme'
                    : r.body.trim()),
            kind: MapPlaceKind.tip,
            lat: r.pinLat!,
            lng: r.pinLng!,
            source: MapPlaceSource.stimme,
            tourId: r.tourId,
            tip: r.body,
          ),
    ];
    setState(() => _stimmePlaces = pins);
    unawaited(_syncMarkers());
  }

  Future<void> _refreshMeetPlaces() async {
    try {
      final store = RideGroupStore();
      final mine = await store.activeGroups();
      final pub = await store.publicGroups();
      final byId = <String, RideGroup>{
        for (final g in mine) g.id: g,
        for (final g in pub) g.id: g,
      };
      if (!mounted) return;
      setState(() {
        _meetGroups = byId.values.toList();
        _meetMemberIds = {for (final g in mine) g.id};
      });
      unawaited(_syncMarkers());
    } catch (_) {}
  }

  void _onMapCameraTick() {
    final moving = _map?.isCameraMoving ?? false;
    if (moving != _cameraMoving) {
      _cameraMoving = moving;
      _cameraMovedAt = DateTime.now();
    }
    if (_planMapHintOnMap) {
      _planHintCamTick.value++;
      _planHintScreenDebounce?.cancel();
      _planHintScreenDebounce = Timer(
        const Duration(milliseconds: 32),
        _syncPlanHintScreen,
      );
    } else if (_planHintScreen.value != null) {
      _planHintScreen.value = null;
    }
    if (_planEditorActive && _hasLivePlanLine) {
      _planGrabScreenDebounce?.cancel();
      _planGrabScreenDebounce = Timer(
        const Duration(milliseconds: 32),
        () => unawaited(_syncPlanGrabScreen()),
      );
    } else if (_planGrabScreen != null) {
      _planGrabScreen = null;
    }
  }

  Future<void> _syncPlanHintScreen() async {
    final c = _map;
    final at = _planMapHintAt;
    if (c == null || at == null || !_planMapHintOnMap) {
      if (_planHintScreen.value != null) _planHintScreen.value = null;
      return;
    }
    try {
      final p = await c.toScreenLocation(at);
      if (!mounted || !_planMapHintOnMap) return;
      final now = _planMapHintAt;
      if (now == null ||
          now.latitude != at.latitude ||
          now.longitude != at.longitude) {
        return;
      }
      _planHintScreen.value = Offset(p.x.toDouble(), p.y.toDouble());
    } catch (_) {}
  }

  Future<void> _syncPlanGrabScreen() async {
    if (!_planEditorActive || !_hasLivePlanLine) {
      _planGrabScreen = null;
      return;
    }
    final c = _map;
    final cam = c?.cameraPosition;
    final line = _planComputedLineLngLat();
    if (c == null || cam == null || line == null || line.length < 2) {
      _planGrabScreen = null;
      return;
    }
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final mapH = math.max(120.0, size.height - _panelInset);
    final sampled = planGrabScreenSample(
      line,
      zoom: cam.zoom,
      lat: cam.target.latitude,
      centerLng: cam.target.longitude,
      centerLat: cam.target.latitude,
      mapW: size.width,
      mapH: mapH,
      bearingDeg: cam.bearing,
      tiltDeg: cam.tilt,
    );
    final pins = _planGrabAvoidPins();
    final gen = ++_planGrabScreenGen;
    try {
      final linePts = await c.toScreenLocationBatch([
        for (final p in sampled) LatLng(p[1], p[0]),
      ]);
      if (gen != _planGrabScreenGen || !mounted) return;
      final pinPts = pins.isEmpty
          ? const <math.Point<num>>[]
          : await c.toScreenLocationBatch([
              for (final p in pins) LatLng(p[1], p[0]),
            ]);
      if (gen != _planGrabScreenGen || !mounted) return;
      if (linePts.length != sampled.length) return;
      _planGrabScreen = PlanGrabScreenCache(
        lineScreen: [
          for (final p in linePts) (x: p.x.toDouble(), y: p.y.toDouble()),
        ],
        lineLngLat: sampled,
        pinScreen: [
          for (final p in pinPts) (x: p.x.toDouble(), y: p.y.toDouble()),
        ],
      );
    } catch (_) {}
  }

  Future<({double lat, double lng})?> _planNativeUnproject(
    double x,
    double y,
  ) async {
    final c = _map;
    if (c == null) return null;
    try {
      final ll = await c.toLatLng(math.Point<num>(x, y));
      return (lat: ll.latitude, lng: ll.longitude);
    } catch (_) {
      return null;
    }
  }

  void _clearLeftoverRouteForNewPin() {
    _calcAbGen++;
    _previewGen++;
    _calcAbDebounce?.cancel();
    _skipAutoCameraFit = false;
    _selectedTourId = null;
    _hofPinLoopId = null;
    _ideaPin = null;
    _tourLayer = null;
    _trailOverlay = null;
    _destinationTrail = null;
    _computed = null;
    _approach = null;
    _label = null;
    _vias.clear();
    _planLineTouched = false;
    _planPulseViaIndex = null;
    _planBendHighlightUntil = null;
  }

  /// Drop leftover tour when the rider places a new routing pin.
  /// Live street A–B stays until the engine returns. Returns true if a via
  /// was inserted (Komoot line-tap).
  bool _placePlanMapPoint(GeoPoint p, {OsmTrailSegment? trailHit}) {
    _lastRoutePinAt = DateTime.now();
    _lastMapTap = p;
    _lastMapTapAt = _lastRoutePinAt;
    final viaBefore = _vias.length;
    final leftover = planLeftoverTourWipesOnTap(
      leftover: mapPinClearsTourPreview(
        computedEngine: _computed?.engine,
        selectedTourId: _selectedTourId,
      ),
      hasStart: _start != null,
      hasEnd: _end != null,
      pickingVia: _pick == _PickMode.via,
    );
    final pinIsDest = mapPinIsGpsDestination(
      tourPreviewOnMap: leftover,
      leftoverRoute: leftover,
      hasGps: _userPos != null,
      startSet: _start != null,
      endSet: _end != null,
      pickingStart: _pick == _PickMode.start,
    );
    if (planDestPinKeepsSession(
      editorActive: _planEditorActive,
      startSet: _start != null,
      leftoverTour: leftover,
      pickingStart: _pick == _PickMode.start,
    )) {
      final line = _planComputedLineLngLat();
      final along = line == null
          ? null
          : projectOntoRoute(coordinates: line, lat: p.lat, lng: p.lng);
      if (planMapTapInsertsViaAlong(
        startSet: true,
        endSet: _end != null,
        pickingVia: _pick == _PickMode.via,
        pickingStart: false,
        pickingEnd: _pick == _PickMode.end,
        crossTrackM: along?.crossTrackM,
      )) {
        _insertPlanViaAlong(p);
        return true;
      }
      if (planFarTapInsertsVia(
        startSet: true,
        endSet: _end != null,
        pickingStart: false,
        pickingEnd: _pick == _PickMode.end,
      )) {
        _insertPlanViaAlong(p);
        return true;
      }
      if (planBusyBlocksDestReplace(
        routingBusy: _loading,
        hasStart: true,
        hasEnd: _end != null,
        pickingEnd: _pick == _PickMode.end,
      )) {
        return false;
      }
      _abFromBrowsePin = false;
      _pushPlanUndo();
      setState(() {
        _end = p;
        _endAddrCtrl.text = _l10n.discoverOnMapPlace;
        _pick = _PickMode.none;
        _destinationTrail = trailHit;
      });
      unawaited(HapticFeedback.lightImpact());
      unawaited(_rememberLastPlanDest());
      unawaited(_reversePlanFieldLabels());
      return false;
    }
    final line = _planComputedLineLngLat();
    final along = line == null
        ? null
        : projectOntoRoute(coordinates: line, lat: p.lat, lng: p.lng);
    final shapeVia = planMapTapInsertsViaAlong(
      startSet: _start != null,
      endSet: _end != null,
      pickingVia: _pick == _PickMode.via,
      pickingStart: _pick == _PickMode.start,
      pickingEnd: _pick == _PickMode.end,
      crossTrackM: along?.crossTrackM,
    );
    if (shapeVia) {
      _insertPlanViaAlong(p);
      return true;
    }
    if (planFarTapInsertsVia(
      startSet: _start != null,
      endSet: _end != null,
      pickingStart: _pick == _PickMode.start,
      pickingEnd: _pick == _PickMode.end,
    )) {
      _insertPlanViaAlong(p);
      return true;
    }
    if (planBusyBlocksDestReplace(
      routingBusy: _loading,
      hasStart: _start != null,
      hasEnd: _end != null,
      pickingStart: _pick == _PickMode.start,
      pickingEnd: _pick == _PickMode.end,
    )) {
      return false;
    }
    _pushPlanUndo();
    setState(() {
      if (leftover) _clearLeftoverRouteForNewPin();
      if (pinIsDest || leftover) _skipAutoCameraFit = false;
      if (pinIsDest) {
        if (_userPos != null) {
          _start = _userPos;
          _startAddrCtrl.text = _l10n.discoverMyPosition;
        } else {
          _start = null;
          _startAddrCtrl.clear();
        }
        _end = p;
        _endAddrCtrl.text = _l10n.discoverOnMapPlace;
        _pick = _PickMode.none;
        _vias.clear();
        _destinationTrail = trailHit;
        return;
      }
      switch (_pick) {
        case _PickMode.via:
          _insertPlanViaAlongInState(p);
          break;
        case _PickMode.end:
          _end = p;
          _endAddrCtrl.text = _l10n.discoverOnMapPlace;
          _pick = _PickMode.none;
          _destinationTrail = trailHit;
          break;
        case _PickMode.start:
          _start = p;
          _startAddrCtrl.text = _l10n.discoverOnMapPlace;
          _pick = _PickMode.end;
          break;
        case _PickMode.none:
          if (_start == null) {
            _start = p;
            _startAddrCtrl.text = _l10n.discoverOnMapPlace;
            _pick = _PickMode.end;
          } else if (_end == null) {
            _end = p;
            _endAddrCtrl.text = _l10n.discoverOnMapPlace;
            _destinationTrail = trailHit;
          } else {
            _insertPlanViaAlongInState(p);
          }
          break;
      }
    });
    if (pinIsDest) {
      unawaited(HapticFeedback.lightImpact());
      unawaited(_rememberLastPlanDest());
      unawaited(_syncBikeOverlayVisibility());
      if (_destShouldPulse) _startDestPulse();
    }
    if (_vias.length > viaBefore) _afterPlanViaInserted();
    unawaited(_reversePlanFieldLabels());
    return false;
  }

  List<List<double>>? _planComputedLineLngLat() {
    final coords = _computed?.coordinates;
    if (coords == null || coords.length < 2) return null;
    return [
      for (final c in coords) [c.lng, c.lat]
    ];
  }

  void _insertPlanViaAlongInState(GeoPoint raw, {String? label}) {
    final line = _planComputedLineLngLat();
    final p = _snapViaPoint(raw);
    if (plannedRouteViaIsDuplicate(
      vias: [
        for (final v in _vias) (lat: v.lat, lng: v.lng),
      ],
      lat: p.lat,
      lng: p.lng,
    )) {
      _pick = _PickMode.none;
      return;
    }
    final next = PlanSession.fromParts(
      start: _start,
      end: _end,
      vias: _vias,
    ).insertViaAlong(p, line: line, label: label ?? _l10n.discoverOnMapPlace);
    _vias
      ..clear()
      ..addAll(next.labeledVias);
    _pick = _PickMode.none;
  }

  void _insertPlanViaAlong(GeoPoint raw, {String? label}) {
    final now = DateTime.now();
    if (_lastPlanViaAlongAt != null &&
        now.difference(_lastPlanViaAlongAt!) <
            const Duration(milliseconds: 400)) {
      return;
    }
    _lastPlanViaAlongAt = now;
    _abFromBrowsePin = false;
    // Map / elev via — not a parked ribbon finger; avoid stale wait-chip.
    _planShapeHintAt = null;
    _pushPlanUndo();
    final dismissCoach = _planLineCoach;
    setState(() {
      _insertPlanViaAlongInState(raw, label: label);
      _trailOverlay = null;
      _tourLayer = null;
      if (dismissCoach) _planLineCoach = false;
    });
    if (dismissCoach) {
      unawaited(RidePrefs.setPlanLineCoachDismissed(true));
    }
    unawaited(HapticFeedback.selectionClick());
    unawaited(_reversePlanFieldLabels());
    _schedulePlanReshape();
    if (!_afterPlanViaInserted()) {
      final last = _vias.isNotEmpty ? _vias.last : null;
      _showPlanStopHint(
        last != null ? GeoPoint(last.lat, last.lng) : raw,
      );
    }
  }

  void _clearBrowseAnchorToGps() {
    final gps = _userPos;
    setState(() {
      _browseAnchor = null;
      _browseAnchorPinned = false;
      _browseAnchorLabel = null;
    });
    if (gps != null) {
      unawaited(
        _map?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(gps.lat, gps.lng), 13),
        ),
      );
    }
    _mergeCatalogNearOrigin();
  }

  bool _isPlanPlaceholderLabel(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    if (t == _l10n.discoverMyPosition) return false;
    if (t == _l10n.discoverOnMapPlace) return true;
    return geocodeHitFromCoordinates(t) != null;
  }

  Future<void> _reversePlanFieldLabels() async {
    Future<void> one(GeoPoint? p, TextEditingController ctrl) async {
      if (p == null) return;
      if (ctrl.text == _l10n.discoverMyPosition) return;
      if (!_isPlanPlaceholderLabel(ctrl.text)) return;
      final hit = await _geocode.reverse(p.lat, p.lng);
      if (!mounted || hit == null) return;
      if (ctrl.text == _l10n.discoverMyPosition) return;
      setState(() => ctrl.text = hit.label);
    }

    await one(_start, _startAddrCtrl);
    await one(_end, _endAddrCtrl);
    if (mounted) unawaited(_rememberLastPlanDest());
    for (var i = 0; i < _vias.length; i++) {
      final v = _vias[i];
      final cur = v.trimmedLabel ?? '';
      if (!_isPlanPlaceholderLabel(cur)) continue;
      final hit = await _geocode.reverse(v.lat, v.lng);
      if (!mounted || hit == null) continue;
      if (i >= _vias.length) continue;
      setState(() {
        _vias[i] = _vias[i].copyWith(label: hit.label);
      });
    }
    if (mounted) unawaited(_syncMarkers());
  }

  Future<void> _fitCameraToAbPins() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final from = _start ?? _userPos;
    final to = _end;
    if (from == null || to == null) return;
    _skipAutoCameraFit = false;
    final swLat = math.min(from.lat, to.lat);
    final swLng = math.min(from.lng, to.lng);
    final neLat = math.max(from.lat, to.lat);
    final neLng = math.max(from.lng, to.lng);
    try {
      if ((neLat - swLat).abs() < 1e-5 && (neLng - swLng).abs() < 1e-5) {
        await map.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(swLat, swLng), 14),
        );
      } else {
        await map.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(swLat, swLng),
              northeast: LatLng(neLat, neLng),
            ),
            left: 40,
            top: 110,
            right: 40,
            bottom: _panelInset + 40,
          ),
        );
      }
    } catch (_) {}
  }

  void _rememberMapPointer(GeoPoint p) {
    _lastMapPointer = p;
    _lastMapPointerAt = DateTime.now();
    _lastMapTap = p;
    _lastMapTapAt = DateTime.now();
  }

  GeoPoint? _recentMapPointer({
    Duration maxAge = const Duration(milliseconds: 800),
  }) {
    final at = _lastMapPointerAt;
    final p = _lastMapPointer;
    if (p == null || at == null) return null;
    if (DateTime.now().difference(at) > maxAge) return null;
    return p;
  }

  void _onMapFeatureTapped(
    dynamic id,
    math.Point<double> point,
    LatLng latLng,
    String layerId,
  ) {
    _rememberMapPointer(GeoPoint(latLng.latitude, latLng.longitude));
  }

  void _scheduleCalcAbFromMap({
    bool keepLine = false,
    bool refitPins = true,
  }) {
    if (_start == null || _end == null) return;
    if (refitPins) unawaited(_fitCameraToAbPins());
    unawaited(_drawAll());
    _calcAbDebounce?.cancel();
    _calcAbDebounce = Timer(kMapPinRouteCommitDelay, () {
      if (!mounted || _start == null || _end == null) return;
      unawaited(_calcAb(keepLine: keepLine, refitPins: refitPins));
    });
  }

  void _schedulePlanReshape({bool refitPins = false}) {
    _scheduleCalcAbFromMap(
      keepLine: _hasLivePlanLine,
      refitPins: refitPins,
    );
  }

  bool _tryInsertViaFromMapTap(GeoPoint tap, {bool onLine = false}) {
    if (_surface == _Surface.detail) return false;
    if (!planEditorMapTapAddsVia(
      editorActive: _planEditorActive,
      hasStart: _start != null,
      hasEnd: _end != null,
      pickingStartOrEnd: _pick == _PickMode.start || _pick == _PickMode.end,
    )) {
      return false;
    }
    // Ribbon already parked the finger; free-map tap must not reuse a stale one.
    if (!onLine) _planShapeHintAt = null;
    final computed = _computed;
    final line = computed != null && computed.coordinates.length >= 2
        ? [
            for (final p in computed.coordinates) [p.lng, p.lat],
          ]
        : null;
    if (line == null) {
      _insertPlanViaAlong(tap);
      return true;
    }
    final radius = plannedRouteTapRadiusM(_mapZoom);
    final snap = plannedRouteTapSnap(
      lineLngLat: line,
      tapLat: tap.lat,
      tapLng: tap.lng,
      maxOffsetM: onLine ? math.max(radius, 420) : radius,
    );
    if (snap == null) {
      _insertPlanViaAlong(tap);
      return true;
    }
    if (plannedRouteViaIsDuplicate(
      vias: [
        for (final v in _vias) (lat: v.lat, lng: v.lng),
      ],
      lat: snap.lat,
      lng: snap.lng,
    )) {
      unawaited(HapticFeedback.selectionClick());
      return true;
    }
    final session = PlanSession.fromParts(
      start: _start,
      end: _end,
      vias: _vias,
    ).insertViaAlong(
      GeoPoint(snap.lat, snap.lng),
      line: line,
      label: _l10n.discoverOnMapPlace,
    );
    _abFromBrowsePin = false;
    _lastRoutePinAt = DateTime.now();
    _pushPlanUndo();
    setState(() {
      _vias
        ..clear()
        ..addAll(session.labeledVias);
      _pick = _PickMode.none;
    });
    unawaited(HapticFeedback.selectionClick());
    final taught = _afterPlanViaInserted();
    unawaited(_syncMarkers());
    _schedulePlanReshape();
    if (!taught) {
      _showPlanStopHint(GeoPoint(snap.lat, snap.lng));
    }
    return true;
  }

  void _previewPlanDragAlong(
    LatLng current, {
    bool draggingStart = false,
    bool draggingEnd = false,
    int? draggingViaIndex,
  }) {
    final computed = _computed;
    final from = _start;
    final to = _end;
    if (computed == null ||
        computed.coordinates.length < 2 ||
        from == null ||
        to == null) {
      return;
    }
    if (!isPlanCustomizableLine(
      engine: computed.engine,
      coordinateCount: computed.coordinates.length,
    )) {
      return;
    }
    var finger = current;
    if (!draggingStart && !draggingEnd) {
      final snapped = _snapViaPoint(
        GeoPoint(current.latitude, current.longitude),
      );
      finger = LatLng(snapped.lat, snapped.lng);
    }
    final line = [
      for (final p in computed.coordinates) [p.lng, p.lat],
    ];
    final prog = projectOntoRoute(
      coordinates: line,
      lat: finger.latitude,
      lng: finger.longitude,
    );
    final km = planDragAlongLabelKm(prog.distanceAlongM);
    final label = _l10n.planAlongKm(km);
    final scrub = planElevScrubT(
      alongM: prog.distanceAlongM,
      lineLenM: routeLengthM(line),
    );
    if ((label != _planDragAlongLabel || scrub != _planElevScrubT) && mounted) {
      _planStopHintTimer?.cancel();
      _planStopHintTimer = null;
      setState(() {
        _planStopHintAt = null;
        _planStopHintLabel = null;
        _planStopHintUntil = null;
        _planDragAlongLabel = label;
        _planShapeHintAt = finger;
        if (scrub != null) _planElevScrubT = scrub;
      });
      if (!PlanSheetSnaps.isPeek(_planSheetExtent)) {
        unawaited(_snapPlanSheet(_planPeekSnap));
      }
      if (_planHintScreen.value != null) _planHintScreen.value = null;
    } else {
      _planShapeHintAt = finger;
    }
    if (scrub != null) _movePlanElevCursor(scrub);
    final band = planRubberBandLngLat(
      startLat: from.lat,
      startLng: from.lng,
      endLat: to.lat,
      endLng: to.lng,
      vias: [
        for (final v in _vias) (lat: v.lat, lng: v.lng),
      ],
      fingerLat: finger.latitude,
      fingerLng: finger.longitude,
      lineLngLat: line,
      draggingStart: draggingStart,
      draggingEnd: draggingEnd,
      draggingViaIndex: draggingViaIndex,
    );
    final map = _map;
    if (map != null) {
      final first = !_planRibbonDimmed;
      unawaited(
        syncPendingAbOverlay(
          map,
          line: [for (final p in band) LatLng(p[1], p[0])],
          kind: PendingAbKind.rubber,
          alongLabel: _l10n.planTickKm(km),
          labelAt: finger,
          raise: first,
        ),
      );
    }
    unawaited(_setPlanRibbonDim(true));
  }

  Future<void> _setPlanRibbonDim(bool dim) async {
    if (_planRibbonDimmed == dim) return;
    _planRibbonDimmed = dim;
    final gen = ++_planRibbonDimGen;
    final c = _map;
    if (c == null) return;
    try {
      await syncPlanRibbonOverlay(
        c,
        slices: dim ? const [] : _planRibbonSlices,
      );
    } catch (_) {}
    final lines = List<({Line line, double opacity})>.of(_planRibbonLines);
    for (final e in lines) {
      if (gen != _planRibbonDimGen) return;
      try {
        await c.updateLine(
          e.line,
          LineOptions(
            lineOpacity: planRibbonDimOpacity(e.opacity, dimmed: dim),
          ),
        );
      } catch (_) {}
    }
    final chevrons = List<Symbol>.of(_planChevronSymbols);
    for (final s in chevrons) {
      if (gen != _planRibbonDimGen) return;
      try {
        await c.updateSymbol(
          s,
          SymbolOptions(
            iconOpacity: planChevronIconOpacity(
              dimmed: dim,
              fresh: _planChevronFresh,
            ),
          ),
        );
      } catch (_) {}
    }
    final ticks = List<Symbol>.of(_planTickSymbols);
    for (final s in ticks) {
      if (gen != _planRibbonDimGen) return;
      try {
        await c.updateSymbol(
          s,
          SymbolOptions(textOpacity: dim ? 0 : 1),
        );
      } catch (_) {}
    }
    final elev = _planElevSymbol;
    if (elev != null) {
      try {
        await c.updateSymbol(
          elev,
          SymbolOptions(iconOpacity: dim ? 0 : 0.95),
        );
      } catch (_) {}
    }
    final discs = List<Symbol>.of(_planBendDiscSymbols);
    for (final s in discs) {
      if (gen != _planRibbonDimGen) return;
      try {
        await c.updateSymbol(
          s,
          SymbolOptions(
            iconOpacity: planGrabHandleOpacity(0.95, dimmed: dim),
          ),
        );
      } catch (_) {}
    }
    final bends = List<Symbol>.of(_planBendSymbols);
    for (final s in bends) {
      if (gen != _planRibbonDimGen) return;
      try {
        await c.updateSymbol(
          s,
          SymbolOptions(
            iconOpacity: planGrabHandleOpacity(0.58, dimmed: dim),
          ),
        );
      } catch (_) {}
    }
    final grabs = List<Line>.of(_planGrabLines);
    for (final line in grabs) {
      if (gen != _planRibbonDimGen) return;
      try {
        await c.updateLine(
          line,
          LineOptions(
            lineOpacity: dim ? 0 : DiscoverMapLineStyle.planGrabHaloOpacity,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _clearPlanDragPreview() async {
    final map = _map;
    if (map != null) {
      final hint = _planShapeHintAt;
      unawaited(
        syncPendingAbOverlay(
          map,
          line: null,
          kind: PendingAbKind.rubber,
          labelAt: hint,
        ),
      );
    }
    if (mounted && _planDragAlongLabel != null) {
      setState(() => _planDragAlongLabel = null);
    }
    await _setPlanRibbonDim(false);
    _planPulseChevronsOnDraw = true;
    _markPlanChevronsFresh();
    unawaited(_syncPlanHintScreen());
  }

  bool _isPlanLineGrab(String? sid) =>
      sid != null && _planGrabGeom.containsKey(sid);

  void _restorePlanGrabLine(String sid) {
    final geom = _planGrabGeom[sid];
    final c = _map;
    if (geom == null || c == null) return;
    for (final line in _planGrabLines) {
      if (line.id != sid) continue;
      unawaited(
        c.updateLine(
          line,
          LineOptions(
            geometry: geom,
            lineOpacity: 0,
          ),
        ),
      );
      return;
    }
  }

  bool _insertViaFromRibbonDrop(GeoPoint at) {
    final line = _planComputedLineLngLat();
    final snapped = _snapViaPoint(at);
    if (plannedRouteViaIsDuplicate(
      vias: [
        for (final v in _vias) (lat: v.lat, lng: v.lng),
      ],
      lat: snapped.lat,
      lng: snapped.lng,
    )) {
      return false;
    }
    final next = PlanSession.fromParts(
      start: _start,
      end: _end,
      vias: _vias,
    ).insertViaAlong(
      snapped,
      line: line,
      label: _l10n.discoverOnMapPlace,
    );
    setState(() {
      _vias
        ..clear()
        ..addAll(next.labeledVias);
      _planDragAlongLabel = null;
    });
    unawaited(HapticFeedback.selectionClick());
    if (!_afterPlanViaInserted()) {
      _showPlanStopHint(snapped);
    }
    return true;
  }

  List<List<double>> _planGrabAvoidPins() {
    final line = _planComputedLineLngLat();
    final pins = <List<double>>[
      if (_start != null) [_start!.lng, _start!.lat],
      if (_end != null) [_end!.lng, _end!.lat],
      for (final v in _vias) [v.lng, v.lat],
    ];
    if (line != null &&
        planReshapeHandlesReady(
          hasVia: _vias.isNotEmpty || _planLineTouched,
          coachVisible: false,
        )) {
      for (final h in planReshapeHandles(
        lineLngLat: line,
        vias: [
          for (final v in _vias) (lat: v.lat, lng: v.lng),
        ],
        zoom: _map?.cameraPosition?.zoom ?? _mapZoom,
      )) {
        pins.add([h.lng, h.lat]);
      }
    }
    return pins;
  }

  void _onPlanLineHoldCancel() {
    _planLineHoldTimer?.cancel();
    _planLineHoldTimer = null;
  }

  void _onPlanLinePointerDown(double lat, double lng) {
    _planPointerGrabbing = true;
    _planPointerHoldDidDest = false;
    _planLineHoldTimer?.cancel();
    final at = GeoPoint(lat, lng);
    _planLineHoldTimer = Timer(kPlanLineHold, () {
      if (!mounted || !_planPointerGrabbing || _planDragAlongLabel != null) {
        return;
      }
      _planPointerHoldDidDest = true;
      _planPointerGrabbing = false;
      _planShapeHintAt = LatLng(at.lat, at.lng);
      unawaited(_clearPlanDragPreview());
      _replacePlanDestFromMap(at);
    });
  }

  void _onPlanLinePointerMove(double lat, double lng) {
    if (!_planPointerGrabbing || _planPointerHoldDidDest) return;
    _planLineHoldTimer?.cancel();
    _previewPlanDragAlong(LatLng(lat, lng));
  }

  void _onPlanLinePointerUp(
    double lat,
    double lng, {
    required bool dragged,
  }) {
    _planLineHoldTimer?.cancel();
    if (_planPointerHoldDidDest) {
      _planPointerHoldDidDest = false;
      _planPointerGrabbing = false;
      return;
    }
    _planPointerGrabbing = false;
    final p = GeoPoint(lat, lng);
    if (dragged) {
      _planShapeHintAt = LatLng(lat, lng);
      unawaited(_clearPlanDragPreview());
      final undoLen = _planUndoStack.length;
      final redoLen = _planRedoStack.length;
      _pushPlanUndo();
      if (_insertViaFromRibbonDrop(p) && _start != null && _end != null) {
        _abFromBrowsePin = false;
        unawaited(_reversePlanFieldLabels());
        _scheduleCalcAbFromMap(keepLine: true, refitPins: false);
      } else {
        while (_planUndoStack.length > undoLen) {
          _planUndoStack.removeLast();
        }
        while (_planRedoStack.length > redoLen) {
          _planRedoStack.removeLast();
        }
      }
      return;
    }
    _planShapeHintAt = LatLng(lat, lng);
    unawaited(_clearPlanDragPreview());
    _tryInsertViaFromMapTap(p, onLine: true);
  }

  void _onPlanLinePointerCancel() {
    _planLineHoldTimer?.cancel();
    _planPointerGrabbing = false;
    _planPointerHoldDidDest = false;
    _planShapeHintAt = null;
    unawaited(_clearPlanDragPreview());
  }

  void _replacePlanDestFromMap(GeoPoint p) {
    if (!planLongPressSetsDest(
      editorActive: true,
      hasStart: _start != null,
      hasEnd: _end != null,
      pickingVia: _pick == _PickMode.via,
      pickingStart: _pick == _PickMode.start,
      tapHitsLine: true,
    )) {
      return;
    }
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      _end = p;
      _endAddrCtrl.text = _l10n.discoverOnMapPlace;
      _pick = _PickMode.none;
    });
    _pulsePlanDest();
    unawaited(HapticFeedback.lightImpact());
    unawaited(_rememberLastPlanDest());
    unawaited(_reversePlanFieldLabels());
    _scheduleCalcAbFromMap(keepLine: true);
  }

  Future<void> _routeToGeocodeHit(GeocodeHit hit) async {
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      _end = GeoPoint(hit.lat, hit.lng);
      _endAddrCtrl.text = hit.label;
      if (_start == null) {
        final o = _riderOrigin;
        if (o != null) {
          _start = o;
          _startAddrCtrl.text = _l10n.discoverMyPosition;
        }
      }
      _surface = _Surface.plan;
      _shellMode = DiscoverShellMode.navigate;
      _pick = _PickMode.none;
      _placeHits = const [];
      _exploreQuery = '';
    });
    await _syncMarkers();
    if (_start != null) await _calcAb();
  }

  Future<void> _routeToGeocodeHitAsStart(GeocodeHit hit) async {
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      _start = GeoPoint(hit.lat, hit.lng);
      _startAddrCtrl.text = hit.label;
      _surface = _Surface.plan;
      _shellMode = DiscoverShellMode.navigate;
      _pick = _end == null ? _PickMode.end : _PickMode.none;
      _placeHits = const [];
      _exploreQuery = '';
    });
    await _syncMarkers();
    if (_end != null) await _calcAb();
  }

  Future<void> _refinePlanEndWithOverlay(
    math.Point<double> point,
    GeoPoint raw,
  ) async {
    final trailHit = await _hitTestBikeOverlay(point);
    if (!mounted || trailHit == null) return;
    var resolved = trailHit;
    for (final t in _trailsForLastMile) {
      if (t.id == trailHit.id) {
        resolved = t;
        break;
      }
    }
    final mile = clipTrailLastMile(
      trailLngLat: resolved.geometry,
      fromLat: (_start ?? _riderOrigin)?.lat ?? _origin.lat,
      fromLng: (_start ?? _riderOrigin)?.lng ?? _origin.lng,
      toLat: raw.lat,
      toLng: raw.lng,
    );
    if (mile == null) return;
    if (!trailIsCorridorEligible(
      highway: resolved.highway,
      difficulty: resolved.difficulty,
    )) {
      return;
    }
    final snapped = GeoPoint(mile.destLat, mile.destLng);
    if ((snapped.lat - raw.lat).abs() < 1e-6 &&
        (snapped.lng - raw.lng).abs() < 1e-6) {
      return;
    }
    setState(() {
      _end = snapped;
      _endAddrCtrl.text = _l10n.discoverOnMapPlace;
      _destinationTrail = resolved;
    });
    await _syncMarkers();
    _schedulePlanReshape();
  }

  Future<OsmTrailSegment?> _hitTestBikeOverlay(math.Point<double> point) async {
    final c = _map;
    if (c == null || !_bikeOverlayAttached || !_bikeOverlayOn) return null;
    try {
      final rect = Rect.fromCenter(
        center: Offset(point.x, point.y),
        width: 18,
        height: 18,
      );
      final features = await c.queryRenderedFeaturesInRect(
        rect,
        kBikeOverlayQueryLayerIds,
        null,
      );
      for (final raw in features) {
        final trail = overlayFeatureToTrail(raw);
        if (trail == null) continue;
        if (!trailIsCorridorEligible(
          highway: trail.highway,
          difficulty: trail.difficulty,
        )) {
          continue;
        }
        return trail;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openOverlayTrail(OsmTrailSegment trail, {GeoPoint? at}) async {
    var resolved = trail;
    for (final t in _trailNetwork) {
      if (t.id == trail.id) {
        resolved = t;
        break;
      }
    }
    if (resolved.surface == null ||
        resolved.surface!.isEmpty ||
        resolved.geometry.length < 2) {
      final osmId = resolved.osmWayId;
      if (osmId != null) {
        final full = await OsmTrailNetworkClient().fetchByOsmId(osmId);
        if (full != null) resolved = full;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedTrailId = resolved.id;
      _selectedTourId = null;
      if (!_trailNetwork.any((t) => t.id == resolved.id)) {
        _trailNetwork = [resolved, ..._trailNetwork];
      }
      _setStatus(
          '${resolved.name} · ${resolved.difficultyLabel} · ${resolved.lengthKm.toStringAsFixed(1)} km');
    });
    await _showTrailSheet(resolved, at: at);
  }

  Future<void> _showTrailSheet(OsmTrailSegment trail, {GeoPoint? at}) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  trail.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    trail.difficultyLabel,
                    '${trail.lengthKm.toStringAsFixed(1)} km',
                    if (trail.surface != null)
                      _trailSurfaceLabel(l10n, trail.surface!),
                    if (trail.highway != null)
                      _trailHighwayLabel(l10n, trail.highway!),
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  [
                    l10n.discoverOsmLivePath,
                    if (trail.surface != null || trail.highway != null)
                      l10n.discoverOsmTags,
                    l10n.discoverTapMapTrails,
                    _navPolicy.isGravity
                        ? l10n.discoverTrailGravityHint
                        : l10n.discoverTrailApproachHint,
                  ].join(' — '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.l),
                ..._trailApproachActions(ctx, l10n, trail, at),
                if (trail.url != null) ...[
                  const SizedBox(height: AppSpacing.s),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(trail.url!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.discoverOpenOsm),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _trailApproachActions(
    BuildContext ctx,
    AppLocalizations l10n,
    OsmTrailSegment trail,
    GeoPoint? at,
  ) {
    final policy = _navPolicy;
    final from = _riderOrigin ?? _origin;
    var distKm = 0.0;
    if (trail.geometry.length >= 2) {
      final a = trail.geometry.first;
      final b = trail.geometry.last;
      distKm = math.min(
        trailAccessHaversineKm(from.lat, from.lng, a[1], a[0]),
        trailAccessHaversineKm(from.lat, from.lng, b[1], b[0]),
      );
    }
    final suggested = suggestedApproachKind(policy: policy, distanceKm: distKm);
    Widget filled(ApproachKind kind, Widget icon, String label) {
      return FilledButton.icon(
        onPressed: () {
          Navigator.pop(ctx);
          if (kind == ApproachKind.atStart) {
            unawaited(_adoptTrailAsOverlay(trail));
          } else {
            unawaited(_approachTrail(trail, at: at, kind: kind));
          }
        },
        icon: icon,
        label: Text(label),
      );
    }

    Widget outlined(ApproachKind kind, Widget icon, String label) {
      return OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(ctx);
          if (kind == ApproachKind.atStart) {
            unawaited(_adoptTrailAsOverlay(trail));
          } else {
            unawaited(_approachTrail(trail, at: at, kind: kind));
          }
        },
        icon: icon,
        label: Text(label),
      );
    }

    if (!policy.isGravity) {
      if (!_trailFitsGarage(trail)) {
        return [
          Text(
            l10n.discoverTrailUnsuitableForBike(
              l10n.bikeCategoryShort(_garageCategory ?? BikeCategory.urban),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ];
      }
      return [
        filled(
          ApproachKind.bicycle,
          const ChromeGlyph('nav', size: 20, color: AppColors.onAccent),
          l10n.discoverRideToTrailhead,
        ),
        const SizedBox(height: AppSpacing.s),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            unawaited(_adoptTrailAsOverlay(trail));
          },
          icon: const ChromeGlyph('split', size: 20),
          label: Text(l10n.discoverPutOnRoute),
        ),
      ];
    }

    final car = suggested == ApproachKind.auto
        ? filled(
            ApproachKind.auto,
            const ChromeGlyph('split', size: 20, color: AppColors.onAccent),
            l10n.discoverApproachByCar)
        : outlined(ApproachKind.auto, const ChromeGlyph('split', size: 20),
            l10n.discoverApproachByCar);
    final walk = suggested == ApproachKind.walk
        ? filled(
            ApproachKind.walk,
            const ChromeGlyph('locate', size: 20, color: AppColors.onAccent),
            l10n.discoverApproachOnFoot)
        : outlined(ApproachKind.walk, const ChromeGlyph('locate', size: 20),
            l10n.discoverApproachOnFoot);
    final start = suggested == ApproachKind.atStart
        ? filled(
            ApproachKind.atStart,
            const ChromeGlyph('flag', size: 20, color: AppColors.onAccent),
            l10n.discoverAtTrailStart)
        : outlined(ApproachKind.atStart, const ChromeGlyph('flag', size: 20),
            l10n.discoverAtTrailStart);
    return [
      car,
      const SizedBox(height: AppSpacing.s),
      walk,
      const SizedBox(height: AppSpacing.s),
      start,
      if (policy.allowPedalConnectors) ...[
        const SizedBox(height: AppSpacing.s),
        outlined(
          ApproachKind.bicycle,
          const ChromeGlyph('nav', size: 20),
          l10n.discoverApproachByBike,
        ),
      ],
    ];
  }

  String _trailSurfaceLabel(AppLocalizations l10n, String raw) {
    final s = raw.toLowerCase().trim();
    return switch (s) {
      'asphalt' || 'paved' || 'concrete' => l10n.filterSurfaceAsphalt,
      'gravel' || 'fine_gravel' || 'compacted' => l10n.filterSurfaceGravel,
      'ground' || 'dirt' || 'earth' || 'unpaved' => l10n.discoverSurfaceNature,
      'grass' => l10n.discoverSurfaceGrass,
      'wood' || 'boardwalk' => l10n.discoverSurfaceWood,
      _ => raw,
    };
  }

  String _trailHighwayLabel(AppLocalizations l10n, String raw) {
    final s = raw.toLowerCase().trim();
    return switch (s) {
      'path' => l10n.discoverHighwayPath,
      'track' => l10n.discoverHighwayTrack,
      'cycleway' => l10n.discoverHighwayCycle,
      'bridleway' => l10n.discoverHighwayBridle,
      'footway' => l10n.discoverHighwayFoot,
      _ => raw,
    };
  }

  Future<void> _approachTrail(
    OsmTrailSegment trail, {
    GeoPoint? at,
    ApproachKind? kind,
  }) async {
    if (!_trailFitsGarage(trail)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n.discoverTrailUnsuitableForBike(
                _l10n.bikeCategoryShort(_garageCategory ?? BikeCategory.urban),
              ),
            ),
          ),
        );
      }
      return;
    }
    final from = _riderOrigin;
    if (from == null) {
      if (mounted) {
        setState(() => _error = _l10n.discoverNeedLocationTrails);
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _selectedTrailId = trail.id;
      _destinationTrail = trail;
      _setStatus(_l10n.discoverApproachTrailhead);
    });
    try {
      if (at != null) {
        final mile = clipTrailLastMile(
          trailLngLat: trail.geometry,
          fromLat: from.lat,
          fromLng: from.lng,
          toLat: at.lat,
          toLng: at.lng,
        );
        final dest = mile != null ? GeoPoint(mile.destLat, mile.destLng) : at;
        final nudged = mile == null
            ? (lat: dest.lat, lng: dest.lng)
            : nudgeJoinTowardRider(
                joinLat: mile.joinLat,
                joinLng: mile.joinLng,
                fromLat: from.lat,
                fromLng: from.lng,
              );
        final join = GeoPoint(nudged.lat, nudged.lng);
        final distKm = trailAccessHaversineKm(
          from.lat,
          from.lng,
          join.lat,
          join.lng,
        );
        final chosen = kind ??
            suggestedApproachKind(policy: _navPolicy, distanceKm: distKm);
        if (chosen == ApproachKind.atStart) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (mile != null) {
            final trailPts = [
              for (final c in mile.geometry) GeoPoint(c[1], c[0]),
            ];
            setState(() {
              _approach = null;
              _trailOverlay = trailPts;
              _tourLayer = null;
              _computed = RouteResult(
                coordinates: trailPts,
                distanceM: mile.lastMileM,
                durationS: mile.lastMileM / 2.5,
                engine: 'osm-trail-last-mile',
              );
              _joinAlongM = 0;
              _gravityComputed = _navPolicy.isGravity;
              _label = trail.name;
              _start = dest;
              _end = trailPts.isEmpty ? dest : trailPts.last;
              _ideaPin = null;
              _surface = _Surface.plan;
              _shellMode = DiscoverShellMode.navigate;
              _detailId = null;
              _setStatus(_l10n.discoverTrailLaid(
                  trail.difficultyLabel, trail.lengthKm.toStringAsFixed(1)));
            });
            await _drawAll();
            await _syncMarkers();
            return;
          }
          await _adoptTrailAsOverlay(trail);
          return;
        }
        final costing = approachRoutingProfile(
          _garageCategory ?? BikeCategory.urban,
          chosen,
        );
        var approach = await _planRouteMaybeRetry(
          from: from,
          to: join,
          profile: costing,
          accessLeg: _navPolicy.isGravity,
        );
        RouteResult merged;
        List<GeoPoint>? trailPts;
        if (mile != null) {
          merged = _stitchApproachLastMile(approach, mile);
          trailPts = [for (final c in mile.geometry) GeoPoint(c[1], c[0])];
        } else {
          merged = approach;
        }
        if (!mounted) return;
        setState(() {
          _approach = approach;
          _trailOverlay = trailPts;
          _tourLayer = null;
          _computed = merged;
          _joinAlongM = approach.distanceM;
          _gravityComputed = _navPolicy.isGravity;
          _label = trail.name;
          _start = from;
          _end = dest;
          _ideaPin = null;
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          _detailId = null;
          _setStatus(_l10n.discoverApproachPlusTrail(
              (merged.distanceM / 1000).toStringAsFixed(1),
              trail.difficultyLabel));
          _loading = false;
        });
        await _drawAll();
        await _syncMarkers();
        await _refreshElevation(merged);
        return;
      }

      final oriented = await _orientTrail(trail);
      final entry = GeoPoint(oriented.entryLat, oriented.entryLng);
      final exit = GeoPoint(oriented.exitLat, oriented.exitLng);
      final distKm = trailAccessHaversineKm(
        from.lat,
        from.lng,
        entry.lat,
        entry.lng,
      );
      final chosen =
          kind ?? suggestedApproachKind(policy: _navPolicy, distanceKm: distKm);
      if (chosen == ApproachKind.atStart) {
        if (!mounted) return;
        setState(() => _loading = false);
        await _adoptTrailAsOverlay(trail);
        return;
      }
      final costing = approachRoutingProfile(
        _garageCategory ?? BikeCategory.urban,
        chosen,
      );
      final approach = await _planRouteMaybeRetry(
        from: from,
        to: entry,
        profile: costing,
        accessLeg: _navPolicy.isGravity,
      );
      final trailPts = [
        for (final p in oriented.geometry) GeoPoint(p[1], p[0]),
      ];
      final merged = RouteResult(
        coordinates: [...approach.coordinates, ...trailPts],
        distanceM: approach.distanceM + trail.lengthKm * 1000,
        durationS: approach.durationS + (trail.lengthKm / 12) * 3600,
        engine: '${approach.engine ?? 'engine'}+trail',
        steps: approach.steps,
      );
      if (!mounted) return;
      final elevHint = oriented.usedElevation
          ? _l10n.discoverTrailOrientedDownhill
          : (_navPolicy.orientByElevation
              ? _l10n.discoverTrailStartUphillUnknown
              : null);
      setState(() {
        _approach = approach;
        _trailOverlay = trailPts;
        _tourLayer = null;
        _computed = merged;
        _joinAlongM = approach.distanceM;
        _gravityComputed = _navPolicy.isGravity;
        _label = trail.name;
        _start = from;
        _end = exit;
        _ideaPin = null;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        _detailId = null;
        _setStatus([
          _l10n.discoverApproachPlusTrail(
            (merged.distanceM / 1000).toStringAsFixed(1),
            trail.difficultyLabel,
          ),
          if (elevHint != null) elevHint,
        ].join(' · '));
        _loading = false;
      });
      await _drawAll();
      await _syncMarkers();
      await _refreshElevation(merged);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _liveRouteError(e);
        });
      }
    }
  }

  Future<void> _adoptTrailAsOverlay(OsmTrailSegment trail) async {
    final oriented = await _orientTrail(trail);
    final trailPts = [for (final p in oriented.geometry) GeoPoint(p[1], p[0])];
    setState(() {
      _selectedTrailId = trail.id;
      _trailOverlay = trailPts;
      _approach = null;
      _joinAlongM = 0;
      _gravityComputed = _navPolicy.isGravity;
      _computed = RouteResult(
        coordinates: trailPts,
        distanceM: trail.lengthKm * 1000,
        durationS: (trail.lengthKm / 12) * 3600,
        engine: 'osm-trail',
      );
      _label = trail.name;
      _start = GeoPoint(oriented.entryLat, oriented.entryLng);
      _end = GeoPoint(oriented.exitLat, oriented.exitLng);
      _surface = _Surface.plan;
      _shellMode = DiscoverShellMode.navigate;
      _detailId = null;
      _setStatus(_l10n.discoverTrailLaid(
          trail.difficultyLabel, trail.lengthKm.toStringAsFixed(1)));
    });
    await _drawAll();
    await _syncMarkers();
  }

  Future<void> _fetchTrailforks() async {
    // Attribution-only API: center + URL, no polyline / no B.
    // TF pins look like rides without an end — keep them off Discover.
    if (_tfPins.isEmpty) return;
    if (mounted) setState(() => _tfPins = const []);
  }

  Future<void> _fetchOutdooractive() async {
    try {
      if (!_hasRealOrigin && !AppConfig.allowDemoContent) {
        if (mounted) {
          setState(() {
            _oaStatus = _l10n.discoverNeedLocationTours;
            _oaIsDegraded = true;
          });
        }
        return;
      }
      if (_browseOnlineAt == null) {
        await _probeBrowseNetwork();
        if (!mounted) return;
      }
      if (!_browseOnline) {
        if (mounted) {
          setState(() {
            _oaStatus = _l10n.discoverOaOffline;
            _oaIsDegraded = true;
          });
        }
        return;
      }
      final o = _origin;
      final uri =
          Uri.parse('${AppConfig.apiBaseUrl}/api/outdooractive').replace(
        queryParameters: {
          'type': 'tour',
          'lat': '${o.lat}',
          'lon': '${o.lng}',
        },
      );
      final res = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (mounted) {
          setState(() {
            _oaStatus = _l10n.discoverOaOffline;
            _oaIsDegraded = true;
          });
        }
        return;
      }
      final data = jsonDecode(res.body);
      if (data is! Map) return;
      final toursRaw = data['tours'] as List? ?? const [];
      final parsed = <_RouteSuggestion>[];
      for (final raw in toursRaw) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        // Nur echte Demo-Einträge überspringen — Flag usingDemoFallback darf
        // Live-Touren nicht mitlöschen.
        if (m['source'] == 'demo' && !AppConfig.allowDemoContent) continue;
        final id = (m['id'] as String?) ?? '';
        final title = (m['title'] as String?) ?? (m['name'] as String?) ?? '';
        if (id.isEmpty || title.isEmpty) continue;
        final centerRaw = m['center'];
        LatLng center = LatLng(o.lat, o.lng);
        if (centerRaw is List && centerRaw.length >= 2) {
          final lng = (centerRaw[0] as num).toDouble();
          final lat = (centerRaw[1] as num).toDouble();
          center = LatLng(lat, lng);
        }
        final difficulty = (m['difficulty'] as String?) ?? 'offen';
        final surface = _inferSurfaceTag(
          title: title,
          difficulty: difficulty,
          profile: _profile,
        );
        final track = _parseLngLatTrack(m['geometry'] ?? m['track']);
        if (track != null && track.length >= 2 && centerRaw is! List) {
          center = LatLng(track.first[1], track.first[0]);
        }
        var durationMin = (m['durationMin'] as num?)?.round() ?? 120;
        if (durationMin >= 1000) {
          durationMin = (durationMin / 60).round();
        }
        final oaType = (m['type'] as String?)?.trim();
        final oaTags = <String>[
          if (oaType != null && oaType.isNotEmpty) oaType,
          'outdooractive',
        ];
        parsed.add(
          _RouteSuggestion(
            id: id.startsWith('oa-') ? id : 'oa-$id',
            name: title,
            distanceKm: (m['lengthKm'] as num?)?.toDouble() ?? 20,
            elevationM: (m['elevationM'] as num?)?.round() ?? 0,
            durationMin: durationMin,
            mtbScale: difficulty,
            surface: surface,
            matchScore: track != null && isUsableMapTrack(track) ? 88 : 80,
            reasons: [
              if (m['summary'] is String) m['summary'] as String,
              if (track != null && isUsableMapTrack(track))
                'Outdooractive mit Track-Polyline'
              else if (track != null)
                'Outdooractive Track zu grob — Route wird nachberechnet'
              else
                'Outdooractive Enrichment (ohne Track — Route berechnen)',
              if (data['attribution'] is String) data['attribution'] as String,
            ],
            center: center,
            categories: TourFilters.inferCategories(
              title: title,
              type: oaType,
              difficulty: difficulty,
              surface: surface,
            ),
            // Degenerate A→B rulers stay on the model for warm-upgrade, but
            // map drawing / nav use hasUsableTrack.
            trackLngLat: track,
            sourceKind: 'outdooractive',
            sportLabel: oaType,
            apiTags: oaTags,
          ),
        );
      }
      if (!mounted) return;
      if (parsed.isEmpty) {
        setState(() {
          _oaStatus = (data['warning'] as String?) ?? _l10n.discoverOaNoLive;
          _oaIsDegraded = true;
        });
        return;
      }
      setState(() {
        final byId = <String, _RouteSuggestion>{
          for (final t in _tours) t.id: t,
          for (final p in parsed) p.id: p,
        };
        _tours = byId.values.toList();
        _oaStatus = _l10n.discoverOaCount(parsed.length);
        _oaIsDegraded = false;
      });
      unawaited(_consumePendingAkte());
      unawaited(_consumePendingStartRide());
      await _drawAll();
      // OA-Treffer ohne Track: Background-Routing für sichtbare Pins.
      unawaited(_warmVisibleMapTourGeometries(
        _filtered.take(DiscoverMapLineStyle.mapTourCap).toList(),
      ));
    } catch (_) {
      if (mounted) {
        setState(() {
          _oaStatus = _l10n.discoverOaOffline;
          _oaIsDegraded = true;
        });
      }
    }
  }

  /// Bundled Nähe-Seeds (Berlin ~60-Min-Loops) — D-60-03.
  Future<void> _loadNaeheSeeds() async {
    try {
      final bundle = await NaeheSeedsBundle.load();
      if (!mounted) return;
      final parsed = <_RouteSuggestion>[];
      for (final s in bundle.routes) {
        if (s.durationMin <= 0 && s.distanceKm <= 0) continue;
        final effort = s.effortLabel;
        // Prefill routed cache with baked street geometry so map / mini-map
        // never flash a synthetic circle when JSON already has a polyline.
        if (s.hasBakedGeometry) {
          _routedLoopCache[s.id] = [
            for (final c in s.bakedGeometry!) GeoPoint(c[1], c[0]),
          ];
        }
        final mixLine = _l10n.surfaceMixLine(
          mix: s.surfaceMix,
          freeText: s.surfaceMixText,
        );
        final seasonLine = _l10n.seasonLabelFor(s.season);
        parsed.add(
          _RouteSuggestion(
            id: s.id,
            name: s.title,
            distanceKm: s.distanceKm,
            elevationM: s.ascentM,
            durationMin: s.durationMin > 0
                ? s.durationMin
                : (s.distanceKm * 4).round().clamp(20, 300),
            mtbScale: TourFilters.honestScaleTag(
              effortLabel: effort,
              categories: s.categories,
            ),
            surface: s.surfaceTag,
            matchScore: s.isLoop ? 70 : 55,
            reasons: [
              if (s.isLoop) 'Rundkurs (Seed)',
              if (s.durationBand != null) 'Dauer-Band ~${s.durationBand}',
              if (s.poiStops.isNotEmpty)
                '${s.poiStops.length} Stops auf der Runde',
              if (s.hasBakedGeometry)
                'Straßen-Geometrie (Seed)'
              else
                'Offline-Fallback · ${bundle.labelWithoutLocation}',
            ],
            center: LatLng(s.centerLat, s.centerLng),
            categories: s.categories,
            trackLngLat: s.trackLngLat,
            sourceKind: 'seed',
            isLoopHint: s.isLoop,
            poiStopsCount: s.poiStops.length,
            sportLabel: s.sportLabel,
            tip: s.tip,
            seasonLabel: seasonLine.isEmpty ? null : seasonLine,
            highlightPoi: s.highlightPoi,
            disciplineNote: s.disciplineNote,
            corridorNote: s.corridorNote,
            shortPitch: s.shortPitch,
            surfaceMixLabel: mixLine.isEmpty ? null : mixLine,
            thumbnailUrl: s.thumbnailUrl ?? heroAssetForSeedId(s.id),
            photoUrls: s.photoUrls,
            apiTags: s.sportTags,
            poiStops: [
              for (final p in s.poiStops)
                _SeedPoiStop(
                  id: p.id,
                  atMin: p.atMin,
                  title: p.title,
                  kind: p.kind,
                  whyGood: p.whyGood,
                ),
            ],
          ),
        );
      }
      setState(() {
        _seedsBundle = bundle;
        final byId = <String, _RouteSuggestion>{
          for (final t in _tours) t.id: t,
        };
        // Seed-IDs sind kuratiert (seed-loop-…); überschreiben eigene Einträge.
        for (final p in parsed) {
          byId[p.id] = p;
        }
        _tours = _catalogEnrichedWithSeeds(byId.values.toList());
        final loops = parsed.where((t) => t.isLoopHint == true).length;
        _seedsOffline = false;
        _seedsStatus =
            'Seeds ${parsed.length} ($loops Rundkurse) · ${bundle.labelWithoutLocation}';
      });
      unawaited(_consumePendingAkte());
      unawaited(_consumePendingStartRide());
      unawaited(
        TourCommunityStore().prefetchCounts(
          parsed.take(TourCoverage.maxCount).map((t) => t.id).toList(),
        ),
      );
      // S25: after seeds land, replace any A→B demo overlay with a real loop.
      // Hof-/Deep-Link-Pin zuerst — erst dann Nähe-Default.
      _pinPendingLoop(
        ref.read(discoverPendingLoopIdProvider) ?? _selectedTourId,
      );
      final pin = _selectedTourId;
      final pinned = pin != null ? _tourById(pin) : null;
      if (pinned != null) {
        await _drawSeedLoopPreview(pinned);
      } else if (pin != null) {
        // Pin steht, Seed noch nicht gemappt — nicht Karlsruhe wählen.
      } else if (_loopOnlyActive) {
        await _ensureLoopMapHonesty();
      } else {
        await _drawAll();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _seedsOffline = true;
          _seedsStatus = 'Seeds offline';
        });
      }
      debugPrint('NaeheSeeds: $e');
    }
  }

  /// Redaktioneller Katalog vom Backend — füllt Touren auch ohne GPS.
  /// Immer `sport=all`: Bike-Kategorie ist nur weiche Sortier-Präferenz.
  Future<void> _fetchPublicCatalog() async {
    final l10n = _l10n;
    try {
      final snap = await PublicToursClient().fetchCatalogSnapshot(sport: 'all');
      final hits = snap.tours;
      if (!mounted || hits.isEmpty) return;
      final o = _originOrNull;
      final baked = await CatalogTourGeometryStore.load();
      if (!mounted) return;
      final parsed = <_RouteSuggestion>[];
      for (final h in hits) {
        final surface = TourFilters.normalizeStoredSurface(
          h.surface,
          fallbackTitle: h.name,
        );
        final track = baked[h.id];
        parsed.add(
          _RouteSuggestion(
            id: h.id,
            name: h.name,
            distanceKm: h.distanceKm,
            elevationM: h.elevationM,
            durationMin: h.durationMin,
            mtbScale: h.difficulty,
            surface: surface,
            matchScore: 75,
            reasons: [
              if (h.summary != null && h.summary!.isNotEmpty) h.summary!,
              'Katalog · ${h.regionSlug} · redaktionell',
              if (h.loop) 'Rundkurs-Idee',
              if (track != null)
                'Straßen-Geometrie (Katalog)'
              else
                'Losfahren lädt Live-/Override-Geometrie',
            ],
            center: LatLng(h.centerLat, h.centerLng),
            categories: h.categories,
            trackLngLat: track,
            sourceKind: 'catalog',
            isLoopHint: h.loop ? true : null,
            apiTags: [
              ...h.tags,
              if (h.regionSlug.isNotEmpty) h.regionSlug,
            ],
          ),
        );
        if (track != null && isUsableMapTrack(track)) {
          _routedLoopCache[h.id] = [
            for (final c in track) GeoPoint(c[1], c[0]),
          ];
        }
      }
      if (o != null) {
        parsed.sort((a, b) {
          final da = _distKm(
            o.lat,
            o.lng,
            a.center.latitude,
            a.center.longitude,
          );
          final db = _distKm(
            o.lat,
            o.lng,
            b.center.latitude,
            b.center.longitude,
          );
          return da.compareTo(db);
        });
      }
      if (!mounted) return;
      // GPS: nur nahe Katalog-Pins mergen (≤120 km, top 40) — sonst Warm/Map-Spam.
      final toMerge = o == null
          ? parsed
          : parsed
              .where((p) {
                final d = _distKm(
                  o.lat,
                  o.lng,
                  p.center.latitude,
                  p.center.longitude,
                );
                return d <= 120;
              })
              .take(40)
              .toList();
      setState(() {
        final byId = <String, _RouteSuggestion>{
          for (final t in _tours) t.id: t,
        };
        for (final p in toMerge) {
          final existing = byId[p.id];
          // Katalog ergänzt; OSM/OA mit höherem Score behalten.
          if (existing == null || existing.matchScore <= p.matchScore) {
            byId[p.id] = p;
          }
        }
        _tours = _catalogEnrichedWithSeeds(byId.values.toList());
        _editorialSets = snap.sets;
        _editorialHonesty = snap.honesty;
        for (final p in parsed) {
          _catalogById[p.id] = p;
        }
        final base = _oaStatus;
        _oaStatus = base == null || base.isEmpty
            ? l10n.discoverCatalogTours(toMerge.length)
            : '$base${l10n.discoverCatalogToursSuffix(toMerge.length)}';
      });
      unawaited(_consumePendingAkte());
      unawaited(_consumePendingStartRide());
      await _drawAll();
      // Katalog-Pins oft ohne Track → sofort Background-Routing.
      unawaited(_warmVisibleMapTourGeometries(
        _filtered.take(DiscoverMapLineStyle.mapTourCap).toList(),
      ));
    } catch (_) {
      // Katalog optional — Discover bleibt mit OA/OSM nutzbar.
    }
  }

  void _mergeCatalogNearOrigin() {
    final parsed = _catalogById.values.toList();
    if (parsed.isEmpty) return;
    final o = _originOrNull;
    final toMerge = o == null
        ? parsed
        : (List<_RouteSuggestion>.from(parsed)
              ..sort((a, b) {
                final da = _distKm(
                  o.lat,
                  o.lng,
                  a.center.latitude,
                  a.center.longitude,
                );
                final db = _distKm(
                  o.lat,
                  o.lng,
                  b.center.latitude,
                  b.center.longitude,
                );
                return da.compareTo(db);
              }))
            .where((p) {
              final d = _distKm(
                o.lat,
                o.lng,
                p.center.latitude,
                p.center.longitude,
              );
              return d <= 120;
            })
            .take(40)
            .toList();
    final before = _tours.map((t) => t.id).toSet();
    setState(() {
      final byId = <String, _RouteSuggestion>{
        for (final t in _tours) t.id: t,
      };
      final keepIds = toMerge.map((e) => e.id).toSet();
      byId.removeWhere(
        (id, t) => t.isCatalog && !keepIds.contains(id),
      );
      for (final p in toMerge) {
        final existing = byId[p.id];
        if (existing == null || existing.matchScore <= p.matchScore) {
          byId[p.id] = p;
        }
      }
      _tours = _catalogEnrichedWithSeeds(byId.values.toList());
    });
    final after = _tours.map((t) => t.id).toSet();
    if (before.length != after.length || !before.containsAll(after)) {
      unawaited(_drawAll());
    }
  }

  void _beginNavigate() {
    final intent = beginNavigateIntent(
      hasEnd: _end != null,
      lastPlace: _lastPlaceHit,
      pendingHits: _placeHits,
    );
    setState(() {
      _vias.clear();
      if (_start == null && _hasRealOrigin) {
        _start = _origin;
        _startAddrCtrl.text = _l10n.discoverMyPosition;
      }
      final dest = intent.destination;
      if (dest != null) {
        _end = GeoPoint(dest.lat, dest.lng);
        _endAddrCtrl.text = dest.label;
        _lastPlaceHit = dest;
        _addrTarget = 'end';
        _destinationTrail = null;
      }
    });
    _setShellMode(
      DiscoverShellMode.navigate,
      pick: _PickMode.end,
    );
    if (_start != null && _end != null) {
      unawaited(_calcAb());
    }
  }

  Future<void> _applyBrowsePlaceHit(GeocodeHit hit) async {
    _lastPlaceHit = hit;
    if (placeHitAppliesAsDestination(
      navigating: _shellMode == DiscoverShellMode.navigate,
    )) {
      _addrTarget = 'end';
      await _applyAddressHit(hit);
      return;
    }
    await _flyBrowsePlace(hit);
  }

  Future<void> _flyBrowsePlace(GeocodeHit hit) async {
    setState(() {
      _browseAnchor = GeoPoint(hit.lat, hit.lng);
      _browseAnchorPinned = true;
      _browseAnchorLabel = hit.label;
      _hofPinLoopId = null;
      _selectedTourId = null;
      _computed = null;
      _label = null;
      _approach = null;
      _tourLayer = null;
      _exploreQuery = '';
      _exploreSearchCtrl.value = TextEditingValue(
        text: hit.label,
        selection: TextSelection.collapsed(offset: hit.label.length),
      );
      _placeHits = const [];
      _geocodeRecents = _pushGeocodeRecentList(hit);
    });
    unawaited(_persistGeocodeRecents(_geocodeRecents));
    final map = _map;
    if (map != null) {
      try {
        await map.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(hit.lat, hit.lng), 12),
        );
      } catch (_) {}
    }
    _mergeCatalogNearOrigin();
    unawaited(_ensureBikeOverlay());
    unawaited(_fetchOsmRoutes());
    unawaited(_fetchTrailNetwork());
  }

  void _schedulePlaceHits(String query) {
    _placeSearchDebounce?.cancel();
    if (!BrowsePlaceSearch.shouldOfferPlaceHits(query)) {
      if (_placeHits.isNotEmpty || _placeSearchNeedNet) {
        setState(() {
          _placeHits = const [];
          _placeSearchNeedNet = false;
        });
      }
      return;
    }
    _placeSearchDebounce = Timer(const Duration(milliseconds: 420), () {
      unawaited(_loadPlaceHits(query));
    });
  }

  Future<void> _loadPlaceHits(String query) async {
    if (BrowsePlaceSearch.needsNetwork(query)) {
      if (_browseOnlineAt == null) {
        await _probeBrowseNetwork();
        if (!mounted) return;
      }
      if (!_browseOnline) {
        if (mounted) {
          setState(() {
            _placeHits = const [];
            _placeSearchNeedNet = true;
          });
        }
        return;
      }
    }
    final o = _origin;
    try {
      final hits = await _geocode.search(
        query,
        biasLat: o.lat,
        biasLng: o.lng,
        limit: 5,
      );
      if (!mounted) return;
      if (_exploreSearchCtrl.text.trim() != query.trim()) return;
      setState(() {
        _placeHits = hits.take(5).toList();
        _placeSearchNeedNet = false;
      });
    } catch (_) {}
  }

  Future<void> _submitBrowseSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    if (BrowsePlaceSearch.needsNetwork(q) && !await _discoverHasNetwork()) {
      if (!mounted) return;
      setState(() => _setStatus(_l10n.discoverSearchNeedNet));
      return;
    }
    final names = _filtered.map((t) => t.name);
    final o = _origin;
    try {
      final hits = await _geocode.search(
        q,
        biasLat: o.lat,
        biasLng: o.lng,
        limit: 5,
      );
      if (!mounted) return;
      if (hits.isEmpty) {
        setState(() => _setStatus(_l10n.discoverNoHitsFor(q)));
        return;
      }
      if (!BrowsePlaceSearch.shouldFlyToPlace(
            query: q,
            visibleTourNames: names,
          ) &&
          hits.length > 1) {
        setState(() {
          _placeHits = hits.take(5).toList();
          _lastPlaceHit = hits.first;
        });
        return;
      }
      await _applyBrowsePlaceHit(hits.first);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setStatus(
            friendlyErrorMessage(e, context: _l10n.discoverGeocodeFailed));
      });
    }
  }

  Future<void> _fetchOsmRoutes() async {
    final l10n = _l10n;
    try {
      if (!_hasRealOrigin) return;
      if (_browseOnlineAt == null) {
        await _probeBrowseNetwork();
        if (!mounted) return;
      }
      if (!_browseOnline) return;
      final o = _origin;
      final hits = await OsmRoutesClient().fetchNearby(
        lat: o.lat,
        lon: o.lng,
        radiusKm: 36,
      );
      if (!mounted || hits.isEmpty) {
        if (mounted && hits.isEmpty) {
          setState(() {
            final base = _oaStatus;
            if (base == null || base.contains('OSM')) return;
            _oaStatus = '$base${l10n.discoverOsmNoHitsSuffix}';
            _oaIsDegraded = true;
          });
        }
        return;
      }
      final parsed = <_RouteSuggestion>[];
      for (final h in hits) {
        final isMtb = h.type.toLowerCase().contains('mtb');
        final surface = _inferSurfaceTag(
          title: h.title,
          type: h.type,
          difficulty: h.difficulty,
          profile: _profile,
        );
        parsed.add(
          _RouteSuggestion(
            id: h.id,
            name: h.title,
            distanceKm: h.lengthKm,
            elevationM: h.elevationM ?? 0,
            durationMin: h.durationMin,
            mtbScale: h.difficulty ?? (isMtb ? 'S1' : 'offen'),
            surface: surface,
            matchScore: 92,
            reasons: [
              if (h.summary != null) h.summary!,
              'OpenStreetMap Relation · Live-Track',
              if (h.url != null) h.url!,
            ],
            center: h.center,
            categories: isMtb
                ? const [
                    BikeCategory.mtbTrail,
                    BikeCategory.mtbAm,
                    BikeCategory.mtbEnduro,
                    BikeCategory.emtb,
                  ]
                : TourFilters.inferCategories(
                    title: h.title,
                    type: h.type,
                    difficulty: h.difficulty,
                    surface: surface,
                  ),
            trackLngLat: h.geometry,
            sourceKind: 'osm',
            sportLabel: h.type,
            apiTags: [
              h.type,
              if (h.difficulty != null) h.difficulty!,
              'osm',
            ],
          ),
        );
      }
      setState(() {
        final byId = <String, _RouteSuggestion>{
          for (final t in _tours) t.id: t,
          for (final p in parsed) p.id: p,
        };
        _tours = byId.values.toList();
        final withTrack = _tours.where((t) => t.hasTrack).length;
        _oaStatus = l10n.discoverToursOsmStatus(
          _tours.length,
          withTrack,
          parsed.length,
        );
      });
      unawaited(_consumePendingAkte());
      unawaited(_consumePendingStartRide());
      await _drawAll();
    } catch (_) {
      // Overpass/API optional — OA bleibt nutzbar.
    }
  }

  Future<void> _refreshElevation(RouteResult? result) async {
    final l10n = _l10n;
    if (result == null ||
        !shouldShowLiveRouteStats(
          hasLiveLine: result.coordinates.length >= 2,
          engine: result.engine,
          coordinateCount: result.coordinates.length,
        )) {
      if (!mounted) return;
      setState(() {
        _elevationSummary = null;
        _elevationGainM = null;
        _planElevSamples = const [];
        _planElevKm = const [];
        _planElevPoints = const [];
        _planElevSource = null;
        _planSurfaceBands = const [];
        _planSurfaceMix = const [];
        _planLegendKinds.clear();
        _planElevScrubT = null;
        _weatherStart = null;
        _weatherSummit = null;
        _filmstripShots = const [];
      });
      return;
    }
    final profile = await _elevationClient.fetchForTrack(result.coordinates);
    if (!mounted) return;
    if (profile == null) {
      setState(() {
        _elevationGainM = null;
        _planElevSamples = const [];
        _planElevKm = const [];
        _planElevPoints = const [];
        _planElevSource = null;
        _planSurfaceBands = const [];
        _planSurfaceMix = const [];
        _planLegendKinds.clear();
        _elevationSummary = null;
      });
      await _refreshPlanExtras(result, null);
      return;
    }
    final samples = elevationSamplesOf(profile);
    final km = elevationDistKmOf(profile);
    final bands = elevationSurfaceBandsOf(profile.points);
    final track = [
      for (final p in result.coordinates) [p.lng, p.lat],
    ];
    final legend = planRibbonLegendKinds(
      bands: bands,
      hasSteep: planSteepLineSlices(
        lineLngLat: track,
        elevM: samples,
        distKm: km.isEmpty ? null : km,
      ).isNotEmpty,
    );
    setState(() {
      _elevationGainM = profile.gainM;
      _planElevSamples = samples;
      _planElevKm = km;
      _planElevPoints = profile.points;
      _planElevSource = profile.source;
      _planSurfaceBands = bands;
      _planSurfaceMix = surfaceSharesFromElevPoints(profile.points);
      _planLegendKinds
        ..clear()
        ..addAll(legend);
      _elevationSummary = elevationSourceIsUserFacing(profile.source)
          ? l10n.discoverElevationGainLossSource(
              '${profile.gainM.round()}',
              '${profile.lossM.round()}',
              profile.source!,
            )
          : l10n.discoverElevationGainLoss(
              '${profile.gainM.round()}',
              '${profile.lossM.round()}',
            );
    });
    await _refreshPlanExtras(result, profile);
    if (_planEditorActive &&
        _planElevSamples.length >= 2 &&
        _hasLivePlanLine &&
        mounted) {
      unawaited(_drawAll());
    }
  }

  Future<void> _refreshPlanExtras(
    RouteResult result,
    ElevationProfile? profile,
  ) async {
    final line = [
      for (final p in result.coordinates) [p.lng, p.lat],
    ];
    WeatherSnapshot? startW;
    WeatherSnapshot? summitW;
    try {
      final start = result.coordinates.first;
      startW = await ref.read(weatherClientProvider).fetch(
            lat: start.lat,
            lon: start.lng,
            profile: _profile.apiId,
            lang: Localizations.localeOf(context).languageCode,
          );
      final summit = profile == null
          ? null
          : maxElevAlong(line: line, points: profile.points);
      if (summit != null) {
        final off = haversineM(start.lat, start.lng, summit.lat, summit.lng);
        if (off > 400) {
          summitW = await ref.read(weatherClientProvider).fetch(
                lat: summit.lat,
                lon: summit.lng,
                profile: _profile.apiId,
                lang: Localizations.localeOf(context).languageCode,
              );
        }
      }
    } catch (_) {}
    final shots = <FilmstripShot>[
      ...await _filmstripClient.fetchAlong(result.coordinates),
    ];
    final tourId = _selectedTourId;
    if (tourId != null && tourId.isNotEmpty) {
      try {
        final bundle = await TourCommunityStore().mergeCloudBundle(tourId);
        for (final r in bundle.reviews) {
          var lat = r.pinLat;
          var lng = r.pinLng;
          if ((lat == null || lng == null) &&
              r.alongM != null &&
              line.length >= 2) {
            final pt = pointAlongRoute(line, r.alongM!);
            lng = pt[0];
            lat = pt[1];
          }
          if (lat == null || lng == null) continue;
          for (final url in r.photoUris) {
            if (!url.startsWith('http')) continue;
            shots.add(
              FilmstripShot(
                id: '${r.id}-$url',
                imageUrl: url,
                lat: lat,
                lng: lng,
                source: 'stimme',
              ),
            );
          }
        }
      } catch (_) {}
    }
    final along = filmstripAlongLine(shots: shots, line: line);
    if (!mounted) return;
    setState(() {
      _weatherStart = startW;
      _weatherSummit = summitW;
      _filmstripShots = along;
    });
  }

  /// Höhenprofil für das Tour-Detail — nur aus echter Geometrie:
  /// Routed-Loop-Cache (Seeds nach [_upgradeSeedLoopGeometry]) oder echte
  /// Tracks (OSM/Outdooractive). Synthetische Seed-Kreise liefern Höhen
  /// entlang eines erfundenen Wegs → dann lieber gar kein Profil.
  Future<void> _ensureDetailElevation(_RouteSuggestion r) async {
    if (_detailElev.containsKey(r.id) || _detailElevPending.contains(r.id)) {
      return;
    }
    _detailElevPending.add(r.id);
    try {
      var routed = _routedLoopCache[r.id];
      if (routed == null && r.isSeed && _isLoop(r)) {
        // Erst echte Geometrie besorgen (zeichnet nebenbei die Loop-Vorschau
        // und füttert die Mini-Map) — Kreis-Track wäre für Höhen unehrlich.
        await _upgradeSeedLoopGeometry(r);
        routed = _routedLoopCache[r.id];
      }
      final track = routed ??
          (!r.isSeed && r.hasTrack
              ? [for (final c in r.trackLngLat!) GeoPoint(c[1], c[0])]
              : null);
      if (track == null || track.length < 2) return;
      final profile = await _elevationClient.fetchForTrack(track);
      if (profile == null) return;
      final samples = <double>[];
      for (final p in profile.points) {
        final e = p['elevation'] ?? p['elev'] ?? p['ele'] ?? p['z'];
        if (e is num) samples.add(e.toDouble());
      }
      if (samples.length < 2 && profile.gainM <= 0) return;
      _detailElev[r.id] =
          (gainM: profile.gainM, lossM: profile.lossM, samples: samples);
      if (mounted && _detailId == r.id) setState(() {});
    } catch (_) {
      // Höhen-API optional — Abschnitt bleibt dann einfach weg.
    } finally {
      _detailElevPending.remove(r.id);
    }
  }

  Future<void> _openTrailView({LatLng? near}) async {
    final c = near ?? LatLng(_origin.lat, _origin.lng);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TrailViewSheet(lat: c.latitude, lng: c.longitude),
    );
  }

  Future<void> _onQuickLineTapped(Line line) async {
    final data = line.data;
    final kind = data?['kind'];
    if (planShapeLineKind(kind?.toString()) || kind == 'active') {
      var tap = _recentMapPointer() ?? _lastMapTap;
      if (tap == null) {
        final geom = line.options.geometry;
        if (geom != null && geom.length >= 2) {
          final mid = geom[geom.length ~/ 2];
          tap = GeoPoint(mid.latitude, mid.longitude);
        }
      }
      if (tap != null && _tryInsertViaFromMapTap(tap, onLine: true)) return;
    }
    if (data == null) return;

    if (kind == 'trail') {
      final id = data['id'] as String?;
      if (id == null) return;
      OsmTrailSegment? trail;
      for (final t in _trailNetwork) {
        if (t.id == id) {
          trail = t;
          break;
        }
      }
      if (trail == null) return;
      final target = _map?.cameraPosition?.target;
      final at =
          target == null ? null : GeoPoint(target.latitude, target.longitude);
      setState(() {
        _selectedTrailId = trail!.id;
        _selectedTourId = null;
        _shellMode = DiscoverShellMode.explore;
        _surface = _Surface.discover;
        _setStatus(
            '${trail.name} · ${trail.difficultyLabel} · ${trail.lengthKm.toStringAsFixed(1)} km');
      });
      await _drawAll();
      if (mounted) await _showTrailSheet(trail, at: at);
      return;
    }

    if (kind == 'tour') {
      final id = data['id'] as String?;
      if (id == null) return;
      setState(() => _selectedTrailId = null);
      final tour = _tourById(id);
      if (tour == null) return;
      await _previewTourOnMap(tour);
      return;
    }

    if (kind != 'quick') return;
    final id = data['id'] as String?;
    final label = data['label'] as String?;
    _QuickOption? match;
    for (final q in _quick) {
      if ((id != null && q.id == id) || (label != null && q.label == label)) {
        match = q;
        break;
      }
    }
    if (match == null) return;
    setState(() {
      _computed = match!.result;
      _label = match.label;
      _selectedTourId = null;
      _selectedTrailId = null;
      _setStatus(_l10n.discoverAltChosen(match.label));
    });
    await _drawRoute(match.result);
  }

  Future<void> _onTfSymbolTapped(Symbol symbol) async {
    final poi = _poiBySymbolId[symbol.id];
    if (poi != null) {
      await _onTourPoiTapped(poi);
      return;
    }
    final tour = _tourBySymbolId[symbol.id];
    if (tour != null) {
      await _onTourPinTapped(tour);
      return;
    }
    final place = _placeBySymbolId[symbol.id];
    if (place != null) {
      await _onMapPlaceTapped(place);
      return;
    }
    final pin = _tfBySymbolId[symbol.id];
    if (pin == null) return;
    try {
      await launchUrl(
        Uri.parse(pin.openUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(pin.name)));
      }
    }
  }

  Future<void> _onTourPinTapped(_RouteSuggestion tour) async {
    _pendingPoiScrollId = null;
    if (tour.id == _selectedTourId) {
      await _openDetail(tour.id, tour.center);
      return;
    }
    await _previewTourOnMap(tour);
  }

  Future<void> _onTourPoiTapped(_SeedPoiStop poi) async {
    final tour = _tourById(_selectedTourId);
    if (tour == null) return;
    _pendingPoiScrollId = poi.id;
    if (_surface != _Surface.detail || _detailId != tour.id) {
      await _openDetail(tour.id, tour.center);
      return;
    }
    _flashAndScrollToPoi(poi.id);
  }

  GlobalKey _keyForPoi(String id) =>
      _poiTileKeys.putIfAbsent(id, GlobalKey.new);

  void _flashAndScrollToPoi(String id) {
    _pendingPoiScrollId = null;
    _poiHighlightTimer?.cancel();
    if (mounted) setState(() => _highlightPoiId = id);
    unawaited(_applyPoiHighlightSizes());
    _poiHighlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _highlightPoiId = null);
      unawaited(_applyPoiHighlightSizes());
    });
    _scrollToPoiTile(id);
  }

  Future<void> _applyPoiHighlightSizes() async {
    final c = _map;
    if (c == null) return;
    for (final entry in _poiSymbolByPoiId.entries) {
      try {
        await c.updateSymbol(
          entry.value,
          SymbolOptions(
            iconSize: poiStopIconSize(
              selected: entry.key == _highlightPoiId,
            ),
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _applyPlaceHighlightSizes() async {
    final c = _map;
    if (c == null) return;
    for (final sym in _placeSymbols) {
      final place = _placeBySymbolId[sym.id];
      if (place == null || coverageMapPoiKind(place) == null) continue;
      try {
        await c.updateSymbol(
          sym,
          SymbolOptions(
            iconSize: poiStopIconSize(
              selected: place.id == _highlightPlaceId,
            ),
          ),
        );
      } catch (_) {}
    }
  }

  void _scrollToPoiTile(String id, {int attempt = 0}) {
    final ctx = _poiTileKeys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        alignment: 0.12,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (attempt >= 8) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToPoiTile(id, attempt: attempt + 1);
    });
  }

  Future<void> _onMapPlaceTapped(MapPlace mapped) async {
    if (!mounted) return;
    if (mapped.source == MapPlaceSource.meet || mapped.id.startsWith('meet-')) {
      await _onMeetPlaceTapped(mapped);
      return;
    }
    if (coverageMapPoiKind(mapped) != null) {
      _highlightPlaceId = mapped.id;
      unawaited(_applyPlaceHighlightSizes());
    }
    final action = await showOrtSheet(
      context,
      place: mapped,
      canAddVia: true,
      onLiveRoute: _hasLivePlanLine,
    );
    if (mounted) {
      _highlightPlaceId = null;
      unawaited(_applyPlaceHighlightSizes());
    }
    if (!mounted || action == null) return;
    switch (action) {
      case OrtSheetAction.addVia:
        _addPlaceAsVia(mapped);
        break;
      case OrtSheetAction.routeHere:
        await _routeToPlace(mapped);
        break;
      case OrtSheetAction.openMaps:
        break;
    }
  }

  Future<void> _onMeetPlaceTapped(MapPlace mapped) async {
    GroupMeetPin? pin;
    for (final p in _meetPins) {
      if (p.placeId == mapped.id) {
        pin = p;
        break;
      }
    }
    if (pin == null) return;
    final isMember = _meetMemberIds.contains(pin.group.id);
    final action = await showGroupMeetSheet(
      context,
      group: pin.group,
      isMember: isMember,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case GroupMeetSheetAction.join:
        await _joinMeetGroup(pin.group);
        break;
      case GroupMeetSheetAction.ride:
        await _startRideFromMeetGroup(pin.group);
        break;
      case GroupMeetSheetAction.dismiss:
        break;
    }
  }

  Future<void> _joinMeetGroup(RideGroup group) async {
    final out = await RideGroupStore().tryJoin(
      groupId: group.id,
      displayLabel: _l10n.platzYou,
    );
    if (!mounted) return;
    if (out.fail == RideGroupJoinFail.needLogin) {
      openAuthScreen(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(out.message)),
    );
    unawaited(_refreshMeetPlaces());
  }

  Future<void> _startRideFromMeetGroup(RideGroup group) async {
    final saved =
        ref.read(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    final pending = startRidePendingIdForGroup(
      savedRouteId: group.savedRouteId,
      catalogTourId: group.catalogTourId,
      saved: saved,
      metas: _savedMeta,
    );
    if (pending == null || pending.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.platzTourNotInMappeHint)),
      );
      return;
    }
    ref.read(ridePendingGroupIdProvider.notifier).state = group.id;
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = pending;
  }

  void _addPlaceAsVia(MapPlace place) {
    _abFromBrowsePin = false;
    var p = GeoPoint(place.lat, place.lng);
    if (viaMaySnapOntoTrail(label: place.name)) {
      p = _snapViaPoint(p);
    }
    if (_hasLivePlanLine) {
      _insertPlanViaAlong(p, label: place.name);
      setState(() {
        if (_surface != _Surface.plan) {
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
        }
        _setStatus('${_l10n.discoverPlaceOnRoute}: ${place.name}');
      });
      return;
    }
    _pushPlanUndo();
    setState(() {
      _vias.add(
        LabeledVia(
          lat: p.lat,
          lng: p.lng,
          label: place.name,
          placeId: place.id,
          kind: place.kindWire,
        ),
      );
      if (_surface != _Surface.plan) {
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
      }
      _pick = _PickMode.none;
    });
    unawaited(_syncMarkers());
    _afterPlanViaInserted();
    if (_start != null && _end != null) {
      unawaited(_calcAb(keepLine: true, refitPins: false));
    }
  }

  Future<void> _routeToPlace(MapPlace place) async {
    _abFromBrowsePin = false;
    _pushPlanUndo();
    final dest = GeoPoint(place.lat, place.lng);
    setState(() {
      _end = dest;
      _endAddrCtrl.text = place.name;
      if (_start == null) {
        final o = _riderOrigin;
        if (o != null) {
          _start = o;
          _startAddrCtrl.text = _l10n.discoverMyPosition;
        }
      }
      _surface = _Surface.plan;
      _shellMode = DiscoverShellMode.navigate;
      _pick = _PickMode.none;
    });
    await _syncMarkers();
    if (_start != null) await _calcAb();
  }

  /// [fresh] nur vom Locate-FAB / „Mein Standort“. Mount: lastKnown, kein Dialog.
  Future<void> _locate({bool fresh = false}) async {
    if (fresh && _browseAnchor != null) {
      _clearBrowseAnchorToGps();
    }
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (fresh && mounted) {
          setState(
            () => _setStatus(_l10n.discoverLocationOff),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (fresh && perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (fresh && mounted) {
          setState(
            () => _setStatus(_l10n.discoverLocationDenied),
          );
        }
        return;
      }
      // Nie getCurrentPosition auf dem ersten Karten-Frame — ANR auf
      // Android (NmeaClient.stop auf dem UI-Thread). MapLibre füllt
      // [_userPos] über onUserLocationUpdated nach.
      var pos = await readCachedPosition(
        maxAge: fresh ? const Duration(hours: 24) : const Duration(minutes: 8),
      );
      if (fresh) {
        pos = await readFreshPosition() ?? pos;
      }
      if (pos == null) {
        if (fresh && mounted) {
          setState(
            () => _setStatus(_l10n.discoverNoGpsFix),
          );
        }
        return;
      }
      if (!mounted) return;
      final p = GeoPoint(pos.latitude, pos.longitude);
      if (pos.heading >= 0) _puckHeadingDeg = pos.heading;
      _skipAutoCameraFit = true;
      setState(() {
        _userPos = p;
        _browseAnchor = null;
        _browseAnchorPinned = false;
        _browseAnchorLabel = null;
        _start = p;
        _startAddrCtrl.text = _l10n.discoverMyPosition;
        _setStatus(_l10n.discoverLocationReady);
      });
      _maybeWarmLiveRouting(p);
      unawaited(_syncOfflineCoverageOverlay());
      unawaited(_fetchOutdooractive());
      unawaited(_fetchOsmRoutes());
      unawaited(_fetchTrailNetwork());
      unawaited(_fetchTrailforks());
      unawaited(_fetchPublicCatalog());
      unawaited(_fetchCoverage());
      _prefetchBikeOverlay();
      // Explizit Near-me nach frischem GPS — Drift-Sync kann verzögern.
      // Rundkurs-Lens: nahen Seed auf die Karte, nie A→B / Fernstadt.
      if (_loopOnlyActive) {
        unawaited(_ensureLoopMapHonesty());
      }
      if (_end != null) {
        _skipAutoCameraFit = false;
        _scheduleCalcAbFromMap();
      } else if (DiscoverExploreChromeLogic.gpsMayRecenterOnUser(
        hofPinLoopId: _hofPinLoopId,
        selectedTourId: _selectedTourId,
      )) {
        try {
          await _map?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 12.5),
          );
        } catch (_) {}
      } else if (!_planningAb) {
        final pin = _hofPinLoopId ?? _selectedTourId;
        final tour = _tourById(pin);
        if (tour != null) unawaited(_focusCameraOnTour(tour));
      }
      unawaited(_syncNavPuck());
    } catch (e) {
      if (fresh && mounted) {
        setState(
          () => _setStatus(_l10n.discoverLocationUnavailable),
        );
      }
    }
  }

  /// Tour-/API-Origin: Suche/Kamera, sonst GPS/Start — kein Stadt-Fake.
  GeoPoint? get _originOrNull => _browseAnchor ?? _userPos ?? _start;

  GeoPoint get _origin => _originOrNull ?? _regionOverview;

  bool get _planningAb => shouldHideDiscoverTourRibbons(
        navigateMode: _shellMode == DiscoverShellMode.navigate,
        hasStart: _start != null,
        hasEnd: _end != null,
      );

  bool get _hideFarmTracksOnBrowse {
    return !_showFarmTracksLayer ||
        shouldHideFarmTracksOnBrowse(
          navigateMode: _shellMode == DiscoverShellMode.navigate,
          loading: _loading,
          hasPendingAbHint: waitingForLiveDiscoverAb(
            hasFrom: (_start ?? _userPos) != null,
            hasEnd: _end != null,
            hasLiveLine: _hasLivePlanLine,
          ),
        );
  }

  /// A–B / Approach start: GPS or an explicit start pin, never the panned map.
  GeoPoint? get _riderOrigin {
    final o = routingOriginPreferGps(
      userLat: _userPos?.lat,
      userLng: _userPos?.lng,
      startLat: _start?.lat,
      startLng: _start?.lng,
    );
    if (o == null) return null;
    return GeoPoint(o.lat, o.lng);
  }

  bool get _hasRealOrigin => DiscoverExploreChromeLogic.aroundOriginIsUsable(
        hasGpsOrStart: _userPos != null || _start != null,
        browseLat: _browseAnchor?.lat,
        browseLng: _browseAnchor?.lng,
        mapZoom: _mapZoom,
      );

  /// Start-A liegt auf dem GPS-Fix — dann nur der Puck, kein grüner A-Kreis.
  bool _startOverlapsUser() {
    final s = _start;
    final u = _userPos;
    if (s == null || u == null) return false;
    return _distKm(s.lat, s.lng, u.lat, u.lng) < 0.04;
  }

  Future<void> _loadNavPuckStyle() async {
    final puck = NavPuckStyleX.fromId(await RidePrefs.navPuckStyleId());
    if (!mounted) return;
    setState(() => _navPuckStyle = puck);
    final c = _map;
    if (c != null) unawaited(_navPuck.setStyle(c, puck));
  }

  Future<void> _applyNavPuckStyle(NavPuckStyle style) async {
    await RidePrefs.setNavPuckStyleId(style.id);
    if (!mounted) return;
    setState(() => _navPuckStyle = style);
    final c = _map;
    if (c != null) unawaited(_navPuck.setStyle(c, style));
  }

  Future<void> _openNavPuckPicker() async {
    if (!mounted) return;
    final picked = await showNavPuckStyleSheet(
      context,
      current: _navPuckStyle,
    );
    if (picked == null || !mounted) return;
    await _applyNavPuckStyle(picked);
  }

  Future<void> _attachNavPuck() async {
    final c = _map;
    if (c == null) return;
    await _navPuck.attach(c, style: _navPuckStyle);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      final map = _map;
      if (map == null) return;
      unawaited(_navPuck.hideNativePuck(map));
    });
    await _syncNavPuck();
  }

  void _onUserLocationUpdated(UserLocation loc) {
    _lastUserLoc = loc;
    final heading = loc.bearing;
    if (heading != null && heading.abs() > 0.5) {
      _puckHeadingDeg = heading;
    } else {
      _puckHeadingDeg = loc.heading?.trueHeading ??
          loc.heading?.magneticHeading ??
          _puckHeadingDeg;
    }
    final next = GeoPoint(loc.position.latitude, loc.position.longitude);
    final firstFix = _userPos == null;
    final prevOutside = _coverageRiderIsOutside;
    _userPos = next;
    final nowOutside = _coverageRiderIsOutside;
    if (firstFix && mounted) {
      var adoptStart = false;
      if (_end != null && _start == null && _pick != _PickMode.start) {
        _start = next;
        _startAddrCtrl.text = _l10n.discoverMyPosition;
        adoptStart = true;
      }
      setState(() {});
      _refreshNearbyDataSources();
      if (adoptStart) _scheduleCalcAbFromMap();
      unawaited(_syncOfflineCoverageOverlay());
      _maybeWarmLiveRouting(next);
    } else if (prevOutside != nowOutside && mounted) {
      setState(() {});
      unawaited(_syncOfflineCoverageOverlay());
    }
    final map = _map;
    if (map != null) unawaited(_navPuck.hideNativePuck(map));
    unawaited(_syncNavPuck());
  }

  double _headingForDiscoverPuck(UserLocation? user) {
    final gps = user?.bearing;
    if (gps != null && gps.abs() > 0.5) return gps;
    return user?.heading?.trueHeading ??
        user?.heading?.magneticHeading ??
        _puckHeadingDeg;
  }

  Future<void> _syncNavPuck() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    final loc = _lastUserLoc;
    final LatLng? at = loc?.position ??
        (_userPos != null ? LatLng(_userPos!.lat, _userPos!.lng) : null);
    if (at == null) return;
    final cam = c.cameraPosition;
    await _navPuck.sync(
      c,
      at: at,
      iconRotateDeg: navPuckIconRotateDeg(
        headingDeg: _headingForDiscoverPuck(loc),
        cameraBearingDeg: cam?.bearing ?? 0,
        northUp: (cam?.tilt ?? 0) < 1,
      ),
      style: _navPuckStyle,
    );
  }

  /// Reagiert auf jede Änderung des echten Origins (GPS-Fix trifft nach dem
  /// ersten Fallback-Render ein, „Hier" tippen, Adresssuche, Kartentipp, …) —
  /// statt eines einmaligen Snapshots beim Moduswechsel. Wird am Anfang von
  /// [build] aufgerufen; günstig genug (eine Distanzberechnung) für jeden
  /// Rebuild, tut aber nur bei echter Drift (> 300 m) etwas.
  ///
  /// Ohne echten Origin (`_hasRealOrigin == false`) wird bewusst nichts
  /// getan — der Fallback-Quick-Fetch um [_regionOverview] beim Kaltstart
  /// (initState, „Quick auch ohne GPS") bleibt unangetastet; sobald ein
  /// echter Fix eintrifft, greift dieser Abgleich zum ersten Mal.
  void _syncOriginDrift() {
    if (!_hasRealOrigin) return;
    final o = _origin;
    final prev = _lastAppliedOrigin;
    final drifted =
        prev == null || _distKm(prev.lat, prev.lng, o.lat, o.lng) > 0.3;
    if (!drifted) return;
    // Trotzdem aktualisieren, auch wenn wir gleich nichts damit tun — sonst
    // gäbe es beim Zurückkehren nach Discover einen einzelnen großen Sprung
    // statt vieler kleiner, die während Planen/Detail nur nicht ausgeführt
    // wurden.
    _lastAppliedOrigin = o;
    // Nur in Discover automatisch der Position folgen. In Planen und Detail
    // hat die Nutzerin die Kamera bewusst auf eine Route oder Tour gerichtet
    // ([_openDetail] zentriert extra darauf) — GPS-Rauschen soll das nicht
    // wieder wegziehen. Genau das war die ursprüngliche Kritik „Kamera
    // kämpft mit dem Nutzer"; ungated hätte sie sich hier gegen das neue
    // Detail-Panel wiederholt.
    if (_surface != _Surface.discover) return;
    if (_skipAutoCameraFit) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _map?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(o.lat, o.lng), 12),
            ) ??
            Future.value(),
      );
      if (!_loading) {
        // ~60 Rundkurs: re-pick nearest loop after GPS/origin drift (not Zurich).
        if (_loopOnlyActive) {
          unawaited(_ensureLoopMapHonesty());
        }
      }
    });
  }

  GeoPoint get _mapCenter => _originOrNull ?? _regionOverview;

  GeoPoint? get _usableDiscoverMapCenter {
    final cam = _map?.cameraPosition;
    if (cam == null || !isLocalDiscoverZoom(cam.zoom)) return null;
    final t = cam.target;
    if (isPlaceholderDiscoverCenter(t.latitude, t.longitude)) return null;
    return GeoPoint(t.latitude, t.longitude);
  }

  void _persistDiscoverViewport() {
    final cam = _map?.cameraPosition;
    if (cam == null || !isLocalDiscoverZoom(cam.zoom)) return;
    final t = cam.target;
    if (isPlaceholderDiscoverCenter(t.latitude, t.longitude)) return;
    unawaited(
      RidePrefs.setDiscoverViewport(
        DiscoverViewport(
          lat: t.latitude,
          lng: t.longitude,
          zoom: cam.zoom,
        ),
      ),
    );
  }

  /// Höhe des unteren Panels aus dem letzten Build. Die Karte liegt jetzt
  /// full-bleed darunter, deshalb braucht das Einpassen der Route (siehe
  /// [_drawAll]) diesen Rand — sonst verschwindet sie hinter dem Panel.
  double _panelInset = 300;

  /// Keine zweite Losfahren-Leiste über dem Sheet (Komoot/AllTrails):
  /// Peek = Tourkarte mit CTA, Navigieren hat eigene Compute-Zeile.
  bool get _showRideBar => false;

  List<_RouteSuggestion> get _filtered {
    final bikes = ref.watch(bikesProvider).valueOrNull ?? const <Bike>[];
    Bike? active;
    for (final b in bikes) {
      if (b.isActive) {
        active = b;
        break;
      }
    }
    active ??= bikes.isEmpty ? null : bikes.first;
    final store = ref.watch(userProfileStoreProvider);
    // Aktives Rad schlägt Profil; ohne Rad: alle gewählten Vorlieben.
    final rankingSports = active != null
        ? <BikeCategory>[active.category]
        : store.preferredSports;

    final base = _tours.where((r) {
      // Dauer-Band der aktiven Lens (für ~60: 45–75 Min, D-60-01).
      if (_matchTourDuration && _minutes > 0) {
        if (!DurationLens.inBand(r.durationMin, _minutes)) return false;
      }
      if (_surfaceFilter != null &&
          !TourFilters.surfaceMatches(r.surface, _surfaceFilter!)) {
        return false;
      }
      if (_effortFilter != null &&
          !TourFilters.effortMatches(r.mtbScale, _effortFilter!)) {
        return false;
      }
      if (_elevationFilter != null &&
          !TourFilters.elevationMatches(r.elevationM, _elevationFilter!)) {
        return false;
      }
      if (!TourFilters.distanceMatches(r.distanceKm, _maxLengthKm)) {
        return false;
      }
      if (_maxDistanceKm != null && _hasRealOrigin) {
        final o = _origin;
        final away =
            _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude);
        if (!TourFilters.awayMatches(away, _maxDistanceKm)) {
          return false;
        }
      }
      if (!TourFilters.formMatches(
        form: _formFilter,
        isLoop: _isLoop(r),
        categories: r.categories,
        tags: r.apiTags,
        title: r.name,
        sportLabel: r.sportLabel,
      )) {
        return false;
      }
      if (!TourFilters.sportMatches(r.categories, _sportFilter)) {
        return false;
      }
      if (_trailScaleFilter.isNotEmpty &&
          !TourFilters.scaleMatches(
            r.mtbScale,
            r.categories,
            _trailScaleFilter,
          )) {
        return false;
      }
      if (_exploreQuery.trim().isNotEmpty) {
        final q = _exploreQuery.trim().toLowerCase();
        final hay = [
          r.name,
          r.sportLabel ?? '',
          _l10n.sportTagLabel(r.sportLabel),
          _sourceLabelOf(r),
          ...r.apiTags,
          ...r.apiTags.map(TourTrait.label),
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_activeTraits.isNotEmpty) {
        for (final wire in _activeTraits) {
          if (!TourTrait.matches(
            tags: r.apiTags,
            name: r.name,
            wire: wire,
          )) {
            return false;
          }
        }
      }
      // Seed-Nähe: nicht hart auf 35 km kappen — Coverage füllt die Liste.
      return true;
    }).toList();

    final covered = _applyTourCoverage(base);
    final sorted = List<_RouteSuggestion>.from(covered);
    sorted.sort((a, b) {
      final o = _origin;
      final n = TourCoverage.compareNearbyThenSport(
        distanceKmA:
            _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude),
        distanceKmB:
            _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude),
        sportMatchA: rankingSports.isEmpty ||
            TourFilters.softSportMatchAny(a.categories, rankingSports),
        sportMatchB: rankingSports.isEmpty ||
            TourFilters.softSportMatchAny(b.categories, rankingSports),
      );
      if (n != 0) return n;
      return _byDistanceThenDurationFit(a, b);
    });
    return sorted;
  }

  /// Seeds: nur 90 km Nähe — keine fremde Landschaft als Fill.
  List<_RouteSuggestion> _applyTourCoverage(List<_RouteSuggestion> base) {
    final seeds = base.where((r) => r.isSeed).toList();
    final rest = base.where((r) => !r.isSeed).toList();
    if (seeds.isEmpty) return base;
    if (!_hasRealOrigin) {
      return [...seeds.take(TourCoverage.maxCount), ...rest];
    }
    final o = _origin;
    final picked = TourCoverage.pickNearbyThenFill(
      items: seeds,
      distanceKm: (r) =>
          _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude),
    );
    return [...picked, ...rest];
  }

  int _byDistanceThenDurationFit(_RouteSuggestion a, _RouteSuggestion b) {
    final o = _origin;
    final da = _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude);
    final db = _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude);
    final c = da.compareTo(db);
    if (c != 0) return c;
    // Dann Duration-Fit (Spec: Distanz → Duration-Band).
    if (_minutes > 0) {
      final fit = DurationLens.fitDelta(
        a.durationMin,
        _minutes,
      ).compareTo(DurationLens.fitDelta(b.durationMin, _minutes));
      if (fit != 0) return fit;
    }
    // Loops leicht bevorzugen (Primary Lens = Rundkurse).
    final la = _isLoop(a) ? 0 : 1;
    final lb = _isLoop(b) ? 0 : 1;
    final lc = la.compareTo(lb);
    if (lc != 0) return lc;
    return b.matchScore.compareTo(a.matchScore);
  }

  /// D-60-LOOP-FILTER-01 — loop honesty (flag + closed geometry).
  /// - Curated seeds: explicit `is_loop` / hint wins (never empty from
  ///   synthetic-geometry false negatives; never promote linear seeds).
  /// - Live/catalog: geometry wins when known; else honest hint.
  bool _isLoop(_RouteSuggestion r) {
    if (r.isSeed) {
      return r.isLoopHint == true;
    }
    final shape = routeShapeOf(r.trackLngLat);
    if (shape == RouteShape.loop) return true;
    if (shape == RouteShape.pointToPoint) return false;
    return r.isLoopHint == true;
  }

  /// D-60-LOOP-FILTER-01 — ⟲ nur bei echten Loops.
  String? _shapeLabel(_RouteSuggestion r) {
    if (_isLoop(r)) return _l10n.discoverLoopBadge;
    final shape = routeShapeOf(r.trackLngLat);
    if (shape == RouteShape.pointToPoint) return _l10n.rideBarPointToPoint;
    // Never label linear / unknown as Runde — leave chip empty.
    return null;
  }

  /// Quick A→B / approx / demo polyline — not a closed loop.
  bool _isDemoOrAbOverlay(RouteResult? r) {
    if (r == null) return false;
    final eng = (r.engine ?? '').toLowerCase();
    if (eng.contains('demo') ||
        eng.contains('approx') ||
        eng.contains('fallback')) {
      return true;
    }
    return false;
  }

  /// S25: with Rundkurs filter, kill green A→B / Demo-Geometrie overlay.
  void _clearAbDemoOverlayForLoopFilter() {
    if (!_loopOnlyActive) return;
    if (_shellMode == DiscoverShellMode.navigate) return;
    final killQuick = _quick.isNotEmpty;
    final killComputed = _isDemoOrAbOverlay(_computed) ||
        (_selectedTourId == null && _computed != null && killQuick);
    if (!killComputed && !killQuick) return;
    _quick = const [];
    if (killComputed) {
      _computed = null;
      _label = null;
      _approach = null;
      _tourLayer = null;
    }
    final st = _status;
    if (st != null && _suppressDemoGeometryBanner(st)) {
      _setStatus(null);
    }
  }

  /// Prefer a curated nearby loop on the map when Rundkurs is on.
  ///
  /// Seeds may load before GPS (fallback origin ≈ W-Europe) and pick a distant
  /// city like Zurich. Once a real origin exists, always re-rank by distance and
  /// drop selections outside the Nähe radius (Komoot/AllTrails: near-me first).
  Future<void> _ensureLoopMapHonesty() async {
    if (!mounted || !_loopOnlyActive) return;
    // Navigieren A–B darf nicht von Rundkurs-Auswahl überschrieben werden.
    if (_shellMode == DiscoverShellMode.navigate || _planningAb) return;
    _clearAbDemoOverlayForLoopFilter();
    const seedRadiusKm = TourCoverage.nearbyRadiusKm;
    final o = _origin;
    final loops = _filtered.where((r) => _isLoop(r) && r.hasTrack).toList()
      ..sort((a, b) {
        final da = _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude);
        final db = _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude);
        return da.compareTo(db);
      });
    final pinId = _hofPinLoopId ??
        ref.read(discoverPendingLoopIdProvider) ??
        _selectedTourId;
    if (pinId != null && pinId.isNotEmpty && _selectedTourId != pinId) {
      if (mounted) setState(() => _selectedTourId = pinId);
    }
    final sel = _tourById(pinId);
    final selDist = sel == null
        ? null
        : _distKm(
            o.lat,
            o.lng,
            sel.center.latitude,
            sel.center.longitude,
          );
    final nearbyOk =
        sel != null && (!_hasRealOrigin || selDist! <= seedRadiusKm);
    if (DiscoverExploreChromeLogic.keepHofPin(
      selectedTourId: pinId,
      selectedFound: sel != null,
      selectedNearby: nearbyOk,
      loopsAvailable: loops.isNotEmpty,
    )) {
      if (sel != null && _isLoop(sel) && sel.hasTrack) {
        await _drawSeedLoopPreview(sel);
      }
      return;
    }
    if (loops.isEmpty) {
      // Far leftover selection (pre-GPS Zurich etc.) — clear map honesty.
      if (_selectedTourId != null || _computed != null) {
        if (mounted) {
          setState(() {
            _selectedTourId = null;
            _computed = null;
            _label = null;
            _approach = null;
            _tourLayer = null;
          });
        }
      }
      if (mounted) {
        setState(() {});
        await _drawAll();
      }
      return;
    }
    // Idle: Karte + Filter, keine ungewählte Nähe-Tour unterschieben.
    if (mounted) await _drawAll();
  }

  Future<void> _drawSeedLoopPreview(_RouteSuggestion r) async {
    if (_shellMode == DiscoverShellMode.navigate || _planningAb) return;
    final gen = _previewGen;
    // Echte Wege statt synthetischem Kreis, sobald das Routing sie kennt.
    final routed = _routedLoopCache[r.id];
    final track = routed != null
        ? [
            for (final p in routed) [p.lng, p.lat]
          ]
        : r.trackLngLat;
    if (track == null || track.length < 4) {
      await _drawAll();
      return;
    }
    final coords = [
      for (final c in track) GeoPoint(c[1], c[0]),
    ];
    var distM = 0.0;
    for (var i = 1; i < coords.length; i++) {
      distM += _distKm(
            coords[i - 1].lat,
            coords[i - 1].lng,
            coords[i].lat,
            coords[i].lng,
          ) *
          1000;
    }
    final preview = RouteResult(
      coordinates: coords,
      distanceM: routed != null ? distM : r.distanceKm * 1000,
      durationS: (r.durationMin * 60).toDouble(),
      engine: routed != null ? 'seed-loop-routed' : 'seed-loop',
      steps: const [],
    );
    if (!mounted || gen != _previewGen) return;
    if (_shellMode == DiscoverShellMode.navigate || _planningAb) return;
    setState(() {
      _computed = preview;
      _label = r.name;
      _quick = const [];
      _approach = null;
      _tourLayer = null;
      _setStatus(null);
    });
    await _drawAll();
    if (!mounted || gen != _previewGen || _planningAb) return;
    await _focusCameraOnTour(r);
    // Live-Upgrade nur wenn noch keine gebackene/routed Geometrie da ist.
    if (routed == null) {
      unawaited(_upgradeSeedLoopGeometry(r));
    }
  }

  /// Lädt im Hintergrund echte Routen-Geometrie für einen Seed-Loop und
  /// ersetzt den synthetischen Kreis sofort in Cache + Tour-Track.
  Future<void> _upgradeSeedLoopGeometry(_RouteSuggestion _) async {
    // Keep baked / catalog tracks. Do not invent geometric vias
    // around the pin — they cut through fields.
  }

  /// Background pentagon routing is disabled — vias land in fields.
  Future<void> _warmVisibleMapTourGeometries(
    List<_RouteSuggestion> _,
  ) async {}

  double _distKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  Iterable<OsmTrailSegment> get _trailsForLastMile sync* {
    final dest = _destinationTrail;
    if (dest != null &&
        trailIsCorridorEligible(
          highway: dest.highway,
          difficulty: dest.difficulty,
        )) {
      yield dest;
    }
  }

  TrailLastMile? _lastMileForDest(GeoPoint from, GeoPoint to) {
    // Only when the rider tapped a trail — not every OSM farm track
    // within 90 m of a map pin (that sends the line through a field).
    final dest = _destinationTrail;
    if (dest == null) return null;
    if (!trailIsCorridorEligible(
      highway: dest.highway,
      difficulty: dest.difficulty,
    )) {
      return null;
    }
    return clipTrailLastMile(
      trailLngLat: dest.geometry,
      fromLat: from.lat,
      fromLng: from.lng,
      toLat: to.lat,
      toLng: to.lng,
    );
  }

  GeoPoint _snapViaPoint(GeoPoint p) {
    final trails = <List<List<double>>>[
      if (_destinationTrail != null &&
          trailIsCorridorEligible(
            highway: _destinationTrail!.highway,
            difficulty: _destinationTrail!.difficulty,
          ))
        _destinationTrail!.geometry,
      for (final t in _sGradeTrails)
        if (trailIsCorridorEligible(
          highway: t.highway,
          difficulty: t.difficulty,
        ))
          t.geometry,
    ];
    final hit = snapPointOntoTrails(
      trails: trails,
      lat: p.lat,
      lng: p.lng,
    );
    if (hit == null) return p;
    return GeoPoint(hit.lat, hit.lng);
  }

  bool _isAbDetour(RouteResult r, GeoPoint from, GeoPoint to) {
    return isImplausibleAbDetour(
      distanceM: r.distanceM,
      fromLat: from.lat,
      fromLng: from.lng,
      toLat: to.lat,
      toLng: to.lng,
      vias: [
        for (final v in _vias) (lat: v.lat, lng: v.lng),
      ],
    );
  }

  /// Live ORS with net. Local Dijkstra only without net, A–B, covering pack.
  /// Browse pin A–B sets [liveStreetOnly] so the pack graph cannot draw
  /// field-scale lines after a miss or a stale offline probe.
  Future<RouteResult> _discoverPlanRoute({
    required GeoPoint from,
    required GeoPoint to,
    List<GeoPoint> vias = const [],
    RoutingProfile? profile,
    bool accessLeg = false,
    RouteVariant variant = RouteVariant.planned,
    bool liveStreetOnly = false,
  }) async {
    final p = profile ?? _abCosting;
    final access = accessLeg || p == RoutingProfile.driving;
    final online = await _discoverHasNetwork();
    final flags = liveStreetOnly
        ? discoverBrowseAbEngineChoice(online: online)
        : discoverAbEngineChoice(
            online: online,
            viasEmpty: vias.isEmpty,
          );
    if (liveStreetOnly && !online) {
      throw StateError('browse-needs-network');
    }
    return _routes.planRoute(
      from: from,
      to: to,
      profile: p,
      vias: vias,
      accessLeg: access,
      variant: variant,
      preferOffline: flags.preferOffline,
      allowOfflineFirst: flags.allowOfflineFirst,
      allowOnline: flags.allowOnline,
      allowOfflineFallback: flags.allowOfflineFallback,
    );
  }

  Future<RouteResult> _planRouteMaybeRetry({
    required GeoPoint from,
    required GeoPoint to,
    List<GeoPoint> vias = const [],
    RoutingProfile? profile,
    bool accessLeg = false,
    RouteVariant variant = RouteVariant.planned,
    bool liveStreetOnly = false,
  }) async {
    final p = profile ?? _abCosting;
    var result = await _discoverPlanRoute(
      from: from,
      to: to,
      profile: p,
      vias: vias,
      accessLeg: accessLeg,
      variant: variant,
      liveStreetOnly: liveStreetOnly,
    );
    if (p == RoutingProfile.driving || p == RoutingProfile.hiking) {
      unawaited(_refreshOfflineChip());
      return result;
    }
    if (!_isAbDetour(result, from, to)) {
      unawaited(_refreshOfflineChip());
      return result;
    }
    await _routes.invalidateRoute(
      from: from,
      to: to,
      profile: p,
      vias: vias,
      accessLeg: accessLeg || p == RoutingProfile.driving,
      variant: variant,
    );
    result = await _discoverPlanRoute(
      from: from,
      to: to,
      profile: p,
      vias: vias,
      accessLeg: accessLeg,
      variant: variant,
      liveStreetOnly: liveStreetOnly,
    );
    unawaited(_refreshOfflineChip());
    return result;
  }

  RouteResult _stitchApproachLastMile(
      RouteResult approach, TrailLastMile mile) {
    final trailPts = [for (final c in mile.geometry) GeoPoint(c[1], c[0])];
    var rest = trailPts;
    if (approach.coordinates.isNotEmpty && trailPts.isNotEmpty) {
      final a = approach.coordinates.last;
      final b = trailPts.first;
      if (haversineM(a.lat, a.lng, b.lat, b.lng) < 18) {
        rest = trailPts.skip(1).toList();
      }
    }
    return RouteResult(
      coordinates: [...approach.coordinates, ...rest],
      distanceM: approach.distanceM + mile.lastMileM,
      durationS: approach.durationS + mile.lastMileM / 2.5,
      engine: '${approach.engine ?? 'engine'}+trail-last-mile',
      steps: approach.steps,
      warnings: [
        ...approach.warnings,
        'Letzte Meile auf dem Trail bis zum Tipp.',
      ],
    );
  }

  Future<void> _calcAb({
    bool keepLine = false,
    bool refitPins = true,
  }) async {
    final from = _start;
    final to = _end;
    if (from == null || to == null) {
      setState(
          () => _error = AppLocalizations.of(context).navigateNeedStartEnd);
      return;
    }
    final keep = keepLine &&
        shouldKeepStaleDiscoverLine(
          hasLiveStreetLine: _hasLivePlanLine,
          leftoverTourOnMap: false,
        );
    setState(() {
      _loading = true;
      _error = null;
      _weatherStart = null;
      _weatherSummit = null;
      _filmstripShots = const [];
      _routeLineStale = keep;
      if (!keep) {
        _computed = null;
        _approach = null;
        _trailOverlay = null;
      } else {
        _trailOverlay = null;
        _tourLayer = null;
      }
      _ideaPin = null;
      _selectedTourId = null;
      _skipAutoCameraFit = keep && !refitPins;
      _planDragAlongLabel = null;
      if (keep) _setStatus(_l10n.discoverRoutingAdapts);
    });
    _previewGen++;
    final gen = ++_calcAbGen;
    if (!keep) _startDestPulse();
    unawaited(_drawAll());
    unawaited(_syncPlanHintScreen());
    try {
      final vias = List<GeoPoint>.from(_viaPoints);
      final namedDest = namedPlaceHudTitle(
            _endAddrCtrl.text,
            skipExact: _l10n.discoverSuggestEnd,
          ) !=
          null;
      // Trail-Last-Mile nur bei Karten-Tap auf den Trail — nicht Café/Adresse.
      final mile =
          !namedDest && vias.isEmpty && _routeVariant == RouteVariant.planned
              ? _lastMileForDest(from, to)
              : null;
      late RouteResult result;
      RouteResult? approach;
      List<GeoPoint>? trailOverlay;
      var dest = to;

      if (mile != null) {
        dest = GeoPoint(mile.destLat, mile.destLng);
        final nudged = nudgeJoinTowardRider(
          joinLat: mile.joinLat,
          joinLng: mile.joinLng,
          fromLat: from.lat,
          fromLng: from.lng,
        );
        final join = GeoPoint(nudged.lat, nudged.lng);
        approach = await _planRouteMaybeRetry(
          from: from,
          to: join,
          profile: _abCosting,
          accessLeg: _navPolicy.isGravity,
          liveStreetOnly: true,
        );
        if (!mounted || gen != _calcAbGen) return;
        var merged = _stitchApproachLastMile(approach, mile);
        if (_isAbDetour(approach, from, join)) {
          final direct = await _planRouteMaybeRetry(
            from: from,
            to: dest,
            profile: _abCosting,
            accessLeg: _navPolicy.isGravity,
            liveStreetOnly: true,
          );
          if (!mounted || gen != _calcAbGen) return;
          if (!_isAbDetour(direct, from, dest) &&
              direct.distanceM + 400 < merged.distanceM) {
            result = direct;
            approach = null;
            trailOverlay = null;
          } else {
            result = merged;
            trailOverlay = [
              for (final c in mile.geometry) GeoPoint(c[1], c[0]),
            ];
          }
        } else {
          result = merged;
          trailOverlay = [
            for (final c in mile.geometry) GeoPoint(c[1], c[0]),
          ];
        }
      } else {
        // Café/Stadt-A–B folgt dem Discover-Rad, nicht Gravity-Auto.
        // Auto bleibt der Last-Mile-Zugang bis zum Trail.
        result = await _planRouteMaybeRetry(
          from: from,
          to: to,
          vias: vias,
          profile: _profile,
          accessLeg: false,
          variant: _routeVariant,
          liveStreetOnly: planCalcUsesLiveStreetsOnly(
            fromBrowsePin: _abFromBrowsePin,
            viasEmpty: vias.isEmpty,
          ),
        );
        if (!mounted || gen != _calcAbGen) return;
        if (_isAbDetour(result, from, to)) {
          setState(() {
            _loading = false;
            _routeLineStale = false;
            if (!keep) _computed = null;
            _error = _l10n.discoverUnplausibleDropped;
          });
          return;
        }
      }
      if (!mounted || gen != _calcAbGen) return;
      await _refreshOfflineChip();
      if (!mounted || gen != _calcAbGen) return;
      final lineLngLat = [
        for (final p in result.coordinates) [p.lng, p.lat],
      ];
      final startIsGps = _userPos != null &&
          haversineM(from.lat, from.lng, _userPos!.lat, _userPos!.lng) < 40;
      var startOut = from;
      var snappedPins = false;
      if (trailOverlay == null) {
        final snap = applyFarmTrimPinSnap(
          startLat: from.lat,
          startLng: from.lng,
          endLat: dest.lat,
          endLng: dest.lng,
          lineLngLat: lineLngLat,
          warnings: result.warnings,
          startIsGps: startIsGps,
        );
        if (snap.snappedStart) {
          startOut = GeoPoint(snap.startLat, snap.startLng);
          snappedPins = true;
        }
        if (snap.snappedEnd) {
          dest = GeoPoint(snap.endLat, snap.endLng);
          snappedPins = true;
        }
      }
      setState(() {
        _start = startOut;
        _end = dest;
        if (snappedPins) {
          _endAddrCtrl.text = _l10n.discoverOnMapPlace;
        }
        _computed = result;
        _approach = approach;
        _trailOverlay = trailOverlay;
        _routeLineStale = false;
        _gravityComputed = mile != null && _navPolicy.isGravity;
        _label = plannedRouteHudLabel(
          destinationField: _endAddrCtrl.text,
          plannedFallback: _l10n.discoverPlannedRoute,
          suggestEndPlaceholder: _l10n.discoverSuggestEnd,
        );
        _tourLayer = null;
        _selectedTourId = null;
        if (result.engine == 'fallback-line') {
          _setStatus(_l10n.discoverStraightFallback, approx: true);
        } else if (result.variant != RouteVariant.planned &&
            !result.variantApplied) {
          _setStatus(_l10n.discoverVariantValhallaOnly);
        } else if (result.riderWarning != null &&
            !result.riderWarning!.contains('in die Navi übernommen')) {
          _setStatus(_l10n.discoverRiderHonestyFor(result.riderWarning!));
        } else if (isOfflineRoutingEngine(result.engine)) {
          final packName = _offlinePackLabel?.trim() ?? '';
          _setStatus(
            packName.isEmpty
                ? _l10n.discoverOfflineRouteReady
                : _l10n.discoverOfflineRouteReadyNamed(packName),
          );
        }
      });
      await _drawAll();
      if (snappedPins) unawaited(_reversePlanFieldLabels());
      if (!mounted || gen != _calcAbGen) return;
      await _refreshElevation(result);
      if (!mounted || gen != _calcAbGen) return;
      await _refreshNavigateOfflineHint();
      unawaited(_rememberLastPlanDest());
    } catch (e) {
      if (mounted && gen == _calcAbGen) {
        setState(
          () => _error = _liveRouteError(
            e,
            browsePin: planCalcUsesLiveStreetsOnly(
              fromBrowsePin: _abFromBrowsePin,
              viasEmpty: _vias.isEmpty,
            ),
          ),
        );
      }
    } finally {
      if (gen == _calcAbGen) {
        // Match Web: parked reshape finger dies when the engine goes idle.
        if (mounted) {
          setState(() {
            _loading = false;
            _planShapeHintAt = null;
          });
        } else {
          _planShapeHintAt = null;
        }
        if (_end != null && _start == null) {
          _startDestPulse();
        } else {
          _stopDestPulse();
        }
      }
    }
  }

  Future<void> _hybridSnap(_RouteSuggestion tour) async {
    final from = _riderOrigin;
    if (from == null) {
      if (mounted) {
        setState(() => _error = _l10n.discoverNeedLocationTrails);
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _setStatus(null);
    });
    try {
      final entry = GeoPoint(tour.center.latitude, tour.center.longitude);
      final dKm = trailAccessHaversineKm(
        from.lat,
        from.lng,
        entry.lat,
        entry.lng,
      );
      final kind = suggestedApproachKind(policy: _navPolicy, distanceKm: dKm);
      final costing = _navPolicy.isGravity
          ? approachRoutingProfile(
              _garageCategory ?? BikeCategory.urban,
              kind == ApproachKind.atStart ? ApproachKind.walk : kind,
            )
          : _profile;
      final approach = await _discoverPlanRoute(
        from: from,
        to: entry,
        profile: costing,
        accessLeg: _navPolicy.isGravity,
      );
      unawaited(_refreshOfflineChip());
      final routed = await _geometryForTour(tour);
      if (!mounted) return;

      if (routed.demo || routed.points.length < 2) {
        setState(() {
          _approach = approach;
          _tourLayer = null;
          _computed = approach;
          _ideaPin = tour.center;
          _label = _l10n.discoverApproachName(tour.name);
          _start = from;
          _end = entry;
          _selectedTourId = tour.id;
          _setStatus(_l10n.discoverPoiIdeaHint);
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
          // Tour, die gar nicht mehr gemeint war.
          _detailId = null;
          _pick = _PickMode.none;
        });
        await _drawAll();
        await _syncMarkers();
        return;
      }

      final track = routed.points;
      final merged = RouteResult(
        coordinates: [...approach.coordinates, ...track],
        distanceM: approach.distanceM + tour.distanceKm * 1000,
        durationS: approach.durationS + tour.durationMin * 60,
        engine: '${approach.engine ?? 'engine'}+tour',
        steps: approach.steps,
      );
      final tourEnd = track.last;
      setState(() {
        _approach = approach;
        _tourLayer = RouteResult(
          coordinates: track,
          distanceM: tour.distanceKm * 1000,
          durationS: tour.durationMin * 60.0,
          engine: 'tour',
        );
        _computed = merged;
        _ideaPin = null;
        _label = _l10n.discoverFromHereName(tour.name);
        _start = from;
        _end = tourEnd;
        _selectedTourId = tour.id;
        _setStatus(_l10n
            .discoverHybridKm((merged.distanceM / 1000).toStringAsFixed(1)));
        _shellMode = DiscoverShellMode.explore;
        _surface = _Surface.discover;
      });
      await _drawAll();
      await _refreshElevation(merged);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = _liveRouteError(e),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Live-Rundtour um [center]. Ohne Engine: leere Punkte (= nur Pin, kein Fake-Track).
  ///
  /// Prefer one `/api/route` call with vias (street-continuous). Per-leg fallback
  /// aborts on `fallback-line` / `approx` so polygonal rulers never become a
  /// “finished” loop on the map.
  // Unused: live pentagon vias land in fields. Kept for a future street-loop path.
  // ignore: unused_element
  Future<({List<GeoPoint> points, bool demo})> _routedTourGeometry(
    LatLng center,
    double distanceKm,
  ) async {
    if (_navPolicy.isGravity) {
      return (points: const <GeoPoint>[], demo: true);
    }
    final radiusKm = math.max(0.8, distanceKm / (2 * math.pi));
    final cosLat =
        math.cos(center.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
    final dLat = (radiusKm * 0.92) / 111.0;
    final dLng = (radiusKm * 1.06) / (111.0 * cosLat);
    const n = 5;
    final ring = <GeoPoint>[];
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final wobble = 0.82 + 0.28 * ((i % 3) / 2);
      ring.add(
        GeoPoint(
          center.latitude + dLat * math.sin(a) * wobble,
          center.longitude + dLng * math.cos(a) * wobble,
        ),
      );
    }

    bool isRulerEngine(String? eng) =>
        eng == 'fallback-line' ||
        eng == 'approx' ||
        (eng?.contains('demo') ?? false);

    // Single request: from → vias → back to start (closed street loop).
    // Dijkstra is A–B only — skip the via shot without net.
    try {
      if (await _discoverHasNetwork()) {
        final oneShot = await _routes.planRoute(
          from: ring.first,
          to: ring.first,
          vias: ring.sublist(1),
          profile: _profile,
          allowOnline: true,
          allowOfflineFirst: false,
        );
        if (!isRulerEngine(oneShot.engine) &&
            oneShot.coordinates.length >= 8 &&
            isUsableMapTrack([
              for (final p in oneShot.coordinates) [p.lng, p.lat],
            ])) {
          return (points: oneShot.coordinates, demo: false);
        }
      }
    } catch (_) {
      // Fall through to per-leg.
    }

    final waypoints = [...ring, ring.first];
    final coords = <GeoPoint>[];
    try {
      for (var i = 0; i < waypoints.length - 1; i++) {
        final leg = await _discoverPlanRoute(
          from: waypoints[i],
          to: waypoints[i + 1],
          profile: _profile,
        );
        if (isRulerEngine(leg.engine) || leg.coordinates.length < 2) {
          // One straight leg poisons the whole ring — pin-only honesty.
          return (points: const <GeoPoint>[], demo: true);
        }
        if (coords.isEmpty) {
          coords.addAll(leg.coordinates);
        } else {
          coords.addAll(leg.coordinates.skip(1));
        }
      }
    } catch (_) {
      // Caller zeigt Pin-only Status.
    }
    final lngLat = [
      for (final p in coords) [p.lng, p.lat]
    ];
    if (coords.length >= 8 && isUsableMapTrack(lngLat)) {
      return (points: coords, demo: false);
    }
    return (points: const <GeoPoint>[], demo: true);
  }

  List<List<double>>? _parseLngLatTrack(dynamic raw) {
    if (raw == null) return null;
    List? coords;
    if (raw is Map) {
      final g = raw['coordinates'] ?? raw['geometry'];
      if (g is Map) {
        coords = g['coordinates'] as List?;
      } else if (g is List) {
        coords = g;
      }
    } else if (raw is List) {
      coords = raw;
    }
    if (coords == null || coords.length < 2) return null;
    final out = <List<double>>[];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        final a = (c[0] as num).toDouble();
        final b = (c[1] as num).toDouble();
        // GeoJSON: [lng, lat]. Tausch nur bei klarem [lat,lng]-Muster.
        if (a.abs() <= 90 &&
            b.abs() <= 180 &&
            a.abs() > b.abs() &&
            b.abs() <= 90) {
          out.add([b, a]); // lat,lng → lng,lat
        } else {
          out.add([a, b]);
        }
      } else if (c is Map) {
        final lat = (c['lat'] as num?)?.toDouble();
        final lng =
            (c['lng'] as num?)?.toDouble() ?? (c['lon'] as num?)?.toDouble();
        if (lat != null && lng != null) out.add([lng, lat]);
      }
    }
    return out.length >= 2 ? out : null;
  }

  Future<({List<GeoPoint> points, bool demo})> _geometryForTour(
    _RouteSuggestion tour,
  ) async {
    final cached = _routedLoopCache[tour.id];
    final hasCache = cached != null &&
        isUsableMapTrack([
          for (final p in cached) [p.lng, p.lat]
        ]);
    final hasTrack = tour.hasTrack;
    final trackUsable = tour.hasUsableTrack;
    final loop = _isLoop(tour);
    final source = chooseTourNavGeometry(
      hasCache: hasCache,
      hasTrack: hasTrack,
      isLoop: loop,
      trackUsable: trackUsable,
    );

    // Selected / baked / organic track wins for Navigation — never silently
    // replace a curated Rundkurs with a fresh live A→B or different ring.
    switch (source) {
      case TourNavGeometrySource.cache:
        return (points: cached!, demo: false);
      case TourNavGeometrySource.track:
        return (
          points: [for (final c in tour.trackLngLat!) GeoPoint(c[1], c[0])],
          demo: false,
        );
      case TourNavGeometrySource.liveClosed:
      case TourNavGeometrySource.none:
        break;
    }

    final bundled = _bundledSeedTrackFor(tour);
    if (bundled != null && bundled.length >= 4) {
      return (
        points: [for (final c in bundled) GeoPoint(c[1], c[0])],
        demo: false,
      );
    }

    final catalogBake = await CatalogTourGeometryStore.geometryFor(tour.id);
    if (catalogBake != null && isUsableMapTrack(catalogBake)) {
      return (
        points: [for (final c in catalogBake) GeoPoint(c[1], c[0])],
        demo: false,
      );
    }

    // Pin-only idea without a baked track: do not wait on catalog/live
    // pentagon vias that land in fields.
    if (_isPinOnlyIdea(tour) && !loop) {
      return (points: const <GeoPoint>[], demo: true);
    }

    if (tour.isCatalog) {
      try {
        final api = await _fetchCatalogTourGeometry(tour)
            .timeout(const Duration(seconds: 20));
        if (api != null) return api;
      } catch (_) {}
    }

    // Never invent geometric vias around the pin — they land in fields.
    return (points: const <GeoPoint>[], demo: true);
  }

  bool _isPinOnlyIdea(_RouteSuggestion r) {
    if (r.hasUsableTrack) return false;
    if (r.hasTrack) return false;
    return r.id.startsWith('idea-') ||
        r.id.startsWith('oa-') ||
        r.id.contains('demo') ||
        r.isCatalog;
  }

  List<List<double>>? _bundledSeedTrackFor(_RouteSuggestion tour) {
    if (tour.isSeed) return null;
    final bundle = _seedsBundle;
    if (bundle == null) return null;
    final match = pickBundledSeedForCatalog(
      catalogName: tour.name,
      catalogLat: tour.center.latitude,
      catalogLng: tour.center.longitude,
      catalogDistanceKm: tour.distanceKm,
      seeds: [
        for (final s in bundle.routes)
          if (s.trackLngLat != null)
            (
              title: s.title,
              lat: s.centerLat,
              lng: s.centerLng,
              distanceKm: s.distanceKm,
              trackLngLat: s.trackLngLat!,
            ),
      ],
    );
    final track = match?.trackLngLat;
    if (track == null || !isUsableMapTrack(track)) return null;
    return track;
  }

  List<_RouteSuggestion> _catalogEnrichedWithSeeds(
    List<_RouteSuggestion> tours,
  ) {
    final bundle = _seedsBundle;
    if (bundle == null) return tours;
    final seeds = [
      for (final s in bundle.routes)
        if (s.trackLngLat != null && isUsableMapTrack(s.trackLngLat))
          (
            title: s.title,
            lat: s.centerLat,
            lng: s.centerLng,
            distanceKm: s.distanceKm,
            trackLngLat: s.trackLngLat!,
          ),
    ];
    if (seeds.isEmpty) return tours;
    return [
      for (final t in tours) _attachBundledSeedIfCatalog(t, seeds),
    ];
  }

  _RouteSuggestion _attachBundledSeedIfCatalog(
    _RouteSuggestion t,
    List<
            ({
              String title,
              double lat,
              double lng,
              double distanceKm,
              List<List<double>> trackLngLat,
            })>
        seeds,
  ) {
    if (!t.isCatalog || t.hasUsableTrack) return t;
    final hit = pickBundledSeedForCatalog(
      catalogName: t.name,
      catalogLat: t.center.latitude,
      catalogLng: t.center.longitude,
      catalogDistanceKm: t.distanceKm,
      seeds: seeds,
    );
    if (hit == null) return t;
    return t.copyWith(
      trackLngLat: hit.trackLngLat,
      center: LatLng(hit.lat, hit.lng),
    );
  }

  Future<({List<GeoPoint> points, bool demo})?> _fetchCatalogTourGeometry(
    _RouteSuggestion tour,
  ) async {
    final hit = await PublicToursClient().fetchGeometry(
      tourId: tour.id,
      profile: _profile.apiId,
    );
    if (hit == null || hit.coordinates.length < 4) return null;
    final eng = hit.engine ?? '';
    if (eng.contains('demo') || eng == 'fallback-line' || eng == 'approx') {
      return null;
    }
    final lngLat = hit.coordinates;
    if (!isUsableMapTrack(lngLat)) return null;
    if (_isLoop(tour) &&
        !isAcceptableLiveLoop(
          trackLngLat: lngLat,
          expectedDistanceKm: tour.distanceKm,
        )) {
      return null;
    }
    final points = [for (final c in lngLat) GeoPoint(c[1], c[0])];
    _routedLoopCache[tour.id] = points;
    return (points: points, demo: false);
  }

  /// Komoot-ähnliche Route: dunkles Casing + helle Hauptlinie.
  /// Selected = dickes Casing; Unselected routed = dünneres Casing, gedämpft.
  Future<List<({Line line, double opacity})>> _addKomootLine(
    MapLibreMapController c,
    List<LatLng> geometry, {
    required bool active,
    String lineColor = '#2ECC71',
    Map<String, dynamic>? data,
    bool casing = true,
    bool skipCore = false,
    double opacityMul = 1,
    bool grab = false,
  }) async {
    final out = <({Line line, double opacity})>[];
    if (geometry.length < 2) return out;
    final mul = opacityMul.clamp(0.2, 1.0);
    if (casing && active) {
      final glowOp = DiscoverMapLineStyle.selectedGlowOpacity * mul;
      out.add((
        line: await c.addLine(
          LineOptions(
            geometry: geometry,
            lineColor: DiscoverMapLineStyle.selectedGlow,
            lineWidth: DiscoverMapLineStyle.selectedGlowWidth,
            lineOpacity: glowOp,
            lineJoin: 'round',
          ),
          data,
        ),
        opacity: glowOp,
      ));
      final caseOp = DiscoverMapLineStyle.activeCasingOpacity * mul;
      out.add((
        line: await c.addLine(
          LineOptions(
            geometry: geometry,
            lineColor: DiscoverMapLineStyle.activeCasing,
            lineWidth: DiscoverMapLineStyle.activeCasingWidth,
            lineOpacity: caseOp,
            lineJoin: 'round',
          ),
          data, // same data so tap on casing still selects trail/route
        ),
        opacity: caseOp,
      ));
    } else if (casing && !active) {
      final muteOp = DiscoverMapLineStyle.mutedCasingOpacity * mul;
      out.add((
        line: await c.addLine(
          LineOptions(
            geometry: geometry,
            lineColor: DiscoverMapLineStyle.mutedCasing,
            lineWidth: DiscoverMapLineStyle.mutedCasingWidth,
            lineOpacity: muteOp,
            lineJoin: 'round',
          ),
          data,
        ),
        opacity: muteOp,
      ));
    }
    if (skipCore) return out;
    final coreOp = (active
            ? DiscoverMapLineStyle.activeOpacity
            : DiscoverMapLineStyle.inactiveOpacity) *
        mul;
    final core = await c.addLine(
      LineOptions(
        geometry: geometry,
        lineColor: lineColor,
        lineWidth: active
            ? DiscoverMapLineStyle.activeWidth
            : DiscoverMapLineStyle.inactiveWidth,
        lineOpacity: coreOp,
        lineJoin: 'round',
      ),
      data,
    );
    out.add((line: core, opacity: coreOp));
    if (grab) {
      final halo = await c.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: DiscoverMapLineStyle.planGrabHalo,
          lineWidth: DiscoverMapLineStyle.planGrabHaloWidth,
          lineOpacity: DiscoverMapLineStyle.planGrabHaloOpacity,
          lineJoin: 'round',
          draggable: false,
        ),
        data,
      );
      _planGrabGeom[halo.id] = [
        for (final p in geometry) LatLng(p.latitude, p.longitude),
      ];
      _planGrabLines.add(halo);
    }
    return out;
  }

  /// Hof-/Deep-Link: Loop-ID merken, Provider erst löschen wenn die Tour da ist.
  void pinFromHof(String id) => _pinPendingLoop(id);

  void _pinPendingLoop(String? id) {
    if (id == null || id.isEmpty) return;
    debugPrint('HofPin: $id tours=${_tours.length}');
    _hofPinLoopId = id;
    _skipAutoCameraFit = false;
    _listBrowseMode = false;
    if (_selectedTourId != id) {
      setState(() => _selectedTourId = id);
    }
    final tour = _tourById(id);
    if (tour == null) return;
    if (ref.read(discoverPendingLoopIdProvider) == id) {
      ref.read(discoverPendingLoopIdProvider.notifier).state = null;
    }
    unawaited(_drawSeedLoopPreview(tour));
  }

  Future<void> _focusCameraOnTour(_RouteSuggestion r) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    _skipAutoCameraFit = true;
    final track = r.trackLngLat;
    if (track != null && track.length >= 2) {
      final lats = [for (final c in track) c[1]];
      final lngs = [for (final c in track) c[0]];
      final swLat = lats.reduce((a, b) => a < b ? a : b);
      final swLng = lngs.reduce((a, b) => a < b ? a : b);
      final neLat = lats.reduce((a, b) => a > b ? a : b);
      final neLng = lngs.reduce((a, b) => a > b ? a : b);
      if ((neLat - swLat).abs() < 1e-5 && (neLng - swLng).abs() < 1e-5) {
        await map.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(swLat, swLng), 13.5),
        );
      } else {
        await map.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(swLat, swLng),
              northeast: LatLng(neLat, neLng),
            ),
            left: 40,
            top: 110,
            right: 40,
            bottom: _panelInset + 40,
          ),
        );
      }
      return;
    }
    await map.animateCamera(
      CameraUpdate.newLatLngZoom(r.center, 13.5),
    );
  }

  _RouteSuggestion? _tourById(String? id) {
    if (id == null) return null;
    for (final r in _tours) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Primär-CTA für Pin-Ideen: vorhandener Track, sonst A→B zum Pin.
  /// Keine geometrische Runde und kein Ziel irgendwo im Feld.
  Future<void> _computeIdeaRoute(_RouteSuggestion tour) async {
    setState(() {
      _loading = true;
      _error = null;
      _setStatus(_l10n.discoverAroundPoiComputing, warm: true);
      _selectedTourId = tour.id;
      _ideaPin = tour.center;
      _label = tour.name;
    });
    try {
      final cached = _routedLoopCache[tour.id];
      final cacheOk = cached != null &&
          isUsableMapTrack([
            for (final p in cached) [p.lng, p.lat]
          ]);
      final useExisting = tour.hasUsableTrack || cacheOk;
      if (useExisting) {
        final routed = await _geometryForTour(tour);
        if (!mounted) return;
        if (!routed.demo && routed.points.length >= 2) {
          final preview = RouteResult(
            coordinates: routed.points,
            distanceM: tour.distanceKm * 1000,
            durationS: tour.durationMin * 60.0,
            engine: 'tour-routed',
          );
          setState(() {
            _computed = preview;
            _ideaPin = null;
            _start = routed.points.first;
            _end = routed.points.last;
            _destinationTrail = null;
            _vias.clear();
            _surface = _Surface.plan;
            _shellMode = DiscoverShellMode.navigate;
            _detailId = null;
            _pick = _PickMode.none;
            _startAddrCtrl.text = _l10n.discoverOnMapPlace;
            _endAddrCtrl.text = _l10n.discoverOnMapPlace;
            _setStatus(_l10n.discoverLiveRouteReady(
                (preview.distanceM / 1000).toStringAsFixed(1)));
            _loading = false;
          });
          await _drawRoute(preview);
          await _syncMarkers();
          unawaited(_reversePlanFieldLabels());
          await _refreshElevation(preview);
          return;
        }
      }

      final pin = GeoPoint(tour.center.latitude, tour.center.longitude);
      final ab = pinOnlyAbEndpoints(
        pinLat: pin.lat,
        pinLng: pin.lng,
        startLat: _start?.lat,
        startLng: _start?.lng,
        userLat: _userPos?.lat,
        userLng: _userPos?.lng,
        preferGps: true,
      );
      if (ab == null) {
        setState(() {
          _start = pin;
          _end = null;
          _destinationTrail = null;
          _vias.clear();
          _computed = null;
          _tourLayer = null;
          _approach = null;
          _ideaPin = tour.center;
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          _detailId = null;
          _pick = _PickMode.end;
          _startAddrCtrl.text = _l10n.discoverPoiNamed(tour.name);
          _endAddrCtrl.text = _l10n.discoverSuggestEnd;
          _setStatus(_l10n.discoverIdeaStartSet);
          _loading = false;
        });
        await _drawAll();
        await _syncMarkers();
        return;
      }

      final fromGps = _userPos != null;
      setState(() {
        _start = GeoPoint(ab.startLat, ab.startLng);
        _end = pin;
        _destinationTrail = null;
        _vias.clear();
        _computed = null;
        _tourLayer = null;
        _approach = null;
        _ideaPin = tour.center;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        _detailId = null;
        _pick = _PickMode.none;
        _startAddrCtrl.text =
            fromGps ? _l10n.discoverMyPosition : _l10n.discoverOnMapPlace;
        _endAddrCtrl.text = _l10n.discoverPoiNamed(tour.name);
        _setStatus(_l10n.discoverNotLoopAb);
        _loading = false;
      });
      await _drawAll();
      await _syncMarkers();
      unawaited(_reversePlanFieldLabels());
      await _calcAb();
      if (mounted && _computed != null) {
        setState(() {
          _setStatus(_l10n.discoverLiveRouteReady(
              (_computed!.distanceM / 1000).toStringAsFixed(1)));
          _ideaPin = null;
        });
        await _syncMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _liveRouteError(e);
          _setStatus(_l10n.discoverRoutingFailedRetry);
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          _detailId = null;
          _pick = _PickMode.end;
        });
      }
    }
  }

  BikeOverlayFamily get _overlayFamily => overlayFamilyForProfile(_profile);

  BikeCategory? get _garageCategory {
    final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
    Bike? active;
    for (final b in bikes) {
      if (b.isActive) {
        active = b;
        break;
      }
    }
    active ??= bikes.isEmpty ? null : bikes.first;
    return active?.category ??
        ref.read(userProfileStoreProvider).preferredSport;
  }

  NavPolicy get _navPolicy =>
      navPolicyForBike(_garageCategory ?? BikeCategory.urban);

  RoutingProfile get _abCosting =>
      _navPolicy.isGravity ? RoutingProfile.driving : _profile;

  void _maybeWarmLiveRouting(GeoPoint? near) {
    if (near == null) return;
    if (!shouldWarmLiveRouting(
      hasStart: _start != null,
      hasEnd: _end != null,
    )) {
      return;
    }
    final cell = liveRoutingWarmupCell(
      profile: _abCosting.apiId,
      lat: near.lat,
      lng: near.lng,
    );
    if (_liveWarmupCell == cell) return;
    _liveWarmupCell = cell;
    unawaited(_routes.warmupLiveRouting(near: near, profile: _abCosting));
  }

  bool _trailFitsGarage(OsmTrailSegment trail) => trailFitsBike(
        bike: _garageCategory ?? BikeCategory.urban,
        scale: trail.difficulty,
      );

  void _applyBikeNavDefaults(BikeCategory? cat) {
    if (cat == null) return;
    // Nur Navi-Profil. Overlay und Dauer folgen nicht still dem Rad.
    _profile = discoverNavProfile(routingProfileForBike(cat));
  }

  void _applyExploreOverlayLayers() {
    _bikeOverlayExtra
      ..clear()
      ..addAll(
        DiscoverExploreChromeLogic.overlayClassesForLayers(
          trailsOn: _showTrailsLayer,
          waysOn: _showBikeWaysLayer,
        ),
      );
    _bikeOverlayOn = _showTrailsLayer || _showBikeWaysLayer;
    _showTrailNetwork = _bikeOverlayOn;
  }

  bool _liveNetworkFallback({double? lng, double? lat, double? zoom}) {
    final cam = _map?.cameraPosition;
    return liveNetworkFallbackAt(
      lng: lng ?? cam?.target.longitude ?? _mapCenter.lng,
      lat: lat ?? cam?.target.latitude ?? _mapCenter.lat,
      zoom: zoom ?? cam?.zoom ?? (_hasRealOrigin ? _mapZoom : 12),
    );
  }

  Future<void> _refreshExploreOverlay() async {
    _applyExploreOverlayLayers();
    final c = _map;
    if (c != null && _bikeOverlayAttached) {
      await _syncBikeOverlayVisibility();
    }
    unawaited(_refreshSGradeLive());
  }

  void _prefetchBikeOverlay() {
    final c = _mapCenter;
    unawaited(
      prefetchBikeOverlay(
        lng: c.lng,
        lat: c.lat,
        zoom: _hasRealOrigin ? _mapZoom : 12,
      ),
    );
  }

  Future<void> _applyHillshadeNow() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    await setHillshadeVisible(c, _showHillshade);
  }

  /// Basemap → overlay → puck → draw, never in parallel.
  /// Concurrent GeoJSON `addSource`/`setGeoJsonSource` SIGSEGVs MapLibre
  /// on the emulator (null Style::Source, fault 0x8).
  Future<void> _onDiscoverStyleLoaded() async {
    final gen = ++_styleAttachGen;
    _styleAttachBusy = true;
    try {
      if (mounted) {
        setState(() => _styleReady = true);
      } else {
        _styleReady = true;
      }
      // Style reload drops addImage registrations — pins otherwise vanish.
      _pinImagesReady = false;
      _activeCoverageLayerReady = false;
      _suggestedCoverageLayerReady = false;
      _bikeOverlayAttached = false;
      _navPuck.reset();
      _bikeOverlayKey = null;
      unawaited(OfflineBasemap.applyDetectedNetworkMode());
      final map = _map;
      if (map == null) return;
      await fixBasemapWaterLayers(
        map,
        coarseOverview: styleHasCoarseWaterPolygons(_mapStyle),
      );
      if (gen != _styleAttachGen || !mounted || _map != map) return;
      if (styleNeedsGrayStreetBoost(_mapStyle)) {
        await boostBasemapStreetContrast(map);
      } else if (styleSkipsNatureFillBoost(_mapStyle)) {
        await applyOverviewBrowsePaint(map);
      } else {
        await warmBasemapNatureFills(map);
      }
      if (gen != _styleAttachGen || !mounted || _map != map) return;
      if (_showHillshade) {
        await applyHillshade(map);
      }
      if (gen != _styleAttachGen || !mounted || _map != map) return;
      await _ensureBikeOverlay(refreshSGrade: false);
      if (gen != _styleAttachGen || !mounted || _map != map) return;
      await _attachNavPuck();
      if (gen != _styleAttachGen || !mounted || _map != map) return;
      await _drawAll(fromStyle: true);
      if (gen != _styleAttachGen || !mounted) return;
    } finally {
      if (gen == _styleAttachGen) _styleAttachBusy = false;
    }
    if (gen != _styleAttachGen || !mounted) return;
    unawaited(_refreshSGradeLive());
    if (_fitPackAfterStyle) {
      _fitPackAfterStyle = false;
      unawaited(_fitOfflinePackBbox());
    }
    final pin = _hofPinLoopId ?? _selectedTourId;
    final tour = pin == null ? null : _tourById(pin);
    if (tour != null && !_planningAb) {
      unawaited(_focusCameraOnTour(tour));
    }
  }

  Future<void> _ensureBikeOverlay({bool refreshSGrade = true}) async {
    final c = _map;
    if (c == null || !_styleReady) return;
    if (_styleAttachBusy && refreshSGrade) return;
    final cam = c.cameraPosition;
    final lng = cam?.target.longitude ?? _mapCenter.lng;
    final lat = cam?.target.latitude ?? _mapCenter.lat;
    final zoom = cam?.zoom ?? (_hasRealOrigin ? 12.0 : 5.5);
    _applyExploreOverlayLayers();
    final data = await resolveBikeOverlayData(
      lng: lng,
      lat: lat,
      zoom: zoom,
    );
    if (!mounted) return;
    final key = data?.toString();
    final liveNetwork = _liveNetworkFallback(lng: lng, lat: lat, zoom: zoom);
    if (key != null && key == _bikeOverlayKey && _bikeOverlayAttached) {
      await _syncBikeOverlayVisibility();
      if (refreshSGrade) unawaited(_refreshSGradeLive());
      unawaited(raisePendingAbLayer(c));
      return;
    }
    if (_bikeOverlayAttached) {
      await detachBikeOverlayLayers(c);
      _bikeOverlayAttached = false;
    }
    _bikeOverlayKey = key;
    await ensureLiveOsmNetworkSource(c);
    await attachLiveOsmNetworkLayers(c);
    await attachSGradeLiveLayer(c);
    if (data != null && mounted) {
      await attachBikeOverlayLayers(
        c,
        data: data,
        family: _overlayFamily,
        visible: _bikeOverlayOn,
        extraOn: _bikeOverlayExtra,
        sGradeOnly: false,
        liveNetwork: liveNetwork,
      );
    } else if (mounted) {
      await _syncBikeOverlayVisibility();
    }
    if (mounted) setState(() => _bikeOverlayAttached = true);
    unawaited(_syncBikeOverlayVisibility());
    if (refreshSGrade) unawaited(_refreshSGradeLive());
    unawaited(raisePendingAbLayer(c));
  }

  Future<void> _refreshSGradeLive() async {
    final c = _map;
    if (c == null || !_styleReady || _styleAttachBusy) return;
    final gen = ++_sGradeGen;
    if (!shouldFetchSGradeLive(
      overlayOn: _bikeOverlayOn,
      extraOn: _bikeOverlayExtra,
      zoom: _mapZoom,
    )) {
      await setSGradeLiveData(c, sGradeFeatureCollection(const []));
      _sGradeTrails = const [];
      return;
    }
    try {
      final bounds = await c.getVisibleRegion();
      if (gen != _sGradeGen || !mounted) return;
      final box = clampSGradeBbox(
        west: bounds.southwest.longitude,
        south: bounds.southwest.latitude,
        east: bounds.northeast.longitude,
        north: bounds.northeast.latitude,
      );
      final trails = await OsmTrailNetworkClient().fetchSGradeInBbox(
        west: box.west,
        south: box.south,
        east: box.east,
        north: box.north,
      );
      if (gen != _sGradeGen || !mounted) return;
      await setSGradeLiveData(c, sGradeFeatureCollection(trails));
      _sGradeTrails = trails;
    } catch (_) {}
  }

  Future<void> _drawAll({bool fromStyle = false}) async {
    final c = _map;
    if (c == null || !_styleReady) return;
    if (_styleAttachBusy && !fromStyle) return;
    final gen = ++_drawGen;
    // Kurze Pause: mehrere _drawAll in Folge (Katalog + Overlay + Zoom)
    // räumen die Linien nicht mehr nacheinander leer.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted || gen != _drawGen) return;
    try {
      await c.clearLines();
      if (gen != _drawGen) return;
      _planRibbonLines.clear();
      _planGrabGeom.clear();
      _planGrabLines.clear();
      final keepDim = _planDragAlongLabel != null;
      if (!keepDim) _planRibbonDimmed = false;
      var ribbonSlices = <({String kind, List<List<double>> coords})>[];
      if (_heatmapConsent && _showHeatLayer) {
        try {
          final rides =
              await ref.read(rideRepositoryProvider).listRides(limit: 40);
          final zones =
              await ref.read(garageRepositoryProvider).listPrivacyZones();
          final heat = buildHeatmapFromRides(
            consentHeatmap: true,
            rides: [for (final r in rides) (id: r.id, track: r.track)],
            privacyZones: zones,
            includeSeedFallback: false,
          );
          // Best-effort community overlay (k≥5). Contribute max once per session.
          HeatmapResult? community;
          String? communityErr;
          try {
            if (!_heatmapContributed) {
              final metas = await SavedRouteMetaStore.listAll();
              for (final r in rides.take(8)) {
                if (!RouteVisibility.mayContributeRide(
                    r.routeId, metas[r.routeId])) {
                  continue;
                }
                await contributeHeatmapTrack(
                  track: r.track,
                  privacyZones: zones,
                );
              }
              _heatmapContributed = true;
            }
            final o = _origin;
            community = await fetchCommunityHeatmap(
              west: o.lng - 0.45,
              south: o.lat - 0.35,
              east: o.lng + 0.45,
              north: o.lat + 0.35,
            );
          } catch (e) {
            communityErr = _l10n.discoverHeatmapOffline;
          }
          final note = [
            heat.disclaimer,
            if (community != null) community.disclaimer,
            if (communityErr != null) communityErr,
          ].join(' · ');
          if (mounted) {
            setState(() => _heatmapNote = note);
          }
          for (final seg in [
            ...heat.visibleSegments,
            ...?community?.visibleSegments,
          ]) {
            if (gen != _drawGen) return;
            if (seg.coordinatesLngLat.length < 2) continue;
            await c.addLine(
              LineOptions(
                geometry: [
                  for (final p in seg.coordinatesLngLat) LatLng(p[1], p[0]),
                ],
                lineColor: seg.id.startsWith('cell-') ? '#E65100' : '#FF7043',
                lineWidth: 6 + seg.intensity * 8,
                lineOpacity: 0.18 + seg.intensity * 0.25,
              ),
            );
          }
        } catch (_) {
          // Fall through — map still usable without heatmap.
        }
      }
      // Trailnetz zuerst (faint), Auswahl hervorgehoben — Community-Erwartung.
      // Overlay = eine Weg-Identität: Overpass-Mesh nicht doppelt, außer
      // Zoom > 14 (Overlay-Kacheln enden typisch dort) mit benannten Wegen.
      final hideOverpassMesh =
          _bikeOverlayAttached && _mapZoom <= kBikeOverlayVectorMaxZoom;
      if (_showTrailNetwork && !hideOverpassMesh) {
        final trails = _bikeOverlayAttached
            ? _visibleTrailNetwork.where((t) => t.hasOsmName)
            : _visibleTrailNetwork;
        for (final trail in trails.take(60)) {
          if (gen != _drawGen) return;
          final geom = [for (final p in trail.geometry) LatLng(p[1], p[0])];
          final selected = trail.id == _selectedTrailId;
          if (selected) {
            await _addKomootLine(
              c,
              geom,
              active: true,
              casing: true,
              lineColor: trail.lineColor,
              data: {'kind': 'trail', 'id': trail.id},
            );
          } else {
            await c.addLine(
              LineOptions(
                geometry: geom,
                lineColor: trail.lineColor,
                lineWidth: DiscoverMapLineStyle.trailUnselectedWidth,
                lineOpacity: _trailScaleFilter.isNotEmpty ||
                        _formFilter == TourFormKey.downhill
                    ? DiscoverMapLineStyle.trailFilteredOpacity
                    : DiscoverMapLineStyle.trailUnselectedOpacity,
                lineJoin: 'round',
              ),
              {'kind': 'trail', 'id': trail.id},
            );
          }
        }
      }
      // Eigene Strecken (Import/Recorded/Engine) — Accent-Blau, unter Selection.
      if (_showOwnTracks) {
        final own = ref.read(savedRoutesProvider).valueOrNull ??
            const <SavedRouteEntry>[];
        final metas = _savedMeta.isEmpty
            ? await SavedRouteMetaStore.listAll()
            : _savedMeta;
        for (final s in own) {
          if (_shellMode != DiscoverShellMode.mine &&
              !RouteVisibility.visibleInPublicExplore(metas[s.id])) {
            continue;
          }
          if (gen != _drawGen) return;
          final coords = s.coordinates.length >= 2
              ? s.coordinates
              : (s.tour.length >= 2
                  ? s.tour
                  : (s.trail.length >= 2 ? s.trail : const <List<double>>[]));
          if (coords.length < 2) continue;
          if (!isUsableMapTrack(coords)) continue;
          final geom = [for (final p in coords) LatLng(p[1], p[0])];
          final selected = _computed != null &&
              _label == s.name &&
              (_computed!.coordinates.length >= 2);
          await _addKomootLine(
            c,
            geom,
            active: selected,
            casing: true,
            lineColor: selected
                ? DiscoverMapLineStyle.ownTrackSelected
                : DiscoverMapLineStyle.ownTrack,
            data: {'kind': 'own', 'id': s.id, 'source': s.source},
          );
        }
      }
      // Alle sichtbaren Karten-Touren mit brauchbarem Track/Cache zeichnen
      // (Komoot/AllTrails: keine Lineale als „fertige Route“). Cap wie Marker.
      final visible = _filtered.take(DiscoverMapLineStyle.mapTourCap).toList();
      final trackTours = visible.where((t) {
        final cached = _routedLoopCache[t.id];
        if (cached != null &&
            isUsableMapTrack([
              for (final p in cached) [p.lng, p.lat]
            ])) {
          return true;
        }
        return shouldPaintDiscoverRibbon(t.trackLngLat);
      }).toList();
      // Falls Selection außerhalb des Caps liegt (selten), trotzdem zeichnen.
      final selectedTour = _tourById(_selectedTourId);
      if (selectedTour != null &&
          !trackTours.any((t) => t.id == selectedTour.id)) {
        final cached = _routedLoopCache[selectedTour.id];
        final cacheOk = cached != null &&
            isUsableMapTrack([
              for (final p in cached) [p.lng, p.lat]
            ]);
        if (cacheOk || shouldPaintDiscoverRibbon(selectedTour.trackLngLat)) {
          trackTours.insert(0, selectedTour);
        }
      }
      trackTours.sort((a, b) {
        final asel = a.id == _selectedTourId ? 0 : 1;
        final bsel = b.id == _selectedTourId ? 0 : 1;
        if (asel != bsel) return asel.compareTo(bsel);
        return 0;
      });
      final hideTourRibbons = _planningAb;
      if (_showToursLayer && !hideTourRibbons) {
        for (final tour in trackTours) {
          if (gen != _drawGen) return;
          final cached = _routedLoopCache[tour.id];
          final List<LatLng> geom;
          final bool routed;
          if (cached != null && cached.length >= 4) {
            geom = [for (final p in cached) LatLng(p.lat, p.lng)];
            routed = true;
          } else {
            geom = [for (final p in tour.trackLngLat!) LatLng(p[1], p[0])];
            routed = false;
          }
          final isSelected = tour.id == _selectedTourId;
          final sport = TourFilters.sportOf(tour.categories);
          final scale = parseTrailDifficulty(tour.mtbScale);
          await _addKomootLine(
            c,
            geom,
            active: isSelected && routed,
            casing: routed,
            lineColor: DiscoverMapLineStyle.ribbonForTour(
              sport: sport,
              scale: scale,
              selected: isSelected,
              routed: routed,
            ),
            data: {
              'kind': 'tour',
              'id': tour.id,
              'engine': routed ? 'seed-loop-routed' : 'seed-loop',
            },
          );
        }
      }
      // Sichtbare Pins ohne Track → Background-Routing (ehrlicher Loading-Status).
      // Nicht während A–B: Pentagon-Vias landen im Feld und die alte Tour
      // bleibt als „halbe Route“ sichtbar.
      if (!hideTourRibbons) {
        unawaited(_warmVisibleMapTourGeometries(visible));
      }
      if (_approach != null && _approach!.coordinates.length >= 2) {
        await _addKomootLine(
          c,
          _approach!.coordinates.map((p) => LatLng(p.lat, p.lng)).toList(),
          active: false,
          lineColor: DiscoverMapLineStyle.approachCore,
        );
      }
      if (_tourLayer != null &&
          !_hofChoice &&
          !hideTourRibbons &&
          shouldPaintDiscoverRibbon([
            for (final p in _tourLayer!.coordinates) [p.lng, p.lat]
          ])) {
        final approx = (_tourLayer!.engine ?? '').contains('demo');
        if (!approx) {
          await _addKomootLine(
            c,
            _tourLayer!.coordinates.map((p) => LatLng(p.lat, p.lng)).toList(),
            active: false,
            lineColor: '#AB47BC',
          );
        }
      }
      if (_trailOverlay != null &&
          _trailOverlay!.length >= 2 &&
          planPaintsTrailLastMileOverlay(
            hasVias: _vias.isNotEmpty,
            reshaping: _routeLineStale,
          )) {
        await _addKomootLine(
          c,
          _trailOverlay!.map((p) => LatLng(p.lat, p.lng)).toList(),
          active: true,
          lineColor: '#FF6A00',
        );
      }
      final fromHint = _start ?? _userPos;
      if (!keepDim && !_keepPlanSharedDisc) {
        await syncPendingAbOverlay(
          c,
          line: shouldPaintPendingAbHint(
            hasFrom: fromHint != null,
            hasEnd: _end != null,
            hasLiveLine: _hasLivePlanLine,
          )
              ? [
                  LatLng(fromHint!.lat, fromHint.lng),
                  LatLng(_end!.lat, _end!.lng),
                ]
              : null,
        );
      }
      // Compass-/Heading-A→B nicht als mintgrüne Tour-Leine auf Discover.
      // Navigieren darf die geplante Linie zeigen; HUD sowieso.
      // Tour-Preview-Linien bleiben weg, sobald ein Ziel-Pin die Story ist.
      if (_hasLivePlanLine) {
        final eng = _computed!.engine ?? '';
        final approx = eng.contains('demo') ||
            eng.contains('fallback') ||
            eng.contains('approx');
        final computedTrack = joinPlanLineToPins(
          lineLngLat: [
            for (final p in _computed!.coordinates) [p.lng, p.lat]
          ],
          startLat: _start?.lat,
          startLng: _start?.lng,
          endLat: _end?.lat,
          endLng: _end?.lng,
        );
        final line = [
          for (final p in computedTrack) LatLng(p[1], p[0]),
        ];
        if (shouldPaintActiveComputedRibbon(
          trackLngLat: computedTrack,
          isHeadingOrDemoOverlay: CompassHeading.hideComputedRibbonOnDiscover(
            isDemoOrApprox: _isDemoOrAbOverlay(_computed) || approx,
            discoverExplore: _shellMode == DiscoverShellMode.explore,
          ),
          approachPaintedSeparately:
              _approach != null && _approach!.coordinates.length >= 2,
        )) {
          final sel = _tourById(_selectedTourId);
          final activeColor = approx
              ? DiscoverMapLineStyle.selectedApprox
              : (sel != null
                  ? DiscoverMapLineStyle.ribbonForTour(
                      sport: TourFilters.sportOf(sel.categories),
                      scale: parseTrailDifficulty(sel.mtbScale),
                      selected: true,
                      routed: true,
                    )
                  : DiscoverMapLineStyle.selectedRouted);
          final canGrab = planRibbonAllowsGrab(
            editorActive: _planEditorActive,
            hasLiveStreetLine: true,
            approx: approx,
          );
          final canTint = canGrab && !_routeLineStale;
          final packRuns = coverageSplitLineByBbox(
            lineLngLat: computedTrack,
            bbox: _offlinePackBbox,
            routingReady: _offlineRoutingReady,
            ring: _offlinePackRing,
          );
          for (final run in packRuns) {
            final geom = [
              for (final p in run.coords) LatLng(p[1], p[0]),
            ];
            if (geom.length < 2) continue;
            if (run.outside) {
              // Sage, no orange glow / grab — graph cannot reshape this.
              // GeoJSON dash sits on the muted casing (annotation has no dash).
              final ribbon = await _addKomootLine(
                c,
                geom,
                active: false,
                lineColor: DiscoverMapLineStyle.packOutside,
                skipCore: true,
                opacityMul: _routeLineStale ? 0.42 : 0.90,
                grab: false,
                data: {
                  'kind': 'active-outside',
                  'approx': approx,
                  if (_label != null) 'label': _label,
                },
              );
              if (gen != _drawGen) return;
              _planRibbonLines.addAll(ribbon);
              ribbonSlices.add((kind: kPlanPackOutKind, coords: run.coords));
              continue;
            }
            final ribbon = await _addKomootLine(
              c,
              geom,
              active: true,
              lineColor: activeColor,
              opacityMul: _routeLineStale ? 0.48 : 1,
              grab: false,
              data: {
                'kind': 'active',
                'approx': approx,
                if (_label != null) 'label': _label,
              },
            );
            if (gen != _drawGen) return;
            _planRibbonLines.addAll(ribbon);
          }
          if (canTint && _planSurfaceBands.isNotEmpty) {
            for (final s in planSurfaceLineSlices(
              lineLngLat: computedTrack,
              bands: _planSurfaceBands,
            )) {
              for (final coords in coverageLinePartsInside(
                lineLngLat: s.coords,
                bbox: _offlinePackBbox,
                routingReady: _offlineRoutingReady,
                ring: _offlinePackRing,
              )) {
                if (coords.length < 2) continue;
                ribbonSlices.add((kind: s.kind.name, coords: coords));
                _planLegendKinds.add(s.kind.name);
              }
            }
          }
          if (canTint && _planElevSamples.length >= 2) {
            for (final slice in planSteepLineSlices(
              lineLngLat: computedTrack,
              elevM: _planElevSamples,
              distKm: _planElevKm.isEmpty ? null : _planElevKm,
            )) {
              for (final coords in coverageLinePartsInside(
                lineLngLat: slice,
                bbox: _offlinePackBbox,
                routingReady: _offlineRoutingReady,
                ring: _offlinePackRing,
              )) {
                if (coords.length < 2) continue;
                ribbonSlices.add((kind: 'steep', coords: coords));
                _planLegendKinds.add('steep');
              }
            }
          }
          if (gen != _drawGen) return;
          // Nicht während Detail: [_openDetail] hat die Kamera bewusst auf die
          // gerade betrachtete Tour zentriert. Läuft [_drawAll] währenddessen
          // erneut (z. B. weil im Hintergrund ein Trailnetz-/Touren-Fetch
          // fertig wird), würde dieses Bounds-Fit sonst stillschweigend zu
          // einer ANDEREN, evtl. längst veralteten `_computed`-Route springen
          // — dieselbe Klasse Kamera-Bug wie in [_syncOriginDrift], nur über
          // Hintergrund-Refreshes statt GPS-Drift ausgelöst. Die Linie selbst
          // wurde trotzdem gezeichnet (oben), nur die Kamera bleibt stehen;
          // Marker müssen unten in jedem Fall noch aktualisiert werden.
          if (_surface != _Surface.detail && !_skipAutoCameraFit) {
            final swLat =
                line.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
            final swLng =
                line.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
            final neLat =
                line.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
            final neLng =
                line.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);
            if ((neLat - swLat).abs() < 1e-5 && (neLng - swLng).abs() < 1e-5) {
              await c.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(swLat, swLng), 14),
              );
            } else {
              await c.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(swLat, swLng),
                    northeast: LatLng(neLat, neLng),
                  ),
                  left: 40,
                  // Kopfzeile schwebt jetzt über der Karte, das Panel deckt
                  // den unteren Teil ab — sonst läge die Route dahinter.
                  top: 110,
                  right: 40,
                  bottom: _panelInset + 40,
                ),
              );
            }
          }
        }
      }
      if (gen != _drawGen) return;
      _planRibbonSlices = ribbonSlices;
      if (ribbonSlices.isNotEmpty) {
        final next = {
          for (final s in ribbonSlices)
            if (s.kind != kPlanPackOutKind) s.kind,
        };
        if (_planLegendKinds.length != next.length ||
            !_planLegendKinds.containsAll(next)) {
          _planLegendKinds
            ..clear()
            ..addAll(next);
          if (mounted) setState(() {});
        }
      } else if (_surface != _Surface.plan && _planLegendKinds.isNotEmpty) {
        _planLegendKinds.clear();
        if (mounted) setState(() {});
      }
      if (keepDim) {
        _planRibbonDimmed = false;
        await _setPlanRibbonDim(true);
      } else {
        await syncPlanRibbonOverlay(c, slices: ribbonSlices);
      }
      if (gen != _drawGen) return;
      await _syncMarkers(coalesce: true);
      if (gen != _drawGen) return;
      await _syncOfflineCoverageOverlay(force: fromStyle);
      await raisePendingAbLayer(c, force: true);
    } catch (_) {}
  }

  Future<void> _drawRoute(RouteResult result) async {
    setState(() {
      _computed = result;
      _rideBarExpanded = true;
    });
    await _drawAll();
    await _refreshElevation(result);
  }

  Future<void> _ensurePinImages(MapLibreMapController c) async {
    if (_pinImagesReady) return;
    try {
      final green = await buildMapMarkerPng(
        fill: const Color(0xFF2E7D32),
        kind: MapPinKind.drop,
      );
      final orange = await buildMapMarkerPng(
        fill: AppColors.accent,
        kind: MapPinKind.drop,
      );
      final blue = await buildMapMarkerPng(
        fill: const Color(0xFF29B6F6),
        kind: MapPinKind.drop,
      );
      final poi = await loadPoiPinPng(MapPoiKind.place);
      final meet = await buildMapMarkerPng(
        fill: AppColors.accent,
        kind: MapPinKind.meet,
      );
      final stimme = await buildMapMarkerPng(
        fill: const Color(0xFF6D4C41),
        kind: MapPinKind.stimme,
      );
      final riderLive = await buildRiderMapPng(live: true);
      final riderStale = await buildRiderMapPng(live: false);
      await c.addImage('aether-pin', green);
      await c.addImage('aether-pin-b', orange);
      await c.addImage('aether-pin-idea', blue);
      await c.addImage('aether-poi', poi);
      for (final kind in MapPoiKind.values) {
        if (kind == MapPoiKind.place) continue;
        await c.addImage(poiPinImageId(kind), await loadPoiPinPng(kind));
      }
      await c.addImage(kRiderNavImageId, riderLive);
      await c.addImage(kRiderTourLiveImageId, riderLive);
      await c.addImage(kRiderTourStaleImageId, riderStale);
      await c.addImage(kRiderFlowImageId, riderLive);
      await c.addImage('aether-pin-meet', meet);
      await c.addImage('aether-pin-stimme', stimme);
      await c.addImage('aether-pin-flow', riderLive);
      const tourIdleFill = Color(0xFF2A2E32);
      await c.addImage(
        'aether-pin-tour',
        await buildMapMarkerPng(fill: tourIdleFill, kind: MapPinKind.tour),
      );
      await c.addImage(
        'aether-pin-tour-on',
        await buildMapMarkerPng(fill: AppColors.accent, kind: MapPinKind.tour),
      );
      for (final g in MapPinGlyph.values) {
        if (g == MapPinGlyph.mark) continue;
        await c.addImage(
          'aether-pin-tour-${g.name}',
          await buildMapMarkerPng(
            fill: tourIdleFill,
            kind: MapPinKind.tour,
            glyph: g,
          ),
        );
        await c.addImage(
          'aether-pin-tour-on-${g.name}',
          await buildMapMarkerPng(
            fill: AppColors.accent,
            kind: MapPinKind.tour,
            glyph: g,
          ),
        );
      }
      final chevron = await buildRouteChevronPng();
      await c.addImage('aether-chevron', chevron);
      final startPin = await buildMapMarkerPng(
        fill: const Color(0xFF2E7D32),
        kind: MapPinKind.start,
      );
      final startOutPin = await buildMapMarkerPng(
        fill: AppColors.sage,
        kind: MapPinKind.start,
      );
      final finishPin = await buildMapMarkerPng(
        fill: AppColors.accent,
        kind: MapPinKind.finish,
      );
      final finishOutPin = await buildMapMarkerPng(
        fill: AppColors.sage,
        kind: MapPinKind.finish,
      );
      final viaPin = await loadRoutePinPng(MapPinKind.via);
      final viaOutPin = await loadRoutePinPng(MapPinKind.via, outside: true);
      final glow = await buildHaloRingPng(const Color(0xFFFF8A3D));
      final glowOut = await buildHaloRingPng(AppColors.sage);
      await c.addImage('aether-pin-start', startPin);
      await c.addImage('aether-pin-start-out', startOutPin);
      await c.addImage('aether-pin-finish', finishPin);
      await c.addImage('aether-pin-finish-out', finishOutPin);
      await c.addImage('aether-pin-via', viaPin);
      await c.addImage('aether-pin-via-out', viaOutPin);
      await c.addImage('aether-pin-halo', glow);
      await c.addImage('aether-pin-halo-out', glowOut);
      _pinImagesReady = true;
    } catch (_) {
      // Style without custom images — text-only symbols still work.
    }
  }

  String? _tourPinOf(_RouteSuggestion tour, {required bool selected}) {
    if (!_pinImagesReady) return null;
    return tourPinImageId(
      TourFilters.sportOf(tour.categories),
      selected: selected,
    );
  }

  Future<void> _addTourBrowsePin(
    MapLibreMapController c, {
    required _RouteSuggestion tour,
    required LatLng at,
    required bool selected,
    required double iconSize,
  }) async {
    final text = TourFilters.browseTourPinText(
      durationMin: tour.durationMin,
      selected: selected,
      zoom: _mapZoom,
      name: tour.name,
    );
    final sym = await c.addSymbol(
      SymbolOptions(
        fontNames: _symbolFonts,
        geometry: at,
        iconImage: _tourPinOf(tour, selected: selected),
        iconSize: iconSize,
        iconAnchor: 'bottom',
        textField: text,
        textSize: selected ? 12 : 10,
        textColor: '#FFFFFF',
        textHaloColor: selected ? '#BF360C' : '#1A120C',
        textHaloWidth: selected ? 1.4 : 1.1,
        textOffset: Offset(0, selected ? 1.52 : 1.42),
        textMaxWidth: selected ? 10 : 6,
      ),
    );
    _tourBySymbolId[sym.id] = tour;
    _tourSymbols.add(sym);
  }

  String _coveragePlaceLabel(MapPlace place) {
    final named = place.source == MapPlaceSource.stimme ||
        place.source == MapPlaceSource.meet;
    final plateKind = coverageMapPoiKind(place);
    var label = named
        ? (place.name.length > 14
            ? '${place.name.substring(0, 13)}…'
            : place.name)
        : '';
    if (plateKind != null && _mapZoom >= 12 && place.name.isNotEmpty) {
      label = place.name.length > 14
          ? '${place.name.substring(0, 13)}…'
          : place.name;
    }
    return label;
  }

  Future<void> _relabelBrowsePins() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    for (final e in _poiBySymbolId.entries) {
      final poi = e.value;
      final index = _poiDrawIndexById[poi.id];
      final sym = _poiSymbolByPoiId[poi.id];
      if (index == null || sym == null) continue;
      try {
        await c.updateSymbol(
          sym,
          SymbolOptions(
            textField: poiPinLabel(
              index: index,
              title: poi.title,
              zoom: _mapZoom,
            ),
          ),
        );
      } catch (_) {}
    }
    for (final sym in _tourSymbols) {
      final tour = _tourBySymbolId[sym.id];
      if (tour == null) continue;
      final selected = tour.id == _selectedTourId;
      try {
        await c.updateSymbol(
          sym,
          SymbolOptions(
            textField: TourFilters.browseTourPinText(
              durationMin: tour.durationMin,
              selected: selected,
              zoom: _mapZoom,
              name: tour.name,
            ),
            textSize: selected ? 12 : 10,
          ),
        );
      } catch (_) {}
    }
    for (final sym in _placeSymbols) {
      final place = _placeBySymbolId[sym.id];
      if (place == null) continue;
      try {
        await c.updateSymbol(
          sym,
          SymbolOptions(textField: _coveragePlaceLabel(place)),
        );
      } catch (_) {}
    }
  }

  /// Punkt bei Anteil [frac] (0..1) entlang einer [lng,lat]-Polyline.
  LatLng _pointAlongTrack(List<List<double>> track, double frac) {
    if (track.isEmpty) return const LatLng(0, 0);
    if (track.length == 1 || frac <= 0) return LatLng(track[0][1], track[0][0]);
    final segLens = <double>[];
    var total = 0.0;
    for (var i = 1; i < track.length; i++) {
      final d = _distKm(
        track[i - 1][1],
        track[i - 1][0],
        track[i][1],
        track[i][0],
      );
      segLens.add(d);
      total += d;
    }
    if (total <= 0) return LatLng(track[0][1], track[0][0]);
    var target = total * frac.clamp(0.0, 1.0);
    for (var i = 0; i < segLens.length; i++) {
      if (target <= segLens[i]) {
        final t = segLens[i] > 0 ? target / segLens[i] : 0.0;
        final a = track[i];
        final b = track[i + 1];
        return LatLng(
          a[1] + (b[1] - a[1]) * t,
          a[0] + (b[0] - a[0]) * t,
        );
      }
      target -= segLens[i];
    }
    return LatLng(track.last[1], track.last[0]);
  }

  void _onPlanElevScrub(double t) {
    setState(() => _planElevScrubT = t);
    _movePlanElevCursor(t);
  }

  void _movePlanElevCursor(double t) {
    unawaited(_syncPlanSharedDisc(scrubT: t));
  }

  Future<void> _syncPlanSharedDisc({double? scrubT}) async {
    final map = _map;
    if (map == null) return;
    if (_planDragAlongLabel != null) return;
    if (_planFingerAdaptingHint && _planShapeHintAt != null) {
      await syncPendingAbOverlay(
        map,
        line: null,
        kind: PendingAbKind.rubber,
        labelAt: _planShapeHintAt,
        raise: false,
      );
      return;
    }
    final t = scrubT ?? _planElevScrubT;
    if (t != null && _computed != null && _computed!.coordinates.length >= 2) {
      final line = [
        for (final p in _computed!.coordinates) [p.lng, p.lat]
      ];
      final ll = _pointAlongTrack(line, t);
      final alongM = routeLengthM(line) * t;
      final km = planDragAlongLabelKm(alongM);
      await syncPendingAbOverlay(
        map,
        line: null,
        kind: PendingAbKind.rubber,
        alongLabel: _l10n.planTickKm(km),
        labelAt: ll,
        raise: false,
      );
    }
  }

  void _onPlanElevTap(double t) {
    if (t <= 0.02 || t >= 0.98) return;
    final line = _planComputedLineLngLat();
    if (line == null || line.length < 2) return;
    final ll = _pointAlongTrack(line, t);
    _insertPlanViaAlong(GeoPoint(ll.latitude, ll.longitude));
  }

  double _bearingDeg(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// OpenFreeMap/Liberty-Fontstack: Die Mapbox-Default-Fonts („Open Sans
  /// Semibold") existieren dort nicht — ein fehlender Fontstack lässt
  /// MapLibre das GANZE Symbol (inkl. Icon) verwerfen. Deshalb waren
  /// A/B/T/POI-Pins auf S25 nie sichtbar.
  static const _symbolFonts = ['Noto Sans Regular'];

  /// maplibre_gl setzt `text-font` data-driven via `["get","fontNames"]`.
  /// MapLibre erlaubt das nicht (nur Literale) → „invalid value for text-font“.
  /// Layer-Default als `["literal", ["Noto Sans Regular"]]` setzen.
  Future<void> _ensureSymbolTextFont(MapLibreMapController c) async {
    final sm = c.symbolManager;
    if (sm == null) {
      debugPrint('symbol text-font: no symbolManager');
      return;
    }
    for (final layerId in sm.layerIds) {
      try {
        await c.setLayerProperties(
          layerId,
          SymbolLayerProperties(
            textFont: [Expressions.literal, _symbolFonts],
          ),
        );
        debugPrint('symbol text-font ok layer=$layerId');
      } catch (e) {
        debugPrint('symbol text-font: $e');
      }
    }
  }

  Future<void> _syncMarkers({bool coalesce = false}) async {
    final c = _map;
    if (c == null || !_styleReady) return;
    final gen = ++_syncMarkersGen;
    if (coalesce) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted || gen != _syncMarkersGen) return;
    }
    try {
      await _ensureSymbolTextFont(c);
      await _ensurePinImages(c);
      try {
        await c.setSymbolIconAllowOverlap(true);
        await c.setSymbolTextAllowOverlap(true);
        await c.setSymbolIconIgnorePlacement(true);
        await c.setSymbolTextIgnorePlacement(true);
      } catch (_) {}
      // Overlap-Setter baut Symbol-Layer neu → Font erneut setzen.
      await _ensureSymbolTextFont(c);
      // Atomar: alle Annotation-Symbole weg und neu. Einzelne removeSymbol-
      // Aufrufe werfen nach Style-Reload (stale Handles) — die Exception
      // brach dann still die GANZE Marker-Synchronisation ab (keine A/B-,
      // Tour- oder POI-Pins mehr auf S25).
      try {
        await c.clearSymbols();
      } catch (_) {}
      if (gen != _syncMarkersGen) return;
      _routeFlowSymbol = null;
      _meetPulseSymbols.clear();
      _meetHaloSymbols.clear();
      _navPuck.forgetSymbol();
      _tfSymbols = [];
      _tfBySymbolId.clear();
      _placeBySymbolId.clear();
      _tourBySymbolId.clear();
      _poiBySymbolId.clear();
      _poiSymbolByPoiId.clear();
      _poiDrawIndexById.clear();
      _placeSymbols.clear();
      _tourSymbols.clear();
      _planStartSymbol = null;
      _planEndSymbol = null;
      _planEndGlowSymbol = null;
      _planViaSymbols.clear();
      _planBendSymbols.clear();
      _planBendDiscSymbols.clear();
      _planChevronSymbols.clear();
      _planTickSymbols.clear();
      _planElevSymbol = null;
      const pin = 'aether-pin';
      final planDrag =
          _shellMode == DiscoverShellMode.navigate || _surface == _Surface.plan;
      if (_ideaPin != null && !_planningAb) {
        await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: _ideaPin!,
            iconImage: _pinImagesReady ? 'aether-pin-idea' : null,
            iconSize: 0.88,
            iconAnchor: 'bottom',
            textField: 'Idee',
            textSize: 12,
            textOffset: const Offset(0, 1.3),
          ),
        );
      }
      if (_start != null && !_startOverlapsUser()) {
        final startOut = coverageRiderOutside(
          lng: _start!.lng,
          lat: _start!.lat,
          bbox: _offlinePackBbox,
          routingReady: _offlineRoutingReady,
          ring: _offlinePackRing,
        );
        _planStartSymbol = await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: LatLng(_start!.lat, _start!.lng),
            iconImage: _pinImagesReady
                ? (startOut ? 'aether-pin-start-out' : 'aether-pin-start')
                : null,
            iconSize: routeSpriteIconSize(selected: false),
            iconAnchor: 'bottom',
            textField: '',
            textSize: 12,
            draggable: planDrag,
          ),
        );
      }
      if (_end != null) {
        final destBusy = _planningAb || _loading || _destShouldPulse;
        final endOut = coverageRiderOutside(
          lng: _end!.lng,
          lat: _end!.lat,
          bbox: _offlinePackBbox,
          routingReady: _offlineRoutingReady,
          ring: _offlinePackRing,
        );
        if (destBusy && _pinImagesReady) {
          _planEndGlowSymbol = await c.addSymbol(
            SymbolOptions(
              geometry: LatLng(_end!.lat, _end!.lng),
              iconImage: endOut ? 'aether-pin-halo-out' : 'aether-pin-halo',
              iconSize: mapPinSdfIconSize(0.88),
              iconOpacity: 0.5,
              iconAnchor: 'center',
            ),
          );
        }
        _planEndSymbol = await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: LatLng(_end!.lat, _end!.lng),
            iconImage: _pinImagesReady
                ? (endOut ? 'aether-pin-finish-out' : 'aether-pin-finish')
                : null,
            iconSize: destBusy
                ? routeSpriteIconSize(selected: true)
                : routeSpriteIconSize(selected: false),
            iconAnchor: 'bottom',
            textField:
                (_planEditorActive || destBusy) ? _l10n.navigateEndLabel : '',
            textSize: 11,
            textColor: endOut ? '#5E6F58' : '#E65100',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 1.2,
            textOffset: const Offset(0, 1.85),
            draggable: planDrag,
          ),
        );
      }
      for (var i = 0; i < _vias.length; i++) {
        final v = _vias[i];
        final pulse = _planPulseViaIndex == i;
        final outsidePack = coverageRiderOutside(
          lng: v.lng,
          lat: v.lat,
          bbox: _offlinePackBbox,
          routingReady: _offlineRoutingReady,
          ring: _offlinePackRing,
        );
        final caption = planViaMapCaption(
          v.trimmedLabel,
          placeholders: [
            _l10n.discoverOnMapPlace,
            _l10n.discoverViaN(i + 1),
          ],
        );
        _planViaSymbols.add(
          await c.addSymbol(
            SymbolOptions(
              fontNames: _symbolFonts,
              geometry: LatLng(v.lat, v.lng),
              iconImage: _pinImagesReady
                  ? (outsidePack ? 'aether-pin-via-out' : 'aether-pin-via')
                  : null,
              iconSize: viaDiscIconSize(pulse: pulse),
              iconAnchor: 'center',
              textField: '${i + 1}',
              textSize: 12,
              textColor: '#1F1F1F',
              textHaloColor: '#FFFFFF',
              textHaloWidth: 1.1,
              textOffset: const Offset(0, 0),
              draggable: planDrag,
            ),
          ),
        );
        if (caption != null) {
          await c.addSymbol(
            SymbolOptions(
              fontNames: _symbolFonts,
              geometry: LatLng(v.lat, v.lng),
              textField: caption,
              textSize: 10,
              textColor: '#1A120C',
              textHaloColor: '#F4F1EC',
              textHaloWidth: 1.6,
              textOffset: const Offset(0, 1.45),
            ),
          );
        }
      }
      if (planDrag && _hasLivePlanLine) {
        final liveLine = [
          for (final p in _computed!.coordinates) [p.lng, p.lat],
        ];
        final showHandles = planReshapeHandlesReady(
          hasVia: _vias.isNotEmpty || _planLineTouched,
          coachVisible: _planLineCoach,
        );
        final handles = showHandles
            ? planReshapeHandles(
                lineLngLat: liveLine,
                vias: [
                  for (final v in _vias) (lat: v.lat, lng: v.lng),
                ],
                zoom: _mapZoom,
                avoidAlongM: [
                  if (_planElevScrubT != null)
                    routeLengthM(liveLine) * _planElevScrubT!,
                ],
              )
            : const <({double lat, double lng, double alongM})>[];
        final highlightBend = _planBendHighlightUntil != null &&
            DateTime.now().isBefore(_planBendHighlightUntil!);
        for (final h in handles) {
          final handleOut = coverageRiderOutside(
            lng: h.lng,
            lat: h.lat,
            bbox: _offlinePackBbox,
            routingReady: _offlineRoutingReady,
            ring: _offlinePackRing,
          );
          if (_pinImagesReady) {
            _planBendDiscSymbols.add(
              await c.addSymbol(
                SymbolOptions(
                  geometry: LatLng(h.lat, h.lng),
                  iconImage:
                      handleOut ? 'aether-pin-via-out' : 'aether-pin-via',
                  iconSize: viaHandleIconSize(),
                  iconOpacity: planGrabHandleOpacity(
                    handleOut ? 0.72 : 0.95,
                    dimmed: _planRibbonDimmed,
                  ),
                  iconAnchor: 'center',
                ),
              ),
            );
          }
          _planBendSymbols.add(
            await c.addSymbol(
              SymbolOptions(
                geometry: LatLng(h.lat, h.lng),
                iconImage: _pinImagesReady
                    ? (handleOut ? 'aether-pin-halo-out' : 'aether-pin-halo')
                    : null,
                iconSize: mapPinSdfIconSize(highlightBend ? 1.12 : 1.02),
                iconOpacity: planGrabHandleOpacity(
                  highlightBend ? 0.78 : 0.58,
                  dimmed: _planRibbonDimmed,
                ),
                iconAnchor: 'center',
                iconHaloColor: '#FFFFFF',
                iconHaloWidth: highlightBend ? 1.8 : 1.2,
                draggable: true,
              ),
            ),
          );
        }
        final hideOrnament = _planRibbonDimmed || _planDragAlongLabel != null;
        final viaAlong = planPinAlongMeters(
          lineLngLat: liveLine,
          pins: [
            for (final v in _vias) (lat: v.lat, lng: v.lng),
          ],
        );
        final tickAvoid = <double>[
          ...viaAlong,
          for (final h in handles) h.alongM,
          if (_planElevScrubT != null)
            routeLengthM(liveLine) * _planElevScrubT!,
        ];
        final ticks = hideOrnament
            ? const <({double lat, double lng, String km, double alongM})>[]
            : planDistanceTicks(
                lineLngLat: liveLine,
                zoom: _mapZoom,
                minZoom: planDistanceTicksMinZoom(routeLengthM(liveLine)),
                avoidAlongM: tickAvoid,
              );
        if (!hideOrnament) {
          for (final t in ticks) {
            _planTickSymbols.add(
              await c.addSymbol(
                SymbolOptions(
                  fontNames: _symbolFonts,
                  geometry: LatLng(t.lat, t.lng),
                  textField: _l10n.planTickKm(t.km),
                  textSize: 11,
                  textColor: '#E65100',
                  textHaloColor: '#FFFFFF',
                  textHaloWidth: 1.5,
                  textOffset: const Offset(0, 0.95),
                ),
              ),
            );
          }
          final chevrons = planDirectionChevrons(
            lineLngLat: liveLine,
            zoom: _mapZoom,
            minZoom: planDistanceTicksMinZoom(routeLengthM(liveLine)),
            avoidAlongM: [
              ...tickAvoid,
              for (final t in ticks) t.alongM,
            ],
          );
          if (_pinImagesReady) {
            for (final ch in chevrons) {
              _planChevronSymbols.add(
                await c.addSymbol(
                  SymbolOptions(
                    geometry: LatLng(ch.lat, ch.lng),
                    iconImage: 'aether-chevron',
                    iconSize: mapChevronIconSize(_mapZoom >= 15 ? 0.42 : 0.32),
                    iconOpacity: planChevronIconOpacity(
                      dimmed: _planRibbonDimmed,
                      fresh: _planChevronFresh,
                    ),
                    iconRotate: ch.bearingDeg,
                    iconAnchor: 'center',
                  ),
                ),
              );
            }
          }
        }
      }
      if (!_planRibbonDimmed &&
          _planDragAlongLabel == null &&
          !_planWaitHintOnMap &&
          _planPulseChevronsOnDraw) {
        _planPulseChevronsOnDraw = false;
        if (_planChevronSymbols.isNotEmpty) _markPlanChevronsFresh();
      }
      if (_aroundYouApplied &&
          _computed != null &&
          _computed!.coordinates.length >= 4) {
        final mid =
            _computed!.coordinates[_computed!.coordinates.length ~/ 2];
        await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: LatLng(mid.lat, mid.lng),
            iconImage: _pinImagesReady ? 'aether-pin-halo' : null,
            iconSize: mapPinSdfIconSize(0.72),
            iconOpacity: 0.55,
            iconAnchor: 'center',
            textField: _l10n.discoverAroundYouUncertainShort,
            textSize: 11,
            textColor: '#E65100',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 1.4,
            textOffset: const Offset(0, 1.1),
          ),
        );
      }
      unawaited(_syncPlanGrabScreen());
      if (_planElevScrubT != null &&
          _computed != null &&
          _computed!.coordinates.length >= 2 &&
          _planDragAlongLabel == null) {
        unawaited(_syncPlanSharedDisc());
      }
      if (_showToursLayer && !_planningAb) {
        for (final pinTf in _tfPins.take(12)) {
          if (!shouldDrawTrailforksMapPin()) continue;
          final sym = await c.addSymbol(
            SymbolOptions(
              fontNames: _symbolFonts,
              geometry: pinTf.center,
              iconImage: _pinImagesReady ? pin : null,
              iconSize: 1.0,
              textField: '',
              textSize: 11,
              textOffset: const Offset(0, 1.2),
            ),
          );
          _tfSymbols.add(sym);
          _tfBySymbolId[sym.id] = pinTf;
        }
      }
      final visible = _visibleMapPlaces;
      final meetDraw = [
        for (final p in visible)
          if (p.source == MapPlaceSource.meet) p,
      ];
      final otherDraw = [
        for (final p in visible)
          if (p.source != MapPlaceSource.meet) p,
      ];
      final drawPlaces = [
        ...meetDraw,
        ...otherDraw.take((24 - meetDraw.length).clamp(0, 24)),
      ];
      for (final place in drawPlaces) {
        final plateKind = coverageMapPoiKind(place);
        final label = _coveragePlaceLabel(place);
        final at = LatLng(place.lat, place.lng);
        if (place.source == MapPlaceSource.meet && _pinImagesReady) {
          final halo = await c.addSymbol(
            SymbolOptions(
              fontNames: _symbolFonts,
              geometry: at,
              iconImage: 'aether-pin-halo',
              iconSize: mapPinSdfIconSize(0.78),
              iconOpacity: 0.55,
            ),
          );
          _meetHaloSymbols.add(halo);
        }
        final icon = place.source == MapPlaceSource.meet
            ? 'aether-pin-meet'
            : place.source == MapPlaceSource.stimme
                ? 'aether-pin-stimme'
                : plateKind != null
                    ? poiPinImageId(plateKind)
                    : 'aether-pin-idea';
        final isPlate = plateKind != null;
        final isDrop = !isPlate &&
            place.source != MapPlaceSource.meet &&
            place.source != MapPlaceSource.stimme;
        final sym = await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: at,
            iconImage: _pinImagesReady ? icon : null,
            iconSize: isPlate
                ? poiStopIconSize(
                    selected: _highlightPlaceId == place.id,
                  )
                : place.source == MapPlaceSource.meet ||
                        place.source == MapPlaceSource.stimme
                    ? routeSpriteIconSize(
                        selected: _highlightPlaceId == place.id,
                      )
                    : 0.7,
            iconAnchor: isDrop ||
                    isPlate ||
                    place.source == MapPlaceSource.meet ||
                    place.source == MapPlaceSource.stimme
                ? 'bottom'
                : 'center',
            textField: label,
            textSize: 11,
            textColor: isPlate ? '#1A120C' : '#FFFFFF',
            textHaloColor: isPlate ? '#F4F1EC' : '#121215',
            textHaloWidth: isPlate ? 1.6 : 1.2,
            textOffset: Offset(
              0,
              isPlate ||
                      place.source == MapPlaceSource.meet ||
                      place.source == MapPlaceSource.stimme
                  ? 1.85
                  : 1.25,
            ),
          ),
        );
        if (place.source == MapPlaceSource.meet) {
          _meetPulseSymbols.add(sym);
        }
        _placeBySymbolId[sym.id] = place;
        _placeSymbols.add(sym);
      }
      // Nur Touren OHNE zeichbare Polyline als Pin — und nur kurz, während
      // Background-Routing läuft. Fertige Tracks haben bereits eine Line in
      // [_drawAll] (keine blinden T-Pins à la leere Ideen-Punkte).
      if (_showToursLayer && !_planningAb) {
        for (final tour in _filtered.take(DiscoverMapLineStyle.mapTourCap)) {
          final cached = _routedLoopCache[tour.id];
          final hasLine =
              tour.hasTrack || (cached != null && cached.length >= 4);
          final selected = tour.id == _selectedTourId;
          if (hasLine) {
            if (selected || _mapZoom < 10) continue;
            final start = cached != null && cached.isNotEmpty
                ? LatLng(cached.first.lat, cached.first.lng)
                : (tour.trackLngLat != null && tour.trackLngLat!.isNotEmpty
                    ? LatLng(
                        tour.trackLngLat!.first[1],
                        tour.trackLngLat!.first[0],
                      )
                    : tour.center);
            await _addTourBrowsePin(
              c,
              tour: tour,
              at: start,
              selected: false,
              iconSize: tourPinIconSize(selected: false),
            );
            continue;
          }
          if (_isPinOnlyIdea(tour) && !_isLoop(tour)) {
            await _addTourBrowsePin(
              c,
              tour: tour,
              at: tour.center,
              selected: false,
              iconSize: tourPinIconSize(selected: false),
            );
            continue;
          }
          await _addTourBrowsePin(
            c,
            tour: tour,
            at: tour.center,
            selected: selected,
            iconSize: tourPinIconSize(selected: selected),
          );
        }
      }
      if (_showToursLayer &&
          shouldShowDiscoverTourPois(
            hideRibbons: _planningAb,
            hasSelectedTour: _selectedTourId != null,
            computedEngine: _computed?.engine,
          )) {
        await _syncPoiStopMarkers(c);
      }
      await _ensureRouteFlow(c);
      if (_meetPulseSymbols.isNotEmpty) _ensurePinAnim();
      await _ensureSymbolTextFont(c);
    } catch (e) {
      debugPrint('syncMarkers: $e');
    } finally {
      await _syncNavPuck();
      if (_destShouldPulse) unawaited(_applyDestPulseSize());
    }
  }

  /// POI-Stops des ausgewählten Rundkurses als nummerierte Punkte entlang
  /// der Route (Komoot-Highlights) + Start-Fahne am Loop-Anfang.
  /// Symbole wurden vorab via [MapLibreMapController.clearSymbols] entfernt.
  Future<void> _syncPoiStopMarkers(MapLibreMapController c) async {
    final sel = _tourById(_selectedTourId);
    if (sel == null) {
      _poiFracsOnMap = const [];
      return;
    }
    final track = _routedLoopCache[sel.id] != null
        ? [
            for (final p in _routedLoopCache[sel.id]!) [p.lng, p.lat]
          ]
        : sel.trackLngLat;
    if (track == null || track.length < 4) {
      _poiFracsOnMap = const [];
      return;
    }
    final startLl = LatLng(track.first[1], track.first[0]);
    debugPrint(
      'PoiMarkers start=$startLl pinsReady=$_pinImagesReady stops=${sel.poiStops.length}',
    );
    // POIs first so start/finish symbols stack above (global overlap is on).
    final placed = <double>[];
    var i = 0;
    if (sel.poiStops.isNotEmpty && sel.durationMin > 0) {
      for (final poi in sel.poiStops) {
        if (placed.length >= 8) break;
        i++;
        if (poi.atMin <= 0) continue; // Trailhead == Start-Fahne
        final frac = poi.atMin / sel.durationMin;
        if (!poiFracFitsAlong(frac, placed)) continue;
        placed.add(frac);
        final pos = _pointAlongTrack(track, frac);
        final highlighted = _highlightPoiId == poi.id;
        _poiDrawIndexById[poi.id] = i;
        final sym = await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: pos,
            iconImage: _pinImagesReady
                ? poiPinImageId(mapPoiKindFromRaw(poi.kind))
                : null,
            iconSize: poiStopIconSize(selected: highlighted),
            iconAnchor: 'bottom',
            textField: poiPinLabel(
              index: i,
              title: poi.title,
              zoom: _mapZoom,
            ),
            textSize: 11,
            textColor: '#1A120C',
            textHaloColor: '#F4F1EC',
            textHaloWidth: 1.6,
            textOffset: const Offset(0, 1.85),
            textMaxWidth: 12,
          ),
        );
        _poiBySymbolId[sym.id] = poi;
        _poiSymbolByPoiId[poi.id] = sym;
      }
    }
    _poiFracsOnMap = placed;
    await _addTourBrowsePin(
      c,
      tour: sel,
      at: startLl,
      selected: true,
      iconSize: tourPinIconSize(selected: true, atStart: true),
    );
    debugPrint('PoiMarkers drawn=$i tour=${sel.id}');
  }

  void _stopRouteFlow() {
    _routeFlowTimer?.cancel();
    _routeFlowTimer = null;
    _routeFlowSymbol = null;
    _routeFlowGeom = const [];
  }

  void _ensurePinAnim() {
    _routeFlowTimer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      unawaited(_tickPinAnim());
    });
  }

  Future<void> _ensureRouteFlow(MapLibreMapController c) async {
    final sel = _tourById(_selectedTourId);
    List<LatLng> geom = const [];
    if (sel != null) {
      final cached = _routedLoopCache[sel.id];
      if (cached != null && cached.length >= 4) {
        geom = [for (final p in cached) LatLng(p.lat, p.lng)];
      } else if (sel.trackLngLat != null && sel.trackLngLat!.length >= 4) {
        geom = [
          for (final p in sel.trackLngLat!) LatLng(p[1], p[0]),
        ];
      }
    }
    if (geom.length < 4) {
      _stopRouteFlow();
      return;
    }
    _routeFlowGeom = geom;
    try {
      _routeFlowSymbol = await c.addSymbol(
        SymbolOptions(
          fontNames: _symbolFonts,
          geometry: geom.first,
          iconImage: _pinImagesReady ? kRiderFlowImageId : null,
          iconSize: RiderMapIconSize.flow,
        ),
      );
    } catch (_) {
      _routeFlowSymbol = null;
      return;
    }
    if (_pinImagesReady && _mapZoom >= 11) {
      final track = [
        for (final p in geom) [p.longitude, p.latitude],
      ];
      const count = 7;
      for (var i = 1; i <= count; i++) {
        final frac = i / (count + 1);
        if (_poiFracsOnMap.any((p) => (p - frac).abs() < kPoiFracGap)) {
          continue;
        }
        final at = _pointAlongTrack(track, frac);
        final ahead = _pointAlongTrack(track, (frac + 0.012).clamp(0.0, 1.0));
        try {
          await c.addSymbol(
            SymbolOptions(
              fontNames: _symbolFonts,
              geometry: at,
              iconImage: kRiderFlowImageId,
              iconSize: RiderMapIconSize.flowBead,
              iconAnchor: 'center',
              iconRotate: _bearingDeg(at, ahead),
              textField: '',
              textSize: 10,
            ),
          );
        } catch (_) {}
      }
    }
    _ensurePinAnim();
  }

  Future<void> _tickPinAnim() async {
    final c = _map;
    if (c == null) return;
    _pinPulse += 0.11;
    final wave = (math.sin(_pinPulse) + 1) / 2;
    final flow = _routeFlowSymbol;
    if (flow != null && _routeFlowGeom.length >= 4) {
      _routeFlowT = (_routeFlowT + 0.0055) % 1.0;
      final track = [
        for (final p in _routeFlowGeom) [p.longitude, p.latitude],
      ];
      final at = _pointAlongTrack(track, _routeFlowT);
      try {
        await c.updateSymbol(
          flow,
          SymbolOptions(
            geometry: at,
            iconSize: RiderMapIconSize.flow + 0.08 * wave,
          ),
        );
      } catch (_) {
        _routeFlowSymbol = null;
      }
    }
    for (var i = 0; i < _meetHaloSymbols.length; i++) {
      try {
        await c.updateSymbol(
          _meetHaloSymbols[i],
          SymbolOptions(
            iconSize: 0.68 + 0.22 * wave,
            iconOpacity: 0.22 + 0.38 * (1 - wave),
          ),
        );
      } catch (_) {}
    }
    for (final s in _meetPulseSymbols) {
      try {
        await c.updateSymbol(
          s,
          SymbolOptions(iconSize: meetPinPulseIconSize(wave)),
        );
      } catch (_) {}
    }
    if (_routeFlowSymbol == null &&
        _meetPulseSymbols.isEmpty &&
        _meetHaloSymbols.isEmpty) {
      _routeFlowTimer?.cancel();
      _routeFlowTimer = null;
    }
  }

  /// Meine-Play: gleicher HUD-Start wie Losfahren (Autostart + Ride-Tab).
  Future<void> _startRideFromSaved(SavedRouteEntry s) async {
    if (_launchingRide) return;
    final catalog = catalogTourIdOf(
      s.id,
      _savedMeta[s.id] ?? SavedRouteMeta.empty,
    );
    final tour = catalog != null
        ? (_tourById(catalog) ?? _tourById(s.id))
        : _tourById(s.id);
    if (tour != null && (_isLoop(tour) || tour.hasTrack)) {
      await _startRide(suggestion: tour);
      return;
    }
    final route = activeRouteFromSaved(s);
    if (route == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.discoverNoTrackOnMap),
        ),
      );
      return;
    }
    _openRideHud(route);
  }

  void _openRideHud(ActiveRoute route) {
    ref.read(activeRouteProvider.notifier).state = route;
    ref.read(rideAutostartProvider.notifier).state = true;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
    unawaited(_bindPendingGroupForRide(route.id));
  }

  /// Let's ride an dieser Tour: nur die passende Gruppe, nie eine andere.
  Future<void> _bindPendingGroupForRide(String routeId) async {
    final prefer = ref.read(ridePendingGroupIdProvider);
    final catalog = catalogTourIdOf(
      routeId,
      _savedMeta[routeId] ?? SavedRouteMeta.empty,
    );
    final g = await RideGroupStore().groupForRide(
      routeId,
      preferGroupId: prefer,
      catalogTourId: catalog,
    );
    if (!mounted) return;
    ref.read(ridePendingGroupIdProvider.notifier).state = g?.id;
  }

  Future<void> _startRide({_RouteSuggestion? suggestion}) async {
    if (_launchingRide) return;
    _launchingRide = true;
    final l10n = _l10n;
    try {
      // Selected tour track is the spine. If GPS is far from that track,
      // prepend a live approach (GPS → join) so Losfahren is not tour-only.
      // Navigieren-Panel mit berechneter A–B: nicht eine Rest-Tour aus Entdecken.
      final usePlannedAb = suggestion == null &&
          _shellMode == DiscoverShellMode.navigate &&
          _computed != null;
      final tour = usePlannedAb
          ? null
          : (suggestion ??
              (_selectedTourId != null ? _tourById(_selectedTourId) : null));
      if (tour != null && (_isLoop(tour) || tour.hasTrack)) {
        final routed = await _geometryForTour(tour);
        if (!mounted) return;
        if (routed.demo || routed.points.length < 2) {
          if (_isLoop(tour)) {
            // Never silently demote a Rundkurs to Start→Ziel-Vorschlag.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_l10n.discoverNoClosedLoop),
              ),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.discoverNoLiveTrackPlan),
            ),
          );
          await _computeIdeaRoute(tour);
          return;
        }
        var coords = routed.points.map((p) => [p.lng, p.lat]).toList();
        var closed = navGeometryIsLoop(coords);
        // Honesty: loop selection must navigate a closed polyline — unless we
        // prepend a GPS approach (open A→join is the honest shape).
        if (_isLoop(tour) && !closed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.discoverNotClosedLoopNav),
            ),
          );
          return;
        }
        final navSteps = navStepsFromPolyline(
          routed.points.map((p) => (lat: p.lat, lng: p.lng)).toList(),
        );
        var tourSteps = [
          for (final st in navSteps)
            NavStep(
              id: st.id,
              instruction: st.instruction,
              distanceAlongM: st.distanceAlongM,
              streetName: extractStreetNameFromInstruction(st.instruction),
            ),
        ];
        try {
          if (!_navPolicy.skipEngineTrackReroute) {
            final engine = await _routes
                .planNavAlongTrack(track: routed.points, profile: _profile)
                .timeout(const Duration(seconds: 10));
            final remapped = remapEngineStepsOntoTrack(engine.steps, coords);
            if (engineStepsUseful(remapped)) {
              tourSteps = [
                for (final s in remapped)
                  NavStep(
                    id: s.id,
                    instruction: s.instruction,
                    distanceAlongM: s.distanceAlongM,
                    streetName: s.streetName ??
                        extractStreetNameFromInstruction(s.instruction),
                  ),
              ];
            }
          }
        } catch (_) {}

        var approachSteps = <NavStep>[];
        var approachDistM = 0.0;
        var remainM = tour.distanceKm * 1000;
        final gps = _userPos;
        if (gps != null && coords.length >= 2) {
          final prog = projectOntoRoute(
            coordinates: coords,
            lat: gps.lat,
            lng: gps.lng,
          );
          if (tourNeedsApproachFromGps(prog.crossTrackM)) {
            final joinIdx = (prog.segmentIndex + 1).clamp(1, coords.length - 1);
            final join = coords[joinIdx];
            try {
              if (mounted) setState(() => _loading = true);
              final dKm = trailAccessHaversineKm(
                gps.lat,
                gps.lng,
                join[1],
                join[0],
              );
              final kind = suggestedApproachKind(
                policy: _navPolicy,
                distanceKm: dKm,
              );
              if (kind == ApproachKind.atStart) {
                if (mounted) setState(() => _loading = false);
              } else {
                final costing = _navPolicy.isGravity
                    ? approachRoutingProfile(
                        _garageCategory ?? BikeCategory.urban,
                        kind,
                      )
                    : _profile;
                final approach = await _discoverPlanRoute(
                  from: gps,
                  to: GeoPoint(join[1], join[0]),
                  profile: costing,
                  accessLeg: _navPolicy.isGravity,
                ).timeout(const Duration(seconds: 15));
                unawaited(_refreshOfflineChip());
                final eng = approach.engine ?? '';
                final approx = eng.contains('demo') ||
                    eng == 'fallback-line' ||
                    eng == 'approx';
                if (!approx && approach.coordinates.length >= 2) {
                  final approachCoords = [
                    for (final p in approach.coordinates) [p.lng, p.lat],
                  ];
                  final merged = mergeApproachAndTour(
                    approachLngLat: approachCoords,
                    tourLngLat: coords,
                    joinIndex: joinIdx,
                  );
                  coords = merged.coordinates;
                  remainM = merged.remainM;
                  closed = false;
                  approachDistM = approach.distanceM;
                  approachSteps = [
                    for (final st in approach.steps)
                      NavStep(
                        id: st.id,
                        instruction: st.instruction,
                        distanceAlongM: st.distanceAlongM,
                        streetName: st.streetName ??
                            extractStreetNameFromInstruction(st.instruction),
                      ),
                  ];
                  debugPrint(
                    'Losfahren approach ${approachDistM.toStringAsFixed(0)}m '
                    'engine=$eng join=$joinIdx verts=${coords.length}',
                  );
                }
              }
            } catch (e) {
              debugPrint('Losfahren approach failed: $e');
            } finally {
              if (mounted) setState(() => _loading = false);
            }
          }
        }

        final steps = [
          ...approachSteps,
          for (final s in tourSteps)
            NavStep(
              id: s.id,
              instruction: s.instruction,
              distanceAlongM: s.distanceAlongM + approachDistM,
              streetName: s.streetName,
            ),
        ];
        _openRideHud(
          ActiveRoute(
            id: tour.id,
            name: approachDistM > 0
                ? l10n.discoverFromHereName(tour.name)
                : tour.name,
            distanceKm: approachDistM > 0
                ? (approachDistM + remainM) / 1000
                : tour.distanceKm,
            elevationM: tour.elevationM.toDouble(),
            durationMin: approachDistM > 0
                ? ((approachDistM + remainM) / 1000 / 12 * 60).round()
                : tour.durationMin,
            mtbScale: tour.mtbScale,
            coordinates: coords,
            steps: steps,
            poiStops: () {
              final duration = approachDistM > 0
                  ? ((approachDistM + remainM) / 1000 / 12 * 60).round()
                  : tour.durationMin;
              final viaStops = poiStopsFromVias(
                vias: _vias,
                coordinates: coords,
                durationMin: duration,
              );
              if (viaStops.isNotEmpty) return viaStops;
              return [
                for (final p in tour.poiStops)
                  ActiveRoutePoi(
                    atMin: p.atMin,
                    title: p.title,
                    kind: p.kind,
                  ),
              ];
            }(),
            isLoop: closed,
            joinAlongM: approachDistM,
            gravitySession: _navPolicy.isGravity,
          ),
        );
        return;
      }

      var engine = _computed;
      if (engine == null) return;
      final from = _start;
      final to = _end;
      final skipDetourCheck = _gravityComputed || _trailOverlay != null;
      if (!skipDetourCheck &&
          from != null &&
          to != null &&
          isImplausibleAbDetour(
            distanceM: engine.distanceM,
            fromLat: from.lat,
            fromLng: from.lng,
            toLat: to.lat,
            toLng: to.lng,
            vias: [
              for (final v in _vias) (lat: v.lat, lng: v.lng),
            ],
          )) {
        await _routes.invalidateRoute(
          from: from,
          to: to,
          profile: _abCosting,
          vias: List<GeoPoint>.from(_viaPoints),
          accessLeg: _navPolicy.isGravity,
          variant: _routeVariant,
        );
        await _calcAb();
        if (!mounted) return;
        engine = _computed;
        if (engine == null) return;
      }
      final eng = engine.engine ?? '';
      final approx = eng.contains('demo') || eng.contains('fallback');
      if (approx || engine.coordinates.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.discoverNoRealPolyline),
            ),
          );
        }
        return;
      }
      final elevM = _elevationGainM ?? 0;
      final coords = engine.coordinates.map((p) => [p.lng, p.lat]).toList();
      final durationMin = (engine.durationS / 60).round();
      final catalogId = _selectedTourId;
      String routeId;
      if (catalogId != null &&
          _adaptingTourName != null &&
          catalogTourIdOf(catalogId) != null) {
        routeId = catalogId;
      } else if (planStartRidePersistsDraft(
        hasComputed: true,
        fromCatalogSuggestion: suggestion != null,
      )) {
        final entry = await _persistCurrentPlan(
          announce: false,
          offerOffline: false,
        );
        if (!mounted) return;
        final handoff = planRideHandoffId(entry?.id);
        if (handoff == null) return;
        routeId = handoff;
      } else {
        routeId = 'engine-${DateTime.now().millisecondsSinceEpoch}';
      }
      _openRideHud(
        ActiveRoute(
          id: routeId,
          name: _label ?? l10n.discoverComputedRoute,
          distanceKm: engine.distanceM / 1000,
          elevationM: elevM,
          durationMin: durationMin,
          mtbScale: null,
          coordinates: coords,
          steps: engine.steps
              .map(
                (st) => NavStep(
                  id: st.id,
                  instruction: st.instruction,
                  distanceAlongM: st.distanceAlongM,
                  streetName: st.streetName,
                ),
              )
              .toList(),
          poiStops: poiStopsFromVias(
            vias: _vias,
            coordinates: coords,
            durationMin: durationMin,
            destinationLabel: namedPlaceHudTitle(
              _endAddrCtrl.text,
              skipExact: _l10n.discoverSuggestEnd,
            ),
          ),
          isLoop: navGeometryIsLoop(coords),
          joinAlongM: _joinAlongM,
          gravitySession: _gravityComputed ||
              (_navPolicy.isGravity && _trailOverlay != null),
        ),
      );
    } finally {
      _launchingRide = false;
    }
  }

  bool _continuePlanAsGroup(String routeId) {
    if (!ref.read(platzPendingPlanAsGroupProvider)) return false;
    ref.read(platzPendingPlanAsGroupProvider.notifier).state = false;
    ref.read(platzPendingCreateGroupRouteIdProvider.notifier).state = routeId;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.platz;
    return true;
  }

  void _clearPlanAsGroupIfUnused() {
    ref.read(platzPendingPlanAsGroupProvider.notifier).state = false;
  }

  Future<void> _saveCurrent() async {
    await _persistCurrentPlan();
  }

  /// Persists the live A→B draft. Returns null if nothing to save or group
  /// handoff already left Discover (caller must not start ride).
  Future<SavedRouteEntry?> _persistCurrentPlan({
    bool announce = true,
    bool offerOffline = true,
  }) async {
    final r = _computed;
    if (r == null) return null;
    final geomKey = planDraftGeometryKey(
      coordinates: [
        for (final p in r.coordinates) [p.lng, p.lat],
      ],
      viaCount: _vias.length,
      distanceM: r.distanceM,
    );
    final reuseId = planReuseSavedHandoffId(
      lastSavedId: _lastPersistedPlanId,
      lastSavedGeomKey: _lastPersistedPlanKey,
      currentGeomKey: geomKey,
    );
    if (reuseId != null) {
      final list =
          ref.read(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
      for (final e in list) {
        if (e.id == reuseId) {
          if (announce && mounted) {
            setState(() => _setStatus(_l10n.discoverSaved));
          }
          return e;
        }
      }
    }
    final waypoints = <SavedWaypoint>[
      if (_start != null)
        SavedWaypoint(
          role: 'start',
          lng: _start!.lng,
          lat: _start!.lat,
          label: _l10n.navigateStartLabel,
        ),
      for (var i = 0; i < _vias.length; i++)
        SavedWaypoint(
          role: 'via',
          lng: _vias[i].lng,
          lat: _vias[i].lat,
          label: _vias[i].trimmedLabel ?? _l10n.discoverViaN(i + 1),
        ),
      if (_end != null)
        SavedWaypoint(
          role: 'end',
          lng: _end!.lng,
          lat: _end!.lat,
          label: _l10n.navigateEndLabel,
        ),
    ];
    final entry = await _routes.saveComputed(
      name: _label ?? _l10n.discoverSavedRoute,
      result: r,
      waypoints: waypoints,
      approach: _approach?.coordinates ?? const [],
      tour: _tourLayer?.coordinates ?? const [],
      trail: _trailOverlay ?? const [],
      source: _approach != null || _tourLayer != null || _trailOverlay != null
          ? 'import'
          : 'engine',
      elevationGainM: _elevationGainM,
      elevationPoints: _planElevPoints,
      elevationSource: _planElevSource,
    );
    ref.invalidate(savedRoutesProvider);
    _lastPersistedPlanId = entry.id;
    _lastPersistedPlanKey = geomKey;
    if (_continuePlanAsGroup(entry.id)) return null;
    if (!mounted) return entry;
    if (announce) {
      setState(() => _setStatus(_l10n.discoverSaved));
    }
    if (!offerOffline) return entry;
    final a = _start;
    final b = _end;
    if (a == null || b == null) return entry;
    final covered = await OfflinePackDirs.legitimateCoversRoute(
      fromLng: a.lng,
      fromLat: a.lat,
      toLng: b.lng,
      toLat: b.lat,
      vias: _offlineViaLngLats(),
      along: _offlineAlongLngLats(r.coordinates),
    );
    if (!mounted || covered) return entry;
    OfflinePackRow? pack;
    try {
      pack = suggestedPackForRoute(
        packs: await _ensureOfflineCatalog(),
        fromLng: a.lng,
        fromLat: a.lat,
        toLng: b.lng,
        toLat: b.lat,
        extra: [
          ..._offlineViaLngLats(),
          ..._offlineAlongLngLats(r.coordinates),
        ],
      );
    } catch (_) {}
    if (!mounted) return entry;
    final offer = shouldOfferOfflinePackDownload(
      covered: false,
      suggestedPackId: pack?.id,
      installedIds: await OfflinePackDirs.legitimateIds(),
      hasActivatedPack: await OfflinePackDirs.hasLegitimateActivatedPack(),
    );
    if (!mounted || !offer) return entry;
    var snack = _l10n.discoverOfflineAfterSave;
    if (pack != null) {
      snack = _l10n.discoverOfflineAfterSaveForPack(
        _l10n.overlayRegionNameFor(pack.id, pack.name),
        formatPackBytes(pack.routingBytes),
        packId: pack.id,
      );
    }
    final mid = r.coordinates[r.coordinates.length ~/ 2];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snack),
        action: SnackBarAction(
          label: _l10n.discoverOfflineAfterSaveAction,
          onPressed: () => unawaited(
            _openOfflineMaps(focus: mid, focusPackId: pack?.id),
          ),
        ),
      ),
    );
    return entry;
  }

  Future<void> _openTourOverflow(_RouteSuggestion r) async {
    final l10n = AppLocalizations.of(context);
    final pick = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: HofThresholdNav.sheetBottomInset(ctx, extra: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const ChromeGlyph('karte', size: 22),
                title: Text(l10n.showOnMap),
                onTap: () => Navigator.pop(ctx, 'map'),
              ),
              ListTile(
                leading: const ChromeGlyph('filter', size: 22),
                title: Text(l10n.adaptTour),
                onTap: () => Navigator.pop(ctx, 'adapt'),
              ),
              ListTile(
                leading: const ChromeGlyph('locate', size: 22),
                title: Text(l10n.discoverFromHere),
                onTap: () => Navigator.pop(ctx, 'fromHere'),
              ),
              ListTile(
                leading: const ChromeGlyph('photo', size: 22),
                title: Text(l10n.discoverNearbyPhotos),
                onTap: () => Navigator.pop(ctx, 'photos'),
              ),
              ListTile(
                leading: const ChromeGlyph('merken', size: 22),
                title: Text(l10n.discoverToMyTours),
                onTap: () => Navigator.pop(ctx, 'save'),
              ),
              ListTile(
                leading: const ChromeGlyph('platz', size: 22),
                title: Text(l10n.akteAddToCollection),
                onTap: () => Navigator.pop(ctx, 'collection'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || pick == null) return;
    switch (pick) {
      case 'map':
        await _previewTourOnMap(r);
      case 'adapt':
        await _adoptTourIntoPlan(r);
      case 'fromHere':
        await _hybridSnap(r);
      case 'photos':
        _openTrailView(near: r.center);
      case 'save':
        await _saveTourToLibrary(r);
      case 'collection':
        await _saveTourToLibrary(r, quiet: true);
        if (!mounted) return;
        final added = await showAddToCollectionSheet(context, routeId: r.id);
        if (added && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.discoverAddedToCollection)),
          );
        }
    }
  }

  Future<void> _saveTourToLibrary(
    _RouteSuggestion r, {
    bool quiet = false,
  }) async {
    final saved =
        ref.read(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    if (saved.any((e) => e.id == r.id)) {
      if (_continuePlanAsGroup(r.id)) return;
      if (!mounted || quiet) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.discoverAlreadyInMappe)),
      );
      return;
    }
    final routed = _routedLoopCache[r.id];
    var coords = routed != null && routed.length >= 2
        ? [
            for (final p in routed) [p.lng, p.lat]
          ]
        : (r.trackLngLat ?? const <List<double>>[]);
    if (coords.length >= 2 && !trackHasRealElev(coords)) {
      if (_selectedTourId == r.id &&
          _planElevPoints.isNotEmpty &&
          !elevationSourceIsDemo(_planElevSource)) {
        coords = attachRealElevToTrack(
          trackLngLat: coords,
          samples: trackElevSamplesFromMaps(_planElevPoints),
          source: _planElevSource,
        );
      } else {
        final geo = [
          for (final p in coords) GeoPoint(p[1], p[0]),
        ];
        final profile = await _elevationClient.fetchForTrack(geo);
        if (profile != null && !elevationSourceIsDemo(profile.source)) {
          coords = attachRealElevToTrack(
            trackLngLat: coords,
            samples: trackElevSamplesFromMaps(profile.points),
            source: profile.source,
          );
        }
      }
    }
    await _routes.saveEntry(
      SimpleAddRoute.fromExistingTour(
        id: r.id,
        name: r.name,
        distanceKm: r.distanceKm,
        elevationM: r.elevationM.toDouble(),
        durationMin: r.durationMin,
        startLat: r.center.latitude,
        startLng: r.center.longitude,
        coordinates: coords,
      ),
    );
    final bike = await ref.read(garageRepositoryProvider).getActiveBike();
    final cur = await SavedRouteMetaStore.get(r.id);
    await SavedRouteMetaStore.put(
      r.id,
      cur.copyWith(
        catalogTourId: r.id,
        preferredBikeId: bike?.id,
        mtbScale: mappeFaceTag(r.mtbScale),
        surface: mappeFaceTag(r.surface),
      ),
    );
    ref.invalidate(savedRoutesProvider);
    if (_continuePlanAsGroup(r.id)) return;
    if (!mounted || quiet) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.discoverInMappeNamed(r.name))),
    );
  }

  Future<void> _addSimpleRouteSheet() async {
    final nameCtrl = TextEditingController(
      text: SimpleAddRoute.defaultName(DateTime.now()),
    );
    var useGps = _userPos != null;
    final saved = await showModalBottomSheet<SavedRouteEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final gps = _userPos;
            final center = _usableDiscoverMapCenter;
            final loc = AppLocalizations.of(ctx);
            final pin = resolveAddRouteStart(
              gpsLat: useGps ? gps?.lat : null,
              gpsLng: useGps ? gps?.lng : null,
              mapLat: center?.lat,
              mapLng: center?.lng,
            );
            final startLine = pin == null
                ? loc.mappeStartNone
                : pin.source == AddRouteStartSource.gps
                    ? loc.mappeStartGps(
                        '${pin.lat.toStringAsFixed(3)}°N, ${pin.lng.toStringAsFixed(3)}°E',
                      )
                    : loc.mappeStartMap(
                        '${pin.lat.toStringAsFixed(3)}°N, ${pin.lng.toStringAsFixed(3)}°E',
                      );
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: HofThresholdNav.sheetBottomInset(ctx),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.discoverAddRoute,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.mappeAddHint,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: loc.garageName,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('GPS'),
                        selected: useGps && gps != null,
                        onSelected: gps == null
                            ? null
                            : (v) => setSheet(() => useGps = v),
                      ),
                      FilterChip(
                        label: Text(loc.discoverMapCenter),
                        selected: (!useGps || gps == null) && center != null,
                        onSelected: center == null
                            ? null
                            : (_) => setSheet(() => useGps = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    startLine,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        ctx,
                        SimpleAddRoute.fromStart(
                          name: nameCtrl.text,
                          lat: pin?.lat,
                          lng: pin?.lng,
                        ),
                      );
                    },
                    child: Text(loc.discoverSaveToMine),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    if (saved == null) return;
    await _routes.saveEntry(saved);
    ref.invalidate(savedRoutesProvider);
    if (_continuePlanAsGroup(saved.id)) return;
    if (!mounted) return;
    setState(() {
      _hofChoice = false;
      _shellMode = DiscoverShellMode.mine;
      _setStatus(_l10n.discoverSavedNamed(saved.name));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.discoverSavedToMine(saved.name))),
    );
  }

  /// Zeigt einen kurzen Fehlerhinweis mit „Datei erneut wählen" — kein
  /// Rohtext-Paste-Feld mehr (unbenutzbar für alle außer Entwicklern).
  /// `true` = Nutzer will erneut auswählen, `false`/`null` = abbrechen.
  Future<bool> _retryGpxPick(String message) async {
    if (!mounted) return false;
    final retry = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).gpxImportAction),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx).discoverPickFileAgain),
          ),
        ],
      ),
    );
    return retry == true;
  }

  Future<void> _importGpxDialog() async {
    String xml;
    String fallbackName;

    while (true) {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['gpx', 'xml'],
      );
      if (f == null) {
        // Nutzer hat den Datei-Dialog selbst abgebrochen — kein erzwungenes
        // Retry, sonst wirkt es wie eine Endlosschleife.
        return;
      }
      final name = f.name.replaceAll(
        RegExp(r'\.gpx$', caseSensitive: false),
        '',
      );
      String? content;
      try {
        if (f.path != null) {
          content = await File(f.path!).readAsString();
        } else {
          final bytes = await f.readAsBytes();
          content = decodeGpxBytes(bytes);
        }
      } catch (_) {}

      if (content == null || content.trim().isEmpty) {
        if (await _retryGpxPick(
          _l10n.discoverGpxUnreadable(f.name),
        )) {
          continue;
        }
        return;
      }
      xml = content;
      fallbackName = name;
      break;
    }

    final parsed = parseGpx(xml, fallbackName: fallbackName);
    if (parsed == null) {
      if (await _retryGpxPick(
        _l10n.discoverGpxInvalid,
      )) {
        return _importGpxDialog();
      }
      return;
    }
    final entry = SavedRouteEntry(
      id: 'import-${const Uuid().v4()}',
      name: parsed.name,
      distanceKm: parsed.distanceKm,
      elevationM: parsed.elevationM,
      durationMin: parsed.durationMinEstimate,
      savedAt: DateTime.now().toUtc(),
      source: 'import',
      coordinates: parsed.points,
      waypoints: [
        if (parsed.points.isNotEmpty)
          SavedWaypoint(
            role: 'start',
            lng: parsed.points.first[0],
            lat: parsed.points.first[1],
          ),
        if (parsed.points.length > 1)
          SavedWaypoint(
            role: 'end',
            lng: parsed.points.last[0],
            lat: parsed.points.last[1],
          ),
      ],
    );
    await _routes.saveEntry(entry);
    ref.invalidate(savedRoutesProvider);
    if (_continuePlanAsGroup(entry.id)) return;
    if (!mounted) return;
    setState(() {
      _setStatus(_l10n.discoverGpxImported(
          parsed.name, parsed.distanceKm.toStringAsFixed(1)));
      _hofChoice = false;
      _shellMode = DiscoverShellMode.mine;
      _surface = _Surface.discover;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_l10n.discoverSavedDotName(parsed.name)),
        action: SnackBarAction(
          label: _l10n.discoverAsActive,
          onPressed: () {
            ref.read(activeRouteProvider.notifier).state = ActiveRoute(
              id: entry.id,
              name: entry.name,
              distanceKm: entry.distanceKm,
              elevationM: entry.elevationM,
              durationMin: entry.durationMin,
              coordinates: entry.coordinates,
              isLoop: navGeometryIsLoop(entry.coordinates),
            );
            ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
          },
        ),
      ),
    );
  }

  Future<void> _collectionsSheet() async {
    var cols = await RouteCollectionsStore.list();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.l,
                AppSpacing.l,
                HofThresholdNav.sheetBottomInset(ctx),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(ctx).discoverMenuCollections,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppLocalizations.of(ctx).discoverLocalFoldersHint,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (_editorialSets.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      AppLocalizations.of(ctx).discoverEditorialSets,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _editorialHonesty.isNotEmpty
                          ? _editorialHonesty
                          : AppLocalizations.of(ctx).discoverEditorialHonesty,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    for (final s in _editorialSets.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const ChromeGlyph('platz', size: 22),
                        title: Text(s.name),
                        subtitle: Text(
                          AppLocalizations.of(ctx)
                              .collectionRouteCount(s.count),
                        ),
                        onTap: () async {
                          final tours = [
                            for (final id in s.tourIds)
                              if (_catalogById[id] != null) _catalogById[id]!,
                          ];
                          if (tours.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(ctx)
                                      .discoverEditorialEmpty,
                                ),
                              ),
                            );
                            return;
                          }
                          final pick = await showDialog<_RouteSuggestion>(
                            context: ctx,
                            builder: (dCtx) => SimpleDialog(
                              title: Text(s.name),
                              children: [
                                for (final t in tours.take(20))
                                  SimpleDialogOption(
                                    onPressed: () => Navigator.pop(dCtx, t),
                                    child: Text(
                                      '${t.name} · ${t.distanceKm.toStringAsFixed(1)} km',
                                    ),
                                  ),
                              ],
                            ),
                          );
                          if (pick != null && ctx.mounted) {
                            Navigator.pop(ctx);
                            await _previewTourOnMap(pick);
                          }
                        },
                      ),
                    const Divider(),
                  ],
                  const SizedBox(height: AppSpacing.m),
                  for (final c in cols)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name),
                      subtitle: Text(
                        AppLocalizations.of(ctx).collectionRouteCount(
                          c.routeIds.length,
                        ),
                      ),
                      onTap: () async {
                        final saved = await _routes.listSaved();
                        if (!ctx.mounted) return;
                        final inCol = [
                          for (final id in c.routeIds)
                            for (final s in saved)
                              if (s.id == id) s,
                        ];
                        if (inCol.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(ctx)
                                    .discoverNoSavedInCollection,
                              ),
                            ),
                          );
                          return;
                        }
                        final pick = await showDialog<SavedRouteEntry>(
                          context: ctx,
                          builder: (dCtx) => SimpleDialog(
                            title: Text(c.name),
                            children: [
                              for (final s in inCol)
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(dCtx, s),
                                  child: Text(
                                    '${s.name} · ${s.distanceKm.toStringAsFixed(1)} km',
                                  ),
                                ),
                            ],
                          ),
                        );
                        if (pick != null && ctx.mounted) {
                          Navigator.pop(ctx);
                          await _loadSaved(pick);
                        }
                      },
                      trailing: IconButton(
                        icon: const ChromeGlyph('trash', size: 22),
                        onPressed: () async {
                          await RouteCollectionsStore.delete(c.id);
                          cols = await RouteCollectionsStore.list();
                          setModal(() {});
                        },
                      ),
                    ),
                  if (cols.isEmpty)
                    Text(
                      AppLocalizations.of(ctx).discoverNoCollectionYet,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(ctx).discoverNewCollection,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      await RouteCollectionsStore.create(name);
                      cols = await RouteCollectionsStore.list();
                      nameCtrl.clear();
                      setModal(() {});
                    },
                    child: Text(AppLocalizations.of(ctx).discoverCreate),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  OutlinedButton(
                    onPressed: () async {
                      final saved = await _routes.listSaved();
                      if (!ctx.mounted) return;
                      if (saved.isEmpty || cols.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(ctx)
                                  .discoverNeedRouteAndCollection,
                            ),
                          ),
                        );
                        return;
                      }
                      String? routeId;
                      if (_computed != null) {
                        for (final s in saved) {
                          if (s.name == _label) {
                            routeId = s.id;
                            break;
                          }
                        }
                      }
                      routeId ??= await showDialog<String>(
                        context: ctx,
                        builder: (dCtx) => SimpleDialog(
                          title:
                              Text(AppLocalizations.of(dCtx).discoverPickRoute),
                          children: [
                            for (final s in saved.take(20))
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(dCtx, s.id),
                                child: Text(
                                  '${s.name} · ${s.distanceKm.toStringAsFixed(1)} km',
                                ),
                              ),
                          ],
                        ),
                      );
                      if (routeId == null || !ctx.mounted) return;
                      final colId = cols.length == 1
                          ? cols.first.id
                          : await showDialog<String>(
                              context: ctx,
                              builder: (dCtx) => SimpleDialog(
                                title: Text(AppLocalizations.of(dCtx)
                                    .discoverPickCollection),
                                children: [
                                  for (final c in cols)
                                    SimpleDialogOption(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, c.id),
                                      child: Text(
                                        '${c.name} (${c.routeIds.length})',
                                      ),
                                    ),
                                ],
                              ),
                            );
                      if (colId == null || !ctx.mounted) return;
                      await RouteCollectionsStore.addRoute(colId, routeId);
                      cols = await RouteCollectionsStore.list();
                      setModal(() {});
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(ctx)
                                .discoverAddedToCollection),
                          ),
                        );
                      }
                    },
                    child: Text(
                        AppLocalizations.of(ctx).discoverRouteToCollection),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadSaved(SavedRouteEntry s) async {
    final coords = s.coordinates.map((c) => GeoPoint(c[1], c[0])).toList();
    if (coords.length < 2) {
      final startWp = s.waypoints.where((w) => w.role == 'start').firstOrNull;
      final start = startWp != null ? GeoPoint(startWp.lat, startWp.lng) : null;
      if (!mounted) return;
      setState(() {
        _computed = null;
        _label = s.name;
        _start = start;
        _end = null;
        _vias.clear();
        _hofChoice = false;
        _shellMode = DiscoverShellMode.mine;
        _surface = _Surface.discover;
        _setStatus(_l10n.discoverStartSavedNoTrack);
      });
      if (start != null) {
        try {
          await _map?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(start.lat, start.lng), 13),
          );
        } catch (_) {}
      }
      return;
    }
    final result = RouteResult(
      coordinates: coords,
      distanceM: s.distanceKm * 1000,
      durationS: s.durationMin * 60.0,
      engine: restoredSavedEngine(s.engine),
    );
    setState(() {
      _computed = result;
      _label = s.name;
      _approach = s.approach.length >= 2
          ? RouteResult(
              coordinates: s.approach.map((c) => GeoPoint(c[1], c[0])).toList(),
              distanceM: 0,
              durationS: 0,
              engine: 'approach',
            )
          : null;
      _tourLayer = s.tour.length >= 2
          ? RouteResult(
              coordinates: s.tour.map((c) => GeoPoint(c[1], c[0])).toList(),
              distanceM: 0,
              durationS: 0,
              engine: 'tour',
            )
          : null;
      _trailOverlay = s.trail.length >= 2
          ? s.trail.map((c) => GeoPoint(c[1], c[0])).toList()
          : null;
      _start = s.waypoints
          .where((w) => w.role == 'start')
          .map((w) => GeoPoint(w.lat, w.lng))
          .firstOrNull;
      _end = s.waypoints
          .where((w) => w.role == 'end')
          .map((w) => GeoPoint(w.lat, w.lng))
          .firstOrNull;
      _vias
        ..clear()
        ..addAll(
          s.waypoints.where((w) => w.role == 'via').map(
                (w) => LabeledVia(
                  lat: w.lat,
                  lng: w.lng,
                  label: w.label,
                ),
              ),
        );
      // Gespeicherte Route: Meine-Modus, Track auf Karte, Los-Leiste.
      _hofChoice = false;
      _shellMode = DiscoverShellMode.mine;
      _surface = _Surface.discover;
      _setStatus(_l10n.discoverSavedRouteLoaded);
    });
    await _drawAll();
  }

  /// Tour hinter dem offenen Detail-Panel. Fällt auf [_tours] zurück, falls
  /// die Tour gerade nicht in [_filtered] steckt (z. B. Filter geändert,
  /// während das Panel offen war) — sonst verschwindet der Inhalt unter der
  /// Nutzerin weg, während das Panel selbst offen bleibt.
  _RouteSuggestion? get _detailTour => _tourById(_detailId);

  /// Tour-Fokus auf der Karte: volle Discover-Chrome (Titel, GPX, Menü,
  /// Sport-Chips, Status-Pills) würde die Strecke zudecken — Komoot-ähnlich
  /// nur minimale Controls oben. Discover/Planen behalten die normale Leiste.
  bool get _tourMapFocus => _surface == _Surface.detail;

  @override
  Widget build(BuildContext context) {
    final pendingLoop = ref.watch(discoverPendingLoopIdProvider);
    if (pendingLoop != null && pendingLoop.isNotEmpty) {
      _hofPinLoopId = pendingLoop;
    }
    ref.listen(discoverLaunchModeProvider, (prev, next) {
      if (next == null) return;
      _applyDiscoverLaunch(next);
    });
    ref.listen(shellTabIndexProvider, (prev, next) {
      if (next != ShellTabs.karte) {
        _clearPlanAsGroupIfUnused();
        return;
      }
      unawaited(_syncBrowseMapStyle());
      unawaited(_refreshOfflineChip());
    });
    ref.listen(discoverPendingMineProvider, (prev, next) {
      if (next != true) return;
      ref.read(discoverPendingMineProvider.notifier).state = false;
      _setShellMode(DiscoverShellMode.mine);
      unawaited(_consumePendingAkte());
      unawaited(_consumePendingStartRide());
    });
    ref.listen(discoverPendingAkteRouteIdProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      unawaited(_consumePendingAkte());
    });
    ref.listen(discoverPendingLoopIdProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      _pinPendingLoop(next);
    });
    ref.listen(discoverPendingLensMinutesProvider, (prev, next) {
      if (next == null) return;
      ref.read(discoverPendingLensMinutesProvider.notifier).state = null;
      setState(() {
        _minutes = next;
        _matchTourDuration = next > 0;
      });
    });
    ref.listen(discoverPendingStartRideRouteIdProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      unawaited(_consumePendingStartRide());
    });
    ref.listen(bikesProvider, (prev, next) {
      final c = _map;
      if (c == null || !_bikeOverlayAttached) return;
      unawaited(_syncBikeOverlayVisibility());
    });
    _syncOriginDrift();
    final style = _mapStyle;

    final size = MediaQuery.sizeOf(context);
    final panelHeight = _surface == _Surface.discover
        ? size.height * _discoverSheetExtent
        : size.height * _planSheetExtent;
    if (_hofChoice) {
      _panelInset = 248;
    } else if (_planSheetActive) {
      _panelInset = panelHeight;
    } else if (!_discoverSheetCtrl.isAttached) {
      _panelInset = panelHeight;
    }

    final coverageEdge = _coverageEdgeInfo(AppLocalizations.of(context));
    final coverageLegendOn = DiscoverExploreChromeLogic.showExploreLayerRow(
          hasSelection: DiscoverExploreChromeLogic.showIdlePeek(
            _hofPinLoopId ?? _selectedTourId,
          ),
          planning: _shellMode == DiscoverShellMode.navigate,
        ) &&
        (_showTrailsLayer || _showBikeWaysLayer);
    // Coach lives in the sheet (peek subtitle / form hint), never on the line.
    const planCoachOn = false;
    final showLocateFab = !_hofChoice &&
        !planCoachOn &&
        !_planWaitHidesChrome &&
        _planDragAlongLabel == null &&
        ((_shellMode == DiscoverShellMode.explore &&
                _surface == _Surface.discover) ||
            _surface == _Surface.plan);
    final showPlanHistoryFabs = planMapHistoryFabsVisible(
      editorActive: _surface == _Surface.plan,
      hasHistory:
          _planUndoStack.isNotEmpty || _planRedoStack.isNotEmpty,
      mapHintOnMap: _planMapHintOnMap,
      rubberBand: _planDragAlongLabel != null,
      coachVisible: planCoachOn,
      routingWaitBanner: _showPlanRoutingWait,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            _onPlanUndoShortcut,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            _onPlanUndoShortcut,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _onPlanRedoShortcut,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): _onPlanRedoShortcut,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true):
            _onPlanRedoShortcut,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              // Karte füllt den Screen. Discover ist Karte + Liste — nicht
              // Kopfzeile, Kartenfenster und Schubfach übereinander.
              Positioned.fill(child: _buildMap(style)),
              const StatusBarScrim(),
              if (showLocateFab || showPlanHistoryFabs)
                Positioned(
                  top: MapOrnaments.compassMargins(
                    context,
                    extraBelowSafe:
                        DiscoverExploreChromeLogic.ornamentExtraBelowSafe(
                      _resolvedExploreChromeHeight,
                    ),
                  ).y.toDouble(),
                  right: MapOrnaments.compassMargins(context).x.toDouble(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showLocateFab) _discoverLocateFab(),
                      if (showLocateFab && showPlanHistoryFabs)
                        const SizedBox(height: 8),
                      if (showPlanHistoryFabs && _planUndoStack.isNotEmpty)
                        _discoverMapFab(
                          key: const Key('plan-map-undo'),
                          tooltip: AppLocalizations.of(context).planUndo,
                          mark: 'undo',
                          onTap: _undoPlan,
                          size: 40,
                        ),
                      if (showPlanHistoryFabs &&
                          _planUndoStack.isNotEmpty &&
                          _planRedoStack.isNotEmpty)
                        const SizedBox(height: 8),
                      if (showPlanHistoryFabs && _planRedoStack.isNotEmpty)
                        _discoverMapFab(
                          key: const Key('plan-map-redo'),
                          tooltip: AppLocalizations.of(context).planRedo,
                          mark: 'redo',
                          onTap: _redoPlan,
                          size: 40,
                        ),
                    ],
                  ),
                ),
              if (_showPlanRoutingWait && !_planWaitHintOnMap)
                Positioned(
                  left: AppSpacing.m,
                  right: 64,
                  bottom: _panelInset + AppSpacing.s,
                  child: Material(
                    key: const Key('plan-routing-wait'),
                    color: const Color(0xF21A120C),
                    elevation: 6,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: Row(
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFFFFB080),
                              ),
                            )
                          else
                            const ChromeGlyph(
                              'flag',
                              size: 18,
                              color: Color(0xFFFFB080),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasLivePlanLine
                                  ? AppLocalizations.of(context)
                                      .discoverRoutingAdapts
                                  : AppLocalizations.of(context)
                                      .discoverEndSetComputing,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_planUndoStack.isNotEmpty)
                            TextButton(
                              onPressed: _undoPlan,
                              child: Text(
                                AppLocalizations.of(context)
                                    .discoverLastDestUndo,
                                style:
                                    const TextStyle(color: Color(0xFFFFB080)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_surface == _Surface.plan &&
                  _planLegendKinds.isNotEmpty &&
                  !_showPlanRoutingWait &&
                  !_planRibbonDimmed &&
                  _planDragAlongLabel == null)
                Positioned(
                  left: AppSpacing.m,
                  right: showPlanHistoryFabs ? 72 : AppSpacing.m,
                  bottom: _panelInset + AppSpacing.s,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _planRibbonLegend(
                      AppLocalizations.of(context),
                      compact: planRibbonLegendCompact(size.width),
                    ),
                  ),
                ),
              if (_surface == _Surface.discover &&
                  DiscoverExploreChromeLogic.showExploreLayerRow(
                    hasSelection: DiscoverExploreChromeLogic.showIdlePeek(
                      _hofPinLoopId ?? _selectedTourId,
                    ),
                    planning: _shellMode == DiscoverShellMode.navigate,
                  ))
                Positioned(
                  left: AppSpacing.m,
                  right: AppSpacing.m,
                  top: DiscoverExploreChromeLogic.layerRowTop(
                    statusTop: MediaQuery.paddingOf(context).top,
                    chromeHeight: _resolvedExploreChromeHeight,
                  ),
                  child: (_showTrailsLayer || _showBikeWaysLayer)
                      ? DiscoverMapLegend(
                          trailsOn: _showTrailsLayer,
                          waysOn: _showBikeWaysLayer,
                        )
                      : const SizedBox.shrink(),
                ),
              if (!_hofChoice &&
                  _surface == _Surface.discover &&
                  coverageEdge != null)
                Positioned(
                  left: AppSpacing.m,
                  top: DiscoverExploreChromeLogic.layerRowTop(
                        statusTop: MediaQuery.paddingOf(context).top,
                        chromeHeight: _resolvedExploreChromeHeight,
                      ) +
                      (coverageLegendOn
                          ? DiscoverExploreChromeLogic.exploreLegendHeight + 16
                          : 0),
                  child: CoverageEdgePill(
                    label: coverageEdge.label,
                    outside: coverageEdge.outside,
                    overview: coverageEdge.overview,
                    needsNet: coverageEdge.needsNet,
                    streetAway: coverageEdge.streetAway,
                    onTap: () => unawaited(_openOfflineMaps()),
                  ),
                ),
              if (!_hofChoice)
                Positioned(
                    top: 0, left: 0, right: 0, child: _buildFloatingHeader()),
              // FAB und Los-Leiste stapeln in EINER bodenverankerten Spalte.
              // Getrennt positioniert bräuchte der FAB die Höhe der Leiste als
              // Konstante — die aber wächst, sobald der Routenname zweizeilig
              // umbricht, und beide würden sich überlappen.
              if (!_hofChoice)
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _discoverSheetCtrl,
                    _planSheetCtrl,
                  ]),
                  builder: (context, _) {
                    final extent = _surface == _Surface.discover
                        ? _discoverSheetExtent
                        : _planSheetExtent;
                    final bottom = extent * size.height + AppSpacing.s;
                    // Während Drag: Inset live für Kamera-Padding.
                    if (_surface == _Surface.discover &&
                        _discoverSheetCtrl.isAttached) {
                      _panelInset = extent * size.height;
                    } else if (_planSheetActive &&
                        _planSheetCtrl.isAttached) {
                      _panelInset = extent * size.height;
                    }
                    return Positioned(
                      left: AppSpacing.m,
                      right: AppSpacing.m,
                      bottom: bottom,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (DiscoverBrowseSheetSnaps.isFull(extent) &&
                              _shellMode == DiscoverShellMode.explore &&
                              _surface == _Surface.discover) ...[
                            Center(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.charcoal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                ),
                                onPressed: () => unawaited(
                                  _snapDiscoverSheet(
                                    DiscoverBrowseSheetSnaps.mapTarget(
                                      hasSelection: _hasExploreSelection,
                                    ),
                                  ),
                                ),
                                icon: const ChromeGlyph('karte', size: 18),
                                label: Text(
                                  AppLocalizations.of(context).mapToggleFab,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (PlanSheetSnaps.isFull(extent) &&
                              _planSheetActive) ...[
                            Center(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.charcoal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                ),
                                onPressed: () => unawaited(
                                  _snapPlanSheet(_planPeekSnap),
                                ),
                                icon: const ChromeGlyph('karte', size: 18),
                                label: Text(
                                  AppLocalizations.of(context).mapToggleFab,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_error ==
                                  AppLocalizations.of(context)
                                      .discoverViasNeedNet &&
                              _vias.isNotEmpty &&
                              (_surface == _Surface.plan ||
                                  _shellMode ==
                                      DiscoverShellMode.navigate)) ...[
                            Material(
                              color: const Color(0xE61F1F1F),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                                child: Row(
                                  children: [
                                    const ChromeGlyph(
                                      'offline',
                                      size: 18,
                                      color: Color(0xFFFF6A00),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .discoverViasNeedNet,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      key: const Key('discover-drop-vias-map'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _dropViasAndReroute,
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .discoverViasDropAndGo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_showRideBar && _surface != _Surface.detail) ...[
                            _buildRideBar(),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              if (_hofChoice)
                Positioned(
                  left: AppSpacing.m,
                  right: AppSpacing.m,
                  bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.m,
                  child: _buildHofRideOutChoice(),
                )
              else if (_surface == _Surface.discover)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (n) {
                      _syncDiscoverSheetExtent(n.extent);
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      // expand:false → Hit-Test nur Sheet-Höhe, Map darüber pannbar.
                      // No selection key: recreating the sheet while the same
                      // controller is still attached throws FlutterError
                      // ("controller is already attached") on tour tap.
                      expand: false,
                      controller: _discoverSheetCtrl,
                      initialChildSize: _hasExploreSelection
                          ? DiscoverBrowseSheetSnaps.peek
                          : (_listBrowseMode
                              ? DiscoverBrowseSheetSnaps.half
                              : DiscoverBrowseSheetSnaps.closed),
                      minChildSize: DiscoverBrowseSheetSnaps.minSize(
                        hasSelection: _hasExploreSelection,
                      ),
                      maxChildSize: DiscoverBrowseSheetSnaps.full,
                      snap: true,
                      snapSizes: DiscoverBrowseSheetSnaps.sheetSnapSizes(
                        hasSelection: _hasExploreSelection,
                      ),
                      builder: (context, scrollController) {
                        return _buildBottomPanel(
                          scrollController: scrollController,
                        );
                      },
                    ),
                  ),
                )
              else
                Align(
                  alignment: Alignment.bottomCenter,
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (n) {
                      _syncPlanSheetExtent(n.extent);
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      key: const Key('plan-detail-sheet'),
                      expand: false,
                      controller: _planSheetCtrl,
                      initialChildSize: _planInitialSnap,
                      minChildSize: _planPeekSnap,
                      maxChildSize: PlanSheetSnaps.full,
                      snap: true,
                      snapSizes: PlanSheetSnaps.sheetSnapSizes,
                      builder: (context, scrollController) {
                        return _buildBottomPanel(
                          scrollController: scrollController,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(String style) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PlanLineGrabLayer(
          enabled: _planEditorActive && _hasLivePlanLine,
          camera: () => _map?.cameraPosition,
          lineLngLat: () => _planComputedLineLngLat() ?? const [],
          pinLngLat: _planGrabAvoidPins,
          screenCache: () => _planGrabScreen,
          nativeUnproject: _planNativeUnproject,
          onExclusiveGrab: (v) {
            if (!mounted || v == _planLineExclusiveGrab) return;
            setState(() => _planLineExclusiveGrab = v);
          },
          onDown: _onPlanLinePointerDown,
          onMove: _onPlanLinePointerMove,
          onUp: _onPlanLinePointerUp,
          onCancel: _onPlanLinePointerCancel,
          onHoldCancel: _onPlanLineHoldCancel,
          child: MapLibreMap(
          key: ValueKey(_mapStyle),
          styleString: style,
          initialCameraPosition: CameraPosition(
            target: LatLng(_mapCenter.lat, _mapCenter.lng),
            zoom: _hasRealOrigin ? 13.5 : 5.5,
          ),
          compassEnabled: false,
          attributionButtonPosition: AttributionButtonPosition.bottomRight,
          attributionButtonMargins: MapOrnaments.attributionMargins(context),
          logoViewMargins: MapOrnaments.logoMargins(context),
          myLocationEnabled: true,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          trackCameraPosition: true,
          minMaxZoomPreference: const MinMaxZoomPreference(3, 18),
          rotateGesturesEnabled: !_planLineExclusiveGrab,
          scrollGesturesEnabled: !_planLineExclusiveGrab,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: !_planLineExclusiveGrab,
          gestureRecognizers: _mapGestures,
          onMapCreated: (c) {
            _map?.removeListener(_onMapCameraTick);
            _map = c;
            c.addListener(_onMapCameraTick);
            unawaited(_syncPlanGrabScreen());
            _pinImagesReady = false;
            _activeCoverageLayerReady = false;
            _suggestedCoverageLayerReady = false;
            _navPuck.reset();
            c.onSymbolTapped.add(_onTfSymbolTapped);
            c.onLineTapped.add(_onQuickLineTapped);
            c.onFeatureTapped.add(_onMapFeatureTapped);
            c.onFeatureDrag.add(_onPlanPinDrag);
            if (_styleReady && mounted) {
              setState(() => _styleReady = false);
            } else {
              _styleReady = false;
            }
          },
          onStyleLoadedCallback: () {
            unawaited(_onDiscoverStyleLoaded());
          },
          onUserLocationUpdated: _onUserLocationUpdated,
          // Kurzer Tipp: Tour/Trail/Ort ansehen. A/B nur in Pick-Modus
          // („Start auf Karte“ / „Ziel auf Karte“). Route-Pins: Long-Press.
          onMapClick: (point, latLng) async {
            final now = DateTime.now();
            _lastMapTap = GeoPoint(latLng.latitude, latLng.longitude);
            _lastMapTapAt = now;
            final cameraBusy = mapTapLooksLikeCameraGesture(
              now: now,
              cameraMoving: _map?.isCameraMoving ?? _cameraMoving,
              cameraMovedAt: _cameraMovedAt,
            );
            if (_surface != _Surface.plan) {
              if (cameraBusy) return;
              final tap = GeoPoint(latLng.latitude, latLng.longitude);
              _rememberMapPointer(tap);
              if (_tryInsertViaFromMapTap(tap)) return;
              final trail = await _hitTestBikeOverlay(point);
              if (trail != null) {
                await _openOverlayTrail(
                  trail,
                  at: tap,
                );
              }
              return;
            }
            if (_startAddrFocus.hasFocus || _endAddrFocus.hasFocus) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
            final placingVia = _start != null &&
                _end != null &&
                _pick != _PickMode.start &&
                _pick != _PickMode.end;
            if (placingVia && _planLineCoach) {
              setState(() => _planLineCoach = false);
              unawaited(RidePrefs.setPlanLineCoachDismissed(true));
            }
            if (!mapPlanEditorTapPlacesPin(
              editorActive: true,
              addressFieldFocused:
                  _startAddrFocus.hasFocus || _endAddrFocus.hasFocus,
              cameraMoving: _map?.isCameraMoving ?? _cameraMoving,
              cameraMovedAt: _cameraMovedAt,
              lastPinAt: _lastRoutePinAt,
              now: now,
              placingVia: placingVia || _pick == _PickMode.via,
            )) {
              return;
            }
            var p = GeoPoint(latLng.latitude, latLng.longitude);
            _rememberMapPointer(p);
            if (_tryInsertViaFromMapTap(p)) return;
            if (_pick == _PickMode.via) {
              p = _snapViaPoint(p);
            }
            final wasWithoutOrigin = !_hasRealOrigin;
            final shapedVia = _placePlanMapPoint(p);
            await _drawAll();
            await _syncMarkers();
            if (wasWithoutOrigin && _hasRealOrigin) {
              _refreshNearbyDataSources();
            }
            if (!shapedVia) {
              _scheduleCalcAbFromMap(keepLine: true);
            }
            if (_end != null &&
                _pick != _PickMode.via &&
                (_end!.lat - p.lat).abs() < 1e-4 &&
                (_end!.lng - p.lng).abs() < 1e-4) {
              unawaited(_refinePlanEndWithOverlay(point, p));
            }
          },
          onCameraIdle: () {
            final cam = _map?.cameraPosition;
            final t = cam?.target;
            if (t != null) {
              unawaited(_ensureBikeOverlay());
              final next = nextOnlineBasemapStyleUrl(
                currentStyle: _mapStyle,
                lng: t.longitude,
                lat: t.latitude,
              );
              if (next != null && next != _mapStyle && mounted) {
                setState(() => _mapStyle = next);
              }
            }
            final z = cam?.zoom ?? _mapZoom;
            final crossed = (z > kBikeOverlayVectorMaxZoom) !=
                (_mapZoom > kBikeOverlayVectorMaxZoom);
            final prevPinBand = TourFilters.browsePinZoomBand(_mapZoom);
            final nextPinBand = TourFilters.browsePinZoomBand(z);
            final pinBandChanged = prevPinBand != nextPinBand;
            final coverBandChanged =
                coverageNameZoomBand(z) != coverageNameZoomBand(_mapZoom);
            _mapZoom = z;
            if (crossed && _bikeOverlayAttached && _showTrailNetwork) {
              unawaited(_drawAll());
            } else if (coverBandChanged) {
              unawaited(_syncMarkers(coalesce: true));
              unawaited(_syncOfflineCoverageOverlay());
            } else if (pinBandChanged) {
              if (TourFilters.browsePinZoomBandNeedsFullResync(
                prevPinBand,
                nextPinBand,
              )) {
                unawaited(_syncMarkers(coalesce: true));
              } else {
                unawaited(_relabelBrowsePins());
              }
            }
            _sGradeDebounce?.cancel();
            _sGradeDebounce = Timer(const Duration(milliseconds: 450), () {
              unawaited(_refreshSGradeLive());
            });
            _viewportDebounce?.cancel();
            _viewportDebounce = Timer(const Duration(milliseconds: 800), () {
              _persistDiscoverViewport();
              if (!mounted) return;
              final cam = _map?.cameraPosition?.target;
              final gps = _userPos;
              if (gps != null && cam != null) {
                final d =
                    _distKm(gps.lat, gps.lng, cam.latitude, cam.longitude);
                if (d < 25) {
                  if (_browseAnchor != null && !_browseAnchorPinned) {
                    setState(() {
                      _browseAnchor = null;
                      _browseAnchorLabel = null;
                    });
                    _mergeCatalogNearOrigin();
                  }
                  return;
                }
              }
              final next = _usableDiscoverMapCenter;
              if (next == null) {
                final prev = _browseAnchor;
                if (prev != null &&
                    !_browseAnchorPinned &&
                    (isPlaceholderDiscoverCenter(prev.lat, prev.lng) ||
                        !isLocalDiscoverZoom(_mapZoom))) {
                  setState(() {
                    _browseAnchor = null;
                    _browseAnchorLabel = null;
                  });
                  _mergeCatalogNearOrigin();
                }
                return;
              }
              if (_browseAnchorPinned) return;
              final prev = _browseAnchor;
              if (prev != null &&
                  _distKm(prev.lat, prev.lng, next.lat, next.lng) < 8) {
                return;
              }
              setState(() {
                _browseAnchor = next;
                _browseAnchorLabel = null;
              });
              _mergeCatalogNearOrigin();
            });
            unawaited(_syncNavPuck());
          },
          // Langer Druck → Ziel (A→B). Via nur über „Via auf Karte“.
          onMapLongClick: (point, latLng) async {
            if (_surface == _Surface.detail) return;
            final now = DateTime.now();
            _lastMapTap = GeoPoint(latLng.latitude, latLng.longitude);
            if (mapTapLooksLikeCameraGesture(
              now: now,
              cameraMoving: _map?.isCameraMoving ?? _cameraMoving,
              cameraMovedAt: _cameraMovedAt,
            )) {
              return;
            }
            final p = GeoPoint(latLng.latitude, latLng.longitude);
            _rememberMapPointer(p);
            final wasWithoutOrigin = !_hasRealOrigin;
            if (_surface == _Surface.plan ||
                _shellMode == DiscoverShellMode.navigate) {
              if (mapLongPressAddsVia(
                explicitlyPickingVia: _pick == _PickMode.via,
              )) {
                _insertPlanViaAlong(_snapViaPoint(p));
                _lastRoutePinAt = now;
                await _syncMarkers();
                return;
              }
              if (planLongPressSetsDest(
                editorActive: true,
                hasStart: _start != null,
                hasEnd: _end != null,
                pickingVia: _pick == _PickMode.via,
                pickingStart: _pick == _PickMode.start,
                tapHitsLine: false,
              )) {
                _abFromBrowsePin = false;
                _pushPlanUndo();
                setState(() {
                  _end = p;
                  _endAddrCtrl.text = _l10n.discoverOnMapPlace;
                  _pick = _PickMode.none;
                });
                _pulsePlanDest();
                unawaited(HapticFeedback.lightImpact());
                unawaited(_rememberLastPlanDest());
                unawaited(_reversePlanFieldLabels());
                await _drawAll();
                await _syncMarkers();
                _scheduleCalcAbFromMap(keepLine: true);
                if (_end != null &&
                    (_end!.lat - p.lat).abs() < 1e-4 &&
                    (_end!.lng - p.lng).abs() < 1e-4) {
                  unawaited(_refinePlanEndWithOverlay(point, p));
                }
                return;
              }
              final shapedVia = _placePlanMapPoint(p);
              await _drawAll();
              await _syncMarkers();
              if (!shapedVia) {
                _scheduleCalcAbFromMap(keepLine: true);
              }
              if (_end != null &&
                  (_end!.lat - p.lat).abs() < 1e-4 &&
                  (_end!.lng - p.lng).abs() < 1e-4) {
                unawaited(_refinePlanEndWithOverlay(point, p));
              }
              return;
            }
            if (!discoverExploreMapTapOpensPlan(
              planning: false,
              picking: _pick != _PickMode.none,
            )) {
              return;
            }
            _abFromBrowsePin = true;
            final shapedBrowse = _placePlanMapPoint(p);
            final cue = discoverBrowsePinCue(
              hasStart: _start != null,
              hasEnd: _end != null,
              hasGps: _userPos != null,
            );
            _openPlan(
              status: switch (cue) {
                DiscoverBrowsePinCue.computing => _l10n.discoverEndSetComputing,
                DiscoverBrowsePinCue.waitingGpsForStart =>
                  _l10n.discoverDestSetWaitingGps,
                DiscoverBrowsePinCue.pickStart => _l10n.discoverStartSetPickEnd,
              },
              pick: _PickMode.none,
            );
            if (cue == DiscoverBrowsePinCue.computing ||
                cue == DiscoverBrowsePinCue.waitingGpsForStart) {
              _pulsePlanDest();
            }
            await _drawAll();
            await _syncMarkers();
            if (wasWithoutOrigin && _hasRealOrigin) {
              _refreshNearbyDataSources();
            }
            if (!shapedBrowse) {
              _scheduleCalcAbFromMap(keepLine: true);
            }
          },
        ),
        ),
        if (_planMapHintOnMap && _planMapHintAt != null)
          Positioned.fill(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _planHintCamTick,
                _planHintScreen,
              ]),
              builder: (context, _) {
                final pad = MediaQuery.paddingOf(context);
                final at = _planMapHintAt!;
                final String label;
                if (_planFingerAdaptingHint) {
                  label = _l10n.discoverRoutingAdapts;
                } else if (_planStopHintActive) {
                  label = _planStopHintLabel ?? _l10n.planStopSetHint;
                } else if (_planDestWaitHint &&
                    _planStopHintLabel == _l10n.discoverLastDestApplied) {
                  label = _planStopHintLabel!;
                } else {
                  label = switch (_planDestWaitCopy) {
                    PlanMapDestWaitCopy.waitingGps =>
                      _l10n.discoverDestSetWaitingGps,
                    PlanMapDestWaitCopy.firstAb =>
                      _l10n.discoverEndSetComputing,
                    PlanMapDestWaitCopy.adapting =>
                      _l10n.discoverRoutingAdapts,
                  };
                }
                return PlanMapFingerHint(
                  camera: () => _map?.cameraPosition,
                  lat: at.latitude,
                  lng: at.longitude,
                  label: label,
                  undoLabel:
                      _planUndoStack.isNotEmpty ? _l10n.planUndo : null,
                  onUndo: _planUndoStack.isNotEmpty ? _undoPlan : null,
                  avoidRightPx: kPlanMapChromeFabColPx,
                  avoidTopPx: pad.top + kPlanMapChromeFabColPx,
                  avoidBottomPx: pad.bottom,
                  nativeScreen: _planHintScreen.value,
                  firstAb: _planMapHintWideChip,
                );
              },
            ),
          ),
        if (!_styleReady) const Positioned.fill(child: MapLoadingScrim()),
      ],
    );
  }

  Widget _buildHofRideOutChoice() {
    final l10n = AppLocalizations.of(context);
    return Material(
      key: const Key('hof-ride-out-choice'),
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.96),
      elevation: 6,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.hofMapChoiceHint,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton(
              style: AppTheme.rideOutCta(height: 48),
              onPressed: _hofJustRide,
              child: Text(
                l10n.hofJustRide,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
              onPressed: _hofShowTours,
              child: Text(
                l10n.hofShowTours,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const HofWatchCard(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    final onMap = Theme.of(context).scaffoldBackgroundColor;
    final l10n = AppLocalizations.of(context);
    // Tour-Detail: Discover-Leiste aus. Zurück sitzt nur im Sheet —
    // kein zweiter Pfeil über der Karte.
    if (_tourMapFocus) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_shellMode == DiscoverShellMode.explore)
              _komootExploreChrome(onMap)
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: onMap.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    tooltip: l10n.navigateBackToExplore,
                    onPressed: () => _setShellMode(DiscoverShellMode.explore),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            if (_routingStatusNote != null &&
                !_suppressDemoGeometryBanner(_routingStatusNote!)) ...[
              const SizedBox(height: AppSpacing.xs),
              _mapNotePill(_routingStatusNote!),
            ],
          ],
        ),
      ),
    );
  }

  void _rememberExploreChromeHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box =
          _exploreChromeKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final h = box.size.height;
      if ((h - _exploreChromeHeight).abs() < 1) return;
      setState(() => _exploreChromeHeight = h);
    });
  }

  Widget _planGeocodeHitTile(GeocodeHit hit, {required bool recent}) {
    final l10n = _l10n;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ChromeGlyph(recent ? 'recent' : 'karte', size: 18),
      title: Text(hit.label, style: const TextStyle(fontSize: 13)),
      onTap: () => unawaited(_applyAddressHit(hit)),
      onLongPress: () => _addGeocodeHitAsVia(hit),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _planDestFlagTooltip(l10n),
            icon: const ChromeGlyph('flag', size: 18),
            onPressed: () => unawaited(_routeToGeocodeHit(hit)),
          ),
          if (_start != null) _planHitOverflow(hit, l10n),
        ],
      ),
    );
  }

  Widget _planHitOverflow(GeocodeHit hit, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      padding: EdgeInsets.zero,
      iconSize: 18,
      splashRadius: 18,
      icon: const Icon(Icons.more_horiz),
      onSelected: (v) {
        if (v == 'start') unawaited(_routeToGeocodeHitAsStart(hit));
        if (v == 'via') _addGeocodeHitAsVia(hit);
      },
      itemBuilder: (_) => [
        if (_start != null)
          PopupMenuItem(
            value: 'start',
            child: Text(l10n.discoverReplaceStart),
          ),
        if (_start != null && _end != null)
          PopupMenuItem(
            value: 'via',
            child: Text(l10n.discoverPlaceOnRoute),
          ),
      ],
    );
  }

  Widget _explorePlaceHitChip(GeocodeHit hit, {bool recent = false}) {
    final l10n = _l10n;
    final extra = _start != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionChip(
          visualDensity: VisualDensity.compact,
            avatar: recent ? const ChromeGlyph('recent', size: 16) : null,
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              hit.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onPressed: () => unawaited(_flyBrowsePlace(hit)),
        ),
        IconButton(
          tooltip: _planDestFlagTooltip(l10n),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => unawaited(_routeToGeocodeHit(hit)),
          icon: const ChromeGlyph('flag', size: 18),
        ),
        if (extra) _planHitOverflow(hit, l10n),
      ],
    );
  }

  Widget _exploreSearchField(AppLocalizations l10n) {
    return Semantics(
      label: l10n.discoverSearchHint,
      textField: true,
      child: TextField(
        controller: _exploreSearchCtrl,
        textInputAction: TextInputAction.search,
        maxLines: 1,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: _submitBrowseSearch,
        onChanged: (v) {
          setState(() {
            _exploreQuery = v;
            if (v.trim().isNotEmpty &&
                DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent)) {
              unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.half));
            }
          });
          _schedulePlaceHits(v);
        },
        style: const TextStyle(overflow: TextOverflow.ellipsis),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.chipIdle.withValues(alpha: 0.55),
          prefixIcon: const ChromeGlyph(
            'search',
            size: 20,
            color: AppColors.muted,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          hintText: l10n.discoverSearchHint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _explorePlanCta(AppLocalizations l10n) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.chrome,
        foregroundColor: AppColors.onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      onPressed: () {
        setState(() {
          _vias.clear();
          _abFromBrowsePin = false;
          if (_start == null) {
            final o = _riderOrigin;
            if (o != null) {
              _start = o;
              _startAddrCtrl.text = _l10n.discoverMyPosition;
            }
          }
        });
        _setShellMode(
          DiscoverShellMode.navigate,
          pick: _PickMode.end,
        );
      },
      child: Text(
        l10n.planRouteCta,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  /// Komoot-Chrome: Suche + „Route planen“, darunter Umkreis · Filter · Karteninhalt.
  Widget _komootExploreChrome(Color onMap) {
    _rememberExploreChromeHeight();
    final l10n = AppLocalizations.of(context);
    final selectedAway = _selectedAwayKm;
    final aroundKm = DiscoverExploreChromeLogic.aroundDisplayKm(
      _maxDistanceKm,
      selectedAwayKm: selectedAway,
    );
    final aroundSet = DiscoverExploreChromeLogic.aroundIsSet(
      _maxDistanceKm,
      selectedAwayKm: selectedAway,
    );
    final aroundUsesAway = DiscoverExploreChromeLogic.usesSelectedAway(
      _maxDistanceKm,
      selectedAway,
    );
    final hasSelection = DiscoverExploreChromeLogic.showIdlePeek(
      _hofPinLoopId ?? _selectedTourId,
    );
    final compact = DiscoverExploreChromeLogic.compactExploreChrome(
      hasSelection: hasSelection,
      searching: _exploreQuery.trim().isNotEmpty,
    );
    final filterIconOnly = DiscoverExploreChromeLogic.filterChipIconOnly(
      compact: compact,
      aroundUsesAway: aroundUsesAway,
    );
    final stackSearch = DiscoverExploreChromeLogic.stackSearchOnOwnRow(
      MediaQuery.sizeOf(context).width,
    );
    final showsPlan = DiscoverExploreChromeLogic.chromeShowsPlanCta(
      hasSelection,
    );
    return Material(
      key: _exploreChromeKey,
      color: onMap.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppRadius.card),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stackSearch) ...[
              _exploreSearchField(l10n),
              if (showsPlan) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _explorePlanCta(l10n),
                ),
              ],
            ] else
              Row(
                children: [
                  Expanded(child: _exploreSearchField(l10n)),
                  if (showsPlan) ...[
                    const SizedBox(width: 8),
                    _explorePlanCta(l10n),
                  ],
                ],
              ),
            if (_placeSearchNeedNet) ...[
              const SizedBox(height: 6),
              Text(
                l10n.discoverSearchNeedNet,
                key: const Key('discover-search-need-net'),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.muted,
                ),
              ),
            ],
            if (_placeHits.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _placeHits.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) => _explorePlaceHitChip(_placeHits[i]),
                ),
              ),
            ] else if (_exploreQuery.trim().length < 2 &&
                _geocodeRecents.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l10n.discoverRecently,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _geocodeRecents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) => _explorePlaceHitChip(
                    _geocodeRecents[i],
                    recent: true,
                  ),
                ),
              ),
            ],
            if (_browseAnchor != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  key: const Key('discover-back-to-gps'),
                  avatar: const ChromeGlyph('locate', size: 16),
                  label: Text(
                    _browseAnchorLabel ?? l10n.discoverMapArea,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  visualDensity:
                      const VisualDensity(horizontal: -1, vertical: -2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_navProfileChipVisible) ...[
                          _profileChip(),
                          const SizedBox(width: 6),
                        ],
                        ActionChip(
                          key: const Key('discover-around-chip'),
                          avatar: ChromeGlyph(
                            'locate',
                            size: 15,
                            color: aroundSet
                                ? AppColors.onAccent
                                : AppColors.chipIdleText,
                          ),
                          label: Text(
                            aroundUsesAway
                                ? l10n.discoverAroundAwayKm(aroundKm)
                                : aroundSet
                                    ? l10n.filterAroundKm(aroundKm)
                                    : l10n.discoverAroundIdle,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: aroundSet
                                  ? AppColors.onAccent
                                  : AppColors.chipIdleText,
                            ),
                          ),
                          backgroundColor: aroundSet
                              ? AppColors.accent
                              : AppColors.chipIdle.withValues(alpha: 0.55),
                          onPressed: () => unawaited(_openAroundSheet()),
                          visualDensity:
                              const VisualDensity(horizontal: -1, vertical: -2),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: aroundSet
                                ? AppColors.accent
                                : AppColors.border.withValues(alpha: 0.9),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          key: const Key('discover-filter-chip'),
                          tooltip: l10n.filter,
                          avatar: ChromeGlyph(
                            'filter',
                            size: 15,
                            color: _activeFilterCount > 0
                                ? AppColors.onAccent
                                : AppColors.chipIdleText,
                          ),
                          label: Text(
                            filterIconOnly
                                ? (_activeFilterCount > 0
                                    ? '$_activeFilterCount'
                                    : '')
                                : (_activeFilterCount > 0
                                    ? '${l10n.filter} $_activeFilterCount'
                                    : l10n.filter),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _activeFilterCount > 0
                                  ? AppColors.onAccent
                                  : AppColors.chipIdleText,
                            ),
                          ),
                          labelPadding:
                              filterIconOnly && _activeFilterCount <= 0
                                  ? EdgeInsets.zero
                                  : null,
                          backgroundColor: _activeFilterCount > 0
                              ? AppColors.accent
                              : AppColors.chipIdle.withValues(alpha: 0.55),
                          onPressed: () => unawaited(_openFilterSheet()),
                          visualDensity:
                              const VisualDensity(horizontal: -1, vertical: -2),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: _activeFilterCount > 0
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _mapContentsChip(l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapNotePill(String text) {
    return Material(
      color: AppColors.charcoal.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: 4,
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRideBar() {
    final r = _computed!;
    final sel = _selectedTourId != null ? _tourById(_selectedTourId) : null;
    // What Losfahren will navigate: selected tour track/cache, else `_computed`
    // (hybrid Anfahrt+Loop is open — must not keep a lying „Rundkurs“ label).
    List<List<double>>? navTrack;
    final cached = sel != null ? _routedLoopCache[sel.id] : null;
    if (sel != null && (_isLoop(sel) || sel.hasTrack)) {
      if (cached != null && cached.length >= 4) {
        navTrack = [
          for (final p in cached) [p.lng, p.lat]
        ];
      } else {
        navTrack = sel.trackLngLat;
      }
    }
    navTrack ??= [
      for (final p in r.coordinates) [p.lng, p.lat],
    ];
    final isLoop = navGeometryIsLoop(navTrack);
    final title = _label ?? sel?.name ?? 'Route';
    final km = (r.distanceM / 1000).toStringAsFixed(1);
    final mins = (r.durationS / 60).round();
    final loopTrack = isLoop ? navTrack : null;
    final l10n = AppLocalizations.of(context);
    final meta = [
      if (isLoop)
        l10n.loopLabel
      else if (routeShapeOf(navTrack) == RouteShape.pointToPoint)
        l10n.rideBarPointToPoint
      else
        l10n.rideBarRoute,
      '$km km',
      _fmtRideDuration(mins, l10n),
      if (_elevationSummary != null) _elevationSummary!,
    ].join(' · ');

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 180) {
          setState(() => _rideBarExpanded = false);
        } else if (v < -180) {
          setState(() => _rideBarExpanded = true);
        }
      },
      child: Material(
        color: AppColors.overlay.withValues(alpha: 0.90),
        elevation: 6,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _rideBarExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.s,
                    AppSpacing.s,
                    AppSpacing.s,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _rideBarExpanded = false),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.rideBarCollapseHint,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (isLoop)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.s,
                              ),
                              child: _LoopMiniMap(
                                size: 40,
                                stroke: AppColors.chrome,
                                fill: AppColors.sage.withValues(alpha: 0.20),
                                showStart: true,
                                track: loopTrack,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meta,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.save,
                            onPressed: _saveCurrent,
                            visualDensity: VisualDensity.compact,
                            icon: const ChromeGlyph(
                              'merken',
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.chrome,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                              ),
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                unawaited(_startRide(suggestion: sel)),
                            icon: const ChromeGlyph(
                              'play',
                              size: 18,
                              color: AppColors.onAccent,
                            ),
                            label: Text(l10n.rideBarStart),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : InkWell(
                  onTap: () => setState(() => _rideBarExpanded = true),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$title · $meta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.rideBarExpandHint,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Unteres Panel — beherbergt alle drei Zustände. Der Wechsel ist eine
  /// Bewegung (Panels fahren von unten übereinander), kein Tab- oder
  /// Screen-Sprung wie vorher beim Tour-Detail.
  ///
  /// [scrollController] kommt vom Discover-[DraggableScrollableSheet] und
  /// verbindet Listen-Scroll mit Sheet-Drag.
  Widget _buildBottomPanel({ScrollController? scrollController}) {
    final Widget panelChild;
    if (_surface == _Surface.detail) {
      panelChild = KeyedSubtree(
        key: ValueKey('panel-detail-$_detailId'),
        child: _buildDetailPanel(scrollController: scrollController),
      );
    } else if (_shellMode == DiscoverShellMode.navigate ||
        _surface == _Surface.plan) {
      panelChild = KeyedSubtree(
        key: const ValueKey('panel-navigate'),
        child: _buildPlanPanel(scrollController: scrollController),
      );
    } else if (_shellMode == DiscoverShellMode.mine) {
      panelChild = KeyedSubtree(
        key: const ValueKey('panel-mine'),
        child: _buildMinePanel(scrollController: scrollController),
      );
    } else {
      panelChild = KeyedSubtree(
        key: const ValueKey('panel-discover'),
        child: _buildDiscoverPanel(scrollController: scrollController),
      );
    }
    return Material(
      elevation: 10,
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: !(_planSheetActive && _planSheetIsPeek),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // Default StackFit.loose + center can leave flex children with
          // unbounded width during the cross-fade → BoxConstraints(w=Infinity)
          // on Tourenkarten Rows. Expand to the panel's tight size instead.
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(anim);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: panelChild,
        ),
      ),
    );
  }

  Widget _panelHandle({String? semanticsLabel}) {
    final l10n = AppLocalizations.of(context);
    final planning = _planSheetActive;
    final closed = !planning &&
        DiscoverBrowseSheetSnaps.isClosed(_discoverSheetExtent);
    final full = planning
        ? PlanSheetSnaps.isFull(_planSheetExtent)
        : DiscoverBrowseSheetSnaps.isFull(_discoverSheetExtent);
    final kicker = planning
        ? (full ? l10n.browseMap : l10n.planRouteTitle)
        : (closed ? l10n.mappeKicker : null);
    final showKicker = closed || (planning && full);
    final label = [
      if (kicker != null) kicker,
      semanticsLabel ??
          (planning ? l10n.sheetDragHandleNavigate : l10n.sheetDragHandle),
    ].join('. ');
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        key: const Key('discover-sheet-handle'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (planning) {
            unawaited(
              _snapPlanSheet(
                PlanSheetSnaps.handleTapTarget(
                  _planSheetExtent,
                  peekSnap: _planPeekSnap,
                ),
              ),
            );
            return;
          }
          unawaited(
            _snapDiscoverSheet(
              DiscoverBrowseSheetSnaps.handleTapTarget(
                _discoverSheetExtent,
                hasSelection: _hasExploreSelection,
              ),
            ),
          );
        },
        child: SizedBox(
          height: showKicker ? 48 : 36,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (showKicker && kicker != null) ...[
                const SizedBox(height: 6),
                Text(
                  kicker,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.muted,
                  ),
                ),
              ] else ...[
                Icon(
                  full ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  size: 16,
                  color: AppColors.muted.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Demo-Geometrie / Näherung banners — killed on prod + Rundkurs path (S25).
  bool _suppressDemoGeometryBanner(String text) {
    final t = text.toLowerCase();
    final isDemoGeom =
        t.contains('demo-geometrie') || t.contains('demo geometrie');
    // Prod path: never show Demo-Geometrie chrome.
    if (isDemoGeom && !AppConfig.allowDemoContent) return true;
    if (_loopOnlyActive) {
      return isDemoGeom ||
          _statusIsApprox ||
          t.contains('näherung') ||
          t.contains('naeherung') ||
          t.contains('live-routing nicht') ||
          t.contains('live routing');
    }
    return false;
  }

  Widget _panelMessages() {
    final status = _status;
    final hideStaleNearby =
        status == _l10n.discoverLocationReady && _tours.isNotEmpty;
    // Subtitle already shows waiting-GPS / tap-start — don't repeat below.
    final hideWaitingGpsDup = status == _l10n.discoverDestSetWaitingGps &&
        _end != null &&
        _start == null;
    final hideStatus = hideStaleNearby ||
        hideWaitingGpsDup ||
        (status != null && _suppressDemoGeometryBanner(status));
    if (_error == null &&
        (status == null || hideStatus) &&
        _planDragAlongLabel == null) {
      return const SizedBox.shrink();
    }
    // Warm-Routing ist Hintergrund — das Panel-Subtitle reicht.
    final hideWarm = _statusIsWarm;
    if (_error == null && hideWarm && _planDragAlongLabel == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          if (_error == _l10n.discoverBrowseNeedsNetwork)
            Align(
              alignment: Alignment.centerLeft,
              child: _browseLoadMapPackButton(),
            ),
          if (_error == _l10n.discoverViasNeedNet && _vias.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: _dropViasAndGoButton(),
            ),
          if (status != null && !hideStatus)
            Text(
              status,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          if (_planDragAlongLabel != null)
            Text(
              _planDragAlongLabel!,
              key: const Key('plan-drag-along'),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// Produkt-Default Discover: alle Dauer, alle Formen, kein Sport-Zwang.
  /// Distanz sitzt am Umkreis — hier nur Sheet-Filter.
  bool get _sheetFiltersAtDefaults =>
      _minutes == DiscoverExploreChromeLogic.defaultDurationMin &&
      !_matchTourDuration &&
      _formFilter == TourFormKey.all &&
      _sportFilter.isEmpty &&
      _surfaceFilter == null &&
      _effortFilter == null &&
      _elevationFilter == null &&
      _maxLengthKm == null &&
      _trailScaleFilter.isEmpty &&
      _activeTraits.isEmpty;

  bool get _filtersAtDefaults =>
      _sheetFiltersAtDefaults && _maxDistanceKm == null;

  /// Badge am Filter-Chip: Abweichungen vom Default. Distanz zählt am Umkreis.
  int get _activeFilterCount {
    var n = 0;
    if (_matchTourDuration && _minutes > 0) {
      n++;
    }
    if (_formFilter != TourFormKey.all) n++;
    if (_sportFilter.isNotEmpty) n++;
    if (_surfaceFilter != null) n++;
    if (_effortFilter != null) n++;
    if (_elevationFilter != null) n++;
    if (_maxLengthKm != null) n++;
    if (_trailScaleFilter.isNotEmpty) n++;
    if (_activeTraits.isNotEmpty) n += _activeTraits.length;
    return n;
  }

  void _resetSheetFilters() {
    setState(() {
      _minutes = DiscoverExploreChromeLogic.defaultDurationMin;
      _matchTourDuration = false;
      _formFilter = TourFormKey.all;
      _sportFilter.clear();
      _surfaceFilter = null;
      _effortFilter = null;
      _elevationFilter = null;
      _maxLengthKm = null;
      _trailScaleFilter.clear();
      _activeTraits.clear();
    });
    unawaited(_drawAll());
  }

  void _resetAround() {
    setState(() => _maxDistanceKm = null);
    unawaited(_drawAll());
  }

  void _resetFilters() {
    setState(() {
      _minutes = DiscoverExploreChromeLogic.defaultDurationMin;
      _matchTourDuration = false;
      _formFilter = TourFormKey.all;
      _sportFilter.clear();
      _surfaceFilter = null;
      _effortFilter = null;
      _elevationFilter = null;
      _maxDistanceKm = null;
      _maxLengthKm = null;
      _trailScaleFilter.clear();
      _activeTraits.clear();
    });
    unawaited(_drawAll());
  }

  /// Kurz: nur Distanz-Max. Filter bleibt die andere Fläche.
  Future<void> _openAroundSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            void update(VoidCallback fn) {
              setState(fn);
              setModal(() {});
            }

            return SafeArea(
              child: Padding(
                key: const Key('discover-around-sheet'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  0,
                  AppSpacing.l,
                  AppSpacing.m,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.discoverAroundIdle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip:
                              MaterialLocalizations.of(ctx).closeButtonTooltip,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final d in TourFilters.distanceMaxChips)
                          FilterChip(
                            label: Text(l10n.tourDistanceMaxChip(d.id)),
                            selected: _maxDistanceKm == d.id,
                            onSelected: (sel) => update(
                              () => _maxDistanceKm = sel ? d.id : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                            onPressed: _maxDistanceKm == null
                                ? null
                                : () {
                                    _resetAround();
                                    setModal(() {});
                                  },
                            child: Text(l10n.filterReset),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.chrome,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              l10n.filterShowTours(_filtered.length),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() {});
      unawaited(_drawAll());
    }
  }

  bool get _mapContentsCustomized =>
      DiscoverExploreChromeLogic.mapContentsCustomized(
        toursOn: _showToursLayer,
        trailsOn: _showTrailsLayer,
        waysOn: _showBikeWaysLayer,
        hillshadeOn: _showHillshade,
        placesOn: _showPlacesLayer,
        heatOn: _showHeatLayer,
        heatConsent: _heatmapConsent,
      );

  Widget _mapContentsChip(AppLocalizations l10n) {
    final customized = _mapContentsCustomized;
    final routingOn = _offlineRoutingReady;
    final pack = _offlinePackLabel?.trim() ?? '';
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final caption = routingOn && pack.isNotEmpty && !narrow
        ? coverageChipCaption(pack)
        : null;
    final tooltip = routingOn && pack.isNotEmpty
        ? l10n.offlineCoverageLabelFor(pack, packId: _offlinePackId)
        : routingOn
            ? l10n.offlineRoutingOn
            : l10n.discoverMapContentsTitle;
    final fill = customized
        ? AppColors.accent
        : routingOn
            ? AppColors.sage.withValues(alpha: 0.35)
            : AppColors.chipIdle.withValues(alpha: 0.55);
    final ink = customized
        ? AppColors.onAccent
        : routingOn
            ? AppColors.sageOnDark
            : AppColors.chipIdleText;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            side: BorderSide(
              color: customized
                  ? AppColors.accent
                  : routingOn
                      ? AppColors.sageOnDark
                      : AppColors.border.withValues(alpha: 0.9),
            ),
          ),
          child: InkWell(
            key: const Key('discover-map-contents'),
            onTap: () => unawaited(_openMapContentsSheet()),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 40,
                maxWidth: caption == null
                    ? 40
                    : (MediaQuery.sizeOf(context).width < 380 ? 100 : 128),
                minHeight: 40,
                maxHeight: 40,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: caption == null ? 0 : 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChromeGlyph(
                      routingOn && !customized ? 'check' : 'layers',
                      size: 20,
                      color: ink,
                    ),
                    if (caption != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMapContentsSheet() async {
    final tool = await showModalBottomSheet<DiscoverMapContentsTool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            void sync(VoidCallback fn) {
              setState(fn);
              setModal(() {});
            }

            return DiscoverMapContentsSheet(
              toursOn: _showToursLayer,
              trailsOn: _showTrailsLayer,
              waysOn: _showBikeWaysLayer,
              farmTracksOn: _showFarmTracksLayer,
              hillshadeOn: _showHillshade,
              placesOn: _showPlacesLayer,
              heatOn: _heatmapConsent && _showHeatLayer,
              heatLocked: !_heatmapConsent,
              offlineReady: _offlineRoutingReady,
              offlinePackLabel: _offlinePackLabel,
              offlinePackId: _offlinePackId,
              offlineOverviewReady: _offlineOverviewReady,
              browseOnline: _browseOnline,
              onTours: (v) {
                sync(() => _showToursLayer = v);
                unawaited(_drawAll());
                unawaited(_syncMarkers());
              },
              onTrails: (v) {
                sync(() {
                  _showTrailsLayer = v;
                  _showTrailNetwork = v || _showBikeWaysLayer;
                });
                unawaited(_refreshExploreOverlay());
                unawaited(_drawAll());
              },
              onWays: (v) {
                sync(() {
                  _showBikeWaysLayer = v;
                  _showTrailNetwork = _showTrailsLayer || v;
                });
                unawaited(_refreshExploreOverlay());
                unawaited(_drawAll());
              },
              onFarmTracks: (v) {
                sync(() => _showFarmTracksLayer = v);
                unawaited(RidePrefs.setShowFarmTracks(v));
                unawaited(_syncBikeOverlayVisibility());
              },
              onHillshade: (v) {
                sync(() => _showHillshade = v);
                unawaited(_applyHillshadeNow());
              },
              onPlaces: (v) {
                sync(() => _showPlacesLayer = v);
                unawaited(_syncMarkers());
              },
              onHeat: () {
                if (!_heatmapConsent) {
                  Navigator.pop(ctx);
                  unawaited(_onHeatLayerTapped());
                  return;
                }
                sync(() => _showHeatLayer = !_showHeatLayer);
                unawaited(_drawAll());
              },
              onTool: (tool) => Navigator.pop(ctx, tool),
            );
          },
        );
      },
    );
    if (!mounted || tool == null) return;
    switch (tool) {
      case DiscoverMapContentsTool.collections:
        _collectionsSheet();
      case DiscoverMapContentsTool.photos:
        _openTrailView();
      case DiscoverMapContentsTool.offline:
        unawaited(
          _openOfflineMaps(
            focusPackId: _navigateOfflinePack?.id ?? _offlinePackId,
          ),
        );
    }
  }

  /// Die zwölf Dauer-Chips aus der Kopfzeile leben jetzt hier — sichtbar nur,
  /// wenn man sie braucht. Das war der Hauptgrund für die überladene Leiste.
  /// Distanz nicht hier: die hat der Umkreis-Chip.
  Future<void> _openFilterSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            void update(VoidCallback fn) {
              setState(fn);
              setModal(() {});
            }

            Widget group(String title, List<Widget> chips) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(spacing: 6, runSpacing: 6, children: chips),
                  const SizedBox(height: AppSpacing.m),
                ],
              );
            }

            final sheetH = MediaQuery.sizeOf(ctx).height * 0.78;
            return SafeArea(
              child: SizedBox(
                key: const Key('discover-filter-sheet'),
                height: sheetH,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.l,
                          0,
                          AppSpacing.l,
                          AppSpacing.m,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.filter,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: MaterialLocalizations.of(ctx)
                                      .closeButtonTooltip,
                                  onPressed: () => Navigator.pop(ctx),
                                  icon: const Icon(Icons.close),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            // Primärfilter auch hier spiegeln (eine Semantik), ohne
                            // Jargon-„Band"-Chip — Dauer-Auswahl = Liste filtern.
                            group(l10n.filterDurationLens, [
                              for (final p in DurationLens.presets)
                                FilterChip(
                                  label:
                                      Text(l10n.durationChipLabel(p.minutes)),
                                  selected: _minutes == p.minutes &&
                                      (p.minutes == 0
                                          ? !_matchTourDuration
                                          : _matchTourDuration),
                                  onSelected: (_) => update(() {
                                    _minutes = p.minutes;
                                    _matchTourDuration = p.minutes > 0;
                                  }),
                                ),
                            ]),
                            group(l10n.filterForm, [
                              for (final f in TourFilters.formFilterChips)
                                Tooltip(
                                  message: l10n.tourFormHint(f),
                                  child: FilterChip(
                                    label: Text(l10n.tourFormChip(f)),
                                    selected: _formFilter == f,
                                    onSelected: (sel) {
                                      update(() {
                                        _formFilter = sel ? f : TourFormKey.all;
                                        if (f == TourFormKey.downhill && sel) {
                                          _showTrailNetwork = true;
                                          _bikeOverlayExtra.add(
                                            BikeOverlayClass.mtb,
                                          );
                                        }
                                      });
                                      if (_formFilter == TourFormKey.loop) {
                                        unawaited(_ensureLoopMapHonesty());
                                      } else {
                                        unawaited(_drawAll());
                                      }
                                    },
                                  ),
                                ),
                            ]),
                            group(l10n.filterBikeType, [
                              for (final s in TourFilters.sportFilterChips)
                                FilterChip(
                                  label: Text(
                                    s == TourSportKey.dh
                                        ? l10n.filterSportDh
                                        : l10n.tourSportChip(s),
                                  ),
                                  selected: _sportFilter.contains(s),
                                  avatar: CircleAvatar(
                                    backgroundColor: Color(
                                      int.parse(
                                        'FF${DiscoverMapLineStyle.ribbonForTour(sport: s, scale: TrailDifficulty.open, selected: true, routed: true).substring(1)}',
                                        radix: 16,
                                      ),
                                    ),
                                    radius: 6,
                                  ),
                                  onSelected: (sel) => update(() {
                                    if (sel) {
                                      _sportFilter.add(s);
                                    } else {
                                      _sportFilter.remove(s);
                                    }
                                  }),
                                ),
                            ]),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.m),
                              child: Text(
                                l10n.filterBikeTypeHonesty,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (TourFilters.filterSheetShowsSScale(
                              mtbOverlayFamily:
                                  _overlayFamily == BikeOverlayFamily.mtb,
                              sportFilter: _sportFilter,
                              form: _formFilter,
                            ))
                              group(l10n.filterSingletrail, [
                                for (final d in kTrailScaleFilterChips)
                                  Tooltip(
                                    message: l10n.filterSingletrailHint,
                                    child: FilterChip(
                                      label: Text(l10n.trailDifficultyTech(d)),
                                      selected: _trailScaleFilter.contains(d),
                                      avatar: CircleAvatar(
                                        backgroundColor: Color(
                                          int.parse(
                                            'FF${trailDifficultyColor(d).substring(1)}',
                                            radix: 16,
                                          ),
                                        ),
                                        radius: 6,
                                      ),
                                      onSelected: (sel) {
                                        update(() {
                                          if (sel) {
                                            _trailScaleFilter.add(d);
                                            _showTrailNetwork = true;
                                            _bikeOverlayExtra.add(
                                              BikeOverlayClass.mtb,
                                            );
                                          } else {
                                            _trailScaleFilter.remove(d);
                                          }
                                        });
                                        unawaited(_drawAll());
                                      },
                                    ),
                                  ),
                              ]),
                            group(l10n.filterTourLength, [
                              for (final d in TourFilters.distanceMaxChips)
                                FilterChip(
                                  label: Text(l10n.tourDistanceMaxChip(d.id)),
                                  selected: _maxLengthKm == d.id,
                                  onSelected: (sel) => update(
                                    () => _maxLengthKm = sel ? d.id : null,
                                  ),
                                ),
                            ]),
                            group(l10n.filterSurfaceGroup, [
                              for (final s in TourFilters.availableSurfaces(
                                _tours.map((t) => t.surface),
                              ))
                                Tooltip(
                                  message: l10n.tourSurfaceHint(s),
                                  child: FilterChip(
                                    label: Text(l10n.tourSurfaceChip(s)),
                                    selected: _surfaceFilter == s,
                                    onSelected: (sel) => update(
                                      () => _surfaceFilter = sel ? s : null,
                                    ),
                                  ),
                                ),
                            ]),
                            group(l10n.filterExertion, [
                              for (final e in TourEffortKey.values)
                                Tooltip(
                                  message: l10n.tourEffortHint(e),
                                  child: FilterChip(
                                    label: Text(l10n.tourEffortChip(e)),
                                    selected: _effortFilter == e,
                                    onSelected: (sel) => update(
                                      () => _effortFilter = sel ? e : null,
                                    ),
                                  ),
                                ),
                            ]),
                            group(l10n.filterElevation, [
                              for (final hm in TourElevationKey.values)
                                FilterChip(
                                  label: Text(l10n.tourElevationChip(hm)),
                                  selected: _elevationFilter == hm,
                                  onSelected: (sel) => update(
                                    () => _elevationFilter = sel ? hm : null,
                                  ),
                                ),
                            ]),
                            group(l10n.filterTrailNetwork, [
                              FilterChip(
                                label: Text(l10n.filterNetworkOn),
                                selected: _showTrailNetwork,
                                onSelected: (v) {
                                  update(() {
                                    _showTrailNetwork = v;
                                    _showTrailsLayer = v;
                                    _showBikeWaysLayer = v;
                                  });
                                  unawaited(_refreshExploreOverlay());
                                  unawaited(_drawAll());
                                },
                              ),
                              FilterChip(
                                label: Text(l10n.myRoutesShowOnMap),
                                selected: _showOwnTracks,
                                onSelected: (v) {
                                  update(() => _showOwnTracks = v);
                                  unawaited(_drawAll());
                                },
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    // Sticky CTA wie Komoot: Zurücksetzen + Ergebnisse.
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.l,
                        AppSpacing.s,
                        AppSpacing.l,
                        AppSpacing.m,
                      ),
                      decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              onPressed: _sheetFiltersAtDefaults
                                  ? null
                                  : () {
                                      _resetSheetFilters();
                                      setModal(() {});
                                    },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.filterReset),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.chrome,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child:
                                  Text(l10n.filterShowTours(_filtered.length)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() {});
      unawaited(_drawAll());
    }
  }

  /// Profil-Auswahl als Chip — eine Stelle für beide Zustände statt zweier
  /// getrennter Dropdowns in Kopfzeile und Planen.
  Widget _discoverMapFab({
    required Key key,
    required String tooltip,
    required String mark,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    double size = 48,
  }) {
    return Material(
      color: AppColors.charcoal,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: ChromeGlyph(
              mark,
              size: size < 48 ? 18 : 22,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _planRibbonLegend(AppLocalizations l10n, {bool compact = false}) {
    Widget swatch(Color color, String label) {
      final dot = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
      if (compact) {
        return Semantics(
          label: label,
          child: Tooltip(
            message: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: dot,
            ),
          ),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A120C),
            ),
          ),
        ],
      );
    }

    return Material(
      color: const Color(0xE6F4F1EC),
      elevation: 3,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: 6,
        ),
        child: Wrap(
          spacing: compact ? 6 : 10,
          runSpacing: 4,
          children: [
            if (_planLegendKinds.contains('asphalt'))
              swatch(const Color(0xFF5C8FBF), l10n.filterSurfaceAsphalt),
            if (_planLegendKinds.contains('gravel'))
              swatch(const Color(0xFFE0B04A), l10n.filterSurfaceGravel),
            if (_planLegendKinds.contains('trail'))
              swatch(const Color(0xFFC47B3A), l10n.filterSurfaceTrail),
            if (_planLegendKinds.contains('unknown'))
              swatch(const Color(0xFFFF6A00), l10n.planMapUnknown),
            if (_planLegendKinds.contains('steep'))
              swatch(const Color(0xFFC2410C), l10n.planMapSteep),
          ],
        ),
      ),
    );
  }

  Widget _discoverLocateFab() {
    return MapLocateFab(
      key: const Key('nav-puck-discover-locate'),
      tooltip: AppLocalizations.of(context).discoverLocateLongPress,
      active: true,
      onTap: () => unawaited(_locate(fresh: true)),
      onLongPress: () => unawaited(_openNavPuckPicker()),
    );
  }

  List<RoutingProfile> get _navProfileMenu {
    final store = ref.read(userProfileStoreProvider);
    return discoverProfileMenuForSports(
      primary: store.preferredSport,
      sports: store.preferredSports,
    );
  }

  bool get _navProfileChipVisible =>
      discoverNavProfileChipVisible(_navProfileMenu);

  Widget _profileChip() {
    final items = _navProfileMenu;
    return PopupMenuButton<RoutingProfile>(
      key: const Key('discover-nav-profile-chip'),
      tooltip: _l10n.discoverChipTooltip,
      initialValue: _profile,
      onSelected: (p) {
        setState(() {
          _profile = discoverNavProfile(p);
        });
        final c = _map;
        if (c != null && _bikeOverlayAttached) {
          unawaited(_syncBikeOverlayVisibility());
        }
        if (_surface == _Surface.plan ||
            _shellMode == DiscoverShellMode.navigate) {
          if (_start != null && _end != null) {
            unawaited(_calcAb(keepLine: true, refitPins: false));
          } else {
            _maybeWarmLiveRouting(_userPos ?? _start);
          }
        } else {
          unawaited(_fetchPublicCatalog());
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<RoutingProfile>(
          enabled: false,
          child: Text(
            routingProfileSharesGhBasicBike(_profile)
                ? _l10n.discoverNavHonestyBike
                : _l10n.discoverNavHonestyFoot,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        for (final p in items)
          PopupMenuItem(
            value: p,
            child: Text(_l10n.discoverChipLabel(p)),
          ),
      ],
      child: Chip(
        avatar: const RadNavMark(
          color: AppColors.chipIdleText,
          size: 15,
        ),
        label: Text(
          _l10n.discoverChipLabel(_profile),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        backgroundColor: AppColors.chipIdle.withValues(alpha: 0.55),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Tour antippen → Strecke sofort auf der Karte (Peek), Detail optional.
  /// Auswahl bleibt in der Sheet-Liste oben, auch nach Aufziehen.
  Future<void> _previewTourOnMap(_RouteSuggestion r) async {
    setState(() {
      _selectedTourId = r.id;
      _listBrowseMode = false;
      _rideBarExpanded = true;
    });
    unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.peek));
    if (r.hasTrack) {
      await _drawSeedLoopPreview(r);
      if (!mounted) return;
      try {
        await _map?.animateCamera(
          CameraUpdate.newLatLngZoom(r.center, 12.5),
        );
      } catch (_) {}
    } else {
      // Pin-only: drop leftover preview from the previous tour.
      if (isTourPreviewLine(_computed?.engine)) {
        setState(() {
          _computed = null;
          _approach = null;
          _tourLayer = null;
          _label = null;
        });
        await _drawAll();
      }
      await _openDetail(r.id, r.center);
    }
  }

  /// Der eine Discover-Zustand: Steuerzeile, dann die Tourenliste.
  /// Heading-Karten bleiben aus der Liste — keine N/O/SW-Touren.
  ///
  /// Mit [scrollController] vom Sheet: Drag am Handle/Liste bewegt Snaps;
  /// Primärchips (Dauer · Rundkurs · Asphalt · Distanz) bleiben sportneutral.
  Widget _buildDiscoverPanel({ScrollController? scrollController}) {
    final peek = DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent) ||
        DiscoverBrowseSheetSnaps.isClosed(_discoverSheetExtent);
    final sections = <Widget>[
      ..._toursSection(),
    ];

    final header = const SizedBox.shrink();

    final pinnedId = _hofPinLoopId ?? _selectedTourId;
    final peekId = CompassHeading.peekTourId(
      selectedTourId: pinnedId,
      firstFilteredTourId: _filtered.isNotEmpty ? _filtered.first.id : null,
    );
    final peekTour = peekId != null ? _tourById(peekId) : null;
    final pinnedTour = pinnedId != null ? _tourById(pinnedId) : null;
    // Peek nur nach Pin oder Auswahl — nie die erste Nähe-Karte.
    final topCard = DiscoverExploreChromeLogic.showIdlePeek(pinnedId)
        ? (pinnedTour ?? peekTour)
        : null;

    // Sheet-Modus: ein ScrollView steuert Drag + Liste (Handle mit drin).
    if (scrollController != null) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: _panelHandle()),
          if (topCard != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.m,
              ),
              sliver: SliverToBoxAdapter(
                child: peek
                    ? _tourPeekCard(topCard, _origin)
                    : _tourListCard(topCard, _origin),
              ),
            ),
          if (!peek) ...[
            SliverToBoxAdapter(child: header),
            SliverToBoxAdapter(child: _panelMessages()),
            if (_loading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.m,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(sections),
              ),
            ),
          ],
        ],
      );
    }

    // Plan/Detail-Fallback (feste Höhe) — sollte für Discover selten greifen.
    return Column(
      children: [
        _panelHandle(),
        header,
        _panelMessages(),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              0,
              AppSpacing.m,
              AppSpacing.m,
            ),
            children: sections,
          ),
        ),
      ],
    );
  }

  /// Touren — dieselbe Liste wie der Tab, kartenfirst.
  Widget _buildMinePanel({ScrollController? scrollController}) {
    final l10n = AppLocalizations.of(context);
    final savedList =
        ref.watch(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    final visibility = ref.watch(tourVisibilityProvider);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.navPlatz,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.browseList,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ref.read(shellTabIndexProvider.notifier).state =
                      ShellTabs.platz;
                },
                icon: const ChromeGlyph('layers', size: 20),
              ),
              FilterChip(
                label: Text(
                  l10n.myRoutesShowOnMap,
                  style: const TextStyle(fontSize: 11),
                ),
                selected: _showOwnTracks,
                onSelected: (v) {
                  setState(() => _showOwnTracks = v);
                  unawaited(_drawAll());
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.mineSheetHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final chip in TourFilters.visibilityChips)
                FilterChip(
                  label: Text(
                    l10n.tourVisibilityChip(chip.id),
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: visibility == chip.id,
                  onSelected: (_) {
                    ref.read(tourVisibilityProvider.notifier).state = chip.id;
                    unawaited(_reloadSavedMeta());
                  },
                ),
            ],
          ),
        ],
      ),
    );

    final body = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.chrome),
              onPressed: () => unawaited(_addSimpleRouteSheet()),
              icon: const ChromeGlyph('add', size: 18, color: AppColors.onAccent),
              label: Text(_l10n.discoverAddRoute),
            ),
            OutlinedButton.icon(
              onPressed: _importGpxDialog,
              icon: const ChromeGlyph('download', size: 18),
              label: Text(l10n.gpxImportAction),
            ),
          ],
        ),
      ),
      if (savedList.isEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _l10n.discoverMineEmptyHint,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _setShellMode(
            DiscoverShellMode.navigate,
            pick: _PickMode.start,
          ),
          icon: const ChromeGlyph('nav', size: 20),
          label: Text(l10n.mineEmptyCtaNavigate),
        ),
      ] else
        ..._savedTiles(includeTitle: false),
    ];

    if (scrollController != null) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _panelHandle(semanticsLabel: l10n.sheetDragHandleMine),
          ),
          SliverToBoxAdapter(child: header),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              0,
              AppSpacing.m,
              AppSpacing.m,
            ),
            sliver: SliverList(delegate: SliverChildListDelegate(body)),
          ),
        ],
      );
    }

    return Column(
      children: [
        _panelHandle(semanticsLabel: l10n.sheetDragHandleMine),
        header,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              0,
              AppSpacing.m,
              AppSpacing.m,
            ),
            children: body,
          ),
        ),
      ],
    );
  }

  String? _planOfflineSurfaceLine(AppLocalizations l10n) {
    if (!isOfflineRoutingEngine(_computed?.engine)) return null;
    final pack = _offlinePackLabel?.trim() ?? '';
    if (pack.isNotEmpty) {
      return l10n.offlineCoverageLabelFor(pack, packId: _offlinePackId);
    }
    return l10n.discoverMenuOffline;
  }

  String? _planSurfaceCell(AppLocalizations l10n) {
    if (_planSurfaceMix.isNotEmpty) {
      final s = _planSurfaceMix.first;
      return '${osmSurfaceDisplay(s.key, l10n)} ${(s.share * 100).round()}%';
    }
    return _planOfflineSurfaceLine(l10n);
  }

  String _planRouteStatsLine() {
    final r = _computed;
    if (r == null) return '';
    final km = (r.distanceM / 1000).toStringAsFixed(1);
    final mins = (r.durationS / 60).round();
    final elev = _elevationSummary;
    var line = (elev == null || elev.isEmpty)
        ? '$km km · $mins min'
        : '$km km · $mins min · $elev';
    final surface = _planOfflineSurfaceLine(_l10n);
    if (surface != null) line = '$line · $surface';
    if (_aroundYouApplied) {
      line = '$line · ${_l10n.discoverAroundYouUncertainShort}';
    }
    return line;
  }

  List<String> _loopJustificationReasons(AppLocalizations l10n) {
    final got = _computed == null ? 0 : (_computed!.durationS / 60).round();
    final surface = _surfaceFromLoopWarnings(_computed?.warnings ?? const []);
    return [
      l10n.discoverLoopReasonDuration('$got', '$_minutes'),
      surface != null
          ? l10n.discoverLoopReasonSurface(surface)
          : l10n.discoverLoopReasonOsmTags,
      l10n.discoverAroundYouHint,
    ];
  }

  String? _surfaceFromLoopWarnings(List<String> warnings) {
    final re = RegExp(r'überwiegend\s+(.+)$', caseSensitive: false);
    for (final w in warnings) {
      final m = re.firstMatch(w);
      final s = m?.group(1)?.trim();
      if (s != null && s.length >= 3) return s;
    }
    return null;
  }

  String _planStickyKmMin() {
    final r = _computed;
    final adapting = _adaptingTour;
    if (r != null && r.distanceM >= 80) {
      final km = r.distanceM / 1000;
      return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km · ${(r.durationS / 60).round()} min';
    }
    if (adapting != null && adapting.distanceKm > 0) {
      final km = adapting.distanceKm;
      return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km · ${adapting.durationMin.round()} min';
    }
    if (r == null) return '';
    final km = r.distanceM / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km · ${(r.durationS / 60).round()} min';
  }

  Widget _planStickyCta(AppLocalizations l10n) {
    if (_computed != null && _start != null && _end != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _planStickyKmMin(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
            Row(
              children: [
                Tooltip(
                  message: l10n.save,
                  child: OutlinedButton(
                    onPressed: () => unawaited(_saveCurrent()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                    ),
                    child: const ChromeGlyph('merken', size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                    ),
                    onPressed: () => unawaited(_startRide()),
                    icon: const ChromeGlyph(
                      'play',
                      size: 22,
                      color: AppColors.onAccent,
                    ),
                    label: Text(l10n.goRide),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (_start != null && _end == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: FilledButton(
          key: const Key('discover-set-end-sticky'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
          onPressed: () {
            setState(() => _pick = _PickMode.end);
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Text(l10n.discoverSetEndCta),
        ),
      );
    }
    if (_start == null) {
      final hasGps = _userPos != null;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: FilledButton.icon(
          key: const Key('discover-tap-start-sticky'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
          onPressed: () {
            if (hasGps) {
              unawaited(_useMyLocationAsStart());
              return;
            }
            // Pick on map — don't focus the address field or map taps stay
            // blocked (mapPlanEditorTapPlacesPin). Keyboard search is optional.
            setState(() => _pick = _PickMode.start);
            _setStatus(_l10n.discoverTapStart);
            FocusManager.instance.primaryFocus?.unfocus();
          },
          icon: ChromeGlyph(
            hasGps ? 'locate' : 'flag',
            size: 22,
            color: AppColors.onAccent,
          ),
          label: Text(
            hasGps ? l10n.navigateMyLocation : l10n.discoverTapStart,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _planPeekChrome(AppLocalizations l10n) {
    final dest = _endAddrCtrl.text.trim();
    final destLabel = dest.isEmpty
        ? (_pick == _PickMode.end
            ? l10n.discoverTapStart
            : l10n.discoverSetEndCta)
        : dest;
    final stats = _planStickyKmMin();
    final title = _adaptingTourName ?? l10n.planRouteTitle;
    final canGo = _computed != null && _start != null && _end != null;
    final canVia = _start != null && _end != null;
    final viaArmed = _pick == _PickMode.via;
    final coach = _planLineCoach && canVia;
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.s + inset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            viaArmed
                ? l10n.navigateViaHint
                : coach
                    ? l10n.planLineCoachShort
                    : [
                        if (stats.isNotEmpty) stats,
                        destLabel,
                      ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: viaArmed ? const Color(0xFFE65100) : AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                tooltip: l10n.save,
                visualDensity: VisualDensity.compact,
                onPressed: canGo ? () => unawaited(_saveCurrent()) : null,
                icon: const ChromeGlyph('merken', size: 20),
              ),
              if (canVia) ...[
                IconButton(
                  key: const Key('plan-peek-via'),
                  tooltip: l10n.navigateAddVia,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final dismiss = _planLineCoach;
                    setState(() {
                      _pick = viaArmed ? _PickMode.none : _PickMode.via;
                      if (dismiss) _planLineCoach = false;
                    });
                    if (dismiss) {
                      unawaited(RidePrefs.setPlanLineCoachDismissed(true));
                    }
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: viaArmed
                        ? const Color(0xFFE65100)
                        : null,
                    backgroundColor: viaArmed
                        ? const Color(0x22E65100)
                        : null,
                  ),
                  icon: const ChromeGlyph('add', size: 20),
                ),
              ],
              const SizedBox(width: 4),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    minimumSize: const Size.fromHeight(40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: canGo
                      ? () => unawaited(_startRide())
                      : () {
                          setState(() => _pick = _PickMode.end);
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                  icon: ChromeGlyph(
                    canGo ? 'play' : 'flag',
                    size: 18,
                    color: AppColors.onAccent,
                  ),
                  label: Text(canGo ? l10n.goRide : l10n.discoverSetEndCta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Navigieren — A→B als erster Klasse-Modus (Komoot-ähnlich).
  /// Bei Tour-Anpassen bleibt ein Zurück; sonst steuert der Shell-Toggle.
  Widget _buildPlanPanel({ScrollController? scrollController}) {
    final l10n = AppLocalizations.of(context);
    final peek = PlanSheetSnaps.isPeek(_planSheetExtent);
    return Column(
      children: [
        Expanded(
          child: _withLoadingVeil(
            _buildPlanSheet(scrollController: scrollController),
          ),
        ),
        if (!peek &&
            _computed != null &&
            _start != null &&
            _end != null &&
            _showNavigateOfflineHint)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              0,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Material(
              color: AppColors.sage.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                side: BorderSide(
                  color: AppColors.sageOnDark.withValues(alpha: 0.55),
                ),
              ),
              child: TextButton.icon(
                key: const Key('navigate-offline-hint'),
                onPressed: () => unawaited(
                  _openOfflineMaps(
                    focus: GeoPoint(
                      (_start!.lat + _end!.lat) / 2,
                      (_start!.lng + _end!.lng) / 2,
                    ),
                    focusPackId: _navigateOfflinePack?.id,
                  ),
                ),
                icon: const ChromeGlyph('download', size: 18),
                label: Text(_navigateOfflineHintLabel(l10n)),
              ),
            ),
          ),
        if (!peek) _planStickyCta(l10n),
      ],
    );
  }

  /// Tour-Detail — vorher ein eigener `Scaffold` mit `AppBar`, der beim
  /// Antippen einer Tour die ganze Karte wegriss. Jetzt derselbe Platz wie
  /// Planen: ein Panel über der Karte, die im Hintergrund auf die Tour
  /// zentriert bleibt (siehe [_openDetail]).
  Widget _detailPeekChrome(_RouteSuggestion detail) {
    final km = detail.distanceKm;
    final kmLabel = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.s + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            detail.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${detail.durationMin.round()} Min  ·  $kmLabel km',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chrome,
              foregroundColor: AppColors.onAccent,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _loading
                ? null
                : () => unawaited(_startRide(suggestion: detail)),
            icon: const ChromeGlyph(
              'play',
              size: 20,
              color: AppColors.onAccent,
            ),
            label: Text(_l10n.goRide),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel({ScrollController? scrollController}) {
    final detail = _detailTour;
    if (detail == null) {
      // Tour ist aus der Liste gefallen (Filter geändert, Daten neu
      // geladen), während das Panel offen war — kein Absturz, kurzer
      // Hinweis mit Weg zurück statt eines leeren Panels.
      return Column(
        children: [
          _panelHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.m,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: _l10n.navigateBackToExplore,
                  onPressed: _closeDetail,
                  icon: const Icon(Icons.arrow_back),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    _l10n.discoverTourGone,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(
                  _l10n.discoverTourGoneBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Beschreibung: shortPitch bevorzugt; tip springt ein, wenn es keinen
    // Pitch gibt — sonst erscheint tip unten unter „Tipps & Infos".
    final pitch = detail.shortPitch?.trim();
    final tip = detail.tip?.trim();
    final description = (pitch != null && pitch.isNotEmpty)
        ? pitch
        : ((tip != null && tip.isNotEmpty) ? tip : null);
    final tipRow =
        (tip != null && tip.isNotEmpty && tip != description) ? tip : null;

    final peek = PlanSheetSnaps.isPeek(_planSheetExtent);
    if (peek) {
      return ListView(
        controller: scrollController,
        children: [
          _panelHandle(),
          _detailPeekChrome(detail),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: _withLoadingVeil(
            ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.l,
                AppSpacing.l + 88,
              ),
              children: [
                _panelHandle(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: _l10n.navigateBackToExplore,
                    onPressed: _closeDetail,
                    icon: const Icon(Icons.arrow_back),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                _panelMessages(),
                if (detail.isSeed || detail.thumbnailUrl != null) ...[
                  _tourHero(
                    detail,
                    _origin,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    // Distanz/Schwierigkeit stehen in Meta + Startzeile.
                    showScanChips: false,
                    enableCarousel: true,
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
                // H1 im Inhalt — 2-Sekunden-Scan: Name → Meta → Stats.
                Text(
                  detail.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                _detailMetaRow(detail),
                const SizedBox(height: AppSpacing.l),
                _detailStatsGrid(detail),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.l),
                  _ExpandableText(description),
                ],
                ..._detailElevationSection(detail),
                if (detail.poiStops.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _detailSectionTitle(_l10n.discoverTourTimeline),
                  const SizedBox(height: AppSpacing.s),
                  for (var i = 0; i < detail.poiStops.length; i++)
                    _poiTimelineTile(
                      detail.poiStops[i],
                      isLast: i == detail.poiStops.length - 1,
                    ),
                ],
                ..._detailInfoSection(detail, tipRow),
                const SizedBox(height: AppSpacing.xl),
                TourFunctionKit(
                  tourId: detail.id,
                  tags: detail.apiTags,
                  categories: detail.categories,
                  onOpenGroup: () {
                    ref.read(shellTabIndexProvider.notifier).state =
                        ShellTabs.platz;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                TourCommunitySection(tourId: detail.id),
                const SizedBox(height: AppSpacing.l),
                _detailStartRow(detail),
                if (_isPinOnlyIdea(detail)) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    _l10n.discoverNoTrackYet,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        _detailActionBar(detail),
      ],
    );
  }

  Widget _detailSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }

  /// Komoot-Zeile unter dem Titel: „⟲ Rundkurs · Sport · ● Schwierigkeit".
  /// Kein Social-Proof in der Scan-Zeile — Zahlen gehören in Heatmap/Consent.
  Widget _detailMetaRow(_RouteSuggestion detail) {
    const sep = Text(
      '  ·  ',
      style: TextStyle(fontSize: 13, color: AppColors.muted),
    );
    final children = <Widget>[];
    void add(Widget w) {
      if (children.isNotEmpty) children.add(sep);
      children.add(w);
    }

    if (_isLoop(detail)) {
      add(
        Text(
          _l10n.discoverLoopBadge,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.chrome,
          ),
        ),
      );
    } else if (_shapeLabel(detail) case final shape?) {
      add(
        Text(
          shape,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (detail.sportLabel case final sport?) {
      add(
        Text(
          _l10n.sportTagLabel(sport),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    } else if (detail.sourceKind == 'osm' ||
        detail.sourceKind == 'outdooractive' ||
        detail.sourceKind == 'catalog') {
      add(
        Text(
          _sourceLabelOf(detail),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    }
    add(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DifficultyDot(raw: detail.mtbScale),
          const SizedBox(width: 5),
          Text(
            _difficultyDisplay(_l10n, detail.mtbScale),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    add(TourSocialProof(tourId: detail.id));
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.xs,
      children: children,
    );
  }

  /// Stats-Grid 2×2 im Komoot-Stil: Label klein, Wert groß, feine Trenner.
  /// Typ/Form nicht nochmal — steht schon in [_detailMetaRow].
  Widget _detailStatsGrid(_RouteSuggestion detail) {
    final elev = _detailElev[detail.id];
    final gainM = detail.elevationM > 0
        ? detail.elevationM
        : ((elev != null && elev.gainM > 0) ? elev.gainM.round() : null);
    final surfaceLabel = detail.surfaceMixLabel?.trim().isNotEmpty == true
        ? detail.surfaceMixLabel!
        : TourFilters.surfaceDisplay(detail.surface);

    Widget cell(String label, String value) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget vSep() => Container(width: 1, height: 36, color: AppColors.border);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              cell(_l10n.discoverDuration,
                  _fmtRideDuration(detail.durationMin, _l10n)),
              vSep(),
              cell(
                _l10n.discoverLength,
                '${detail.distanceKm.toStringAsFixed(detail.distanceKm < 10 ? 1 : 0)} km',
              ),
            ],
          ),
          Container(height: 1, color: AppColors.border),
          Row(
            children: [
              cell(_l10n.discoverAscent, gainM != null ? '↑ $gainM m' : '—'),
              vSep(),
              cell(_l10n.filterSurfaceGroup, surfaceLabel),
            ],
          ),
        ],
      ),
    );
  }

  /// Höhenprofil-Sektion — nur wenn echte Samples für DIESE Tour da sind
  /// (siehe [_ensureDetailElevation]); nie Fake-Kurven.
  List<Widget> _detailElevationSection(_RouteSuggestion detail) {
    final elev = _detailElev[detail.id];
    if (elev == null || elev.samples.length < 2) return const [];
    // Aufstieg steht schon im Stats-Grid — hier nur Abstieg ergänzen.
    return [
      const SizedBox(height: AppSpacing.l),
      _detailSectionTitle(_l10n.discoverElevationProfile),
      const SizedBox(height: AppSpacing.s),
      SizedBox(
        width: double.infinity,
        height: 64,
        child: CustomPaint(painter: _MiniElevPainter(elev.samples)),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        _l10n.discoverDescent('${elev.lossM.round()}'),
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    ];
  }

  /// Ein Stop im Tourverlauf: Punkt + Linie links (Komoot-Timeline),
  /// Minuten-Marke, Titel, whyGood.
  Widget _poiTimelineTile(_SeedPoiStop p, {required bool isLast}) {
    final highlighted = _highlightPoiId == p.id;
    return GestureDetector(
      onTap: () => _flashAndScrollToPoi(p.id),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        key: _keyForPoi(p.id),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.sage.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF4F1EC),
                        border: Border.all(
                          color: highlighted
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.55),
                          width: highlighted ? 2.2 : 1.6,
                        ),
                      ),
                      child: Center(
                        child: _poiDrawIndexById[p.id] != null
                            ? Text(
                                '${_poiDrawIndexById[p.id]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A120C),
                                  height: 1,
                                ),
                              )
                            : _poiKindMark(p.kind, size: 18),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: AppColors.border),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.atMin > 0
                            ? _l10n.discoverElevMin(p.atMin)
                            : _l10n.navigateStartLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        p.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (p.whyGood case final why?)
                        Text(
                          why,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// „Tipps & Infos" — Tipp, Saison, Untergrund, Disziplin, Korridor, API-Tags
  /// als Icon-Zeilen (ersetzt die früheren Einzel-Überschriften).
  List<Widget> _detailInfoSection(_RouteSuggestion detail, String? tipRow) {
    final traits = _detailTraitChips(detail);
    // Untergrund steht schon im Stats-Grid — hier nicht wiederholen.
    final rows = <({String mark, String label, String text})>[
      if (tipRow != null)
        (mark: 'hint', label: _l10n.discoverTip, text: tipRow),
      if (detail.seasonLabel case final s?)
        (mark: 'calendar', label: _l10n.discoverBestTime, text: s),
      if (detail.disciplineNote case final d?)
        (mark: 'nav', label: _l10n.discoverDiscipline, text: d),
      if (detail.corridorNote case final c?)
        (mark: 'split', label: _l10n.discoverCorridor, text: c),
    ];
    if (rows.isEmpty && traits == null) return const [];
    return [
      const SizedBox(height: AppSpacing.l),
      _detailSectionTitle(_l10n.discoverTipsInfo),
      const SizedBox(height: AppSpacing.s),
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChromeGlyph(r.mark, size: 18, color: AppColors.muted),
              const SizedBox(width: AppSpacing.s + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      r.text,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (traits != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            _l10n.discoverTraits,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        traits,
      ],
    ];
  }

  Widget? _detailTraitChips(_RouteSuggestion detail) {
    final wires = TourTrait.visibleWires(
      detail.apiTags,
      extraSkip: [
        detail.sourceKind,
        if (detail.sportLabel != null) detail.sportLabel!,
      ],
    );
    if (wires.isEmpty) return null;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final w in wires)
          FilterChip(
            label: Text(TourTrait.label(w)),
            selected: _activeTraits.contains(TourTrait.keyOf(w)),
            onSelected: (_) => _toggleTrait(w),
          ),
      ],
    );
  }

  void _toggleTrait(String wire) {
    final key = TourTrait.keyOf(wire);
    setState(() {
      if (_activeTraits.contains(key)) {
        _activeTraits.remove(key);
      } else {
        _activeTraits.add(key);
      }
    });
    unawaited(_drawAll());
  }

  /// „Startpunkt · X km von hier" + „Anfahrt" (Komoot-Detail) —
  /// Anfahrt = bestehender Hybrid-Snap (Anfahrt + Tour in einer Route).
  Widget _detailStartRow(_RouteSuggestion detail) {
    final o = _origin;
    final distKm =
        _distKm(o.lat, o.lng, detail.center.latitude, detail.center.longitude);
    final distLabel = distKm < 1
        ? '<1 km'
        : distKm < 10
            ? '${distKm.toStringAsFixed(1)} km'
            : '${distKm.round()} km';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const ChromeGlyph(
            'flag',
            size: 20,
            color: AppColors.chrome,
          ),
          const SizedBox(width: AppSpacing.s + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.discoverStartPoint,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  _l10n.discoverFromHereKm(distLabel),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _loading ? null : () => unawaited(_hybridSnap(detail)),
            icon: const ChromeGlyph('nav', size: 18),
            label: Text(_l10n.discoverApproach),
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom-Bar im Detail: Losfahren (bzw. Route berechnen bei
  /// Pin-only-Ideen ohne Polyline) + Anpassen — immer erreichbar, ohne
  /// durch das ganze Panel zu scrollen (Komoot Speichern/Navigieren-Leiste).
  Widget _detailActionBar(_RouteSuggestion detail) {
    final pinOnly = _isPinOnlyIdea(detail);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s + 2,
        AppSpacing.l,
        AppSpacing.s + 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.chrome,
                foregroundColor: AppColors.onAccent,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: _loading
                  ? null
                  : pinOnly
                      ? () => unawaited(_adoptTourIntoPlan(detail))
                      : () => unawaited(_startRide(suggestion: detail)),
              icon: ChromeGlyph(
                pinOnly ? 'flag' : 'play',
                size: 22,
                color: AppColors.onAccent,
              ),
              label: Text(
                pinOnly ? l10n.discoverSetEndCta : l10n.goRide,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          IconButton(
            tooltip: _l10n.discoverToMyTours,
            onPressed:
                _loading ? null : () => unawaited(_saveTourToLibrary(detail)),
            icon: const ChromeGlyph('merken', size: 22),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: AppColors.chipIdleText,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed:
                  _loading ? null : () => unawaited(_adoptTourIntoPlan(detail)),
              icon: const ChromeGlyph('filter', size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.adaptTour,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withLoadingVeil(Widget body) {
    if (!_loading) return body;
    final peek = _planSheetActive && _planSheetIsPeek;
    return Column(
      children: [
        const LinearProgressIndicator(minHeight: 2),
        if (_surface == _Surface.plan && !peek)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              6,
              AppSpacing.m,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context).discoverRoutingAdapts,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ),
        Expanded(child: body),
      ],
    );
  }

  /// Sektions-Überschrift innerhalb der einen Discover-Liste — ersetzt den
  /// früheren Tab-Wechsel zwischen „Schnell" und „Touren".
  Widget _sectionTitle(String title, {String? hint, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _onPlanPinDrag(
    dynamic id, {
    required math.Point<double> point,
    required LatLng origin,
    required LatLng current,
    required LatLng delta,
    required DragEventType eventType,
  }) {
    if (_shellMode != DiscoverShellMode.navigate && _surface != _Surface.plan) {
      return;
    }
    if (eventType != DragEventType.end) {
      final sid = id?.toString();
      if (_isPlanLineGrab(sid)) {
        _restorePlanGrabLine(sid!);
        _previewPlanDragAlong(current);
        return;
      }
      final draggingStart = sid != null && _planStartSymbol?.id == sid;
      final draggingEnd = sid != null && _planEndSymbol?.id == sid;
      int? viaIndex;
      if (!draggingStart && !draggingEnd && sid != null) {
        final i = _planViaSymbols.indexWhere((s) => s.id == sid);
        if (i >= 0 && i < _vias.length) viaIndex = i;
      }
      _previewPlanDragAlong(
        current,
        draggingStart: draggingStart,
        draggingEnd: draggingEnd,
        draggingViaIndex: viaIndex,
      );
      return;
    }
    unawaited(_clearPlanDragPreview());
    final sid = id?.toString();
    if (sid == null) return;
    final undoLen = _planUndoStack.length;
    final redoLen = _planRedoStack.length;
    _pushPlanUndo();
    final p = GeoPoint(current.latitude, current.longitude);
    var changed = false;
    if (_planStartSymbol?.id == sid) {
      setState(() {
        _start = p;
        _startAddrCtrl.text = _l10n.discoverOnMapPlace;
        _planDragAlongLabel = null;
      });
      changed = true;
    } else if (_planEndSymbol?.id == sid) {
      setState(() {
        _end = p;
        _endAddrCtrl.text = _l10n.discoverOnMapPlace;
        _planDragAlongLabel = null;
      });
      changed = true;
    } else {
      final i = _planViaSymbols.indexWhere((s) => s.id == sid);
      if (i >= 0 && i < _vias.length) {
        final old = _vias[i];
        final at =
            viaMaySnapOntoTrail(label: old.trimmedLabel) ? _snapViaPoint(p) : p;
        setState(() {
          _vias[i] = LabeledVia(
            lat: at.lat,
            lng: at.lng,
            label: _l10n.discoverOnMapPlace,
            placeId: old.placeId,
            kind: old.kind,
          );
          _planDragAlongLabel = null;
        });
        changed = true;
      } else if (_planBendSymbols.any((s) => s.id == sid) ||
          _isPlanLineGrab(sid)) {
        if (_isPlanLineGrab(sid)) _restorePlanGrabLine(sid);
        changed = _insertViaFromRibbonDrop(p);
      }
    }
    if (changed) {
      _abFromBrowsePin = false;
      unawaited(_reversePlanFieldLabels());
      if (_start != null && _end != null) {
        _scheduleCalcAbFromMap(keepLine: true, refitPins: false);
      }
    } else {
      while (_planUndoStack.length > undoLen) {
        _planUndoStack.removeLast();
      }
      while (_planRedoStack.length > redoLen) {
        _planRedoStack.removeLast();
      }
    }
  }

  void _closeLoop() {
    final s = _start;
    if (s == null) return;
    _abFromBrowsePin = false;
    _pushPlanUndo();
    setState(() {
      _end = s;
      _endAddrCtrl.text = _startAddrCtrl.text.isEmpty
          ? AppLocalizations.of(context).navigateStartLabel
          : _startAddrCtrl.text;
    });
    unawaited(_syncMarkers());
    unawaited(_calcAb(keepLine: true, refitPins: false));
  }

  void _swapStartEnd() {
    final s = _start;
    final e = _end;
    _abFromBrowsePin = false;
    _pushPlanUndo();
    final st = _startAddrCtrl.text;
    final et = _endAddrCtrl.text;
    setState(() {
      _start = e;
      _end = s;
      _startAddrCtrl.text = et;
      _endAddrCtrl.text = st;
      _addrHits = const [];
    });
    unawaited(_syncMarkers());
    if (_start != null && _end != null) {
      unawaited(_calcAb(keepLine: true, refitPins: false));
    }
  }

  Future<void> _useMyLocationAsStart() async {
    var u = _userPos;
    if (u == null) {
      await _locate(fresh: true);
      u = _userPos;
    }
    if (!mounted || u == null) return;
    _pushPlanUndo();
    setState(() {
      _start = u;
      _startAddrCtrl.text = AppLocalizations.of(context).navigateMyLocation;
      _pick = _end == null ? _PickMode.end : _PickMode.none;
      _addrHits = const [];
    });
    await _syncMarkers();
    if (_end != null) await _calcAb();
  }

  Widget _buildPlanSheet({ScrollController? scrollController}) {
    final l10n = AppLocalizations.of(context);
    final peek = PlanSheetSnaps.isPeek(_planSheetExtent);
    final adapting = _adaptingTourName;
    final ideaTour = _ideaPin != null ? _tourById(_selectedTourId) : null;
    return ListView(
      controller: scrollController,
      padding: peek
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(
              AppSpacing.m,
              0,
              AppSpacing.m,
              AppSpacing.m,
            ),
      children: [
        _panelHandle(semanticsLabel: l10n.sheetDragHandleNavigate),
        if (peek) _planPeekChrome(l10n),
        if (!peek) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 0, 0),
            child: Row(
              children: [
                if (adapting != null)
                  IconButton(
                    tooltip: l10n.navigateBackToExplore,
                    onPressed: _closePlan,
                    icon: const Icon(Icons.arrow_back),
                    visualDensity: VisualDensity.compact,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adapting != null
                            ? l10n.adaptTourTitle
                            : l10n.planRouteTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        adapting != null
                            ? l10n.discoverAdjustStops
                            : _planDragAlongLabel ??
                                (_pick == _PickMode.via
                                    ? l10n.navigateViaHint
                                    : (_end != null && _start == null)
                                        ? l10n.discoverDestSetWaitingGps
                                        : _start == null
                                            ? l10n.discoverTapStart
                                            : l10n.planEditLineHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_navProfileChipVisible) _profileChip(),
              ],
            ),
          ),
          if (_adaptingTour != null) ...[
          PlanAdaptBanner(
            name: _adaptingTour!.name,
            photoUrl: _adaptingTour!.heroPhotoUrls.isNotEmpty
                ? _adaptingTour!.heroPhotoUrls.first
                : _adaptingTour!.thumbnailUrl,
            distanceKm: _adaptingTour!.distanceKm,
            durationMin: _adaptingTour!.durationMin,
            elevationM: _adaptingTour!.elevationM,
            surface: (_adaptingTour!.surfaceMixLabel ?? _adaptingTour!.surface)
                .trim(),
            looped: _isLoop(_adaptingTour!),
            compact: _computed != null,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (_ideaPin != null && _adaptingTour == null && ideaTour != null) ...[
          PlanAdaptBanner(
            name: ideaTour.name,
            photoUrl: ideaTour.heroPhotoUrls.isNotEmpty
                ? ideaTour.heroPhotoUrls.first
                : ideaTour.thumbnailUrl,
            distanceKm: ideaTour.distanceKm,
            durationMin: ideaTour.durationMin,
            elevationM: ideaTour.elevationM,
            surface: (ideaTour.surfaceMixLabel ?? ideaTour.surface).trim(),
            looped: _isLoop(ideaTour),
            compact: true,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (_planDragAlongLabel != null) ...[
          Text(
            _planDragAlongLabel!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          Text(
            l10n.discoverRoutingAdapts,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        PlanWaypointStack(
          startController: _startAddrCtrl,
          endController: _endAddrCtrl,
          startFocus: _startAddrFocus,
          endFocus: _endAddrFocus,
          vias: List<LabeledVia>.from(_vias),
          hasStart: _start != null,
          hasEnd: _end != null,
          startOutside: coverageRiderOutside(
            lng: _start?.lng,
            lat: _start?.lat,
            bbox: _offlinePackBbox,
            routingReady: _offlineRoutingReady,
            ring: _offlinePackRing,
          ),
          endOutside: coverageRiderOutside(
            lng: _end?.lng,
            lat: _end?.lat,
            bbox: _offlinePackBbox,
            routingReady: _offlineRoutingReady,
            ring: _offlinePackRing,
          ),
          viaOutside: [
            for (final v in _vias)
              coverageRiderOutside(
                lng: v.lng,
                lat: v.lat,
                bbox: _offlinePackBbox,
                routingReady: _offlineRoutingReady,
                ring: _offlinePackRing,
              ),
          ],
          loopClosed: PlanSession.fromParts(
            start: _start,
            end: _end,
          ).isClosedLoop(),
          onMyLocation: () => unawaited(_useMyLocationAsStart()),
          onSwap: _swapStartEnd,
          pickingVia: _pick == _PickMode.via,
          viaHint: _pick == _PickMode.via ? l10n.navigateViaHint : null,
          lineHint: _hasLivePlanLine && _start != null && _end != null
              ? l10n.planEditLineHint
              : null,
          onUndo: _planUndoStack.isEmpty ? null : _undoPlan,
          onRedo: _planRedoStack.isEmpty ? null : _redoPlan,
          onAddVia: () => setState(() {
            _pick = _PickMode.via;
            _setStatus(l10n.navigateViaHint);
          }),
          onCloseLoop: _closeLoop,
          onStartChanged: (_) {
            if (_error != null) setState(() => _error = null);
            _scheduleAddressSearch('start');
          },
          onEndChanged: (_) {
            if (_error != null) setState(() => _error = null);
            _scheduleAddressSearch('end');
          },
          onStartSubmitted: () {
            unawaited(_searchAddress('start'));
            _endAddrFocus.requestFocus();
          },
          onEndSubmitted: () => unawaited(_searchAddress('end')),
          onViaReorder: (from, to) {
            final snapshot = List<LabeledVia>.from(_vias);
            _pushPlanUndo();
            setState(() {
              _abFromBrowsePin = false;
              _vias
                ..clear()
                ..addAll(moveLabeledViaTo(snapshot, from, to));
            });
            unawaited(_syncMarkers());
            if (_start != null && _end != null) {
              unawaited(_calcAb(keepLine: true, refitPins: false));
            }
          },
          onViaRemove: (index) {
            _pushPlanUndo();
            setState(() => _vias.removeAt(index));
            unawaited(_syncMarkers());
            if (_start != null && _end != null) {
              unawaited(_calcAb(keepLine: true, refitPins: false));
            }
          },
          onViaChanged: (i, q) {
            if (_error != null) setState(() => _error = null);
            _scheduleAddressSearch('via:$i', query: q);
          },
          onViaSubmitted: (i, q) =>
              unawaited(_searchAddress('via:$i', query: q)),
        ),
        _panelMessages(),
        if (_offerLastPlanDest) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              key: const Key('last-plan-dest-chip'),
              avatar: const ChromeGlyph('recent', size: 16),
              label: Text(_lastPlanDestChipText()),
              onPressed: _applyLastPlanDest,
              onDeleted: _dismissLastPlanDestChip,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (_addrBusy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: LinearProgressIndicator(),
          ),
        for (final h in _addrHits) _planGeocodeHitTile(h, recent: false),
        if (_addrHits.isEmpty && _geocodeRecents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              l10n.discoverRecently,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          for (final h in _geocodeRecents)
            _planGeocodeHitTile(h, recent: true),
        ],
        if (_error != null && _start != null && _end != null)
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => unawaited(
                  _calcAb(keepLine: true, refitPins: false),
                ),
                child: Text(l10n.retry),
              ),
              if (_error == l10n.discoverBrowseNeedsNetwork)
                _browseLoadMapPackButton(),
              if (_error == l10n.discoverViasNeedNet && _vias.isNotEmpty)
                _dropViasAndGoButton(),
            ],
          ),
        if (_computed != null && _start != null && _end != null) ...[
          if (shouldShowLiveRouteStats(
            hasLiveLine: true,
            engine: _computed!.engine,
            coordinateCount: _computed!.coordinates.length,
          )) ...[
            const SizedBox(height: AppSpacing.s),
            Semantics(
              key: const Key('navigate-route-stats'),
              label: _planRouteStatsLine(),
              child: Opacity(
                opacity: _planDragAlongLabel != null ? 0.45 : 1,
                child: PlanRouteStats(
                  distanceKm: _computed!.distanceM / 1000,
                  durationMin: (_computed!.durationS / 60).round(),
                  ascentM: _elevationGainM,
                  surfaceLine: _planSurfaceCell(l10n),
                  looped: PlanSession.fromParts(
                    start: _start,
                    end: _end,
                  ).isClosedLoop(),
                  uncertainShort: _aroundYouApplied
                      ? l10n.discoverAroundYouUncertainShort
                      : null,
                  reasons: _aroundYouApplied
                      ? _loopJustificationReasons(l10n)
                      : const [],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            PlanSurfaceBar(mix: _planSurfaceMix),
            if (_planElevSamples.length >= 2) ...[
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Text(
                    l10n.discoverElevationProfile,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.planElevSteepHint,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              PlanElevationChart(
                samples: _planElevSamples,
                sampleKm: _planElevKm.isEmpty ? null : _planElevKm,
                scrubT: _planElevScrubT,
                totalKm: _computed!.distanceM / 1000,
                surfaceBands:
                    _planSurfaceBands.isEmpty ? null : _planSurfaceBands,
                onScrub: _onPlanElevScrub,
                onTap: _onPlanElevTap,
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.s),
          RouteVariantChips(
            value: _routeVariant,
            enabled: _valhallaLive,
            onChanged: (v) {
              if (!planVariantChanged(before: _routeVariant, after: v)) {
                return;
              }
              _pushPlanUndo();
              setState(() => _routeVariant = v);
              if (_start != null && _end != null) {
                unawaited(_calcAb(keepLine: true, refitPins: false));
              }
            },
          ),
          if (_weatherStart != null || _weatherSummit != null)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                dense: true,
                title: Row(
                  children: [
                    WeatherGlyph(
                      _weatherStart?.trailHint ?? _weatherSummit?.trailHint,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.discoverWeatherAlong,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  if (_weatherStart != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.discoverWeatherStart(
                          '${_weatherStart!.tempC.round()}',
                          l10n.weatherTrailHintLabel(_weatherStart!.trailHint),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  if (_weatherStart?.rideWindowLabel != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _weatherStart!.rideWindowLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  if (_weatherSummit != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.discoverWeatherSummit(
                          '${_weatherSummit!.tempC.round()}',
                          l10n.weatherTrailHintLabel(_weatherSummit!.trailHint),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ),
            ),
          if (_filmstripShots.isNotEmpty)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.discoverPhotosAlong,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  PlanFilmstrip(
                    shots: _filmstripShots,
                    onTap: (s) {
                      final map = _map;
                      if (map == null) return;
                      map.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(s.lat, s.lng), 15),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
        ],
      ],
    );
  }

  /// Demo-Stadt centers from bundled Nähe seeds (Berlin + DACH + Rhein-Neckar).
  /// Chip only meaningful when ≥1 seed in 45–75 min exists for that city.
  static const _demoCities = <({String id, double lat, double lng})>[
    (id: 'wiesloch', lat: 49.295, lng: 8.698),
    (id: 'heidelberg', lat: 49.409, lng: 8.694),
    (id: 'mannheim', lat: 49.483, lng: 8.462),
    (id: 'berlin', lat: 52.52, lng: 13.405),
    (id: 'hamburg', lat: 53.567, lng: 10.005),
    (id: 'muenchen', lat: 48.183, lng: 11.61),
    (id: 'koeln', lat: 50.941, lng: 6.958),
    (id: 'frankfurt', lat: 50.106, lng: 8.685),
    (id: 'stuttgart', lat: 48.812, lng: 9.23),
    (id: 'zuerich', lat: 47.366, lng: 8.541),
    (id: 'wien', lat: 48.218, lng: 16.392),
    (id: 'innsbruck', lat: 47.286, lng: 11.399),
    (id: 'konstanz', lat: 47.677, lng: 9.174),
    (id: 'paris', lat: 48.828, lng: 2.435),
    (id: 'lyon', lat: 45.777, lng: 4.855),
    (id: 'strasbourg', lat: 48.583, lng: 7.75),
    (id: 'nice', lat: 43.695, lng: 7.265),
    (id: 'annecy', lat: 45.887, lng: 6.12),
  ];

  void _focusOrtSearch() {
    _openPlan(
      status: _l10n.discoverChangePlaceSearch,
      pick: _PickMode.start,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAddrFocus.requestFocus();
    });
  }

  Future<void> _applyDemoCity(String id, double lat, double lng) async {
    final l10n = _l10n;
    final name = l10n.demoCityLabel(id);
    setState(() {
      // Demo-Ort schlägt GPS, sonst bliebe _userPos die echte Position.
      _userPos = null;
      _start = GeoPoint(lat, lng);
      _startAddrCtrl.text = name;
      _minutes = 60;
      _matchTourDuration = true;
      _formFilter = TourFormKey.all;
      _setStatus(l10n.discoverDemoRegion(name));
      _shellMode = DiscoverShellMode.explore;
      _surface = _Surface.discover;
      _detailId = null;
      _pick = _PickMode.none;
    });
    if (_seedsBundle == null) {
      await _loadNaeheSeeds();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.discoverDemoRegion(name))),
    );
    try {
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12),
      );
    } catch (_) {}
    unawaited(_fetchOutdooractive());
    unawaited(_fetchOsmRoutes());
    unawaited(_fetchPublicCatalog());
    await _drawAll();
  }

  Widget _emptyOrtPicker() {
    // S25: never a dead black sheet — always Ort / Dauer / Demo-Stadt CTAs.
    final l10n = AppLocalizations.of(context);
    final hasFilters = !_filtersAtDefaults;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Card(
        color: AppColors.surfaceDark,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          // ListView child: min height + stretch width (Q-BAR-DIS-02).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.emptyToursTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                !_browseOnline
                    ? l10n.discoverOaOffline
                    : hasFilters
                        ? l10n.emptyToursFiltersBody
                        : l10n.emptyToursNearbyBody,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (_loopOnlyActive) ...[
                const SizedBox(height: AppSpacing.m),
                _aroundYouCta(),
              ],
              const SizedBox(height: AppSpacing.m),
              if (hasFilters) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.chrome,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () {
                      _resetFilters();
                    },
                    icon: const ChromeGlyph('filter', size: 22),
                    label: Text(l10n.filterResetFilters),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              SizedBox(
                width: double.infinity,
                child: hasFilters
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: _focusOrtSearch,
                        icon: const ChromeGlyph('search', size: 20),
                        label: Text(l10n.discoverChangePlace),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.chrome,
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: _focusOrtSearch,
                        icon: const ChromeGlyph('search', size: 20),
                        label: Text(l10n.discoverChangePlace),
                      ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.discoverSuggestDuration,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in DurationLens.presets)
                    ActionChip(
                      label: Text(
                        p.minutes == 60 ? l10n.quickFilter1h : p.label,
                      ),
                      onPressed: () {
                        setState(() {
                          _minutes = p.minutes;
                          _matchTourDuration = p.minutes > 0;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              if (AppConfig.allowDemoContent) ...[
                Text(
                  l10n.discoverDemoCities,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in _demoCities)
                      ActionChip(
                        label: Text(l10n.demoCityLabel(c.id)),
                        onPressed: () => unawaited(
                          _applyDemoCity(c.id, c.lat, c.lng),
                        ),
                      ),
                  ],
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openPlan(
                    status: _l10n.discoverPlanYourself,
                    pick: _PickMode.start,
                  ),
                  child: Text(l10n.planRouteTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAroundYou({bool next = false}) async {
    final l10n = _l10n;
    if (!profileAllowsOsmRoundTrip(_profile)) {
      setState(() => _error = l10n.discoverAroundYouSport);
      return;
    }
    if (!_browseOnline) {
      setState(() => _error = l10n.discoverAroundYouOffline);
      return;
    }
    final origin = _riderOrigin ?? _userPos ?? _mapCenter;
    if (next) _loopSeed += 1;
    setState(() {
      _loopBusy = true;
      _error = null;
      _loading = true;
    });
    try {
      final minutes = _minutes > 0 ? _minutes : 60;
      final result = await _routes.planLoop(
        from: origin,
        profile: _profile,
        minutes: minutes,
        seed: _loopSeed,
      );
      if (!mounted) return;
      final start = result.coordinates.first;
      final end = result.coordinates.last;
      setState(() {
        _start = start;
        _end = end;
        _vias.clear();
        _computed = result;
        _ideaPin = null;
        _selectedTourId = null;
        _adaptingTour = null;
        _adaptingTourName = null;
        _label = l10n.discoverAroundYouLoop;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        _detailId = null;
        _pick = _PickMode.none;
        _startAddrCtrl.text = l10n.discoverMyPosition;
        _endAddrCtrl.text = l10n.discoverMyPosition;
        _aroundYouApplied = true;
        _loopBusy = false;
        _loading = false;
        _aroundYouStats = l10n.discoverAroundYouStats(
          (result.distanceM / 1000).toStringAsFixed(1),
          (result.durationS / 60).round(),
        );
        _setStatus(
          '${l10n.discoverAroundYouHint} · $_aroundYouStats · ${l10n.discoverAroundYouUncertainShort}',
        );
      });
      await _drawRoute(result);
      await _syncMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loopBusy = false;
        _loading = false;
        _error = _liveRouteError(e);
      });
    }
  }

  Widget _aroundYouCta({bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    if (!profileAllowsOsmRoundTrip(_profile)) return const SizedBox.shrink();
    final label = _loopBusy
        ? l10n.discoverAroundYouBusy
        : _aroundYouApplied
            ? l10n.discoverAroundYouAnother
            : l10n.discoverAroundYouCta;
    final icon = _loopBusy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const ChromeGlyph('loop', size: 20);
    void onPressed() => unawaited(_generateAroundYou(next: _aroundYouApplied));
    final button = compact
        ? OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.chrome,
              minimumSize: const Size(0, 40),
            ),
            onPressed: _loopBusy ? null : onPressed,
            icon: icon,
            label: Text(label),
          )
        : FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chrome,
              minimumSize: const Size(0, 48),
            ),
            onPressed: _loopBusy ? null : onPressed,
            icon: icon,
            label: Text(label),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          button,
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              l10n.discoverAroundYouHint,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            if (_aroundYouStats != null) ...[
              const SizedBox(height: 2),
              Text(
                '$_aroundYouStats · ${l10n.discoverAroundYouUncertainShort}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            if (_aroundYouApplied)
              for (final r in _loopJustificationReasons(l10n))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    r,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
          ] else if (_aroundYouStats != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$_aroundYouStats · ${l10n.discoverAroundYouUncertainShort}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }

  /// Filter-Empty: ein Tap setzt zurück — kein toter Hinweistext.
  Widget _emptyFilterState() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Card(
        color: AppColors.surfaceDark,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formFilter == TourFormKey.downhill
                    ? l10n.filterNoDownhillTours
                    : _trailScaleFilter.isNotEmpty
                        ? l10n.filterNoScaleTours
                        : l10n.emptyToursTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                _formFilter == TourFormKey.downhill
                    ? l10n.filterNoDownhillToursHint
                    : _trailScaleFilter.isNotEmpty
                        ? l10n.filterSingletrailHint
                        : l10n.emptyToursFiltersBody,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.chrome,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () {
                  _resetFilters();
                },
                icon: const ChromeGlyph('filter', size: 22),
                label: Text(l10n.filterResetFilters),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zweite Sektion: Katalog, Live (OSM/OA) und Seed-Fallback getrennt.
  List<Widget> _toursSection() {
    final list = _filtered;
    final pinnedId = _selectedTourId;
    bool skip(_RouteSuggestion r) => pinnedId != null && r.id == pinnedId;
    final catalogAll = list.where((r) => r.isCatalog && !skip(r)).toList();
    final live =
        list.where((r) => !r.isCatalog && !r.isSeed && !skip(r)).toList();
    // Seed strip for ~60 / Rundkurs: honest loops only — never fill with A→B.
    final seedsAll = list.where((r) => r.isSeed && !skip(r)).toList();
    final seeds = _loopOnlyActive ? seedsAll.where(_isLoop).toList() : seedsAll;
    final o = _origin;
    const seedRadiusKm = TourCoverage.nearbyRadiusKm;
    // Katalog-Runden in GPS-Nähe gehören in dieselbe Liste wie Seeds —
    // sonst fehlt z. B. Wiesloch Feierabend unter „in der Nähe“.
    final nearbyCatalog = <_RouteSuggestion>[];
    final catalog = <_RouteSuggestion>[];
    for (final r in catalogAll) {
      final away = _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude);
      final near = _hasRealOrigin && _isLoop(r) && away <= seedRadiusKm;
      if (near) {
        nearbyCatalog.add(r);
      } else {
        catalog.add(r);
      }
    }
    final nearbyCards = [...seeds, ...nearbyCatalog]
      ..sort(_byDistanceThenDurationFit);
    final showSeeds = nearbyCards.isNotEmpty;
    final seedLabel = _minutes == DiscoverExploreChromeLogic.defaultDurationMin
        ? _l10n.discoverNearbySection
        : _l10n.naeheLocationLabel(
            hasOrigin: _hasRealOrigin,
            raw: _hasRealOrigin
                ? _seedsBundle?.labelWithLocation
                : _seedsBundle?.labelWithoutLocation,
          );

    final loopCount = list.where(_isLoop).length;
    final nearbyLoopCount = list.where((r) {
      if (!_isLoop(r)) return false;
      return _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude) <=
          seedRadiusKm;
    }).length;

    final refresh = TextButton(
      onPressed: _loading || !_browseOnline
          ? null
          : () {
              unawaited(_fetchPublicCatalog());
              unawaited(_fetchOutdooractive());
              unawaited(_fetchOsmRoutes());
              unawaited(_fetchTrailNetwork());
              unawaited(_loadNaeheSeeds());
            },
      child: Text(_l10n.discoverRefresh),
    );
    return [
      if (!showSeeds)
        _sectionTitle(
          list.isEmpty
              ? _l10n.discoverTours
              : _loopOnlyActive && loopCount > 0
                  ? _l10n.discoverToursLoops(loopCount)
                  : _l10n.discoverToursCount(list.length),
          hint: _hasRealOrigin ? null : _l10n.discoverNoGpsCurated,
          trailing: refresh,
        ),
      // Eine Statuszeile statt Standort + Seeds + OA + Trailnetz + Heatmap.
      Builder(
        builder: (_) {
          String? line;
          TextStyle style =
              const TextStyle(fontSize: 12, color: AppColors.muted);
          VoidCallback? onTap;
          if (!_hasRealOrigin) {
            line = _l10n.discoverGrantLocationNearby;
          } else if (!_browseOnline) {
            line = _l10n.discoverOaOffline;
            style = const TextStyle(fontSize: 11, color: AppColors.muted);
          } else if (showSeeds) {
            line = null;
          } else if (_oaIsDegraded) {
            line = _oaStatus;
            style = const TextStyle(fontSize: 11, color: AppColors.muted);
          } else if (_trailIsDegraded) {
            line = _trailNetworkStatus;
            style = const TextStyle(fontSize: 11, color: AppColors.muted);
          } else if (!_heatmapConsent) {
            line = _l10n.discoverHeatmapConsent;
            style = const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              decoration: TextDecoration.underline,
            );
            onTap = () async {
              await openPrivacyScreen(context);
              if (mounted) await _loadHeatmapConsent();
            };
          } else if (_heatmapNote != null) {
            line = _heatmapNote;
            style = const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            );
          }
          if (line == null) return const SizedBox.shrink();
          final child = Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(line, style: style),
          );
          if (onTap == null) return child;
          return InkWell(onTap: onTap, child: child);
        },
      ),
      if (_selectedTrailId != null)
        Builder(
          builder: (_) {
            OsmTrailSegment? sel;
            for (final t in _trailNetwork) {
              if (t.id == _selectedTrailId) {
                sel = t;
                break;
              }
            }
            if (sel == null) return const SizedBox.shrink();
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.s),
              child: ListTile(
                dense: true,
                leading: ChromeGlyph(
                  'elevation',
                  size: 22,
                  color: Color(
                    int.parse('FF${sel.lineColor.substring(1)}', radix: 16),
                  ),
                ),
                title: Text(sel.name),
                subtitle: Text(
                  '${sel.difficultyLabel} · ${sel.lengthKm.toStringAsFixed(1)} km',
                ),
                trailing: IconButton(
                  tooltip: _l10n.discoverRideToStartShort,
                  icon: const ChromeGlyph('nav', size: 22),
                  onPressed: () => unawaited(_approachTrail(sel!)),
                ),
                onTap: () => unawaited(_showTrailSheet(sel!)),
              ),
            );
          },
        ),
      // Empty only when zero honest loops in the filtered list — never hide
      // nearby seed cards behind the ort picker while loops exist (S25).
      if (list.isEmpty && _formFilter == TourFormKey.downhill)
        _emptyFilterState()
      else if (loopCount == 0 && _loopOnlyActive)
        _emptyOrtPicker()
      else if (list.isEmpty)
        !_filtersAtDefaults ? _emptyFilterState() : _emptyOrtPicker()
      else if (nearbyLoopCount == 0 &&
          _minutes == DiscoverExploreChromeLogic.defaultDurationMin &&
          loopCount > 0 &&
          !showSeeds)
        _emptyOrtPicker(),
      if (_loopOnlyActive &&
          profileAllowsOsmRoundTrip(_profile) &&
          loopCount > 0 &&
          (showSeeds || nearbyLoopCount > 0))
        _aroundYouCta(compact: true),
      if (showSeeds) ...[
        _sectionTitle(
          _seedsOffline
              ? '$seedLabel (${nearbyCards.length}) · ${_l10n.rideGroupOffline}'
              : '$seedLabel (${nearbyCards.length})',
          hint: _hasRealOrigin
              ? (nearbyLoopCount > 0
                  ? _l10n.discoverLoopsNearby
                  : _l10n.discoverNoLoop90)
              : _l10n.discoverRecommendedNoGps,
          trailing: refresh,
        ),
        for (final r in nearbyCards) _tourListCard(r, o),
      ],
      if (catalog.isNotEmpty) ...[
        _sectionTitle(
          _l10n.discoverRecommended(catalog.length),
          hint: _l10n.discoverRecommendedHint,
        ),
        for (final r in catalog) _tourListCard(r, o),
      ],
      if (live.isNotEmpty) ...[
        _sectionTitle(
          _l10n.discoverInRegion(live.length),
          hint: _hasRealOrigin
              ? _l10n.discoverToursAround
              : _l10n.discoverAfterLocation,
        ),
        for (final r in live) _tourListCard(r, o),
      ],
    ];
  }

  /// Komoot/AllTrails-style photo hero: big image, difficulty + distance,
  /// loop mini-map inset — never blank/black. [borderRadius] erlaubt der
  /// Detail-Ansicht volle Rundung (Karte rundet nur oben).
  /// [enableCarousel]: Detail PageView + Dots (Komoot-Stil).
  Widget _tourHero(
    _RouteSuggestion r,
    GeoPoint o, {
    BorderRadius? borderRadius,
    bool showScanChips = true,
    bool enableCarousel = false,
  }) {
    const height = 196.0;
    final loop = _isLoop(r);
    final urls = <String>[...r.heroPhotoUrls];
    if (enableCarousel) {
      for (final u in _communityHeroUrls[r.id] ?? const <String>[]) {
        if (!urls.contains(u)) urls.add(u);
      }
    }

    Widget slideForUrl(String url) {
      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _paintedHeroFallback(r, height),
        );
      }
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _paintedHeroFallback(r, height),
        );
      }
      return _paintedHeroFallback(r, height);
    }

    // Detail: echte Fotos; bei nur einem Thumb zusätzlich painted Fallback-Slide
    // (kein Fake-Community-Foto). Liste: erstes Bild / painted.
    final slides = <Widget>[];
    if (urls.isEmpty) {
      if (!r.isSeed && !enableCarousel) return const SizedBox.shrink();
      slides.add(_paintedHeroFallback(r, height));
    } else {
      for (final u in urls) {
        slides.add(slideForUrl(u));
      }
      if (enableCarousel && urls.length == 1) {
        slides.add(_paintedHeroFallback(r, height));
      }
    }

    final radius = borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(AppRadius.card));
    final track = _routedLoopCache[r.id] != null
        ? [
            for (final p in _routedLoopCache[r.id]!) [p.lng, p.lat],
          ]
        : r.trackLngLat;

    if (!enableCarousel || slides.length <= 1) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              slides.first,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x66000000)],
                    stops: [0.55, 1.0],
                  ),
                ),
              ),
              if (showScanChips)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroChip(
                        mark: 'elevation',
                        label: _difficultyDisplay(_l10n, r.mtbScale),
                        emphasize: true,
                      ),
                      const SizedBox(height: 6),
                      _HeroChip(
                        mark: 'split',
                        label:
                            '${r.distanceKm.toStringAsFixed(r.distanceKm < 10 ? 1 : 0)} km',
                      ),
                    ],
                  ),
                ),
              if (loop)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _LoopMiniMap(
                    size: 60,
                    stroke: AppColors.sageOnDark,
                    fill: AppColors.sage.withValues(alpha: 0.20),
                    showStart: true,
                    track: track,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return _TourHeroCarousel(
      height: height,
      borderRadius: radius,
      slides: slides,
      showScanChips: showScanChips,
      difficultyLabel: _difficultyDisplay(_l10n, r.mtbScale),
      distanceLabel:
          '${r.distanceKm.toStringAsFixed(r.distanceKm < 10 ? 1 : 0)} km',
      loop: loop,
      loopTrack: track,
    );
  }

  Widget _paintedHeroFallback(_RouteSuggestion r, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.overlay,
            AppColors.surfaceDark,
            AppColors.hofGround,
          ],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Text(
        r.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.chipIdleText,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  /// Peek: Name, Dauer, Runden-km und Abstand — kein Hero, der den Titel frisst.
  Widget _tourPeekCard(_RouteSuggestion r, GeoPoint o) {
    final l10n = AppLocalizations.of(context);
    final loopKm = DiscoverExploreChromeLogic.formatLoopKm(r.distanceKm);
    final awayKm = _hasRealOrigin
        ? DiscoverExploreChromeLogic.formatAwayKm(
            _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude),
          )
        : null;
    final sport = TourFilters.honestSportLabel(
      sportLabel: r.sportLabel,
      surface: r.surface,
    );
    final meta = <String>[
      _fmtRideDuration(r.durationMin, l10n),
      l10n.discoverPeekLoopKm(loopKm),
      if (sport != null) _l10n.sportTagLabel(sport),
    ];
    final away = awayKm == null
        ? null
        : (awayKm == 0
            ? l10n.discoverPeekAwayNear
            : l10n.discoverPeekAwayKm(awayKm));
    return Material(
      key: const Key('discover-peek-card'),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
      child: InkWell(
        onTap: () => unawaited(
          _snapDiscoverSheet(DiscoverBrowseSheetSnaps.half),
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.s,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tourDisplayName(r.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.2,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              if (away != null) ...[
                const SizedBox(height: 2),
                Text(
                  away,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted.withValues(alpha: 0.9),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              DiscoverPeekActions(
                navigateLabel:
                    _isPinOnlyIdea(r) ? l10n.discoverSetEndCta : null,
                onNavigate: () {
                  if (_isPinOnlyIdea(r)) {
                    unawaited(_adoptTourIntoPlan(r));
                  } else {
                    unawaited(_startRide(suggestion: r));
                  }
                },
                onSave: () => unawaited(_saveTourToLibrary(r)),
                onAkte: () => unawaited(_openDetail(r.id, r.center)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tourListCard(_RouteSuggestion r, GeoPoint o) {
    final l10n = AppLocalizations.of(context);
    final loop = _isLoop(r);
    final selected = _selectedTourId == r.id;
    final distKm = _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude);
    final pinOnly = _isPinOnlyIdea(r);
    // Eine Meta-Zeile wie Komoot: Dauer · km · hm · Form — kein Pitch/★ in der Liste.
    final metaParts = <String>[
      _fmtRideDuration(r.durationMin, l10n),
      '${r.distanceKm.toStringAsFixed(r.distanceKm < 10 ? 1 : 0)} km',
      if (r.elevationM > 0) '↑ ${r.elevationM} m',
      if (loop) l10n.loopLabel,
    ];
    final awayKm = DiscoverExploreChromeLogic.formatAwayKm(distKm);
    final nearLabel = awayKm == 0
        ? l10n.discoverPeekAwayNear
        : l10n.discoverPeekAwayKm(awayKm);
    final sport = TourFilters.honestSportLabel(
      sportLabel: r.sportLabel,
      surface: r.surface,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surfaceDark,
        elevation: selected ? 2 : 0,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.55)
                : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (r.isSeed || r.thumbnailUrl != null)
                InkWell(
                  onTap: () => unawaited(_previewTourOnMap(r)),
                  child: _tourHero(r, o),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.m,
                  AppSpacing.m,
                  AppSpacing.s + 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => unawaited(_previewTourOnMap(r)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tourDisplayName(r.name),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.2,
                              color: selected ? AppColors.accent : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TourSocialProof(tourId: r.id),
                          const SizedBox(height: 6),
                          Text(
                            metaParts.join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sport == null
                                ? nearLabel
                                : '$nearLabel · ${_l10n.sportTagLabel(sport)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    // Eine Primäraktion — Details über Titel-Tap / overflow.
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.chrome,
                              foregroundColor: AppColors.onAccent,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                            onPressed: _loading
                                ? null
                                : pinOnly
                                    ? () => unawaited(_adoptTourIntoPlan(r))
                                    : () =>
                                        unawaited(_startRide(suggestion: r)),
                            icon: ChromeGlyph(
                              pinOnly ? 'flag' : 'play',
                              size: 20,
                              color: AppColors.onAccent,
                            ),
                            label: Text(
                              pinOnly ? l10n.discoverSetEndCta : l10n.goRide,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: l10n.tourDetails,
                          onPressed: () =>
                              unawaited(_openDetail(r.id, r.center)),
                          icon: const ChromeGlyph('hint', size: 22),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          tooltip: l10n.moreActions,
                          onPressed: () => unawaited(_openTourOverflow(r)),
                          icon: const Icon(Icons.more_horiz),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _savedTiles({bool includeTitle = true}) {
    final l10n = AppLocalizations.of(context);
    final allSaved =
        ref.watch(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    final savedList = RouteVisibility.filter(
      allSaved,
      ref.watch(tourVisibilityProvider),
      _savedMeta,
    );
    return [
      if (includeTitle) ...[
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.navPlatz,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
      ],
      if (savedList.isEmpty && allSaved.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: MappeEmptyBlock(
            compact: true,
            title: l10n.mappeEmptyTitle,
            hint: l10n.myRoutesEmpty,
          ),
        )
      else if (savedList.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                _l10n.discoverNoSavedFilter,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              TextButton(
                onPressed: () {
                  ref.read(tourVisibilityProvider.notifier).state =
                      TourVisibilityKey.allMine;
                },
                child: Text(l10n.mappeShowAll),
              ),
            ],
          ),
        )
      else
        for (final s in savedList)
          SavedMappeTile(
            route: s,
            meta: _savedMeta[s.id],
            sourceBadge: _sourceBadge(l10n, s.source),
            onOpen: () => _loadSaved(s),
            onDetail: () => unawaited(_openMyRouteDetail(s)),
            onDelete: () async {
              await _routes.deleteSaved(s.id);
              await SavedRouteMetaStore.delete(s.id);
              ref.invalidate(savedRoutesProvider);
              unawaited(_drawAll());
            },
            onGoRide: savedRouteHasTrack(s)
                ? () => unawaited(_startRideFromSaved(s))
                : null,
          ),
    ];
  }

  String _sourceBadge(AppLocalizations l10n, String source) {
    return mappeSourceChip(
          source,
          importLabel: l10n.myRoutesSourceImport,
          recordedLabel: l10n.myRoutesSourceRecorded,
          ownLabel: l10n.discoverOwn,
        ) ??
        '';
  }

  bool _akteConsumeBusy = false;

  Future<void> _consumePendingStartRide() async {
    final id = ref.read(discoverPendingStartRideRouteIdProvider);
    if (id == null || id.isEmpty) return;
    var list = ref.read(savedRoutesProvider).valueOrNull ?? const [];
    if (list.isEmpty) {
      try {
        list = await ref.read(savedRoutesProvider.future);
      } catch (_) {
        list = const [];
      }
    }
    var metas = await SavedRouteMetaStore.listAll();
    var match = resolveAkteSavedRoute(
      pendingId: id,
      saved: list,
      metas: metas,
    );
    if (match == null) {
      final tour = _tourById(id);
      if (tour == null && _tours.isEmpty) {
        return;
      }
      if (tour != null) {
        await _saveTourToLibrary(tour, quiet: true);
        ref.invalidate(savedRoutesProvider);
        try {
          list = await ref.read(savedRoutesProvider.future);
        } catch (_) {
          list = ref.read(savedRoutesProvider).valueOrNull ?? list;
        }
        metas = await SavedRouteMetaStore.listAll();
        match = resolveAkteSavedRoute(
          pendingId: id,
          saved: list,
          metas: metas,
        );
        ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = null;
        if (match != null) {
          await _startRideFromSaved(match);
          return;
        }
        await _startRide(suggestion: tour);
        return;
      }
    }
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = null;
    if (match == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.discoverNoTrackOnMap)),
      );
      return;
    }
    await _startRideFromSaved(match);
  }

  Future<void> _consumePendingAkte() async {
    if (_akteConsumeBusy) return;
    final id = ref.read(discoverPendingAkteRouteIdProvider);
    if (id == null || id.isEmpty) return;
    _akteConsumeBusy = true;
    try {
      Future<List<SavedRouteEntry>> loadSaved() async {
        var list = ref.read(savedRoutesProvider).valueOrNull ?? const [];
        if (list.isEmpty) {
          try {
            list = await ref.read(savedRoutesProvider.future);
          } catch (_) {
            list = const [];
          }
        }
        return list;
      }

      var list = await loadSaved();
      var metas = await SavedRouteMetaStore.listAll();
      var match = resolveAkteSavedRoute(
        pendingId: id,
        saved: list,
        metas: metas,
      );

      if (match == null) {
        final tour = _tourById(id);
        if (tour == null && _tours.isEmpty) {
          // Katalog noch nicht da — nach dem Laden erneut.
          return;
        }
        if (tour != null) {
          await _saveTourToLibrary(tour);
          ref.invalidate(savedRoutesProvider);
          try {
            list = await ref.read(savedRoutesProvider.future);
          } catch (_) {
            list = await loadSaved();
          }
          metas = await SavedRouteMetaStore.listAll();
          match = resolveAkteSavedRoute(
            pendingId: id,
            saved: list,
            metas: metas,
          );
        }
      }

      ref.read(discoverPendingAkteRouteIdProvider.notifier).state = null;
      if (!mounted) return;
      if (match == null) {
        final tour = _tourById(id);
        if (tour != null) {
          await _openDetail(id, tour.center);
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await _openMyRouteDetail(match);
    } finally {
      _akteConsumeBusy = false;
    }
  }

  Future<void> _reloadSavedMeta() async {
    final all = await SavedRouteMetaStore.listAll();
    if (!mounted) return;
    setState(() => _savedMeta = all);
  }

  Future<void> _openMyRouteDetail(SavedRouteEntry s) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return TourAkteSheet(
          route: s,
          sourceBadge: _sourceBadge(l10n, s.source),
          onShowOnMap: () {
            Navigator.pop(ctx);
            unawaited(_loadSaved(s));
          },
          onGoRide: () {
            Navigator.pop(ctx);
            unawaited(_startRideFromSaved(s));
          },
          onCreateGroup: () {
            Navigator.pop(ctx);
            ref.read(platzPendingCreateGroupRouteIdProvider.notifier).state =
                s.id;
            ref.read(shellTabIndexProvider.notifier).state = ShellTabs.platz;
          },
        );
      },
    );
    unawaited(_reloadSavedMeta());
    unawaited(_drawAll());
  }
}

/// Beschreibung mit „Mehr anzeigen" (Komoot-Detail): kollabiert auf drei
/// Zeilen; der Toggle erscheint nur, wenn der Text wirklich überläuft —
/// kurzer Text bleibt eine schlichte Textzeile.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _style = TextStyle(fontSize: 13, height: 1.4);
  static const _trimLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final probe = TextPainter(
          text: TextSpan(text: widget.text, style: _style),
          maxLines: _trimLines,
          textDirection: Directionality.of(context),
        )..layout(
            maxWidth: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : double.infinity,
          );
        final overflows = probe.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: _style,
              maxLines: _expanded ? null : _trimLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.chrome,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? AppLocalizations.of(context).discoverShowLess
                      : AppLocalizations.of(context).discoverShowMore,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Komoot-style PageView hero with page dots (Tour-Detail).
class _TourHeroCarousel extends StatefulWidget {
  const _TourHeroCarousel({
    required this.height,
    required this.borderRadius,
    required this.slides,
    required this.showScanChips,
    required this.difficultyLabel,
    required this.distanceLabel,
    required this.loop,
    required this.loopTrack,
  });

  final double height;
  final BorderRadius borderRadius;
  final List<Widget> slides;
  final bool showScanChips;
  final String difficultyLabel;
  final String distanceLabel;
  final bool loop;
  final List<List<double>>? loopTrack;

  @override
  State<_TourHeroCarousel> createState() => _TourHeroCarouselState();
}

class _TourHeroCarouselState extends State<_TourHeroCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => widget.slides[i],
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x66000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
            if (widget.showScanChips)
              Positioned(
                left: 10,
                top: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroChip(
                      mark: 'elevation',
                      label: widget.difficultyLabel,
                      emphasize: true,
                    ),
                    const SizedBox(height: 6),
                    _HeroChip(
                      mark: 'flag',
                      label: widget.distanceLabel,
                    ),
                  ],
                ),
              ),
            if (widget.loop)
              Positioned(
                right: 10,
                bottom: 28,
                child: _LoopMiniMap(
                  size: 60,
                  stroke: AppColors.sageOnDark,
                  fill: AppColors.sage.withValues(alpha: 0.20),
                  showStart: true,
                  track: widget.loopTrack,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.slides.length; i++)
                    Container(
                      width: i == _page ? 8 : 6,
                      height: i == _page ? 8 : 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: i == _page ? 0.95 : 0.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay chip on tour heroes (difficulty / distance) — Komoot-style.
class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.mark,
    required this.label,
    this.emphasize = false,
  });

  final String mark;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.overlay.withValues(alpha: 0.90)
            : AppColors.hofGround.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChromeGlyph(mark, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini loop preview inset (Komoot/AllTrails card map thumbnail).
/// Mit [track] (Polyline `[lng, lat]`) zeichnet der Painter die echte,
/// normalisierte Routenform statt des generischen Ovals.
class _LoopMiniMap extends StatelessWidget {
  const _LoopMiniMap({
    required this.size,
    required this.stroke,
    required this.fill,
    this.showStart = false,
    this.track,
  });

  final double size;
  final Color stroke;
  final Color fill;
  final bool showStart;
  final List<List<double>>? track;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _LoopMiniMapPainter(
            stroke: stroke,
            fill: fill,
            showStart: showStart,
            track: track,
          ),
        ),
      ),
    );
  }
}

class _LoopMiniMapPainter extends CustomPainter {
  const _LoopMiniMapPainter({
    required this.stroke,
    required this.fill,
    required this.showStart,
    this.track,
  });

  final Color stroke;
  final Color fill;
  final bool showStart;
  final List<List<double>>? track;

  @override
  void paint(Canvas canvas, Size size) {
    final t = track;
    if (t != null && t.length >= 2) {
      _paintTrack(canvas, size, t);
      return;
    }
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.52),
      width: size.width * 0.62,
      height: size.height * 0.48,
    );
    final path = Path()..addOval(rect);
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    if (showStart) {
      final a = Offset(rect.center.dx, rect.top);
      canvas.drawCircle(a, 4.5, Paint()..color = AppColors.accent);
      canvas.drawCircle(a, 2.2, Paint()..color = Colors.white);
    }
  }

  /// Echte Geometrie: fit in die Box (Padding 9), Längengrade mit
  /// cos(lat) korrigiert, damit die Form nicht plattgedrückt wird.
  /// Stroke-first (kein Fill), Start- + End-Punkt — keine Kreis-/Ellipsen-Optik.
  void _paintTrack(Canvas canvas, Size size, List<List<double>> t) {
    var minLng = double.infinity;
    var maxLng = double.negativeInfinity;
    var minLat = double.infinity;
    var maxLat = double.negativeInfinity;
    for (final p in t) {
      if (p.length < 2) continue;
      minLng = math.min(minLng, p[0]);
      maxLng = math.max(maxLng, p[0]);
      minLat = math.min(minLat, p[1]);
      maxLat = math.max(maxLat, p[1]);
    }
    if (!minLng.isFinite || !minLat.isFinite) return;
    final midLat = (minLat + maxLat) / 2;
    final midLng = (minLng + maxLng) / 2;
    final cosLat = math.cos(midLat * math.pi / 180).abs().clamp(0.05, 1.0);
    // 1e-9: Degenerate-Guard (alle Punkte identisch) — nie durch 0 teilen.
    final wDeg = math.max((maxLng - minLng) * cosLat, 1e-9);
    final hDeg = math.max(maxLat - minLat, 1e-9);
    const pad = 9.0;
    final scale = math.min(
      (size.width - pad * 2) / wDeg,
      (size.height - pad * 2) / hDeg,
    );
    Offset project(List<double> p) => Offset(
          size.width / 2 + (p[0] - midLng) * cosLat * scale,
          size.height / 2 + (midLat - p[1]) * scale,
        );
    Path? path;
    Offset? firstPt;
    Offset? lastPt;
    for (final p in t) {
      if (p.length < 2) continue;
      final o = project(p);
      firstPt ??= o;
      lastPt = o;
      if (path == null) {
        path = Path()..moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    if (path == null) return;
    // Soft underlay (not a filled ellipse) — keeps shape readable on dark tile.
    canvas.drawPath(
      path,
      Paint()
        ..color = fill.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (showStart && firstPt != null) {
      canvas.drawCircle(firstPt, 4.5, Paint()..color = AppColors.accent);
      canvas.drawCircle(firstPt, 2.2, Paint()..color = Colors.white);
    }
    // End tip (direction cue) — slightly smaller, offset if closed loop.
    if (lastPt != null && firstPt != null) {
      final closed = (lastPt - firstPt).distance < 3.0;
      if (!closed) {
        canvas.drawCircle(lastPt, 3.2, Paint()..color = stroke);
        canvas.drawCircle(lastPt, 1.4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoopMiniMapPainter oldDelegate) =>
      oldDelegate.stroke != stroke ||
      oldDelegate.fill != fill ||
      oldDelegate.showStart != showStart ||
      oldDelegate.track != track;
}

class _TrailViewSheet extends StatefulWidget {
  const _TrailViewSheet({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  State<_TrailViewSheet> createState() => _TrailViewSheetState();
}

class _TrailViewSheetState extends State<_TrailViewSheet> {
  TrailViewResult? _result;
  String? _error;
  bool _loading = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await fetchTrailViewNear(lat: widget.lat, lng: widget.lng);
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e,
            context: AppLocalizations.of(context).discoverTrailView);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos = _result?.photos ?? const <TrailPhoto>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.discoverTrailView,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (_loading)
              const Padding(
                // 40: großzügiger Spinner-Abstand, keine Rhythmus-Stufe.
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error))
            else ...[
              SizedBox(
                height: 220,
                child: photos.isEmpty
                    ? Center(child: Text(l10n.discoverNoPhotosNearby))
                    : PageView.builder(
                        itemCount: photos.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (ctx, i) {
                          final p = photos[i];
                          if (p.isNetworkImage) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.chip,
                              ),
                              child: Image.network(
                                p.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => AppConfig
                                        .allowDemoContent
                                    ? _demoTile(p.title)
                                    : Center(
                                        child:
                                            Text(l10n.discoverImageUnavailable),
                                      ),
                              ),
                            );
                          }
                          return AppConfig.allowDemoContent
                              ? _demoTile(p.title)
                              : Center(child: Text(l10n.discoverNoLivePhotos));
                        },
                      ),
              ),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  photos[_page.clamp(0, photos.length - 1)].title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  photos[_page.clamp(0, photos.length - 1)].attributionHtml,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              Text(
                _result?.disclaimer ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                _result?.attribution ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              OutlinedButton.icon(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://www.mapillary.com/app/?lat=${widget.lat}&lng=${widget.lng}&z=16',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const ChromeGlyph('share', size: 20),
                label: Text(l10n.discoverOpenMapillary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _demoTile(String title) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.elevated, AppColors.surfaceDark],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.chipIdleText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            (_result?.usingDemo == true)
                ? AppLocalizations.of(context).discoverMapillarySample
                : AppLocalizations.of(context).discoverPreview,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.chipIdleText.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniElevPainter extends CustomPainter {
  _MiniElevPainter(this.samples);

  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || size.width <= 0 || size.height <= 0) return;
    var minV = samples.first;
    var maxV = samples.first;
    for (final v in samples) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV).abs() < 1 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = size.width * i / (samples.length - 1);
      final y =
          size.height - ((samples[i] - minV) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    // Fläche unter der Linie (Komoot-Profil) — dezent auslaufender Verlauf.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.30),
            AppColors.accent.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniElevPainter oldDelegate) =>
      oldDelegate.samples != samples;
}
