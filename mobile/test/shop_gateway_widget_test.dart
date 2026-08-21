import 'package:aetherride_mobile/core/config.dart';
import 'package:aetherride_mobile/core/shopify_storefront.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/shop/shop_product.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/shop/shop_screen.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:aetherride_mobile/providers/shop_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _shopApp({
  required List<Bike> bikes,
  ShopShelves shelves = const ShopShelves(ok: false),
  List<Override> extra = const [],
  Locale locale = const Locale('de', 'DE'),
}) {
  return ProviderScope(
    overrides: [
      onboardingDoneProvider.overrideWith((ref) => true),
      bikesProvider.overrideWith((ref) async => bikes),
      shopShelvesProvider.overrideWith((ref) async => shelves),
      ...extra,
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ShopScreen(),
    ),
  );
}

const _luna = Bike(
  id: 'g1',
  name: 'Luna',
  category: BikeCategory.gravel,
  isActive: true,
  wheelSize: WheelSize.c700,
);

const _trail = Bike(
  id: 'm1',
  name: 'Trail',
  category: BikeCategory.mtbEnduro,
  wheelSize: WheelSize.w29,
);

const _kette = ShopProduct(
  id: 'p1',
  handle: 'sram-kette',
  name: 'SRAM Kette PC-1110',
  manufacturer: 'SRAM',
  priceEur: 16.99,
  currencyCode: 'EUR',
  slotKey: 'chain',
  tags: ['category:gravel', 'slot:chain'],
);

const _assegai = ShopProduct(
  id: 'p-mtb',
  handle: 'maxxis-assegai',
  name: 'Maxxis Assegai',
  manufacturer: 'Maxxis',
  priceEur: 89,
  currencyCode: 'EUR',
  slotKey: 'tire',
  tags: ['category:mtb', 'slot:tire', 'wheel:29'],
);

