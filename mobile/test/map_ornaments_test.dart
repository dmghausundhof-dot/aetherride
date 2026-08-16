import 'dart:math' show Point;

import 'package:aetherride_mobile/presentation/shared/map_ornaments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  setUp(() {
    _CompassProbe.last = null;
    _LocateProbe.last = null;
  });

  testWidgets('Kompass sitzt unter Statusleiste, nicht in der Batteriezeile',
      (tester) async {
    const statusTop = 52.0;
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: statusTop)),
        child: _CompassProbe(),
      ),
    );
    final p = _CompassProbe.last!;
    expect(p.x, MapOrnaments.sideMin);
    expect(p.y, statusTop + MapOrnaments.gapBelowStatus);
    expect(
      p.y,
      greaterThan(statusTop),
      reason: 'y muss unter padding.top liegen (S25-Batterie)',
    );
  });

  testWidgets('Discover-Kompass liegt unter Suchleiste, Location darunter',
      (tester) async {
    const statusTop = 52.0;
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: statusTop)),
        child: _CompassProbe(
          extraBelowSafe: MapOrnaments.discoverHeaderClearance,
        ),
      ),
    );
    expect(
      _CompassProbe.last!.y,
      statusTop +
          MapOrnaments.gapBelowStatus +
          MapOrnaments.discoverHeaderClearance,
    );
    expect(_LocateProbe.last, isNull);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: statusTop)),
        child: _LocateProbe(
          extraBelowSafe: MapOrnaments.discoverHeaderClearance,
        ),
      ),
    );
    expect(
      _LocateProbe.last!.y,
      statusTop +
          MapOrnaments.gapBelowStatus +
          MapOrnaments.discoverHeaderClearance +
          MapOrnaments.compassSlot +
          MapOrnaments.controlGap,
    );
    expect(_LocateProbe.last!.x, _CompassProbe.last!.x);
    expect(
      _LocateProbe.last!.y - _CompassProbe.last!.y,
      greaterThanOrEqualTo(MapOrnaments.compassSlot),
    );
  });

  testWidgets('rechtes Cutout vergrößert den Seitenabstand', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.only(top: 24, right: 44),
        ),
        child: _CompassProbe(),
      ),
    );
    expect(_CompassProbe.last!.x, 44);
  });

  test('Position bleibt oben rechts (Batterie ist dort, Inset statt Seite)',
      () {
    expect(
      MapOrnaments.compassPosition,
      CompassViewPosition.topRight,
    );
  });
}

class _CompassProbe extends StatelessWidget {
  const _CompassProbe({this.extraBelowSafe = 0});

  final double extraBelowSafe;
  static Point? last;

  @override
  Widget build(BuildContext context) {
    last = MapOrnaments.compassMargins(
      context,
      extraBelowSafe: extraBelowSafe,
    );
    return const SizedBox.shrink();
  }
}

class _LocateProbe extends StatelessWidget {
  const _LocateProbe({this.extraBelowSafe = 0});

  final double extraBelowSafe;
  static Point? last;

  @override
  Widget build(BuildContext context) {
    last = MapOrnaments.locateMargins(
      context,
      extraBelowSafe: extraBelowSafe,
    );
    return const SizedBox.shrink();
  }
}
