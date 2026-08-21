import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/core/theme/nav_hud_tokens.dart';
import 'package:aetherride_mobile/domain/active_route.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_hud_layer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HUD-Reiter: Karte / Daten / Fahrwerk, Karte aktiv', (tester) async {
    RideLiveLayer? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RideHudLayerBar(
            selected: RideLiveLayer.map,
            mapLabel: 'Karte',
            dataLabel: 'Daten',
            chassisLabel: 'Fahrwerk',
            onSelected: (v) => picked = v,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ride-hud-layer-bar')), findsOneWidget);
    expect(find.text('Karte'), findsOneWidget);
    expect(find.text('Daten'), findsOneWidget);
    expect(find.text('Fahrwerk'), findsOneWidget);
    expect(find.byType(SegmentedButton<RideLiveLayer>), findsNothing);

    final label = tester.widget<Text>(find.text('Karte'));
    expect(label.style?.fontSize, NavHudTokens.layerLabelDp);
    expect(label.style?.fontWeight, NavHudTokens.layerLabelWeight);
    expect(label.style?.color, AppColors.accent);

    await tester.tap(find.byKey(const Key('ride-hud-layer-data')));
    expect(picked, RideLiveLayer.data);
  });

  testWidgets('HUD zu ist sichtbar und groß', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RideHudLayerBar(
            selected: RideLiveLayer.map,
            mapLabel: 'Karte',
            dataLabel: 'Daten',
            chassisLabel: 'Fahrwerk',
            onSelected: (_) {},
            onClose: () => closed = true,
            closeLabel: 'HUD zu',
          ),
        ),
      ),
    );
    final close = find.byKey(const Key('ride-hud-close'));
    expect(close, findsOneWidget);
    expect(find.text('HUD zu'), findsOneWidget);
    expect(tester.getSize(close).height, greaterThanOrEqualTo(NavHudTokens.layerBarMinHeightDp));
    await tester.tap(close);
    expect(closed, isTrue);
  });

  testWidgets('Daten/Fahrwerk sitzen in derselben Insel unter den Reitern',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RideHudLayerBar(
            selected: RideLiveLayer.suspension,
            mapLabel: 'Karte',
            dataLabel: 'Daten',
            chassisLabel: 'Fahrwerk',
            onSelected: (_) {},
            body: const Text('Neigung 0°'),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('ride-hud-layer-bar')), findsOneWidget);
    expect(find.text('Fahrwerk'), findsOneWidget);
    expect(find.text('Neigung 0°'), findsOneWidget);
    final bar = tester.getRect(find.byKey(const Key('ride-hud-layer-bar')));
    final body = tester.getRect(find.text('Neigung 0°'));
    expect(body.top, greaterThan(bar.top));
    expect(body.bottom, lessThanOrEqualTo(bar.bottom + 0.5));
  });

  testWidgets('ohne Fahrwerk nur zwei Reiter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RideHudLayerBar(
            selected: RideLiveLayer.data,
            mapLabel: 'Karte',
            dataLabel: 'Daten',
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('ride-hud-layer-suspension')), findsNothing);
    expect(find.text('Fahrwerk'), findsNothing);
    final data = tester.widget<Text>(find.text('Daten'));
    expect(data.style?.color, AppColors.accent);
  });
}
