import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/active_route.dart';
import '../../domain/ble.dart';
import '../../domain/sensor.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends ConsumerState<RideScreen> {
  FusedMetrics? _metrics;
  BoschLiveData? _ldi;
  StreamSubscription<SensorBlock>? _sensorSub;
  StreamSubscription<BoschLiveData>? _bleSub;
  StreamSubscription<LocationFix>? _locSub;
  Timer? _tick;
  Timer? _idleLock;
  int _confirmStop = 0;
  DateTime? _startedAt;
  bool _usingGps = false;


  void _bumpIdle() {
    ref.read(autoLockedProvider.notifier).state = false;
    _idleLock?.cancel();
    if (ref.read(isRidingProvider)) {
      _idleLock = Timer(const Duration(seconds: 20), () {
        if (mounted && ref.read(isRidingProvider)) {
          ref.read(autoLockedProvider.notifier).state = true;
        }
      });
    }
  }

  Future<void> _start() async {
    final sensor = ref.read(sensorCoreProvider);
    final ble = ref.read(bleCoreProvider);
    final location = ref.read(locationCoreProvider);
    await sensor.start();
    await ble.connect();
    await location.startRideTracking();
    _usingGps = location.lastFix != null;
    _locSub = location.fixes.listen((_) {
      if (!mounted || ref.read(isPausedProvider)) return;
      _usingGps = true;
      ref.read(rideDistanceMProvider.notifier).state = location.distanceM;
    });
    _sensorSub = sensor.blocks.listen((b) {
      if (mounted) setState(() => _metrics = b.fused);
    });
    _bleSub = ble.liveData.listen((d) {
      if (mounted) setState(() => _ldi = d);
    });
    _startedAt = DateTime.now();
    ref.read(isRidingProvider.notifier).state = true;
    ref.read(isPausedProvider.notifier).state = false;
    ref.read(rideElapsedSecProvider.notifier).state = 0;
    ref.read(rideDistanceMProvider.notifier).state = 0;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ref.read(isPausedProvider)) return;
      final start = _startedAt;
      if (start != null) {
        ref.read(rideElapsedSecProvider.notifier).state =
            DateTime.now().difference(start).inSeconds;
      }
      // Sim-Distanz nur wenn noch kein GPS-Fix
      if (!_usingGps) {
        ref.read(rideDistanceMProvider.notifier).state += 4.2;
      }
    });
    _bumpIdle();
    setState(() => _confirmStop = 0);
  }

  Future<void> _stop() async {
    if (_confirmStop == 0) {
      setState(() => _confirmStop = 1);
      return;
    }
    await _sensorSub?.cancel();
    await _bleSub?.cancel();
    await _locSub?.cancel();
    _tick?.cancel();
    _idleLock?.cancel();
    await ref.read(sensorCoreProvider).stop();
    await ref.read(bleCoreProvider).disconnect();
    await ref.read(locationCoreProvider).stopRideTracking();
    ref.read(isRidingProvider.notifier).state = false;
    ref.read(isPausedProvider.notifier).state = false;
    ref.read(autoLockedProvider.notifier).state = false;
    ref.read(activeRouteProvider.notifier).state = null;
    setState(() {
      _confirmStop = 0;
      _metrics = null;
      _usingGps = false;
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _bleSub?.cancel();
    _locSub?.cancel();
    _tick?.cancel();
    _idleLock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riding = ref.watch(isRidingProvider);
    final paused = ref.watch(isPausedProvider);
    final route = ref.watch(activeRouteProvider);
    final layer = ref.watch(rideLayerProvider);
    final mount = ref.watch(mountCheckProvider);
    final sunlight = ref.watch(sunlightModeProvider);
    final locked = ref.watch(autoLockedProvider);
    final elapsed = ref.watch(rideElapsedSecProvider);
    final distanceM = ref.watch(rideDistanceMProvider);

    final theme = sunlight ? AppTheme.sunlight : Theme.of(context);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(riding ? 'Live' : 'Bereit'),
          actions: [
            IconButton(
              tooltip: 'Sunlight Mode',
              onPressed: () {
                ref.read(sunlightModeProvider.notifier).state = !sunlight;
              },
              icon: Icon(
                Icons.wb_sunny_outlined,
                color: sunlight ? AppColors.sunAccent : null,
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: _bumpIdle,
          onDoubleTap: _bumpIdle,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (route != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.navigation),
                          title: Text(route.name),
                          subtitle: Text(
                            '${route.distanceKm} km · ${route.elevationM.round()} hm'
                            '${route.steps.isNotEmpty ? ' · ${route.steps.length} Manöver' : ''}',
                          ),
                          trailing: riding
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    ref
                                        .read(activeRouteProvider.notifier)
                                        .state = null;
                                  },
                                ),
                        ),
                      )
                    else if (!riding)
                      const Text(
                        'Optional: Route in Discover wählen und „Losfahren“.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    const SizedBox(height: 12),
                    if (!riding) ...[
                      Text('Handy am Lenker?',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: mount == MountCheck.mounted
                                    ? AppColors.accent
                                    : null,
                              ),
                              onPressed: () {
                                ref.read(mountCheckProvider.notifier).state =
                                    MountCheck.mounted;
                              },
                              child: const Text('Ja — Analyse an'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(mountCheckProvider.notifier).state =
                                    MountCheck.handheld;
                              },
                              child: const Text('Nein — nur Track'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (riding) ...[
                      const SizedBox(height: 8),
                      SegmentedButton<RideLiveLayer>(
                        segments: const [
                          ButtonSegment(
                            value: RideLiveLayer.map,
                            label: Text('Karte'),
                            icon: Icon(Icons.map),
                          ),
                          ButtonSegment(
                            value: RideLiveLayer.data,
                            label: Text('Daten'),
                            icon: Icon(Icons.grid_view),
                          ),
                          ButtonSegment(
                            value: RideLiveLayer.suspension,
                            label: Text('Fahrwerk'),
                            icon: Icon(Icons.waves),
                          ),
                        ],
                        selected: {layer},
                        onSelectionChanged: (s) {
                          _bumpIdle();
                          ref.read(rideLayerProvider.notifier).state = s.first;
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildLayer(layer, mount, route)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _bigStat(
                            '${(_ldi?.speedKmh ?? 0).toStringAsFixed(0)}',
                            'km/h',
                          ),
                          _bigStat(
                            (distanceM / 1000).toStringAsFixed(1),
                            'km',
                          ),
                          _bigStat(_fmt(elapsed), 'Zeit'),
                        ],
                      ),
                    ] else
                      const Spacer(),
                    if (_metrics != null &&
                        layer == RideLiveLayer.suspension) ...[
                      _MetricRow(
                        'G-Peak',
                        _metrics!.gForcePeak.toStringAsFixed(2),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (riding)
                          IconButton.filledTonal(
                            onPressed: () {
                              _bumpIdle();
                              ref.read(isPausedProvider.notifier).state =
                                  !paused;
                            },
                            icon: Icon(
                              paused ? Icons.play_arrow : Icons.pause,
                            ),
                          ),
                        if (riding) const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: riding
                                  ? (_confirmStop > 0
                                      ? Colors.red
                                      : Colors.redAccent)
                                  : AppColors.accent,
                              minimumSize: const Size.fromHeight(64),
                            ),
                            onPressed: () async {
                              _bumpIdle();
                              if (riding) {
                                await _stop();
                              } else {
                                await _start();
                              }
                            },
                            child: Text(
                              riding
                                  ? (_confirmStop > 0
                                      ? 'Nochmal tippen'
                                      : 'Stop')
                                  : (route != null
                                      ? '${route.name} starten'
                                      : 'Freifahren starten'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (riding && _confirmStop == 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Beenden erfordert 2 Tipps',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
              if (locked && riding)
                Positioned.fill(
                  child: Material(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
                    child: InkWell(
                      onTap: _bumpIdle,
                      onDoubleTap: _bumpIdle,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 48, color: AppColors.accent),
                          SizedBox(height: 12),
                          Text('Auto-Lock',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Doppeltipp zum Aufwecken'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayer(
    RideLiveLayer layer,
    MountCheck mount,
    ActiveRoute? route,
  ) {
    switch (layer) {
      case RideLiveLayer.map:
        return Card(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                route != null
                    ? 'Route aktiv · ${route.coordinates.length} Punkte\n'
                        '(MapLibre-Layer analog Discover)'
                    : 'Freeride · Track wird aufgezeichnet',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case RideLiveLayer.data:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _MetricRow(
                  'Speed',
                  '${(_ldi?.speedKmh ?? 0).toStringAsFixed(1)} km/h',
                ),
                _MetricRow(
                  'SOC',
                  '${(_ldi?.batterySocPercent ?? 0).toStringAsFixed(0)} %',
                ),
                _MetricRow(
                  'Power',
                  '${(_ldi?.riderPowerW ?? 0).toStringAsFixed(0)} W',
                ),
                _MetricRow(
                  'Cadence',
                  '${(_ldi?.cadenceRpm ?? 0).toStringAsFixed(0)} rpm',
                ),
              ],
            ),
          ),
        );
      case RideLiveLayer.suspension:
        if (mount != MountCheck.mounted) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Fahrwerksanalyse aus',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Handy am Lenker befestigen und als montiert markieren.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      ref.read(mountCheckProvider.notifier).state =
                          MountCheck.mounted;
                    },
                    child: const Text('Als montiert markieren'),
                  ),
                ],
              ),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_metrics != null) ...[
                  _MetricRow(
                    'G-Peak',
                    _metrics!.gForcePeak.toStringAsFixed(2),
                  ),
                  _MetricRow(
                    'Lean °',
                    _metrics!.leanAngleDeg.toStringAsFixed(1),
                  ),
                  _MetricRow(
                    'Flow',
                    _metrics!.flowContribution.toStringAsFixed(2),
                  ),
                ] else
                  const Text('Warte auf Sensorik…'),
              ],
            ),
          ),
        );
    }
  }

  Widget _bigStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
