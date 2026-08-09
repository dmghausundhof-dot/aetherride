import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/data/local/user_profile_store.dart';
import 'package:aetherride_mobile/domain/bike.dart';

void main() {
  test('bikeCategoryFromName resolves known enums', () {
    expect(bikeCategoryFromName('emtb'), BikeCategory.emtb);
    expect(bikeCategoryFromName('mtbAm'), BikeCategory.mtbAm);
    expect(bikeCategoryFromName('nope'), isNull);
    expect(bikeCategoryFromName(null), isNull);
  });

  test('new UserProfileStore starts with onboarding pending', () {
    final store = UserProfileStore();
    expect(store.onboardingDone, isFalse);
    expect(store.preferredSport, isNull);
  });
}
