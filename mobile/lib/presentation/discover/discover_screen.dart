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
import '../../core/theme/app_theme.dart';
import '../../data/import/gpx_import.dart';
import '../../data/routing/elevation_client.dart';
import '../../data/routing/geocode_client.dart';
import '../../data/routing/osm_routes_client.dart';
import '../../data/routing/osm_trail_network_client.dart';
import '../../data/routing/route_collections.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/routing/heatmap.dart';
import '../../data/routing/heatmap_client.dart';
import '../../data/routing/routing_status_client.dart';
import '../../domain/routing/trail_difficulty.dart';
import '../../domain/routing/trail_view.dart';
import '../../domain/saved_route.dart';
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
    required this.loop,
    required this.matchScore,
    required this.reasons,
    required this.center,
    this.categories = const [
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.mtbEnduro,
    ],
    this.trackLngLat,
  });

  final String id;
  final String name;
  final double distanceKm;
  final int elevationM;
  final int durationMin;
  final String mtbScale;
  final String surface;
  final bool loop;
  final int matchScore;
  final List<String> reasons;
  final LatLng center;
  final List<BikeCategory> categories;
  /// Optional echte Polyline [lng, lat] (z. B. Outdooractive).
  final List<List<double>>? trackLngLat;

  bool get hasTrack =>
      trackLngLat != null && trackLngLat!.length >= 2;
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

