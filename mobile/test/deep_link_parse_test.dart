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
}
