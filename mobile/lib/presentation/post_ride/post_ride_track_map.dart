import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/offline_pmtiles_store.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../../l10n/app_localizations.dart';
import '../ride/widgets/ride_network.dart';

class RideMediaMapPin {
  const RideMediaMapPin({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

/// MapLibre-Karte mit GPS-Track als Polyline (Post-Ride / Freeride).
class PostRideTrackMap extends StatefulWidget {
  const PostRideTrackMap({
    super.key,
    required this.track,
    this.telemetry,
    this.height = 220,
    this.pins = const [],
    this.embedded = false,
  });

  /// Track points as `{lat,lng,...}`.
  final List<Map<String, dynamic>> track;

  /// Vorab berechnete Telemetrie — sonst einmal hier.
  final RideTelemetry? telemetry;
  final double height;
  final List<RideMediaMapPin> pins;

  /// Ohne eigene Ecken — sitzt in der Terrain-Fläche.
  final bool embedded;

  @override
  State<PostRideTrackMap> createState() => _PostRideTrackMapState();
}

class _PostRideTrackMapState extends State<PostRideTrackMap> {
  static final _gestures = <Factory<OneSequenceGestureRecognizer>>{
    Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
  };

  MapLibreMapController? _map;
  String _style = AppConfig.mapStyleUrl;
  int _drawGen = 0;
  bool _online = true;
  bool _offlineStreetTiles = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveStyle());
  }

  Future<void> _resolveStyle() async {
    try {
      final s = await AppConfig.resolveMapStyleUrl();
      final online = await rideHasNetwork();
      final street = rideHudUsesOfflineStreetTiles(
        liveStyle: AppConfig.mapStyleUrl,
        resolvedStyle: s,
      );
      var empty = '';
      try {
        empty = await OfflinePmtilesStore.emptyHudStyleUri();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _style = rideHudMapStyle(
          liveStyle: AppConfig.mapStyleUrl,
          resolvedStyle: s,
          online: online,
          offlineStreetTiles: street,
          emptyStyleUri: empty,
        );
        _online = online;
        _offlineStreetTiles = street;
      });
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant PostRideTrackMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.track, widget.track) ||
        !_samePins(oldWidget.pins, widget.pins)) {
      unawaited(_draw());
    }
  }

  bool _samePins(List<RideMediaMapPin> a, List<RideMediaMapPin> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].lat != b[i].lat || a[i].lng != b[i].lng) return false;
    }
    return true;
  }

  List<LatLng> get _line {
    final out = <LatLng>[];
    for (final p in widget.track) {
      final lat = (p['lat'] as num?)?.toDouble();
      final lng = (p['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      out.add(LatLng(lat, lng));
    }
    // Display-Decimation für sehr lange Freerides.
    if (out.length <= 2500) return out;
    final step = (out.length / 2000).ceil();
    final sampled = <LatLng>[
      for (var i = 0; i < out.length; i += step) out[i],
    ];
    if (sampled.last != out.last) sampled.add(out.last);
    return sampled;
  }

  LatLng get _center {
    final line = _line;
    if (line.isEmpty) return const LatLng(47.2, 6.5);
    return line[line.length ~/ 2];
  }

  Future<void> _draw() async {
    final c = _map;
    final line = _line;
    if (c == null || line.length < 2) return;
    final gen = ++_drawGen;
    try {
      await c.clearLines();
      if (gen != _drawGen) return;
      await c.addLine(
        LineOptions(
          geometry: line,
          lineColor: '#1A120C',
          lineWidth: 10,
          lineOpacity: 0.72,
          lineJoin: 'round',
        ),
      );
      if (gen != _drawGen) return;
      final graded = gradeMapLayers(
        widget.telemetry ?? buildRideTelemetry(widget.track),
      );
      if (graded.isEmpty) {
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: '#FF6A00',
            lineWidth: 5.5,
            lineJoin: 'round',
          ),
        );
      } else {
        for (final seg in graded) {
          if (gen != _drawGen) return;
          if (seg.points.length < 2) continue;
          await c.addLine(
            LineOptions(
              geometry: [
                for (final p in seg.points) LatLng(p.lat, p.lng),
              ],
              lineColor: seg.colorHex,
              lineWidth: 5.5,
              lineJoin: 'round',
            ),
          );
        }
      }
      if (gen != _drawGen) return;
      await _fitBounds(c, line);
      if (gen != _drawGen) return;
      try {
        await c.clearSymbols();
      } catch (_) {}
      for (final pin in widget.pins) {
        if (gen != _drawGen) return;
        try {
          await c.addSymbol(
            SymbolOptions(
              geometry: LatLng(pin.lat, pin.lng),
              textField: '●',
              textSize: 16,
              textColor: '#FF6A00',
              textHaloColor: '#FFFFFF',
              textHaloWidth: 1.6,
            ),
          );
        } catch (_) {}
      }
    } catch (_) {
      // Style/PlatformView kann während dispose weg sein.
    }
  }

  Future<void> _fitBounds(MapLibreMapController c, List<LatLng> line) async {
    double swLat = line.first.latitude, neLat = line.first.latitude;
    double swLng = line.first.longitude, neLng = line.first.longitude;
    for (final p in line) {
      swLat = math.min(swLat, p.latitude);
      neLat = math.max(neLat, p.latitude);
      swLng = math.min(swLng, p.longitude);
      neLng = math.max(neLng, p.longitude);
    }
    final padLat = math.max((neLat - swLat) * 0.12, 0.002);
    final padLng = math.max((neLng - swLng) * 0.12, 0.002);
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(swLat - padLat, swLng - padLng),
            northeast: LatLng(neLat + padLat, neLng + padLng),
          ),
          left: 36,
          top: 36,
          right: 36,
          bottom: rideHudStreetMapNeedsNet(
            online: _online,
            offlineStreetTiles: _offlineStreetTiles,
          )
              ? 56
              : 36,
        ),
      );
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(_center, 13));
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line.length < 2) {
      return SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Text(
              'Kein GPS-Track',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      );
    }

    final mapHint = rideHudStreetMapNeedsNet(
      online: _online,
      offlineStreetTiles: _offlineStreetTiles,
    );
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.embedded
            ? BorderRadius.zero
            : BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            MapLibreMap(
              key: ValueKey('post-ride-map-$_style'),
              styleString: _style,
              initialCameraPosition: CameraPosition(target: _center, zoom: 13),
              myLocationEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              gestureRecognizers: _gestures,
              onMapCreated: (c) => _map = c,
              onStyleLoadedCallback: () => unawaited(_draw()),
            ),
            if (mapHint)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Material(
                    color: AppColors.charcoal.withValues(alpha: 0.78),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        AppLocalizations.of(context).rideHudStreetNeedsNet,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
    );
  }
}
