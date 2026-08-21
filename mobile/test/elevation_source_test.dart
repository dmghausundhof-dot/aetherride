import 'package:aetherride_mobile/data/routing/elevation_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides engine tokens from the rider line', () {
    expect(elevationSourceIsUserFacing(null), isFalse);
    expect(elevationSourceIsUserFacing(''), isFalse);
    expect(elevationSourceIsUserFacing('api'), isFalse);
    expect(elevationSourceIsUserFacing('graphhopper'), isFalse);
    expect(elevationSourceIsUserFacing('SRTM'), isTrue);
    expect(elevationSourceIsUserFacing('Copernicus'), isTrue);
  });
}
