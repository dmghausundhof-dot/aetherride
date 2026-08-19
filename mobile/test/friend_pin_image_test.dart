import 'package:aetherride_mobile/presentation/map/friend_pin_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Live- und Stale-Pin unterscheiden sich', () async {
    final live = await buildFriendPinPng(live: true, initials: 'S');
    final stale = await buildFriendPinPng(live: false, initials: 'S');
    expect(live.length, greaterThan(80));
    expect(stale.length, greaterThan(80));
    expect(live, isNot(equals(stale)));
    expect(friendPinImageId(userId: 'auth-1', live: true), 'aether-friend-auth-1-live');
  });
}
