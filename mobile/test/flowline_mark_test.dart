import 'package:aetherride_mobile/core/theme/flowline_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlowLineMark lädt das offizielle Mark-SVG', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: FlowLineMark(size: 32, onDark: true)),
        ),
      ),
    );
    expect(find.byType(FlowLineMark), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('FlowLineWordmark zeigt Mark und FlowLine', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: FlowLineWordmark())),
      ),
    );
    expect(find.byType(FlowLineMark), findsOneWidget);
    expect(find.byType(FlowLineWordmark), findsOneWidget);
    expect(find.textContaining('Flow'), findsWidgets);
  });
}
