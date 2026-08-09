import 'package:aetherride_mobile/app.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell zeigt Home mit Navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bikesProvider.overrideWith(
            (ref) async => [
              const Bike(
                id: 'test',
                name: 'Trail E-MTB',
                category: BikeCategory.emtb,
              ),
            ],
          ),
        ],
        child: const AetherRideApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Garage'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.textContaining('Wetter'), findsWidgets);
    expect(find.text('Trail E-MTB'), findsWidgets);
  });
}
