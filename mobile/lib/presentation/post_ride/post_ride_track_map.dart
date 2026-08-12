import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';

/// MapLibre-Karte mit GPS-Track als Polyline (Post-Ride / Freeride).
class PostRideTrackMap extends StatefulWidget {
  const PostRideTrackMap({
    super.key,
    required this.track,
    this.height = 220,
  });

  /// Track points as `{lat,lng,...}`.
  final List<Map<String, dynamic>> track;
  final double height;

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

  @override
  void initState() {
    super.initState();
    AppConfig.resolveMapStyleUrl().then((s) {
      if (mounted) setState(() => _style = s);
    });
  }

  @override
  void didUpdateWidget(covariant PostRideTrackMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.track, widget.track)) {
      unawaited(_draw());
    }
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
          lineColor: '#BF360C',
          lineWidth: 10,
          lineOpacity: 0.85,
          lineJoin: 'round',
        ),
      );
      if (gen != _drawGen) return;
      await c.addLine(
        LineOptions(
          geometry: line,
          lineColor: '#FF6B35',
          lineWidth: 5.5,
          lineJoin: 'round',
        ),
      );
      if (gen != _drawGen) return;
      await _fitBounds(c, line);
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
          bottom: 36,
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.35)),
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

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: MapLibreMap(
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
      ),
    );
  }
}
