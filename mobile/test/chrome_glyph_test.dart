import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/presentation/shared/chrome_glyph.dart';

void main() {
  testWidgets('chrome glyphs load the FlowLine assets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ChromeGlyph('hof', size: 22),
              ChromeGlyph('karte', size: 14, color: Color(0xFF9CA3AF)),
              ChromeGlyph('search'),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(ChromeGlyph), findsNWidgets(3));
    expect(find.byType(SvgPicture), findsNWidgets(3));
  });

  test('asset aliases stay on existing packs', () {
    expect(ChromeGlyph.assetPath('platz'), 'assets/tours/glyph-mappe.svg');
    expect(ChromeGlyph.assetPath('offline'), 'assets/weather/offline.svg');
    expect(ChromeGlyph.assetPath('photo'), 'assets/garage/glyph-photo.svg');
    expect(ChromeGlyph.assetPath('hof'), 'assets/chrome/glyph-hof.svg');
    expect(ChromeGlyph.assetPath('check'), 'assets/garage/glyph-ready.svg');
    expect(ChromeGlyph.assetPath('watch'), 'assets/chrome/glyph-watch.svg');
    expect(ChromeGlyph.assetPath('lang'), 'assets/chrome/glyph-lang.svg');
    expect(ChromeGlyph.assetPath('cloud'), 'assets/chrome/glyph-cloud.svg');
    expect(ChromeGlyph.assetPath('enter'), 'assets/chrome/glyph-enter.svg');
    expect(ChromeGlyph.assetPath('loop'), 'assets/tours/glyph-loop.svg');
    expect(ChromeGlyph.assetPath('copy'), 'assets/chrome/glyph-copy.svg');
  });
}
