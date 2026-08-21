import '../community/labeled_via.dart';
import '../../data/routing/routing_client.dart';

/// One plan-editor snapshot (Komoot Zurück / AllTrails undo).
class PlanEditSnap {
  const PlanEditSnap({
    required this.start,
    required this.end,
    required this.vias,
    required this.startLabel,
    required this.endLabel,
  });

  final GeoPoint? start;
  final GeoPoint? end;
  final List<LabeledVia> vias;
  final String startLabel;
  final String endLabel;

  PlanEditSnap copy() => PlanEditSnap(
        start: start,
        end: end,
        vias: List<LabeledVia>.from(vias),
        startLabel: startLabel,
        endLabel: endLabel,
      );
}

class PlanHistory {
  PlanHistory({this.max = 24});

  final int max;
  final List<PlanEditSnap> past = [];
  final List<PlanEditSnap> future = [];

  bool get canUndo => past.isNotEmpty;
  bool get canRedo => future.isNotEmpty;

  void push(PlanEditSnap current) {
    past.add(current.copy());
    if (past.length > max) past.removeAt(0);
    future.clear();
  }

  PlanEditSnap? undo(PlanEditSnap current) {
    if (past.isEmpty) return null;
    future.add(current.copy());
    return past.removeLast();
  }

  PlanEditSnap? redo(PlanEditSnap current) {
    if (future.isEmpty) return null;
    past.add(current.copy());
    return future.removeLast();
  }

  void clear() {
    past.clear();
    future.clear();
  }
}
