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
import '../../data/import/gpx_import.dart';
import '../../data/routing/elevation_client.dart';
import '../../data/routing/geocode_client.dart';
import '../../data/routing/osm_routes_client.dart';
import '../../data/routing/osm_trail_network_client.dart';
import '../../data/routing/naehe_seeds.dart';
import '../../data/routing/public_tours_client.dart';
import '../../data/routing/route_collections.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/routing/duration_lens.dart';
import '../../domain/routing/heatmap.dart';
import '../../data/routing/heatmap_client.dart';
import '../../data/routing/routing_status_client.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/route_shape.dart';
import '../../domain/routing/trail_difficulty.dart';
import '../../domain/routing/trail_view.dart';
import '../../domain/saved_route.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../profile/profile_screen.dart';
import '../map/map_pin_image.dart';
import 'offline_maps_sheet.dart';

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
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.mtbEnduro,
    ],
    this.trackLngLat,
    this.sourceKind = 'other',
    this.isLoopHint,
    this.poiStopsCount = 0,
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

  bool get hasTrack => trackLngLat != null && trackLngLat!.length >= 2;

  bool get isCatalog => sourceKind == 'catalog';
  bool get isLiveOsm => sourceKind == 'osm';
  bool get isOutdooractive => sourceKind == 'outdooractive';
  bool get isSeed => sourceKind == 'seed';

  String get sourceLabel => switch (sourceKind) {
        'catalog' => 'Katalog',
        'osm' => 'OSM live',
        'outdooractive' => 'Outdooractive',
        'seed' => 'Region',
        _ => 'Tour',
      };
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

/// Menschliche Übersetzung der Untergrund-Tags (Multi-Sport).
String _surfaceDisplay(String raw) => switch (raw) {
      'trail/root' => 'Naturboden · Wurzeln',
      'flow/compact' => 'Flow · fest verdichtet',
      'asphalt/paved' => 'Asphalt · befestigt',
      'gravel/compacted' => 'Schotter · verdichtet',
      'mixed/urban' => 'Stadt · gemischt',
      _ => raw,
    };

/// Kurzform für Filter-Chips (Multi-Sport).
String _chipSurfaceLabel(String raw) => switch (raw) {
      'trail/root' => 'Naturboden',
      'flow/compact' => 'Flow',
      'asphalt/paved' => 'Asphalt',
      'gravel/compacted' => 'Schotter',
      'mixed/urban' => 'Stadt',
      _ => raw.split('/').first,
    };

/// Leitet Untergrund aus Text/Typ ab (OA/OSM oft ohne surface-Feld).
String _inferSurfaceTag({
  required String title,
  String? type,
  String? difficulty,
  RoutingProfile? profile,
}) {
  final blob =
      '${title.toLowerCase()} ${type?.toLowerCase() ?? ''} ${difficulty?.toLowerCase() ?? ''}';
  if (blob.contains('city') ||
      blob.contains('urban') ||
      blob.contains('stadt') ||
      blob.contains('pendel') ||
      blob.contains('alltag')) {
    return 'mixed/urban';
  }
  if (blob.contains('road') ||
      blob.contains('rennrad') ||
      blob.contains('asphalt') ||
      blob.contains('race') ||
      blob.contains('radweg')) {
    return 'asphalt/paved';
  }
  if (blob.contains('gravel') ||
      blob.contains('schotter') ||
      blob.contains('forst') ||
      blob.contains('unpaved')) {
    return 'gravel/compacted';
  }
  if (blob.contains('mtb') ||
      blob.contains('trail') ||
      blob.contains('enduro') ||
      blob.contains('single') ||
      blob.contains('s2') ||
      blob.contains('s3') ||
      blob.contains('schwer')) {
    return 'trail/root';
  }
  // Fallback nach aktivem Routing-Profil
  return switch (profile) {
    RoutingProfile.road => 'asphalt/paved',
    RoutingProfile.urban => 'mixed/urban',
    RoutingProfile.gravel || RoutingProfile.ebikeTour => 'gravel/compacted',
    RoutingProfile.mtbTrail ||
    RoutingProfile.mtbEnduro ||
    RoutingProfile.emtb =>
      'trail/root',
    _ => 'flow/compact',
  };
}

/// Weicher Surface-Filter: Tour-Tags vs. Nutzer-Chip (nicht nur exakter Match).
bool _surfaceMatchesFilter(String tourSurface, String filter) {
  if (tourSurface == filter) return true;
  // Verwandte Gruppen
  const groups = <String, Set<String>>{
    'asphalt/paved': {'asphalt/paved', 'mixed/urban'},
    'mixed/urban': {'mixed/urban', 'asphalt/paved'},
    'gravel/compacted': {'gravel/compacted', 'flow/compact'},
    'flow/compact': {'flow/compact', 'gravel/compacted', 'trail/root'},
    'trail/root': {'trail/root', 'flow/compact'},
  };
  return groups[filter]?.contains(tourSurface) ?? false;
}

/// Touren-Schwierigkeit / Beanspruchung (nicht nur MTB-S-Skala-Wording).
String _chipScaleLabel(String code) => switch (code) {
      'S0' => 'Leicht',
      'S1' => 'Mittel',
      'S2+' => 'Anspruchsvoll',
      _ => code,
    };

/// Eine Zeile für Trail-Fakten: Farbpunkt + Schwierigkeit fett, weitere
/// Angaben (Untergrund, Rundkurs/Strecke, Höhenmeter, …) gedämpft dahinter.
/// Eine Komponente für Tourenkarte und Detailansicht statt zweier Kopien mit
/// eigenem Rohtext.
class _DifficultyStatsRow extends StatelessWidget {
  const _DifficultyStatsRow({
    required this.difficultyRaw,
    this.segments = const [],
    this.fontSize = 12,
  });

  final String difficultyRaw;
  final List<String> segments;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DifficultyDot(raw: difficultyRaw),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _difficultyDisplay(difficultyRaw),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                  ),
                ),
                for (final s in segments)
                  TextSpan(
                    text: '  ·  $s',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: fontSize,
                    ),
                  ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
/// die Karte bleibt in allen drei Zuständen sichtbar und bedienbar, deshalb
/// ein persistentes Panel statt `showModalBottomSheet` oder ein zweiter
/// `Scaffold`. `detail` trug vorher gar keinen Surface-Wert: das Antippen
/// einer Tour ersetzte über `_detailId` den kompletten Bildschirminhalt
/// (eigener `Scaffold` mit `AppBar`) und riss die Karte komplett weg — der
/// einzige verbliebene „Modus-Sprung" nach dem Umbau auf Discover/Planen.
enum _Surface { discover, plan, detail }

