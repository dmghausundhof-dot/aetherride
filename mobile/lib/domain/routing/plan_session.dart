import '../community/labeled_via.dart';
import '../../data/routing/routing_client.dart';
import 'route_progress.dart';

enum PlanWaypointRole { start, via, end }

class PlanWaypoint {
  const PlanWaypoint({
    required this.id,
    required this.role,
    required this.lat,
    required this.lng,
    this.label,
    this.placeId,
    this.kind,
  });

  final String id;
  final PlanWaypointRole role;
  final double lat;
  final double lng;
  final String? label;
  final String? placeId;
  final String? kind;

  GeoPoint get point => GeoPoint(lat, lng);

  PlanWaypoint copyWith({
    String? id,
    PlanWaypointRole? role,
    double? lat,
    double? lng,
    String? label,
    String? placeId,
    String? kind,
  }) =>
      PlanWaypoint(
        id: id ?? this.id,
        role: role ?? this.role,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        label: label ?? this.label,
        placeId: placeId ?? this.placeId,
        kind: kind ?? this.kind,
      );
}

/// Immutable A→via→B editor state. Discover still stores start/end/vias;
/// convert at the panel edge so [_calcAb] stays unchanged.
class PlanSession {
  const PlanSession({
    this.start,
    this.end,
    this.vias = const [],
  });

  final PlanWaypoint? start;
  final PlanWaypoint? end;
  final List<PlanWaypoint> vias;

  List<PlanWaypoint> get ordered => [
        if (start != null) start!,
        ...vias,
        if (end != null) end!,
      ];

  GeoPoint? get startPoint => start?.point;
  GeoPoint? get endPoint => end?.point;

  List<LabeledVia> get labeledVias => [
        for (final v in vias)
          LabeledVia(
            lat: v.lat,
            lng: v.lng,
            label: v.label,
            placeId: v.placeId,
            kind: v.kind,
          ),
      ];

  bool get canCompute => start != null && end != null;

  bool isClosedLoop({double toleranceM = 200}) {
    final a = start;
    final b = end;
    if (a == null || b == null) return false;
    return haversineM(a.lat, a.lng, b.lat, b.lng) <= toleranceM;
  }

  factory PlanSession.fromParts({
    GeoPoint? start,
    GeoPoint? end,
    List<LabeledVia> vias = const [],
    String? startLabel,
    String? endLabel,
  }) {
    return PlanSession(
      start: start == null
          ? null
          : PlanWaypoint(
              id: 'start',
              role: PlanWaypointRole.start,
              lat: start.lat,
              lng: start.lng,
              label: startLabel,
            ),
      end: end == null
          ? null
          : PlanWaypoint(
              id: 'end',
              role: PlanWaypointRole.end,
              lat: end.lat,
              lng: end.lng,
              label: endLabel,
            ),
      vias: [
        for (var i = 0; i < vias.length; i++)
          PlanWaypoint(
            id: 'via-$i',
            role: PlanWaypointRole.via,
            lat: vias[i].lat,
            lng: vias[i].lng,
            label: vias[i].label,
            placeId: vias[i].placeId,
            kind: vias[i].kind,
          ),
      ],
    );
  }

  PlanSession swapStartEnd() {
    if (start == null && end == null) return this;
    return PlanSession(
      start: end?.copyWith(id: 'start', role: PlanWaypointRole.start),
      end: start?.copyWith(id: 'end', role: PlanWaypointRole.end),
      vias: vias.reversed.toList(),
    );
  }

  PlanSession closeLoop({String? label}) {
    final a = start;
    if (a == null) return this;
    return PlanSession(
      start: start,
      vias: vias,
      end: PlanWaypoint(
        id: 'end',
        role: PlanWaypointRole.end,
        lat: a.lat,
        lng: a.lng,
        label: label ?? a.label,
      ),
    );
  }

  PlanSession addVia(GeoPoint p, {String? label}) {
    return PlanSession(
      start: start,
      end: end,
      vias: [
        ...vias,
        PlanWaypoint(
          id: 'via-${vias.length}-${p.lat.toStringAsFixed(5)}',
          role: PlanWaypointRole.via,
          lat: p.lat,
          lng: p.lng,
          label: label,
        ),
      ],
    );
  }

  PlanSession removeViaAt(int index) {
    if (index < 0 || index >= vias.length) return this;
    final next = [...vias]..removeAt(index);
    return PlanSession(start: start, end: end, vias: next);
  }

  PlanSession moveVia(int index, int delta) {
    return PlanSession(
      start: start,
      end: end,
      vias: moveLabeledVia(labeledVias, index, delta)
          .asMap()
          .entries
          .map(
            (e) => PlanWaypoint(
              id: 'via-${e.key}',
              role: PlanWaypointRole.via,
              lat: e.value.lat,
              lng: e.value.lng,
              label: e.value.label,
              placeId: e.value.placeId,
              kind: e.value.kind,
            ),
          )
          .toList(),
    );
  }

  PlanSession movePoint(PlanWaypointRole role, GeoPoint p, {int? viaIndex}) {
    switch (role) {
      case PlanWaypointRole.start:
        if (start == null) return this;
        return PlanSession(
          start: start!.copyWith(lat: p.lat, lng: p.lng),
          end: end,
          vias: vias,
        );
      case PlanWaypointRole.end:
        if (end == null) return this;
        return PlanSession(
          start: start,
          end: end!.copyWith(lat: p.lat, lng: p.lng),
          vias: vias,
        );
      case PlanWaypointRole.via:
        final i = viaIndex ?? 0;
        if (i < 0 || i >= vias.length) return this;
        final next = [...vias];
        next[i] = next[i].copyWith(lat: p.lat, lng: p.lng);
        return PlanSession(start: start, end: end, vias: next);
    }
  }

