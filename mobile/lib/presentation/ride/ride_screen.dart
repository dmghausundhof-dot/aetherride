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
import '../../core/errors/friendly_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/nav_hud_tokens.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/routing/basemap_street_contrast.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/offline_basemap.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/routing_client.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/active_route.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/bike.dart';
import '../../domain/ble.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../../domain/ble/ride_ble_samples.dart';
import '../../domain/ebike/range.dart';
import '../../domain/hud_bike_peek.dart';
import '../../domain/hud_media.dart';
import '../../domain/ride.dart';
import '../../domain/ride_auto_lock.dart';
import '../../domain/routing/battery_preset.dart';
import '../../domain/routing/camera_follow_smooth.dart';
import '../../domain/routing/connectivity_chip.dart';
import '../../domain/routing/nav_announce.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/nav_map_paint.dart';
import '../../domain/routing/nav_policy.dart';
import '../../domain/routing/ride_nav_honesty.dart';
import '../../domain/routing/route_progress.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../domain/routing/upcoming_rail.dart';
import '../../domain/sensor.dart';
import '../../domain/sensor/live_hints.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../native/hud_media_channel.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../map/nav_puck_image.dart';
import '../map/nav_puck_overlay.dart';
import '../post_ride/post_ride_screen.dart';
import '../shared/map_ornaments.dart';
import '../shared/status_bar_scrim.dart';
import '../shell/shell_tabs.dart';
import 'widgets/battery_preset_sheet.dart';
import 'widgets/reroute_sheet.dart';
import 'widgets/ride_auto_lock_overlay.dart';
import 'widgets/ride_bike_peek.dart';
import 'widgets/ride_compass_chip.dart';
import 'widgets/ride_connectivity_chip.dart';
import 'widgets/ride_data_strip.dart';
import 'widgets/ride_media_chip.dart';
import 'widgets/ride_network.dart';
import 'widgets/ride_next_turn_banner.dart';
import 'widgets/ride_off_route_banner.dart';
import 'widgets/ride_group_pin_banner.dart';
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

  /// Sticky: crank CSC streamed this ride — 0 rpm at a stoplight stays valid.
  bool _hasCrank = false;
  final RideBleSamples _bleSamples = RideBleSamples();
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
  String? _liveHintId;
  int? _liveHintN;
  int _hardImpactStreak = 0;
  double _standSeconds = 0;
  double _prevPeakG = 0;
  double? _startSoc;

  final HudMediaChannel _hudMedia = HudMediaChannel();
  StreamSubscription<HudNowPlaying>? _mediaSub;
  HudNowPlaying _nowPlaying = HudNowPlaying.idle;
  bool _mediaPromptDismissed = false;
  DateTime? _mediaOptimisticUntil;

  MapLibreMapController? _rideMap;
  final NavPuckOverlay _navPuck = NavPuckOverlay();
  UserLocation? _lastUserLoc;
  int _mapDrawSkip = 0;
  int _rideMapDrawGen = 0;
  final RideGroupStore _rideGroups = RideGroupStore();
  DateTime? _lastGroupPresenceAt;
  Timer? _groupPinPoll;
  String _mapStyle = AppConfig.mapStyleUrl;
  bool _bikeOverlayAttached = false;
  bool _offRoute = false;
  String? _offRouteBanner;
  DateTime? _lastAutoRerouteAt;
  bool _autoRerouteBusy = false;

  /// User chose „Bleiben“ — no forced rejoin until they leave route again.
  bool _userChoseStay = false;
  bool _rerouteSheetOpen = false;
  bool _gravityFollowSpoken = false;

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
  DateTime? _lastHudHeadingAt;
  double _lastHudHeadingPaint = 0;

  /// N-04/N-09: default Pocket = no Keep-Screen-On.
  RideBatteryPreset _batteryPreset = RideBatteryPreset.pocket;

  /// Map / HUD nav mark. Default Berg-A until RidePrefs loads.
  NavPuckStyle _navPuckStyle = NavPuckStyle.chevron;

  /// N-03/N-08 connectivity honesty.
  bool _networkOnline = true;
  bool _offlineMapAvailable = false;
  ConnectivityChipState _connectivityState = ConnectivityChipState.live;
  Timer? _connectivityTimer;
  StreamSubscription<RideNotificationAction>? _notifActionSub;

  /// Distanz entlang Active Route (Nav); Odometer bleibt [rideDistanceMProvider].
  double _alongRouteM = 0;
  double _crossTrackM = 0;
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

  String? _ttsLangTag;

  @override
  void initState() {
    super.initState();
    unawaited(_initTts());
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLocaleBinding.sync(context);
    final tag = AppLocaleBinding.ttsLanguageTag();
    if (_ttsLangTag != tag) {
      _ttsLangTag = tag;
      unawaited(_initTts());
    }
  }

  void _consumeRideAutostart() {
    if (ref.read(rideAutostartProvider) != true) return;
    ref.read(rideAutostartProvider.notifier).state = false;
    if (ref.read(isRidingProvider) || _starting) return;
    unawaited(_start());
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage(AppLocaleBinding.ttsLanguageTag());
      await _tts.setSpeechRate(0.5);
      await _tts.setAudioAttributesForNavigation();
    } catch (_) {}
  }

  /// Nav / hints: duck background music (Android `focus: true`).
  Future<void> _speakHud(String text) async {
    if (_ttsMuted || text.trim().isEmpty) return;
    try {
      await _tts.setAudioAttributesForNavigation();
    } catch (_) {}
    if (!mounted || _ttsMuted) return;
    try {
      await _tts.speak(text, focus: true);
    } catch (_) {}
  }

  Future<void> _startHudMedia() async {
    if (!mounted) return;
    await _mediaSub?.cancel();
    _mediaSub = _hudMedia.nowPlaying.listen((np) {
      if (!mounted) return;
      if (np.active || np.musicActive) {
        _mediaOptimisticUntil = null;
      }
      if (np == _nowPlaying) return;
      setState(() => _nowPlaying = np);
    });
    await _hudMedia.startWatching();
    if (!mounted) await _stopHudMedia();
  }

  Future<void> _stopHudMedia() async {
    await _mediaSub?.cancel();
    _mediaSub = null;
    _mediaOptimisticUntil = null;
    if (mounted) {
      setState(() => _nowPlaying = HudNowPlaying.idle);
    } else {
      _nowPlaying = HudNowPlaying.idle;
    }
    await _hudMedia.stopWatching();
  }

  void _onHudPlayPause() {
    _bumpIdle();
    final playing =
        _nowPlaying.playing || (!_nowPlaying.active && _nowPlaying.musicActive);
    if (playing && !_nowPlaying.active) {
      _mediaOptimisticUntil = DateTime.now().add(const Duration(seconds: 90));
      setState(() {
        _nowPlaying = _nowPlaying.copyWith(playing: false, musicActive: false);
      });
    }
    unawaited(_hudMedia.playPause());
  }

  /// System-back: Auto-Lock zuerst schließen, sonst Pause, sonst Stop.
  /// Direkt nach Losfahren kein Post-Ride — sonst landet Play auf Aktivität.
  bool handleSystemBack() {
    if (!mounted) return false;
    if (_starting) return true;
    if (ref.read(autoLockedProvider)) {
      _bumpIdle();
      return true;
    }
    if (ref.read(isRidingProvider)) {
      final started = _startedAt;
      final age =
          started == null ? Duration.zero : DateTime.now().difference(started);
      if (age < const Duration(milliseconds: 1500)) {
        return true;
      }
      if (!ref.read(isPausedProvider)) {
        ref.read(isPausedProvider.notifier).state = true;
        _confirmStop = 0;
        _syncRideNotification();
        if (mounted) setState(() {});
        return true;
      }
      unawaited(_stop());
      return true;
    }
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    return true;
  }

  Future<void> _loadRidePrefs() async {
    final preset = await RidePrefs.batteryPreset();
    final puck = NavPuckStyleX.fromId(await RidePrefs.navPuckStyleId());
    final mapOk = await _probeOfflineMapAvailable();
    final mediaDismissed = await RidePrefs.hudMediaPromptDismissed();
    if (!mounted) return;
    setState(() {
      _batteryPreset = preset;
      _navPuckStyle = puck;
      _offlineMapAvailable = mapOk;
      _mediaPromptDismissed = mediaDismissed || _mediaPromptDismissed;
    });
    final c = _rideMap;
    if (c != null) unawaited(_navPuck.setStyle(c, puck));
  }

  /// True only with a MapLibre OfflineRegion or an explicit local style.
  /// A routing graph without basemap tiles is not an offline map.
  Future<bool> _probeOfflineMapAvailable() async {
    if (await OfflineBasemap.hasAnyRegion()) return true;
    try {
      final m = await OfflineMapsPrefs.read();
      if (m['basemapReady'] == true) return true;
      final style = (m['pmtilesUrl'] as String?)?.trim() ?? '';
      if (style.isEmpty) return false;
      if (style.startsWith('file:') ||
          style.startsWith('/') ||
          style.contains('asset://') ||
          style.startsWith('pmtiles://')) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshConnectivityChip() async {
    final online = await rideHasNetwork();
    unawaited(OfflineBasemap.applyNetworkMode(online: online));
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

  Future<void> _applyNavPuckStyle(NavPuckStyle style) async {
    await RidePrefs.setNavPuckStyleId(style.id);
    if (!mounted) return;
    setState(() => _navPuckStyle = style);
    final c = _rideMap;
    if (c != null) unawaited(_navPuck.setStyle(c, style));
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
        content: Text(_l10n.batteryPresetSnack(picked)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _syncRideNotification() {
    if (!mounted) return;
    final location = ref.read(locationCoreProvider);
    final paused = ref.read(isPausedProvider);
    final text = paused ? _l10n.ridePause : _l10n.rideRunning;
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
      }).listen(_onAmbientLight, onError: (_) {});
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
    final loc = _lastUserLoc;
    if (loc != null) return loc.position;
    return null;
  }

  /// Kompass-Kurs zwischen zwei Lat/Lng-Punkten (0–360°).
  double _bearingDeg(double lat1, double lng1, double lat2, double lng2) {
    final lat1r = lat1 * math.pi / 180;
    final lat2r = lat2 * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2r);
    final x = math.cos(lat1r) * math.sin(lat2r) -
        math.sin(lat1r) * math.cos(lat2r) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// DACH+FR Übersicht bis GPS — kein Stadt-Fake.
  static const _regionOverview = LatLng(47.2, 6.5);

  LatLng _mapTarget(ActiveRoute? route) =>
      _mapTargetOrNull(route) ?? _regionOverview;

  void _onRideMapCreated(MapLibreMapController c) {
    _rideMap = c;
    _navPuck.reset();
  }

  Future<void> _onRideStyleLoaded() async {
    unawaited(OfflineBasemap.applyDetectedNetworkMode());
    final c = _rideMap;
    if (c == null) return;
    _bikeOverlayAttached = false;
    _navPuck.reset();
    if (styleNeedsGrayStreetBoost(_mapStyle)) {
      await boostBasemapStreetContrast(c);
    } else {
      await warmBasemapNatureFills(c);
    }
    await _navPuck.attach(c, style: _navPuckStyle);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      final map = _rideMap;
      if (map == null) return;
      unawaited(_navPuck.hideNativePuck(map));
    });
    await _ensureBikeOverlay();
    await _drawRideMap();
    await _syncNavPuck();
  }

  BikeOverlayFamily _rideOverlayFamily() {
    final bikes = ref.read(bikesProvider).valueOrNull ?? const <Bike>[];
    if (bikes.isNotEmpty) return overlayFamilyFromActiveBike(bikes);
    final sport = ref.read(userProfileStoreProvider).preferredSport;
    return overlayFamilyForBike(sport ?? BikeCategory.urban);
  }

  Set<BikeOverlayClass> _rideOverlayExtra(BikeOverlayFamily family) {
    return {...kAllPaintedOverlayClasses, ...overlayClassesForFamily(family)};
  }

  Future<void> _ensureBikeOverlay() async {
    final c = _rideMap;
    if (c == null) return;
    final family = _rideOverlayFamily();
    final extra = _rideOverlayExtra(family);
    if (_bikeOverlayAttached) {
      await applyBikeOverlayVisibility(
        c,
        family: family,
        visible: true,
        extraOn: extra,
      );
      return;
    }
    final route = ref.read(activeRouteProvider);
    final fromTrack = _track.isNotEmpty ? _track.last : null;
    final fromRoute = route != null && route.coordinates.isNotEmpty
        ? route.coordinates.first
        : null;
    final lng = fromTrack?.lng ?? fromRoute?[0] ?? 8.693;
    final lat = fromTrack?.lat ?? fromRoute?[1] ?? 49.409;
    final live = await attachLiveOsmNetworkLayers(c);
    final data = await resolveBikeOverlayData(lng: lng, lat: lat);
    if (data != null && mounted) {
      await attachBikeOverlayLayers(
        c,
        data: data,
        family: family,
        visible: true,
        extraOn: extra,
        sGradeOnly: live,
      );
    } else if (mounted) {
      await applyBikeOverlayVisibility(
        c,
        family: family,
        visible: true,
        extraOn: extra,
      );
    }
    _bikeOverlayAttached = true;
  }

  void _onUserLocationUpdated(UserLocation loc) {
    _lastUserLoc = loc;
    unawaited(_syncNavPuck());
    if (!mounted || !ref.read(isRidingProvider)) return;
    final h = _headingForPuck(loc);
    final now = DateTime.now();
    final moved = (h - _lastHudHeadingPaint).abs() >= 4;
    final stale = _lastHudHeadingAt == null ||
        now.difference(_lastHudHeadingAt!) > const Duration(milliseconds: 400);
    if (!moved && !stale) return;
    _lastHudHeadingPaint = h;
    _lastHudHeadingAt = now;
    setState(() {});
  }

  double _headingForPuck(UserLocation? user) {
    if (_track.length >= 2) {
      final a = _track[_track.length - 2];
      final b = _track.last;
      return _bearingDeg(a.lat, a.lng, b.lat, b.lng);
    }
    final gps = user?.bearing;
    if (gps != null && gps.abs() > 0.5) return gps;
    return user?.heading?.trueHeading ?? user?.heading?.magneticHeading ?? 0;
  }

  Widget _hudCompass() {
    return RideCompassChip(
      headingDeg: _headingForPuck(_lastUserLoc),
      northUp: _northUp,
      onToggle: () {
        _bumpIdle();
        setState(() => _northUp = !_northUp);
        if (_cameraFollow) unawaited(_drawRideMap());
      },
    );
  }

  Future<void> _syncNavPuck() async {
    final c = _rideMap;
    if (c == null) return;
    final loc = _lastUserLoc;
    final LatLng? at = loc?.position ??
        (_track.isNotEmpty ? LatLng(_track.last.lat, _track.last.lng) : null);
    if (at == null) return;
    await _navPuck.sync(
      c,
      at: at,
      iconRotateDeg: navPuckIconRotateDeg(
        headingDeg: _headingForPuck(loc),
        cameraBearingDeg: _lastAppliedCameraBearing,
        northUp: _northUp,
      ),
      style: _navPuckStyle,
    );
  }

  Future<void> _drawRideMap() async {
    final c = _rideMap;
    if (c == null) return;
    final gen = ++_rideMapDrawGen;
    try {
      await c.clearLines();
      if (gen != _rideMapDrawGen) return;
      final route = ref.read(activeRouteProvider);
      final trailish = (route?.mtbScale ?? '').trim().isNotEmpty;
      final framing = navFollowFraming(
        northUp: _northUp,
        trailish: trailish,
      );
      final zoomForPaint = _cameraFollow
          ? framing.zoom
          : (c.cameraPosition?.zoom ?? framing.zoom);
      final ribbon = navRibbonWidths(zoomForPaint);

      if (route != null && route.coordinates.length >= 2) {
        final layers = navPhaseRibbons(
          coordinates: route.coordinates,
          alongRouteM: _alongRouteM,
          joinAlongM: route.joinAlongM,
        );
        if (gen != _rideMapDrawGen) return;
        Future<void> addRibbon({
          required List<List<double>> coords,
          required String casing,
          required String core,
          required double casingW,
          required double coreW,
          required double casingOpacity,
          required double coreOpacity,
        }) async {
          if (coords.length < 2) return;
          final geom = [for (final p in coords) LatLng(p[1], p[0])];
          await c.addLine(
            LineOptions(
              geometry: geom,
              lineColor: casing,
              lineWidth: casingW,
              lineOpacity: casingOpacity,
              lineJoin: 'round',
            ),
          );
          if (gen != _rideMapDrawGen) return;
          await c.addLine(
            LineOptions(
              geometry: geom,
              lineColor: core,
              lineWidth: coreW,
              lineOpacity: coreOpacity,
              lineJoin: 'round',
            ),
          );
        }

        // Traveled first (under remaining). Approach ≠ tour green.
        await addRibbon(
          coords: layers.traveled,
          casing: NavMapColors.traveledCasing,
          core: NavMapColors.traveledCore,
          casingW: ribbon.traveledCasing,
          coreW: ribbon.traveledCore,
          casingOpacity: 0.45,
          coreOpacity: 0.7,
        );
        if (gen != _rideMapDrawGen) return;
        await addRibbon(
          coords: layers.approachRemaining,
          casing: NavMapColors.approachCasing,
          core: NavMapColors.approachCore,
          casingW: ribbon.remainingCasing * 0.92,
          coreW: ribbon.remainingCore * 0.92,
          casingOpacity: 0.9,
          coreOpacity: 1,
        );
        if (gen != _rideMapDrawGen) return;
        await addRibbon(
          coords: layers.tourRemaining,
          casing: NavMapColors.remainingCasing,
          core: NavMapColors.remainingCore,
          casingW: ribbon.remainingCasing,
          coreW: ribbon.remainingCore,
          casingOpacity: 0.95,
          coreOpacity: 1,
        );
      }
      if (gen != _rideMapDrawGen) return;
      if (_track.length >= 2) {
        final line = [for (final p in _track) LatLng(p.lat, p.lng)];
        // On-route: remaining/traveled already tell the story. GPS ribbon
        // only for Freeride or after leaving the line.
        final drawGps = route == null || _offRoute;
        if (drawGps) {
          await c.addLine(
            LineOptions(
              geometry: line,
              lineColor: NavMapColors.gpsCasing,
              lineWidth: ribbon.gpsCasing,
              lineOpacity: 0.85,
              lineJoin: 'round',
            ),
          );
          if (gen != _rideMapDrawGen) return;
          await c.addLine(
            LineOptions(
              geometry: line,
              lineColor: NavMapColors.gpsCore,
              lineWidth: ribbon.gpsCore,
              lineJoin: 'round',
            ),
          );
          if (gen != _rideMapDrawGen) return;
        }
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
            var target = last;
            if (route != null &&
                route.coordinates.length >= 2 &&
                !_offRoute &&
                framing.lookAheadM > 0) {
              final ahead = pointAlongRoute(
                route.coordinates,
                _alongRouteM + framing.lookAheadM,
              );
              target = LatLng(ahead[1], ahead[0]);
            }
            _programmaticCamera = true;
            await c.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: target,
                  zoom: framing.zoom,
                  bearing: bearing,
                  tilt: framing.tilt,
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
      } else if (_cameraFollow && _track.isNotEmpty) {
        final p = _track.last;
        _programmaticCamera = true;
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), framing.zoom),
        );
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          _programmaticCamera = false;
        });
      } else if (!_cameraFollow &&
          route != null &&
          route.coordinates.length >= 2) {
        final pts = [for (final p in route.coordinates) LatLng(p[1], p[0])];
        final swLat =
            pts.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
        final swLng =
            pts.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
        final neLat =
            pts.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
        final neLng =
            pts.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);
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
    if (gen == _rideMapDrawGen) {
      await _drawGroupPins(c);
    }
    await _drawJoinMark(c, ref.read(activeRouteProvider));
    await _syncNavPuck();
  }

  Future<void> _drawJoinMark(
    MapLibreMapController c,
    ActiveRoute? route,
  ) async {
    if (route == null ||
        route.joinAlongM <= 0 ||
        route.coordinates.length < 2) {
      return;
    }
    final p = pointAlongRoute(route.coordinates, route.joinAlongM);
    try {
      await c.addSymbol(
        SymbolOptions(
          geometry: LatLng(p[1], p[0]),
          textField: 'Tour',
          textSize: 12,
          textColor: NavMapColors.remainingCore,
          textHaloColor: '#0A1A12',
          textHaloWidth: 1.4,
        ),
      );
    } catch (_) {}
  }

  /// Echte Presence aus dem Store. Kein Demo-Fahrer. Eigenen Puck nicht doppelt.
  Future<void> _drawGroupPins(MapLibreMapController c) async {
    try {
      await c.clearSymbols();
    } catch (_) {}
    _navPuck.forgetSymbol();
    final route = ref.read(activeRouteProvider);
    final group = await _rideGroups.groupForRide(route?.id);
    if (group == null) return;
    final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
    final pins = await _rideGroups.visiblePins(groupId: group.id, zones: zones);
    for (final p in pins) {
      if (await _rideGroups.isSelfId(p.userId)) continue;
      if (p.lat == null || p.lng == null) continue;
      if (!RideGroupPolicy.pinVisible(p.visibility)) continue;
      try {
        await c.addSymbol(
          SymbolOptions(
            geometry: LatLng(p.lat!, p.lng!),
            textField:
                p.visibility == RideGroupPresenceVisibility.stale ? '·' : '●',
            textSize: 16,
            textColor: '#FF8A3D',
            textHaloColor: '#0A1A12',
            textHaloWidth: 1.2,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _publishGroupPresence(double lat, double lng) async {
    final now = DateTime.now();
    final last = _lastGroupPresenceAt;
    if (last != null && now.difference(last).inSeconds < 6) return;
    _lastGroupPresenceAt = now;
    final route = ref.read(activeRouteProvider);
    final group = await _rideGroups.groupForRide(route?.id);
    if (group == null) return;
    final me = await _rideGroups.localMember(group.id);
    if (me == null || !me.liveOptIn) return;
    final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
    await _rideGroups.publishPresence(
      groupId: group.id,
      lat: lat,
      lng: lng,
      zones: zones,
    );
    final c = _rideMap;
    if (c != null && mounted) await _drawGroupPins(c);
  }

  Future<void> _refreshGroupPins() async {
    if (!mounted || !ref.read(isRidingProvider)) return;
    final route = ref.read(activeRouteProvider);
    final group = await _rideGroups.groupForRide(route?.id);
    if (group != null && group.onServer) {
      await _rideGroups.pullPresence(group.id);
    }
    final c = _rideMap;
    if (c != null && mounted) await _drawGroupPins(c);
  }

  /// LDI-Speed, sonst GPS (Freeride ohne CSC).
  double get _effectiveSpeedKmh {
    final ldi = _ldi?.speedKmh;
    if (ldi != null && ldi > 0.5) return ldi;
    return _gpsSpeedKmh;
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool _instructionIsArrive(String instruction) {
    final t = instruction.toLowerCase();
    return t.contains('ziel') ||
        t.contains('arriv') ||
        t.contains('destination') ||
        t.contains('destinazione');
  }

  /// Engine-Steps (400/150/30) bevorzugt; sonst Bearing-Cues als Fallback.
  void _maybeSpeakNav(NavCue cue, int remainingM) {
    if (_ttsMuted || !ref.read(isRidingProvider)) return;
    final speed = _effectiveSpeedKmh;
    final text = pickAnnounce(
      stepId: cue.id,
      instruction: _l10n.navInstructionFor(cue.instruction),
      isArrive: _instructionIsArrive(cue.instruction),
      remainingM: remainingM.toDouble(),
      speedKmh: speed,
      spoken: _spokenAnnounceKeys,
      street: extractStreetNameFromInstruction(cue.instruction),
      languageCode: AppLocaleBinding.chromeLanguageCode,
    );
    if (text == null) return;
    if (_lastSpokenText == text) return;
    _lastSpokenText = text;
    unawaited(_wakeOnCueIfNeeded());
    unawaited(_speakHud(text));
  }

  void _considerNavTts() {
    final route = ref.read(activeRouteProvider);
    if (route == null || route.coordinates.length < 4) return;
    if (_gravityFollowNow(route)) {
      if (!_gravityFollowSpoken && !_ttsMuted) {
        _gravityFollowSpoken = true;
        unawaited(_speakHud(_l10n.rideFollowTrail));
      }
      return;
    }
    if (!showTurnByTurn(crossTrackM: _crossTrackM)) return;
    final along = _alongRouteM;
    final speed = _effectiveSpeedKmh;

    if (route.steps.isNotEmpty) {
      final nxt = nextRouteStep(route.steps, along);
      if (nxt != null) {
        final text = pickAnnounce(
          stepId: nxt.step.id,
          instruction: _l10n.navInstructionFor(nxt.step.instruction),
          isArrive: _instructionIsArrive(nxt.step.instruction),
          remainingM: nxt.remainingM,
          speedKmh: speed,
          spoken: _spokenAnnounceKeys,
          street: nxt.step.streetName ??
              extractStreetNameFromInstruction(nxt.step.instruction),
          languageCode: AppLocaleBinding.chromeLanguageCode,
        );
        if (text != null &&
            !_ttsMuted &&
            ref.read(isRidingProvider) &&
            _lastSpokenText != text) {
          _lastSpokenText = text;
          unawaited(_wakeOnCueIfNeeded());
          unawaited(_speakHud(text));
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
    int? n;
    if (h.id == 'bracket-run') {
      n = int.tryParse(RegExp(r'\d+').firstMatch(h.text)?.group(0) ?? '');
    }
    if (_liveHintId == h.id && _liveHintN == n) return;
    if (!mounted) return;
    final localized = _l10n.liveHintFor(h.id, n: n);
    setState(() {
      _liveHintId = h.id;
      _liveHintN = n;
      _liveHintText = localized;
    });
    if (!_ttsMuted && h.kind != 'stand') {
      unawaited(_speakHud(clampHint(localized)));
    }
  }

  void _bumpIdle() {
    _setAutoLocked(false);
    _armIdleLock();
  }

  void _setAutoLocked(bool locked) {
    if (ref.read(autoLockedProvider) == locked) return;
    ref.read(autoLockedProvider.notifier).state = locked;
  }

  void _armIdleLock() {
    _idleLock?.cancel();
    if (!ref.read(isRidingProvider)) return;
    _idleLock = Timer(RideAutoLockPolicy.idleTimeout, _onIdleLockTick);
  }

  void _onIdleLockTick() {
    if (!mounted || !ref.read(isRidingProvider)) return;
    if (ref.read(autoLockedProvider)) return;
    final paused = ref.read(isPausedProvider);
    if (!RideAutoLockPolicy.shouldArm(
      riding: true,
      paused: paused,
      speedKmh: _effectiveSpeedKmh,
    )) {
      // Still rolling — keep HUD visible, check again after another idle window.
      _armIdleLock();
      return;
    }
    _setAutoLocked(true);
  }

  void _unlockAutoLockIfMoving() {
    if (!RideAutoLockPolicy.shouldUnlockForMotion(
      locked: ref.read(autoLockedProvider),
      paused: ref.read(isPausedProvider),
      speedKmh: _effectiveSpeedKmh,
    )) {
      return;
    }
    _setAutoLocked(false);
    _armIdleLock();
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
            title: Text(_l10n.rideLocationOff),
            content: Text(_l10n.rideLocationOffBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_l10n.rideSettings),
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
            title: Text(_l10n.rideLocationPermission),
            content: Text(_l10n.rideLocationDeniedForever),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_l10n.rideAppSettings),
              ),
            ],
          ),
        );
        if (go == true) await location.openAppSettings();
        return false;
      case LocationPermissionResult.denied:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.rideLocationNeeded),
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
          SnackBar(
            content: Text(_l10n.rideBleOffSnack),
          ),
        );
        return;
      }
      if (bleResult == BlePermissionResult.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.rideBleDeniedSnack),
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

      // Garage-Kopplung: nur der Radsensor ist Ride-GATT. Drive-Identität
      // darf den Start nicht mit 2×14 s blockieren und nicht den CSC überschreiben.
      String? preferredId;
      BikeBleKind? kindHint;
      BikeBleBinding binding = const BikeBleBinding();
      final bikeId = active?.id;
      if (bikeId != null && bikeId.isNotEmpty) {
        binding =
            await ref.read(bikeBleStoreProvider).bindingForBike(bikeId);
        final target = rideBlePreferredTarget(binding);
        preferredId = target.deviceId;
        kindHint = target.kindHint;
      }

      final savedWatch = await ref.read(bikeBleStoreProvider).savedWatch();
      if (!mounted || !ref.read(isRidingProvider)) return;

      // Uhr-GATT parallel zum Rad — ohne zweiten Scan, der den CSC-Scan stört.
      final watchJob = savedWatch == null
          ? Future<bool>.value(false)
          : ble.connectWatch(
              deviceId: savedWatch.deviceId,
              scanIfMissing: false,
            );

      final cscOk = await ble.connect(
        deviceId: preferredId,
        kindHint: kindHint,
        tryLdi: false,
      );
      var watchOk = false;
      try {
        watchOk = await watchJob;
      } catch (e) {
        debugPrint('ride: parallel watch connect failed ($e)');
      }
      if (!mounted || !ref.read(isRidingProvider)) return;
      if (!ble.hasWheelLive) {
        final kind = ble.connectedKind;
        final msg = kind != null && bikeBleKindIsDrive(kind)
            ? _l10n.bleDriveFailFor(kind, detail: ble.statusDetail)
            : _l10n.bleStatusDetailFor(
                ble.statusDetail ?? _l10n.rideNoBikeSensor,
              );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }

      final remoteId = ble.lastRemoteId;
      final connectedKind = ble.connectedKind;
      if (cscOk &&
          ble.hasWheelLive &&
          bikeId != null &&
          bikeId.isNotEmpty &&
          remoteId != null &&
          remoteId.isNotEmpty &&
          connectedKind != null &&
          !bikeBleKindIsDrive(connectedKind)) {
        await ref.read(bikeBleStoreProvider).saveWheel(
              bikeId,
              BikeBleDevice(
                deviceId: remoteId,
                name: ble.connectedDeviceName,
                kind: bikeBleKindToStorage(connectedKind),
              ),
            );
      }

      final drive = binding.drive;
      if (drive != null &&
          drive.deviceId.isNotEmpty &&
          mounted &&
          ref.read(isRidingProvider)) {
        unawaited(
          ble.attachSavedDrive(
            deviceId: drive.deviceId,
            kindHint: bikeBleKindFromStorage(drive.kind),
          ),
        );
      }

      if (savedWatch != null && !watchOk) {
        watchOk = await ble.connectWatch(
          deviceId: savedWatch.deviceId,
          scanIfMissing: true,
        );
        if (!mounted || !ref.read(isRidingProvider)) return;
      }
      if (watchOk) {
        final watchId = ble.lastWatchRemoteId;
        if (watchId != null && watchId.isNotEmpty) {
          await ref.read(bikeBleStoreProvider).saveWatch(
                BikeBleDevice(
                  deviceId: watchId,
                  name: ble.connectedWatchName ?? savedWatch?.name,
                ),
              );
        }
      }
    } catch (e) {
      debugPrint('ride: deferred BLE connect failed ($e) — continue without');
    }
  }

  Future<void> _start() async {
    if (_starting || ref.read(isRidingProvider)) return;
    _confirmStop = 0;
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
    _gpsStatus = _l10n.rideGpsUnavailable;
    _lastGpsDistanceM = 0;
    _gpsStallSec = 0;
    _startedAt = DateTime.now();
    _spokenAnnounceKeys.clear();
    _liveHintText = null;
    _liveHintId = null;
    _liveHintN = null;
    _hardImpactStreak = 0;
    _standSeconds = 0;
    _prevPeakG = 0;
    _startSoc = null;
    _hasCrank = false;
    _bleSamples.reset();
    _alongRouteM = 0;
    _crossTrackM = 0;
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
    _groupPinPoll?.cancel();
    _groupPinPoll = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_refreshGroupPins());
    });
    unawaited(_refreshGroupPins());
    ref.read(rideElapsedSecProvider.notifier).state = 0;
    ref.read(rideDistanceMProvider.notifier).state = 0;
    if (mounted) setState(() => _starting = false);
    unawaited(_startHudMedia());

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
          _gpsStatus = _l10n.rideGpsFix;
        }
      } else {
        _gpsStatus = _l10n.rideGpsFixN(_gpsFixCount);
      }
      _track.add(
        _liveTrackPoint(
          lat: fix.lat,
          lng: fix.lng,
          timeMs: fix.timestamp.millisecondsSinceEpoch,
          elev: fix.altitudeM,
        ),
      );
      unawaited(_publishGroupPresence(fix.lat, fix.lng));
      final route = ref.read(activeRouteProvider);
      if (route != null && route.coordinates.length >= 2) {
        final prog = projectOntoRoute(
          coordinates: route.coordinates,
          lat: fix.lat,
          lng: fix.lng,
        );
        _alongRouteM = prog.distanceAlongM;
        _crossTrackM = prog.crossTrackM;
        final nextOff = updateOffRouteState(
          currentlyOff: _offRoute,
          crossTrackM: prog.crossTrackM,
        );
        if (nextOff != _offRoute) {
          _offRoute = nextOff;
          if (nextOff) {
            _offRouteBanner = _l10n.rerouteTitle;
            _userChoseStay = false;
            _rejoinWhyLine = null;
            if (mounted) setState(() {});
            if (!_ttsMuted && ref.read(isRidingProvider)) {
              unawaited(_wakeOnCueIfNeeded());
              unawaited(_speakHud(_l10n.rideOffRouteTts));
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
        _crossTrackM = 0;
        if (_offRoute || _offRouteBanner != null) {
          _offRoute = false;
          _offRouteBanner = null;
        }
      }
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
      if (mounted) {
        setState(() {
          _ldi = d;
          _hasCrank = HudBikePeek.crankLive(
            bikeConnected: ble.hasWheelLive,
            previouslySeen: _hasCrank,
            cadenceRpm: d.cadenceRpm,
          );
        });
      }
      if (!ref.read(isPausedProvider)) {
        _bleSamples.add(d);
      }
      // Nur echte LDI/GATT-SoC — CSC liefert null, nicht erfinden.
      final soc = d.batterySocPercent;
      if (soc != null) _startSoc ??= soc;
    });
    // Nearby Devices / BLE after HUD stable — never interrupt camera start.
    unawaited(_connectBleAfterHudStable());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ref.read(isPausedProvider)) return;
      _unlockAutoLockIfMoving();
      final start = _startedAt;
      if (start != null) {
        ref.read(rideElapsedSecProvider.notifier).state =
            DateTime.now().difference(start).inSeconds;
      }
      if (!_usingGps) {
        if (_allowGpsStallSim) {
          _tickSimMotion(elevFallback: 280);
        } else {
          _gpsStatus = _l10n.rideGpsUnavailable;
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
                ? _l10n.rideGpsStillSim
                : _l10n.rideGpsStillWeak;
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
      _gravityFollowSpoken = false;
      _liveHintText = null;
      _liveHintId = null;
      _liveHintN = null;
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
      _liveTrackPoint(
        lat: baseLat + math.sin(t / 18) * 0.00018,
        lng: baseLng + t * 0.00004,
        timeMs: DateTime.now().millisecondsSinceEpoch,
        elev: elevFallback ?? last?.elev ?? 280,
      ),
    );
    _gpsStatus = _l10n.rideGpsSimActive;
    if (mounted && t % 3 == 0) setState(() {});
  }

  TrackPoint _liveTrackPoint({
    required double lat,
    required double lng,
    required int timeMs,
    double? elev,
  }) {
    final live = _ldi;
    final hr = live?.heartRateBpm;
    final cad = live?.cadenceRpm;
    final pwr = live?.riderPowerW;
    return TrackPoint(
      lat: lat,
      lng: lng,
      timeMs: timeMs,
      elev: elev,
      heartRateBpm: hr != null && hr >= 1 && hr <= 239 ? hr : null,
      cadenceRpm: cad != null && cad > 0.5 ? cad : null,
      powerW: pwr != null && pwr > 0 && pwr < 2500 ? pwr : null,
    );
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

  bool _gravityFollowNow(ActiveRoute? route) {
    if (route == null || !route.gravitySession) return false;
    return gravityOnDescent(
      gravitySession: true,
      alongRouteM: _alongRouteM,
      joinAlongM: route.joinAlongM,
    );
  }

  /// First reaction when leaving the route: offline toast or online sheet (N-02b).
  Future<void> _onWentOffRoute() async {
    if (!mounted || !ref.read(isRidingProvider)) return;
    final route = ref.read(activeRouteProvider);
    if (_gravityFollowNow(route)) {
      setState(() {
        _userChoseStay = true;
        _offRouteBanner = _l10n.rideStayOnTrail;
        _autoRerouteEnabled = false;
      });
      return;
    }
    final online = await rideHasNetwork();
    if (!mounted) return;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.rideOfflineRerouteToast),
          duration: const Duration(seconds: 4),
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
            _offRouteBanner = _l10n.rerouteTitle;
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
    if (_autoRerouteBusy || !ref.read(isRidingProvider)) return;
    if (_rerouteSheetOpen) return;
    if (!RideAutoLockPolicy.shouldAutoRejoin(
      enabled: _autoRerouteEnabled,
      userChoseStay: _userChoseStay,
      offRoute: _offRoute,
      paused: ref.read(isPausedProvider),
      speedKmh: _effectiveSpeedKmh,
      crossTrackM: _crossTrackM,
    )) {
      return;
    }
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
    if (!_ttsMuted) unawaited(_speakHud(_l10n.rideRouteRestoredTts));
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
          SnackBar(content: Text(_l10n.rideNoGpsRejoin)),
        );
      }
      return;
    }

    final online = await rideHasNetwork();
    if (!online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.rideOfflineRerouteToast)),
        );
      }
      return;
    }

    final prog = projectOntoRoute(
      coordinates: route.coordinates,
      lat: lastFix.lat,
      lng: lastFix.lng,
    );
    if (_gravityFollowNow(route) ||
        gravityOnDescent(
          gravitySession: route.gravitySession,
          alongRouteM: prog.distanceAlongM,
          joinAlongM: route.joinAlongM,
        )) {
      if (mounted) {
        setState(() {
          _userChoseStay = true;
          _offRouteBanner = _l10n.rideStayOnTrail;
          _autoRerouteEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.rideStayOnTrail)),
        );
      }
      return;
    }
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
        final cat = active?.category ?? preferred ?? BikeCategory.dh;
        late final RoutingProfile rejoinProfile;
        if (route.gravitySession) {
          final dKm = haversineM(
                lastFix.lat,
                lastFix.lng,
                rejoinPt[1],
                rejoinPt[0],
              ) /
              1000;
          var kind = suggestedApproachKind(
            policy: navPolicyForBike(cat),
            distanceKm: dKm,
          );
          if (kind == ApproachKind.atStart) kind = ApproachKind.walk;
          rejoinProfile = approachRoutingProfile(cat, kind);
        } else {
          rejoinProfile = routingProfileForBike(
            active?.category ?? preferred ?? BikeCategory.mtbAm,
          );
        }
        final result = await ref.read(routeRepositoryProvider).planRoute(
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
      final why = skipAheadM > 0 ? _l10n.rideSkipAheadWhy : _l10n.rideRejoinWhy;
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
        joinAlongM: approach.isEmpty ? 0 : routeLengthM(approach),
        gravitySession: route.gravitySession,
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
          _speakHud(
            skipAheadM > 0 ? _l10n.rideSkipAheadTts : _l10n.rerouteRejoin,
          ),
        );
      }
      unawaited(_drawRideMap());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n.rideRejoinFailed(friendlyErrorMessage(e)),
            ),
          ),
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
        ref
            .read(rideChunkRepositoryProvider)
            .uploadPending(rideId: uploadRideId),
      );
    }
    await _sensorSub?.cancel();
    await _bleSub?.cancel();
    await _locSub?.cancel();
    _tick?.cancel();
    _groupPinPoll?.cancel();
    _groupPinPoll = null;
    _idleLock?.cancel();
    await _stopHudMedia();
    await ref.read(sensorCoreProvider).stop();
    await ref.read(bleCoreProvider).disconnectBikeKeepWatch();
    await ref.read(locationCoreProvider).stopRideTracking();

    final started = _startedAt ?? DateTime.now();
    final ended = DateTime.now();
    var distanceM = ref.read(rideDistanceMProvider);
    final elapsed = ref.read(rideElapsedSecProvider);
    final route = ref.read(activeRouteProvider);
    final bike = await ref.read(garageRepositoryProvider).getActiveBike();
    final setup = bike == null
        ? null
        : await ref.read(setupRepositoryProvider).getCurrent(bike.id);

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

    final record = await ref.read(rideRepositoryProvider).endRide(
      id: _rideId,
      bikeId: bike?.id,
      setupId: setup?.id,
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
        ..._bleSamples.toSummary(),
      },
    );

    ref.invalidate(recentRidesProvider);
    ref.invalidate(coachWatchProvider);

    // E-Bike Reichweite nur mit gemessenem SoC-Delta und Pack-Wh.
    final isEbike = bike?.hasElectricAssist == true;
    if (isEbike && bike != null) {
      final comps =
          await ref.read(componentRepositoryProvider).listInstalled(bike.id);
      final distanceKm = distanceM / 1000;
      final whUsed = rideEnergyUsedWh(
        distanceKm: distanceKm,
        startSoc: _startSoc,
        endSoc: _ldi?.batterySocPercent,
        packWh: packCapacityWh(comps),
      );
      if (shouldCalibrateRange(
        distanceKm: distanceKm,
        batteryWhUsed: whUsed,
      )) {
        final store = ref.read(userProfileStoreProvider);
        await store.load();
        final prev = store.rangeCalibration ??
            defaultCalibration(category: bike.category);
        final next = calibrateFromRide(
          prev: prev,
          distanceKm: distanceKm,
          movingTimeSec: elapsed.toDouble(),
          batteryWhUsed: whUsed!,
          avgRiderPowerW: _bleSamples.powerCount > 0
              ? _bleSamples.powerSum / _bleSamples.powerCount
              : null,
        );
        await store.setRangeCalibration(next);
      }
    }

    ref.read(isRidingProvider.notifier).state = false;
    ref.read(isPausedProvider.notifier).state = false;
    _setAutoLocked(false);
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
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => PostRideScreen(rideId: record.id),
      ),
    );
    if (!mounted) return;
    if (result != null && result.startsWith('akte:')) {
      final routeId = result.substring(5);
      if (routeId.isNotEmpty) {
        ref.read(discoverPendingAkteRouteIdProvider.notifier).state = routeId;
      }
      ref.read(shellTabIndexProvider.notifier).state = ShellTabs.platz;
      return;
    }
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.hof;
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _bleSub?.cancel();
    _locSub?.cancel();
    _lightSub?.cancel();
    _tick?.cancel();
    _groupPinPoll?.cancel();
    _idleLock?.cancel();
    _undoRejoinTimer?.cancel();
    _connectivityTimer?.cancel();
    _notifActionSub?.cancel();
    unawaited(_mediaSub?.cancel());
    _mediaSub = null;
    unawaited(_hudMedia.dispose());
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
    final l10n = AppLocalizations.of(context);

    // Map-first: no AppBar on pre-ride or Clean HUD (N-START-01 / N-HUD-01).
    final hideAppBar = !riding || (riding && _cleanMode);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: hideAppBar
            ? null
            : AppBar(
                title: Text(riding ? l10n.rideLiveRide : l10n.rideReady),
                actions: [
                  if (riding) ...[
                    IconButton(
                      tooltip: _cameraFollow
                          ? l10n.rideFollowOn
                          : l10n.rideFollowFree,
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
                      tooltip: _northUp ? l10n.rideNorthUp : l10n.rideHeadingUp,
                      onPressed: () {
                        setState(() => _northUp = !_northUp);
                        if (_cameraFollow) unawaited(_drawRideMap());
                      },
                      icon: _northUp
                          ? const Icon(Icons.explore)
                          : AetherNavMark(
                              size: 22,
                              color: AppColors.accent,
                              style: _navPuckStyle,
                            ),
                    ),
                  ],
                  if (riding && route != null)
                    IconButton(
                      tooltip: _autoRerouteEnabled
                          ? l10n.rideAutoRerouteOn
                          : l10n.rideAutoRerouteOff,
                      onPressed: () {
                        setState(
                          () => _autoRerouteEnabled = !_autoRerouteEnabled,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _autoRerouteEnabled
                                  ? l10n.rideAutoRerouteActive(
                                      AppConfig.autoRerouteCooldownSec,
                                    )
                                  : l10n.rideAutoRerouteManual,
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
                    tooltip: _ttsMuted ? l10n.rideTtsOn : l10n.rideTtsMute,
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
                      tooltip: l10n.rideDisplayNamed(
                        l10n.batteryPresetTitle(_batteryPreset),
                      ),
                      onPressed: () => unawaited(_showBatteryPresetPicker()),
                      icon: Icon(
                        _batteryPreset.keepScreenOn
                            ? Icons.battery_alert_outlined
                            : Icons.battery_saver_outlined,
                        color: _batteryPreset.costsBattery
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                  IconButton(
                    tooltip: _sunlightAuto
                        ? l10n.rideSunlightAuto
                        : l10n.rideSunlightManual,
                    onPressed: _toggleSunlightManual,
                    icon: Icon(
                      Icons.wb_sunny_outlined,
                      color: sunlight ? AppColors.sunAccent : null,
                    ),
                  ),
                ],
              ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _bumpIdle,
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
            key: ValueKey('ride-map-$_mapStyle'),
            styleString: _mapStyle,
            initialCameraPosition: CameraPosition(
              target: _mapTarget(route),
              zoom: route != null ? 14 : (_lastUserLoc != null ? 15.6 : 5.8),
            ),
            myLocationEnabled: true,
            trackCameraPosition: false,
            compassEnabled: true,
            compassViewPosition: MapOrnaments.compassPosition,
            compassViewMargins: MapOrnaments.compassMargins(
              context,
              extraBelowSafe: MapOrnaments.ridePreStartClearance,
            ),
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: _rideMapGestures,
            onMapCreated: _onRideMapCreated,
            onStyleLoadedCallback: () {
              unawaited(_onRideStyleLoaded());
            },
            onUserLocationUpdated: _onUserLocationUpdated,
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
        Positioned(
          left: 12,
          right: 12,
          bottom: 96,
          child: RideGroupPinBanner(routeId: route?.id),
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
    final l10n = AppLocalizations.of(context);
    ({
      String distance,
      String instruction,
      String iconName,
      String? street
    })? navParts;
    if (route != null && _gravityFollowNow(route)) {
      final restKm = math.max(0.0, route.distanceKm - _alongRouteM / 1000);
      navParts = (
        distance: formatHudKm(restKm),
        instruction: l10n.rideFollowTrail,
        iconName: 'straight',
        street: route.mtbScale,
      );
    } else if (route != null &&
        route.coordinates.length >= 4 &&
        showTurnByTurn(crossTrackM: _crossTrackM)) {
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
            instruction: _l10n.navInstructionFor(parts.instruction),
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
            instruction: _l10n.navInstructionFor(parts.instruction),
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

    // Rest km + Ziel. Far off-route / Anfahrt: bis Route vs Rest Runde.
    final rest = route == null
        ? null
        : rideRestSplit(
            routeDistanceKm: route.distanceKm,
            alongRouteM: _alongRouteM,
            joinAlongM: route.joinAlongM,
            crossTrackM: _crossTrackM,
          );
    final splitRest = rest?.mode == RideRestHudMode.splitToJoin;
    final speed = _effectiveSpeedKmh;
    String etaLabel;
    if (splitRest) {
      etaLabel = formatHudKm(rest!.restLoopKm ?? 0);
    } else if (rest?.restKm != null && speed > 3) {
      final etaMin = (rest!.restKm! / speed * 60).round();
      final etaAt = DateTime.now().add(Duration(minutes: etaMin));
      etaLabel =
          '${etaAt.hour.toString().padLeft(2, '0')}:${etaAt.minute.toString().padLeft(2, '0')}';
    } else if (rest?.restKm != null && route!.durationMin > 0) {
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

    final midValue = rest == null
        ? (distanceM < 1000
            ? (distanceM / 1000).toStringAsFixed(2)
            : (distanceM / 1000).toStringAsFixed(1))
        : formatHudKm(
            splitRest ? (rest.untilJoinKm ?? 0) : (rest.restKm ?? 0),
          );
    // nav-hud-tokens-v1 Clean labels: Tempo · noch km · Ziel.
    // CSC/LDI > 0.5 km/h still replaces GPS; caption becomes Rad.
    final speedCaption = l10n.hudSpeedCaptionFor(
      HudBikePeek.speedCaption(
        wheelDrives: HudBikePeek.wheelDrivesSpeed(_ldi?.speedKmh),
        hasRouteRest: rest != null,
      ),
    );
    final bikePeek = HudBikePeek.chips(
      cleanMode: _cleanMode,
      hasCrank: _hasCrank,
      cadenceRpm: _ldi?.cadenceRpm ?? 0,
      heartRateBpm: _ldi?.heartRateBpm,
      riderPowerW: _ldi?.riderPowerW,
      batterySocPercent: _ldi?.batterySocPercent,
      assistMode: _ldi?.assistMode,
      leanAngleDeg: _metrics?.leanAngleDeg,
      showChassis: _showsChassisUx(ref),
    );
    final midLabel = rest == null
        ? l10n.rideKm
        : (splitRest ? l10n.rideUntilJoin : l10n.rideRestKm);
    final rightLabel = rest == null
        ? l10n.rideTime
        : (splitRest ? l10n.rideRestLoop : l10n.rideEta);

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: locked,
            child: layer == RideLiveLayer.map
                ? MapLibreMap(
                    key: ValueKey('ride-map-$_mapStyle'),
                    styleString: _mapStyle,
                    initialCameraPosition: CameraPosition(
                      target: _mapTarget(route),
                      zoom: 15.8,
                    ),
                    myLocationEnabled: true,
                    trackCameraPosition: false,
                    compassEnabled: false,
                    scrollGesturesEnabled: !locked,
                    zoomGesturesEnabled: !locked,
                    rotateGesturesEnabled: !locked,
                    tiltGesturesEnabled: !locked,
                    gestureRecognizers: locked
                        ? const <Factory<OneSequenceGestureRecognizer>>{}
                        : _rideMapGestures,
                    onMapCreated: _onRideMapCreated,
                    onStyleLoadedCallback: () {
                      unawaited(_onRideStyleLoaded());
                    },
                    onUserLocationUpdated: _onUserLocationUpdated,
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
        ),
        const StatusBarScrim(),
        if (locked)
          RideAutoLockOverlay(
            backgroundColor: theme.scaffoldBackgroundColor,
            routeName: route?.name,
            onUnlock: _bumpIdle,
          ),
        IgnorePointer(
          ignoring: locked,
          child: SafeArea(
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
                  // Clean: compass always (not a 5th nav stat). Follow only
                  // after the rider panned. Pro chrome via data-strip tap.
                  if (_cleanMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: Row(
                        children: [
                          if (route != null)
                            Expanded(child: _tourNameChip(theme, route.name))
                          else
                            const Spacer(),
                          const SizedBox(width: AppSpacing.xs),
                          _hudCompass(),
                          if (!_cameraFollow) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Material(
                              color: theme.cardColor.withValues(alpha: 0.9),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              child: IconButton(
                                tooltip: l10n.rideFollowCamera,
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
                          ],
                        ],
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
                              tooltip:
                                  _ttsMuted ? l10n.rideTtsOn : l10n.rideTtsMute,
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
                          _hudCompass(),
                          const SizedBox(width: AppSpacing.xs),
                          if (!_cameraFollow)
                            Material(
                              color: theme.cardColor.withValues(alpha: 0.9),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              child: IconButton(
                                tooltip: l10n.rideFollowCamera,
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
                          if (connectivityChipVisibleInClean(
                              _connectivityState))
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
                              tooltip: _batteryPreset.costsBattery
                                  ? l10n.rideDisplayNamedBattery(
                                      l10n.batteryPresetTitle(_batteryPreset),
                                    )
                                  : l10n.rideDisplayNamed(
                                      l10n.batteryPresetTitle(_batteryPreset),
                                    ),
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
                                    ? AppColors.warning
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_cleanMode && route != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: _tourNameChip(theme, route.name),
                    ),
                  if (navParts != null)
                    RideNextTurnBanner(
                      distance: navParts.distance,
                      instruction: navParts.instruction,
                      icon: turnIcon(navParts.iconName),
                      street: navParts.street,
                      maneuver: _l10n.navInstructionFor(
                        maneuverLabelFromInstruction(
                          navParts.instruction,
                        ),
                      ),
                      navPuckStyle: _navPuckStyle,
                    ),
                  // N-07: one-line upcoming peek under next-turn.
                  if (route != null &&
                      navParts != null &&
                      !_gravityFollowNow(route) &&
                      showTurnByTurn(crossTrackM: _crossTrackM))
                    _buildUpcomingRail(route),
                  // Status: off-route / rejoin why / GPS (one strip only).
                  _buildStatusStrip(theme),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.paddingOf(context).bottom,
          child: IgnorePointer(
            ignoring: locked,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pro / layer switcher only outside Clean Mode.
                if (!_cleanMode) ...[
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
                              ref
                                  .watch(userProfileStoreProvider)
                                  .preferredSport,
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
                      child: Text(l10n.rideQuietDisplay),
                    ),
                  ),
                ],
                Builder(
                  builder: (_) {
                    final mediaKind = hudMediaChipKind(
                      cleanMode: _cleanMode,
                      listenerEnabled: _nowPlaying.listenerEnabled,
                      promptDismissed: _mediaPromptDismissed,
                      hasSession: _nowPlaying.active,
                      musicActive: _nowPlaying.musicActive,
                      optimisticHold: hudMediaOptimisticHoldActive(
                        _mediaOptimisticUntil,
                        DateTime.now(),
                      ),
                    );
                    if (mediaKind == HudMediaChipKind.hidden) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: RideMediaChip(
                        kind: mediaKind,
                        nowPlaying: _nowPlaying,
                        compact: _cleanMode,
                        onPlayPause: _onHudPlayPause,
                        onSkipNext: () {
                          _bumpIdle();
                          unawaited(_hudMedia.skipNext());
                        },
                        onSkipPrevious: () {
                          _bumpIdle();
                          unawaited(_hudMedia.skipPrevious());
                        },
                        onEnable: () {
                          _bumpIdle();
                          unawaited(HudMediaChannel.openListenerSettings());
                        },
                        onDismissPrompt: () {
                          _bumpIdle();
                          setState(() => _mediaPromptDismissed = true);
                          unawaited(
                            RidePrefs.setHudMediaPromptDismissed(true),
                          );
                        },
                        onOpenPlayer: () {
                          _bumpIdle();
                          unawaited(_hudMedia.openPlayer());
                        },
                      ),
                    );
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: RideDataStrip(
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
                    ),
                    if (!paused && _cleanMode) ...[
                      const SizedBox(width: AppSpacing.s),
                      Tooltip(
                        message: l10n.ridePause,
                        child: SizedBox(
                          width: NavHudTokens.pauseFabDp,
                          height: NavHudTokens.pauseFabDp,
                          child: FilledButton(
                            key: const Key('ride-pause-fab'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.chromeFill(context),
                              foregroundColor: AppColors.inkOnChrome(context),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(
                                NavHudTokens.pauseFabDp,
                                NavHudTokens.pauseFabDp,
                              ),
                            ),
                            onPressed: () {
                              _bumpIdle();
                              setState(() => _confirmStop = 0);
                              ref.read(isPausedProvider.notifier).state = true;
                              _syncRideNotification();
                            },
                            child: const Icon(Icons.pause_rounded, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (bikePeek.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s),
                  RideBikePeek(chips: bikePeek),
                ],
                if (paused || !_cleanMode) ...[
                  const SizedBox(height: AppSpacing.s),
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
                            paused ? l10n.rideResume : l10n.ridePause,
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
                                ? AppColors.error
                                : AppColors.error.withValues(alpha: 0.85),
                            minimumSize: const Size.fromHeight(56),
                          ),
                          onPressed: () async {
                            _bumpIdle();
                            await _stop();
                          },
                          child: Text(
                            _confirmStop > 0
                                ? l10n.rideTapAgain
                                : l10n.rideStop,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (paused && _confirmStop == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.rideStopNeedsTwo,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.meta(context),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tourNameChip(ThemeData theme, String name) {
    return Material(
      key: const Key('ride-tour-name'),
      color: theme.cardColor.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: 6,
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// N-07 / nav-hud-tokens-v1: compact line under next-turn if stop <15 min.
  /// Does not count as a fifth Clean Mode HUD element.
  Widget _buildUpcomingRail(ActiveRoute route) {
    String? nextNextInstr;
    double? nextNextRemain;
    if (route.steps.isNotEmpty) {
      final remaining = route.steps
          .where((s) => s.distanceAlongM > _alongRouteM + 5)
          .toList()
        ..sort((a, b) => a.distanceAlongM.compareTo(b.distanceAlongM));
      if (remaining.length >= 2) {
        final second = remaining[1];
        final street = second.streetName?.trim().isNotEmpty == true
            ? second.streetName!.trim()
            : extractStreetNameFromInstruction(second.instruction);
        nextNextInstr = street ?? _l10n.navInstructionFor(second.instruction);
        nextNextRemain = second.distanceAlongM - _alongRouteM;
      }
    } else if (route.coordinates.length >= 4) {
      final cues = buildNavCues(route.coordinates);
      final ahead =
          cues.where((c) => c.distanceAlongM > _alongRouteM + 5).toList();
      if (ahead.length >= 2) {
        nextNextInstr = _l10n.navInstructionFor(ahead[1].instruction);
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
        title: _l10n.rideRerouting,
        background: AppColors.mapWarnFill,
        foreground: AppColors.mapWarnInk,
      );
    }
    if (_routeBeforeRejoin != null && _rejoinWhyLine != null) {
      return RideOffRouteBanner(
        title: _rejoinWhyLine!,
        subtitle: _l10n.rideUndo10s,
        actionLabel: _l10n.rideUndo,
        onAction: () {
          _bumpIdle();
          _undoRejoin();
        },
        background: AppColors.sunSurface,
        foreground: AppColors.sageOnLight,
      );
    }
    if (_offRouteBanner != null) {
      final far = !showTurnByTurn(crossTrackM: _crossTrackM);
      return RideOffRouteBanner(
        title: _l10n.rerouteTitle,
        subtitle: _userChoseStay
            ? _l10n.rideStayOffHint
            : far
                ? _l10n.rideKmToRoute(formatHudKm(_crossTrackM / 1000))
                : (_autoRerouteEnabled ? _l10n.rideRecalc : _l10n.rideTapOptions),
        actionLabel: _userChoseStay ? _l10n.rideOptions : _l10n.rerouteRejoin,
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
        background: AppColors.mapWarnFill,
        foreground: AppColors.mapWarnInk,
        compact: true,
      );
    }
    if (_liveHintText != null && !_cleanMode) {
      return RideOffRouteBanner(
        title: _liveHintText!,
        background: AppColors.mapWarnFill,
        foreground: AppColors.mapWarnInk,
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
            key: ValueKey(_mapStyle),
            styleString: _mapStyle,
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
            onMapCreated: _onRideMapCreated,
            onStyleLoadedCallback: () {
              unawaited(_onRideStyleLoaded());
            },
            onUserLocationUpdated: _onUserLocationUpdated,
          ),
        );
      case RideLiveLayer.data:
        final ble = ref.read(bleCoreProvider);
        final bleConnected = ble.hasWheelLive;
        final driveOnly = ble.isDriveWithoutMetrics;
        final bleSpeed = _ldi?.speedKmh;
        final bleCadence = _ldi?.cadenceRpm;
        final l10n = _l10n;
        return Semantics(
          label: l10n.rideLiveData,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  _MetricRow(
                    l10n.rideSpeed,
                    '${_effectiveSpeedKmh.toStringAsFixed(1)} km/h',
                  ),
                  if (bleConnected && bleSpeed != null && bleSpeed > 0.3)
                    _MetricRow(
                      l10n.rideSensorSpeed,
                      '${bleSpeed.toStringAsFixed(1)} km/h',
                    ),
                  _MetricRow(
                    l10n.rideDistance,
                    '${(ref.read(rideDistanceMProvider) / 1000).toStringAsFixed(2)} km',
                  ),
                  _MetricRow(
                    l10n.rideTime,
                    _fmt(ref.read(rideElapsedSecProvider)),
                  ),
                  if (_ldi?.batterySocPercent != null)
                    _MetricRow(
                      l10n.rideSoc,
                      '${_ldi!.batterySocPercent!.toStringAsFixed(0)} %',
                    ),
                  if (_ldi?.riderPowerW != null)
                    _MetricRow(
                      l10n.ridePower,
                      '${_ldi!.riderPowerW!.toStringAsFixed(0)} W',
                    ),
                  if (_ldi?.assistMode != null &&
                      _ldi!.assistMode!.trim().isNotEmpty)
                    _MetricRow(l10n.rideAssist, _ldi!.assistMode!),
                  if (_ldi?.heartRateBpm != null)
                    _MetricRow(
                      l10n.rideHeart,
                      '${_ldi!.heartRateBpm!.toStringAsFixed(0)} bpm',
                    ),
                  if (_hasCrank && bleCadence != null)
                    _MetricRow(
                      l10n.rideCadence,
                      '${bleCadence.toStringAsFixed(0)} rpm',
                    ),
                  if (bleConnected)
                    _MetricRow(
                      l10n.rideBikeSensor,
                      ble.connectedDeviceName ?? l10n.rideConnected,
                    )
                  else if (driveOnly)
                    _MetricRow(
                      l10n.rideBikeSensor,
                      l10n.bleDriveFailFor(
                        ble.connectedKind ?? BikeBleKind.otherDrive,
                        detail: ble.statusDetail,
                      ),
                    ),
                  if (ble.isWatchConnected)
                    _MetricRow(
                      l10n.rideWatch,
                      [
                        ble.connectedWatchName ?? l10n.rideConnected,
                        if (_ldi?.heartRateBpm != null)
                          '${_ldi!.heartRateBpm!.round()} bpm'
                        else
                          l10n.rideHeartWaiting,
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
                  Text(
                    _l10n.rideChassisOff,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    _l10n.rideChassisHint,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  FilledButton(
                    onPressed: () {
                      ref.read(mountCheckProvider.notifier).state =
                          MountCheck.mounted;
                    },
                    child: Text(_l10n.rideMarkMounted),
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
                  _MetricRow(
                      _l10n.rideGPeak, _metrics!.gForcePeak.toStringAsFixed(2)),
                  _MetricRow(
                    _l10n.rideLean,
                    _metrics!.leanAngleDeg.toStringAsFixed(1),
                  ),
                  _MetricRow(
                    _l10n.rideFlow,
                    _metrics!.flowContribution.toStringAsFixed(2),
                  ),
                ] else
                  Text(_l10n.rideWaitingSensors),
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