enum _PickMode { none, start, end, via }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _pinImagesReady = false;
  int _drawGen = 0;
  Symbol? _startSymbol;
  Symbol? _endSymbol;
  Symbol? _ideaSymbol;
  LatLng? _ideaPin;
  List<Symbol> _tfSymbols = [];
  List<Symbol> _tourSymbols = [];
  final Map<String, _TfPin> _tfBySymbolId = {};

  _Surface _surface = _Surface.discover;
  RoutingProfile _profile = RoutingProfile.mtbTrail;
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

  List<_RouteSuggestion> _tours = <_RouteSuggestion>[];
  List<OsmTrailSegment> _trailNetwork = [];
  bool _showTrailNetwork = true;
  String? _selectedTrailId;
  String? _trailNetworkStatus;
  TrailDifficulty? _trailScaleFilter;

  /// Filtert die Tourenliste auf Nähe zum Zeitbudget [_minutes].
  /// Default an: ~60-Min-Lens mit Band 45–75 (D-60-01).
  bool _matchTourDuration = true;
  String? _surfaceFilter;
  String? _scaleFilter; // S0 / S1 / S2+
  bool? _loopOnly;
  int? _minElevationM;
  bool _heatmapConsent = false;
  bool _heatmapContributed = false;

  /// Bundled Nähe-Seeds (Berlin) — Fallback ohne GPS / leeres OA·OSM.
  NaeheSeedsBundle? _seedsBundle;
  String? _seedsStatus;

  /// Community-Aggregat vom Backend (bereits k≥5-gefiltert, anonym) — zeigt
  /// als Vertrauenssignal an Tourenkarten, ohne dass der Nutzer selbst
  /// Consent für den eigenen Beitrag geben muss (Lesen ≠ Beitragen).
  HeatmapResult? _communityHeatmap;
  String? _elevationSummary;
  List<double> _elevationSamples = const [];
  double? _elevationGainM;
  String? _oaStatus;
  List<_TfPin> _tfPins = [];
  String? _heatmapNote;
  String? _routingStatusNote;
  String _mapStyle = AppConfig.mapStyleUrl;
  final _geocode = GeocodeClient();
  final _startAddrCtrl = TextEditingController();
  final _startAddrFocus = FocusNode();
  final _endAddrCtrl = TextEditingController();
  List<GeocodeHit> _addrHits = const [];
  bool _addrBusy = false;
  String? _addrTarget; // 'start' | 'end'
  Timer? _addrDebounce;
  int _quickGen = 0;
  String? _selectedTourId;

  /// Nur Karten-Übersicht DACH+FR bis GPS da ist — nie Tour-Origin.
  static const _regionOverview = GeoPoint(47.2, 6.5);
  /// Multi-Sport Oberflächen — MTB, Gravel, Road, City.
  static const _surfaceTags = [
    'asphalt/paved',
    'gravel/compacted',
    'flow/compact',
    'trail/root',
    'mixed/urban',
  ];

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
    unawaited(_fetchCommunityHeatmap());
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
      final sportCat = active?.category ??
          ref.read(userProfileStoreProvider).preferredSport;
      if (active != null) {
        setState(() {
          _profile = routingProfileForBike(active.category);
          // Sport-aware Dauer-Default (Touring → 2–3 h, sonst ~60).
          _minutes = DurationLens.defaultMinutesForSport(sportCat);
          _matchTourDuration = _minutes > 0;
        });
      } else {
        final preferred =
            ref.read(userProfileStoreProvider).preferredSport;
        if (preferred != null) {
          setState(() {
            _profile = routingProfileForBike(preferred);
            _minutes = DurationLens.defaultMinutesForSport(preferred);
            _matchTourDuration = _minutes > 0;
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
        });
      }
      final pendingLoop = ref.read(discoverPendingLoopIdProvider);
      if (pendingLoop != null) {
        ref.read(discoverPendingLoopIdProvider.notifier).state = null;
        setState(() => _selectedTourId = pendingLoop);
      }
      final launch = ref.read(discoverLaunchModeProvider);
      if (launch != null) {
        ref.read(discoverLaunchModeProvider.notifier).state = null;
        // quick/tours sind keine eigenen Ziele mehr — beides ist Discover.
        // Nur „plan" öffnet direkt das Planen-Panel.
        if (launch == DiscoverLaunchMode.plan) {
          setState(() => _surface = _Surface.plan);
        }
      }
      if (_quick.isEmpty) {
        unawaited(_refreshQuick(limit: 3));
      }
    });
  }

  @override
  void dispose() {
    _addrDebounce?.cancel();
    _startAddrCtrl.dispose();
    _startAddrFocus.dispose();
    _endAddrCtrl.dispose();
    super.dispose();
  }

  /// Planen öffnen — die eine Stelle, an der Discover in den Plan-Zustand
  /// wechselt. Kein Tab-Wechsel: das Panel fährt über die Karte, die Karte
  /// behält ihren Ausschnitt und bleibt bedienbar.
  void _openPlan({String? status, _PickMode pick = _PickMode.none}) {
    setState(() {
      _surface = _Surface.plan;
      // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
      // Tour, die gar nicht mehr gemeint war.
      _detailId = null;
      _pick = pick;
      _addrHits = const [];
      _error = null;
      if (status != null) {
        _status = status;
      } else {
        _status ??= 'Adresse suchen oder auf die Karte tippen';
      }
    });
  }

  /// Zurück nach Discover. Die berechnete Route bleibt sichtbar — der Nutzer
  /// soll sein Ergebnis auf der Karte behalten, nicht bei jedem „Zurück"
  /// von vorn anfangen.
  void _closePlan() {
    setState(() {
      _surface = _Surface.discover;
      _pick = _PickMode.none;
      _addrHits = const [];
    });
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
    await _drawAll();
    if (!mounted) return;
    try {
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(center, 12.5));
    } catch (_) {}
  }

  /// Zurück aus dem Detail nach Discover. `_selectedTourId` bleibt bewusst
  /// gesetzt — die Tour soll in Liste und Karte hervorgehoben bleiben,
  /// nicht beim Schließen des Panels wieder verschwinden.
  void _closeDetail() {
    setState(() {
      _detailId = null;
      _surface = _Surface.discover;
    });
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
      final hits = await _geocode.search(
        q,
        biasLat: o.lat,
        biasLng: o.lng,
      );
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
        _status =
            friendlyErrorMessage(e, context: 'Adresssuche fehlgeschlagen');
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
          _surface = _Surface.plan;
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
          await map.animateCamera(
            CameraUpdate.newLatLngZoom(tour.center, 12),
          );
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
        _surface = _Surface.plan;
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
    final s = await fetchRoutingStatus();
    if (!mounted || s == null) return;
    setState(() => _routingStatusNote = s.bannerText);
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
    unawaited(_fetchCommunityHeatmap());
  }

  /// Community-Heatmap um den Origin — liefert das Vertrauenssignal für
  /// „beliebt bei anderen Ride-Nutzern" auf den Tourenkarten. Nur ein
  /// GET auf bereits anonymisierte Serverdaten (k≥5), kein neuer Endpunkt
  /// nötig — `fetchCommunityHeatmap()`/`/api/heatmap` existierten schon,
  /// wurden aber nirgends aufgerufen.
  Future<void> _fetchCommunityHeatmap() async {
    if (!_hasRealOrigin) return;
    final o = _origin;
    const deltaDeg = 0.08; // ~8 km, wie beim OSM-Trailnetz-Radius.
    try {
      final result = await fetchCommunityHeatmap(
        west: o.lng - deltaDeg,
        south: o.lat - deltaDeg,
        east: o.lng + deltaDeg,
        north: o.lat + deltaDeg,
      );
      if (!mounted || result == null) return;
      setState(() => _communityHeatmap = result);
    } catch (_) {
      // Vertrauenssignal ist optional — Discover bleibt ohne es nutzbar.
    }
  }

  /// Höchste Fahrerzahl eines Community-Segments nahe [center], oder null,
  /// wenn keins in ~800 m Reichweite liegt. Serverseitig schon k≥5-gefiltert
  /// — eine Zahl hier ist also nie eine Einzelperson.
  int? _nearbyActivity(LatLng center) {
    final segs = _communityHeatmap?.visibleSegments;
    if (segs == null || segs.isEmpty) return null;
    int? best;
    for (final s in segs) {
      if (s.coordinatesLngLat.isEmpty) continue;
      final p = s.coordinatesLngLat.first;
      final dKm = _distKm(center.latitude, center.longitude, p[1], p[0]);
      if (dKm > 0.8) continue;
      if (best == null || s.uniqueUsers > best) best = s.uniqueUsers;
    }
    return best;
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
                  '${trail.difficultyLabel} · ${trail.lengthKm.toStringAsFixed(1)} km'
                  '${trail.surface != null ? ' · ${trail.surface}' : ''}'
                  '${trail.highway != null ? ' · ${trail.highway}' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'OSM-Live-Pfad — Tippen auf der Karte wählt Trails. '
                  'Anfahrt zum Einstieg, dann als Overlay speichern oder fahren.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
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
    final trailPts = [
      for (final p in oriented.geometry) GeoPoint(p[1], p[0]),
    ];
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
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/trailforks')
          .replace(queryParameters: {
        'hint': 'dry_likely',
        'lat': '${o.lat}',
        'lon': '${o.lng}',
      });
      final res = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 8));
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
          .replace(queryParameters: {
        'type': 'tour',
        'lat': '${o.lat}',
        'lon': '${o.lng}',
      });
      final res = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 12));
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
        parsed.add(
          _RouteSuggestion(
            id: id.startsWith('oa-') ? id : 'oa-$id',
            name: title,
            distanceKm: (m['lengthKm'] as num?)?.toDouble() ?? 20,
            elevationM: (m['elevationM'] as num?)?.round() ?? 0,
            durationMin: durationMin,
            mtbScale: difficulty,
            surface: surface,
            matchScore: track != null ? 88 : 80,
            reasons: [
              if (m['summary'] is String) m['summary'] as String,
              if (track != null)
                'Outdooractive mit Track-Polyline'
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
            trackLngLat: track,
            sourceKind: 'outdooractive',
          ),
        );
      }
      if (!mounted) return;
      if (parsed.isEmpty) {
        setState(() {
          _oaStatus = (data['warning'] as String?) ??
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
              for (final p in s.poiStops.take(3))
                '· ${p.atMin} Min  ${p.title}',
              'Offline-Fallback · ${bundle.labelWithoutLocation}',
            ],
            center: LatLng(s.centerLat, s.centerLng),
            categories: s.categories,
            trackLngLat: s.trackLngLat,
            sourceKind: 'seed',
            isLoopHint: s.isLoop,
            poiStopsCount: s.poiStops.length,
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
      await _drawAll();
    } catch (e) {
      if (mounted) {
        setState(() => _seedsStatus = 'Seeds offline');
      }
      debugPrint('NaeheSeeds: $e');
    }
  }

  /// Redaktioneller Katalog vom Backend — füllt Touren auch ohne GPS.
  Future<void> _fetchPublicCatalog() async {
    try {
      final sport = catalogSportForProfile(_profile.apiId);
      final hits = await PublicToursClient().fetchCatalog(sport: sport);
      if (!mounted || hits.isEmpty) return;
      final o = _originOrNull;
      final parsed = <_RouteSuggestion>[];
      for (final h in hits) {
        final surface = h.surface.contains('/')
            ? h.surface
            : _inferSurfaceTag(
                title: h.name,
                difficulty: h.difficulty,
                profile: _profile,
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
          ),
        );
      }
      if (o != null) {
        parsed.sort((a, b) {
          final da =
              _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude);
          final db =
              _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude);
          return da.compareTo(db);
        });
      }
      if (!mounted) return;
      setState(() {
        final byId = <String, _RouteSuggestion>{
          for (final t in _tours) t.id: t,
        };
        for (final p in parsed) {
          final existing = byId[p.id];
          // Katalog ergänzt; OSM/OA mit höherem Score behalten.
          if (existing == null || existing.matchScore <= p.matchScore) {
            byId[p.id] = p;
          }
        }
        _tours = byId.values.toList();
        final base = _oaStatus;
        _oaStatus = base == null || base.isEmpty
            ? 'Katalog ${parsed.length} Touren'
            : '$base · Katalog ${parsed.length}';
      });
      await _drawAll();
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
        radiusKm: 20,
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
            elevationM: 0,
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
        _elevationSamples = const [];
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
        _elevationSamples = const [];
      });
      return;
    }
    final samples = <double>[];
    for (final p in profile.points) {
      final e = p['elevation'] ?? p['elev'] ?? p['ele'] ?? p['z'];
      if (e is num) samples.add(e.toDouble());
    }
    setState(() {
      _elevationGainM = profile.gainM;
      _elevationSummary =
          '+${profile.gainM.round()} / −${profile.lossM.round()} hm'
          '${profile.source != null ? ' · ${profile.source}' : ''}';
      _elevationSamples = samples;
    });
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
    final pin = _tfBySymbolId[symbol.id];
    if (pin == null) return;
    try {
      await launchUrl(
        Uri.parse(pin.openUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pin.name)),
        );
      }
    }
  }

  Future<void> _locate() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(
              () => _status = 'Ortungsdienst aus — Start tippen oder Adresse');
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
              () => _status = 'Standort-Berechtigung fehlt — Adresse nutzen');
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
          setState(() =>
              _status = 'Kein GPS-Fix — Karte tippen oder Adresse suchen');
        }
        return;
      }
      if (!mounted) return;
      final p = GeoPoint(pos.latitude, pos.longitude);
      setState(() {
        _userPos = p;
        _start = p;
        _startAddrCtrl.text = 'Meine Position';
        _status = 'Standort bereit · In der Nähe wird geladen…';
      });
      unawaited(_fetchOutdooractive());
      unawaited(_fetchOsmRoutes());
      unawaited(_fetchTrailNetwork());
      unawaited(_fetchTrailforks());
      unawaited(_fetchPublicCatalog());
      unawaited(_fetchCommunityHeatmap());
      // Explizit Near-me nach frischem GPS — Drift-Sync kann verzögern.
      unawaited(_refreshQuick(limit: 3));
      try {
        await _map?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 12.5),
        );
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(
            () => _status = 'Position nicht verfügbar — Adresse oder Tippen');
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
                CameraUpdate.newLatLngZoom(LatLng(o.lat, o.lng), 12)) ??
            Future.value(),
      );
      if (!_loading) {
        unawaited(_refreshQuick(limit: 3));
      }
    });
  }

  GeoPoint get _mapCenter => _originOrNull ?? _regionOverview;

  /// Höhe des unteren Panels aus dem letzten Build. Die Karte liegt jetzt
  /// full-bleed darunter, deshalb braucht das Einpassen der Route (siehe
  /// [_drawAll]) diesen Rand — sonst verschwindet sie hinter dem Panel.
  double _panelInset = 300;

  /// Los-Leiste: sichtbar, sobald eine Route auf der Karte liegt — egal ob
  /// aus Discover oder Planen. Vorher hing das an Label-Strings wie „(Plan)",
  /// was für Nutzer:innen nicht nachvollziehbar war (mal da, mal nicht).
  /// Die Leiste gehört zur gezeichneten Route, nicht zum Zustand.
  bool get _showRideBar => _computed != null;

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
          !_surfaceMatchesFilter(r.surface, _surfaceFilter!)) {
        return false;
      }
      if (_scaleFilter != null) {
        final scale = r.mtbScale.toUpperCase();
        if (_scaleFilter == 'S0' && !scale.contains('S0')) return false;
        if (_scaleFilter == 'S1' &&
            !scale.contains('S1') &&
            !scale.contains('S0')) {
          return false;
        }
        if (_scaleFilter == 'S2+' &&
            !(scale.contains('S2') ||
                scale.contains('S3') ||
                scale.contains('S4'))) {
          return false;
        }
      }
      if (_minElevationM != null && r.elevationM < _minElevationM!) {
        return false;
      }
      // „Nur Rundkurse": echte Geometrie ODER ehrlicher Seed/Katalog-Hint.
      // A→B-Geometrie nie als Rundkurs durchlassen (D-60-02).
      if (_loopOnly == true && !_isLoop(r)) {
        return false;
      }
      // Seed proximity ≥35 km (Wiesloch→HD/MA). Never use a tiny radius.
      if (r.isSeed && _hasRealOrigin) {
        final o = _origin;
        final d = _distKm(
          o.lat,
          o.lng,
          r.center.latitude,
          r.center.longitude,
        );
        if (d > 35) return false;
      }
      return true;
    }).toList();

    if (cat == null) {
      final sorted = List<_RouteSuggestion>.from(base);
      sorted.sort(_byDistanceThenDurationFit);
      return sorted;
    }
    // Nähe zuerst, innerhalb davon Kategorie-Treffer nach vorn.
    final matched = <_RouteSuggestion>[];
    final rest = <_RouteSuggestion>[];
    for (final r in base) {
      if (r.categories.contains(cat)) {
        matched.add(r);
      } else {
        rest.add(r);
      }
    }
    matched.sort(_byDistanceThenDurationFit);
    rest.sort(_byDistanceThenDurationFit);
    if (matched.isEmpty) {
      final sorted = List<_RouteSuggestion>.from(base);
      sorted.sort(_byDistanceThenDurationFit);
      return sorted;
    }
    return [...matched, ...rest];
  }

  int _byDistanceThenDurationFit(_RouteSuggestion a, _RouteSuggestion b) {
    final o = _origin;
    final da = _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude);
    final db = _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude);
    final c = da.compareTo(db);
    if (c != 0) return c;
    // Dann Duration-Fit (Spec: Distanz → Duration-Band).
    if (_minutes > 0) {
      final fit = DurationLens.fitDelta(a.durationMin, _minutes)
          .compareTo(DurationLens.fitDelta(b.durationMin, _minutes));
      if (fit != 0) return fit;
    }
    // Loops leicht bevorzugen (Primary Lens = Rundkurse).
    final la = _isLoop(a) ? 0 : 1;
    final lb = _isLoop(b) ? 0 : 1;
    final lc = la.compareTo(lb);
    if (lc != 0) return lc;
    return b.matchScore.compareTo(a.matchScore);
  }

  /// Ehrlich: Geometrie schlägt Hint. Seed `is_loop` nur ohne P2P-Track.
  bool _isLoop(_RouteSuggestion r) {
    final shape = routeShapeOf(r.trackLngLat);
    if (shape == RouteShape.loop) return true;
    if (shape == RouteShape.pointToPoint) return false;
    return r.isLoopHint == true;
  }

  /// Rundkurs / Strecke — ⟲ nur bei echten Loops (D-60-02).
  String? _shapeLabel(_RouteSuggestion r) {
    if (_isLoop(r)) return '⟲ Rundkurs';
    final shape = routeShapeOf(r.trackLngLat);
    if (shape == RouteShape.pointToPoint) return 'Strecke';
    return null;
  }

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
    final gen = ++_quickGen;
    // Darf das Ergebnis die Karte übernehmen? Nur wenn dort nichts liegt, das
    // die Nutzerin selbst gewählt hat. Seit Discover der Dauerzustand ist,
    // läuft dieser Refresh bei jedem GPS-Drift > 300 m ([_syncOriginDrift]) —
    // ohne diese Sperre würde eine ausgewählte Tour beim Herumlaufen einfach
    // durch einen Schnell-Vorschlag ersetzt.
    final previousQuickLabels = {for (final q in _quick) q.label};
    final takeOverMap = _computed == null ||
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
    final labels = [
      'Richtung Norden',
      'Richtung Osten',
      'Richtung Südwest',
    ];
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
        var result = await _routes.planRoute(
          from: origin,
          to: dests[i],
          profile: _profile,
        );
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
      setState(() => _error = 'Start und Ziel setzen');
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
            () => _error = friendlyErrorMessage(e, context: 'Route berechnen'));
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
        _surface = _Surface.discover;
      });
      await _drawAll();
      await _refreshElevation(merged);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = friendlyErrorMessage(e, context: 'Route berechnen'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Live-Rundtour um [center]. Ohne Engine: leere Punkte (= nur Pin, kein Fake-Track).
  Future<({List<GeoPoint> points, bool demo})> _routedTourGeometry(
    LatLng center,
    double distanceKm,
  ) async {
    final half = 0.008 + (distanceKm / 200).clamp(0.0, 0.04) * 0.5;
    final waypoints = [
      GeoPoint(center.latitude, center.longitude),
      GeoPoint(center.latitude + half, center.longitude + half * 0.4),
      GeoPoint(center.latitude + half * 0.2, center.longitude - half),
      GeoPoint(center.latitude - half * 0.8, center.longitude - half * 0.3),
      GeoPoint(center.latitude, center.longitude),
    ];
    final coords = <GeoPoint>[];
    try {
      for (var i = 0; i < waypoints.length - 1; i++) {
        final leg = await _routes.planRoute(
          from: waypoints[i],
          to: waypoints[i + 1],
          profile: _profile,
        );
        if (leg.coordinates.isEmpty) continue;
        if (coords.isEmpty) {
          coords.addAll(leg.coordinates);
        } else {
          coords.addAll(leg.coordinates.skip(1));
        }
      }
    } catch (_) {
      // Caller zeigt Pin-only Status.
    }
    if (coords.length >= 4) {
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
    if (tour.hasTrack) {
      return (
        points: [
          for (final c in tour.trackLngLat!) GeoPoint(c[1], c[0]),
        ],
        demo: false,
      );
    }
    return _routedTourGeometry(tour.center, tour.distanceKm);
  }

  bool _isPinOnlyIdea(_RouteSuggestion r) {
    if (r.hasTrack) return false;
    return r.id.startsWith('idea-') ||
        r.id.startsWith('oa-') ||
        r.id.contains('demo');
  }

  /// Komoot-ähnliche Route: dunkles Casing + helle Hauptlinie (nur aktiv).
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
          lineColor: '#14241C',
          lineWidth: 12,
          lineOpacity: 0.92,
          lineJoin: 'round',
        ),
        data, // same data so tap on casing still selects trail/route
      );
    }
    await c.addLine(
      LineOptions(
        geometry: geometry,
        lineColor: lineColor,
        lineWidth: active ? 5.5 : 3.0,
        lineOpacity: active ? 1.0 : 0.55,
        lineJoin: 'round',
      ),
      data,
    );
  }

  /// Ziel-Vorschlag ~¼ der Ideendistanz NE vom Pin (A→B, editierbar).
  GeoPoint _suggestedEndNear(LatLng center, double distanceKm) {
    final legKm = (distanceKm * 0.25).clamp(3.0, 12.0);
    final dLat = legKm / 111.0;
    final cosLat =
        math.cos(center.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
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
          // Verlässt Detail (falls offen), sonst zeigt „Zurück" später eine
          // Tour, die gar nicht mehr gemeint war.
          _detailId = null;
          _pick = _PickMode.end;
        });
      }
    }
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
          final rides =
              await ref.read(rideRepositoryProvider).listRides(limit: 40);
          final zones =
              await ref.read(garageRepositoryProvider).listPrivacyZones();
          final heat = buildHeatmapFromRides(
            consentHeatmap: true,
            rides: [
              for (final r in rides) (id: r.id, track: r.track),
            ],
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
      if (_showTrailNetwork) {
        for (final trail in _visibleTrailNetwork.take(60)) {
          if (gen != _drawGen) return;
          final geom = [
            for (final p in trail.geometry) LatLng(p[1], p[0]),
          ];
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
                lineWidth: 2.4,
                lineOpacity: 0.42,
                lineJoin: 'round',
              ),
              {'kind': 'trail', 'id': trail.id},
            );
          }
        }
      }
      // Nur ausgewählte Tour + max. 2 nahe Tracks — nicht alle OSM-Relationen.
      final trackTours = _tours.where((t) => t.hasTrack).toList();
      final selected = trackTours.where((t) => t.id == _selectedTourId);
      final others = trackTours.where((t) => t.id != _selectedTourId).take(2);
      for (final tour in [...selected, ...others]) {
        if (gen != _drawGen) return;
        final geom = [
          for (final p in tour.trackLngLat!) LatLng(p[1], p[0]),
        ];
        final isSelected = tour.id == _selectedTourId;
        await _addKomootLine(
          c,
          geom,
          active: isSelected,
          casing: isSelected,
          lineColor: isSelected ? '#00C853' : '#66BB6A',
          data: {'kind': 'tour', 'id': tour.id},
        );
      }
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
        final line =
            _computed!.coordinates.map((p) => LatLng(p.lat, p.lng)).toList();
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
      if (gen != _drawGen) return;
      await _syncMarkers();
    } catch (_) {}
  }

  Future<void> _drawRoute(RouteResult result) async {
    setState(() => _computed = result);
    await _drawAll();
    await _refreshElevation(result);
  }

  Future<void> _ensurePinImages(MapLibreMapController c) async {
    if (_pinImagesReady) return;
    try {
      final green = await buildMapPinPng(fill: const Color(0xFF00C853));
      final orange = await buildMapPinPng(fill: const Color(0xFFFF6B35));
      final blue = await buildMapPinPng(fill: const Color(0xFF29B6F6));
      await c.addImage('aether-pin', green);
      await c.addImage('aether-pin-b', orange);
      await c.addImage('aether-pin-idea', blue);
      _pinImagesReady = true;
    } catch (_) {
      // Style without custom images — text-only symbols still work.
    }
  }

  Future<void> _syncMarkers() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    try {
      await _ensurePinImages(c);
      if (_startSymbol != null) await c.removeSymbol(_startSymbol!);
      if (_endSymbol != null) await c.removeSymbol(_endSymbol!);
      if (_ideaSymbol != null) await c.removeSymbol(_ideaSymbol!);
      _startSymbol = null;
      _endSymbol = null;
      _ideaSymbol = null;
      for (final s in _tfSymbols) {
        await c.removeSymbol(s);
      }
      _tfSymbols = [];
      _tfBySymbolId.clear();
      for (final s in _tourSymbols) {
        await c.removeSymbol(s);
      }
      _tourSymbols = [];
      const pin = 'aether-pin';
      if (_ideaPin != null) {
        _ideaSymbol = await c.addSymbol(
          SymbolOptions(
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
        _startSymbol = await c.addSymbol(
          SymbolOptions(
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
        _endSymbol = await c.addSymbol(
          SymbolOptions(
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
      // Tour-Pins ohne volle Polyline (Rest der OSM-Liste).
      final drawnIds = {
        if (_selectedTourId != null) _selectedTourId!,
        ..._tours.where((t) => t.hasTrack).take(3).map((t) => t.id),
      };
      for (final tour in _filtered.take(16)) {
        if (drawnIds.contains(tour.id) && tour.hasTrack) continue;
        final sym = await c.addSymbol(
          SymbolOptions(
            geometry: tour.center,
            iconImage: _pinImagesReady ? pin : null,
            iconSize: 0.9,
            textField: 'T',
            textSize: 11,
            textOffset: const Offset(0, 1.15),
          ),
        );
        _tourSymbols.add(sym);
      }
    } catch (_) {}
  }

  Future<void> _startRide({_RouteSuggestion? suggestion}) async {
    if (suggestion != null) {
      final routed = await _geometryForTour(suggestion);
      if (!mounted) return;
      if (routed.demo || routed.points.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kein Live-Track — Route berechnen öffnet Planen mit Ziel-Vorschlag.',
            ),
          ),
        );
        await _computeIdeaRoute(suggestion);
        return;
      }
      final coords = routed.points.map((p) => [p.lng, p.lat]).toList();
      final navSteps = navStepsFromPolyline(
        routed.points.map((p) => (lat: p.lat, lng: p.lng)).toList(),
      );
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: suggestion.id,
        name: suggestion.name,
        distanceKm: suggestion.distanceKm,
        elevationM: suggestion.elevationM.toDouble(),
        durationMin: suggestion.durationMin,
        mtbScale: suggestion.mtbScale,
        coordinates: coords,
        steps: [
          for (final st in navSteps)
            NavStep(
              id: st.id,
              instruction: st.instruction,
              distanceAlongM: st.distanceAlongM,
            ),
        ],
      );
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
    ref.read(activeRouteProvider.notifier).state = ActiveRoute(
      id: 'engine-${DateTime.now().millisecondsSinceEpoch}',
      name: _label ?? 'Berechnete Route',
      distanceKm: engine.distanceM / 1000,
      elevationM: elevM,
      durationMin: (engine.durationS / 60).round(),
      mtbScale: null,
      coordinates: engine.coordinates.map((p) => [p.lng, p.lat]).toList(),
      steps: engine.steps
          .map(
            (st) => NavStep(
              id: st.id,
              instruction: st.instruction,
              distanceAlongM: st.distanceAlongM,
            ),
          )
          .toList(),
    );
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
      final name =
          f.name.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
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
            '„${f.name}“ konnte nicht gelesen werden — beschädigt oder kein gültiges GPX.')) {
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
          'GPX ungültig oder zu wenige Punkte — andere Datei wählen?')) {
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
                          '${c.routeIds.length} Routen · tippen zum Öffnen'),
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
                              content: Text('Zur Sammlung hinzugefügt')),
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
    if (coords.length < 2) return;
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
      // Gespeicherte Route landet in Discover — sichtbar auf der Karte, mit
      // „Los"-Leiste. Wer sie ändern will, öffnet Planen bewusst.
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

  @override
  Widget build(BuildContext context) {
    _syncOriginDrift();
    final style = _mapStyle;

    final size = MediaQuery.sizeOf(context);
    // `size` bleibt bei geöffneter Tastatur unverändert — nur `viewInsets`
    // wächst. Planen hat zwei Adressfelder; ohne diesen Abzug rechnet die
    // Panel-Höhe unten so, als wäre der ganze Screen frei, und die Tastatur
    // frisst den Platz dann von der Kartenseite statt vom Panel.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Panel-Höhe relativ zum Screen: die Karte behält auf kleinen Geräten
    // Luft, die Liste bleibt auf großen nutzbar. Detail braucht am meisten
    // Platz (Statistik + Höhenprofil + bis zu vier Aktionen).
    final desiredPanelHeight = switch (_surface) {
      _Surface.plan => size.height * (_ideaPin != null ? 0.54 : 0.48),
      _Surface.detail => size.height * 0.62,
      _Surface.discover => size.height * 0.44,
    };
    // Obere Grenze weicht der Tastatur statt des Kartenrests — die untere
    // Grenze bleibt 220, außer die Tastatur lässt selbst dafür keinen Platz
    // mehr (sehr kleines Gerät + Tastatur): dann gewinnt der verfügbare
    // Raum, damit `clamp` nicht mit min > max abstürzt.
    final maxPanelHeight = math.max(
      220.0,
      math.min(560.0, size.height - keyboardInset - _minMapPeekHeight),
    );
    final panelHeight = desiredPanelHeight.clamp(220.0, maxPanelHeight);
    _panelInset = panelHeight;

    return Scaffold(
      body: Stack(
        children: [
          // Karte füllt den Screen. Discover ist Karte + Liste — nicht
          // Kopfzeile, Kartenfenster und Schubfach übereinander.
          Positioned.fill(child: _buildMap(style)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingHeader(),
          ),
          // FAB und Los-Leiste stapeln in EINER bodenverankerten Spalte.
          // Getrennt positioniert bräuchte der FAB die Höhe der Leiste als
          // Konstante — die aber wächst, sobald der Routenname zweizeilig
          // umbricht, und beide würden sich überlappen.
          Positioned(
            left: AppSpacing.m,
            right: AppSpacing.m,
            bottom: panelHeight + AppSpacing.s,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // „Route bauen" ist der sichtbare Einstieg ins Planen —
                // statt eines Tabs, den man vor der Nutzung wählen muss.
                if (_surface == _Surface.discover)
                  FloatingActionButton.extended(
                    heroTag: 'discover-plan',
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    onPressed: () => _openPlan(
                      status: _start == null
                          ? 'Start wählen: Adresse, „Hier" oder Karte lange drücken'
                          : 'Ziel wählen: Adresse oder Karte lange drücken',
                      pick: _start == null ? _PickMode.start : _PickMode.end,
                    ),
                    icon: const Icon(Icons.route),
                    label: const Text('Route bauen'),
                  ),
                // Nicht über dem Detail-Panel — das hat mit
                // „Losfahren"/„Route berechnen" bereits eine eigene,
                // tourspezifische Haupt-Aktion; eine zweite Leiste
                // darüber wäre eine doppelte, uneindeutige CTA.
                if (_showRideBar && _surface != _Surface.detail) ...[
                  const SizedBox(height: AppSpacing.s),
                  _buildRideBar(),
                ],
              ],
            ),
          ),
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
        unawaited(_drawAll());
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
      // Langer Druck ist der dritte Einstieg ins Planen (neben „Route bauen"
      // und „Anpassen") — aber nur aus Discover heraus. Der Code kannte beim
      // Umbau auf Option B nur „plan" als Sonderfall und „alles andere" als
      // Discover; seit Detail eine dritte Surface ist, hätte ein
      // Aus-Versehen-lang-Drücken beim Lesen einer Tour sie stillschweigend
      // verworfen und eine neue Planen-Sitzung gestartet. Während Detail
      // bleibt die Karte deshalb wie bei einem kurzen Tipp unberührt.
      onMapLongClick: (point, latLng) async {
        if (_surface == _Surface.detail) return;
        final p = GeoPoint(latLng.latitude, latLng.longitude);
        final wasWithoutOrigin = !_hasRealOrigin;
        if (_surface == _Surface.plan) {
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

  Widget _buildFloatingHeader() {
    final onMap = Theme.of(context).scaffoldBackgroundColor;
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
            Material(
              color: onMap.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        MultiSportCopy.navDiscover,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Meine Position',
                      onPressed: _locate,
                      icon: const Icon(Icons.my_location, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: 'GPX importieren',
                      onPressed: _importGpxDialog,
                      icon: const Icon(Icons.upload_file, size: 20),
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
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'collections',
                          child: Text(MultiSportCopy.discoverMenuCollections),
                        ),
                        PopupMenuItem(
                          value: 'trailview',
                          // Nicht „Trail“-only — Mapillary für alle Oberflächen.
                          child: Text(MultiSportCopy.discoverMenuPhotos),
                        ),
                        PopupMenuItem(
                          value: 'offline',
                          child: Text(MultiSportCopy.discoverMenuOffline),
                        ),
                        PopupMenuItem(
                          value: 'privacy',
                          child: Text(MultiSportCopy.discoverMenuPrivacy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_surface == _Surface.discover) ...[
              const SizedBox(height: AppSpacing.xs),
              _sportProfileChips(),
            ],
            if (_routingStatusNote != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _mapNotePill(_routingStatusNote!),
            ],
          ],
        ),
      ),
    );
  }

  /// Sport-Profile als horizontale Chips — Default aus Bike/Profil.
  Widget _sportProfileChips() {
    // Kern-Disziplinen zuerst (Multi-Sport), Rest im Overflow via Profil-Chip.
    const primary = <RoutingProfile>[
      RoutingProfile.mtbTrail,
      RoutingProfile.gravel,
      RoutingProfile.road,
      RoutingProfile.urban,
      RoutingProfile.emtb,
      RoutingProfile.ebikeTour,
      RoutingProfile.mtbEnduro,
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: primary.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final p = primary[i];
          final selected = _profile == p;
          return FilterChip(
            label: Text(
              p.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            selectedColor: AppColors.accent.withValues(alpha: 0.28),
            backgroundColor: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.92),
            side: BorderSide(
              color: selected
                  ? AppColors.accent
                  : AppColors.forest.withValues(alpha: 0.25),
            ),
            onSelected: (_) {
              setState(() => _profile = p);
              if (_surface == _Surface.plan) {
                if (_start != null && _end != null) unawaited(_calcAb());
              } else {
                unawaited(_refreshQuick(limit: 3));
                unawaited(_fetchPublicCatalog());
              }
            },
          );
        },
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
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_label ?? 'Route'} · '
                '${(r.distanceM / 1000).toStringAsFixed(1)} km · '
                '${(r.durationS / 60).round()} min'
                '${_elevationSummary != null ? ' · $_elevationSummary' : ''}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Speichern',
              onPressed: _saveCurrent,
              icon: const Icon(
                Icons.bookmark_border,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (_surface == _Surface.discover)
              IconButton(
                tooltip: 'Route anpassen',
                onPressed: () => _openPlan(status: 'Route anpassen'),
                icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
            // Gleicher Text + gleiches Icon wie der „Losfahren"-Button auf
            // Home — ein Wort für „diese Route jetzt starten", überall.
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              ),
              onPressed: () => _startRide(),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Losfahren'),
            ),
          ],
        ),
      ),
    );
  }

  /// Unteres Panel — beherbergt alle drei Zustände. Der Wechsel ist eine
  /// Bewegung (Panels fahren von unten übereinander), kein Tab- oder
  /// Screen-Sprung wie vorher beim Tour-Detail.
  Widget _buildBottomPanel() {
    final child = switch (_surface) {
      _Surface.plan => KeyedSubtree(
          key: const ValueKey('panel-plan'),
          child: _buildPlanPanel(),
        ),
      _Surface.detail => KeyedSubtree(
          key: ValueKey('panel-detail-$_detailId'),
          child: _buildDetailPanel(),
        ),
      _Surface.discover => KeyedSubtree(
          key: const ValueKey('panel-discover'),
          child: _buildDiscoverPanel(),
        ),
    };
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
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
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
          child: child,
        ),
      ),
    );
  }

  Widget _panelHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _panelMessages() {
    if (_error == null && _status == null) return const SizedBox.shrink();
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
          if (_status != null)
            Text(
              _status!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// Zählt gesetzte Filter für das Badge am „Filter"-Knopf — sonst weiß
  /// niemand, warum die Liste kurz ist.
  int get _activeFilterCount {
    var n = 0;
    if (_matchTourDuration) n++;
    if (_surfaceFilter != null) n++;
    if (_scaleFilter != null) n++;
    if (_loopOnly == true) n++;
    if (_minElevationM != null) n++;
    if (_trailScaleFilter != null) n++;
    return n;
  }

  void _resetFilters() {
    setState(() {
      _matchTourDuration = false;
      _surfaceFilter = null;
      _scaleFilter = null;
      _loopOnly = null;
      _minElevationM = null;
      _trailScaleFilter = null;
    });
    unawaited(_drawAll());
  }

  /// Die zwölf Dauer-Chips aus der Kopfzeile leben jetzt hier — sichtbar nur,
  /// wenn man sie braucht. Das war der Hauptgrund für die überladene Leiste.
  Future<void> _openFilterSheet() async {
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

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  0,
                  AppSpacing.l,
                  AppSpacing.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _activeFilterCount == 0
                              ? null
                              : () {
                                  _resetFilters();
                                  setModal(() {});
                                },
                          child: const Text('Zurücksetzen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    group('Dauer-Lens', [
                      for (final p in DurationLens.presets)
                        FilterChip(
                          label: Text(p.label),
                          selected: _minutes == p.minutes &&
                              (p.minutes == 0
                                  ? !_matchTourDuration
                                  : _matchTourDuration),
                          onSelected: (_) => update(() {
                            _minutes = p.minutes;
                            _matchTourDuration = p.minutes > 0;
                          }),
                        ),
                      Tooltip(
                        message:
                            'Liste streng nach Dauer-Band filtern (für ~60: 45–75 Min)',
                        child: FilterChip(
                          label: Text(
                            _minutes > 0
                                ? 'Band ${DurationLens.chipLabel(_minutes)}'
                                : 'Band aus',
                          ),
                          selected: _matchTourDuration && _minutes > 0,
                          onSelected: (sel) => update(() {
                            _matchTourDuration = sel && _minutes > 0;
                          }),
                        ),
                      ),
                    ]),
                    group('Untergrund (alle Disziplinen)', [
                      for (final s in _surfaceTags)
                        Tooltip(
                          message: _surfaceDisplay(s),
                          child: FilterChip(
                            label: Text(_chipSurfaceLabel(s)),
                            selected: _surfaceFilter == s,
                            onSelected: (sel) => update(
                              () => _surfaceFilter = sel ? s : null,
                            ),
                          ),
                        ),
                    ]),
                    group('Beanspruchung', [
                      for (final sc in ['S0', 'S1', 'S2+'])
                        Tooltip(
                          message: 'Filter-Stufe $sc (OSM/Tour-Metadaten)',
                          child: FilterChip(
                            label: Text(_chipScaleLabel(sc)),
                            selected: _scaleFilter == sc,
                            onSelected: (sel) =>
                                update(() => _scaleFilter = sel ? sc : null),
                          ),
                        ),
                    ]),
                    group('Höhenmeter', [
                      for (final hm in [400, 800, 1200])
                        FilterChip(
                          label: Text('≥$hm hm'),
                          selected: _minElevationM == hm,
                          onSelected: (sel) =>
                              update(() => _minElevationM = sel ? hm : null),
                        ),
                    ]),
                    group('Form', [
                      Tooltip(
                        message: 'Nur Touren mit Track, deren Start und Ziel '
                            'zusammenfallen',
                        child: FilterChip(
                          label: const Text('Nur Rundkurse'),
                          selected: _loopOnly == true,
                          onSelected: (sel) =>
                              update(() => _loopOnly = sel ? true : null),
                        ),
                      ),
                    ]),
                    group('Trailnetz (Karte)', [
                      FilterChip(
                        label: Text(_showTrailNetwork ? 'Netz an' : 'Netz aus'),
                        selected: _showTrailNetwork,
                        onSelected: (v) {
                          update(() => _showTrailNetwork = v);
                          unawaited(_drawAll());
                        },
                      ),
                      for (final d in TrailDifficulty.values)
                        Tooltip(
                          message: 'OSM-Skala: ${trailDifficultyLabel(d)}',
                          child: FilterChip(
                            label: Text(trailDifficultyFriendlyLabel(d)),
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
                              update(() => _trailScaleFilter = sel ? d : null);
                              unawaited(_drawAll());
                            },
                          ),
                        ),
                    ]),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('${_filtered.length} Touren zeigen'),
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
        if (_surface == _Surface.plan) {
          // Im Planen nie _refreshQuick: das würde die halb gebaute Route
          // durch einen Schnell-Vorschlag ersetzen und die Karte umzeichnen.
          if (_start != null && _end != null) unawaited(_calcAb());
        } else {
          unawaited(_refreshQuick(limit: 3));
          unawaited(_fetchPublicCatalog());
        }
      },
      itemBuilder: (_) => [
        for (final p in RoutingProfile.values)
          PopupMenuItem(value: p, child: Text(p.label)),
      ],
      child: _panelChip(
        icon: Icons.pedal_bike,
        label: _profile.label,
        selected: false,
      ),
    );
  }

  /// Dauer-Lens Chips: ~45 · ~60 · ~90 · 2–3 h · egal (D-60-01).
  Widget _durationChip() {
    return PopupMenuButton<int>(
      tooltip: 'Dauer-Lens (~60 Min Default)',
      initialValue: _minutes,
      onSelected: (m) {
        setState(() {
          _minutes = m;
          // „egal“ schaltet Dauer-Filter aus; Presets schalten ihn an.
          _matchTourDuration = m > 0;
        });
        unawaited(_refreshQuick(limit: 3));
      },
      itemBuilder: (_) => [
        for (final p in DurationLens.presets)
          PopupMenuItem(
            value: p.minutes,
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: p.minutes == _minutes
                      ? const Icon(Icons.check, size: 16)
                      : null,
                ),
                Text(
                  p.label,
                  style: TextStyle(
                    fontWeight: p.minutes == 60
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (p.minutes == 60)
                  const Text(
                    '  Default',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
              ],
            ),
          ),
      ],
      child: _panelChip(
        icon: Icons.schedule,
        label: DurationLens.chipLabel(_minutes),
        selected: _matchTourDuration && _minutes > 0,
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

  /// Der eine Discover-Zustand: Steuerzeile, dann eine durchgehende Liste aus
  /// Schnell-Vorschlägen, Touren und Gespeichertem. Vorher waren das zwei
  /// getrennte Tabs mit unterschiedlichem Kartenformat.
  Widget _buildDiscoverPanel() {
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.m,
      ),
      children: [
        ..._quickSection(),
        ..._toursSection(),
        ..._savedTiles(),
      ],
    );
    return Column(
      children: [
        _panelHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.xs,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _durationChip(),
                const SizedBox(width: AppSpacing.xs),
                _profileChip(),
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: () => unawaited(_openFilterSheet()),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: _panelChip(
                    icon: Icons.tune,
                    label: 'Filter',
                    selected: _activeFilterCount > 0,
                    badge: _activeFilterCount,
                  ),
                ),
              ],
            ),
          ),
        ),
        _panelMessages(),
        Expanded(child: _withLoadingVeil(body)),
      ],
    );
  }

  /// Planen — derselbe Platz, anderer Inhalt. Die Kopfzeile trägt „Zurück",
  /// damit klar ist: das hier ist ein Zwischenschritt, kein zweiter Bereich.
  Widget _buildPlanPanel() {
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
                onPressed: _closePlan,
                icon: const Icon(Icons.arrow_back),
                visualDensity: VisualDensity.compact,
              ),
              const Expanded(
                child: Text(
                  'Route planen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              _profileChip(),
            ],
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
              Expanded(
                child: Text(
                  detail.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
                Text(
                  '${detail.distanceKm} km · ${detail.elevationM} hm · '
                  '${detail.durationMin} min',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                _DifficultyStatsRow(
                  difficultyRaw: detail.mtbScale,
                  segments: [
                    _surfaceDisplay(detail.surface),
                    if (_shapeLabel(detail) case final shape?) shape,
                    if (_nearbyActivity(detail.center) case final n?)
                      'beliebt · ≥$n Ride-Nutzer',
                  ],
                  fontSize: 13,
                ),
                if (_elevationSummary != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _elevationSummary!,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
                if (_elevationSamples.length >= 2) ...[
                  const SizedBox(height: AppSpacing.s),
                  SizedBox(
                    height: 48,
                    child: CustomPaint(
                      painter: _MiniElevPainter(_elevationSamples),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.m),
                ...detail.reasons.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text('· $r'),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                if (_isPinOnlyIdea(detail)) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed:
                        _loading ? null : () => _computeIdeaRoute(detail),
                    icon: const Icon(Icons.route),
                    label: const Text('Route berechnen'),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  const Text(
                    'Keine gespeicherte Polyline — Live-Routing um den '
                    'Ortspunkt oder A→B mit Ziel-Vorschlag.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  OutlinedButton.icon(
                    onPressed: () => _startRide(suggestion: detail),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Losfahren (nach Routing)'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: () => _startRide(suggestion: detail),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Losfahren'),
                  ),
                ],
                const SizedBox(height: AppSpacing.s),
                // Benannt nach der Handlung, nicht nach dem Panel, in dem
                // man landet — wie auf der Tourenkarte in der Liste.
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => unawaited(_adoptTourIntoPlan(detail)),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Anpassen'),
                ),
                const SizedBox(height: AppSpacing.s),
                OutlinedButton(
                  onPressed:
                      _loading ? null : () => unawaited(_hybridSnap(detail)),
                  child: const Text('Von hier starten (Hybrid)'),
                ),
                const SizedBox(height: AppSpacing.s),
                OutlinedButton.icon(
                  onPressed: () => _openTrailView(near: detail.center),
                  icon: const Icon(Icons.streetview),
                  label: const Text('Trail View — Mapillary'),
                ),
              ],
            ),
          ),
        ),
      ],
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
            ? 'Vorschläge für ${DurationLens.chipLabel(_minutes)} · Profil ${_profile.label} · Tippen = Karte, Los = Navigation'
            : 'Standort erlauben für Touren ab hier · Default-Lens ${DurationLens.chipLabel(_minutes)}',
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
            label: const Text('Standort für Near-me freigeben'),
          ),
        ),
      if (_quick.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Text(
            _loading
                ? 'Vorschläge werden berechnet…'
                : 'Keine Vorschläge — Standort setzen, Sport-Chip wählen oder „Neu".',
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
                  leading:
                      const Icon(Icons.near_me, color: AppColors.accent),
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
                      label: const Text('Anpassen'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
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
                      label: const Text(MultiSportCopy.goRide),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildPlanSheet() {
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
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
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
                const SizedBox(height: AppSpacing.s),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          if (ideaTour != null &&
                              (_end == null || _computed == null)) {
                            unawaited(_computeIdeaRoute(ideaTour));
                          } else {
                            unawaited(_calcAb());
                          }
                        },
                  icon: const Icon(Icons.route),
                  label: Text(
                    ideaTour != null
                        ? 'Route berechnen & speichern'
                        : 'Route berechnen',
                  ),
                ),
                if (_end == null)
                  TextButton(
                    onPressed: () => setState(() => _pick = _PickMode.end),
                    child: const Text('Ziel auf Karte tippen'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        Text(
          switch (_pick) {
            _PickMode.via => 'Tippe Via auf die Karte — oder Adresse unten',
            _PickMode.end => 'Tippe Ziel oder Adresse eingeben',
            _PickMode.start => 'Tippe Start oder Adresse eingeben',
            _ => 'Adresse suchen oder auf Karte tippen',
          },
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Start-Adresse',
                textField: true,
                child: TextField(
                  controller: _startAddrCtrl,
                  focusNode: _startAddrFocus,
                  autofillHints: const [AutofillHints.addressCity],
                  decoration: const InputDecoration(
                    labelText: 'Start-Adresse',
                    hintText: 'z. B. Heidelberg Hbf',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => _scheduleAddressSearch('start'),
                  onSubmitted: (_) => _searchAddress('start'),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Start suchen',
              onPressed: _addrBusy ? null : () => _searchAddress('start'),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Ziel-Adresse',
                textField: true,
                child: TextField(
                  controller: _endAddrCtrl,
                  autofillHints: const [AutofillHints.addressCity],
                  decoration: const InputDecoration(
                    labelText: 'Ziel-Adresse',
                    hintText: 'z. B. Wiesloch',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => _scheduleAddressSearch('end'),
                  onSubmitted: (_) => _searchAddress('end'),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ziel suchen',
              onPressed: _addrBusy ? null : () => _searchAddress('end'),
              icon: const Icon(Icons.search),
            ),
          ],
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
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          children: [
            ActionChip(
              label: const Text('Start tippen'),
              onPressed: () => setState(() => _pick = _PickMode.start),
            ),
            ActionChip(
              label: const Text('+ Via'),
              onPressed: () => setState(() => _pick = _PickMode.via),
            ),
            ActionChip(
              label: const Text('Ziel tippen'),
              onPressed: () => setState(() => _pick = _PickMode.end),
            ),
            ActionChip(
              label: Text(_userPos != null ? 'Hier' : 'Standort'),
              onPressed: () => unawaited(_locate()),
            ),
          ],
        ),
        Text(
          'Start: ${_start != null ? '${_start!.lat.toStringAsFixed(3)}, ${_start!.lng.toStringAsFixed(3)}' : '—'}',
          style: const TextStyle(fontSize: 12),
        ),
        ..._vias.asMap().entries.map(
              (e) => Row(
                children: [
                  Expanded(
                    child: Text(
                      'Via ${e.key + 1}: ${e.value.lat.toStringAsFixed(3)}, ${e.value.lng.toStringAsFixed(3)}',
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
        Text(
          'Ziel: ${_end != null ? '${_end!.lat.toStringAsFixed(3)}, ${_end!.lng.toStringAsFixed(3)}' : '—'}',
          style: const TextStyle(fontSize: 12),
        ),
        TextButton(
          onPressed: () {
            final u = _userPos;
            if (u != null) {
              setState(() {
                _start = u;
                _startAddrCtrl.text = 'Meine Position';
                _pick = _PickMode.end;
              });
              _syncMarkers();
            } else {
              _locate();
            }
          },
          child: const Text('Start = meine Position'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
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
                ? 'Route berechnen (Start & Ziel nötig)'
                : 'Route berechnen',
          ),
        ),
      ],
    );
  }


  /// Demo-Stadt centers from bundled Nähe seeds (Berlin + DACH + Rhein-Neckar).
  /// Chip only meaningful when ≥1 seed in 45–75 min exists for that city.
  static const _demoCities = <({String name, double lat, double lng})>[
    (name: 'Berlin', lat: 52.52, lng: 13.405),
    (name: 'München', lat: 48.183, lng: 11.61),
    (name: 'Köln', lat: 50.941, lng: 6.958),
    (name: 'Zürich', lat: 47.366, lng: 8.541),
    (name: 'Wien', lat: 48.218, lng: 16.392),
    (name: 'Innsbruck', lat: 47.286, lng: 11.399),
    (name: 'Konstanz', lat: 47.677, lng: 9.174),
    (name: 'Heidelberg', lat: 49.409, lng: 8.694),
    (name: 'Mannheim', lat: 49.483, lng: 8.462),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Noch keine ~60-Min-Touren hier.',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wähle eine Demo-Stadt oder änder den Ort.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: _focusOrtSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Ort ändern'),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              const Text(
                'Demo-Stadt',
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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openPlan(
                    status: 'Route selbst planen — Start & Ziel setzen',
                    pick: _PickMode.start,
                  ),
                  child: const Text('Route selbst planen'),
                ),
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
    final catalog = list.where((r) => r.isCatalog).toList();
    final live = list.where((r) => !r.isCatalog && !r.isSeed).toList();
    final seeds = list.where((r) => r.isSeed).toList();
    final o = _origin;
    final liveEmpty = live.isEmpty;
    // Seeds: ohne Standort, wenn OA/OSM/Katalog dünn, oder immer bei ~60-Lens
    // (nicht hinter einem einzelnen Live-Hiking-Hit verstecken — D-60 / RN P0).
    final showSeeds = seeds.isNotEmpty &&
        (!_hasRealOrigin || liveEmpty || catalog.isEmpty || _minutes == 60);
    final seedLabel = _hasRealOrigin
        ? (_seedsBundle?.labelWithLocation ?? '~60 Min um dich')
        : (_seedsBundle?.labelWithoutLocation ?? '~60 Min in deiner Region');
    final sources = [
      if (_oaStatus != null) _oaStatus!,
      if (_seedsStatus != null) _seedsStatus!,
      if (_trailNetworkStatus != null) _trailNetworkStatus!,
    ].join(' · ');

    final loopCount = list.where(_isLoop).length;
    // Soft radius for empty-ort UI only — seeds stay in the list (no hard-fail).
    // ≥35 km so Wiesloch still sees HD/MA Rhein-Neckar centers.
    const seedRadiusKm = 35.0;
    final nearbyLoopCount = list.where((r) {
      if (!_isLoop(r)) return false;
      return _distKm(o.lat, o.lng, r.center.latitude, r.center.longitude) <=
          seedRadiusKm;
    }).length;
    final lensHint = _matchTourDuration && _minutes > 0
        ? ' · Lens ${DurationLens.chipLabel(_minutes)}'
        : '';

    return [
      _sectionTitle(
        loopCount > 0
            ? 'Touren (${list.length}) · $loopCount Rundkurse$lensHint'
            : 'Touren (${list.length})$lensHint',
        hint: _hasRealOrigin
            ? 'Katalog + Live · ab ${o.lat.toStringAsFixed(2)}°N'
                '${_userPos != null ? ' (GPS)' : ''}'
            : 'Katalog + Seeds ohne GPS · Live-OSM nach Standort',
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
      if (sources.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            sources,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: _heatmapConsent
            ? Text(
                _heatmapNote ??
                    'Heatmap: lokal eigene Rides; Community erst ab k≥5 vom Backend',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF7043),
                ),
              )
            : InkWell(
                onTap: () async {
                  await openPrivacyScreen(context);
                  if (mounted) await _loadHeatmapConsent();
                },
                child: const Text(
                  'Heatmaps nach Consent — Privatsphäre öffnen',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
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
      if (!_hasRealOrigin)
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.m),
          child: Text(
            'Katalog-Touren jederzeit · GPS freigeben für Near-me und OSM-Live.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      if (nearbyLoopCount == 0 && _minutes == 60)
        _emptyOrtPicker()
      else if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _activeFilterCount > 0
                      ? 'Keine Tour bei diesen Filtern.'
                      : 'Keine Touren — „Neu“ tippen oder Filter lockern.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              if (_activeFilterCount > 0)
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Filter zurücksetzen'),
                ),
            ],
          ),
        ),
      if (showSeeds) ...[
        _sectionTitle(
          '$seedLabel (${seeds.length})',
          hint: _hasRealOrigin
              ? 'Region-Loops ≤35 km · offline · Losfahren startet Ride'
              : 'Kuratierte ~60-Min Rundkurse · Berlin · DACH · Rhein-Neckar',
        ),
        for (final r in seeds) _tourListCard(r, o),
      ],
      if (catalog.isNotEmpty) ...[
        _sectionTitle(
          'Katalog (${catalog.length})',
          hint: 'Redaktionell · Multi-Sport · Geometry beim Losfahren',
        ),
        for (final r in catalog) _tourListCard(r, o),
      ],
      if (live.isNotEmpty) ...[
        _sectionTitle(
          'Live / OSM (${live.length})',
          hint: _hasRealOrigin
              ? 'OpenStreetMap & Partner in der Nähe'
              : 'Erscheint nach GPS / Startpunkt',
        ),
        for (final r in live) _tourListCard(r, o),
      ],
    ];
  }

  Widget _tourListCard(_RouteSuggestion r, GeoPoint o) {
    final loop = _isLoop(r);
    final shape = _shapeLabel(r);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => unawaited(_openDetail(r.id, r.center)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (loop) ...[
                        const Text(
                          '⟲',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          r.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _selectedTourId == r.id
                                ? AppColors.accent
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: r.isSeed
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : r.isCatalog
                                  ? AppColors.accent.withValues(alpha: 0.12)
                                  : AppColors.forest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          r.sourceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: r.isCatalog || r.isSeed
                                ? AppColors.accent
                                : AppColors.forestOnDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    [
                      if (shape != null) shape,
                      '~${r.durationMin} Min',
                      '${r.distanceKm} km',
                      if (r.poiStopsCount > 0) '${r.poiStopsCount} Stops',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DifficultyStatsRow(
                    difficultyRaw: r.mtbScale,
                    segments: [
                      _surfaceDisplay(r.surface),
                      if (r.elevationM > 0) '↑${r.elevationM} m',
                      if (_nearbyActivity(r.center) case final n?)
                        'beliebt · ≥$n Ride-Nutzer',
                    ],
                  ),
                  Text(
                    '~${_distKm(o.lat, o.lng, r.center.latitude, r.center.longitude).round()} km entfernt'
                    '${_isPinOnlyIdea(r) ? ' · Tour-Idee' : r.hasTrack ? ' · Track' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            // Primary CTA zuerst (D-60-02): Losfahren ohne Detail-Umweg.
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: _loading
                        ? null
                        : () => unawaited(_startRide(suggestion: r)),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(
                      r.hasTrack || r.isSeed
                          ? MultiSportCopy.goRide
                          : (r.id.startsWith('oa-') || r.id.contains('demo'))
                              ? 'Los · Track?'
                              : MultiSportCopy.goRide,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                OutlinedButton(
                  onPressed: () => unawaited(_openDetail(r.id, r.center)),
                  child: const Text('Mehr'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_isPinOnlyIdea(r))
                    OutlinedButton.icon(
                      onPressed:
                          _loading ? null : () => _computeIdeaRoute(r),
                      icon: const Icon(Icons.route, size: 16),
                      label: const Text('Route berechnen'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () async {
                        final routed = await _geometryForTour(r);
                        if (!mounted) return;
                        if (routed.demo || routed.points.length < 2) {
                          await _computeIdeaRoute(r);
                          return;
                        }
                        final preview = RouteResult(
                          coordinates: routed.points,
                          distanceM: r.distanceKm * 1000,
                          durationS: r.durationMin * 60.0,
                          engine: 'tour-routed',
                        );
                        setState(() {
                          _computed = preview;
                          _ideaPin = null;
                          _selectedTourId = r.id;
                          _label = r.name;
                          _status = 'Live-geroutete Tour-Vorschau';
                        });
                        await _drawRoute(preview);
                      },
                      child: const Text('Vorschau'),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton(
                    onPressed: _loading ? null : () => _hybridSnap(r),
                    child: const Text('Von hier'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed:
                        _loading ? null : () => _adoptTourIntoPlan(r),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Anpassen'),
                  ),
                  IconButton(
                    tooltip: 'Umgebungsfotos',
                    onPressed: () => _openTrailView(near: r.center),
                    icon: const Icon(Icons.streetview, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _savedTiles() {
    final savedList =
        ref.watch(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    if (savedList.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.s),
      const Text(
        'Gespeichert',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
      for (final s in savedList)
        ListTile(
          dense: true,
          title: Text(s.name),
          subtitle: Text(
            '${s.distanceKm.toStringAsFixed(1)} km · ${s.durationMin} min'
            '${s.hasLayerParts ? ' · Layer' : ''}',
          ),
          onTap: () => _loadSaved(s),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await _routes.deleteSaved(s.id);
                  ref.invalidate(savedRoutesProvider);
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
                  );
                  ref.read(shellTabIndexProvider.notifier).state = 2;
                },
              ),
            ],
          ),
        ),
    ];
  }
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
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
                              : const Center(
                                  child: Text('Keine Live-Fotos'),
                                );
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
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
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniElevPainter oldDelegate) =>
      oldDelegate.samples != samples;
}
