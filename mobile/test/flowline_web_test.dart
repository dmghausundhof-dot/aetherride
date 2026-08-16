import 'package:aetherride_mobile/core/shop_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FlowLine-Web-Katalog zeigt nicht auf myshopify', () {
    expect(FlowLineWeb.hub().toString(), 'https://aetherride.vercel.app/shop');
    expect(FlowLineWeb.product('sram-kette').path, '/shop/p/sram-kette');
    expect(FlowLineWeb.product('sram-kette').host, 'aetherride.vercel.app');

    final parts = FlowLineWeb.parts(bikeId: 'g1', slot: 'chain');
    expect(parts.queryParameters['bike'], 'g1');
    expect(parts.queryParameters['slot'], 'chain');
    expect(parts.queryParameters['fit'], 'bike');
    expect(parts.queryParameters['door'], 'parts');
    expect(parts.host.contains('myshopify'), isFalse);
  });

  test('Zum Händler nur bei tiefer Nicht-Shopify-URL', () {
    expect(
      isShopifyOnlineStoreUri(
        Uri.parse(
          'https://dmg-haus-und-hof-shop.myshopify.com/products/sram-kette',
        ),
      ),
      isTrue,
    );
    expect(
      merchantCtaUri(
        'https://dmg-haus-und-hof-shop.myshopify.com/products/sram-kette',
      ),
      isNull,
    );
    expect(merchantCtaUri('https://www.sram.com/'), isNull);
    expect(
      merchantCtaUri('https://oneupcomponents.com/products/v3-dropper-post')
          ?.host,
      'oneupcomponents.com',
    );
    expect(isDeepProductUri(Uri.parse('https://www.sram.com/')), isFalse);
    expect(
      isDeepProductUri(
        Uri.parse(
          'https://www.bike-components.de/de/s/?searchterm=SRAM+XX+Eagle',
        ),
      ),
      isTrue,
    );
  });
}
