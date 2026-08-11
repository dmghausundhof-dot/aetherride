import 'package:aetherride_mobile/core/shop_web.dart';
import 'package:aetherride_mobile/data/shop/shop_catalog_client.dart';
import 'package:aetherride_mobile/data/shop/shop_product.dart';
import 'package:aetherride_mobile/data/shop/shop_soft_fit.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('featuredCollectionSeed', () {
    test('every seed product has a real Shopify CDN photo', () {
      final seed = featuredCollectionSeed();
      expect(seed.length, greaterThanOrEqualTo(5));
      for (final p in seed) {
        expect(p.imageUrl, contains('cdn.shopify.com'));
        expect(p.handle, isNotEmpty);
        expect(p.name, isNotEmpty);
        expect(p.priceEur, greaterThan(0));
      }
    });
  });

  group('ShopProduct.fromJson', () {
    test('maps Storefront parts payload + image fallback', () {
      final p = ShopProduct.fromJson(
        {
          'handle': 'magura-8p-pads',
          'name': 'Magura 8.P Beläge',
          'manufacturer': 'Magura',
          'priceEur': 29.9,
          'currencyCode': 'EUR',
          'softFit': {
            'slots': ['brake_pads'],
          },
        },
        fallbackImage: ShopCdnImages.forHandle('magura-8p-pads'),
      );
      expect(p.handle, 'magura-8p-pads');
      expect(p.chip, 'brake_pads');
      expect(p.imageUrl, contains('cdn.shopify.com'));
      expect(p.priceEur, 29.9);
    });

    test('uses provided imageUrl when present', () {
      const img =
          'https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1571068316344-75bc76f77890.jpg?v=1786479566';
      final p = ShopProduct.fromJson(
        {
          'handle': 'ergon-gp1',
          'title': 'Ergon GP1',
          'vendor': 'Ergon',
          'priceEur': 39,
          'imageUrl': img,
        },
        fallbackImage: ShopCdnImages.pool.first,
      );
      expect(p.imageUrl, img);
      expect(p.name, 'Ergon GP1');
      expect(p.manufacturer, 'Ergon');
    });
  });

  group('ShopWebLinks', () {
    test('parts and product deep links', () {
      expect(ShopWebLinks.parts(), endsWith('/shop/parts'));
      expect(
        ShopWebLinks.parts(bikeId: 'b1', fitBike: true, slot: 'chain'),
        contains('bike=b1'),
      );
      expect(
        ShopWebLinks.parts(bikeId: 'b1', fitBike: true, slot: 'chain'),
        contains('slot=chain'),
      );
      expect(
        ShopWebLinks.product('magura-8p-pads'),
        endsWith('/shop/p/magura-8p-pads'),
      );
    });

    test('garage slot mapping', () {
      expect(
        ShopWebLinks.partsSlotFromComponent(ComponentSlot.chain),
        'chain',
      );
      expect(
        ShopWebLinks.partsSlotFromComponent(ComponentSlot.brakeFront),
        'brake_pads',
      );
      expect(
        ShopWebLinks.partsSlotFromComponent(ComponentSlot.frame),
        isNull,
      );
    });
  });

  group('ShopCdnImages', () {
    test('forHandle is stable and from pool', () {
      final a = ShopCdnImages.forHandle('orbea-terra-m20');
      final b = ShopCdnImages.forHandle('orbea-terra-m20');
      expect(a, b);
      expect(ShopCdnImages.pool, contains(a));
    });
  });

  group('SoftFit / attrs-dimmap', () {
    test('parse tags + verdict passt for matching magura', () {
      final tags = parseSoftFitTags([
        'slot:brake_pads',
        'magura_shape:8',
        'caliper:mt7',
      ]);
      expect(tags.slots, contains('brake_pads'));
      final ctx = SoftFitContext(
        bikeId: 'b1',
        bikeName: 'Trail',
        maguraShape: '8',
        calipers: const ['mt7'],
      );
      expect(softFitVerdict(tags, ctx), 'passt');
      expect(productMatchesSoftFitFilter(tags, ctx, 'bike'), isTrue);
    });

    test('attrs dimmap from installed brakes', () {
      final ctx = AttrsDimMap.fromInstalled(
        bikeId: 'b1',
        bikeName: 'Enduro',
        installed: [
          const BikeComponent(
            id: 'c1',
            bikeId: 'b1',
            slot: ComponentSlot.brakeFront,
            manufacturer: 'Magura',
            model: 'MT7',
            attributes: {'magura_shape': '8'},
          ),
        ],
      );
      expect(ctx.maguraShape, '8');
      expect(ctx.installedSlots, contains(ComponentSlot.brakeFront));
      expect(ctx.missingSlots, isNotEmpty);
    });

    test('appShopDeepLink query params', () {
      final link = ShopWebLinks.appShopDeepLink(
        bikeId: 'bike-1',
        slot: 'chain',
        fitBike: true,
      );
      expect(link, contains('bikeId=bike-1'));
      expect(link, contains('slot=chain'));
      expect(link, contains('fit=bike'));
    });
  });
}
