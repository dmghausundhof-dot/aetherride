import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/basemap_street_contrast.dart';
import '../../data/routing/map_style_url.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/privacy/privacy_zone_map.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../map/map_pin_image.dart';
import '../shared/map_ornaments.dart';
import '../shared/map_loading_scrim.dart';
import 'privacy_zone_editor_panel.dart';

/// MapLibre braucht Eager-Gesten, sonst frisst Parent/PlatformView Zoom/Pan.
final _privacyMapGestures = <Factory<OneSequenceGestureRecognizer>>{
  Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
};

Future<PrivacyZone?> openPrivacyZoneMap(
  BuildContext context, {
  PrivacyZone? existing,
}) {
  return Navigator.of(context).push<PrivacyZone>(
    MaterialPageRoute(
      builder: (_) => PrivacyZoneMapScreen(existing: existing),
    ),
  );
}

/// Fullscreen-Karte zum Setzen/Anpassen einer Privacy-Zone (Tap + Radius-Slider).
class PrivacyZoneMapScreen extends ConsumerStatefulWidget {
  const PrivacyZoneMapScreen({super.key, this.existing});

  final PrivacyZone? existing;

  @override
  ConsumerState<PrivacyZoneMapScreen> createState() =>
      _PrivacyZoneMapScreenState();
}

