import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/shop/shop_screen.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _shopApp({required List<Bike> bikes}) {
  return ProviderScope(
    overrides: [
      onboardingDoneProvider.overrideWith((ref) => true),
      bikesProvider.overrideWith((ref) async => bikes),
    ],
    child: MaterialApp(
      locale: const Locale('de', 'DE'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ShopScreen(),
    ),
  );
}

void main() {
  testWidgets('Shop-Tab ist Gateway, kein Produktgrid', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [
          Bike(
            id: 'g1',
            name: 'Luna',
            category: BikeCategory.gravel,
            isActive: true,
            wheelSize: WheelSize.c700,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-gateway')), findsOneWidget);
    expect(find.text('Der Laden'), findsOneWidget);
    expect(find.text('Zum Shop'), findsOneWidget);
    expect(find.text('Für dein Rad'), findsWidgets);
    expect(find.text('Merchandise'), findsWidgets);
    expect(find.textContaining('Kasse dort'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('Ohne Rad: ehrlicher Leerstand, Merch bleibt', (tester) async {
    await tester.pumpWidget(_shopApp(bikes: const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Stell ein Rad'), findsOneWidget);
    expect(find.text('Merchandise'), findsWidgets);
    expect(find.text('Rad abstellen'), findsOneWidget);
  });
}
