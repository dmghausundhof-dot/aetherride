import 'package:aetherride_mobile/data/routing/overlay_regions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GPS picks DACH overlay region, not RN default', () {
    expect(overlayRegionForPoint(16.373, 48.208)?.id, 'wien');
    expect(overlayRegionForPoint(11.575, 48.137)?.id, 'muenchen');
    expect(overlayRegionForPoint(8.541, 47.376)?.id, 'zuerich');
    expect(overlayRegionForPoint(9.993, 53.551)?.id, 'hamburg');
    expect(overlayRegionForPoint(8.694, 49.409)?.id, 'rhein-neckar');
    expect(overlayRegionForPoint(-30, 0), isNull);
  });
}
