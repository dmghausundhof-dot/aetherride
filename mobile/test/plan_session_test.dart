import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/community/labeled_via.dart';
import 'package:aetherride_mobile/domain/routing/plan_session.dart';
import 'package:aetherride_mobile/domain/routing/tour_nav_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const start = GeoPoint(49.4, 8.67);
  const end = GeoPoint(49.41, 8.71);
  const mid = GeoPoint(49.405, 8.69);

  group('PlanSession', () {
    test('swap reverses start/end and via order', () {
      final s = PlanSession.fromParts(
        start: start,
        end: end,
        vias: const [
          LabeledVia(lat: 49.405, lng: 8.69, label: 'Café'),
          LabeledVia(lat: 49.408, lng: 8.70, label: 'Quelle'),
        ],
        startLabel: 'A',
        endLabel: 'B',
      ).swapStartEnd();
      expect(s.start?.lat, end.lat);
      expect(s.end?.lat, start.lat);
      expect(s.vias.map((e) => e.label).toList(), ['Quelle', 'Café']);
    });

    test('closeLoop copies start onto end', () {
      final s = PlanSession.fromParts(start: start, end: end).closeLoop(
        label: 'Start',
      );
      expect(s.end?.lat, start.lat);
      expect(s.end?.lng, start.lng);
      expect(s.isClosedLoop(), isTrue);
    });

    test('insertViaAlong orders by distance along the line', () {
      final line = <List<double>>[
        [8.67, 49.400],
        [8.69, 49.405],
        [8.71, 49.410],
      ];
      final s = PlanSession.fromParts(start: start, end: end).insertViaAlong(
        mid,
        line: line,
        label: 'Mitte',
      );
      expect(s.vias, hasLength(1));
      expect(s.vias.first.label, 'Mitte');
    });

    test('insertViaAlong snaps a near-line tap onto the polyline', () {
      final line = <List<double>>[
        [8.67, 49.400],
        [8.69, 49.405],
        [8.71, 49.410],
      ];
      final off = GeoPoint(49.4052, 8.6904);
      final s = PlanSession.fromParts(start: start, end: end).insertViaAlong(
        off,
        line: line,
        label: 'Snap',
      );
      expect(s.vias, hasLength(1));
      expect((s.vias.first.lng - 8.69).abs(), lessThan(0.001));
      expect((s.vias.first.lat - 49.405).abs(), lessThan(0.001));
    });

    test('insertViaAlong keeps placeId on existing vias', () {
      final line = <List<double>>[
        [8.67, 49.400],
        [8.69, 49.405],
        [8.71, 49.410],
      ];
      final s = PlanSession.fromParts(
        start: start,
        end: end,
        vias: const [
          LabeledVia(lat: 49.408, lng: 8.70, label: 'Café', placeId: 'osm-1'),
        ],
      ).insertViaAlong(mid, line: line, label: 'Mitte');
      expect(s.vias, hasLength(2));
      expect(s.labeledVias.any((v) => v.placeId == 'osm-1'), isTrue);
      expect(s.labeledVias.first.label, 'Mitte');
    });

    test('planMapTapInsertsViaAlong is near-line or explicit via', () {
      expect(
        planMapTapInsertsViaAlong(
          startSet: true,
          endSet: true,
          pickingVia: false,
          crossTrackM: 40,
        ),
        isTrue,
      );
      expect(
        planMapTapInsertsViaAlong(
          startSet: true,
          endSet: true,
          pickingVia: false,
          crossTrackM: 400,
        ),
        isFalse,
      );
      expect(
        planMapTapInsertsViaAlong(
          startSet: true,
          endSet: true,
          pickingVia: false,
          pickingEnd: true,
          crossTrackM: 10,
        ),
        isFalse,
      );
      expect(
        planMapTapInsertsViaAlong(
          startSet: true,
          endSet: true,
          pickingVia: false,
          lineHit: true,
          crossTrackM: 400,
        ),
        isTrue,
      );
      expect(planShapeLineKind('active'), isTrue);
      expect(planShapeLineKind('quick'), isFalse);
    });

    test('far tap with a live line inserts a via; long-press sets dest', () {
      expect(
        planFarTapInsertsVia(
          startSet: true,
          endSet: true,
          hasLiveLine: true,
          pickingStart: false,
          pickingEnd: false,
        ),
        isTrue,
      );
      expect(
        planFarTapInsertsVia(
          startSet: true,
          endSet: true,
          hasLiveLine: true,
          pickingStart: false,
          pickingEnd: true,
        ),
        isFalse,
      );
      expect(
        planLongPressSetsDest(
          editorActive: true,
          hasStart: true,
          hasEnd: true,
          pickingVia: false,
          pickingStart: false,
          tapHitsLine: false,
        ),
        isTrue,
      );
      expect(
        planLongPressSetsDest(
          editorActive: true,
          hasStart: true,
          hasEnd: true,
          pickingVia: false,
          pickingStart: false,
          tapHitsLine: true,
        ),
        isTrue,
      );
    });

    test('undo stack skips identical snaps and caps length', () {
      final a = PlanUndoFrame.fromParts(
        start: start,
        end: end,
        startLabel: 'A',
        endLabel: 'B',
      );
      final b = PlanUndoFrame.fromParts(
        start: start,
        end: mid,
        startLabel: 'A',
        endLabel: 'C',
      );
      var stack = pushPlanUndo(const [], a);
      stack = pushPlanUndo(stack, a);
      expect(stack, hasLength(1));
      stack = pushPlanUndo(stack, b);
      expect(stack, hasLength(2));
      expect(stack.last.end?.lat, mid.lat);
    });

    test('moveVia uses labeled-via order', () {
      final s = PlanSession.fromParts(
        start: start,
        end: end,
        vias: const [
          LabeledVia(lat: 49.405, lng: 8.69, label: 'A'),
          LabeledVia(lat: 49.408, lng: 8.70, label: 'B'),
        ],
      ).moveVia(1, -1);
      expect(s.vias.map((e) => e.label).toList(), ['B', 'A']);
    });
  });

  test('nextPlanSlot fills start then end then via', () {
    expect(
        nextPlanSlot(startSet: false, endSet: false), PlanWaypointRole.start);
    expect(nextPlanSlot(startSet: true, endSet: false), PlanWaypointRole.end);
    expect(nextPlanSlot(startSet: true, endSet: true), PlanWaypointRole.via);
  });

  test('geocode/recents slot never clobbers start once A is set', () {
    expect(
      planGeocodeHitSlot(
        hasStart: true,
        hasEnd: false,
        pickingVia: false,
        pickingEnd: false,
        pickingStart: false,
        startFieldFocused: false,
        endFieldFocused: false,
      ),
      PlanWaypointRole.end,
    );
    expect(
      planGeocodeHitSlot(
        hasStart: true,
        hasEnd: true,
        pickingVia: false,
        pickingEnd: false,
        pickingStart: false,
        startFieldFocused: false,
        endFieldFocused: false,
      ),
      PlanWaypointRole.via,
    );
    expect(
      planGeocodeHitSlot(
        hasStart: true,
        hasEnd: true,
        pickingVia: true,
        pickingEnd: false,
        pickingStart: false,
        startFieldFocused: false,
        endFieldFocused: false,
      ),
      PlanWaypointRole.via,
    );
    expect(
      planGeocodeHitSlot(
        hasStart: true,
        hasEnd: false,
        pickingVia: false,
        pickingEnd: false,
        pickingStart: false,
        startFieldFocused: true,
        endFieldFocused: false,
      ),
      PlanWaypointRole.start,
    );
  });

  test('plan editor tap may place pins without pick mode', () {
    final t0 = DateTime.utc(2026, 8, 19, 12);
    final quiet = t0.subtract(const Duration(seconds: 2));
    expect(
      mapPlanEditorTapPlacesPin(
        editorActive: true,
        addressFieldFocused: false,
        cameraMoving: false,
        cameraMovedAt: quiet,
        lastPinAt: quiet,
        now: t0,
      ),
      isTrue,
    );
    expect(
      mapPlanEditorTapPlacesPin(
        editorActive: false,
        addressFieldFocused: false,
        cameraMoving: false,
        cameraMovedAt: quiet,
        lastPinAt: quiet,
        now: t0,
      ),
      isFalse,
    );
    expect(
      mapPlanEditorTapPlacesPin(
        editorActive: true,
        addressFieldFocused: true,
        cameraMoving: false,
        cameraMovedAt: quiet,
        lastPinAt: t0,
        now: t0,
        placingVia: true,
      ),
      isTrue,
    );
  });
}
