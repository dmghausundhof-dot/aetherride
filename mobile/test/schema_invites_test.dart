import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/schema_invites.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty bike invites two open slots, due stays', () {
    const slots = ['a', 'b', 'c', 'd', 'e'];
    expect(
      schemaInviteSlots(
        hotspotSlots: slots,
        installed: <String>{},
      ),
      ['a', 'b'],
    );
    expect(
      schemaHiddenOpenCount(
        hotspotSlots: slots,
        installed: <String>{},
      ),
      3,
    );
    expect(
      schemaInviteSlots(
        hotspotSlots: slots,
        installed: {'a'},
        due: {'c'},
      ),
      ['c', 'b', 'd'],
    );
  });

  test('frame and quiet-fit are not invitations', () {
    expect(
      schemaInviteSlots(
        hotspotSlots: ['stem', 'frame', 'saddle', 'headset'],
        installed: <String>{},
      ),
      ['stem', 'saddle'],
    );
    expect(schemaInviteSkips('frame'), isTrue);
    expect(schemaInviteSkips(ComponentSlot.frame), isTrue);
    expect(schemaInviteSkips(ComponentSlot.headset), isTrue);
    expect(schemaInviteSkips(ComponentSlot.fork), isFalse);
    expect(schemaHotspotQuiet('frame', missing: true), isTrue);
    expect(schemaHotspotQuiet('frame', missing: false), isFalse);
    expect(schemaHotspotQuiet('fork', missing: true), isFalse);
    expect(
      schemaHiddenOpenCount(
        hotspotSlots: ['stem', 'frame', 'saddle', 'headset', 'seatpost'],
        installed: <String>{},
      ),
      1,
    );
  });
}