class _PrivacyZoneMapScreenState extends ConsumerState<PrivacyZoneMapScreen> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  String _style = AppConfig.mapStyleUrl;
  PrivacyZoneMapOrigin? _origin;
  bool _originReady = false;

  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _pinImagesReady = false;
  Fill? _fill;
  Line? _line;
  Symbol? _pin;
  int _overlayGen = 0;

  double? _centerLat;
  double? _centerLng;
  double _radiusM = kPrivacyZoneDefaultRadiusM;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelCtrl = TextEditingController(
      text: existing?.label ?? kPrivacyZoneDefaultLabel,
    );
    _radiusM = existing != null
        ? clampPrivacyZoneRadius(existing.radiusM)
        : kPrivacyZoneDefaultRadiusM;
    if (existing != null) {
      _centerLat = existing.lat;
      _centerLng = existing.lng;
    }
    _latCtrl = TextEditingController(
      text: existing != null ? existing.lat.toStringAsFixed(5) : '',
    );
    _lngCtrl = TextEditingController(
      text: existing != null ? existing.lng.toStringAsFixed(5) : '',
    );
    AppConfig.resolveMapStyleUrl().then((s) {
      if (mounted && s != _style) setState(() => _style = s);
    });
    unawaited(prefetchMapStyleJson(_style));
    unawaited(_resolveOrigin());
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  bool get _placed =>
      _centerLat != null &&
      _centerLng != null &&
      isPlausiblePrivacyCoord(_centerLat!, _centerLng!);

  Future<void> _resolveOrigin() async {
    final existing = widget.existing;
    if (existing != null &&
        isPlausiblePrivacyCoord(existing.lat, existing.lng)) {
      if (!mounted) return;
      setState(() {
        _origin = PrivacyZoneMapOrigin(
          lat: existing.lat,
          lng: existing.lng,
          zoom: cameraZoomForPrivacyRadius(existing.radiusM, lat: existing.lat),
          source: PrivacyZoneMapOriginSource.existing,
        );
        _originReady = true;
      });
      return;
    }

    Position? gps;
    try {
      gps = await Geolocator.getLastKnownPosition();
    } catch (_) {}
    if (gps == null) {
      try {
        gps = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {}
    }
    List<Map<String, dynamic>>? track;
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isNotEmpty) track = rides.first.track;
    } catch (_) {}
    if (!mounted) return;
    final origin = resolvePrivacyZoneMapOrigin(
      gpsLat: gps?.latitude,
      gpsLng: gps?.longitude,
      lastRideTrack: track,
      countryCode: Localizations.localeOf(context).countryCode,
    );
    setState(() {
      _origin = origin;
      _originReady = true;
      if (!_placed && origin.shouldPrePlace) {
        _centerLat = origin.lat;
        _centerLng = origin.lng;
        _latCtrl.text = origin.lat.toStringAsFixed(5);
        _lngCtrl.text = origin.lng.toStringAsFixed(5);
      }
    });
  }

  void _placeAt(double lat, double lng) {
    if (!isPlausiblePrivacyCoord(lat, lng)) return;
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _latCtrl.text = lat.toStringAsFixed(5);
      _lngCtrl.text = lng.toStringAsFixed(5);
    });
    unawaited(_syncOverlay());
  }

  Future<void> _ensurePinImage(MapLibreMapController c) async {
    if (_pinImagesReady) return;
    try {
      final png = await buildMapPinPng(fill: AppColors.accent);
      await c.addImage('privacy-zone-pin', png);
      _pinImagesReady = true;
    } catch (_) {}
  }

  Future<void> _onStyleReady(MapLibreMapController c) async {
    await _ensurePinImage(c);
    await fixBasemapWaterLayers(c);
    await warmBasemapNatureFills(c);
    await _syncOverlay();
  }

  Future<void> _syncOverlay() async {
    final c = _map;
    final lat = _centerLat;
    final lng = _centerLng;
    if (c == null || !_styleReady || lat == null || lng == null) return;
    if (!isPlausiblePrivacyCoord(lat, lng)) return;
    final gen = ++_overlayGen;
    final ring = [
      for (final p in privacyZoneCircleRing(
        lat: lat,
        lng: lng,
        radiusM: _radiusM,
      ))
        LatLng(p.lat, p.lng),
    ];
    final fillOpts = FillOptions(
      geometry: [ring],
      fillColor: '#FF6A00',
      fillOpacity: 0.22,
      fillOutlineColor: '#FF6A00',
    );
    final lineOpts = LineOptions(
      geometry: ring,
      lineColor: '#FF6A00',
      lineWidth: 2.5,
      lineOpacity: 0.9,
      lineJoin: 'round',
    );
    final pinOpts = SymbolOptions(
      geometry: LatLng(lat, lng),
      iconImage: _pinImagesReady ? 'privacy-zone-pin' : null,
      iconSize: 1.05,
      iconAnchor: 'center',
    );
    try {
      if (_fill == null) {
        _fill = await c.addFill(fillOpts);
        if (gen != _overlayGen) return;
        _line = await c.addLine(lineOpts);
        if (gen != _overlayGen) return;
        _pin = await c.addSymbol(pinOpts);
      } else {
        await c.updateFill(_fill!, fillOpts);
        if (gen != _overlayGen) return;
        final line = _line;
        if (line != null) await c.updateLine(line, lineOpts);
        if (gen != _overlayGen) return;
        final pin = _pin;
        if (pin != null) await c.updateSymbol(pin, pinOpts);
      }
    } catch (_) {
      // Style/PlatformView kann während dispose weg sein.
    }
  }

  Future<void> _fitToZone() async {
    final c = _map;
    final lat = _centerLat;
    final lng = _centerLng;
    if (c == null || lat == null || lng == null) return;
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          cameraZoomForPrivacyRadius(_radiusM, lat: lat),
        ),
      );
    } catch (_) {}
  }

  void _onRadiusChanged(double v) {
    setState(() => _radiusM = clampPrivacyZoneRadius(v));
    unawaited(_syncOverlay());
  }

  void _applyCoords() {
    final l10n = AppLocalizations.of(context);
    final lat = parsePrivacyZoneCoord(_latCtrl.text, isLat: true);
    final lng = parsePrivacyZoneCoord(_lngCtrl.text, isLat: false);
    if (lat == null || lng == null || !isPlausiblePrivacyCoord(lat, lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.privacyZoneInvalidCoords)),
      );
      return;
    }
    _placeAt(lat, lng);
    unawaited(_fitToZone());
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    if (!_placed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.privacyZoneNeedTap)),
      );
      return;
    }
    final existing = widget.existing;
    final zone = privacyZoneFromDraft(
      id: existing?.id ?? const Uuid().v4(),
      label: _labelCtrl.text,
      lat: _centerLat!,
      lng: _centerLng!,
      radiusM: _radiusM.roundToDouble(),
    );
    Navigator.of(context).pop(zone);
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final editing = widget.existing != null;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(editing ? l10n.privacyZoneEdit : l10n.privacyZoneTitle),
        leadingWidth: 108,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        actions: [
          TextButton(
            onPressed: _placed ? _save : null,
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: !_originReady || origin == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      MapLibreMap(
                        key: ValueKey('privacy-zone-map-$_style'),
                        styleString: _style,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(origin.lat, origin.lng),
                          zoom: origin.zoom,
                        ),
                        myLocationEnabled: true,
                        myLocationTrackingMode: MyLocationTrackingMode.none,
                        compassEnabled: true,
                        compassViewPosition: MapOrnaments.compassPosition,
                        compassViewMargins:
                            MapOrnaments.compassMargins(context),
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        gestureRecognizers: _privacyMapGestures,
                        annotationOrder: const [
                          AnnotationType.fill,
                          AnnotationType.line,
                          AnnotationType.symbol,
                        ],
                        annotationConsumeTapEvents: const [
                          AnnotationType.symbol,
                        ],
                        onMapCreated: (c) => _map = c,
                        onStyleLoadedCallback: () {
                          if (mounted) setState(() => _styleReady = true);
                          _pinImagesReady = false;
                          _fill = null;
                          _line = null;
                          _pin = null;
                          final c = _map;
                          if (c == null) return;
                          unawaited(_onStyleReady(c));
                        },
                        onMapClick: (point, latLng) {
                          _placeAt(latLng.latitude, latLng.longitude);
                        },
                      ),
                      if (!_styleReady)
                        const Positioned.fill(child: MapLoadingScrim()),
                      if (!_placed)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: IgnorePointer(
                            child: Material(
                              color: AppColors.overlay.withValues(alpha: 0.8),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  l10n.privacyZoneTapShort,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: SingleChildScrollView(
                    child: PrivacyZoneEditorPanel(
                      labelController: _labelCtrl,
                      radiusM: _radiusM,
                      onRadiusChanged: _onRadiusChanged,
                      onRadiusChangeEnd: (_) => unawaited(_fitToZone()),
                      latController: _latCtrl,
                      lngController: _lngCtrl,
                      onApplyCoords: _applyCoords,
                      placed: _placed,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
