import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ),
  _RouteSuggestion(
    id: 'r-kitz-gravel',
    name: 'Gravel Loop Kitzbühel',
    distanceKm: 62.1,
    elevationM: 890,
    durationMin: 180,
    mtbScale: '—',
    surface: 'gravel/asphalt',
    loop: true,
    matchScore: 74,
    reasons: [
      'Gravel/Asphalt für Ausdauerfenster',
      'Machbar in ~3 h',
      'Rundkurs mit moderatem Climb',
    ],
  ),
];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  MapLibreMapController? _map;
  RouteResult? _route;
  String? _error;
  bool _loading = false;
  RoutingProfile _profile = RoutingProfile.mtbTrail;
  int _minutes = 150;
  bool _loopOnly = false;
  final Set<String> _saved = {};
  String? _detailId;

  static const _from = GeoPoint(47.99, 7.85);
  static const _to = GeoPoint(47.95, 7.92);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<_RouteSuggestion> get _filtered {
    return _seedRoutes.where((r) {
      if (_loopOnly && !r.loop) return false;
      final delta = (r.durationMin - _minutes).abs();
      return delta <= 90;
    }).toList();
  }

  Future<void> _calcRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await RoutingClient().requestRoute(
        from: _from,
        to: _to,
        profile: _profile,
      );
      setState(() => _route = result);
      await _drawRoute(result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
          lineColor: '#E07A3D',
          lineWidth: 4,
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
          bottom: 40,
        ),
      );
    } catch (_) {}
  }

  void _startRide({_RouteSuggestion? suggestion}) {
    final s = suggestion;
    final engine = _route;
    if (s != null) {
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: s.id,
        name: s.name,
        distanceKm: s.distanceKm,
        elevationM: s.elevationM.toDouble(),
        durationMin: s.durationMin,
        mtbScale: s.mtbScale,
        coordinates: engine?.coordinates
                .map((p) => [p.lng, p.lat])
                .toList() ??
            const [],
        steps: engine?.steps
                .map(
                  (st) => NavStep(
                    id: st.id,
                    instruction: st.instruction,
                    distanceAlongM: st.distanceAlongM,
                  ),
                )
                .toList() ??
            const [],
      );
    } else if (engine != null) {
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: 'engine-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Berechnete Route',
        distanceKm: engine.distanceM / 1000,
        elevationM: engine.distanceM * 0.03,
        durationMin: (engine.durationS / 60).round(),
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
    }
    ref.read(shellTabIndexProvider.notifier).state = 2;
  }

  @override
  Widget build(BuildContext context) {
    final style = AppConfig.pmtilesUrl.isNotEmpty
        ? 'https://demotiles.maplibre.org/style.json'
        : 'https://demotiles.maplibre.org/style.json';

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
              '${detail.distanceKm} km · ${detail.elevationM} hm · ${detail.durationMin} min · ${detail.mtbScale}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${detail.matchScore}% Match · ${detail.loop ? 'Rundkurs' : 'A→B'} · ${detail.surface}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            ...detail.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· '),
                    Expanded(child: Text(r)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () => _startRide(suggestion: detail),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Losfahren'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Vorschläge'),
            Tab(text: 'Karte'),
            Tab(text: 'Gespeichert'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildSuggestions(),
          _buildMap(style),
          _buildSaved(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final list = _filtered;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Zeitfenster: $_minutes min',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: _minutes.toDouble(),
          min: 45,
          max: 300,
          divisions: 17,
          label: '$_minutes min',
          onChanged: (v) => setState(() => _minutes = v.round()),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Rundkurs'),
              selected: _loopOnly,
              onSelected: (v) => setState(() => _loopOnly = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Text('Keine Touren mit diesen Filtern.')
        else
          ...list.map(_routeTile),
      ],
    );
  }

  Widget _routeTile(_RouteSuggestion r) {
    final saved = _saved.contains(r.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _detailId = r.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${r.matchScore}%',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${r.distanceKm} km · ${r.elevationM} hm · ${r.durationMin} min · ${r.mtbScale}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Weil: ${r.reasons.take(2).join(' — ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      if (saved) {
                        _saved.remove(r.id);
                      } else {
                        _saved.add(r.id);
                      }
                    }),
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      onPressed: _startRide,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Losfahren'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(String style) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RoutingProfile>(
                  initialValue: _profile,
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
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: _loading ? null : _calcRoute,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Planen'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        if (_route != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${(_route!.distanceM / 1000).toStringAsFixed(1)} km · '
              '${(_route!.durationS / 60).toStringAsFixed(0)} min',
            ),
          ),
        Expanded(
          child: MapLibreMap(
            styleString: style,
            initialCameraPosition: const CameraPosition(
              target: LatLng(47.97, 7.88),
              zoom: 11,
            ),
            onMapCreated: (c) => _map = c,
          ),
        ),
      ],
    );
  }

  Widget _buildSaved() {
    final saved = _seedRoutes.where((r) => _saved.contains(r.id)).toList();
    if (saved.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Noch keine gespeicherten Touren. Speichere Vorschläge mit dem Lesezeichen.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: saved.map(_routeTile).toList(),
    );
  }
}
