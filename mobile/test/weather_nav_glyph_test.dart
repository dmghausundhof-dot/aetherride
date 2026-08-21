import 'package:aetherride_mobile/presentation/shared/nav_turn_glyph.dart';
import 'package:aetherride_mobile/presentation/shared/weather_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('weather and nav glyph asset paths', () {
    expect(WeatherGlyph.assetPath(), 'assets/weather/dry.svg');
    expect(
      WeatherGlyph.assetPath(trailHint: 'wet_likely'),
      'assets/weather/wet.svg',
    );
    expect(
      WeatherGlyph.assetPath(trailHint: 'damp_possible'),
      'assets/weather/damp.svg',
    );
    expect(WeatherGlyph.assetPath(offline: true), 'assets/weather/offline.svg');
    expect(navTurnAssetPath('turn_left'), 'assets/nav/turn-left.svg');
    expect(navTurnAssetPath('flag'), 'assets/nav/arrive.svg');
    expect(navTurnAssetPath('u_turn_left'), 'assets/nav/u-turn.svg');
    expect(navTurnAssetPath('navigation'), isNull);
  });

  test('nav glyphs match FlowLine muted+orange strokes', () async {
    final svg = await rootBundle.loadString('assets/nav/turn-left.svg');
    expect(svg, contains('#9CA3AF'));
    expect(svg, contains('#FF6A00'));
    expect(svg, contains('stroke-width="1.8"'));
    expect(svg.contains('#1A120C'), isFalse);
  });

  testWidgets('WeatherGlyph and NavTurnGlyph load SVGs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              WeatherGlyph('dry_likely', size: 18),
              NavTurnGlyph('turn_left', size: 24),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(WeatherGlyph), findsOneWidget);
    expect(find.byType(NavTurnGlyph), findsOneWidget);
  });
}
