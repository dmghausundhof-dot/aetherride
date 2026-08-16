import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import '../../core/theme/nav_hud_tokens.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/routing_client.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/ble.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../../domain/ebike/range.dart';
import '../../domain/ride.dart';
import '../../domain/routing/battery_preset.dart';
import '../../domain/routing/camera_follow_smooth.dart';
import '../../domain/routing/connectivity_chip.dart';
import '../../domain/routing/nav_announce.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/route_progress.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../domain/routing/upcoming_rail.dart';
import '../../domain/sensor.dart';
import '../../domain/sensor/live_hints.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../post_ride/post_ride_screen.dart';
import '../shared/status_bar_scrim.dart';
import '../home/hof_watch_card.dart';
import '../shell/shell_tabs.dart';
import 'widgets/battery_preset_sheet.dart';
import 'widgets/reroute_sheet.dart';
import 'widgets/ride_connectivity_chip.dart';
import 'widgets/ride_data_strip.dart';
import 'widgets/ride_network.dart';
import 'widgets/ride_next_turn_banner.dart';
import 'widgets/ride_off_route_banner.dart';
import 'widgets/ride_pre_start_chrome.dart';
import 'widgets/ride_upcoming_rail.dart';

Set<Factory<OneSequenceGestureRecognizer>> get _rideMapGestures =>
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
    };

/// Lux reading — sensors_plus has no AmbientLightEvent yet; local stand-in.
class AmbientLightEvent {
  const AmbientLightEvent(this.lux);
  final double lux;
}

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => RideScreenState();
}

class RideScreenState extends ConsumerState<RideScreen> {
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
  int _rideMapDrawGen = 0;
  String _mapStyle = AppConfig.mapStyleUrl;
  bool _offRoute = false;
  String? _offRouteBanner;
  DateTime? _lastAutoRerouteAt;
  bool _autoRerouteBusy = false;

  /// User chose „Bleiben“ — no forced rejoin until they leave route again.
  bool _userChoseStay = false;
  bool _rerouteSheetOpen = false;

  /// Snapshot for 10s Undo after successful rejoin (N-02).
  ActiveRoute? _routeBeforeRejoin;
  Timer? _undoRejoinTimer;
  String? _rejoinWhyLine;

  /// Clean Mode mid-ride: max ~4 chrome elements (N-01). Pro via data-strip tap.
  bool _cleanMode = true;

  /// User-Toggle (zusätzlich zu dart-define AETHER_AUTO_REROUTE).
  bool _autoRerouteEnabled = AppConfig.autoReroute;

  /// Kamera folgt GPS während der Fahrt (Komoot-ähnlich).
  bool _cameraFollow = true;

  /// true = Norden oben; false = Fahrtrichtung oben (Heading-up default).
  bool _northUp = false;

  /// true während/kurz nach programmatischem animateCamera — sonst pausiert
  /// [onCameraIdle] den Follow bei jedem GPS-Update.
  bool _programmaticCamera = false;

  double _smoothedCameraBearing = 0;
  double _lastAppliedCameraBearing = 0;
  double? _lastFollowLat;
  double? _lastFollowLng;
  DateTime? _lastFollowCameraAt;

  /// N-04/N-09: default Pocket = no Keep-Screen-On.
  RideBatteryPreset _batteryPreset = RideBatteryPreset.pocket;

  /// N-03/N-08 connectivity honesty.
  bool _networkOnline = true;
  bool _offlineMapAvailable = false;
  ConnectivityChipState _connectivityState = ConnectivityChipState.live;
  Timer? _connectivityTimer;
  StreamSubscription<RideNotificationAction>? _notifActionSub;

  /// Distanz entlang Active Route (Nav); Odometer bleibt [rideDistanceMProvider].
  double _alongRouteM = 0;
  int _gpsFixCount = 0;
  String? _gpsStatus;
  double _lastGpsDistanceM = 0;
  int _gpsStallSec = 0;

  /// Distanz-Sim nur explizit — nie default in Debug (QA/Emulator sonst Fake-km).
  static bool get _allowGpsStallSim =>
      const bool.fromEnvironment('AETHER_SIM_MOTION', defaultValue: false);

  /// Meter die nur aus Sim kamen (nicht persistieren / Track-Override).
  double _simDistanceM = 0;
  bool _simMotionUsed = false;

  /// When false, light sensor drives [sunlightModeProvider]; manual toggle locks.
  bool _sunlightAuto = true;
  StreamSubscription<AmbientLightEvent>? _lightSub;
  DateTime? _brightSince;
  static const _sunlightLux = 8000.0;
  static const _sunlightHold = Duration(seconds: 4);
  static const _ambientLightChannel = EventChannel(
    'com.aetherride/ambient_light',
  );