enum _SheetMode { quick, plan, tours }

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

  _SheetMode _mode = _SheetMode.quick;
  RoutingProfile _profile = RoutingProfile.mtbTrail;
  int _minutes = 90;
  bool _loading = false;
  String? _error;
  String? _status;

  GeoPoint? _userPos;
  GeoPoint? _start;
  GeoPoint? _end;
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
  int? _durationBucket; // 60 / 90 / 120
  String? _surfaceFilter;
  String? _scaleFilter; // S0 / S1 / S2+
  bool? _loopOnly;
  int? _minElevationM;
  bool _heatmapConsent = false;
  bool _heatmapContributed = false;
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
  final _endAddrCtrl = TextEditingController();
  List<GeocodeHit> _addrHits = const [];
  bool _addrBusy = false;
  String? _addrTarget; // 'start' | 'end'
  Timer? _addrDebounce;
  int _quickGen = 0;
  String? _selectedTourId;

  /// Nur Karten-Übersicht DACH+FR bis GPS da ist — nie Tour-Origin.
  static const _regionOverview = GeoPoint(47.2, 6.5);
  static const _durationBuckets = [60, 90, 120];
  static const _surfaceTags = ['flow/compact', 'trail/root'];

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
      if (active != null) {
        setState(() => _profile = routingProfileForBike(active.category));
      }
      final launch = ref.read(discoverLaunchModeProvider);
      if (launch != null) {
        ref.read(discoverLaunchModeProvider.notifier).state = null;
        setState(() {
          _mode = switch (launch) {
            DiscoverLaunchMode.plan => _SheetMode.plan,
            DiscoverLaunchMode.tours => _SheetMode.tours,
            DiscoverLaunchMode.quick => _SheetMode.quick,
          };
        });
      }
      if (_mode == _SheetMode.quick && _quick.isEmpty) {
        unawaited(_refreshQuick(limit: 3));
      }
    });
  }

  @override
  void dispose() {
    _addrDebounce?.cancel();
    _startAddrCtrl.dispose();
    _endAddrCtrl.dispose();
    super.dispose();
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
        _status = 'Adresssuche fehlgeschlagen: $e';
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
          _mode = _SheetMode.plan;
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
        _mode = _SheetMode.plan;
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
          _error = '$e';
        });
      }
    }
  }

  Future<void> _loadHeatmapConsent() async {
    try {
      final consents =
          await ref.read(garageRepositoryProvider).listConsents();
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
  }

  Future<void> _showTrailSheet(OsmTrailSegment trail) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                const SizedBox(height: 6),
                Text(
                  '${trail.difficultyLabel} · ${trail.lengthKm.toStringAsFixed(1)} km'
                  '${trail.surface != null ? ' · ${trail.surface}' : ''}'
                  '${trail.highway != null ? ' · ${trail.highway}' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'OSM-Live-Pfad — Tippen auf der Karte wählt Trails. '
                  'Anfahrt zum Einstieg, dann als Overlay speichern oder fahren.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(_approachTrail(trail));
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Zum Trailhead anfahren'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(_adoptTrailAsOverlay(trail));
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text('Trail auf Route legen'),
                ),
                if (trail.url != null) ...[
                  const SizedBox(height: 8),
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
        _mode = _SheetMode.plan;
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
          _error = '$e';
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
      _mode = _SheetMode.plan;
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
            openUrl: (m['openUrl'] as String?) ??
                'https://www.trailforks.com/',
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
        final surface = difficulty.toLowerCase().contains('schwer') ||
                difficulty.toLowerCase().contains('s2')
            ? 'trail/root'
            : 'flow/compact';
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
            loop: true,
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
        parsed.add(
          _RouteSuggestion(
            id: h.id,
            name: h.title,
            distanceKm: h.lengthKm,
            elevationM: 0,
            durationMin: h.durationMin,
            mtbScale: h.difficulty ?? (isMtb ? 'S1' : 'offen'),
            surface: isMtb ? 'trail/root' : 'flow/compact',
            loop: false,
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
            'Touren ${_tours.length} (${withTrack} mit Track) · OSM ${parsed.length}';
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
        _mode = _SheetMode.tours;
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
      setState(() {
        _selectedTourId = id;
        _selectedTrailId = null;
        _detailId = id;
        _mode = _SheetMode.tours;
      });
      await _drawAll();
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
          setState(() => _status = 'Ortungsdienst aus — Start tippen oder Adresse');
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
          setState(() => _status = 'Standort-Berechtigung fehlt — Adresse nutzen');
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
          setState(() => _status = 'Kein GPS-Fix — Karte tippen oder Adresse suchen');
        }
        return;
      }
      if (!mounted) return;
      final p = GeoPoint(pos.latitude, pos.longitude);
      setState(() {
        _userPos = p;
        _start = p;
        _startAddrCtrl.text = 'Meine Position';
        _status =
            'Position ${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}';
      });
      unawaited(_fetchOutdooractive());
      unawaited(_fetchOsmRoutes());
      unawaited(_fetchTrailNetwork());
      unawaited(_fetchTrailforks());
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 12),
      );
      if (_mode == _SheetMode.quick) {
        await _refreshQuick();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Position nicht verfügbar — Adresse oder Tippen');
      }
    }
  }

  /// Tour-/API-Origin nur mit echtem Start oder GPS — kein Stadt-Fake.
  GeoPoint? get _originOrNull => _userPos ?? _start;

  GeoPoint get _origin =>
      _originOrNull ?? _regionOverview;

  bool get _hasRealOrigin => _userPos != null || _start != null;

  GeoPoint get _mapCenter => _originOrNull ?? _regionOverview;

  /// Los-Leiste: in Planen nur bei echter Plan-Route, nicht bei Quick-Rest.
  bool get _showRideBar {
    if (_computed == null) return false;
    if (_mode != _SheetMode.plan) return true;
    final label = _label ?? '';
    return label == 'Geplante Route' ||
        label.endsWith('(Plan)') ||
        label.contains('(angehängt)');
  }

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
      // Dauer nur bei explizitem Bucket — sonst alle Regionen sichtbar.
      if (_durationBucket != null) {
        final delta = (r.durationMin - _durationBucket!).abs();
        if (delta > 45) return false;
      }
      if (_surfaceFilter != null && r.surface != _surfaceFilter) {
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
      if (_loopOnly == true) {
        if (r.distanceKm < 8) return false;
      }
      return true;
    }).toList();

    if (cat == null) {
      final sorted = List<_RouteSuggestion>.from(base);
      sorted.sort(_byDistanceFromOrigin);
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
    matched.sort(_byDistanceFromOrigin);
    rest.sort(_byDistanceFromOrigin);
    if (matched.isEmpty) {
      final sorted = List<_RouteSuggestion>.from(base);
      sorted.sort(_byDistanceFromOrigin);
      return sorted;
    }
    return [...matched, ...rest];
  }

  int _byDistanceFromOrigin(_RouteSuggestion a, _RouteSuggestion b) {
    final o = _origin;
    final da = _distKm(o.lat, o.lng, a.center.latitude, a.center.longitude);
    final db = _distKm(o.lat, o.lng, b.center.latitude, b.center.longitude);
    final c = da.compareTo(db);
    if (c != 0) return c;
    return b.matchScore.compareTo(a.matchScore);
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
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
      _quick = [];
    });
    final dests = _quickDestinations(_origin, _minutes);
    final labels = [
      '$_minutes min · Norden',
      '$_minutes min · Osten',
      '$_minutes min · Südwest',
    ];
    final reasons = [
      'Out-and-back Richtung Norden',
      'Out-and-back Richtung Osten',
      'Out-and-back Richtung Südwest',
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
        final result = await _routes.planRoute(
          from: _origin,
          to: dests[i],
          profile: _profile,
        );
        out.add(
          _QuickOption(
            id: 'quick-$i-$_minutes',
            label: labels[i],
            reason: reasons[i],
            result: result,
          ),
        );
      } catch (e) {
        final msg = e.toString();
        lastErr = msg;
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
          from: _origin,
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
      if (out.isNotEmpty) {
        _computed = out.first.result;
        _label = out.first.label;
        _selectedTourId = null;
      }
    });
    if (out.isNotEmpty) {
      await _drawRoute(out.first.result);
      await _refreshElevation(out.first.result);
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
      if (mounted) setState(() => _error = e.toString());
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
          _mode = _SheetMode.plan;
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
        _status =
            'Hybrid · ${(merged.distanceM / 1000).toStringAsFixed(1)} km';
        _mode = _SheetMode.tours;
      });
      await _drawAll();
      await _refreshElevation(merged);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
    final cosLat = math.cos(center.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
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
          _mode = _SheetMode.plan;
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
        _mode = _SheetMode.plan;
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
          _error = '$e';
          _status =
              'Routing fehlgeschlagen — Ziel tippen und erneut berechnen.';
          _mode = _SheetMode.plan;
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
                  for (final p in seg.coordinatesLngLat)
                    LatLng(p[1], p[0]),
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
      final others = trackTours
          .where((t) => t.id != _selectedTourId)
          .take(2);
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
        final approx =
            eng.contains('demo') || eng.contains('fallback');
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
              top: 40,
              right: 40,
              bottom: 120,
            ),
          );
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
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: suggestion.id,
        name: suggestion.name,
        distanceKm: suggestion.distanceKm,
        elevationM: suggestion.elevationM.toDouble(),
        durationMin: suggestion.durationMin,
        mtbScale: suggestion.mtbScale,
        coordinates: routed.points.map((p) => [p.lng, p.lat]).toList(),
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

  Future<void> _importGpxDialog() async {
    String? xml;
    String fallbackName = 'GPX-Import';

    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['gpx', 'xml'],
    );
    if (f != null) {
      fallbackName = f.name.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
      try {
        if (f.path != null) {
          xml = await File(f.path!).readAsString();
        } else {
          final bytes = await f.readAsBytes();
          xml = decodeGpxBytes(bytes);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    if (xml == null) {
      // Fallback: Paste-Dialog
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('GPX importieren'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Datei-Dialog abgebrochen — GPX-Inhalt hier einfügen.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '<gpx>…</gpx>',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      xml = ctrl.text.trim();
      if (xml.isEmpty) return;
    }

    if (xml.trim().isEmpty) return;
    final parsed = parseGpx(xml, fallbackName: fallbackName);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPX ungültig oder zu wenige Punkte')),
      );
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
      _mode = _SheetMode.tours;
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
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(ctx).bottom,
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
                  const SizedBox(height: 4),
                  const Text(
                    'Lokale Ordner für gespeicherte Routen — kein Social-Feed.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  for (final c in cols)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name),
                      subtitle: Text('${c.routeIds.length} Routen · tippen zum Öffnen'),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Neue Sammlung',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      await RouteCollectionsStore.create(nameCtrl.text);
                      cols = await RouteCollectionsStore.list();
                      nameCtrl.clear();
                      setModal(() {});
                    },
                    child: const Text('Anlegen'),
                  ),
                  const SizedBox(height: 8),
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
                          const SnackBar(content: Text('Zur Sammlung hinzugefügt')),
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
    final coords = s.coordinates
        .map((c) => GeoPoint(c[1], c[0]))
        .toList();
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
              coordinates:
                  s.approach.map((c) => GeoPoint(c[1], c[0])).toList(),
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
      _mode = s.hasLayerParts ? _SheetMode.tours : _SheetMode.plan;
      _status = 'Gespeicherte Route geladen';
    });
    await _drawAll();
  }

  @override
  Widget build(BuildContext context) {
    final style = _mapStyle;
    final detail = _detailId == null
        ? null
        : _tours.cast<_RouteSuggestion?>().firstWhere(
              (r) => r?.id == _detailId,
              orElse: () => null,
            );

    if (detail != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _detailId = null),
          ),
          title: Text(detail.name),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${detail.distanceKm} km · ${detail.elevationM} hm · ${detail.durationMin} min',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elevation: ${detail.elevationM} hm · ${detail.surface}',
              style: const TextStyle(fontSize: 13),
            ),
            if (_elevationSummary != null) ...[
              const SizedBox(height: 4),
              Text(
                _elevationSummary!,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            if (_elevationSamples.length >= 2) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: CustomPaint(
                  painter: _MiniElevPainter(_elevationSamples),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...detail.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('· $r'),
              ),
            ),
            const SizedBox(height: 16),
            if (_isPinOnlyIdea(detail)) ...[
              FilledButton.icon(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed:
                    _loading ? null : () => _computeIdeaRoute(detail),
                icon: const Icon(Icons.route),
                label: const Text('Route berechnen'),
              ),
              const SizedBox(height: 8),
              Text(
                'Keine gespeicherte Polyline — Live-Routing um den Ortspunkt '
                'oder A→B mit Ziel-Vorschlag.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _startRide(suggestion: detail),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Losfahren (nach Routing)'),
              ),
            ] else ...[
              FilledButton.icon(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () => _startRide(suggestion: detail),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Losfahren'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : () => _adoptTourIntoPlan(detail),
              child: const Text('In Planen'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : () => _hybridSnap(detail),
              child: const Text('Von hier starten (Hybrid)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openTrailView(near: detail.center),
              icon: const Icon(Icons.streetview),
              label: const Text('Trail View — Mapillary'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'GPX importieren',
                        onPressed: _importGpxDialog,
                        icon: const Icon(Icons.upload_file),
                      ),
                      IconButton(
                        tooltip: 'Meine Position',
                        onPressed: _locate,
                        icon: const Icon(Icons.my_location),
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
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'collections',
                            child: Text('Sammlungen'),
                          ),
                          PopupMenuItem(
                            value: 'trailview',
                            child: Text('Trail View'),
                          ),
                          PopupMenuItem(
                            value: 'offline',
                            child: Text('Offline-Karten'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_routingStatusNote != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _routingStatusNote!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (_mode == _SheetMode.tours && _oaStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _oaStatus!,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                  if (_mode == _SheetMode.tours && _trailNetworkStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _trailNetworkStatus!,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                  if (_mode == _SheetMode.tours && _heatmapConsent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _heatmapNote ??
                            'Heatmap: lokal eigene Rides; Community erst ab k≥5 vom Backend',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF7043),
                        ),
                      ),
                    )
                  else if (_mode == _SheetMode.tours)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () async {
                          await openPrivacyScreen(context);
                          if (mounted) await _loadHeatmapConsent();
                        },
                        child: const Text(
                          'Heatmaps nach Consent — Privatsphäre öffnen',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  if (_mode == _SheetMode.tours) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final m in _durationBuckets) ...[
                            FilterChip(
                              label: Text('$m min'),
                              selected: _durationBucket == m,
                              onSelected: (sel) {
                                setState(() {
                                  _durationBucket = sel ? m : null;
                                  if (sel) _minutes = m;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                          for (final s in _surfaceTags) ...[
                            FilterChip(
                              label: Text(s.split('/').first),
                              selected: _surfaceFilter == s,
                              onSelected: (sel) {
                                setState(() {
                                  _surfaceFilter = sel ? s : null;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                          for (final sc in ['S0', 'S1', 'S2+']) ...[
                            FilterChip(
                              label: Text(sc),
                              selected: _scaleFilter == sc,
                              onSelected: (sel) {
                                setState(() {
                                  _scaleFilter = sel ? sc : null;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                          FilterChip(
                            label: const Text('Rundkurs'),
                            selected: _loopOnly == true,
                            onSelected: (sel) {
                              setState(() => _loopOnly = sel ? true : null);
                            },
                          ),
                          const SizedBox(width: 6),
                          for (final hm in [400, 800, 1200]) ...[
                            FilterChip(
                              label: Text('≥$hm hm'),
                              selected: _minElevationM == hm,
                              onSelected: (sel) {
                                setState(() {
                                  _minElevationM = sel ? hm : null;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_mode != _SheetMode.plan) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<RoutingProfile>(
                          key: ValueKey('profile-qt-$_profile'),
                          initialValue: _profile,
                          isDense: true,
                          items: RoutingProfile.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ),
                              )
                              .toList(),
                          onChanged: (p) {
                            if (p == null) return;
                            setState(() => _profile = p);
                            if (_mode == _SheetMode.quick) {
                              unawaited(_refreshQuick(limit: 3));
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Profil',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      if (_mode == _SheetMode.quick) ...[
                      const SizedBox(width: 10),
                      Text(
                        '$_minutes min',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ],
                    ],
                  ),
                  if (_mode == _SheetMode.quick)
                  Slider(
                    value: _minutes.toDouble(),
                    min: 45,
                    max: 240,
                    divisions: 13,
                    label: '$_minutes min',
                    onChanged: (v) => setState(() {
                      _minutes = v.round();
                      _durationBucket = null;
                    }),
                    onChangeEnd: (_) {
                      if (_mode == _SheetMode.quick) {
                        unawaited(_refreshQuick(limit: 3));
                      }
                    },
                  ),
                  ],
                  if (_mode == _SheetMode.plan)
                    DropdownButtonFormField<RoutingProfile>(
                      key: ValueKey('profile-plan-$_profile'),
                      initialValue: _profile,
                      isDense: true,
                      items: RoutingProfile.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.label),
                            ),
                          )
                          .toList(),
                      onChanged: (p) {
                        if (p == null) return;
                        setState(() => _profile = p);
                        if (_start != null && _end != null) {
                          unawaited(_calcAb());
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Profil',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MapLibreMap(
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
                  onMapClick: (point, latLng) async {
                    if (_mode != _SheetMode.plan) return;
                    final p = GeoPoint(latLng.latitude, latLng.longitude);
                    final wasWithoutOrigin = !_hasRealOrigin;
                    setState(() {
                      switch (_pick) {
                        case _PickMode.via:
                          _vias.add(p);
                          break;
                        case _PickMode.end:
                          _end = p;
                          _pick = _PickMode.none;
                          break;
                        case _PickMode.start:
                          _start = p;
                          _pick = _PickMode.end;
                          break;
                        case _PickMode.none:
                          if (_start == null) {
                            _start = p;
                            _pick = _PickMode.end;
                          } else {
                            _end = p;
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
                ),
                if (_showRideBar)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_label ?? 'Route'} · '
                                '${(_computed!.distanceM / 1000).toStringAsFixed(1)} km · '
                                '${(_computed!.durationS / 60).round()} min'
                                '${_elevationSummary != null ? ' · $_elevationSummary' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
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
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () => _startRide(),
                              child: const Text('Los'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        _modeChip(_SheetMode.quick, 'Schnell', Icons.bolt),
                        const SizedBox(width: 6),
                        _modeChip(_SheetMode.plan, 'Planen', Icons.route),
                        const SizedBox(width: 6),
                        _modeChip(_SheetMode.tours, 'Touren', Icons.map),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _status!,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  SizedBox(
                    height: _mode == _SheetMode.plan
                        ? (_ideaPin != null ? 280 : 220)
                        : 170,
                    child: _buildSheetBody(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(_SheetMode mode, String label, IconData icon) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _mode = mode;
            _addrHits = const [];
            _error = null;
            if (mode == _SheetMode.plan) {
              _status ??= 'Adresse suchen oder auf Karte tippen';
            }
          });
          if (mode == _SheetMode.quick) {
            unawaited(_refreshQuick(limit: 3));
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.chipIdle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.chipIdleText,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.chipIdleText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetBody() {
    final body = switch (_mode) {
      _SheetMode.quick => _buildQuickSheet(),
      _SheetMode.plan => _buildPlanSheet(),
      _SheetMode.tours => _buildToursSheet(),
    };
    if (!_loading) return body;
    return Stack(
      children: [
        Opacity(opacity: 0.45, child: IgnorePointer(child: body)),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildQuickSheet() {
    return ListView(
          padding: const EdgeInsets.all(12),
          scrollDirection: Axis.horizontal,
          children: [
            if (_quick.isEmpty)
              const SizedBox(
                width: 220,
                child: Center(child: Text('Keine Quick-Optionen')),
              ),
            ..._quick.map((q) {
              final selected = _label == q.label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      _computed = q.result;
                      _label = q.label;
                      _selectedTourId = null;
                    });
                    await _drawRoute(q.result);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accent
                            : AppColors.muted.withValues(alpha: 0.35),
                      ),
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(q.result.distanceM / 1000).toStringAsFixed(1)} km · '
                          '${(q.result.durationS / 60).round()} min',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          q.reason,
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
  }

  Widget _buildPlanSheet() {
    final ideaTour = _ideaPin != null ? _tourById(_selectedTourId) : null;
    return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_ideaPin != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
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
                    const SizedBox(height: 4),
                    Text(
                      _end == null
                          ? 'Ziel tippen oder Adresse — dann Route berechnen.'
                          : 'Start/Ziel gesetzt. Route berechnen oder Ziel anpassen.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
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
                        onPressed: () =>
                            setState(() => _pick = _PickMode.end),
                        child: const Text('Ziel auf Karte tippen'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              switch (_pick) {
                _PickMode.via => 'Tippe Via auf die Karte — oder Adresse unten',
                _PickMode.end => 'Tippe Ziel oder Adresse eingeben',
                _PickMode.start => 'Tippe Start oder Adresse eingeben',
                _ => 'Adresse suchen oder auf Karte tippen',
              },
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Start-Adresse',
                    textField: true,
                    child: TextField(
                      controller: _startAddrCtrl,
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
            const SizedBox(height: 6),
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
                padding: EdgeInsets.symmetric(vertical: 8),
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
            const SizedBox(height: 6),
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

  Widget _buildToursSheet() {
        final list = _filtered;
        final o = _origin;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Trails & Touren',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilterChip(
                  label: Text(_showTrailNetwork ? 'Netz an' : 'Netz aus'),
                  selected: _showTrailNetwork,
                  onSelected: (v) {
                    setState(() => _showTrailNetwork = v);
                    unawaited(_drawAll());
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Difficulty legend — what MTB riders expect on the map.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final d in TrailDifficulty.values) ...[
                    FilterChip(
                      label: Text(trailDifficultyLabel(d)),
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
                        setState(() {
                          _trailScaleFilter = sel ? d : null;
                        });
                        unawaited(_drawAll());
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => unawaited(_fetchTrailNetwork()),
                    child: const Text('Netz neu'),
                  ),
                ],
              ),
            ),
            if (_selectedTrailId != null) ...[
              const SizedBox(height: 8),
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
                    child: ListTile(
                      leading: Icon(
                        Icons.terrain,
                        color: Color(
                          int.parse(
                            'FF${sel.lineColor.substring(1)}',
                            radix: 16,
                          ),
                        ),
                      ),
                      title: Text(sel.name),
                      subtitle: Text(
                        '${sel.difficultyLabel} · ${sel.lengthKm.toStringAsFixed(1)} km',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.navigation),
                        onPressed: () => unawaited(_approachTrail(sel!)),
                      ),
                      onTap: () => unawaited(_showTrailSheet(sel!)),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Touren vom Standort (${list.length})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                _hasRealOrigin
                    ? 'Sortiert nach Nähe zu ${o.lat.toStringAsFixed(2)}°N, ${o.lng.toStringAsFixed(2)}°E'
                        '${_userPos != null ? ' (GPS)' : ''}'
                    : 'Standort oder Start setzen — Trails für DACH & Frankreich',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
            if (!_hasRealOrigin)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Keine Beispiel-Touren — erst GPS oder Startpunkt, dann Live-Touren.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (list.isEmpty && _hasRealOrigin)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Keine Tour bei diesen Filtern — Filter lockern oder später erneut laden.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ...list.map((r) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _detailId = r.id;
                            _selectedTourId = r.id;
                          });
                          unawaited(_drawAll());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _selectedTourId == r.id
                                    ? AppColors.accent
                                    : null,
                              ),
                            ),
                            Text(
                              _isPinOnlyIdea(r)
                                  ? 'Tour-Idee · kein Track — „Route berechnen“'
                                  : 'Gespeicherte / geroutete Tour',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              '~${_distKm(o.lat, o.lng, r.center.latitude, r.center.longitude).round()} km entfernt · '
                              '${r.distanceKm} km · ${r.elevationM} hm · ${r.durationMin} min · ${r.matchScore}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              r.surface,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_isPinOnlyIdea(r)) ...[
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                ),
                                onPressed: _loading
                                    ? null
                                    : () => _computeIdeaRoute(r),
                                icon: const Icon(Icons.route, size: 18),
                                label: const Text('Route berechnen & speichern'),
                              ),
                              const SizedBox(width: 8),
                            ] else
                              OutlinedButton(
                                onPressed: () async {
                                  final routed = await _geometryForTour(r);
                                  if (!mounted) return;
                                  if (routed.demo ||
                                      routed.points.length < 2) {
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
                                    _status =
                                        'Live-geroutete Tour-Vorschau';
                                  });
                                  await _drawRoute(preview);
                                },
                                child: const Text('Vorschau'),
                              ),
                            if (!_isPinOnlyIdea(r)) const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed:
                                  _loading ? null : () => _hybridSnap(r),
                              child: const Text('Von hier'),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton(
                              onPressed: _loading
                                  ? null
                                  : () => _adoptTourIntoPlan(r),
                              child: const Text('In Planen'),
                            ),
                            IconButton(
                              tooltip: 'Trail View',
                              onPressed: () =>
                                  _openTrailView(near: r.center),
                              icon: const Icon(Icons.streetview, size: 20),
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                              ),
                              onPressed: () => _startRide(suggestion: r),
                              child: Text(
                                r.id.startsWith('idea-') ||
                                        r.id.startsWith('oa-') ||
                                        r.id.startsWith('r-') ||
                                        r.id.contains('demo')
                                    ? 'Los · Track?'
                                    : 'Los',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            ..._savedTiles(),
          ],
        );
  }

  List<Widget> _savedTiles() {
    final savedList =
        ref.watch(savedRoutesProvider).valueOrNull ?? const <SavedRouteEntry>[];
    if (savedList.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Text(
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
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _result?.photos ?? const <TrailPhoto>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Text(
                _result?.disclaimer ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                _result?.attribution ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A7C59), Color(0xFF2D4A35)],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
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
      final y = size.height -
          ((samples[i] - minV) / range) * (size.height - 4) -
          2;
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
