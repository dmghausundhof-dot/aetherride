import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/active_route.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';

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

class _SavedEntry {
  const _SavedEntry({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    required this.durationMin,
    required this.coordinates,
  });
  final String id;
  final String name;
  final double distanceKm;
  final double elevationM;
  final int durationMin;
  final List<List<double>> coordinates;
}

enum _SheetMode { quick, plan, tours }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  MapLibreMapController? _map;
  Symbol? _startSymbol;
  Symbol? _endSymbol;

  _SheetMode _mode = _SheetMode.quick;
  RoutingProfile _profile = RoutingProfile.mtbTrail;
  int _minutes = 90;
  bool _loading = false;
  String? _error;
  String? _status;

  GeoPoint? _userPos;
  GeoPoint? _start;
  GeoPoint? _end;
  bool _pickEnd = false;

  RouteResult? _computed;
  String? _label;
  List<_QuickOption> _quick = [];
  final List<_SavedEntry> _saved = [];
  String? _detailId;

  static const _fallback = GeoPoint(47.99, 7.85);

  @override
  void initState() {
    super.initState();
    _locate();
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
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
    return _seedRoutes.where((r) {
      final delta = (r.durationMin - _minutes).abs();
      return delta <= 90;
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

  Future<void> _refreshQuick() async {
    setState(() {
      _loading = true;
      _error = null;
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
    final client = RoutingClient();
    for (var i = 0; i < dests.length; i++) {
      try {
        final result = await client.requestRoute(
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
      } catch (_) {}
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
    if (out.isNotEmpty) await _drawRoute(out.first.result);
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
      final result = await RoutingClient().requestRoute(
        from: from,
        to: to,
        profile: _profile,
      );
      if (!mounted) return;
      setState(() {
        _computed = result;
        _label = 'Geplante Route';
      });
      await _drawRoute(result);
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
      final approach = await RoutingClient().requestRoute(
        from: _origin,
        to: entry,
        profile: _profile,
      );
      // Append a simple diamond around tour center as track stand-in
      final track = _demoLoop(tour.center, tour.distanceKm);
      final coords = [
        ...approach.coordinates,
        ...track,
      ];
      final merged = RouteResult(
        coordinates: coords,
        distanceM: approach.distanceM + tour.distanceKm * 1000,
        durationS: approach.durationS + tour.durationMin * 60,
        engine: '${approach.engine ?? 'engine'}+tour',
        steps: approach.steps,
      );
      if (!mounted) return;
      setState(() {
        _computed = merged;
        _label = '${tour.name} (von hier)';
        _start = _origin;
        _end = entry;
        _status =
            'Hybrid · ${(merged.distanceM / 1000).toStringAsFixed(1)} km';
        _mode = _SheetMode.tours;
      });
      await _drawRoute(merged);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<GeoPoint> _demoLoop(LatLng center, double distanceKm) {
    final half = 0.01 + (distanceKm / 180) * 0.035;
    final pts = <GeoPoint>[
      GeoPoint(center.latitude - half * 0.7, center.longitude - half),
      GeoPoint(center.latitude - half * 0.7, center.longitude + half),
      GeoPoint(center.latitude + half * 0.7, center.longitude + half),
      GeoPoint(center.latitude + half * 0.7, center.longitude - half),
      GeoPoint(center.latitude - half * 0.7, center.longitude - half),
    ];
    return pts;
  }

  Future<void> _drawRoute(RouteResult result) async {
    final c = _map;
    if (c == null || result.coordinates.isEmpty) return;
    final line = result.coordinates.map((p) => LatLng(p.lat, p.lng)).toList();
    try {
      await c.clearLines();
      await c.addLine(
        LineOptions(
          geometry: line,
          lineColor: '#4FC3F7',
          lineWidth: 4.5,
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
      await _syncMarkers();
    } catch (_) {}
  }

  Future<void> _syncMarkers() async {
    final c = _map;
    if (c == null) return;
    try {
      if (_startSymbol != null) await c.removeSymbol(_startSymbol!);
      if (_endSymbol != null) await c.removeSymbol(_endSymbol!);
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
    } catch (_) {}
  }

  void _startRide({_RouteSuggestion? suggestion}) {
    final engine = _computed;
    if (suggestion != null && engine == null) {
      final loop = _demoLoop(suggestion.center, suggestion.distanceKm);
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

  void _saveCurrent() {
    final r = _computed;
    if (r == null) return;
    setState(() {
      _saved.insert(
        0,
        _SavedEntry(
          id: 'saved-${DateTime.now().millisecondsSinceEpoch}',
          name: _label ?? 'Gespeicherte Route',
          distanceKm: r.distanceM / 1000,
          elevationM: r.distanceM * 0.03,
          durationMin: (r.durationS / 60).round(),
          coordinates: r.coordinates.map((p) => [p.lng, p.lat]).toList(),
        ),
      );
      _status = 'Gespeichert';
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = AppConfig.mapStyleUrl;
    final detail = _detailId == null
        ? null
        : _seedRoutes.cast<_RouteSuggestion?>().firstWhere(
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
                        tooltip: 'Meine Position',
                        onPressed: _locate,
                        icon: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
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
                    onChanged: (v) => setState(() => _minutes = v.round()),
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
                    if (_computed != null) await _drawRoute(_computed!);
                  },
                  onMapClick: (point, latLng) async {
                    if (_mode != _SheetMode.plan) return;
                    final p = GeoPoint(latLng.latitude, latLng.longitude);
                    setState(() {
                      if (_pickEnd || _start != null) {
                        _end = p;
                        _pickEnd = false;
                      } else {
                        _start = p;
                        _pickEnd = true;
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
                                '${(_computed!.durationS / 60).round()} min',
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
              _pickEnd
                  ? 'Tippe auf die Karte fürs Ziel'
                  : 'Tippe auf die Karte für Start, dann Ziel',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Start: ${_start != null ? '${_start!.lat.toStringAsFixed(3)}, ${_start!.lng.toStringAsFixed(3)}' : '—'}',
            ),
            Text(
              'Ziel: ${_end != null ? '${_end!.lat.toStringAsFixed(3)}, ${_end!.lng.toStringAsFixed(3)}' : '—'}',
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final u = _userPos;
                if (u != null) {
                  setState(() {
                    _start = u;
                    _pickEnd = true;
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final loop = _demoLoop(r.center, r.distanceKm);
                              final fake = RouteResult(
                                coordinates: loop,
                                distanceM: r.distanceKm * 1000,
                                durationS: r.durationMin * 60.0,
                                engine: 'tour-adopt',
                              );
                              setState(() {
                                _computed = fake;
                                _label = r.name;
                              });
                              await _drawRoute(fake);
                            },
                            child: const Text('Vorschau'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                _loading ? null : () => _hybridSnap(r),
                            child: const Text('Von hier'),
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
            if (_saved.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Gespeichert',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              ..._saved.map(
                (s) => ListTile(
                  dense: true,
                  title: Text(s.name),
                  subtitle: Text(
                    '${s.distanceKm.toStringAsFixed(1)} km · ${s.durationMin} min',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      ref.read(activeRouteProvider.notifier).state =
                          ActiveRoute(
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
                ),
              ),
            ],
          ],
        );
    }
  }
}