  /// Insert via by along-track order when a line exists.
  PlanSession insertViaAlong(
    GeoPoint p, {
    List<List<double>>? line,
    String? label,
    String? placeId,
    String? kind,
  }) {
    var lat = p.lat;
    var lng = p.lng;
    if (line != null && line.length >= 2) {
      final onto = projectOntoRoute(
        coordinates: line,
        lat: p.lat,
        lng: p.lng,
      );
      if (onto.crossTrackM <= kPlanViaAlongMaxOffM) {
        final pt = pointAlongRoute(line, onto.distanceAlongM);
        lng = pt[0];
        lat = pt[1];
      }
    }
    final via = PlanWaypoint(
      id: 'via-${vias.length}-${lat.toStringAsFixed(5)}',
      role: PlanWaypointRole.via,
      lat: lat,
      lng: lng,
      label: label,
      placeId: placeId,
      kind: kind,
    );
    if (line == null || line.length < 2) {
      return PlanSession(start: start, end: end, vias: [...vias, via]);
    }
    final click = projectOntoRoute(
      coordinates: line,
      lat: lat,
      lng: lng,
    );
    var insertAt = vias.length;
    var before = 0;
    for (final v in vias) {
      final along = projectOntoRoute(
        coordinates: line,
        lat: v.lat,
        lng: v.lng,
      );
      if (along.distanceAlongM < click.distanceAlongM) before += 1;
    }
    insertAt = before;
    final next = [...vias]..insert(insertAt, via);
    return PlanSession(start: start, end: end, vias: next);
  }
}

/// Hit radius for tap-on-line vias (Komoot-style), metres.
const kPlanViaAlongMaxOffM = 90.0;

bool planShapeLineKind(String? kind) {
  return kind == 'active' || kind == 'active-merged' || kind == 'approach';
}

/// Line tap / near-line map tap inserts a via; empty-map tap still replaces dest.
bool planMapTapInsertsViaAlong({
  required bool startSet,
  required bool endSet,
  required bool pickingVia,
  bool pickingStart = false,
  bool pickingEnd = false,
  double? crossTrackM,
  bool lineHit = false,
  double maxOffM = kPlanViaAlongMaxOffM,
}) {
  if (!startSet || !endSet) return false;
  if (pickingStart || pickingEnd) return false;
  if (pickingVia || lineHit) return true;
  if (crossTrackM == null || !crossTrackM.isFinite) return false;
  return crossTrackM <= maxOffM;
}

/// After A+B with a live street line, a tap beside the ribbon pulls the
/// route through that point (Komoot Include / AllTrails continue-tap).
/// Dest stays unless pick-end or [planLongPressSetsDest].
bool planFarTapInsertsVia({
  required bool startSet,
  required bool endSet,
  required bool hasLiveLine,
  required bool pickingStart,
  required bool pickingEnd,
}) {
  if (pickingStart || pickingEnd) return false;
  return startSet && endSet && hasLiveLine;
}

/// Komoot “Set as destination”: long-press / Alt-hold after A+B.
/// Short tap on the line remains via. Explicit via/start pick keeps that pin.
bool planLongPressSetsDest({
  required bool editorActive,
  required bool hasStart,
  required bool hasEnd,
  required bool pickingVia,
  required bool pickingStart,
  required bool tapHitsLine,
}) {
  if (!editorActive || pickingVia || pickingStart) {
    return false;
  }
  tapHitsLine;
  return hasStart && hasEnd;
}

const kPlanUndoMax = 20;

/// Snapshot of A/vias/B for Komoot-style undo.
class PlanUndoFrame {
  const PlanUndoFrame({
    this.start,
    this.end,
    this.vias = const [],
    this.startLabel = '',
    this.endLabel = '',
  });

  final GeoPoint? start;
  final GeoPoint? end;
  final List<LabeledVia> vias;
  final String startLabel;
  final String endLabel;

  factory PlanUndoFrame.fromParts({
    GeoPoint? start,
    GeoPoint? end,
    List<LabeledVia> vias = const [],
    String startLabel = '',
    String endLabel = '',
  }) =>
      PlanUndoFrame(
        start: start,
        end: end,
        vias: List<LabeledVia>.from(vias),
        startLabel: startLabel,
        endLabel: endLabel,
      );

  String get key {
    String pt(GeoPoint? p) =>
        p == null ? '-' : '${p.lat.toStringAsFixed(5)},${p.lng.toStringAsFixed(5)}';
    final via = [
      for (final v in vias)
        '${v.lat.toStringAsFixed(5)},${v.lng.toStringAsFixed(5)}',
    ].join('|');
    return '${pt(start)}>$via>${pt(end)}|$startLabel|$endLabel';
  }
}

List<PlanUndoFrame> pushPlanUndo(
  List<PlanUndoFrame> stack,
  PlanUndoFrame snap, {
  int max = kPlanUndoMax,
}) {
  if (stack.isNotEmpty && stack.last.key == snap.key) return stack;
  final next = [...stack, snap];
  if (next.length <= max) return next;
  return next.sublist(next.length - max);
}

/// Next empty editor slot. After A+B the dest field stays the dest slot;
/// map taps on/near the live line insert vias (Komoot/AllTrails).
PlanWaypointRole nextPlanSlot({
  required bool startSet,
  required bool endSet,
}) {
  if (!startSet) return PlanWaypointRole.start;
  return PlanWaypointRole.end;
}
