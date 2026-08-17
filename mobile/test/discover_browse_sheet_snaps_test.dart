import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/presentation/discover/discover_browse_sheet_snaps.dart';

void main() {
  group('DiscoverBrowseSheetSnaps', () {
    test('idle sheet can close; selection cannot go below peek', () {
      expect(
        DiscoverBrowseSheetSnaps.closed,
        lessThan(DiscoverBrowseSheetSnaps.peek),
      );
      expect(
        DiscoverBrowseSheetSnaps.peek,
        lessThan(DiscoverBrowseSheetSnaps.half),
      );
      expect(
        DiscoverBrowseSheetSnaps.half,
        lessThan(DiscoverBrowseSheetSnaps.full),
      );
      expect(
        DiscoverBrowseSheetSnaps.minSize(hasSelection: false),
        DiscoverBrowseSheetSnaps.closed,
      );
      expect(
        DiscoverBrowseSheetSnaps.minSize(hasSelection: true),
        DiscoverBrowseSheetSnaps.peek,
      );
      expect(
        DiscoverBrowseSheetSnaps.sheetSnapSizes(hasSelection: false),
        [DiscoverBrowseSheetSnaps.peek, DiscoverBrowseSheetSnaps.half],
      );
      expect(
        DiscoverBrowseSheetSnaps.sheetSnapSizes(hasSelection: true),
        [DiscoverBrowseSheetSnaps.half],
      );
      expect(
        DiscoverBrowseSheetSnaps.snapSizes(hasSelection: false),
        [
          DiscoverBrowseSheetSnaps.closed,
          DiscoverBrowseSheetSnaps.peek,
          DiscoverBrowseSheetSnaps.half,
          DiscoverBrowseSheetSnaps.full,
        ],
      );
    });

    test('classifies extents into closed / peek / half / full', () {
      expect(DiscoverBrowseSheetSnaps.isClosed(0.045), isTrue);
      expect(DiscoverBrowseSheetSnaps.isPeek(0.18), isFalse);
      expect(DiscoverBrowseSheetSnaps.isPeek(0.34), isTrue);
      expect(DiscoverBrowseSheetSnaps.isHalf(0.42), isTrue);
      expect(DiscoverBrowseSheetSnaps.isFull(0.80), isTrue);
    });

    test('nearest and list/map targets', () {
      expect(
        DiscoverBrowseSheetSnaps.nearest(0.09, hasSelection: false),
        DiscoverBrowseSheetSnaps.closed,
      );
      expect(
        DiscoverBrowseSheetSnaps.nearest(0.19, hasSelection: true),
        DiscoverBrowseSheetSnaps.peek,
      );
      expect(
        DiscoverBrowseSheetSnaps.nearest(0.45, hasSelection: false),
        DiscoverBrowseSheetSnaps.half,
      );
      expect(
        DiscoverBrowseSheetSnaps.listTarget(DiscoverBrowseSheetSnaps.closed),
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
        DiscoverBrowseSheetSnaps.mapTarget(hasSelection: false),
        DiscoverBrowseSheetSnaps.closed,
      );
      expect(
        DiscoverBrowseSheetSnaps.mapTarget(hasSelection: true),
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
                    minChildSize: DiscoverBrowseSheetSnaps.closed,
                    maxChildSize: DiscoverBrowseSheetSnaps.full,
                    snap: true,
                    snapSizes: DiscoverBrowseSheetSnaps.sheetSnapSizes(
                      hasSelection: false,
                    ),
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

    final closedAnim = controller.animateTo(
      DiscoverBrowseSheetSnaps.closed,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await closedAnim;
    expect(
      controller.size,
      closeTo(DiscoverBrowseSheetSnaps.closed, 0.02),
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
