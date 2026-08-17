import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/presentation/discover/discover_explore_chrome.dart';

void main() {
  group('DiscoverExploreChromeLogic', () {
    test('around chip shows 35 km until a max is set', () {
      expect(DiscoverExploreChromeLogic.defaultAroundKm, 35);
      expect(DiscoverExploreChromeLogic.aroundDisplayKm(null), 35);
      expect(DiscoverExploreChromeLogic.aroundDisplayKm(40), 40);
      expect(DiscoverExploreChromeLogic.aroundIsSet(null), isFalse);
      expect(DiscoverExploreChromeLogic.aroundIsSet(40), isTrue);
    });
  });
}
