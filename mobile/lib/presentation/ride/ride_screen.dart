import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/active_route.dart';
import '../../domain/ble.dart';
import '../../domain/ride.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/sensor.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../post_ride/post_ride_screen.dart';

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
  final List<TrackPoint> _track = [];
  double _peakG = 1;
  double _flowSum = 0;
  int _flowN = 0;

  String? _rideId;
  bool _rawUploadConsent = false;
  final List<SensorBlock> _chunkBuf = [];
  int _chunkSeq = 0;
  static const _chunkEvery = 30;

  final FlutterTts _tts = FlutterTts();
  bool _ttsMuted = false;
  String? _lastSpokenCueId;
  String? _lastSpokenText;
  String? _lastSpokenPhase;

  @override
  void initState() {
    super.initState();
    unawaited(_tts.setLanguage('de-DE'));
    unawaited(_tts.setSpeechRate(0.5));
  }

  /// Speak nav banner at ~80 m (near) and once when remaining first enters range.
  void _maybeSpeakNav(NavCue cue, int remainingM) {
    if (_ttsMuted || !ref.read(isRidingProvider)) return;
    final near = remainingM <= 80;
    final approach = remainingM <= 300;
    if (!near && !approach) return;
    final phase = near ? 'near' : 'approach';
    final text = cueBannerText(cue, remainingM);
    if (_lastSpokenCueId == cue.id &&
        (_lastSpokenPhase == phase || _lastSpokenText == text)) {
      return;
    }
    _lastSpokenCueId = cue.id;
    _lastSpokenText = text;
    _lastSpokenPhase = phase;
    unawaited(_tts.speak(text));
  }

  void _considerNavTts() {
    final route = ref.read(activeRouteProvider);
    if (route == null || route.coordinates.length < 4) return;
    final cues = buildNavCues(route.coordinates);
    final nxt = nextCue(cues, ref.read(rideDistanceMProvider));
    if (nxt != null) _maybeSpeakNav(nxt.cue, nxt.remainingM);
  }


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

  Future<void> _flushChunk({bool force = false}) async {
    if (!_rawUploadConsent || _rideId == null) {
      _chunkBuf.clear();
      return;
    }
    if (!force && _chunkBuf.length < _chunkEvery) return;
    if (_chunkBuf.isEmpty) return;
    final blocks = List<SensorBlock>.from(_chunkBuf);
    _chunkBuf.clear();
    final seq = _chunkSeq++;
    final rideId = _rideId!;
    try {
      await ref.read(rideChunkRepositoryProvider).appendChunk(
            rideId: rideId,
            seq: seq,
            blocks: blocks,
          );
    } catch (_) {
      // Keep ride UI light — chunk write failures are non-fatal.
    }
  }

  Future<void> _start() async {
    final sensor = ref.read(sensorCoreProvider);
    final ble = ref.read(bleCoreProvider);
    final location = ref.read(locationCoreProvider);
    final consents = await ref.read(garageRepositoryProvider).listConsents();
    _rawUploadConsent = consents['raw_data_upload'] == true;
    _rideId = const Uuid().v4();
    _chunkBuf.clear();
    _chunkSeq = 0;

    await sensor.start();
    await ble.connect();
    await location.startRideTracking();
    _usingGps = location.lastFix != null;
    _locSub = location.fixes.listen((fix) {
      if (!mounted || ref.read(isPausedProvider)) return;
      _usingGps = true;
      ref.read(rideDistanceMProvider.notifier).state = location.distanceM;
      _track.add(
        TrackPoint(
          lat: fix.lat,
          lng: fix.lng,
          timeMs: fix.timestamp.millisecondsSinceEpoch,
          elev: fix.altitudeM,
        ),
      );
      _considerNavTts();
    });
    _sensorSub = sensor.blocks.listen((b) {
      final fused = b.fused;
      if (fused == null) return;
      if (mounted) setState(() => _metrics = fused);
      if (fused.gForcePeak > _peakG) _peakG = fused.gForcePeak;
      _flowSum += fused.flowContribution;
      _flowN += 1;
      if (_rawUploadConsent) {
        _chunkBuf.add(b);
        if (_chunkBuf.length >= _chunkEvery) {
          unawaited(_flushChunk());
        }
      }
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
      _considerNavTts();
    });
    _bumpIdle();
    setState(() {
      _confirmStop = 0;
      _lastSpokenCueId = null;
      _lastSpokenText = null;
      _lastSpokenPhase = null;
    });
  }

  Future<void> _stop() async {
    if (_confirmStop == 0) {
      setState(() => _confirmStop = 1);
      return;
    }
    await _flushChunk(force: true);
    await _sensorSub?.cancel();
    await _bleSub?.cancel();
    await _locSub?.cancel();
    _tick?.cancel();
    _idleLock?.cancel();
    await ref.read(sensorCoreProvider).stop();
    await ref.read(bleCoreProvider).disconnect();
    await ref.read(locationCoreProvider).stopRideTracking();

    final started = _startedAt ?? DateTime.now();
    final ended = DateTime.now();
    final distanceM = ref.read(rideDistanceMProvider);
    final elapsed = ref.read(rideElapsedSecProvider);
    final route = ref.read(activeRouteProvider);
    final bike = await ref.read(garageRepositoryProvider).getActiveBike();
    final bikeId = bike?.id ?? 'unknown';

    // Fallback-Track wenn kein GPS: synthetische Punkte entlang Distanz
    var track = List<TrackPoint>.from(_track);
    if (track.length < 2 && distanceM > 10) {
      final steps = (elapsed.clamp(2, 120));
      for (var i = 0; i < steps; i++) {
        track.add(
          TrackPoint(
            lat: 47.99 + i * 0.0001,
            lng: 7.85 + i * 0.00012,
            timeMs: started.millisecondsSinceEpoch + i * 1000,
          ),
        );
      }
    }

    final record = await ref.read(rideRepositoryProvider).endRide(
          id: _rideId,
          bikeId: bikeId,
          startedAt: started,
          endedAt: ended,
          distanceKm: distanceM / 1000,
          movingTimeSec: elapsed,
          name: route?.name ?? 'Ride',
          routeId: route?.id,
          elevationM: route?.elevationM ?? distanceM * 0.03,
          track: track,
          summary: {
            'peakG': _peakG,
            'avgFlow': _flowN == 0 ? null : _flowSum / _flowN,
            'usingGps': _usingGps,
            if (_ldi != null) 'soc': _ldi!.batterySocPercent,
          },
        );

    ref.read(isRidingProvider.notifier).state = false;
    ref.read(isPausedProvider.notifier).state = false;
    ref.read(autoLockedProvider.notifier).state = false;
    ref.read(activeRouteProvider.notifier).state = null;
    ref.read(rideElapsedSecProvider.notifier).state = 0;
    ref.read(rideDistanceMProvider.notifier).state = 0;
    ref.invalidate(bikesProvider);
    ref.invalidate(recentRidesProvider);
    setState(() {
      _confirmStop = 0;
      _metrics = null;
      _usingGps = false;
      _track.clear();
      _peakG = 1;
      _flowSum = 0;
      _flowN = 0;
      _rideId = null;
      _rawUploadConsent = false;
      _chunkBuf.clear();
      _chunkSeq = 0;
    });

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostRideScreen(rideId: record.id),
      ),
    );
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _bleSub?.cancel();
    _locSub?.cancel();
    _tick?.cancel();
    _idleLock?.cancel();
    unawaited(_tts.stop());
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
              tooltip: _ttsMuted ? 'TTS an' : 'TTS stumm',
              onPressed: () {
                setState(() => _ttsMuted = !_ttsMuted);
                if (_ttsMuted) unawaited(_tts.stop());
              },
              icon: Icon(
                _ttsMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              ),
            ),
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
                    if (route != null) ...[
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
                      ),
                      if (riding && route.coordinates.length >= 4)
                        Builder(
                          builder: (context) {
                            final cues = buildNavCues(route.coordinates);
                            final nxt = nextCue(cues, distanceM);
                            if (nxt == null) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                cueBannerText(nxt.cue, nxt.remainingM),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                    ] else if (!riding)
                      const Text(
                        'Optional: Route in Discover wählen und „Losfahren“.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    if (!riding) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Geschwindigkeit: Standard-BLE CSC. '
                        'E-Bike Live (Bosch LDI) folgt (G-1).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
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
                            (_ldi?.speedKmh ?? 0).toStringAsFixed(0),
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
