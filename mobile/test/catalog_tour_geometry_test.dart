import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/data/routing/catalog_tour_geometry.dart';

void main() {
  test('parses Wiesloch bake and skips thin rings', () {
    const raw = '''
{
  "r-wiesloch-feierabend": {
    "coordinates": [
      [8.69, 49.29], [8.70, 49.30], [8.71, 49.29], [8.70, 49.28],
      [8.69, 49.29], [8.68, 49.295], [8.695, 49.305], [8.705, 49.298],
      [8.69, 49.29]
    ],
    "source": "osrm-cycling-prebake-v1"
  },
  "thin": { "coordinates": [[8.0, 49.0], [8.1, 49.1]] }
}
''';
    final parsed = CatalogTourGeometryStore.parseOverrides(raw);
    expect(parsed.containsKey('r-wiesloch-feierabend'), isTrue);
    expect(parsed['r-wiesloch-feierabend']!.length, greaterThanOrEqualTo(8));
    expect(parsed.containsKey('thin'), isFalse);
  });
}
