import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/presentation/discover/discover_browse_sheet_snaps.dart';

void main() {
  group('DiscoverBrowseSheetSnaps', () {
    test('snap ladder is ordered peek < half < full', () {
      expect(DiscoverBrowseSheetSnaps.peek, lessThan(DiscoverBrowseSheetSnaps.half));
      expect(DiscoverBrowseSheetSnaps.half, lessThan(DiscoverBrowseSheetSnaps.full));
      expect(
        DiscoverBrowseSheetSnaps.sheetSnapSizes,
        [DiscoverBrowseSheetSnaps.half],
      );
      expect(
        DiscoverBrowseSheetSnaps.snapSizes,
        [
          DiscoverBrowseSheetSnaps.peek,
          DiscoverBrowseSheetSnaps.half,
          DiscoverBrowseSheetSnaps.full,
        ],
      );
    });

    test('classifies extents into peek / half / full', () {
      expect(DiscoverBrowseSheetSnaps.isPeek(0.18), isTrue);
      expect(DiscoverBrowseSheetSnaps.isHalf(0.42), isTrue);
      expect(DiscoverBrowseSheetSnaps.isFull(0.80), isTrue);
    });

    test('nearest and list/map targets', () {
      expect(
        DiscoverBrowseSheetSnaps.nearest(0.19),
        DiscoverBrowseSheetSnaps.peek,
      );
      expect(
        DiscoverBrowseSheetSnaps.nearest(0.45),
        DiscoverBrowseSheetSnaps.half,
      );
      expect(
        DiscoverBrowseSheetSnaps.listTarget(DiscoverBrowseSheetSnaps.peek),
        DiscoverBrowseSheetSnaps.half,
      );
      expect(
        DiscoverBrowseSheetSnaps.listTarget(DiscoverBrowseSheetSnaps.half),
        DiscoverBrowseSheetSnaps.full,
      );
      expect(
        DiscoverBrowseSheetSnaps.mapTarget,
        DiscoverBrowseSheetSnaps.peek,
      );
    });
  });

  testWidgets('draggable sheet attaches at half snap', (tester) async {
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
                    initialChildSize: DiscoverBrowseSheetSnaps.half,
                    minChildSize: DiscoverBrowseSheetSnaps.peek,
                    maxChildSize: DiscoverBrowseSheetSnaps.full,
                    snap: true,
                    snapSizes: DiscoverBrowseSheetSnaps.sheetSnapSizes,
                    builder: (context, scroll) {
                      return Material(
                        color: Colors.white,
                        child: ListView.builder(
                          controller: scroll,
                          itemCount: 20,
                          itemBuilder: (_, i) =>
                              ListTile(title: Text('Tour $i')),
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
    expect(
      controller.size,
      closeTo(DiscoverBrowseSheetSnaps.half, 0.02),
    );

    // animateTo needs frames — drive ticker explicitly (no deadlock).
    final peekAnim = controller.animateTo(
      DiscoverBrowseSheetSnaps.peek,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await peekAnim;
    expect(
      controller.size,
      closeTo(DiscoverBrowseSheetSnaps.peek, 0.02),
    );

    final fullAnim = controller.animateTo(
      DiscoverBrowseSheetSnaps.full,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await fullAnim;
    expect(
      controller.size,
      closeTo(DiscoverBrowseSheetSnaps.full, 0.02),
    );
  });
}
