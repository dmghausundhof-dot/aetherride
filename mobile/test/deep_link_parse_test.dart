import 'package:aetherride_mobile/data/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkParse.kindOf', () {
    test('custom scheme ride', () {
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://ride?route=r-1')),
        DeepLinkKind.ride,
      );
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://ride')),
        DeepLinkKind.ride,
      );
    });

    test('custom scheme tours / discover', () {
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://tours/r-heidelberg-city')),
        DeepLinkKind.tour,
      );
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://discover')),
        DeepLinkKind.discover,
      );
    });

    test('custom scheme shop / teile / parts → shop tab', () {
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://shop')),
        DeepLinkKind.shop,
      );
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://teile')),
        DeepLinkKind.shop,
      );
      expect(
        DeepLinkParse.kindOf(Uri.parse('aetherride://parts')),
        DeepLinkKind.shop,
      );
    });

    test('https app links', () {
      expect(
        DeepLinkParse.kindOf(
          Uri.parse(
            'https://aetherride.vercel.app/open/ride?route=r-heidelberg-city',
          ),
        ),
        DeepLinkKind.ride,
      );
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('https://aetherride.vercel.app/tours/r-heidelberg-city'),
        ),
        DeepLinkKind.tour,
      );
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('https://aetherride.vercel.app/discover'),
        ),
        DeepLinkKind.discover,
      );
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('https://aetherride.vercel.app/shop/parts'),
        ),
        DeepLinkKind.shop,
      );
      expect(
        DeepLinkParse.kindOf(Uri.parse('https://aetherride.vercel.app/teile')),
        DeepLinkKind.shop,
      );
    });

    test('platz invite https + custom scheme', () {
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('https://aetherride.vercel.app/library?group=ABC234'),
        ),
        DeepLinkKind.platz,
      );
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('aetherride://platz?code=ABC234&g=token'),
        ),
        DeepLinkKind.platz,
      );
      expect(
        DeepLinkParse.groupCodeOf(
          Uri.parse('https://aetherride.vercel.app/library?group=abc234'),
        ),
        'ABC234',
      );
      expect(
        DeepLinkParse.groupCodeOf(
          Uri.parse('aetherride://platz?code=K7M2NP'),
        ),
        'K7M2NP',
      );
      expect(
        DeepLinkParse.groupInviteTokenOf(
          Uri.parse('aetherride://platz?code=ABC234&g=eyJ2Ijox'),
        ),
        'eyJ2Ijox',
      );
      expect(
        DeepLinkParse.groupCodeOf(
          Uri.parse(
            'https://aetherride.vercel.app/library?group=11111111-1111-1111-1111-111111111111&g=tok',
          ),
        ),
        '11111111-1111-1111-1111-111111111111'.toUpperCase(),
      );
    });

    test('auth callbacks ignored', () {
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('io.aetherride.app://login-callback/'),
        ),
        DeepLinkKind.ignore,
      );
      expect(
        DeepLinkParse.kindOf(
          Uri.parse('io.aetherride.app://strava-callback/'),
        ),
        DeepLinkKind.ignore,
      );
    });
  });

  group('DeepLinkParse.routeIdOf', () {
    test('query param', () {
      expect(
        DeepLinkParse.routeIdOf(
          Uri.parse('aetherride://ride?route=r-heidelberg-city'),
        ),
        'r-heidelberg-city',
      );
    });

    test('path segment under tours', () {
      expect(
        DeepLinkParse.routeIdOf(
          Uri.parse('https://aetherride.vercel.app/tours/r-heidelberg-city'),
        ),
        'r-heidelberg-city',
      );
      expect(
        DeepLinkParse.routeIdOf(
          Uri.parse('aetherride://tours/r-heidelberg-city'),
        ),
        'r-heidelberg-city',
      );
    });
  });

  group('DeepLinkParse discover loop start (D-60-05)', () {
    test('loop id + start + lens from query', () {
      final uri = Uri.parse(
        'aetherride://discover?lens=60&loop=seed-loop-tempelhofer-60&start=1',
      );
      expect(DeepLinkParse.kindOf(uri), DeepLinkKind.discover);
      expect(DeepLinkParse.loopIdOf(uri), 'seed-loop-tempelhofer-60');
      expect(DeepLinkParse.startRideOf(uri), isTrue);
      expect(DeepLinkParse.lensMinutesOf(uri), 60);
    });

    test('https discover path', () {
      final uri = Uri.parse(
        'https://aetherride.vercel.app/discover?loop=seed-loop-spree-feierabend-60&start=1',
      );
      expect(DeepLinkParse.kindOf(uri), DeepLinkKind.discover);
      expect(DeepLinkParse.loopIdOf(uri), 'seed-loop-spree-feierabend-60');
      expect(DeepLinkParse.startRideOf(uri), isTrue);
    });

    test('start absent is false', () {
      final uri = Uri.parse(
        'aetherride://discover?loop=seed-loop-tempelhofer-60',
      );
      expect(DeepLinkParse.startRideOf(uri), isFalse);
    });

    test('start=true also enables autostart handoff', () {
      final uri = Uri.parse(
        'aetherride://discover?lens=60&loop=seed-loop-tempelhofer-60&start=true',
      );
      expect(DeepLinkParse.startRideOf(uri), isTrue);
      expect(DeepLinkParse.loopIdOf(uri), 'seed-loop-tempelhofer-60');
    });

    test('Berlin demo deep-link shape for S25 adb', () {
      // adb shell am start -a android.intent.action.VIEW \
      //   -d 'aetherride://discover?lens=60&loop=seed-loop-tempelhofer-60&start=1' \
      //   com.aetherride.aetherride_mobile
      final uri = Uri.parse(
        'aetherride://discover?lens=60&loop=seed-loop-tempelhofer-60&start=1',
      );
      expect(DeepLinkParse.kindOf(uri), DeepLinkKind.discover);
      expect(DeepLinkParse.startRideOf(uri), isTrue);
      expect(DeepLinkParse.loopIdOf(uri), 'seed-loop-tempelhofer-60');
      expect(DeepLinkParse.lensMinutesOf(uri), 60);
    });
  });

  group('DeepLinkParse shop params', () {
    test('query slot bike handle fit', () {
      final uri = Uri.parse(
        'aetherride://shop?slot=chain&bike=g1&fit=bike&handle=sram-kette',
      );
      expect(DeepLinkParse.kindOf(uri), DeepLinkKind.shop);
      expect(DeepLinkParse.shopSlotOf(uri), 'chain');
      expect(DeepLinkParse.shopBikeOf(uri), 'g1');
      expect(DeepLinkParse.shopHandleOf(uri), 'sram-kette');
      expect(DeepLinkParse.shopFitBikeOf(uri), isTrue);
    });

    test('https /shop/p/<handle>', () {
      final uri = Uri.parse('https://aetherride.app/shop/p/sram-kette');
      expect(DeepLinkParse.kindOf(uri), DeepLinkKind.shop);
      expect(DeepLinkParse.shopHandleOf(uri), 'sram-kette');
    });

    test('custom scheme shop/p/handle', () {
      final uri = Uri.parse('aetherride://shop/p/sram-kette');
      expect(DeepLinkParse.kindOf(uri), DeepLinkKind.shop);
      expect(DeepLinkParse.shopHandleOf(uri), 'sram-kette');
    });

    test('job=replace implies fit bike; snapshot focus ignored', () {
      expect(
        DeepLinkParse.shopFitBikeOf(
          Uri.parse('https://aetherride.app/shop?job=replace'),
        ),
        isTrue,
      );
      expect(
        DeepLinkParse.shopHandleOf(
          Uri.parse('https://aetherride.app/shop?focus=sp-sram'),
        ),
        isNull,
      );
      expect(DeepLinkParse.shopFitBikeOf(Uri.parse('aetherride://shop')), isFalse);
    });
  });
}
