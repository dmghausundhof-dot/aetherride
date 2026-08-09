import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
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
import '../../data/routing/route_collections.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/routing/heatmap.dart';
import '../../data/routing/heatmap_client.dart';
import '../../domain/routing/trail_view.dart';
import '../../domain/saved_route.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../profile/profile_screen.dart';
import 'offline_maps_sheet.dart';

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

/// Lokale Tour-*Ideen* (Schwarzwald/Freiburg) — keine Track-Polylines.
/// Geometrie erst via Live-Routing, sonst ehrliche Näherung (gestrichelt).
const _seedRoutes = <_RouteSuggestion>[
  _RouteSuggestion(
    id: 'idea-schauinsland',
    name: 'Schauinsland Trail-Idee',
    distanceKm: 22,
    elevationM: 980,
    durationMin: 130,
    mtbScale: 'S1–S2',
    surface: 'trail/forest',
    loop: true,
    matchScore: 90,
    reasons: [
      'Idee für MTB um Freiburg — kein gespeicherter GPS-Track',
      'Live-Routing oder GPX nötig für echte Linienführung',
    ],
    center: LatLng(47.912, 7.898),
    categories: const [
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.mtbEnduro,
      BikeCategory.emtb,
    ],
  ),
  _RouteSuggestion(
    id: 'idea-kaltenbronn',
    name: 'Kaltenbronn Runden-Idee',
    distanceKm: 34,
    elevationM: 980,
    durationMin: 160,
    mtbScale: 'S1–S2',
    surface: 'trail/root',
    loop: true,
    matchScore: 86,
    reasons: [
      'Schwarzwald-Klassiker als Idee — Geometrie nicht vorgeliefert',
    ],
    center: LatLng(48.642, 8.425),
    categories: const [
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.gravel,
      BikeCategory.emtb,
    ],
  ),
  _RouteSuggestion(
    id: 'idea-dreisam-city',
    name: 'Dreisam City-Schleife',
    distanceKm: 12,
    elevationM: 80,
    durationMin: 45,
    mtbScale: '—',
    surface: 'asphalt/path',
    loop: true,
    matchScore: 84,
    reasons: [
      'City-/Urban-Idee entlang der Dreisam — nicht als Trail verkauft',
    ],
    center: LatLng(47.995, 7.845),
    categories: const [
      BikeCategory.urban,
      BikeCategory.etrekking,
      BikeCategory.road,
    ],
  ),
  _RouteSuggestion(
    id: 'idea-kaiserstuhl-road',
    name: 'Kaiserstuhl Rennrad-Idee',
    distanceKm: 48,
    elevationM: 620,
    durationMin: 140,
    mtbScale: '—',
    surface: 'asphalt',
    loop: true,
    matchScore: 82,
    reasons: [
      'Rennrad-/Gravel-Idee westlich Freiburg — Strecke erst routen',
    ],
    center: LatLng(48.09, 7.67),
    categories: const [
      BikeCategory.road,
      BikeCategory.gravel,
      BikeCategory.etrekking,
    ],
  ),
];

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

class _TrailSeed {
  const _TrailSeed({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.points,
  });
  final String id;
  final String name;
  final String difficulty;
  final List<GeoPoint> points;
}

/// Kurze Beispiel-Connectoren (5 Punkte) — kein OSM-/Partner-Track.
/// Standardmäßig aus (`_showTrails = false`).
const _seedTrails = <_TrailSeed>[
  _TrailSeed(
    id: 'beispiel-freiburg-west',
    name: 'Beispiel-Connector West (kein Track)',
    difficulty: 'S0–S1 · Demo',
    points: [
      GeoPoint(47.97, 7.8),
      GeoPoint(47.975, 7.81),
      GeoPoint(47.98, 7.82),
      GeoPoint(47.985, 7.83),
      GeoPoint(47.99, 7.84),
    ],
  ),
  _TrailSeed(
    id: 'beispiel-mooswald',
    name: 'Beispiel-Connector Mooswald (kein Track)',
    difficulty: 'S1 · Demo',
    points: [
      GeoPoint(48.005, 7.77),
      GeoPoint(48.008, 7.775),
      GeoPoint(48.012, 7.78),
      GeoPoint(48.015, 7.785),
      GeoPoint(48.018, 7.79),
    ],
  ),
];

enum _SheetMode { quick, plan, tours }

