import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../domain/routing/tour_nav_geometry.dart';

/// Listens on the map without stealing hit-tests, so pinch still reaches MapLibre.
/// One finger on the ribbon: tap / rubber / hold. A second finger cancels.
class PlanLineGrabLayer extends StatefulWidget {
  const PlanLineGrabLayer({
    super.key,
    required this.camera,
    required this.lineLngLat,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onCancel,
    required this.child,
    this.pinLngLat,
    this.screenCache,
    this.nativeUnproject,
    this.enabled = true,
    this.onExclusiveGrab,
    this.onHoldCancel,
  });

  final CameraPosition? Function() camera;
  final List<List<double>> Function() lineLngLat;
  final List<List<double>> Function()? pinLngLat;
  final PlanGrabScreenCache? Function()? screenCache;
  final Future<({double lat, double lng})?> Function(double x, double y)?
      nativeUnproject;
  final void Function(double lat, double lng) onDown;
  final void Function(double lat, double lng) onMove;
  final void Function(double lat, double lng, {required bool dragged}) onUp;
  final VoidCallback onCancel;
  final ValueChanged<bool>? onExclusiveGrab;
  /// Finger slipped — cancel hold→dest before exclusive rubber.
  final VoidCallback? onHoldCancel;
  final bool enabled;
  final Widget child;

  @override
  State<PlanLineGrabLayer> createState() => _PlanLineGrabLayerState();
}

class _PlanLineGrabLayerState extends State<PlanLineGrabLayer> {
  final Set<int> _pointers = {};
  int? _grabId;
  Offset? _down;
  bool _dragged = false;
  bool _exclusive = false;
  bool _grabArmed = false;
  bool _holdCancelSent = false;
  int _unprojectGen = 0;
  ({double lat, double lng})? _lastNative;
  Offset? _pendingNativeLocal;
  Timer? _nativeDebounce;

  PlanGrabScreenCache? get _cache {
    final c = widget.screenCache?.call();
    return c != null && c.usable ? c : null;
  }

