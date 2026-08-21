import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../domain/routing/tour_nav_geometry.dart';

/// Hit-tests only the live plan ribbon so map pan/zoom still reach MapLibre.
class PlanLineGrabLayer extends StatefulWidget {
  const PlanLineGrabLayer({
    super.key,
    required this.camera,
    required this.lineLngLat,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onCancel,
    this.pinLngLat,
  });

  final CameraPosition? Function() camera;
  final List<List<double>> Function() lineLngLat;
  final List<List<double>> Function()? pinLngLat;
  final void Function(double lat, double lng) onDown;
  final void Function(double lat, double lng) onMove;
  final void Function(double lat, double lng, {required bool dragged}) onUp;
  final VoidCallback onCancel;

  @override
  State<PlanLineGrabLayer> createState() => _PlanLineGrabLayerState();
}

class _PlanLineGrabLayerState extends State<PlanLineGrabLayer> {
  Offset? _down;
  bool _dragged = false;

  bool _hits(Offset local, Size size) {
    final cam = widget.camera();
    if (cam == null) return false;
    return planMapPointerHitsRibbon(
      localX: local.dx,
      localY: local.dy,
      width: size.width,
      height: size.height,
      centerLng: cam.target.longitude,
      centerLat: cam.target.latitude,
      zoom: cam.zoom,
      bearingDeg: cam.bearing,
      tiltDeg: cam.tilt,
      lineLngLat: widget.lineLngLat(),
      pinLngLat: widget.pinLngLat?.call() ?? const [],
    );
  }

  ({double lat, double lng})? _toLatLng(Offset local, Size size) {
    final cam = widget.camera();
    if (cam == null) return null;
    final ll = planMapScreenToLngLat(
      localX: local.dx,
      localY: local.dy,
      width: size.width,
      height: size.height,
      centerLng: cam.target.longitude,
      centerLat: cam.target.latitude,
      zoom: cam.zoom,
      bearingDeg: cam.bearing,
      tiltDeg: cam.tilt,
    );
    if (ll == null) return null;
    return (lat: ll.lat, lng: ll.lng);
  }

  @override
  Widget build(BuildContext context) {
    return _PlanLineHit(
      hitsLine: _hits,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          _down = e.localPosition;
          _dragged = false;
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final ll = _toLatLng(e.localPosition, box.size);
          if (ll == null) return;
          widget.onDown(ll.lat, ll.lng);
        },
        onPointerMove: (e) {
          if (_down != null &&
              (e.localPosition - _down!).distance >= kPlanLineGrabMovePx) {
            _dragged = true;
          }
          if (!_dragged) return;
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final ll = _toLatLng(e.localPosition, box.size);
          if (ll == null) return;
          widget.onMove(ll.lat, ll.lng);
        },
        onPointerUp: (e) {
          final dragged = _dragged;
          _down = null;
          _dragged = false;
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) {
            widget.onCancel();
            return;
          }
          final ll = _toLatLng(e.localPosition, box.size);
          if (ll == null) {
            widget.onCancel();
            return;
          }
          widget.onUp(ll.lat, ll.lng, dragged: dragged);
        },
        onPointerCancel: (_) {
          _down = null;
          _dragged = false;
          widget.onCancel();
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlanLineHit extends SingleChildRenderObjectWidget {
  const _PlanLineHit({required this.hitsLine, required super.child});

  final bool Function(Offset local, Size size) hitsLine;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPlanLineHit(hitsLine: hitsLine);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderPlanLineHit renderObject,
  ) {
    renderObject.hitsLine = hitsLine;
  }
}

class _RenderPlanLineHit extends RenderProxyBox {
  _RenderPlanLineHit({required this.hitsLine});

  bool Function(Offset local, Size size) hitsLine;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position) || !hitsLine(position, size)) return false;
    return super.hitTest(result, position: position);
  }
}