enum _PickMode { none, start, end, via }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  MapLibreMapController? _map;
  Symbol? _startSymbol;
  Symbol? _endSymbol;
  Symbol? _ideaSymbol;
  LatLng? _ideaPin;
  List<Symbol> _tfSymbols = [];
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
  bool _showTrails = false;

  List<_RouteSuggestion> _tours = List<_RouteSuggestion>.from(_seedRoutes);
  int? _durationBucket; // 60 / 90 / 120
  String? _surfaceFilter;
  String? _scaleFilter; // S0 / S1 / S2+
  bool? _loopOnly;
  int? _minElevationM;
  bool _heatmapConsent = false;
  bool _heatmapContributed = false;
  String? _elevationSummary;
  List<double> _elevationSamples = const [];
  String? _oaStatus;
  List<_TfPin> _tfPins = [];
  String? _heatmapNote;
  String _mapStyle = AppConfig.mapStyleUrl;
  final _geocode = GeocodeClient();
  final _startAddrCtrl = TextEditingController();
  final _endAddrCtrl = TextEditingController();
  List<GeocodeHit> _addrHits = const [];
  bool _addrBusy = false;
  String? _addrTarget; // 'start' | 'end'
  int _quickGen = 0;
  String? _selectedTourId;

  static const _fallback = GeoPoint(47.99, 7.85);
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
    _fetchTrailforks();
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
    _startAddrCtrl.dispose();
    _endAddrCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String target) async {
    final q = target == 'end' ? _endAddrCtrl.text : _startAddrCtrl.text;
    setState(() {
      _addrBusy = true;
      _addrTarget = target;
      _addrHits = const [];
    });
    try {
      final hits = await _geocode.search(q);
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

  Future<void> _fetchTrailforks() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/trailforks')
          .replace(queryParameters: {'hint': 'dry_likely'});
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
          setState(() => _oaStatus = 'Outdooractive offline — Seeds');
        }
        return;
      }
      final data = jsonDecode(res.body);
      if (data is! Map) return;
      final toursRaw = data['tours'] as List? ?? const [];
      if (toursRaw.isEmpty) return;
      final parsed = <_RouteSuggestion>[];
      for (final raw in toursRaw) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
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
        final difficulty = (m['difficulty'] as String?) ?? 'S1–S2';
        final surface = difficulty.toLowerCase().contains('schwer') ||
                difficulty.toLowerCase().contains('s2')
            ? 'trail/root'
            : 'flow/compact';
        final track = _parseLngLatTrack(m['geometry'] ?? m['track']);
        if (track != null && track.length >= 2 && centerRaw is! List) {
          center = LatLng(track.first[1], track.first[0]);
        }
        final isDemo = m['source'] == 'demo' ||
            data['usingDemoFallback'] == true;
        parsed.add(
          _RouteSuggestion(
            id: id,
            name: title,
            distanceKm: (m['lengthKm'] as num?)?.toDouble() ?? 20,
            elevationM: (m['elevationM'] as num?)?.round() ?? 800,
            durationMin: (m['durationMin'] as num?)?.round() ?? 120,
            mtbScale: difficulty,
            surface: surface,
            loop: true,
            matchScore: track != null ? 88 : 80,
            reasons: [
              if (m['summary'] is String) m['summary'] as String,
              if (track != null)
                'Outdooractive mit Track-Polyline'
              else if (isDemo)
                'Outdooractive Beispiel (kein Live-Detail)'
              else
                'Outdooractive Enrichment (ohne Track — Route berechnen)',
              if (data['attribution'] is String) data['attribution'] as String,
            ],
            center: center,
            trackLngLat: track,
          ),
        );
      }
      if (parsed.isEmpty || !mounted) return;
      setState(() {
        final byId = <String, _RouteSuggestion>{
          for (final s in _seedRoutes) s.id: s,
          for (final p in parsed) p.id: p,
        };
        _tours = byId.values.toList();
        final demo = data['usingDemoFallback'] == true ||
            data['configured'] != true ||
            parsed.any((t) => t.reasons.any((r) => r.contains('Beispiel')));
        _oaStatus = demo
            ? 'Outdooractive Beispiel — keine Track-Wahrheit'
            : 'Outdooractive Enrichment';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _oaStatus = 'Outdooractive offline — Seeds');
      }
    }
  }

  Future<void> _refreshElevation(RouteResult? result) async {
    if (result == null || result.coordinates.length < 2) {
      if (!mounted) return;
      setState(() {
        _elevationSummary = null;
        _elevationSamples = const [];
      });
      return;
    }
    final profile = await _elevationClient.fetchForTrack(result.coordinates);
    if (!mounted) return;
    if (profile == null) {
      final approx = (result.distanceM * 0.03).round();
      setState(() {
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
    if (data == null || data['kind'] != 'quick') return;
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

  Future<void> _useDemoOrigin() async {
    const p = _fallback;
    setState(() {
      _userPos = p;
      _start = p;
      _startAddrCtrl.text = 'Ort Freiburg';
      _status = 'Start: Freiburg — Quick/Planen neu berechnen';
    });
    try {
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 11),
      );
    } catch (_) {}
    if (_mode == _SheetMode.quick) {
      await _refreshQuick(limit: 3);
    } else if (_mode == _SheetMode.plan && _end != null) {
      await _calcAb();
    } else {
      await _syncMarkers();
    }
  }

  Future<void> _locate() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(() => _status = 'Ortungsdienst aus — Start manuell oder Adresse');
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
      // Last-known zuerst — startet keinen Location-Service (ANR-Risiko).
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted) return;
      final p = GeoPoint(pos.latitude, pos.longitude);
      setState(() {
        _userPos = p;
        _start = p;
        _startAddrCtrl.text = 'Meine Position';
        _status =
            'Position ${p.lat.toStringAsFixed(3)}, ${p.lng.toStringAsFixed(3)}';
      });
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 11),
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

  GeoPoint get _origin => _userPos ?? _start ?? _fallback;

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
      if (_durationBucket != null) {
        final delta = (r.durationMin - _durationBucket!).abs();
        if (delta > 45) return false;
      } else {
        final delta = (r.durationMin - _minutes).abs();
        if (delta > 90) return false;
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

    if (cat == null) return base;
    final matched = base.where((r) => r.categories.contains(cat)).toList();
    return matched.isNotEmpty ? matched : base;
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

  Future<void> _attachTrail(_TrailSeed trail, {required bool asVia}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entry = trail.points.first;
      final exit = trail.points.last;
      final mid = trail.points[trail.points.length ~/ 2];
      if (asVia) {
        setState(() {
          _start ??= _origin;
          _vias
            ..clear()
            ..addAll([entry, mid, exit]);
          _end ??= exit;
          _pick = _PickMode.none;
          _mode = _SheetMode.plan;
        });
        await _calcAb();
        return;
      }
      final approach = await _routes.planRoute(
        from: _origin,
        to: entry,
        profile: _profile,
      );
      final merged = RouteResult(
        coordinates: [...approach.coordinates, ...trail.points],
        distanceM: approach.distanceM + trail.points.length * 200.0,
        durationS: approach.durationS + trail.points.length * 40.0,
        engine: '${approach.engine ?? 'engine'}+trail',
        steps: approach.steps,
      );
      if (!mounted) return;
      setState(() {
        _approach = approach;
        _trailOverlay = trail.points;
        _computed = merged;
        _label = '${trail.name} (angehängt)';
        _start = _origin;
        _end = exit;
      });
      await _drawAll();
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
        // Heuristik: |lng| typically > |lat| in DACH → [lng,lat]
        if (a.abs() <= 90 && b.abs() > 90) {
          out.add([b, a]);
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
    for (final r in _seedRoutes) {
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
    if (c == null) return;
    try {
      await c.clearLines();
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
      if (_showTrails) {
        for (final trail in _seedTrails) {
          await c.addLine(
            LineOptions(
              geometry:
                  trail.points.map((p) => LatLng(p.lat, p.lng)).toList(),
              lineColor: '#B0BEC5',
              lineWidth: 2.5,
              lineOpacity: 0.55,
            ),
          );
        }
      }
      if (_approach != null && _approach!.coordinates.length >= 2) {
        await c.addLine(
          LineOptions(
            geometry: _approach!.coordinates
                .map((p) => LatLng(p.lat, p.lng))
                .toList(),
            lineColor: '#66BB6A',
            lineWidth: 4,
          ),
        );
      }
      if (_tourLayer != null && _tourLayer!.coordinates.length >= 2) {
        final approx = (_tourLayer!.engine ?? '').contains('demo');
        await c.addLine(
          LineOptions(
            geometry: _tourLayer!.coordinates
                .map((p) => LatLng(p.lat, p.lng))
                .toList(),
            lineColor: approx ? '#9E9E9E' : '#AB47BC',
            lineWidth: approx ? 3 : 4,
            lineOpacity: approx ? 0.55 : 1.0,
          ),
        );
      }
      if (_trailOverlay != null && _trailOverlay!.length >= 2) {
        await c.addLine(
          LineOptions(
            geometry:
                _trailOverlay!.map((p) => LatLng(p.lat, p.lng)).toList(),
            lineColor: '#FF6B35',
            lineWidth: 4,
          ),
        );
      }
      for (final q in _quick) {
        if (q.label == _label) continue;
        if (q.result.coordinates.length < 2) continue;
        await c.addLine(
          LineOptions(
            geometry: q.result.coordinates
                .map((p) => LatLng(p.lat, p.lng))
                .toList(),
            lineColor: '#90A4AE',
            lineWidth: 5,
            lineOpacity: 0.6,
          ),
          {'kind': 'quick', 'id': q.id, 'label': q.label},
        );
      }
      if (_computed != null && _computed!.coordinates.length >= 2) {
        final eng = _computed!.engine ?? '';
        final approx =
            eng.contains('demo') || eng.contains('fallback');
        final line = _computed!.coordinates
            .map((p) => LatLng(p.lat, p.lng))
            .toList();
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: approx ? '#78909C' : '#4FC3F7',
            lineWidth: approx ? 3.5 : 5,
            lineOpacity: approx ? 0.65 : 1.0,
          ),
          {
            'kind': 'active',
            'approx': approx,
            if (_label != null) 'label': _label,
          },
        );
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                line.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
                line.map((e) => e.longitude).reduce((a, b) => a < b ? a : b),
              ),
              northeast: LatLng(
                line.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
                line.map((e) => e.longitude).reduce((a, b) => a > b ? a : b),
              ),
            ),
            left: 40,
            top: 40,
            right: 40,
            bottom: 120,
          ),
        );
      }
      await _syncMarkers();
    } catch (_) {}
  }

  Future<void> _drawRoute(RouteResult result) async {
    setState(() => _computed = result);
    await _drawAll();
    await _refreshElevation(result);
  }

  Future<void> _syncMarkers() async {
    final c = _map;
    if (c == null) return;
    try {
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
      if (_ideaPin != null) {
        _ideaSymbol = await c.addSymbol(
          SymbolOptions(
            geometry: _ideaPin!,
            iconImage: 'marker-15',
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
            iconImage: 'marker-15',
            textField: 'S',
            textOffset: const Offset(0, 1.2),
          ),
        );
      }
      if (_end != null) {
        _endSymbol = await c.addSymbol(
          SymbolOptions(
            geometry: LatLng(_end!.lat, _end!.lng),
            iconImage: 'marker-15',
            textField: 'Z',
            textOffset: const Offset(0, 1.2),
          ),
        );
      }
      for (final pin in _tfPins.take(12)) {
        final sym = await c.addSymbol(
          SymbolOptions(
            geometry: pin.center,
            iconImage: 'marker-15',
            textField: 'TF',
            textSize: 11,
            textOffset: const Offset(0, 1.2),
          ),
        );
        _tfSymbols.add(sym);
        _tfBySymbolId[sym.id] = pin;
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
          xml = String.fromCharCodes(bytes);
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
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const OfflineMapsSheet(),
                              );
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
                  if (_mode == _SheetMode.tours && _oaStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _oaStatus!,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                  if (_mode == _SheetMode.tours && _heatmapConsent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _heatmapNote ??
                            'Heatmap aktiv (lokal + Community k≥5 wenn Backend)',
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
                        onTap: () => openPrivacyScreen(context),
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
                  styleString: style,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_origin.lat, _origin.lng),
                    zoom: 11,
                  ),
                  onMapCreated: (c) async {
                    _map = c;
                    c.onSymbolTapped.add(_onTfSymbolTapped);
                    c.onLineTapped.add(_onQuickLineTapped);
                    await _drawAll();
                  },
                  onMapClick: (point, latLng) async {
                    if (_mode != _SheetMode.plan) return;
                    final p = GeoPoint(latLng.latitude, latLng.longitude);
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
                        ? (_ideaPin != null ? 380 : 320)
                        : 240,
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
            color: selected ? AppColors.accent : AppColors.sunSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.muted,
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
                        _end == null && ideaTour != null
                            ? 'Route berechnen'
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
                  child: TextField(
                    controller: _startAddrCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start-Adresse',
                      hintText: 'z. B. Freiburg Hbf',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress('start'),
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
                  child: TextField(
                    controller: _endAddrCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ziel-Adresse',
                      hintText: 'z. B. Kirchzarten',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress('end'),
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
                  label: const Text('Ort Freiburg'),
                  onPressed: () => unawaited(_useDemoOrigin()),
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
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                const Text(
                  'Beispiel-Connectoren',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Switch(
                  value: _showTrails,
                  onChanged: (v) async {
                    setState(() => _showTrails = v);
                    await _drawAll();
                  },
                ),
              ],
            ),
            if (_showTrails)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Graue 5-Punkt-Linien — kein OSM-/Partner-Track.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ..._seedTrails.map(
              (tr) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(tr.difficulty, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _attachTrail(tr, asVia: false),
                            child: const Text('Anhängen'),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _attachTrail(tr, asVia: true),
                            child: const Text('Als Via'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                        onTap: () => setState(() => _detailId = r.id),
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
                                label: const Text('Route berechnen'),
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
                                    _demoTile(p.title),
                              ),
                            );
                          }
                          return _demoTile(p.title);
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
