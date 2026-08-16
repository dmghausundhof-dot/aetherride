import 'package:aetherride_mobile/data/community/public_profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromApi: Handle und Name ohne erfundene Felder', () {
    final s = PublicProfileCloud.fromApi({
      'enabled': true,
      'handle': 'platza',
      'display_name': 'Platz A',
      'bio': '',
      'sports': <String>[],
      'show_ride_count': true,
      'region_label': '',
    });
    expect(s.enabled, isTrue);
    expect(s.handle, 'platza');
    expect(s.displayName, 'Platz A');
    expect(s.bio, isEmpty);
  });
}
