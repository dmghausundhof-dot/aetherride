import 'package:aetherride_mobile/domain/garage/family_setup_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leaving Ich snapshots the live setup', () {
    expect(
      snapshotOwnSetup(activeRiderId: null, currentSetupId: 'mine'),
      'mine',
    );
    expect(
      snapshotOwnSetup(activeRiderId: 'kid', currentSetupId: 'kid-setup'),
      isNull,
    );
  });

  test('Ich restores the remembered setup, not the kid one', () {
    expect(
      setupToApplyOnFamilySwitch(
        nextRiderId: null,
        rememberedOwnId: 'mine',
        nextRiderSetupIds: const [],
        existingSetupIds: const ['mine', 'kid-setup'],
        familyOwnedSetupIds: const ['kid-setup'],
        currentSetupId: 'kid-setup',
      ),
      'mine',
    );
  });

  test('family chip applies the rider setup', () {
    expect(
      setupToApplyOnFamilySwitch(
        nextRiderId: 'kid',
        rememberedOwnId: 'mine',
        nextRiderSetupIds: const ['kid-setup'],
        existingSetupIds: const ['mine', 'kid-setup'],
        familyOwnedSetupIds: const ['kid-setup'],
        currentSetupId: 'mine',
      ),
      'kid-setup',
    );
  });
}
