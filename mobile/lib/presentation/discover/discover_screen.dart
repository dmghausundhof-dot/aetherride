import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import '../../data/import/gpx_import.dart';
import '../../data/routing/elevation_client.dart';
import '../../data/routing/geocode_client.dart';
import '../../data/routing/osm_routes_client.dart';
import '../../data/routing/osm_trail_network_client.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/coverage_client.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../data/routing/naehe_seeds.dart';
import '../../data/routing/public_tours_client.dart';
import '../../data/routing/route_collections.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/routing_client.dart';
import '../../data/routing/simple_add_route.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/routing/duration_lens.dart';
import '../../domain/routing/tour_filters.dart';
import '../../domain/routing/tour_coverage.dart';
import '../../domain/routing/heatmap.dart';
import '../../data/routing/heatmap_client.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/routing_status_client.dart';
import '../../domain/routing/engine_steps_along.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../domain/routing/route_shape.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/routing/trail_difficulty.dart';
import '../../domain/routing/trail_view.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../data/routing/saved_route_meta_store.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../profile/profile_screen.dart';
import '../home/hof_watch_card.dart';
import '../shell/shell_tabs.dart';
import '../map/map_pin_image.dart';
import '../shared/status_bar_scrim.dart';
import 'discover_browse_sheet_snaps.dart';
import 'discover_shell_mode.dart';
import 'saved_route_notes_section.dart';
import 'discover_map_line_style.dart';
import 'bike_overlay_legend.dart';
import 'widgets/tour_community_section.dart';
import 'widgets/tour_social_proof.dart';
import 'offline_maps_sheet.dart';

/// Profil-Menü: City/Trekking/Gravel/Road zuerst — kein MTB-first Default.
const _kDiscoverProfileMenuOrder = <RoutingProfile>[
  RoutingProfile.urban,
  RoutingProfile.ebikeTour,
  RoutingProfile.gravel,
  RoutingProfile.road,
  RoutingProfile.mtbTrail,
  RoutingProfile.mtbEnduro,
  RoutingProfile.emtb,
  RoutingProfile.hiking,
];

/// MapLibre in Flutter braucht Eager-Gesten, sonst frisst Parent/PlatformView Zoom/Pan.
Set<Factory<OneSequenceGestureRecognizer>> get _mapGestures =>
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
    };

class _TfPin {
  const _TfPin({
    required this.id,
    required this.name,
    required this.center,
    required this.openUrl,
    this.difficulty,
    this.conditionLabel,
  });
  final String id;
  final String name;
  final LatLng center;
  final String openUrl;
  final String? difficulty;
  final String? conditionLabel;
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
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.etrekking,
      BikeCategory.emtb,
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

  String get sourceLabel => switch (sourceKind) {
    'catalog' => 'Katalog',
    'osm' => 'OSM live',
    'outdooractive' => 'Outdooractive',
    'seed' => 'Region',
    _ => 'Tour',
  };

  _RouteSuggestion copyWith({List<List<double>>? trackLngLat}) {
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
      center: center,
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
String _fmtRideDuration(int minutes) {
  if (minutes <= 0) return '—';
  if (minutes < 60) return '$minutes Min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

/// Icon je POI-Stop-Art (Seeds: trailhead/viewpoint/cafe/culture/water/…).
IconData _poiKindIcon(String kind) => switch (kind.toLowerCase().trim()) {
  'trailhead' => Icons.flag,
  'viewpoint' => Icons.landscape,
  'cafe' => Icons.local_cafe,
  'culture' => Icons.museum,
  'water' => Icons.water_drop,
  'transit' => Icons.tram,
  'meetup' => Icons.groups,
  _ => Icons.place,
};

/// Übersetzt eine rohe Schwierigkeits-Angabe (OSM S-Skala oder Outdooractive-
/// Klartext wie "mittel") in ein Label ohne Nachschlagen. Der Rohwert bleibt
/// über [trailDifficultyLabel]/Tooltips im Detail abrufbar.
String _difficultyDisplay(String raw) {
  final parsed = parseTrailDifficulty(raw);
  if (parsed != TrailDifficulty.open) {
    return trailDifficultyFriendlyLabel(parsed);
  }
  final t = raw.trim();
  if (t.isEmpty || t.toLowerCase() == 'offen') return 'Nicht eingestuft';
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

class DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _pinImagesReady = false;
  bool _bikeOverlayAttached = false;
  bool _bikeOverlayOn = true;
  final Set<BikeOverlayClass> _bikeOverlayExtra = {};
  int _drawGen = 0;
  LatLng? _ideaPin;
  List<Symbol> _tfSymbols = [];
  final Map<String, _TfPin> _tfBySymbolId = {};
  List<CoveragePlace> _googlePlaces = [];
  final Map<String, CoveragePlace> _placeBySymbolId = {};

  /// Live-geroutete Loop-Geometrie pro Seed-Tour (ersetzt den synthetischen
  /// Kreis, sobald die Routing-Engine antwortet) — Komoot zeigt echte Wege.
  final Map<String, List<GeoPoint>> _routedLoopCache = {};
  final Set<String> _routedLoopPending = {};

  _Surface _surface = _Surface.discover;
  /// Primäre Map-Shell: Entdecken | Navigieren | Meine.
  DiscoverShellMode _shellMode = DiscoverShellMode.explore;
  /// Neutral bis Garage/Profil greift — nicht MTB-lastig vorwählen.
  RoutingProfile _profile = RoutingProfile.urban;

  /// Default-Lens ~60 Min (D-60-01); 0 = egal.
  int _minutes = 60;
  bool _loading = false;
  String? _error;
  String? _status;

  GeoPoint? _userPos;
  GeoPoint? _start;
  GeoPoint? _end;

  /// Origin, für den Kamera + „Schnell"-Vorschläge zuletzt angewendet wurden.
  /// `null` = noch nie ein echter (nicht-Fallback-)Origin gesehen.
  /// Ersetzt einmalige Snapshots (Kaltstart-Fallback vor GPS-Fix) durch
  /// laufenden Abgleich in [_syncOriginDrift], aufgerufen bei jedem Rebuild.
  GeoPoint? _lastAppliedOrigin;
  final List<GeoPoint> _vias = [];
  _PickMode _pick = _PickMode.none;

  RouteResult? _computed;
  RouteResult? _approach;
  RouteResult? _tourLayer;
  List<GeoPoint>? _trailOverlay;
  String? _label;
  List<_QuickOption> _quick = [];
  String? _detailId;
  final Map<String, List<String>> _communityHeroUrls = {};

  List<_RouteSuggestion> _tours = <_RouteSuggestion>[];
  List<OsmTrailSegment> _trailNetwork = [];
  bool _showTrailNetwork = true;
  /// Eigene SavedRoutes dauerhaft als Accent-Layer (nicht nur nach Tap).
  bool _showOwnTracks = true;
  String? _selectedTrailId;
  String? _trailNetworkStatus;
  TrailDifficulty? _trailScaleFilter;

  /// Filtert die Tourenliste auf Nähe zum Zeitbudget [_minutes].
  /// Default an: ~60-Min-Lens mit Band 45–75 (D-60-01).
  bool _matchTourDuration = true;
  TourSurfaceKey? _surfaceFilter;
  TourEffortKey? _effortFilter;
  TourElevationKey? _elevationFilter;
  double? _maxDistanceKm;
  /// Primary Lens ~60 = Rundkurse (D-60). User can turn off via chip.
  bool? _loopOnly = true;

  /// Discover-Browse: true ≈ Half/Full-Snap, false ≈ Peek (Map dominant).
  /// Wird mit [DraggableScrollableSheet] synchron gehalten; Liste/Karte-Toggle
  /// snappt das Sheet statt nur die feste Höhe umzuschalten.
  bool _listBrowseMode = false;

  /// Rausfahren: Karte mit Wahl, ohne Touren-Sheet.
  bool _hofChoice = false;

  /// Nach „Touren anzeigen“: Tap startet Navigation.
  bool _hofDirectNav = false;

  final DraggableScrollableController _discoverSheetCtrl =
      DraggableScrollableController();

  /// Strecken-/Los-Leiste: einziehbar (Drag/Tap), sonst blockiert sie die Map.
  bool _rideBarExpanded = true;

  /// Gesetzt, wenn Planen aus einer Tour („Anpassen") kommt — klarerer Titel.
  String? _adaptingTourName;

  bool _heatmapConsent = false;
  bool _heatmapContributed = false;

  /// Bundled Nähe-Seeds (Berlin) — Fallback ohne GPS / leeres OA·OSM.
  NaeheSeedsBundle? _seedsBundle;
  String? _seedsStatus;

  String? _elevationSummary;
  double? _elevationGainM;

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
  String _mapStyle = AppConfig.mapStyleUrl;
  final _geocode = GeocodeClient();
  final _startAddrCtrl = TextEditingController();
  final _startAddrFocus = FocusNode();
  final _endAddrCtrl = TextEditingController();
  final _endAddrFocus = FocusNode();
  final _exploreSearchCtrl = TextEditingController();
  String _exploreQuery = '';
  List<GeocodeHit> _addrHits = const [];
  bool _addrBusy = false;
  String? _addrTarget; // 'start' | 'end'
  Timer? _addrDebounce;
  int _quickGen = 0;
  String? _selectedTourId;

  /// Nur Karten-Übersicht DACH+FR bis GPS da ist — nie Tour-Origin.
  static const _regionOverview = GeoPoint(47.2, 6.5);

  /// Mindestplatz über dem Panel, der bei geöffneter Tastatur erhalten
  /// bleiben muss — Kopfzeile plus ein Rest Karte. Ohne das würde die
  /// Panel-Höhe (als Prozent der VOLLEN Bildschirmhöhe berechnet) bei
  /// geöffneter Tastatur zusammen mit ihr über den sichtbaren Bereich
  /// hinausragen und ihren oberen Rand — Griff und „Zurück" — nach oben
  /// aus dem Bild schieben, ohne dass ein Overflow-Fehler das anzeigt.
  static const _minMapPeekHeight = 96.0;

  RouteRepository get _routes => ref.read(routeRepositoryProvider);
  final _elevationClient = ElevationClient();

  @override
  void initState() {
    super.initState();
    _locate();
    _loadHeatmapConsent();
    _fetchOutdooractive();
    _fetchOsmRoutes();
    _fetchTrailNetwork();
    _fetchTrailforks();
    unawaited(_fetchPublicCatalog());
    unawaited(_loadNaeheSeeds());
    unawaited(_fetchRoutingStatus());
    unawaited(
      AppConfig.resolveMapStyleUrl().then((s) {
        if (!mounted || s == _mapStyle) return;
        setState(() => _mapStyle = s);
      }),
    );
    // Quick auch ohne GPS — sonst bleibt die Liste leer bis Locate ok ist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
      final active = bikes.cast<Bike?>().firstWhere(
        (b) => b?.isActive == true,
        orElse: () => bikes.isEmpty ? null : bikes.first,
      );
      final sportCat =
          active?.category ?? ref.read(userProfileStoreProvider).preferredSport;
      if (active != null) {
        setState(() {
          _profile = routingProfileForBike(active.category);
          // Sport-aware Dauer-Default (Touring → 2–3 h, sonst ~60).
          _minutes = DurationLens.defaultMinutesForSport(sportCat);
          _matchTourDuration = _minutes > 0;
          if (_minutes == 60) _loopOnly = true;
        });
      } else {
        final preferred = ref.read(userProfileStoreProvider).preferredSport;
        if (preferred != null) {
          setState(() {
            _profile = routingProfileForBike(preferred);
            _minutes = DurationLens.defaultMinutesForSport(preferred);
            _matchTourDuration = _minutes > 0;
            if (_minutes == 60) _loopOnly = true;
          });
        }
      }
      // Deep-Link: lens / loop highlight (ohne start=1; start läuft im Handler).
      final pendingLens = ref.read(discoverPendingLensMinutesProvider);
      if (pendingLens != null) {
        ref.read(discoverPendingLensMinutesProvider.notifier).state = null;
        setState(() {
          _minutes = pendingLens;
          _matchTourDuration = pendingLens > 0;
          if (pendingLens == 60) _loopOnly = true;
        });
      }
      final pendingLoop = ref.read(discoverPendingLoopIdProvider);
      if (pendingLoop != null) {
        ref.read(discoverPendingLoopIdProvider.notifier).state = null;
        setState(() => _selectedTourId = pendingLoop);
      }
      final launch = ref.read(discoverLaunchModeProvider);
      _applyDiscoverLaunch(launch);
      if (_quick.isEmpty) {
        unawaited(_refreshQuick(limit: 3));
      }
    });
  }

  @override
  void dispose() {
    _addrDebounce?.cancel();
    _discoverSheetCtrl.dispose();
    _startAddrCtrl.dispose();
    _startAddrFocus.dispose();
    _endAddrCtrl.dispose();
    _endAddrFocus.dispose();
    _exploreSearchCtrl.dispose();
    super.dispose();
  }

  double get _discoverSheetExtent {
    if (_discoverSheetCtrl.isAttached) return _discoverSheetCtrl.size;
    return _listBrowseMode
        ? DiscoverBrowseSheetSnaps.half
        : DiscoverBrowseSheetSnaps.peek;
  }

  void _syncDiscoverSheetExtent(double extent) {
    final h = extent * MediaQuery.sizeOf(context).height;
    // Kamera-Padding live ohne Rebuild — FAB folgt über ListenableBuilder.
    _panelInset = h;
    final wantList = !DiscoverBrowseSheetSnaps.isPeek(extent);
    if (_listBrowseMode == wantList) return;
    setState(() => _listBrowseMode = wantList);
  }

  Future<void> _snapDiscoverSheet(double size) async {
    final target = DiscoverBrowseSheetSnaps.nearest(size);
    setState(() {
      _listBrowseMode = !DiscoverBrowseSheetSnaps.isPeek(target);
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

  /// Wechselt die Map-Shell (Entdecken | Navigieren | Meine).
  /// Detail wird geschlossen; berechnete Route bleibt auf der Karte.
  void _applyDiscoverLaunch(DiscoverLaunchMode? launch) {
    if (launch == null) return;
    ref.read(discoverLaunchModeProvider.notifier).state = null;
    if (launch == DiscoverLaunchMode.plan) {
      _setShellMode(
        DiscoverShellMode.navigate,
        status: 'Start & Ziel setzen — dann Route berechnen',
        pick: _PickMode.start,
      );
      return;
    }
    if (launch == DiscoverLaunchMode.rideOut) {
      setState(() {
        _hofChoice = true;
        _hofDirectNav = false;
        _detailId = null;
        _selectedTourId = null;
        _surface = _Surface.discover;
        _shellMode = DiscoverShellMode.explore;
      });
    }
  }

  void _hofJustRide() {
    setState(() {
      _hofChoice = false;
      _hofDirectNav = false;
      _selectedTourId = null;
    });
    ref.read(activeRouteProvider.notifier).state = null;
    ref.read(rideAutostartProvider.notifier).state = true;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
  }

  void _hofShowTours() {
    setState(() {
      _hofChoice = false;
      _hofDirectNav = true;
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
    setState(() {
      _shellMode = mode;
      _detailId = null;
      _addrHits = const [];
      _error = null;
      if (clearAdapting && adaptingTourName == null) {
        _adaptingTourName = null;
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
            _status = status;
          } else if (_adaptingTourName != null) {
            _status ??= 'Start, Ziel oder Stopp anpassen';
          } else {
            // Subtitle am Panel reicht — kein zweiter Hinweis-Text.
            _status = null;
          }
        case DiscoverShellMode.explore:
          _surface = _Surface.discover;
          _pick = _PickMode.none;
          // Keine A→B-Hinweise mehr unter der Tourenliste.
          _status = null;
          _rideBarExpanded = false;
        case DiscoverShellMode.mine:
          _surface = _Surface.discover;
          _pick = _PickMode.none;
          _showOwnTracks = true;
          _status = null;
          _rideBarExpanded = false;
      }
    });
    if (mode == DiscoverShellMode.explore || mode == DiscoverShellMode.mine) {
      unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.half));
    }
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
    setState(() {
      _detailId = tourId;
      _selectedTourId = tourId;
      _surface = _Surface.detail;
    });
    // Höhenprofil im Hintergrund — braucht echte Geometrie (lädt bei Seeds
    // nebenbei das Live-Routing für Karte + Mini-Map nach).
    final tour = _tourById(tourId);
    if (tour != null) unawaited(_ensureDetailElevation(tour));
    unawaited(_loadCommunityHeroes(tourId));
    await _drawAll();
    if (!mounted) return;
    try {
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(center, 12.5));
    } catch (_) {}
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
    });
  }