  /// True while Losfahren / autostart is awaiting location permission + engines.
  /// Map stays visible — never swap back to a sensor checklist.
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_tts.setLanguage('de-DE'));
    unawaited(_tts.setSpeechRate(0.5));
    _startAutoSunlight();
    unawaited(_loadRidePrefs());
    unawaited(
      AppConfig.resolveMapStyleUrl().then((s) {
        if (mounted) setState(() => _mapStyle = s);
      }),
    );
    // Deep-link may set rideAutostart before this State mounts — ref.listen
    // only fires on *changes*, so consume a pending true on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumeRideAutostart();
    });
  }

  void _consumeRideAutostart() {
    if (ref.read(rideAutostartProvider) != true) return;
    ref.read(rideAutostartProvider.notifier).state = false;
    if (ref.read(isRidingProvider) || _starting) return;
    unawaited(_start());
  }

  /// System-back: Stop-Bestätigung während der Fahrt, sonst HUD → Karte.
  bool handleSystemBack() {
    if (!mounted) return false;
    if (_starting) return true;
    if (ref.read(isRidingProvider)) {
      unawaited(_stop());
      return true;
    }
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    return true;
  }

  Future<void> _loadRidePrefs() async {
    final preset = await RidePrefs.batteryPreset();
    final mapOk = await _probeOfflineMapAvailable();
    if (!mounted) return;
    setState(() {
      _batteryPreset = preset;
      _offlineMapAvailable = mapOk;
    });
  }

  /// Local pack or offline-capable style override (not remote-only basemap).
  Future<bool> _probeOfflineMapAvailable() async {
    try {
      final m = await OfflineMapsPrefs.read();
      final pack = (m['activatedPackPath'] as String?)?.trim() ?? '';
      if (pack.isNotEmpty) return true;
      final style = (m['pmtilesUrl'] as String?)?.trim() ?? '';
      if (style.isEmpty) return false;
      // file:// or asset-style local paths count; pure https remote does not.
      if (style.startsWith('file:') ||
          style.startsWith('/') ||
          style.contains('asset://')) {
        return true;
      }
      // pmtiles:// or custom offline tile scheme.
      if (style.startsWith('pmtiles://')) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshConnectivityChip() async {
    final online = await rideHasNetwork();
    final route = ref.read(activeRouteProvider);
    final hasRoute = route != null && route.coordinates.length >= 2;
    final state = resolveConnectivityChip(
      online: online,
      hasRouteGeometry: hasRoute,
      offlineMapAvailable: _offlineMapAvailable,
    );
    if (!mounted) return;
    if (online != _networkOnline || state != _connectivityState) {
      setState(() {
        _networkOnline = online;
        _connectivityState = state;
      });
    }
  }

  Future<void> _applyBatteryPreset(
    RideBatteryPreset preset, {
    bool persist = true,
  }) async {
    _batteryPreset = preset;
    if (persist) await RidePrefs.setBatteryPreset(preset);
    if (!ref.read(isRidingProvider)) return;
    if (preset.keepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    if (mounted) setState(() {});
  }

  /// Ultra: brief wake on voice cue / off-route (N-09).
  Future<void> _wakeOnCueIfNeeded() async {
    if (_batteryPreset != RideBatteryPreset.ultra) return;
    if (!ref.read(isRidingProvider)) return;
    try {
      await WakelockPlus.enable();
      Future<void>.delayed(const Duration(seconds: 12), () async {
        if (!mounted) return;
        if (_batteryPreset != RideBatteryPreset.ultra) return;
        if (!ref.read(isRidingProvider)) return;
        await WakelockPlus.disable();
      });
    } catch (_) {}
  }

  Future<void> _showBatteryPresetPicker() async {
    final picked = await showBatteryPresetSheet(
      context,
      current: _batteryPreset,
    );
    if (picked == null || !mounted) return;
    await _applyBatteryPreset(picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          picked == RideBatteryPreset.pocket
              ? 'Pocket — Display darf aus (Akku sparen).'
              : picked == RideBatteryPreset.lenker
              ? 'Lenker — Display an (kostet Akku).'
              : 'Ultra — Display nur bei Abbiegen (kostet Akku).',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _syncRideNotification() {
    final location = ref.read(locationCoreProvider);
    final paused = ref.read(isPausedProvider);
    final text = paused ? 'Pause' : 'Fahrt läuft';
    unawaited(
      location.updateRideNotification(
        paused: paused,
        muted: _ttsMuted,
        text: text,
      ),
    );
  }

  void _bindNotificationActions() {
    _notifActionSub?.cancel();
    final location = ref.read(locationCoreProvider);
    _notifActionSub = location.notificationActions.listen((a) {
      if (!mounted || !ref.read(isRidingProvider)) return;
      if (a.name == 'pause') {
        final paused = ref.read(isPausedProvider);
        ref.read(isPausedProvider.notifier).state = !paused;
        if (paused) setState(() => _confirmStop = 0);
        _syncRideNotification();
        if (mounted) setState(() {});
      } else if (a.name == 'mute') {
        setState(() => _ttsMuted = !_ttsMuted);
        if (_ttsMuted) unawaited(_tts.stop());
        _syncRideNotification();
      }
    });
  }

  /// Auto-Sunlight: lux > 8000 for ~4s → enable; else reset while auto.
  /// sensors_plus is imported for SensorInterval; lux comes from TYPE_LIGHT.
  void _startAutoSunlight() {
    _lightSub?.cancel();
    try {
      _lightSub = _ambientLightChannel
          .receiveBroadcastStream(SensorInterval.normalInterval.inMicroseconds)
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

  LatLng? _mapTargetOrNull(ActiveRoute? route) {
    if (_track.isNotEmpty) {
      final p = _track.last;
      return LatLng(p.lat, p.lng);
    }
    if (route != null && route.coordinates.isNotEmpty) {
      final c = route.coordinates.first;
      return LatLng(c[1], c[0]);
    }
    return null;
  }

  /// Kompass-Kurs zwischen zwei Lat/Lng-Punkten (0–360°).
  double _bearingDeg(double lat1, double lng1, double lat2, double lng2) {
    final lat1r = lat1 * math.pi / 180;
    final lat2r = lat2 * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2r);
    final x =
        math.cos(lat1r) * math.sin(lat2r) -
        math.sin(lat1r) * math.cos(lat2r) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// DACH+FR Übersicht bis GPS — kein Stadt-Fake.
  static const _regionOverview = LatLng(47.2, 6.5);

  LatLng _mapTarget(ActiveRoute? route) =>
      _mapTargetOrNull(route) ?? _regionOverview;

  String _onlineStyleFor(LatLng t) =>
      nextOnlineBasemapStyleUrl(
        currentStyle: _mapStyle,
        lng: t.longitude,
        lat: t.latitude,
      ) ??
      _mapStyle;

  Future<void> _drawRideMap() async {
    final c = _rideMap;
    if (c == null) return;
    final gen = ++_rideMapDrawGen;
    try {
      await c.clearLines();
      if (gen != _rideMapDrawGen) return;
      final route = ref.read(activeRouteProvider);
      if (route != null && route.coordinates.length >= 2) {
        final planned = [for (final p in route.coordinates) LatLng(p[1], p[0])];
        if (gen != _rideMapDrawGen) return;
        // Thick high-contrast route ribbon (N-01) — outline + core.
        await c.addLine(
          LineOptions(
            geometry: planned,
            lineColor: '#0A1A12',
            lineWidth: 18,
            lineOpacity: 0.95,
            lineJoin: 'round',
          ),
        );
        if (gen != _rideMapDrawGen) return;
        await c.addLine(
          LineOptions(
            geometry: planned,
            lineColor: '#00E676',
            lineWidth: 10,
            lineOpacity: 1,
            lineJoin: 'round',
          ),
        );
      }
      if (gen != _rideMapDrawGen) return;
      if (_track.length >= 2) {
        final line = [for (final p in _track) LatLng(p.lat, p.lng)];
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: '#BF360C',
            lineWidth: 10,
            lineOpacity: 0.85,
            lineJoin: 'round',
          ),
        );
        if (gen != _rideMapDrawGen) return;
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: '#FF6B35',
            lineWidth: 5.5,
            lineJoin: 'round',
          ),
        );
        if (gen != _rideMapDrawGen) return;
        final last = line.last;
        if (_cameraFollow) {
          if (line.length >= 2) {
            final measured = _bearingDeg(
              line[line.length - 2].latitude,
              line[line.length - 2].longitude,
              last.latitude,
              last.longitude,
            );
            // N-06: low-pass heading to reduce heading-up jank.
            _smoothedCameraBearing = _lastFollowCameraAt == null
                ? measured
                : smoothBearingDeg(
                    previous: _smoothedCameraBearing,
                    measured: measured,
                    alpha: 0.32,
                  );
          }
          final bearing = _northUp ? 0.0 : _smoothedCameraBearing;
          final now = DateTime.now();
          final doUpdate = shouldUpdateFollowCamera(
            lastLat: _lastFollowLat,
            lastLng: _lastFollowLng,
            nextLat: last.latitude,
            nextLng: last.longitude,
            lastBearing: _lastAppliedCameraBearing,
            nextBearing: bearing,
            lastUpdateAt: _lastFollowCameraAt,
            now: now,
          );
          if (doUpdate) {
            _lastFollowLat = last.latitude;
            _lastFollowLng = last.longitude;
            _lastFollowCameraAt = now;
            _lastAppliedCameraBearing = bearing;
            _programmaticCamera = true;
            await c.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: last,
                  zoom: 16,
                  bearing: bearing,
                  tilt: _northUp ? 0 : 40,
                ),
              ),
              // Slightly longer ease reduces 120Hz jank vs snappy snaps.
              duration: const Duration(milliseconds: 550),
            );
            Future<void>.delayed(const Duration(milliseconds: 600), () {
              _programmaticCamera = false;
            });
          }
        }
      } else if (route != null && route.coordinates.length >= 2) {
        final pts = [for (final p in route.coordinates) LatLng(p[1], p[0])];
        final swLat = pts
            .map((e) => e.latitude)
            .reduce((a, b) => a < b ? a : b);
        final swLng = pts
            .map((e) => e.longitude)
            .reduce((a, b) => a < b ? a : b);
        final neLat = pts
            .map((e) => e.latitude)
            .reduce((a, b) => a > b ? a : b);
        final neLng = pts
            .map((e) => e.longitude)
            .reduce((a, b) => a > b ? a : b);
        if (gen != _rideMapDrawGen) return;
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
              left: 28,
              top: 28,
              right: 28,
              bottom: 28,
            ),
          );
        }
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
      street: extractStreetNameFromInstruction(cue.instruction),
    );
    if (text == null) return;
    if (_lastSpokenText == text) return;
    _lastSpokenText = text;
    unawaited(_wakeOnCueIfNeeded());
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
          street: nxt.step.streetName ??
              extractStreetNameFromInstruction(nxt.step.instruction),
        );
        if (text != null &&
            !_ttsMuted &&
            ref.read(isRidingProvider) &&
            _lastSpokenText != text) {
          _lastSpokenText = text;
          unawaited(_wakeOnCueIfNeeded());
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

  /// Fahrwerk/Mount nur bei Federgabel-relevanten Sports (nicht City/Road).
  bool _showsChassisUx(WidgetRef ref) {
    final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
    Bike? active;
    for (final b in bikes) {
      if (b.isActive) {
        active = b;
        break;
      }
    }
    active ??= bikes.isEmpty ? null : bikes.first;
    final cat =
        active?.category ?? ref.read(userProfileStoreProvider).preferredSport;
    return cat?.showsChassisLayer ?? false;
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
      await ref
          .read(rideChunkRepositoryProvider)
          .appendChunk(rideId: rideId, seq: seq, blocks: blocks);
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

    // BLE / Nearby Devices is optional — never gate start on it.
    // Permission + connect run in [_connectBleAfterHudStable] after the
    // nav HUD has painted, so the system dialog cannot freeze start.
    return true;
  }

  /// Defer Nearby/BLE until HUD + camera are up. Denial is non-fatal.
  Future<void> _connectBleAfterHudStable() async {
    // Let the first ride frames paint (map / next-turn) before any dialog.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || !ref.read(isRidingProvider)) return;

    final ble = ref.read(bleCoreProvider);
    try {
      final bleResult = await ble.ensurePermission();
      if (!mounted || !ref.read(isRidingProvider)) return;
      if (bleResult == BlePermissionResult.adapterOff) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bluetooth aus — Fahren auch ohne Sensor möglich; später verbinden.',
            ),
          ),
        );
        return;
      }
      if (bleResult == BlePermissionResult.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nearby/Bluetooth verweigert — GPS-Navigation läuft ohne Sensor.',
            ),
          ),
        );
        return;
      }
      if (bleResult == BlePermissionResult.unsupported) return;

      final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
      Bike? active;
      for (final b in bikes) {
        if (b.isActive) {
          active = b;
          break;
        }
      }
      active ??= bikes.isEmpty ? null : bikes.first;
      final wheel = active?.wheelSize;
      if (wheel != null) {
        ble.wheelCircumferenceM = switch (wheel) {
          WheelSize.w275 => 2.070,
          WheelSize.w29 => 2.105,
          WheelSize.c700 => 2.130,
          WheelSize.b650 => 1.935,
        };
      }

      // Garage-Kopplung: gespeicherte deviceId des aktiven Bikes bevorzugen.
      String? preferredId;
      BikeBleKind? kindHint;
      final bikeId = active?.id;
      if (bikeId != null && bikeId.isNotEmpty) {
        final saved =
            await ref.read(bikeBleStoreProvider).deviceForBike(bikeId);
        preferredId = saved?.deviceId;
        kindHint = bikeBleKindFromStorage(saved?.kind);
      }

      final cscOk = await ble.connect(
        deviceId: preferredId,
        kindHint: kindHint,
      );
      if (!mounted || !ref.read(isRidingProvider)) return;
      if (!cscOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ble.statusDetail ??
                  'Kein Radsensor gefunden — GPS-Track läuft weiter.',
            ),
          ),
        );
      }

      final remoteId = ble.lastRemoteId;
      if (cscOk &&
          bikeId != null &&
          bikeId.isNotEmpty &&
          remoteId != null &&
          remoteId.isNotEmpty) {
        await ref.read(bikeBleStoreProvider).saveForBike(
              bikeId,
              BikeBleDevice(
                deviceId: remoteId,
                name: ble.connectedDeviceName,
                kind: ble.connectedKind == null
                    ? null
                    : bikeBleKindToStorage(ble.connectedKind!),
              ),
            );
      }

      final savedWatch = await ref.read(bikeBleStoreProvider).savedWatch();
      if (!mounted || !ref.read(isRidingProvider)) return;
      if (savedWatch != null) {
        final watchOk = await ble.connectWatch(
          deviceId: savedWatch.deviceId,
          scanIfMissing: true,
        );
        if (!mounted || !ref.read(isRidingProvider)) return;
        if (watchOk) {
          final watchId = ble.lastWatchRemoteId;
          if (watchId != null && watchId.isNotEmpty) {
            await ref.read(bikeBleStoreProvider).saveWatch(
                  BikeBleDevice(
                    deviceId: watchId,
                    name: ble.connectedWatchName ?? savedWatch.name,
                  ),
                );
          }
        }
      }
    } catch (e) {
      debugPrint('ride: deferred BLE connect failed ($e) — continue without');
    }
  }

  Future<void> _start() async {
    if (_starting || ref.read(isRidingProvider)) return;
    setState(() => _starting = true);

    final ok = await _preflightPermissions();
    if (!ok || !mounted) {
      if (mounted) {
        setState(() => _starting = false);
        ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
      }
      return;
    }

    final sensor = ref.read(sensorCoreProvider);
    final ble = ref.read(bleCoreProvider);
    final location = ref.read(locationCoreProvider);
    // Consent lookup is secondary — do not block HUD paint on storage I/O.
    unawaited(
      ref.read(garageRepositoryProvider).listConsents().then((consents) {
        _rawUploadConsent = consents['raw_data_upload'] == true;
      }),
    );
    _rideId = const Uuid().v4();
    _chunkBuf.clear();
    _chunkSeq = 0;
    _gpsFixCount = 0;
    _gpsStatus = 'Kein GPS — Track bleibt leer. Kein erfundener Verlauf.';
    _lastGpsDistanceM = 0;
    _gpsStallSec = 0;
    _startedAt = DateTime.now();
    _spokenAnnounceKeys.clear();
    _liveHintText = null;
    _hardImpactStreak = 0;
    _standSeconds = 0;
    _prevPeakG = 0;
    _startSoc = null;
    _alongRouteM = 0;
    _offRoute = false;
    _offRouteBanner = null;
    _userChoseStay = false;
    _rejoinWhyLine = null;
    _clearUndoRejoin();
    // Heading-up default when riding with a route (N-01).
    if (ref.read(activeRouteProvider) != null) {
      _northUp = false;
    }
    _cleanMode = true;
    _simDistanceM = 0;
    _simMotionUsed = false;
    _usingGps = false;

    // N-START-01: flip riding ASAP so map + HUD paint before sensor work.
    // BLE / Nearby stays deferred in [_connectBleAfterHudStable].
    ref.read(isRidingProvider.notifier).state = true;
    ref.read(isPausedProvider.notifier).state = false;
    ref.read(rideElapsedSecProvider.notifier).state = 0;
    ref.read(rideDistanceMProvider.notifier).state = 0;
    if (mounted) setState(() => _starting = false);

    // GPS + IMU in parallel after HUD is visible — never await BLE here.
    unawaited(sensor.start());
    unawaited(location.startRideTracking());
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
          if (nextOff) {
            _offRouteBanner = 'Abseits der Route.';
            _userChoseStay = false;
            _rejoinWhyLine = null;
            if (mounted) setState(() {});
            if (!_ttsMuted && ref.read(isRidingProvider)) {
              unawaited(_wakeOnCueIfNeeded());
              unawaited(_tts.speak('Abseits der Route'));
            }
            unawaited(_onWentOffRoute());
          } else {
            _offRouteBanner = null;
            if (mounted) setState(() {});
          }
        } else if (nextOff && !_userChoseStay) {
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
    // Nearby Devices / BLE after HUD stable — never interrupt camera start.
    unawaited(_connectBleAfterHudStable());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ref.read(isPausedProvider)) return;
      final start = _startedAt;
      if (start != null) {
        ref.read(rideElapsedSecProvider.notifier).state = DateTime.now()
            .difference(start)
            .inSeconds;
      }
      if (!_usingGps) {
        if (_allowGpsStallSim) {
          _tickSimMotion(elevFallback: 280);
        } else {
          _gpsStatus = 'Kein GPS — Track bleibt leer. Kein erfundener Verlauf.';
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
          // Echte GPS-Distanz; Sim-Anteil nicht mitzählen.
          ref.read(rideDistanceMProvider.notifier).state = d;
        } else {
          _gpsStallSec += 1;
          if (_gpsStallSec >= 5) {
            _gpsStatus = _allowGpsStallSim
                ? 'GPS still — Sim-Track (nicht speichern)'
                : 'GPS still — Signal schwach / Stand';
            if (mounted && ref.read(rideElapsedSecProvider) % 3 == 0) {
              setState(() {});
            }
          }
          if (_gpsStallSec >= 5 && _allowGpsStallSim) {
            _tickSimMotion(
              elevFallback: _track.isNotEmpty ? _track.last.elev : 280,
            );
          }
        }
      }
      _considerNavTts();
      final m = _metrics;
      if (m != null) _considerLiveHints(m);
    });
    _bumpIdle();
    // N-04/N-09: Keep-Screen-On only for Lenker (opt-in). Default Pocket = off.
    unawaited(_applyBatteryPreset(_batteryPreset, persist: false));
    _bindNotificationActions();
    _connectivityTimer?.cancel();
    unawaited(_refreshConnectivityChip());
    _connectivityTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(_refreshConnectivityChip());
    });
    _syncRideNotification();
    setState(() {
      _confirmStop = 0;
      _lastSpokenText = null;
      _liveHintText = null;
      _lastFollowLat = null;
      _lastFollowLng = null;
      _lastFollowCameraAt = null;
    });
    // First ride: calm one-shot preset ask (battery-saving default until chosen).
    unawaited(_maybeAskBatteryPresetOnce());
  }

  Future<void> _maybeAskBatteryPresetOnce() async {
    if (!mounted || !ref.read(isRidingProvider)) return;
    final chosen = await RidePrefs.batteryPresetChosen();
    if (chosen || !mounted) return;
    // Brief delay so map/HUD paints first.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || !ref.read(isRidingProvider)) return;
    await _showBatteryPresetPicker();
  }

  /// Nur mit AETHER_SIM_MOTION — UI-Odometer kann steigen, Persistenz filtert.
  void _tickSimMotion({required double? elevFallback}) {
    const stepM = 4.2;
    _simMotionUsed = true;
    _simDistanceM += stepM;
    ref.read(rideDistanceMProvider.notifier).state += stepM;
    final last = _track.isNotEmpty ? _track.last : null;
    final baseLat = last?.lat ?? _regionOverview.latitude;
    final baseLng = last?.lng ?? _regionOverview.longitude;
    final t = ref.read(rideElapsedSecProvider);
    _track.add(
      TrackPoint(
        lat: baseLat + math.sin(t / 18) * 0.00018,
        lng: baseLng + t * 0.00004,
        timeMs: DateTime.now().millisecondsSinceEpoch,
        elev: elevFallback ?? last?.elev ?? 280,
      ),
    );
    _gpsStatus = 'Sim-Track aktiv (AETHER_SIM_MOTION)';
    if (mounted && t % 3 == 0) setState(() {});
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

  /// First reaction when leaving the route: offline toast or online sheet (N-02b).
  Future<void> _onWentOffRoute() async {
    if (!mounted || !ref.read(isRidingProvider)) return;
    final online = await rideHasNetwork();
    if (!mounted) return;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text(kOfflineRerouteToast),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    if (_userChoseStay || _rerouteSheetOpen) return;
    if (_autoRerouteEnabled) {
      unawaited(_maybeAutoReroute());
      return;
    }
    await _showRerouteSheetIfNeeded();
  }

  Future<void> _showRerouteSheetIfNeeded() async {
    if (!mounted || _rerouteSheetOpen || !_offRoute) return;
    _rerouteSheetOpen = true;
    try {
      final action = await showRerouteSheet(context);
      if (!mounted) return;
      switch (action) {
        case RerouteSheetAction.rejoin:
          await _rejoinRoute();
        case RerouteSheetAction.stay:
          setState(() {
            _userChoseStay = true;
            _offRouteBanner = 'Abseits der Route.';
          });
        case RerouteSheetAction.skip:
          await _rejoinRoute(skipAheadM: 800);
        case null:
          // Dismiss without forcing rejoin (same as stay for auto-reroute).
          setState(() => _userChoseStay = true);
      }
    } finally {
      _rerouteSheetOpen = false;
    }
  }

  Future<void> _maybeAutoReroute() async {
    if (!_autoRerouteEnabled || _userChoseStay || !_offRoute) return;
    if (_autoRerouteBusy || !ref.read(isRidingProvider)) return;
    if (ref.read(isPausedProvider)) return;
    if (_rerouteSheetOpen) return;
    final last = _lastAutoRerouteAt;
    if (last != null &&
        DateTime.now().difference(last).inSeconds <
            AppConfig.autoRerouteCooldownSec) {
      return;
    }
    final online = await rideHasNetwork();
    if (!online) {
      // No fake replan offline (N-02b).
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

  int _segmentIndexNearAlong(List<List<double>> coords, double targetAlongM) {
    if (coords.length < 2) return 0;
    var along = 0.0;
    for (var i = 1; i < coords.length; i++) {
      along += haversineM(
        coords[i - 1][1],
        coords[i - 1][0],
        coords[i][1],
        coords[i][0],
      );
      if (along >= targetAlongM) {
        return i.clamp(1, coords.length - 1);
      }
    }
    return coords.length - 1;
  }

  void _clearUndoRejoin() {
    _undoRejoinTimer?.cancel();
    _undoRejoinTimer = null;
    _routeBeforeRejoin = null;
  }

  void _startUndoWindow(ActiveRoute previous) {
    _undoRejoinTimer?.cancel();
    _routeBeforeRejoin = previous;
    _undoRejoinTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        _routeBeforeRejoin = null;
        _rejoinWhyLine = null;
      });
    });
  }

  void _undoRejoin() {
    final prev = _routeBeforeRejoin;
    if (prev == null) return;
    ref.read(activeRouteProvider.notifier).state = prev;
    _clearUndoRejoin();
    setState(() {
      _rejoinWhyLine = null;
      _offRoute = false;
      _offRouteBanner = null;
      _alongRouteM = 0;
    });
    if (!_ttsMuted) unawaited(_tts.speak('Route wiederhergestellt'));
    unawaited(_drawRideMap());
  }

  /// Rejoin onto planned route. [skipAheadM] > 0 skips a section (N-02b).
  Future<void> _rejoinRoute({double skipAheadM = 0}) async {
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

    final online = await rideHasNetwork();
    if (!online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: const Text(kOfflineRerouteToast)),
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
    final baseIdx = (prog.segmentIndex + 1).clamp(
      1,
      route.coordinates.length - 1,
    );
    final rejoinIdx = skipAheadM > 0
        ? _segmentIndexNearAlong(
            route.coordinates,
            prog.distanceAlongM + skipAheadM,
          )
        : baseIdx;
    final rejoinPt = route.coordinates[rejoinIdx];
    final remaining = route.coordinates.sublist(rejoinIdx);
    // Along-distance of rejoin point for step remapping.
    var rejoinAlongM = 0.0;
    for (var i = 1; i <= rejoinIdx && i < route.coordinates.length; i++) {
      rejoinAlongM += haversineM(
        route.coordinates[i - 1][1],
        route.coordinates[i - 1][0],
        route.coordinates[i][1],
        route.coordinates[i][0],
      );
    }
    final stepCutoff = skipAheadM > 0 ? rejoinAlongM : prog.distanceAlongM;

    try {
      List<List<double>> approach = const [];
      List<NavStep> approachSteps = const [];
      var approachDistM = 0.0;
      final needApproach = prog.crossTrackM > 25 || skipAheadM > 0;
      if (needApproach) {
        // Rejoin-Profil: bevorzugter Sport / aktives Bike, nicht immer MTB.
        final preferred = ref.read(userProfileStoreProvider).preferredSport;
        final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
        Bike? active;
        for (final b in bikes) {
          if (b.isActive) {
            active = b;
            break;
          }
        }
        active ??= bikes.isEmpty ? null : bikes.first;
        final rejoinProfile = routingProfileForBike(
          active?.category ?? preferred ?? BikeCategory.mtbAm,
        );
        final result = await ref
            .read(routeRepositoryProvider)
            .planRoute(
              from: GeoPoint(lastFix.lat, lastFix.lng),
              to: GeoPoint(rejoinPt[1], rejoinPt[0]),
              profile: rejoinProfile,
            );
        approach = result.coordinates.map((p) => [p.lng, p.lat]).toList();
        approachDistM = result.distanceM;
        approachSteps = result.steps
            .map(
              (st) => NavStep(
                id: st.id,
                instruction: st.instruction,
                distanceAlongM: st.distanceAlongM,
                streetName: st.streetName,
              ),
            )
            .toList();
      }

      final merged = <List<double>>[...approach, ...remaining];
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
      final snapshot = route;
      final why = skipAheadM > 0
          ? 'Abschnitt übersprungen — zurück zur Route.'
          : 'Zurück zur Route.';
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
            if (st.distanceAlongM >= stepCutoff)
              NavStep(
                id: st.id,
                instruction: st.instruction,
                distanceAlongM: (st.distanceAlongM - stepCutoff + approachDistM)
                    .clamp(0, double.infinity),
                streetName: st.streetName,
              ),
        ],
        poiStops: route.poiStops,
        // Rejoin splice is typically open (approach + remainder).
        isLoop: false,
      );
      _startUndoWindow(snapshot);
      setState(() {
        _offRoute = false;
        _offRouteBanner = null;
        _userChoseStay = false;
        _alongRouteM = 0;
        _rejoinWhyLine = why;
      });
      if (!_ttsMuted) {
        unawaited(
          _tts.speak(
            skipAheadM > 0 ? 'Abschnitt übersprungen' : 'Zurück zur Route',
          ),
        );
      }
      unawaited(_drawRideMap());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rejoin fehlgeschlagen: $e')));
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
        ref
            .read(rideChunkRepositoryProvider)
            .uploadPending(rideId: uploadRideId),
      );
    }
    await _sensorSub?.cancel();
    await _bleSub?.cancel();
    await _locSub?.cancel();
    _tick?.cancel();
    _idleLock?.cancel();
    await ref.read(sensorCoreProvider).stop();
    await ref.read(bleCoreProvider).disconnectBikeKeepWatch();
    await ref.read(locationCoreProvider).stopRideTracking();

    final started = _startedAt ?? DateTime.now();
    final ended = DateTime.now();
    var distanceM = ref.read(rideDistanceMProvider);
    final elapsed = ref.read(rideElapsedSecProvider);
    final route = ref.read(activeRouteProvider);
    final bike = await ref.read(garageRepositoryProvider).getActiveBike();
    final bikeId = bike?.id ?? 'unknown';

    var track = List<TrackPoint>.from(_track);

    // Sim-Meter nie persistieren; Track-Haversine nicht als Override bei Sim.
    if (_simMotionUsed) {
      distanceM = math.max(0, distanceM - _simDistanceM);
      if (!_usingGps) {
        track = const [];
        distanceM = 0;
      }
    } else {
      final trackDist = _distanceAlongTrackM(track);
      if (trackDist > distanceM + 15) {
        distanceM = trackDist;
      }
    }

    final elevFromRoute = route?.elevationM;
    final elevFromTrack = _elevationGainFromTrack(track);
    final elevHonest = elevFromRoute != null && elevFromRoute > 0
        ? elevFromRoute
        : elevFromTrack;
    final elevSource = elevFromRoute != null && elevFromRoute > 0
        ? 'route'
        : (elevFromTrack > 0 ? 'gps_track' : 'none');

    final record = await ref
        .read(rideRepositoryProvider)
        .endRide(
          id: _rideId,
          bikeId: bikeId,
          startedAt: started,
          endedAt: ended,
          distanceKm: distanceM / 1000,
          movingTimeSec: elapsed,
          name: route?.name ?? 'Freeride',
          routeId: route?.id,
          elevationM: elevHonest,
          track: track,
          summary: {
            'peakG': _peakG,
            'avgFlow': _flowN == 0 ? null : _flowSum / _flowN,
            'usingGps': _usingGps,
            'gpsStallSim': _simMotionUsed,
            'simDistanceM': _simDistanceM,
            'trackPoints': track.length,
            'elevationSource': elevSource,
            if (_ldi?.batterySocPercent != null) 'soc': _ldi!.batterySocPercent,
          },
        );

    // E-Bike Reichweiten-Kalibrierung wenn genug Distanz + SOC-Delta
    final isEbike = bike?.hasElectricAssist == true;
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
      final prev =
          store.rangeCalibration ??
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
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    await _notifActionSub?.cancel();
    _notifActionSub = null;
    ref.invalidate(bikesProvider);
    ref.invalidate(recentRidesProvider);
    ref.invalidate(rideStatsProvider);
    _clearUndoRejoin();
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
      _offRoute = false;
      _offRouteBanner = null;
      _userChoseStay = false;
      _rejoinWhyLine = null;
      _cleanMode = true;
      _lastFollowLat = null;
      _lastFollowLng = null;
      _lastFollowCameraAt = null;
    });

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostRideScreen(rideId: record.id),
      ),
    );
    if (!mounted) return;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.hof;
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _bleSub?.cancel();
    _locSub?.cancel();
    _lightSub?.cancel();
    _tick?.cancel();
    _idleLock?.cancel();
    _undoRejoinTimer?.cancel();
    _connectivityTimer?.cancel();
    _notifActionSub?.cancel();
    unawaited(_tts.stop());
    unawaited(WakelockPlus.disable());
    // Stop CSC reconnect when leaving Ride.
    unawaited(ref.read(bleCoreProvider).disconnectBikeKeepWatch());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(rideAutostartProvider, (prev, next) {
      if (next != true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _consumeRideAutostart();
      });
    });

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

    // Map-first: no AppBar on pre-ride or Clean HUD (N-START-01 / N-HUD-01).
    final hideAppBar = !riding || (riding && _cleanMode);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: hideAppBar
            ? null
            : AppBar(
                title: Text(riding ? 'Live-Fahrt' : 'Bereit'),
                actions: [
                  if (riding) ...[
                    IconButton(
                      tooltip: _cameraFollow
                          ? 'Kamera-Follow an'
                          : 'Kamera frei',
                      onPressed: () {
                        setState(() => _cameraFollow = !_cameraFollow);
                        if (_cameraFollow) unawaited(_drawRideMap());
                      },
                      icon: Icon(
                        _cameraFollow
                            ? Icons.my_location
                            : Icons.location_searching,
                        color: _cameraFollow ? AppColors.accent : null,
                      ),
                    ),
                    IconButton(
                      tooltip: _northUp ? 'Norden oben' : 'Fahrtrichtung oben',
                      onPressed: () {
                        setState(() => _northUp = !_northUp);
                        if (_cameraFollow) unawaited(_drawRideMap());
                      },
                      icon: Icon(
                        _northUp ? Icons.explore : Icons.navigation,
                        color: !_northUp ? AppColors.accent : null,
                      ),
                    ),
                  ],
                  if (riding && route != null)
                    IconButton(
                      tooltip: _autoRerouteEnabled
                          ? 'Auto-Reroute an'
                          : 'Auto-Reroute aus',
                      onPressed: () {
                        setState(
                          () => _autoRerouteEnabled = !_autoRerouteEnabled,
                        );
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
                      _syncRideNotification();
                    },
                    icon: Icon(
                      _ttsMuted
                          ? Icons.volume_off_outlined
                          : Icons.volume_up_outlined,
                    ),
                  ),
                  if (riding)
                    IconButton(
                      tooltip: 'Display: ${_batteryPreset.titleDe}',
                      onPressed: () => unawaited(_showBatteryPresetPicker()),
                      icon: Icon(
                        _batteryPreset.keepScreenOn
                            ? Icons.battery_alert_outlined
                            : Icons.battery_saver_outlined,
                        color: _batteryPreset.costsBattery
                            ? Colors.orange.shade800
                            : null,
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
          child: riding
              ? _buildLiveHud(
                  theme: theme,
                  route: route,
                  layer: layer,
                  mount: mount,
                  paused: paused,
                  locked: locked,
                  elapsed: elapsed,
                  distanceM: distanceM,
                )
              : _buildPreRideMap(route: route),
        ),
      ),
    );
  }

  /// N-START-01: map paints first; one primary Losfahren CTA. No sensor checklist.
  Widget _buildPreRideMap({
    required ActiveRoute? route,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: MapLibreMap(
            key: ValueKey('ride-map-${_onlineStyleFor(_mapTarget(route))}'),
            styleString: _onlineStyleFor(_mapTarget(route)),
            initialCameraPosition: CameraPosition(
              target: _mapTarget(route),
              zoom: route != null ? 12.5 : 5.8,
            ),
            myLocationEnabled: true,
            trackCameraPosition: false,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: _rideMapGestures,
            onMapCreated: (c) {
              _rideMap = c;
            },
            onStyleLoadedCallback: () {
              unawaited(_drawRideMap());
            },
          ),
        ),
        const StatusBarScrim(),
        RidePreStartChrome(
          routeName: route?.name,
          starting: _starting,
          onClearRoute: route == null
              ? null
              : () {
                  ref.read(activeRouteProvider.notifier).state = null;
                },
          onStart: () {
            _bumpIdle();
            unawaited(_start());
          },
        ),
      ],
    );
  }

  Widget _buildLiveHud({
    required ThemeData theme,
    required ActiveRoute? route,
    required RideLiveLayer layer,
    required MountCheck mount,
    required bool paused,
    required bool locked,
    required int elapsed,
    required double distanceM,
  }) {
    ({String distance, String instruction, String iconName, String? street})?
        navParts;
    if (route != null && route.coordinates.length >= 4) {
      if (route.steps.isNotEmpty) {
        final nxt = nextRouteStep(route.steps, _alongRouteM);
        if (nxt != null) {
          final cue = NavCue(
            id: nxt.step.id,
            distanceAlongM: nxt.step.distanceAlongM,
            instruction: nxt.step.instruction,
            bearingDeg: 0,
          );
          final parts = cueBannerParts(cue, nxt.remainingM.round());
          final street = nxt.step.streetName?.trim().isNotEmpty == true
              ? nxt.step.streetName!.trim()
              : extractStreetNameFromInstruction(nxt.step.instruction);
          navParts = (
            distance: parts.distance,
            instruction: parts.instruction,
            iconName: navTurnIconName(nxt.step.instruction),
            street: street,
          );
        }
      } else {
        final cues = buildNavCues(route.coordinates);
        final nxt = nextCue(cues, _alongRouteM);
        if (nxt != null) {
          final parts = cueBannerParts(nxt.cue, nxt.remainingM);
          navParts = (
            distance: parts.distance,
            instruction: parts.instruction,
            iconName: navTurnIconName(nxt.cue.instruction),
            street: extractStreetNameFromInstruction(nxt.cue.instruction),
          );
        }
      }
    }

    IconData turnIcon(String name) => switch (name) {
      'flag' => Icons.flag,
      'turn_left' => Icons.turn_left,
      'turn_right' => Icons.turn_right,
      'turn_sharp_left' => Icons.turn_sharp_left,
      'turn_sharp_right' => Icons.turn_sharp_right,
      'turn_slight_left' => Icons.turn_slight_left,
      'turn_slight_right' => Icons.turn_slight_right,
      'straight' => Icons.straight,
      'u_turn_left' => Icons.u_turn_left,
      _ => Icons.navigation,
    };

    // Rest km + ETA for data strip (route-aware).
    final restKm = route != null
        ? math.max(0.0, route.distanceKm - (_alongRouteM / 1000))
        : null;
    final speed = _effectiveSpeedKmh;
    String etaLabel;
    if (restKm != null && speed > 3) {
      final etaMin = (restKm / speed * 60).round();
      final etaAt = DateTime.now().add(Duration(minutes: etaMin));
      etaLabel =
          '${etaAt.hour.toString().padLeft(2, '0')}:${etaAt.minute.toString().padLeft(2, '0')}';
    } else if (restKm != null && route!.durationMin > 0) {
      final frac = route.distanceKm > 0
          ? (_alongRouteM / 1000 / route.distanceKm).clamp(0.0, 1.0)
          : 0.0;
      final remainMin = (route.durationMin * (1 - frac)).round();
      final etaAt = DateTime.now().add(Duration(minutes: remainMin));
      etaLabel =
          '${etaAt.hour.toString().padLeft(2, '0')}:${etaAt.minute.toString().padLeft(2, '0')}';
    } else {
      etaLabel = _fmt(elapsed);
    }

    final midValue = restKm != null
        ? (restKm < 10 ? restKm.toStringAsFixed(1) : restKm.toStringAsFixed(0))
        : (distanceM < 1000
              ? (distanceM / 1000).toStringAsFixed(2)
              : (distanceM / 1000).toStringAsFixed(1));
    // nav-hud-tokens-v1 Clean labels: Speed · Rest-km · ETA
    final midLabel =
        restKm != null ? NavHudTokens.labelRestKm : 'km';
    final rightLabel =
        restKm != null ? NavHudTokens.labelEta : 'Zeit';
    final speedCaption =
        restKm != null ? NavHudTokens.labelSpeed : 'km/h';

    return Stack(
      children: [
        Positioned.fill(
          child: layer == RideLiveLayer.map
              ? MapLibreMap(
                  key: ValueKey('ride-map-${_onlineStyleFor(_mapTarget(route))}'),
                  styleString: _onlineStyleFor(_mapTarget(route)),
                  initialCameraPosition: CameraPosition(
                    target: _mapTarget(route),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  trackCameraPosition: false,
                  compassEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  gestureRecognizers: _rideMapGestures,
                  onMapCreated: (c) {
                    _rideMap = c;
                  },
                  onStyleLoadedCallback: () {
                    unawaited(_drawRideMap());
                  },
                  // Manuelles Schieben/Zoomen: Follow pausieren (wie Komoot).
                  onCameraIdle: () {
                    if (_programmaticCamera) return;
                    if (!ref.read(isRidingProvider)) return;
                    if (!_cameraFollow) return;
                    setState(() => _cameraFollow = false);
                  },
                )
              : ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: Padding(
                    // Platz für Top-Bar/Bottom-Controls-Overlay.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      88,
                      AppSpacing.l,
                      160,
                    ),
                    child: _buildLayer(layer, mount, route),
                  ),
                ),
        ),
        const StatusBarScrim(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.s,
              AppSpacing.m,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clean Mode = exactly 4 HUD elements (next-turn · Speed ·
                // Rest-km · ETA). No trust-strip chrome. Re-follow only when
                // the user panned the map; Pro chrome via data-strip tap.
                if (_cleanMode && !_cameraFollow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: theme.cardColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: IconButton(
                          tooltip: 'Kamera folgen',
                          onPressed: () {
                            setState(() => _cameraFollow = true);
                            unawaited(_drawRideMap());
                          },
                          icon: const Icon(
                            Icons.my_location,
                            size: 22,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!_cleanMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: Row(
                      children: [
                        Material(
                          color: theme.cardColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: IconButton(
                            tooltip: _ttsMuted ? 'TTS an' : 'TTS stumm',
                            onPressed: () {
                              setState(() => _ttsMuted = !_ttsMuted);
                              if (_ttsMuted) unawaited(_tts.stop());
                              _syncRideNotification();
                            },
                            icon: Icon(
                              _ttsMuted
                                  ? Icons.volume_off_outlined
                                  : Icons.volume_up_outlined,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Material(
                          color: theme.cardColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: IconButton(
                            tooltip: _northUp
                                ? 'Norden oben'
                                : 'Fahrtrichtung oben',
                            onPressed: () {
                              setState(() => _northUp = !_northUp);
                              if (_cameraFollow) unawaited(_drawRideMap());
                            },
                            icon: Icon(
                              _northUp ? Icons.explore : Icons.navigation,
                              size: 22,
                              color: !_northUp ? AppColors.accent : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (!_cameraFollow)
                          Material(
                            color: theme.cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: IconButton(
                              tooltip: 'Kamera folgen',
                              onPressed: () {
                                setState(() => _cameraFollow = true);
                                unawaited(_drawRideMap());
                              },
                              icon: const Icon(
                                Icons.my_location,
                                size: 22,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        if (connectivityChipVisibleInClean(_connectivityState))
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RideConnectivityChip(
                                state: _connectivityState,
                                compact: true,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Material(
                          color: theme.cardColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: IconButton(
                            tooltip:
                                'Display: ${_batteryPreset.titleDe}${_batteryPreset.costsBattery ? ' (kostet Akku)' : ''}',
                            onPressed: () =>
                                unawaited(_showBatteryPresetPicker()),
                            icon: Icon(
                              _batteryPreset.keepScreenOn
                                  ? Icons.battery_alert_outlined
                                  : _batteryPreset.wakeOnCue
                                  ? Icons.battery_charging_full
                                  : Icons.battery_saver_outlined,
                              size: 22,
                              color: _batteryPreset.costsBattery
                                  ? Colors.orange.shade800
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (navParts != null)
                  RideNextTurnBanner(
                    distance: navParts.distance,
                    instruction: navParts.instruction,
                    icon: turnIcon(navParts.iconName),
                    street: navParts.street,
                    maneuver: maneuverLabelFromInstruction(
                      navParts.instruction,
                    ),
                  )
                else if (route != null)
                  Material(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    color: theme.cardColor.withValues(alpha: 0.92),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.navigation, size: 20),
                      title: Text(
                        route.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (route.isLoop) 'Rundkurs',
                          '${route.distanceKm} km',
                          '${route.elevationM.round()} hm',
                        ].join(' · '),
                      ),
                    ),
                  ),
                // N-07: one-line upcoming peek under next-turn.
                if (route != null) _buildUpcomingRail(route),
                // Status: off-route / rejoin why / GPS (one strip only).
                _buildStatusStrip(theme),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pro / layer switcher only outside Clean Mode.
              if (!_cleanMode) ...[
                const HofWatchCard(compact: true),
                const SizedBox(height: AppSpacing.s),
                SegmentedButton<RideLiveLayer>(
                  segments: [
                    ButtonSegment(
                      value: RideLiveLayer.map,
                      label: Text(AppLocalizations.of(context).rideMap),
                      icon: const Icon(Icons.map),
                    ),
                    ButtonSegment(
                      value: RideLiveLayer.data,
                      label: Text(AppLocalizations.of(context).rideData),
                      icon: const Icon(Icons.grid_view),
                    ),
                    if (_showsChassisUx(ref))
                      ButtonSegment(
                        value: RideLiveLayer.suspension,
                        label: Text(
                          AppLocalizations.of(context).chassisLayerLabelFor(
                            ref.watch(userProfileStoreProvider).preferredSport,
                          ),
                        ),
                        icon: const Icon(Icons.waves),
                      ),
                  ],
                  selected: {
                    layer == RideLiveLayer.suspension && !_showsChassisUx(ref)
                        ? RideLiveLayer.map
                        : layer,
                  },
                  onSelectionChanged: (s) {
                    _bumpIdle();
                    ref.read(rideLayerProvider.notifier).state = s.first;
                  },
                ),
                const SizedBox(height: AppSpacing.s),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _cleanMode = true),
                    child: const Text('Ruhige Anzeige'),
                  ),
                ),
              ],
              RideDataStrip(
                speedLabel: speed.toStringAsFixed(0),
                speedCaption: speedCaption,
                midValue: midValue,
                midLabel: midLabel,
                rightValue: etaLabel,
                rightLabel: rightLabel,
                onTap: () {
                  // Pro data without polluting Clean default.
                  _bumpIdle();
                  setState(() => _cleanMode = !_cleanMode);
                },
              ),
              const SizedBox(height: AppSpacing.s),
              // Clean: Pause only. Finish after Pause → confirm (brief).
              if (paused || !_cleanMode)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: () {
                          _bumpIdle();
                          final wasPaused = paused;
                          ref.read(isPausedProvider.notifier).state = !paused;
                          if (wasPaused) setState(() => _confirmStop = 0);
                          _syncRideNotification();
                        },
                        child: Text(
                          paused ? 'Weiter' : 'Pause',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _confirmStop > 0
                              ? Colors.red
                              : Colors.redAccent,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: () async {
                          _bumpIdle();
                          await _stop();
                        },
                        child: Text(
                          _confirmStop > 0 ? 'Nochmal tippen' : 'Stop',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                )
              else
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () {
                    _bumpIdle();
                    setState(() => _confirmStop = 0);
                    ref.read(isPausedProvider.notifier).state = true;
                    _syncRideNotification();
                  },
                  child: const Text(
                    'Pause',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              if (paused && _confirmStop == 0)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Beenden erfordert 2 Tipps',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
        if (locked)
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
                    SizedBox(height: AppSpacing.m),
                    Text(
                      'Auto-Lock',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('Doppeltipp zum Aufwecken'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// N-07 / nav-hud-tokens-v1: compact line under next-turn if stop <15 min.
  /// Does not count as a fifth Clean Mode HUD element.
  Widget _buildUpcomingRail(ActiveRoute route) {
    String? nextNextInstr;
    double? nextNextRemain;
    if (route.steps.isNotEmpty) {
      final remaining =
          route.steps.where((s) => s.distanceAlongM > _alongRouteM + 5).toList()
            ..sort((a, b) => a.distanceAlongM.compareTo(b.distanceAlongM));
      if (remaining.length >= 2) {
        final second = remaining[1];
        final street = second.streetName?.trim().isNotEmpty == true
            ? second.streetName!.trim()
            : extractStreetNameFromInstruction(second.instruction);
        nextNextInstr = street ?? second.instruction;
        nextNextRemain = second.distanceAlongM - _alongRouteM;
      }
    } else if (route.coordinates.length >= 4) {
      final cues = buildNavCues(route.coordinates);
      final ahead = cues
          .where((c) => c.distanceAlongM > _alongRouteM + 5)
          .toList();
      if (ahead.length >= 2) {
        nextNextInstr = ahead[1].instruction;
        nextNextRemain = ahead[1].distanceAlongM - _alongRouteM;
      }
    }

    final totalM = route.distanceKm * 1000;
    final poi = nextPoiStop(
      stops: [
        for (final p in route.poiStops)
          RoutePoiStop(atMin: p.atMin, title: p.title, kind: p.kind),
      ],
      alongRouteM: _alongRouteM,
      totalDistanceM: totalM,
      durationMin: route.durationMin,
    );

    final speed = _effectiveSpeedKmh;
    final turnEta = nextNextRemain == null
        ? null
        : etaMinForDistanceM(nextNextRemain, speedKmh: speed);
    final poiEta = poi == null
        ? null
        : poiEtaMin(
            poi: poi,
            alongRouteM: _alongRouteM,
            totalDistanceM: totalM,
            durationMin: route.durationMin,
          );

    final item = buildUpcomingRail(
      nextNextTurnInstruction: nextNextInstr,
      nextNextTurnRemainingM: nextNextRemain,
      nextNextTurnEtaMin: turnEta,
      nextPoi: poi,
      nextPoiEtaMin: poiEta,
      remainingClimbM: null,
    );
    if (item == null) return const SizedBox.shrink();
    return RideUpcomingRail(item: item);
  }

  /// Eine Statuszeile statt gestapelter Banner. Priorität (höchste zuerst):
  /// Reroute läuft → Undo Rejoin → Abseits der Route → GPS → Hinweis.
  Widget _buildStatusStrip(ThemeData theme) {
    if (_autoRerouteBusy) {
      return RideOffRouteBanner(
        title: 'Route wird neu berechnet …',
        background: Colors.orange.shade100,
        foreground: Colors.orange.shade900,
      );
    }
    if (_routeBeforeRejoin != null && _rejoinWhyLine != null) {
      return RideOffRouteBanner(
        title: _rejoinWhyLine!,
        subtitle: '10 s Rückgängig',
        actionLabel: 'Rückgängig',
        onAction: () {
          _bumpIdle();
          _undoRejoin();
        },
        background: Colors.green.shade50,
        foreground: Colors.green.shade900,
      );
    }
    if (_offRouteBanner != null) {
      return RideOffRouteBanner(
        title: 'Abseits der Route.',
        subtitle: _userChoseStay
            ? 'Du bleibst abseits — tippe für Optionen.'
            : (_autoRerouteEnabled ? 'Neu berechnen …' : 'Tippe für Optionen.'),
        actionLabel: _userChoseStay ? 'Optionen' : 'Zurück zur Route',
        onAction: () {
          _bumpIdle();
          if (_userChoseStay) {
            setState(() => _userChoseStay = false);
            unawaited(_showRerouteSheetIfNeeded());
          } else {
            unawaited(_rejoinRoute());
          }
        },
      );
    }
    if (_gpsStatus != null) {
      return RideOffRouteBanner(
        title: _gpsStatus!,
        background: Colors.orange.shade50,
        foreground: Colors.orange.shade800,
        compact: true,
      );
    }
    if (_liveHintText != null && !_cleanMode) {
      return RideOffRouteBanner(
        title: _liveHintText!,
        background: Colors.orange.shade50,
        foreground: Colors.orange.shade800,
        compact: true,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLayer(
    RideLiveLayer layer,
    MountCheck mount,
    ActiveRoute? route,
  ) {
    switch (layer) {
      case RideLiveLayer.map:
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: MapLibreMap(
            key: ValueKey(_onlineStyleFor(_mapTarget(route))),
            styleString: _onlineStyleFor(_mapTarget(route)),
            initialCameraPosition: CameraPosition(
              target: _mapTarget(route),
              zoom: 14,
            ),
            myLocationEnabled: true,
            trackCameraPosition: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: _rideMapGestures,
            onMapCreated: (c) {
              _rideMap = c;
            },
            onStyleLoadedCallback: () {
              unawaited(_drawRideMap());
            },
          ),
        );
      case RideLiveLayer.data:
        final ble = ref.read(bleCoreProvider);
        final bleConnected = ble.isConnected;
        final bleSpeed = _ldi?.speedKmh;
        final bleCadence = _ldi?.cadenceRpm;
        return Semantics(
          label: AppLocalizations.of(context).rideLiveData,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  _MetricRow(
                    'Tempo',
                    '${_effectiveSpeedKmh.toStringAsFixed(1)} km/h',
                  ),
                  if (bleConnected && bleSpeed != null && bleSpeed > 0.3)
                    _MetricRow(
                      'Sensor-Tempo',
                      '${bleSpeed.toStringAsFixed(1)} km/h',
                    ),
                  _MetricRow(
                    'Distanz',
                    '${(ref.read(rideDistanceMProvider) / 1000).toStringAsFixed(2)} km',
                  ),
                  _MetricRow('Zeit', _fmt(ref.read(rideElapsedSecProvider))),
                  if (_ldi?.batterySocPercent != null)
                    _MetricRow(
                      'SoC',
                      '${_ldi!.batterySocPercent!.toStringAsFixed(0)} %',
                    ),
                  if (_ldi?.riderPowerW != null)
                    _MetricRow(
                      'Leistung',
                      '${_ldi!.riderPowerW!.toStringAsFixed(0)} W',
                    ),
                  if (_ldi?.assistMode != null &&
                      _ldi!.assistMode!.trim().isNotEmpty)
                    _MetricRow('Assist', _ldi!.assistMode!),
                  if (_ldi?.heartRateBpm != null)
                    _MetricRow(
                      'Puls',
                      '${_ldi!.heartRateBpm!.toStringAsFixed(0)} bpm',
                    ),
                  _MetricRow(
                    'Kadenz',
                    bleConnected && bleCadence != null && bleCadence > 0
                        ? '${bleCadence.toStringAsFixed(0)} rpm'
                        : '—',
                  ),
                  _MetricRow(
                    'Radsensor',
                    bleConnected
                        ? (ble.connectedDeviceName ?? 'Verbunden')
                        : 'Nicht verbunden',
                  ),
                  if (ble.isWatchConnected)
                    _MetricRow(
                      'Smartwatch',
                      [
                        ble.connectedWatchName ?? 'Verbunden',
                        if (_ldi?.heartRateBpm != null)
                          '${_ldi!.heartRateBpm!.round()} bpm'
                        else
                          'Puls wartet',
                      ].join(' · '),
                    ),
                ],
              ),
            ),
          ),
        );
      case RideLiveLayer.suspension:
        if (mount != MountCheck.mounted) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Fahrwerksanalyse aus',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  const Text(
                    'Handy am Lenker befestigen und als montiert markieren.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.m),
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
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              children: [
                if (_metrics != null) ...[
                  _MetricRow('G-Peak', _metrics!.gForcePeak.toStringAsFixed(2)),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
