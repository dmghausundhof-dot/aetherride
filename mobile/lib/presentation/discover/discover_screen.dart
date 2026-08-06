import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/routing_client.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  MapLibreMapController? _map;
  RouteResult? _route;
  String? _error;
  bool _loading = false;
  RoutingProfile _profile = RoutingProfile.mtbTrail;

  // Default: Black Forest sample
  static const _from = GeoPoint(47.99, 7.85);
  static const _to = GeoPoint(47.95, 7.92);

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
    final line = result.coordinates
        .map((p) => LatLng(p.lat, p.lng))
        .toList();
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
    } catch (_) {
      // Map style may not be ready
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = AppConfig.pmtilesUrl.isNotEmpty
        ? 'https://demotiles.maplibre.org/style.json'
        : 'https://demotiles.maplibre.org/style.json';

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: Column(
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: _loading ? null : _calcRoute,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Route'),
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
                '${(_route!.durationS / 60).toStringAsFixed(0)} min'
                '${_route!.engine != null ? ' · ${_route!.engine}' : ''}',
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
              myLocationEnabled: false,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Online: /api/route · Offline Valhalla FFI folgt (S7). '
              '© OpenStreetMap',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
