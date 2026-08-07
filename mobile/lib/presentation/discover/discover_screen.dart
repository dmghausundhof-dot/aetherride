import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/elevation_client.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/active_route.dart';
import '../../domain/routing/heatmap.dart';
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
}

const _seedRoutes = <_RouteSuggestion>[
  _RouteSuggestion(
    id: 'r-soell-flow',
    name: 'Flow Trail Söll',
    distanceKm: 18.7,
    elevationM: 720,
    durationMin: 95,
    mtbScale: 'S1–S2',
    surface: 'flow/compact',
    loop: true,
    matchScore: 92,
    reasons: [
      'Passt zu Trail-/Enduro-Setups',
      'Flow-Charakter matched typisches Profil',
      'Dauer ~95 min im Wochenendfenster',
    ],
    center: LatLng(47.505, 12.192),
  ),
  _RouteSuggestion(
    id: 'r-alpbach-enduro',
    name: 'Enduro Alpbachtal',
    distanceKm: 28.4,
    elevationM: 1240,
    durationMin: 150,
    mtbScale: 'S2–S3',
    surface: 'trail/root',
    loop: true,
    matchScore: 88,
    reasons: [
      'Technisch wie von Enduro-Fahrern bevorzugt',
      'Steile Abschnitte (~1240 hm)',
      'Rundkurs · machbar in ~2:30 h',
    ],
    center: LatLng(47.399, 11.944),
  ),
  _RouteSuggestion(
    id: 'r-kaltenbronn',
    name: 'Kaltenbronn Runde',
    distanceKm: 34,
    elevationM: 980,
    durationMin: 160,
    mtbScale: 'S1–S2',
    surface: 'trail/root',
    loop: true,
    matchScore: 85,
    reasons: [
      'Schwarzwald-Klassiker',
      'Flow + moderate Technik',
      'Rundkurs fürs Wochenende',
    ],
    center: LatLng(48.642, 8.425),
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

const _seedTrails = <_TrailSeed>[
  _TrailSeed(
    id: 'trail-freiburg-west',
    name: 'Freiburg West Connector',
    difficulty: 'S0–S1',
    points: [
      GeoPoint(47.97, 7.8),
      GeoPoint(47.975, 7.81),
      GeoPoint(47.98, 7.82),
      GeoPoint(47.985, 7.83),
      GeoPoint(47.99, 7.84),
    ],
  ),
  _TrailSeed(
    id: 'trail-mooswald',
    name: 'Mooswald Singletrack',
    difficulty: 'S1',
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
  bool _showTrails = true;

  List<_RouteSuggestion> _tours = List<_RouteSuggestion>.from(_seedRoutes);
  int? _durationBucket; // 60 / 90 / 120
  String? _surfaceFilter;
  String? _scaleFilter; // S0 / S1 / S2+
  bool? _loopOnly;
  int? _minElevationM;
  bool _heatmapConsent = false;
  String? _elevationSummary;
  List<double> _elevationSamples = const [];
  String? _oaStatus;
  List<_TfPin> _tfPins = [];
  String? _heatmapNote;

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
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/outdooractive')
          .replace(queryParameters: {'type': 'tour'});
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
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
        LatLng center = const LatLng(47.5, 11.5);
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
            matchScore: 80,
            reasons: [
              if (m['summary'] is String) m['summary'] as String,
              'Outdooractive Enrichment',
              if (data['attribution'] is String) data['attribution'] as String,
            ],
            center: center,
          ),
        );
      }
      if (parsed.isEmpty || !mounted) return;
      setState(() {
        _tours = parsed;
        _oaStatus = data['configured'] == true
            ? 'Outdooractive'
            : 'Outdooractive Demo';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _oaStatus = 'Outdooractive offline — Seeds');
      }
    }
  }

  Future<void> _refreshElevation(RouteResult? result) async {
    if (result == null || result.coordinates.length < 2) {
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
        _elevationSummary = '~$approx hm (geschätzt)';
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
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
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
      });
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 11),
      );
      if (_mode == _SheetMode.quick) {
        await _refreshQuick();
      }
    } catch (_) {}
  }

  GeoPoint get _origin => _userPos ?? _start ?? _fallback;

  List<_RouteSuggestion> get _filtered {
    return _tours.where((r) {
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
        // Heuristik: längere Touren eher Rundkurse / OA-Touren
        if (r.distanceKm < 8) return false;
      }
      return true;
    }).toList();
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

  Future<void> _refreshQuick({int limit = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
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
    final out = <_QuickOption>[..._quick];
    final max = limit.clamp(1, dests.length);
    for (var i = 0; i < max; i++) {
      if (out.any((o) => o.id == 'quick-$i')) continue;
      if (out.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
      try {
        final result = await _routes.planRoute(
          from: _origin,
          to: dests[i],
          profile: _profile,
        );
        out.add(
          _QuickOption(
            id: 'quick-$i',
            label: labels[i],
            reason: reasons[i],
            result: result,
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('429') || msg.toLowerCase().contains('limit')) {
          if (mounted) {
            setState(() {
              _status =
                  'Routing-Limit — Planer sparsam nutzen oder später erneut.';
            });
          }
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _quick = out;
      _loading = false;
      if (out.isNotEmpty) {
        _computed = out.first.result;
        _label = out.first.label;
        _start = _origin;
        _end = dests.first;
      } else {
        _error = 'Keine Quick-Routen — Planer nutzen.';
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
      });
      await _drawAll();
      await _refreshElevation(result);
    } catch (e) {
      setState(() => _error = e.toString());
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
      setState(() => _error = e.toString());
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
      final track = await _routedTourGeometry(tour.center, tour.distanceKm);
      final merged = RouteResult(
        coordinates: [...approach.coordinates, ...track],
        distanceM: approach.distanceM + tour.distanceKm * 1000,
        durationS: approach.durationS + tour.durationMin * 60,
        engine: '${approach.engine ?? 'engine'}+tour',
        steps: approach.steps,
      );
      if (!mounted) return;
      setState(() {
        _approach = approach;
        _tourLayer = RouteResult(
          coordinates: track,
          distanceM: tour.distanceKm * 1000,
          durationS: tour.durationMin * 60.0,
          engine: 'tour',
        );
        _computed = merged;
        _label = '${tour.name} (von hier)';
        _start = _origin;
        _end = entry;
        _status =
            'Hybrid · ${(merged.distanceM / 1000).toStringAsFixed(1)} km';
        _mode = _SheetMode.tours;
      });
      await _drawAll();
      await _refreshElevation(merged);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Geroutete Rundtour um [center]; Fallback synthetisches Rechteck.
  Future<List<GeoPoint>> _routedTourGeometry(
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
    } catch (_) {}
    if (coords.length >= 4) return coords;
    return _demoLoop(center, distanceKm);
  }

  List<GeoPoint> _demoLoop(LatLng center, double distanceKm) {
    final half = 0.01 + (distanceKm / 180) * 0.035;
    return [
      GeoPoint(center.latitude - half * 0.7, center.longitude - half),
      GeoPoint(center.latitude - half * 0.7, center.longitude + half),
      GeoPoint(center.latitude + half * 0.7, center.longitude + half),
      GeoPoint(center.latitude + half * 0.7, center.longitude - half),
      GeoPoint(center.latitude - half * 0.7, center.longitude - half),
    ];
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
            includeSeedFallback: true,
          );
          if (mounted) {
            setState(() => _heatmapNote = heat.disclaimer);
          }
          for (final seg in heat.visibleSegments) {
            if (seg.coordinatesLngLat.length < 2) continue;
            await c.addLine(
              LineOptions(
                geometry: [
                  for (final p in seg.coordinatesLngLat)
                    LatLng(p[1], p[0]),
                ],
                lineColor: '#FF7043',
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
              lineColor: '#FF6B35',
              lineWidth: 3,
              lineOpacity: 0.7,
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
        await c.addLine(
          LineOptions(
            geometry: _tourLayer!.coordinates
                .map((p) => LatLng(p.lat, p.lng))
                .toList(),
            lineColor: '#AB47BC',
            lineWidth: 4,
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
            lineWidth: 3,
            lineOpacity: 0.45,
          ),
        );
      }
      final result = _computed;
      if (result != null && result.coordinates.length >= 2) {
        final line =
            result.coordinates.map((p) => LatLng(p.lat, p.lng)).toList();
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: '#4FC3F7',
            lineWidth: 5,
            lineOpacity: 0.9,
          ),
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
      for (final s in _tfSymbols) {
        await c.removeSymbol(s);
      }
      _tfSymbols = [];
      _tfBySymbolId.clear();
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
    final engine = _computed;
    if (suggestion != null && engine == null) {
      final loop =
          await _routedTourGeometry(suggestion.center, suggestion.distanceKm);
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: suggestion.id,
        name: suggestion.name,
        distanceKm: suggestion.distanceKm,
        elevationM: suggestion.elevationM.toDouble(),
        durationMin: suggestion.durationMin,
        mtbScale: suggestion.mtbScale,
        coordinates: loop.map((p) => [p.lng, p.lat]).toList(),
      );
    } else if (engine != null) {
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: 'engine-${DateTime.now().millisecondsSinceEpoch}',
        name: _label ?? suggestion?.name ?? 'Berechnete Route',
        distanceKm: engine.distanceM / 1000,
        elevationM: engine.distanceM * 0.03,
        durationMin: (engine.durationS / 60).round(),
        mtbScale: suggestion?.mtbScale,
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
    } else {
      return;
    }
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
    final style = AppConfig.mapStyleUrl;
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
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () => _startRide(suggestion: detail),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Losfahren'),
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
                        tooltip: 'Trail View',
                        onPressed: () => _openTrailView(),
                        icon: const Icon(Icons.streetview),
                      ),
                      IconButton(
                        tooltip: 'Offline-Karten',
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const OfflineMapsSheet(),
                          );
                        },
                        icon: const Icon(Icons.map_outlined),
                      ),
                      IconButton(
                        tooltip: 'Meine Position',
                        onPressed: _locate,
                        icon: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  if (_oaStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _oaStatus!,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                  if (_heatmapConsent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _heatmapNote ?? 'Heatmap aktiv (eigene Rides)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF7043),
                        ),
                      ),
                    )
                  else
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<RoutingProfile>(
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
                            if (p != null) setState(() => _profile = p);
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
                      const SizedBox(width: 10),
                      Text(
                        '$_minutes min',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
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
                    if (_computed != null) await _drawRoute(_computed!);
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
                  },
                ),
                if (_computed != null)
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
                    height: 220,
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
          setState(() => _mode = mode);
          if (mode == _SheetMode.quick) {
            _refreshQuick();
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_mode) {
      case _SheetMode.quick:
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
      case _SheetMode.plan:
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              switch (_pick) {
                _PickMode.via => 'Tippe Via auf die Karte',
                _PickMode.end => 'Tippe Ziel auf die Karte',
                _PickMode.start => 'Tippe Start auf die Karte',
                _ => 'Start / Via / Ziel setzen',
              },
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Start'),
                  onPressed: () => setState(() => _pick = _PickMode.start),
                ),
                ActionChip(
                  label: const Text('+ Via'),
                  onPressed: () => setState(() => _pick = _PickMode.via),
                ),
                ActionChip(
                  label: const Text('Ziel'),
                  onPressed: () => setState(() => _pick = _PickMode.end),
                ),
              ],
            ),
            Text(
              'Start: ${_start != null ? '${_start!.lat.toStringAsFixed(3)}, ${_start!.lng.toStringAsFixed(3)}' : '—'}',
            ),
            ..._vias.asMap().entries.map(
              (e) => Text(
                'Via ${e.key + 1}: ${e.value.lat.toStringAsFixed(3)}, ${e.value.lng.toStringAsFixed(3)}',
              ),
            ),
            Text(
              'Ziel: ${_end != null ? '${_end!.lat.toStringAsFixed(3)}, ${_end!.lng.toStringAsFixed(3)}' : '—'}',
            ),
            TextButton(
              onPressed: () {
                final u = _userPos;
                if (u != null) {
                  setState(() {
                    _start = u;
                    _pick = _PickMode.end;
                  });
                  _syncMarkers();
                } else {
                  _locate();
                }
              },
              child: const Text('Start = meine Position'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _loading ? null : _calcAb,
              child: const Text('Route berechnen'),
            ),
          ],
        );
      case _SheetMode.tours:
        final list = _filtered;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                const Text('Trails', style: TextStyle(fontWeight: FontWeight.w700)),
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
                        child: Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${r.distanceKm} km · ${r.elevationM} hm · ${r.durationMin} min · ${r.matchScore}%',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      Text(
                        r.surface,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final loop = await _routedTourGeometry(
                                r.center,
                                r.distanceKm,
                              );
                              final preview = RouteResult(
                                coordinates: loop,
                                distanceM: r.distanceKm * 1000,
                                durationS: r.durationMin * 60.0,
                                engine: 'tour-routed',
                              );
                              setState(() {
                                _computed = preview;
                                _label = r.name;
                              });
                              await _drawRoute(preview);
                            },
                            child: const Text('Vorschau'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                _loading ? null : () => _hybridSnap(r),
                            child: const Text('Von hier'),
                          ),
                          IconButton(
                            tooltip: 'Trail View',
                            onPressed: () => _openTrailView(near: r.center),
                            icon: const Icon(Icons.streetview, size: 20),
                          ),
                          const Spacer(),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                            ),
                            onPressed: () => _startRide(suggestion: r),
                            child: const Text('Los'),
                          ),
                        ],
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
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFE8F0E9),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
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
