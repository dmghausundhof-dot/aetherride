import 'package:aetherride_mobile/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell zeigt AetherRide auf Home', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AetherRideApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('AetherRide'), findsWidgets);
    expect(find.text('Garage'), findsWidgets);
  });
}
