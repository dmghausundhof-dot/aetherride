import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/ble.dart';
import '../../domain/ride.dart';
import '../../domain/routing/nav_announce.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/route_progress.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/ebike/range.dart';
import '../../domain/sensor.dart';
import '../../domain/sensor/live_hints.dart';
import '../../native/location_core_channel.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../post_ride/post_ride_screen.dart';

/// Lux reading — sensors_plus has no AmbientLightEvent yet; local stand-in.
class AmbientLightEvent {
  const AmbientLightEvent(this.lux);
  final double lux;
}

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends ConsumerState<RideScreen> {
  FusedMetrics? _metrics;
  BoschLiveData? _ldi;
  double _gpsSpeedKmh = 0;
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
  final Set<String> _spokenAnnounceKeys = {};
  String? _lastSpokenText;
  String? _liveHintText;
  int _hardImpactStreak = 0;
  double _standSeconds = 0;
  double _prevPeakG = 0;
  double? _startSoc;

  MapLibreMapController? _rideMap;
  int _mapDrawSkip = 0;
  String _mapStyle = AppConfig.mapStyleUrl;
  bool _offRoute = false;
  String? _offRouteBanner;
  DateTime? _lastAutoRerouteAt;
  bool _autoRerouteBusy = false;
  /// User-Toggle (zusätzlich zu dart-define AETHER_AUTO_REROUTE).
  bool _autoRerouteEnabled = AppConfig.autoReroute;
  /// Distanz entlang Active Route (Nav); Odometer bleibt [rideDistanceMProvider].
  double _alongRouteM = 0;
  int _gpsFixCount = 0;
  String? _gpsStatus;
  double _lastGpsDistanceM = 0;
  int _gpsStallSec = 0;

  static bool get _allowGpsStallSim =>
      kDebugMode ||
      const bool.fromEnvironment('AETHER_SIM_MOTION', defaultValue: false);

  /// When false, light sensor drives [sunlightModeProvider]; manual toggle locks.
  bool _sunlightAuto = true;
  StreamSubscription<AmbientLightEvent>? _lightSub;
  DateTime? _brightSince;
  static const _sunlightLux = 8000.0;
  static const _sunlightHold = Duration(seconds: 4);
  static const _ambientLightChannel = EventChannel('com.aetherride/ambient_light');

  @override
  void initState() {
    super.initState();
    unawaited(_tts.setLanguage('de-DE'));
    unawaited(_tts.setSpeechRate(0.5));
    _startAutoSunlight();
    unawaited(
      AppConfig.resolveMapStyleUrl().then((s) {
        if (mounted) setState(() => _mapStyle = s);
      }),
    );
  }

  /// Auto-Sunlight: lux > 8000 for ~4s → enable; else reset while auto.
  /// sensors_plus is imported for SensorInterval; lux comes from TYPE_LIGHT.
  void _startAutoSunlight() {
    _lightSub?.cancel();
    try {
      _lightSub = _ambientLightChannel
          .receiveBroadcastStream(
            SensorInterval.normalInterval.inMicroseconds,
          )
          .map((raw) {
            final lux = raw is num
                ? raw.toDouble()
                : (raw is List && raw.isNotEmpty)
                    ? (raw.first as num).toDouble()
                    : 0.0;
            return AmbientLightEvent(lux);
          })
          .listen(_onAmbientLight, onError: (_) {});
    } catch (_) {
      // No light sensor — manual toggle only.
    }
  }

  void _onAmbientLight(AmbientLightEvent event) {
    if (!_sunlightAuto || !mounted) return;
    final now = DateTime.now();
    if (event.lux > _sunlightLux) {
      _brightSince ??= now;
      if (now.difference(_brightSince!) >= _sunlightHold) {
        if (!ref.read(sunlightModeProvider)) {
          ref.read(sunlightModeProvider.notifier).state = true;
        }
      }
    } else {
      _brightSince = null;
      if (ref.read(sunlightModeProvider)) {
        ref.read(sunlightModeProvider.notifier).state = false;
      }
    }
  }

  void _toggleSunlightManual() {
    _sunlightAuto = false;
    _brightSince = null;
    final on = ref.read(sunlightModeProvider);
    ref.read(sunlightModeProvider.notifier).state = !on;
  }

  LatLng _mapTarget(ActiveRoute? route) {
    if (_track.isNotEmpty) {
      final p = _track.last;
      return LatLng(p.lat, p.lng);
    }
    if (route != null && route.coordinates.isNotEmpty) {
      final c = route.coordinates.first;
      return LatLng(c[1], c[0]);
    }
    return const LatLng(47.99, 7.85);
  }

  Future<void> _drawRideMap() async {
    final c = _rideMap;
    if (c == null) return;
    try {
      await c.clearLines();
      final route = ref.read(activeRouteProvider);
      if (route != null && route.coordinates.length >= 2) {
        await c.addLine(
          LineOptions(
            geometry: [
              for (final p in route.coordinates) LatLng(p[1], p[0]),
            ],
            lineColor: '#4FC3F7',
            lineWidth: 4,
            lineOpacity: 0.85,
          ),
        );
      }
      if (_track.length >= 2) {
        final line = [for (final p in _track) LatLng(p.lat, p.lng)];
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: '#FF6B35',
            lineWidth: 5,
          ),
        );
        final last = line.last;
        await c.animateCamera(CameraUpdate.newLatLngZoom(last, 15));
      } else if (route != null && route.coordinates.length >= 2) {
        final pts = [
          for (final p in route.coordinates) LatLng(p[1], p[0]),
        ];
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                pts.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
                pts.map((e) => e.longitude).reduce((a, b) => a < b ? a : b),
              ),
              northeast: LatLng(
                pts.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
                pts.map((e) => e.longitude).reduce((a, b) => a > b ? a : b),
              ),
            ),
            left: 28,
            top: 28,
            right: 28,
            bottom: 28,
          ),
        );
      }
    } catch (_) {}
  }


  /// LDI-Speed, sonst GPS (Freeride ohne CSC).
  double get _effectiveSpeedKmh {
    final ldi = _ldi?.speedKmh;
    if (ldi != null && ldi > 0.5) return ldi;
    return _gpsSpeedKmh;
  }

  /// Engine-Steps (400/150/30) bevorzugt; sonst Bearing-Cues als Fallback.
  void _maybeSpeakNav(NavCue cue, int remainingM) {
    if (_ttsMuted || !ref.read(isRidingProvider)) return;
    final speed = _effectiveSpeedKmh;
    final text = pickAnnounce(
      stepId: cue.id,
      instruction: cue.instruction,
      isArrive: cue.instruction == 'Ziel erreicht',
      remainingM: remainingM.toDouble(),
      speedKmh: speed,
      spoken: _spokenAnnounceKeys,
    );
    if (text == null) return;
    if (_lastSpokenText == text) return;
    _lastSpokenText = text;
    unawaited(_tts.speak(text));
  }

  void _considerNavTts() {
    final route = ref.read(activeRouteProvider);
    if (route == null || route.coordinates.length < 4) return;
    final along = _alongRouteM;
    final speed = _effectiveSpeedKmh;

    if (route.steps.isNotEmpty) {
      final nxt = nextRouteStep(route.steps, along);
      if (nxt != null) {
        final text = pickAnnounce(
          stepId: nxt.step.id,
          instruction: nxt.step.instruction,
          isArrive: nxt.step.instruction.toLowerCase().contains('ziel'),
          remainingM: nxt.remainingM,
          speedKmh: speed,
          spoken: _spokenAnnounceKeys,
        );
        if (text != null &&
            !_ttsMuted &&
            ref.read(isRidingProvider) &&
            _lastSpokenText != text) {
          _lastSpokenText = text;
          unawaited(_tts.speak(text));
        }
        return;
      }
    }

    final cues = buildNavCues(route.coordinates);
    final nxt = nextCue(cues, along);
    if (nxt != null) _maybeSpeakNav(nxt.cue, nxt.remainingM);
  }

  void _considerLiveHints(FusedMetrics fused) {
    final speed = _effectiveSpeedKmh;
    if (speed < 3) {
      _standSeconds += 1;
    } else {
      _standSeconds = 0;
    }
    final impactJust = fused.gForcePeak >= 3.2 && fused.gForcePeak > _prevPeakG;
    _prevPeakG = fused.gForcePeak;
    if (impactJust) {
      _hardImpactStreak += 1;
    } else if (fused.gForcePeak < 2.0) {
      _hardImpactStreak = 0;
    }
    final hints = hintsFromMetrics(
      speedKmh: speed,
      standSeconds: _standSeconds,
      impactJustDetected: impactJust,
      hardImpactStreak: _hardImpactStreak,
    );
    if (hints.isEmpty) return;
    final h = hints.first;
    if (_liveHintText == h.text) return;
    if (mounted) setState(() => _liveHintText = h.text);
    if (!_ttsMuted && h.kind != 'stand') {
      unawaited(_tts.speak(clampHint(h.text)));
    }
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

  Future<bool> _preflightPermissions() async {
    final location = ref.read(locationCoreProvider);
    final result = await location.ensurePermissionDetailed();
    if (!mounted) return false;
    switch (result) {
      case LocationPermissionResult.granted:
        break;
      case LocationPermissionResult.servicesDisabled:
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Standort aus'),
            content: const Text(
              'Ohne Standort kein GPS-Track. Bitte Ortungsdienste einschalten.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Einstellungen'),
              ),
            ],
          ),
        );
        if (go == true) await location.openLocationSettings();
        return false;
      case LocationPermissionResult.deniedForever:
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Standort-Berechtigung'),
            content: const Text(
              'Standort dauerhaft verweigert. In den App-Einstellungen freigeben, '
              'sonst bleibt der Track leer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('App-Einstellungen'),
              ),
            ],
          ),
        );
        if (go == true) await location.openAppSettings();
        return false;
      case LocationPermissionResult.denied:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Standort nötig für Track & Navigation — erneut starten und erlauben.',
              ),
            ),
          );
        }
        return false;
    }

    // BLE is optional (CSC) — prompt, never block Freeride.
    final ble = ref.read(bleCoreProvider);
    final bleResult = await ble.ensurePermission();
    if (!mounted) return false;
    if (bleResult == BlePermissionResult.adapterOff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth aus — Freeride ohne CSC möglich; Sensor später verbinden.',
          ),
        ),
      );
    } else if (bleResult == BlePermissionResult.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'BLE-Berechtigung fehlt — Freeride läuft ohne Kadenz/Leistung.',
          ),
        ),
      );
    }
    return true;
  }

  Future<void> _start() async {
    final ok = await _preflightPermissions();
    if (!ok || !mounted) return;

    final sensor = ref.read(sensorCoreProvider);
    final ble = ref.read(bleCoreProvider);
    final location = ref.read(locationCoreProvider);
    final consents = await ref.read(garageRepositoryProvider).listConsents();
    _rawUploadConsent = consents['raw_data_upload'] == true;
    _rideId = const Uuid().v4();
    _chunkBuf.clear();
    _chunkSeq = 0;
    _gpsFixCount = 0;
    _gpsStatus = 'Warte auf GPS…';
    _lastGpsDistanceM = 0;
    _gpsStallSec = 0;

    await sensor.start();
    await ble.connect();
    await location.startRideTracking();
    _usingGps = false;
    _locSub = location.fixes.listen((fix) {
      if (!mounted || ref.read(isPausedProvider)) return;
      _gpsFixCount += 1;
      final gpsKmh = (fix.speedMps * 3.6).clamp(0.0, 120.0);
      if (gpsKmh > 0.3 || _gpsSpeedKmh > 0) {
        _gpsSpeedKmh = gpsKmh;
      }
      if (_gpsFixCount >= 2) {
        _usingGps = true;
        final d = location.distanceM;
        if (d > _lastGpsDistanceM + 1.0) {
          _lastGpsDistanceM = d;
          _gpsStallSec = 0;
          _gpsStatus = null;
          ref.read(rideDistanceMProvider.notifier).state = d;
        } else if (_gpsStatus == null && d < 1) {
          _gpsStatus = 'GPS-Fix…';
        }
      } else {
        _gpsStatus = 'GPS-Fix $_gpsFixCount…';
      }
      final route = ref.read(activeRouteProvider);
      if (route != null && route.coordinates.length >= 2) {
        final prog = projectOntoRoute(
          coordinates: route.coordinates,
          lat: fix.lat,
          lng: fix.lng,
        );
        _alongRouteM = prog.distanceAlongM;
        final nextOff = updateOffRouteState(
          currentlyOff: _offRoute,
          crossTrackM: prog.crossTrackM,
        );
        if (nextOff != _offRoute) {
          _offRoute = nextOff;
          _offRouteBanner = nextOff ? 'Route verlassen' : null;
          if (mounted) setState(() {});
          if (nextOff && !_ttsMuted && ref.read(isRidingProvider)) {
            unawaited(_tts.speak('Route verlassen'));
          }
          if (nextOff) unawaited(_maybeAutoReroute());
        } else if (nextOff) {
          unawaited(_maybeAutoReroute());
        }
      } else {
        _alongRouteM = location.distanceM;
        if (_offRoute || _offRouteBanner != null) {
          _offRoute = false;
          _offRouteBanner = null;
        }
      }
      _track.add(
        TrackPoint(
          lat: fix.lat,
          lng: fix.lng,
          timeMs: fix.timestamp.millisecondsSinceEpoch,
          elev: fix.altitudeM,
        ),
      );
      if (mounted) setState(() {});
      _considerNavTts();
      _mapDrawSkip += 1;
      if (_mapDrawSkip >= 3 || _track.length == 2) {
        _mapDrawSkip = 0;
        unawaited(_drawRideMap());
      }
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
      // Nur echte LDI-SoC — CSC liefert null, nicht erfinden.
      final soc = d.batterySocPercent;
      if (soc != null) _startSoc ??= soc;
    });
    _startedAt = DateTime.now();
    _spokenAnnounceKeys.clear();
    _liveHintText = null;
    _hardImpactStreak = 0;
    _standSeconds = 0;
    _prevPeakG = 0;
    _startSoc = null;
    ref.read(isRidingProvider.notifier).state = true;
    ref.read(isPausedProvider.notifier).state = false;
    ref.read(rideElapsedSecProvider.notifier).state = 0;
    ref.read(rideDistanceMProvider.notifier).state = 0;
    _alongRouteM = 0;
    _offRoute = false;
    _offRouteBanner = null;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ref.read(isPausedProvider)) return;
      final start = _startedAt;
      if (start != null) {
        ref.read(rideElapsedSecProvider.notifier).state =
            DateTime.now().difference(start).inSeconds;
      }
      if (!_usingGps) {
        // Ohne Fix: kein Fake-Track in Release. Sim nur Debug / AETHER_SIM_MOTION.
        if (_allowGpsStallSim) {
          ref.read(rideDistanceMProvider.notifier).state += 4.2;
          final last = _track.isNotEmpty ? _track.last : null;
          final baseLat = last?.lat ?? 47.995;
          final baseLng = last?.lng ?? 7.85;
          final t = ref.read(rideElapsedSecProvider);
          _track.add(
            TrackPoint(
              lat: baseLat + math.sin(t / 18) * 0.00018,
              lng: baseLng + t * 0.00004,
              timeMs: DateTime.now().millisecondsSinceEpoch,
              elev: 280 + t * 0.4,
            ),
          );
          if (mounted && t % 3 == 0) setState(() {});
        } else {
          _gpsStatus = 'Warte auf GPS — Track erst mit Fix';
          if (mounted && ref.read(rideElapsedSecProvider) % 3 == 0) {
            setState(() {});
          }
        }
      } else {
        final d = location.distanceM;
        if (d > _lastGpsDistanceM + 1.0) {
          _lastGpsDistanceM = d;
          _gpsStallSec = 0;
          _gpsStatus = null;
          ref.read(rideDistanceMProvider.notifier).state = d;
        } else {
          _gpsStallSec += 1;
          if (_gpsStallSec >= 5) {
            _gpsStatus = _allowGpsStallSim
                ? 'GPS still — Sim-Track'
                : 'GPS still — Signal schwach / Stand';
            if (mounted && ref.read(rideElapsedSecProvider) % 3 == 0) {
              setState(() {});
            }
          }
          // Emulator/Stillstand: nur Debug oder AETHER_SIM_MOTION.
          if (_gpsStallSec >= 5 && _allowGpsStallSim) {
            ref.read(rideDistanceMProvider.notifier).state += 4.2;
            final last = _track.isNotEmpty ? _track.last : null;
            final baseLat = last?.lat ?? 47.995;
            final baseLng = last?.lng ?? 7.85;
            final t = ref.read(rideElapsedSecProvider);
            _track.add(
              TrackPoint(
                lat: baseLat + math.sin(t / 18) * 0.00018,
                lng: baseLng + t * 0.00004,
                timeMs: DateTime.now().millisecondsSinceEpoch,
                elev: last?.elev ?? 280,
              ),
            );
            if (mounted && t % 3 == 0) setState(() {});
          }
        }
      }
      _considerNavTts();
      final m = _metrics;
      if (m != null) _considerLiveHints(m);
    });
    _bumpIdle();
    unawaited(WakelockPlus.enable());
    setState(() {
      _confirmStop = 0;
      _lastSpokenText = null;
      _liveHintText = null;
    });
  }

  double _distanceAlongTrackM(List<TrackPoint> track) {
    var sum = 0.0;
    for (var i = 1; i < track.length; i++) {
      sum += haversineM(
        track[i - 1].lat,
        track[i - 1].lng,
        track[i].lat,
        track[i].lng,
      );
    }
    return sum;
  }

  double _elevationGainFromTrack(List<TrackPoint> track) {
    var gain = 0.0;
    double? prev;
    for (final p in track) {
      final e = p.elev;
      if (e == null) continue;
      if (prev != null && e > prev + 0.5) gain += e - prev;
      prev = e;
    }
    return gain;
  }

  Future<void> _maybeAutoReroute() async {
    if (!_autoRerouteEnabled) return;
    if (_autoRerouteBusy || !ref.read(isRidingProvider)) return;
    if (ref.read(isPausedProvider)) return;
    final last = _lastAutoRerouteAt;
    if (last != null &&
        DateTime.now().difference(last).inSeconds <
            AppConfig.autoRerouteCooldownSec) {
      return;
    }
    _autoRerouteBusy = true;
    try {
      await _rejoinRoute();
      _lastAutoRerouteAt = DateTime.now();
    } finally {
      _autoRerouteBusy = false;
    }
  }

  Future<void> _rejoinRoute() async {
    final route = ref.read(activeRouteProvider);
    if (route == null || route.coordinates.length < 2) return;
    final lastFix = _track.isNotEmpty ? _track.last : null;
    if (lastFix == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein GPS-Fix für Rejoin')),
        );
      }
      return;
    }
    final prog = projectOntoRoute(
      coordinates: route.coordinates,
      lat: lastFix.lat,
      lng: lastFix.lng,
    );
    // Rest der Originalroute ab Segment (nicht nur Endpunkt).
    final rejoinIdx =
        (prog.segmentIndex + 1).clamp(1, route.coordinates.length - 1);
    final rejoinPt = route.coordinates[rejoinIdx];
    final remaining = route.coordinates.sublist(rejoinIdx);
    try {
      List<List<double>> approach = const [];
      List<NavStep> approachSteps = const [];
      var approachDistM = 0.0;
      if (prog.crossTrackM > 25) {
        final result = await ref.read(routeRepositoryProvider).planRoute(
              from: GeoPoint(lastFix.lat, lastFix.lng),
              to: GeoPoint(rejoinPt[1], rejoinPt[0]),
              profile: RoutingProfile.mtbTrail,
            );
        approach = result.coordinates.map((p) => [p.lng, p.lat]).toList();
        approachDistM = result.distanceM;
        approachSteps = result.steps
            .map(
              (st) => NavStep(
                id: st.id,
                instruction: st.instruction,
                distanceAlongM: st.distanceAlongM,
              ),
            )
            .toList();
      }

      final merged = <List<double>>[
        ...approach,
        ...remaining,
      ];
      if (merged.length < 2) {
        throw StateError('Keine brauchbare Rejoin-Geometrie');
      }

      var remainDist = 0.0;
      for (var i = 1; i < remaining.length; i++) {
        remainDist += haversineM(
          remaining[i - 1][1],
          remaining[i - 1][0],
          remaining[i][1],
          remaining[i][0],
        );
      }

      if (!mounted) return;
      ref.read(activeRouteProvider.notifier).state = ActiveRoute(
        id: '${route.id}-rejoin',
        name: '${route.name} (Rejoin)',
        distanceKm: (approachDistM + remainDist) / 1000,
        elevationM: route.elevationM,
        durationMin: ((approachDistM + remainDist) / 1000 / 12 * 60).round(),
        mtbScale: route.mtbScale,
        coordinates: merged,
        steps: [
          ...approachSteps,
          for (final st in route.steps)
            if (st.distanceAlongM >= prog.distanceAlongM)
              NavStep(
                id: st.id,
                instruction: st.instruction,
                distanceAlongM:
                    (st.distanceAlongM - prog.distanceAlongM + approachDistM)
                        .clamp(0, double.infinity),
              ),
        ],
      );
      setState(() {
        _offRoute = false;
        _offRouteBanner = null;
        _alongRouteM = 0;
      });
      if (!_ttsMuted) unawaited(_tts.speak('Route neu berechnet'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejoin fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _stop() async {
    if (_confirmStop == 0) {
      setState(() => _confirmStop = 1);
      return;
    }
    await _flushChunk(force: true);
    final uploadRideId = _rideId;
    if (_rawUploadConsent && uploadRideId != null) {
      unawaited(
        ref.read(rideChunkRepositoryProvider).uploadPending(rideId: uploadRideId),
      );
    }
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
    var distanceM = ref.read(rideDistanceMProvider);
    final elapsed = ref.read(rideElapsedSecProvider);
    final route = ref.read(activeRouteProvider);
    final bike = await ref.read(garageRepositoryProvider).getActiveBike();
    final bikeId = bike?.id ?? 'unknown';

    // Kein Fake-Track: ohne GPS bleibt der Track leer (Post-Ride zeigt das ehrlich).
    var track = List<TrackPoint>.from(_track);

    // Distanz aus Track, wenn Odometer leer blieb (Stillstand-GPS).
    final trackDist = _distanceAlongTrackM(track);
    if (trackDist > distanceM + 15) {
      distanceM = trackDist;
    }

    final elevFromRoute = route?.elevationM;
    final elevFromTrack = _elevationGainFromTrack(track);
    final elevHonest = elevFromRoute != null && elevFromRoute > 0
        ? elevFromRoute
        : elevFromTrack;
    final elevSource = elevFromRoute != null && elevFromRoute > 0
        ? 'route'
        : (elevFromTrack > 0 ? 'gps_track' : 'none');

    final record = await ref.read(rideRepositoryProvider).endRide(
          id: _rideId,
          bikeId: bikeId,
          startedAt: started,
          endedAt: ended,
          distanceKm: distanceM / 1000,
          movingTimeSec: elapsed,
          name: route?.name ?? 'Ride',
          routeId: route?.id,
          elevationM: elevHonest,
          track: track,
          summary: {
            'peakG': _peakG,
            'avgFlow': _flowN == 0 ? null : _flowSum / _flowN,
            'usingGps': _usingGps,
            'gpsStallSim': _gpsStallSec >= 3 && _allowGpsStallSim,
            'trackPoints': track.length,
            'elevationSource': elevSource,
            if (_ldi?.batterySocPercent != null)
              'soc': _ldi!.batterySocPercent,
          },
        );

    // E-Bike Reichweiten-Kalibrierung wenn genug Distanz + SOC-Delta
    final isEbike = bike?.category == BikeCategory.emtb ||
        bike?.category == BikeCategory.etrekking;
    if (isEbike && distanceM >= 2000) {
      final endSoc = _ldi?.batterySocPercent;
      final startSoc = _startSoc;
      final batteryWh = 500.0;
      double whUsed;
      if (startSoc != null && endSoc != null && startSoc > endSoc) {
        whUsed = batteryWh * ((startSoc - endSoc) / 100);
      } else {
        whUsed = (distanceM / 1000) * 12; // Heuristik
      }
      final store = ref.read(userProfileStoreProvider);
      await store.load();
      final prev = store.rangeCalibration ??
          defaultCalibration(category: bike!.category);
      final next = calibrateFromRide(
        prev: prev,
        distanceKm: distanceM / 1000,
        movingTimeSec: elapsed.toDouble(),
        batteryWhUsed: whUsed,
      );
      await store.setRangeCalibration(next);
    }

    ref.read(isRidingProvider.notifier).state = false;
    ref.read(isPausedProvider.notifier).state = false;
    ref.read(autoLockedProvider.notifier).state = false;
    ref.read(activeRouteProvider.notifier).state = null;
    ref.read(rideElapsedSecProvider.notifier).state = 0;
    ref.read(rideDistanceMProvider.notifier).state = 0;
    unawaited(WakelockPlus.disable());
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
      _rideMap = null;
      _mapDrawSkip = 0;
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
    _lightSub?.cancel();
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
            if (riding && route != null)
              IconButton(
                tooltip: _autoRerouteEnabled
                    ? 'Auto-Reroute an'
                    : 'Auto-Reroute aus',
                onPressed: () {
                  setState(() => _autoRerouteEnabled = !_autoRerouteEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _autoRerouteEnabled
                            ? 'Auto-Reroute aktiv (Cooldown ${AppConfig.autoRerouteCooldownSec}s)'
                            : 'Auto-Reroute aus — manueller Rejoin bleibt',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  _autoRerouteEnabled
                      ? Icons.alt_route
                      : Icons.alt_route_outlined,
                  color: _autoRerouteEnabled ? AppColors.accent : null,
                ),
              ),
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
              tooltip: _sunlightAuto
                  ? 'Sunlight Mode (Auto)'
                  : 'Sunlight Mode (Manuell)',
              onPressed: _toggleSunlightManual,
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
                      if (riding && _offRouteBanner != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade400),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _offRouteBanner!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _bumpIdle();
                                  unawaited(_rejoinRoute());
                                },
                                child: Text(
                                  'Zurück',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (riding && route.coordinates.length >= 4)
                        Builder(
                          builder: (context) {
                            String? banner;
                            if (route.steps.isNotEmpty) {
                              final nxt = nextRouteStep(
                                route.steps,
                                _alongRouteM,
                              );
                              if (nxt != null) {
                                banner = cueBannerText(
                                  NavCue(
                                    id: nxt.step.id,
                                    distanceAlongM: nxt.step.distanceAlongM,
                                    instruction: nxt.step.instruction,
                                    bearingDeg: 0,
                                  ),
                                  nxt.remainingM.round(),
                                );
                              }
                            } else {
                              final cues = buildNavCues(route.coordinates);
                              final nxt = nextCue(cues, _alongRouteM);
                              if (nxt != null) {
                                banner = cueBannerText(
                                  nxt.cue,
                                  nxt.remainingM,
                                );
                              }
                            }
                            if (banner == null) {
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
                                banner,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      if (riding && _liveHintText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _liveHintText!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ] else if (!riding)
                      const Text(
                        'Optional: Route in Discover wählen und „Losfahren“.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    if (!riding) ...[
                      const SizedBox(height: 8),
                      Text(
                        _cscStatusLine(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        _cscStatusLine(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (_gpsStatus != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _gpsStatus!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                            (_effectiveSpeedKmh).toStringAsFixed(0),
                            'km/h',
                          ),
                          _bigStat(
                            distanceM < 1000
                                ? (distanceM / 1000).toStringAsFixed(2)
                                : (distanceM / 1000).toStringAsFixed(1),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MapLibreMap(
            key: ValueKey(_mapStyle),
            styleString: _mapStyle,
            initialCameraPosition: CameraPosition(
              target: _mapTarget(route),
              zoom: 14,
            ),
            myLocationEnabled: true,
            trackCameraPosition: false,
            onMapCreated: (c) {
              _rideMap = c;
            },
            onStyleLoadedCallback: () {
              unawaited(_drawRideMap());
            },
          ),
        );
      case RideLiveLayer.data:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _MetricRow(
                  'Tempo',
                  '${_effectiveSpeedKmh.toStringAsFixed(1)} km/h',
                ),
                _MetricRow(
                  'SoC',
                  _ldi?.batterySocPercent != null
                      ? '${_ldi!.batterySocPercent!.toStringAsFixed(0)} %'
                      : '— (LDI folgt G-1)',
                ),
                _MetricRow(
                  'Leistung',
                  _ldi?.riderPowerW != null
                      ? '${_ldi!.riderPowerW!.toStringAsFixed(0)} W'
                      : '—',
                ),
                _MetricRow(
                  'Kadenz',
                  _ldi != null
                      ? '${_ldi!.cadenceRpm.toStringAsFixed(0)} rpm'
                      : '—',
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

  String _cscStatusLine() {
    final connected =
        ref.read(bleCoreProvider).isConnected || _ldi != null;
    final riding = ref.read(isRidingProvider);
    final csc = connected
        ? 'CSC verbunden'
        : (riding ? 'CSC nicht verbunden' : 'CSC bereit (Standard-BLE)');
    return '$csc · LDI folgt G-1';
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
