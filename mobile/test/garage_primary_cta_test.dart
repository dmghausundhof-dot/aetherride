import 'package:aetherride_mobile/domain/garage/garage_primary_cta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Priorität: Wartung vor Teilen vor Aktiv vor Setup', () {
    expect(
      resolveGaragePrimaryAction(
        isActive: false,
        dueCount: 2,
        partsCount: 0,
      ),
      GaragePrimaryAction.viewMaintenance,
    );
    expect(
      resolveGaragePrimaryAction(
        isActive: false,
        dueCount: 0,
        partsCount: 0,
      ),
      GaragePrimaryAction.addPart,
    );
    expect(
      resolveGaragePrimaryAction(
        isActive: false,
        dueCount: 0,
        partsCount: 3,
      ),
      GaragePrimaryAction.setActive,
    );
    expect(
      resolveGaragePrimaryAction(
        isActive: true,
        dueCount: 0,
        partsCount: 3,
      ),
      GaragePrimaryAction.openSetup,
    );
  });
}
