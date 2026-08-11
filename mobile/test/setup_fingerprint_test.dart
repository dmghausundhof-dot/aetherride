import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/setup.dart';
import 'package:aetherride_mobile/domain/setup/fingerprint.dart';

void main() {
  test('tire pressure fingerprint uses psi, not bar', () {
    final fp = SetupFingerprint.fromSetup(
      BikeSetup(
        id: 's1',
        bikeId: 'b1',
        label: 'Basis',
        values: BikeSetup.defaultValues(),
        createdAt: DateTime.utc(2026, 8, 11),
        isCurrent: true,
      ),
    );

    final tireLine = fp.lines.firstWhere((l) => l.startsWith('Reifen'));
    expect(tireLine, 'Reifen 22 psi');
    expect(tireLine.toLowerCase(), isNot(contains('bar')));
  });

  test('null setup stays empty-safe', () {
    final fp = SetupFingerprint.fromSetup(null);
    expect(fp.lines, ['Kein Setup']);
  });
}
