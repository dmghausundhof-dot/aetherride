import 'package:aetherride_mobile/app.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/shop/shop_product.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:aetherride_mobile/providers/shop_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell zeigt Home mit Navigation', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('de', 'DE');
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(() {
      tester.platformDispatcher.clearLocaleTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingDoneProvider.overrideWith((ref) => true),
          bikesProvider.overrideWith(
            (ref) async => [
              const Bike(
                id: 'test',
                name: 'Trail E-MTB',
                category: BikeCategory.emtb,
              ),
            ],
          ),
          shopShelvesProvider.overrideWith(
            (ref) async => const ShopShelves(ok: false),
          ),
        ],
        child: const FlowLineApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Werkstatt'), findsWidgets);
    expect(find.text('Karte'), findsWidgets);
    expect(find.text('Platz'), findsWidgets);
    expect(find.text('Laden'), findsNothing);
    expect(find.text('Der Hof'), findsWidgets);
    expect(find.byKey(const Key('hof-threshold-nav')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Fahren'), findsNothing);
    expect(find.text('Garage'), findsNothing);
    expect(find.byKey(const Key('hof-title')), findsOneWidget);
    expect(find.byKey(const Key('hof-ride-out')), findsOneWidget);
    expect(find.text('Trail E-MTB'), findsWidgets);
    expect(find.textContaining('Tour finden'), findsNothing);
  });

  testWidgets('Zurück vom Laden in der Werkstatt, nicht als Tab',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.localeTestValue = const Locale('de', 'DE');
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(() {
      tester.platformDispatcher.clearLocaleTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingDoneProvider.overrideWith((ref) => true),
          bikesProvider.overrideWith(
            (ref) async => [
              const Bike(
                id: 'test',
                name: 'Trail E-MTB',
                category: BikeCategory.emtb,
              ),
            ],
          ),
          shopShelvesProvider.overrideWith(
            (ref) async => const ShopShelves(ok: false),
          ),
        ],
        child: const FlowLineApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('hof-threshold-nav')),
            matching: find.text('Werkstatt'),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('werkstatt-parts-row')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('werkstatt-parts-row')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('werkstatt-parts-row')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('shop-gateway')), findsOneWidget);
    expect(find.text('Laden'), findsNothing);

    final handled = await tester.binding.handlePopRoute();
    expect(handled, isTrue);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shop-gateway')), findsNothing);
    expect(find.byKey(const Key('werkstatt-parts-row')), findsOneWidget);
    expect(find.byKey(const Key('hof-threshold-nav')), findsOneWidget);
  });
}
