import 'package:aetherride_mobile/presentation/shared/hof_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HofSplash zeigt die offizielle Boot-Animation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HofSplash()));
    expect(find.byType(HofSplash), findsOneWidget);
    expect(find.byType(ColoredBox), findsWidgets);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump();
    expect(find.byType(HofSplash), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.byType(HofSplash), findsOneWidget);
  });
}
