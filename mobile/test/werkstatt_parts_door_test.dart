import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/shop/shop_product.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/garage/werkstatt_parts_door.dart';
import 'package:aetherride_mobile/presentation/shop/shop_screen.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:aetherride_mobile/providers/shop_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _luna = Bike(
  id: 'g1',
  name: 'Luna',
  category: BikeCategory.gravel,
  isActive: true,
  wheelSize: WheelSize.c700,
);

Widget _doorApp({required Widget door}) {
  return ProviderScope(
    overrides: [
      onboardingDoneProvider.overrideWith((ref) => true),
      bikesProvider.overrideWith((ref) async => const [_luna]),
      shopShelvesProvider.overrideWith(
        (ref) async => const ShopShelves(ok: false),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('de', 'DE'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: door,
        bottomNavigationBar: const SizedBox(
          key: Key('hof-threshold-nav'),
          height: 56,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Teile-Tür bleibt zu, solange der Laden pausiert', (tester) async {
    await tester.pumpWidget(
      _doorApp(
        door: const WerkstattPartsDoor(
          bikeId: 'g1',
          bikeName: 'Luna',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('werkstatt-parts-row')), findsNothing);
    expect(find.byKey(const Key('werkstatt-parts-lookup')), findsNothing);
    expect(find.byKey(const Key('shop-gateway')), findsNothing);
  });

  testWidgets('openShopGateway pusht den Laden nicht, solange er pausiert',
      (tester) async {
    await tester.pumpWidget(
      _doorApp(
        door: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => openShopGateway(context, ref, bikeId: 'g1'),
            child: const Text('open-shop'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open-shop'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shop-gateway')), findsNothing);
  });
}