  /// Inner map/sheet state that system-back must pop before leaving Karte.
  bool get hasInnerBack {
    if (_hofChoice) return true;
    if (_surface == _Surface.detail) return true;
    if (_pick != _PickMode.none) return true;
    if (_shellMode == DiscoverShellMode.navigate) return true;
    if (_shellMode == DiscoverShellMode.mine) return true;
    if (_showRideBar && _rideBarExpanded) return true;
    if (_listBrowseMode) return true;
    if (!DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent)) return true;
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
      _closeDetail();
      return true;
    }
    if (_pick != _PickMode.none) {
      setState(() => _pick = _PickMode.none);
      return true;
    }
    if (_shellMode == DiscoverShellMode.navigate) {
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
        !DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent)) {
      unawaited(_snapDiscoverSheet(DiscoverBrowseSheetSnaps.peek));
      return true;
    }
    return false;
  }

  void _scheduleAddressSearch(String target) {
    _addrDebounce?.cancel();
    _addrDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_searchAddress(target));
    });
  }

  Future<void> _searchAddress(String target) async {
    final q = target == 'end' ? _endAddrCtrl.text : _startAddrCtrl.text;
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
    try {
      final o = _origin;
      final hits = await _geocode.search(q, biasLat: o.lat, biasLng: o.lng);
      if (!mounted) return;
      setState(() {
        _addrHits = hits;
        _addrBusy = false;
        if (hits.isEmpty) {
          _status = 'Keine Treffer für „$q“';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addrBusy = false;
        _status = friendlyErrorMessage(
          e,
          context: 'Adresssuche fehlgeschlagen',
        );
      });
    }
  }

  Future<void> _applyAddressHit(GeocodeHit hit) async {
    final target = _addrTarget ?? 'start';
    final p = GeoPoint(hit.lat, hit.lng);
    final becameOrigin = target != 'end' && _userPos == null && _start == null;
    setState(() {
      if (target == 'end') {
        _end = p;
        _endAddrCtrl.text = hit.label;
        _pick = _PickMode.none;
      } else {
        _start = p;
        _startAddrCtrl.text = hit.label;
        _pick = _PickMode.end;
      }
      _addrHits = const [];
      _status = '${target == 'end' ? 'Ziel' : 'Start'}: ${hit.label}';
    });
    await _syncMarkers();
    if (_map != null) {
      try {
        await _map!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(hit.lat, hit.lng), 12),
        );
      } catch (_) {}
    }
    if (target != 'end' || becameOrigin) {
      _refreshNearbyDataSources();
    }
    if (_start != null && _end != null) {
      await _calcAb();
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

      if (routed.demo || routed.points.length < 2) {
        final c = GeoPoint(tour.center.latitude, tour.center.longitude);
        final end = _suggestedEndNear(tour.center, tour.distanceKm);
        setState(() {
          _start = c;
          _end = end;
          _vias.clear();
          _computed = null;
          _tourLayer = null;
          _approach = null;
          _ideaPin = tour.center;
          _selectedTourId = tour.id;
          _label = '${tour.name} (Plan)';
          _adaptingTourName = tour.name;
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
          // Tour, die gar nicht mehr gemeint war.
          _detailId = null;
          _pick = _PickMode.none;
          _startAddrCtrl.text =
              '${c.lat.toStringAsFixed(4)}, ${c.lng.toStringAsFixed(4)}';
          _endAddrCtrl.text = 'Ziel-Vorschlag (anpassbar)';
          _status =
              'Tour-Idee: Start = Ortspunkt, Ziel-Vorschlag gesetzt — Route berechnen.';
          _loading = false;
        });
        await _drawAll();
        await _syncMarkers();
        final map = _map;
        if (map != null) {
          await map.animateCamera(CameraUpdate.newLatLngZoom(tour.center, 12));
        }
        return;
      }

      final pts = routed.points;
      final start = pts.first;
      final end = pts.last;
      final mid = pts[pts.length ~/ 2];
      final result = RouteResult(
        coordinates: pts,
        distanceM: tour.distanceKm * 1000,
        durationS: tour.durationMin * 60.0,
        engine: 'tour-adopt',
      );
      setState(() {
        _start = start;
        _end = end;
        _vias
          ..clear()
          ..add(mid);
        _computed = result;
        _ideaPin = null;
        _label = '${tour.name} (Plan)';
        _adaptingTourName = tour.name;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
        // Tour, die gar nicht mehr gemeint war.
        _detailId = null;
        _pick = _PickMode.none;
        _startAddrCtrl.text =
            '${start.lat.toStringAsFixed(4)}, ${start.lng.toStringAsFixed(4)}';
        _endAddrCtrl.text =
            '${end.lat.toStringAsFixed(4)}, ${end.lng.toStringAsFixed(4)}';
        _status = 'Tour in Planen — Start/Ziel/Via editierbar';
        _loading = false;
      });
      await _drawRoute(result);
      await _syncMarkers();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = friendlyErrorMessage(e, context: 'Route berechnen');
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

  Future<void> _fetchRoutingStatus() async {
    // Prod: no Demo-Geometrie / Routing-Key chrome (Q-BAR-DIS-01 / S25).
    if (!AppConfig.showRoutingDebug || !AppConfig.allowDemoContent) {
      if (mounted && _routingStatusNote != null) {
        setState(() => _routingStatusNote = null);
      }
      return;
    }
    final s = await fetchRoutingStatus();
    if (!mounted || s == null) return;
    final text = s.bannerText;
    if (_suppressDemoGeometryBanner(text)) {
      setState(() => _routingStatusNote = null);
      return;
    }
    setState(() => _routingStatusNote = text);
  }

  Future<void> _openOfflineMaps() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const OfflineMapsSheet(),
    );
    if (!mounted) return;
    if (changed == true) {
      final s = await AppConfig.resolveMapStyleUrl();
      if (!mounted) return;
      setState(() {
        _mapStyle = s;
        _styleReady = false;
        _pinImagesReady = false;
      });
    }
  }

  List<OsmTrailSegment> get _visibleTrailNetwork {
    var list = _trailNetwork;
    if (_trailScaleFilter != null) {
      list = [
        for (final t in list)
          if (t.difficulty == _trailScaleFilter) t,
      ];
    }
    return list;
  }

  Future<void> _fetchTrailNetwork() async {
    try {
      if (!_hasRealOrigin) {
        if (mounted) {
          setState(
            () => _trailNetworkStatus =
                'Standort oder Start setzen für Trailnetz',
          );
        }
        return;
      }
      final o = _origin;
      if (mounted) {
        setState(() => _trailNetworkStatus = 'Trailnetz lädt…');
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
            ? 'Kein OSM-Trailnetz in der Nähe'
            : 'Trailnetz ${hits.length} · Tippen zum Auswählen';
      });
      await _drawAll();
    } catch (_) {
      if (mounted) {
        setState(() => _trailNetworkStatus = 'Trailnetz offline');
      }
    }
  }

  /// Nächsten Trail-Einstieg zu [from] wählen; Geometrie ggf. umdrehen.
  ({List<List<double>> geometry, GeoPoint entry, GeoPoint exit})
  _orientTrailToOrigin(OsmTrailSegment trail, GeoPoint from) {
    final first = trail.geometry.first;
    final last = trail.geometry.last;
    final dFirst = _distKm(from.lat, from.lng, first[1], first[0]);
    final dLast = _distKm(from.lat, from.lng, last[1], last[0]);
    if (dLast < dFirst) {
      final rev = trail.geometry.reversed.toList();
      return (
        geometry: rev,
        entry: GeoPoint(rev.first[1], rev.first[0]),
        exit: GeoPoint(rev.last[1], rev.last[0]),
      );
    }
    return (
      geometry: trail.geometry,
      entry: GeoPoint(first[1], first[0]),
      exit: GeoPoint(last[1], last[0]),
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
        _status = snap.honestyLabel;
      }
    });
    await _drawAll();
  }

  Future<void> _showTrailSheet(OsmTrailSegment trail) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
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
                      _trailSurfaceLabel(trail.surface!),
                    if (trail.highway != null)
                      _trailHighwayLabel(trail.highway!),
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  [
                    'OSM-Live-Pfad',
                    if (trail.surface != null || trail.highway != null)
                      'Tags aus OpenStreetMap',
                    'Tippen auf der Karte wählt Trails.',
                    'Anfahrt zum Einstieg, dann Overlay speichern oder fahren.',
                  ].join(' — '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.l),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(_approachTrail(trail));
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Zum Startpunkt anfahren'),
                ),
                const SizedBox(height: AppSpacing.s),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(_adoptTrailAsOverlay(trail));
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text('Auf Route legen'),
                ),
                if (trail.url != null) ...[
                  const SizedBox(height: AppSpacing.s),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(trail.url!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Auf OpenStreetMap öffnen'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _trailSurfaceLabel(String raw) {
    final s = raw.toLowerCase().trim();
    return switch (s) {
      'asphalt' || 'paved' || 'concrete' => 'Asphalt',
      'gravel' || 'fine_gravel' || 'compacted' => 'Schotter',
      'ground' || 'dirt' || 'earth' || 'unpaved' => 'Naturweg',
      'grass' => 'Gras',
      'wood' || 'boardwalk' => 'Holz',
      _ => raw,
    };
  }

  static String _trailHighwayLabel(String raw) {
    final s = raw.toLowerCase().trim();
    return switch (s) {
      'path' => 'Pfad',
      'track' => 'Forstweg',
      'cycleway' => 'Radweg',
      'bridleway' => 'Reitweg',
      'footway' => 'Fußweg',
      _ => raw,
    };
  }

  Future<void> _approachTrail(OsmTrailSegment trail) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedTrailId = trail.id;
      _status = 'Anfahrt zum Trailhead…';
    });
    try {
      final oriented = _orientTrailToOrigin(trail, _origin);
      final approach = await _routes.planRoute(
        from: _origin,
        to: oriented.entry,
        profile: _profile,
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
      setState(() {
        _approach = approach;
        _trailOverlay = trailPts;
        _tourLayer = null;
        _computed = merged;
        _label = trail.name;
        _start = _origin;
        _end = oriented.exit;
        _ideaPin = null;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
        // Tour, die gar nicht mehr gemeint war.
        _detailId = null;
        _status =
            'Anfahrt + Trail · ${(merged.distanceM / 1000).toStringAsFixed(1)} km · ${trail.difficultyLabel}';
        _loading = false;
      });
      await _drawAll();
      await _syncMarkers();
      await _refreshElevation(merged);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = friendlyErrorMessage(e, context: 'Route berechnen');
        });
      }
    }
  }

  Future<void> _adoptTrailAsOverlay(OsmTrailSegment trail) async {
    final oriented = _orientTrailToOrigin(trail, _origin);
    final trailPts = [for (final p in oriented.geometry) GeoPoint(p[1], p[0])];
    setState(() {
      _selectedTrailId = trail.id;
      _trailOverlay = trailPts;
      _computed = RouteResult(
        coordinates: trailPts,
        distanceM: trail.lengthKm * 1000,
        durationS: (trail.lengthKm / 12) * 3600,
        engine: 'osm-trail',
      );
      _label = trail.name;
      _start = oriented.entry;
      _end = oriented.exit;
      _surface = _Surface.plan;
      _shellMode = DiscoverShellMode.navigate;
      // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
      // Tour, die gar nicht mehr gemeint war.
      _detailId = null;
      _status =
          'Trail gelegt · ${trail.difficultyLabel} · ${trail.lengthKm.toStringAsFixed(1)} km — speichern oder Los';
    });
    await _drawAll();
    await _syncMarkers();
  }

  Future<void> _fetchTrailforks() async {
    try {
      if (!_hasRealOrigin) return;
      final o = _origin;
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/trailforks').replace(
        queryParameters: {
          'hint': 'dry_likely',
          'lat': '${o.lat}',
          'lon': '${o.lng}',
        },
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      if (data is! Map) return;
      final pins = <_TfPin>[];
      for (final raw in (data['pins'] as List? ?? const [])) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final centerRaw = m['center'];
        if (centerRaw is! List || centerRaw.length < 2) continue;
        final lng = (centerRaw[0] as num).toDouble();
        final lat = (centerRaw[1] as num).toDouble();
        pins.add(
          _TfPin(
            id: (m['id'] as String?) ?? 'tf',
            name: (m['name'] as String?) ?? 'Trailforks',
            center: LatLng(lat, lng),
            openUrl: (m['openUrl'] as String?) ?? 'https://www.trailforks.com/',
            difficulty: m['difficulty'] as String?,
            conditionLabel: m['conditionLabel'] as String?,
          ),
        );
      }
      if (pins.isEmpty || !mounted) return;
      setState(() => _tfPins = pins);
      await _drawAll();
    } catch (_) {}
  }

  Future<void> _fetchOutdooractive() async {
    try {
      if (!_hasRealOrigin && !AppConfig.allowDemoContent) {
        if (mounted) {
          setState(() => _oaStatus = 'Standort oder Start setzen für Touren');
        }
        return;
      }
      final o = _origin;
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/outdooractive')
          .replace(
            queryParameters: {
              'type': 'tour',
              'lat': '${o.lat}',
              'lon': '${o.lng}',
            },
          );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (mounted) {
          setState(() => _oaStatus = 'Outdooractive offline');
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
            categories: const [
              BikeCategory.mtbTrail,
              BikeCategory.mtbAm,
              BikeCategory.mtbEnduro,
              BikeCategory.gravel,
              BikeCategory.road,
              BikeCategory.urban,
              BikeCategory.emtb,
              BikeCategory.etrekking,
              BikeCategory.hiking,
            ],
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
          _oaStatus =
              (data['warning'] as String?) ??
              'Outdooractive — keine Live-Touren in der Nähe';
        });
        return;
      }
      setState(() {
        final byId = <String, _RouteSuggestion>{
          for (final t in _tours) t.id: t,
          for (final p in parsed) p.id: p,
        };
        _tours = byId.values.toList();
        _oaStatus = 'Outdooractive ${parsed.length} · OSM/Tracks folgen';
      });
      await _drawAll();
      // OA-Treffer ohne Track: Background-Routing für sichtbare Pins.
      unawaited(_warmVisibleMapTourGeometries(
        _filtered.take(DiscoverMapLineStyle.mapTourCap).toList(),
      ));
    } catch (_) {
      if (mounted) {
        setState(() => _oaStatus = 'Outdooractive offline');
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
        final mtb = switch (effort.toLowerCase()) {
          'leicht' => 'S0',
          'anspruchsvoll' || 'schwer' => 'S2+',
          _ => 'S1',
        };
        // Prefill routed cache with baked street geometry so map / mini-map
        // never flash a synthetic circle when JSON already has a polyline.
        if (s.hasBakedGeometry) {
          _routedLoopCache[s.id] = [
            for (final c in s.bakedGeometry!) GeoPoint(c[1], c[0]),
          ];
        }
        parsed.add(
          _RouteSuggestion(
            id: s.id,
            name: s.title,
            distanceKm: s.distanceKm,
            elevationM: s.ascentM,
            durationMin: s.durationMin > 0
                ? s.durationMin
                : (s.distanceKm * 4).round().clamp(20, 300),
            mtbScale: mtb,
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
            seasonLabel: s.seasonLabel,
            highlightPoi: s.highlightPoi,
            disciplineNote: s.disciplineNote,
            corridorNote: s.corridorNote,
            shortPitch: s.shortPitch,
            surfaceMixLabel: s.surfaceMixLabel,
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
        _tours = byId.values.toList();
        final loops = parsed.where((t) => t.isLoopHint == true).length;
        _seedsStatus =
            'Seeds ${parsed.length} ($loops Rundkurse) · ${bundle.labelWithoutLocation}';
      });
      unawaited(
        TourCommunityStore().prefetchCounts(
          parsed.take(TourCoverage.maxCount).map((t) => t.id).toList(),
        ),
      );
      // S25: after seeds land, replace any A→B demo overlay with a real loop.
      if (_loopOnly == true) {
        await _ensureLoopMapHonesty();
      } else {
        await _drawAll();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _seedsStatus = 'Seeds offline');
      }
      debugPrint('NaeheSeeds: $e');
    }
  }

  /// Redaktioneller Katalog vom Backend — füllt Touren auch ohne GPS.
  /// Immer `sport=all`: Bike-Kategorie ist nur weiche Sortier-Präferenz.
  Future<void> _fetchPublicCatalog() async {
    try {
      final hits = await PublicToursClient().fetchCatalog(sport: 'all');
      if (!mounted || hits.isEmpty) return;
      final o = _originOrNull;
      final parsed = <_RouteSuggestion>[];
      for (final h in hits) {
        final surface = TourFilters.normalizeStoredSurface(
          h.surface,
          fallbackTitle: h.name,
        );
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
              'Losfahren lädt Live-/Override-Geometrie',
            ],
            center: LatLng(h.centerLat, h.centerLng),
            categories: h.categories,
            sourceKind: 'catalog',
            isLoopHint: h.loop ? true : null,
            apiTags: [
              ...h.tags,
              if (h.regionSlug.isNotEmpty) h.regionSlug,
            ],
          ),
        );
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
        _tours = byId.values.toList();
        final base = _oaStatus;
        _oaStatus = base == null || base.isEmpty
            ? 'Katalog ${toMerge.length} Touren'
            : '$base · Katalog ${toMerge.length}';
      });
      await _drawAll();
      // Katalog-Pins oft ohne Track → sofort Background-Routing.
      unawaited(_warmVisibleMapTourGeometries(
        _filtered.take(DiscoverMapLineStyle.mapTourCap).toList(),
      ));
    } catch (_) {
      // Katalog optional — Discover bleibt mit OA/OSM nutzbar.
    }
  }

  Future<void> _fetchOsmRoutes() async {
    try {
      if (!_hasRealOrigin) return;
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
            _oaStatus = '$base · OSM keine Treffer';
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
                : const [
                    BikeCategory.gravel,
                    BikeCategory.road,
                    BikeCategory.urban,
                    BikeCategory.etrekking,
                    BikeCategory.hiking,
                    BikeCategory.mtbTrail,
                  ],
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
        _oaStatus =
            'Touren ${_tours.length} ($withTrack mit Track) · OSM ${parsed.length}';
      });
      await _drawAll();
    } catch (_) {
      // Overpass/API optional — OA bleibt nutzbar.
    }
  }

  Future<void> _refreshElevation(RouteResult? result) async {
    if (result == null || result.coordinates.length < 2) {
      if (!mounted) return;
      setState(() {
        _elevationSummary = null;
        _elevationGainM = null;
      });
      return;
    }
    final profile = await _elevationClient.fetchForTrack(result.coordinates);
    if (!mounted) return;
    if (profile == null) {
      final approx = (result.distanceM * 0.03).round();
      setState(() {
        _elevationGainM = result.distanceM * 0.03;
        _elevationSummary =
            '~$approx hm (Distanz-Schätzung — Höhen-API nicht erreichbar)';
      });
      return;
    }
    setState(() {
      _elevationGainM = profile.gainM;
      _elevationSummary =
          '+${profile.gainM.round()} / −${profile.lossM.round()} hm'
          '${profile.source != null ? ' · ${profile.source}' : ''}';
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
    if (data == null) return;
    final kind = data['kind'];

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
      setState(() {
        _selectedTrailId = trail!.id;
        _selectedTourId = null;
        _shellMode = DiscoverShellMode.explore;
        _surface = _Surface.discover;
        _status =
            '${trail.name} · ${trail.difficultyLabel} · ${trail.lengthKm.toStringAsFixed(1)} km';
      });
      await _drawAll();
      if (mounted) await _showTrailSheet(trail);
      return;
    }

    if (kind == 'tour') {
      final id = data['id'] as String?;
      if (id == null) return;
      setState(() => _selectedTrailId = null);
      final tour = _tourById(id);
      if (tour == null) return;
      if (_hofDirectNav) {
        await _startRide(suggestion: tour);
        return;
      }
      await _openDetail(id, tour.center);
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
      _status = 'Alternative gewählt: ${match.label}';
    });
    await _drawRoute(match.result);
  }

  Future<void> _onTfSymbolTapped(Symbol symbol) async {
    final place = _placeBySymbolId[symbol.id];
    if (place != null) {
      final url = place.mapsUrl.trim();
      if (url.isEmpty) return;
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${place.name} · Powered by Google')),
          );
        }
      }
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

  Future<void> _locate() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(
            () => _status = 'Ortungsdienst aus — Start tippen oder Adresse',
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => _status = 'Standort-Berechtigung fehlt — Adresse nutzen',
          );
        }
        return;
      }
      // Frische Position zuerst — lastKnown kann alte Demo-/Test-Orte sein.
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          final age = DateTime.now().difference(pos.timestamp);
          if (age > const Duration(minutes: 5)) pos = null;
        }
      }
      if (pos == null) {
        if (mounted) {
          setState(
            () => _status = 'Kein GPS-Fix — Karte tippen oder Adresse suchen',
          );
        }
        return;
      }
      if (!mounted) return;
      final p = GeoPoint(pos.latitude, pos.longitude);
      final nextStyle = nextOnlineBasemapStyleUrl(
        currentStyle: _mapStyle,
        lng: p.lng,
        lat: p.lat,
      );
      final styleChanged = nextStyle != null && nextStyle != _mapStyle;
      setState(() {
        _userPos = p;
        _start = p;
        _startAddrCtrl.text = 'Meine Position';
        _status = 'Standort bereit · In der Nähe wird geladen…';
        if (nextStyle != null) _mapStyle = nextStyle;
      });
      unawaited(_fetchOutdooractive());
      unawaited(_fetchOsmRoutes());
      unawaited(_fetchTrailNetwork());
      unawaited(_fetchTrailforks());
      unawaited(_fetchPublicCatalog());
      unawaited(_fetchCoverage());
      // Explizit Near-me nach frischem GPS — Drift-Sync kann verzögern.
      // Rundkurs-Lens: nahen Seed auf die Karte, nie A→B / Fernstadt.
      if (_loopOnly == true) {
        unawaited(_ensureLoopMapHonesty());
      } else {
        unawaited(_refreshQuick(limit: 3));
      }
      try {
        if (!styleChanged) {
          await _map?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 12.5),
          );
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(
          () => _status = 'Position nicht verfügbar — Adresse oder Tippen',
        );
      }
    }
  }

  /// Tour-/API-Origin nur mit echtem Start oder GPS — kein Stadt-Fake.
  GeoPoint? get _originOrNull => _userPos ?? _start;

  GeoPoint get _origin => _originOrNull ?? _regionOverview;

  bool get _hasRealOrigin => _userPos != null || _start != null;

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
        if (_loopOnly == true) {
          unawaited(_ensureLoopMapHonesty());
        } else {
          unawaited(_refreshQuick(limit: 3));
        }
      }
    });
  }

  GeoPoint get _mapCenter => _originOrNull ?? _regionOverview;

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
    final cat = active?.category;

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
      if (!TourFilters.distanceMatches(r.distanceKm, _maxDistanceKm)) {
        return false;
      }
      // „Nur Rundkurse": echte Geometrie ODER ehrlicher Seed/Katalog-Hint.
      // D-60-LOOP-FILTER-01: A→B-Geometrie nie als Rundkurs durchlassen.
      if (_loopOnly == true && !_isLoop(r)) {
        return false;
      }
      if (_exploreQuery.trim().isNotEmpty) {
        final q = _exploreQuery.trim().toLowerCase();
        final hay = [
          r.name,
          r.sportLabel ?? '',
          r.sourceLabel,
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      // Seed-Nähe: nicht hart auf 35 km kappen — Coverage füllt die Liste.
      return true;
    }).toList();

    final covered = _applyTourCoverage(base);

    if (cat == null) {
      final sorted = List<_RouteSuggestion>.from(covered);
      sorted.sort(_byDistanceThenDurationFit);
      return sorted;
    }
    // Nähe zuerst, innerhalb davon weiche Kategorie-/Familien-Präferenz.
    final matched = <_RouteSuggestion>[];
    final rest = <_RouteSuggestion>[];
    for (final r in covered) {
      if (TourFilters.softSportMatch(r.categories, cat)) {
        matched.add(r);
      } else {
        rest.add(r);
      }
    }
    matched.sort(_byDistanceThenDurationFit);
    rest.sort(_byDistanceThenDurationFit);
    if (matched.isEmpty) {
      final sorted = List<_RouteSuggestion>.from(covered);
      sorted.sort(_byDistanceThenDurationFit);
      return sorted;
    }
    return [...matched, ...rest];
  }

  /// Seeds: 90 km Nähe, sonst mit den nächsten auffüllen (kein 3-Karten-Stub).
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
    if (_isLoop(r)) return '⟲ Runde';
    final shape = routeShapeOf(r.trackLngLat);
    if (shape == RouteShape.pointToPoint) return 'Strecke';
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
    // Active quick suggestion (Richtung Norden/…) without a selected tour.
    if (_selectedTourId == null &&
        _label != null &&
        _quick.any((q) => q.label == _label)) {
      return true;
    }
    return false;
  }

  /// S25: with Rundkurs filter, kill green A→B / Demo-Geometrie overlay.
  void _clearAbDemoOverlayForLoopFilter() {
    if (_loopOnly != true) return;
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
      _status = null;
    }
  }

  /// Prefer a curated nearby loop on the map when Rundkurs is on.
  ///
  /// Seeds may load before GPS (fallback origin ≈ W-Europe) and pick a distant
  /// city like Zurich. Once a real origin exists, always re-rank by distance and
  /// drop selections outside the Nähe radius (Komoot/AllTrails: near-me first).
  Future<void> _ensureLoopMapHonesty() async {
    if (!mounted || _loopOnly != true) return;
    _clearAbDemoOverlayForLoopFilter();
    const seedRadiusKm = TourCoverage.nearbyRadiusKm;
    final o = _origin;
    final loops = _filtered.where((r) => _isLoop(r) && r.hasTrack).toList()
      ..sort((a, b) {
        final da = _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude);
        final db = _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude);
        return da.compareTo(db);
      });
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
    final best = loops.first;
    final bestDist = _distKm(
      o.lat,
      o.lng,
      best.center.latitude,
      best.center.longitude,
    );
    // Keep current only if it is still an honest nearby loop.
    if (_selectedTourId != null) {
      final sel = _tourById(_selectedTourId);
      if (sel != null && _isLoop(sel) && sel.hasTrack) {
        final selDist = _distKm(
          o.lat,
          o.lng,
          sel.center.latitude,
          sel.center.longitude,
        );
        final nearbyOk = !_hasRealOrigin || selDist <= seedRadiusKm;
        final stillBest =
            sel.id == best.id || selDist <= bestDist + 0.05;
        if (nearbyOk && stillBest) {
          await _drawSeedLoopPreview(sel);
          return;
        }
      }
    }
    if (mounted) {
      setState(() => _selectedTourId = best.id);
    }
    await _drawSeedLoopPreview(best);
  }

  Future<void> _drawSeedLoopPreview(_RouteSuggestion r) async {
    // Echte Wege statt synthetischem Kreis, sobald das Routing sie kennt.
    final routed = _routedLoopCache[r.id];
    final track = routed != null
        ? [for (final p in routed) [p.lng, p.lat]]
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
    if (!mounted) return;
    setState(() {
      _computed = preview;
      _label = r.name;
      _quick = const [];
      _approach = null;
      _tourLayer = null;
      _status = null;
    });
    await _drawAll();
    // Live-Upgrade nur wenn noch keine gebackene/routed Geometrie da ist.
    if (routed == null) {
      unawaited(_upgradeSeedLoopGeometry(r));
    }
  }

  /// Lädt im Hintergrund echte Routen-Geometrie für einen Seed-Loop und
  /// ersetzt den synthetischen Kreis sofort in Cache + Tour-Track.
  Future<void> _upgradeSeedLoopGeometry(_RouteSuggestion r) async {
    if (_routedLoopPending.contains(r.id) ||
        _routedLoopCache.containsKey(r.id)) {
      return;
    }
    _routedLoopPending.add(r.id);
    try {
      final routed = await _routedTourGeometry(r.center, r.distanceKm)
          .timeout(const Duration(seconds: 18));
      if (routed.demo || routed.points.length < 4) return;
      final pts = routed.points;
      final lngLat = [for (final p in pts) [p.lng, p.lat]];
      if (!isUsableMapTrack(lngLat)) return;
      if (_isLoop(r) &&
          !isAcceptableLiveLoop(
            trackLngLat: lngLat,
            expectedDistanceKm: r.distanceKm,
          )) {
        return;
      }
      _routedLoopCache[r.id] = pts;
      if (!mounted) return;
      setState(() {
        _tours = [
          for (final t in _tours)
            if (t.id == r.id) t.copyWith(trackLngLat: lngLat) else t,
        ];
      });
      if (_selectedTourId == r.id) {
        await _drawSeedLoopPreview(
          _tourById(r.id) ?? r.copyWith(trackLngLat: lngLat),
        );
      } else {
        await _drawAll();
      }
    } catch (_) {
      // Organische Seed-Näherung bleibt — Live-Routing optional.
    } finally {
      _routedLoopPending.remove(r.id);
    }
  }

  /// Komoot/AllTrails: sichtbare Karten-Touren ohne brauchbare Polyline
  /// sofort nachrouten — Pins / Lineale werden nicht dauerhaft belassen.
  Future<void> _warmVisibleMapTourGeometries(
    List<_RouteSuggestion> visible,
  ) async {
    final need = <_RouteSuggestion>[];
    for (final t in visible) {
      final cached = _routedLoopCache[t.id];
      final cacheOk = cached != null &&
          isUsableMapTrack([for (final p in cached) [p.lng, p.lat]]);
      if (t.hasUsableTrack || cacheOk) continue;
      if (_routedLoopPending.contains(t.id)) continue;
      // Lineare Tip-/Idee-Karten ohne Loop bleiben Pin-Ideen (A→B CTA).
      if (_isPinOnlyIdea(t) && !_isLoop(t)) continue;
      need.add(t);
    }
    if (need.isEmpty) return;
    if (mounted &&
        (_status == null ||
            _status!.isEmpty ||
            _status!.contains('Route') ||
            _status!.contains('Track'))) {
      setState(() {
        _status = need.length == 1
            ? 'Route wird berechnet…'
            : '${need.length} Routen werden berechnet…';
      });
    }
    // Parallelität begrenzen — OSRM/Backend nicht überlasten.
    const batch = DiscoverMapLineStyle.warmBatchSize;
    for (var i = 0; i < need.length; i += batch) {
      if (!mounted) return;
      final chunk = need.skip(i).take(batch);
      await Future.wait([
        for (final t in chunk) _upgradeSeedLoopGeometry(t),
      ]);
    }
    if (!mounted) return;
    // Status nur während laufender Warm-Jobs — Fehlschläge nicht ewig anzeigen.
    if (_routedLoopPending.isEmpty &&
        _status != null &&
        (_status!.contains('berechnet') || _status!.contains('berechnen'))) {
      setState(() => _status = null);
    }
  }

  double _distKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  List<GeoPoint> _quickDestinations(GeoPoint start, int minutes) {
    final km = math.max(4.0, (minutes / 60) * 14 * 0.45);
    final deg = km / 111;
    final cosLat = math.cos(start.lat * math.pi / 180);
    return [
      GeoPoint(start.lat + deg, start.lng),
      GeoPoint(start.lat, start.lng + deg / cosLat),
      GeoPoint(start.lat - deg * 0.7, start.lng - deg * 0.7 / cosLat),
    ];
  }

  Future<void> _refreshQuick({int limit = 3}) async {
    // Rundkurs-Lens: Seeds/Loops sind die Antwort. Die drei A→B-Anfragen
    // würden nur verworfen — aber währenddessen läge minutenlang der
    // Lade-Veil über dem Panel (der „permanente Ladebalken" auf S25).
    if (_loopOnly == true) {
      if (_quick.isNotEmpty || _loading) {
        setState(() {
          _quick = const [];
          _loading = false;
          _error = null;
        });
      }
      await _ensureLoopMapHonesty();
      return;
    }
    final gen = ++_quickGen;
    // Darf das Ergebnis die Karte übernehmen? Nur wenn dort nichts liegt, das
    // die Nutzerin selbst gewählt hat. Seit Discover der Dauerzustand ist,
    // läuft dieser Refresh bei jedem GPS-Drift > 300 m ([_syncOriginDrift]) —
    // ohne diese Sperre würde eine ausgewählte Tour beim Herumlaufen einfach
    // durch einen Schnell-Vorschlag ersetzt.
    final previousQuickLabels = {for (final q in _quick) q.label};
    final takeOverMap =
        _computed == null ||
        _label == null ||
        previousQuickLabels.contains(_label);
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
      _quick = [];
    });
    // Origin EINMAL einfrieren: _syncOriginDrift() kann _userPos mitten in
    // diesem async Loop aktualisieren (neuer GPS-Fix trifft während der
    // 350ms-Pausen zwischen den drei Anfragen ein). Ohne dieses Snapshot
    // läse jede Zeile unten _origin frisch neu — from (neuer Origin) und
    // to (dests[i], relativ zum ALTEN Origin berechnet) könnten dann
    // hunderte km auseinanderliegen, obwohl beide „plausibel" aussehen.
    final origin = _origin;
    final dests = _quickDestinations(origin, _minutes);
    // Kein „$_minutes min" im Titel: die Minuten sind das Zeitbudget, mit dem
    // das ZIEL platziert wird — nicht die Dauer der berechneten Route. Die
    // echte Dauer steht auf der Karte. Vorher las sich „90 min · Norden" wie
    // eine 90-Minuten-Tour, obwohl nur der Hinweg geroutet wird.
    final labels = ['Richtung Norden', 'Richtung Osten', 'Richtung Südwest'];
    final reasons = [
      'Ziel im Norden — Rückweg noch nicht enthalten',
      'Ziel im Osten — Rückweg noch nicht enthalten',
      'Ziel im Südwest — Rückweg noch nicht enthalten',
    ];
    final out = <_QuickOption>[];
    final max = limit.clamp(1, dests.length);
    String? lastErr;
    var usedApprox = false;
    for (var i = 0; i < max; i++) {
      if (gen != _quickGen) return;
      if (out.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (gen != _quickGen) return;
      try {
        // Hartes Timeout: ein hängender Routing-Call darf den Quick-Refresh
        // (und damit den Lade-Zustand) nicht minutenlang festhalten.
        var result = await _routes
            .planRoute(
              from: origin,
              to: dests[i],
              profile: _profile,
            )
            .timeout(const Duration(seconds: 10));
        // Plausibilitätsnetz: „Schnell" schlägt Ziele ~9–15 km Luftlinie vom
        // Origin vor (siehe _quickDestinations) — eine echte Trail-Route
        // dorthin ist windungsreich, aber kein Vielfaches davon. Ein Treffer,
        // der das grob sprengt (kaputter Cache-Altbestand, Routing-Ausreißer,
        // …), fliegt raus statt als „90 min" mit 250+ km angezeigt zu werden.
        final beelineKm = _distKm(
          origin.lat,
          origin.lng,
          dests[i].lat,
          dests[i].lng,
        );
        final plausibleCapKm = math.max(beelineKm * 8, 20.0);
        if (result.distanceM / 1000 > plausibleCapKm) {
          await _routes.invalidateRoute(
            from: origin,
            to: dests[i],
            profile: _profile,
          );
          result = approximateOutAndBack(
            from: origin,
            to: dests[i],
            label: labels[i],
          );
          usedApprox = true;
          lastErr = 'Unplausibles Routing-Ergebnis verworfen';
        }
        out.add(
          _QuickOption(
            id: 'quick-$i-$_minutes',
            label: result.engine == 'approx'
                ? '${labels[i]} (Näherung)'
                : labels[i],
            reason: result.engine == 'approx'
                ? '${reasons[i]} · Live-Routing lieferte kein plausibles Ergebnis'
                : reasons[i],
            result: result,
          ),
        );
      } catch (e) {
        final msg = e.toString();
        lastErr = friendlyErrorMessage(e, context: 'Quick-Route');
        usedApprox = true;
        if (msg.contains('429') || msg.toLowerCase().contains('limit')) {
          if (mounted && gen == _quickGen) {
            setState(() {
              _status =
                  'Routing-Limit — Näherung genutzt. Später erneut berechnen.';
            });
          }
        }
        final approx = approximateOutAndBack(
          from: origin,
          to: dests[i],
          label: labels[i],
        );
        out.add(
          _QuickOption(
            id: 'quick-$i-$_minutes',
            label: '${labels[i]} (Näherung)',
            reason: '${reasons[i]} · Live-Routing nicht verfügbar',
            result: approx,
          ),
        );
        if (msg.contains('429') || msg.toLowerCase().contains('limit')) {
          break;
        }
      }
    }
    if (!mounted || gen != _quickGen) return;
    // S25: Rundkurs filter — never paint / list A→B quick as the answer.
    if (_loopOnly == true) {
      setState(() {
        _quick = const [];
        _loading = false;
        _error = null;
        if (usedApprox ||
            (_status != null && _suppressDemoGeometryBanner(_status!))) {
          _status = null;
        }
      });
      await _ensureLoopMapHonesty();
      return;
    }
    setState(() {
      _quick = out;
      _loading = false;
      if (out.isEmpty) {
        _error = lastErr ?? 'Keine Quick-Routen';
      } else if (usedApprox && _status == null) {
        _status = 'Teilweise Näherung — Live-Routing eingeschränkt';
      }
      if (out.isNotEmpty && takeOverMap) {
        _computed = out.first.result;
        _label = out.first.label;
        _selectedTourId = null;
      }
    });
    if (out.isNotEmpty && takeOverMap) {
      await _drawRoute(out.first.result);
      await _refreshElevation(out.first.result);
    } else {
      // Auswahl bleibt, aber die neuen Vorschläge müssen als graue
      // Alternativlinien nachgezeichnet werden.
      await _drawAll();
    }
  }

  Future<void> _calcAb() async {
    final from = _start;
    final to = _end;
    if (from == null || to == null) {
      setState(() => _error = AppLocalizations.of(context).navigateNeedStartEnd);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _routes.planRoute(
        from: from,
        to: to,
        profile: _profile,
        vias: List<GeoPoint>.from(_vias),
      );
      if (!mounted) return;
      setState(() {
        _computed = result;
        _label = 'Geplante Route';
        _approach = null;
        _tourLayer = null;
        _selectedTourId = null;
        if (result.engine == 'fallback-line') {
          _status = 'Gerade Fallback — Live-Routing lieferte keine Geometrie';
        }
      });
      await _drawAll();
      await _refreshElevation(result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = friendlyErrorMessage(e, context: 'Route berechnen'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hybridSnap(_RouteSuggestion tour) async {
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });
    try {
      final entry = GeoPoint(tour.center.latitude, tour.center.longitude);
      final approach = await _routes.planRoute(
        from: _origin,
        to: entry,
        profile: _profile,
      );
      final routed = await _geometryForTour(tour);
      if (!mounted) return;

      if (routed.demo || routed.points.length < 2) {
        setState(() {
          _approach = approach;
          _tourLayer = null;
          _computed = approach;
          _ideaPin = tour.center;
          _label = '${tour.name} (Anfahrt)';
          _start = _origin;
          _end = entry;
          _selectedTourId = tour.id;
          _status =
              'Anfahrt zum Ortspunkt — kein Tour-Track. Ziel weiterplanen oder GPX.';
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
        _label = '${tour.name} (von hier)';
        _start = _origin;
        _end = tourEnd;
        _selectedTourId = tour.id;
        _status = 'Hybrid · ${(merged.distanceM / 1000).toStringAsFixed(1)} km';
        _shellMode = DiscoverShellMode.explore;
        _surface = _Surface.discover;
      });
      await _drawAll();
      await _refreshElevation(merged);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = friendlyErrorMessage(e, context: 'Route berechnen'),
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
  Future<({List<GeoPoint> points, bool demo})> _routedTourGeometry(
    LatLng center,
    double distanceKm,
  ) async {
    final radiusKm = math.max(0.8, distanceKm / (2 * math.pi));
    final cosLat = math
        .cos(center.latitude * math.pi / 180)
        .abs()
        .clamp(0.2, 1.0);
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
        eng == 'fallback-line' || eng == 'approx' || (eng?.contains('demo') ?? false);

    // Single request: from → vias → back to start (closed street loop).
    try {
      final oneShot = await _routes.planRoute(
        from: ring.first,
        to: ring.first,
        vias: ring.sublist(1),
        profile: _profile,
      );
      if (!isRulerEngine(oneShot.engine) &&
          oneShot.coordinates.length >= 8 &&
          isUsableMapTrack([
            for (final p in oneShot.coordinates) [p.lng, p.lat],
          ])) {
        return (points: oneShot.coordinates, demo: false);
      }
    } catch (_) {
      // Fall through to per-leg.
    }

    final waypoints = [...ring, ring.first];
    final coords = <GeoPoint>[];
    try {
      for (var i = 0; i < waypoints.length - 1; i++) {
        final leg = await _routes.planRoute(
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
    final lngLat = [for (final p in coords) [p.lng, p.lat]];
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
        isUsableMapTrack([for (final p in cached) [p.lng, p.lat]]);
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

    try {
      final live = await _routedTourGeometry(tour.center, tour.distanceKm)
          .timeout(const Duration(seconds: 18));
      if (!live.demo && live.points.length >= 4) {
        final lngLat = [for (final p in live.points) [p.lng, p.lat]];
        if (isAcceptableLiveLoop(
          trackLngLat: lngLat,
          expectedDistanceKm: tour.distanceKm,
        )) {
          _routedLoopCache[tour.id] = live.points;
          return (points: live.points, demo: false);
        }
      }
    } catch (_) {
      // Caller may fall back to plan A→B for pin-only ideas.
    }
    // Loop without usable closed geometry → demo (do not return open legs).
    if (loop) {
      return (points: const <GeoPoint>[], demo: true);
    }
    return _routedTourGeometry(tour.center, tour.distanceKm);
  }

  bool _isPinOnlyIdea(_RouteSuggestion r) {
    if (r.hasTrack) return false;
    return r.id.startsWith('idea-') ||
        r.id.startsWith('oa-') ||
        r.id.contains('demo');
  }

  /// Komoot-ähnliche Route: dunkles Casing + helle Hauptlinie.
  /// Selected = dickes Casing; Unselected routed = dünneres Casing, gedämpft.
  Future<void> _addKomootLine(
    MapLibreMapController c,
    List<LatLng> geometry, {
    required bool active,
    String lineColor = '#2ECC71',
    Map<String, dynamic>? data,
    bool casing = true,
  }) async {
    if (geometry.length < 2) return;
    if (casing && active) {
      await c.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: DiscoverMapLineStyle.activeCasing,
          lineWidth: DiscoverMapLineStyle.activeCasingWidth,
          lineOpacity: DiscoverMapLineStyle.activeCasingOpacity,
          lineJoin: 'round',
        ),
        data, // same data so tap on casing still selects trail/route
      );
    } else if (casing && !active) {
      await c.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: DiscoverMapLineStyle.mutedCasing,
          lineWidth: DiscoverMapLineStyle.mutedCasingWidth,
          lineOpacity: DiscoverMapLineStyle.mutedCasingOpacity,
          lineJoin: 'round',
        ),
        data,
      );
    }
    await c.addLine(
      LineOptions(
        geometry: geometry,
        lineColor: lineColor,
        lineWidth: active
            ? DiscoverMapLineStyle.activeWidth
            : DiscoverMapLineStyle.inactiveWidth,
        lineOpacity: active
            ? DiscoverMapLineStyle.activeOpacity
            : DiscoverMapLineStyle.inactiveOpacity,
        lineJoin: 'round',
      ),
      data,
    );
  }

  /// Ziel-Vorschlag ~¼ der Ideendistanz NE vom Pin (A→B, editierbar).
  GeoPoint _suggestedEndNear(LatLng center, double distanceKm) {
    final legKm = (distanceKm * 0.25).clamp(3.0, 12.0);
    final dLat = legKm / 111.0;
    final cosLat = math
        .cos(center.latitude * math.pi / 180)
        .abs()
        .clamp(0.2, 1.0);
    final dLng = legKm / (111.0 * cosLat);
    return GeoPoint(
      center.latitude + dLat * 0.75,
      center.longitude + dLng * 0.75,
    );
  }

  _RouteSuggestion? _tourById(String? id) {
    if (id == null) return null;
    for (final r in _filtered) {
      if (r.id == id) return r;
    }
    for (final r in _tours) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Primär-CTA für Pin-Ideen: erst Live-Runde, sonst A→B mit Ziel-Vorschlag.
  Future<void> _computeIdeaRoute(_RouteSuggestion tour) async {
    setState(() {
      _loading = true;
      _error = null;
      _status = 'Route um Ortspunkt wird berechnet…';
      _selectedTourId = tour.id;
      _ideaPin = tour.center;
      _label = tour.name;
    });
    try {
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
          _vias.clear();
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
          // Tour, die gar nicht mehr gemeint war.
          _detailId = null;
          _pick = _PickMode.none;
          _startAddrCtrl.text =
              '${_start!.lat.toStringAsFixed(4)}, ${_start!.lng.toStringAsFixed(4)}';
          _endAddrCtrl.text =
              '${_end!.lat.toStringAsFixed(4)}, ${_end!.lng.toStringAsFixed(4)}';
          _status =
              'Live-Route · ${(preview.distanceM / 1000).toStringAsFixed(1)} km — speichern oder Losfahren';
          _loading = false;
        });
        await _drawRoute(preview);
        await _syncMarkers();
        await _refreshElevation(preview);
        return;
      }

      final start = GeoPoint(tour.center.latitude, tour.center.longitude);
      final end = _suggestedEndNear(tour.center, tour.distanceKm);
      setState(() {
        _start = start;
        _end = end;
        _vias.clear();
        _computed = null;
        _tourLayer = null;
        _approach = null;
        _ideaPin = tour.center;
        _surface = _Surface.plan;
        _shellMode = DiscoverShellMode.navigate;
        // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
        // Tour, die gar nicht mehr gemeint war.
        _detailId = null;
        _pick = _PickMode.none;
        _startAddrCtrl.text = 'Ortspunkt · ${tour.name}';
        _endAddrCtrl.text = 'Ziel-Vorschlag (anpassbar)';
        _status =
            'Kein Rundkurs — A→B-Vorschlag gesetzt. „Route berechnen“ oder Ziel tippen.';
        _loading = false;
      });
      await _drawAll();
      await _syncMarkers();
      await _calcAb();
      if (mounted && _computed != null) {
        setState(() {
          _status =
              'Näherungsroute A→B · Ziel auf Karte anpassen, dann erneut berechnen.';
          _ideaPin = null;
        });
        await _syncMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = friendlyErrorMessage(e, context: 'Routing');
          _status =
              'Routing fehlgeschlagen — Ziel tippen und erneut berechnen.';
          _surface = _Surface.plan;
          _shellMode = DiscoverShellMode.navigate;
          // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
          // Tour, die gar nicht mehr gemeint war.
          _detailId = null;
          _pick = _PickMode.end;
        });
      }
    }
  }

  BikeOverlayFamily get _overlayFamily {
    final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
    if (bikes.isNotEmpty) return overlayFamilyFromActiveBike(bikes);
    return switch (_profile) {
      RoutingProfile.mtbTrail ||
      RoutingProfile.mtbEnduro ||
      RoutingProfile.emtb ||
      RoutingProfile.hiking =>
        BikeOverlayFamily.mtb,
      RoutingProfile.gravel || RoutingProfile.ebikeTour =>
        BikeOverlayFamily.gravel,
      RoutingProfile.urban => BikeOverlayFamily.urban,
      RoutingProfile.road => BikeOverlayFamily.road,
    };
  }

  Future<void> _ensureBikeOverlay() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    if (_bikeOverlayAttached) {
      await applyBikeOverlayVisibility(
        c,
        family: _overlayFamily,
        visible: _bikeOverlayOn,
        extraOn: _bikeOverlayExtra,
      );
      return;
    }
    final data = await resolveBikeOverlayData(
      lng: _mapCenter.lng,
      lat: _mapCenter.lat,
    );
    if (data == null || !mounted) return;
    await attachBikeOverlayLayers(
      c,
      data: data,
      family: _overlayFamily,
      visible: _bikeOverlayOn,
      extraOn: _bikeOverlayExtra,
    );
    if (mounted) setState(() => _bikeOverlayAttached = true);
  }

  Future<void> _drawAll() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    final gen = ++_drawGen;
    try {
      await c.clearLines();
      if (gen != _drawGen) return;
      if (_heatmapConsent) {
        try {
          final rides = await ref
              .read(rideRepositoryProvider)
              .listRides(limit: 40);
          final zones = await ref
              .read(garageRepositoryProvider)
              .listPrivacyZones();
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
              for (final r in rides.take(8)) {
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
            communityErr = 'Community-Heatmap offline';
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
      // Wenn das Regions-Overlay liegt, Overpass-Linien nicht doppelt zeichnen
      // (Overlay ist die dichte Karte; Overpass bleibt Fallback + Tap-Liste).
      if (_showTrailNetwork && !_bikeOverlayAttached) {
        for (final trail in _visibleTrailNetwork.take(60)) {
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
                lineOpacity: DiscoverMapLineStyle.trailUnselectedOpacity,
                lineJoin: 'round',
              ),
              {'kind': 'trail', 'id': trail.id},
            );
          }
        }
      }
      // Eigene Strecken (Import/Recorded/Engine) — Accent-Blau, unter Selection.
      if (_showOwnTracks) {
        final own =
            ref.read(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
        for (final s in own) {
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
      final visible =
          _filtered.take(DiscoverMapLineStyle.mapTourCap).toList();
      final trackTours = visible.where((t) {
        final cached = _routedLoopCache[t.id];
        if (cached != null &&
            isUsableMapTrack([for (final p in cached) [p.lng, p.lat]])) {
          return true;
        }
        return t.hasUsableTrack;
      }).toList();
      // Falls Selection außerhalb des Caps liegt (selten), trotzdem zeichnen.
      final selectedTour = _tourById(_selectedTourId);
      if (selectedTour != null &&
          !trackTours.any((t) => t.id == selectedTour.id)) {
        final cached = _routedLoopCache[selectedTour.id];
        final cacheOk = cached != null &&
            isUsableMapTrack([for (final p in cached) [p.lng, p.lat]]);
        if (cacheOk || selectedTour.hasUsableTrack) {
          trackTours.insert(0, selectedTour);
        }
      }
      trackTours.sort((a, b) {
        final asel = a.id == _selectedTourId ? 0 : 1;
        final bsel = b.id == _selectedTourId ? 0 : 1;
        if (asel != bsel) return asel.compareTo(bsel);
        return 0;
      });
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
        // Unrouted seed approx: cooler Tone. Routed: Komoot-grün + Casing
        // (selected hell/dick, andere dunkler aber ribbon-sichtbar).
        await _addKomootLine(
          c,
          geom,
          active: isSelected && routed,
          casing: routed,
          lineColor: routed
              ? (isSelected
                  ? DiscoverMapLineStyle.selectedRouted
                  : DiscoverMapLineStyle.unselectedRouted)
              : (isSelected
                  ? DiscoverMapLineStyle.selectedApprox
                  : DiscoverMapLineStyle.unselectedApprox),
          data: {
            'kind': 'tour',
            'id': tour.id,
            'engine': routed ? 'seed-loop-routed' : 'seed-loop',
          },
        );
      }
      // Sichtbare Pins ohne Track → Background-Routing (ehrlicher Loading-Status).
      unawaited(_warmVisibleMapTourGeometries(visible));
      if (_approach != null && _approach!.coordinates.length >= 2) {
        await _addKomootLine(
          c,
          _approach!.coordinates.map((p) => LatLng(p.lat, p.lng)).toList(),
          active: false,
          lineColor: '#66BB6A',
        );
      }
      if (_tourLayer != null && _tourLayer!.coordinates.length >= 2) {
        final approx = (_tourLayer!.engine ?? '').contains('demo');
        await _addKomootLine(
          c,
          _tourLayer!.coordinates.map((p) => LatLng(p.lat, p.lng)).toList(),
          active: false,
          lineColor: approx ? '#9E9E9E' : '#AB47BC',
        );
      }
      if (_trailOverlay != null && _trailOverlay!.length >= 2) {
        await _addKomootLine(
          c,
          _trailOverlay!.map((p) => LatLng(p.lat, p.lng)).toList(),
          active: true,
          lineColor: '#FF6B35',
        );
      }
      for (final q in _quick) {
        if (q.label == _label) continue;
        if (q.result.coordinates.length < 2) continue;
        await _addKomootLine(
          c,
          q.result.coordinates.map((p) => LatLng(p.lat, p.lng)).toList(),
          active: false,
          lineColor: '#90A4AE',
          data: {'kind': 'quick', 'id': q.id, 'label': q.label},
        );
      }
      if (_computed != null && _computed!.coordinates.length >= 2) {
        final eng = _computed!.engine ?? '';
        final approx = eng.contains('demo') || eng.contains('fallback');
        final line = _computed!.coordinates
            .map((p) => LatLng(p.lat, p.lng))
            .toList();
        await _addKomootLine(
          c,
          line,
          active: true,
          lineColor: approx ? '#78909C' : '#00E676',
          data: {
            'kind': 'active',
            'approx': approx,
            if (_label != null) 'label': _label,
          },
        );
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
        if (_surface != _Surface.detail) {
          final swLat = line
              .map((e) => e.latitude)
              .reduce((a, b) => a < b ? a : b);
          final swLng = line
              .map((e) => e.longitude)
              .reduce((a, b) => a < b ? a : b);
          final neLat = line
              .map((e) => e.latitude)
              .reduce((a, b) => a > b ? a : b);
          final neLng = line
              .map((e) => e.longitude)
              .reduce((a, b) => a > b ? a : b);
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
      if (gen != _drawGen) return;
      await _syncMarkers();
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
      final green = await buildMapPinPng(fill: const Color(0xFF00C853));
      final orange = await buildMapPinPng(fill: const Color(0xFFFF6B35));
      final blue = await buildMapPinPng(fill: const Color(0xFF29B6F6));
      final poi = await buildMapPinPng(fill: const Color(0xFF1B5E20));
      await c.addImage('aether-pin', green);
      await c.addImage('aether-pin-b', orange);
      await c.addImage('aether-pin-idea', blue);
      await c.addImage('aether-poi', poi);
      _pinImagesReady = true;
    } catch (_) {
      // Style without custom images — text-only symbols still work.
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

  Future<void> _syncMarkers() async {
    final c = _map;
    if (c == null || !_styleReady) return;
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
      _tfSymbols = [];
      _tfBySymbolId.clear();
      _placeBySymbolId.clear();
      const pin = 'aether-pin';
      if (_ideaPin != null) {
        await c.addSymbol(
          SymbolOptions(
          fontNames: _symbolFonts,
            geometry: _ideaPin!,
            iconImage: _pinImagesReady ? 'aether-pin-idea' : null,
            iconSize: 1.2,
            textField: 'Idee',
            textSize: 12,
            textOffset: const Offset(0, 1.3),
          ),
        );
      }
      if (_start != null) {
        await c.addSymbol(
          SymbolOptions(
          fontNames: _symbolFonts,
            geometry: LatLng(_start!.lat, _start!.lng),
            iconImage: _pinImagesReady ? pin : null,
            iconSize: 1.35,
            textField: 'A',
            textSize: 14,
            textColor: '#FFFFFF',
            textHaloColor: '#1B5E20',
            textHaloWidth: 1.4,
            textOffset: const Offset(0, 1.35),
          ),
        );
      }
      if (_end != null) {
        await c.addSymbol(
          SymbolOptions(
          fontNames: _symbolFonts,
            geometry: LatLng(_end!.lat, _end!.lng),
            iconImage: _pinImagesReady ? 'aether-pin-b' : null,
            iconSize: 1.35,
            textField: 'B',
            textSize: 14,
            textColor: '#FFFFFF',
            textHaloColor: '#BF360C',
            textHaloWidth: 1.4,
            textOffset: const Offset(0, 1.35),
          ),
        );
      }
      for (final pinTf in _tfPins.take(12)) {
        final sym = await c.addSymbol(
          SymbolOptions(
          fontNames: _symbolFonts,
            geometry: pinTf.center,
            iconImage: _pinImagesReady ? pin : null,
            iconSize: 1.0,
            textField: 'TF',
            textSize: 11,
            textOffset: const Offset(0, 1.2),
          ),
        );
        _tfSymbols.add(sym);
        _tfBySymbolId[sym.id] = pinTf;
      }
      for (final place in _googlePlaces.take(10)) {
        final label = place.kind == 'bike_shop' ? 'Laden' : 'POI';
        final sym = await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: place.center,
            iconImage: _pinImagesReady ? 'aether-pin-idea' : null,
            iconSize: 0.95,
            textField: label,
            textSize: 10,
            textOffset: const Offset(0, 1.2),
          ),
        );
        _placeBySymbolId[sym.id] = place;
      }
      // Nur Touren OHNE zeichbare Polyline als Pin — und nur kurz, während
      // Background-Routing läuft. Fertige Tracks haben bereits eine Line in
      // [_drawAll] (keine blinden T-Pins à la leere Ideen-Punkte).
      for (final tour in _filtered.take(DiscoverMapLineStyle.mapTourCap)) {
        final hasLine = tour.hasTrack ||
            (_routedLoopCache[tour.id]?.length ?? 0) >= 4;
        if (hasLine) continue;
        if (_isPinOnlyIdea(tour) && !_isLoop(tour)) {
          // Explizite Pin-Ideen (oa-/idea- ohne Track) — ehrlich als Idee.
          await c.addSymbol(
            SymbolOptions(
              fontNames: _symbolFonts,
              geometry: tour.center,
              iconImage: _pinImagesReady ? 'aether-pin-idea' : null,
              iconSize: 0.85,
              textField: 'Idee',
              textSize: 10,
              textOffset: const Offset(0, 1.15),
            ),
          );
          continue;
        }
        // Loop/Katalog ohne Track: Loading-Pin bis Warm-Routing fertig ist.
        final pending = _routedLoopPending.contains(tour.id);
        await c.addSymbol(
          SymbolOptions(
            fontNames: _symbolFonts,
            geometry: tour.center,
            iconImage: _pinImagesReady ? pin : null,
            iconSize: 0.85,
            textField: pending ? '…' : 'T',
            textSize: 11,
            textOffset: const Offset(0, 1.15),
          ),
        );
      }
      await _syncPoiStopMarkers(c);
      await _ensureSymbolTextFont(c);
    } catch (e) {
      debugPrint('syncMarkers: $e');
    }
  }

  /// POI-Stops des ausgewählten Rundkurses als nummerierte Punkte entlang
  /// der Route (Komoot-Highlights) + Start-Fahne am Loop-Anfang.
  /// Symbole wurden vorab via [MapLibreMapController.clearSymbols] entfernt.
  Future<void> _syncPoiStopMarkers(MapLibreMapController c) async {
    final sel = _tourById(_selectedTourId);
    if (sel == null) return;
    final track = _routedLoopCache[sel.id] != null
        ? [for (final p in _routedLoopCache[sel.id]!) [p.lng, p.lat]]
        : sel.trackLngLat;
    if (track == null || track.length < 4) return;
    // Start-Fahne (A wie Komoot) am Anfang des Loops.
    final startLl = LatLng(track.first[1], track.first[0]);
    debugPrint(
      'PoiMarkers start=$startLl pinsReady=$_pinImagesReady stops=${sel.poiStops.length}',
    );
    await c.addSymbol(
      SymbolOptions(
          fontNames: _symbolFonts,
        geometry: startLl,
        iconImage: _pinImagesReady ? 'aether-pin' : null,
        iconSize: 1.2,
        textField: 'Start',
        textSize: 11,
        textColor: '#FFFFFF',
        textHaloColor: '#1B5E20',
        textHaloWidth: 1.4,
        textOffset: const Offset(0, 1.3),
      ),
    );
    if (sel.poiStops.isEmpty || sel.durationMin <= 0) return;
    var i = 0;
    for (final poi in sel.poiStops.take(8)) {
      i++;
      if (poi.atMin <= 0) continue; // Trailhead == Start-Fahne
      final frac = (poi.atMin / sel.durationMin).clamp(0.02, 0.98);
      final pos = _pointAlongTrack(track, frac);
      await c.addSymbol(
        SymbolOptions(
          fontNames: _symbolFonts,
          geometry: pos,
          iconImage: _pinImagesReady ? 'aether-poi' : null,
          iconSize: 1.05,
          textField: '$i · ${poi.title}',
          textSize: 11,
          textColor: '#FFFFFF',
          textHaloColor: '#123A28',
          textHaloWidth: 1.6,
          textOffset: const Offset(0, 1.25),
          textMaxWidth: 12,
        ),
      );
    }
    debugPrint('PoiMarkers drawn=$i tour=${sel.id}');
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(track.first[1], track.first[0]), 14.5),
      );
    } catch (_) {}
  }

  Future<void> _startRide({_RouteSuggestion? suggestion}) async {
    // Map chrome Losfahren often omits [suggestion]; still prefer the selected
    // tour track over hybrid `_computed` (Anfahrt+Loop = open A→B).
    final tour = suggestion ??
        (_selectedTourId != null ? _tourById(_selectedTourId) : null);
    if (tour != null && (_isLoop(tour) || tour.hasTrack)) {
      final routed = await _geometryForTour(tour);
      if (!mounted) return;
      if (routed.demo || routed.points.length < 2) {
        if (_isLoop(tour)) {
          // Never silently demote a Rundkurs to Start→Ziel-Vorschlag.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kein geschlossener Rundkurs-Track — Tour erneut wählen oder Anpassen.',
              ),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kein Live-Track — Route berechnen öffnet Planen mit Ziel-Vorschlag.',
            ),
          ),
        );
        await _computeIdeaRoute(tour);
        return;
      }
      final coords = routed.points.map((p) => [p.lng, p.lat]).toList();
      final closed = navGeometryIsLoop(coords);
      // Honesty: loop selection must navigate a closed polyline.
      if (_isLoop(tour) && !closed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Geometrie ist keine geschlossene Runde — Navigation abgebrochen.',
            ),
          ),
        );
        return;
      }
      final navSteps = navStepsFromPolyline(
        routed.points.map((p) => (lat: p.lat, lng: p.lng)).toList(),
      );
      var steps = [
        for (final st in navSteps)
          NavStep(
            id: st.id,
            instruction: st.instruction,
            distanceAlongM: st.distanceAlongM,
            streetName: extractStreetNameFromInstruction(st.instruction),
          ),
      ];
      try {
        final engine = await _routes
            .planNavAlongTrack(track: routed.points, profile: _profile)
            .timeout(const Duration(seconds: 10));
        final remapped = remapEngineStepsOntoTrack(engine.steps, coords);
        if (engineStepsUseful(remapped)) {
          steps = [
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
      } catch (_) {}
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: tour.id,
        name: tour.name,
        distanceKm: tour.distanceKm,
        elevationM: tour.elevationM.toDouble(),
        durationMin: tour.durationMin,
        mtbScale: tour.mtbScale,
        coordinates: coords,
        steps: steps,
        poiStops: [
          for (final p in tour.poiStops)
            ActiveRoutePoi(
              atMin: p.atMin,
              title: p.title,
              kind: p.kind,
            ),
        ],
        isLoop: closed,
      );
      // Losfahren = start nav (same as discover?start=1 deep-link path).
      ref.read(rideAutostartProvider.notifier).state = true;
      ref.read(shellTabIndexProvider.notifier).state = 2;
      return;
    }

    final engine = _computed;
    if (engine == null) return;
    final eng = engine.engine ?? '';
    final approx = eng.contains('demo') || eng.contains('fallback');
    if (approx || engine.coordinates.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Keine echte Track-Polyline — Route neu berechnen oder GPX.',
            ),
          ),
        );
      }
      return;
    }
    final elevMatch = RegExp(r'\+(\d+)').firstMatch(_elevationSummary ?? '');
    final elevM = elevMatch != null
        ? double.tryParse(elevMatch.group(1)!) ?? engine.distanceM * 0.03
        : engine.distanceM * 0.03;
    final coords = engine.coordinates.map((p) => [p.lng, p.lat]).toList();
    ref.read(activeRouteProvider.notifier).state = ActiveRoute(
      id: 'engine-${DateTime.now().millisecondsSinceEpoch}',
      name: _label ?? 'Berechnete Route',
      distanceKm: engine.distanceM / 1000,
      elevationM: elevM,
      durationMin: (engine.durationS / 60).round(),
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
      isLoop: navGeometryIsLoop(coords),
    );
    ref.read(rideAutostartProvider.notifier).state = true;
    ref.read(shellTabIndexProvider.notifier).state = 2;
  }

  Future<void> _saveCurrent() async {
    final r = _computed;
    if (r == null) return;
    final waypoints = <SavedWaypoint>[
      if (_start != null)
        SavedWaypoint(
          role: 'start',
          lng: _start!.lng,
          lat: _start!.lat,
          label: 'Start',
        ),
      for (var i = 0; i < _vias.length; i++)
        SavedWaypoint(
          role: 'via',
          lng: _vias[i].lng,
          lat: _vias[i].lat,
          label: 'Via ${i + 1}',
        ),
      if (_end != null)
        SavedWaypoint(
          role: 'end',
          lng: _end!.lng,
          lat: _end!.lat,
          label: 'Ziel',
        ),
    ];
    await _routes.saveComputed(
      name: _label ?? 'Gespeicherte Route',
      result: r,
      waypoints: waypoints,
      approach: _approach?.coordinates ?? const [],
      tour: _tourLayer?.coordinates ?? const [],
      trail: _trailOverlay ?? const [],
      source: _approach != null || _tourLayer != null || _trailOverlay != null
          ? 'import'
          : 'engine',
      elevationGainM: _elevationGainM,
    );
    ref.invalidate(savedRoutesProvider);
    if (!mounted) return;
    setState(() => _status = 'Gespeichert');
  }

  Future<void> _saveTourToLibrary(_RouteSuggestion r) async {
    final saved =
        ref.read(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    if (saved.any((e) => e.id == r.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schon in Meine Touren')),
      );
      return;
    }
    final routed = _routedLoopCache[r.id];
    final coords = routed != null && routed.length >= 2
        ? [for (final p in routed) [p.lng, p.lat]]
        : (r.trackLngLat ?? const <List<double>>[]);
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
    ref.invalidate(savedRoutesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('In Meine Touren: ${r.name}')),
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
            final center = _mapCenter;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Route hinzufügen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Name + Start — ohne erfundenen Track. Strecke später berechnen oder GPX.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
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
                        label: const Text('Kartenmitte'),
                        selected: !useGps || gps == null,
                        onSelected: (_) => setSheet(() => useGps = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final origin = (useGps && gps != null) ? gps : center;
                      Navigator.pop(
                        ctx,
                        SimpleAddRoute.fromStart(
                          name: nameCtrl.text,
                          lat: origin.lat,
                          lng: origin.lng,
                        ),
                      );
                    },
                    child: const Text('In Meine Touren speichern'),
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
    if (!mounted) return;
    setState(() {
      _shellMode = DiscoverShellMode.mine;
      _status = 'Gespeichert: ${saved.name}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('In Meine Touren: ${saved.name}')),
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
        title: const Text('GPX importieren'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Datei erneut wählen'),
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
          '„${f.name}“ konnte nicht gelesen werden — beschädigt oder kein gültiges GPX.',
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
        'GPX ungültig oder zu wenige Punkte — andere Datei wählen?',
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
    if (!mounted) return;
    setState(() {
      _status =
          'GPX importiert: ${parsed.name} · ${parsed.distanceKm.toStringAsFixed(1)} km';
      _shellMode = DiscoverShellMode.mine;
      _surface = _Surface.discover;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gespeichert · ${parsed.name}'),
        action: SnackBarAction(
          label: 'Als Active',
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
            ref.read(shellTabIndexProvider.notifier).state = 2;
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
                AppSpacing.l + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sammlungen',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Lokale Ordner für gespeicherte Routen — kein Social-Feed.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final c in cols)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name),
                      subtitle: Text(
                        '${c.routeIds.length} Routen · tippen zum Öffnen',
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
                            const SnackBar(
                              content: Text(
                                'Keine passenden gespeicherten Routen in dieser Sammlung',
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
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await RouteCollectionsStore.delete(c.id);
                          cols = await RouteCollectionsStore.list();
                          setModal(() {});
                        },
                      ),
                    ),
                  if (cols.isEmpty)
                    const Text(
                      'Noch keine Sammlung.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Neue Sammlung',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  FilledButton(
                    onPressed: () async {
                      await RouteCollectionsStore.create(nameCtrl.text);
                      cols = await RouteCollectionsStore.list();
                      nameCtrl.clear();
                      setModal(() {});
                    },
                    child: const Text('Anlegen'),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  OutlinedButton(
                    onPressed: () async {
                      final saved = await _routes.listSaved();
                      if (!ctx.mounted) return;
                      if (saved.isEmpty || cols.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Braucht mindestens eine gespeicherte Route und eine Sammlung',
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
                          title: const Text('Route wählen'),
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
                                title: const Text('Sammlung wählen'),
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
                          const SnackBar(
                            content: Text('Zur Sammlung hinzugefügt'),
                          ),
                        );
                      }
                    },
                    child: const Text('Route zu Sammlung'),
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
      final start = startWp != null
          ? GeoPoint(startWp.lat, startWp.lng)
          : null;
      if (!mounted) return;
      setState(() {
        _computed = null;
        _label = s.name;
        _start = start;
        _end = null;
        _vias.clear();
        _shellMode = DiscoverShellMode.mine;
        _surface = _Surface.discover;
        _status =
            'Startpunkt gespeichert — noch keine Strecke. Navigieren oder GPX.';
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
      engine: 'saved',
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
          s.waypoints
              .where((w) => w.role == 'via')
              .map((w) => GeoPoint(w.lat, w.lng)),
        );
      // Gespeicherte Route: Meine-Modus, Track auf Karte, Los-Leiste.
      _shellMode = DiscoverShellMode.mine;
      _surface = _Surface.discover;
      _status = 'Gespeicherte Route geladen';
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
    ref.listen(discoverLaunchModeProvider, (prev, next) {
      if (next == null) return;
      _applyDiscoverLaunch(next);
    });
    ref.listen(bikesProvider, (prev, next) {
      final c = _map;
      if (c == null || !_bikeOverlayAttached) return;
      unawaited(
        applyBikeOverlayVisibility(
          c,
          family: _overlayFamily,
          visible: _bikeOverlayOn,
          extraOn: _bikeOverlayExtra,
        ),
      );
    });
    _syncOriginDrift();
    final style = _mapStyle;

    final size = MediaQuery.sizeOf(context);
    // `size` bleibt bei geöffneter Tastatur unverändert — nur `viewInsets`
    // wächst. Planen hat zwei Adressfelder; ohne diesen Abzug rechnet die
    // Panel-Höhe unten so, als wäre der ganze Screen frei, und die Tastatur
    // frisst den Platz dann von der Kartenseite statt vom Panel.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Plan/Detail/Navigate: feste Höhen. Entdecken/Meine: Draggable Sheet.
    final desiredPanelHeight = switch (_surface) {
      _Surface.plan => size.height * (_ideaPin != null ? 0.58 : 0.52),
      _Surface.detail => size.height * 0.52,
      _Surface.discover => size.height * _discoverSheetExtent,
    };
    // Tour-Fokus / Peek: mehr Map für die Strecke.
    final mapPeekHeight = _tourMapFocus
        ? 176.0
        : (_surface == _Surface.discover &&
                DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent))
            ? 240.0
            : _minMapPeekHeight;
    // Obere Grenze weicht der Tastatur statt des Kartenrests — die untere
    // Grenze bleibt 220, außer die Tastatur lässt selbst dafür keinen Platz
    // mehr (sehr kleines Gerät + Tastatur): dann gewinnt der verfügbare
    // Raum, damit `clamp` nicht mit min > max abstürzt.
    final maxPanelHeight = math.max(
      220.0,
      math.min(560.0, size.height - keyboardInset - mapPeekHeight),
    );
    final panelHeight = _surface == _Surface.discover
        ? desiredPanelHeight.clamp(
            size.height * DiscoverBrowseSheetSnaps.peek,
            size.height * DiscoverBrowseSheetSnaps.full,
          )
        : desiredPanelHeight.clamp(220.0, maxPanelHeight);
    if (_hofChoice) {
      _panelInset = 188;
    } else if (_surface != _Surface.discover) {
      _panelInset = panelHeight;
    } else if (!_discoverSheetCtrl.isAttached) {
      _panelInset = panelHeight;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Karte füllt den Screen. Discover ist Karte + Liste — nicht
          // Kopfzeile, Kartenfenster und Schubfach übereinander.
          Positioned.fill(child: _buildMap(style)),
          const StatusBarScrim(),
          if (_surface == _Surface.discover)
            Positioned(
              left: AppSpacing.m,
              top: MediaQuery.paddingOf(context).top + 92,
              child: BikeOverlayLegend(
                family: _overlayFamily,
                visible: _bikeOverlayOn,
                extraOn: _bikeOverlayExtra,
                onToggleVisible: () {
                  setState(() => _bikeOverlayOn = !_bikeOverlayOn);
                  final c = _map;
                  if (c != null && _bikeOverlayAttached) {
                    unawaited(
                      applyBikeOverlayVisibility(
                        c,
                        family: _overlayFamily,
                        visible: _bikeOverlayOn,
                        extraOn: _bikeOverlayExtra,
                      ),
                    );
                  }
                },
                onToggleClass: (cls) {
                  setState(() {
                    _bikeOverlayOn = true;
                    if (_bikeOverlayExtra.contains(cls)) {
                      _bikeOverlayExtra.remove(cls);
                    } else {
                      _bikeOverlayExtra.add(cls);
                    }
                  });
                  final c = _map;
                  if (c != null && _bikeOverlayAttached) {
                    unawaited(
                      applyBikeOverlayVisibility(
                        c,
                        family: _overlayFamily,
                        visible: _bikeOverlayOn,
                        extraOn: _bikeOverlayExtra,
                      ),
                    );
                  }
                },
              ),
            ),
          if (!_hofChoice)
            Positioned(top: 0, left: 0, right: 0, child: _buildFloatingHeader()),
          // FAB und Los-Leiste stapeln in EINER bodenverankerten Spalte.
          // Getrennt positioniert bräuchte der FAB die Höhe der Leiste als
          // Konstante — die aber wächst, sobald der Routenname zweizeilig
          // umbricht, und beide würden sich überlappen.
          if (!_hofChoice)
            ListenableBuilder(
            listenable: _discoverSheetCtrl,
            builder: (context, _) {
              final extent = _surface == _Surface.discover
                  ? _discoverSheetExtent
                  : panelHeight / size.height;
              final bottom = extent * size.height + AppSpacing.s;
              // Während Drag: Inset live für Kamera-Padding.
              if (_surface == _Surface.discover &&
                  _discoverSheetCtrl.isAttached) {
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
                    if (_shellMode == DiscoverShellMode.explore &&
                        _surface == _Surface.discover) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            tooltip: AppLocalizations.of(context)
                                .navigateMyLocation,
                            onPressed: _locate,
                            icon: const Icon(Icons.my_location, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (DiscoverBrowseSheetSnaps.isFull(extent) &&
                        _shellMode == DiscoverShellMode.explore &&
                        _surface == _Surface.discover) ...[
                      Center(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.forest,
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
                              DiscoverBrowseSheetSnaps.mapTarget,
                            ),
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(
                            AppLocalizations.of(context).mapToggleFab,
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
                  expand: false,
                  controller: _discoverSheetCtrl,
                  initialChildSize: _listBrowseMode
                      ? DiscoverBrowseSheetSnaps.half
                      : DiscoverBrowseSheetSnaps.peek,
                  minChildSize: DiscoverBrowseSheetSnaps.peek,
                  maxChildSize: DiscoverBrowseSheetSnaps.full,
                  snap: true,
                  snapSizes: DiscoverBrowseSheetSnaps.sheetSnapSizes,
                  builder: (context, scrollController) {
                    return _buildBottomPanel(
                      scrollController: scrollController,
                    );
                  },
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: panelHeight,
                  child: _buildBottomPanel(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(String style) {
    return MapLibreMap(
      key: ValueKey(_mapStyle),
      styleString: style,
      initialCameraPosition: CameraPosition(
        target: LatLng(_mapCenter.lat, _mapCenter.lng),
        zoom: _hasRealOrigin ? 12 : 5.5,
      ),
      compassEnabled: true,
      trackCameraPosition: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      gestureRecognizers: _mapGestures,
      onMapCreated: (c) {
        _map = c;
        _styleReady = false;
        _pinImagesReady = false;
        c.onSymbolTapped.add(_onTfSymbolTapped);
        c.onLineTapped.add(_onQuickLineTapped);
      },
      onStyleLoadedCallback: () {
        _styleReady = true;
        // Style-Reload verwirft addImage-Registrierungen — Pins sonst
        // unsichtbar (Symbol mit fehlendem iconImage rendert gar nicht).
        _pinImagesReady = false;
        _bikeOverlayAttached = false;
        unawaited(_ensureBikeOverlay());
        unawaited(_drawAll());
      },
      onCameraIdle: () {
        final t = _map?.cameraPosition?.target;
        if (t == null) return;
        final next = nextOnlineBasemapStyleUrl(
          currentStyle: _mapStyle,
          lng: t.longitude,
          lat: t.latitude,
        );
        if (next == null || next == _mapStyle || !mounted) return;
        setState(() => _mapStyle = next);
      },
      // Kurzer Tipp setzt Punkte nur, wenn Planen offen ist — sonst bleiben
      // Tipps für Trails/Touren/Routen auf der Karte reserviert.
      onMapClick: (point, latLng) async {
        if (_surface != _Surface.plan) return;
        final p = GeoPoint(latLng.latitude, latLng.longitude);
        final wasWithoutOrigin = !_hasRealOrigin;
        setState(() {
          switch (_pick) {
            case _PickMode.via:
              _vias.add(p);
              break;
            case _PickMode.end:
              _end = p;
              _endAddrCtrl.text = _fmtPoint(p);
              _pick = _PickMode.none;
              break;
            case _PickMode.start:
              _start = p;
              _startAddrCtrl.text = _fmtPoint(p);
              _pick = _PickMode.end;
              break;
            case _PickMode.none:
              if (_start == null) {
                _start = p;
                _startAddrCtrl.text = _fmtPoint(p);
                _pick = _PickMode.end;
              } else {
                _end = p;
                _endAddrCtrl.text = _fmtPoint(p);
              }
              break;
          }
        });
        await _syncMarkers();
        if (wasWithoutOrigin && _hasRealOrigin) {
          _refreshNearbyDataSources();
        }
        if (_start != null && _end != null) {
          await _calcAb();
        }
      },
      // Langer Druck → Navigieren (A→B). Im Detail unberührt; im Navigieren
      // fügt Langdruck einen Via-Punkt hinzu.
      onMapLongClick: (point, latLng) async {
        if (_surface == _Surface.detail) return;
        final p = GeoPoint(latLng.latitude, latLng.longitude);
        final wasWithoutOrigin = !_hasRealOrigin;
        if (_surface == _Surface.plan ||
            _shellMode == DiscoverShellMode.navigate) {
          setState(() => _vias.add(p));
          await _syncMarkers();
          if (_start != null && _end != null) await _calcAb();
          return;
        }
        final asStart = _start == null;
        setState(() {
          if (asStart) {
            _start = p;
            _startAddrCtrl.text = _fmtPoint(p);
          } else {
            _end = p;
            _endAddrCtrl.text = _fmtPoint(p);
          }
        });
        _openPlan(
          status: asStart
              ? 'Start gesetzt — jetzt Ziel wählen'
              : 'Ziel gesetzt — Route wird berechnet',
          pick: asStart ? _PickMode.end : _PickMode.none,
        );
        await _syncMarkers();
        if (wasWithoutOrigin && _hasRealOrigin) {
          _refreshNearbyDataSources();
        }
        if (_start != null && _end != null) {
          await _calcAb();
        }
      },
    );
  }

  String _fmtPoint(GeoPoint p) =>
      '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}';

  Widget _buildHofRideOutChoice() {
    final l10n = AppLocalizations.of(context);
    return Material(
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
    // Tour-Detail: volle Discover-Leiste + Status-Pills ausblenden — nur
    // Zurück (Schließen im Sheet bleibt). Map zeigt die Strecke.
    if (_tourMapFocus) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            0,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: onMap.withValues(alpha: 0.94),
              shape: const CircleBorder(),
              elevation: 3,
              child: IconButton(
                tooltip: l10n.navigateBackToExplore,
                onPressed: _closeDetail,
                icon: const Icon(Icons.arrow_back, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      );
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

  /// Komoot-Chrome: Suche + „Route planen“, darunter Sport · Umkreis · Filter.
  Widget _komootExploreChrome(Color onMap) {
    final l10n = AppLocalizations.of(context);
    final aroundKm = (_maxDistanceKm ?? 35).round();
    return Material(
      color: onMap.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppRadius.card),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exploreSearchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() {
                      _exploreQuery = v;
                      _selectedTourId = null;
                    }),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.chipIdle.withValues(alpha: 0.55),
                      prefixIcon: const Icon(Icons.search, size: 20),
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
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forestOnDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () {
                    if (_start == null && _hasRealOrigin) {
                      setState(() {
                        _start = _origin;
                        _startAddrCtrl.text = 'Meine Position';
                      });
                    }
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _profileChip(),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: Icon(
                      Icons.my_location,
                      size: 15,
                      color: AppColors.chipIdleText,
                    ),
                    label: Text(
                      l10n.filterAroundKm(aroundKm),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => unawaited(_openFilterSheet()),
                    visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: Icon(
                      Icons.tune,
                      size: 15,
                      color: _activeFilterCount > 0
                          ? Colors.white
                          : AppColors.chipIdleText,
                    ),
                    label: Text(
                      _activeFilterCount > 0
                          ? '${l10n.moreFilters} ${_activeFilterCount}'
                          : l10n.moreFilters,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _activeFilterCount > 0
                            ? Colors.white
                            : AppColors.chipIdleText,
                      ),
                    ),
                    backgroundColor: _activeFilterCount > 0
                        ? AppColors.accent
                        : AppColors.chipIdle.withValues(alpha: 0.55),
                    onPressed: () => unawaited(_openFilterSheet()),
                    visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: _activeFilterCount > 0
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: l10n.discoverModeMine,
                    onPressed: () => _setShellMode(DiscoverShellMode.mine),
                    icon: const Icon(Icons.bookmark_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Mehr',
                    onSelected: (v) {
                      switch (v) {
                        case 'collections':
                          _collectionsSheet();
                        case 'trailview':
                          _openTrailView();
                        case 'offline':
                          unawaited(_openOfflineMaps());
                        case 'privacy':
                          unawaited(() async {
                            await openPrivacyScreen(context);
                            if (mounted) await _loadHeatmapConsent();
                          }());
                      }
                    },
                    itemBuilder: (menuCtx) {
                      final m = AppLocalizations.of(menuCtx);
                      return [
                        PopupMenuItem(
                          value: 'collections',
                          child: Text(m.discoverMenuCollections),
                        ),
                        PopupMenuItem(
                          value: 'trailview',
                          child: Text(m.discoverMenuPhotos),
                        ),
                        PopupMenuItem(
                          value: 'offline',
                          child: Text(m.discoverMenuOffline),
                        ),
                        PopupMenuItem(
                          value: 'privacy',
                          child: Text(m.discoverMenuPrivacy),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapNotePill(String text) {
    return Material(
      color: Colors.black.withValues(alpha: 0.68),
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
        navTrack = [for (final p in cached) [p.lng, p.lat]];
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
      _fmtRideDuration(mins),
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
        color: const Color(0xE614201C),
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
                        onTap: () =>
                            setState(() => _rideBarExpanded = false),
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
                                  color: Color(0xFF8FA89C),
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
                                stroke: AppColors.forestOnDark,
                                fill: const Color(0x332D6A4F),
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
                                    color: Color(0xFFB8C9C0),
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
                            tooltip: 'Speichern',
                            onPressed: _saveCurrent,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.bookmark_border,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.forestOnDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                              ),
                              minimumSize: const Size(0, 40),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                unawaited(_startRide(suggestion: sel)),
                            icon: const Icon(Icons.play_arrow, size: 18),
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
                            color: Color(0xFF8FA89C),
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
        child: _buildDetailPanel(),
      );
    } else if (_shellMode == DiscoverShellMode.navigate ||
        _surface == _Surface.plan) {
      panelChild = KeyedSubtree(
        key: const ValueKey('panel-navigate'),
        child: _buildPlanPanel(),
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
    return Semantics(
      label: semanticsLabel ?? l10n.sheetDragHandle,
      button: true,
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: AppSpacing.s, bottom: 2),
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
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
    if (_loopOnly == true) {
      return isDemoGeom ||
          t.contains('näherung') ||
          t.contains('naeherung') ||
          t.contains('live-routing nicht');
    }
    return false;
  }

  Widget _panelMessages() {
    final status = _status;
    final hideStatus =
        status != null && _suppressDemoGeometryBanner(status);
    if (_error == null && (status == null || hideStatus)) {
      return const SizedBox.shrink();
    }
    // Warm-Routing und Pick-Hinweise sind Hintergrund — das Panel-Subtitle reicht.
    final hideWarm = status != null &&
        (status.contains('werden berechnet') ||
            status.contains('wird berechnet') ||
            status.contains('Route wird berechnet') ||
            status.startsWith('Ziel wählen') ||
            status.startsWith('Start wählen') ||
            status.startsWith('Adresse suchen'));
    if (_error == null && hideWarm) {
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
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          if (status != null && !hideStatus)
            Text(
              status,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// Produkt-Default Discover: ~60 Min + Rundkurs (Komoot-nähe „kurze Runde").
  bool get _filtersAtDefaults =>
      _matchTourDuration &&
      _minutes == TourFilters.primaryQuickDurationMin &&
      _loopOnly == true &&
      _surfaceFilter == null &&
      _effortFilter == null &&
      _elevationFilter == null &&
      _maxDistanceKm == null &&
      _trailScaleFilter == null;

  /// Badge am „Mehr Filter"-Chip: nur Abweichungen vom Default / zusätzliche
  /// Einschränkungen — nicht die immer aktiven Primärdefaults (1 Std · Rundkurs).
  int get _activeFilterCount {
    var n = 0;
    if (_matchTourDuration &&
        _minutes > 0 &&
        _minutes != TourFilters.primaryQuickDurationMin) {
      n++;
    }
    if (_surfaceFilter != null) n++;
    if (_effortFilter != null) n++;
    if (_elevationFilter != null) n++;
    if (_maxDistanceKm != null) n++;
    if (_trailScaleFilter != null) n++;
    return n;
  }

  void _resetFilters() {
    setState(() {
      _minutes = TourFilters.primaryQuickDurationMin;
      _matchTourDuration = true;
      _loopOnly = true;
      _surfaceFilter = null;
      _effortFilter = null;
      _elevationFilter = null;
      _maxDistanceKm = null;
      _trailScaleFilter = null;
    });
    unawaited(_drawAll());
  }

  /// Die zwölf Dauer-Chips aus der Kopfzeile leben jetzt hier — sichtbar nur,
  /// wenn man sie braucht. Das war der Hauptgrund für die überladene Leiste.
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
                                label: Text(l10n.durationChipLabel(p.minutes)),
                                selected:
                                    _minutes == p.minutes &&
                                    (p.minutes == 0
                                        ? !_matchTourDuration
                                        : _matchTourDuration),
                                onSelected: (_) => update(() {
                                  _minutes = p.minutes;
                                  _matchTourDuration = p.minutes > 0;
                                  // ~60 Default: Rundkurse mitdenken, nicht erzwingen
                                  // beim Abwählen anderer Dauern.
                                  if (p.minutes ==
                                      TourFilters.primaryQuickDurationMin) {
                                    _loopOnly = true;
                                  }
                                }),
                              ),
                          ]),
                          group(l10n.filterForm, [
                            Tooltip(
                              message: l10n.filterLoopsOnlyTooltip,
                              child: FilterChip(
                                label: Text(l10n.filterLoopsOnly),
                                selected: _loopOnly == true,
                                onSelected: (sel) {
                                  update(() => _loopOnly = sel ? true : null);
                                  if (sel) {
                                    unawaited(_ensureLoopMapHonesty());
                                  } else {
                                    unawaited(_drawAll());
                                  }
                                },
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
                          group(l10n.filterDistance, [
                            for (final d in TourFilters.distanceMaxChips)
                              FilterChip(
                                label: Text(l10n.tourDistanceMaxChip(d.id)),
                                selected: _maxDistanceKm == d.id,
                                onSelected: (sel) => update(
                                  () => _maxDistanceKm = sel ? d.id : null,
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
                              label: Text(
                                _showTrailNetwork
                                    ? l10n.filterNetworkOn
                                    : l10n.filterNetworkOff,
                              ),
                              selected: _showTrailNetwork,
                              onSelected: (v) {
                                update(() => _showTrailNetwork = v);
                                unawaited(_drawAll());
                              },
                            ),
                            FilterChip(
                              label: Text(
                                _showOwnTracks
                                    ? l10n.myRoutesShowOnMap
                                    : l10n.myRoutesHideOnMap,
                              ),
                              selected: _showOwnTracks,
                              onSelected: (v) {
                                update(() => _showOwnTracks = v);
                                unawaited(_drawAll());
                              },
                            ),
                            // OSM-S-Skala (technisch) — nicht dieselben Labels wie
                            // Tour-Schwierigkeit (Leicht/Mittel/Anspruchsvoll).
                            for (final d in TrailDifficulty.values)
                              if (d != TrailDifficulty.open)
                                Tooltip(
                                  message: l10n.filterOsmScaleTooltip(
                                    l10n.trailDifficultyFriendly(d),
                                  ),
                                  child: FilterChip(
                                    label: Text(l10n.trailDifficultyTech(d)),
                                    selected: _trailScaleFilter == d,
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
                                      update(
                                        () =>
                                            _trailScaleFilter = sel ? d : null,
                                      );
                                      unawaited(_drawAll());
                                    },
                                  ),
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
                      border: Border(top: BorderSide(color: AppColors.border)),
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
                            onPressed: _filtersAtDefaults
                                ? null
                                : () {
                                    _resetFilters();
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
                              backgroundColor: AppColors.forestOnDark,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.filterShowTours(_filtered.length)),
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
  Widget _profileChip() {
    return PopupMenuButton<RoutingProfile>(
      tooltip: 'Profil wählen',
      initialValue: _profile,
      onSelected: (p) {
        setState(() => _profile = p);
        final c = _map;
        if (c != null && _bikeOverlayAttached) {
          unawaited(
            applyBikeOverlayVisibility(
              c,
              family: _overlayFamily,
              visible: _bikeOverlayOn,
              extraOn: _bikeOverlayExtra,
            ),
          );
        }
        if (_surface == _Surface.plan ||
            _shellMode == DiscoverShellMode.navigate) {
          // Im Navigieren nie _refreshQuick: das würde die halb gebaute Route
          // durch einen Schnell-Vorschlag ersetzen und die Karte umzeichnen.
          if (_start != null && _end != null) unawaited(_calcAb());
        } else {
          unawaited(_refreshQuick(limit: 3));
          unawaited(_fetchPublicCatalog());
        }
      },
      itemBuilder: (_) => [
        for (final p in _kDiscoverProfileMenuOrder)
          PopupMenuItem(value: p, child: Text(p.label)),
      ],
      child: _panelChip(
        icon: Icons.pedal_bike,
        label: _profile.label,
        selected: false,
      ),
    );
  }

  Widget _panelChip({
    required IconData icon,
    required String label,
    required bool selected,
    int badge = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.accent
              : AppColors.muted.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: selected ? Colors.white : null),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : null,
            ),
          ),
          if (badge > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
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
    if (_hofDirectNav) {
      await _startRide(suggestion: r);
      return;
    }
    if (r.hasTrack) {
      await _drawSeedLoopPreview(r);
      if (!mounted) return;
      try {
        await _map?.animateCamera(
          CameraUpdate.newLatLngZoom(r.center, 12.5),
        );
      } catch (_) {}
    } else {
      // Pin-only: Detail erklärt „Route berechnen" klarer als leere Karte.
      await _openDetail(r.id, r.center);
    }
  }

  /// Der eine Discover-Zustand: Steuerzeile, dann eine durchgehende Liste aus
  /// Schnell-Vorschlägen und Touren. A→B und Meine Strecken sind eigene
  /// Shell-Modi (nicht mehr in dieser Liste vergraben).
  ///
  /// Mit [scrollController] vom Sheet: Drag am Handle/Liste bewegt Snaps;
  /// Primärchips (Dauer · Rundkurs · Asphalt · Distanz) bleiben sportneutral.
  Widget _buildDiscoverPanel({ScrollController? scrollController}) {
    final l10n = AppLocalizations.of(context);
    final peek = DiscoverBrowseSheetSnaps.isPeek(_discoverSheetExtent);
    final sections = <Widget>[
      if (_loopOnly != true) ..._quickSection(),
      ..._toursSection(),
    ];

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
          if (!peek) ...[
            Text(
              l10n.navDiscover,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );

    final peekTour = _selectedTourId != null
        ? _tourById(_selectedTourId)
        : (_filtered.isNotEmpty ? _filtered.first : null);
    final pinnedTour =
        _selectedTourId != null ? _tourById(_selectedTourId) : null;
    final topCard = pinnedTour ?? (peek ? peekTour : null);

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
                child: _tourListCard(topCard, _origin),
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

  /// Meine Strecken — UGC / Import / Recorded als eigener Shell-Modus.
  Widget _buildMinePanel({ScrollController? scrollController}) {
    final l10n = AppLocalizations.of(context);
    final savedList =
        ref.watch(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
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
                  l10n.myRoutesTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilterChip(
                label: Text(
                  _showOwnTracks
                      ? l10n.myRoutesHideOnMap
                      : l10n.myRoutesShowOnMap,
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.forestOnDark),
              onPressed: () => unawaited(_addSimpleRouteSheet()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Route hinzufügen'),
            ),
            OutlinedButton.icon(
              onPressed: _importGpxDialog,
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(l10n.gpxImportAction),
            ),
          ],
        ),
      ),
      if (savedList.isEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Noch keine eigenen Strecken — Route hinzufügen, GPX oder aufzeichnen.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _setShellMode(
            DiscoverShellMode.navigate,
            pick: _PickMode.start,
          ),
          icon: const Icon(Icons.navigation_outlined),
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

  /// Navigieren — A→B als erster Klasse-Modus (Komoot-ähnlich).
  /// Bei Tour-Anpassen bleibt ein Zurück; sonst steuert der Shell-Toggle.
  Widget _buildPlanPanel() {
    final l10n = AppLocalizations.of(context);
    final adapting = _adaptingTourName;
    return Column(
      children: [
        _panelHandle(semanticsLabel: l10n.sheetDragHandleNavigate),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.m,
            0,
          ),
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
                          : l10n.navigateTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      adapting != null ? adapting : l10n.navigateSubtitle,
                      maxLines: 2,
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
              _profileChip(),
            ],
          ),
        ),
        if (adapting != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              0,
              AppSpacing.m,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.adaptTourHint,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        _panelMessages(),
        Expanded(child: _withLoadingVeil(_buildPlanSheet())),
      ],
    );
  }

  /// Tour-Detail — vorher ein eigener `Scaffold` mit `AppBar`, der beim
  /// Antippen einer Tour die ganze Karte wegriss. Jetzt derselbe Platz wie
  /// Planen: ein Panel über der Karte, die im Hintergrund auf die Tour
  /// zentriert bleibt (siehe [_openDetail]).
  Widget _buildDetailPanel() {
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
                  tooltip: 'Zurück zu Discover',
                  onPressed: _closeDetail,
                  icon: const Icon(Icons.arrow_back),
                  visualDensity: VisualDensity.compact,
                ),
                const Expanded(
                  child: Text(
                    'Tour nicht mehr verfügbar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.l),
                child: Text(
                  'Diese Tour ist gerade nicht in der Liste — z. B. weil ein '
                  'Filter sie ausschließt.',
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

    return Column(
      children: [
        _panelHandle(),
        // Komoot/AllTrails: Zurück — Anpassen lebt nur in der Sticky-Bar.
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
                tooltip: 'Zurück zu Discover',
                onPressed: _closeDetail,
                icon: const Icon(Icons.arrow_back),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
            ],
          ),
        ),
        _panelMessages(),
        Expanded(
          child: _withLoadingVeil(
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.l,
                AppSpacing.l,
              ),
              children: [
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
                  _detailSectionTitle('Tourverlauf'),
                  const SizedBox(height: AppSpacing.s),
                  for (var i = 0; i < detail.poiStops.length; i++)
                    _poiTimelineTile(
                      detail.poiStops[i],
                      isLast: i == detail.poiStops.length - 1,
                    ),
                ],
                ..._detailInfoSection(detail, tipRow),
                const SizedBox(height: AppSpacing.xl),
                TourCommunitySection(tourId: detail.id),
                const SizedBox(height: AppSpacing.l),
                _detailStartRow(detail),
                if (_isPinOnlyIdea(detail)) ...[
                  const SizedBox(height: AppSpacing.s),
                  const Text(
                    'Noch keine Strecke — „Route berechnen“ baut sie live.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
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
        const Text(
          '⟲ Rundkurs',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.forestOnDark,
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
          sport,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    } else if (detail.sourceKind == 'osm' ||
        detail.sourceKind == 'outdooractive' ||
        detail.sourceKind == 'catalog') {
      add(
        Text(
          detail.sourceLabel,
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
            _difficultyDisplay(detail.mtbScale),
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
              cell('Dauer', _fmtRideDuration(detail.durationMin)),
              vSep(),
              cell(
                'Länge',
                '${detail.distanceKm.toStringAsFixed(detail.distanceKm < 10 ? 1 : 0)} km',
              ),
            ],
          ),
          Container(height: 1, color: AppColors.border),
          Row(
            children: [
              cell('Aufstieg', gainM != null ? '↑ $gainM m' : '—'),
              vSep(),
              cell('Untergrund', surfaceLabel),
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
      _detailSectionTitle('Höhenprofil'),
      const SizedBox(height: AppSpacing.s),
      SizedBox(
        width: double.infinity,
        height: 64,
        child: CustomPaint(painter: _MiniElevPainter(elev.samples)),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '↓ ${elev.lossM.round()} m Abstieg',
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    ];
  }

  /// Ein Stop im Tourverlauf: Punkt + Linie links (Komoot-Timeline),
  /// Minuten-Marke, Titel, whyGood.
  Widget _poiTimelineTile(_SeedPoiStop p, {required bool isLast}) {
    return IntrinsicHeight(
      key: ValueKey(p.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.chipIdle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    _poiKindIcon(p.kind),
                    size: 15,
                    color: AppColors.forestOnDark,
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
                    p.atMin > 0 ? 'Min ${p.atMin}' : 'Start',
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
    );
  }

  /// „Tipps & Infos" — Tipp, Saison, Untergrund, Disziplin, Korridor, API-Tags
  /// als Icon-Zeilen (ersetzt die früheren Einzel-Überschriften).
  List<Widget> _detailInfoSection(_RouteSuggestion detail, String? tipRow) {
    final tagLine = _detailTagLine(detail);
    // Untergrund steht schon im Stats-Grid — hier nicht wiederholen.
    final rows = <({IconData icon, String label, String text})>[
      if (tipRow != null)
        (icon: Icons.lightbulb_outline, label: 'Tipp', text: tipRow),
      if (detail.seasonLabel case final s?)
        (icon: Icons.event, label: 'Beste Zeit', text: s),
      if (detail.disciplineNote case final d?)
        (icon: Icons.directions_bike, label: 'Disziplin', text: d),
      if (detail.corridorNote case final c?)
        (icon: Icons.alt_route, label: 'Korridor', text: c),
      if (tagLine != null)
        (icon: Icons.label_outline, label: 'Merkmale', text: tagLine),
    ];
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.l),
      _detailSectionTitle('Tipps & Infos'),
      const SizedBox(height: AppSpacing.s),
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(r.icon, size: 18, color: AppColors.muted),
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
    ];
  }

  /// Compact trail/catalog tags — skip noise already shown as source/sport.
  String? _detailTagLine(_RouteSuggestion detail) {
    final skip = <String>{
      detail.sourceKind,
      'outdooractive',
      'osm',
      'catalog',
      'seed',
      if (detail.sportLabel != null) detail.sportLabel!.toLowerCase(),
    };
    final seen = <String>{};
    final out = <String>[];
    for (final raw in detail.apiTags) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (skip.contains(key) || seen.contains(key)) continue;
      seen.add(key);
      out.add(t);
      if (out.length >= 5) break;
    }
    if (out.isEmpty) return null;
    return out.join(' · ');
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
          const Icon(
            Icons.place_outlined,
            size: 20,
            color: AppColors.forestOnDark,
          ),
          const SizedBox(width: AppSpacing.s + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Startpunkt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '$distLabel von hier',
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
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Anfahrt'),
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
                backgroundColor: AppColors.forestOnDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: _loading
                  ? null
                  : pinOnly
                      ? () => unawaited(_computeIdeaRoute(detail))
                      : () => unawaited(_startRide(suggestion: detail)),
              icon: Icon(pinOnly ? Icons.route : Icons.play_arrow, size: 22),
              label: Text(
                pinOnly ? l10n.computeRoute : l10n.goRide,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          IconButton(
            tooltip: 'In Meine Touren',
            onPressed: _loading
                ? null
                : () => unawaited(_saveTourToLibrary(detail)),
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                foregroundColor: const Color(0xFFE8EEEA),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: _loading
                  ? null
                  : () => unawaited(_adoptTourIntoPlan(detail)),
              icon: const Icon(Icons.tune, size: 16),
              label: Text(l10n.adaptTour),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withLoadingVeil(Widget body) {
    if (!_loading) return body;
    return Stack(
      children: [
        Opacity(opacity: 0.45, child: IgnorePointer(child: body)),
        const Center(child: CircularProgressIndicator()),
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

  /// „Schnell" ist kein eigener Modus mehr, sondern die erste Sektion der
  /// Discover-Liste — im selben vertikalen Kartenformat wie die Touren.
  /// Jede Karte benennt, ob der Rückweg enthalten ist: live geroutet wird
  /// nur der Hinweg zum Ziel, nur die Offline-Näherung hängt ihn an.
  List<Widget> _quickSection() {
    return [
      _sectionTitle(
        'In deiner Nähe · ${_profile.label}',
        hint: _hasRealOrigin
            ? 'Tippen zeigt die Strecke · Losfahren startet die Navigation'
            : 'Standort freigeben für Touren ab hier',
        trailing: TextButton(
          onPressed: _loading ? null : () => unawaited(_refreshQuick(limit: 3)),
          child: const Text('Neu'),
        ),
      ),
      if (!_hasRealOrigin)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: OutlinedButton.icon(
            onPressed: () => unawaited(_locate()),
            icon: const Icon(Icons.my_location),
            label: const Text('Standort freigeben'),
          ),
        ),
      if (_quick.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Text(
            _loading
                ? 'Vorschläge werden berechnet…'
                : 'Keine Vorschläge — Standort setzen, Rad-Profil wählen oder „Neu“.',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      for (final q in _quick)
        Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.s),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            side: BorderSide(
              color: _label == q.label ? AppColors.accent : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 8, right: 4),
                  leading: const Icon(Icons.near_me, color: AppColors.accent),
                  title: Text(
                    q.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${(q.result.distanceM / 1000).toStringAsFixed(1)} km · '
                    '${(q.result.durationS / 60).round()} min · '
                    '${q.result.engine == 'approx' ? 'Hin & zurück' : 'nur Hinweg'}'
                    '\n${q.reason}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    setState(() {
                      _computed = q.result;
                      _label = q.label;
                      _selectedTourId = null;
                    });
                    await _drawRoute(q.result);
                  },
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          _computed = q.result;
                          _label = q.label;
                        });
                        await _drawRoute(q.result);
                        if (!mounted) return;
                        _openPlan(status: 'Vorschlag anpassen: ${q.label}');
                      },
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(AppLocalizations.of(context).adaptTour),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forestOnDark,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        setState(() {
                          _computed = q.result;
                          _label = q.label;
                          _selectedTourId = null;
                        });
                        await _drawRoute(q.result);
                        if (!mounted) return;
                        await _startRide();
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(AppLocalizations.of(context).goRide),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  void _swapStartEnd() {
    final s = _start;
    final e = _end;
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
    if (_start != null && _end != null) unawaited(_calcAb());
  }

  Future<void> _useMyLocationAsStart() async {
    var u = _userPos;
    if (u == null) {
      await _locate();
      u = _userPos;
    }
    if (!mounted || u == null) return;
    setState(() {
      _start = u;
      _startAddrCtrl.text = AppLocalizations.of(context).navigateMyLocation;
      _pick = _end == null ? _PickMode.end : _PickMode.none;
      _addrHits = const [];
    });
    await _syncMarkers();
    if (_end != null) await _calcAb();
  }

  Widget _buildPlanSheet() {
    final l10n = AppLocalizations.of(context);
    final ideaTour = _ideaPin != null ? _tourById(_selectedTourId) : null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        if (_ideaPin != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ideaTour != null
                      ? 'Idee „${ideaTour.name}“ — nur Ortspunkt'
                      : 'Tour-Idee — nur Ortspunkt auf der Karte',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _end == null
                      ? 'Ziel tippen oder Adresse — dann Route berechnen.'
                      : 'Start/Ziel gesetzt. Route berechnen oder Ziel anpassen.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        // Komoot: A/B in einem Block, Map-Tippen statt Chip-Leiste.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.forest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Semantics(
                      label: l10n.navigateStartLabel,
                      textField: true,
                      child: TextField(
                        controller: _startAddrCtrl,
                        focusNode: _startAddrFocus,
                        autofillHints: const [AutofillHints.addressCity],
                        decoration: InputDecoration(
                          labelText: 'A  ${l10n.navigateStartLabel}',
                          hintText: l10n.navigateStartHint,
                          prefixIcon: const Icon(Icons.trip_origin, size: 18),
                          suffixIcon: IconButton(
                            tooltip: l10n.navigateMyLocation,
                            onPressed: () =>
                                unawaited(_useMyLocationAsStart()),
                            icon: const Icon(Icons.my_location, size: 18),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.chip),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _scheduleAddressSearch('start'),
                        onSubmitted: (_) {
                          unawaited(_searchAddress('start'));
                          _endAddrFocus.requestFocus();
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Semantics(
                      label: l10n.navigateEndLabel,
                      textField: true,
                      child: TextField(
                        controller: _endAddrCtrl,
                        focusNode: _endAddrFocus,
                        autofillHints: const [AutofillHints.addressCity],
                        decoration: InputDecoration(
                          labelText: 'B  ${l10n.navigateEndLabel}',
                          hintText: l10n.navigateEndHint,
                          prefixIcon: const Icon(Icons.flag_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.chip),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => _scheduleAddressSearch('end'),
                        onSubmitted: (_) => _searchAddress('end'),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.navigateSwap,
                onPressed: _swapStartEnd,
                icon: const Icon(Icons.swap_vert),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _pick = _PickMode.via),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.navigateAddVia),
          ),
        ),
        if (_addrBusy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: LinearProgressIndicator(),
          ),
        for (final h in _addrHits)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined, size: 18),
            title: Text(h.label, style: const TextStyle(fontSize: 13)),
            onTap: () => _applyAddressHit(h),
          ),
        if (_vias.isNotEmpty) ...[
          ..._vias.asMap().entries.map(
            (e) => Row(
              children: [
                Expanded(
                  child: Text(
                    'Via ${e.key + 1}: ${e.value.lat.toStringAsFixed(3)}, '
                    '${e.value.lng.toStringAsFixed(3)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() => _vias.removeAt(e.key));
                    if (_start != null && _end != null) {
                      unawaited(_calcAb());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestOnDark,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _loading
              ? null
              : () {
                  final idea = _tourById(_selectedTourId);
                  if (_ideaPin != null &&
                      idea != null &&
                      (_end == null || _computed == null)) {
                    unawaited(_computeIdeaRoute(idea));
                  } else {
                    unawaited(_calcAb());
                  }
                },
          icon: const Icon(Icons.route),
          label: Text(
            _start == null || _end == null
                ? l10n.navigateComputeNeedBoth
                : (ideaTour != null
                    ? 'Route berechnen & speichern'
                    : l10n.computeRoute),
          ),
        ),
        if (_computed != null && _start != null && _end != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            '${(_computed!.distanceM / 1000).toStringAsFixed(1)} km · '
            '${(_computed!.durationS / 60).round()} min'
            '${_elevationSummary != null ? ' · $_elevationSummary' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }


  /// Demo-Stadt centers from bundled Nähe seeds (Berlin + DACH + Rhein-Neckar).
  /// Chip only meaningful when ≥1 seed in 45–75 min exists for that city.
  static const _demoCities = <({String name, double lat, double lng})>[
    (name: 'Wiesloch', lat: 49.295, lng: 8.698),
    (name: 'Heidelberg', lat: 49.409, lng: 8.694),
    (name: 'Mannheim', lat: 49.483, lng: 8.462),
    (name: 'Berlin', lat: 52.52, lng: 13.405),
    (name: 'Hamburg', lat: 53.567, lng: 10.005),
    (name: 'München', lat: 48.183, lng: 11.61),
    (name: 'Köln', lat: 50.941, lng: 6.958),
    (name: 'Frankfurt', lat: 50.106, lng: 8.685),
    (name: 'Stuttgart', lat: 48.812, lng: 9.23),
    (name: 'Zürich', lat: 47.366, lng: 8.541),
    (name: 'Wien', lat: 48.218, lng: 16.392),
    (name: 'Innsbruck', lat: 47.286, lng: 11.399),
    (name: 'Konstanz', lat: 47.677, lng: 9.174),
    (name: 'Paris', lat: 48.828, lng: 2.435),
    (name: 'Lyon', lat: 45.777, lng: 4.855),
    (name: 'Straßburg', lat: 48.583, lng: 7.75),
    (name: 'Nizza', lat: 43.695, lng: 7.265),
    (name: 'Annecy', lat: 45.887, lng: 6.12),
  ];

  void _focusOrtSearch() {
    _openPlan(
      status: 'Ort ändern — Stadt oder Adresse suchen',
      pick: _PickMode.start,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAddrFocus.requestFocus();
    });
  }

  Future<void> _applyDemoCity(String name, double lat, double lng) async {
    setState(() {
      // Demo-Ort schlägt GPS, sonst bliebe _userPos die echte Position.
      _userPos = null;
      _start = GeoPoint(lat, lng);
      _startAddrCtrl.text = name;
      _minutes = 60;
      _matchTourDuration = true;
      _loopOnly = true;
      _status = 'Demo-Region: $name';
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
      SnackBar(content: Text('Demo-Region: $name')),
    );
    try {
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12),
      );
    } catch (_) {}
    unawaited(_fetchOutdooractive());
    unawaited(_fetchOsmRoutes());
    unawaited(_fetchPublicCatalog());
    unawaited(_refreshQuick(limit: 3));
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                hasFilters
                    ? l10n.emptyToursFiltersBody
                    : l10n.emptyToursNearbyBody,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              if (hasFilters) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forestOnDark,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () {
                      _resetFilters();
                      unawaited(_refreshQuick(limit: 3));
                    },
                    icon: const Icon(Icons.filter_alt_off),
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
                        icon: const Icon(Icons.search),
                        label: const Text('Ort ändern'),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.forestOnDark,
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: _focusOrtSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('Ort ändern'),
                      ),
              ),
              const SizedBox(height: AppSpacing.s),
              const Text(
                'Dauer vorschlagen',
                style: TextStyle(
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
                        p.minutes == 60
                            ? l10n.quickFilter1h
                            : p.label,
                      ),
                      onPressed: () {
                        setState(() {
                          _minutes = p.minutes;
                          _matchTourDuration = p.minutes > 0;
                          if (p.minutes == 60) {
                            _loopOnly = true;
                          } else if (p.minutes == 0) {
                            _loopOnly = null;
                          }
                        });
                        unawaited(_refreshQuick(limit: 3));
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              if (kDebugMode || AppConfig.allowDemoContent) ...[
                const Text(
                  'Demo-Städte',
                  style: TextStyle(
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
                        label: Text(c.name),
                        onPressed: () => unawaited(
                          _applyDemoCity(c.name, c.lat, c.lng),
                        ),
                      ),
                  ],
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openPlan(
                    status: 'Route selbst planen — Start & Ziel setzen',
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
                l10n.emptyToursTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.emptyToursFiltersBody,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forestOnDark,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: () {
                  _resetFilters();
                  unawaited(_refreshQuick(limit: 3));
                },
                icon: const Icon(Icons.filter_alt_off),
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
    final catalog = list.where((r) => r.isCatalog && !skip(r)).toList();
    final live =
        list.where((r) => !r.isCatalog && !r.isSeed && !skip(r)).toList();
    // Seed strip for ~60 / Rundkurs: honest loops only — never fill with A→B.
    final seedsAll = list.where((r) => r.isSeed && !skip(r)).toList();
    final seeds = (_minutes == 60 || _loopOnly == true)
        ? seedsAll.where(_isLoop).toList()
        : seedsAll;
    final o = _origin;
    // Seeds immer zeigen, sobald welche durch Filter/Coverage kommen.
    final showSeeds = seeds.isNotEmpty;
    final seedLabel = _hasRealOrigin
        ? (_seedsBundle?.labelWithLocation ?? '~60 Min um dich')
        : (_seedsBundle?.labelWithoutLocation ?? '~60 Min in deiner Region');

    final loopCount = list.where(_isLoop).length;
    // Soft radius for empty-ort UI — Coverage nutzt 90 km + Fill.
    const seedRadiusKm = TourCoverage.nearbyRadiusKm;
    final nearbyLoopCount = list.where((r) {
      if (!_isLoop(r)) return false;
      return _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude) <=
          seedRadiusKm;
    }).length;

    return [
      _sectionTitle(
        list.isEmpty
            ? 'Touren'
            : loopCount > 0
                ? 'Touren · $loopCount Rundkurse'
                : 'Touren · ${list.length}',
        hint: _hasRealOrigin
            ? null
            : 'Ohne GPS: kuratierte Touren · Standort für Nähe',
        trailing: TextButton(
          onPressed: _loading
              ? null
              : () {
                  unawaited(_fetchPublicCatalog());
                  unawaited(_fetchOsmRoutes());
                  unawaited(_fetchTrailNetwork());
                  unawaited(_loadNaeheSeeds());
                },
          child: const Text('Neu'),
        ),
      ),
      // Eine Statuszeile statt Standort + Seeds + OA + Trailnetz + Heatmap.
      Builder(
        builder: (_) {
          String? line;
          TextStyle style = const TextStyle(fontSize: 12, color: AppColors.muted);
          VoidCallback? onTap;
          if (!_hasRealOrigin) {
            line = 'Standort freigeben für Touren in deiner Nähe';
          } else if (showSeeds) {
            line =
                '${seeds.length} Touren in der Nähe'
                '${_seedsStatus != null ? ' · offline' : ''}';
          } else if (_oaStatus != null &&
              (_oaStatus!.toLowerCase().contains('offline') ||
                  _oaStatus!.toLowerCase().contains('keine'))) {
            line = _oaStatus;
            style = const TextStyle(fontSize: 11, color: AppColors.muted);
          } else if (_trailNetworkStatus != null &&
              _trailNetworkStatus!.toLowerCase().contains('kein')) {
            line = _trailNetworkStatus;
            style = const TextStyle(fontSize: 11, color: AppColors.muted);
          } else if (!_heatmapConsent) {
            line = 'Heatmaps nach Consent — Privatsphäre öffnen';
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
              color: Color(0xFFFF7043),
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
                leading: Icon(
                  Icons.terrain,
                  color: Color(
                    int.parse('FF${sel.lineColor.substring(1)}', radix: 16),
                  ),
                ),
                title: Text(sel.name),
                subtitle: Text(
                  '${sel.difficultyLabel} · ${sel.lengthKm.toStringAsFixed(1)} km',
                ),
                trailing: IconButton(
                  tooltip: 'Zum Startpunkt',
                  icon: const Icon(Icons.navigation),
                  onPressed: () => unawaited(_approachTrail(sel!)),
                ),
                onTap: () => unawaited(_showTrailSheet(sel!)),
              ),
            );
          },
        ),
      // Empty only when zero honest loops in the filtered list — never hide
      // nearby seed cards behind the ort picker while loops exist (S25).
      if (loopCount == 0 && (_minutes == 60 || _loopOnly == true))
        _emptyOrtPicker()
      else if (list.isEmpty)
        !_filtersAtDefaults
            ? _emptyFilterState()
            : _emptyOrtPicker()
      else if (nearbyLoopCount == 0 &&
          _minutes == 60 &&
          loopCount > 0 &&
          !showSeeds)
        _emptyOrtPicker(),
      if (showSeeds) ...[
        _sectionTitle(
          '$seedLabel (${seeds.length})',
          hint: _hasRealOrigin
              ? 'Rundkurse in deiner Nähe'
              : 'Empfohlene Touren · auch ohne GPS',
        ),
        for (final r in seeds) _tourListCard(r, o),
      ],
      if (catalog.isNotEmpty) ...[
        _sectionTitle(
          'Empfohlen (${catalog.length})',
          hint: 'Für alle Radtypen · Strecke beim Losfahren',
        ),
        for (final r in catalog) _tourListCard(r, o),
      ],
      if (live.isNotEmpty) ...[
        _sectionTitle(
          'In der Region (${live.length})',
          hint: _hasRealOrigin
              ? 'Touren aus der Umgebung'
              : 'Erscheint nach Standort',
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
                        icon: Icons.terrain,
                        label: _difficultyDisplay(r.mtbScale),
                        emphasize: true,
                      ),
                      const SizedBox(height: 6),
                      _HeroChip(
                        icon: Icons.straighten,
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
                    stroke: const Color(0xFF4ADE80),
                    fill: const Color(0x331B3A2F),
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
      difficultyLabel: _difficultyDisplay(r.mtbScale),
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
          colors: [Color(0xFF2D4A35), Color(0xFF1A2E24), Color(0xFF0F1A16)],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Text(
        r.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _tourListCard(_RouteSuggestion r, GeoPoint o) {
    final l10n = AppLocalizations.of(context);
    final loop = _isLoop(r);
    final selected = _selectedTourId == r.id;
    final distKm =
        _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude);
    final pinOnly = _isPinOnlyIdea(r);
    // Eine Meta-Zeile wie Komoot: Dauer · km · hm · Form — kein Pitch/★ in der Liste.
    final metaParts = <String>[
      _fmtRideDuration(r.durationMin),
      '${r.distanceKm.toStringAsFixed(r.distanceKm < 10 ? 1 : 0)} km',
      if (r.elevationM > 0) '↑ ${r.elevationM} m',
      if (loop) l10n.loopLabel,
    ];
    final nearLabel = distKm < 1
        ? '<1 km'
        : distKm < 10
            ? '${distKm.toStringAsFixed(1)} km'
            : '${distKm.round()} km';
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
                      onTap: () => unawaited(_openDetail(r.id, r.center)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            r.name,
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
                            '$nearLabel entfernt'
                            '${r.sportLabel != null ? ' · ${r.sportLabel}' : ''}',
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
                              backgroundColor: AppColors.forestOnDark,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                            onPressed: _loading
                                ? null
                                : pinOnly
                                    ? () => unawaited(_computeIdeaRoute(r))
                                    : () =>
                                        unawaited(_startRide(suggestion: r)),
                            icon: Icon(
                              pinOnly ? Icons.route : Icons.play_arrow,
                              size: 20,
                            ),
                            label: Text(
                              pinOnly ? l10n.computeRoute : l10n.goRide,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: l10n.tourDetails,
                          onPressed: () =>
                              unawaited(_openDetail(r.id, r.center)),
                          icon: const Icon(Icons.info_outline, size: 22),
                          visualDensity: VisualDensity.compact,
                        ),
                        PopupMenuButton<String>(
                          tooltip: l10n.moreActions,
                          onSelected: (v) async {
                            switch (v) {
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
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'map',
                              child: Text(l10n.showOnMap),
                            ),
                            PopupMenuItem(
                              value: 'adapt',
                              child: Text(l10n.adaptTour),
                            ),
                            const PopupMenuItem(
                              value: 'fromHere',
                              child: Text('Von hier'),
                            ),
                            const PopupMenuItem(
                              value: 'photos',
                              child: Text('Fotos in der Nähe'),
                            ),
                            const PopupMenuItem(
                              value: 'save',
                              child: Text('Zu Meine Touren'),
                            ),
                          ],
                          icon: const Icon(Icons.more_horiz),
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
    final savedList =
        ref.watch(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    return [
      if (includeTitle) ...[
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.myRoutesTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
      ],
      if (savedList.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.myRoutesEmpty,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        )
      else
        for (final s in savedList)
          ListTile(
            dense: true,
            leading: Icon(
              s.source == 'recorded'
                  ? Icons.fiber_manual_record
                  : (s.source == 'import'
                      ? Icons.upload_file
                      : Icons.route),
              color: Color(
                int.parse(
                  'FF${DiscoverMapLineStyle.ownTrack.substring(1)}',
                  radix: 16,
                ),
              ),
            ),
            title: Text(s.name),
            subtitle: Text(
              s.coordinates.length < 2
                  ? '${_sourceBadge(l10n, s.source)} · Startpunkt — noch keine Strecke'
                  : '${_sourceBadge(l10n, s.source)} · '
                      '${s.distanceKm.toStringAsFixed(1)} km · ${s.durationMin} min',
            ),
            onTap: () => _loadSaved(s),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.myRouteOpenDetail,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => unawaited(_openMyRouteDetail(s)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _routes.deleteSaved(s.id);
                    await SavedRouteMetaStore.delete(s.id);
                    ref.invalidate(savedRoutesProvider);
                    unawaited(_drawAll());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    ref.read(activeRouteProvider.notifier).state = ActiveRoute(
                      id: s.id,
                      name: s.name,
                      distanceKm: s.distanceKm,
                      elevationM: s.elevationM,
                      durationMin: s.durationMin,
                      coordinates: s.coordinates,
                      isLoop: navGeometryIsLoop(s.coordinates),
                    );
                    ref.read(shellTabIndexProvider.notifier).state = 2;
                  },
                ),
              ],
            ),
          ),
    ];
  }

  String _sourceBadge(AppLocalizations l10n, String source) {
    switch (source) {
      case 'import':
        return l10n.myRoutesSourceImport;
      case 'recorded':
        return l10n.myRoutesSourceRecorded;
      case 'library':
        return 'Eigene';
      default:
        return l10n.myRoutesSourceEngine;
    }
  }

  Future<void> _openMyRouteDetail(SavedRouteEntry s) async {
    final l10n = AppLocalizations.of(context);
    var meta = await SavedRouteMetaStore.get(s.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_sourceBadge(l10n, s.source)} · '
                      '${s.distanceKm.toStringAsFixed(1)} km · '
                      '${s.elevationM.round()} hm · ${s.durationMin} min',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (meta.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(meta.description),
                    ],
                    if (meta.photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.myRouteDetailPhotos,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: meta.photoPaths.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final path = meta.photoPaths[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 88,
                                  height: 88,
                                  color: AppColors.muted.withValues(alpha: 0.2),
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SavedRouteNotesSection(
                      notes: meta.notes,
                      onAdd: (text) async {
                        final note = SavedRouteNote.create(text: text);
                        meta = await SavedRouteMetaStore.addNote(s.id, note);
                        setSheet(() {});
                      },
                      onRemove: (id) async {
                        meta = await SavedRouteMetaStore.removeNote(s.id, id);
                        setSheet(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        unawaited(_loadSaved(s));
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.showOnMap),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                  foregroundColor: AppColors.forestOnDark,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
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
                      icon: Icons.terrain,
                      label: widget.difficultyLabel,
                      emphasize: true,
                    ),
                    const SizedBox(height: 6),
                    _HeroChip(
                      icon: Icons.place_outlined,
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
                  stroke: const Color(0xFF4ADE80),
                  fill: const Color(0x331B3A2F),
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
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasize ? const Color(0xE61B3A2F) : const Color(0xCC0A1210),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
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
        color: const Color(0xEE14201C),
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
        _error = friendlyErrorMessage(e, context: 'Trail-Ansicht');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Text(
                    'Trail View',
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
              Text(_error!, style: const TextStyle(color: Colors.redAccent))
            else ...[
              SizedBox(
                height: 220,
                child: photos.isEmpty
                    ? const Center(child: Text('Keine Fotos in der Nähe'))
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
                                errorBuilder: (_, __, ___) =>
                                    AppConfig.allowDemoContent
                                    ? _demoTile(p.title)
                                    : const Center(
                                        child: Text('Bild nicht verfügbar'),
                                      ),
                              ),
                            );
                          }
                          return AppConfig.allowDemoContent
                              ? _demoTile(p.title)
                              : const Center(child: Text('Keine Live-Fotos'));
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
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Mapillary öffnen'),
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
          colors: [Color(0xFF4A7C59), Color(0xFF2D4A35)],
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
              color: Color(0xFFE8F0E9),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            (_result?.usingDemo == true)
                ? 'Beispiel — Mapillary nicht verfügbar'
                : 'Vorschau',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE8F0E9).withValues(alpha: 0.85),
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
