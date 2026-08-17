import 'package:aetherride_mobile/presentation/shared/hof_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HofSplash zeigt die offizielle Boot-Animation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HofSplash()));
    expect(find.byType(HofSplash), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HofSplash), findsOneWidget);

    await tester.pump(HofSplash.motion);
    expect(find.byType(HofSplash), findsOneWidget);
  });
}
