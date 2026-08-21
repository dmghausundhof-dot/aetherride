import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/presentation/discover/plan_sheet_snaps.dart';

void main() {
  group('PlanSheetSnaps', () {
    test('peek is 80% map, full is 20% map free', () {
      expect(PlanSheetSnaps.peek, 0.20);
      expect(PlanSheetSnaps.full, 0.80);
      expect(PlanSheetSnaps.peek, lessThan(PlanSheetSnaps.form));
      expect(PlanSheetSnaps.form, lessThan(PlanSheetSnaps.full));
      expect(PlanSheetSnaps.minSize, PlanSheetSnaps.peek);
      expect(PlanSheetSnaps.maxSize, PlanSheetSnaps.full);
      expect(PlanSheetSnaps.sheetSnapSizes, [PlanSheetSnaps.form]);
    });

    test('classifies peek / form / full', () {
      expect(PlanSheetSnaps.isPeek(0.20), isTrue);
      expect(PlanSheetSnaps.isPeek(0.34), isTrue);
      expect(PlanSheetSnaps.isForm(0.50), isTrue);
      expect(PlanSheetSnaps.isFull(0.80), isTrue);
      expect(PlanSheetSnaps.isFull(0.66), isTrue);
    });

    test('handle tap cycles peek → form → full → peek', () {
      expect(
        PlanSheetSnaps.handleTapTarget(PlanSheetSnaps.peek),
        PlanSheetSnaps.form,
      );
      expect(
        PlanSheetSnaps.handleTapTarget(PlanSheetSnaps.form),
        PlanSheetSnaps.full,
      );
      expect(
        PlanSheetSnaps.handleTapTarget(PlanSheetSnaps.full),
        PlanSheetSnaps.peek,
      );
    });

    test('open: adapting peeks so the line stays on the map', () {
      expect(PlanSheetSnaps.openTarget(adapting: true), PlanSheetSnaps.peek);
      expect(PlanSheetSnaps.openTarget(adapting: false), PlanSheetSnaps.form);
    });

    test('nearest snaps to the three stops', () {
      expect(PlanSheetSnaps.nearest(0.22), PlanSheetSnaps.peek);
      expect(PlanSheetSnaps.nearest(0.48), PlanSheetSnaps.form);
      expect(PlanSheetSnaps.nearest(0.79), PlanSheetSnaps.full);
    });
  });

  testWidgets('plan sheet attaches at form and animates to peek',
      (tester) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 800,
            width: 390,
            child: Stack(
              children: [
                const ColoredBox(color: Color(0xFF88AA99)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: DraggableScrollableSheet(
                    expand: false,
                    controller: controller,
                    initialChildSize: PlanSheetSnaps.form,
                    minChildSize: PlanSheetSnaps.peek,
                    maxChildSize: PlanSheetSnaps.full,
                    snap: true,
                    snapSizes: PlanSheetSnaps.sheetSnapSizes,
                    builder: (context, scroll) {
                      return Material(
                        color: Colors.white,
                        child: ListView(
                          controller: scroll,
                          children: const [
                            ListTile(title: Text('Planen')),
                            ListTile(title: Text('Wohin')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controller.isAttached, isTrue);
    expect(controller.size, closeTo(PlanSheetSnaps.form, 0.02));

    final peek = controller.animateTo(
      PlanSheetSnaps.peek,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await peek;
    expect(controller.size, closeTo(PlanSheetSnaps.peek, 0.02));
  });
}