void main() {
  test('Laden-Tür und Shopify-Kasse sind default aus', () {
    expect(AppConfig.shopEnabled, isFalse);
    expect(AppConfig.shopifyCommerceEnabled, isFalse);
    expect(ShopifyStorefront.isConfigured, isFalse);
  });

  testWidgets('Shop-Gateway, kein Produktgrid', (tester) async {
    await tester.pumpWidget(_shopApp(bikes: const [_luna]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-gateway')), findsOneWidget);
    expect(find.byKey(const Key('shop-appbar-title')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('shop-appbar-title'))).data,
      'Der Laden',
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Teile'),
      ),
      findsNothing,
    );
    expect(find.text('Der Laden'), findsWidgets);
    expect(find.text('Zum Shop'), findsNothing);
    expect(find.text('Für dein Rad'), findsWidgets);
    expect(find.text('Cycling Parts'), findsNothing);
    expect(find.byKey(const Key('shop-merch')), findsNothing);
    expect(find.textContaining('beim Händler'), findsOneWidget);
    expect(find.byKey(const Key('shop-catalog-failed')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('AppBar heißt wie die Tür, nicht das Sortiment', (tester) async {
    const cases = [
      (Locale('de', 'DE'), 'Der Laden', 'Teile'),
      (Locale('en'), 'The shop', 'Parts'),
      (Locale('fr'), 'Le magasin', 'Pièces'),
      (Locale('it'), 'Il negozio', 'Pezzi'),
    ];
    for (final (locale, door, parts) in cases) {
      await tester.pumpWidget(
        _shopApp(bikes: const [_luna], locale: locale),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.widget<Text>(find.byKey(const Key('shop-appbar-title'))).data,
        door,
        reason: locale.languageCode,
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(parts),
        ),
        findsNothing,
        reason: locale.languageCode,
      );
    }
  });

  testWidgets('Ohne Rad: ehrlicher Leerstand, Merch bleibt', (tester) async {
    await tester.pumpWidget(_shopApp(bikes: const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Lege ein Rad'), findsOneWidget);
    expect(find.byKey(const Key('shop-merch')), findsNothing);
    expect(find.text('Rad anlegen'), findsOneWidget);
  });

  testWidgets('Storefront-Regal zeigt Preis, kein In-App-Warenkorb',
      (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(ok: true, parts: [_kette]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('SRAM Kette PC-1110'), findsOneWidget);
    expect(find.textContaining('€'), findsWidgets);
    expect(find.text('Details'), findsWidgets);
    expect(find.textContaining('passt zu Luna'), findsOneWidget);
    expect(find.byKey(const Key('shop-merch')), findsNothing);
    expect(find.byKey(const Key('shop-parts')), findsNothing);
    expect(find.text('Add to Cart'), findsNothing);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('Produktakte ohne Warenkorb', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(ok: true, parts: [_kette]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final card = find.byKey(const Key('shop-product-sram-kette'));
    await tester.dragUntilVisible(
      card,
      find.byKey(const Key('shop-gateway')),
      const Offset(0, -240),
    );
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-product-sheet')), findsOneWidget);
    expect(find.byKey(const Key('shop-sheet-open')), findsNothing);
    expect(find.byKey(const Key('shop-sheet-web')), findsOneWidget);
    expect(find.text('Im Shop öffnen'), findsNothing);
    expect(find.text('Im Browser öffnen'), findsWidgets);
    expect(find.text('Add to Cart'), findsNothing);
    expect(find.byKey(const Key('shop-sheet-dealer')), findsNothing);
  });

  testWidgets('Zum Händler nur bei tiefer Händler-URL', (tester) async {
    const dealer = ShopProduct(
      id: 'p-dealer',
      handle: 'oneup-dropper',
      name: 'OneUp Dropper',
      manufacturer: 'OneUp',
      priceEur: 199,
      currencyCode: 'EUR',
      slotKey: 'dropper',
      affiliateUrl: 'https://oneupcomponents.com/products/v3-dropper-post',
    );
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(ok: true, parts: [dealer]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final card = find.byKey(const Key('shop-product-oneup-dropper'));
    await tester.dragUntilVisible(
      card,
      find.byKey(const Key('shop-gateway')),
      const Offset(0, -240),
    );
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-sheet-dealer')), findsOneWidget);
    expect(find.text('Beim Händler kaufen'), findsOneWidget);
  });

  testWidgets('Werkstatt-Slot filtert das Regal', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        extra: [
          shopPendingSlotProvider.overrideWith((ref) => 'chain'),
        ],
        shelves: const ShopShelves(
          ok: true,
          parts: [
            _kette,
            ShopProduct(
              id: 'p2',
              handle: 'schwalbe-gone',
              name: 'Schwalbe G-One',
              manufacturer: 'Schwalbe',
              priceEur: 64,
              currencyCode: 'EUR',
              slotKey: 'tire',
              tags: ['category:gravel', 'slot:tire'],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('SRAM Kette PC-1110'), findsOneWidget);
    expect(find.text('Schwalbe G-One'), findsNothing);
  });

  testWidgets('Leeres Storefront-Regal ist gestaltet, kein Fehler', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(ok: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-catalog-empty')), findsOneWidget);
    expect(find.byKey(const Key('shop-go')), findsNothing);
    expect(find.byKey(const Key('shop-catalog-failed')), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Add to Cart'), findsNothing);
  });

  testWidgets('Nur passende blendet Mismatch aus', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(
          ok: true,
          parts: [_kette, _assegai],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('SRAM Kette PC-1110'), findsOneWidget);
    expect(find.text('Maxxis Assegai'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-fit-only')));
    await tester.pump();

    expect(find.text('SRAM Kette PC-1110'), findsOneWidget);
    expect(find.text('Maxxis Assegai'), findsNothing);
  });

  testWidgets('Deep-Link-Handle öffnet die Produktakte', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        extra: [
          shopPendingHandleProvider.overrideWith((ref) => 'sram-kette'),
        ],
        shelves: const ShopShelves(ok: true, parts: [_kette]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.byKey(const Key('shop-product-sheet')), findsOneWidget);
    expect(find.byKey(const Key('shop-sheet-web')), findsOneWidget);
    expect(find.text('Im Shop öffnen'), findsNothing);
  });

  testWidgets('Mehrere Räder: Union, Chip filtert Fit', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna, _trail],
        shelves: const ShopShelves(
          ok: true,
          parts: [_kette, _assegai],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-bike-all')), findsOneWidget);
    expect(find.byKey(const Key('shop-bike-g1')), findsOneWidget);
    expect(find.byKey(const Key('shop-bike-m1')), findsOneWidget);
    expect(find.text('SRAM Kette PC-1110'), findsOneWidget);
    expect(find.text('Maxxis Assegai'), findsOneWidget);
    expect(find.text('Teile passend zu deinen Rädern'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-bike-g1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shop-fit-only')));
    await tester.pump();

    expect(find.text('SRAM Kette PC-1110'), findsOneWidget);
    expect(find.text('Maxxis Assegai'), findsNothing);
    expect(find.textContaining('Teile passend zu Luna'), findsOneWidget);
  });

  testWidgets('Merch-Leere ist ehrlich, keine Merchandise-Tür', (tester) async {
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(ok: true, parts: [_kette]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-merch')), findsNothing);
    expect(find.byKey(const Key('shop-merch-empty')), findsOneWidget);
    expect(find.text('Kleidung'), findsOneWidget);
    expect(find.textContaining('Kein Merch im Regal'), findsOneWidget);
    expect(find.text('Merchandise'), findsNothing);
  });

  testWidgets('Live-Räder nur Storefront, kein Snapshot-SKU', (tester) async {
    const terra = ShopProduct(
      id: 'gid://shopify/Product/9',
      handle: 'orbea-terra-m20',
      name: 'Orbea Terra M20 Team',
      manufacturer: 'Orbea',
      priceEur: 3199,
    );
    await tester.pumpWidget(
      _shopApp(
        bikes: const [_luna],
        shelves: const ShopShelves(
          ok: true,
          parts: [_kette],
          bikes: [terra],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('shop-featured-bikes')), findsOneWidget);
    expect(
      find.byKey(const Key('shop-featured-orbea-terra-m20')),
      findsOneWidget,
    );
    expect(find.text('Orbea Terra M20 Team'), findsOneWidget);
    expect(find.textContaining('sp-shopify'), findsNothing);
    expect(find.byKey(const Key('shop-parts')), findsNothing);
  });
}
