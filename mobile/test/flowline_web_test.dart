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

  test('myshopify bleibt in der App zu ohne Shopify-Kasse', () {
    final shopify = Uri.parse(
      'https://dmg-haus-und-hof-shop.myshopify.com/products/sram-kette',
    );
    expect(allowInAppShopOutbound(shopify), isFalse);
    expect(allowInAppShopOutbound(FlowLineWeb.hub()), isTrue);
    expect(
      allowInAppShopOutbound(
        Uri.parse('https://oneupcomponents.com/products/v3-dropper-post'),
      ),
      isTrue,
    );
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
    expect(
      isDeepProductUri(Uri.parse('https://www.bike24.de/p2391234.html')),
      isTrue,
    );
    expect(isDeepProductUri(Uri.parse('https://www.bike24.de/')), isFalse);
    expect(
      merchantCtaUri('https://www.bike24.de/p2391234.html')?.host,
      'www.bike24.de',
    );
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