  bool _hits(Offset local, Size size) {
    final cache = _cache;
    if (cache != null) {
      return planMapPointerHitsScreenRibbon(
        localX: local.dx,
        localY: local.dy,
        lineScreen: cache.lineScreen,
        pinScreen: cache.pinScreen,
      );
    }
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

  ({double lat, double lng})? _toLatLng(
    Offset local,
    Size size, {
    required bool preferLine,
  }) {
    final cache = _cache;
    if (cache != null && preferLine) {
      final onLine = planLngLatAtScreenRibbon(
        localX: local.dx,
        localY: local.dy,
        lineScreen: cache.lineScreen,
        lineLngLat: cache.lineLngLat,
      );
      if (onLine != null) return (lat: onLine.lat, lng: onLine.lng);
    }
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

  void _requestNative(
    Offset local, {
    required bool drivePreview,
  }) {
    final fn = widget.nativeUnproject;
    if (fn == null) return;
    final gen = ++_unprojectGen;
    fn(local.dx, local.dy).then((ll) {
      if (gen != _unprojectGen || ll == null) return;
      _lastNative = ll;
      if (!drivePreview || !_dragged) return;
      widget.onMove(ll.lat, ll.lng);
    });
  }

  void _scheduleNative(
    Offset local, {
    required bool drivePreview,
  }) {
    _pendingNativeLocal = local;
    _nativeDebounce?.cancel();
    _nativeDebounce = Timer(const Duration(milliseconds: 32), () {
      final p = _pendingNativeLocal;
      if (p == null) return;
      _requestNative(p, drivePreview: drivePreview);
    });
  }

  void _setExclusive(bool value) {
    if (_exclusive == value) return;
    _exclusive = value;
    widget.onExclusiveGrab?.call(value);
  }

  void _clearGrab({required bool notify}) {
    final had = _grabArmed || _dragged || _exclusive;
    _grabId = null;
    _down = null;
    _dragged = false;
    _grabArmed = false;
    _holdCancelSent = false;
    _lastNative = null;
    _pendingNativeLocal = null;
    _nativeDebounce?.cancel();
    _nativeDebounce = null;
    _unprojectGen++;
    _setExclusive(false);
    if (notify && had) widget.onCancel();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!widget.enabled) return;
    _pointers.add(e.pointer);
    if (planLineGrabYieldsToPinch(pointerCount: _pointers.length)) {
      _clearGrab(notify: true);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    if (!_hits(e.localPosition, box.size)) return;
    final ll = _toLatLng(e.localPosition, box.size, preferLine: true);
    if (ll == null) return;
    _grabId = e.pointer;
    _down = e.localPosition;
    _dragged = false;
    _grabArmed = true;
    _holdCancelSent = false;
    widget.onDown(ll.lat, ll.lng);
    _requestNative(e.localPosition, drivePreview: false);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!widget.enabled) return;
    if (planLineGrabYieldsToPinch(pointerCount: _pointers.length)) {
      _clearGrab(notify: true);
      return;
    }
    if (e.pointer != _grabId || _down == null) return;
    final movePx = (e.localPosition - _down!).distance;
    if (!_holdCancelSent &&
        planLineHoldCancelsOnMove(movePx: movePx)) {
      _holdCancelSent = true;
      widget.onHoldCancel?.call();
    }
    if (planLineGrabBecomesExclusive(
      pointerCount: _pointers.length,
      movePx: movePx,
    )) {
      _dragged = true;
      _setExclusive(true);
    }
    if (!_dragged) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final stillOnLine = _hits(e.localPosition, box.size);
    final ll = _toLatLng(
      e.localPosition,
      box.size,
      preferLine: stillOnLine,
    );
    if (ll != null) widget.onMove(ll.lat, ll.lng);
    // Sync math/cache owns the rubber preview; native only fills _lastNative
    // for commit (or drives preview when sync has nothing).
    _scheduleNative(
      e.localPosition,
      drivePreview: planGrabNativeDrivesPreview(hasSyncPreview: ll != null),
    );
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (e.pointer != _grabId) return;
    final dragged = _dragged;
    final box = context.findRenderObject() as RenderBox?;
    _nativeDebounce?.cancel();
    _nativeDebounce = null;
    _pendingNativeLocal = null;
    _grabId = null;
    _down = null;
    _dragged = false;
    _grabArmed = false;
    _setExclusive(false);
    if (box == null) {
      widget.onCancel();
      return;
    }
    final stillOnLine = _hits(e.localPosition, box.size);
    unawaited(_finishUp(
      local: e.localPosition,
      size: box.size,
      dragged: dragged,
      stillOnLine: stillOnLine,
    ));
  }

  Future<void> _finishUp({
    required Offset local,
    required Size size,
    required bool dragged,
    required bool stillOnLine,
  }) async {
    final gen = ++_unprojectGen;
    ({double lat, double lng})? ll;
    if (!dragged || stillOnLine) {
      ll = _toLatLng(local, size, preferLine: true);
    } else {
      final fn = widget.nativeUnproject;
      if (fn != null) {
        try {
          ll = await fn(local.dx, local.dy);
        } catch (_) {}
      }
      if (gen != _unprojectGen) return;
      ll ??= _lastNative ?? _toLatLng(local, size, preferLine: false);
    }
    _lastNative = null;
    if (gen != _unprojectGen) return;
    if (ll == null) {
      widget.onCancel();
      return;
    }
    widget.onUp(ll.lat, ll.lng, dragged: dragged);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (e.pointer == _grabId || _grabArmed) {
      _clearGrab(notify: true);
    }
  }

  @override
  void dispose() {
    _nativeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}

/// “Route passt sich an…” at the last finger, not in the bottom sheet.
class PlanMapFingerHint extends StatelessWidget {
  const PlanMapFingerHint({
    super.key,
    required this.camera,
    required this.lat,
    required this.lng,
    required this.label,
    this.undoLabel,
    this.onUndo,
    this.avoidRightPx = kPlanMapChromeFabColPx,
    this.avoidTopPx = 0,
    this.avoidBottomPx = 0,
    this.nativeScreen,
    this.firstAb = false,
    this.preferAbove = false,
  });

  final CameraPosition? Function() camera;
  final double lat;
  final double lng;
  final String label;
  final String? undoLabel;
  final VoidCallback? onUndo;
  final double avoidRightPx;
  final double avoidTopPx;
  final double avoidBottomPx;
  final Offset? nativeScreen;
  final bool firstAb;
  final bool preferAbove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 8) {
          return const SizedBox.shrink();
        }
        final cam = camera();
        final s = cam == null
            ? null
            : planMapLngLatToScreen(
                lng: lng,
                lat: lat,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                centerLng: cam.target.longitude,
                centerLat: cam.target.latitude,
                zoom: cam.zoom,
                bearingDeg: cam.bearing,
                tiltDeg: cam.tilt,
              );
        if (s == null && nativeScreen == null) {
          return const SizedBox.shrink();
        }
        final fingerX = nativeScreen?.dx ?? s!.x;
        final fingerY = nativeScreen?.dy ?? s!.y;
        final chipW = planFingerHintChipW(
          undo: onUndo != null,
          firstAb: firstAb,
        );
        const chipH = 40.0;
        final box = planFingerHintPlacement(
          fingerX: fingerX,
          fingerY: fingerY,
          mapW: constraints.maxWidth,
          mapH: constraints.maxHeight,
          chipW: chipW,
          chipH: chipH,
          avoidRight: avoidRightPx,
          avoidTop: avoidTopPx,
          avoidBottom: avoidBottomPx,
          preferAbove: preferAbove,
        );
        return Stack(
          children: [
            Positioned(
              left: box.left,
              top: box.top,
              child: Material(
                color: const Color(0xF21A120C),
                elevation: 6,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: chipW,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (onUndo != null && undoLabel != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onUndo,
                            child: Text(
                              undoLabel!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFB080),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
