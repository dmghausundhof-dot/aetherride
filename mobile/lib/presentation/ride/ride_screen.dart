import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/config.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/nav_hud_tokens.dart';
import '../../data/community/ride_group_cloud.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/community/ride_together_look.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/ride/ride_media_io.dart';
import '../../data/routing/ride_to_saved.dart';
import '../../data/routing/basemap_street_contrast.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/overview_browse_paint.dart';
import '../../data/routing/offline_basemap.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_pack_catalog.dart';
import '../../data/routing/offline_pack_dirs.dart';
import '../../data/routing/offline_pmtiles_store.dart';
import '../../data/routing/offline_tiles.dart';
import '../../data/routing/routing_client.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/active_route.dart';
import '../../domain/routing/offline_rejoin.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_pin.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/community/ride_together.dart';
import '../../domain/bike.dart';
import '../../domain/ble.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../../domain/ble/manufacturer_live.dart';
import '../../domain/ble/ride_ble_samples.dart';
import '../../domain/ebike/range.dart';
import '../../domain/hud_bike_peek.dart';
import '../../domain/hud_lean_calibration.dart';
import '../../domain/hud_media.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/ride.dart';
import '../../domain/ride/gps_teleport.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../../domain/ride_activity.dart';
import '../../domain/ride_auto_lock.dart';
import '../../domain/ride_journal.dart';
import '../../domain/routing/battery_preset.dart';
import '../../domain/routing/camera_follow_smooth.dart';
import '../../domain/routing/connectivity_chip.dart';
import '../../domain/routing/nav_announce.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/nav_map_paint.dart';
import '../../domain/routing/nav_policy.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/routing/ride_nav_honesty.dart';
import '../../domain/routing/route_progress.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../domain/routing/upcoming_rail.dart';
import '../../domain/sensor.dart';
import '../../domain/sensor/live_hints.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../domain/tours/tour_akte.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../native/hud_media_channel.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../discover/offline_maps_sheet.dart';
import '../map/friend_pin_image.dart';
import '../map/map_pin_image.dart';
import '../map/nav_puck_image.dart';
import '../map/nav_puck_overlay.dart';
import '../map/rider_map_image.dart';
import '../post_ride/post_ride_screen.dart';
import '../shared/chrome_glyph.dart';
import '../shared/map_locate_fab.dart';
import '../shared/map_ornaments.dart';
import '../shared/status_bar_scrim.dart';
import '../shell/shell_tabs.dart';
import 'widgets/battery_preset_sheet.dart';
import 'widgets/reroute_sheet.dart';
import 'widgets/ride_auto_lock_overlay.dart';
import 'widgets/ride_bike_peek.dart';
import 'widgets/ride_connectivity_chip.dart';
import 'widgets/ride_street_net_hint.dart';
import 'widgets/ride_data_strip.dart';
import 'widgets/ride_draw_tour_chip.dart';
import 'widgets/ride_media_chip.dart';
import 'widgets/ride_network.dart';
import 'widgets/ride_next_turn_banner.dart';
import 'widgets/ride_off_route_banner.dart';
import 'widgets/ride_group_extend_sheet.dart';
import 'widgets/ride_group_friend_sheet.dart';
import 'widgets/ride_group_live_bar.dart';
import 'widgets/ride_group_pin_banner.dart';
import 'widgets/ride_hud_layer_bar.dart';
import 'widgets/ride_hud_live_dock.dart';
import 'widgets/ride_together_sheet.dart';
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
  RideJournal _rideJournal = RideJournal.empty;
  List<PrivacyZone> _privacyZones = const [];
  bool _pickingPhoto = false;
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
  final List<Symbol> _friendPinSymbols = [];
  final Map<String, String> _friendPinUserBySymbol = {};
  Symbol? _joinMarkSymbol;
  String? _ridePoiPinsForId;
  String? _rideNextPoiKey;
  final List<Symbol> _ridePoiSymbols = [];
  final Map<String, Symbol> _ridePoiSymbolByKey = {};
  bool _ridePoiImagesReady = false;
  RideGroupHudSnap? _groupHud;
  bool _skipHudToast = false;
  RideGroupHudNote? _lastHudToast;
  DateTime? _lastHudToastAt;
  UserLocation? _lastUserLoc;
  int _mapDrawSkip = 0;
  int _rideMapDrawGen = 0;
  final RideGroupStore _rideGroups = RideGroupStore();
  late final RideTogetherLook _together;
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
  bool _drawingTour = false;

  /// Mount-zero for HUD lean — every clamp sits at a different rest angle.
  double _leanOffsetDeg = 0;

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

  /// Map / HUD nav mark. Default 3D-Fahrer until RidePrefs loads.
  NavPuckStyle _navPuckStyle = NavPuckStyle.rider;

  /// N-03/N-08 connectivity honesty.
  bool _networkOnline = true;
  bool _offlineMapAvailable = false;
  bool _streetHudInstalled = false;
  List<double>? _streetHudBbox;
  StreetHudOfferKind? _streetHudKind;
  bool _offlineRoutingReady = false;
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
    _together = RideTogetherLook(onAdopt: _adoptTogetherSnap);
    _together.addListener(_onTogetherLook);
    unawaited(_initTts());
    _startAutoSunlight();
    unawaited(_loadRidePrefs());
    RidePrefs.navPuckRevision.addListener(_onNavPuckPref);
    OfflineMapsPrefs.revision.addListener(_onPackRevision);
    unawaited(_resolveRideHudStyle());
    unawaited(_refreshGroupHudOnly());
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

  /// HUD stays on street-level tiles. Local DACH z11 is overview-only
  /// (`maxzoom: 11`) and leaves the ride map black at z15.
  Future<void> _resolveRideHudStyle() async {
    final online = await rideHasNetwork();
    final street = await _probeOfflineMapAvailable();
    if (!mounted) return;
    await _syncRideHudStyle(online: online, offlineStreetTiles: street);
  }

  Future<void> _syncRideHudStyle({
    required bool online,
    required bool offlineStreetTiles,
  }) async {
    final live = AppConfig.mapStyleUrl;
    String? resolved;
    try {
      resolved = await AppConfig.resolveMapStyleUrl();
    } catch (_) {}
    var empty = '';
    try {
      empty = await OfflinePmtilesStore.emptyHudStyleUri();
    } catch (_) {}
    if (!mounted) return;
    final next = rideHudMapStyle(
      liveStyle: live,
      resolvedStyle: resolved,
      online: online,
      offlineStreetTiles: offlineStreetTiles,
      emptyStyleUri: empty,
    );
    if (next == _mapStyle) return;
    setState(() => _mapStyle = next);
  }

  Future<void> _loadRidePrefs() async {
    final preset = await RidePrefs.batteryPreset();
    final puck = NavPuckStyleX.fromId(await RidePrefs.navPuckStyleId());
    final mapOk = await _probeOfflineMapAvailable();
    final routingOk = await _probeOfflineRoutingReady();
    final mediaDismissed = await RidePrefs.hudMediaPromptDismissed();
    final leanOffset = await RidePrefs.leanOffsetDeg();
    final chassisMounted = await RidePrefs.chassisMounted();
    if (!mounted) return;
    setState(() {
      _batteryPreset = preset;
      _navPuckStyle = puck;
      _offlineMapAvailable = mapOk;
      _offlineRoutingReady = routingOk;
      _mediaPromptDismissed = mediaDismissed || _mediaPromptDismissed;
      _leanOffsetDeg = leanOffset;
    });
    if (chassisMounted || HudLeanCalibration.isCalibrated(leanOffset)) {
      ref.read(mountCheckProvider.notifier).state = MountCheck.mounted;
    }
    final c = _rideMap;
    if (c != null) unawaited(_navPuck.setStyle(c, puck));
  }

  /// True only when the HUD would paint from local street tiles.
  /// Overview PMTiles / DACH z11 are not an offline ride map.
  Future<bool> _probeOfflineMapAvailable({
    double? lng,
    double? lat,
  }) async {
    try {
      final installed = await OfflineBasemap.streetHudReadyForActivatedPack();
      _streetHudInstalled = installed;
      if (installed) {
        try {
          final prefs = await OfflineMapsPrefs.read();
          final packId = OfflineMapsPrefs.packIdFromActivatedPath(
            await OfflineMapsPrefs.activatedPackPath(),
          );
          if (OfflineMapsPrefs.streetHudPackIdFrom(prefs) == packId) {
            _streetHudBbox = OfflineMapsPrefs.streetHudBboxFrom(prefs);
            _streetHudKind = streetHudKindFromRaw(
              OfflineMapsPrefs.streetHudKindRawFrom(prefs),
            );
          } else {
            // Region without matching prefs — not pack-wide coverage.
            _streetHudBbox = null;
            _streetHudKind = null;
          }
        } catch (_) {
          _streetHudBbox = null;
          _streetHudKind = null;
        }
        return streetHudCoversHere(
          regionReady: true,
          kind: _streetHudKind,
          storedBbox: _streetHudBbox,
          userLng: lng ?? _lastFollowLng,
          userLat: lat ?? _lastFollowLat,
        );
      }
      _streetHudBbox = null;
      _streetHudKind = null;
      final resolved = await AppConfig.resolveMapStyleUrl();
      return rideHudUsesOfflineStreetTiles(
        liveStyle: AppConfig.mapStyleUrl,
        resolvedStyle: resolved,
      );
    } catch (_) {
      return false;
    }
  }

  /// Graph on disk and Occupancy cover this fix (or pack-only if no GPS yet).
  Future<bool> _probeOfflineRoutingReady({
    double? lng,
    double? lat,
  }) async {
    try {
      if (!await OfflinePackDirs.hasLegitimateActivatedPack()) return false;
      final x = lng ?? _lastFollowLng;
      final y = lat ?? _lastFollowLat;
      if (x == null || y == null) return true;
      return OfflinePackDirs.legitimateCoversPoint(x, y);
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncOfflineHonestyAtFix(double lat, double lng) async {
    final mapOk = await _probeOfflineMapAvailable(lng: lng, lat: lat);
    final routingOk = await _probeOfflineRoutingReady(lng: lng, lat: lat);
    if (!mounted) return;
    final route = ref.read(activeRouteProvider);
    final hasRoute = route != null && route.coordinates.length >= 2;
    final state = resolveConnectivityChip(
      online: _networkOnline,
      hasRouteGeometry: hasRoute,
      offlineMapAvailable: mapOk,
      offlineRoutingReady: routingOk,
    );
    if (mapOk == _offlineMapAvailable &&
        routingOk == _offlineRoutingReady &&
        state == _connectivityState) {
      return;
    }
    setState(() {
      _offlineMapAvailable = mapOk;
      _offlineRoutingReady = routingOk;
      _connectivityState = state;
    });
    unawaited(
      _syncRideHudStyle(
        online: _networkOnline,
        offlineStreetTiles: mapOk,
      ),
    );
  }

  /// Street HUD is dark at zoom 15 — sit with the nav chrome, not a second pill.
  Widget? _streetNetHintBanner() {
    if (!rideHudStreetMapNeedsNet(
      online: _networkOnline,
      offlineStreetTiles: _offlineMapAvailable,
    )) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: RideStreetNetHint(
          key: const Key('ride-street-net-hint'),
          label: _streetHudInstalled && !_offlineMapAvailable
              ? _l10n.rideHudStreetOutside
              : _l10n.rideHudStreetNeedsNet,
          onTap: () => unawaited(_openOfflineMapsFromRide()),
        ),
      ),
    );
  }

  Future<void> _openOfflineMapsFromRide() async {
    List<double>? routeBbox;
    List<List<double>>? routeLine;
    final route = ref.read(activeRouteProvider);
    if (route != null && route.coordinates.length >= 2) {
      routeBbox = streetHudBboxFromLngLats(route.coordinates);
      routeLine = streetHudSketchLine(route.coordinates);
    }
    await openOfflineMapsSheet(
      context,
      userLng: _lastFollowLng,
      userLat: _lastFollowLat,
      routeBbox: routeBbox,
      routeLine: routeLine,
    );
    if (!mounted) return;
    unawaited(_refreshConnectivityChip());
  }

  Future<void> _refreshConnectivityChip() async {
    final online = await rideHasNetwork();
    unawaited(OfflineBasemap.applyNetworkMode(online: online));
    final mapOk = await _probeOfflineMapAvailable();
    final routingOk = await _probeOfflineRoutingReady();
    final route = ref.read(activeRouteProvider);
    final hasRoute = route != null && route.coordinates.length >= 2;
    final state = resolveConnectivityChip(
      online: online,
      hasRouteGeometry: hasRoute,
      offlineMapAvailable: mapOk,
      offlineRoutingReady: routingOk,
    );
    if (!mounted) return;
    if (online != _networkOnline ||
        mapOk != _offlineMapAvailable ||
        routingOk != _offlineRoutingReady ||
        state != _connectivityState) {
      setState(() {
        _networkOnline = online;
        _offlineMapAvailable = mapOk;
        _offlineRoutingReady = routingOk;
        _connectivityState = state;
      });
    }
    await _syncRideHudStyle(online: online, offlineStreetTiles: mapOk);
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

  void _onNavPuckPref() {
    unawaited(_reloadNavPuckStyle());
  }

  void _onPackRevision() {
    unawaited(_refreshConnectivityChip());
  }

  Future<void> _reloadNavPuckStyle() async {
    final puck = NavPuckStyleX.fromId(await RidePrefs.navPuckStyleId());
    if (!mounted) return;
    setState(() => _navPuckStyle = puck);
    final c = _rideMap;
    if (c != null) unawaited(_navPuck.setStyle(c, puck));
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

  void _forgetRideSymbols() {
    _joinMarkSymbol = null;
    _friendPinSymbols.clear();
    _friendPinUserBySymbol.clear();
    _ridePoiSymbols.clear();
    _ridePoiPinsForId = null;
    _ridePoiImagesReady = false;
  }

  void _onRideMapCreated(MapLibreMapController c) {
    _rideMap = c;
    _navPuck.reset();
    _forgetRideSymbols();
    c.onSymbolTapped.add(_onFriendPinTapped);
  }

  Future<void> _onRideStyleLoaded() async {
    unawaited(OfflineBasemap.applyDetectedNetworkMode());
    final c = _rideMap;
    if (c == null) return;
    _bikeOverlayAttached = false;
    _navPuck.reset();
    _forgetRideSymbols();
    await fixBasemapWaterLayers(
      c,
      coarseOverview: styleHasCoarseWaterPolygons(_mapStyle),
    );
    if (!isRideHudEmptyStyle(_mapStyle)) {
      if (styleNeedsGrayStreetBoost(_mapStyle)) {
        await boostBasemapStreetContrast(c);
      } else if (styleSkipsNatureFillBoost(_mapStyle)) {
        await applyOverviewBrowsePaint(c);
      } else {
        await warmBasemapNatureFills(c);
      }
    }
    await _navPuck.attach(c, style: _navPuckStyle);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      final map = _rideMap;
      if (map == null) return;
      unawaited(_navPuck.hideNativePuck(map));
    });
    if (!isRideHudEmptyStyle(_mapStyle)) {
      await _ensureBikeOverlay();
    }
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
        liveNetwork: liveNetworkFallbackAt(
          lng: _track.isNotEmpty ? _track.last.lng : 8.693,
          lat: _track.isNotEmpty ? _track.last.lat : 49.409,
        ),
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
    await attachLiveOsmNetworkLayers(c);
    final data = await resolveBikeOverlayData(lng: lng, lat: lat);
    final liveNetwork = liveNetworkFallbackAt(lng: lng, lat: lat);
    if (data != null && mounted) {
      await attachBikeOverlayLayers(
        c,
        data: data,
        family: family,
        visible: true,
        extraOn: extra,
        sGradeOnly: false,
        liveNetwork: liveNetwork,
      );
    } else if (mounted) {
      await applyBikeOverlayVisibility(
        c,
        family: family,
        visible: true,
        extraOn: extra,
        liveNetwork: liveNetwork,
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

  Future<void> _captureRidePhoto() async {
    if (_pickingPhoto) return;
    final l10n = _l10n;
    if (!_rideJournal.canAddPhoto) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRidePhotosMax(RideJournal.maxPhotos))),
      );
      return;
    }
    setState(() => _pickingPhoto = true);
    try {
      final last = _track.isNotEmpty ? _track.last : null;
      final media = await pickRidePhoto(
        source: ImageSource.camera,
        journal: _rideJournal,
        lastFix: last,
        track: trackJsonOf(_track),
        zones: _privacyZones,
        fallbackLastTrack: true,
      );
      if (media == null || !mounted) return;
      setState(() {
        _rideJournal = _rideJournal.copyWith(
          photos: [..._rideJournal.photos, media],
        );
      });
      final msg = media.hasPin
          ? l10n.ridePhotoPinned
          : (media.privacyStripped
              ? l10n.ridePhotoPrivateZone
              : l10n.ridePhotoNeedGps);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Widget _ridePhotoFab() {
    final l10n = _l10n;
    final count = _rideJournal.photos.length;
    return Tooltip(
      message: l10n.ridePhotoTooltip,
      child: SizedBox(
        width: NavHudTokens.pauseFabDp,
        height: NavHudTokens.pauseFabDp,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FilledButton(
              key: const Key('ride-photo-fab'),
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
              onPressed: _pickingPhoto
                  ? null
                  : () {
                      _bumpIdle();
                      unawaited(_captureRidePhoto());
                    },
              child: _pickingPhoto
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const ChromeGlyph('photo', size: 26),
            ),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hudLocateFab({required bool paused}) {
    final l10n = _l10n;
    final m = MapOrnaments.hudLocateMargins(context, paused: paused);
    return Positioned(
      left: m.x.toDouble(),
      bottom: m.y.toDouble(),
      child: MapLocateFab(
        key: const Key('hud-locate-fab'),
        tooltip: l10n.rideFollowCamera,
        active: _cameraFollow,
        onTap: () {
          _bumpIdle();
          setState(() => _cameraFollow = true);
          unawaited(_drawRideMap());
        },
      ),
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
          final live = _drawingTour && route == null;
          await c.addLine(
            LineOptions(
              geometry: line,
              lineColor: NavMapColors.gpsCasing,
              lineWidth: ribbon.gpsCasing * (live ? 1.28 : 1),
              lineOpacity: 0.85,
              lineJoin: 'round',
            ),
          );
          if (gen != _rideMapDrawGen) return;
          await c.addLine(
            LineOptions(
              geometry: line,
              lineColor: NavMapColors.gpsCore,
              lineWidth: ribbon.gpsCore * (live ? 1.28 : 1),
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
    await _syncRidePoiPins(c, ref.read(activeRouteProvider));
    await _syncNavPuck();
  }

  Future<void> _drawJoinMark(
    MapLibreMapController c,
    ActiveRoute? route,
  ) async {
    if (_joinMarkSymbol != null) {
      try {
        await c.removeSymbol(_joinMarkSymbol!);
      } catch (_) {}
      _joinMarkSymbol = null;
    }
    if (route == null ||
        route.joinAlongM <= 0 ||
        route.coordinates.length < 2) {
      return;
    }
    final p = pointAlongRoute(route.coordinates, route.joinAlongM);
    try {
      _joinMarkSymbol = await c.addSymbol(
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

  Future<void> _ensureRidePoiImages(MapLibreMapController c) async {
    if (_ridePoiImagesReady) return;
    try {
      for (final kind in MapPoiKind.values) {
        await c.addImage(poiPinImageId(kind), await loadPoiPinPng(kind));
      }
      _ridePoiImagesReady = true;
    } catch (_) {}
  }

  Future<void> _syncRidePoiPins(
    MapLibreMapController c,
    ActiveRoute? route,
  ) async {
    final id = route?.id;
    if (id == _ridePoiPinsForId && _ridePoiSymbols.isNotEmpty) {
      await _highlightRideNextPoi(route);
      return;
    }
    for (final s in _ridePoiSymbols) {
      try {
        await c.removeSymbol(s);
      } catch (_) {}
    }
    _ridePoiSymbols.clear();
    _ridePoiSymbolByKey.clear();
    _rideNextPoiKey = null;
    _ridePoiPinsForId = id;
    if (route == null ||
        route.poiStops.isEmpty ||
        route.durationMin <= 0 ||
        route.coordinates.length < 4) {
      return;
    }
    await _ensureRidePoiImages(c);
    final next = nextPoiStop(
      stops: [
        for (final x in route.poiStops)
          RoutePoiStop(atMin: x.atMin, title: x.title, kind: x.kind),
      ],
      alongRouteM: _alongRouteM,
      totalDistanceM: route.distanceKm * 1000,
      durationMin: route.durationMin,
    );
    final placed = <double>[];
    var i = 0;
    for (final poi in route.poiStops) {
      if (placed.length >= 8) break;
      i++;
      if (poi.atMin <= 0) continue;
      final frac = poi.atMin / route.durationMin;
      if (!poiFracFitsAlong(frac, placed)) continue;
      placed.add(frac);
      final alongM = frac * route.distanceKm * 1000;
      final p = pointAlongRoute(route.coordinates, alongM);
      try {
        final key = '${poi.atMin}|${poi.title}';
        final selected =
            next != null && next.atMin == poi.atMin && next.title == poi.title;
        if (selected) _rideNextPoiKey = key;
        final sym = await c.addSymbol(
          SymbolOptions(
            geometry: LatLng(p[1], p[0]),
            iconImage: _ridePoiImagesReady
                ? poiPinImageId(mapPoiKindFromRaw(poi.kind))
                : null,
            iconSize: poiStopIconSize(selected: selected),
            iconAnchor: 'bottom',
            textField: poiPinLabel(
              index: i,
              title: poi.title,
              zoom: 11,
            ),
            textSize: 11,
            textColor: '#1A120C',
            textHaloColor: '#F4F1EC',
            textHaloWidth: 1.6,
            textOffset: const Offset(0, 1.85),
          ),
        );
        _ridePoiSymbols.add(sym);
        _ridePoiSymbolByKey[key] = sym;
      } catch (_) {}
    }
  }

  Future<void> _highlightRideNextPoi(ActiveRoute? route) async {
    final c = _rideMap;
    if (c == null || _ridePoiSymbolByKey.isEmpty || route == null) return;
    final next = nextPoiStop(
      stops: [
        for (final p in route.poiStops)
          RoutePoiStop(atMin: p.atMin, title: p.title, kind: p.kind),
      ],
      alongRouteM: _alongRouteM,
      totalDistanceM: route.distanceKm * 1000,
      durationMin: route.durationMin,
    );
    final key = next == null ? null : '${next.atMin}|${next.title}';
    if (key == _rideNextPoiKey) return;
    _rideNextPoiKey = key;
    for (final entry in _ridePoiSymbolByKey.entries) {
      try {
        await c.updateSymbol(
          entry.value,
          SymbolOptions(
            iconSize: poiStopIconSize(selected: entry.key == key),
          ),
        );
      } catch (_) {}
    }
  }

  LatLng? _selfMapAt() {
    final loc = _lastUserLoc;
    if (loc != null) return loc.position;
    if (_track.isNotEmpty) {
      final p = _track.last;
      return LatLng(p.lat, p.lng);
    }
    return null;
  }

  Future<void> _clearFriendPins(MapLibreMapController c) async {
    for (final s in _friendPinSymbols) {
      try {
        await c.removeSymbol(s);
      } catch (_) {}
    }
    _friendPinSymbols.clear();
    _friendPinUserBySymbol.clear();
  }

  Future<void> _ensureFriendPinImage(
    MapLibreMapController c, {
    required String imageId,
    required bool live,
    required String initials,
  }) async {
    try {
      await c.addImage(
        imageId,
        await buildFriendPinPng(live: live, initials: initials),
      );
    } catch (_) {}
  }

  /// Echte Presence. Nur Freund-Symbole tauschen — kein clearSymbols.
  Future<void> _drawGroupPins(MapLibreMapController c) async {
    await _clearFriendPins(c);
    final route = ref.read(activeRouteProvider);
    final group = await _groupForActiveRide();
    if (group == null) {
      if (mounted) _applyGroupHud(null);
      return;
    }
    final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
    final pins = await _rideGroups.visiblePins(groupId: group.id, zones: zones);
    final members = await _rideGroups.membersOf(group.id);
    final selfIds = await _rideGroups.selfIds();
    final me = await _rideGroups.localMember(group.id);
    final selfAt = _selfMapAt();
    final hud = _hudFrom(
      group: group,
      members: members,
      pins: pins,
      selfIds: selfIds,
      optIn: me?.liveOptIn ?? false,
      selfAt: selfAt,
    );
    if (!mounted) return;
    _applyGroupHud(hud);
    final l10n = AppLocalizations.of(context);
    for (final m in hud.mates) {
      if (m.self || !m.sharing || m.lat == null || m.lng == null) continue;
      final rel = m.stale
          ? null
          : friendRelLabel(
              m.rel,
              ahead: l10n.rideGroupAhead,
              behind: l10n.rideGroupBehind,
              left: l10n.rideGroupLeft,
              right: l10n.rideGroupRight,
            );
      final chip = friendPinChip(
        name: m.label,
        meters: m.meters,
        stale: m.stale,
        staleLabel: l10n.rideGroupPinStale,
        relLabel: rel,
      );
      final imageId = friendPinImageId(userId: m.userId, live: !m.stale);
      await _ensureFriendPinImage(
        c,
        imageId: imageId,
        live: !m.stale,
        initials: friendPinInitials(m.label),
      );
      try {
        final sym = await c.addSymbol(
          SymbolOptions(
            geometry: LatLng(m.lat!, m.lng!),
            iconImage: imageId,
            iconSize: RiderMapIconSize.friend,
            iconAnchor: 'bottom',
            textField: chip,
            textSize: 11,
            textColor: m.stale ? '#C4C4C8' : '#FFFFFF',
            textHaloColor: '#121215',
            textHaloWidth: 1.2,
            textOffset: const Offset(0, 1.15),
          ),
        );
        _friendPinSymbols.add(sym);
        _friendPinUserBySymbol[sym.id] = m.userId;
      } catch (_) {}
    }
  }

  RideGroupHudSnap _hudFrom({
    required RideGroup group,
    required List<RideGroupMember> members,
    required List<RideGroupPresence> pins,
    required Set<String> selfIds,
    required bool optIn,
    LatLng? selfAt,
  }) {
    final l10n = mounted ? AppLocalizations.of(context) : null;
    return buildRideGroupHudSnap(
      group: group,
      members: members,
      pins: pins,
      selfIds: selfIds,
      optIn: optIn,
      selfLat: selfAt?.latitude,
      selfLng: selfAt?.longitude,
      headingDeg: _headingForFriendRel(),
      fallbackSelf: l10n?.platzYou ?? 'Du',
      fallbackOther: l10n?.platzGuest ?? 'Gast',
      friendN: l10n?.rideGroupFriendN,
    );
  }

  double? _headingForFriendRel() {
    if (_track.length >= 2) {
      final a = _track[_track.length - 2];
      final b = _track.last;
      return _bearingDeg(a.lat, a.lng, b.lat, b.lng);
    }
    final gps = _lastUserLoc?.bearing;
    if (gps != null && gps.abs() > 0.5) return gps;
    return null;
  }

  void _applyGroupHud(RideGroupHudSnap? next) {
    final prev = _groupHud;
    final skip = _skipHudToast;
    _skipHudToast = false;
    if (!mounted) return;
    setState(() => _groupHud = next);
    if (skip) return;
    _toastHudDelta(
      friendHudDelta(prev: prev, next: next, now: DateTime.now()),
    );
  }

  void _toastHudDelta(RideGroupHudDelta delta) {
    if (delta.note == RideGroupHudNote.none) return;
    final now = DateTime.now();
    if (_lastHudToast == delta.note &&
        _lastHudToastAt != null &&
        now.difference(_lastHudToastAt!) < const Duration(seconds: 8)) {
      return;
    }
    _lastHudToast = delta.note;
    _lastHudToastAt = now;
    final l10n = _l10n;
    final msg = switch (delta.note) {
      RideGroupHudNote.windowClosed => l10n.rideGroupWindowClosedToast,
      RideGroupHudNote.mateLeft =>
        l10n.rideGroupMateLeftToast(delta.name ?? l10n.platzGuest),
      RideGroupHudNote.groupGone => l10n.rideGroupGoneToast,
      RideGroupHudNote.none => null,
    };
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _refreshGroupHudOnly() async {
    final group = await _groupForActiveRide();
    if (!mounted) return;
    if (group == null) {
      _applyGroupHud(null);
      return;
    }
    final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
    final pins = await _rideGroups.visiblePins(groupId: group.id, zones: zones);
    final members = await _rideGroups.membersOf(group.id);
    final selfIds = await _rideGroups.selfIds();
    final me = await _rideGroups.localMember(group.id);
    if (!mounted) return;
    _applyGroupHud(
      _hudFrom(
        group: group,
        members: members,
        pins: pins,
        selfIds: selfIds,
        optIn: me?.liveOptIn ?? false,
        selfAt: _selfMapAt(),
      ),
    );
  }

  Future<void> _toggleGroupOptIn(bool on) async {
    final id = _groupHud?.groupId;
    if (id == null) return;
    await _rideGroups.setLiveOptIn(id, on);
    if (!mounted) return;
    await _refreshGroupHudOnly();
    final c = _rideMap;
    if (c != null) await _drawGroupPins(c);
    if (!on || !mounted) return;
    final snap = _groupHud;
    if (snap == null) return;
    final others = [
      for (final m in snap.mates)
        if (!m.self) m.label,
    ];
    final line = friendShareOnLine(
      otherNames: others,
      untilHm: friendUntilHm(snap.windowEnd),
      one: _l10n.rideGroupShareOnLineOne,
      many: _l10n.rideGroupShareOnLineMany,
      none: _l10n.rideGroupShareOnLineNone,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(line), duration: const Duration(seconds: 4)),
    );
  }

  void _onFriendPinTapped(Symbol symbol) {
    final uid = _friendPinUserBySymbol[symbol.id];
    if (uid == null) return;
    RideGroupHudMate? mate;
    for (final m in _groupHud?.mates ?? const <RideGroupHudMate>[]) {
      if (m.userId == uid) mate = m;
    }
    if (mate == null || !mounted) return;
    _openFriendSheet(mate);
  }

  void _openFriendSheet(RideGroupHudMate mate) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => RideGroupFriendSheet(
        mate: mate,
        onFlyTo: () => unawaited(_flyToFriend(mate)),
      ),
    );
  }

  Future<void> _flyToFriend(RideGroupHudMate mate) async {
    final c = _rideMap;
    if (c == null || mate.lat == null || mate.lng == null) return;
    _cameraFollow = false;
    _programmaticCamera = true;
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(mate.lat!, mate.lng!), 15),
      );
    } catch (_) {}
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _programmaticCamera = false;
    });
    if (mounted) setState(() {});
  }

  Future<void> _frameGroupRiders() async {
    final c = _rideMap;
    if (c == null) return;
    final pts = <LatLng>[];
    final self = _selfMapAt();
    if (self != null) pts.add(self);
    for (final m in _groupHud?.mates ?? const <RideGroupHudMate>[]) {
      if (m.self || m.lat == null || m.lng == null) continue;
      pts.add(LatLng(m.lat!, m.lng!));
    }
    if (pts.isEmpty) return;
    _cameraFollow = false;
    _programmaticCamera = true;
    try {
      if (pts.length == 1) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14));
      } else {
        var swLat = pts.first.latitude;
        var swLng = pts.first.longitude;
        var neLat = swLat;
        var neLng = swLng;
        for (final p in pts) {
          swLat = math.min(swLat, p.latitude);
          swLng = math.min(swLng, p.longitude);
          neLat = math.max(neLat, p.latitude);
          neLng = math.max(neLng, p.longitude);
        }
        if ((neLat - swLat).abs() < 0.0005) {
          swLat -= 0.002;
          neLat += 0.002;
        }
        if ((neLng - swLng).abs() < 0.0005) {
          swLng -= 0.002;
          neLng += 0.002;
        }
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(swLat, swLng),
              northeast: LatLng(neLat, neLng),
            ),
            left: 48,
            top: 80,
            right: 48,
            bottom: 160,
          ),
        );
      }
    } catch (_) {}
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _programmaticCamera = false;
    });
    if (mounted) setState(() {});
  }

  Future<void> _extendGroupWindow() async {
    final id = _groupHud?.groupId;
    if (id == null) return;
    final choice = await showRideGroupExtendSheet(context);
    if (choice == null || !mounted) return;
    final ok = await _rideGroups.extendWindow(
      id,
      hours: choice.addHours ?? 1,
      newEnd: choice.newEnd,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_rideGroups.lastNote ?? _l10n.rideGroupGoneToast),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.rideGroupWindowExtended)),
    );
    await _refreshGroupHudOnly();
    final c = _rideMap;
    if (c != null) await _drawGroupPins(c);
  }

  Future<void> _leaveGroupFromRide() async {
    final id = _groupHud?.groupId;
    if (id == null) return;
    _skipHudToast = true;
    await _rideGroups.leaveGroup(id);
    unawaited(_together.stop(clearSession: true));
    if (!mounted) return;
    _applyGroupHud(null);
    final c = _rideMap;
    if (c != null) await _clearFriendPins(c);
  }

  Widget? _groupLiveBar() {
    final snap = _groupHud;
    if (snap == null) return null;
    return RideGroupLiveBar(
      snap: snap,
      onToggleOptIn: (on) => unawaited(_toggleGroupOptIn(on)),
      onFriend: _openFriendSheet,
      onFrameAll: () => unawaited(_frameGroupRiders()),
      onExtend: () => unawaited(_extendGroupWindow()),
      onLeave: () => unawaited(_leaveGroupFromRide()),
      onInvite: snap.isSession ? () => unawaited(_openTogether()) : null,
    );
  }

  void _onTogetherLook() {
    if (mounted) setState(() {});
  }

  Future<void> _adoptTogetherSnap(TogetherLookSnap snap) async {
    if (snap.group == null) return;
    await _rideGroups.adoptCloudBundle(
      RideGroupCloudBundle(
        me: snap.me,
        groups: [snap.group!.copyWith(onServer: true)],
        members: snap.members,
      ),
    );
    if (mounted) await _refreshGroupHudOnly();
  }

  String _togetherChipLine(AppLocalizations l10n) {
    final inbound = _together.snap?.inbound ?? const <TogetherInbound>[];
    final kind = togetherChipKind(
      looking: _together.looking,
      joinCode: _together.joinCode,
      inboundCount: inbound.length,
      outboundStatus: _together.outbound?.status ??
          (_together.pendingTo != null ? 'pending' : null),
    );
    return rideTogetherChipLine(
      l10n,
      kind: kind,
      joinCode: _together.joinCode,
      inboundName: inbound.isEmpty ? null : inbound.first.label,
    );
  }

  bool get _togetherActive =>
      _together.looking ||
      _together.joinCode != null ||
      (_together.snap?.inbound.isNotEmpty ?? false) ||
      _together.pendingTo != null ||
      _together.outbound != null;

  Widget? _togetherChip({required ActiveRoute? route}) {
    final inbound = _together.snap?.inbound ?? const <TogetherInbound>[];
    if (_togetherActive) {
      if (inbound.isNotEmpty) return null;
      return RideTogetherChip(
        onTap: () => unawaited(_openTogether()),
        line: _togetherChipLine(_l10n),
        compact: _cleanMode,
      );
    }
    if (_groupHud != null) {
      if (!_cleanMode) return null;
      final code = (_groupHud!.joinCode ?? '').trim();
      return RideTogetherChip(
        onTap: _openGroupRoster,
        line: code.isNotEmpty ? code : _groupHud!.title,
        compact: true,
      );
    }
    if (_cleanMode) return null;
    if (route != null) return null;
    return RideTogetherChip(onTap: () => unawaited(_openTogether()));
  }

  Widget? _hudSocialIsland({required ActiveRoute? route}) {
    if (_groupHud != null && !_cleanMode) return _groupLiveBar();
    return _togetherChip(route: route);
  }

  void _openGroupRoster() {
    final snap = _groupHud;
    if (snap == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => RideGroupRosterSheet(
        snap: snap,
        onFriend: _openFriendSheet,
        onFrameAll: () => unawaited(_frameGroupRiders()),
        onExtend: () => unawaited(_extendGroupWindow()),
        onLeave: () => unawaited(_leaveGroupFromRide()),
        onInvite: snap.isSession ? () => unawaited(_openTogether()) : null,
      ),
    );
  }

  Widget? _togetherInboundBanner() {
    final inbound = _together.snap?.inbound ?? const <TogetherInbound>[];
    if (inbound.isEmpty) return null;
    final l10n = _l10n;
    final first = inbound.first;
    return RideTogetherInboundCard(
      key: const Key('ride-together-inbound-hud'),
      onAccept: _together.busy
          ? null
          : () => unawaited(_respondTogether(first, true)),
      onDecline: _together.busy
          ? null
          : () => unawaited(_respondTogether(first, false)),
      acceptLabel: l10n.rideTogetherAccept,
      declineLabel: l10n.rideTogetherDecline,
      askLabel: l10n.rideTogetherInbound(
        first.label.trim().isEmpty ? l10n.rideTogetherAnon : first.label.trim(),
      ),
    );
  }

  Future<void> _respondTogether(TogetherInbound inbound, bool accept) async {
    final res = await _together.respond(inbound, accept);
    if (!mounted) return;
    if (accept && res != null && res.ok && res.bundle != null) {
      await _rideGroups.adoptCloudBundle(res.bundle!);
      await _refreshGroupPins();
    }
  }

  Future<void> _openTogether() async {
    final loc = _selfMapAt();
    final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
    if (!mounted) return;
    final inZone = loc != null &&
        RideGroupPolicy.pointInPrivacyZones(loc.latitude, loc.longitude, zones);
    _together.setFix(
      lat: loc?.latitude,
      lng: loc?.longitude,
      inPrivacyZone: inZone,
    );
    await _together.ensureStarted(
      lat: loc?.latitude,
      lng: loc?.longitude,
      inPrivacyZone: inZone,
      needGpsNote: _l10n.rideTogetherNeedGps,
      inZoneNote: _l10n.rideTogetherInZone,
      needLoginNote: _l10n.rideTogetherNeedLogin,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => RideTogetherSheet(
        groups: _rideGroups,
        look: _together,
        lat: loc?.latitude,
        lng: loc?.longitude,
        inPrivacyZone: inZone,
        onPaired: () {
          unawaited(_refreshGroupPins());
        },
      ),
    );
    if (mounted) await _refreshGroupHudOnly();
  }

  Future<RideGroup?> _groupForActiveRide() {
    final route = ref.read(activeRouteProvider);
    return _rideGroups.groupForRide(
      route?.id,
      preferGroupId: ref.read(ridePendingGroupIdProvider),
      catalogTourId:
          route == null || route.id.isEmpty ? null : catalogTourIdOf(route.id),
    );
  }

  Future<void> _publishGroupPresence(double lat, double lng) async {
    final now = DateTime.now();
    final last = _lastGroupPresenceAt;
    if (last != null && now.difference(last).inSeconds < 6) return;
    _lastGroupPresenceAt = now;
    final group = await _groupForActiveRide();
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
    final group = await _groupForActiveRide();
    if (group != null && group.onServer) {
      await _rideGroups.pullPresence(group.id);
    }
    final c = _rideMap;
    if (c != null && mounted) await _drawGroupPins(c);
  }

  /// LDI/CSC-Speed, sonst GPS. Bei lebendem Rad kein GPS-Drift im Stand.
  double get _effectiveSpeedKmh {
    return rideEffectiveSpeedKmh(
      liveSpeedKmh: _ldi?.speedKmh,
      wheelLive: ref.read(bleCoreProvider).hasWheelLive,
      gpsSpeedKmh: _gpsSpeedKmh,
    );
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

  void _considerPoiTts() {
    if (_ttsMuted || !ref.read(isRidingProvider)) return;
    final route = ref.read(activeRouteProvider);
    if (route == null || route.poiStops.isEmpty) return;
    final totalM = route.distanceKm * 1000;
    if (totalM <= 0 || route.durationMin <= 0) return;
    final poi = nextPoiStop(
      stops: [
        for (final p in route.poiStops)
          RoutePoiStop(atMin: p.atMin, title: p.title, kind: p.kind),
      ],
      alongRouteM: _alongRouteM,
      totalDistanceM: totalM,
      durationMin: route.durationMin,
    );
    if (poi == null) return;
    final eta = poiEtaMin(
      poi: poi,
      alongRouteM: _alongRouteM,
      totalDistanceM: totalM,
      durationMin: route.durationMin,
    );
    if (eta == null) return;
    final text = pickPoiAnnounce(
      title: poi.title,
      atMin: poi.atMin,
      etaMin: eta,
      spoken: _spokenAnnounceKeys,
    );
    if (text == null || _lastSpokenText == text) return;
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
      keepScreenOn: _batteryPreset.keepScreenOn,
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
        ble.wheelCircumferenceM = wheelCircumferenceM(wheel);
      }

      // Garage-Kopplung: CSC zuerst. Bosch LDI / Drive danach — LDI
      // abwarten, wenn sonst kein Tempo da ist.
      BikeBleBinding binding = const BikeBleBinding();
      var plan = const RideBleConnectPlan();
      final bikeId = active?.id;
      if (bikeId != null && bikeId.isNotEmpty) {
        binding = await ref.read(bikeBleStoreProvider).bindingForBike(bikeId);
        plan = rideBleConnectPlan(binding);
      }
      final preferredId = plan.wheelId;
      final kindHint = plan.wheelKind;

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

      if (plan.attachDrive &&
          plan.driveId != null &&
          plan.driveId!.isNotEmpty &&
          mounted &&
          ref.read(isRidingProvider)) {
        final attach = ble.attachSavedDrive(
          deviceId: plan.driveId!,
          kindHint: plan.driveKind,
        );
        if (plan.awaitDriveForSpeed || !ble.hasWheelLive) {
          await attach;
        } else {
          unawaited(attach);
        }
      }
      if (plan.startLdi &&
          !ble.isLdiLive &&
          mounted &&
          ref.read(isRidingProvider)) {
        unawaited(_retryBoschLdiWhileRiding(ble, plan));
      }
      if (!mounted || !ref.read(isRidingProvider)) return;
      if (!ble.hasWheelLive) {
        final kind = ble.connectedKind ?? plan.driveKind;
        final msg = kind != null && bikeBleKindIsDrive(kind)
            ? _l10n.bleDriveFailFor(kind, detail: ble.statusDetail)
            : _l10n.bleStatusDetailFor(
                ble.statusDetail ?? _l10n.rideNoBikeSensor,
              );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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

  /// Bike still waking after the first LDI window — keep advertising eb20.
  Future<void> _retryBoschLdiWhileRiding(
    BleCoreChannel ble,
    RideBleConnectPlan plan,
  ) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      final next = rideLdiRetryPlan(
        startLdi: plan.startLdi,
        ldiLive: ble.isLdiLive,
        stillRiding: mounted && ref.read(isRidingProvider),
        attempt: attempt,
      );
      if (!next.shouldRetry) return;
      await Future<void>.delayed(next.delay);
      if (!mounted || !ref.read(isRidingProvider) || ble.isLdiLive) return;
      try {
        await ble.startLdiAccessory(pairing: false);
      } catch (e) {
        debugPrint('ride: LDI retry $attempt failed ($e)');
      }
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
    _rideJournal = RideJournal.empty;
    unawaited(
      ref.read(garageRepositoryProvider).listPrivacyZones().then((zones) {
        _privacyZones = zones;
      }),
    );
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
    _drawingTour = false;
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
      final lastPt = _track.isNotEmpty ? _track.last : null;
      if (lastPt != null) {
        final hopM = haversineM(lastPt.lat, lastPt.lng, fix.lat, fix.lng);
        final dtSec =
            (fix.timestamp.millisecondsSinceEpoch - lastPt.timeMs) / 1000.0;
        if (isGpsTeleport(
          distanceM: hopM,
          dtSec: dtSec,
          accuracyM: fix.accuracyM,
        )) {
          if (mounted) setState(() {});
          return;
        }
      }
      _track.add(
        _liveTrackPoint(
          lat: fix.lat,
          lng: fix.lng,
          timeMs: fix.timestamp.millisecondsSinceEpoch,
          elev: fix.altitudeM,
        ),
      );
      unawaited(_syncOfflineHonestyAtFix(fix.lat, fix.lng));
      unawaited(_publishGroupPresence(fix.lat, fix.lng));
      if (_together.looking) {
        _together.setFix(lat: fix.lat, lng: fix.lng);
      }
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
      _considerPoiTts();
      unawaited(_highlightRideNextPoi(ref.read(activeRouteProvider)));
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
      _considerPoiTts();
      unawaited(_highlightRideNextPoi(ref.read(activeRouteProvider)));
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
    final fused = _metrics;
    final hr = live?.heartRateBpm;
    final cad = live?.cadenceRpm;
    final pwr = live?.riderPowerW;
    final spd = _gpsSpeedKmh;
    return TrackPoint(
      lat: lat,
      lng: lng,
      timeMs: timeMs,
      elev: elev,
      heartRateBpm: hr != null && hr >= 1 && hr <= 239 ? hr : null,
      cadenceRpm: cad != null && cad > 0.5 ? cad : null,
      powerW: pwr != null && pwr > 0 && pwr < 2500 ? pwr : null,
      leanDeg: fused?.leanAngleDeg,
      gPeak: fused?.gForcePeak,
      impact: fused?.impactDetected == true,
      speedKmh: spd > 0.4 && spd < 90 ? spd : null,
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

  bool _gravityFollowNow(ActiveRoute? route) {
    if (route == null || !route.gravitySession) return false;
    return gravityOnDescent(
      gravitySession: true,
      alongRouteM: _alongRouteM,
      joinAlongM: route.joinAlongM,
    );
  }

  /// First reaction when leaving the route: splice/graph if honest, else toast.
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
      final graphReady = await OfflinePackDirs.hasLegitimateActivatedPack();
      if (!mounted) return;
      // Close enough: splice remainder, no routing. Far: graph required.
      if (!graphReady && _crossTrackM > 25) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.rideOfflineRerouteToast),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
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
      final action = await showRerouteSheet(
        context,
        online: _networkOnline,
      );
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
      final graphReady = await OfflinePackDirs.hasLegitimateActivatedPack();
      if (!graphReady && _crossTrackM > 25) return;
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
      final needApproach = prog.crossTrackM > 25;
      if (needApproach) {
        final online = await rideHasNetwork();
        if (!online) {
          var covered = await OfflinePackDirs.legitimateCoversRoute(
            fromLng: lastFix.lng,
            fromLat: lastFix.lat,
            toLng: rejoinPt[0],
            toLat: rejoinPt[1],
          );
          if (!covered) {
            covered = await OfflinePackDirs.switchToPackCovering(
              fromLng: lastFix.lng,
              fromLat: lastFix.lat,
              toLng: rejoinPt[0],
              toLat: rejoinPt[1],
            );
            if (covered) {
              OfflineTilesStore.instance.clearCache();
              unawaited(_refreshConnectivityChip());
            }
          }
          if (!canOfflineRejoin(
            needApproach: true,
            graphReady: covered,
            routeCovered: covered,
          )) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_l10n.rideOfflineRerouteToast)),
              );
            }
            return;
          }
        }
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
        final flags = discoverAbEngineChoice(online: online);
        final result = await ref.read(routeRepositoryProvider).planRoute(
              from: GeoPoint(lastFix.lat, lastFix.lng),
              to: GeoPoint(rejoinPt[1], rejoinPt[0]),
              profile: rejoinProfile,
              accessLeg: route.gravitySession,
              preferOffline: flags.preferOffline,
              allowOfflineFirst: flags.allowOfflineFirst,
              allowOnline: flags.allowOnline,
              allowOfflineFallback: flags.allowOfflineFallback,
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

  String _liveTourName(DateTime started) {
    final d = started.toLocal();
    final stamp =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return 'Neue Tour $stamp';
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
    unawaited(_rideGroups.endFreerideSession());
    unawaited(_together.stop(clearSession: true));
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

    final tel = buildRideTelemetry([for (final p in track) p.toJson()]);
    final elevFromRoute = route?.elevationM;
    final elevFromTrack = tel.climbM.toDouble();
    // Persistenz = Profil. Mit GPS-Höhe gilt der Track — auch bei 0 hm.
    // Routen-Höhe nur Fallback, nie als Override.
    final elevHonest = tel.hasElev
        ? elevFromTrack
        : (elevFromRoute != null && elevFromRoute > 0 ? elevFromRoute : 0.0);
    final elevSource = tel.hasElev
        ? 'gps_track'
        : (elevFromRoute != null && elevFromRoute > 0 ? 'route' : 'none');

    final drawingTour = _drawingTour &&
        route == null &&
        rideActivityCanDrawTour(activeRouteId: route?.id);
    var record = await ref.read(rideRepositoryProvider).endRide(
      id: _rideId,
      bikeId: bike?.id,
      setupId: setup?.id,
      startedAt: started,
      endedAt: ended,
      distanceKm: distanceM / 1000,
      movingTimeSec: elapsed,
      name: drawingTour ? _liveTourName(started) : (route?.name ?? 'Freeride'),
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
        if (elevFromRoute != null && elevFromRoute > 0)
          'routeElevationM': elevFromRoute,
        if (tel.hasElev) ...{
          'climbM': tel.climbM,
          'descentM': tel.descentM,
          if (tel.maxGradePct != null) 'maxGradePct': tel.maxGradePct,
        },
        'liveTour': drawingTour,
        if (_ldi?.batterySocPercent != null) 'soc': _ldi!.batterySocPercent,
        ..._bleSamples.toSummary(),
        ..._rideJournal.toSummaryPatch(),
      },
    );
    if (drawingTour && track.length >= 2) {
      try {
        final entry = await saveRideAsTour(
          routes: ref.read(routeRepositoryProvider),
          ride: record,
          id: 'recorded-${record.id}',
          name: record.name,
          photoPaths: _rideJournal.photoPaths,
          media: _rideJournal.media,
          notes: _rideJournal.notes,
        );
        await ref
            .read(rideRepositoryProvider)
            .attachSavedRoute(record.id, entry.id);
        ref.invalidate(savedRoutesProvider);
        record = (await ref.read(rideRepositoryProvider).getById(record.id)) ??
            record;
      } catch (_) {}
    }

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
    ref.read(ridePendingGroupIdProvider.notifier).state = null;
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
      _rideJournal = RideJournal.empty;
      _pickingPhoto = false;
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
      _drawingTour = false;
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
    RidePrefs.navPuckRevision.removeListener(_onNavPuckPref);
    OfflineMapsPrefs.revision.removeListener(_onPackRevision);
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
    _together.removeListener(_onTogetherLook);
    unawaited(_together.stop(clearSession: true));
    _together.dispose();
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
    // Tick the HUD (ETA clock / Pro km·Zeit) even when Clean strip hides them.
    ref.watch(rideElapsedSecProvider);
    ref.watch(rideDistanceMProvider);

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
                      icon: ChromeGlyph(
                        'locate',
                        size: 22,
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
                          ? const ChromeGlyph(
                              'compass',
                              size: 22,
                              color: AppColors.accent,
                            )
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
                      icon: ChromeGlyph(
                        'split',
                        size: 22,
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
            compassEnabled: false,
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
          netHint: _streetNetHintBanner(),
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
          child: _groupLiveBar() ?? RideGroupPinBanner(routeId: route?.id),
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
  }) {
    final l10n = AppLocalizations.of(context);
    final ble = ref.read(bleCoreProvider);
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
    // Same Tempo · noch km · Ziel chrome with or without ActiveRoute.
    // Ohne Route: rest/Ziel stay empty — no km/h · km · Zeit light HUD.
    String etaLabel;
    if (rest == null) {
      etaLabel = NavHudTokens.emptyStat;
    } else if (splitRest) {
      etaLabel = formatHudKm(rest.restLoopKm ?? 0);
    } else if (rest.restKm != null && speed > 3) {
      final etaMin = (rest.restKm! / speed * 60).round();
      final etaAt = DateTime.now().add(Duration(minutes: etaMin));
      etaLabel =
          '${etaAt.hour.toString().padLeft(2, '0')}:${etaAt.minute.toString().padLeft(2, '0')}';
    } else if (rest.restKm != null && route!.durationMin > 0) {
      final frac = route.distanceKm > 0
          ? (_alongRouteM / 1000 / route.distanceKm).clamp(0.0, 1.0)
          : 0.0;
      final remainMin = (route.durationMin * (1 - frac)).round();
      final etaAt = DateTime.now().add(Duration(minutes: remainMin));
      etaLabel =
          '${etaAt.hour.toString().padLeft(2, '0')}:${etaAt.minute.toString().padLeft(2, '0')}';
    } else {
      etaLabel = NavHudTokens.emptyStat;
    }

    final midValue = rest == null
        ? NavHudTokens.emptyStat
        : formatHudKm(
            splitRest ? (rest.untilJoinKm ?? 0) : (rest.restKm ?? 0),
          );
    // nav-hud-tokens-v1 Clean labels: Tempo · noch km · Ziel.
    // CSC/LDI > 0.5 km/h still replaces GPS; caption becomes Rad.
    final speedCaption = l10n.hudSpeedCaptionFor(
      HudBikePeek.speedCaption(
        wheelDrives: HudBikePeek.wheelDrivesSpeed(_ldi?.speedKmh),
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
      leanAngleDeg: _displayLeanDeg,
      showChassis: _showsChassisUx(ref),
    );
    final midLabel = splitRest ? l10n.rideUntilJoin : l10n.rideRestKm;
    final rightLabel = splitRest ? l10n.rideRestLoop : l10n.rideEta;

    final effectiveLayer =
        layer == RideLiveLayer.suspension && !_showsChassisUx(ref)
            ? RideLiveLayer.map
            : layer;
    final showLiveDock = !_cleanMode && effectiveLayer != RideLiveLayer.map;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: locked,
            child: MapLibreMap(
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
        if (!locked) _hudLocateFab(paused: paused),
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
                  // Clean: dest chip only. Locate FAB sits on the map.
                  if (_cleanMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: Row(
                        children: [
                          if (route != null)
                            Expanded(child: _tourNameChip(theme, route.name))
                          else if (rideActivityCanDrawTour(
                            activeRouteId: null,
                          ))
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RideDrawTourChip(
                                  drawing: _drawingTour,
                                  onToggle: () {
                                    setState(
                                      () => _drawingTour = !_drawingTour,
                                    );
                                    unawaited(_drawRideMap());
                                  },
                                ),
                              ),
                            )
                          else
                            const Spacer(),
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
                          if (connectivityChipVisibleInClean(
                                  _connectivityState) &&
                              connectivityChipVisibleBesideMapHint(
                                state: _connectivityState,
                                mapHintVisible: rideHudStreetMapNeedsNet(
                                  online: _networkOnline,
                                  offlineStreetTiles: _offlineMapAvailable,
                                ),
                              ))
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RideConnectivityChip(
                                  state: _connectivityState,
                                  compact: true,
                                  mapHintVisible: rideHudStreetMapNeedsNet(
                                    online: _networkOnline,
                                    offlineStreetTiles: _offlineMapAvailable,
                                  ),
                                  onTap: _connectivityState ==
                                          ConnectivityChipState.live
                                      ? null
                                      : () => unawaited(
                                            _openOfflineMapsFromRide(),
                                          ),
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
                      iconName: navParts.iconName,
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
                  if (!locked) ...[
                    if (_streetNetHintBanner() case final hint?) hint,
                  ],
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
                if (!showLiveDock && _togetherInboundBanner() != null) ...[
                  _togetherInboundBanner()!,
                  const SizedBox(height: NavHudTokens.islandGapDp),
                ],
                if (!showLiveDock &&
                    _hudSocialIsland(route: route) != null) ...[
                  _hudSocialIsland(route: route)!,
                  const SizedBox(height: NavHudTokens.islandGapDp),
                ],
                if (!_cleanMode) ...[
                  RideHudLayerBar(
                    selected: effectiveLayer,
                    mapLabel: l10n.rideMap,
                    dataLabel: l10n.rideData,
                    chassisLabel: _showsChassisUx(ref)
                        ? l10n.chassisLayerLabelFor(
                            ref.watch(userProfileStoreProvider).preferredSport,
                          )
                        : null,
                    body: showLiveDock
                        ? _buildLiveDock(effectiveLayer, mount)
                        : null,
                    onSelected: (next) {
                      _bumpIdle();
                      ref.read(rideLayerProvider.notifier).state = next;
                    },
                    onClose: () {
                      _bumpIdle();
                      setState(() => _cleanMode = true);
                    },
                    closeLabel: l10n.rideHudClose,
                  ),
                  const SizedBox(height: NavHudTokens.islandGapDp),
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
                      _ridePhotoFab(),
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
                            child: const ChromeGlyph(
                              'pause',
                              size: 28,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!showLiveDock && bikePeek.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s),
                  RideBikePeek(chips: bikePeek),
                ],
                if (!ble.hasWheelLive &&
                    (ble.statusDetail == 'ldi_waiting_flow' ||
                        ble.statusDetail == l10n.bleLdiWaitingFlow)) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    l10n.rideLdiWaiting,
                    key: const Key('ride-ldi-waiting'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.meta(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (paused || !_cleanMode) ...[
                  const SizedBox(height: AppSpacing.s),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ridePhotoFab(),
                  ),
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
                : (_autoRerouteEnabled
                    ? _l10n.rideRecalc
                    : _l10n.rideTapOptions),
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

  double? get _displayLeanDeg {
    final raw = _metrics?.leanAngleDeg;
    if (raw == null) return null;
    return HudLeanCalibration.displayDeg(raw, _leanOffsetDeg);
  }

  bool get _canCalibrateLean => HudLeanCalibration.canCalibrate(
        rawLeanDeg: _metrics?.leanAngleDeg,
        speedKmh: _effectiveSpeedKmh,
      );

  void _calibrateLean() {
    if (!_canCalibrateLean) return;
    final raw = _metrics!.leanAngleDeg;
    final offset = HudLeanCalibration.offsetFromRaw(raw);
    HapticFeedback.selectionClick();
    setState(() => _leanOffsetDeg = offset);
    unawaited(RidePrefs.setLeanOffsetDeg(offset));
    unawaited(RidePrefs.setChassisMounted(true));
    if (ref.read(mountCheckProvider) != MountCheck.mounted) {
      ref.read(mountCheckProvider.notifier).state = MountCheck.mounted;
    }
  }

  void _resetLeanCal() {
    HapticFeedback.selectionClick();
    setState(() => _leanOffsetDeg = 0);
    unawaited(RidePrefs.setLeanOffsetDeg(0));
  }

  void _markChassisMounted() {
    ref.read(mountCheckProvider.notifier).state = MountCheck.mounted;
    unawaited(RidePrefs.setChassisMounted(true));
  }

  Widget _buildLiveDock(RideLiveLayer layer, MountCheck mount) {
    final primed = mount == MountCheck.mounted ||
        HudLeanCalibration.isCalibrated(_leanOffsetDeg);
    switch (layer) {
      case RideLiveLayer.map:
        return const SizedBox.shrink();
      case RideLiveLayer.data:
        return Semantics(
          label: _l10n.rideLiveData,
          child: RideHudDataDock(
            embedded: true,
            metrics: _liveDataMetrics(),
          ),
        );
      case RideLiveLayer.suspension:
        return RideHudChassisDock(
          embedded: true,
          mount: primed ? MountCheck.mounted : mount,
          leanDeg: _displayLeanDeg,
          gPeak: _metrics?.gForcePeak,
          flow: _metrics?.flowContribution,
          calibrated: HudLeanCalibration.isCalibrated(_leanOffsetDeg),
          calibrateEnabled: _canCalibrateLean,
          onMarkMounted: _markChassisMounted,
          onCalibrate: _calibrateLean,
          onResetCal: _resetLeanCal,
        );
    }
  }

  List<HudDockMetric> _liveDataMetrics() {
    final ble = ref.read(bleCoreProvider);
    final l10n = _l10n;
    final bleConnected = ble.hasWheelLive;
    final driveOnly = ble.isDriveWithoutMetrics;
    final bleCadence = _ldi?.cadenceRpm;
    // Tempo sits on the strip — dock only adds what the strip cannot.
    final out = <HudDockMetric>[];
    out.add(
      HudDockMetric(
        l10n.rideDistance,
        (ref.read(rideDistanceMProvider) / 1000).toStringAsFixed(2),
      ),
    );
    out.add(
        HudDockMetric(l10n.rideTime, _fmt(ref.read(rideElapsedSecProvider))));
    if (_ldi?.batterySocPercent != null) {
      out.add(
        HudDockMetric(
          l10n.rideSoc,
          '${_ldi!.batterySocPercent!.toStringAsFixed(0)}%',
        ),
      );
    }
    if (_ldi?.riderPowerW != null) {
      out.add(
        HudDockMetric(
          l10n.ridePower,
          '${_ldi!.riderPowerW!.toStringAsFixed(0)} W',
        ),
      );
    }
    if (_ldi?.assistMode != null && _ldi!.assistMode!.trim().isNotEmpty) {
      out.add(HudDockMetric(l10n.rideAssist, _ldi!.assistMode!));
    }
    if (_ldi?.heartRateBpm != null) {
      out.add(
        HudDockMetric(
          l10n.rideHeart,
          _ldi!.heartRateBpm!.toStringAsFixed(0),
        ),
      );
    }
    if (_hasCrank && bleCadence != null) {
      out.add(
        HudDockMetric(l10n.rideCadence, bleCadence.toStringAsFixed(0)),
      );
    }
    if (!bleConnected && driveOnly) {
      out.add(
        HudDockMetric(
          l10n.rideBikeSensor,
          l10n.bleDriveFailFor(
            ble.connectedKind ?? BikeBleKind.otherDrive,
            detail: ble.statusDetail,
          ),
        ),
      );
    }
    if (out.length <= RideHudLiveDock.maxDataChips) return out;
    return out.sublist(0, RideHudLiveDock.maxDataChips);
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
