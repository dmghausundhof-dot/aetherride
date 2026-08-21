import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/community/labeled_via.dart';
import 'package:aetherride_mobile/domain/routing/plan_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('undo then redo restores the dest pin', () {
    final h = PlanHistory();
    const a = GeoPoint(49.4, 8.67);
    const b = GeoPoint(49.41, 8.71);
    h.push(const PlanEditSnap(
      start: a,
      end: null,
      vias: [],
      startLabel: 'A',
      endLabel: '',
    ));
    final current = const PlanEditSnap(
      start: a,
      end: b,
      vias: [],
      startLabel: 'A',
      endLabel: 'B',
    );
    final undone = h.undo(current);
    expect(undone, isNotNull);
    expect(undone!.end, isNull);
    expect(h.canRedo, isTrue);
    final redone = h.redo(undone);
    expect(redone!.end, b);
    expect(h.canUndo, isTrue);
  });

  test('new edit clears redo', () {
    final h = PlanHistory();
    const a = GeoPoint(49.4, 8.67);
    h.push(PlanEditSnap(
      start: a,
      end: null,
      vias: const [],
      startLabel: 'A',
      endLabel: '',
    ));
    h.undo(PlanEditSnap(
      start: a,
      end: const GeoPoint(49.41, 8.71),
      vias: const [],
      startLabel: 'A',
      endLabel: 'B',
    ));
    expect(h.canRedo, isTrue);
    h.push(PlanEditSnap(
      start: a,
      end: const GeoPoint(49.42, 8.72),
      vias: const [],
      startLabel: 'A',
      endLabel: 'C',
    ));
    expect(h.canRedo, isFalse);
  });
}
